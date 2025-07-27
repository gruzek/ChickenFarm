extends Node3D

@onready var left_message_label: Label = $"../UI/LeftMessageLabel"
@onready var right_message_label: Label = $"../UI/RightMessageLabel"

# Tween for smooth animations
var tween: Tween
var wasd_displayed = false

# Message sequence system
var message_sequence: Array = []
var current_message_index: int = 0
var is_playing_sequence: bool = false

# Message structure: {"text": String, "delay_before": float, "show_duration": float, "target": String}
var default_messages = [
	{"text": "Welcome to ChickenFarm!", "delay_before": 3.0, "show_duration": 3.0, "target": "right"},
	{"text": "Use W,A,S,D to move", "delay_before": 1.0, "show_duration": 4.0, "target": "right"},
	{"text": "Make Many Chickens", "delay_before": 0.5, "show_duration": 3.0, "target": "right"},
	{"text": "E for Build Menu", "delay_before": 1.0, "show_duration": 4.0, "target": "right"},
	{"text": "Need Eggs to Build", "delay_before": 1.0, "show_duration": 4.0, "target": "right"},
	{"text": "SPACE to Throw Eggs", "delay_before": 1.0, "show_duration": 4.0, "target": "right"},
	{"text": "Throw Eggs to make Chickens", "delay_before": 1.0, "show_duration": 4.0, "target": "right"},
	{"text": "Need Chickens for Eggs", "delay_before": 1.0, "show_duration": 4.0, "target": "right"},
	{"text": "Watch out for Werewolves", "delay_before": 1.0, "show_duration": 4.0, "target": "right"},
]

func _ready():
	# Create the tween
	tween = create_tween()
	tween.set_parallel(true)  # Allow multiple tweens to run simultaneously
	
	# Start the default message sequence when the game starts
	play_message_sequence()

func display_wasd() -> void:
	"""Legacy function - now handled by message sequence"""
	fade_in(right_message_label, "Use W,A,S,D to move")

func _process(delta) -> void:
	# Process function - currently unused
	pass

func fade_out(duration: float = 1.0, target_label: Label = null) -> void:
	"""Fade out a message label over the specified duration"""
	# If no specific label is provided, fade out both
	if target_label == null:
		fade_out_label(left_message_label, duration)
		fade_out_label(right_message_label, duration)
	else:
		fade_out_label(target_label, duration)

func fade_out_label(label: Label, duration: float) -> void:
	"""Fade out a specific label"""
	if label and label.modulate.a > 0:
		# Create a new tween if the current one is finished
		if not tween or not tween.is_valid():
			tween = create_tween()
			tween.set_parallel(true)
		
		# Tween the alpha (transparency) from current value to 0
		tween.tween_property(label, "modulate:a", 0.0, duration)

func fade_out_left(duration: float = 1.0) -> void:
	"""Convenience function to fade out left message"""
	fade_out(duration, left_message_label)

func fade_out_right(duration: float = 1.0) -> void:
	"""Convenience function to fade out right message"""
	fade_out(duration, right_message_label)

func fade_in(target_label: Label, text: String, duration: float = 0.5) -> void:
	"""Fade in a label with text"""
	if target_label:
		target_label.text = text
		if not tween or not tween.is_valid():
			tween = create_tween()
			tween.set_parallel(true)
		
		tween.tween_property(target_label, "modulate:a", 1.0, duration)

# Message Sequence Functions
func play_message_sequence(messages: Array = []) -> void:
	"""Play a sequence of timed messages"""
	if messages.is_empty():
		messages = default_messages
	
	message_sequence = messages
	current_message_index = 0
	is_playing_sequence = true
	
	# Start the sequence
	play_next_message()

func play_next_message() -> void:
	"""Play the next message in the sequence"""
	if not is_playing_sequence or current_message_index >= message_sequence.size():
		# Sequence finished
		is_playing_sequence = false
		return
	
	var message_data = message_sequence[current_message_index]
	var text = message_data.get("text", "")
	var delay_before = message_data.get("delay_before", 0.0)
	var show_duration = message_data.get("show_duration", 3.0)
	var target = message_data.get("target", "right")
	
	# Wait for the delay before showing this message
	await get_tree().create_timer(delay_before).timeout
	
	# Get the target label
	var target_label = get_target_label(target)
	if target_label:
		# Fade in the message
		fade_in(target_label, text, 0.5)
		
		# Wait for the show duration
		await get_tree().create_timer(show_duration).timeout
		
		# Fade out the message
		fade_out_label(target_label, 0.5)
		
		# Wait for fade out to complete
		await get_tree().create_timer(0.5).timeout
	
	# Move to next message
	current_message_index += 1
	play_next_message()

func get_target_label(target: String) -> Label:
	"""Get the label based on target string"""
	match target.to_lower():
		"left":
			return left_message_label
		"right":
			return right_message_label
		_:
			return right_message_label  # Default to right

func stop_sequence() -> void:
	"""Stop the current message sequence"""
	is_playing_sequence = false
	# Fade out any visible messages
	fade_out(0.3)

func add_message_to_sequence(text: String, delay_before: float = 0.5, show_duration: float = 3.0, target: String = "right") -> void:
	"""Add a single message to the current sequence"""
	var message = {
		"text": text,
		"delay_before": delay_before,
		"show_duration": show_duration,
		"target": target
	}
	message_sequence.append(message)
	
