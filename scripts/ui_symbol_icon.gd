class_name UISymbolIcon
extends Control

var symbol:="sparkle":
	set(value):symbol=value;queue_redraw()
var icon_color:=Color("#ffe168"):
	set(value):icon_color=value;queue_redraw()

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size==Vector2.ZERO:custom_minimum_size=Vector2(34,34)

func _draw()->void:
	var center:=size*.5
	var radius:=minf(size.x,size.y)*.42
	match symbol:
		"seed":
			draw_circle(center,radius*.62,icon_color)
			draw_arc(center,radius*.62,0.0,TAU,24,icon_color.lightened(.28),maxf(2.0,radius*.12),true)
		"heart":
			var points:=PackedVector2Array([center+Vector2(0,radius*.78),center+Vector2(-radius*.92,-radius*.18),center+Vector2(-radius*.55,-radius*.78),center+Vector2(0,-radius*.36),center+Vector2(radius*.55,-radius*.78),center+Vector2(radius*.92,-radius*.18)])
			draw_colored_polygon(points,icon_color)
		"lock":
			draw_arc(center+Vector2(0,-radius*.22),radius*.48,PI,TAU,20,icon_color,maxf(3.0,radius*.16),true)
			draw_rect(Rect2(center+Vector2(-radius*.65,-radius*.10),Vector2(radius*1.3,radius*.94)),icon_color,true)
		"rain":
			draw_arc(center+Vector2(0,-radius*.18),radius*.76,PI,TAU,24,icon_color,maxf(3.0,radius*.16),true)
			for offset in [-.48,0.0,.48]:draw_line(center+Vector2(radius*offset,radius*.18),center+Vector2(radius*(offset-.14),radius*.78),icon_color,maxf(2.0,radius*.12),true)
		"pointer":
			var points:=PackedVector2Array([center+Vector2(-radius*.18,radius*.85),center+Vector2(-radius*.18,-radius*.66),center+Vector2(radius*.12,-radius*.92),center+Vector2(radius*.36,-radius*.62),center+Vector2(radius*.72,-radius*.24),center+Vector2(radius*.60,radius*.46),center+Vector2(radius*.18,radius*.86)])
			draw_colored_polygon(points,icon_color)
		_:
			var points:=PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius*.22,-radius*.22),center+Vector2(radius,0),center+Vector2(radius*.22,radius*.22),center+Vector2(0,radius),center+Vector2(-radius*.22,radius*.22),center+Vector2(-radius,0),center+Vector2(-radius*.22,-radius*.22)])
			draw_colored_polygon(points,icon_color)
