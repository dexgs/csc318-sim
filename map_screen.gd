extends Control

var car_start = Vector2(-22, 625)
var marker_start = Vector2(30, 530)
var s = 0.27

var speed: float = 0
var speed_limit = 50

var stop = false


func update_position(pos: Vector3) -> void:
	var pos_2d = Vector2(pos.x, pos.z)
	pos_2d -= car_start
	$marker.set_position(marker_start + pos_2d * -s)

func _physics_process(delta: float) -> void:
	var diff = speed - speed_limit
	var abs_diff = abs(diff)
	
	if abs_diff < 5 or int(speed) < 5:
		yellow_border_off()
	else:
		yellow_border_on()
	
	if stop:
		$red_screen/slow_down.visible = false
		$red_screen/stop.visible = true
		if int(speed) == 0:
			stop = false
		else:
			red_screen_on()
	else:
		if diff > 10:
			$red_screen/slow_down.visible = true
			$red_screen/stop.visible = false
			red_screen_on()
		else:
			red_screen_off()

func _ready() -> void:
	$red_screen_fade.set_current_animation("red_screen_fade")
	$red_screen_fade.pause()
	$yellow_border_fade.set_current_animation("yellow_border_fade")
	$yellow_border_fade.pause()

func yellow_border_on() -> void:
	if $yellow_border_fade.current_animation_position > 0.0:
		$yellow_border_fade.play_backwards("yellow_border_fade")

func yellow_border_off() -> void:
	if $yellow_border_fade.current_animation_position < 0.5:
		$yellow_border_fade.play("yellow_border_fade")

func red_screen_on() -> void:
	if $red_screen_fade.current_animation_position > 0.0:
		$red_screen_fade.play_backwards("red_screen_fade")

func red_screen_off() -> void:
	if $red_screen_fade.current_animation_position < 0.5:
		$red_screen_fade.play("red_screen_fade")
