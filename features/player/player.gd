class_name Player
extends CharacterBody3D
## Plane locked 2.5D player controller with coyote time, jump buffer, and single item carry.

enum State {
	IDLE,
	WALK,
	JUMP,
	FALL,
	CARRY,
	DEAD,
}

const DEFAULT_TUNING_PATH: String = "res://data/tuning.tres"
const COLOR_PAPER: Color = Color(0.18, 0.52, 0.88, 1.0)
const COLOR_PLASTIC: Color = Color(0.95, 0.78, 0.15, 1.0)
const COLOR_GLASS: Color = Color(0.20, 0.75, 0.38, 1.0)

@export var tuning: TuningData

var state: State = State.IDLE
var facing_direction: float = 1.0
var is_carrying: bool = false
var carried_item_type: StringName = &""

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _current_heat: float = 0.0
var _was_on_floor: bool = true
var _carry_visual: Node3D
var _carry_box: CSGBox3D
var _carry_label: Label3D
var _carry_material: StandardMaterial3D

@onready var _visual_root: Node3D = $VisualRoot
@onready var _penguin_model: Node3D = get_node_or_null("VisualRoot/PenguinModel")


func _ready() -> void:
	add_to_group(&"player")
	axis_lock_linear_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	if tuning == null:
		tuning = load(DEFAULT_TUNING_PATH) as TuningData
	_setup_carry_visual()
	EventBus.heat_changed.connect(_on_heat_changed)
	EventBus.litter_picked.connect(_on_litter_picked)
	EventBus.litter_sorted.connect(_on_litter_sorted)
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
	if is_on_floor() and not _was_on_floor:
		_animate_squash(Vector3(1.15, 0.85, 1.15))
	_was_on_floor = is_on_floor()
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


func _animate_squash(target_scale: Vector3) -> void:
	if _penguin_model == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_penguin_model, "scale", target_scale, 0.07)
	tween.tween_property(_penguin_model, "scale", Vector3.ONE, 0.14)


func _setup_carry_visual() -> void:
	_carry_visual = Node3D.new()
	_carry_visual.name = "CarryVisual"
	_carry_visual.position = Vector3(0.0, 2.05, 0.0)
	_carry_visual.visible = false
	_carry_material = StandardMaterial3D.new()
	_carry_box = CSGBox3D.new()
	_carry_box.size = Vector3(0.42, 0.42, 0.42)
	_carry_box.material = _carry_material
	_carry_visual.add_child(_carry_box)
	_carry_label = Label3D.new()
	_carry_label.position = Vector3(0.0, 0.42, 0.0)
	_carry_label.pixel_size = 0.008
	_carry_label.font_size = 42
	_carry_label.outline_size = 10
	_carry_visual.add_child(_carry_label)
	add_child(_carry_visual)


func _on_litter_picked(type: StringName) -> void:
	is_carrying = true
	carried_item_type = type
	if _carry_visual == null:
		return
	_carry_visual.visible = true
	if type == &"paper":
		_carry_material.albedo_color = COLOR_PAPER
		_carry_label.text = "◼"
	elif type == &"plastic":
		_carry_material.albedo_color = COLOR_PLASTIC
		_carry_label.text = "▲"
	else:
		_carry_material.albedo_color = COLOR_GLASS
		_carry_label.text = "●"


func _on_litter_sorted(_type: StringName, _correct: bool) -> void:
	is_carrying = false
	carried_item_type = &""
	if _carry_visual != null:
		_carry_visual.visible = false


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
		_animate_squash(Vector3(0.86, 1.18, 0.86))
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
