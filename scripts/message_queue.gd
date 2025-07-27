class_name MessageQueue
extends RefCounted

# Queue of messages to display
var messages: Array = []
var is_playing: bool = false
var current_message_index: int = 0

# Reference to the label this queue controls
var target_label: Label
var tween: Tween

# Signals for queue events
signal queue_finished
signal message_started(message_data: Dictionary)
signal message_finished(message_data: Dictionary)

func _init(label: Label, tween_ref: Tween):
	target_label = label
	tween = tween_ref

func add_message(text: String, delay_before: float = 0.5, show_duration: float = 3.0) -> void:
	"""Add a message to the end of the queue"""
	var message = {
		"text": text,
		"delay_before": delay_before,
		"show_duration": show_duration
	}
	messages.append(message)
	
	# Start playing if not already playing
	if not is_playing:
		play_next_message()

func interrupt_queue(text: String, delay_before: float = 0.0, show_duration: float = 3.0) -> void:
	"""Insert a message at the front of the queue (plays next)"""
	var message = {
		"text": text,
		"delay_before": delay_before,
		"show_duration": show_duration
	}
	
	if is_playing:
		# Insert after current message
		messages.insert(current_message_index + 1, message)
	else:
		# Insert at the beginning
		messages.insert(0, message)
		play_next_message()

func clear_queue() -> void:
	"""Clear all messages from the queue and stop playing"""
	messages.clear()
	current_message_index = 0
	is_playing = false
	
	# Fade out current message if any
	if target_label and target_label.modulate.a > 0:
		fade_out_label(0.3)

func get_queue_size() -> int:
	"""Get the number of messages remaining in the queue"""
	return messages.size() - current_message_index

func is_queue_empty() -> bool:
	"""Check if the queue is empty"""
	return messages.is_empty() or current_message_index >= messages.size()

func play_next_message() -> void:
	"""Play the next message in the queue"""
	if is_queue_empty():
		# Queue finished
		is_playing = false
		current_message_index = 0
		queue_finished.emit()
		return
	
	is_playing = true
	var message_data = messages[current_message_index]
	var text = message_data.get("text", "")
	var delay_before = message_data.get("delay_before", 0.0)
	var show_duration = message_data.get("show_duration", 3.0)
	
	message_started.emit(message_data)
	
	# Wait for the delay before showing this message
	await Engine.get_main_loop().create_timer(delay_before).timeout
	
	# Fade in the message
	fade_in_label(text, 0.5)
	
	# Wait for the show duration
	await Engine.get_main_loop().create_timer(show_duration).timeout
	
	# Fade out the message
	fade_out_label(0.5)
	
	# Wait for fade out to complete
	await Engine.get_main_loop().create_timer(0.5).timeout
	
	message_finished.emit(message_data)
	
	# Move to next message
	current_message_index += 1
	play_next_message()

func fade_in_label(text: String, duration: float) -> void:
	"""Fade in the label with text"""
	if target_label:
		target_label.text = text
		if not tween or not tween.is_valid():
			tween = target_label.create_tween()
			tween.set_parallel(true)
		
		tween.tween_property(target_label, "modulate:a", 1.0, duration)

func fade_out_label(duration: float) -> void:
	"""Fade out the label"""
	if target_label and target_label.modulate.a > 0:
		if not tween or not tween.is_valid():
			tween = target_label.create_tween()
			tween.set_parallel(true)
		
		tween.tween_property(target_label, "modulate:a", 0.0, duration)
