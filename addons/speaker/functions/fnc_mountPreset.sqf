#include "..\script_component.hpp"
/*
 * Author: Raz
 * Where a speaker sits for a named mounting position.
 *
 * On a person (offset is in the spine3 bone space, tune in game with "Adjust position"):
 *   "back" (on the backpack), "side" (at the hip), "under" (under the backpack)
 * On a vehicle (offset from the vehicle's centre, from its bounding box):
 *   "roof", "rear", "front"
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: What it is mounted on <OBJECT>
 * 2: Position name <STRING>
 *
 * Return Value:
 * [offset <ARRAY>, turn in degrees <NUMBER>, bone <STRING> ("" on vehicles)]
 */

params ["_speaker", "_parent", "_preset"];

private _party = _speaker isKindOf "jbl_partybox";

if (_parent isKindOf "CAManBase") exitWith {
    // [name, offset, turn]; the PartyBox is bigger, so it sits further out
    private _table = [
        [["back", [-0.15, -0.15, 0], 0], ["side", [0.22, -0.05, -0.15], 90], ["under", [-0.10, -0.18, -0.38], 0]],
        [["back", [-0.25, -0.32, 0], 0], ["side", [0.30, -0.10, -0.12], 90], ["under", [-0.25, -0.30, -0.40], 0]]
    ] select _party;
    private _entry = _table select ((_table findIf {(_x select 0) == _preset}) max 0);
    [_entry select 1, _entry select 2, "spine3"]
};

private _box = boundingBoxReal _parent;
(_box select 0) params ["_minX", "_minY", "_minZ"];
(_box select 1) params ["_maxX", "_maxY", "_maxZ"];

switch (_preset) do {
    case "rear": { [[0, _minY - 0.2, _minZ + 0.8], 180, ""] };
    case "front": { [[0, _maxY - 0.8, _minZ + 1.0], 0, ""] };
    default { [[0, 0, _maxZ + 0.05], 0, ""] }; // roof
}
