class_name MonologueUI
extends CanvasLayer
## Displays subtitle monologues with hope tier variants.

@export var display_duration: float = 4.2
@export var fade_duration: float = 0.3

var _current_key: StringName = &""
var _fade_tween: Tween
var _hide_timer: float = 0.0
var _is_displaying: bool = false

@onready var _panel: PanelContainer = %PanelContainer
@onready var _subtitle_label: Label = %SubtitleLabel


func _ready() -> void:
	EventBus.monologue_requested.connect(_on_monologue_requested)
	EventBus.language_changed.connect(_on_language_changed)
	_panel.modulate.a = 0.0
	_panel.visible = false


func _process(delta: float) -> void:
	if not _is_displaying:
		return
	_hide_timer -= delta
	if _hide_timer <= 0.0:
		_hide_subtitle()


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
	_panel.visible = true
	_is_displaying = true
	_hide_timer = display_duration
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_panel, "modulate:a", 1.0, fade_duration)


func _hide_subtitle() -> void:
	_is_displaying = false
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_panel, "modulate:a", 0.0, fade_duration)
	_fade_tween.tween_callback(_on_fade_out_finished)


func _on_fade_out_finished() -> void:
	_panel.visible = false


func _on_language_changed(_code: String) -> void:
	if not _is_displaying or _current_key.is_empty():
		return
	var tier: StringName = GameState.get_hope_tier()
	var variant_key: String = str(_current_key) + "_" + str(tier)
	var text: String = tr(variant_key)
	if text == variant_key:
		text = tr(String(_current_key))
	_subtitle_label.text = text
