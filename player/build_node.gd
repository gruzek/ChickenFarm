extends Node3D

# Signals for build mode state changes
signal build_mode_entered
signal build_mode_exited

var preview_instance: Node3D = null
var in_build_mode = false
var current_item_index = 0
var buildable_scenes: Array[PackedScene]
var buildable_costs: Array[int]
var building_names: Array[String]
var cost_label: Label3D = null
	
@onready var camera_3d: Camera3D = $"../Camera3D"
@onready var egg_bank = get_tree().get_first_node_in_group("egg bank")

var current_scene

func _ready():
	# Load buildable scenes programmatically
	buildable_scenes = [
		load("res://chicken_coop/chicken_coop.tscn"),
		load("res://egg_pickerupper/egg_pickerupper.tscn"),
		load("res://egg_dispenser/egg_dispenser.tscn"),
	]

	buildable_costs = [
		5,
		100,
		300
	]

	building_names = [
		"Chicken Coop",
		"Egg PickerUpperinator 5000",
		"Egg Dispenser"
	]

	# Get current scene
	current_scene = get_tree().current_scene.name

func _process(delta: float) -> void:
	# Don't build in the start scene
	if current_scene == "Start Scene":
		return

	# Start build mode
	if !in_build_mode and Input.is_action_just_pressed("build_thing"):
		if buildable_scenes.size() > 0:
			in_build_mode = true
			build_mode_entered.emit()
			instantiate_preview()
			# Preview mode is already set in instantiate_preview
	elif in_build_mode and Input.is_action_just_pressed("build_thing"):
		preview_instance.queue_free()
		in_build_mode = false
		build_mode_exited.emit()
	
	if in_build_mode:
		var mouse_ground_position = get_mouse_ground_position()
		if mouse_ground_position:
			preview_instance.global_position = mouse_ground_position
			if buildable_costs[current_item_index] > egg_bank.eggs:
				preview_instance.set_buildable(false)
			else:
				# Check for collisions and update buildable state
				check_build_collision()
		#print(mouse_ground_position)
		
		# Item selection
		if Input.is_action_just_pressed("next_build_item"):
			switch_to_next_item()
		if Input.is_action_just_pressed("previous_build_item"):
			switch_to_previous_item()
		
		# Cancel build
		if Input.is_action_just_pressed("cancel_build"):
			preview_instance.queue_free()
			in_build_mode = false
			build_mode_exited.emit()
		
		# Finalize build
		if Input.is_action_just_pressed("finalize_build"):
			if preview_instance.is_buildable:
				# Make preview fully opaque
				preview_instance.set_buildable(true)
				preview_instance.set_preview_mode(false)
				# Activate the object when placed
				set_active(true)
				in_build_mode = false
				egg_bank.eggs = egg_bank.eggs - buildable_costs[current_item_index]
				remove_cost_label_from_preview()
				build_mode_exited.emit()

# Item switching functions
func switch_to_next_item():
	if buildable_scenes.size() > 1:
		current_item_index = (current_item_index + 1) % buildable_scenes.size()
		update_preview_item()

func switch_to_previous_item():
	if buildable_scenes.size() > 1:
		current_item_index = (current_item_index - 1 + buildable_scenes.size()) % buildable_scenes.size()
		update_preview_item()

func update_preview_item():
	if preview_instance:
		# Store current position
		var current_position = preview_instance.global_position
		# Remove old preview
		preview_instance.queue_free()
		# Create new preview
		preview_instance = buildable_scenes[current_item_index].instantiate()
		get_tree().current_scene.add_child(preview_instance)
		# Set preview mode and restore position
		preview_instance.set_preview_mode(true)  # This will trigger collision area setup
		preview_instance.global_position = current_position
		# Disable activity for preview objects
		set_active(false)
		# Add cost label above the preview
		var can_afford = false
		if (egg_bank.eggs - buildable_costs[current_item_index] >=0):
			can_afford=true
		add_cost_label_to_preview(can_afford)

# Create the initial preview instance
func instantiate_preview():
	preview_instance = buildable_scenes[current_item_index].instantiate()
	get_tree().current_scene.add_child(preview_instance)
	
	# Set preview mode first - this will trigger collision area setup
	preview_instance.set_preview_mode(true)
	
	# Disable activity for preview objects
	set_active(false)
	
	# Add cost label above the preview
	var can_afford = false
	if (egg_bank.eggs - buildable_costs[current_item_index] >=0):
		can_afford=true
	add_cost_label_to_preview(can_afford)

# For building
func get_mouse_ground_position():
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera_3d.project_ray_origin(mouse_pos)
	var to = from + camera_3d.project_ray_normal(mouse_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1  # only look at layer 1 (ground)
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position
	else:
		return null

# Check if the preview object is colliding with anything
func check_build_collision():
	if not preview_instance:
		return
	
	# Method 1: Use physics shape query
	var collision_shape = preview_instance.get_collision_shape()
	if not collision_shape:
		print("Warning: Preview instance has no collision shape")
		return
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = collision_shape
	query.transform = preview_instance.global_transform
	query.collision_mask = 3  # Layers 1 and 2 (terrain + buildings)
	
	# Exclude the preview object itself from collision detection
	var exclude_rids = []
	if preview_instance.has_method("get_rid"):
		exclude_rids.append(preview_instance.get_rid())
	query.exclude = exclude_rids
	
	var result = space_state.intersect_shape(query)
	
	# Filter out collisions with objects named "Ground"
	var filtered_collisions = []
	for collision in result:
		var collider = collision.collider
		# Check if the collider or any of its parents is named "Ground"
		var should_ignore = false
		var current_node = collider
		while current_node != null:
			if current_node.name == "Ground":
				should_ignore = true
				break
			current_node = current_node.get_parent()
		
		if not should_ignore:
			filtered_collisions.append(collision)
	
	var is_colliding = filtered_collisions.size() > 0
	
	# Method 2: Direct overlap check with existing buildings
	# This is a backup method to ensure we detect collisions with other buildings
	var is_overlapping_buildings = false
	var buildings = get_tree().get_nodes_in_group("buildable_objects")
	
	for building in buildings:
		# Skip the preview instance itself
		if building == preview_instance:
			continue
		
		# Check if the preview's position is close to this building's position
		var distance = preview_instance.global_position.distance_to(building.global_position)
		
		if distance < 2.0:
			is_overlapping_buildings = true
			break
	
	# Combine results from both methods
	is_colliding = filtered_collisions.size() > 0 or is_overlapping_buildings
	
	if filtered_collisions.size() > 0:
		for i in range(min(3, filtered_collisions.size())):
			var collider = filtered_collisions[i].collider
	#elif is_overlapping_buildings:
		#print("DEBUG: Overlapping with existing buildings")
	#else:
		#print("DEBUG: No collisions detected")
	
	# Update buildable state
	preview_instance.set_buildable(not is_colliding)

# Helper function to set active state on preview instance or its children
func set_active(value: bool):
	if not preview_instance:
		return
		
	# First check if the preview instance itself has the method
	if preview_instance.has_method("set_is_active"):
		preview_instance.set_is_active(value)
		return
		
	# If not, check immediate children
	for child in preview_instance.get_children():
		if child.has_method("set_is_active"):
			child.set_is_active(value)
			return

func remove_cost_label_from_preview():
	# Remove any existing cost label
	if cost_label != null:
		cost_label.queue_free()
		cost_label=null

# Add a label showing the cost above the preview instance
func add_cost_label_to_preview(can_afford):
	if not preview_instance:
		return
		
	# Remove any existing cost label
	#var existing_label = preview_instance.find_child("CostLabel")
	#if existing_label:
		#existing_label.queue_free()
	
	# Create a new Label3D node
	cost_label = Label3D.new()
	cost_label.name = "CostLabel"
	
	# Set label properties
	cost_label.text = str(buildable_costs[current_item_index]) + " eggs"
	cost_label.font_size = 32  # Larger font size
	if (can_afford):
		cost_label.modulate = Color(0.8, 1, .8)  # green color for affordable
	else:
		cost_label.modulate = Color(1, 0, 0)  # red color for unaffordable
	cost_label.outline_size = 2  # Add outline
	cost_label.outline_modulate = Color(0, 0, 0)  # Black outline
	
	# Make the label visible from all angles
	cost_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cost_label.no_depth_test = true  # Ensure it renders on top
	cost_label.fixed_size = true  # Keep consistent size regardless of distance
	
	# Position the label above the object based on object size
	var height_offset = 3.0  # Default height offset
	
	# Try to get a better height based on the object's collision shape
	var collision_shape = find_collision_shape_recursive(preview_instance)
	if collision_shape and collision_shape is BoxShape3D:
		# For box shapes, use the box height + some padding
		height_offset = 0
	
	# Position the label above the object
	cost_label.position = Vector3(0, height_offset, 0)
	
	# Add the label as a child of the preview instance
	preview_instance.add_child(cost_label)
	
	# Add the building name to the label
	cost_label.text = building_names[current_item_index] + "\nCost: " + str(buildable_costs[current_item_index]) + " eggs"

# Helper function to find collision shapes recursively in a node and its children
func find_collision_shape_recursive(node):
	# Check if this node has a shape property (like CollisionShape3D)
	if node is CollisionShape3D and node.shape:
		return node.shape
	
	# Check if this node is a StaticBody3D with collision shapes
	if node is StaticBody3D:
		for child in node.get_children():
			if child is CollisionShape3D and child.shape:
				return child.shape
	
	# Recursively check children
	for child in node.get_children():
		var result = find_collision_shape_recursive(child)
		if result:
			return result
	
	return null
