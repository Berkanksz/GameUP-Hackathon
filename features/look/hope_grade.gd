class_name HopeGrade
extends Node
## Drives environment adjustment saturation, ambient light, and sky tint based on GameState hope.

const LOW_HOPE_COLOR: Color = Color(0.62, 0.74, 0.88, 1.0)
const HIGH_HOPE_COLOR: Color = Color(0.98, 0.88, 0.74, 1.0)
const LOW_SATURATION: float = 0.65
const HIGH_SATURATION: float = 1.30

@export var world_environment: WorldEnvironment
@export var directional_light: DirectionalLight3D

var _tween: Tween


func _ready() -> void:
	if world_environment == null:
		world_environment = get_parent() as WorldEnvironment
	if directional_light == null:
		directional_light = get_tree().get_first_node_in_group(&"directional_light") as DirectionalLight3D
	_setup_environment()
	EventBus.hope_changed.connect(_on_hope_changed)
	_apply_hope(GameState.hope, false)


func _setup_environment() -> void:
	if world_environment == null:
		return
	if world_environment.environment == null:
		world_environment.environment = Environment.new()


func _on_hope_changed(new_hope: float) -> void:
	_apply_hope(new_hope, true)


func _apply_hope(hope_val: float, animate: bool) -> void:
	if world_environment == null or world_environment.environment == null:
		return
	var env: Environment = world_environment.environment
	var t: float = clampf(hope_val / 100.0, 0.0, 1.0)
	var target_ambient: Color = LOW_HOPE_COLOR.lerp(HIGH_HOPE_COLOR, t)
	
	if not animate:
		env.ambient_light_color = target_ambient
		if directional_light != null:
			directional_light.light_color = target_ambient
		return
	
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(env, "ambient_light_color", target_ambient, 1.2)
	if directional_light != null:
		_tween.tween_property(directional_light, "light_color", target_ambient, 1.2)
