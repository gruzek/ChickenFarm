extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var move_timer: Timer = $move_timer

@export var move_speed = 5
@export var reaction_time = 1

func _ready() -> void:
	move_timer.wait_time = reaction_time
	


func _on_move_timer_timeout() -> void:
	var eggs = get_tree().get_nodes_in_group("egg")
	var chosen_egg = randi_range(0, eggs.size())
	navigation_agent_3d.target_position = eggs[chosen_egg].global_transform.origin
	if eggs == null:
		pass
