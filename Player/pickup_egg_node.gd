extends Node3D

signal pickup_egg

@export var pickup_range = 3

func _process(delta: float) -> void:
	check_for_egg()

# Checks if an egg is in pickup range then picks it up
func check_for_egg():
	for egg in get_tree().get_nodes_in_group("egg"):
		if global_transform.origin.distance_to(egg.global_transform.origin) < pickup_range:
			egg.queue_free()
			pickup_egg.emit()
