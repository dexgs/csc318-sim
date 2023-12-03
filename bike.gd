class_name Bike
extends CharacterBody3D

@export var next_checkpoint_path: NodePath = ""
@onready var next_checkpoint = get_node(next_checkpoint_path)

@export var active_radius: float = 30

var is_active: bool = false

@export var speed: float = 20

func _ready() -> void:
	$active_area/CollisionShape3D.shape.set_radius(active_radius)

func _physics_process(delta: float) -> void:
	$model/wheel_animation.speed_scale = velocity.length()
	
	var angle = (Vector3(0, 0, 1) * transform.translated(-position).inverse()).signed_angle_to(velocity, Vector3(0, 1, 0))
	rotate(Vector3(0, 1, 0), angle)
	var r = $model.get_rotation()
	#$model.set_rotation(Vector3(r.x, r.y, angle / 2))
	
	if is_active and next_checkpoint != null:
		velocity = velocity.move_toward((next_checkpoint.position - position).normalized() * speed, 5 * delta)
		move_and_slide()
		
		if next_checkpoint.overlaps_body(self):
			if next_checkpoint.next_checkpoint == NodePath("."):
				self.queue_free()
			else:
				next_checkpoint = next_checkpoint.get_node(next_checkpoint.next_checkpoint)
	else:
		for body in $active_area.get_overlapping_bodies():
			if body is Car and body.is_player:
				is_active = true
