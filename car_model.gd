extends CharacterBody3D

var rpm_climb: float = 0.7
var rpm_decay: float = 0.4
var rolling_decay: float = 10.0
var slide_decay: float = 0.5
var brake_power: float = 30.0
var steering_c: float = 5.0

var rpm: float = 0.0
var last_steering: float = 0.0
var direction: Vector2 = Vector2.DOWN
var last_vel: Vector2 = Vector2.ZERO
var accel: Vector2 = Vector2.ZERO

const EPSILON: float = 0.0001
const UP: Vector3 = Vector3(0, 1, 0)

const FORWARD: Vector3 = Vector3(0, 0, 1)

var wheels = []

func _ready() -> void:
	wheels = [$front_l, $front_r, $rear_l, $rear_r]

func power(rpm: float) -> float:
	return rpm * 10

func drive(throttle: float, brake: float, steering: float, delta: float) -> void:
	assert(0 <= throttle and throttle <= 1)
	assert(0 <= brake and brake <= 1)
	assert(-1 <= steering and steering <= 1)
	
	var steering_weight = delta * 2
	steering = steering * steering_weight + last_steering * (1 - steering_weight)
	last_steering = steering
	
	$front_l.angle = -steering * 0.5
	$front_r.angle = -steering * 0.5
	
	var steering_wheel_rotation = $body/steering_wheel.get_rotation()
	$body/steering_wheel.set_rotation(Vector3(steering_wheel_rotation.x, -steering * 1.5, 0))
	
	for wheel in wheels:
		wheel.speed = velocity.length()
	
	# transform with translation removed
	var rotate_transform = transform.translated(-position)
	
	var up = rotate_transform * UP
	var up_transform = Transform3D.IDENTITY
	if not up.is_equal_approx(UP):
		var up_axis = up.cross(UP).normalized()
		var up_angle = up.signed_angle_to(UP, up_axis)
		up_transform = Transform3D().rotated(up_axis, up_angle)
	
	var forward_transformed = up_transform.inverse() * (rotate_transform * FORWARD)
	direction = Vector2(forward_transformed.x, forward_transformed.z)
	
	var adj_direction = direction
	
	var vel_rotated = up_transform * velocity
	var velocity_2d = Vector2(vel_rotated.x, vel_rotated.z)
	
	# handle reversing """convincingly"""
	if direction.dot(velocity_2d) < 0.0:
		steering *= -1
		adj_direction *= -1
	
	# Smooth coefficient between [0.0, 1.0] based on vehicle speed
	# https://www.desmos.com/calculator/t0yij5aqal
	var c = 0.5 * (1 - cos(0.4 * min(velocity_2d.length() / 3, 2.5 * PI)))
	assert(0 <= c and c <= 1)
	
	if throttle > 0.0 and brake == 0.0:
		rpm += throttle * rpm_climb * max(1 - c, 0.3) * delta
	else:
		rpm -= rpm_decay * delta
		rpm = max(rpm, 0.0)
	
	var wheel_vel = power(rpm) * direction.rotated(steering * c)
	
	var dot = abs(wheel_vel.normalized().dot(velocity_2d.normalized()))
	if wheel_vel.length_squared() < EPSILON:
		dot = 1.0
	
	velocity_2d += (wheel_vel - velocity_2d) * delta
	
	var rotate_amount = (adj_direction.angle_to(velocity_2d) + steering * max(1 - c, 0.3) * steering_c) * c * delta
	direction = direction.rotated(rotate_amount)
	rotate(up, -rotate_amount)
	
	var friction = \
		adj_direction * min(
			delta * max(c, 0.3) * (rolling_decay + brake * brake_power),
			velocity_2d.project(adj_direction).length()) \
		+ (velocity_2d - velocity_2d.project(adj_direction)).normalized() * (1.0 - dot) * slide_decay * delta
	
	rpm -= brake_power * (brake) * delta
	
	if velocity_2d.length_squared() > EPSILON:
		velocity_2d -= friction
	
	velocity_2d = velocity_2d.rotated(velocity_2d.angle_to(adj_direction) * dot * steering_c * delta)
	
	accel = (velocity_2d - last_vel).rotated(-direction.angle())
	last_vel = velocity_2d
	
	var velocity_3d = Vector3(velocity_2d.x, 0, velocity_2d.y)
	velocity = up_transform.inverse() * velocity_3d

const FRONT_TILT: float = 0.4
const SIDE_TILT: float = 0.3
const MAX_ACCEL: float = 5.0
var front_roll = Transform3D().rotated(Vector3(-1, 0, 0), FRONT_TILT)
var side_roll = Transform3D().rotated(Vector3(0, 0, 1), SIDE_TILT)

func body_roll(delta: float) -> void:
	var front_weight = min(max(accel.x, -MAX_ACCEL), MAX_ACCEL) / MAX_ACCEL
	var side_weight = min(max(accel.y, -MAX_ACCEL), MAX_ACCEL) / MAX_ACCEL
	
	var t = Transform3D.IDENTITY
	
	if front_weight >= 0:
		t *= Transform3D.IDENTITY.interpolate_with(front_roll, front_weight)
	else:
		t *= Transform3D.IDENTITY.interpolate_with(front_roll.inverse(), -front_weight)
	
	if side_weight >= 0:
		t *= Transform3D.IDENTITY.interpolate_with(side_roll, side_weight)
	else:
		t *= Transform3D.IDENTITY.interpolate_with(side_roll.inverse(), -side_weight)
	
	$body.transform = $body.transform.interpolate_with(t, 5 * delta)

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
	body_roll(delta)
	move_and_slide()
