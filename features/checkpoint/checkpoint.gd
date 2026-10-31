class_name Checkpoint
extends Area3D
## Cairn checkpoint area that emits checkpoint_reached when entered by the player.

const INACTIVE_COLOR: Color = Color(0.55, 0.62, 0.68, 1.0)
const ACTIVE_COLOR: Color = Color(1.0, 0.78, 0.28, 1.0)

@export var checkpoint_id: StringName = &"cp_1"

var is_active: bool = false

@onready var _top_stone: GeometryInstance3D = get_node_or_null("TopStone") as GeometryInstance3D
@onready var _beacon_light: OmniLight3D = get_node_or_null("BeaconLight") as OmniLight3D


func _ready() -> void:
	add_to_group(&"checkpoint")
	body_entered.connect(_on_body_entered)
	EventBus.checkpoint_reached.connect(_on_checkpoint_reached)
	_update_visual()


func _on_body_entered(body: Node3D) -> void:
	if body == null or not body.is_in_group(&"player"):
		return
	EventBus.checkpoint_reached.emit(checkpoint_id)


func _on_checkpoint_reached(reached_id: StringName) -> void:
	is_active = (reached_id == checkpoint_id)
	_update_visual()


func _update_visual() -> void:
	if _beacon_light != null:
		_beacon_light.visible = is_active
	if _top_stone != null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = ACTIVE_COLOR if is_active else INACTIVE_COLOR
		_top_stone.material_override = mat
