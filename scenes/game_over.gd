extends Control

@onready var new_game_button: Button = $NewGameButton
@onready var stats_label: Label = $StatsLabel

func _ready():
	# Connect the button's pressed signal to the _on_start_button_pressed function
	new_game_button.pressed.connect(_on_new_game_button_pressed)

func _on_new_game_button_pressed():
	# Load the main scene when the button is pressed
	get_tree().change_scene_to_file("res://scenes/main.tscn")
