extends Control

# Message queue for credits
var credits_queue: MessageQueue
var tween: Tween
@onready var credits_label: Label = $CanvasLayer/Control/CreditsLabel

# Credits messages that loop
var credits_messages = [
	{"text": "Credits", "delay_before": 0.0, "show_duration": 1.0},
	{"text": "Game Design, Art and Music by Zaplee", "delay_before": 0.0, "show_duration": 2.0},
	{"text": "Coding by Toadz, Kletiz, and Zaplee", "delay_before": 0.0, "show_duration": 2.0}
]

func _ready():
	# Connect the button's pressed signal to the _on_start_button_pressed function
	$CanvasLayer/Control/StartButton.pressed.connect(_on_start_button_pressed)
	
	# Create the tween for credits
	tween = create_tween()
	tween.set_parallel(true)
	
	# Initialize credits message queue
	credits_queue = MessageQueue.new(credits_label, tween)
	
	# Connect to queue finished signal to loop credits
	credits_queue.queue_finished.connect(_on_credits_finished)
	
	# Start the credits loop
	start_credits_loop()

func start_credits_loop():
	"""Start displaying the credits messages"""
	for message in credits_messages:
		var text = message.get("text", "")
		var delay = message.get("delay_before", 0.0)
		var duration = message.get("show_duration", 1.0)
		credits_queue.add_message(text, delay, duration)

func _on_credits_finished():
	"""Called when credits queue finishes - restart the loop"""
	start_credits_loop()

func _on_start_button_pressed():
	# Load the main scene when the button is pressed
	get_tree().change_scene_to_file("res://scenes/main.tscn")
