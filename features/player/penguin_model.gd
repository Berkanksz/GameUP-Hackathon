class_name PenguinModel
extends Node3D
## Applies 3-band toon and inverted hull outline shader materials to the imported penguin glb mesh.

const TOON_SHADER_PATH: String = "res://shaders/toon.gdshader"
const OUTLINE_SHADER_PATH: String = "res://shaders/outline.gdshader"

const COLOR_DARK: Color = Color("1B2430")
const COLOR_BELLY: Color = Color("EAF2F8")
const COLOR_SCARF: Color = Color("D64045")
const COLOR_ORANGE: Color = Color("FFB347")
const COLOR_OUTLINE: Color = Color("1B2430")

@export var outline_thickness: float = 0.016


func _ready() -> void:
	_apply_materials_recursive(self)


func _apply_materials_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		_apply_to_mesh_instance(node as MeshInstance3D)
	for child: Node in node.get_children():
		_apply_materials_recursive(child)


func _apply_to_mesh_instance(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.mesh == null:
		return
	var toon_shader: Shader = load(TOON_SHADER_PATH) as Shader
	var outline_shader: Shader = load(OUTLINE_SHADER_PATH) as Shader
	if toon_shader == null or outline_shader == null:
		return
	var outline_mat: ShaderMaterial = ShaderMaterial.new()
	outline_mat.shader = outline_shader
	outline_mat.set_shader_parameter(&"outline_color", COLOR_OUTLINE)
	outline_mat.set_shader_parameter(&"thickness", outline_thickness)

	var surface_count: int = mesh_instance.mesh.get_surface_count()
	for idx: int in range(surface_count):
		var orig_mat: Material = mesh_instance.mesh.surface_get_material(idx)
		var mat_name: String = orig_mat.resource_name if orig_mat != null else ""
		var toon_mat: ShaderMaterial = ShaderMaterial.new()
		toon_mat.shader = toon_shader
		toon_mat.set_shader_parameter(&"albedo_color", _resolve_palette_color(mat_name))
		toon_mat.next_pass = outline_mat
		mesh_instance.set_surface_override_material(idx, toon_mat)


func _resolve_palette_color(mat_name: String) -> Color:
	if mat_name.contains("belly"):
		return COLOR_BELLY
	if mat_name.contains("scarf"):
		return COLOR_SCARF
	if mat_name.contains("orange"):
		return COLOR_ORANGE
	return COLOR_DARK
