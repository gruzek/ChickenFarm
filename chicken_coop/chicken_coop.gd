extends BuildableObject

var in_build_mode = false

# Capacity management
@export var max_capacity = 10
var current_occupancy = 0
var chickens_count_inside = 0  # Just count chickens, don't store references since they'll be destroyed

# Chicken scene for spawning
@export var chicken_scene: PackedScene = preload("res://chicken/chicken.tscn")

func _ready():
	add_to_group("chicken_coop")
	
	# Add this coop's capacity to the total
	var ui_node = get_tree().get_first_node_in_group("egg bank")
	if ui_node:
		ui_node.total_coop_capacity += max_capacity
	
	# Connect to day-night cycle signals
	var day_night_cycle = get_tree().get_first_node_in_group("day_night_cycle")
	if day_night_cycle:
		day_night_cycle.morning_civil_twilight.connect(_on_morning_civil_twilight)

# Capacity management functions
func can_accept_chicken() -> bool:
	"""Check if the coop has space for another chicken"""
	return current_occupancy < max_capacity

func add_chicken(chicken: Node) -> bool:
	"""Try to add a chicken to the coop. Returns true if successful."""
	if not can_accept_chicken():
		return false
	
	# Add to counts
	chickens_count_inside += 1
	current_occupancy += 1
	
	# Update chickens in coops count
	var ui_node = get_tree().get_first_node_in_group("egg bank")
	if ui_node:
		ui_node.chickens_in_coops += 1
	
	# Destroy the chicken - it's now safely stored as a count
	chicken.queue_free()
	
	return true

func remove_chicken_by_count() -> bool:
	"""Remove one chicken from the coop count. Returns true if successful."""
	if chickens_count_inside <= 0:
		return false  # No chickens inside
	
	chickens_count_inside -= 1
	current_occupancy -= 1
	
	# Update chickens in coops count
	var ui_node = get_tree().get_first_node_in_group("egg bank")
	if ui_node:
		ui_node.chickens_in_coops -= 1
	
	return true

func is_full() -> bool:
	"""Check if the coop is at maximum capacity"""
	return current_occupancy >= max_capacity

func is_empty() -> bool:
	"""Check if the coop is empty"""
	return current_occupancy == 0

func get_available_space() -> int:
	"""Get the number of available spaces in the coop"""
	return max_capacity - current_occupancy

func get_occupancy_info() -> Dictionary:
	"""Get detailed information about coop occupancy"""
	return {
		"current_occupancy": current_occupancy,
		"max_capacity": max_capacity,
		"available_space": get_available_space(),
		"is_full": is_full(),
		"is_empty": is_empty(),
		"occupancy_percentage": (float(current_occupancy) / float(max_capacity)) * 100.0
	}

func _on_morning_civil_twilight():
	"""Called at morning civil twilight - spawn chickens from the coop"""
	while chickens_count_inside > 0:
		# Create a new chicken
		var new_chicken = chicken_scene.instantiate()
		
		# Add to the scene
		get_tree().current_scene.add_child(new_chicken)
		
		# Position near the coop (with some randomness)
		var spawn_offset = Vector3(
			randf_range(-2.0, 2.0),
			0,
			randf_range(-2.0, 2.0)
		)
		new_chicken.global_position = global_position + spawn_offset
		
		# Remove from coop count
		remove_chicken_by_count()
