extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var move_timer: Timer = $move_timer

@export var move_speed = 5
@export var reaction_time = 1

var getting_egg = false

var is_active=false

func set_is_active( value ) -> void:
	is_active = value
	
func _ready() -> void:
	move_timer.wait_time = reaction_time

func _on_move_timer_timeout() -> void:
	if is_active:
		var eggs = get_tree().get_nodes_in_group("egg")
		if eggs.is_empty() || getting_egg:
			return
		
		var chosen_egg = randi_range(0, eggs.size() - 1)
		if eggs[chosen_egg] == null:
			return
		
		navigation_agent_3d.target_position = eggs[chosen_egg].global_transform.origin
		getting_egg = true

func _physics_process(delta: float) -> void:
	if is_active:
		if !navigation_agent_3d.is_navigation_finished():
			# Calculate direction 
			var next_position = navigation_agent_3d.get_next_path_position()
			var direction = (next_position - global_position).normalized()
			velocity = direction * move_speed
		
			# Look the right direction
			var look_target = global_position + Vector3(direction.x, 0, direction.z)
			look_at(look_target)
		
			move_and_slide()
		else:
			getting_egg = false
