extends Node

var car = null
var ui = null


func _ready():
	car = get_parent().get_node("car")
	ui = get_parent().get_node("driving_ui")

func _physics_process(delta: float) -> void:
	car.input(ui.throttle, ui.brake, ui.steering)
