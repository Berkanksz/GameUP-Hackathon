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
	_complete(body)


func _on_choice_made(choice_id: StringName, _option: StringName) -> void:
	if choice_id == complete_on_choice:
		var player: Node3D = get_tree().get_first_node_in_group(&"player") as Node3D
		_complete(player)


func _complete(player_body: Node3D = null) -> void:
	if _completed:
		return
	_completed = true
	for mono: Node in get_tree().get_nodes_in_group(&"monologue_ui"):
		if mono.has_method(&"hide_immediately"):
			mono.call(&"hide_immediately")
	if complete_on_choice.is_empty():
		var cam_rig: Node = get_tree().get_first_node_in_group(&"camera_rig")
		if cam_rig != null and cam_rig.has_method(&"freeze_at_current_position"):
			cam_rig.call(&"freeze_at_current_position")
		if player_body != null and player_body.has_method(&"start_level_exit_walk"):
			player_body.call(&"start_level_exit_walk")
	EventBus.chapter_completed.emit(chapter_id)
