extends Node3D

@onready var gun: MeshInstance3D = $Gun
@onready var barrel: Node3D = $Barrel

@export var damage = 5
@export var range = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var target = find_best_target(enemies)
	if target:
		look_at(target.global_position, Vector3.UP, true)

func find_best_target(targets: Array[Node]):
	"""Find the closest valid target (chicken or player)"""
	var best_target = null
	var best_distance = 1000
	for target_node in targets:
		# Double-check that target is still valid and alive
		if target_node and is_instance_valid(target_node):
			var distance = global_position.distance_to(target_node.global_transform.origin)
			if distance < best_distance:
				best_target = target_node
				best_distance = distance
	return best_target
