class_name ChoicePoint
extends Area3D
## Interactive narrative decision point with prompt and choices.

@export var choice_id: StringName = &"chick"
@export var hope_reward: float = 15.0
@export var prompt_key: StringName = &"CHOICE_CHICK_PROMPT"
@export var option_a_key: StringName = &"CHOICE_CHICK_HELP"
@export var option_b_key: StringName = &"CHOICE_CHICK_SKIP"
@export var option_a_id: StringName = &"help"
@export var option_b_id: StringName = &"skip"
@export var success_monologue_key: StringName = &"CHOICE_CHICK_SAVED"

var _has_chosen: bool = false

@onready var _choice_layer: CanvasLayer = %ChoiceLayer
@onready var _prompt_label: Label = %PromptLabel
@onready var _option_a_button: Button = %OptionAButton
@onready var _option_b_button: Button = %OptionBButton
@onready var _chick_model: Node3D = %ChickModel
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
	if choice_id != &"chick":
		if _chick_model != null:
			_chick_model.visible = false
		if _floe_base != null:
			_floe_base.visible = false
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


func _on_body_entered(body: Node3D) -> void:
	if _has_chosen:
		return
	if not body.is_in_group(&"player"):
		return
	_open_dialog()


func _open_dialog() -> void:
	_choice_layer.visible = true
	_option_a_button.grab_focus()


func _on_option_a_pressed() -> void:
	_has_chosen = true
	_choice_layer.visible = false
	GameState.add_hope(hope_reward)
	EventBus.choice_made.emit(choice_id, option_a_id)
	Audio.play_sfx(&"choice")
	if choice_id == &"seed" and _sprout_model != null:
		_sprout_model.visible = true
		_sprout_model.scale = Vector3(0.01, 0.01, 0.01)
		var sprout_tween: Tween = create_tween()
		sprout_tween.tween_property(_sprout_model, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif _chick_model != null and _chick_model.visible:
		var start_y: float = _chick_model.position.y
		var tween: Tween = create_tween()
		tween.tween_property(_chick_model, "position:y", start_y + 0.8, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(_chick_model, "position:y", start_y, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(_chick_model, "position:x", _chick_model.position.x + 3.0, 0.4)
		tween.parallel().tween_property(_chick_model, "scale", Vector3(0.01, 0.01, 0.01), 0.4)
		tween.tween_callback(func() -> void: _chick_model.visible = false)
	if not success_monologue_key.is_empty():
		EventBus.monologue_requested.emit(success_monologue_key)


func _on_option_b_pressed() -> void:
	_has_chosen = true
	_choice_layer.visible = false
	EventBus.choice_made.emit(choice_id, option_b_id)


func _on_language_changed(_code: String) -> void:
	_refresh_text()


func _refresh_text() -> void:
	if _prompt_label != null:
		_prompt_label.text = tr(prompt_key)
	if _option_a_button != null:
		_option_a_button.text = tr(option_a_key)
	if _option_b_button != null:
		_option_b_button.text = tr(option_b_key)
