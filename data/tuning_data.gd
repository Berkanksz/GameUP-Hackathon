class_name TuningData
extends Resource
## Global movement and camera tuning parameters.

@export var walk_speed: float = 6.5
@export var walk_acceleration: float = 42.0
@export var walk_friction: float = 48.0
@export var air_acceleration: float = 28.0
@export var air_friction: float = 12.0
@export var jump_velocity: float = 11.5
@export var jump_release_multiplier: float = 0.45
@export var gravity_up: float = 26.0
@export var gravity_down: float = 36.0
@export var max_fall_speed: float = 22.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var camera_follow_speed: float = 7.0
@export var camera_lookahead_x: float = 2.2
@export var camera_lookahead_speed: float = 4.0
@export var camera_offset: Vector3 = Vector3(0.0, 2.2, 24.0)
@export var camera_fov: float = 25.0
@export var heat_max: float = 1.0
@export var heat_slow_threshold: float = 0.7
@export var heat_slow_multiplier: float = 0.7
@export var heat_passive_cool_rate: float = 0.05
@export var heat_sun_rate: float = 0.35
@export var heat_shade_rate: float = -0.45
@export var respawn_delay: float = 0.3
