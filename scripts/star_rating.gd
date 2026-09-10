class_name StarRating
extends Control

var star_count := 0:
	set(value):
		star_count=clampi(value,0,2)
		custom_minimum_size=Vector2(maxf(1.0,float(star_count)*34.0),34.0)
		queue_redraw()
var star_color:=Color("#ffd34e")
var outline_color:=Color("#7a4612")

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	custom_minimum_size=Vector2(maxf(1.0,float(star_count)*34.0),34.0)

func _draw()->void:
	for index in star_count:
		var center:=Vector2(17.0+34.0*index,17.0)
		var outer:=_star_points(center,14.5,6.3)
		draw_colored_polygon(_star_points(center,16.5,7.4),outline_color)
		draw_colored_polygon(outer,star_color)
		draw_polyline(PackedVector2Array(outer),Color("#fff3a0"),1.5,true)

func _star_points(center:Vector2,outer_radius:float,inner_radius:float)->PackedVector2Array:
	var points:=PackedVector2Array()
	for point_index in 10:
		var radius:=outer_radius if point_index%2==0 else inner_radius
		var angle:=-PI*.5+float(point_index)*PI/5.0
		points.append(center+Vector2(cos(angle),sin(angle))*radius)
	return points
