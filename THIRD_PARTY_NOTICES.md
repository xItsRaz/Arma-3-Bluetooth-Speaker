# Third-party notices

This project (see `LICENSE`) is licensed under the GNU General Public License, version 2 or (at your option) any later version. It includes or links the following third-party material. Each keeps its own license.

## Included in this repository

| What | Where | License |
|---|---|---|
| CBA_A3 macro headers (`script_macros_common.hpp`, `script_xeh.hpp`) | `include/x/cba/` | GNU GPL v2, by the CBA team (Sickboy, Spooner and contributors). Source: https://github.com/CBATeam/CBA_A3 |

## Required at runtime, not included

- [CBA_A3](https://github.com/CBATeam/CBA_A3), GNU GPL v2
- [ACE3](https://github.com/acemod/ACE3), GNU GPL v2

## Sound extension (`extension/`), Rust crates compiled into `btspk_speaker_x64.dll`

| Crate | License |
|---|---|
| [arma-rs](https://github.com/BrettMayson/arma-rs) | MIT |
| [cpal](https://github.com/RustAudio/cpal) | Apache-2.0 |
| [Symphonia](https://github.com/pdeljanov/Symphonia) | MPL-2.0 |
| [ureq](https://github.com/algesten/ureq) | MIT or Apache-2.0 |
| [native-tls](https://github.com/sfackler/rust-native-tls) | MIT or Apache-2.0 |

These crates have further dependencies of their own; the full list with exact versions is in `extension/Cargo.lock`, and each crate's license text ships with its source on crates.io. Because cpal is Apache-2.0 (not compatible with GPL version 2 only), this project is licensed "GPL-2.0-or-later", so the combined work can be distributed under GPL version 3 where needed.

## Build tools (not distributed with the mod)

- [HEMTT](https://hemtt.dev/), Arma 3 mod build tool
- [Arma 3 Object Builder for Blender](https://github.com/MrClock8163/Arma3ObjectBuilder), used by `tools/blender/make_models.py` to export models
- Arma 3 Tools (Bohemia Interactive), optional, to binarize models

## Trademarks

Spotify is a registered trademark of Spotify AB. The Bluetooth word mark is a registered trademark of Bluetooth SIG, Inc. Arma 3 is a trademark of Bohemia Interactive a.s. This project is unofficial and not affiliated with or endorsed by any of them.
