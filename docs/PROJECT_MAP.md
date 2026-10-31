# PROJECT MAP

Purpose: module contracts and intent. The agent reads this instead of the whole project. Keep it current, short, and truthful. Structure facts live in GRAPH.md (auto generated).
Status marks: [ ] planned, [x] built.

## Signals (EventBus)
| Signal | Payload | Emitted by | Heard by |
|---|---|---|---|
| player_died | reason: StringName | player | respawn, hud |
| player_respawned | checkpoint_id: StringName | respawn | heat, camera |
| heat_changed | value: float | heat component | hud, player, look |
| hope_changed | value: float | game_state | hud, look, audio |
| litter_picked | type: StringName | litter item | hud, player |
| litter_sorted | type: StringName, correct: bool | sorting bin | game_state, narrative, audio |
| gate_opened | gate_id: StringName | litter gate | narrative, camera |
| checkpoint_reached | checkpoint_id: StringName | checkpoint | respawn |
| monologue_requested | key: StringName | narrative trigger, systems | monologue ui |
| fact_collected | key: StringName | fact card | game_state, hud |
| choice_made | choice_id: StringName, option: StringName | choice point | game_state |
| chapter_started | chapter_id: StringName | chapter loader | hud, audio, camera |
| chapter_completed | chapter_id: StringName | chapter | chapter loader |
| language_changed | code: String | settings | ui |
| game_ended | ending_id: StringName | ending | credits |

## Public contracts
### autoload
1. [x] GameState: hope: float, add_hope(amount: float) -> void, get_ending_id() -> StringName, set_flag(id: StringName) -> void, has_flag(id: StringName) -> bool, reset() -> void, current_chapter: StringName.
2. [x] Settings: set_language(code: String) -> void, get_language() -> String, set_volume(bus: StringName, value: float) -> void, get_volume(bus: StringName) -> float.
3. [x] Audio: play_sfx(key: StringName) -> void, play_music(key: StringName) -> void, play_ambience(key: StringName) -> void, stop_music() -> void, stop_ambience() -> void.

### features
1. [x] Player: @export fall_death_y: float, respawn_at(target_position: Vector3) -> void, die(reason: StringName) -> void, set_push(source_id: StringName, speed_x: float) -> void, clear_push(source_id: StringName) -> void, set_cinematic_lock(locked: bool) -> void, set_pushing_object(pushing: bool) -> void, start_level_exit_walk() -> void, is_sliding() -> bool, apply_launch_boost(boost_vel_x: float, boost_vel_y: float) -> void, is_carrying: bool, carried_item_type: StringName, is_cinematic_locked: bool, is_pushing_object: bool, is_exiting_level: bool. Supports State.SLIDE belly slide on Shift and dynamic exertion heat. Group: player.
2. [x] CameraRig: @export target: Node3D, @export bounds: Rect2, @export use_bounds: bool, set_bounds(new_bounds: Rect2) -> void, snap_to_target() -> void, focus_on(world_pos: Vector3, target_fov: float, duration: float) -> void, release_focus(duration: float) -> void, freeze_at_current_position() -> void. Group: camera_rig.
3. [x] HeatComponent: set_rate(source_id: StringName, rate: float) -> void, clear_rate(source_id: StringName) -> void, heat: float.
4. [x] HeatZone (Area3D): @export rate: float, @export zone_id: StringName, @export show_debug_visual: bool. Registers with the HeatComponent of the player body that enters.
5. [x] IceTile (StaticBody3D): @export melt_time: float, @export respawn_time: float, @export sun_multiplier: float.
6. [x] Checkpoint (Area3D): @export checkpoint_id: StringName, is_active: bool. Group: checkpoint.
7. [x] Respawn: @export player: Node3D, @export tuning: TuningData, active_checkpoint_id: StringName.
8. [x] Hud (CanvasLayer): @export tuning: TuningData, toggle_pause() -> void, pause_game() -> void, resume_game() -> void. Listens to heat_changed, player_died, player_respawned, language_changed, hope_changed, fact_collected, litter_picked, litter_sorted, chapter_started, chapter_completed. Includes Esc pause and settings menu, 5 level routing, and level intro fade and shrink transition.
9. [x] LitterItem (Area3D): @export litter_type: StringName (paper, plastic, glass). Group: litter.
10. [x] SortingBin (Area3D): @export accepts: StringName, sort_from_player(player_node: Node3D) -> bool. Group: bin.
11. [x] LitterGate (StaticBody3D): @export gate_id: StringName, @export required_count: int, @export show_intro_cinematic: bool, is_open: bool, current_count: int, open_gate() -> void. Dispenses litter items directly from the pile, shrinks visually as items are pulled, and opens when all 3 items are sorted. Group: gate.
12. [x] NarrativeTrigger (Area3D): @export key: StringName, @export once: bool.
13. [x] MonologueUI (CanvasLayer): hide_immediately() -> void. Listens to monologue_requested, picks key variant by hope tier (_LOW, _MID, _HIGH suffix if present, else base key). Displays lines inside a fixed left middle lower rectangular box so it never collides with 3D objects. Group: monologue_ui.
14. [x] FactCard (Area3D): @export fact_key: StringName, @export source_label: String. Uses 3D Climate Holo Globe model.
15. [x] ChoicePoint (Area3D): @export choice_id: StringName, @export hope_reward: float. Locks player movement, runs pre choice 3D animation, zooms CameraRig, and opens bottom docked choice panel.
16. [ ] ChapterData (Resource): chapter_id, title_key, start_position, camera_bounds: Rect2, next_scene.
17. [x] ChapterGoal (Area3D): @export chapter_id: StringName, @export complete_on_choice: StringName. Freezes CameraRig, triggers Player.start_level_exit_walk, and emits chapter_completed.
18. [x] PenguinModel (Node3D): @export outline_width: float, @export outline_color: Color, set_walk_amount(amount: float) -> void, set_slide_amount(amount: float) -> void, set_push_amount(amount: float) -> void. Separated foot meshes with procedural waddle, foot swing, belly slide, and snowball pushing animation.
19. [x] WindZone (Area3D): @export zone_id: StringName, @export push_speed: float, @export size: Vector3, is_gusting: bool. Pushes player sideways with timed gusts and streak particles.
20. [x] HutLamp (Node3D): @export choice_id: StringName, @export on_option_id: StringName. Lights solar lamp in cabin on lamp connect choice.
21. [x] Ending (Node3D): centered summit diorama with hope tier ending sequence, character celebration, rescued companions, and tier text cards.
22. [x] Credits (CanvasLayer): rolling credits, thanks message, and return to main menu.
23. [x] HopeGrade (Node): @export world_environment: WorldEnvironment, @export directional_light: DirectionalLight3D. Smoothly tweens environment adjustment saturation and ambient light color on EventBus.hope_changed.
24. [x] VFX: SnowParticles (CPUParticles3D) for ambient snowfall; MeltDripParticles (CPUParticles3D) for melting IceTile droplets.
25. [x] SlideSwoopRamp (Node3D): @export launch_vel_x: float, @export launch_vel_y: float, @export prompt_key: StringName. Curved downhill and uphill ice ramp that launches sliding players across a gap.
26. [x] ThermalVent (Area3D): @export lift_velocity: float, @export vent_height: float, @export cooling_rate: float. Upward warm air column that lifts the player and cools heat slightly.
27. [x] TiltingBridge (Node3D): @export bridge_length: float, @export max_tilt_degrees: float, @export tilt_speed: float. See saw ice plank that tilts under player offset weight.
28. [x] IceBoulder (Node3D): @export max_push_distance: float, @export push_speed: float, @export boulder_radius: float. Pushable snowball boulder for step puzzles.
29. [x] MovingPlatform (Node3D): @export move_offset: Vector3, @export cycle_duration: float, @export platform_width: float. Oscillating ice floe platform that carries the player.

## Couplings the scanner cannot see
(Fill as they appear. Also record in memory graph as scene_couples_to.)
1. CameraRig finds the first node in group player when target is not assigned.
2. Player flips child VisualRoot on the x scale according to facing direction and scales child PenguinModel for jump and land squash and stretch.
3. HeatComponent calls die on its parent node when heat reaches heat_max.
4. HeatZone searches entering player body children for a HeatComponent node.
5. Respawn finds the first node in group player when player is not assigned and searches group checkpoint by checkpoint_id.
6. IceTile checks overlapping HeatZone areas with positive rate on StepDetector to apply sun_multiplier.
7. FactCard registers static source lookup used by Hud on fact_collected.
8. ChoicePoint locks player movement, calls focus_on on group camera_rig, calls hide_immediately on group monologue_ui, adds hope_reward to GameState, and emits choice_made.
9. ChapterGoal emits chapter_completed to open completion summary on Hud across chapters 1 to 4 or transitions to ending on chapter_5.
10. LitterItem and SortingBin inspect entering player body is_carrying and carried_item_type properties.
11. LitterGate checks group gate for earlier closed gates by x position so gates open sequentially.
12. WindZone calls set_push and clear_push on entering player bodies.
13. HutLamp connects to EventBus.choice_made for the lamp choice.
14. SlideSwoopRamp checks player is_sliding on LaunchArea and calls apply_launch_boost.

## Decisions
1. Perspective camera FOV about 25, not orthogonal.
2. Compatibility renderer.
3. Hope is narrative only, never a fail state.
4. Litter is carried one item at a time.
