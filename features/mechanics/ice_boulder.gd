class_name IceBoulder
extends Node3D
## Interactive snow boulder that rolls forward as the player pushes it, shattering an ice barrier on impact.

@export var max_push_distance: float = 2.45
@export var push_speed: float = 3.2
@export var boulder_radius: float = 0.92

var _pushed_distance: float = 0.0
var _shattered: bool = false
var _pushing_player: CharacterBody3D = null
var _roll_sfx_timer: float = 0.0

@onready var _boulder_visual: Node3D = $BoulderVisual
@onready var _push_zone: Area3D = $BoulderVisual/PushZone
@onready var _barrier_body: StaticBody3D = get_node_or_null("IceBarrier")


func _ready() -> void:
	if _push_zone != null:
		_push_zone.body_entered.connect(_on_body_entered)
		_push_zone.body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if _shattered or _boulder_visual == null:
		return
	if _pushing_player == null or not is_instance_valid(_pushing_player):
		return

	var input_x: float = Input.get_axis(&"move_left", &"move_right")
	var moving_right: bool = input_x > 0.05 or _pushing_player.velocity.x > 0.15
	var behind_ball: bool = _pushing_player.global_position.x <= _boulder_visual.global_position.x + 0.15

	if moving_right and behind_ball:
		if _pushing_player.has_method(&"set_pushing_object"):
			_pushing_player.call(&"set_pushing_object", true)
		var step: float = minf(push_speed * delta, max_push_distance - _pushed_distance)
		_pushed_distance += step
		_boulder_visual.position.x += step
		_boulder_visual.rotation.z -= step / maxf(boulder_radius, 0.1)
		var max_player_x: float = _boulder_visual.global_position.x - 0.96
		if _pushing_player.global_position.x > max_player_x:
			_pushing_player.global_position.x = max_player_x
		_roll_sfx_timer += delta
		if _roll_sfx_timer >= 0.28:
			_roll_sfx_timer = 0.0
			Audio.play_sfx(&"snow_step")
		if _pushed_distance >= max_push_distance - 0.02:
			_shatter_barrier()
	else:
		if _pushing_player.has_method(&"set_pushing_object"):
			_pushing_player.call(&"set_pushing_object", false)
		var max_player_x: float = _boulder_visual.global_position.x - 0.96
		if behind_ball and _pushing_player.global_position.x > max_player_x:
			_pushing_player.global_position.x = max_player_x
			if _pushing_player.velocity.x > 0.0:
				_pushing_player.velocity.x = 0.0


func _shatter_barrier() -> void:
	if _shattered:
		return
	_shattered = true
	if _pushing_player != null and is_instance_valid(_pushing_player) and _pushing_player.has_method(&"set_pushing_object"):
		_pushing_player.call(&"set_pushing_object", false)
	Audio.play_sfx(&"ice_crack")
	if _barrier_body != null:
		var col: CollisionShape3D = _barrier_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if col != null:
			col.set_deferred(&"disabled", true)
		_barrier_body.collision_layer = 0
		var btween: Tween = create_tween().set_parallel(true)
		btween.tween_property(_barrier_body, "scale", Vector3(1.35, 0.08, 1.35), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		btween.tween_property(_barrier_body, "position:y", 0.1, 0.28)
		btween.chain().tween_callback(func() -> void: _barrier_body.visible = false)
	if _boulder_visual != null:
		var rtween: Tween = create_tween().set_parallel(true)
		rtween.tween_property(_boulder_visual, "position", _boulder_visual.position + Vector3(1.1, -1.25, 0.0), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		rtween.tween_property(_boulder_visual, "rotation:z", _boulder_visual.rotation.z - 1.6, 0.34)
		rtween.tween_property(_boulder_visual, "scale", Vector3(0.05, 0.05, 0.05), 0.34)
		rtween.chain().tween_callback(func() -> void: _boulder_visual.visible = false)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player") and body is CharacterBody3D:
		_pushing_player = body as CharacterBody3D


func _on_body_exited(body: Node3D) -> void:
	if body == _pushing_player:
		if _pushing_player != null and is_instance_valid(_pushing_player) and _pushing_player.has_method(&"set_pushing_object"):
			_pushing_player.call(&"set_pushing_object", false)
		_pushing_player = null
