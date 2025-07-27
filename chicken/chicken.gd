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

# Coop seeking variables
var is_seeking_coop = false
var target_coop = null
var current_coop_index = 0  # For cycling through coops when they're full

# Health
@export var starting_health = 10
var health: int:
	set(health_in):
		health = health_in
		if health <= 0:
			# Decrement chicken count when dying
			var ui_node = get_tree().get_first_node_in_group("egg bank")
			if ui_node:
				ui_node.chickens -= 1
			queue_free()

func _ready() -> void:
	health = starting_health
	add_to_group("chicken")
	
	# Add to chicken count
	var ui_node = get_tree().get_first_node_in_group("egg bank")
	if ui_node:
		ui_node.chickens += 1
	
	# Connect to day-night cycle signals
	var day_night_cycle = get_tree().get_first_node_in_group("day_night_cycle")
	if day_night_cycle:
		day_night_cycle.sunset.connect(_on_sunset)
		day_night_cycle.morning_civil_twilight.connect(_on_morning_civil_twilight)
		
		# If spawning at night, immediately start seeking a coop
		if is_nighttime():
			start_seeking_coop()
		else:
			# During day, start by wandering to a random location
			pick_random_point()

func _process(delta: float) -> void:
	roam_timer += delta

	if roam_timer >= roam_interval:# and !navigation_agent_3d.is_navigation_finished():
		pick_random_point()
		roam_timer = 0.0

func _physics_process(delta: float) -> void:
	# Check for nearby wolves first (highest priority)
	var nearby_wolf = detect_nearby_wolf()
	if nearby_wolf and not is_fleeing:
		flee_from_wolf(nearby_wolf)
	
	# If seeking coop, check if we've reached the target coop
	if is_seeking_coop and target_coop and navigation_agent_3d.is_navigation_finished():
		check_coop_arrival()
	
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

# Coop seeking functions
func _on_sunset():
	"""Called when sunset signal is emitted - start seeking a coop"""
	if not is_fleeing:  # Don't interrupt fleeing behavior
		start_seeking_coop()

func _on_morning_civil_twilight():
	"""Called when morning civil twilight signal is emitted - start roaming (chickens are recreated by coops)"""
	# Stop any current behaviors and start fresh roaming
	is_seeking_coop = false
	is_pecking = false
	peck_timer = 0.0
	target_coop = null
	current_coop_index = 0
	
	# Start roaming to a random point
	pick_random_point()

func start_seeking_coop():
	"""Begin seeking the closest available coop"""
	is_seeking_coop = true
	is_pecking = false  # Stop pecking
	peck_timer = 0.0
	current_coop_index = 0  # Reset coop index (chickens forget previous attempts)
	
	find_next_coop()

func find_next_coop():
	"""Find the next closest coop to try"""
	var coops = get_tree().get_nodes_in_group("chicken_coop")
	if coops.is_empty():
		# No coops available, go back to normal behavior
		stop_seeking_coop()
		return
	
	# Sort coops by distance
	var sorted_coops = coops.duplicate()
	sorted_coops.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	
	# If we've tried all coops, give up and roam normally
	if current_coop_index >= sorted_coops.size():
		stop_seeking_coop()
		return
	
	# Set target to the next closest coop
	target_coop = sorted_coops[current_coop_index]
	navigation_agent_3d.target_position = target_coop.global_position

func check_coop_arrival():
	"""Check if the coop has space when we arrive"""
	if not target_coop or not is_instance_valid(target_coop):
		# Coop was destroyed, find another
		current_coop_index += 1
		find_next_coop()
		return
	
	# Try to enter the coop
	if target_coop.can_accept_chicken():
		# Success! Enter the coop
		if target_coop.add_chicken(self):
			# Hide the chicken (they're inside the coop)
			visible = false
			is_seeking_coop = false
			# Stop all movement
			velocity = Vector3.ZERO
			chicken_animation_player.play("idle")
		else:
			# Failed to add (shouldn't happen if can_accept_chicken was true)
			current_coop_index += 1
			find_next_coop()
	else:
		# Coop is full, try the next one
		current_coop_index += 1
		find_next_coop()

func stop_seeking_coop():
	"""Stop seeking coops and return to normal behavior"""
	# During nighttime, chickens don't give up seeking coops
	if is_nighttime():
		# Reset and try again - chickens are persistent at night
		current_coop_index = 0
		find_next_coop()
		return
	
	is_seeking_coop = false
	target_coop = null
	current_coop_index = 0
	# Resume normal roaming
	pick_random_point()



func is_nighttime() -> bool:
	"""Check if it's currently nighttime (after sunset, before morning civil twilight)"""
	var day_night_cycle = get_tree().get_first_node_in_group("day_night_cycle")
	if not day_night_cycle:
		return false
	
	# Get current time and cycle info
	var current_time = day_night_cycle.current_time
	var sunset_time = day_night_cycle.sunset_time
	var morning_civil_twilight_time = day_night_cycle.morning_civil_twilight_time
	
	# Check if we're in the night period
	# Night is from sunset to morning_civil_twilight (which wraps around to next day)
	if sunset_time < morning_civil_twilight_time:
		# Normal case: sunset and morning twilight are in same cycle
		return current_time >= sunset_time and current_time < morning_civil_twilight_time
	else:
		# Wrap-around case: night spans across cycle boundary
		return current_time >= sunset_time or current_time < morning_civil_twilight_time
