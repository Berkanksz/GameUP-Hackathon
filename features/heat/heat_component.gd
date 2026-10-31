class_name HeatComponent
extends Node
## Tracks player heat from active zones and triggers overheat at maximum heat.

const DEFAULT_TUNING_PATH: String = "res://data/tuning.tres"

@export var tuning: TuningData

var heat: float = 0.0

var _rates: Dictionary = {}
var _overheated: bool = false


func _ready() -> void:
	if tuning == null:
		tuning = load(DEFAULT_TUNING_PATH) as TuningData
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.heat_changed.emit(heat)


func _physics_process(delta: float) -> void:
	if _overheated or tuning == null:
		return
	var total_rate: float = _compute_total_rate()
	var next_heat: float = clampf(heat + total_rate * delta, 0.0, tuning.heat_max)
	if not is_equal_approx(next_heat, heat):
		heat = next_heat
		EventBus.heat_changed.emit(heat)
	if heat >= tuning.heat_max:
		_overheated = true
		var parent: Node = get_parent()
		if parent != null and parent.has_method(&"die"):
			parent.call(&"die", &"overheat")


## Registers or updates the heat rate per second for a given source identifier.
func set_rate(source_id: StringName, rate: float) -> void:
	_rates[source_id] = rate


## Removes a heat source identifier from the active rate table.
func clear_rate(source_id: StringName) -> void:
	_rates.erase(source_id)


func _compute_total_rate() -> float:
	if _rates.is_empty():
		return -tuning.heat_passive_cool_rate
	var sum_rate: float = 0.0
	for value: Variant in _rates.values():
		sum_rate += float(value)
	return sum_rate


func _on_player_respawned(_checkpoint_id: StringName) -> void:
	_overheated = false
	_rates.clear()
	heat = 0.0
	EventBus.heat_changed.emit(heat)
