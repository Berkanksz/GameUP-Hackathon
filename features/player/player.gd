class_name Player
extends CharacterBody3D
## Plane locked 2.5D player controller with coyote time, jump buffer, boulder pushing, and single item carry.

enum State {
	IDLE,
	WALK,
	SLIDE,
	JUMP,
	FALL,
	CARRY,
	DEAD,
}

const DEFAULT_TUNING_PATH: String = "res://data/tuning.tres"
const MODEL_PAPER: PackedScene = preload("res://assets/models/litter/litter_box.glb")
const MODEL_PLASTIC: PackedScene = preload("res://assets/models/litter/litter_bottle.glb")
const MODEL_GLASS: PackedScene = preload("res://assets/models/litter/litter_jar.glb")
const COLOR_PAPER: Color = Color(0.18, 0.52, 0.88, 1.0)
const COLOR_PLASTIC: Color = Color(0.95, 0.78, 0.15, 1.0)
const COLOR_GLASS: Color = Color(0.20, 0.75, 0.38, 1.0)

@export var tuning: TuningData
@export var fall_death_y: float = -2.2
@export var slide_speed_multiplier: float = 1.45

var state: State = State.IDLE
var facing_direction: float = 1.0
var is_carrying: bool = false
var carried_item_type: StringName = &""
var is_cinematic_locked: bool = false
var is_pushing_object: bool = false

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _current_heat: float = 0.0
var _was_on_floor: bool = true
var _is_sliding_active: bool = false
var _is_exit_walking: bool = false
var _carry_visual: Node3D
var _carry_paper: Node3D
var _carry_plastic: Node3D
var _carry_glass: Node3D
var _carry_label: Label3D
var _push_sources: Dictionary = {}
var _step_timer: float = 0.0

@onready var _visual_root: Node3D = $VisualRoot
@onready var _penguin_model: PenguinModel = get_node_or_null("VisualRoot/PenguinModel") as PenguinModel
@onready var _heat_comp: HeatComponent = get_node_or_null("HeatComponent") as HeatComponent


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
	if _heat_comp != null:
		_heat_comp.heat = 0.14
		EventBus.heat_changed.emit(_heat_comp.heat)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if _is_exit_walking:
		_is_sliding_active = false
		facing_direction = 1.0
		if _visual_root != null:
			_visual_root.scale.x = 1.0
		velocity.x = move_toward(velocity.x, tuning.walk_speed * 1.18, tuning.walk_acceleration * delta)
		_apply_gravity(delta)
		move_and_slide()
		global_position.z = 0.0
		velocity.z = 0.0
		state = State.WALK
		_update_walk_anim()
		_update_footsteps(delta)
		return
	if global_position.y < fall_death_y:
		die(&"fall")
		return
	if is_cinematic_locked:
		_is_sliding_active = false
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
		_apply_gravity(delta)
		move_and_slide()
		global_position.z = 0.0
		velocity.z = 0.0
		state = State.IDLE
		_update_walk_anim()
		return
	_update_timers(delta)
	_apply_gravity(delta)
	_handle_jump()
	_handle_horizontal(delta)
	var push_x: float = _get_push_x()
	velocity.x += push_x
	move_and_slide()
	velocity.x -= push_x
	if is_on_wall() and not is_zero_approx(push_x):
		velocity.x = 0.0
	global_position.z = 0.0
	velocity.z = 0.0
	if global_position.y < fall_death_y:
		die(&"fall")
		return
	if is_on_floor() and not _was_on_floor:
		_animate_squash(Vector3(1.15, 0.85, 1.15))
		Audio.play_sfx(&"land")
	_was_on_floor = is_on_floor()
	_update_state()
	_update_exertion_heat()
	_update_walk_anim()
	_update_footsteps(delta)


## Adds or replaces an external horizontal push speed, for example wind.
func set_push(source_id: StringName, speed_x: float) -> void:
	_push_sources[source_id] = speed_x


## Removes an external push source.
func clear_push(source_id: StringName) -> void:
	_push_sources.erase(source_id)


## Sets whether the penguin is actively pushing a heavy object such as a snow boulder.
func set_pushing_object(pushing: bool) -> void:
	is_pushing_object = pushing


## Starts the automatic rightward walk-off sequence at the end of a chapter.
func start_level_exit_walk() -> void:
	_is_exit_walking = true
	is_cinematic_locked = false
	is_pushing_object = false
	_is_sliding_active = false
	facing_direction = 1.0
	if _visual_root != null:
		_visual_root.scale.x = 1.0


## Locks or unlocks player movement and input during interactive cinematics.
func set_cinematic_lock(locked: bool) -> void:
	is_cinematic_locked = locked
	if locked:
		_is_sliding_active = false
		is_pushing_object = false
		velocity.x = 0.0
		state = State.IDLE
		_update_walk_anim()


## Returns true if the player is currently belly-sliding.
func is_sliding() -> bool:
	return _is_sliding_active or state == State.SLIDE


## Applies an immediate launch velocity for ski-jump ramps or thermal updrafts.
func apply_launch_boost(vel_x: float, vel_y: float) -> void:
	velocity.x = vel_x
	velocity.y = vel_y
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	if not is_zero_approx(vel_x):
		facing_direction = signf(vel_x)
		if _visual_root != null:
			_visual_root.scale.x = facing_direction
	_animate_squash(Vector3(0.84, 1.22, 0.84))
	Audio.play_sfx(&"jump")


## Resets the player state and moves to the target world position on the z plane.
func respawn_at(target_position: Vector3) -> void:
	global_position = Vector3(target_position.x, target_position.y, 0.0)
	velocity = Vector3.ZERO
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_is_exit_walking = false
	is_pushing_object = false
	if _penguin_model != null:
		_penguin_model.rotation_degrees.x = 0.0
		_penguin_model.position.y = 0.0
	state = State.IDLE


## Marks the player dead and notifies listeners through EventBus.
func die(reason: StringName) -> void:
	if state == State.DEAD or _is_exit_walking:
		return
	state = State.DEAD
	velocity = Vector3.ZERO
	if reason == &"overheat" and _penguin_model != null:
		var tween: Tween = create_tween()
		tween.tween_property(_penguin_model, "rotation_degrees:x", 65.0, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(_penguin_model, "position:y", -0.16, 0.32)
	EventBus.player_died.emit(reason)


func _update_exertion_heat() -> void:
	if _heat_comp == null:
		return
	if _is_sliding_active and absf(velocity.x) > 0.2:
		_heat_comp.set_rate(&"exertion", -0.28)
	elif is_pushing_object and absf(velocity.x) > 0.05:
		_heat_comp.set_rate(&"exertion", 0.12 if _heat_comp.heat < 0.40 else 0.0)
	elif not is_on_floor():
		_heat_comp.set_rate(&"exertion", 0.08 if _heat_comp.heat < 0.35 else 0.0)
	elif absf(velocity.x) > 0.2:
		_heat_comp.set_rate(&"exertion", 0.06 if _heat_comp.heat < 0.30 else 0.0)
	else:
		if _heat_comp.heat > 0.12:
			_heat_comp.clear_rate(&"exertion")
		else:
			_heat_comp.set_rate(&"exertion", 0.03 if _heat_comp.heat < 0.10 else 0.0)


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
	_carry_paper = MODEL_PAPER.instantiate() as Node3D
	_carry_paper.scale = Vector3(1.4, 1.4, 1.4)
	_carry_paper.position = Vector3(0.0, -0.25, 0.0)
	_carry_visual.add_child(_carry_paper)
	_carry_plastic = MODEL_PLASTIC.instantiate() as Node3D
	_carry_plastic.scale = Vector3(1.4, 1.4, 1.4)
	_carry_plastic.position = Vector3(0.0, -0.3, 0.0)
	_carry_visual.add_child(_carry_plastic)
	_carry_glass = MODEL_GLASS.instantiate() as Node3D
	_carry_glass.scale = Vector3(1.4, 1.4, 1.4)
	_carry_glass.position = Vector3(0.0, -0.3, 0.0)
	_carry_visual.add_child(_carry_glass)
	_carry_label = Label3D.new()
	_carry_label.position = Vector3(0.0, 0.58, 0.0)
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
	if _carry_paper != null:
		_carry_paper.visible = (type == &"paper")
	if _carry_plastic != null:
		_carry_plastic.visible = (type == &"plastic")
	if _carry_glass != null:
		_carry_glass.visible = (type == &"glass")
	if type == &"paper":
		_carry_label.modulate = COLOR_PAPER
		_carry_label.text = "◼"
	elif type == &"plastic":
		_carry_label.modulate = COLOR_PLASTIC
		_carry_label.text = "▲"
	else:
		_carry_label.modulate = COLOR_GLASS
		_carry_label.text = "●"


func _on_litter_sorted(_type: StringName, correct: bool) -> void:
	if not correct:
		return
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


func _is_slide_pressed() -> bool:
	return (InputMap.has_action(&"slide") and Input.is_action_pressed(&"slide")) or Input.is_physical_key_pressed(KEY_SHIFT)


func _handle_horizontal(delta: float) -> void:
	var input_axis: float = Input.get_axis(&"move_left", &"move_right")
	var on_ground: bool = is_on_floor()
	_is_sliding_active = _is_slide_pressed() and not is_pushing_object
	var accel: float = tuning.walk_acceleration if on_ground else tuning.air_acceleration
	var fric: float = tuning.walk_friction if on_ground else tuning.air_friction
	if _is_sliding_active and is_zero_approx(input_axis):
		input_axis = facing_direction
	if not is_zero_approx(input_axis):
		var speed_mult: float = tuning.heat_slow_multiplier if _current_heat >= tuning.heat_slow_threshold else 1.0
		if _is_sliding_active:
			speed_mult *= slide_speed_multiplier
		velocity.x = move_toward(velocity.x, input_axis * tuning.walk_speed * speed_mult, accel * delta)
		facing_direction = signf(input_axis)
		if _visual_root != null:
			_visual_root.scale.x = facing_direction
	else:
		var slide_fric: float = fric * 0.35 if _is_sliding_active else fric
		velocity.x = move_toward(velocity.x, 0.0, slide_fric * delta)


func _update_state() -> void:
	if not is_on_floor():
		state = State.JUMP if velocity.y > 0.0 else State.FALL
		return
	if _is_sliding_active and absf(velocity.x) > 0.1:
		state = State.SLIDE
	elif is_carrying:
		state = State.CARRY
	elif absf(velocity.x) > 0.1:
		state = State.WALK
	else:
		state = State.IDLE


func _get_push_x() -> float:
	var total: float = 0.0
	for speed: float in _push_sources.values():
		if _is_sliding_active and speed < 0.0:
			total += speed * 0.45
		else:
			total += speed
	return total


func _update_walk_anim() -> void:
	if _penguin_model == null:
		return
	var amount: float = 0.0
	if is_on_floor() and tuning.walk_speed > 0.0:
		amount = absf(velocity.x) / tuning.walk_speed
	_penguin_model.set_walk_amount(amount)
	_penguin_model.set_slide_amount(1.0 if _is_sliding_active else 0.0)
	_penguin_model.set_push_amount(1.0 if (is_pushing_object and absf(velocity.x) > 0.05) else 0.0)
	if _carry_visual != null:
		_carry_visual.position.y = 1.32 if _is_sliding_active else 2.05


func _on_heat_changed(value: float) -> void:
	_current_heat = value


func _update_footsteps(delta: float) -> void:
	if not is_on_floor():
		_step_timer = 0.0
		return
	if state == State.SLIDE:
		_step_timer += delta
		if _step_timer >= 0.48:
			_step_timer = 0.0
			Audio.play_sfx(&"snow_step")
	elif state == State.WALK or state == State.CARRY:
		var speed_ratio: float = absf(velocity.x) / maxf(tuning.walk_speed, 0.1)
		_step_timer += delta * maxf(speed_ratio, 0.5)
		if _step_timer >= 0.32:
			_step_timer = 0.0
			Audio.play_sfx(&"snow_step")
	else:
		_step_timer = 0.25
