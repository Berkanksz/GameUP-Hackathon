class_name Player
extends CharacterBody3D
## Plane locked 2.5D player controller with coyote time and jump buffer.

enum State {
	IDLE,
	WALK,
	JUMP,
	FALL,
	CARRY,
	DEAD,
}

const DEFAULT_TUNING_PATH: String = "res://data/tuning.tres"

@export var tuning: TuningData

var state: State = State.IDLE
var facing_direction: float = 1.0
var is_carrying: bool = false

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _current_heat: float = 0.0

@onready var _visual_root: Node3D = $VisualRoot


func _ready() -> void:
	add_to_group(&"player")
	axis_lock_linear_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	if tuning == null:
		tuning = load(DEFAULT_TUNING_PATH) as TuningData
	EventBus.heat_changed.connect(_on_heat_changed)
	global_position.z = 0.0


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_update_timers(delta)
	_apply_gravity(delta)
	_handle_jump()
	_handle_horizontal(delta)
	move_and_slide()
	global_position.z = 0.0
	velocity.z = 0.0
	_update_state()


## Resets the player state and moves to the target world position on the z plane.
func respawn_at(target_position: Vector3) -> void:
	global_position = Vector3(target_position.x, target_position.y, 0.0)
	velocity = Vector3.ZERO
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	state = State.IDLE


## Marks the player dead and notifies listeners through EventBus.
func die(reason: StringName) -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	velocity = Vector3.ZERO
	EventBus.player_died.emit(reason)


func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = tuning.coyote_time
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)
	if Input.is_action_just_pressed(&"jump"):
		_jump_buffer_timer = tuning.jump_buffer_time
	else:
		_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var grav: float = tuning.gravity_up if velocity.y > 0.0 else tuning.gravity_down
	velocity.y = maxf(velocity.y - grav * delta, -tuning.max_fall_speed)


func _handle_jump() -> void:
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = tuning.jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		Audio.play_sfx(&"jump")
	if Input.is_action_just_released(&"jump") and velocity.y > 0.0:
		velocity.y *= tuning.jump_release_multiplier


func _handle_horizontal(delta: float) -> void:
	var input_axis: float = Input.get_axis(&"move_left", &"move_right")
	var on_ground: bool = is_on_floor()
	var accel: float = tuning.walk_acceleration if on_ground else tuning.air_acceleration
	var fric: float = tuning.walk_friction if on_ground else tuning.air_friction
	if not is_zero_approx(input_axis):
		var speed_mult: float = tuning.heat_slow_multiplier if _current_heat >= tuning.heat_slow_threshold else 1.0
		velocity.x = move_toward(velocity.x, input_axis * tuning.walk_speed * speed_mult, accel * delta)
		facing_direction = signf(input_axis)
		if _visual_root != null:
			_visual_root.scale.x = facing_direction
	else:
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)


func _update_state() -> void:
	if not is_on_floor():
		state = State.JUMP if velocity.y > 0.0 else State.FALL
		return
	if is_carrying:
		state = State.CARRY
	elif absf(velocity.x) > 0.1:
		state = State.WALK
	else:
		state = State.IDLE


func _on_heat_changed(value: float) -> void:
	_current_heat = value
