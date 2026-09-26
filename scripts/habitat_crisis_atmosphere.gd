class_name HabitatCrisisAtmosphere
extends Control

# Visual-only Act III atmosphere. It deliberately has no connection to the
# retired rain bonus, seed rewards, growth, ownership, or habitat simulation.

var crisis_active := false
var habitat_visible := false
var rain_drops: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "HabitatCrisisAtmosphere"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = -5
	rng.seed = 20260926
	for index in 58:
		rain_drops.append({
			"x": rng.randf_range(0.0, 576.0),
			"y": rng.randf_range(-1024.0, 1024.0),
			"speed": rng.randf_range(520.0, 940.0),
			"length": rng.randf_range(20.0, 42.0)
		})
	visible = false
	set_process(true)


func activate() -> void:
	crisis_active = true
	_refresh_visibility()


func deactivate() -> void:
	crisis_active = false
	_refresh_visibility()


func set_habitat_visible(value: bool) -> void:
	habitat_visible = value
	_refresh_visibility()


func _refresh_visibility() -> void:
	visible = crisis_active and habitat_visible
	if visible:
		move_to_front()
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	for drop in rain_drops:
		drop["y"] = float(drop["y"]) + float(drop["speed"]) * delta
		if float(drop["y"]) > 1050.0:
			drop["y"] = rng.randf_range(-240.0, -20.0)
			drop["x"] = rng.randf_range(0.0, 576.0)
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.045, 0.07, 0.50))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.18, 0.24, 0.32, 0.18))
	for drop in rain_drops:
		var start := Vector2(float(drop["x"]), float(drop["y"]))
		var finish := start + Vector2(-7.0, float(drop["length"]))
		draw_line(start, finish, Color(0.72, 0.86, 1.0, 0.58), 1.5)
