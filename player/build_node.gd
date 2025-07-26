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
	print("Build_node: Loaded ", buildable_scenes.size(), " buildable scenes")

func _process(delta: float) -> void:

	# Start build mode
	if !in_build_mode and Input.is_action_just_pressed("build_thing"):
		print("Build_node: Entering build mode")
		if buildable_scenes.size() > 0:
			in_build_mode = true
			build_mode_entered.emit()
			preview_instance = buildable_scenes[current_item_index].instantiate()
			get_tree().current_scene.add_child(preview_instance)
			# Make preview semi-transparent
			preview_instance.set_preview_mode(true)

	if in_build_mode:
		var mouse_ground_position = get_mouse_ground_position()
		if mouse_ground_position:
			preview_instance.global_position = mouse_ground_position
		#print(mouse_ground_position)
		
		# Item selection
		if Input.is_action_just_pressed("next_build_item"):
			print("DEBUG: next_item pressed")
			switch_to_next_item()
		if Input.is_action_just_pressed("previous_build_item"):
			print("DEBUG: previous_item pressed")
			switch_to_previous_item()
		
		# Cancle build
		if Input.is_action_just_pressed("cancel_build"):
			print("Build_node: Canceling build mode")
			preview_instance.queue_free()
			in_build_mode = false
			build_mode_exited.emit()
		
		# Finalize build
		if Input.is_action_just_pressed("finalize_build"):
			print("Build_node: Finalizing build mode")
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
		print("Build_node: Switched to item ", current_item_index)

func switch_to_previous_item():
	if buildable_scenes.size() > 1:
		current_item_index = (current_item_index - 1 + buildable_scenes.size()) % buildable_scenes.size()
		update_preview_item()
		print("Build_node: Switched to item ", current_item_index)

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
		preview_instance.set_preview_mode(true)
		preview_instance.global_position = current_position

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
