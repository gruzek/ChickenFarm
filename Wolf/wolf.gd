extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var target_timer: Timer = $"Target Timer"
#@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $werewolf/AnimationPlayer/AnimationTree
@onready var wolf_collider: CollisionShape3D = $CollisionShape3D
@onready var attack_cooldown_timer: Timer = $"Attack Timer"


@export var attack_range = 2.0
@export var attack_damage = 5
@export var move_speed = 10
@export var reaction_time = 1.0
@export var attack_duration = 2.0  # How long the attack animation takes
@export var attack_cooldown = 1.0
@export var starting_health = 20

var can_attack = true

var health: int:
	set(health_in):
		health = health_in
		if health <=0:
			die()

# Targeting variables
var target: Node
var is_attacking = false
var attack_timer = 0.0

# Variables for animation
@export var anim_blend_speed = 15
enum {RUN, ATTACK, IDLE}
var currentAnim = RUN
var death_anim_play = false
@onready var death_timer: Timer = $"Death Timer"
@export var death_despawn_time = 3


var is_dead = false

func _ready() -> void:
	target_timer.wait_time = reaction_time
	add_to_group("wolf")
	health = starting_health
	attack_cooldown_timer.wait_time = attack_cooldown


func _on_target_timer_timeout() -> void:
	# Check if dead
	if is_dead:
		return
	# Get all potential targets (chickens and player)
	var chickens = get_tree().get_nodes_in_group("chicken")
	var players = get_tree().get_nodes_in_group("player")
	
	# Filter out freed/invalid/dead targets
	var valid_targets: Array[Node] = []
	
	# Add valid chickens
	for chicken in chickens:
		if chicken and is_instance_valid(chicken) and not chicken.is_dead:
			valid_targets.append(chicken)
	
	# Add valid players
	for player in players:
		if player and is_instance_valid(player) and not player.is_dead:
			valid_targets.append(player)
	
	if valid_targets.is_empty():
		target = null
		return
	
	target = find_best_target(valid_targets)
	if target == null:
		return

	navigation_agent_3d.target_position = target.global_transform.origin

func _physics_process(delta: float) -> void:
	# Check if dead
	if is_dead:
		return
	# Animation update
	handle_animations(delta)
	
	if is_attacking:
		# Check if target died during attack
		if not target or not is_instance_valid(target) or target.is_dead:
			# Target died, immediately stop attacking and find new target
			is_attacking = false
			attack_timer = 0.0
			find_new_target_immediately()
			return
		
		# Handle attack sequence
		attack_timer += delta
		if attack_timer >= attack_duration:
			# Attack finished
			finish_attack()
		return
	
	if target:
		# Check if target is still valid and alive
		if not is_instance_valid(target) or target.is_dead:
			finish_attack()  # Clean up if target was destroyed or died
			find_new_target_immediately()
			return
		
		# Continuously update target position (follow the chicken)
		navigation_agent_3d.target_position = target.global_position
		
		# Check if we're close enough to attack
		var distance_to_target = global_position.distance_to(target.global_position)
		if distance_to_target <= attack_range && can_attack:
			start_attack()
			return
		
		# Move toward target
		var next_position = navigation_agent_3d.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		velocity = direction * move_speed
		
		# Look the right direction
		var look_target = global_position + Vector3(direction.x, 0, direction.z)
		look_at(look_target)
		
		move_and_slide()

func start_attack():
	"""Begin attacking the current target"""
	if not target or not is_instance_valid(target):
		return
	
	is_attacking = true
	attack_timer = 0.0
	
	# Stop moving
	#velocity = Vector3.ZERO
	
	# Tell the chicken it's being attacked (stops its movement)
	if target.has_method("start_being_attacked"):
		target.start_being_attacked()
	
	# Play attack animation
	attack()
	currentAnim = ATTACK
	can_attack = false
	#animation_player.play("attack")

func attack():
	# Check if target is still valid before dealing damage
	if target and is_instance_valid(target):
		target.health -= attack_damage
	can_attack = false

func finish_attack():
	"""Clean up after attack is finished"""
	is_attacking = false
	attack_timer = 0.0
	
	# Tell the chicken it's no longer being attacked
	if target and is_instance_valid(target) and target.has_method("stop_being_attacked"):
		target.stop_being_attacked()
	
	# Check if target is dead and find new target
	if not target or not is_instance_valid(target) or target.is_dead:
		find_new_target_immediately()
	
	attack_cooldown_timer.start()
	currentAnim = IDLE

# Controls Animations
func handle_animations(delta):
	match currentAnim:
		IDLE:
			# Changes the blend amount in the animation tree depending on the players state
			animation_tree["parameters/Attack/blend_amount"] = lerpf(animation_tree["parameters/Attack/blend_amount"], 0, anim_blend_speed * delta)
		ATTACK:
			animation_tree["parameters/Attack/blend_amount"] = lerpf(animation_tree["parameters/Attack/blend_amount"], 1, anim_blend_speed * delta)
			animation_tree["parameters/Run/blend_amount"] = lerpf(animation_tree["parameters/Run/blend_amount"], 0, anim_blend_speed * delta)
	# there's a target, run at them
	if target: 
		animation_tree["parameters/Run/blend_amount"] = lerpf(animation_tree["parameters/Run/blend_amount"], 1, anim_blend_speed * delta)
	else:
		animation_tree["parameters/Run/blend_amount"] = lerpf(animation_tree["parameters/Run/blend_amount"], 0, anim_blend_speed * delta)
	


func find_new_target():
	"""Find a new target after current one dies or becomes invalid"""
	target = null
	# The timer will handle finding the next target

func find_new_target_immediately():
	"""Immediately find a new target without waiting for timer"""
	target = null
	
	# Get all potential targets (chickens and player)
	var chickens = get_tree().get_nodes_in_group("chicken")
	var players = get_tree().get_nodes_in_group("player")
	
	# Filter out freed/invalid/dead targets
	var valid_targets: Array[Node] = []
	
	# Add valid chickens
	for chicken in chickens:
		if chicken and is_instance_valid(chicken) and not chicken.is_dead:
			valid_targets.append(chicken)
	
	# Add valid players
	for player in players:
		if player and is_instance_valid(player) and not player.is_dead:
			valid_targets.append(player)
	
	if not valid_targets.is_empty():
		target = find_best_target(valid_targets)
		if target:
			navigation_agent_3d.target_position = target.global_position

func find_best_target(targets: Array[Node]):
	"""Find the closest valid target (chicken or player)"""
	var best_target = null
	var best_distance = 1000
	for target_node in targets:
		# Double-check that target is still valid and alive
		if target_node and is_instance_valid(target_node) and not target_node.is_dead:
			var distance = global_position.distance_to(target_node.global_transform.origin)
			if distance < best_distance:
				best_target = target_node
				best_distance = distance
	return best_target

func die():
	is_dead = true
	death_timer.wait_time = death_despawn_time
	death_timer.start()
	animation_tree["parameters/Die/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	wolf_collider.queue_free()
	# Do spark particles

func _on_death_timer_timeout() -> void:
	queue_free()


func _on_attack_timer_timeout() -> void:
	can_attack = true
