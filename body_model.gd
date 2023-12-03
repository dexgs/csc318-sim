extends Node3D

const COLOURS = [
	Color.RED,
	Color.DIM_GRAY,
	Color.BLUE,
	Color.NAVY_BLUE,
	Color.YELLOW,
	Color.LIGHT_CORAL,
	Color.DARK_OLIVE_GREEN,
	Color.INDIGO,
	Color.MEDIUM_PURPLE,
	Color.WHITE
]


func _ready():
	randomize()
	$body.get_surface_override_material(1).albedo_color = COLOURS[randi() % COLOURS.size()]
