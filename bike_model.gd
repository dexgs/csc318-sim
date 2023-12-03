extends Node3D

const BODY_COLOURS = [
	Color.DIM_GRAY,
	Color.BLUE,
	Color.NAVY_BLUE,
	Color.YELLOW
]

const BIKE_COLOURS = [
	Color.ORANGE_RED,
	Color.BLACK,
	Color.BLUE,
	Color.RED
]


func _ready():
	randomize()
	$Icosphere_027.get_surface_override_material(0).albedo_color = BODY_COLOURS[randi() % BODY_COLOURS.size()]
	$Circle_002.get_surface_override_material(0).albedo_color = BIKE_COLOURS[randi() % BIKE_COLOURS.size()]
