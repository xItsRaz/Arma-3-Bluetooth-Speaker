#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// Where a backpack-clipped speaker sits, in spine3 bone space [x, y, z] (tune in game)
GVAR(clipOffset) = [-0.15, -0.15, 0];

#include "initSettings.inc.sqf"

ADDON = true;
