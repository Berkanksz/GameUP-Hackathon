class_name Credits
extends CanvasLayer
## Rolls credits after game_ended, shows thanks, then returns to the main menu.

const MAIN_MENU_PATH: String = "res://features/ui/main_menu.tscn"
const CREDIT_KEYS: Array[String] = [
	"UI_TITLE",
	"UI_CREDITS_EVENT",
	"UI_CREDITS_DESIGN",
	"UI_CREDITS_ENGINE",
	"UI_CREDITS_ART",
	"UI_CREDITS_FACTS",
	"UI_CREDITS_INSPIRATION",
]

@export var roll_time: float = 12.0
@export var thanks_time: float = 3.5
@export var fade_time: float = 0.8
@export var line_font_size: int = 26

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
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_menu()


func _on_game_ended(_ending_id: StringName) -> void:
	visible = true
	await get_tree().process_frame
	_roll_box.position.y = _roll_area.size.y
	var tween: Tween = create_tween()
	tween.tween_property(_roll_box, "position:y", -_roll_box.size.y, roll_time)
	tween.tween_property(_thanks_label, "modulate:a", 1.0, fade_time)
	tween.tween_interval(thanks_time)
	tween.tween_callback(_return_to_menu)


func _build_lines() -> void:
	for key: String in CREDIT_KEYS:
		var label := Label.new()
		label.name = key
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override(&"font_size", line_font_size)
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
