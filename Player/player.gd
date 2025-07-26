extends CharacterBody3D

# Player Statistics
@export var SPEED = 12.0
@export var ROTATION_SPEED = 10.0  # Speed at which the player rotates to face movement direction
@export var pickup_range = 25
@export var egg_throw_range = 5.0

# egg throwing
@export var throwing_egg_scene: PackedScene
@export var egg_break_partical: PackedScene

@onready var player_rig: Node3D = $player_rig
@onready var build_node: Node3D = $build_node


# Variables for animation
@export var anim_blend_speed = 15
enum {IDLE, RUN}
var currentAnim = IDLE
@onready var animation_tree: AnimationTree = $player_rig/AnimationPlayer/AnimationTree

signal egg_amount_changed(value)

var in_build_mode = false

func _ready():
	# Connect to build_node signals
	build_node.build_mode_entered.connect(_on_build_mode_entered)
	build_node.build_mode_exited.connect(_on_build_mode_exited)

func _process(delta: float) -> void:
	# Pickup logic
	check_for_egg()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# Animation update
	handle_animations(delta)
	
	# Throw Egg
	if Input.is_action_just_pressed("throw_egg"):
		throw_egg()

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

# Throwing eggs
func throw_egg():
	var start_pos = global_position + Vector3.UP * 1.5 # to make it eye or hand hieght
	var forward = -global_transform.basis.z.normalized()
	var distance = egg_throw_range
	var end_pos = start_pos + forward * distance
	
	spawn_and_tween_egg(start_pos, end_pos)


func spawn_and_tween_egg(start_pos: Vector3, end_pos: Vector3):
	# Spawn egg
	var throwing_egg = throwing_egg_scene.instantiate()
	get_tree().current_scene.add_child(throwing_egg)
	throwing_egg.global_position = start_pos
	
	# Tween egg
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var duration = 0.5
	var peak_height = 2.5
	
	tween.tween_method(func(t):
		var flat_lerp = start_pos.lerp(end_pos, t)
		var vertical_arc = sin(t * PI) * peak_height
		throwing_egg.global_position = flat_lerp + Vector3.UP * vertical_arc
	, 0.0, 1.0, duration)
	
	tween.tween_callback(func():
		#await get_tree().create_timer(duration).timeout
		throwing_egg.queue_free()
		var egg_break = egg_break_partical.instantiate()
		add_child(egg_break)
		egg_break.global_position = end_pos
		
		)
	

# Signal handlers for build mode
func _on_build_mode_entered():
	in_build_mode = true
	print("Player: Build mode entered")

func _on_build_mode_exited():
	in_build_mode = false
	print("Player: Build mode exited")

#func _ready():
	#pickup_area.body_entered.connect(_on_body_entered)

## For picking up/interacting with things
#func _on_body_entered(body):
	#print(body)
