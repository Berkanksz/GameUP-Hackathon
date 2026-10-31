class_name LitterGate
extends StaticBody3D
## Trash pile barrier that opens after a required number of items are sorted.

@export var gate_id: StringName = &"c2_gate_1"
@export var required_count: int = 3

var is_open: bool = false
var current_count: int = 0

@onready var _collision_shape: CollisionShape3D = %CollisionShape3D
@onready var _visual_root: Node3D = %VisualRoot
@onready var _count_label: Label3D = %CountLabel


func _ready() -> void:
	add_to_group(&"gate")
	EventBus.litter_sorted.connect(_on_litter_sorted)
	_update_label()


## Opens the gate barrier, disables collision, and emits gate_opened.
func open_gate() -> void:
	if is_open:
		return
	is_open = true
	_update_label()
	if _collision_shape != null:
		_collision_shape.set_deferred(&"disabled", true)
	if _visual_root != null:
		var tween: Tween = create_tween()
		tween.tween_property(_visual_root, "position:y", _visual_root.position.y - 4.2, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(func() -> void: _visual_root.visible = false)
	EventBus.gate_opened.emit(gate_id)
	EventBus.monologue_requested.emit(&"MONO_C2_GATE")


func _on_litter_sorted(_type: StringName, _correct: bool) -> void:
	if is_open:
		return
	if _has_earlier_closed_gate():
		return
	current_count += 1
	_update_label()
	if current_count >= required_count:
		open_gate()


func _has_earlier_closed_gate() -> bool:
	for node: Node in get_tree().get_nodes_in_group(&"gate"):
		if node == self or not (node is Node3D):
			continue
		var other_gate: Node3D = node as Node3D
		if other_gate.global_position.x < global_position.x - 0.1 and not bool(other_gate.get("is_open")):
			return true
	return false


func _update_label() -> void:
	if _count_label == null:
		return
	if is_open:
		_count_label.visible = false
	else:
		_count_label.text = "%d / %d" % [current_count, required_count]
