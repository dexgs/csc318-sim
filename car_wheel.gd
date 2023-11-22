extends Node3D

var angle: float = 0.0
var speed: float = 0.0


func _physics_process(delta: float) -> void:
	var r = get_rotation()
	set_rotation(Vector3(r.x + speed * delta, angle, 0))
