extends Area3D

var direction = Vector3.FORWARD

@export var speed = 55
@export var damage = 5

func _physics_process(delta: float) -> void:
	position += direction * delta * speed

func _on_timer_timeout() -> void:
	queue_free()

func _on_area_entered(area: Area3D):
	print(area)
