class_name LitterItem
extends Area3D
## Collectible recyclable litter item with type icon and color coding.

const COLOR_PAPER: Color = Color(0.18, 0.52, 0.88, 1.0)
const COLOR_PLASTIC: Color = Color(0.95, 0.78, 0.15, 1.0)
const COLOR_GLASS: Color = Color(0.20, 0.75, 0.38, 1.0)

@export var litter_type: StringName = &"paper"
@export var bob_amplitude: float = 0.08
@export var bob_speed: float = 2.6
@export var spin_speed: float = 1.4

var _picked: bool = false
var _base_y: float = 0.0
var _clock: float = 0.0

@onready var _visual_root: Node3D = %VisualRoot
@onready var _paper_mesh: Node3D = %PaperMesh
@onready var _plastic_mesh: Node3D = %PlasticMesh
@onready var _glass_mesh: Node3D = %GlassMesh
@onready var _icon_label: Label3D = %IconLabel


func _ready() -> void:
	add_to_group(&"litter")
	_base_y = position.y
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	_apply_type_visual()


func _process(delta: float) -> void:
	if _picked:
		return
	_clock += delta * bob_speed
	if _visual_root != null:
		_visual_root.position.y = sin(_clock) * bob_amplitude
		_visual_root.rotate_y(delta * spin_speed)


func _physics_process(_delta: float) -> void:
	if _picked or not monitoring:
		return
	for body: Node3D in get_overlapping_bodies():
		if _try_pick(body):
			return


func _apply_type_visual() -> void:
	if _paper_mesh == null or _plastic_mesh == null or _glass_mesh == null:
		return
	_paper_mesh.visible = (litter_type == &"paper")
	_plastic_mesh.visible = (litter_type == &"plastic")
	_glass_mesh.visible = (litter_type == &"glass")
	if _icon_label == null:
		return
	if litter_type == &"paper":
		_icon_label.text = "◼"
		_icon_label.modulate = COLOR_PAPER
	elif litter_type == &"plastic":
		_icon_label.text = "▲"
		_icon_label.modulate = COLOR_PLASTIC
	else:
		_icon_label.text = "●"
		_icon_label.modulate = COLOR_GLASS


func _on_body_entered(body: Node3D) -> void:
	_try_pick(body)


func _try_pick(body: Node3D) -> bool:
	if _picked:
		return false
	if not body.is_in_group(&"player"):
		return false
	if bool(body.get("is_carrying")):
		return false
	_picked = true
	set_deferred(&"monitoring", false)
	EventBus.litter_picked.emit(litter_type)
	Audio.play_sfx(&"pickup")
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", position.y + 0.5, 0.22)
	tween.chain().tween_callback(queue_free)
	return true
