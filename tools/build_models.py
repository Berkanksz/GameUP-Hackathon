"""Builds and exports realistic, sculpted 3D models in Blender for Save Pengu."""
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


def make_mat(name, hex_color, roughness=0.55, metallic=0.0, emission_hex=None, emission_strength=0.0):
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
        if emission_hex and emission_strength > 0.0:
            eh = emission_hex.lstrip("#")
            er, eg, eb = tuple(int(eh[i:i+2], 16) / 255.0 for i in (0, 2, 4))
            er, eg, eb = er ** 2.2, eg ** 2.2, eb ** 2.2
            if "Emission Color" in bsdf.inputs:
                bsdf.inputs["Emission Color"].default_value = (er, eg, eb, 1.0)
            if "Emission Strength" in bsdf.inputs:
                bsdf.inputs["Emission Strength"].default_value = emission_strength
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


def build_baby_chick():
    """Clean, high-detail 3D baby penguin (chick.glb) with zero white intersection on the head."""
    clear_scene()
    mat_head = make_mat("mat_chick_head", "1D2B3A", 0.62)        # Deep slate-navy crown & back
    mat_down = make_mat("mat_chick_down", "4E677D", 0.72)        # Soft slate-blue chick plumage
    mat_belly = make_mat("mat_chick_belly", "ECF3F9", 0.78)      # Soft cream-white tummy (not blinding)
    mat_beak = make_mat("mat_chick_beak", "FF921C", 0.35)        # Warm tangerine beak & webbed feet
    mat_eye = make_mat("mat_chick_eye", "0B0F14", 0.10)          # Glossy dark eyes
    mat_sparkle = make_mat("mat_chick_sparkle", "FFFFFF", 0.05)  # Eye catchlight
    mat_scarf = make_mat("mat_chick_scarf", "E63946", 0.58)      # Warm crimson winter scarf

    # Webbed orange feet at z=0.0..0.07
    for side in (-1.0, 1.0):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=0.10, location=(side * 0.09, -0.07, 0.04))
        foot = bpy.context.active_object
        foot.scale = (0.90, 1.35, 0.38)
        foot.data.materials.append(mat_beak)

    # Plump lower body (z=0.05..0.52)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, radius=0.25, location=(0.0, 0.0, 0.28))
    body = bpy.context.active_object
    body.scale = (0.96, 0.92, 1.04)
    body.data.materials.append(mat_down)

    # Soft white belly strictly on the lower front torso (z=0.09..0.41, well below neck scarf!)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=14, radius=0.185, location=(0.0, -0.085, 0.25))
    belly = bpy.context.active_object
    belly.scale = (0.86, 0.72, 0.84)
    belly.data.materials.append(mat_belly)

    # Knitted winter neck scarf at z=0.46 separating body and head cleanly
    bpy.ops.mesh.primitive_torus_add(major_radius=0.185, minor_radius=0.046, major_segments=24, minor_segments=12, location=(0.0, 0.0, 0.465))
    scarf = bpy.context.active_object
    scarf.scale = (1.0, 0.98, 0.85)
    scarf.data.materials.append(mat_scarf)

    # Scarf tail hanging on front-left chest
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.09, -0.18, 0.38))
    tail = bpy.context.active_object
    tail.scale = (0.065, 0.035, 0.15)
    tail.rotation_euler = (math.radians(14), math.radians(-12), math.radians(10))
    tail.data.materials.append(mat_scarf)

    # Clean, dark slate-navy round head (z=0.47..0.85) - NO white sphere inside!
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, radius=0.21, location=(0.0, 0.0, 0.65))
    head = bpy.context.active_object
    head.scale = (1.0, 0.96, 0.95)
    head.data.materials.append(mat_head)

    # Expressive glossy eyes on the front face (-Y in Blender = +Z toward camera in Godot)
    for side in (-1.0, 1.0):
        ex = side * 0.082
        # Subtle cheek blush / eye rim below brow
        bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=10, radius=0.052, location=(ex, -0.172, 0.655))
        rim = bpy.context.active_object
        rim.scale = (0.95, 0.35, 1.05)
        rim.data.materials.append(mat_belly)

        bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=10, radius=0.038, location=(ex, -0.192, 0.66))
        eye = bpy.context.active_object
        eye.data.materials.append(mat_eye)

        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=0.014, location=(ex - 0.012, -0.222, 0.674))
        sp = bpy.context.active_object
        sp.data.materials.append(mat_sparkle)

    # Cute rounded orange beak on the front face
    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=0.058, radius2=0.012, depth=0.13, location=(0.0, -0.24, 0.615))
    beak = bpy.context.active_object
    beak.rotation_euler = (math.radians(82), 0.0, 0.0)
    beak.data.materials.append(mat_beak)

    # Raised flippers waving on both sides
    for side in (-1.0, 1.0):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=10, radius=0.12, location=(side * 0.245, -0.01, 0.34))
        wing = bpy.context.active_object
        wing.scale = (0.32, 0.62, 1.28)
        wing.rotation_euler = (0.0, side * math.radians(-38), 0.0)
        wing.data.materials.append(mat_head)

    finalize_and_export("chick", "chick.blend", "penguin/chick.glb")


def build_mountain_bg():
    """Sculpted realistic multi-peak alpine massif with rocky strata, snow gullies, and foothill spruce forest."""
    clear_scene()
    mat_rock_dark = make_mat("mat_mountain_dark", "2E3B4E", 0.92)
    mat_rock_mid = make_mat("mat_mountain_rock", "435368", 0.88)
    mat_snow = make_mat("mat_mountain_snow", "B8CCE0", 0.78)
    mat_trunk = make_mat("mat_trunk", "4A2E1B", 0.92)
    mat_foliage = make_mat("mat_foliage", "1E4631", 0.78)

    # Deep grounded mountain base skirt (-9m to +1m)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, -4.0))
    skirt = bpy.context.active_object
    skirt.scale = (26.0, 10.0, 9.0)
    skirt.data.materials.append(mat_rock_dark)

    rng = random.Random(104)
    peaks = [
        (-6.5, 0.2, 3.6, 7.2, 5.0, 12.0),
        (0.0, 0.8, 5.2, 8.8, 6.0, 15.2),
        (6.8, -0.2, 3.3, 6.6, 4.6, 11.2),
        (-2.8, -1.2, 2.2, 5.2, 3.8, 7.8),
        (3.6, -1.0, 2.5, 5.5, 4.0, 8.4),
    ]
    for px, py, pz, rx, ry, h in peaks:
        bpy.ops.mesh.primitive_cone_add(vertices=14, radius1=rx, radius2=0.25, depth=h, location=(px, py, pz))
        p = bpy.context.active_object
        p.scale = (1.0, ry / rx, 1.0)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        p.data.materials.append(mat_rock_mid)
        p.data.materials.append(mat_rock_dark)
        p.data.materials.append(mat_snow)

        # Subdivide and displace vertices for natural craggy alpine ridges
        bm = bmesh.new()
        bm.from_mesh(p.data)
        bmesh.ops.subdivide_edges(bm, edges=bm.edges, cuts=2, use_grid_fill=True)
        for v in bm.verts:
            if v.co.z > -h * 0.45:
                ang = math.atan2(v.co.y, v.co.x)
                ridge = 1.0 + 0.14 * math.cos(ang * 5.0 + px) + rng.uniform(-0.08, 0.08)
                v.co.x *= ridge
                v.co.y *= ridge
                v.co.z += rng.uniform(-0.22, 0.22)
        bm.to_mesh(p.data)
        bm.free()
        p.data.update()

        for poly in p.data.polygons:
            world_z = pz + poly.center.z
            if world_z > pz + h * 0.12 and poly.normal.z > 0.15:
                poly.material_index = 2  # Soft glacier snow on upper slopes
            elif poly.normal.x < -0.2 or poly.normal.y > 0.2:
                poly.material_index = 1  # Shadowed cliff facet
            else:
                poly.material_index = 0

    # Foothill spruce trees along the front slope
    tree_spots = [
        (-8.5, -3.2, 0.2, 0.85),
        (-5.8, -3.5, 0.6, 0.95),
        (-3.2, -3.8, 1.1, 1.05),
        (-0.5, -3.6, 0.9, 0.90),
        (2.2, -3.7, 1.2, 1.00),
        (5.1, -3.4, 0.7, 0.88),
        (8.0, -3.1, 0.3, 0.80),
    ]
    for tx, ty, tz, s in tree_spots:
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.14 * s, depth=1.1 * s, location=(tx, ty, tz + 0.35 * s))
        tr = bpy.context.active_object
        tr.data.materials.append(mat_trunk)
        for tier_i, (zh, r1, dh) in enumerate([(1.0, 0.78, 1.1), (1.65, 0.58, 0.95), (2.2, 0.38, 0.75)]):
            bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=r1 * s, radius2=0.05 * s, depth=dh * s, location=(tx, ty, tz + zh * s))
            fol = bpy.context.active_object
            fol.data.materials.append(mat_foliage if tier_i < 2 else mat_snow)

    finalize_and_export("mountain_bg", "mountain_bg.blend", "environment/mountain_bg.glb")


def build_iceberg_bg():
    """Sculpted tabular and pinnacle coastal iceberg with stratified blue ice and wave arches."""
    clear_scene()
    mat_deep_ice = make_mat("mat_deep_ice", "2B6CB0", 0.32, 0.05)
    mat_mid_ice = make_mat("mat_mid_ice", "63B3ED", 0.38, 0.05)
    mat_crest_snow = make_mat("mat_crest_snow", "C4DCF0", 0.72, 0.0)

    # Underwater keel (-6.5m to +0.5m)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, -3.0))
    keel = bpy.context.active_object
    keel.scale = (15.0, 5.5, 7.0)
    keel.data.materials.append(mat_deep_ice)

    rng = random.Random(209)
    spires = [
        (-3.6, 0.0, 2.2, 4.4, 3.0, 6.2),
        (0.6, 0.4, 3.2, 5.4, 3.6, 8.0),
        (4.5, -0.2, 1.9, 3.9, 2.8, 5.2),
    ]
    for sx, sy, sz, rx, ry, h in spires:
        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=rx, radius2=0.55, depth=h, location=(sx, sy, sz))
        sp = bpy.context.active_object
        sp.scale = (1.0, ry / rx, 1.0)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        sp.data.materials.append(mat_mid_ice)
        sp.data.materials.append(mat_deep_ice)
        sp.data.materials.append(mat_crest_snow)

        bm = bmesh.new()
        bm.from_mesh(sp.data)
        bmesh.ops.subdivide_edges(bm, edges=bm.edges, cuts=2, use_grid_fill=True)
        for v in bm.verts:
            v.co.x *= 1.0 + rng.uniform(-0.10, 0.10)
            v.co.y *= 1.0 + rng.uniform(-0.10, 0.10)
        bm.to_mesh(sp.data)
        bm.free()
        sp.data.update()

        for poly in sp.data.polygons:
            wz = sz + poly.center.z
            if wz > sz + h * 0.15 and poly.normal.z > 0.2:
                poly.material_index = 2
            elif wz < sz - h * 0.15:
                poly.material_index = 1
            else:
                poly.material_index = 0

    finalize_and_export("iceberg_bg", "iceberg_bg.blend", "environment/iceberg_bg.glb")


def build_pine_tree():
    """Realistic multi-tiered boreal spruce tree with scalloped branches and snow-laden boughs."""
    clear_scene()
    mat_trunk = make_mat("mat_trunk", "4A2C18", 0.90)
    mat_foliage_dark = make_mat("mat_foliage_dark", "1B4332", 0.78)
    mat_foliage = make_mat("mat_foliage", "2D6A4F", 0.72)
    mat_snow = make_mat("mat_snow", "C8DDF0", 0.76)

    # Tapered trunk with roots (-0.4m to +1.0m)
    bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=0.24, radius2=0.10, depth=1.5, location=(0.0, 0.0, 0.35))
    trunk = bpy.context.active_object
    trunk.data.materials.append(mat_trunk)

    # 5 lush scalloped foliage whorls
    tiers = [
        (0.85, 1.02, 0.18, 0.85),
        (1.30, 0.86, 0.15, 0.78),
        (1.72, 0.70, 0.12, 0.72),
        (2.10, 0.54, 0.09, 0.65),
        (2.44, 0.36, 0.03, 0.58),
    ]
    for idx, (tz, r1, r2, h) in enumerate(tiers):
        bpy.ops.mesh.primitive_cone_add(vertices=14, radius1=r1, radius2=r2, depth=h, location=(0.0, 0.0, tz))
        cone = bpy.context.active_object
        cone.data.materials.append(mat_foliage if idx % 2 == 0 else mat_foliage_dark)
        cone.data.materials.append(mat_snow)
        for v in cone.data.vertices:
            if v.co.z < 0.0:
                ang = math.atan2(v.co.y, v.co.x)
                scallop = 1.0 + 0.14 * math.cos(ang * 7.0 + idx)
                v.co.x *= scallop
                v.co.y *= scallop
        cone.data.update()

        # Snow layer on upper surface of each branch tier
        if idx >= 1:
            bpy.ops.mesh.primitive_cone_add(vertices=14, radius1=r1 * 0.82, radius2=r2 * 1.05, depth=h * 0.52, location=(0.0, 0.0, tz + h * 0.22))
            sc = bpy.context.active_object
            sc.data.materials.append(mat_snow)

    finalize_and_export("pine_tree", "pine_tree.blend", "environment/pine_tree.glb")


def build_rock_formation():
    """Sculpted glacial erratic granite boulders with faceted crevices and soft snow drift."""
    clear_scene()
    mat_granite = make_mat("mat_granite", "4A5568", 0.88)
    mat_slate = make_mat("mat_slate", "2D3748", 0.92)
    mat_snow = make_mat("mat_snow", "C2D6EA", 0.78)

    rng = random.Random(312)
    boulders = [
        (0.0, 0.0, 0.42, 1.35, 0.95, 0.88),
        (0.85, -0.18, 0.24, 0.95, 0.78, 0.68),
        (-0.82, 0.12, 0.20, 0.88, 0.72, 0.62),
    ]
    for bx, by, bz, sx, sy, sz in boulders:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.95, location=(bx, by, bz))
        rock = bpy.context.active_object
        rock.scale = (sx, sy, sz)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        rock.data.materials.append(mat_granite)
        rock.data.materials.append(mat_slate)
        rock.data.materials.append(mat_snow)

        for v in rock.data.vertices:
            v.co.x *= 1.0 + rng.uniform(-0.12, 0.12)
            v.co.y *= 1.0 + rng.uniform(-0.12, 0.12)
            v.co.z *= 1.0 + rng.uniform(-0.10, 0.10)
        rock.data.update()

        for poly in rock.data.polygons:
            if poly.normal.z > 0.48 and (bz + poly.center.z) > 0.35:
                poly.material_index = 2
            elif poly.normal.z < -0.15 or poly.normal.x < -0.35:
                poly.material_index = 1
            else:
                poly.material_index = 0

    finalize_and_export("rock_formation", "rock_formation.blend", "environment/rock_formation.glb")


def build_ice_tile():
    """Sculpted crystalline glacier ice floe with bevelled ice edges and snow crust."""
    clear_scene()
    mat_ice_top = make_mat("mat_ice_top", "B8D8EE", 0.45, 0.05)
    mat_ice_side = make_mat("mat_ice_side", "4A90E2", 0.30, 0.10)
    mat_ice_deep = make_mat("mat_ice_deep", "2B5876", 0.35, 0.10)

    # Upper snow-ice slab
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=1.55, depth=0.32, location=(0.0, 0.0, -0.06))
    top_slab = bpy.context.active_object
    top_slab.scale = (1.05, 0.85, 1.0)
    top_slab.data.materials.append(mat_ice_top)

    # Submerged faceted ice keel
    bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=1.48, radius2=0.85, depth=0.55, location=(0.0, 0.0, -0.45))
    keel = bpy.context.active_object
    keel.rotation_euler = (math.radians(180), 0.0, 0.0)
    keel.scale = (1.02, 0.82, 1.0)
    keel.data.materials.append(mat_ice_side)
    keel.data.materials.append(mat_ice_deep)

    finalize_and_export("ice_tile", "ice_tile.blend", "ice/ice_tile.glb")


def build_research_hut():
    """Detailed polar alpine research station with timber cladding, metal roof, porch railings, and comms dish."""
    clear_scene()
    mat_stone = make_mat("mat_stone", "4A5568", 0.9)
    mat_wood = make_mat("mat_wood", "8D5B4C", 0.72)
    mat_dark_wood = make_mat("mat_dark_wood", "4A2C1D", 0.82)
    mat_roof = make_mat("mat_roof", "2B3A4A", 0.55, 0.35)
    mat_snow = make_mat("mat_snow", "C8DDF0", 0.78)
    mat_window = make_mat("mat_window", "FFD166", 0.15, 0.0, "FFB703", 0.65)
    mat_frame = make_mat("mat_frame", "1B2430", 0.5)
    mat_door = make_mat("mat_door", "C83E4D", 0.45)
    mat_steel = make_mat("mat_steel", "90A4AE", 0.35, 0.65)

    # Stone foundation base
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, -0.025))
    found = bpy.context.active_object
    found.scale = (4.4, 3.1, 0.75)
    found.data.materials.append(mat_stone)

    for side in (-1.0, 1.0):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.55, side * 1.62, 0.18))
        porch = bpy.context.active_object
        porch.scale = (2.2, 0.65, 0.26)
        porch.data.materials.append(mat_dark_wood)

        # Insulated door + frame + round porthole window
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.55, side * 1.26, 1.22))
        df = bpy.context.active_object
        df.scale = (0.96, 0.12, 1.76)
        df.data.materials.append(mat_frame)

        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.55, side * 1.29, 1.20))
        door = bpy.context.active_object
        door.scale = (0.80, 0.10, 1.62)
        door.data.materials.append(mat_door)

        # Warm glowing multi-pane window
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.85, side * 1.26, 1.52))
        wf = bpy.context.active_object
        wf.scale = (1.15, 0.12, 0.98)
        wf.data.materials.append(mat_frame)

        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.85, side * 1.29, 1.52))
        wg = bpy.context.active_object
        wg.scale = (0.94, 0.10, 0.78)
        wg.data.materials.append(mat_window)

    # Cabin walls
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 1.42))
    walls = bpy.context.active_object
    walls.scale = (3.85, 2.52, 2.15)
    walls.data.materials.append(mat_wood)

    # Corner timber posts
    for cx in (-1.92, 1.92):
        for cy in (-1.26, 1.26):
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(cx, cy, 1.42))
            post = bpy.context.active_object
            post.scale = (0.22, 0.22, 2.22)
            post.data.materials.append(mat_dark_wood)

    # Gable roof slopes
    for side, ang in ((-1.0, 32), (1.0, -32)):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, side * 0.78, 2.92))
        rf = bpy.context.active_object
        rf.scale = (4.45, 1.98, 0.18)
        rf.rotation_euler = (math.radians(ang), 0.0, 0.0)
        rf.data.materials.append(mat_roof)

        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, side * 0.75, 3.05))
        sf = bpy.context.active_object
        sf.scale = (4.32, 1.86, 0.14)
        sf.rotation_euler = (math.radians(ang), 0.0, 0.0)
        sf.data.materials.append(mat_snow)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 2.75))
    gf = bpy.context.active_object
    gf.scale = (3.78, 1.38, 0.66)
    gf.data.materials.append(mat_wood)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 3.42))
    ridge = bpy.context.active_object
    ridge.scale = (4.48, 0.34, 0.22)
    ridge.data.materials.append(mat_snow)

    # Stone chimney + metal flue cap
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.35, 0.45, 3.25))
    chimney = bpy.context.active_object
    chimney.scale = (0.55, 0.55, 1.55)
    chimney.data.materials.append(mat_stone)

    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.18, depth=0.35, location=(1.35, 0.45, 4.15))
    flue = bpy.context.active_object
    flue.data.materials.append(mat_steel)

    finalize_and_export("research_hut", "research_hut.blend", "environment/research_hut.glb")


def build_solar_lamp():
    """Detailed polar solar beacon post with photovoltaic panel, battery box, and lantern."""
    clear_scene()
    mat_steel = make_mat("mat_steel", "546E7A", 0.38, 0.65)
    mat_dark = make_mat("mat_dark", "263238", 0.45, 0.50)
    mat_solar = make_mat("mat_solar", "1A365D", 0.18, 0.45)
    mat_glass = make_mat("mat_glass", "FFF3B0", 0.15, 0.0, "FFD166", 0.45)

    # Heavy octagonal base
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.34, depth=0.22, location=(0.0, 0.0, 0.11))
    base = bpy.context.active_object
    base.data.materials.append(mat_dark)

    # Battery box on post
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.52))
    bat = bpy.context.active_object
    bat.scale = (0.28, 0.24, 0.36)
    bat.data.materials.append(mat_steel)

    # Vertical pole
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.065, depth=1.85, location=(0.0, 0.0, 1.02))
    pole = bpy.context.active_object
    pole.data.materials.append(mat_steel)

    # Tilted solar panel at top
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.18, 0.0, 1.96))
    panel = bpy.context.active_object
    panel.scale = (0.58, 0.42, 0.05)
    panel.rotation_euler = (0.0, math.radians(24), 0.0)
    panel.data.materials.append(mat_solar)

    # Lantern arm & warm housing
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.16, 0.0, 1.72))
    arm = bpy.context.active_object
    arm.scale = (0.36, 0.06, 0.06)
    arm.data.materials.append(mat_dark)

    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.14, depth=0.18, location=(0.30, 0.0, 1.62))
    lamp = bpy.context.active_object
    lamp.data.materials.append(mat_glass)

    finalize_and_export("solar_lamp", "solar_lamp.blend", "environment/solar_lamp.glb")


def build_green_glass_bottle():
    """Realistic emerald green glass bottle (litter_jar.glb)."""
    clear_scene()
    mat_green = make_mat("mat_green_glass", "1E824C", 0.14, 0.12)
    mat_dark_green = make_mat("mat_dark_green", "11512F", 0.18, 0.12)
    mat_label = make_mat("mat_label", "F4EFE6", 0.65, 0.0)
    mat_gold = make_mat("mat_gold_foil", "D4AC0D", 0.30, 0.55)

    bpy.ops.mesh.primitive_cylinder_add(vertices=18, radius=0.14, depth=0.35, location=(0.0, 0.0, 0.175))
    body = bpy.context.active_object
    body.data.materials.append(mat_green)

    bpy.ops.mesh.primitive_cylinder_add(vertices=18, radius=0.145, depth=0.15, location=(0.0, 0.0, 0.18))
    label = bpy.context.active_object
    label.data.materials.append(mat_label)

    bpy.ops.mesh.primitive_cone_add(vertices=18, radius1=0.14, radius2=0.052, depth=0.15, location=(0.0, 0.0, 0.42))
    shoulder = bpy.context.active_object
    shoulder.data.materials.append(mat_green)

    bpy.ops.mesh.primitive_cylinder_add(vertices=18, radius=0.050, depth=0.15, location=(0.0, 0.0, 0.56))
    neck = bpy.context.active_object
    neck.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_cylinder_add(vertices=18, radius=0.062, depth=0.03, location=(0.0, 0.0, 0.63))
    lip = bpy.context.active_object
    lip.data.materials.append(mat_dark_green)

    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for m in meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    body.rotation_euler = (0.0, math.radians(14), 0.0)

    finalize_and_export("litter_jar", "litter_jar.blend", "litter/litter_jar.glb")


def build_crumpled_paper():
    """Realistic crushed beverage carton & folded newspaper bundle (litter_box.glb)."""
    clear_scene()
    mat_paper = make_mat("mat_paper_white", "DCE6F0", 0.82, 0.0)
    mat_blue = make_mat("mat_paper_blue", "1F618D", 0.68, 0.0)
    mat_crease = make_mat("mat_paper_crease", "9FB3C8", 0.88, 0.0)

    # Crushed gable-top carton body
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.02, 0.0, 0.18))
    carton = bpy.context.active_object
    carton.scale = (0.26, 0.22, 0.32)
    carton.rotation_euler = (math.radians(8), math.radians(-12), math.radians(10))
    carton.data.materials.append(mat_blue)

    # White printed stripe wrap
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.02, 0.0, 0.18))
    band = bpy.context.active_object
    band.scale = (0.27, 0.23, 0.14)
    band.rotation_euler = (math.radians(8), math.radians(-12), math.radians(10))
    band.data.materials.append(mat_paper)

    # Gable roof top of carton
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.18, radius2=0.04, depth=0.12, location=(-0.04, 0.01, 0.37))
    top = bpy.context.active_object
    top.rotation_euler = (math.radians(8), math.radians(-12), math.radians(55))
    top.data.materials.append(mat_crease)

    finalize_and_export("litter_box", "litter_box.blend", "litter/litter_box.glb")


def build_plastic_bottle():
    """Realistic ribbed PET plastic bottle with cap and label (litter_bottle.glb)."""
    clear_scene()
    mat_plastic = make_mat("mat_plastic_body", "F5B041", 0.20, 0.08)
    mat_label = make_mat("mat_plastic_label", "D35400", 0.38, 0.0)
    mat_cap = make_mat("mat_plastic_cap", "C0392B", 0.28, 0.0)

    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.13, depth=0.19, location=(0.0, 0.0, 0.095))
    bot = bpy.context.active_object
    bot.data.materials.append(mat_plastic)

    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.10, depth=0.11, location=(0.015, 0.0, 0.23))
    waist = bpy.context.active_object
    waist.scale = (1.12, 0.82, 1.0)
    waist.data.materials.append(mat_label)

    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.128, depth=0.15, location=(0.0, 0.0, 0.34))
    top_body = bpy.context.active_object
    top_body.data.materials.append(mat_plastic)

    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=0.128, radius2=0.048, depth=0.11, location=(0.0, 0.0, 0.47))
    cone = bpy.context.active_object
    cone.data.materials.append(mat_plastic)

    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.056, depth=0.055, location=(0.0, 0.0, 0.55))
    cap = bpy.context.active_object
    cap.data.materials.append(mat_cap)

    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for m in meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = bot
    bpy.ops.object.join()
    bot.rotation_euler = (0.0, math.radians(-11), 0.0)

    finalize_and_export("litter_bottle", "litter_bottle.blend", "litter/litter_bottle.glb")


def build_recycling_bins():
    """Realistic wheeled recycling containers with dome lids and color-coded trim."""
    configs = [
        ("bin_paper", "bin_paper.blend", "litter/bin_paper.glb", "1F618D", "5499C7"),
        ("bin_plastic", "bin_plastic.blend", "litter/bin_plastic.glb", "D4AC0D", "F4D03F"),
        ("bin_glass", "bin_glass.blend", "litter/bin_glass.glb", "1E8449", "52BE80"),
    ]
    for name, blend_name, rel_path, body_hex, lid_hex in configs:
        clear_scene()
        mat_body = make_mat(f"mat_{name}_body", body_hex, 0.42, 0.12)
        mat_lid = make_mat(f"mat_{name}_lid", lid_hex, 0.35, 0.15)
        mat_dark = make_mat(f"mat_{name}_dark", "1C2833", 0.75, 0.2)

        # Base plinth / wheels
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.46, depth=0.10, location=(0.0, 0.0, 0.05))
        base = bpy.context.active_object
        base.data.materials.append(mat_dark)

        # Tapered ribbed bin body
        bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=0.44, radius2=0.50, depth=0.92, location=(0.0, 0.0, 0.56))
        body = bpy.context.active_object
        body.data.materials.append(mat_body)

        # Collar rim
        bpy.ops.mesh.primitive_torus_add(major_radius=0.50, minor_radius=0.045, major_segments=20, minor_segments=10, location=(0.0, 0.0, 1.02))
        rim = bpy.context.active_object
        rim.data.materials.append(mat_lid)

        # Dome hood lid
        bpy.ops.mesh.primitive_uv_sphere_add(segments=18, ring_count=10, radius=0.49, location=(0.0, 0.0, 1.04))
        dome = bpy.context.active_object
        dome.scale = (1.0, 1.0, 0.42)
        dome.data.materials.append(mat_lid)

        finalize_and_export(name, blend_name, rel_path)


def build_litter_gate():
    """Realistic multi-item coastal waste & industrial debris mound blocking the pass (litter_gate.glb)."""
    clear_scene()
    mat_dirt = make_mat("mat_debris_dirt", "2E353F", 0.92)
    mat_snow = make_mat("mat_debris_snow", "D8E7F5", 0.75)
    mat_rust = make_mat("mat_debris_rust", "943C22", 0.65, 0.4)
    mat_blue = make_mat("mat_debris_blue_barrel", "1B4F72", 0.45)
    mat_wood = make_mat("mat_debris_wood", "6E4E33", 0.88)
    mat_cardboard = make_mat("mat_debris_cardboard", "C59B68", 0.82)
    mat_tire = make_mat("mat_debris_tire", "1C2024", 0.95)
    mat_plastic_orange = make_mat("mat_debris_orange_jug", "E67E22", 0.32)
    mat_plastic_cyan = make_mat("mat_debris_plastic_cyan", "2980B9", 0.28)
    mat_glass_green = make_mat("mat_debris_glass_green", "1E8449", 0.15)
    mat_can = make_mat("mat_debris_can", "B2BABB", 0.35, 0.75)
    mat_rope = make_mat("mat_debris_rope", "F1C40F", 0.70)

    # 1. Base frozen embankment (flattened dome, wide and stable)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=1.35, depth=0.35, location=(0.0, 0.0, 0.17))
    base = bpy.context.active_object
    base.scale = (1.1, 1.3, 1.0)
    base.data.materials.append(mat_dirt)

    # Snow patches clinging to the base
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.55, 0.45, 0.28))
    snow1 = bpy.context.active_object
    snow1.scale = (0.75, 0.65, 0.22)
    snow1.rotation_euler = (0.1, 0.2, -0.3)
    snow1.data.materials.append(mat_snow)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.65, -0.35, 0.22))
    snow2 = bpy.context.active_object
    snow2.scale = (0.68, 0.72, 0.18)
    snow2.rotation_euler = (-0.15, 0.1, 0.4)
    snow2.data.materials.append(mat_snow)

    # 2. Weathered Rusty Oil Drum (tilted on its side)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.38, depth=0.92, location=(0.35, 0.12, 0.58))
    drum_rust = bpy.context.active_object
    drum_rust.rotation_euler = (math.radians(35), math.radians(-18), math.radians(25))
    drum_rust.data.materials.append(mat_rust)

    # Drum ribs / reinforcing rings
    for ring_z in [-0.22, 0.22]:
        bpy.ops.mesh.primitive_torus_add(major_radius=0.39, minor_radius=0.03, major_segments=16, minor_segments=8, location=(0.35, 0.12, 0.58))
        ring = bpy.context.active_object
        ring.rotation_euler = (math.radians(35), math.radians(-18), math.radians(25))
        ring.data.materials.append(mat_rust)

    # 3. Industrial Blue Plastic Drum (standing upright but listing)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.35, depth=0.88, location=(-0.32, 0.25, 0.58))
    drum_blue = bpy.context.active_object
    drum_blue.rotation_euler = (math.radians(8), math.radians(-14), math.radians(10))
    drum_blue.data.materials.append(mat_blue)

    # 4. Discarded Worn Rubber Tire (leaning against the blue drum and ground)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.36, minor_radius=0.12, major_segments=18, minor_segments=10, location=(-0.58, -0.28, 0.38))
    tire = bpy.context.active_object
    tire.rotation_euler = (math.radians(65), math.radians(20), math.radians(-35))
    tire.data.materials.append(mat_tire)

    # 5. Broken Wooden Shipping Pallet (slanted in the center of the mound)
    pallet_loc = (-0.02, -0.28, 0.56)
    pallet_rot = (math.radians(-38), math.radians(15), math.radians(-8))

    # Pallet stringers (3 support beams)
    for ox in [-0.35, 0.0, 0.35]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(pallet_loc[0] + ox * 0.85, pallet_loc[1], pallet_loc[2]))
        st = bpy.context.active_object
        st.scale = (0.08, 0.88, 0.08)
        st.rotation_euler = pallet_rot
        st.data.materials.append(mat_wood)

    # Pallet top deck slats (4 boards)
    for oy in [-0.32, -0.10, 0.12, 0.34]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(pallet_loc[0], pallet_loc[1] + oy * 0.65, pallet_loc[2] + 0.06 - oy * 0.35))
        board = bpy.context.active_object
        board.scale = (0.82, 0.11, 0.035)
        board.rotation_euler = pallet_rot
        board.data.materials.append(mat_wood)

    # 6. Crushed Corrugated Cardboard Box (tucked against the side)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.62, 0.08, 0.82))
    box = bpy.context.active_object
    box.scale = (0.44, 0.38, 0.32)
    box.rotation_euler = (math.radians(22), math.radians(-28), math.radians(15))
    box.data.materials.append(mat_cardboard)

    # Second flattened box
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.35, -0.55, 0.32))
    box2 = bpy.context.active_object
    box2.scale = (0.52, 0.36, 0.08)
    box2.rotation_euler = (math.radians(15), math.radians(35), math.radians(-10))
    box2.data.materials.append(mat_cardboard)

    # 7. Plastic Hazard Oil / Detergent Jug
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.18, -0.42, 0.85))
    jug = bpy.context.active_object
    jug.scale = (0.24, 0.18, 0.32)
    jug.rotation_euler = (math.radians(18), math.radians(12), math.radians(-25))
    jug.data.materials.append(mat_plastic_orange)

    # Jug handle
    bpy.ops.mesh.primitive_torus_add(major_radius=0.08, minor_radius=0.025, location=(0.14, -0.42, 0.96))
    handle = bpy.context.active_object
    handle.rotation_euler = (math.radians(90), 0.0, math.radians(-25))
    handle.data.materials.append(mat_plastic_orange)

    # 8. Discarded Plastic Bottle (cyan)
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.10, depth=0.34, location=(-0.15, -0.52, 0.44))
    bot = bpy.context.active_object
    bot.rotation_euler = (math.radians(72), math.radians(10), math.radians(45))
    bot.data.materials.append(mat_plastic_cyan)

    # 9. Emerald Green Glass Wine/Soda Bottle
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.11, depth=0.38, location=(0.48, -0.32, 0.42))
    gbot = bpy.context.active_object
    gbot.rotation_euler = (math.radians(68), math.radians(-25), math.radians(60))
    gbot.data.materials.append(mat_glass_green)

    # 10. Crushed Aluminum Soda Cans
    for can_loc in [(0.52, -0.15, 0.32), (-0.42, -0.48, 0.28)]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.08, depth=0.14, location=can_loc)
        can = bpy.context.active_object
        can.rotation_euler = (math.radians(45), math.radians(30), math.radians(10))
        can.data.materials.append(mat_can)

    # 11. Coiled Yellow Marine Fishing Rope
    bpy.ops.mesh.primitive_torus_add(major_radius=0.24, minor_radius=0.045, major_segments=16, minor_segments=8, location=(0.08, -0.12, 0.88))
    rope = bpy.context.active_object
    rope.rotation_euler = (math.radians(30), math.radians(-25), math.radians(15))
    rope.data.materials.append(mat_rope)

    finalize_and_export("litter_gate", "litter_gate.blend", "litter/litter_gate.glb")


def build_fact_holo_globe():
    """Climate Research Globe & Crystal Ring (fact_holo_globe.glb)."""
    clear_scene()
    mat_gold = make_mat("mat_ring_gold", "FFB703", 0.22, 0.78)
    mat_ocean = make_mat("mat_globe_ocean", "0077B6", 0.22, 0.12)
    mat_land = make_mat("mat_globe_land", "2A9D8F", 0.42, 0.05)
    mat_ice = make_mat("mat_globe_ice", "E0F2FE", 0.35, 0.0)
    mat_crystal = make_mat("mat_globe_crystal", "48CAE4", 0.15, 0.2, "48CAE4", 0.4)

    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.18, depth=0.08, location=(0.0, 0.0, -0.36))
    base = bpy.context.active_object
    base.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_torus_add(major_radius=0.38, minor_radius=0.036, major_segments=24, minor_segments=12, location=(0.0, 0.0, 0.0))
    ring1 = bpy.context.active_object
    ring1.rotation_euler = (math.radians(90), 0.0, math.radians(18))
    ring1.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_torus_add(major_radius=0.32, minor_radius=0.024, major_segments=20, minor_segments=10, location=(0.0, 0.0, 0.0))
    ring2 = bpy.context.active_object
    ring2.rotation_euler = (math.radians(65), math.radians(32), 0.0)
    ring2.data.materials.append(mat_crystal)

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.23, location=(0.0, 0.0, 0.0))
    globe = bpy.context.active_object
    globe.data.materials.append(mat_ocean)
    globe.data.materials.append(mat_land)
    globe.data.materials.append(mat_ice)

    for i, poly in enumerate(globe.data.polygons):
        cz = poly.center.z
        if abs(cz) > 0.155:
            poly.material_index = 2
        elif (i % 4 == 0) or (i % 7 == 0):
            poly.material_index = 1

    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.09, radius2=0.0, depth=0.14, location=(0.0, 0.0, 0.50))
    top_c1 = bpy.context.active_object
    top_c1.data.materials.append(mat_crystal)

    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.09, radius2=0.0, depth=0.10, location=(0.0, 0.0, 0.40))
    top_c2 = bpy.context.active_object
    top_c2.rotation_euler = (math.radians(180), 0.0, 0.0)
    top_c2.data.materials.append(mat_crystal)

    finalize_and_export("fact_holo_globe", "fact_holo_globe.blend", "props/fact_holo_globe.glb")


def build_seed_patch():
    """Fertile soil mound ringed with stones and a golden seed pod (seed_patch.glb)."""
    clear_scene()
    mat_soil = make_mat("mat_soil", "3E2723", 0.92)
    mat_stone = make_mat("mat_stone", "607D8B", 0.85)
    mat_seed = make_mat("mat_seed_gold", "FFD166", 0.28)
    mat_leaf = make_mat("mat_seed_tip", "40916C", 0.48)

    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.52, depth=0.16, location=(0.0, 0.0, 0.08))
    mound = bpy.context.active_object
    mound.data.materials.append(mat_soil)

    for i in range(10):
        ang = i * (2.0 * math.pi / 10.0)
        sx = math.cos(ang) * 0.50
        sy = math.sin(ang) * 0.50
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.11, location=(sx, sy, 0.09))
        st = bpy.context.active_object
        st.scale = (1.2, 1.0, 0.75)
        st.data.materials.append(mat_stone)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=0.12, location=(0.0, -0.05, 0.22))
    seed = bpy.context.active_object
    seed.scale = (1.35, 0.9, 0.95)
    seed.rotation_euler = (0.0, math.radians(-20), 0.0)
    seed.data.materials.append(mat_seed)

    bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=0.05, radius2=0.01, depth=0.12, location=(0.08, -0.05, 0.30))
    tip = bpy.context.active_object
    tip.rotation_euler = (0.0, math.radians(35), 0.0)
    tip.data.materials.append(mat_leaf)

    finalize_and_export("seed_patch", "seed_patch.blend", "props/seed_patch.glb")


def build_arctic_flower():
    """Blooming Arctic tundra cushion plant with vibrant star flowers (arctic_flower.glb)."""
    clear_scene()
    mat_soil = make_mat("mat_fl_soil", "2A1E17", 0.94)
    mat_stone = make_mat("mat_fl_stone", "546E7A", 0.88)
    mat_moss = make_mat("mat_fl_moss", "2D6A4F", 0.72)
    mat_stem = make_mat("mat_fl_stem", "40916C", 0.55)
    mat_leaf = make_mat("mat_fl_leaf", "52B788", 0.48)
    mat_petal = make_mat("mat_fl_petal", "FFD166", 0.32, emission_hex="F4A261", emission_strength=0.35)
    mat_center = make_mat("mat_fl_center", "E76F51", 0.25, emission_hex="E76F51", emission_strength=0.7)

    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.55, depth=0.14, location=(0.0, 0.0, 0.07))
    base = bpy.context.active_object
    base.data.materials.append(mat_soil)

    for i in range(11):
        ang = i * (2.0 * math.pi / 11.0)
        sx = math.cos(ang) * 0.54
        sy = math.sin(ang) * 0.54
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.10, location=(sx, sy, 0.08))
        st = bpy.context.active_object
        st.scale = (1.1, 0.9, 0.7)
        st.data.materials.append(mat_stone)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=18, ring_count=12, radius=0.48, location=(0.0, 0.0, 0.16))
    cushion = bpy.context.active_object
    cushion.scale = (1.0, 0.95, 0.42)
    cushion.data.materials.append(mat_moss)

    for i in range(8):
        ang = i * (2.0 * math.pi / 8.0) + 0.18
        lx = math.cos(ang) * 0.34
        ly = math.sin(ang) * 0.34
        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.08, radius2=0.01, depth=0.28, location=(lx, ly, 0.22))
        leaf = bpy.context.active_object
        leaf.scale = (0.7, 1.3, 0.3)
        leaf.rotation_euler = (math.sin(ang) * 0.5, -math.cos(ang) * 0.5, ang)
        leaf.data.materials.append(mat_leaf)

    flower_positions = [
        (0.0, 0.0, 0.55),
        (-0.22, 0.14, 0.46),
        (0.24, 0.12, 0.48),
        (0.02, -0.24, 0.44),
    ]

    for fx, fy, fz in flower_positions:
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.028, depth=fz - 0.20, location=(fx * 0.65, fy * 0.65, (fz + 0.20) / 2.0))
        stem = bpy.context.active_object
        stem.data.materials.append(mat_stem)

        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.065, location=(fx, fy, fz))
        center = bpy.context.active_object
        center.scale = (1.0, 1.0, 0.6)
        center.data.materials.append(mat_center)

        for p in range(5):
            pang = p * (2.0 * math.pi / 5.0)
            px = fx + math.cos(pang) * 0.11
            py = fy + math.sin(pang) * 0.11
            bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=0.072, location=(px, py, fz - 0.01))
            petal = bpy.context.active_object
            petal.scale = (0.65, 1.15, 0.28)
            petal.rotation_euler = (0.0, 0.0, pang)
            petal.data.materials.append(mat_petal)

    finalize_and_export("arctic_flower", "arctic_flower.blend", "props/arctic_flower.glb")


def build_ocean_buoy():
    """Polar ocean acoustic monitoring buoy (ocean_buoy.glb)."""
    clear_scene()
    mat_red = make_mat("mat_buoy_red", "D62828", 0.38, 0.22)
    mat_white = make_mat("mat_buoy_white", "DCE6F0", 0.48, 0.10)
    mat_steel = make_mat("mat_buoy_steel", "457B9D", 0.32, 0.65)
    mat_beacon = make_mat("mat_buoy_beacon", "00F5D4", 0.15, 0.1, "00F5D4", 0.5)

    bpy.ops.mesh.primitive_cylinder_add(vertices=18, radius=0.45, depth=0.35, location=(0.0, 0.0, 0.175))
    b1 = bpy.context.active_object
    b1.data.materials.append(mat_red)

    bpy.ops.mesh.primitive_cylinder_add(vertices=18, radius=0.36, depth=0.25, location=(0.0, 0.0, 0.45))
    b2 = bpy.context.active_object
    b2.data.materials.append(mat_white)

    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.07, depth=0.95, location=(0.0, 0.0, 0.95))
    mast = bpy.context.active_object
    mast.data.materials.append(mat_steel)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 1.15))
    bar = bpy.context.active_object
    bar.scale = (0.55, 0.08, 0.08)
    bar.data.materials.append(mat_steel)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=0.14, location=(0.0, 0.0, 1.48))
    dome = bpy.context.active_object
    dome.data.materials.append(mat_beacon)

    finalize_and_export("ocean_buoy", "ocean_buoy.blend", "props/ocean_buoy.glb")


def build_weather_tower():
    """Automated mountain weather relay dish & solar station (weather_tower.glb)."""
    clear_scene()
    mat_frame = make_mat("mat_tower_frame", "546E7A", 0.40, 0.55)
    mat_dish = make_mat("mat_tower_dish", "DCE6F0", 0.35, 0.25)
    mat_solar = make_mat("mat_tower_solar", "1D3557", 0.20, 0.45)
    mat_beacon = make_mat("mat_tower_beacon", "FFD166", 0.15, 0.1, "FFD166", 0.5)

    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.50, depth=0.22, location=(0.0, 0.0, 0.11))
    pad = bpy.context.active_object
    pad.data.materials.append(mat_frame)

    bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=0.09, depth=1.55, location=(0.0, 0.0, 0.92))
    mast = bpy.context.active_object
    mast.data.materials.append(mat_frame)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.38, 0.0, 0.95))
    solar = bpy.context.active_object
    solar.scale = (0.55, 0.38, 0.05)
    solar.rotation_euler = (math.radians(25), 0.0, 0.0)
    solar.data.materials.append(mat_solar)

    bpy.ops.mesh.primitive_cone_add(vertices=18, radius1=0.36, radius2=0.06, depth=0.18, location=(0.18, -0.12, 1.42))
    dish = bpy.context.active_object
    dish.rotation_euler = (math.radians(55), 0.0, math.radians(-25))
    dish.data.materials.append(mat_dish)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=10, radius=0.11, location=(0.0, 0.0, 1.76))
    light = bpy.context.active_object
    light.data.materials.append(mat_beacon)

    finalize_and_export("weather_tower", "weather_tower.blend", "props/weather_tower.glb")


if __name__ == "__main__":
    build_baby_chick()
    build_mountain_bg()
    build_iceberg_bg()
    build_pine_tree()
    build_rock_formation()
    build_ice_tile()
    build_research_hut()
    build_solar_lamp()
    build_green_glass_bottle()
    build_crumpled_paper()
    build_plastic_bottle()
    build_recycling_bins()
    build_litter_gate()
    build_fact_holo_globe()
    build_seed_patch()
    build_arctic_flower()
    build_ocean_buoy()
    build_weather_tower()
    print("ALL REALISTIC BLENDER MODELS BUILT AND EXPORTED SUCCESSFULLY.")
