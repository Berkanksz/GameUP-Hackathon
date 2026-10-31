class_name LitterGate
extends StaticBody3D
## Trash pile barrier that dispenses 3 recyclable items from the mound, shrinks as each item is taken, and opens when all 3 are sorted.

@export var gate_id: StringName = &"c2_gate_1"
@export var required_count: int = 3
@export var dispense_from_pile: bool = true
@export var play_intro_cinematic: bool = false

var is_open: bool = false
var current_count: int = 0

var _pile_queue: Array[StringName] = [&"paper", &"plastic", &"glass"]
var _intro_played: bool = false
var _player_near_pile: Node3D = null

@onready var _collision_shape: CollisionShape3D = %CollisionShape3D
@onready var _visual_root: Node3D = %VisualRoot
@onready var _count_label: Label3D = %CountLabel
@onready var _pickup_area: Area3D = get_node_or_null("%PilePickupArea")
@onready var _intro_area: Area3D = get_node_or_null("%IntroTriggerArea")
@onready var _paper_preview: Node3D = get_node_or_null("%PilePaperPreview")
@onready var _plastic_preview: Node3D = get_node_or_null("%PilePlasticPreview")
@onready var _glass_preview: Node3D = get_node_or_null("%PileGlassPreview")


func _ready() -> void:
	add_to_group(&"gate")
	EventBus.litter_sorted.connect(_on_litter_sorted)
	if _pickup_area != null:
		_pickup_area.body_entered.connect(_on_pickup_body_entered)
		_pickup_area.body_exited.connect(_on_pickup_body_exited)
	if _intro_area != null:
		_intro_area.body_entered.connect(_on_intro_body_entered)
	_update_label()
	_update_pile_previews()


func _physics_process(_delta: float) -> void:
	if is_open or not dispense_from_pile:
		return
	if _player_near_pile != null and is_instance_valid(_player_near_pile):
		_try_dispense_to_player(_player_near_pile)


## Opens the gate barrier, disables collision, and emits gate_opened.
func open_gate() -> void:
	if is_open:
		return
	is_open = true
	_update_label()
	if _collision_shape != null:
		_collision_shape.set_deferred(&"disabled", true)
	if _visual_root != null:
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(_visual_root, "scale", Vector3(0.02, 0.02, 0.02), 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(_visual_root, "position:y", -0.6, 0.38)
		tween.chain().tween_callback(func() -> void: _visual_root.visible = false)
	EventBus.gate_opened.emit(gate_id)
	EventBus.monologue_requested.emit(&"MONO_C2_GATE")


func _try_dispense_to_player(player_body: Node3D) -> void:
	if is_open or _pile_queue.is_empty():
		return
	if _has_earlier_closed_gate():
		return
	if bool(player_body.get("is_carrying")):
		return
	var next_item: StringName = _pile_queue.pop_front()
	EventBus.litter_picked.emit(next_item)
	Audio.play_sfx(&"pickup")
	_update_pile_previews()
	_shrink_pile_step()


func _shrink_pile_step() -> void:
	if _visual_root == null or is_open:
		return
	var remaining_in_pile: int = _pile_queue.size()
	var target_scale: Vector3 = Vector3.ONE
	if remaining_in_pile == 2:
		target_scale = Vector3(0.84, 0.72, 0.84)
	elif remaining_in_pile == 1:
		target_scale = Vector3(0.66, 0.48, 0.66)
	elif remaining_in_pile <= 0:
		target_scale = Vector3(0.42, 0.25, 0.42)
	var tween: Tween = create_tween()
	tween.tween_property(_visual_root, "scale", target_scale, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_pile_previews() -> void:
	if _paper_preview != null:
		_paper_preview.visible = _pile_queue.has(&"paper")
	if _plastic_preview != null:
		_plastic_preview.visible = _pile_queue.has(&"plastic")
	if _glass_preview != null:
		_glass_preview.visible = _pile_queue.has(&"glass")


func _on_pickup_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player"):
		_player_near_pile = body
		_try_dispense_to_player(body)


func _on_pickup_body_exited(body: Node3D) -> void:
	if body == _player_near_pile:
		_player_near_pile = null


func _on_intro_body_entered(body: Node3D) -> void:
	if _intro_played or is_open or not play_intro_cinematic:
		return
	if not body.is_in_group(&"player"):
		return
	_intro_played = true
	if body.has_method(&"set_cinematic_lock"):
		body.call(&"set_cinematic_lock", true)
	var cam_rig: Node = get_tree().get_first_node_in_group(&"camera_rig")
	if cam_rig != null and cam_rig.has_method(&"focus_on"):
		cam_rig.call(&"focus_on", global_position + Vector3(-2.5, 0.8, 0.0), 17.5, 0.55)
	Audio.play_sfx(&"ice_crack")
	EventBus.monologue_requested.emit(&"MONO_LITTER_PILE_INTRO")
	if _visual_root != null:
		var shake: Tween = create_tween()
		shake.tween_property(_visual_root, "rotation_degrees:z", -5.0, 0.12)
		shake.tween_property(_visual_root, "rotation_degrees:z", 5.0, 0.12)
		shake.tween_property(_visual_root, "rotation_degrees:z", 0.0, 0.12)
	var timer: SceneTreeTimer = get_tree().create_timer(1.65)
	timer.timeout.connect(func() -> void:
		if cam_rig != null and is_instance_valid(cam_rig) and cam_rig.has_method(&"release_focus"):
			cam_rig.call(&"release_focus", 0.5)
		if body != null and is_instance_valid(body) and body.has_method(&"set_cinematic_lock"):
			body.call(&"set_cinematic_lock", false)
	)


func _on_litter_sorted(_type: StringName, correct: bool) -> void:
	if is_open or not correct:
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
