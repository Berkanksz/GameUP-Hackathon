class_name ChoicePoint
extends Area3D
## Interactive narrative decision point with pre-choice cinematic, camera zoom, player lock, and choice dock.

@export var choice_id: StringName = &"chick"
@export var hope_reward: float = 15.0
@export var prompt_key: StringName = &"CHOICE_CHICK_PROMPT"
@export var option_a_key: StringName = &"CHOICE_CHICK_HELP"
@export var option_b_key: StringName = &"CHOICE_CHICK_SKIP"
@export var option_a_id: StringName = &"help"
@export var option_b_id: StringName = &"skip"
@export var success_monologue_key: StringName = &"CHOICE_CHICK_SAVED"

var _has_chosen: bool = false
var _cinematic_running: bool = false
var _locked_player: Node3D = null

@onready var _choice_layer: CanvasLayer = %ChoiceLayer
@onready var _panel_container: PanelContainer = get_node_or_null("%PanelContainer")
@onready var _prompt_label: Label = %PromptLabel
@onready var _option_a_button: Button = %OptionAButton
@onready var _option_b_button: Button = %OptionBButton
@onready var _chick_model: Node3D = %ChickModel
@onready var _seed_patch_model: Node3D = get_node_or_null("%SeedPatchModel")
@onready var _buoy_model: Node3D = get_node_or_null("%BuoyModel")
@onready var _tower_model: Node3D = get_node_or_null("%TowerModel")
@onready var _sprout_model: Node3D = get_node_or_null("%SproutModel")
@onready var _floe_base: Node3D = get_node_or_null("FloeBase")


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	_choice_layer.visible = false
	_option_a_button.pressed.connect(_on_option_a_pressed)
	_option_b_button.pressed.connect(_on_option_b_pressed)
	EventBus.language_changed.connect(_on_language_changed)
	_refresh_text()
	_configure_visuals_for_type()
	var flag_a: StringName = StringName("choice_" + str(choice_id) + "_" + str(option_a_id))
	var flag_b: StringName = StringName("choice_" + str(choice_id) + "_" + str(option_b_id))
	if GameState.has_flag(flag_a):
		_has_chosen = true
		if choice_id == &"chick" and _chick_model != null:
			_chick_model.visible = false
		elif choice_id == &"seed" and _sprout_model != null:
			_sprout_model.visible = true
	elif GameState.has_flag(flag_b):
		_has_chosen = true


func _configure_visuals_for_type() -> void:
	if _chick_model != null:
		_chick_model.visible = (choice_id == &"chick")
	if _floe_base != null:
		_floe_base.visible = (choice_id == &"chick" or choice_id == &"buoy")
	if _seed_patch_model != null:
		_seed_patch_model.visible = (choice_id == &"seed")
	if _buoy_model != null:
		_buoy_model.visible = (choice_id == &"buoy")
	if _tower_model != null:
		_tower_model.visible = (choice_id == &"tower")


func _on_body_entered(body: Node3D) -> void:
	if _has_chosen or _cinematic_running:
		return
	if not body.is_in_group(&"player"):
		return
	_start_interaction_cinematic(body)


func _start_interaction_cinematic(player_body: Node3D) -> void:
	_cinematic_running = true
	_locked_player = player_body
	if _locked_player != null and _locked_player.has_method(&"set_cinematic_lock"):
		_locked_player.call(&"set_cinematic_lock", true)
	for mono: Node in get_tree().get_nodes_in_group(&"monologue_ui"):
		if mono.has_method(&"hide_immediately"):
			mono.call(&"hide_immediately")

	var cam_rig: Node = get_tree().get_first_node_in_group(&"camera_rig")
	var focus_target: Vector3 = global_position + Vector3(0.0, 0.35, 0.0)
	var target_fov: float = 14.5
	if choice_id == &"lamp":
		focus_target = global_position + Vector3(-0.4, 0.85, 0.0)
		target_fov = 15.5
	if cam_rig != null and cam_rig.has_method(&"focus_on"):
		cam_rig.call(&"focus_on", focus_target, target_fov, 0.65)

	var cine: Tween = create_tween()
	if choice_id == &"chick" and _chick_model != null:
		Audio.play_sfx(&"ice_crack")
		var base_y: float = _chick_model.position.y
		if _floe_base != null:
			cine.tween_property(_floe_base, "rotation_degrees:z", -6.5, 0.14)
			cine.tween_property(_floe_base, "rotation_degrees:z", 5.5, 0.14)
			cine.tween_property(_floe_base, "rotation_degrees:z", -3.0, 0.12)
		# Chick slips into cracking ice crust and wiggles frantically
		cine.parallel().tween_property(_chick_model, "position:y", base_y - 0.08, 0.22)
		cine.tween_property(_chick_model, "rotation_degrees:z", 14.0, 0.11)
		cine.tween_property(_chick_model, "rotation_degrees:z", -14.0, 0.11)
		cine.tween_property(_chick_model, "rotation_degrees:z", 10.0, 0.11)
		cine.tween_property(_chick_model, "rotation_degrees:z", 0.0, 0.11)
	elif choice_id == &"seed" and _seed_patch_model != null:
		Audio.play_sfx(&"pickup")
		cine.tween_property(_seed_patch_model, "scale", Vector3(1.62, 1.62, 1.62), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		cine.tween_property(_seed_patch_model, "scale", Vector3(1.4, 1.4, 1.4), 0.22)
	elif choice_id == &"buoy" and _buoy_model != null:
		Audio.play_sfx(&"ice_crack")
		cine.tween_property(_buoy_model, "rotation_degrees:z", -12.0, 0.18)
		cine.tween_property(_buoy_model, "rotation_degrees:z", 9.0, 0.18)
		cine.tween_property(_buoy_model, "rotation_degrees:z", -5.0, 0.16)
	elif choice_id == &"tower" and _tower_model != null:
		Audio.play_sfx(&"ice_crack")
		cine.tween_property(_tower_model, "rotation_degrees:z", 10.0, 0.22)
		cine.tween_property(_tower_model, "rotation_degrees:z", 6.0, 0.20)
	else:
		Audio.play_sfx(&"pickup")
		cine.tween_interval(0.45)

	cine.tween_callback(_open_dialog)


func _open_dialog() -> void:
	_choice_layer.visible = true
	if _panel_container != null:
		_panel_container.modulate.a = 0.0
		var ui_tween: Tween = create_tween()
		ui_tween.tween_property(_panel_container, "modulate:a", 1.0, 0.22)
	_option_a_button.grab_focus()


func _release_cinematic() -> void:
	_cinematic_running = false
	var cam_rig: Node = get_tree().get_first_node_in_group(&"camera_rig")
	if cam_rig != null and cam_rig.has_method(&"release_focus"):
		cam_rig.call(&"release_focus", 0.55)
	if _locked_player != null and is_instance_valid(_locked_player) and _locked_player.has_method(&"set_cinematic_lock"):
		_locked_player.call(&"set_cinematic_lock", false)
	_locked_player = null


func _on_option_a_pressed() -> void:
	if _has_chosen:
		return
	_has_chosen = true
	_choice_layer.visible = false
	GameState.add_hope(hope_reward)
	EventBus.choice_made.emit(choice_id, option_a_id)
	Audio.play_sfx(&"sort_ok")

	var out_tween: Tween = create_tween()
	if choice_id == &"seed" and _sprout_model != null:
		_sprout_model.visible = true
		_sprout_model.scale = Vector3(0.01, 0.01, 0.01)
		out_tween.tween_property(_sprout_model, "scale", Vector3(1.55, 1.55, 1.55), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		out_tween.tween_interval(0.25)
	elif choice_id == &"chick" and _chick_model != null and _chick_model.visible:
		if _floe_base != null:
			_floe_base.rotation_degrees.z = 0.0
		var start_y: float = 0.14
		out_tween.tween_property(_chick_model, "position:y", start_y + 0.85, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		out_tween.tween_property(_chick_model, "position:y", start_y, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(_chick_model, "position:x", _chick_model.position.x + 2.6, 0.42)
		out_tween.parallel().tween_property(_chick_model, "scale", Vector3(0.01, 0.01, 0.01), 0.42)
		out_tween.tween_callback(func() -> void: _chick_model.visible = false)
	elif choice_id == &"buoy" and _buoy_model != null:
		out_tween.tween_property(_buoy_model, "rotation_degrees:z", 0.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		out_tween.tween_property(_buoy_model, "position:y", 0.22, 0.2)
		out_tween.tween_property(_buoy_model, "position:y", 0.0, 0.2)
	elif choice_id == &"tower" and _tower_model != null:
		out_tween.tween_property(_tower_model, "rotation_degrees:z", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		out_tween.tween_interval(0.2)
	else:
		out_tween.tween_interval(0.35)

	out_tween.tween_callback(func() -> void:
		_release_cinematic()
		if not success_monologue_key.is_empty():
			EventBus.monologue_requested.emit(success_monologue_key)
	)


func _on_option_b_pressed() -> void:
	if _has_chosen:
		return
	_has_chosen = true
	_choice_layer.visible = false
	Audio.play_sfx(&"ui_click")
	EventBus.choice_made.emit(choice_id, option_b_id)
	_release_cinematic()


func _on_language_changed(_code: String) -> void:
	_refresh_text()


func _refresh_text() -> void:
	if _prompt_label != null:
		_prompt_label.text = tr(prompt_key)
	if _option_a_button != null:
		_option_a_button.text = tr(option_a_key)
	if _option_b_button != null:
		_option_b_button.text = tr(option_b_key)
