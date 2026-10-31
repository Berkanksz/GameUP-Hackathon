class_name SlideSwoopRamp
extends Node3D
## Curved downhill and uphill ski-jump ramp that launches the player across gaps when belly-sliding.

@export var launch_velocity: Vector2 = Vector2(10.8, 9.4)
@export var walk_boost_velocity: Vector2 = Vector2(8.8, 8.2)
@export var hint_monologue_key: StringName = &"TUT_SLIDE"

var _hint_shown: bool = false
var _launch_cooldown: float = 0.0

@onready var _entry_zone: Area3D = $EntryZone
@onready var _launch_zone: Area3D = $LaunchZone


func _ready() -> void:
	if _entry_zone != null:
		_entry_zone.body_entered.connect(_on_entry_body_entered)
	if _launch_zone != null:
		_launch_zone.body_entered.connect(_on_launch_body_entered)


func _physics_process(delta: float) -> void:
	if _launch_cooldown > 0.0:
		_launch_cooldown = maxf(0.0, _launch_cooldown - delta)
	if _launch_zone != null and _launch_cooldown <= 0.0:
		for body: Node3D in _launch_zone.get_overlapping_bodies():
			if body.is_in_group(&"player"):
				_try_launch(body)


func _on_entry_body_entered(body: Node3D) -> void:
	if not body.is_in_group(&"player"):
		return
	if not _hint_shown and not hint_monologue_key.is_empty():
		_hint_shown = true
		EventBus.monologue_requested.emit(hint_monologue_key)


func _on_launch_body_entered(body: Node3D) -> void:
	if not body.is_in_group(&"player"):
		return
	_try_launch(body)


func _try_launch(body: Node3D) -> void:
	if _launch_cooldown > 0.0:
		return
	if not body.has_method(&"apply_launch_boost"):
		return
	var sliding: bool = false
	if body.has_method(&"is_sliding"):
		sliding = bool(body.call(&"is_sliding"))
	var vx: float = 0.0
	if body is CharacterBody3D:
		vx = (body as CharacterBody3D).velocity.x
	if sliding or vx > 2.2:
		_launch_cooldown = 0.45
		var target_vel: Vector2 = launch_velocity if sliding else walk_boost_velocity
		body.call(&"apply_launch_boost", target_vel.x, target_vel.y)
