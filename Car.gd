extends CharacterBody2D

var rpm_climb: float = 50.0
var rpm_decay: float = 40.0
var rolling_decay: float = 10.0
var slide_decay: float = 30.0
var brake_power: float = 1000.0

var rpm: float = 0.0
var direction: Vector2 = Vector2.UP

const EPSILON: float = 0.0001

func power(rpm: float) -> float:
	return rpm * 10

func drive(throttle: float, brake: float, steering: float, delta: float) -> void:
	assert(0 <= throttle and throttle <= 1)
	assert(0 <= brake and brake <= 1)
	assert(-1 <= steering and steering <= 1)
	
	var adj_direction = direction
	
	# handle reversing """convincingly"""
	if direction.dot(velocity) < 0.0:
		steering *= -1
		adj_direction *= -1
	
	if throttle > 0.0 and brake == 0.0:
		rpm += throttle * rpm_climb * delta
	else:
		rpm -= rpm_decay * delta
		rpm = max(rpm, 0.0)
	
	# Smooth coefficient between [0.0, 1.0] based on vehicle speed
	# https://www.desmos.com/calculator/t0yij5aqal
	var c = 0.5 * (1 - cos(0.4 * min(velocity.length() / 40, 2.5 * PI)))
	print(c)
	assert(0 <= c and c <= 1)
	
	var wheel_vel = power(rpm) * adj_direction.rotated(steering * c)
	
	var dot = abs(wheel_vel.normalized().dot(velocity.normalized()))
	if wheel_vel.length_squared() < EPSILON:
		dot = 1.0
	
	velocity += (wheel_vel - velocity) * delta
	
	var rotate_amount = (adj_direction.angle_to(velocity) + steering) * dot * c * delta
	direction = direction.rotated(rotate_amount)
	rotate(rotate_amount)
	
	var friction = \
		adj_direction * dot * (rolling_decay + brake * brake_power) \
		+ (velocity - velocity.project(adj_direction)).normalized() * (1.0 - dot) * slide_decay
	
	if velocity.length_squared() > EPSILON:
		velocity -= friction.normalized() * min(velocity.length(), friction.length() * c * delta)
	else:
		rpm = 0.0
	
	velocity = velocity.rotated(velocity.angle_to(adj_direction) * c * delta)

func _physics_process(delta: float) -> void:
	var steering = 0.0
	if Input.is_action_pressed('ui_left'):
		steering = -1.0
	elif Input.is_action_pressed('ui_right'):
		steering = 1.0
	
	var throttle = 0.0
	if Input.is_action_pressed('ui_up'):
		throttle = 1.0
	
	var brake = 0.0
	if Input.is_action_pressed('ui_down'):
		brake = 1.0
	
	drive(throttle, brake, steering, delta)
	move_and_slide()
