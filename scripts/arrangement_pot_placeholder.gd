class_name ArrangementPotPlaceholder
extends Control

var display_name := "鉢"

func _draw()->void:
	var center:=size*Vector2(.5,.72)
	var rim:=Rect2(size.x*.16,size.y*.50,size.x*.68,size.y*.15)
	var body:=PackedVector2Array([
		Vector2(size.x*.22,size.y*.60),
		Vector2(size.x*.78,size.y*.60),
		Vector2(size.x*.68,size.y*.94),
		Vector2(size.x*.32,size.y*.94)
	])
	draw_polygon(body,PackedColorArray([Color("#c9804e")]))
	draw_polyline(PackedVector2Array([body[0],body[1],body[2],body[3],body[0]]),Color("#704329"),4.0,true)
	draw_style_box(_rounded_box(Color("#dc9863"),Color("#704329"),18,4),rim)
	draw_ellipse(center+Vector2(0,-size.y*.14),size.x*.29,size.y*.055,Color("#5a321f"))
	var font:=get_theme_default_font()
	var label_size:=font.get_string_size(display_name,HORIZONTAL_ALIGNMENT_CENTER,-1,16)
	draw_string(font,Vector2((size.x-label_size.x)*.5,size.y*.87),display_name,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#fff1d2"))

func _rounded_box(bg:Color,border:Color,radius:int,width:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border
	style.set_border_width_all(width);style.set_corner_radius_all(radius)
	return style
