class_name PenguinModel
extends Node3D
## Applies 3-band toon and inverted hull outline shader materials to the imported penguin glb mesh.

const TOON_SHADER: Shader = preload("res://shaders/toon.gdshader")
const OUTLINE_SHADER: Shader = preload("res://shaders/outline.gdshader")

const COLOR_DARK: Color = Color("1B2430")
const COLOR_BELLY: Color = Color("EAF2F8")
const COLOR_SCARF: Color = Color("D64045")
const COLOR_ORANGE: Color = Color("FFB347")
const FOOT_L_NAME: String = "foot_l"
const FOOT_R_NAME: String = "foot_r"
const BODY_NAME: String = "penguin"
## Keeps the step cycle moving while the walk blend fades out.
const MIN_PHASE_SPEED: float = 0.5

@export var outline_width: float = 0.016
@export var outline_color: Color = Color("1B2430")

@export_group("Walk")
@export var step_frequency: float = 2.6
@export var foot_lift: float = 0.07
@export var foot_swing: float = 0.45
@export var waddle_angle: float = 0.1
@export var body_bob: float = 0.03
@export var walk_blend_speed: float = 8.0
@export var slide_blend_speed: float = 11.0
@export var slide_pitch: float = -1.35
@export var slide_lift_y: float = 0.28
@export var slide_offset_x: float = -0.25

var _outline_mat: ShaderMaterial
var _toon_mats: Dictionary = {}
var _foot_l: Node3D
var _foot_r: Node3D
var _body: Node3D
var _foot_l_rest: Vector3 = Vector3.ZERO
var _foot_r_rest: Vector3 = Vector3.ZERO
var _walk_amount: float = 0.0
var _walk_target: float = 0.0
var _slide_amount: float = 0.0
var _slide_target: float = 0.0
var _step_phase: float = 0.0


func _ready() -> void:
	_outline_mat = ShaderMaterial.new()
	_outline_mat.shader = OUTLINE_SHADER
	_outline_mat.set_shader_parameter(&"outline_color", outline_color)
	_outline_mat.set_shader_parameter(&"thickness", outline_width)
	_apply_materials_recursive(self)
	_foot_l = find_child(FOOT_L_NAME, true, false) as Node3D
	_foot_r = find_child(FOOT_R_NAME, true, false) as Node3D
	_body = find_child(BODY_NAME, true, false) as Node3D
	if _foot_l != null:
		_foot_l_rest = _foot_l.position
	if _foot_r != null:
		_foot_r_rest = _foot_r.position


func _process(delta: float) -> void:
	_walk_amount = move_toward(_walk_amount, _walk_target, walk_blend_speed * delta)
	_slide_amount = move_toward(_slide_amount, _slide_target, slide_blend_speed * delta)
	if _walk_amount > 0.0 and _slide_amount < 0.5:
		_step_phase = fmod(_step_phase + delta * step_frequency * TAU * maxf(_walk_amount, MIN_PHASE_SPEED), TAU)
	elif not is_zero_approx(_step_phase):
		_step_phase = 0.0
	_apply_walk_pose()


## Sets walk animation strength from 0 (idle) to 1 (full walk speed).
func set_walk_amount(amount: float) -> void:
	_walk_target = clampf(amount, 0.0, 1.0)


## Sets belly slide animation strength from 0 (upright) to 1 (full belly slide).
func set_slide_amount(amount: float) -> void:
	_slide_target = clampf(amount, 0.0, 1.0)


func _apply_walk_pose() -> void:
	var wave: float = sin(_step_phase)
	var walk_weight: float = _walk_amount * (1.0 - _slide_amount)
	rotation.z = slide_pitch * _slide_amount
	position.y = slide_lift_y * _slide_amount
	position.x = slide_offset_x * _slide_amount
	if _foot_l != null:
		_foot_l.position = _foot_l_rest + Vector3(0.0, maxf(wave, 0.0) * foot_lift * walk_weight, 0.0)
		_foot_l.rotation.z = lerpf(wave * foot_swing * walk_weight, -0.85, _slide_amount)
	if _foot_r != null:
		_foot_r.position = _foot_r_rest + Vector3(0.0, maxf(-wave, 0.0) * foot_lift * walk_weight, 0.0)
		_foot_r.rotation.z = lerpf(-wave * foot_swing * walk_weight, -0.85, _slide_amount)
	if _body != null:
		_body.rotation.x = wave * waddle_angle * walk_weight
		_body.position.y = absf(wave) * body_bob * walk_weight


func _apply_materials_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		_apply_to_mesh_instance(node as MeshInstance3D)
	for child: Node in node.get_children():
		_apply_materials_recursive(child)


func _apply_to_mesh_instance(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.mesh == null:
		return
	for idx: int in range(mesh_instance.mesh.get_surface_count()):
		var orig_mat: Material = mesh_instance.mesh.surface_get_material(idx)
		var mat_name: String = orig_mat.resource_name.to_lower() if orig_mat != null else ""
		mesh_instance.set_surface_override_material(idx, _get_toon_material(_resolve_palette_color(mat_name)))


func _get_toon_material(color: Color) -> ShaderMaterial:
	var key: String = color.to_html()
	if _toon_mats.has(key):
		return _toon_mats[key]
	var toon_mat: ShaderMaterial = ShaderMaterial.new()
	toon_mat.shader = TOON_SHADER
	toon_mat.set_shader_parameter(&"albedo_color", color)
	toon_mat.next_pass = _outline_mat
	_toon_mats[key] = toon_mat
	return toon_mat


func _resolve_palette_color(mat_name: String) -> Color:
	if mat_name.contains("belly"):
		return COLOR_BELLY
	if mat_name.contains("scarf"):
		return COLOR_SCARF
	if mat_name.contains("orange"):
		return COLOR_ORANGE
	return COLOR_DARK
