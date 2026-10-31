class_name NarrativeTrigger
extends Area3D
## Triggers a monologue subtitle when the player enters the area.

@export var key: StringName = &""
@export var once: bool = true

var _triggered: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _triggered and once:
		return
	if not body.is_in_group(&"player"):
		return
	_triggered = true
	if not key.is_empty():
		EventBus.monologue_requested.emit(key)
