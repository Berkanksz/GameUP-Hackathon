extends Node
## Tracks hope score, story flags, and active chapter state.

const HOPE_MIN: float = 0.0
const HOPE_MAX: float = 100.0
const HOPE_START: float = 10.0
const HOPE_MID_THRESHOLD: float = 35.0
const HOPE_HIGH_THRESHOLD: float = 70.0

var hope: float = HOPE_START
var current_chapter: StringName = &""

var _flags: Dictionary = {}


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
