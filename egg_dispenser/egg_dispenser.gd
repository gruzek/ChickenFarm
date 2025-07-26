extends BuildableObject

var in_build_mode = false

@export var egg_rate = 2
@export var egg_range = 10

@export var spin_speed = 180

@export var throwing_egg_scene : PackedScene
@export var egg_break_partical : PackedScene

@onready var gear: MeshInstance3D = $egg_dispenser_static_body/Gear

@onready var egg_spawn_timer: Timer = $"Egg Spawn Timer"

var is_active=false

func set_is_active( value ) -> void:
	is_active = value

func _ready() -> void:
	#egg_spawn_timer.wait_time = egg_rate
	print(egg_spawn_timer)
	pass

func _process(delta: float) -> void:
	if is_active:
		gear.global_rotate(Vector3.UP, spin_speed * delta)

func _on_egg_spawn_timer_timeout() -> void:
	if is_active:
		var random_pos = Vector3(randf_range(-egg_range, egg_range), 0, randf_range(-egg_range, egg_range))
		spawn_and_tween_egg(global_position + Vector3.UP * 1.5, global_position + random_pos)
		print(random_pos)

func spawn_and_tween_egg(start_pos: Vector3, end_pos: Vector3):
	# Spawn egg
	var throwing_egg = throwing_egg_scene.instantiate()
	get_tree().current_scene.add_child(throwing_egg)
	throwing_egg.global_position = start_pos
	
	# Tween egg
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var duration = 0.5
	var peak_height = 2.5
	
	tween.tween_method(func(t):
		var flat_lerp = start_pos.lerp(end_pos, t)
		var vertical_arc = sin(t * PI) * peak_height
		throwing_egg.global_position = flat_lerp + Vector3.UP * vertical_arc
	, 0.0, 1.0, duration)
	
	tween.tween_callback(func():
		#await get_tree().create_timer(duration).timeout
		throwing_egg.explode()
		)
