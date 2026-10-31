---
name: blender_to_godot
description: Use when a new 3D model, texture, sound, or font is needed. Covers license safe sourcing, creating original low poly models in Blender through MCP, exporting glb, and importing to Godot.
---

# Asset sourcing and Blender to Godot

## 1. Find first (max 3 searches per asset)
1. Check docs/ASSET_LIST.md for the preferred source of the item.
2. Search CC0 sources: Kenney, Quaternius, Poly Haven (Blender MCP has a Poly Haven integration, use it), OpenGameArt with CC0 filter, Freesound with CC0 filter, Google Fonts (OFL).
3. Open the source page and confirm the license text there. CC0, public domain, OFL, MIT are fine. CC BY is fine with credit. Anything else is rejected.
4. Do not enable or use Sketchfab unless the model page shows CC0.
5. Download into assets/<type>/<pack_or_item>/. Log it in docs/ASSET_LICENSES.md immediately.

## 2. Create when not found (original work)
Style: low poly, flat colors, no image textures, palette from skill toon_2_5d_look.
Budgets: props under 1500 triangles, hero characters under 4000.
Steps in Blender via MCP:
1. Build from primitives and simple modifiers. Keep geometry clean.
2. One Principled BSDF material per color, base color only.
3. 1 unit equals 1 meter. Origin at the bottom center. Apply all transforms and modifiers.
4. Name objects in snake_case. Characters face +X after import into Godot. Check once and rotate the scene root in Godot if needed.
5. Save the .blend into art_source/ (a folder Godot ignores).
6. Export glTF Binary (.glb) to assets/models/<category>/<name>.glb. No lights, no cameras.
7. Log it in docs/ASSET_LICENSES.md with author "project owner" and license "CC0 original".

## 3. Import to Godot
1. Let Godot import the glb. Check the console for import errors.
2. Wrap each model in its own scene under the owning feature folder. Add collision shapes by hand, never auto generate for gameplay bodies.
3. Apply toon and outline materials from skill toon_2_5d_look.
4. Run python tools/check_project.py licenses before finishing.

## Audio and fonts
1. Audio: ogg for music and ambience, wav for short sfx. Normalize loudness lightly, loop points clean.
2. Fonts: only OFL fonts that contain Turkish glyphs. Verify ı İ ş ğ ç ö ü by rendering a test label.
