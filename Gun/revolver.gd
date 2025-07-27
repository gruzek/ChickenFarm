extends Node3D

@export var bullet_scene: PackedScene
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

@onready var barrel: Node3D = $Barrel

func shoot():
	var shot = bullet_scene.instantiate()
	get_tree().current_scene.add_child(shot)
	shot.global_position = barrel.global_position
	shot.global_position.y = 1 # set the a hieght to be able to hit things
	shot.direction = barrel.global_transform.basis.x
	audio_stream_player_3d.play()
