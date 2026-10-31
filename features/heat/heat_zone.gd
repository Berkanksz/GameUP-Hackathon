class_name HeatZone
extends Area3D
## Area zone that applies a heating or cooling rate to an entering player.

const SUN_COLOR: Color = Color(1.0, 0.72, 0.2, 0.22)
const SHADE_COLOR: Color = Color(0.2, 0.62, 0.95, 0.22)

@export var rate: float = 0.35
@export var zone_id: StringName = &"sun_zone"

@onready var _visual_box: CSGBox3D = get_node_or_null("VisualBox") as CSGBox3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_apply_visual_tint()


func _on_body_entered(body: Node3D) -> void:
	var comp: HeatComponent = _find_heat_component(body)
	if comp != null:
		comp.set_rate(_get_zone_key(), rate)


func _on_body_exited(body: Node3D) -> void:
	var comp: HeatComponent = _find_heat_component(body)
	if comp != null:
		comp.clear_rate(_get_zone_key())


func _find_heat_component(body: Node) -> HeatComponent:
	if body == null or not body.is_in_group(&"player"):
		return null
	for child: Node in body.get_children():
		if child is HeatComponent:
			return child as HeatComponent
	return null


func _get_zone_key() -> StringName:
	if not zone_id.is_empty():
		return zone_id
	return StringName(name)


func _apply_visual_tint() -> void:
	if _visual_box == null:
		return
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = SUN_COLOR if rate >= 0.0 else SHADE_COLOR
	_visual_box.material = mat
