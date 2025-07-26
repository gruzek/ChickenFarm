extends Node3D

@export var egg_break_partical: PackedScene
@export var chicken_scene: PackedScene

@export var chicken_chance = 50

func explode():
	var egg_break = egg_break_partical.instantiate()
	get_tree().current_scene.add_child(egg_break)
	egg_break.global_position = position
	spawn_chicken()
	queue_free()

func spawn_chicken():
	var num = randf_range(0, 100)
	print(num)
	if num < chicken_chance:
		var chicken = chicken_scene.instantiate()
		get_tree().current_scene.add_child(chicken)
		chicken.global_position = position
