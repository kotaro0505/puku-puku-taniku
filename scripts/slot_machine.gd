class_name SlotMachineFoundation
extends Control

signal exit_requested
signal spin_started(targets: Array[String])
signal reel_stopped(reel_index: int, symbol_id: String)
signal all_reels_stopped(symbol_ids: Array[String])
signal preview_win(symbol_ids: Array[String])
signal prize_requested(prize_type: String, payload: Dictionary)

const ReelClass = preload("res://scripts/slot_reel.gd")
const GlassClass = preload("res://scripts/slot_glass_overlay.gd")
const LampClass = preload("res://scripts/slot_lamp.gd")
const BACKGROUND: Texture2D = preload("res://assets/slot/slot-machine-background.jpg")
const SLOT_FONT: Font = preload("res://assets/fonts/ZenMaruGothic-Bold.ttf")
const DESIGN_SIZE := Vector2(720, 1280)
const REEL_RECTS := [
	Rect2(143, 424, 138, 218),
	Rect2(300, 424, 136, 218),
	Rect2(454, 424, 135, 218),
]
const CONTROL_RECTS := [
	Rect2(128, 686, 108, 106),
	Rect2(258, 691, 94, 96),
	Rect2(371, 691, 94, 96),
	Rect2(484, 691, 94, 96),
]

@export_range(0.0, 1.0, 0.01) var preview_hit_chance := 0.25
@export_enum("spin_start", "first_stop", "all_stopped") var lamp_timing := "all_stopped"

var design_root: Control
var background_layer: TextureRect
var reel_layer: Control
var glass_layer: SlotGlassOverlay
var lamp_layer: Control
var preview_lamp: SlotPreviewLamp
var prize_layer: Control
var controls_layer: Control
var reels: Array[SlotReel] = []
var spin_button: Button
var stop_buttons: Array[Button] = []
var lamp_test_button: Button
var status_label: Label
var next_stop_index := -1
var pending_targets: Array[String] = []
var stopped_results: Array[String] = ["", "", ""]
var pending_hit := false
var forced_result_for_next_spin: Array[String] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	rng.randomize()
	_build_scene_layers()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()

func _build_scene_layers() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "ScreenBackdrop"
	backdrop.color = Color("090806")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	design_root = Control.new()
	design_root.name = "SlotDesignRoot"
	design_root.size = DESIGN_SIZE
	design_root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(design_root)

	background_layer = TextureRect.new()
	background_layer.name = "MachineBackgroundLayer"
	background_layer.texture = BACKGROUND
	background_layer.size = DESIGN_SIZE
	background_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_layer.stretch_mode = TextureRect.STRETCH_SCALE
	background_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(background_layer)

	reel_layer = Control.new()
	reel_layer.name = "ReelLayer"
	reel_layer.size = DESIGN_SIZE
	reel_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(reel_layer)
	for index in range(REEL_RECTS.size()):
		var reel := ReelClass.new() as SlotReel
		reel.name = "Reel%d" % (index + 1)
		reel.reel_index = index
		reel.position = REEL_RECTS[index].position
		reel.size = REEL_RECTS[index].size
		reel.stopped.connect(_on_reel_stopped)
		reel_layer.add_child(reel)
		reels.append(reel)

	glass_layer = GlassClass.new() as SlotGlassOverlay
	glass_layer.name = "GlassWindowOverlayLayer"
	glass_layer.size = DESIGN_SIZE
	design_root.add_child(glass_layer)

	lamp_layer = Control.new()
	lamp_layer.name = "HitLampLayer"
	lamp_layer.size = DESIGN_SIZE
	lamp_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(lamp_layer)
	preview_lamp = LampClass.new() as SlotPreviewLamp
	preview_lamp.name = "PekariLamp"
	preview_lamp.position = Vector2(274, 241)
	preview_lamp.size = Vector2(174, 116)
	lamp_layer.add_child(preview_lamp)

	prize_layer = Control.new()
	prize_layer.name = "FuturePrizeLayer"
	prize_layer.position = Vector2(213, 916)
	prize_layer.size = Vector2(310, 126)
	prize_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(prize_layer)

	controls_layer = Control.new()
	controls_layer.name = "ControlsLayer"
	controls_layer.size = DESIGN_SIZE
	controls_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	design_root.add_child(controls_layer)
	_build_controls()

func _build_controls() -> void:
	spin_button = _make_physical_button("SpinButton", CONTROL_RECTS[0], "SPIN")
	spin_button.pressed.connect(spin)
	for index in range(3):
		var stop_button := _make_physical_button("StopButton%d" % (index + 1), CONTROL_RECTS[index + 1], "STOP %d" % (index + 1))
		stop_button.disabled = true
		stop_button.pressed.connect(stop_reel.bind(index))
		stop_buttons.append(stop_button)

	var back_button := _make_text_button("BackButton", Rect2(18, 20, 150, 54), "← ゲームへ")
	back_button.pressed.connect(_leave_preview)
	lamp_test_button = _make_text_button("LampTestButton", Rect2(536, 20, 166, 54), "ペカリ確認")
	lamp_test_button.pressed.connect(_toggle_test_lamp)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.position = Vector2(148, 1167)
	status_label.size = Vector2(424, 58)
	status_label.text = "SPINを押してスタート"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_override("font", SLOT_FONT)
	status_label.add_theme_font_size_override("font_size", 21)
	status_label.add_theme_color_override("font_color", Color("fff4d3"))
	status_label.add_theme_color_override("font_outline_color", Color(0.08, 0.045, 0.02, 0.95))
	status_label.add_theme_constant_override("outline_size", 6)
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls_layer.add_child(status_label)

func _make_physical_button(node_name: String, rect: Rect2, tooltip: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.position = rect.position
	button.size = rect.size
	button.pivot_offset = rect.size * 0.5
	button.text = ""
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _button_style(Color(0,0,0,0), Color(0.63,0.91,1.0,0.0), 48))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.35,0.84,1.0,0.08), Color(0.69,0.94,1.0,0.34), 48))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.76,0.96,1.0,0.22), Color(0.84,0.98,1.0,0.68), 48))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0,0,0,0.09), Color(0,0,0,0), 48))
	button.button_down.connect(_animate_button_press.bind(button, true))
	button.button_up.connect(_animate_button_press.bind(button, false))
	controls_layer.add_child(button)
	return button

func _make_text_button(node_name: String, rect: Rect2, text_value: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.position = rect.position
	button.size = rect.size
	button.pivot_offset = rect.size * 0.5
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", SLOT_FONT)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("fff1ca"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.08,0.045,0.025,0.76), Color(0.84,0.62,0.27,0.72), 18))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.12,0.15,0.13,0.88), Color(0.50,0.92,0.94,0.92), 18))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.22,0.37,0.36,0.90), Color(0.72,0.98,1.0,1.0), 18))
	button.button_down.connect(_animate_button_press.bind(button, true))
	button.button_up.connect(_animate_button_press.bind(button, false))
	controls_layer.add_child(button)
	return button

func _button_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0,0,0,0.30)
	style.shadow_size = 4
	return style

func _animate_button_press(button: Button, pressed: bool) -> void:
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * (0.92 if pressed else 1.0), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func spin() -> void:
	if reels.any(func(reel): return reel.is_moving()):
		return
	preview_lamp.set_lit(false, "spin_reset")
	stopped_results = ["", "", ""]
	pending_targets = _choose_targets()
	pending_hit = pending_targets[0] == pending_targets[1] and pending_targets[1] == pending_targets[2]
	next_stop_index = 0
	spin_button.disabled = true
	for index in range(stop_buttons.size()):
		stop_buttons[index].disabled = index != 0
	for reel in reels:
		reel.start_spin()
	status_label.text = "左からSTOPを押してね"
	_maybe_light_for_stage("spin_start")
	spin_started.emit(pending_targets.duplicate())

func stop_reel(index: int) -> void:
	if index != next_stop_index or index < 0 or index >= reels.size():
		return
	stop_buttons[index].disabled = true
	reels[index].request_stop(pending_targets[index])
	if index == 0:
		_maybe_light_for_stage("first_stop")
	next_stop_index += 1
	if next_stop_index < stop_buttons.size():
		stop_buttons[next_stop_index].disabled = false
		status_label.text = "STOP %d を押してね" % (next_stop_index + 1)
	else:
		next_stop_index = -1
		status_label.text = "リール停止中…"

func trigger_hit_preview(source: String = "manual") -> void:
	preview_lamp.set_lit(true, source)
	status_label.text = "ペカッ！ 水色ランプ点灯"

func clear_hit_preview(source: String = "manual") -> void:
	preview_lamp.set_lit(false, source)
	if not reels.any(func(reel): return reel.is_moving()):
		status_label.text = "SPINを押してスタート"

func set_next_spin_result_for_test(symbol_ids: Array[String]) -> void:
	forced_result_for_next_spin = symbol_ids.duplicate()

func _choose_targets() -> Array[String]:
	if forced_result_for_next_spin.size() == 3:
		var forced := forced_result_for_next_spin.duplicate()
		forced_result_for_next_spin.clear()
		return forced
	var symbol_ids: Array[String] = []
	for symbol in ReelClass.SYMBOLS:
		symbol_ids.append(str(symbol.id))
	if rng.randf() < preview_hit_chance:
		var winning_symbol := symbol_ids[rng.randi_range(0, symbol_ids.size() - 1)]
		return [winning_symbol, winning_symbol, winning_symbol]
	var result: Array[String] = []
	for index in range(3):
		result.append(symbol_ids[rng.randi_range(0, symbol_ids.size() - 1)])
	if result[0] == result[1] and result[1] == result[2]:
		result[2] = symbol_ids[(symbol_ids.find(result[2]) + 1) % symbol_ids.size()]
	return result

func _on_reel_stopped(index: int, symbol_id: String) -> void:
	stopped_results[index] = symbol_id
	reel_stopped.emit(index, symbol_id)
	if stopped_results.any(func(value): return value.is_empty()):
		return
	spin_button.disabled = false
	for button in stop_buttons:
		button.disabled = true
	_maybe_light_for_stage("all_stopped")
	if pending_hit:
		status_label.text = "ペカッ！ 仮当たり"
		preview_win.emit(stopped_results.duplicate())
	else:
		status_label.text = "もう一度SPIN！"
	all_reels_stopped.emit(stopped_results.duplicate())

func _maybe_light_for_stage(stage: String) -> void:
	if pending_hit and lamp_timing == stage:
		trigger_hit_preview(stage)

func _toggle_test_lamp() -> void:
	if preview_lamp.is_lit:
		clear_hit_preview("test_button")
	else:
		trigger_hit_preview("test_button")

func _leave_preview() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.href = window.location.pathname", true)
	else:
		exit_requested.emit()

func _apply_responsive_layout() -> void:
	if not design_root:
		return
	var viewport_size := get_viewport_rect().size
	var fit := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	design_root.scale = Vector2.ONE * fit
	design_root.position = (viewport_size - DESIGN_SIZE * fit) * 0.5

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: spin()
			KEY_1: stop_reel(0)
			KEY_2: stop_reel(1)
			KEY_3: stop_reel(2)
			KEY_L: _toggle_test_lamp()
