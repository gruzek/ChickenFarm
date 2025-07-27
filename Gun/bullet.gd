extends Area3D

var direction = Vector3.FORWARD

@export var speed = 55
@export var damage = 5

func _physics_process(delta: float) -> void:
	position += direction * delta * speed

func _on_timer_timeout() -> void:
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		body.health -= damage
		queue_free()
