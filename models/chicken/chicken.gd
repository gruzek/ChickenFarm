extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var chicken_animation_player: AnimationPlayer = $chicken_animation_player

# Egg variables
@export var egg: PackedScene
@export var egg_chance = 50

# Roaming variables
@export var roaming_speed = 5.0
@export var roaming_radius = 15.0
@export var roam_interval = 3.0
var roam_timer = 0.0

func _process(delta: float) -> void:
	roam_timer += delta

	if roam_timer >= roam_interval:# and !navigation_agent_3d.is_navigation_finished():
		pick_random_point()
		roam_timer = 0.0

func _physics_process(delta: float) -> void:
	if !navigation_agent_3d.is_navigation_finished():
		# Calculate direction 
		var next_position = navigation_agent_3d.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		velocity = direction * roaming_speed
		
		# Look the right direction
		var look_target = global_position + Vector3(direction.x, 0, direction.z)
		look_at(look_target)
		
		move_and_slide()
		chicken_animation_player.play("waddle")
	else:
		velocity = Vector3.ZERO
		chicken_animation_player.play("idle")

func pick_random_point():
	var rand_offset = Vector3(
		randf_range(-roaming_radius, roaming_radius),
		0,
		randf_range(-roaming_radius, roaming_radius)
	)
	var new_pos = global_position + rand_offset
	navigation_agent_3d.target_position = new_pos

func lay_egg():
	if randf_range(0, 100) <= egg_chance:
		print("EGG!")
		var new_egg = egg.instantiate()
		get_tree().current_scene.add_child(new_egg)
		new_egg.global_position = position

func _on_egg_timer_timeout() -> void:
	lay_egg()
