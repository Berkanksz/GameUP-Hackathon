extends Node
## Tracks hope score, story flags, and active chapter state.

const HOPE_MIN: float = 0.0
const HOPE_MAX: float = 100.0
const HOPE_START: float = 10.0
const HOPE_MID_THRESHOLD: float = 35.0
const HOPE_HIGH_THRESHOLD: float = 70.0
const HOPE_FACT_REWARD: float = 2.0

var hope: float = HOPE_START
var current_chapter: StringName = &""

var _flags: Dictionary = {}


func _ready() -> void:
	EventBus.fact_collected.connect(_on_fact_collected)
	EventBus.choice_made.connect(_on_choice_made)


## Increases or decreases hope within bounds and emits hope_changed.
func add_hope(amount: float) -> void:
	hope = clampf(hope + amount, HOPE_MIN, HOPE_MAX)
	EventBus.hope_changed.emit(hope)


## Returns the ending tier identifier based on current hope.
func get_ending_id() -> StringName:
	if hope >= HOPE_HIGH_THRESHOLD:
		return &"HIGH"
	if hope >= HOPE_MID_THRESHOLD:
		return &"MID"
	return &"LOW"


## Returns hope tier matching get_ending_id.
func get_hope_tier() -> StringName:
	return get_ending_id()


## Records a story or progression flag.
func set_flag(id: StringName) -> void:
	_flags[id] = true


## Checks whether a story flag has been set.
func has_flag(id: StringName) -> bool:
	return _flags.get(id, false)


## Resets state to starting values for a new run.
func reset() -> void:
	hope = HOPE_START
	current_chapter = &""
	_flags.clear()
	EventBus.hope_changed.emit(hope)


func _on_fact_collected(key: StringName) -> void:
	var fact_flag: StringName = StringName("fact_" + str(key))
	if not has_flag(fact_flag):
		set_flag(fact_flag)
		add_hope(HOPE_FACT_REWARD)


func _on_choice_made(choice_id: StringName, option: StringName) -> void:
	set_flag(StringName("choice_" + str(choice_id) + "_" + str(option)))
