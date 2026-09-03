class_name ArrangementWorkbenchPlaceholder
extends Control

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw()->void:
	var width:=size.x
	var height:=size.y
	# This is intentionally a simple foreground placeholder, not final artwork.
	# The greenhouse master image remains visible through it, so replacing
	# greenhouse_main_extended.png later does not require UI code changes.
	draw_rect(Rect2(0,height*.62,width,height*.38),Color(0.25,0.12,0.065,.83))
	draw_rect(Rect2(0,height*.60,width,height*.065),Color(0.48,0.27,0.13,.96))
	draw_line(Vector2(0,height*.615),Vector2(width,height*.615),Color(0.82,0.58,0.29,.72),4.0)
	for index in range(8):
		var x:=float(index)*width/7.0
		draw_line(Vector2(x,height*.65),Vector2(x-42.0,height),Color(0.16,0.075,0.04,.20),2.0)
	draw_rect(Rect2(width*.07,height*.16,width*.30,12),Color(0.31,0.16,0.09,.55))
	draw_rect(Rect2(width*.63,height*.20,width*.28,12),Color(0.31,0.16,0.09,.45))
