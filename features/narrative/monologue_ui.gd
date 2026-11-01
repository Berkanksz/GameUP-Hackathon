class_name MonologueUI
extends CanvasLayer
## Displays narrative and reactive messages inside a fixed rectangular dock at the left-middle-lower screen area.

const BOTTOM_CINEMATIC_KEYS: Array[StringName] = [
	&"MONO_C1_START",
	&"MONO_C1_END",
	&"MONO_C2_START",
	&"MONO_C2_END",
	&"MONO_C3_START",
	&"MONO_C3_VIEW",
	&"MONO_C3_TOP",
	&"MONO_C4_START",
	&"MONO_C4_END",
	&"MONO_C5_START",
]

@export var display_duration: float = 7.5
@export var fade_duration: float = 0.24

var _current_key: StringName = &""
var _fade_tween: Tween
var _hide_timer: float = 0.0
var _is_displaying: bool = false
var _use_penguin_callout: bool = false

@onready var _panel: PanelContainer = %PanelContainer
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _callout_panel: PanelContainer = get_node_or_null("%PenguinCallout") as PanelContainer
@onready var _callout_label: Label = get_node_or_null("%CalloutLabel") as Label


func _ready() -> void:
	add_to_group(&"monologue_ui")
	EventBus.monologue_requested.connect(_on_monologue_requested)
	EventBus.fact_collected.connect(_on_fact_collected)
	EventBus.chapter_completed.connect(_on_chapter_completed)
	EventBus.language_changed.connect(_on_language_changed)
	_panel.modulate.a = 0.0
	_panel.visible = false
	if _callout_panel != null:
		_callout_panel.position = Vector2(36.0, 560.0)
		_callout_panel.modulate.a = 0.0
		_callout_panel.visible = false


## Immediately hides any active monologue banner or callout rectangle.
func hide_immediately() -> void:
	_is_displaying = false
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_panel.visible = false
	_panel.modulate.a = 0.0
	if _callout_panel != null:
		_callout_panel.visible = false
		_callout_panel.modulate.a = 0.0


func _process(delta: float) -> void:
	if not _is_displaying:
		return
	_hide_timer -= delta
	if _hide_timer <= 0.0:
		_hide_subtitle()


func _on_fact_collected(_key: StringName) -> void:
	pass


func _on_chapter_completed(_chapter_id: StringName) -> void:
	hide_immediately()


func _on_monologue_requested(key: StringName) -> void:
	_current_key = key
	_show_monologue(key)


func _show_monologue(key: StringName) -> void:
	var tier: StringName = GameState.get_hope_tier()
	var variant_key: String = str(key) + "_" + str(tier)
	var text: String = tr(variant_key)
	if text == variant_key:
		text = tr(String(key))
	if text.is_empty() or text == String(key):
		return
	_subtitle_label.text = text
	if _callout_label != null:
		_callout_label.text = text
	_use_penguin_callout = not (key in BOTTOM_CINEMATIC_KEYS) and _callout_panel != null
	_is_displaying = true
	_hide_timer = display_duration
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	if _use_penguin_callout:
		_panel.visible = false
		_callout_panel.position = Vector2(36.0, 560.0)
		_callout_panel.visible = true
		_callout_panel.scale = Vector2(0.94, 0.94)
		_fade_tween.set_parallel(true)
		_fade_tween.tween_property(_callout_panel, "modulate:a", 1.0, fade_duration)
		_fade_tween.tween_property(_callout_panel, "scale", Vector2.ONE, fade_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		if _callout_panel != null:
			_callout_panel.visible = false
		_panel.visible = true
		_fade_tween.tween_property(_panel, "modulate:a", 1.0, fade_duration)


func _hide_subtitle() -> void:
	_is_displaying = false
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	var active_panel: Control = _callout_panel if (_use_penguin_callout and _callout_panel != null) else _panel
	_fade_tween.tween_property(active_panel, "modulate:a", 0.0, fade_duration)
	_fade_tween.tween_callback(_on_fade_out_finished)


func _on_fade_out_finished() -> void:
	_panel.visible = false
	if _callout_panel != null:
		_callout_panel.visible = false


func _on_language_changed(_code: String) -> void:
	if not _is_displaying or _current_key.is_empty():
		return
	var tier: StringName = GameState.get_hope_tier()
	var variant_key: String = str(_current_key) + "_" + str(tier)
	var text: String = tr(variant_key)
	if text == variant_key:
		text = tr(String(_current_key))
	_subtitle_label.text = text
	if _callout_label != null:
		_callout_label.text = text
