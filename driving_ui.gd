extends Control

const MAX_LENGTH: float = 400.0
const COLOUR_SLOW = Color(0, 0, 0, 0.7)
const COLOUR_FAST = Color(1, 0, 0, 0.3)

var drive_mouse_start = null
var drive_mouse_v = null

var look_mouse_start = null
var look_mouse_v = null

var steering = 0.0
var throttle = 0.0
var brake = 0.0

var look = 0.0

var drive_held = false
var look_held = false


func _ready() -> void:
	$pause_button._toggled(true)

func _draw() -> void:
	if drive_mouse_start != null and drive_mouse_v != null:
		var w = drive_mouse_v.length() / MAX_LENGTH
		var c = COLOUR_SLOW.lerp(COLOUR_FAST, w)
		draw_line(drive_mouse_start, drive_mouse_start + drive_mouse_v, c, 10.0)

func _process(delta: float) -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
	if drive_mouse_v != null:
		var w = drive_mouse_v.length() / MAX_LENGTH
		w *= min(1.0, w / 0.5)
		
		if drive_mouse_v.length() < 5:
			steering = 0.0
		else:
			steering = -1 * (abs(drive_mouse_v.angle()) / (PI / 2) - 1)
			if steering < -1.0:
				steering = -1.0
			elif steering > 1.0:
				steering = 1.0
			steering *= min(drive_mouse_v.length() / (MAX_LENGTH / 3), 1.0)
		
		var reverse_angle = PI / 16
		if drive_mouse_v.angle() > reverse_angle and drive_mouse_v.angle() < PI - reverse_angle:
			throttle = 0.0
			brake = min(w, 1.0)
			steering *= -1
		else:
			throttle = min(w, 1.0)
			brake = 0.0
	if look_mouse_v != null:
		look = look_mouse_v.x / MAX_LENGTH

func _input(event) -> void:
	if event is InputEventMouseMotion:
		if drive_held:
			drive_mouse_v = (event.position - drive_mouse_start).limit_length(MAX_LENGTH)
		elif look_held:
			look_mouse_v = (event.position - look_mouse_start).limit_length(MAX_LENGTH)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed:
				drive_held = false
			elif not drive_held:
				drive_held = true
				drive_mouse_v = Vector2.ZERO
				drive_mouse_start = event.position
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if not event.pressed:
				look_held = false
			elif not look_held:
				look_held = true
				look_mouse_v = Vector2.ZERO
				look_mouse_start = event.position
