extends Node3D

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

@export var noise_scale: float = 0.1
@export var density: float = 0.1
@export var threshold: float = 0.4
@export var speed: float = 0.01
@export var fog_color: Color = Color(1.0,1.0,1.0,0.9)
@export var steps: int = 48

func _ready():
	# apply all at startup
	_apply_all_shader_params()

func _apply_all_shader_params():
	var mat = _get_shader_material()
	if mat:
		mat.set_shader_parameter("noise_scale", noise_scale)
		mat.set_shader_parameter("density", density)
		mat.set_shader_parameter("threshold", threshold)
		mat.set_shader_parameter("speed", speed)
		mat.set_shader_parameter("fog_color", fog_color)
		mat.set_shader_parameter("steps", steps)

func _get_shader_material() -> ShaderMaterial:
	var m = mesh_instance_3d.material_override
	if m is ShaderMaterial:
		return m
	# fallback: surface 0
	m = mesh_instance_3d.get_active_material(0)
	if m is ShaderMaterial:
		return m
	print("No Shader!")
	return null

#–– setters for live updates when exported in the editor or changed at runtime ––

func _set_noise_scale(v):
	noise_scale = v
	var mat = _get_shader_material()
	if mat:
		mat.set_shader_parameter("noise_scale", v)

func _set_density(v):
	density = v
	var mat = _get_shader_material()
	if mat:
		mat.set_shader_parameter("density", v)

func _set_threshold(v):
	threshold = v
	var mat = _get_shader_material()
	if mat:
		mat.set_shader_parameter("threshold", v)

func _set_speed(v):
	speed = v
	var mat = _get_shader_material()
	if mat:
		mat.set_shader_parameter("speed", v)

func _set_fog_color(c):
	fog_color = c
	var mat = _get_shader_material()
	if mat:
		mat.set_shader_parameter("fog_color", c)

func _set_steps(i):
	steps = i
	var mat = _get_shader_material()
	if mat:
		mat.set_shader_parameter("steps", i)
