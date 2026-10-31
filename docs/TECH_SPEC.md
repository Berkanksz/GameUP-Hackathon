# Tech spec

## 1. Engine
Godot 4.3 or newer, GDScript only. Renderer: Compatibility (widest hardware and web support). Run through Godot MCP.

## 2. Project settings
1. Window 1920x1080, stretch mode canvas_items, aspect keep.
2. Input actions: move_left (A, Left), move_right (D, Right), jump (Space), interact (E), pause (Escape).
3. Physics layers: 1 world, 2 player, 3 zones, 4 interactables.
4. Groups: player, checkpoint, litter, bin, gate.
5. Translations: translations/strings.csv imported, locales en and tr, fallback en.
6. Default font: OFL font with Turkish glyphs set in a project theme.

## 3. Folder layout (res://)
```
autoload/            event_bus.gd, game_state.gd, settings.gd, audio.gd
features/
  player/            player.tscn, player.gd, states
  camera/            camera_rig.tscn, camera_rig.gd
  heat/              heat_component.gd, heat_zone.tscn, heat_zone.gd
  ice/               ice_tile.tscn, ice_tile.gd
  checkpoint/        checkpoint.tscn, checkpoint.gd, respawn.gd
  litter/            litter_item, sorting_bin, litter_gate
  narrative/         narrative_trigger, monologue_ui, fact_card, choice_point
  chapters/          chapter_1_shore.tscn, chapter_2_slope.tscn, chapter_3_summit.tscn, chapter_loader.gd
  ending/            ending_scene.tscn, ending.gd
  ui/                main_menu, hud, pause_menu, settings_panel, credits
  look/              hope_grade.gd, parallax layers
data/                tuning.tres, chapter data resources
shaders/             toon.gdshader, outline.gdshader
assets/
  models/ audio/ fonts/ textures/
art_source/          .blend files, has .gdignore
translations/        strings.csv
docs/ tools/         have .gdignore
```
Each feature folder owns its scenes, scripts, and its own resources. Shared things live in autoload or data.

## 4. Autoloads (4 only)
1. EventBus: signals only, no logic.
2. GameState: hope, chapter, flags, ending id.
3. Settings: language, volume, persistence in user://settings.cfg.
4. Audio: play_sfx, play_music, bus volumes.

## 5. Player (CharacterBody3D, plane locked)
1. Walk with acceleration and friction, variable height jump, coyote time, jump buffer.
2. States as a small enum: IDLE, WALK, JUMP, FALL, CARRY, DEAD. No heavy state machine framework.
3. HeatComponent child handles heat. Player never reads zones directly.
4. Greybox first with CSGBox3D and a capsule. Real model comes later through the asset skill.

## 6. Data and text
1. Tuning values in data/tuning.tres (a custom Resource with typed exports).
2. All text through tr(KEY). Format with placeholders and the % operator.
3. Facts live in the CSV. Their sources live in docs/FACTS_SOURCES.md.

## 7. Build
1. Windows Desktop preset into export/. Optional Web preset with the single thread option.
2. Smoke test before every export. See workflow ship_check.

## 8. Performance budget
60 fps on integrated graphics. One directional light, no heavy post effects, particles under 500, models under 1500 triangles (hero under 4000).
