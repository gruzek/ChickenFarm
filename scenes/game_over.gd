extends Control

@onready var new_game_button: Button = $NewGameButton
@onready var stats_label: Label = $StatsLabel

func _ready():
	# Connect the button's pressed signal to the _on_start_button_pressed function
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	
	# Display death statistics
	var game_stats = get_node("/root/GameStats")
	if game_stats:
		stats_label.text = game_stats.get_death_stats_text()
	else:
		stats_label.text = "0 Chickens and 0 Eggs"

func _on_new_game_button_pressed():
	# Load the main scene when the button is pressed
	get_tree().change_scene_to_file("res://scenes/main.tscn")
