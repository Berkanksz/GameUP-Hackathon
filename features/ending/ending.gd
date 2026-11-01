class_name Ending
extends Node3D
## Plays the hope tier ending: centered summit diorama, penguin action, ending text, then emits game_ended.

const TIER_BACKGROUNDS: Dictionary = {
	&"LOW": Color(0.45, 0.55, 0.68, 1.0),
	&"MID": Color(0.58, 0.74, 0.90, 1.0),
	&"HIGH": Color(0.96, 0.78, 0.54, 1.0),
}

@export var camera: Camera3D
@export var penguin_root: Node3D
@export var penguin_model: PenguinModel
@export var environment: WorldEnvironment
@export var pull_back_offset: Vector3 = Vector3(0.0, 0.55, 2.8)
@export var pull_back_time: float = 7.5
@export var walk_distance: float = 1.6
@export var walk_time: float = 2.6
@export var text_delay: float = 1.4
@export var text_fade: float = 0.75
@export var text_hold: float = 4.2
@export var call_hold: float = 3.8

var ending_id: StringName = &"LOW"

@onready var _text_root: Control = %TextRoot
@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _call_root: Control = %CallRoot
@onready var _call_label: Label = %CallLabel
@onready var _chick_companion: Node3D = get_node_or_null("%ChickCompanion")
@onready var _sprout_companion: Node3D = get_node_or_null("%SproutCompanion")
@onready var _beacon_light: OmniLight3D = get_node_or_null("%BeaconLight")


func _ready() -> void:
	ending_id = GameState.get_ending_id()
	EventBus.language_changed.connect(_on_language_changed)
	_refresh_text()
	_text_root.modulate.a = 0.0
	_call_root.modulate.a = 0.0
	_apply_background()
	_pull_back_camera()
	_play_penguin_action()
	_play_text_sequence()


func _pull_back_camera() -> void:
	if camera == null:
		return
	camera.position = Vector3(0.0, 1.85, 8.8)
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "position", camera.position + pull_back_offset, pull_back_time)


func _play_penguin_action() -> void:
	if penguin_root == null or penguin_model == null:
		return
	penguin_root.position = Vector3(-1.6, 0.0, 0.0)
	penguin_root.scale = Vector3.ONE
	penguin_model.set_slide_amount(0.0)
	penguin_model.set_walk_amount(1.0)

	var tween: Tween = create_tween()
	# Step 1: Walk from left (-1.6) right into the center of the camera (0.0) in front of the hut and lamp
	tween.tween_property(penguin_root, "position:x", 0.0, walk_time)
	tween.tween_callback(penguin_model.set_walk_amount.bind(0.0))

	if ending_id == &"HIGH":
		# Joyful double hop in the center with the rescued chick, then a celebratory belly-slide!
		tween.tween_property(penguin_root, "position:y", 0.58, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if _chick_companion != null:
			tween.parallel().tween_property(_chick_companion, "position:y", 0.48, 0.22)
		tween.tween_property(penguin_root, "position:y", 0.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		if _chick_companion != null:
			tween.parallel().tween_property(_chick_companion, "position:y", 0.0, 0.20)
		tween.tween_property(penguin_root, "position:y", 0.52, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(penguin_root, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(func() -> void:
			penguin_model.set_slide_amount(1.0)
		)
		tween.tween_property(penguin_root, "position:x", 1.15, 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func() -> void:
			penguin_model.set_slide_amount(0.0)
			penguin_root.scale.x = -1.0
		)
	elif ending_id == &"MID":
		# Pause at center, look back at the warm hut, then face the valley and hop gently
		tween.tween_interval(0.45)
		tween.tween_callback(func() -> void: penguin_root.scale.x = -1.0)
		tween.tween_interval(0.8)
		tween.tween_callback(func() -> void: penguin_root.scale.x = 1.0)
		tween.tween_property(penguin_root, "position:y", 0.38, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(penguin_root, "position:y", 0.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		# LOW: Walk slowly from center (0.0) to 0.85, staying inside the central frame
		tween.tween_interval(0.5)
		tween.tween_callback(penguin_model.set_walk_amount.bind(0.65))
		tween.tween_property(penguin_root, "position:x", 0.85, 1.8)
		tween.tween_callback(penguin_model.set_walk_amount.bind(0.0))


func _play_text_sequence() -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(text_delay)
	tween.tween_property(_text_root, "modulate:a", 1.0, text_fade)
	tween.tween_interval(text_hold)
	tween.tween_property(_text_root, "modulate:a", 0.0, text_fade)
	tween.tween_property(_call_root, "modulate:a", 1.0, text_fade)
	tween.tween_interval(call_hold)
	tween.tween_property(_call_root, "modulate:a", 0.0, text_fade)
	tween.tween_callback(func() -> void: EventBus.game_ended.emit(ending_id))


func _apply_background() -> void:
	if environment != null and environment.environment != null:
		environment.environment.background_color = TIER_BACKGROUNDS.get(ending_id, TIER_BACKGROUNDS[&"MID"])
	if _chick_companion != null:
		_chick_companion.visible = (ending_id != &"LOW" or GameState.has_flag(&"choice_chick_help"))
	if _sprout_companion != null:
		_sprout_companion.visible = (ending_id != &"LOW" or GameState.has_flag(&"choice_seed_plant"))
	if _beacon_light != null:
		_beacon_light.light_energy = 3.0 if ending_id == &"HIGH" else (1.8 if ending_id == &"MID" else 0.6)


func _refresh_text() -> void:
	_title_label.text = tr("END_%s_TITLE" % ending_id)
	_body_label.text = tr("END_%s_TEXT" % ending_id)
	_call_label.text = tr("END_CALL")


func _on_language_changed(_code: String) -> void:
	_refresh_text()
