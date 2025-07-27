extends Control

func _ready():
	# Connect the button's pressed signal to the _on_start_button_pressed function
	$CanvasLayer/Control/StartButton.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed():
	# Load the main scene when the button is pressed
	get_tree().change_scene_to_file("res://scenes/main.tscn")
