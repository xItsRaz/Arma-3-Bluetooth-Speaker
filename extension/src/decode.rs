//! Decoding: any common audio file or download becomes mono f32 at the mixer's sample rate.

use symphonia::core::audio::sample::Sample;
use symphonia::core::codecs::audio::AudioDecoderOptions;
use symphonia::core::errors::Error;
use symphonia::core::formats::probe::Hint;
use symphonia::core::formats::{FormatOptions, TrackType};
use symphonia::core::io::{MediaSource, MediaSourceStream};
use symphonia::core::meta::MetadataOptions;

/// Decodes a whole track. `extension` ("mp3", "ogg"...) only helps format detection.
pub fn decode_to_mono(
    source: Box<dyn MediaSource>,
    extension: Option<&str>,
    target_rate: u32,
) -> Result<Vec<f32>, String> {
    let stream = MediaSourceStream::new(source, Default::default());
    let mut hint = Hint::new();
    if let Some(extension) = extension {
        hint.with_extension(extension);
    }

    let mut format = symphonia::default::get_probe()
        .probe(&hint, stream, FormatOptions::default(), MetadataOptions::default())
        .map_err(|e| format!("unknown audio format: {e}"))?;

    let track = format.default_track(TrackType::Audio).ok_or("no audio track")?;
    let track_id = track.id;
    let params = track
        .codec_params
        .as_ref()
        .and_then(|p| p.audio())
        .ok_or("no audio parameters")?;
    let mut decoder = symphonia::default::get_codecs()
        .make_audio_decoder(params, &AudioDecoderOptions::default())
        .map_err(|e| format!("unsupported codec: {e}"))?;

    let mut mono: Vec<f32> = Vec::new();
    let mut source_rate = 0u32;
    let mut scratch: Vec<f32> = Vec::new();

    loop {
        let packet = match format.next_packet() {
            Ok(Some(packet)) => packet,
            // End of the stream, or an unexpected end of a truncated file: keep what we have
            Ok(None) | Err(_) => break,
        };
        if packet.track_id != track_id {
            continue;
        }
        match decoder.decode(&packet) {
            Ok(buffer) => {
                let channels = buffer.spec().channels().count().max(1);
                source_rate = buffer.spec().rate();
                scratch.resize(buffer.samples_interleaved(), f32::MID);
                buffer.copy_to_slice_interleaved(&mut scratch);
                mono.extend(scratch.chunks(channels).map(|frame| frame.iter().sum::<f32>() / channels as f32));
            }
            Err(Error::DecodeError(_)) => {} // a damaged packet: skip it
            Err(_) => break,
        }
    }

    if mono.is_empty() || source_rate == 0 {
        return Err("the file has no audio".to_string());
    }
    Ok(resample(&mono, source_rate, target_rate))
}

/// Linear resampler. Good enough for music through a game.
pub fn resample(input: &[f32], from: u32, to: u32) -> Vec<f32> {
    if from == to || input.is_empty() {
        return input.to_vec();
    }
    let ratio = from as f64 / to as f64;
    let length = ((input.len() as f64) / ratio) as usize;
    (0..length)
        .map(|i| {
            let position = i as f64 * ratio;
            let index = position as usize;
            let fraction = (position - index as f64) as f32;
            let a = input[index.min(input.len() - 1)];
            let b = input[(index + 1).min(input.len() - 1)];
            a + (b - a) * fraction
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;

    /// A tiny 16-bit mono WAV file in memory.
    fn wav(samples: &[i16], rate: u32) -> Vec<u8> {
        let data_len = (samples.len() * 2) as u32;
        let mut bytes = Vec::new();
        bytes.extend_from_slice(b"RIFF");
        bytes.extend_from_slice(&(36 + data_len).to_le_bytes());
        bytes.extend_from_slice(b"WAVEfmt ");
        bytes.extend_from_slice(&16u32.to_le_bytes());
        bytes.extend_from_slice(&1u16.to_le_bytes()); // PCM
        bytes.extend_from_slice(&1u16.to_le_bytes()); // mono
        bytes.extend_from_slice(&rate.to_le_bytes());
        bytes.extend_from_slice(&(rate * 2).to_le_bytes());
        bytes.extend_from_slice(&2u16.to_le_bytes());
        bytes.extend_from_slice(&16u16.to_le_bytes());
        bytes.extend_from_slice(b"data");
        bytes.extend_from_slice(&data_len.to_le_bytes());
        for s in samples {
            bytes.extend_from_slice(&s.to_le_bytes());
        }
        bytes
    }

    #[test]
    fn decodes_a_wav() {
        let samples: Vec<i16> = (0..4410).map(|i| ((i as f32 * 0.1).sin() * 16000.0) as i16).collect();
        let out = decode_to_mono(Box::new(Cursor::new(wav(&samples, 44100))), Some("wav"), 44100).unwrap();
        assert_eq!(out.len(), 4410);
        assert!(out.iter().any(|s| s.abs() > 0.3));
    }

    #[test]
    fn resamples_to_the_mixer_rate() {
        let samples: Vec<i16> = vec![1000; 4410];
        let out = decode_to_mono(Box::new(Cursor::new(wav(&samples, 44100))), Some("wav"), 48000).unwrap();
        assert!((out.len() as i64 - 4800).abs() <= 2, "{}", out.len());
    }

    #[test]
    fn garbage_is_an_error_not_a_crash() {
        let result = decode_to_mono(Box::new(Cursor::new(vec![1u8, 2, 3, 4, 5, 6, 7, 8])), None, 48000);
        assert!(result.is_err());
    }
}
