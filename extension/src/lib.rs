//! jbl_speaker: the Arma 3 extension behind the JBL Speaker mod (PLAN.md section 2).
//!
//! SQF talks to it with `"jbl_speaker" callExtension [command, [args]]`:
//!   version                               -> extension version
//!   init                                  -> "ok:<sample rate>" or "error:<reason>" (opens the sound card)
//!   listener x y z fx fy fz               -> where you are and look (ASL position, view direction)
//!   play id file offset gain range x y z  -> start a track (async; answers come back as callbacks)
//!   voice id x y z gain range muffle reverb extra
//!                                         -> move / re-tune a playing voice (a few times a second)
//!   room size                             -> the size of the room you are in, in metres (shapes the echo)
//!   stop id | stop_all | master v | level id | playing
//!
//! Callbacks (the ExtensionCallback event, name "jbl_speaker"): function "started" | "ended" |
//! "error", data = the voice id (for "error": "id|reason").

mod decode;
mod engine;
mod mixer;

use std::collections::HashMap;
use std::fs::File;
use std::io::Cursor;
use std::path::{Path, PathBuf};
use std::sync::mpsc::{channel, Sender};
use std::sync::{Arc, Mutex, OnceLock};
use std::thread;
use std::time::{Duration, Instant};

use arma_rs::{arma, Context, Extension};

use mixer::{Listener, VoiceParams};

const NAME: &str = "jbl_speaker";
/// Largest download we accept (bytes).
const MAX_DOWNLOAD: u64 = 200 * 1024 * 1024;
/// Decoded tracks kept in memory (about 46 MB each for 4 minutes).
const CACHE_TRACKS: usize = 6;

#[arma]
fn init() -> Extension {
    paths::pin_module();
    Extension::build()
        .version(env!("CARGO_PKG_VERSION").to_string())
        .command("init", cmd_init)
        .command("listener", cmd_listener)
        .command("play", cmd_play)
        .command("voice", cmd_voice)
        .command("stop", cmd_stop)
        .command("stop_all", cmd_stop_all)
        .command("room", cmd_room)
        .command("master", cmd_master)
        .command("level", cmd_level)
        .command("playing", cmd_playing)
        .finish()
}

fn cmd_init() -> String {
    match engine::engine() {
        Ok(e) => format!("ok:{}", e.sample_rate),
        Err(e) => format!("error:{e}"),
    }
}

fn cmd_listener(x: f32, y: f32, z: f32, fx: f32, fy: f32, fz: f32) -> String {
    match engine::engine() {
        Ok(e) => {
            e.mixer().set_listener(Listener { pos: [x, y, z], forward: [fx, fy, fz] });
            "ok".into()
        }
        Err(e) => format!("error:{e}"),
    }
}

/// Which `play` call is the current one for an id; a `stop` makes a loading track obsolete.
fn generations() -> &'static Mutex<HashMap<String, u64>> {
    static MAP: OnceLock<Mutex<HashMap<String, u64>>> = OnceLock::new();
    MAP.get_or_init(Default::default)
}

fn next_generation() -> u64 {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(1);
    COUNTER.fetch_add(1, Ordering::Relaxed)
}

#[allow(clippy::too_many_arguments)]
fn cmd_play(ctx: Context, id: String, file: String, offset: f32, gain: f32, range: f32, x: f32, y: f32, z: f32) -> String {
    let engine = match engine::engine() {
        Ok(e) => e,
        Err(e) => return format!("error:{e}"),
    };
    let generation = next_generation();
    generations().lock().unwrap().insert(id.clone(), generation);
    engine.mixer().stop(&id);
    ensure_events(ctx);

    let params = VoiceParams { pos: [x, y, z], gain, range, ..Default::default() };
    thread::spawn(move || {
        let started = Instant::now();
        let callback = |function: &str, data: String| emit(function, data);
        match load(&file, engine.sample_rate) {
            Ok(data) => {
                // Decoding takes a moment: skip ahead so everyone stays in sync
                let seconds = offset.max(0.0) + started.elapsed().as_secs_f32();
                let frame = (seconds * engine.sample_rate as f32) as usize;
                let current = generations().lock().unwrap().get(&id).copied() == Some(generation);
                if !current {
                    return; // stopped or restarted while loading
                }
                if frame >= data.len() {
                    callback("ended", id);
                    return;
                }
                engine.mixer().play(&id, data, frame, params);
                callback("started", id);
            }
            Err(e) => callback("error", format!("{id}|{e}")),
        }
    });
    "queued".into()
}

#[allow(clippy::too_many_arguments)]
fn cmd_voice(id: String, x: f32, y: f32, z: f32, gain: f32, range: f32, muffle: f32, reverb: f32, extra: f32) -> String {
    match engine::engine() {
        Ok(e) => {
            e.mixer().set_voice(&id, VoiceParams { pos: [x, y, z], gain, range, muffle, reverb, extra_distance: extra });
            "ok".into()
        }
        Err(e) => format!("error:{e}"),
    }
}

fn cmd_stop(id: String) -> String {
    generations().lock().unwrap().remove(&id);
    if let Ok(e) = engine::engine() {
        e.mixer().stop(&id);
    }
    "ok".into()
}

fn cmd_stop_all() -> String {
    generations().lock().unwrap().clear();
    if let Ok(e) = engine::engine() {
        e.mixer().stop_all();
    }
    "ok".into()
}

fn cmd_room(size: f32) -> String {
    match engine::engine() {
        Ok(e) => {
            e.mixer().set_room(size);
            "ok".into()
        }
        Err(e) => format!("error:{e}"),
    }
}

fn cmd_master(volume: f32) -> String {
    match engine::engine() {
        Ok(e) => {
            e.mixer().master = volume.clamp(0.0, 2.0);
            "ok".into()
        }
        Err(e) => format!("error:{e}"),
    }
}

fn cmd_level(id: String) -> f32 {
    engine::engine().map_or(0.0, |e| e.mixer().level(&id))
}

fn cmd_playing() -> String {
    engine::engine().map_or(0, |e| e.mixer().voice_count()).to_string()
}

/// Messages for Arma: (function, data). One thread owns the Context (it can't be cloned) and sends
/// them; the first `play` call hands it over.
fn event_sender() -> &'static OnceLock<Mutex<Sender<(String, String)>>> {
    static SENDER: OnceLock<Mutex<Sender<(String, String)>>> = OnceLock::new();
    &SENDER
}

fn emit(function: &str, data: String) {
    if let Some(tx) = event_sender().get() {
        let _ = tx.lock().unwrap().send((function.to_string(), data));
    }
}

/// Starts the callback thread and the watcher that reports finished tracks. Only the first call
/// does anything.
fn ensure_events(ctx: Context) {
    let (tx, rx) = channel::<(String, String)>();
    if event_sender().set(Mutex::new(tx)).is_err() {
        return;
    }
    thread::spawn(move || {
        while let Ok((function, data)) = rx.recv() {
            let _ = ctx.callback_data(NAME, &function, data);
        }
    });
    thread::spawn(|| loop {
        thread::sleep(Duration::from_millis(150));
        if let Ok(e) = engine::engine() {
            let ended = e.mixer().take_ended();
            for id in ended {
                emit("ended", id);
            }
        }
    });
}

/// A file name, absolute path or http(s) link to decoded mono audio at the mixer's rate.
fn load(file: &str, rate: u32) -> Result<Arc<Vec<f32>>, String> {
    static CACHE: OnceLock<Mutex<Vec<(String, Arc<Vec<f32>>)>>> = OnceLock::new();
    let cache = CACHE.get_or_init(Default::default);
    let key = format!("{rate}|{file}");
    if let Some((_, data)) = cache.lock().unwrap().iter().find(|(k, _)| *k == key) {
        return Ok(data.clone());
    }

    let extension = Path::new(file.split(['?', '#']).next().unwrap_or(file)).extension().and_then(|e| e.to_str()).map(str::to_lowercase);
    let data = if file.starts_with("http://") || file.starts_with("https://") {
        let mut response = ureq::get(file).call().map_err(|e| format!("download failed: {e}"))?;
        let bytes = response.body_mut().with_config().limit(MAX_DOWNLOAD).read_to_vec().map_err(|e| format!("download failed: {e}"))?;
        decode::decode_to_mono(Box::new(Cursor::new(bytes)), extension.as_deref(), rate)?
    } else {
        let path = resolve(file).ok_or_else(|| format!("file not found: {file}"))?;
        let handle = File::open(&path).map_err(|e| format!("{}: {e}", path.display()))?;
        decode::decode_to_mono(Box::new(handle), extension.as_deref(), rate)?
    };

    let data = Arc::new(data);
    let mut cache = cache.lock().unwrap();
    if cache.len() >= CACHE_TRACKS {
        cache.remove(0);
    }
    cache.push((key, data.clone()));
    Ok(data)
}

/// Absolute paths are used as they are; anything else is looked up in `<mod folder>/music/`.
fn resolve(file: &str) -> Option<PathBuf> {
    let path = Path::new(file);
    if path.is_absolute() {
        return path.is_file().then(|| path.to_path_buf());
    }
    let candidate = paths::mod_folder()?.join("music").join(file);
    candidate.is_file().then_some(candidate)
}

mod paths {
    use std::path::PathBuf;

    /// The folder this DLL was loaded from (the mod folder).
    #[cfg(windows)]
    pub fn mod_folder() -> Option<PathBuf> {
        use std::ffi::c_void;
        use std::os::windows::ffi::OsStringExt;

        #[link(name = "kernel32")]
        extern "system" {
            fn GetModuleHandleExW(flags: u32, address: *const c_void, module: *mut *mut c_void) -> i32;
            fn GetModuleFileNameW(module: *mut c_void, buffer: *mut u16, size: u32) -> u32;
        }
        const FROM_ADDRESS: u32 = 0x4;
        const UNCHANGED_REFCOUNT: u32 = 0x2;

        let mut module: *mut c_void = std::ptr::null_mut();
        let mut buffer = [0u16; 1024];
        // SAFETY: plain Win32 calls with valid pointers; the address belongs to this module
        let length = unsafe {
            if GetModuleHandleExW(FROM_ADDRESS | UNCHANGED_REFCOUNT, mod_folder as *const c_void, &mut module) == 0 {
                return None;
            }
            GetModuleFileNameW(module, buffer.as_mut_ptr(), buffer.len() as u32)
        } as usize;
        if length == 0 || length >= buffer.len() {
            return None;
        }
        let dll = PathBuf::from(std::ffi::OsString::from_wide(&buffer[..length]));
        dll.parent().map(PathBuf::from)
    }

    #[cfg(not(windows))]
    pub fn mod_folder() -> Option<PathBuf> {
        None
    }

    /// Keeps this DLL loaded until the process ends. Our background threads (audio stream,
    /// callbacks) keep running while Arma shuts down; if Arma unloaded the DLL first they would
    /// run code that is gone, which crashed the game on exit (access violation).
    #[cfg(windows)]
    pub fn pin_module() {
        use std::ffi::c_void;

        #[link(name = "kernel32")]
        extern "system" {
            fn GetModuleHandleExW(flags: u32, address: *const c_void, module: *mut *mut c_void) -> i32;
        }
        const PIN: u32 = 0x1;
        const FROM_ADDRESS: u32 = 0x4;

        let mut module: *mut c_void = std::ptr::null_mut();
        // SAFETY: plain Win32 call with a valid pointer; the address belongs to this module
        unsafe {
            GetModuleHandleExW(PIN | FROM_ADDRESS, pin_module as *const c_void, &mut module);
        }
    }

    #[cfg(not(windows))]
    pub fn pin_module() {}
}

#[cfg(test)]
mod tests {
    use super::*;
    use arma_rs::testing::Result as Handled;
    use std::time::Duration;

    fn args(values: &[&str]) -> Option<Vec<String>> {
        Some(values.iter().map(|v| v.to_string()).collect())
    }

    /// One test, one extension instance: the callback thread is global, like in Arma.
    /// Needs a sound card and a converted song in addons/audio/sounds; parts skip without them.
    #[test]
    fn end_to_end() {
        let ext = init().testing();

        // Wrong number of arguments is an error code, not a crash
        let (_, code) = ext.call("voice", args(&["a", "1"]));
        assert_ne!(code, 0);

        if !ext.call("init", None).0.starts_with("ok") {
            eprintln!("skipped: no audio device");
            return;
        }
        let _ = ext.call("listener", args(&["0", "0", "0", "0", "1", "0"]));

        // A missing file comes back as an "error" callback with the voice id
        let _ = ext.call("play", args(&["missing", "no_such_song.ogg", "0", "1", "75", "0", "3", "0"]));
        let error: Handled<String, String> = ext.callback_handler(
            |_, function, data| if function == "error" { Handled::Ok(format!("{data:?}")) } else { Handled::Continue },
            Duration::from_secs(5),
        );
        match error {
            Handled::Ok(text) => assert!(text.contains("missing") && text.contains("not found"), "{text}"),
            _ => panic!("no error callback"),
        }

        // A real song through the real sound card
        let folder = Path::new(env!("CARGO_MANIFEST_DIR")).join("../addons/audio/sounds");
        let song = std::fs::read_dir(folder)
            .into_iter()
            .flatten()
            .filter_map(|e| e.ok().map(|e| e.path()))
            .find(|p| p.extension().is_some_and(|e| e == "ogg"));
        let Some(song) = song else {
            eprintln!("skipped: no song in addons/audio/sounds");
            return;
        };
        let path = song.canonicalize().unwrap();
        let (queued, _) = ext.call("play", args(&["song", path.to_str().unwrap(), "5", "1", "75", "0", "3", "0"]));
        assert_eq!(queued, "queued");

        let started: Handled<String, String> = ext.callback_handler(
            |_, function, data| match function {
                "started" => Handled::Ok(format!("{data:?}")),
                "error" => Handled::Err(format!("{data:?}")),
                _ => Handled::Continue,
            },
            Duration::from_secs(20),
        );
        assert!(started.is_ok(), "song did not start: {started:?}");
        assert_eq!(ext.call("playing", None).0, "1");

        std::thread::sleep(Duration::from_millis(800));
        let level: f32 = ext.call("level", args(&["song"])).0.parse().unwrap();
        assert!(level > 0.0, "silence (level {level})");

        let _ = ext.call("stop", args(&["song"]));
        assert_eq!(ext.call("playing", None).0, "0");
    }
}
