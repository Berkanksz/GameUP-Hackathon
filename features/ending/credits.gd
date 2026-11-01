class_name Credits
extends CanvasLayer
## Rolls credits after game_ended, shows thanks, then returns to the main menu.

const MAIN_MENU_PATH: String = "res://features/ui/main_menu.tscn"
const CREDIT_KEYS: Array[String] = [
	"UI_TITLE",
	"UI_CREDITS_AUTHOR",
	"UI_CREDITS_ENGINE",
	"UI_CREDITS_MODELS",
	"UI_CREDITS_AUDIO",
	"UI_CREDITS_FONT",
	"UI_CREDITS_FACTS",
	"UI_CREDITS_INSPIRATION",
]

@export var roll_time: float = 11.0
@export var thanks_time: float = 3.2
@export var fade_time: float = 0.8
@export var line_font_size: int = 22

var _leaving: bool = false

@onready var _roll_area: Control = %RollArea
@onready var _roll_box: VBoxContainer = %RollBox
@onready var _credits_title: Label = %CreditsTitle
@onready var _thanks_label: Label = %ThanksLabel
@onready var _skip_label: Label = %SkipLabel


func _ready() -> void:
	visible = false
	_thanks_label.modulate.a = 0.0
	_build_lines()
	_refresh_text()
	EventBus.game_ended.connect(_on_game_ended)
	EventBus.language_changed.connect(_on_language_changed)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_menu()


func _on_game_ended(_ending_id: StringName) -> void:
	visible = true
	_thanks_label.modulate.a = 0.0
	_roll_box.modulate.a = 0.0
	await get_tree().process_frame
	await get_tree().process_frame

	var box_height: float = _roll_box.size.y
	var area_height: float = _roll_area.size.y
	var tween: Tween = create_tween()

	if box_height <= area_height - 60.0:
		_roll_box.position.y = (area_height - box_height) * 0.5
		tween.tween_property(_roll_box, "modulate:a", 1.0, fade_time)
		tween.tween_interval(roll_time)
		tween.tween_property(_roll_box, "modulate:a", 0.0, fade_time)
	else:
		_roll_box.modulate.a = 1.0
		_roll_box.position.y = area_height
		var overflow_distance: float = box_height + area_height
		var scroll_duration: float = maxf(roll_time, overflow_distance / 45.0)
		tween.tween_property(_roll_box, "position:y", -box_height, scroll_duration)

	tween.tween_property(_thanks_label, "modulate:a", 1.0, fade_time)
	tween.tween_interval(thanks_time)
	tween.tween_property(_thanks_label, "modulate:a", 0.0, fade_time)
	tween.tween_callback(_return_to_menu)


func _build_lines() -> void:
	for key: String in CREDIT_KEYS:
		var label := Label.new()
		label.name = key
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if key == "UI_TITLE":
			label.add_theme_font_size_override(&"font_size", line_font_size + 4)
			label.add_theme_color_override(&"font_color", Color(1.0, 0.94, 0.65, 1.0))
		elif key == "UI_CREDITS_AUTHOR":
			label.add_theme_font_size_override(&"font_size", line_font_size + 2)
			label.add_theme_color_override(&"font_color", Color(0.92, 0.98, 1.0, 1.0))
		else:
			label.add_theme_font_size_override(&"font_size", line_font_size)
			label.add_theme_color_override(&"font_color", Color(0.88, 0.94, 0.98, 0.95))
		_roll_box.add_child(label)


func _refresh_text() -> void:
	_credits_title.text = tr("UI_CREDITS")
	_thanks_label.text = tr("UI_THANKS")
	_skip_label.text = "Esc: %s" % tr("UI_SKIP")
	for key: String in CREDIT_KEYS:
		var label: Label = _roll_box.get_node_or_null(key) as Label
		if label != null:
			label.text = tr(key)


func _return_to_menu() -> void:
	if _leaving:
		return
	_leaving = true
	GameState.reset()
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_language_changed(_code: String) -> void:
	_refresh_text()
	await get_tree().process_frame
	if visible and _roll_box != null and _roll_area != null:
		var box_height: float = _roll_box.size.y
		var area_height: float = _roll_area.size.y
		if box_height <= area_height - 60.0:
			_roll_box.position.y = (area_height - box_height) * 0.5
