class_name Hud
extends CanvasLayer
## Heads up display with localized heat bar and high heat shimmer feedback.

const DEFAULT_TUNING_PATH: String = "res://data/tuning.tres"
const NORMAL_FILL_COLOR: Color = Color(0.28, 0.72, 0.92, 1.0)
const HOT_FILL_COLOR: Color = Color(0.95, 0.42, 0.18, 1.0)

@export var tuning: TuningData

var _current_heat: float = 0.0
var _shimmer_clock: float = 0.0
var _flash_alpha: float = 0.0
var _fill_style: StyleBoxFlat

@onready var _heat_label: Label = %HeatLabel
@onready var _heat_bar: ProgressBar = %HeatBar
@onready var _shimmer_overlay: ColorRect = %ShimmerOverlay


func _ready() -> void:
	if tuning == null:
		tuning = load(DEFAULT_TUNING_PATH) as TuningData
	_setup_bar_style()
	EventBus.heat_changed.connect(_on_heat_changed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.language_changed.connect(_on_language_changed)
	_refresh_text()
	_apply_heat(0.0)


func _process(delta: float) -> void:
	_update_shimmer(delta)


func _setup_bar_style() -> void:
	_fill_style = StyleBoxFlat.new()
	_fill_style.bg_color = NORMAL_FILL_COLOR
	_fill_style.set_corner_radius_all(4)
	_heat_bar.add_theme_stylebox_override(&"fill", _fill_style)


func _refresh_text() -> void:
	_heat_label.text = tr("UI_HEAT")


func _on_language_changed(_code: String) -> void:
	_refresh_text()


func _on_heat_changed(value: float) -> void:
	_apply_heat(value)


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
	if _fill_style != null:
		_fill_style.bg_color = HOT_FILL_COLOR if _current_heat >= threshold else NORMAL_FILL_COLOR


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
		var wave: float = 0.5 + 0.5 * sin(_shimmer_clock)
		shimmer_alpha = ratio * (0.08 + 0.08 * wave)
	var final_alpha: float = clampf(maxf(shimmer_alpha, _flash_alpha), 0.0, 0.45)
	_shimmer_overlay.color = Color(1.0, 0.48, 0.15, final_alpha)
