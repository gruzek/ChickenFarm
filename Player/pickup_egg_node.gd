extends Node3D

@export var pickup_range = 3

@onready var egg_bank = get_tree().get_first_node_in_group("egg bank")
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _process(delta: float) -> void:
	check_for_egg()

func _ready() -> void:
	print(self, ": ", egg_bank)

# Checks if an egg is in pickup range then picks it up
func check_for_egg():
	for egg in get_tree().get_nodes_in_group("egg"):
		if global_transform.origin.distance_to(egg.global_transform.origin) < pickup_range:
			egg.queue_free()
			egg_bank.eggs += 1
			print(audio_stream_player_3d)
			audio_stream_player_3d.play()
