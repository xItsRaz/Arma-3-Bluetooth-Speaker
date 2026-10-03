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

// Shared speaker state (object variables, see PLAN.md 16.2)
#define VAR_PLAYING "jbl_playing"
#define VAR_TRACK   "jbl_track"
#define VAR_START   "jbl_start"
#define VAR_SESSION "jbl_session"
#define VAR_SOURCE  "jbl_soundSource"

// PartyBoost: followers point at their leader; the leader lists its followers
#define VAR_LEADER    "jbl_linkLeader"
#define VAR_FOLLOWERS "jbl_linkFollowers"
#define LINK_RADIUS   15
#define LINK_MAX      8

// Synced clock: serverTime in MP, time in SP
#define NOW ([time, serverTime] select isMultiplayer)
