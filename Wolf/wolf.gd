extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var target_timer: Timer = $"Target Timer"
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var attack_range = 0.7
@export var attack_damage = 2

@export var move_speed = 5
@export var reaction_time = 1

var target: Node

func _ready() -> void:
	target_timer.wait_time = reaction_time


func _on_target_timer_timeout() -> void:
	var chickens = get_tree().get_nodes_in_group("chicken")
	if chickens.is_empty():
		print("EMPTY - RETUREND")
		return
	
	target = find_best_target(chickens)
	if target == null:
		print("NULL - RETUREND")
		return

	navigation_agent_3d.target_position = target.global_transform.origin

func _physics_process(delta: float) -> void:
	if target:
		# Calculate direction 
		var next_position = navigation_agent_3d.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		velocity = direction * move_speed
		
		# Look the right direction
		var look_target = global_position + Vector3(direction.x, 0, direction.z)
		look_at(look_target)
		
		move_and_slide()
		
		var distance = global_position.distance_to(navigation_agent_3d.target_position)
		if distance <= attack_range:
			animation_player.play("attack")

func attack():
	target.health -= attack_damage

func find_best_target(chickens: Array[Node]):
	var best_target = null
	var best_distance = 1000
	for chick in chickens:
		var distance = global_position.distance_to(chick.global_transform.origin)
		if distance < best_distance:
			best_target = chick
			best_distance = distance
	return best_target
