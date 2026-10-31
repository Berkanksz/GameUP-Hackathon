extends Control
## Animated 3D main menu screen with joyful ramp-sliding penguin, cheering background penguins, language switch, and volume control.

const FIRST_CHAPTER_PATH: String = "res://features/chapters/chapter_1_shore.tscn"
const SLIDE_LOOP_DURATION: float = 3.2

var _anim_clock: float = 0.0

@onready var _title_label: Label = %TitleLabel
@onready var _subtitle_label: Label = get_node_or_null("%SubtitleLabel")
@onready var _play_button: Button = %PlayButton
@onready var _language_button: Button = %LanguageButton
@onready var _volume_button: Button = %VolumeButton
@onready var _quit_button: Button = %QuitButton
@onready var _hero_slider: Node3D = get_node_or_null("%HeroSlider")
@onready var _hero_penguin: PenguinModel = get_node_or_null("%HeroPenguin") as PenguinModel
@onready var _friend_1: PenguinModel = get_node_or_null("%FriendPenguin1") as PenguinModel
@onready var _friend_2: PenguinModel = get_node_or_null("%FriendPenguin2") as PenguinModel
@onready var _friend_chick: Node3D = get_node_or_null("%FriendChick")
@onready var _menu_camera: Camera3D = get_node_or_null("%Camera3D")


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_language_button.pressed.connect(_on_language_pressed)
	_volume_button.pressed.connect(_on_volume_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	EventBus.language_changed.connect(_on_language_changed)
	if _hero_penguin != null:
		_hero_penguin.set_slide_amount(1.0)
	if _friend_1 != null:
		_friend_1.set_walk_amount(0.75)
	if _friend_2 != null:
		_friend_2.set_walk_amount(0.85)
	_refresh_text()
	_play_button.grab_focus()


func _process(delta: float) -> void:
	_anim_clock += delta
	_animate_diorama()


func _animate_diorama() -> void:
	var t: float = fmod(_anim_clock, SLIDE_LOOP_DURATION) / SLIDE_LOOP_DURATION
	if _hero_slider != null:
		if t < 0.45:
			# Sliding down the icy ramp
			var u: float = t / 0.45
			_hero_slider.position.x = lerpf(-2.8, 1.4, u)
			_hero_slider.position.y = lerpf(1.45, -0.32, u)
			_hero_slider.rotation.z = lerpf(-0.48, 0.0, u)
		elif t < 0.85:
			# Swooping up the launch lip and soaring joyfully through the air!
			var u: float = (t - 0.45) / 0.40
			_hero_slider.position.x = lerpf(1.4, 5.8, u)
			var arc: float = 4.0 * u * (1.0 - u)
			_hero_slider.position.y = lerpf(-0.32, 0.45, u) + arc * 2.15
			_hero_slider.rotation.z = lerpf(0.38, -0.25, u) + sin(u * TAU) * 0.35
		else:
			# Happy bounce on landing ridge before looping
			var u: float = (t - 0.85) / 0.15
			_hero_slider.position.x = lerpf(5.8, 6.8, u)
			_hero_slider.position.y = 0.45 + absf(sin(u * PI)) * 0.45
			_hero_slider.rotation.z = 0.0

	if _friend_1 != null:
		_friend_1.position.y = 0.42 + maxf(0.0, sin(_anim_clock * 4.2)) * 0.32
	if _friend_2 != null:
		_friend_2.position.y = 0.42 + maxf(0.0, sin(_anim_clock * 4.8 + 1.4)) * 0.28
	if _friend_chick != null:
		_friend_chick.position.y = 0.42 + maxf(0.0, sin(_anim_clock * 5.6 + 0.7)) * 0.36
		_friend_chick.rotation.y = sin(_anim_clock * 3.0) * 0.35
	if _menu_camera != null:
		_menu_camera.position.x = -1.2 + sin(_anim_clock * 0.65) * 0.35
		_menu_camera.position.y = 2.5 + cos(_anim_clock * 0.5) * 0.12


func _on_language_changed(_code: String) -> void:
	_refresh_text()


func _refresh_text() -> void:
	_title_label.text = tr("UI_TITLE")
	if _subtitle_label != null:
		_subtitle_label.text = tr("UI_SUBTITLE")
	_play_button.text = tr("UI_PLAY")
	var current_lang: String = Settings.get_language()
	var lang_label_key: String = "UI_LANG_TR" if current_lang == "tr" else "UI_LANG_EN"
	_language_button.text = "%s: %s" % [tr("UI_LANGUAGE"), tr(lang_label_key)]
	var current_vol: float = Settings.get_volume(&"Master")
	_volume_button.text = "%s: %d%%" % [tr("UI_VOLUME"), int(roundf(current_vol * 100.0))]
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


func _on_volume_pressed() -> void:
	var current_vol: float = Settings.get_volume(&"Master")
	var next_vol: float = current_vol - 0.25
	if next_vol < -0.01:
		next_vol = 1.0
	Settings.set_volume(&"Master", next_vol)
	Audio.play_sfx(&"ui_click")
	_refresh_text()


func _on_quit_pressed() -> void:
	Audio.play_sfx(&"ui_click")
	get_tree().quit()
