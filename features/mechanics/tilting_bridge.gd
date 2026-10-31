class_name TiltingBridge
extends Node3D
## Dynamic seesaw glacier bridge that tilts according to the player's horizontal position on the plank.

@export var max_tilt_degrees: float = 14.0
@export var tilt_speed: float = 5.5

var _player_on_bridge: Node3D = null

@onready var _plank: AnimatableBody3D = $PlankBody
@onready var _detector: Area3D = $DetectorArea


func _ready() -> void:
	if _detector != null:
		_detector.body_entered.connect(_on_body_entered)
		_detector.body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if _plank == null:
		return
	var target_deg: float = 0.0
	if _player_on_bridge != null and is_instance_valid(_player_on_bridge):
		var rel_x: float = clampf((_player_on_bridge.global_position.x - global_position.x) / 2.2, -1.0, 1.0)
		target_deg = -rel_x * max_tilt_degrees
	_plank.rotation_degrees.z = move_toward(_plank.rotation_degrees.z, target_deg, tilt_speed * max_tilt_degrees * delta)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player"):
		_player_on_bridge = body


func _on_body_exited(body: Node3D) -> void:
	if body == _player_on_bridge:
		_player_on_bridge = null
