extends CharacterBody3D

@onready var player_rig: Node3D = $player_rig

const SPEED = 12.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 10.0  # Speed at which the player rotates to face movement direction

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

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
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

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
