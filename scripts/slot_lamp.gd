class_name SlotPreviewLamp
extends Control

signal light_changed(is_lit: bool, source: String)

var is_lit := false
var pulse_phase := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	queue_redraw()

func set_lit(value: bool, source: String = "system") -> void:
	if is_lit == value:
		return
	is_lit = value
	pulse_phase = 0.0
	set_process(is_lit)
	queue_redraw()
	light_changed.emit(is_lit, source)

func _process(delta: float) -> void:
	pulse_phase = fposmod(pulse_phase + delta * 2.4, TAU)
	queue_redraw()

func _draw() -> void:
	var center := size * Vector2(0.5, 0.53)
	if not is_lit:
		_draw_ellipse(center, Vector2(78, 49), Color(0.015, 0.055, 0.055, 0.82))
		_draw_ellipse(center, Vector2(61, 38), Color(0.04, 0.12, 0.12, 0.72))
		_draw_lotus(center + Vector2(0, 5), Color(0.19, 0.38, 0.34, 0.78), Color(0.30, 0.55, 0.49, 0.65))
		return
	var pulse := (sin(pulse_phase) + 1.0) * 0.5
	_draw_ellipse(center, Vector2(85, 54), Color(0.18, 0.84, 1.0, 0.12 + pulse * 0.05))
	_draw_ellipse(center, Vector2(70, 45), Color(0.12, 0.90, 1.0, 0.20 + pulse * 0.08))
	_draw_ellipse(center, Vector2(54, 35), Color(0.58, 0.98, 1.0, 0.22 + pulse * 0.08))
	_draw_lotus(center + Vector2(0, 5), Color(0.42, 1.0, 0.82, 0.76), Color(0.70, 0.98, 1.0, 0.95))

func _draw_lotus(center: Vector2, fill: Color, outline: Color) -> void:
	for angle in [-1.08, -0.54, 0.0, 0.54, 1.08]:
		var leaf_center := center + Vector2(sin(angle) * 22.0, -absf(cos(angle)) * 7.0)
		var points := _leaf_points(leaf_center, 54.0, 17.0, angle)
		draw_colored_polygon(points, fill)
		points.append(points[0])
		draw_polyline(points, outline, 2.0, true)
	draw_arc(center + Vector2(0, 13), 27.0, PI * 0.12, PI * 0.88, 20, outline, 2.0)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(48):
		var angle := TAU * float(index) / 48.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

func _leaf_points(center: Vector2, length: float, width: float, angle: float) -> PackedVector2Array:
	var local_points := [Vector2(0,-length*0.5), Vector2(width*0.5,-length*0.08), Vector2(width*0.42,length*0.30), Vector2(0,length*0.5), Vector2(-width*0.42,length*0.30), Vector2(-width*0.5,-length*0.08)]
	var result := PackedVector2Array()
	for point in local_points:
		result.append(center + point.rotated(angle))
	return result
