extends Node3D

@onready var left_message_label: Label = $"../UI/LeftMessageLabel"
@onready var right_message_label: Label = $"../UI/RightMessageLabel"

# Message queues for each side
var left_queue: MessageQueue
var right_queue: MessageQueue

# Tween for animations
var tween: Tween

# Default startup messages
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
	tween.set_parallel(true)
	
	# Initialize message queues
	left_queue = MessageQueue.new(left_message_label, tween)
	right_queue = MessageQueue.new(right_message_label, tween)
	
	# Add default startup messages to the appropriate queues
	for message in default_messages:
		var target = message.get("target", "right")
		var text = message.get("text", "")
		var delay = message.get("delay_before", 0.5)
		var duration = message.get("show_duration", 3.0)
		
		if target == "left":
			left_queue.add_message(text, delay, duration)
		else:
			right_queue.add_message(text, delay, duration)

# Queue-based Message API
func add_left_message(text: String, delay_before: float = 0.5, show_duration: float = 3.0) -> void:
	"""Add a message to the left queue"""
	left_queue.add_message(text, delay_before, show_duration)

func add_right_message(text: String, delay_before: float = 0.5, show_duration: float = 3.0) -> void:
	"""Add a message to the right queue"""
	right_queue.add_message(text, delay_before, show_duration)

func interrupt_left_queue(text: String, delay_before: float = 0.0, show_duration: float = 3.0) -> void:
	"""Interrupt the left queue with an urgent message"""
	left_queue.interrupt_queue(text, delay_before, show_duration)

func interrupt_right_queue(text: String, delay_before: float = 0.0, show_duration: float = 3.0) -> void:
	"""Interrupt the right queue with an urgent message"""
	right_queue.interrupt_queue(text, delay_before, show_duration)

func clear_left_queue() -> void:
	"""Clear all messages from the left queue"""
	left_queue.clear_queue()

func clear_right_queue() -> void:
	"""Clear all messages from the right queue"""
	right_queue.clear_queue()

func clear_all_queues() -> void:
	"""Clear all messages from both queues"""
	left_queue.clear_queue()
	right_queue.clear_queue()

func get_left_queue_size() -> int:
	"""Get the number of messages remaining in the left queue"""
	return left_queue.get_queue_size()

func get_right_queue_size() -> int:
	"""Get the number of messages remaining in the right queue"""
	return right_queue.get_queue_size()

func is_left_queue_empty() -> bool:
	"""Check if the left queue is empty"""
	return left_queue.is_queue_empty()

func is_right_queue_empty() -> bool:
	"""Check if the right queue is empty"""
	return right_queue.is_queue_empty()

# Legacy functions for backward compatibility
func display_wasd() -> void:
	"""Legacy function - use add_right_message instead"""
	add_right_message("Use W,A,S,D to move", 0.0, 4.0)

func _process(delta) -> void:
	# Process function - currently unused
	pass

# Signal handlers (can be used to trigger messages based on game events)
func _on_day_night_cycle_evening_civil_twilight() -> void:
	# Example: Show a nighttime warning message
	interrupt_right_queue("Beware of Werewolves", 0.0, 4.0)

func _on_day_night_cycle_morning_civil_twilight() -> void:
	# Example: Show a morning message
	add_right_message("Good Morning Sunshine", 0.0, 4.0)

func _on_player_build_mode_entered() -> void:
	interrupt_left_queue("Build Mode: Right Click to Cancel", 0.0, 3.0)
	interrupt_left_queue("Build Mode: Left Click to Place", 0.0, 3.0)
	interrupt_left_queue("Build Mode: Use Q or Mouse Wheel to change building", 0.0, 3.0)


func _on_player_build_mode_exited() -> void:
	pass # Replace with function body.
