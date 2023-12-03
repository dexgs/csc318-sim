extends Node

var camera = null
var car = null
var ui = null


func _ready():
	car = get_parent().get_node("car")
	camera = car.get_node("car_cam")
	ui = get_parent().get_node("driving_ui")

func _physics_process(delta: float) -> void:
	if car.is_player:
		car.input(ui.throttle, ui.brake, ui.steering)
	var r = camera.get_rotation()
	camera.set_rotation(Vector3(r.x, lerp(r.y, -PI - ui.look, 5 * delta), r.z))
