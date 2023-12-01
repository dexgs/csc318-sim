extends Control

var speed: int = 0
const MAX_SPEED: int = 150

func _process(delta: float) -> void:
	$speed_label.text = str(speed)
	var w: float = min(float(speed) / MAX_SPEED, 1.0)
	var a: float = PI * w - PI / 2
	$dial.rotation = a
