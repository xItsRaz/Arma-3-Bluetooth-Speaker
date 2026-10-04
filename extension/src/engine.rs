//! The audio device: one cpal output stream that pulls from the shared mixer.

use std::sync::mpsc::channel;
use std::sync::{Arc, Mutex, MutexGuard, OnceLock};
use std::thread;

use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use cpal::{FromSample, SampleFormat, SizedSample, StreamConfig};

use crate::mixer::Mixer;

pub struct Engine {
    mixer: Arc<Mutex<Mixer>>,
    pub sample_rate: u32,
}

impl Engine {
    pub fn mixer(&self) -> MutexGuard<'_, Mixer> {
        // A panic elsewhere must not silence the music for good
        self.mixer.lock().unwrap_or_else(|e| e.into_inner())
    }
}

static ENGINE: OnceLock<Result<Engine, String>> = OnceLock::new();

/// Starts the audio device the first time, then returns it. Errors are remembered.
pub fn engine() -> Result<&'static Engine, String> {
    ENGINE.get_or_init(start).as_ref().map_err(|e| e.clone())
}

fn start() -> Result<Engine, String> {
    let (tx, rx) = channel::<Result<Engine, String>>();
    // The stream lives on its own thread (it must never be dropped and is not Send everywhere)
    thread::Builder::new()
        .name("jbl-audio".into())
        .spawn(move || match open() {
            Ok((engine, stream)) => {
                let _ = tx.send(Ok(engine));
                let _keep_alive = stream;
                loop {
                    thread::park();
                }
            }
            Err(e) => {
                let _ = tx.send(Err(e));
            }
        })
        .map_err(|e| e.to_string())?;
    rx.recv().map_err(|e| e.to_string())?
}

fn open() -> Result<(Engine, cpal::Stream), String> {
    let host = cpal::default_host();
    let device = host.default_output_device().ok_or("no audio output device")?;
    let config = device.default_output_config().map_err(|e| e.to_string())?;
    let format = config.sample_format();
    let config: StreamConfig = config.into();
    let sample_rate = config.sample_rate;

    let mixer = Arc::new(Mutex::new(Mixer::new(sample_rate)));
    let stream = match format {
        SampleFormat::F32 => build::<f32>(&device, config, mixer.clone()),
        SampleFormat::I16 => build::<i16>(&device, config, mixer.clone()),
        SampleFormat::U16 => build::<u16>(&device, config, mixer.clone()),
        SampleFormat::I32 => build::<i32>(&device, config, mixer.clone()),
        other => Err(format!("unsupported sample format {other}")),
    }?;
    stream.play().map_err(|e| e.to_string())?;
    Ok((Engine { mixer, sample_rate }, stream))
}

fn build<T>(device: &cpal::Device, config: StreamConfig, mixer: Arc<Mutex<Mixer>>) -> Result<cpal::Stream, String>
where
    T: SizedSample + FromSample<f32>,
{
    let channels = (config.channels as usize).max(1);
    let mut scratch: Vec<f32> = Vec::new();
    device
        .build_output_stream(
            config,
            move |data: &mut [T], _: &cpal::OutputCallbackInfo| {
                let frames = data.len() / channels;
                scratch.resize(frames * 2, 0.0);
                mixer.lock().unwrap_or_else(|e| e.into_inner()).render(&mut scratch);
                for (frame, stereo) in data.chunks_mut(channels).zip(scratch.chunks(2)) {
                    for (i, sample) in frame.iter_mut().enumerate() {
                        // Stereo goes to the first two channels, any others stay silent
                        *sample = match i {
                            0 => T::from_sample(stereo[0]),
                            1 => T::from_sample(stereo[1]),
                            _ => T::from_sample(0.0),
                        };
                    }
                }
            },
            |e: cpal::Error| eprintln!("jbl_speaker: audio stream error: {e}"),
            None,
        )
        .map_err(|e| e.to_string())
}
