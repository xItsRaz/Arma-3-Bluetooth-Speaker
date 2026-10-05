"""Builds the JBL Speaker (Charge-style) and the JBL PartyBox as Arma 3 models.

Run with Blender 4.4 (the Arma 3 Object Builder addon v2.5.1 enabled):
    blender --background --python tools/blender/make_models.py -- <output folder> [<preview folder>]

Writes jbl_speaker.p3d and jbl_partybox.p3d to the output folder, and (optional) preview PNGs.
Sizes are in metres. Origin at the bottom centre, front facing +Y, Z up (PLAN.md section 15).

Parts and named selections (used by hiddenSelections in the config):
    JBL Speaker : camo (body + end caps), led_battery (5 LEDs), led_glow (rim rings), damage (body)
    PartyBox    : camo (body), ring_left / ring_right (woofer light rings), strobe, damage
Memory points:
    JBL Speaker : sound_source, led_light, carry, attach_back
    PartyBox    : sound_source, light_front, light_top
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = ARGS[0] if ARGS else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "addons", "speaker", "models")
PREVIEW = ARGS[1] if len(ARGS) > 1 else None

# Arma 3 Object Builder LOD types (utilities/data.py)
LOD_VISUAL, LOD_SHADOW, LOD_GEOMETRY, LOD_MEMORY = "0", "4", "6", "9"
LOD_VIEW_GEOMETRY, LOD_FIRE_GEOMETRY = "14", "15"


# ---------------------------------------------------------------- materials
MATERIALS = {}


def material(name, rgb, alpha=1.0):
    """A material whose Arma texture is a procedural colour (no texture file needed yet)."""
    if name in MATERIALS:
        return MATERIALS[name]
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*rgb, 1.0)
    props = mat.a3ob_properties_material
    props.texture_type = "COLOR"
    props.color_value = (*rgb, alpha)
    props.color_type = "CO"
    MATERIALS[name] = mat
    return mat


def palette():
    return {
        "body": material("jbl_body", (0.07, 0.08, 0.10)),        # dark fabric grille
        "rubber": material("jbl_rubber", (0.02, 0.02, 0.02)),     # end caps, foot, feet
        "plastic": material("jbl_plastic", (0.12, 0.12, 0.13)),   # panels, buttons
        "led": material("jbl_led", (0.2, 0.9, 0.3)),               # LEDs
        "glow": material("jbl_glow", (0.9, 0.9, 1.0)),             # rim / ring lights
        "speaker": material("jbl_cone", (0.03, 0.03, 0.035)),      # speaker cones
        "metal": material("jbl_metal", (0.45, 0.45, 0.48)),        # handle, tweeter
    }


# ---------------------------------------------------------------- mesh helpers
class Builder:
    """A bmesh plus the vertex groups ("named selections") its parts belong to."""

    def __init__(self, name, mats):
        self.name = name
        self.bm = bmesh.new()
        self.mats = list(mats.values())
        self.mat_index = {key: i for i, key in enumerate(mats)}
        self.groups = {}

    def box(self, size, center, groups=(), material_key=None, bevel=0.0, smooth=False):
        res = bmesh.ops.create_cube(self.bm, size=1.0)
        verts = res["verts"]
        bmesh.ops.scale(self.bm, verts=verts, vec=Vector(size), space=Matrix.Identity(4))
        bmesh.ops.translate(self.bm, verts=verts, vec=Vector(center))
        if bevel > 0:
            edges = list({e for v in verts for e in v.link_edges})
            before = set(self.bm.faces)
            bmesh.ops.bevel(self.bm, geom=edges, offset=bevel, segments=2, affect="EDGES")
            # the bevel replaces the corner vertices: take them from the faces it created
            verts = list({v for f in self.bm.faces if f not in before for v in f.verts})
        return self._register(verts, groups, material_key, smooth)

    def cylinder(self, radius, length, center, axis="Z", segments=24, groups=(), material_key=None,
                 radius2=None, smooth=True):
        res = bmesh.ops.create_cone(self.bm, cap_ends=True, cap_tris=False, segments=segments,
                                    radius1=radius, radius2=radius if radius2 is None else radius2, depth=length)
        verts = res["verts"]
        # create_cone is along Z: turn it to the wanted axis
        if axis == "X":
            bmesh.ops.rotate(self.bm, verts=verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(90), 3, "Y"))
        elif axis == "Y":
            bmesh.ops.rotate(self.bm, verts=verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(90), 3, "X"))
        bmesh.ops.translate(self.bm, verts=verts, vec=Vector(center))
        return self._register(verts, groups, material_key, smooth)

    def ring(self, outer, inner, length, center, axis="Y", segments=32, groups=(), material_key=None):
        """A flat ring: a cylinder with a smaller one cut out (built from two cylinders joined by faces)."""
        outer_res = bmesh.ops.create_cone(self.bm, cap_ends=False, segments=segments, radius1=outer, radius2=outer, depth=length)
        inner_res = bmesh.ops.create_cone(self.bm, cap_ends=False, segments=segments, radius1=inner, radius2=inner, depth=length)
        outer_v = sorted(outer_res["verts"], key=lambda v: (v.co.z > 0, math.atan2(v.co.y, v.co.x)))
        inner_v = sorted(inner_res["verts"], key=lambda v: (v.co.z > 0, math.atan2(v.co.y, v.co.x)))
        # caps between outer and inner at the top and bottom
        for level in (0, 1):
            o = outer_v[level * segments:(level + 1) * segments]
            i = inner_v[level * segments:(level + 1) * segments]
            for k in range(segments):
                n = (k + 1) % segments
                self.bm.faces.new((o[k], o[n], i[n], i[k]))
        verts = outer_res["verts"] + inner_res["verts"]
        if axis == "X":
            bmesh.ops.rotate(self.bm, verts=verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(90), 3, "Y"))
        elif axis == "Y":
            bmesh.ops.rotate(self.bm, verts=verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(90), 3, "X"))
        bmesh.ops.translate(self.bm, verts=verts, vec=Vector(center))
        return self._register(verts, groups, material_key, True)

    def _register(self, verts, groups, material_key, smooth):
        for name in groups:
            self.groups.setdefault(name, set()).update(verts)
        faces = {f for v in verts for f in v.link_faces}
        for f in faces:
            if material_key is not None:
                f.material_index = self.mat_index[material_key]
            f.smooth = smooth
        return verts

    def finish(self, lod, resolution, name_suffix, collection, with_materials=True):
        """Turns the bmesh into an Arma LOD object."""
        bm = self.bm
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bmesh.ops.triangulate(bm, faces=bm.faces[:])  # Arma has no n-gons
        # a UV map (Arma needs one; the colours are procedural so a simple projection is enough)
        uv = bm.loops.layers.uv.verify()
        for face in bm.faces:
            for loop in face.loops:
                loop[uv].uv = (loop.vert.co.x * 2.0 + 0.5, loop.vert.co.z * 2.0 + 0.5)
        mesh = bpy.data.meshes.new(f"{self.name}_{name_suffix}")
        deform = bm.verts.layers.deform.verify()
        obj = bpy.data.objects.new(f"{self.name}_{name_suffix}", mesh)
        collection.objects.link(obj)
        group_index = {}
        for name in self.groups:
            group_index[name] = obj.vertex_groups.new(name=name).index
        for name, verts in self.groups.items():
            for v in verts:
                if v.is_valid:
                    v[deform][group_index[name]] = 1.0
        bm.to_mesh(mesh)
        bm.free()
        for mat in (self.mats if with_materials else []):  # a shadow volume must have no materials
            mesh.materials.append(mat)
        props = obj.a3ob_properties_object
        props.is_a3_lod = True
        props.lod = lod
        props.resolution = resolution
        return obj


def set_mass(obj, kilograms):
    """Distributes the total mass over the vertices (the Geometry LOD carries the object's mass)."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    layer = bm.verts.layers.float.get("a3ob_mass") or bm.verts.layers.float.new("a3ob_mass")
    for v in bm.verts:
        v[layer] = kilograms / len(bm.verts)
    bm.to_mesh(obj.data)
    bm.free()


def memory_lod(name, points, collection):
    """The Memory LOD: loose vertices, each in a vertex group named after the point."""
    mesh = bpy.data.meshes.new(f"{name}_memory")
    obj = bpy.data.objects.new(f"{name}_memory", mesh)
    collection.objects.link(obj)
    mesh.from_pydata([p for p in points.values()], [], [])
    for index, point in enumerate(points):
        group = obj.vertex_groups.new(name=point)
        group.add([index], 1.0, "REPLACE")
    props = obj.a3ob_properties_object
    props.is_a3_lod = True
    props.lod = LOD_MEMORY
    props.resolution = 0
    return obj


# ---------------------------------------------------------------- the JBL Speaker (Charge-style)
LENGTH = 0.223        # JBL Charge 5: 223 x 96.5 x 94 mm
RADIUS = 0.0475


def speaker_visual(mats, segments, detail):
    b = Builder("jbl_speaker", mats)
    centre_z = RADIUS
    body_len = 0.187
    cap_len = (LENGTH - body_len) / 2
    # fabric body, along X
    b.cylinder(RADIUS, body_len, (0, 0, centre_z), "X", segments, ("camo", "damage"), "body")
    for side in (-1, 1):
        x = side * (body_len / 2 + cap_len / 2)
        # rubber end cap with the passive radiator rim
        b.cylinder(RADIUS * 0.995, cap_len, (x, 0, centre_z), "X", segments, ("camo",), "rubber")
        x_end = side * (LENGTH / 2)
        if detail >= 1:
            b.ring(0.041, 0.034, 0.003, (x_end + side * 0.0005, 0, centre_z), "X", segments, ("led_glow",), "glow")
            b.cylinder(0.034, 0.002, (x_end - side * 0.001, 0, centre_z), "X", segments, ("camo",), "speaker")
    # flat rubber foot so it does not roll
    b.box((0.19, 0.045, 0.012), (0, 0, 0.006), ("camo",), "rubber")
    if detail >= 1:
        # button strip on top: power, bluetooth, play, minus, plus, PartyBoost
        b.box((0.075, 0.022, 0.004), (0, 0, centre_z + RADIUS + 0.0005), (), "plastic")
        for i in range(6):
            b.cylinder(0.0035, 0.003, (-0.03 + i * 0.012, 0, centre_z + RADIUS + 0.0035), "Z", 8, (), "metal")
        # battery LED bar: 5 dots on the lower front
        angle = math.radians(35)
        for i in range(5):
            y = RADIUS * math.cos(angle) + 0.0005
            z = centre_z - RADIUS * math.sin(angle)
            b.box((0.007, 0.003, 0.004), (-0.02 + i * 0.01, y, z), ("led_battery",), "led")
        # plain badge area on the front (no logo)
        b.box((0.045, 0.002, 0.012), (0, RADIUS + 0.0005, centre_z + 0.01), (), "plastic")
    return b


def speaker_geometry(mats):
    b = Builder("jbl_speaker", mats)
    b.cylinder(RADIUS, LENGTH, (0, 0, RADIUS), "X", 12, ("component01",), None, smooth=False)
    return b


def speaker_shadow(mats):
    b = Builder("jbl_speaker", mats)
    b.cylinder(RADIUS, LENGTH, (0, 0, RADIUS), "X", 10, (), None, smooth=False)
    return b


def make_speaker(collection):
    mats = palette()
    visuals = []
    for resolution, (segments, detail) in enumerate([(24, 1), (14, 1), (8, 0), (6, 0)], start=1):
        visuals.append(speaker_visual(mats, segments, detail).finish(LOD_VISUAL, resolution, f"res{resolution}", collection))
    geometry = speaker_geometry(mats).finish(LOD_GEOMETRY, 0, "geometry", collection)
    set_mass(geometry, 1.0)  # about 1 kg
    speaker_geometry(mats).finish(LOD_FIRE_GEOMETRY, 0, "fire", collection)
    speaker_geometry(mats).finish(LOD_VIEW_GEOMETRY, 0, "view", collection)
    speaker_shadow(mats).finish(LOD_SHADOW, 0, "shadow", collection, with_materials=False)
    memory_lod("jbl_speaker", {
        "sound_source": (0, 0, RADIUS),
        "led_light": (0, RADIUS, 0.02),
        "carry": (0, 0, RADIUS * 2),
        "attach_back": (0, -RADIUS, RADIUS),
    }, collection)
    return visuals


# ---------------------------------------------------------------- the PartyBox (110 class)
BOX_W, BOX_D, BOX_H = 0.292, 0.282, 0.568   # upright, front faces +Y


def partybox_visual(mats, segments, detail):
    b = Builder("jbl_partybox", mats)
    foot = 0.012
    body_h = BOX_H - foot
    b.box((BOX_W, BOX_D, body_h), (0, 0, foot + body_h / 2), ("camo", "damage"), "body", bevel=0.012 if detail else 0.0)
    front = BOX_D / 2
    # two woofers behind a dark mesh, each in a lit ring
    for z, ring_name in ((0.17, "ring_left"), (0.39, "ring_right")):
        b.cylinder(0.092, 0.012, (0, front + 0.001, z), "Y", segments, (), "speaker")
        if detail:
            b.ring(0.108, 0.096, 0.008, (0, front + 0.004, z), "Y", segments, (ring_name,), "glow")
    # tweeter and strobe on the top front
    b.cylinder(0.03, 0.01, (0, front + 0.001, 0.515), "Y", max(segments // 2, 8), (), "metal")
    if detail:
        b.box((0.09, 0.006, 0.014), (0, front + 0.003, 0.548), ("strobe",), "glow")
        # top control panel and carry handle
        b.box((0.2, 0.07, 0.004), (0, -0.04, BOX_H + 0.002), (), "plastic")
        b.box((0.02, 0.03, 0.03), (-0.07, 0.04, BOX_H + 0.015), (), "plastic")
        b.box((0.02, 0.03, 0.03), (0.07, 0.04, BOX_H + 0.015), (), "plastic")
        b.box((0.16, 0.03, 0.016), (0, 0.04, BOX_H + 0.038), (), "metal")
    # four rubber feet
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.cylinder(0.02, foot, (sx * 0.11, sy * 0.10, foot / 2), "Z", max(segments // 2, 8), (), "rubber")
    return b


def partybox_geometry(mats):
    b = Builder("jbl_partybox", mats)
    b.box((BOX_W, BOX_D, BOX_H), (0, 0, BOX_H / 2), ("component01",), None)
    return b


def make_partybox(collection):
    mats = palette()
    visuals = []
    for resolution, (segments, detail) in enumerate([(32, 1), (20, 1), (12, 0), (8, 0)], start=1):
        visuals.append(partybox_visual(mats, segments, detail).finish(LOD_VISUAL, resolution, f"res{resolution}", collection))
    geometry = partybox_geometry(mats).finish(LOD_GEOMETRY, 0, "geometry", collection)
    set_mass(geometry, 11.0)  # about 11 kg (unverified real weight)
    partybox_geometry(mats).finish(LOD_FIRE_GEOMETRY, 0, "fire", collection)
    partybox_geometry(mats).finish(LOD_VIEW_GEOMETRY, 0, "view", collection)
    partybox_geometry(mats).finish(LOD_SHADOW, 0, "shadow", collection, with_materials=False)
    memory_lod("jbl_partybox", {
        "sound_source": (0, 0, BOX_H / 2),
        "light_front": (0, BOX_D / 2, 0.28),
        "light_top": (0, 0, BOX_H),
        "carry": (0, 0, BOX_H),
    }, collection)
    return visuals


# ---------------------------------------------------------------- export + preview
def reset_scene():
    """Empties the scene by hand (a factory reset would also switch the Arma addon off)."""
    for collection in (bpy.data.objects, bpy.data.collections, bpy.data.meshes, bpy.data.materials,
                       bpy.data.cameras, bpy.data.lights, bpy.data.worlds):
        for item in list(collection):
            collection.remove(item)
    MATERIALS.clear()


def validate(collection):
    """Runs the addon's own LOD validation and prints what it complains about."""
    import importlib
    base = next(name for name in sys.modules if name.endswith("Arma3ObjectBuilder") and "bl_ext" in name)
    validator_module = importlib.import_module(base + ".utilities.validator")
    logger_module = importlib.import_module(base + ".utilities.logger")
    validator = validator_module.Validator(logger_module.ProcessLogger())
    validator.setup_lod_specific()
    for obj in collection.objects:
        lod = obj.a3ob_properties_object.lod
        ok = validator.validate_lod(obj, lod, False, False, True)
        print("VALIDATE", obj.name, "OK" if ok else "FAILED")


def export(collection, path):
    validate(collection)
    for obj in bpy.context.scene.objects:
        obj.select_set(False)
    for obj in collection.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = collection.objects[0]
    result = bpy.ops.a3ob.export_p3d(
        filepath=path, use_selection=False, visible_only=True, apply_transforms=True, apply_modifiers=True,
        validate_lods=True, validate_lods_warning_errors=False, lod_collisions="IGNORE", relative_paths=True,
        force_lowercase=True, renumber_components=True, generate_components=True,
    )
    print("EXPORT", path, result, os.path.exists(path) and os.path.getsize(path))


def preview(visual, path_prefix, size):
    """Workbench renders from three angles, with a 10 cm grid cube next to it for scale."""
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.render.resolution_x, scene.render.resolution_y = 900, 600
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.world = bpy.data.worlds.new("w")
    scene.world.color = (0.55, 0.6, 0.65)
    # hide every LOD but the first visual one
    for obj in scene.objects:
        obj.hide_render = obj is not visual
    # a 10 cm reference cube beside the model
    ref = bpy.data.objects.new("ref", bpy.data.meshes.new("ref"))
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=0.1)
    bm.to_mesh(ref.data)
    bm.free()
    ref.location = (size * 0.9, 0, 0.05)
    scene.collection.objects.link(ref)
    ground = bpy.data.objects.new("ground", bpy.data.meshes.new("ground"))
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=2.0)
    bm.to_mesh(ground.data)
    bm.free()
    scene.collection.objects.link(ground)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    centre = Vector((size * 0.3, 0, size * 0.45))
    for name, (azimuth, elevation) in {"front34": (-35, 22), "side": (-90, 8), "top": (-10, 70)}.items():
        distance = size * 3.2
        a, e = math.radians(azimuth), math.radians(elevation)
        cam.location = centre + Vector((math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e))) * distance  # the front faces +Y
        direction = centre - cam.location
        cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = f"{path_prefix}_{name}.png"
        bpy.ops.render.render(write_still=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, maker, size in (("jbl_speaker", make_speaker, 0.223), ("jbl_partybox", make_partybox, 0.568)):
        reset_scene()
        collection = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(collection)
        visuals = maker(collection)
        export(collection, os.path.join(OUT, f"{name}.p3d"))
        if PREVIEW:
            os.makedirs(PREVIEW, exist_ok=True)
            preview(visuals[0], os.path.join(PREVIEW, name), size)


main()
