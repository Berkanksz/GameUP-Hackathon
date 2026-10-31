class_name MonologueUI
extends CanvasLayer
## Displays subtitle monologues at the bottom of the screen or floating in front of the penguin.

const BOTTOM_CINEMATIC_KEYS: Array[StringName] = [
	&"MONO_C1_START",
	&"MONO_C1_END",
	&"MONO_C2_START",
	&"MONO_C2_END",
	&"MONO_C3_START",
	&"MONO_C3_VIEW",
	&"MONO_C3_TOP",
]

@export var display_duration: float = 4.8
@export var fade_duration: float = 0.28

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
	EventBus.monologue_requested.connect(_on_monologue_requested)
	EventBus.language_changed.connect(_on_language_changed)
	_panel.modulate.a = 0.0
	_panel.visible = false
	if _callout_panel != null:
		_callout_panel.modulate.a = 0.0
		_callout_panel.visible = false


func _process(delta: float) -> void:
	if not _is_displaying:
		return
	if _use_penguin_callout and _callout_panel != null and _callout_panel.visible:
		_update_callout_position()
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
		_callout_panel.visible = true
		_update_callout_position()
		_callout_panel.scale = Vector2(0.88, 0.88)
		_fade_tween.set_parallel(true)
		_fade_tween.tween_property(_callout_panel, "modulate:a", 1.0, fade_duration)
		_fade_tween.tween_property(_callout_panel, "scale", Vector2.ONE, fade_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		if _callout_panel != null:
			_callout_panel.visible = false
		_panel.visible = true
		_fade_tween.tween_property(_panel, "modulate:a", 1.0, fade_duration)


func _update_callout_position() -> void:
	if _callout_panel == null:
		return
	var player: Node3D = get_tree().get_first_node_in_group(&"player") as Node3D
	var cam: Camera3D = get_viewport().get_camera_3d()
	if player == null or cam == null:
		return
	var facing: float = float(player.get("facing_direction"))
	if is_zero_approx(facing):
		facing = 1.0
	var world_anchor: Vector3 = player.global_position + Vector3(facing * 2.1, 2.25, 0.0)
	var screen_pos: Vector2 = cam.unproject_position(world_anchor)
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var box_size: Vector2 = _callout_panel.size
	var target_x: float = clampf(screen_pos.x - box_size.x * 0.5, 32.0, maxf(32.0, vp_size.x - box_size.x - 32.0))
	var target_y: float = clampf(screen_pos.y - box_size.y, 120.0, maxf(120.0, vp_size.y - box_size.y - 160.0))
	_callout_panel.position = Vector2(target_x, target_y)


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
