extends Area3D


func _on_body_entered(body) -> void:
	if body is Car and body.is_player:
		get_tree().reload_current_scene()
