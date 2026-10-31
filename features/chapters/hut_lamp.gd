class_name HutLamp
extends Node3D
## Solar lamp prop that lights up when its choice is answered with the connect option.

@export var choice_id: StringName = &"lamp"
@export var on_option_id: StringName = &"on"
@export var light_energy: float = 2.4
@export var fade_time: float = 1.2
@export var glow_color: Color = Color(1.0, 0.85, 0.45, 1.0)

@onready var _light: OmniLight3D = get_node_or_null("OmniLight3D") as OmniLight3D
@onready var _bulb: GeometryInstance3D = get_node_or_null("Bulb") as GeometryInstance3D


func _ready() -> void:
	if _light != null:
		_light.light_energy = 0.0
	EventBus.choice_made.connect(_on_choice_made)
	if GameState.has_flag(StringName("choice_" + str(choice_id) + "_" + str(on_option_id))):
		_turn_on(0.0)


func _on_choice_made(id: StringName, option: StringName) -> void:
	if id == choice_id and option == on_option_id:
		_turn_on(fade_time)


func _turn_on(duration: float) -> void:
	if _bulb != null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = glow_color
		mat.emission_enabled = true
		mat.emission = glow_color
		mat.emission_energy_multiplier = 2.0
		_bulb.material = mat
	if _light == null:
		return
	if duration <= 0.0:
		_light.light_energy = light_energy
		return
	create_tween().tween_property(_light, "light_energy", light_energy, duration)
