class_name ThermalVent
extends Area3D
## Updraft geyser that launches the player upward into the air with steam particles.

@export var updraft_speed: float = 11.4
@export var horizontal_nudge: float = 0.0

var _cooldown: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
		return
	for body: Node3D in get_overlapping_bodies():
		if body.is_in_group(&"player"):
			_boost_player(body)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(&"player"):
		return
	_boost_player(body)


func _boost_player(body: Node3D) -> void:
	if _cooldown > 0.0:
		return
	if not body.has_method(&"apply_launch_boost"):
		return
	_cooldown = 0.38
	var vx: float = horizontal_nudge
	if is_zero_approx(vx) and body is CharacterBody3D:
		vx = (body as CharacterBody3D).velocity.x
	body.call(&"apply_launch_boost", vx, updraft_speed)
