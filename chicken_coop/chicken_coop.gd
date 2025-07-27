extends BuildableObject

var in_build_mode = false

# Capacity management
@export var max_capacity = 10
var current_occupancy = 0
var chickens_inside = []  # Array to track which chickens are inside

func _ready():
	add_to_group("chicken_coop")
	
	# Add this coop's capacity to the total
	var ui_node = get_tree().get_first_node_in_group("egg bank")
	if ui_node:
		ui_node.total_coop_capacity += max_capacity

# Capacity management functions
func can_accept_chicken() -> bool:
	"""Check if the coop has space for another chicken"""
	return current_occupancy < max_capacity

func add_chicken(chicken: Node) -> bool:
	"""Try to add a chicken to the coop. Returns true if successful."""
	if not can_accept_chicken():
		return false
	
	if chicken in chickens_inside:
		return false  # Chicken is already inside
	
	chickens_inside.append(chicken)
	current_occupancy += 1
	
	# Update chickens in coops count
	var ui_node = get_tree().get_first_node_in_group("egg bank")
	if ui_node:
		ui_node.chickens_in_coops += 1
	
	return true

func remove_chicken(chicken: Node) -> bool:
	"""Remove a chicken from the coop. Returns true if successful."""
	if chicken not in chickens_inside:
		return false  # Chicken wasn't inside
	
	chickens_inside.erase(chicken)
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
