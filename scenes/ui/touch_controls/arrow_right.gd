extends TextureRect

func _draw():
	var size = Vector2(30, 30)
	var points = PackedVector2Array([
		Vector2(size.x, size.y / 2),
		Vector2(0, 0),
		Vector2(0, size.y * 0.3),
		Vector2(size.x * 0.7, size.y / 2),
		Vector2(0, size.y * 0.7),
		Vector2(0, size.y)
	])
	draw_colored_polygon(points, Color.WHITE)