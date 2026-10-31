class_name ChapterGoal
extends Area3D
## Triggers chapter completion when the player enters the area or a set choice is made.

@export var chapter_id: StringName = &"chapter_1"
## When set, completion waits for this choice_id instead of the player entering.
@export var complete_on_choice: StringName = &""

var _completed: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = complete_on_choice.is_empty()
	monitorable = false
	if complete_on_choice.is_empty():
		body_entered.connect(_on_body_entered)
	else:
		EventBus.choice_made.connect(_on_choice_made)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(&"player"):
		return
	_complete()


func _on_choice_made(choice_id: StringName, _option: StringName) -> void:
	if choice_id == complete_on_choice:
		_complete()


func _complete() -> void:
	if _completed:
		return
	_completed = true
	EventBus.chapter_completed.emit(chapter_id)
