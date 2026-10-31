extends Control
## Main menu screen with play, language switch, and quit actions.

const FIRST_CHAPTER_PATH: String = "res://features/chapters/chapter_1_shore.tscn"

@onready var _title_label: Label = %TitleLabel
@onready var _play_button: Button = %PlayButton
@onready var _language_button: Button = %LanguageButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_language_button.pressed.connect(_on_language_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	EventBus.language_changed.connect(_on_language_changed)
	_refresh_text()


func _on_language_changed(_code: String) -> void:
	_refresh_text()


func _refresh_text() -> void:
	_title_label.text = tr("UI_TITLE")
	_play_button.text = tr("UI_PLAY")
	var current_lang: String = Settings.get_language()
	var lang_label_key: String = "UI_LANG_TR" if current_lang == "tr" else "UI_LANG_EN"
	_language_button.text = "%s: %s" % [tr("UI_LANGUAGE"), tr(lang_label_key)]
	_quit_button.text = tr("UI_QUIT")


func _on_play_pressed() -> void:
	Audio.play_sfx(&"ui_click")
	GameState.reset()
	if ResourceLoader.exists(FIRST_CHAPTER_PATH):
		get_tree().change_scene_to_file(FIRST_CHAPTER_PATH)


func _on_language_pressed() -> void:
	Audio.play_sfx(&"ui_click")
	var next_lang: String = "tr" if Settings.get_language() == "en" else "en"
	Settings.set_language(next_lang)


func _on_quit_pressed() -> void:
	Audio.play_sfx(&"ui_click")
	get_tree().quit()
