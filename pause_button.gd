extends Button

@onready var pause_label = get_parent().get_node("pause_label")
@onready var instruction_panel = get_parent().get_node("instruction_panel")

func _toggled(button_pressed: bool) -> void:
	pause_label.visible = button_pressed
	instruction_panel.visible = button_pressed
	get_tree().paused = button_pressed
