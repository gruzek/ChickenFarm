extends CharacterBody3D

# Player Statistics
@export var SPEED = 12.0
const JUMP_VELOCITY = 4.5
@export var ROTATION_SPEED = 10.0  # Speed at which the player rotates to face movement direction
@export var pickup_range = 25

@onready var camera_3d: Camera3D = $Camera3D
#@onready var pickup_area: Area3D = $PickupArea
@onready var player_rig: Node3D = $player_rig

@export var chicken_scene: PackedScene

# Variables for animation
@export var anim_blend_speed = 15
enum {IDLE, RUN}
var currentAnim = IDLE
@onready var animation_tree: AnimationTree = $player_rig/AnimationPlayer/AnimationTree

signal egg_amount_changed(value)




var in_build_mode = false
var preview_instance: Node3D = null

func _process(delta: float) -> void:
	# Start build mode
	if !in_build_mode and Input.is_action_just_pressed("build_thing"):
		in_build_mode = true
		preview_instance = chicken_scene.instantiate()
		get_tree().current_scene.add_child(preview_instance)
		# Make preview semi-transparent
		preview_instance.set_preview_mode(true)

	if in_build_mode:
		var mouse_ground_position = get_mouse_ground_position()
		if mouse_ground_position:
			preview_instance.global_position = mouse_ground_position
		#print(mouse_ground_position)
		
		# Cancle build
		if Input.is_action_just_pressed("ui_cancel"):
			preview_instance.queue_free()
			in_build_mode = false
		
		# Finalize build
		if Input.is_action_just_pressed("ui_accept"):
			# Make preview fully opaque
			preview_instance.set_preview_mode(false)
			in_build_mode = false
			
	# Pickup logic
	check_for_egg()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# Animation update
	handle_animations(delta)

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Handle movement
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Rotate player_rig to face movement direction
		var target_rotation = atan2(direction.x, direction.z)
		rotate_player_to_direction(target_rotation, delta)
		
		# Play run animation
		currentAnim = RUN
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		# Play idle animation
		currentAnim = IDLE

	move_and_slide()

# Function to smoothly rotate the player_rig to face the movement direction
func rotate_player_to_direction(target_rotation: float, delta: float) -> void:
	# Get current Y rotation
	var current_rotation = player_rig.rotation.y
	
	# Calculate the shortest angle difference
	var angle_diff = target_rotation - current_rotation
	# Normalize the angle difference to be between -PI and PI
	while angle_diff > PI:
		angle_diff -= 2 * PI
	while angle_diff < -PI:
		angle_diff += 2 * PI
	
	# Smoothly interpolate to the target rotation
	var new_rotation = current_rotation + angle_diff * ROTATION_SPEED * delta
	player_rig.rotation.y = new_rotation

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

# Controls Animations
func handle_animations(delta):
	match currentAnim:
		IDLE:
			# Changes the blend amount in the animation tree depending on the players state
			animation_tree["parameters/Run/blend_amount"] = lerpf(animation_tree["parameters/Run/blend_amount"], 0, anim_blend_speed * delta)
		RUN:
			animation_tree["parameters/Run/blend_amount"] = lerpf(animation_tree["parameters/Run/blend_amount"], 1, anim_blend_speed * delta)

# Checks if an egg is in pickup range then picks it up
func check_for_egg():
	for egg in get_tree().get_nodes_in_group("egg"):
		if global_transform.origin.distance_to(egg.global_transform.origin) < pickup_range:
			egg.queue_free()
			egg_amount_changed.emit(1)

#func _ready():
	#pickup_area.body_entered.connect(_on_body_entered)

## For picking up/interacting with things
#func _on_body_entered(body):
	#print(body)
