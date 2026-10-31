class_name Ending
extends Node3D
## Plays the hope tier ending: camera pull back, penguin action, ending text, then emits game_ended.

const TIER_BACKGROUNDS: Dictionary = {
	&"LOW": Color(0.56, 0.6, 0.66, 1.0),
	&"MID": Color(0.7, 0.77, 0.85, 1.0),
	&"HIGH": Color(0.95, 0.8, 0.62, 1.0),
}

@export var camera: Camera3D
@export var penguin_root: Node3D
@export var penguin_model: PenguinModel
@export var environment: WorldEnvironment
@export var pull_back_offset: Vector3 = Vector3(0.0, 3.0, 16.0)
@export var pull_back_time: float = 8.0
@export var walk_distance: float = 5.0
@export var walk_time: float = 5.0
@export var text_delay: float = 2.0
@export var text_fade: float = 0.8
@export var text_hold: float = 4.5
@export var call_hold: float = 4.0

var ending_id: StringName = &"LOW"

@onready var _text_root: Control = %TextRoot
@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _call_root: Control = %CallRoot
@onready var _call_label: Label = %CallLabel
@onready var _cop_label: Label = %CopLabel


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
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "position", camera.position + pull_back_offset, pull_back_time)


func _play_penguin_action() -> void:
	if penguin_root == null or penguin_model == null:
		return
	# LOW walks on, MID walks then turns to look back, HIGH turns and heads back down.
	var direction: float = -1.0 if ending_id == &"HIGH" else 1.0
	var distance: float = walk_distance * (0.4 if ending_id == &"MID" else 1.0)
	var duration: float = walk_time * (0.4 if ending_id == &"MID" else 1.0)
	penguin_root.scale.x = direction
	penguin_model.set_walk_amount(1.0)
	var tween: Tween = create_tween()
	tween.tween_property(penguin_root, "position:x", penguin_root.position.x + direction * distance, duration)
	tween.tween_callback(penguin_model.set_walk_amount.bind(0.0))
	if ending_id == &"MID":
		tween.tween_interval(0.6)
		tween.tween_callback(func() -> void: penguin_root.scale.x = -1.0)


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
	if environment == null or environment.environment == null:
		return
	environment.environment.background_color = TIER_BACKGROUNDS.get(ending_id, TIER_BACKGROUNDS[&"MID"])


func _refresh_text() -> void:
	_title_label.text = tr("END_%s_TITLE" % ending_id)
	_body_label.text = tr("END_%s_TEXT" % ending_id)
	_call_label.text = tr("END_CALL")
	_cop_label.text = tr("END_COP31")


func _on_language_changed(_code: String) -> void:
	_refresh_text()
