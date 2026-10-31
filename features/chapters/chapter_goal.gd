class_name ChapterGoal
extends Area3D
## Triggers chapter completion when the player enters the area.

@export var chapter_id: StringName = &"chapter_1"

var _completed: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _completed:
		return
	if not body.is_in_group(&"player"):
		return
	_completed = true
	EventBus.chapter_completed.emit(chapter_id)
