"""Builds and exports clean low-poly 3D models in Blender for Higher Ground."""
import bpy
import bmesh
import math
import os
import random

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART_DIR = os.path.join(ROOT_DIR, "art_source")
MODELS_DIR = os.path.join(ROOT_DIR, "assets", "models")


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def make_mat(name, hex_color, roughness=0.55, metallic=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    h = hex_color.lstrip("#")
    r, g, b = tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    r, g, b = r ** 2.2, g ** 2.2, b ** 2.2
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (r, g, b, 1.0)
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = metallic
    return mat


def finalize_and_export(obj_name, blend_name, glb_rel_path):
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for m in meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = obj_name
    obj.data.name = obj_name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.location = (0.0, 0.0, 0.0)

    blend_path = os.path.join(ART_DIR, blend_name)
    glb_path = os.path.join(MODELS_DIR, glb_rel_path)
    os.makedirs(os.path.dirname(glb_path), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format='GLB',
        use_selection=True,
        export_apply=True,
        export_lights=False,
        export_cameras=False
    )
    zs = [v.co.z for v in obj.data.vertices]
    print(f"Exported {glb_rel_path}: verts={len(obj.data.vertices)}, Z=[{min(zs):.2f}, {max(zs):.2f}]")


def build_research_hut():
    clear_scene()
    mat_stone = make_mat("mat_stone", "5A6978", 0.9)
    mat_wood = make_mat("mat_wood", "8B5A3C", 0.75)
    mat_dark_wood = make_mat("mat_dark_wood", "4A2C1D", 0.85)
    mat_roof = make_mat("mat_roof", "2C3E50", 0.7)
    mat_snow = make_mat("mat_snow", "EAF2F8", 0.8)
    mat_window = make_mat("mat_window", "FFD166", 0.15)
    mat_frame = make_mat("mat_frame", "1B2430", 0.6)
    mat_door = make_mat("mat_door", "D64045", 0.5)

    # Foundation base (z=-0.4 to z=0.35 so it sits solidly into summit snow)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, -0.025))
    found = bpy.context.active_object
    found.scale = (4.2, 3.0, 0.75)
    found.data.materials.append(mat_stone)

    # Front wooden deck + step facing camera (+Y in Blender maps to -Z in Godot, so build symmetrical on both +Y and -Y!)
    for side in (-1.0, 1.0):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.55, side * 1.6, 0.16))
        porch = bpy.context.active_object
        porch.scale = (2.1, 0.6, 0.25)
        porch.data.materials.append(mat_dark_wood)

        # Door frame & red insulated door
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.55, side * 1.26, 1.22))
        df = bpy.context.active_object
        df.scale = (0.95, 0.12, 1.75)
        df.data.materials.append(mat_frame)

        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.55, side * 1.29, 1.20))
        door = bpy.context.active_object
        door.scale = (0.78, 0.10, 1.62)
        door.data.materials.append(mat_door)

        # Glowing window with cross frame
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.85, side * 1.26, 1.52))
        wf = bpy.context.active_object
        wf.scale = (1.1, 0.12, 0.95)
        wf.data.materials.append(mat_frame)

        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.85, side * 1.29, 1.52))
        wg = bpy.context.active_object
        wg.scale = (0.90, 0.10, 0.76)
        wg.data.materials.append(mat_window)

    # Main wooden cabin walls (z=0.35 to z=2.5)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 1.42))
    walls = bpy.context.active_object
    walls.scale = (3.8, 2.5, 2.15)
    walls.data.materials.append(mat_wood)

    # Corner log pillars
    for cx in (-1.9, 1.9):
        for cy in (-1.25, 1.25):
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(cx, cy, 1.42))
            post = bpy.context.active_object
            post.scale = (0.2, 0.2, 2.2)
            post.data.materials.append(mat_dark_wood)

    # Proper pitched gable roof slopes
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, -0.78, 2.92))
    rf = bpy.context.active_object
    rf.scale = (4.4, 1.95, 0.18)
    rf.rotation_euler = (math.radians(32), 0.0, 0.0)
    rf.data.materials.append(mat_roof)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.78, 2.92))
    rb = bpy.context.active_object
    rb.scale = (4.4, 1.95, 0.18)
    rb.rotation_euler = (math.radians(-32), 0.0, 0.0)
    rb.data.materials.append(mat_roof)

    # Snow blanket on roof
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, -0.75, 3.05))
    sf = bpy.context.active_object
    sf.scale = (4.3, 1.85, 0.14)
    sf.rotation_euler = (math.radians(32), 0.0, 0.0)
    sf.data.materials.append(mat_snow)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.75, 3.05))
    sb = bpy.context.active_object
    sb.scale = (4.3, 1.85, 0.14)
    sb.rotation_euler = (math.radians(-32), 0.0, 0.0)
    sb.data.materials.append(mat_snow)

    # Gable filler under ridge
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 2.75))
    gf = bpy.context.active_object
    gf.scale = (3.75, 1.35, 0.65)
    gf.data.materials.append(mat_wood)

    # Snow ridge cap
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 3.42))
    ridge = bpy.context.active_object
    ridge.scale = (4.45, 0.32, 0.22)
    ridge.data.materials.append(mat_snow)

    # Chimney
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.35, 0.45, 3.25))
    chimney = bpy.context.active_object
    chimney.scale = (0.55, 0.55, 1.5)
    chimney.data.materials.append(mat_stone)

    finalize_and_export("research_hut", "research_hut.blend", "environment/research_hut.glb")


def build_green_glass_bottle():
    """Green glass bottle (litter_jar.glb) for glass recycling."""
    clear_scene()
    mat_green = make_mat("mat_green_glass", "1E9E52", 0.18, 0.1)
    mat_dark_green = make_mat("mat_dark_green", "146B38", 0.2, 0.1)
    mat_label = make_mat("mat_label", "F7F1E3", 0.7, 0.0)

    # Main cylindrical body
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.14, depth=0.34, location=(0.0, 0.0, 0.17))
    body = bpy.context.active_object
    body.data.materials.append(mat_green)

    # Cream paper label around middle
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.146, depth=0.14, location=(0.0, 0.0, 0.17))
    label = bpy.context.active_object
    label.data.materials.append(mat_label)

    # Tapered shoulder (cone)
    bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.14, radius2=0.055, depth=0.14, location=(0.0, 0.0, 0.41))
    shoulder = bpy.context.active_object
    shoulder.data.materials.append(mat_green)

    # Bottle neck
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.052, depth=0.15, location=(0.0, 0.0, 0.55))
    neck = bpy.context.active_object
    neck.data.materials.append(mat_green)

    # Lip ring at top
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.064, depth=0.03, location=(0.0, 0.0, 0.62))
    lip = bpy.context.active_object
    lip.data.materials.append(mat_dark_green)

    # Join and tilt slightly for visual flair
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for m in meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    body.rotation_euler = (0.0, math.radians(14), 0.0)

    finalize_and_export("litter_jar", "litter_jar.blend", "litter/litter_jar.glb")


def build_crumpled_paper():
    """Crumpled paper ball + folded sheet (litter_box.glb) for paper recycling."""
    clear_scene()
    mat_paper = make_mat("mat_paper_white", "F2F6FA", 0.85, 0.0)
    mat_blue = make_mat("mat_paper_blue", "2980B9", 0.75, 0.0)
    mat_crease = make_mat("mat_paper_crease", "CBD6E2", 0.9, 0.0)

    # Main crumpled paper wad (low-poly icosphere with displaced vertices)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.22, location=(0.0, 0.0, 0.22))
    wad = bpy.context.active_object
    wad.data.materials.append(mat_paper)
    wad.data.materials.append(mat_blue)
    wad.data.materials.append(mat_crease)

    rng = random.Random(77)
    for i, v in enumerate(wad.data.vertices):
        factor = rng.uniform(0.74, 1.24)
        v.co.x *= factor
        v.co.y *= rng.uniform(0.76, 1.22)
        v.co.z *= rng.uniform(0.78, 1.20)

    for i, poly in enumerate(wad.data.polygons):
        if i % 5 == 0:
            poly.material_index = 1  # Blue ink/stripe on paper
        elif i % 3 == 0:
            poly.material_index = 2  # Shadowed crease

    # Add a protruding folded paper corner flap so it's super recognizable
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.08, -0.05, 0.34))
    flap = bpy.context.active_object
    flap.scale = (0.22, 0.18, 0.04)
    flap.rotation_euler = (math.radians(28), math.radians(-22), math.radians(15))
    flap.data.materials.append(mat_blue)

    finalize_and_export("litter_box", "litter_box.blend", "litter/litter_box.glb")


def build_plastic_bottle():
    """Crushed plastic water bottle with red cap (litter_bottle.glb) for plastic recycling."""
    clear_scene()
    mat_plastic = make_mat("mat_plastic_body", "F4D03F", 0.25, 0.05)
    mat_label = make_mat("mat_plastic_label", "E67E22", 0.4, 0.0)
    mat_cap = make_mat("mat_plastic_cap", "E74C3C", 0.3, 0.0)

    # Lower half of plastic bottle
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.13, depth=0.18, location=(0.0, 0.0, 0.09))
    bot = bpy.context.active_object
    bot.data.materials.append(mat_plastic)

    # Pinched / crushed waist in middle
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.095, depth=0.10, location=(0.02, 0.0, 0.22))
    waist = bpy.context.active_object
    waist.scale = (1.15, 0.75, 1.0)
    waist.rotation_euler = (0.0, math.radians(-8), 0.0)
    waist.data.materials.append(mat_label)

    # Upper half of bottle
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.125, depth=0.15, location=(0.0, 0.0, 0.33))
    top_body = bpy.context.active_object
    top_body.data.materials.append(mat_plastic)

    # Tapered cone top
    bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=0.125, radius2=0.048, depth=0.11, location=(0.0, 0.0, 0.46))
    cone = bpy.context.active_object
    cone.data.materials.append(mat_plastic)

    # Bright red plastic bottle cap
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.055, depth=0.055, location=(0.0, 0.0, 0.54))
    cap = bpy.context.active_object
    cap.data.materials.append(mat_cap)

    # Join and tilt slightly
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for m in meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = bot
    bpy.ops.object.join()
    bot.rotation_euler = (0.0, math.radians(-12), 0.0)

    finalize_and_export("litter_bottle", "litter_bottle.blend", "litter/litter_bottle.glb")


def build_pine_tree():
    """Grounded pine tree with trunk extending to z=-0.35 so it never floats on slopes."""
    clear_scene()
    mat_trunk = make_mat("mat_trunk", "5C3A21", 0.9)
    mat_foliage = make_mat("mat_foliage", "2D5A3C", 0.75)
    mat_snow = make_mat("mat_snow", "EAF2F8", 0.8)

    # Trunk extends from z=-0.35 up to z=0.8
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.18, depth=1.15, location=(0.0, 0.0, 0.225))
    trunk = bpy.context.active_object
    trunk.data.materials.append(mat_trunk)

    # Three foliage tiers
    tiers = [
        (0.0, 0.0, 1.05, 0.85, 0.15, 1.0),
        (0.0, 0.0, 1.65, 0.68, 0.12, 0.9),
        (0.0, 0.0, 2.20, 0.48, 0.04, 0.8),
    ]
    for x, y, z, r1, r2, h in tiers:
        bpy.ops.mesh.primitive_cone_add(vertices=7, radius1=r1, radius2=r2, depth=h, location=(x, y, z))
        c = bpy.context.active_object
        c.data.materials.append(mat_foliage)

    # Snow cap on top tier
    bpy.ops.mesh.primitive_cone_add(vertices=7, radius1=0.32, radius2=0.02, depth=0.45, location=(0.0, 0.0, 2.42))
    cap = bpy.context.active_object
    cap.data.materials.append(mat_snow)

    finalize_and_export("pine_tree", "pine_tree.blend", "environment/pine_tree.glb")


def build_rock_formation():
    """Grounded rock formation extending down to z=-0.4 so it never floats."""
    clear_scene()
    mat_rock = make_mat("mat_rock", "5C6B7A", 0.9)
    mat_snow = make_mat("mat_snow", "EAF2F8", 0.8)

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1.1, location=(0.0, 0.0, 0.45))
    r1 = bpy.context.active_object
    r1.scale = (1.3, 0.9, 0.85)
    r1.data.materials.append(mat_rock)

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.75, location=(0.75, -0.15, 0.25))
    r2 = bpy.context.active_object
    r2.scale = (1.1, 0.85, 0.75)
    r2.data.materials.append(mat_rock)

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.65, location=(-0.7, 0.1, 0.2))
    r3 = bpy.context.active_object
    r3.scale = (1.0, 0.8, 0.7)
    r3.data.materials.append(mat_rock)

    # Snow cap on main boulder
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.78, location=(0.0, 0.0, 0.88))
    s1 = bpy.context.active_object
    s1.scale = (1.15, 0.8, 0.42)
    s1.data.materials.append(mat_snow)

    finalize_and_export("rock_formation", "rock_formation.blend", "environment/rock_formation.glb")


def build_mountain_bg():
    """Mountain range with deep skirt (-8m) and pine trees sitting directly on its lower slopes!"""
    clear_scene()
    mat_rock = make_mat("mat_mountain_rock", "4A5868", 0.92)
    mat_snow = make_mat("mat_mountain_snow", "E6F0F8", 0.82)
    mat_trunk = make_mat("mat_trunk", "5C3A21", 0.9)
    mat_foliage = make_mat("mat_foliage", "2D5A3C", 0.75)

    # Deep base skirt from z=-8.0 to z=0.5 so mountain NEVER floats in the air
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, -3.75))
    skirt = bpy.context.active_object
    skirt.scale = (24.0, 9.0, 8.5)
    skirt.data.materials.append(mat_rock)

    # Three main mountain peaks rising from z=-2.0 up to z=11.0
    peaks = [
        (-5.5, 0.0, 3.5, 6.5, 4.5, 11.0),
        (0.5, 0.6, 4.8, 7.8, 5.2, 13.5),
        (6.2, -0.3, 3.0, 6.0, 4.2, 10.0),
    ]
    for px, py, pz, rx, ry, h in peaks:
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=rx, radius2=0.3, depth=h, location=(px, py, pz))
        p = bpy.context.active_object
        p.scale = (1.0, ry / rx, 1.0)
        p.data.materials.append(mat_rock)

        # Snow cap on top 40% of peak
        cap_h = h * 0.42
        cap_z = pz + (h * 0.5) - (cap_h * 0.5) + 0.08
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=rx * 0.45, radius2=0.32, depth=cap_h, location=(px, py, cap_z))
        sc = bpy.context.active_object
        sc.scale = (1.02, (ry / rx) * 1.02, 1.0)
        sc.data.materials.append(mat_snow)

    # Add pine trees directly rooted onto the mountain's lower/mid rocky slopes!
    tree_spots = [
        (-7.2, -2.2, 0.2, 0.8),
        (-3.8, -2.5, 0.8, 0.9),
        (-1.2, -2.8, 1.4, 0.85),
        (2.5, -2.6, 1.1, 0.95),
        (5.0, -2.3, 0.5, 0.8),
        (7.8, -2.1, 0.1, 0.75),
    ]
    for tx, ty, tz, s in tree_spots:
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.15 * s, depth=1.0 * s, location=(tx, ty, tz + 0.3 * s))
        tr = bpy.context.active_object
        tr.data.materials.append(mat_trunk)

        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.75 * s, radius2=0.08 * s, depth=1.8 * s, location=(tx, ty, tz + 1.3 * s))
        fol = bpy.context.active_object
        fol.data.materials.append(mat_foliage)

    finalize_and_export("mountain_bg", "mountain_bg.blend", "environment/mountain_bg.glb")


def build_iceberg_bg():
    """Grounded iceberg with deep underwater skirt (-6m) so it never floats."""
    clear_scene()
    mat_ice = make_mat("mat_ice", "C8E6F5", 0.35)
    mat_snow = make_mat("mat_snow", "F0F7FC", 0.75)

    # Underwater / base block from z=-6.0 to z=0.5
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, -2.75))
    skirt = bpy.context.active_object
    skirt.scale = (14.0, 5.0, 6.5)
    skirt.data.materials.append(mat_ice)

    # Angular iceberg spires
    spires = [
        (-3.2, 0.0, 2.0, 4.2, 2.8, 5.5),
        (0.8, 0.3, 2.8, 5.0, 3.2, 7.0),
        (4.2, -0.2, 1.6, 3.6, 2.5, 4.5),
    ]
    for sx, sy, sz, rx, ry, h in spires:
        bpy.ops.mesh.primitive_cone_add(vertices=5, radius1=rx, radius2=0.6, depth=h, location=(sx, sy, sz))
        sp = bpy.context.active_object
        sp.scale = (1.0, ry / rx, 1.0)
        sp.data.materials.append(mat_ice)

        bpy.ops.mesh.primitive_cone_add(vertices=5, radius1=rx * 0.5, radius2=0.62, depth=h * 0.4, location=(sx, sy, sz + h * 0.31))
        cap = bpy.context.active_object
        cap.scale = (1.02, (ry / rx) * 1.02, 1.0)
        cap.data.materials.append(mat_snow)

    finalize_and_export("iceberg_bg", "iceberg_bg.blend", "environment/iceberg_bg.glb")


def build_baby_chick():
    """Adorable, high-visibility 3D baby penguin model (chick.glb) with feet at z=0.0."""
    clear_scene()
    mat_down = make_mat("mat_chick_down", "7F9EB2", 0.75)       # Soft blue-grey fluffy back
    mat_head = make_mat("mat_chick_head", "2C3E50", 0.7)        # Dark slate cap
    mat_belly = make_mat("mat_chick_belly", "FFFDF9", 0.8)      # Bright snow-white tummy/cheeks
    mat_beak = make_mat("mat_chick_beak", "FF9F1C", 0.4)        # Bright orange-gold beak & feet
    mat_eye = make_mat("mat_chick_eye", "11161B", 0.15)         # Glossy dark eyes
    mat_sparkle = make_mat("mat_chick_sparkle", "FFFFFF", 0.05) # Eye highlight
    mat_scarf = make_mat("mat_chick_scarf", "FF5964", 0.6)      # Bright coral-red winter band

    # Webbed orange feet sitting right on z=0.0..0.08
    for side in (-1.0, 1.0):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.11, location=(side * 0.04, -0.11 * side, 0.045))
        foot = bpy.context.active_object
        foot.scale = (1.35, 0.85, 0.42)
        foot.data.materials.append(mat_beak)

    # Plump fluffy body (z=0.06 to z=0.52)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.25, location=(0.0, 0.0, 0.29))
    body = bpy.context.active_object
    body.scale = (0.95, 0.92, 1.08)
    body.data.materials.append(mat_down)

    # Bright white tummy & chest patch facing camera (-Y in Blender = +Z in Godot) and -X (player side)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.22, location=(-0.05, -0.06, 0.28))
    belly = bpy.context.active_object
    belly.scale = (0.88, 0.85, 0.98)
    belly.data.materials.append(mat_belly)

    # Warm coral-red neck scarf so the chick stands out vividly against ice
    bpy.ops.mesh.primitive_torus_add(major_radius=0.19, minor_radius=0.048, location=(0.0, 0.0, 0.47))
    scarf = bpy.context.active_object
    scarf.scale = (1.0, 1.0, 0.85)
    scarf.data.materials.append(mat_scarf)

    # Cute big round head (z=0.46 to z=0.82)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.22, location=(0.0, 0.0, 0.64))
    head = bpy.context.active_object
    head.scale = (1.0, 0.98, 0.96)
    head.data.materials.append(mat_head)

    # White face cheeks facing front-left (-X, -Y)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=10, radius=0.185, location=(-0.05, -0.06, 0.62))
    face = bpy.context.active_object
    face.scale = (0.92, 0.88, 0.86)
    face.data.materials.append(mat_belly)

    # Expressive big eyes + white sparkles on front/camera side
    for ex, ey in ((-0.14, -0.15), (0.04, -0.20)):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=0.048, location=(ex, ey, 0.66))
        eye = bpy.context.active_object
        eye.data.materials.append(mat_eye)

        bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.018, location=(ex - 0.015, ey - 0.038, 0.678))
        sp = bpy.context.active_object
        sp.data.materials.append(mat_sparkle)

    # Bright orange beak pointing toward front-left (-X, -Y)
    bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=0.065, radius2=0.01, depth=0.15, location=(-0.12, -0.22, 0.61))
    beak = bpy.context.active_object
    beak.rotation_euler = (math.radians(72), 0.0, math.radians(-28))
    beak.data.materials.append(mat_beak)

    # Little flippers raised out to the sides as if waving for help!
    for side in (-1.0, 1.0):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=0.12, location=(side * 0.25, 0.02, 0.36))
        wing = bpy.context.active_object
        wing.scale = (0.35, 0.65, 1.25)
        wing.rotation_euler = (0.0, side * math.radians(-42), 0.0)
        wing.data.materials.append(mat_head)

    # Fluffy tuft on top of head
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.05, radius2=0.008, depth=0.12, location=(0.0, 0.0, 0.87))
    tuft = bpy.context.active_object
    tuft.rotation_euler = (math.radians(-12), math.radians(10), 0.0)
    tuft.data.materials.append(mat_down)

    finalize_and_export("chick", "chick.blend", "penguin/chick.glb")


def build_fact_holo_globe():
    """Climate Research Globe & Crystal Ring (fact_holo_globe.glb) for FactCard collectibles."""
    clear_scene()
    mat_gold = make_mat("mat_ring_gold", "FFB703", 0.25, 0.75)
    mat_ocean = make_mat("mat_globe_ocean", "0096C7", 0.25, 0.1)
    mat_land = make_mat("mat_globe_land", "2EC4B6", 0.45, 0.05)
    mat_ice = make_mat("mat_globe_ice", "F8FDFF", 0.3, 0.0)
    mat_crystal = make_mat("mat_globe_crystal", "48CAE4", 0.15, 0.2)

    # Lower brass capsule pedestal
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.18, depth=0.08, location=(0.0, 0.0, -0.36))
    base = bpy.context.active_object
    base.data.materials.append(mat_gold)

    # Outer golden gyroscope ring
    bpy.ops.mesh.primitive_torus_add(major_radius=0.38, minor_radius=0.036, major_segments=20, minor_segments=10, location=(0.0, 0.0, 0.0))
    ring1 = bpy.context.active_object
    ring1.rotation_euler = (math.radians(90), 0.0, math.radians(18))
    ring1.data.materials.append(mat_gold)

    # Inner tilted meridian ring
    bpy.ops.mesh.primitive_torus_add(major_radius=0.32, minor_radius=0.024, major_segments=18, minor_segments=8, location=(0.0, 0.0, 0.0))
    ring2 = bpy.context.active_object
    ring2.rotation_euler = (math.radians(65), math.radians(32), 0.0)
    ring2.data.materials.append(mat_crystal)

    # Central miniature Earth globe
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.23, location=(0.0, 0.0, 0.0))
    globe = bpy.context.active_object
    globe.data.materials.append(mat_ocean)
    globe.data.materials.append(mat_land)
    globe.data.materials.append(mat_ice)

    for i, poly in enumerate(globe.data.polygons):
        cz = poly.center.z
        if abs(cz) > 0.155:
            poly.material_index = 2  # Polar ice caps
        elif (i % 4 == 0) or (i % 7 == 0):
            poly.material_index = 1  # Green-teal continents

    # Top floating climate crystal diamond
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.09, radius2=0.0, depth=0.14, location=(0.0, 0.0, 0.50))
    top_c1 = bpy.context.active_object
    top_c1.data.materials.append(mat_crystal)

    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.09, radius2=0.0, depth=0.10, location=(0.0, 0.0, 0.40))
    top_c2 = bpy.context.active_object
    top_c2.rotation_euler = (math.radians(180), 0.0, 0.0)
    top_c2.data.materials.append(mat_crystal)

    finalize_and_export("fact_holo_globe", "fact_holo_globe.blend", "props/fact_holo_globe.glb")


def build_seed_patch():
    """Fertile soil mound ringed with stones and a golden seed pod (seed_patch.glb)."""
    clear_scene()
    mat_soil = make_mat("mat_soil", "4E342E", 0.92)
    mat_stone = make_mat("mat_stone", "78909C", 0.85)
    mat_seed = make_mat("mat_seed_gold", "FFD166", 0.3)
    mat_leaf = make_mat("mat_seed_tip", "52B788", 0.5)

    # Soil mound
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.52, depth=0.16, location=(0.0, 0.0, 0.08))
    mound = bpy.context.active_object
    mound.data.materials.append(mat_soil)

    # Ring of stones around soil
    for i in range(8):
        ang = i * (2.0 * math.pi / 8.0)
        sx = math.cos(ang) * 0.50
        sy = math.sin(ang) * 0.50
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.11, location=(sx, sy, 0.09))
        st = bpy.context.active_object
        st.scale = (1.2, 1.0, 0.75)
        st.data.materials.append(mat_stone)

    # Glowing golden seed pod resting on soil
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.12, location=(0.0, -0.05, 0.22))
    seed = bpy.context.active_object
    seed.scale = (1.35, 0.9, 0.95)
    seed.rotation_euler = (0.0, math.radians(-20), 0.0)
    seed.data.materials.append(mat_seed)

    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.05, radius2=0.01, depth=0.12, location=(0.08, -0.05, 0.30))
    tip = bpy.context.active_object
    tip.rotation_euler = (0.0, math.radians(35), 0.0)
    tip.data.materials.append(mat_leaf)

    finalize_and_export("seed_patch", "seed_patch.blend", "props/seed_patch.glb")


def build_ocean_buoy():
    """Polar ocean acoustic monitoring buoy (ocean_buoy.glb) for Level 3 ChoicePoint."""
    clear_scene()
    mat_red = make_mat("mat_buoy_red", "E63946", 0.4, 0.2)
    mat_white = make_mat("mat_buoy_white", "F1FAEE", 0.5, 0.1)
    mat_steel = make_mat("mat_buoy_steel", "457B9D", 0.35, 0.6)
    mat_beacon = make_mat("mat_buoy_beacon", "00F5D4", 0.15, 0.1)

    # Buoy base ring
    bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=0.45, depth=0.35, location=(0.0, 0.0, 0.175))
    b1 = bpy.context.active_object
    b1.data.materials.append(mat_red)

    bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=0.36, depth=0.25, location=(0.0, 0.0, 0.45))
    b2 = bpy.context.active_object
    b2.data.materials.append(mat_white)

    # Mast tower
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.07, depth=0.95, location=(0.0, 0.0, 0.95))
    mast = bpy.context.active_object
    mast.data.materials.append(mat_steel)

    # Crossbars
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 1.15))
    bar = bpy.context.active_object
    bar.scale = (0.55, 0.08, 0.08)
    bar.data.materials.append(mat_steel)

    # Top glowing sensor dome
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.14, location=(0.0, 0.0, 1.48))
    dome = bpy.context.active_object
    dome.data.materials.append(mat_beacon)

    finalize_and_export("ocean_buoy", "ocean_buoy.blend", "props/ocean_buoy.glb")


def build_weather_tower():
    """Automated mountain weather relay dish & solar station (weather_tower.glb) for Level 4 ChoicePoint."""
    clear_scene()
    mat_frame = make_mat("mat_tower_frame", "5C6B7A", 0.45, 0.5)
    mat_dish = make_mat("mat_tower_dish", "F8F9FA", 0.35, 0.2)
    mat_solar = make_mat("mat_tower_solar", "1D3557", 0.2, 0.4)
    mat_beacon = make_mat("mat_tower_beacon", "FFD166", 0.15, 0.1)

    # Heavy stone/steel base pad
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.50, depth=0.22, location=(0.0, 0.0, 0.11))
    pad = bpy.context.active_object
    pad.data.materials.append(mat_frame)

    # Central mast
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.09, depth=1.55, location=(0.0, 0.0, 0.92))
    mast = bpy.context.active_object
    mast.data.materials.append(mat_frame)

    # Solar wing panel
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.38, 0.0, 0.95))
    solar = bpy.context.active_object
    solar.scale = (0.55, 0.38, 0.05)
    solar.rotation_euler = (math.radians(25), 0.0, 0.0)
    solar.data.materials.append(mat_solar)

    # Radar / relay dish
    bpy.ops.mesh.primitive_cone_add(vertices=14, radius1=0.36, radius2=0.06, depth=0.18, location=(0.18, -0.12, 1.42))
    dish = bpy.context.active_object
    dish.rotation_euler = (math.radians(55), 0.0, math.radians(-25))
    dish.data.materials.append(mat_dish)

    # Top anemometer / beacon light
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=0.11, location=(0.0, 0.0, 1.76))
    light = bpy.context.active_object
    light.data.materials.append(mat_beacon)

    finalize_and_export("weather_tower", "weather_tower.blend", "props/weather_tower.glb")


if __name__ == "__main__":
    build_research_hut()
    build_green_glass_bottle()
    build_crumpled_paper()
    build_plastic_bottle()
    build_pine_tree()
    build_rock_formation()
    build_mountain_bg()
    build_iceberg_bg()
    build_baby_chick()
    build_fact_holo_globe()
    build_seed_patch()
    build_ocean_buoy()
    build_weather_tower()
    print("ALL BLENDER MODELS BUILT AND EXPORTED SUCCESSFULLY.")
