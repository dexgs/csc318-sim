extends Control

const MAX_LENGTH: float = 400.0
const COLOUR_SLOW = Color(0, 0, 0, 0.7)
const COLOUR_FAST = Color(1, 0, 0, 0.3)

var mouse_start = null
var mouse_v = null

var steering = 0.0
var throttle = 0.0
var brake = 0.0

var held = false

func _draw() -> void:
	if mouse_start != null and mouse_v != null:
		var w = mouse_v.length() / MAX_LENGTH
		var c = COLOUR_SLOW.lerp(COLOUR_FAST, w)
		draw_line(mouse_start, mouse_start + mouse_v, c, 10.0)

func _process(delta: float) -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
	if mouse_v == null:
		return
	
	var w = mouse_v.length() / MAX_LENGTH
	w *= min(1.0, w / 0.5)
	
	if mouse_v.length() < 5:
		steering = 0.0
	else:
		steering = -1 * (abs(mouse_v.angle()) / (PI / 2) - 1)
		if steering < -1.0:
			steering = -1.0
		elif steering > 1.0:
			steering = 1.0
		steering *= min(mouse_v.length() / (MAX_LENGTH / 3), 1.0)
	
	var reverse_angle = PI / 16
	if mouse_v.angle() > reverse_angle and mouse_v.angle() < PI - reverse_angle:
		throttle = 0.0
		brake = min(w, 1.0)
		steering *= -1
	else:
		throttle = min(w, 1.0)
		brake = 0.0

func _input(event) -> void:
	if event is InputEventMouseMotion and held:
		mouse_v = (event.position - mouse_start).limit_length(MAX_LENGTH)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			held = false
		elif not held:
			held = true
			mouse_v = Vector2.ZERO
			mouse_start = event.position
