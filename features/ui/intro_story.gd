class_name IntroStory
extends Control
## Intermediate story and awareness screen shown between Main Menu and Chapter 1.
## Explains gameplay mechanics, story context, and climate awareness goals.
## Features a live 3D showcase penguin looking at the camera and turning its head left/right every 3 seconds.

const FIRST_CHAPTER_PATH: String = "res://features/chapters/chapter_1_shore.tscn"
const MAIN_MENU_PATH: String = "res://features/ui/main_menu.tscn"
const TURN_INTERVAL: float = 3.0

# Base yaw: -90 degrees faces the camera (+Z) directly.
const YAW_SCREEN: float = -90.0
const YAW_LOOK_LEFT: float = -124.0
const YAW_LOOK_RIGHT: float = -56.0

var _turn_timer: float = 0.0
var _look_state: int = 0
var _idle_time: float = 0.0
var _head_tween: Tween
var _base_position: Vector3 = Vector3(2.45, -0.21, 0.0)

@onready var _penguin_root: Node3D = get_node_or_null("%PenguinShowcase") as Node3D
@onready var _start_button: Button = %StartButton
@onready var _back_button: Button = %BackButton
@onready var _badge_label: Label = get_node_or_null("%BadgeLabel") as Label
@onready var _title_label: Label = %TitleLabel
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _story_title: Label = %StoryTitle
@onready var _story_body: Label = %StoryBody
@onready var _gameplay_title: Label = %GameplayTitle

@onready var _gp_item1_title: Label = get_node_or_null("%GpItem1Title") as Label
@onready var _gp_item1_desc: Label = get_node_or_null("%GpItem1Desc") as Label
@onready var _gp_item2_title: Label = get_node_or_null("%GpItem2Title") as Label
@onready var _gp_item2_desc: Label = get_node_or_null("%GpItem2Desc") as Label
@onready var _gp_item3_title: Label = get_node_or_null("%GpItem3Title") as Label
@onready var _gp_item3_desc: Label = get_node_or_null("%GpItem3Desc") as Label
@onready var _gp_item4_title: Label = get_node_or_null("%GpItem4Title") as Label
@onready var _gp_item4_desc: Label = get_node_or_null("%GpItem4Desc") as Label

@onready var _awareness_title: Label = %AwarenessTitle
@onready var _awareness_body: Label = %AwarenessBody
@onready var _hint_label: Label = get_node_or_null("%HintLabel") as Label


func _ready() -> void:
	if _penguin_root != null:
		_base_position = _penguin_root.position
		_penguin_root.rotation_degrees = Vector3(0.0, YAW_SCREEN, 0.0)
	_refresh_text()
	EventBus.language_changed.connect(_on_language_changed)
	_start_button.pressed.connect(_on_start_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_start_button.grab_focus()
	_turn_timer = TURN_INTERVAL


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_on_back_pressed()
	elif event.is_action_pressed(&"ui_accept"):
		_on_start_pressed()


func _process(delta: float) -> void:
	_idle_time += delta
	_update_penguin_idle(delta)
	_update_penguin_look(delta)


func _update_penguin_idle(_delta: float) -> void:
	if _penguin_root == null:
		return
	var breath: float = sin(_idle_time * 2.2) * 0.006
	_penguin_root.position.y = _base_position.y + breath


func _update_penguin_look(delta: float) -> void:
	if _penguin_root == null:
		return
	_turn_timer -= delta
	if _turn_timer <= 0.0:
		_turn_timer = TURN_INTERVAL
		_cycle_head_turn()


func _cycle_head_turn() -> void:
	if _penguin_root == null:
		return
	if _head_tween != null and _head_tween.is_valid():
		_head_tween.kill()
	_head_tween = create_tween()

	# Cycle: 0 = Screen, 1 = Turn Left, 2 = Screen, 3 = Turn Right
	_look_state = (_look_state + 1) % 4
	var target_yaw: float = YAW_SCREEN
	var target_roll: float = 0.0

	match _look_state:
		1:
			target_yaw = YAW_LOOK_LEFT
			target_roll = 3.5
		3:
			target_yaw = YAW_LOOK_RIGHT
			target_roll = -3.5
		_:
			target_yaw = YAW_SCREEN
			target_roll = 0.0

	_head_tween.set_parallel(true)
	_head_tween.tween_property(_penguin_root, "rotation_degrees:y", target_yaw, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_head_tween.tween_property(_penguin_root, "rotation_degrees:z", target_roll, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _refresh_text() -> void:
	if _badge_label != null:
		_badge_label.text = tr("INTRO_BADGE")
	_title_label.text = tr("INTRO_TITLE")
	_subtitle_label.text = tr("INTRO_SUBTITLE")
	_story_title.text = tr("INTRO_STORY_TITLE")
	_story_body.text = tr("INTRO_STORY_BODY")
	_gameplay_title.text = tr("INTRO_GAMEPLAY_TITLE")

	if _gp_item1_title != null:
		_gp_item1_title.text = tr("INTRO_GP_ITEM1_TITLE")
	if _gp_item1_desc != null:
		_gp_item1_desc.text = tr("INTRO_GP_ITEM1_DESC")

	if _gp_item2_title != null:
		_gp_item2_title.text = tr("INTRO_GP_ITEM2_TITLE")
	if _gp_item2_desc != null:
		_gp_item2_desc.text = tr("INTRO_GP_ITEM2_DESC")

	if _gp_item3_title != null:
		_gp_item3_title.text = tr("INTRO_GP_ITEM3_TITLE")
	if _gp_item3_desc != null:
		_gp_item3_desc.text = tr("INTRO_GP_ITEM3_DESC")

	if _gp_item4_title != null:
		_gp_item4_title.text = tr("INTRO_GP_ITEM4_TITLE")
	if _gp_item4_desc != null:
		_gp_item4_desc.text = tr("INTRO_GP_ITEM4_DESC")

	_awareness_title.text = tr("INTRO_AWARENESS_TITLE")
	_awareness_body.text = tr("INTRO_AWARENESS_BODY")
	_start_button.text = tr("INTRO_BTN_START")
	_back_button.text = tr("INTRO_BTN_BACK")
	if _hint_label != null:
		var is_tr: bool = Settings.get_language() == "tr"
		_hint_label.text = "[Enter / Space] Başla • [Esc] Geri" if is_tr else "[Enter / Space] Start • [Esc] Back"


func _on_language_changed(_code: String) -> void:
	_refresh_text()


func _on_start_pressed() -> void:
	Audio.play_sfx(&"ui_click")
	GameState.reset()
	if ResourceLoader.exists(FIRST_CHAPTER_PATH):
		get_tree().change_scene_to_file(FIRST_CHAPTER_PATH)


func _on_back_pressed() -> void:
	Audio.play_sfx(&"ui_click")
	if ResourceLoader.exists(MAIN_MENU_PATH):
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
