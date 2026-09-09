class_name SlotReel
extends Control

signal stopped(reel_index: int, symbol_id: String)

const SLOT_FONT: Font = preload("res://assets/fonts/ZenMaruGothic-Bold.ttf")
const SYMBOLS := [
	{"id":"succulent", "label":"多肉", "color":Color("74a84a")},
	{"id":"seed_bag", "label":"たね", "color":Color("d39a45")},
	{"id":"pot", "label":"鉢", "color":Color("bb7043")},
	{"id":"panda", "label":"パンダ", "color":Color("3e3934")},
	{"id":"mystery_pod", "label":"さや", "color":Color("64a86c")},
	{"id":"puku_coin", "label":"ぷく", "color":Color("f2bf35")},
]

@export var reel_index := 0
@export var symbol_height := 72.0
@export var spin_speed := 980.0
@export var stop_duration := 0.92

var scroll_offset := 0.0
var current_speed := 0.0
var state := "idle"
var centered_symbol_id := "succulent"
var _rng := RandomNumberGenerator.new()
var _motion_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_rng.randomize()
	set_process(false)
	queue_redraw()

func start_spin() -> void:
	if _motion_tween and _motion_tween.is_valid():
		_motion_tween.kill()
	state = "spinning"
	current_speed = maxf(260.0, current_speed)
	set_process(true)
	_motion_tween = create_tween()
	_motion_tween.tween_property(self, "current_speed", spin_speed, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func request_stop(target_symbol_id: String = "") -> void:
	if state != "spinning":
		return
	set_process(false)
	state = "braking"
	if _motion_tween and _motion_tween.is_valid():
		_motion_tween.kill()
	var target_index := _symbol_index(target_symbol_id)
	if target_index < 0:
		target_index = _rng.randi_range(0, SYMBOLS.size() - 1)
	var cycle := symbol_height * float(SYMBOLS.size())
	var base_target := float(target_index) * symbol_height + symbol_height * 0.5 - size.y * 0.5
	var minimum_target := scroll_offset + cycle * 1.75
	var cycle_count := ceili((minimum_target - base_target) / cycle)
	var target_offset := base_target + float(cycle_count) * cycle
	_motion_tween = create_tween()
	_motion_tween.tween_method(_set_scroll_offset, scroll_offset, target_offset, stop_duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_motion_tween.finished.connect(_finish_stop.bind(target_index))

func is_moving() -> bool:
	return state != "idle"

func center_alignment_error() -> float:
	var item_number := roundi((scroll_offset + size.y * 0.5 - symbol_height * 0.5) / symbol_height)
	var center_y := float(item_number) * symbol_height + symbol_height * 0.5 - scroll_offset
	return absf(center_y - size.y * 0.5)

func _process(delta: float) -> void:
	if state != "spinning":
		return
	var cycle := symbol_height * float(SYMBOLS.size())
	scroll_offset = fposmod(scroll_offset + current_speed * delta, cycle)
	queue_redraw()

func _set_scroll_offset(value: float) -> void:
	scroll_offset = value
	queue_redraw()

func _finish_stop(target_index: int) -> void:
	var cycle := symbol_height * float(SYMBOLS.size())
	scroll_offset = fposmod(scroll_offset, cycle)
	current_speed = 0.0
	state = "idle"
	centered_symbol_id = str(SYMBOLS[target_index].id)
	queue_redraw()
	stopped.emit(reel_index, centered_symbol_id)

func _symbol_index(symbol_id: String) -> int:
	for index in range(SYMBOLS.size()):
		if str(SYMBOLS[index].id) == symbol_id:
			return index
	return -1

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.94, 0.90, 0.80, 0.72))
	var first_item := floori((scroll_offset - size.y) / symbol_height) - 1
	var last_item := ceili((scroll_offset + size.y * 2.0) / symbol_height) + 1
	for item_number in range(first_item, last_item):
		var center_y := float(item_number) * symbol_height + symbol_height * 0.5 - scroll_offset
		if center_y < -symbol_height or center_y > size.y + symbol_height:
			continue
		var symbol: Dictionary = SYMBOLS[posmod(item_number, SYMBOLS.size())]
		_draw_symbol(symbol, Vector2(size.x * 0.5, center_y))
		draw_line(Vector2(8.0, center_y + symbol_height * 0.5), Vector2(size.x - 8.0, center_y + symbol_height * 0.5), Color(0.34, 0.20, 0.10, 0.11), 1.0)
	draw_line(Vector2(4.0, size.y * 0.5), Vector2(size.x - 4.0, size.y * 0.5), Color(0.96, 0.73, 0.28, 0.38), 1.5)

func _draw_symbol(symbol: Dictionary, center: Vector2) -> void:
	var symbol_id := str(symbol.id)
	var color: Color = symbol.color
	var icon_center := center + Vector2(0.0, -6.0)
	draw_circle(icon_center, 24.0, Color(color, 0.15))
	match symbol_id:
		"succulent": _draw_succulent(icon_center, color)
		"seed_bag": _draw_seed_bag(icon_center, color)
		"pot": _draw_pot(icon_center, color)
		"panda": _draw_panda(icon_center)
		"mystery_pod": _draw_pod(icon_center, color)
		"puku_coin": _draw_coin(icon_center, color)
	draw_string(SLOT_FONT, Vector2(4.0, center.y + 30.0), str(symbol.label), HORIZONTAL_ALIGNMENT_CENTER, size.x - 8.0, 13, Color(0.20, 0.12, 0.07, 0.92))

func _draw_succulent(center: Vector2, color: Color) -> void:
	for index in range(7):
		var angle := TAU * float(index) / 7.0
		draw_colored_polygon(_leaf_points(center + Vector2.from_angle(angle) * 8.0, 25.0, 10.0, angle + PI * 0.5), Color(color.lightened(0.16), 0.95))
	draw_circle(center, 7.0, color.darkened(0.08))

func _draw_seed_bag(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array([center + Vector2(-16,-14), center + Vector2(16,-14), center + Vector2(20,16), center + Vector2(-20,16)])
	draw_colored_polygon(points, Color(color, 0.96))
	draw_line(center + Vector2(-16,-8), center + Vector2(16,-8), Color(0.35,0.20,0.08,0.75), 2.0)
	draw_circle(center + Vector2(-5,3), 3.5, Color("6f8f3f"))
	draw_circle(center + Vector2(5,5), 3.5, Color("7aa449"))

func _draw_pot(center: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([center+Vector2(-18,-2), center+Vector2(18,-2), center+Vector2(13,17), center+Vector2(-13,17)]), Color(color, 0.97))
	draw_rect(Rect2(center + Vector2(-21,-7), Vector2(42,8)), color.lightened(0.12), true)
	for angle in [-2.35, -1.57, -0.78]:
		draw_colored_polygon(_leaf_points(center + Vector2(0,-8) + Vector2.from_angle(angle) * 7.0, 20.0, 8.0, angle + PI * 0.5), Color("7faa56"))

func _draw_panda(center: Vector2) -> void:
	draw_circle(center + Vector2(-15,-13), 8.0, Color("2d2b29"))
	draw_circle(center + Vector2(15,-13), 8.0, Color("2d2b29"))
	draw_circle(center, 21.0, Color("fff8e8"))
	draw_circle(center + Vector2(-8,-3), 6.0, Color("36322f"))
	draw_circle(center + Vector2(8,-3), 6.0, Color("36322f"))
	draw_circle(center + Vector2(-7,-4), 2.0, Color.WHITE)
	draw_circle(center + Vector2(7,-4), 2.0, Color.WHITE)
	draw_circle(center + Vector2(0,7), 3.0, Color("3a302a"))

func _draw_pod(center: Vector2, color: Color) -> void:
	draw_colored_polygon(_leaf_points(center, 44.0, 18.0, 0.28), Color(color.lightened(0.12), 0.98))
	for offset in [-11.0, 0.0, 11.0]:
		draw_circle(center + Vector2(offset, offset * 0.28), 3.2, Color("e9d16c"))

func _draw_coin(center: Vector2, color: Color) -> void:
	draw_circle(center, 21.0, color)
	draw_arc(center, 17.0, 0.0, TAU, 36, Color("fff0a1"), 2.5)
	draw_string(SLOT_FONT, center + Vector2(-17.0, 8.0), "ぷ", HORIZONTAL_ALIGNMENT_CENTER, 34.0, 20, Color("70460e"))

func _leaf_points(center: Vector2, length: float, width: float, angle: float) -> PackedVector2Array:
	var local_points := [Vector2(0,-length*0.5), Vector2(width*0.5,-length*0.08), Vector2(width*0.42,length*0.30), Vector2(0,length*0.5), Vector2(-width*0.42,length*0.30), Vector2(-width*0.5,-length*0.08)]
	var result := PackedVector2Array()
	for point in local_points:
		result.append(center + point.rotated(angle))
	return result
