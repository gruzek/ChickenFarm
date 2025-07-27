extends Node3D
@onready var world_environment: WorldEnvironment = $"../WorldEnvironment"
@onready var sun_light: DirectionalLight3D = $"../sun_light"
@onready var moon_light: DirectionalLight3D = $"../moon_light"

# Signals for day/night events
signal morning_civil_twilight
signal sunrise
signal sunset
signal evening_civil_twilight

# Color exports for different times of day
@export var sunrise_color: Color = Color(0.97, 0.67, 0.51, 1.0)  # Warm orange/pink
@export var daytime_color: Color = Color(0.53, 0.81, 0.98, 1.0)  # Light blue
@export var sunset_color: Color = Color(0.99, 0.59, 0.35, 1.0)   # Orange/red
@export var night_color: Color = Color(0.0, 0.0, 0.0, 1.0)     # Complete black
@export var moonlight_color: Color = Color(0.1, 0.1, 0.2, 1.0)  # Soft blue moonlight

@export var day_time_seconds: int = 120
@export var night_time_seconds: int = 60
@export var sunrise_overlap: int = 30
@export var sunset_overlap: int = 30

# Time tracking variables
var current_time: float = 0.0  # Time in seconds since sunrise
var total_day_cycle: float = 0.0  # Total seconds in a full day/night cycle

# Event time markers
var morning_civil_twilight_time: float = 0.0
var sunrise_time: float = 0.0
var sunset_time: float = 0.0
var evening_civil_twilight_time: float = 0.0

# Event tracking flags to ensure signals are only emitted once per cycle
var morning_civil_twilight_emitted: bool = false
var sunrise_emitted: bool = false
var sunset_emitted: bool = false
var evening_civil_twilight_emitted: bool = false

# Sun position and intensity variables
var initial_sun_rotation: Vector3

func _ready():
	# Add to group so chickens can find this node
	add_to_group("day_night_cycle")
	
	# Calculate total day cycle length
	total_day_cycle = day_time_seconds + night_time_seconds
	
	# Store initial sun rotation
	initial_sun_rotation = sun_light.rotation_degrees
	
	# Calculate event times
	sunrise_time = 0.0  # Start of the cycle
	morning_civil_twilight_time = day_time_seconds + night_time_seconds - sunrise_overlap/2  # Half way through sunrise
	sunset_time = day_time_seconds  # End of day
	evening_civil_twilight_time = day_time_seconds + sunset_overlap/2  # Half way through sunset
	
	# Start with the sun at sunrise position
	update_cycle(0.0)
	
	# Reset all event flags
	reset_event_flags()

# Main update function called every frame
func _process(delta):
	# Update time of day"environment"
	var previous_time = current_time
	current_time = fmod(current_time + delta, total_day_cycle)
	
	# Check if we've looped back to the start of the cycle
	if previous_time > current_time:
		# Reset event flags for the new cycle
		reset_event_flags()
	
	# Check for events and emit signals
	check_and_emit_events()
	
	# Update sun position and environment
	update_cycle(current_time)

# Resets all event flags at the start of a new cycle
func reset_event_flags() -> void:
	morning_civil_twilight_emitted = false
	sunrise_emitted = false
	sunset_emitted = false
	evening_civil_twilight_emitted = false

# Checks if any events should be triggered and emits signals
func check_and_emit_events() -> void:
	# Sunrise event (at the very start of the cycle)
	if current_time >= sunrise_time and not sunrise_emitted:
		emit_signal("sunrise")
		sunrise_emitted = true
		print("Sunrise event at time: ", current_time)
	
	# Morning civil twilight (halfway through sunrise overlap)
	if current_time >= morning_civil_twilight_time and not morning_civil_twilight_emitted:
		emit_signal("morning_civil_twilight")
		morning_civil_twilight_emitted = true
		print("Morning civil twilight event at time: ", current_time)
	
	# Sunset event (at the end of day time)
	if current_time >= sunset_time and not sunset_emitted:
		emit_signal("sunset")
		sunset_emitted = true
		print("Sunset event at time: ", current_time)
	
	# Evening civil twilight (halfway through sunset overlap)
	if current_time >= evening_civil_twilight_time and not evening_civil_twilight_emitted:
		emit_signal("evening_civil_twilight")
		evening_civil_twilight_emitted = true
		print("Evening civil twilight event at time: ", current_time)

# Updates the sun position and light intensity based on time of day
func update_cycle(time: float) -> void:
	# Calculate sun position
	var sun_position = calculate_sun_position(time)
	
	# Calculate sun intensity
	var sun_intensity = calculate_sun_intensity(time)
	
	# Calculate moon intensity
	var moon_intensity = calculate_moon_intensity(time)
	
	# Calculate sky color
	var sky_color = calculate_sky_color(time)
	
	# Apply position
	sun_light.rotation_degrees = sun_position
	
	# Apply intensities
	sun_light.light_energy = sun_intensity
	moon_light.light_energy = moon_intensity
	
	# Apply colors
	moon_light.light_color = moonlight_color
	
	# Apply sky color
	world_environment.environment.background_color = sky_color
	world_environment.environment.ambient_light_color = sky_color

# Calculates moon light intensity based on time of day
func calculate_moon_intensity(time: float) -> float:
	var intensity = 0.0
	
	# Define key time points
	var sunrise_mid = sunrise_overlap/2
	var sunset_mid = day_time_seconds - sunset_overlap/2
	
	# From morning_civil_twilight to sunrise+sunrise_overlap/2: 1 to 0
	if time >= morning_civil_twilight_time or time <= sunrise_mid:
		# Handle cycle wrap-around
		var adjusted_time = time
		if time >= morning_civil_twilight_time:
			adjusted_time = time - total_day_cycle
		
		var transition_duration = sunrise_mid - (morning_civil_twilight_time - total_day_cycle)
		var progress = (adjusted_time - (morning_civil_twilight_time - total_day_cycle)) / transition_duration
		intensity = lerp(1.0, 0.0, progress)
	
	# From sunrise+sunrise_overlap/2 to sunset-sunset_overlap/2: 0
	elif time > sunrise_mid and time < sunset_mid:
		intensity = 0.0
	
	# From sunset-sunset_overlap/2 to evening_civil_twilight: 0 to 1
	elif time >= sunset_mid and time <= evening_civil_twilight_time:
		var transition_duration = evening_civil_twilight_time - sunset_mid
		var progress = (time - sunset_mid) / transition_duration
		intensity = lerp(0.0, 1.0, progress)
	
	# From evening_civil_twilight to morning_civil_twilight: 1
	else:
		intensity = 1.0
	
	return intensity

# Calculates the sun's position based on time of day
func calculate_sun_position(time: float) -> Vector3:
	var position = initial_sun_rotation
	
	# Calculate the full cycle progress (0.0 to 1.0)
	var cycle_progress = time / total_day_cycle
	
	# Y-axis rotation: Full 360-degree rotation
	# -90 (east) at sunrise, 90 (west) at sunset, 270 (east) at end of night
	var y_angle = lerp(-90.0, 270.0, cycle_progress)
	
	# X-axis rotation depends on day/night
	var x_angle = -15.0  # Default to just below horizon
	
	# During daytime, create an arc above horizon
	if time <= day_time_seconds:
		# Calculate daytime progress (0.0 to 1.0)
		var day_progress = time / day_time_seconds
		
		# Create arc that peaks at noon
		var arc_progress = sin(day_progress * PI) # Creates a 0->1->0 arc
		x_angle = lerp(-15.0, -80.0, arc_progress)
		
	# During nighttime, create an arc below horizon
	else:
		# Calculate nighttime progress (0.0 to 1.0)
		var night_progress = (time - day_time_seconds) / night_time_seconds
		
		# Create arc that dips lowest at midnight
		var arc_progress = sin(night_progress * PI) # Creates a 0->1->0 arc
		x_angle = lerp(-15.0, 15.0, arc_progress) # Positive angle means below horizon
	
	# Apply rotations
	position.y = y_angle
	position.x = x_angle
	
	return position

# Calculates sun intensity based on time of day
func calculate_sun_intensity(time: float) -> float:
	var intensity = 0.0
	
	# Define key time points
	var sunrise_mid = sunrise_overlap/2
	var sunset_mid = day_time_seconds - sunset_overlap/2
	
	# From morning_civil_twilight to sunrise+sunrise_overlap/2: 0 to 1
	if time >= morning_civil_twilight_time or time <= sunrise_mid:
		# Handle cycle wrap-around
		var adjusted_time = time
		if time >= morning_civil_twilight_time:
			adjusted_time = time - total_day_cycle
		
		var transition_duration = sunrise_mid - (morning_civil_twilight_time - total_day_cycle)
		var progress = (adjusted_time - (morning_civil_twilight_time - total_day_cycle)) / transition_duration
		intensity = lerp(0.0, 1.0, progress)
	
	# From sunrise+sunrise_overlap/2 to sunset-sunset_overlap/2: 1
	elif time > sunrise_mid and time < sunset_mid:
		intensity = 1.0
	
	# From sunset-sunset_overlap/2 to evening_civil_twilight: 1 to 0
	elif time >= sunset_mid and time <= evening_civil_twilight_time:
		var transition_duration = evening_civil_twilight_time - sunset_mid
		var progress = (time - sunset_mid) / transition_duration
		intensity = lerp(1.0, 0.0, progress)
	
	# From evening_civil_twilight to morning_civil_twilight: 0
	else:
		intensity = 0.0
	
	return intensity

# Calculates sky color based on time of day
func calculate_sky_color(time: float) -> Color:
	var sky_color = night_color
	
	# Define key time points
	var sunrise_mid = sunrise_overlap/2.0
	var sunset_mid = day_time_seconds - sunset_overlap/2.0
	
	# From morning_civil_twilight to sunrise+sunrise_overlap/2: sunrise_color to daytime_color
	if time >= morning_civil_twilight_time or time <= sunrise_mid:
		# Handle cycle wrap-around
		var adjusted_time = time
		if time >= morning_civil_twilight_time:
			adjusted_time = time - total_day_cycle
		
		var transition_duration = sunrise_mid - (morning_civil_twilight_time - total_day_cycle)
		var progress = (adjusted_time - (morning_civil_twilight_time - total_day_cycle)) / transition_duration
		sky_color = sunrise_color.lerp(daytime_color, progress)
	
	# From sunrise+sunrise_overlap/2 to sunset-sunset_overlap/2: daytime_color
	elif time > sunrise_mid and time < sunset_mid:
		sky_color = daytime_color
	
	# From sunset-sunset_overlap/2 to evening_civil_twilight: daytime_color to sunset_color
	elif time >= sunset_mid and time <= evening_civil_twilight_time:
		var transition_duration = evening_civil_twilight_time - sunset_mid
		var progress = (time - sunset_mid) / transition_duration
		sky_color = daytime_color.lerp(sunset_color, progress)
	
	# From evening_civil_twilight to morning_civil_twilight: sunset_color to sunrise_color through night_color
	else:
		# Calculate night progress (0.0 to 1.0)
		var night_duration = morning_civil_twilight_time - evening_civil_twilight_time
		if night_duration < 0:
			night_duration += total_day_cycle
		
		var night_progress = 0.0
		if time > evening_civil_twilight_time:
			night_progress = (time - evening_civil_twilight_time) / night_duration
		else:
			night_progress = (time + total_day_cycle - evening_civil_twilight_time) / night_duration
		
		# Blend between sunset_color and sunrise_color through night_color
		if night_progress < 0.5:
			# First half: sunset_color to night_color
			var first_half_progress = night_progress * 2.0
			sky_color = sunset_color.lerp(night_color, first_half_progress)
		else:
			# Second half: night_color to sunrise_color
			var second_half_progress = (night_progress - 0.5) * 2.0
			sky_color = night_color.lerp(sunrise_color, second_half_progress)
	
	return sky_color
