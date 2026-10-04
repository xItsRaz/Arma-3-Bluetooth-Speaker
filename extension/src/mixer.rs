//! The 3D mixer: pure DSP with no audio device, so it can be unit tested.
//!
//! Every voice is a mono track. For each audio block the mixer works out, from the listener and
//! the voice position: distance gain (full close up, reaching zero at the voice's range),
//! left/right pan, a low-pass filter (distance + muffling through walls) and a reverb send.

use std::collections::HashMap;
use std::f32::consts::PI;
use std::sync::Arc;

/// Distance (m) inside which a voice plays at full volume.
const REFERENCE_DISTANCE: f32 = 1.0;
/// How fast the volume falls between the reference distance and the range (1 = linear).
const FALLOFF: f32 = 1.5;

#[derive(Clone, Copy, Debug)]
pub struct Listener {
    pub pos: [f32; 3],
    /// Direction the listener looks at (does not need to be normalised).
    pub forward: [f32; 3],
}

impl Default for Listener {
    fn default() -> Self {
        Self { pos: [0.0; 3], forward: [0.0, 1.0, 0.0] }
    }
}

#[derive(Clone, Copy, Debug)]
pub struct VoiceParams {
    pub pos: [f32; 3],
    /// Loudness multiplier (the speaker's volume level).
    pub gain: f32,
    /// Distance in metres at which the voice becomes silent.
    pub range: f32,
    /// 0 = clear, 1 = fully muffled (a wall in between).
    pub muffle: f32,
    /// 0..1 amount sent to the reverb (indoors).
    pub reverb: f32,
    /// Extra path length in metres (sound that bends around a corner or through a door).
    pub extra_distance: f32,
}

impl Default for VoiceParams {
    fn default() -> Self {
        Self { pos: [0.0; 3], gain: 1.0, range: 75.0, muffle: 0.0, reverb: 0.0, extra_distance: 0.0 }
    }
}

struct Voice {
    data: Arc<Vec<f32>>,
    position: usize,
    params: VoiceParams,
    gain_left: f32,
    gain_right: f32,
    send: f32,
    low_pass: f32,
    level: f32,
}

/// What a voice sounds like for the current listener.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Targets {
    pub left: f32,
    pub right: f32,
    /// Low-pass cutoff in Hz.
    pub cutoff: f32,
    pub send: f32,
}

pub fn targets(listener: &Listener, p: &VoiceParams) -> Targets {
    let dx = p.pos[0] - listener.pos[0];
    let dy = p.pos[1] - listener.pos[1];
    let dz = p.pos[2] - listener.pos[2];
    let distance = (dx * dx + dy * dy + dz * dz).sqrt() + p.extra_distance.max(0.0);
    let range = p.range.max(1.0);

    let attenuation = if distance <= REFERENCE_DISTANCE {
        1.0
    } else if distance >= range {
        0.0
    } else {
        (1.0 - (distance - REFERENCE_DISTANCE) / (range - REFERENCE_DISTANCE)).powf(FALLOFF)
    };
    let gain = p.gain.max(0.0) * attenuation;

    // Pan from where the voice is in relation to the listener's right-hand side (horizontal only)
    let fwd_len = (listener.forward[0].powi(2) + listener.forward[1].powi(2)).sqrt();
    let flat = (dx * dx + dy * dy).sqrt();
    let pan = if fwd_len < 1e-4 || flat < 0.5 {
        0.0
    } else {
        // Right of (fx, fy) in Arma's x = east, y = north layout is (fy, -fx)
        let (rx, ry) = (listener.forward[1] / fwd_len, -listener.forward[0] / fwd_len);
        ((dx * rx + dy * ry) / flat).clamp(-1.0, 1.0)
    };
    let angle = (pan + 1.0) * PI / 4.0;

    // Far away sounds lose their highs, walls take most of them
    let distance_fraction = (distance / range).clamp(0.0, 1.0);
    let open_cutoff = 18000.0 - 14000.0 * distance_fraction;
    let cutoff = open_cutoff + (450.0 - open_cutoff) * p.muffle.clamp(0.0, 1.0);

    Targets { left: gain * angle.cos(), right: gain * angle.sin(), cutoff, send: p.reverb.clamp(0.0, 1.0) * gain }
}

/// Freeverb-style reverb: 4 damped comb filters and 2 all-pass filters per channel.
struct Reverb {
    combs_left: Vec<Comb>,
    combs_right: Vec<Comb>,
    allpass_left: Vec<AllPass>,
    allpass_right: Vec<AllPass>,
}

struct Comb {
    buffer: Vec<f32>,
    index: usize,
    filter: f32,
}

struct AllPass {
    buffer: Vec<f32>,
    index: usize,
}

impl Comb {
    fn new(size: usize) -> Self {
        Self { buffer: vec![0.0; size.max(1)], index: 0, filter: 0.0 }
    }

    fn process(&mut self, input: f32) -> f32 {
        const FEEDBACK: f32 = 0.84;
        const DAMPING: f32 = 0.25;
        let out = self.buffer[self.index];
        self.filter = out * (1.0 - DAMPING) + self.filter * DAMPING;
        self.buffer[self.index] = input + self.filter * FEEDBACK;
        self.index = (self.index + 1) % self.buffer.len();
        out
    }
}

impl AllPass {
    fn new(size: usize) -> Self {
        Self { buffer: vec![0.0; size.max(1)], index: 0 }
    }

    fn process(&mut self, input: f32) -> f32 {
        let buffered = self.buffer[self.index];
        let out = buffered - input;
        self.buffer[self.index] = input + buffered * 0.5;
        self.index = (self.index + 1) % self.buffer.len();
        out
    }
}

impl Reverb {
    fn new(sample_rate: u32) -> Self {
        let scale = sample_rate as f32 / 44100.0;
        let size = |n: usize| ((n as f32) * scale) as usize;
        const COMBS: [usize; 4] = [1116, 1188, 1277, 1356];
        const ALLPASS: [usize; 2] = [556, 441];
        const SPREAD: usize = 23; // makes the right channel different from the left
        Self {
            combs_left: COMBS.iter().map(|&n| Comb::new(size(n))).collect(),
            combs_right: COMBS.iter().map(|&n| Comb::new(size(n + SPREAD))).collect(),
            allpass_left: ALLPASS.iter().map(|&n| AllPass::new(size(n))).collect(),
            allpass_right: ALLPASS.iter().map(|&n| AllPass::new(size(n + SPREAD))).collect(),
        }
    }

    fn process(&mut self, input: f32) -> (f32, f32) {
        let mut left: f32 = self.combs_left.iter_mut().map(|c| c.process(input)).sum();
        let mut right: f32 = self.combs_right.iter_mut().map(|c| c.process(input)).sum();
        for a in &mut self.allpass_left {
            left = a.process(left);
        }
        for a in &mut self.allpass_right {
            right = a.process(right);
        }
        (left * 0.25, right * 0.25)
    }
}

pub struct Mixer {
    sample_rate: u32,
    listener: Listener,
    voices: HashMap<String, Voice>,
    ended: Vec<String>,
    reverb: Reverb,
    pub master: f32,
}

impl Mixer {
    pub fn new(sample_rate: u32) -> Self {
        Self {
            sample_rate,
            listener: Listener::default(),
            voices: HashMap::new(),
            ended: Vec::new(),
            reverb: Reverb::new(sample_rate),
            master: 1.0,
        }
    }

    pub fn set_listener(&mut self, listener: Listener) {
        self.listener = listener;
    }

    /// Starts (or restarts) a voice. `start_frame` is where in the track to begin.
    pub fn play(&mut self, id: &str, data: Arc<Vec<f32>>, start_frame: usize, params: VoiceParams) {
        let t = targets(&self.listener, &params);
        self.voices.insert(
            id.to_string(),
            Voice {
                position: start_frame.min(data.len()),
                data,
                params,
                // Start at the right volume so there is no fade-in click from silence
                gain_left: t.left,
                gain_right: t.right,
                send: t.send,
                low_pass: 0.0,
                level: 0.0,
            },
        );
    }

    pub fn set_voice(&mut self, id: &str, params: VoiceParams) {
        if let Some(v) = self.voices.get_mut(id) {
            v.params = params;
        }
    }

    pub fn stop(&mut self, id: &str) {
        self.voices.remove(id);
    }

    pub fn stop_all(&mut self) {
        self.voices.clear();
    }

    #[cfg(test)]
    pub fn is_playing(&self, id: &str) -> bool {
        self.voices.contains_key(id)
    }

    pub fn voice_count(&self) -> usize {
        self.voices.len()
    }

    /// Loudness of the music itself right now (0..1), for LED lights. Independent of distance.
    pub fn level(&self, id: &str) -> f32 {
        self.voices.get(id).map_or(0.0, |v| v.level)
    }

    /// Voices that reached the end of their track since the last call.
    pub fn take_ended(&mut self) -> Vec<String> {
        std::mem::take(&mut self.ended)
    }

    /// Fills `out` with interleaved stereo frames.
    pub fn render(&mut self, out: &mut [f32]) {
        out.fill(0.0);
        let frames = out.len() / 2;
        if frames == 0 {
            return;
        }
        let mut send = vec![0.0f32; frames];
        let listener = self.listener;
        let rate = self.sample_rate as f32;
        let mut finished = Vec::new();

        for (id, voice) in self.voices.iter_mut() {
            let t = targets(&listener, &voice.params);
            let coefficient = 1.0 - (-2.0 * PI * t.cutoff.min(rate * 0.45) / rate).exp();
            let (start_left, start_right, start_send) = (voice.gain_left, voice.gain_right, voice.send);
            let mut energy = 0.0f32;

            for i in 0..frames {
                if voice.position >= voice.data.len() {
                    finished.push(id.clone());
                    break;
                }
                let sample = voice.data[voice.position];
                voice.position += 1;
                energy += sample * sample;

                // Gains move smoothly over the block so changes never click
                let k = (i + 1) as f32 / frames as f32;
                let left = start_left + (t.left - start_left) * k;
                let right = start_right + (t.right - start_right) * k;
                voice.low_pass += coefficient * (sample - voice.low_pass);
                out[i * 2] += voice.low_pass * left;
                out[i * 2 + 1] += voice.low_pass * right;
                send[i] += voice.low_pass * (start_send + (t.send - start_send) * k);
            }

            voice.gain_left = t.left;
            voice.gain_right = t.right;
            voice.send = t.send;
            let rms = (energy / frames as f32).sqrt();
            // Quick rise, slower fall: reads well as a light level
            voice.level = if rms > voice.level { rms } else { voice.level * 0.85 + rms * 0.15 };
        }

        for id in finished {
            self.voices.remove(&id);
            self.ended.push(id);
        }

        for i in 0..frames {
            let (left, right) = self.reverb.process(send[i]);
            out[i * 2] = ((out[i * 2] + left) * self.master).clamp(-1.0, 1.0);
            out[i * 2 + 1] = ((out[i * 2 + 1] + right) * self.master).clamp(-1.0, 1.0);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sine(frames: usize, rate: u32, hz: f32) -> Arc<Vec<f32>> {
        Arc::new((0..frames).map(|i| (i as f32 * 2.0 * PI * hz / rate as f32).sin() * 0.5).collect())
    }

    fn at(x: f32, y: f32, range: f32) -> VoiceParams {
        VoiceParams { pos: [x, y, 0.0], range, ..Default::default() }
    }

    fn rms(out: &[f32], channel: usize) -> f32 {
        let samples: Vec<f32> = out.iter().skip(channel).step_by(2).copied().collect();
        (samples.iter().map(|s| s * s).sum::<f32>() / samples.len() as f32).sqrt()
    }

    #[test]
    fn full_volume_close_silent_at_range() {
        let l = Listener::default();
        let close = targets(&l, &at(0.0, 0.5, 75.0));
        let at_range = targets(&l, &at(0.0, 75.0, 75.0));
        assert!(close.left.hypot(close.right) > 0.99);
        assert_eq!(at_range.left, 0.0);
    }

    #[test]
    fn ten_metres_is_still_loud_at_75m_range() {
        // The packed say3D sound was nearly silent at 10 m
        let t = targets(&Listener::default(), &at(0.0, 10.0, 75.0));
        assert!(t.left.hypot(t.right) > 0.6, "{t:?}");
    }

    #[test]
    fn louder_closer_than_far() {
        let l = Listener::default();
        let near = targets(&l, &at(0.0, 5.0, 75.0));
        let far = targets(&l, &at(0.0, 40.0, 75.0));
        assert!(near.left > far.left);
    }

    #[test]
    fn pans_to_the_side_of_the_speaker() {
        // Listener faces north (+y); east (+x) is on the right
        let l = Listener::default();
        let east = targets(&l, &at(10.0, 0.0, 75.0));
        let west = targets(&l, &at(-10.0, 0.0, 75.0));
        assert!(east.right > east.left * 5.0);
        assert!(west.left > west.right * 5.0);
        // Turn to face east: now a speaker to the north is on the left
        let l = Listener { forward: [1.0, 0.0, 0.0], ..Default::default() };
        let north = targets(&l, &at(0.0, 10.0, 75.0));
        assert!(north.left > north.right * 5.0);
    }

    #[test]
    fn muffle_and_distance_cut_the_highs() {
        let l = Listener::default();
        let clear = targets(&l, &at(0.0, 5.0, 75.0));
        let wall = targets(&l, &VoiceParams { muffle: 1.0, ..at(0.0, 5.0, 75.0) });
        let far = targets(&l, &at(0.0, 60.0, 75.0));
        assert!(wall.cutoff < clear.cutoff * 0.1);
        assert!(far.cutoff < clear.cutoff);
    }

    #[test]
    fn extra_path_length_makes_it_quieter() {
        let l = Listener::default();
        let direct = targets(&l, &at(0.0, 5.0, 75.0));
        let around = targets(&l, &VoiceParams { extra_distance: 20.0, ..at(0.0, 5.0, 75.0) });
        assert!(around.left < direct.left);
    }

    #[test]
    fn renders_audio_and_reports_the_end() {
        let rate = 48000;
        let mut m = Mixer::new(rate);
        m.play("a", sine(1000, rate, 440.0), 0, at(0.0, 2.0, 75.0));
        let mut out = vec![0.0; 2048];
        m.render(&mut out);
        assert!(rms(&out, 0) > 0.05 && rms(&out, 1) > 0.05);
        assert_eq!(m.take_ended(), vec!["a".to_string()]);
        assert!(!m.is_playing("a"));
        // Nothing left to play: silence
        m.render(&mut out);
        assert!(out.iter().all(|s| s.abs() < 0.2)); // only a reverb tail
    }

    #[test]
    fn start_offset_skips_into_the_track() {
        let rate = 48000;
        let mut m = Mixer::new(rate);
        m.play("a", sine(4000, rate, 440.0), 3900, at(0.0, 2.0, 75.0));
        let mut out = vec![0.0; 2048];
        m.render(&mut out);
        assert_eq!(m.take_ended(), vec!["a".to_string()]);
    }

    #[test]
    fn stop_and_level() {
        let rate = 48000;
        let mut m = Mixer::new(rate);
        m.play("a", sine(48000, rate, 440.0), 0, at(0.0, 2.0, 75.0));
        let mut out = vec![0.0; 1024];
        m.render(&mut out);
        assert!(m.level("a") > 0.2);
        m.stop("a");
        assert_eq!(m.level("a"), 0.0);
        assert_eq!(m.voice_count(), 0);
    }

    #[test]
    fn reverb_adds_a_tail() {
        let rate = 48000;
        let dry_params = at(0.0, 2.0, 75.0);
        let wet_params = VoiceParams { reverb: 1.0, ..dry_params };
        let tail = |params: VoiceParams| {
            let mut m = Mixer::new(rate);
            m.play("a", sine(2000, rate, 440.0), 0, params);
            let mut out = vec![0.0; 4096];
            m.render(&mut out); // the voice ends in here
            let mut after = vec![0.0; 4096];
            m.render(&mut after);
            rms(&after, 0)
        };
        assert!(tail(wet_params) > tail(dry_params) + 0.001);
    }

    #[test]
    fn ids_are_independent() {
        let rate = 48000;
        let mut m = Mixer::new(rate);
        m.play("a", sine(48000, rate, 440.0), 0, at(5.0, 0.0, 75.0));
        m.play("b", sine(48000, rate, 330.0), 0, at(-5.0, 0.0, 75.0));
        m.stop("a");
        assert!(m.is_playing("b") && !m.is_playing("a"));
    }
}
