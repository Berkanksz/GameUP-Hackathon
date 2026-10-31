class_name IceBoulder
extends Node3D
## Interactive snow boulder that rolls forward when pushed or slid into, smashing a barrier and forming a bridge.

@export var roll_offset: Vector3 = Vector3(3.4, -1.35, 0.0)
@export var roll_duration: float = 0.55

var _triggered: bool = false

@onready var _trigger_area: Area3D = $TriggerArea
@onready var _boulder_body: AnimatableBody3D = $BoulderBody
@onready var _barrier_body: StaticBody3D = get_node_or_null("IceBarrier")


func _ready() -> void:
	if _trigger_area != null:
		_trigger_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _triggered or not body.is_in_group(&"player"):
		return
	_triggered = true
	Audio.play_sfx(&"ice_crack")
	if _boulder_body != null:
		var target_pos: Vector3 = _boulder_body.position + roll_offset
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(_boulder_body, "position", target_pos, roll_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(_boulder_body, "rotation_degrees:z", -320.0, roll_duration)
	if _barrier_body != null:
		var btween: Tween = create_tween()
		btween.tween_interval(roll_duration * 0.65)
		btween.tween_callback(func() -> void:
			Audio.play_sfx(&"ice_crack")
			_barrier_body.collision_layer = 0
			_barrier_body.visible = false
		)
