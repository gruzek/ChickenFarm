extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var target_timer: Timer = $"Target Timer"

@export var move_speed = 5
@export var reaction_time = 1

var attacking = false

func _ready() -> void:
	target_timer.wait_time = reaction_time


func _on_target_timer_timeout() -> void:
	var chickens = get_tree().get_nodes_in_group("chicken")
	if chickens.is_empty() || attacking:
		print("EMPTY - RETUREND")
		return
		
	var chosen_target = randi_range(0, chickens.size() - 1)
	if chickens[chosen_target] == null:
		print("NULL - RETUREND")
		return
		
	navigation_agent_3d.target_position = chickens[chosen_target].global_transform.origin

func _physics_process(delta: float) -> void:
	if !navigation_agent_3d.is_navigation_finished():
		# Calculate direction 
		var next_position = navigation_agent_3d.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		velocity = direction * move_speed
		
		# Look the right direction
		var look_target = global_position + Vector3(direction.x, 0, direction.z)
		look_at(look_target)
		
		move_and_slide()
