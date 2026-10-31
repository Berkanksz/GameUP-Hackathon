# PROJECT MAP

Purpose: module contracts and intent. The agent reads this instead of the whole project. Keep it current, short, and truthful. Structure facts live in GRAPH.md (auto generated).
Status marks: [ ] planned, [x] built.

## Signals (EventBus)
| Signal | Payload | Emitted by | Heard by |
|---|---|---|---|
| player_died | reason: StringName | player | respawn, hud |
| player_respawned | checkpoint_id: StringName | respawn | heat, camera |
| heat_changed | value: float | heat component | hud, look |
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
3. [x] Audio: play_sfx(key: StringName) -> void, play_music(key: StringName) -> void.

### features
1. [x] Player: respawn_at(target_position: Vector3) -> void, die(reason: StringName) -> void. Group: player.
2. [x] CameraRig: @export target: Node3D, @export bounds: Rect2, @export use_bounds: bool, set_bounds(new_bounds: Rect2) -> void, snap_to_target() -> void.
3. [ ] HeatComponent: set_rate(source_id: StringName, rate: float) -> void, clear_rate(source_id: StringName) -> void, heat: float.
4. [ ] HeatZone (Area3D): @export rate: float, @export zone_id: StringName. Registers with the HeatComponent of the player body that enters.
5. [ ] IceTile (StaticBody3D): @export melt_time: float, @export respawn_time: float, @export sun_multiplier: float.
6. [ ] Checkpoint (Area3D): @export checkpoint_id: StringName. Group: checkpoint.
7. [ ] LitterItem (Area3D): @export litter_type: StringName (paper, plastic, glass). Group: litter.
8. [ ] SortingBin (Area3D): @export accepts: StringName. Group: bin.
9. [ ] LitterGate: @export gate_id: StringName, @export required_count: int. Group: gate.
10. [ ] NarrativeTrigger (Area3D): @export key: StringName, @export once: bool.
11. [ ] MonologueUI: listens to monologue_requested, picks key variant by hope tier (_LOW, _MID, _HIGH suffix if present, else base key).
12. [ ] FactCard: @export fact_key: StringName, @export source_label: String.
13. [ ] ChoicePoint: @export choice_id: StringName, @export hope_reward: float.
14. [ ] ChapterData (Resource): chapter_id, title_key, start_position, camera_bounds: Rect2, next_scene.

## Couplings the scanner cannot see
(Fill as they appear. Also record in memory graph as scene_couples_to.)
1. CameraRig finds the first node in group player when target is not assigned.
2. Player flips child VisualRoot on the x scale according to facing direction.

## Decisions
1. Perspective camera FOV about 25, not orthogonal.
2. Compatibility renderer.
3. Hope is narrative only, never a fail state.
4. Litter is carried one item at a time.
