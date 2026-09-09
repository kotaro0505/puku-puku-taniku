class_name SlotGlassOverlay
extends Control

const WINDOW_RECTS := [
	Rect2(143, 424, 138, 218),
	Rect2(300, 424, 136, 218),
	Rect2(454, 424, 135, 218),
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	for rect in WINDOW_RECTS:
		_draw_window_glass(rect)

func _draw_window_glass(rect: Rect2) -> void:
	var diagonal := PackedVector2Array([
		rect.position + Vector2(5, 5),
		rect.position + Vector2(rect.size.x * 0.42, 5),
		rect.position + Vector2(rect.size.x * 0.18, rect.size.y - 5),
		rect.position + Vector2(5, rect.size.y - 5),
	])
	draw_colored_polygon(diagonal, Color(0.88, 0.98, 1.0, 0.075))
	var edge_glow := PackedVector2Array([
		rect.position + Vector2(rect.size.x - 18, 4),
		rect.position + Vector2(rect.size.x - 4, 4),
		rect.position + Vector2(rect.size.x - 4, rect.size.y - 4),
		rect.position + Vector2(rect.size.x - 30, rect.size.y - 4),
	])
	draw_colored_polygon(edge_glow, Color(0.72, 0.92, 1.0, 0.045))
	for ratio: float in [0.18, 0.52, 0.82]:
		var y: float = rect.position.y + rect.size.y * ratio
		draw_line(Vector2(rect.position.x + 8, y), Vector2(rect.end.x - 8, y), Color(1, 1, 1, 0.10), 2.0)
	draw_rect(rect.grow(-1.0), Color(0.82, 0.96, 1.0, 0.20), false, 1.5)
