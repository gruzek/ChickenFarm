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

# Pecking variables
var is_pecking = false
var peck_timer = 0.0
var peck_duration = 0.0

# Wolf fleeing variables
@export var wolf_detection_range = 8.0
var is_fleeing = false
var flee_speed_multiplier = 1.5

# Health
@export var starting_health = 10
var health: int:
	set(health_in):
		health = health_in
		if health <= 0:
			queue_free()

func _ready() -> void:
	health = starting_health

func _process(delta: float) -> void:
	roam_timer += delta

	if roam_timer >= roam_interval:# and !navigation_agent_3d.is_navigation_finished():
		pick_random_point()
		roam_timer = 0.0

func _physics_process(delta: float) -> void:
	# Check for nearby wolves first
	var nearby_wolf = detect_nearby_wolf()
	if nearby_wolf and not is_fleeing:
		flee_from_wolf(nearby_wolf)
	
	if !navigation_agent_3d.is_navigation_finished():
		# Reset pecking state if we start moving
		is_pecking = false
		peck_timer = 0.0
		
		# Calculate direction 
		var next_position = navigation_agent_3d.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		
		# Use appropriate speed and animation based on state
		if is_fleeing:
			velocity = direction * (roaming_speed * flee_speed_multiplier)
		else:
			velocity = direction * roaming_speed
		
		# Look the right direction
		var look_target = global_position + Vector3(direction.x, 0, direction.z)
		look_at(look_target)
		
		move_and_slide()
		
		# Play appropriate animation
		if is_fleeing:
			chicken_animation_player.play("running")
		else:
			chicken_animation_player.play("waddle")
	else:
		velocity = Vector3.ZERO
		
		# If we were fleeing and reached destination, stop fleeing
		if is_fleeing:
			is_fleeing = false
			# Don't start pecking immediately after fleeing, just go idle
			chicken_animation_player.play("idle")
		else:
			# Handle normal pecking behavior when navigation is finished
			if not is_pecking:
				start_pecking()
			else:
				update_pecking(delta)

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

func start_pecking():
	"""Start the pecking animation for a random duration between 3-7 seconds"""
	is_pecking = true
	peck_timer = 0.0
	peck_duration = randf_range(3.0, 7.0)
	chicken_animation_player.play("pecking")

func update_pecking(delta: float):
	"""Update the pecking timer and return to idle when finished"""
	peck_timer += delta
	if peck_timer >= peck_duration:
		is_pecking = false
		peck_timer = 0.0
		chicken_animation_player.play("idle")

func detect_nearby_wolf():
	"""Detect if there's a wolf within detection range"""
	var wolves = get_tree().get_nodes_in_group("wolf")
	for wolf in wolves:
		if wolf and is_instance_valid(wolf):
			var distance = global_position.distance_to(wolf.global_position)
			if distance <= wolf_detection_range:
				return wolf
	return null

func flee_from_wolf(wolf):
	"""Make the chicken flee away from the wolf"""
	is_fleeing = true
	is_pecking = false  # Stop pecking if we were
	peck_timer = 0.0
	
	# Calculate direction away from wolf
	var flee_direction = (global_position - wolf.global_position).normalized()
	
	# Pick a point away from the wolf
	var flee_distance = roaming_radius * 1.5  # Flee further than normal roaming
	var flee_offset = flee_direction * flee_distance
	var flee_position = global_position + flee_offset
	
	# Set the flee destination
	navigation_agent_3d.target_position = flee_position
