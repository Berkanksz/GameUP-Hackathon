---
name: toon_2_5d_look
description: Use when setting up or changing the visual style, camera, lighting, materials, shaders, backgrounds, or color grading of the 2.5D look.
---

# 2.5D toon look

Game is 3D but plays like 2D. Gameplay plane is z = 0. Renderer: Compatibility.

## Camera
1. Camera3D perspective, FOV about 25, far back on +Z, looking along -Z. Gentle depth gives parallax. Use orthogonal only if asked.
2. Smooth follow on x and y with a small deadzone and a little look ahead in the move direction. Clamp to chapter bounds from ChapterData.
3. Camera never rotates during play.

## Plane and layers
1. Player, platforms, and interactables live at z = 0. Lock motion with axis_lock_linear_z and also zero velocity.z.
2. Background layers at negative z (mountains, far trees). Small foreground silhouettes at slight positive z.
3. Collision only on the z = 0 plane. Decoration has no collision.

## Light and environment
1. One DirectionalLight3D. Shadows off, or one soft shadow if performance allows.
2. WorldEnvironment with ProceduralSkyMaterial gradient, light fog for depth, ambient light from the palette.
3. Hope drives mood: low hope is desaturated and cool, high hope is saturated and warm. Drive Environment adjustment saturation and a color tint from GameState hope through the hope_changed signal. Smooth with a tween.

## Shaders (shaders/)
1. toon.gdshader: spatial shader, albedo uniform, 3 light bands from NdotL, soft band edges.
2. outline.gdshader: inverted hull, render_mode cull_front, push vertices along normals, thickness uniform, unshaded dark color. Attach as next_pass on characters and props only.
3. Terrain and large blocks: toon without outline.
4. Keep shaders tiny and commented in one line each. Validate through Godot MCP.

## Palette
Snow #EAF2F8, ice #9FD3E6, deep sea #1F4E79, rock #5B6770, sun accent #FFB347, hope green #6BBF59, scarf red #D64045, bin paper blue #2F6FDE, bin plastic yellow #F2C230, bin glass green #3FA34D, outline #1B2430.

## Penguin
Original design: round body, short flippers, small red scarf for silhouette and identity. Dark body on light backgrounds for readability. Squash and stretch on jump and land with tweens.

## Budgets
60 fps on integrated graphics. Under 1500 triangles per prop. Particles under 500. No real time global illumination, no SSAO.
