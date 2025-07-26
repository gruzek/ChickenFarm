extends Node3D

# Signals for build mode state changes
signal build_mode_entered
signal build_mode_exited

var preview_instance: Node3D = null
var in_build_mode = false
@export var egg_dispenser_scene: PackedScene
@onready var camera_3d: Camera3D = $"../Camera3D"

func _process(delta: float) -> void:

	# Start build mode
	if !in_build_mode and Input.is_action_just_pressed("build_thing"):
		print("Build_node: Entering build mode")
		in_build_mode = true
		build_mode_entered.emit()
		preview_instance = egg_dispenser_scene.instantiate()
		get_tree().current_scene.add_child(preview_instance)
		# Make preview semi-transparent
		preview_instance.set_preview_mode(true)

	if in_build_mode:
		var mouse_ground_position = get_mouse_ground_position()
		if mouse_ground_position:
			preview_instance.global_position = mouse_ground_position
		#print(mouse_ground_position)
		
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
			preview_instance.set_preview_mode(false)
			in_build_mode = false
			build_mode_exited.emit()

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
