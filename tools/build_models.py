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


if __name__ == "__main__":
    build_research_hut()
    build_green_glass_bottle()
    build_crumpled_paper()
    build_plastic_bottle()
    build_pine_tree()
    build_rock_formation()
    build_mountain_bg()
    build_iceberg_bg()
    print("ALL BLENDER MODELS BUILT AND EXPORTED SUCCESSFULLY.")
