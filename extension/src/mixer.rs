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
    // Logarithmic between "open" and 450 Hz: 0.4 is a glass pane (~4 kHz), 0.9 a wall (~700 Hz)
    let cutoff = open_cutoff * (450.0 / open_cutoff).powf(p.muffle.clamp(0.0, 1.0));

    Targets { left: gain * angle.cos(), right: gain * angle.sin(), cutoff, send: p.reverb.clamp(0.0, 1.0) * gain }
}

/// The reverb. Three parts, all shaped by the size of the room (set from the game):
///  - early reflections: a few taps off a short history (the first bounces off the walls),
///  - a Freeverb-style tail (4 damped combs and 2 all-passes per channel) after a pre-delay,
///  - in big rooms a slap echo: one clear repeat that returns after the sound crossed the room.
struct Reverb {
    sample_rate: u32,
    combs_left: Vec<Comb>,
    combs_right: Vec<Comb>,
    allpass_left: Vec<AllPass>,
    allpass_right: Vec<AllPass>,
    history: Vec<f32>,
    echo: Vec<f32>,
    write: usize,
    predelay: usize,
    taps_left: [(usize, f32); 4],
    taps_right: [(usize, f32); 4],
    echo_delay: usize,
    echo_gain: f32,
    room: f32,
}

struct Comb {
    buffer: Vec<f32>,
    index: usize,
    filter: f32,
    feedback: f32,
}

struct AllPass {
    buffer: Vec<f32>,
    index: usize,
}

/// The sound travels about this far per second (m/s).
const SPEED_OF_SOUND: f32 = 343.0;
/// Longest delay the reverb keeps (seconds).
const HISTORY_SECONDS: f32 = 0.8;

impl Comb {
    fn new(size: usize) -> Self {
        Self { buffer: vec![0.0; size.max(1)], index: 0, filter: 0.0, feedback: 0.84 }
    }

    fn process(&mut self, input: f32) -> f32 {
        const DAMPING: f32 = 0.25;
        let out = self.buffer[self.index];
        self.filter = out * (1.0 - DAMPING) + self.filter * DAMPING;
        self.buffer[self.index] = input + self.filter * self.feedback;
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
        let length = (HISTORY_SECONDS * sample_rate as f32) as usize;
        let mut reverb = Self {
            sample_rate,
            combs_left: COMBS.iter().map(|&n| Comb::new(size(n))).collect(),
            combs_right: COMBS.iter().map(|&n| Comb::new(size(n + SPREAD))).collect(),
            allpass_left: ALLPASS.iter().map(|&n| AllPass::new(size(n))).collect(),
            allpass_right: ALLPASS.iter().map(|&n| AllPass::new(size(n + SPREAD))).collect(),
            history: vec![0.0; length],
            echo: vec![0.0; length],
            write: 0,
            predelay: 0,
            taps_left: [(0, 0.0); 4],
            taps_right: [(0, 0.0); 4],
            echo_delay: 1,
            echo_gain: 0.0,
            room: 0.0,
        };
        reverb.set_room(8.0);
        reverb
    }

    /// Room size in metres (roughly the distance across the room you are in).
    fn set_room(&mut self, size: f32) {
        let size = size.clamp(1.5, 60.0);
        // Ignore small changes: moving the delays makes a faint click
        if self.room > 0.0 && (size / self.room - 1.0).abs() < 0.15 {
            return;
        }
        self.room = size;
        let rate = self.sample_rate as f32;
        let max = self.history.len() - 1;
        let samples = |seconds: f32| ((seconds * rate) as usize).clamp(1, max);

        let big = ((size - 2.0) / 38.0).clamp(0.0, 1.0);
        for comb in self.combs_left.iter_mut().chain(self.combs_right.iter_mut()) {
            comb.feedback = 0.70 + 0.20 * big; // bigger rooms ring longer
        }
        self.predelay = samples(0.004 + 0.035 * big);

        // First bounces: the sound goes to a wall and comes back
        let t = size / SPEED_OF_SOUND;
        self.taps_left = [
            (samples(t * 0.7), 0.50),
            (samples(t * 1.1), 0.40),
            (samples(t * 1.6), 0.30),
            (samples(t * 2.3), 0.22),
        ];
        self.taps_right = [
            (samples(t * 0.9), 0.50),
            (samples(t * 1.3), 0.38),
            (samples(t * 1.9), 0.28),
            (samples(t * 2.7), 0.20),
        ];

        // One clear echo in rooms big enough to have one (a hall, a warehouse)
        self.echo_delay = samples((2.0 * size / SPEED_OF_SOUND).clamp(0.04, 0.6));
        self.echo_gain = ((size - 6.0) / 20.0).clamp(0.0, 1.0) * 0.5;
    }

    fn process(&mut self, input: f32) -> (f32, f32) {
        let length = self.history.len();
        let read = |buffer: &[f32], write: usize, delay: usize| buffer[(write + length - delay) % length];

        self.history[self.write] = input;
        let early_left: f32 = self.taps_left.iter().map(|&(d, g)| g * read(&self.history, self.write, d)).sum();
        let early_right: f32 = self.taps_right.iter().map(|&(d, g)| g * read(&self.history, self.write, d)).sum();
        let late_input = read(&self.history, self.write, self.predelay.max(1));

        let mut left: f32 = self.combs_left.iter_mut().map(|c| c.process(late_input)).sum();
        let mut right: f32 = self.combs_right.iter_mut().map(|c| c.process(late_input)).sum();
        for a in &mut self.allpass_left {
            left = a.process(left);
        }
        for a in &mut self.allpass_right {
            right = a.process(right);
        }

        // Slap echo: repeats itself a few times, getting quieter
        let echoed = read(&self.echo, self.write, self.echo_delay);
        self.echo[self.write] = input + echoed * 0.45;

        self.write = (self.write + 1) % length;
        (
            left * 0.25 + early_left * 0.35 + echoed * self.echo_gain,
            right * 0.25 + early_right * 0.35 + echoed * self.echo_gain * 0.85,
        )
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

    /// Size of the room the listener is in, in metres (shapes the reverb).
    pub fn set_room(&mut self, size: f32) {
        self.reverb.set_room(size);
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
    fn bigger_rooms_ring_longer_and_echo() {
        let rate = 48000;
        let late = |room: f32| {
            let mut m = Mixer::new(rate);
            m.set_room(room);
            m.play("a", sine(2000, rate, 440.0), 0, VoiceParams { reverb: 1.0, ..at(0.0, 2.0, 75.0) });
            let mut out = vec![0.0; 4096];
            m.render(&mut out);
            // Energy well after the sound ended (0.3-0.5 s)
            let mut energy = 0.0;
            for _ in 0..8 {
                let mut chunk = vec![0.0; 4096];
                m.render(&mut chunk);
                energy += chunk.iter().map(|s| s * s).sum::<f32>();
            }
            energy
        };
        assert!(late(40.0) > late(3.0) * 2.0, "{} vs {}", late(40.0), late(3.0));
    }

    #[test]
    fn muffle_curve_is_logarithmic() {
        let l = Listener::default();
        let glass = targets(&l, &VoiceParams { muffle: 0.4, ..at(0.0, 5.0, 75.0) });
        let wall = targets(&l, &VoiceParams { muffle: 0.9, ..at(0.0, 5.0, 75.0) });
        assert!(glass.cutoff > 2500.0 && glass.cutoff < 6000.0, "{}", glass.cutoff);
        assert!(wall.cutoff < 900.0, "{}", wall.cutoff);
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
