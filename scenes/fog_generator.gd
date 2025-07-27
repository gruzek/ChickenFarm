extends Node3D

@onready var ground: CSGBox3D = $"../NavigationRegion3D/Ground"

@export var num_clouds: int = 20
@export var cloud_altitude: float = 5
@export var min_cloud_size: float = 5.0
@export var max_cloud_size: float = 30.0
@export var cloud_height: float = 1.0
@export var cloud_direction: Vector3 = Vector3(-0.8, 0, 1).normalized()
@export var cloud_speed: float = 5

# shader properties
@export var initial_noise_scale: float = 0.04
@export var initial_density: float = 0.075
@export var initial_threshold: float = 0.4
@export var initial_speed: float = 0.01
@export var initial_fog_color: Color = Color(1.0,1.0,1.0,0.5)
@export var initial_steps: int = 48

# Fog scene to instantiate
@export var fog_scene: PackedScene = preload("res://scenes/fog.tscn")

# Array to store cloud instances
var clouds: Array[Node3D] = []

# Array to store ground fog instances
var ground_fog: Array[Node3D] = []

# Ground bounds for cloud recycling
var ground_bounds = {
	"min_x": 0.0,
	"max_x": 0.0,
	"min_z": 0.0,
	"max_z": 0.0
}

func _ready():
	"""Generate clouds when the scene starts"""
	generate_clouds()
	
	# Connect to day-night cycle signals if available
	var day_night_cycle = get_node_or_null("../DayNightCycle")
	if day_night_cycle:
		# Sky clouds: disappear at night, reappear at dawn
		if day_night_cycle.has_signal("evening_civil_twilight"):
			day_night_cycle.evening_civil_twilight.connect(_on_night_start)
		if day_night_cycle.has_signal("morning_civil_twilight"):
			day_night_cycle.morning_civil_twilight.connect(_on_morning_start)
		
		# Ground fog: appear at sunset, disappear at sunrise
		if day_night_cycle.has_signal("sunset"):
			day_night_cycle.sunset.connect(_on_sunset_start)
		if day_night_cycle.has_signal("sunrise"):
			day_night_cycle.sunrise.connect(_on_sunrise_start)
		
		print("Connected to day-night cycle signals")
	else:
		print("Day-night cycle not found, clouds will persist")

func generate_clouds():
	"""Generate num_clouds scattered across the scene"""
	if not ground:
		print("Warning: Ground not found, cannot determine cloud spawn area")
		return
	
	# Debug ground information
	print("Ground found: ", ground.name)
	print("Ground global position: ", ground.global_position)
	print("Ground size: ", ground.size)
	
	# Get ground bounds for cloud positioning
	# Use the actual scaled size, not just the mesh size
	var ground_mesh_size = ground.size
	var ground_scale = ground.scale
	var ground_pos = ground.global_position
	
	# Calculate the actual world size by multiplying mesh size by scale
	var actual_size_x = ground_mesh_size.x * ground_scale.x
	var actual_size_z = ground_mesh_size.z * ground_scale.z
	
	print("Ground mesh size: ", ground_mesh_size)
	print("Ground scale: ", ground_scale)
	print("Actual world size: X=", actual_size_x, ", Z=", actual_size_z)
	
	# Calculate spawn area bounds - use the full ground area
	var min_x = ground_pos.x - (actual_size_x / 2.0)
	var max_x = ground_pos.x + (actual_size_x / 2.0)
	var min_z = ground_pos.z - (actual_size_z / 2.0)
	var max_z = ground_pos.z + (actual_size_z / 2.0)
	
	# Store bounds for cloud recycling
	ground_bounds.min_x = min_x
	ground_bounds.max_x = max_x
	ground_bounds.min_z = min_z
	ground_bounds.max_z = max_z
	
	print("Cloud spawn area calculated:")
	print("  X range: ", min_x, " to ", max_x, " (width: ", max_x - min_x, ")")
	print("  Z range: ", min_z, " to ", max_z, " (depth: ", max_z - min_z, ")")
	print("  Y altitude: ", cloud_altitude)
	
	# Verify we have a valid area
	if abs(max_x - min_x) < 1.0 or abs(max_z - min_z) < 1.0:
		print("ERROR: Ground area too small or invalid. Using fallback area.")
		# Fallback to a reasonable default area
		min_x = -50.0
		max_x = 50.0
		min_z = -50.0
		max_z = 50.0
		# Update stored bounds
		ground_bounds.min_x = min_x
		ground_bounds.max_x = max_x
		ground_bounds.min_z = min_z
		ground_bounds.max_z = max_z
	
	print("Generating ", num_clouds, " clouds...")
	for i in range(num_clouds):
		create_cloud(min_x, max_x, min_z, max_z)

func generate_ground_fog():
	"""Generate ground fog (double the number of clouds, stationary, at ground level)"""
	if not ground:
		print("Warning: Ground not found, cannot generate ground fog")
		return
	
	print("Generating ground fog with ", num_clouds * 2, " fog patches...")
	
	# Use stored ground bounds
	var min_x = ground_bounds.min_x
	var max_x = ground_bounds.max_x
	var min_z = ground_bounds.min_z
	var max_z = ground_bounds.max_z
	
	# Generate double the number of fog patches
	for i in range(num_clouds * 1.25):
		create_ground_fog_patch(min_x, max_x, min_z, max_z)

func create_cloud(min_x: float, max_x: float, min_z: float, max_z: float):
	"""Create a single cloud instance with random properties"""
	if not fog_scene:
		print("Error: fog_scene not loaded")
		return
	
	# Instantiate the fog scene
	var cloud = fog_scene.instantiate()
	if not cloud:
		print("Error: Failed to instantiate fog scene")
		return
	
	# Add to scene tree
	add_child(cloud)
	clouds.append(cloud)
	
	# Add cloud to "clouds" group
	cloud.add_to_group("clouds")
	
	# Set random position with explicit bounds checking
	var random_x = randf_range(min_x, max_x)
	var random_z = randf_range(min_z, max_z)
	var cloud_position = Vector3(random_x, cloud_altitude, random_z)
	cloud.global_position = cloud_position
	
	# Set random scale (size)
	var random_scale_x = randf_range(min_cloud_size, max_cloud_size)
	var random_scale_z = randf_range(min_cloud_size, max_cloud_size)
	var cloud_scale = Vector3(random_scale_x, cloud_height, random_scale_z)
	cloud.scale = cloud_scale
	
	# Debug output for first few clouds
	if clouds.size() <= 3:
		print("Cloud ", clouds.size(), " created:")
		print("  Position: ", cloud_position)
		print("  Scale: ", cloud_scale)
		print("  Bounds used: X(", min_x, " to ", max_x, "), Z(", min_z, " to ", max_z, ")")
	
	# Set up cloud movement
	setup_cloud_movement(cloud)
	
	# Configure cloud shader properties if the cloud has them
	configure_cloud_shader(cloud)

func create_ground_fog_patch(min_x: float, max_x: float, min_z: float, max_z: float):
	"""Create a single ground fog patch with specific properties"""
	if not fog_scene:
		print("Error: fog_scene not loaded")
		return
	
	# Instantiate the fog scene
	var fog_patch = fog_scene.instantiate()
	if not fog_patch:
		print("Error: Failed to instantiate fog scene for ground fog")
		return
	
	# Add to scene tree
	add_child(fog_patch)
	ground_fog.append(fog_patch)
	
	# Add to "ground_fog" group
	fog_patch.add_to_group("ground_fog")
	
	# Set random position at ground level (Y = 0.0)
	var random_x = randf_range(min_x, max_x)
	var random_z = randf_range(min_z, max_z)
	var fog_position = Vector3(random_x, 0.0, random_z)  # Ground level
	fog_patch.global_position = fog_position
	
	# Set random scale using cloud parameters with fixed Y height of 5
	var random_scale_x = randf_range(min_cloud_size, max_cloud_size)
	var random_scale_z = randf_range(min_cloud_size, max_cloud_size)
	var fog_scale = Vector3(random_scale_x, 5.0, random_scale_z)  # Y height = 5
	fog_patch.scale = fog_scale
	
	# Ground fog does not move - no velocity metadata
	
	# Debug output for first few fog patches
	if ground_fog.size() <= 3:
		print("Ground fog ", ground_fog.size(), " created:")
		print("  Position: ", fog_position)
		print("  Scale: ", fog_scale)
	
	# Configure fog shader properties with black color
	configure_ground_fog_shader(fog_patch)

func setup_cloud_movement(cloud: Node3D):
	"""Set up cloud movement with the specified direction and speed"""
	# Create a simple movement script for the cloud
	var velocity = cloud_direction * cloud_speed
	
	# Store velocity in the cloud's metadata for movement in _process
	cloud.set_meta("velocity", velocity)

func configure_cloud_shader(cloud: Node3D):
	"""Configure shader properties using the fog.gd script methods"""
	# The cloud should be an instance of fog.tscn which has fog.gd script
	# Use the fog script's setter methods to configure the shader
	if cloud.has_method("_set_noise_scale"):
		print("Configuring cloud shader properties using fog.gd methods")
		# Use the fog script's setter methods
		cloud._set_noise_scale(initial_noise_scale)
		cloud._set_density(initial_density)
		cloud._set_threshold(initial_threshold)
		cloud._set_speed(initial_speed)
		cloud._set_fog_color(initial_fog_color)
		cloud._set_steps(initial_steps)
	else:
		# Fallback: set the exported variables directly
		print("Using direct property assignment for cloud shader")
		if "noise_scale" in cloud:
			cloud.noise_scale = initial_noise_scale
		if "density" in cloud:
			cloud.density = initial_density
		if "threshold" in cloud:
			cloud.threshold = initial_threshold
		if "speed" in cloud:
			cloud.speed = initial_speed
		if "fog_color" in cloud:
			cloud.fog_color = initial_fog_color
		if "steps" in cloud:
			cloud.steps = initial_steps

func configure_ground_fog_shader(fog_patch: Node3D):
	"""Configure shader properties for ground fog using black color"""
	# Create black color with same alpha as the original fog color
	var black_fog_color = Color(0.0, 0.0, 0.0, initial_fog_color.a/2.0)
	
	# Use the fog script's setter methods with cloud parameters but black color
	if fog_patch.has_method("_set_noise_scale"):
		print("Configuring ground fog shader properties (black color)")
		# Use the same parameters as clouds
		fog_patch._set_noise_scale(initial_noise_scale)
		fog_patch._set_density(initial_density)
		fog_patch._set_threshold(initial_threshold)
		fog_patch._set_speed(initial_speed)
		fog_patch._set_fog_color(black_fog_color)  # Black color
		fog_patch._set_steps(initial_steps)
	else:
		# Fallback: set the exported variables directly
		print("Using direct property assignment for ground fog shader (black color)")
		if "noise_scale" in fog_patch:
			fog_patch.noise_scale = initial_noise_scale
		if "density" in fog_patch:
			fog_patch.density = initial_density
		if "threshold" in fog_patch:
			fog_patch.threshold = initial_threshold
		if "speed" in fog_patch:
			fog_patch.speed = initial_speed
		if "fog_color" in fog_patch:
			fog_patch.fog_color = black_fog_color  # Black color
		if "steps" in fog_patch:
			fog_patch.steps = initial_steps

func _process(delta: float):
	"""Update cloud positions each frame and handle recycling"""
	for i in range(clouds.size() - 1, -1, -1):  # Iterate backwards to safely remove items
		var cloud = clouds[i]
		if not cloud or not is_instance_valid(cloud):
			# Remove invalid clouds
			clouds.remove_at(i)
			continue
		
		if cloud.has_meta("velocity"):
			var velocity = cloud.get_meta("velocity") as Vector3
			cloud.global_position += velocity * delta
			
			# Check if cloud has moved outside the ground area
			var pos = cloud.global_position
			if is_cloud_outside_bounds(pos):
				# Recycle the cloud by moving it to the opposite side
				recycle_cloud(cloud, velocity)

func is_cloud_outside_bounds(pos: Vector3) -> bool:
	"""Check if a cloud position is outside the ground bounds"""
	# Add some buffer to prevent clouds from disappearing too early
	var buffer = max(max_cloud_size, 10.0)
	return (pos.x < ground_bounds.min_x - buffer or 
			pos.x > ground_bounds.max_x + buffer or 
			pos.z < ground_bounds.min_z - buffer or 
			pos.z > ground_bounds.max_z + buffer)

func recycle_cloud(cloud: Node3D, velocity: Vector3):
	"""Move a cloud to the opposite side of the ground area"""
	var pos = cloud.global_position
	var new_pos = pos
	
	# Determine which edge the cloud crossed and place it on the opposite side
	if pos.x < ground_bounds.min_x:
		# Crossed left edge, place on right edge
		new_pos.x = ground_bounds.max_x + max_cloud_size
	elif pos.x > ground_bounds.max_x:
		# Crossed right edge, place on left edge
		new_pos.x = ground_bounds.min_x - max_cloud_size
	
	if pos.z < ground_bounds.min_z:
		# Crossed front edge, place on back edge
		new_pos.z = ground_bounds.max_z + max_cloud_size
	elif pos.z > ground_bounds.max_z:
		# Crossed back edge, place on front edge
		new_pos.z = ground_bounds.min_z - max_cloud_size
	
	# Randomize the other coordinate to add variety
	if abs(velocity.x) > abs(velocity.z):
		# Moving primarily in X direction, randomize Z
		new_pos.z = randf_range(ground_bounds.min_z, ground_bounds.max_z)
	else:
		# Moving primarily in Z direction, randomize X
		new_pos.x = randf_range(ground_bounds.min_x, ground_bounds.max_x)
	
	cloud.global_position = new_pos

func destroy_all_clouds():
	"""Remove all clouds from the scene"""
	print("Destroying all clouds for night time")
	for cloud in clouds:
		if cloud and is_instance_valid(cloud):
			cloud.queue_free()
	clouds.clear()

func destroy_all_ground_fog():
	"""Remove all ground fog from the scene"""
	print("Destroying all ground fog for day time")
	for fog_patch in ground_fog:
		if fog_patch and is_instance_valid(fog_patch):
			fog_patch.queue_free()
	ground_fog.clear()

func _on_night_start():
	"""Called when evening civil twilight begins (night starts)"""
	print("Night started - destroying clouds")
	destroy_all_clouds()

func _on_morning_start():
	"""Called when morning civil twilight begins (dawn starts)"""
	print("Morning started - spawning new clouds")
	# Small delay to ensure any remaining clouds are cleaned up
	await get_tree().process_frame
	generate_clouds()

func _on_sunset_start():
	"""Called when sunset begins - spawn ground fog"""
	print("Sunset started - spawning ground fog")
	generate_ground_fog()

func _on_sunrise_start():
	"""Called when sunrise begins - remove ground fog"""
	print("Sunrise started - removing ground fog")
	destroy_all_ground_fog()
