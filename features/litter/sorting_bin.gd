class_name SortingBin
extends Area3D
## Color and icon coded recycling bin that sorts carried player litter on interact or matching contact.

const COLOR_PAPER: Color = Color(0.18, 0.52, 0.88, 1.0)
const COLOR_PLASTIC: Color = Color(0.95, 0.78, 0.15, 1.0)
const COLOR_GLASS: Color = Color(0.20, 0.75, 0.38, 1.0)

@export var accepts: StringName = &"paper"

var _player_in_range: Node3D = null
var _bin_material: StandardMaterial3D

@onready var _visual_root: Node3D = %VisualRoot
@onready var _bin_body: GeometryInstance3D = get_node_or_null("%BinBody") as GeometryInstance3D
@onready var _paper_model: Node3D = get_node_or_null("%PaperModel") as Node3D
@onready var _plastic_model: Node3D = get_node_or_null("%PlasticModel") as Node3D
@onready var _glass_model: Node3D = get_node_or_null("%GlassModel") as Node3D
@onready var _paper_badge: GeometryInstance3D = get_node_or_null("%PaperBadge") as GeometryInstance3D
@onready var _plastic_badge: GeometryInstance3D = get_node_or_null("%PlasticBadge") as GeometryInstance3D
@onready var _glass_badge: GeometryInstance3D = get_node_or_null("%GlassBadge") as GeometryInstance3D
@onready var _sign_label: Label3D = %SignLabel
@onready var _prompt_label: Label3D = %PromptLabel


func _ready() -> void:
	add_to_group(&"bin")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	EventBus.language_changed.connect(_on_language_changed)
	_apply_bin_visual()
	_refresh_text()


func _process(_delta: float) -> void:
	var can_sort: bool = _player_in_range != null and bool(_player_in_range.get("is_carrying"))
	if _prompt_label != null:
		_prompt_label.visible = can_sort
	if can_sort and Input.is_action_just_pressed(&"interact"):
		sort_from_player(_player_in_range)


## Sorts the item currently carried by player_node and emits litter_sorted.
func sort_from_player(player_node: Node3D) -> bool:
	if player_node == null or not bool(player_node.get("is_carrying")):
		return false
	var item_type: StringName = player_node.get("carried_item_type") as StringName
	var is_correct: bool = (item_type == accepts)
	EventBus.litter_sorted.emit(item_type, is_correct)
	Audio.play_sfx(&"sort_ok" if is_correct else &"sort_bad")
	EventBus.monologue_requested.emit(&"MONO_C2_SORT_OK" if is_correct else &"MONO_C2_SORT_BAD")
	if _visual_root != null:
		var tween: Tween = create_tween()
		tween.tween_property(_visual_root, "scale", Vector3(1.14, 0.86, 1.14), 0.09)
		tween.tween_property(_visual_root, "scale", Vector3.ONE, 0.14)
	return is_correct


func _apply_bin_visual() -> void:
	if _paper_model != null:
		_paper_model.visible = (accepts == &"paper")
	if _plastic_model != null:
		_plastic_model.visible = (accepts == &"plastic")
	if _glass_model != null:
		_glass_model.visible = (accepts == &"glass")
	_bin_material = StandardMaterial3D.new()
	_bin_material.roughness = 0.45
	if accepts == &"paper":
		_bin_material.albedo_color = COLOR_PAPER
	elif accepts == &"plastic":
		_bin_material.albedo_color = COLOR_PLASTIC
	else:
		_bin_material.albedo_color = COLOR_GLASS
	if _bin_body != null:
		_bin_body.material_override = _bin_material
	if _paper_badge != null:
		_paper_badge.visible = (accepts == &"paper")
	if _plastic_badge != null:
		_plastic_badge.visible = (accepts == &"plastic")
	if _glass_badge != null:
		_glass_badge.visible = (accepts == &"glass")


func _refresh_text() -> void:
	if _sign_label != null:
		if accepts == &"paper":
			_sign_label.text = "◼ %s" % tr("UI_BIN_PAPER")
			_sign_label.modulate = COLOR_PAPER.lightened(0.25)
		elif accepts == &"plastic":
			_sign_label.text = "▲ %s" % tr("UI_BIN_PLASTIC")
			_sign_label.modulate = COLOR_PLASTIC.lightened(0.2)
		else:
			_sign_label.text = "● %s" % tr("UI_BIN_GLASS")
			_sign_label.modulate = COLOR_GLASS.lightened(0.25)
	if _prompt_label != null:
		_prompt_label.text = "[E] %s" % tr("UI_HINT_INTERACT")


func _on_language_changed(_code: String) -> void:
	_refresh_text()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = body
		if bool(body.get("is_carrying")) and (body.get("carried_item_type") as StringName) == accepts:
			sort_from_player(body)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
