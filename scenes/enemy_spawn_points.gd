extends Node3D

#@onready var top_left: Node3D = $TopLeft
#@onready var top_right: Node3D = $TopRight
#@onready var bottom_right: Node3D = $BottomRight
#@onready var bottom_left: Node3D = $BottomLeft

@onready var bank = get_tree().get_first_node_in_group("egg bank")

@export var chickens_per_wolf = 5
@export var enemy_scene: PackedScene

# Spawns enemies
func spawn_enemies():
	var enemy_count = int(floor(bank.chickens / chickens_per_wolf))
	print("there are ", bank.chickens, " Chickens, so ", enemy_count, " enemies")
	get_children()
	for i in enemy_count:
		var spawn_point = get_children().pick_random()
		var enemy = enemy_scene.instantiate()
		get_tree().current_scene.add_child(enemy)
		enemy.global_position = spawn_point.global_position
