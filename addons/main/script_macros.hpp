#include "\x\cba\addons\main\script_macros_common.hpp"
#include "\x\cba\addons\xeh\script_xeh.hpp"

// Functions live in <addon>\functions\fnc_<name>.sqf (ACE convention)
#undef PREP
#ifdef DISABLE_COMPILE_CACHE
    #define PREP(fncName) FUNC(fncName) = compile preprocessFileLineNumbers QPATHTOF(functions\DOUBLES(fnc,fncName).sqf)
#else
    #define PREP(fncName) [QPATHTOF(functions\DOUBLES(fnc,fncName).sqf), QFUNC(fncName)] call CBA_fnc_compileFunction
#endif

#define COMPONENT_NAME QUOTE(JBL Speaker - COMPONENT_BEAUTIFIED)

// Wrap a function so event handlers always call the current (recompilable) version
#define LINKFUNC(fncName) {_this call FUNC(fncName)}

// Shared speaker state (object variables)
#define VAR_PLAYING "jbl_playing"
#define VAR_TRACK   "jbl_track"
#define VAR_START   "jbl_start"
#define VAR_SESSION "jbl_session"
#define VAR_SOURCE  "jbl_soundSource"
#define VAR_VOLUME  "jbl_volume"

// Volume levels 1-5 (sound classes <track>_v1 .. _v5, see tools/build_playlist.py)
#define VOLUME_DEFAULT 4
#define VOLUME_MAX     5

// PartyBoost: followers point at their leader; the leader lists its followers
#define VAR_LEADER    "jbl_linkLeader"
#define VAR_FOLLOWERS "jbl_linkFollowers"

// Ownership: owner's player UID ("" = unowned) and whether others are locked out
#define VAR_OWNER      "jbl_owner"
#define VAR_OWNER_NAME "jbl_ownerName"
#define VAR_LOCKED     "jbl_locked"

// Synced clock: serverTime in MP, time in SP
#define NOW ([time, serverTime] select isMultiplayer)

// Inventory form: a magazine whose rounds are battery % + 1
#define MAG_SPEAKER   "jbl_speaker_mag"
// Backpack clip: the unit points at its speaker, the speaker at its unit
#define VAR_CLIPPED    "jbl_clippedSpeaker"
#define VAR_CLIPPED_TO "jbl_clippedTo"

// Battery: [chargeAtT 0-1, T, ratePerSecond]; current = c + rate * (NOW - T)
#define VAR_BAT      "jbl_bat"
#define VAR_DEAD     "jbl_dead"
#define VAR_LOW      "jbl_low"
#define VAR_CHARGING "jbl_charging"

// Damage
#define VAR_DAMAGED "jbl_damaged"
#define VAR_BROKEN  "jbl_broken"
