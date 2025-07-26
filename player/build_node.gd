extends Node3D

# Signals for build mode state changes
signal build_mode_entered
signal build_mode_exited

var preview_instance: Node3D = null
var in_build_mode = false
var current_item_index = 0
var buildable_scenes: Array[PackedScene]
@onready var camera_3d: Camera3D = $"../Camera3D"

func _ready():
	# Load buildable scenes programmatically
	buildable_scenes = [
		load("res://models/chicken_coop/chicken_coop.tscn"),
		load("res://models/egg_dispenser/egg_dispenser.tscn")
	]

func _process(delta: float) -> void:

	# Start build mode
	if !in_build_mode and Input.is_action_just_pressed("build_thing"):
		if buildable_scenes.size() > 0:
			in_build_mode = true
			build_mode_entered.emit()
			instantiate_preview()
			# Preview mode is already set in instantiate_preview

	if in_build_mode:
		var mouse_ground_position = get_mouse_ground_position()
		if mouse_ground_position:
			preview_instance.global_position = mouse_ground_position
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
				in_build_mode = false
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

# Create the initial preview instance
func instantiate_preview():
	preview_instance = buildable_scenes[current_item_index].instantiate()
	get_tree().current_scene.add_child(preview_instance)
	
	# Set preview mode first - this will trigger collision area setup
	preview_instance.set_preview_mode(true)



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
	var is_colliding = result.size() > 0
	
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
	is_colliding = result.size() > 0 or is_overlapping_buildings
	
	if result.size() > 0:
		for i in range(min(3, result.size())):
			var collider = result[i].collider
	#elif is_overlapping_buildings:
		#print("DEBUG: Overlapping with existing buildings")
	#else:
		#print("DEBUG: No collisions detected")
	
	# Update buildable state
	preview_instance.set_buildable(not is_colliding)
