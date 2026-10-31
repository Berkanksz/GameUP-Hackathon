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

var _has_chosen: bool = false

@onready var _choice_layer: CanvasLayer = %ChoiceLayer
@onready var _prompt_label: Label = %PromptLabel
@onready var _option_a_button: Button = %OptionAButton
@onready var _option_b_button: Button = %OptionBButton
@onready var _chick_model: Node3D = %ChickModel


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
	var flag_a: StringName = StringName("choice_" + str(choice_id) + "_" + str(option_a_id))
	var flag_b: StringName = StringName("choice_" + str(choice_id) + "_" + str(option_b_id))
	if GameState.has_flag(flag_a):
		_has_chosen = true
		if _chick_model != null:
			_chick_model.visible = false
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
	if _chick_model != null:
		var start_y: float = _chick_model.position.y
		var tween: Tween = create_tween()
		tween.tween_property(_chick_model, "position:y", start_y + 0.8, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(_chick_model, "position:y", start_y, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(_chick_model, "position:x", _chick_model.position.x + 3.0, 0.4)
		tween.parallel().tween_property(_chick_model, "scale", Vector3(0.01, 0.01, 0.01), 0.4)
		tween.tween_callback(func() -> void: _chick_model.visible = false)
	EventBus.monologue_requested.emit(&"CHOICE_CHICK_SAVED")


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
