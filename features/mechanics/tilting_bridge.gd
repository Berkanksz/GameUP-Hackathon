class_name TiltingBridge
extends Node3D
## Dynamic seesaw bridge that stays horizontal until stepped on and tilts downward under the player's weight.

@export var max_tilt_degrees: float = 8.5
@export var tilt_speed: float = 4.5
@export var half_span: float = 2.8

var _player_on_bridge: Node3D = null

@onready var _plank: StaticBody3D = $PlankBody
@onready var _detector: Area3D = $PlankBody/DetectorArea


func _ready() -> void:
	if _plank != null:
		_plank.rotation_degrees.z = 0.0
	if _detector != null:
		_detector.body_entered.connect(_on_body_entered)
		_detector.body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if _plank == null:
		return
	var target_deg: float = 0.0
	if _player_on_bridge != null and is_instance_valid(_player_on_bridge):
		var above_plank: bool = _player_on_bridge.global_position.y >= global_position.y - 0.05
		if above_plank:
			var offset_x: float = _player_on_bridge.global_position.x - global_position.x
			var norm_x: float = clampf(offset_x / maxf(half_span, 0.5), -1.0, 1.0)
			# In Godot 3D (+X right, +Y up, +Z toward viewer), positive Z rotation lowers -X (left) and negative Z rotation lowers +X (right).
			target_deg = -norm_x * max_tilt_degrees
	_plank.rotation_degrees.z = move_toward(_plank.rotation_degrees.z, target_deg, tilt_speed * max_tilt_degrees * delta)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player"):
		_player_on_bridge = body


func _on_body_exited(body: Node3D) -> void:
	if body == _player_on_bridge:
		_player_on_bridge = null
