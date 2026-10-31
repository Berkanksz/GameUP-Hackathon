class_name FactCard
extends Area3D
## Collectible narrative fact card in 3D space.

static var _sources: Dictionary = {}

@export var fact_key: StringName = &""
@export var source_label: String = ""
@export var bob_amplitude: float = 0.12
@export var bob_speed: float = 2.4
@export var spin_speed: float = 1.6

var _collected: bool = false
var _base_y: float = 0.0
var _clock: float = 0.0

@onready var _visual_root: Node3D = %VisualRoot


## Returns registered source string for a fact key.
static func get_source(key: StringName) -> String:
	return _sources.get(key, "")


## Registers source string for a fact key.
static func register_source(key: StringName, source: String) -> void:
	_sources[key] = source


func _ready() -> void:
	_base_y = position.y
	if not fact_key.is_empty() and not source_label.is_empty():
		register_source(fact_key, source_label)
	if not fact_key.is_empty() and GameState.has_flag(StringName("fact_" + str(fact_key))):
		queue_free()
		return
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _collected:
		return
	_clock += delta * bob_speed
	position.y = _base_y + sin(_clock) * bob_amplitude
	if _visual_root != null:
		_visual_root.rotate_y(delta * spin_speed)


func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
	if not body.is_in_group(&"player"):
		return
	_collected = true
	set_deferred(&"monitoring", false)
	if not fact_key.is_empty():
		EventBus.fact_collected.emit(fact_key)
	Audio.play_sfx(&"pickup")
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", position.y + 0.6, 0.28)
	tween.chain().tween_callback(queue_free)
