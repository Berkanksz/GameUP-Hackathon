class_name MovingPlatform
extends AnimatableBody3D
## Moving glacier lift platform that oscillates smoothly along travel_offset.

@export var travel_offset: Vector3 = Vector3(5.5, 1.5, 0.0)
@export var cycle_duration: float = 4.0

var _origin: Vector3 = Vector3.ZERO
var _clock: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	_origin = position


func _physics_process(delta: float) -> void:
	if cycle_duration <= 0.05:
		return
	_clock += delta * (TAU / cycle_duration)
	var factor: float = 0.5 - 0.5 * cos(_clock)
	position = _origin + travel_offset * factor
