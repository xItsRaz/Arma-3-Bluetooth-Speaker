#include "\x\cba\addons\main\script_macros_common.hpp"
#include "\x\cba\addons\xeh\script_xeh.hpp"

// Functions live in <addon>\functions\fnc_<name>.sqf (ACE convention)
#undef PREP
#ifdef DISABLE_COMPILE_CACHE
    #define PREP(fncName) FUNC(fncName) = compile preprocessFileLineNumbers QPATHTOF(functions\DOUBLES(fnc,fncName).sqf)
#else
    #define PREP(fncName) [QPATHTOF(functions\DOUBLES(fnc,fncName).sqf), QFUNC(fncName)] call CBA_fnc_compileFunction
#endif

#define COMPONENT_NAME QUOTE(Bluetooth Speaker - COMPONENT_BEAUTIFIED)

// Wrap a function so event handlers always call the current (recompilable) version
#define LINKFUNC(fncName) {_this call FUNC(fncName)}

// Shared speaker state (object variables)
#define VAR_PLAYING "btspk_playing"
#define VAR_TRACK   "btspk_track"
#define VAR_START   "btspk_start"
#define VAR_SESSION "btspk_session"
#define VAR_SOURCE  "btspk_soundSource"
#define VAR_VOLUME  "btspk_volume"

// Volume levels 1-5 (sound classes <track>_v1 .. _v5, see tools/build_playlist.py)
#define VOLUME_DEFAULT 4
#define VOLUME_MAX     5

// Party Link: followers point at their leader; the leader lists its followers
#define VAR_LEADER    "btspk_linkLeader"
#define VAR_FOLLOWERS "btspk_linkFollowers"

// Ownership: owner's player UID ("" = unowned) and whether others are locked out
#define VAR_OWNER      "btspk_owner"
#define VAR_OWNER_NAME "btspk_ownerName"
#define VAR_LOCKED     "btspk_locked"

// Synced clock: serverTime in MP, time in SP
#define NOW ([time, serverTime] select isMultiplayer)

// Inventory form: a magazine whose rounds are battery % + 1
#define MAG_SPEAKER   "btspk_speaker_mag"
// Backpack clip: the unit points at its speaker, the speaker at its unit
#define VAR_CLIPPED    "btspk_clippedSpeaker"
#define VAR_CLIPPED_TO "btspk_clippedTo"

// Battery: [chargeAtT 0-1, T, ratePerSecond]; current = c + rate * (NOW - T)
#define VAR_BAT      "btspk_bat"
#define VAR_DEAD     "btspk_dead"
#define VAR_LOW      "btspk_low"
#define VAR_CHARGING "btspk_charging"

// Damage
#define VAR_DAMAGED "btspk_damaged"
#define VAR_BROKEN  "btspk_broken"
