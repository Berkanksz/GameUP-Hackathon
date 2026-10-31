class_name Hud
extends CanvasLayer
## Heads up display with heat meter, hope score bar, carried item indicator, fact popup, and chapter completion.

const DEFAULT_TUNING_PATH: String = "res://data/tuning.tres"
const MAIN_MENU_PATH: String = "res://features/ui/main_menu.tscn"
const CHAPTER_2_PATH: String = "res://features/chapters/chapter_2_slope.tscn"
const FactCardScript = preload("res://features/narrative/fact_card.gd")
const NORMAL_FILL_COLOR: Color = Color(0.28, 0.72, 0.92, 1.0)
const HOT_FILL_COLOR: Color = Color(0.95, 0.42, 0.18, 1.0)
const HOPE_FILL_COLOR: Color = Color(0.24, 0.78, 0.54, 1.0)
const COLOR_PAPER: Color = Color(0.18, 0.52, 0.88, 1.0)
const COLOR_PLASTIC: Color = Color(0.95, 0.78, 0.15, 1.0)
const COLOR_GLASS: Color = Color(0.20, 0.75, 0.38, 1.0)

@export var tuning: TuningData

var _current_heat: float = 0.0
var _shimmer_clock: float = 0.0
var _flash_alpha: float = 0.0
var _heat_fill_style: StyleBoxFlat
var _hope_fill_style: StyleBoxFlat
var _fact_timer: float = 0.0
var _fact_showing: bool = false
var _current_fact_key: StringName = &""
var _carried_type: StringName = &""
var _completed_chapter_id: StringName = &""

@onready var _heat_label: Label = %HeatLabel
@onready var _heat_bar: ProgressBar = %HeatBar
@onready var _hope_label: Label = %HopeLabel
@onready var _hope_value_label: Label = %HopeValueLabel
@onready var _hope_bar: ProgressBar = %HopeBar
@onready var _carry_panel: PanelContainer = get_node_or_null("%CarryPanel")
@onready var _carry_label: Label = get_node_or_null("%CarryLabel")
@onready var _shimmer_overlay: ColorRect = %ShimmerOverlay
@onready var _fact_popup: PanelContainer = %FactPopup
@onready var _fact_text_label: Label = %FactTextLabel
@onready var _fact_source_label: Label = %FactSourceLabel
@onready var _complete_panel: PanelContainer = %CompletePanel
@onready var _complete_title: Label = %CompleteTitle
@onready var _complete_summary: Label = %CompleteSummary
@onready var _complete_continue_button: Button = get_node_or_null("%CompleteContinueButton")
@onready var _complete_restart_button: Button = %CompleteRestartButton
@onready var _complete_menu_button: Button = %CompleteMenuButton


func _ready() -> void:
	if tuning == null:
		tuning = load(DEFAULT_TUNING_PATH) as TuningData
	_setup_bar_styles()
	EventBus.heat_changed.connect(_on_heat_changed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.language_changed.connect(_on_language_changed)
	EventBus.hope_changed.connect(_on_hope_changed)
	EventBus.fact_collected.connect(_on_fact_collected)
	EventBus.litter_picked.connect(_on_litter_picked)
	EventBus.litter_sorted.connect(_on_litter_sorted)
	EventBus.chapter_completed.connect(_on_chapter_completed)
	if _fact_popup != null:
		_fact_popup.visible = false
	if _carry_panel != null:
		_carry_panel.visible = false
	if _complete_panel != null:
		_complete_panel.visible = false
	if _complete_continue_button != null:
		_complete_continue_button.pressed.connect(_on_complete_continue_pressed)
	if _complete_restart_button != null:
		_complete_restart_button.pressed.connect(_on_complete_restart_pressed)
	if _complete_menu_button != null:
		_complete_menu_button.pressed.connect(_on_complete_menu_pressed)
	_refresh_text()
	_apply_heat(0.0)
	_apply_hope(GameState.hope)


func _process(delta: float) -> void:
	_update_shimmer(delta)
	_update_fact_popup(delta)


func _setup_bar_styles() -> void:
	_heat_fill_style = StyleBoxFlat.new()
	_heat_fill_style.bg_color = NORMAL_FILL_COLOR
	_heat_fill_style.set_corner_radius_all(4)
	_heat_bar.add_theme_stylebox_override(&"fill", _heat_fill_style)
	_hope_fill_style = StyleBoxFlat.new()
	_hope_fill_style.bg_color = HOPE_FILL_COLOR
	_hope_fill_style.set_corner_radius_all(4)
	_hope_bar.add_theme_stylebox_override(&"fill", _hope_fill_style)


func _refresh_text() -> void:
	_heat_label.text = tr("UI_HEAT")
	_hope_label.text = tr("UI_HOPE")
	if _fact_showing and not _current_fact_key.is_empty():
		_display_fact(_current_fact_key)
	_refresh_carry_text()
	_refresh_complete_text()


func _refresh_carry_text() -> void:
	if _carry_panel == null or _carry_label == null or _carried_type.is_empty():
		return
	if _carried_type == &"paper":
		_carry_label.text = "◼ %s" % tr("UI_BIN_PAPER")
		_carry_label.modulate = COLOR_PAPER.lightened(0.25)
	elif _carried_type == &"plastic":
		_carry_label.text = "▲ %s" % tr("UI_BIN_PLASTIC")
		_carry_label.modulate = COLOR_PLASTIC.lightened(0.2)
	else:
		_carry_label.text = "● %s" % tr("UI_BIN_GLASS")
		_carry_label.modulate = COLOR_GLASS.lightened(0.25)


func _refresh_complete_text() -> void:
	if _complete_panel == null or not _complete_panel.visible:
		return
	_complete_title.text = tr("UI_CHAPTER_COMPLETE")
	var chapter_key: String = "UI_CHAPTER_2" if _completed_chapter_id == &"chapter_2" else "UI_CHAPTER_1"
	_complete_summary.text = "%s, %s: %d" % [tr(chapter_key), tr("UI_HOPE"), roundi(GameState.hope)]
	if _complete_continue_button != null:
		_complete_continue_button.text = tr("UI_CONTINUE")
		_complete_continue_button.visible = (_completed_chapter_id == &"chapter_1" and ResourceLoader.exists(CHAPTER_2_PATH))
	_complete_restart_button.text = tr("UI_RESTART")
	_complete_menu_button.text = tr("UI_MAIN_MENU")


func _on_language_changed(_code: String) -> void:
	_refresh_text()


func _on_heat_changed(value: float) -> void:
	_apply_heat(value)


func _on_hope_changed(value: float) -> void:
	_apply_hope(value)


func _on_litter_picked(type: StringName) -> void:
	_carried_type = type
	if _carry_panel != null:
		_carry_panel.visible = true
	_refresh_carry_text()


func _on_litter_sorted(_type: StringName, _correct: bool) -> void:
	_carried_type = &""
	if _carry_panel != null:
		_carry_panel.visible = false


func _on_fact_collected(key: StringName) -> void:
	_current_fact_key = key
	_display_fact(key)


func _on_chapter_completed(chapter_id: StringName) -> void:
	_completed_chapter_id = chapter_id
	if _complete_panel != null:
		_complete_panel.visible = true
	_refresh_complete_text()
	if _complete_continue_button != null and _complete_continue_button.visible:
		_complete_continue_button.grab_focus()
	elif _complete_restart_button != null:
		_complete_restart_button.grab_focus()


func _on_complete_continue_pressed() -> void:
	Audio.play_sfx(&"ui_click")
	if _completed_chapter_id == &"chapter_1" and ResourceLoader.exists(CHAPTER_2_PATH):
		get_tree().change_scene_to_file(CHAPTER_2_PATH)


func _on_complete_restart_pressed() -> void:
	Audio.play_sfx(&"ui_click")
	GameState.reset()
	get_tree().reload_current_scene()


func _on_complete_menu_pressed() -> void:
	Audio.play_sfx(&"ui_click")
	if ResourceLoader.exists(MAIN_MENU_PATH):
		get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_player_died(reason: StringName) -> void:
	if reason == &"overheat":
		_flash_alpha = 0.38


func _on_player_respawned(_checkpoint_id: StringName) -> void:
	_flash_alpha = 0.0
	_apply_heat(0.0)


func _apply_heat(value: float) -> void:
	var max_heat: float = tuning.heat_max if tuning != null else 1.0
	_current_heat = clampf(value, 0.0, max_heat)
	_heat_bar.max_value = max_heat
	_heat_bar.value = _current_heat
	var threshold: float = tuning.heat_slow_threshold if tuning != null else 0.7
	if _heat_fill_style != null:
		_heat_fill_style.bg_color = HOT_FILL_COLOR if _current_heat >= threshold else NORMAL_FILL_COLOR


func _apply_hope(value: float) -> void:
	var clamped: float = clampf(value, 0.0, 100.0)
	_hope_bar.max_value = 100.0
	_hope_bar.value = clamped
	_hope_value_label.text = str(roundi(clamped))


func _display_fact(key: StringName) -> void:
	if _fact_popup == null:
		return
	_fact_text_label.text = tr(key)
	var source: String = FactCardScript.get_source(key)
	_fact_source_label.text = "" if source.is_empty() else "%s: %s" % [tr("UI_FACT_SOURCE"), source]
	_fact_popup.visible = true
	_fact_showing = true
	_fact_timer = 5.0


func _update_fact_popup(delta: float) -> void:
	if not _fact_showing:
		return
	_fact_timer -= delta
	if _fact_timer <= 0.0:
		_fact_showing = false
		if _fact_popup != null:
			_fact_popup.visible = false


func _update_shimmer(delta: float) -> void:
	if _shimmer_overlay == null:
		return
	_flash_alpha = maxf(0.0, _flash_alpha - delta * 1.2)
	var threshold: float = tuning.heat_slow_threshold if tuning != null else 0.7
	var max_heat: float = tuning.heat_max if tuning != null else 1.0
	var shimmer_alpha: float = 0.0
	if _current_heat >= threshold and max_heat > threshold:
		_shimmer_clock += delta * 6.5
		var ratio: float = (_current_heat - threshold) / (max_heat - threshold)
		shimmer_alpha = ratio * (0.08 + 0.08 * (0.5 + 0.5 * sin(_shimmer_clock)))
	_shimmer_overlay.color = Color(1.0, 0.48, 0.15, clampf(maxf(shimmer_alpha, _flash_alpha), 0.0, 0.45))
