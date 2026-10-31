class_name WindZone
extends Area3D
## Area that pushes the player sideways in timed gusts.

@export var zone_id: StringName = &"wind"
## Signed horizontal push speed. Negative pushes left.
@export var push_speed: float = -3.0
@export var size: Vector3 = Vector3(6.0, 6.0, 3.0)
@export var gust_on_time: float = 1.6
@export var gust_off_time: float = 1.4
@export var start_offset: float = 0.0
@export var ramp_time: float = 0.35

var is_gusting: bool = false

var _clock: float = 0.0
var _strength: float = 0.0
var _bodies: Array[Node3D] = []

@onready var _collision: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
@onready var _streaks: CPUParticles3D = get_node_or_null("Streaks") as CPUParticles3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_clock = start_offset
	_apply_size()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	var cycle: float = maxf(gust_on_time + gust_off_time, 0.01)
	_clock = fmod(_clock + delta, cycle)
	is_gusting = _clock < gust_on_time
	var target: float = 1.0 if is_gusting else 0.0
	_strength = move_toward(_strength, target, delta / maxf(ramp_time, 0.01))
	if _streaks != null:
		_streaks.emitting = is_gusting
	for body: Node3D in _bodies:
		if is_instance_valid(body):
			body.call(&"set_push", zone_id, push_speed * _strength)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(&"player") or not body.has_method(&"set_push"):
		return
	if not _bodies.has(body):
		_bodies.append(body)


func _on_body_exited(body: Node3D) -> void:
	if not _bodies.has(body):
		return
	_bodies.erase(body)
	if body.has_method(&"clear_push"):
		body.call(&"clear_push", zone_id)


func _apply_size() -> void:
	if _collision != null:
		var box := BoxShape3D.new()
		box.size = size
		_collision.shape = box
	if _streaks != null:
		_streaks.emission_box_extents = size * 0.5
		_streaks.direction = Vector3(signf(push_speed), 0.0, 0.0)
