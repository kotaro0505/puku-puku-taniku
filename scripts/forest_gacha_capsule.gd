extends Control

var lower_color := Color("#86a871")
var upper_color := Color(1.0, 0.96, 0.86, 0.90)

func set_seed(seed_value:int)->void:
	var palette := [Color("#83a66f"),Color("#d99267"),Color("#d9b965"),Color("#89aeb2"),Color("#b58ab0")]
	lower_color=palette[absi(seed_value)%palette.size()]
	queue_redraw()

func _draw()->void:
	var center:=size*.5
	var radius:=minf(size.x,size.y)*.40
	draw_circle(center,radius,lower_color)
	var upper_points:=PackedVector2Array([center-Vector2(radius,0.0)])
	for index in range(17):
		var angle:=PI+PI*float(index)/16.0
		upper_points.append(center+Vector2(cos(angle),sin(angle))*radius)
	upper_points.append(center+Vector2(radius,0.0))
	draw_colored_polygon(upper_points,upper_color)
	draw_arc(center,radius,0.0,TAU,48,Color(1.0,.91,.70,.92),3.0,true)
	draw_line(center-Vector2(radius,0.0),center+Vector2(radius,0.0),Color(1.0,.96,.88,.74),3.0,true)
	draw_circle(center+Vector2(-radius*.26,-radius*.30),radius*.12,Color(1,1,1,.42))
