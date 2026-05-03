extends Node2D

var path: PackedVector2Array = []

func draw_path(p: PackedVector2Array):
	path = p
	queue_redraw()

func _draw() -> void:
	if path.size() > 3:
		draw_polyline(path, Color.WHITE_SMOKE, 2)
