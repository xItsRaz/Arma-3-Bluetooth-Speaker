# Arma 3 scripting notes (for this project)

A working reference for the parts of Arma 3 modding this mod uses.

## The pieces of a mod
- **PBO**: an archive of a folder (`jbl_speaker/`). The file `$PBOPREFIX$` sets its internal path, so `\jbl_speaker\functions\fn_init.sqf` resolves.
- **config.cpp**: the static definitions, read once at game start. It uses a C-like class syntax with inheritance (`class JBL_Speaker: Land_FMradio_F {...}`) and supports `#include` / `#define` (C preprocessor).
  - `CfgPatches`: names the addon. `requiredAddons[]` controls load order, so anything you inherit from must load first.
  - `CfgFunctions`: registers SQF files as `TAG_fnc_name`. They're compiled once and are safe from overwriting.
  - `CfgVehicles`: objects and units. `scope = 2` means visible in the editor.
  - `CfgSounds`: sound classes that `say3D` / `playSound` can play.
  - `CfgRemoteExec`: whitelist for `remoteExec`. Missions can restrict this, so document which functions need allowing.
- **mod.cpp**: the launcher display info. **Keys** (`.bikey`) and **signatures** (`.bisign`) let servers verify the mod.

## SQF basics
- Everything is an expression. Commands are unary or binary (`_unit setDamage 1`) and functions are `[args] call TAG_fnc_x`.
- Variables starting with `_` are local to the script. Declare them with `private _x = ...`. Variables without `_` are global to the machine (`missionNamespace`).
- `params ["_a", ["_b", default, [types]]]` unpacks `_this` and checks types.
- Lazy evaluation: `a && {b}`, so `b` only runs if `a` is true. Use this in conditions that run every frame.
- Code is a value: `{ ... }`. Strings in config (`statement = "..."`) are compiled at runtime. Quotes are escaped by doubling them: `""`.
- Arrays are 0-indexed. `select`, `find`, `count`, `pushBack`, `apply`, `forEach` (`_x` = current item).
- `switch (x) do { case "a": {}; default {}; };`

## Scheduled vs unscheduled
- `call` runs immediately, in the same environment as the caller.
- `spawn` creates a **scheduled** script. It can `sleep` / `waitUntil`, but the engine gives it limited time per frame, so it may lag under load.
- Event handlers, `remoteExecCall`, and init event handlers are **unscheduled**: they can't sleep and must finish quickly. That's why `fn_init` spawns its JIP catch-up.
- Anything that waits, like `fn_trackLoop`, must be `spawn`ed.

## Locality (the most important multiplayer concept)
- The wiki tags every command with whether its **arguments** must be local ("AL") or can be global ("AG"), and whether its **effect** is local ("EL") or global ("EG").
  - `say3D`: global args, **local effect**. Every client has to run it themselves, which is why we `remoteExecCall` to everyone.
  - `addAction`: local effect, so it runs on every client (the init EH does that).
  - `setVariable [name, value, true]`: broadcast and synced to players who join late.
- `isServer`, `hasInterface` (has a screen, i.e. not a dedicated server or headless client), `isMultiplayer`, and `local _obj`.
- **remoteExec / remoteExecCall** `[args] remoteExec ["fn", target, jip]`. Target `0` = everyone, `2` = server, `-2` = all but server, or an object/owner ID. The `jip` flag queues it for players who join later.
- **JIP (join in progress):** a late joiner runs object init EHs and receives public variables. Rebuild the state from those; don't replay history.
- `time` is per machine. `serverTime` is synced in MP, so use `[time, serverTime] select isMultiplayer` for shared timestamps.

## Event handlers
- Object: `class EventHandlers { init = "..."; }` in config, or `_obj addEventHandler ["Deleted", {...}]`.
- Mission: `addMissionEventHandler ["EachFrame", {...}]` (for 3D audio updates, keep it cheap), `["ExtensionCallback", {params ["_name","_function","_data"]}]` (events coming from the DLL).

## Sound commands (no DLL)
- `obj say3D [class, maxDistance, pitch, isSpeech, offset, simulateSpeedOfSound]` returns a sound-source object. `deleteVehicle` on it stops the sound. `offset` = seconds into the file, which lets late joiners sync.
- You can't change volume while a sound plays. Only Ogg Vorbis / WSS / WAV are supported. Mono files are placed properly in 3D.

## Extensions (DLLs)
- `"jbl_speaker" callExtension ["command", [args]]` returns `[result, returnCode, errorCode]`. It's synchronous and runs on the game thread, so **return quickly** and do the real work on DLL threads.
- 64-bit DLL name: `jbl_speaker_x64.dll`, placed in the mod root (`@JBLSpeaker/`).
- Exports (handled for us by **arma-rs** in Rust): `RVExtension`, `RVExtensionArgs`, `RVExtensionVersion`, `RVExtensionRegisterCallback`.
- Async results go back through the callback and show up as the `ExtensionCallback` mission event.
- BattlEye blocks DLLs that aren't whitelisted.

## ACE3 hooks we use
- Interaction menu, config style:
  ```cpp
  class ACE_Actions {
      class ACE_MainActions {
          class jbl_play {
              displayName = "Play";
              condition = "!(_target getVariable ['jbl_playing', false])";
              statement = "[_target, 'play'] remoteExecCall ['JBL_fnc_command', 2]";
          };
      };
  };
  ```
  Script style: `ace_interact_menu_fnc_createAction` + `ace_interact_menu_fnc_addActionToObject` / `addActionToClass`. `insertChildren` builds sub-menus dynamically, e.g. a track list.
- Carrying: `ace_dragging_canCarry = 1; ace_dragging_carryPosition[] = {0,1,1}; ace_dragging_carryDirection = 0;`, or `ace_dragging_fnc_setCarryable` from a script.
- Cargo: `ace_cargo_size`, `ace_cargo_canLoad`.

## Tools
- **Arma 3 Tools** (Steam, Windows): Addon Builder (packs PBOs), Object Builder (models), and DSSignFile (signing).
- **HEMTT**: a cross-platform command-line builder that packs, lints, and signs from one config. It works on Mac/Linux and in GitHub Actions.
- Debugging: the debug console in Eden (`Esc` while previewing), `diag_log` (writes to the `.rpt` log in `%LOCALAPPDATA%\Arma 3`), and `systemChat`.
