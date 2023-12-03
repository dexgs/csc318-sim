class_name Car
extends CharacterBody3D

@export var is_player: bool = false
@export var next_checkpoint_path: NodePath = NodePath("")
var next_checkpoint: Checkpoint = null
@export var active_radius = 1000
var activated = false

var rpm_climb: float = 0.5
var rpm_decay: float = 0.3
var rolling_decay: float = 10.0
var slide_decay: float = 0.5
var brake_power: float = 15.0
var steering_c: float = 5.0

var rpm: float = 0
var last_steering: float = 0.0
var direction: Vector2 = Vector2.DOWN
var last_vel: Vector2 = Vector2.ZERO
var accel: Vector2 = Vector2.ZERO

var steering: float = 0.0
var brake: float = 0.0
var throttle: float = 0.0
var reverse: bool = false

const EPSILON: float = 0.0001
const UP: Vector3 = Vector3(0, 1, 0)

const FORWARD: Vector3 = Vector3(0, 0, 1)

@onready var wheels = [$front_l, $front_r, $rear_l, $rear_r]

func _ready() -> void:
	if is_player:
		rpm = 4.5
		$left_beep_timer.start()
		$right_beep_timer.start()
	else:
		$body/attach.queue_free()
		$body/left_viewport.queue_free()
		$body/right_viewport.queue_free()
		$body/rear_viewport.queue_free()
		$body/cam_transforms.queue_free()
		if next_checkpoint_path != NodePath(""):
			next_checkpoint = get_node(next_checkpoint_path)
		else:
			$engine.queue_free()
			$road_noise.queue_free()
		
		$active_area/CollisionShape3D.shape.set_radius(active_radius)

func power(rpm: float) -> float:
	return rpm * 10

func input(throttle: float, brake: float, steering: float) -> void:
	if velocity.length() < 0.2:
		if throttle > 0.0 and reverse:
			rpm = 0.0
			reverse = false
		elif brake > 0.0 and not reverse:
			rpm = 0.0
			reverse = true
	
	if reverse:
		self.throttle = brake
		self.brake = throttle
		self.steering = steering
	else:
		self.throttle = throttle
		self.brake = brake
		self.steering = steering

func drive(reverse: bool, throttle: float, brake: float, steering: float, delta: float) -> void:
	assert(0 <= throttle and throttle <= 1)
	assert(0 <= brake and brake <= 1)
	assert(-1 <= steering and steering <= 1)
	
	var steering_weight = delta * 2
	steering = steering * steering_weight + last_steering * (1 - steering_weight)
	last_steering = steering
	
	$front_l.angle = -steering * 0.5
	$front_r.angle = -steering * 0.5
	
	if is_player:
		var steering_wheel_rotation = $body/attach/steering_wheel.get_rotation()
		$body/attach/steering_wheel.set_rotation(Vector3(steering_wheel_rotation.x, -steering * 1.5, 0))
	
		$dash_viewport/spedometer.speed = velocity.length() * 1.5
	
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
	
	for wheel in wheels:
		wheel.speed = \
			velocity_2d.project(direction).length() \
			* velocity_2d.normalized().dot(direction)
	
	# handle reversing """convincingly"""
	if direction.dot(velocity_2d) < 0.0:
		steering *= -1
		adj_direction *= -1
	
	# Smooth coefficient between [0.0, 1.0] based on vehicle speed
	# https://www.desmos.com/calculator/t0yij5aqal
	var c = 0.5 * (1 - cos(0.4 * min(velocity_2d.length() / 3, 2.5 * PI)))
	assert(0 <= c and c <= 1)
	
	if throttle > 0.0 and brake == 0.0:
		if rpm < 0.5:
			rpm = 0.5
		rpm += throttle * rpm_climb * max(1 - c, 0.3) * delta
	else:
		rpm -= rpm_decay * delta
		rpm = max(rpm, 0.0)
	
	var wheel_vel = power(rpm) * direction.rotated(steering * c)
	if reverse:
		wheel_vel *= -1
	
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
	
	velocity_2d -= friction * min(velocity_2d.length() / 10, 1.0)
	
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

func get_speed_limit() -> void:
	for area in $Area3D.get_overlapping_areas():
		if area is SpeedLimit:
			$map_viewport/map_screen.speed_limit = area.limit

func update_sounds() -> void:
	$road_noise.volume_db = velocity.length() -30
	$road_noise.pitch_scale = max(min(velocity.length() / 30, 3.0), 0.1)
	
	$engine.volume_db = max(min(velocity.length() / 30, 1.0), 0.5) * throttle * 20 - 30
	$engine.pitch_scale = max(throttle * 1.5, 0.1)

func detect_stop_area() -> void:
	for area in $Area3D.get_overlapping_areas():
		if area is StopArea and $stop_timer.is_stopped() and velocity.length() > 1:
			$stop_timer.start()
			area.set_process_mode(PROCESS_MODE_DISABLED)

func _on_stop_timer_timeout():
	$map_viewport/map_screen.stop = true

func drive_to_checkpoint():
	var diff = next_checkpoint.get_position() - position
	var diff_2d = Vector2(diff.x, diff.z)
	
	throttle = 0.0
	brake = 0.0
	
	var speed = velocity.length() * 1.5
	
	if $front_raycast.is_colliding():
		brake = 1.0
	elif speed < next_checkpoint.target_speed:
		if speed < 1:
			rpm = next_checkpoint.target_speed / 15
		else:
			throttle = 1.0
	elif speed - next_checkpoint.target_speed > 10:
		brake = 0.4
	
	steering = direction.angle_to(diff_2d) / 1.2
	steering = max(min(steering, 1.0), -1.0)
	
	if next_checkpoint.overlaps_body(self):
		if next_checkpoint.next_checkpoint == NodePath("."):
			self.queue_free()
		else:
			next_checkpoint = next_checkpoint.get_node(next_checkpoint.next_checkpoint)

func detect_sides() -> void:
	var left_collider = $left_raycast.get_collider(0)
	if left_collider is CharacterBody3D \
	and left_collider.velocity.normalized().dot(velocity.normalized()) > 0.5 \
	and left_collider.velocity.length() > velocity.length() - 3:
		var d = (position - left_collider.position).project(velocity.normalized()).length()
		$left_beep.volume_db = -30 - d / 4
	else:
		$left_beep.volume_db = -500
	
	var right_collider = $right_raycast.get_collider(0)
	if right_collider is CharacterBody3D \
	and right_collider.velocity.normalized().dot(velocity.normalized()) > 0.5 \
	and right_collider.velocity.length() > velocity.length() - 3:
		var d = (position - right_collider.position).project(velocity.normalized()).length()
		$right_beep.volume_db = -30 - d / 4
	else:
		$right_beep.volume_db = -500

func _physics_process(delta: float) -> void:
	#var steering = 0.0
	#if Input.is_action_pressed('ui_left'):
	#	steering = -1.0
	#elif Input.is_action_pressed('ui_right'):
	#	steering = 1.0
	
	#var throttle = 0.0
	#if Input.is_action_pressed('ui_up'):
	#	throttle = 1.0
	
	#var brake = 0.0
	#if Input.is_action_pressed('ui_down'):
	#	brake = 1.0
	
	#input(throttle, brake, steering)
	drive(self.reverse, self.throttle, self.brake, self.steering, delta)
	body_roll(delta)
	
	if is_player:
		$map_viewport/map_screen.update_position(position)
		$map_viewport/map_screen.speed = velocity.length() * 1.5
		get_speed_limit()
		detect_stop_area()
		update_sounds()
		detect_sides()
	elif activated:
		if next_checkpoint != null:
			drive_to_checkpoint()
	else:
		for body in $active_area.get_overlapping_bodies():
			if body is Car and body.is_player:
				activated = true
	
	move_and_slide()


func _on_left_beep_timer_timeout():
	$left_beep.play()


func _on_right_beep_timer_timeout():
	$right_beep.play()
