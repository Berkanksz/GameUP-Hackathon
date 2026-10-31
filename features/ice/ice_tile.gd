class_name IceTile
extends StaticBody3D
## Melting ice platform that breaks after being stepped on and respawns after a delay.

enum State {
	INTACT,
	MELTING,
	BROKEN,
}

const INTACT_COLOR: Color = Color(0.76, 0.9, 0.98, 1.0)
const CRACKED_COLOR: Color = Color(0.45, 0.68, 0.86, 0.45)

@export var melt_time: float = 0.85
@export var respawn_time: float = 2.5
@export var sun_multiplier: float = 1.8

var state: State = State.INTACT

var _timer: float = 0.0
var _visual_base_pos: Vector3 = Vector3.ZERO
var _material: StandardMaterial3D

@onready var _collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
@onready var _visual_box: CSGBox3D = get_node_or_null("VisualBox") as CSGBox3D
@onready var _step_detector: Area3D = get_node_or_null("StepDetector") as Area3D


func _ready() -> void:
	if _visual_box != null:
		_visual_base_pos = _visual_box.position
		_material = StandardMaterial3D.new()
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.albedo_color = INTACT_COLOR
		_visual_box.material = _material
	if _step_detector != null:
		_step_detector.body_entered.connect(_on_step_body_entered)
	EventBus.player_respawned.connect(_on_player_respawned)
	_restore()


func _physics_process(delta: float) -> void:
	if state == State.INTACT:
		if _is_player_stepping():
			_start_melting()
		return
	if state == State.MELTING:
		var mult: float = sun_multiplier if _is_in_sun() else 1.0
		_timer -= delta * mult
		_update_melting_visual()
		if _timer <= 0.0:
			_break_tile()
		return
	if state == State.BROKEN:
		_timer -= delta
		if _timer <= 0.0:
			_restore()


func _on_step_body_entered(body: Node3D) -> void:
	if state == State.INTACT and body != null and body.is_in_group(&"player"):
		_start_melting()


func _on_player_respawned(_checkpoint_id: StringName) -> void:
	_restore()


func _is_in_sun() -> bool:
	if _step_detector == null:
		return false
	for area: Area3D in _step_detector.get_overlapping_areas():
		if area is HeatZone and (area as HeatZone).rate > 0.0:
			return true
	return false


func _is_player_stepping() -> bool:
	if _step_detector == null:
		return false
	for body: Node3D in _step_detector.get_overlapping_bodies():
		if body != null and body.is_in_group(&"player"):
			return true
	return false


func _start_melting() -> void:
	state = State.MELTING
	_timer = maxf(0.05, melt_time)
	Audio.play_sfx(&"ice_crack")


func _update_melting_visual() -> void:
	if _visual_box == null or _material == null:
		return
	var duration: float = maxf(0.05, melt_time)
	var ratio: float = 1.0 - clampf(_timer / duration, 0.0, 1.0)
	_material.albedo_color = INTACT_COLOR.lerp(CRACKED_COLOR, ratio)
	_visual_box.position = _visual_base_pos + Vector3(sin(ratio * 36.0) * 0.04, -ratio * 0.06, 0.0)


func _break_tile() -> void:
	state = State.BROKEN
	_timer = maxf(0.05, respawn_time)
	if _collision_shape != null:
		_collision_shape.set_deferred(&"disabled", true)
	if _visual_box != null:
		_visual_box.visible = false
		_visual_box.position = _visual_base_pos


func _restore() -> void:
	state = State.INTACT
	_timer = 0.0
	if _collision_shape != null:
		_collision_shape.set_deferred(&"disabled", false)
	if _visual_box != null:
		_visual_box.visible = true
		_visual_box.position = _visual_base_pos
	if _material != null:
		_material.albedo_color = INTACT_COLOR
