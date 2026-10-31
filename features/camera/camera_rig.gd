class_name CameraRig
extends Node3D
## Follows the player with directional lookahead and clamps to level bounds.

const DEFAULT_TUNING_PATH: String = "res://data/tuning.tres"

@export var target: Node3D
@export var bounds: Rect2 = Rect2(-20.0, -2.0, 60.0, 20.0)
@export var use_bounds: bool = true
@export var tuning: TuningData

var _lookahead: float = 0.0
var _cinematic_focus_active: bool = false
var _cinematic_focus_pos: Vector3 = Vector3.ZERO
var _frozen_for_exit: bool = false
var _fov_tween: Tween

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	add_to_group(&"camera_rig")
	if tuning == null:
		tuning = load(DEFAULT_TUNING_PATH) as TuningData
	if _camera != null and tuning != null:
		_camera.fov = tuning.camera_fov
	if target == null:
		_acquire_target()
	EventBus.player_respawned.connect(_on_player_respawned)
	snap_to_target()


func _physics_process(delta: float) -> void:
	if _frozen_for_exit:
		return
	if _cinematic_focus_active:
		var focus_desired: Vector3 = Vector3(
			_cinematic_focus_pos.x,
			_cinematic_focus_pos.y + 1.15,
			tuning.camera_offset.z if tuning != null else 22.0
		)
		global_position = global_position.lerp(focus_desired, clampf(7.5 * delta, 0.0, 1.0))
		return
	if target == null:
		_acquire_target()
		if target == null:
			return
	var dir: float = _get_target_direction()
	var desired_look: float = dir * tuning.camera_lookahead_x
	_lookahead = move_toward(_lookahead, desired_look, tuning.camera_lookahead_speed * delta)
	var desired_pos: Vector3 = _compute_desired_position(target.global_position.x + _lookahead, target.global_position.y)
	global_position = global_position.lerp(desired_pos, clampf(tuning.camera_follow_speed * delta, 0.0, 1.0))


## Smoothly zooms and centers the camera onto a world point for an interactive cinematic.
func focus_on(world_pos: Vector3, target_fov: float = 15.0, duration: float = 0.65) -> void:
	_cinematic_focus_active = true
	_cinematic_focus_pos = world_pos
	if _camera == null:
		return
	if _fov_tween != null and _fov_tween.is_valid():
		_fov_tween.kill()
	_fov_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_fov_tween.tween_property(_camera, "fov", target_fov, duration)


## Releases cinematic focus and restores normal camera FOV and player tracking.
func release_focus(duration: float = 0.55) -> void:
	_cinematic_focus_active = false
	if _camera == null or tuning == null:
		return
	if _fov_tween != null and _fov_tween.is_valid():
		_fov_tween.kill()
	_fov_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_fov_tween.tween_property(_camera, "fov", tuning.camera_fov, duration)


## Freezes the camera at its current position so the player can walk off the right edge of the frame.
func freeze_at_current_position() -> void:
	_frozen_for_exit = true
	_cinematic_focus_active = false


## Replaces the camera bounds rectangle and enables clamping.
func set_bounds(new_bounds: Rect2) -> void:
	bounds = new_bounds
	use_bounds = true


## Immediately places the camera rig at the clamped target position.
func snap_to_target() -> void:
	if target == null or tuning == null:
		return
	_lookahead = _get_target_direction() * tuning.camera_lookahead_x
	global_position = _compute_desired_position(target.global_position.x + _lookahead, target.global_position.y)


func _acquire_target() -> void:
	var node: Node = get_tree().get_first_node_in_group(&"player")
	if node is Node3D:
		target = node as Node3D


func _on_player_respawned(_checkpoint_id: StringName) -> void:
	snap_to_target()


func _get_target_direction() -> float:
	if target is CharacterBody3D:
		var body: CharacterBody3D = target as CharacterBody3D
		if absf(body.velocity.x) > 0.1:
			return signf(body.velocity.x)
	if &"facing_direction" in target:
		return float(target.get(&"facing_direction"))
	return 0.0


func _compute_desired_position(focus_x: float, focus_y: float) -> Vector3:
	var tx: float = focus_x + tuning.camera_offset.x
	var ty: float = focus_y + tuning.camera_offset.y
	if use_bounds and bounds.size.x > 0.0 and bounds.size.y > 0.0:
		tx = clampf(tx, bounds.position.x, bounds.position.x + bounds.size.x)
		ty = clampf(ty, bounds.position.y, bounds.position.y + bounds.size.y)
	return Vector3(tx, ty, tuning.camera_offset.z)
