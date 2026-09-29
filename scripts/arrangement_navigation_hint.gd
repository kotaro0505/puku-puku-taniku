class_name ArrangementNavigationHint
extends Control

signal intro_finished

const Localizer = preload("res://scripts/game_localizer.gd")
const UISymbolIconClass = preload("res://scripts/ui_symbol_icon.gd")

var persistent_panel: PanelContainer
var persistent_label: Label
var intro_panel: PanelContainer
var intro_label: Label
var intro_pointer: Control
var intro_tween: Tween
var intro_playing := false


func _ready() -> void:
	name = "ArrangementNavigationHint"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 870
	_build_ui()
	visible = false


func _build_ui() -> void:
	persistent_panel = PanelContainer.new()
	persistent_panel.size = Vector2(232, 48)
	persistent_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	persistent_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.13, 0.075, 0.04, 0.82)))
	add_child(persistent_panel)
	persistent_label = Label.new()
	persistent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	persistent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	persistent_label.add_theme_font_size_override("font_size", 16)
	persistent_label.add_theme_color_override("font_color", Color("#fff1c8"))
	persistent_label.add_theme_color_override("font_outline_color", Color("#442417"))
	persistent_label.add_theme_constant_override("outline_size", 4)
	persistent_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	persistent_panel.add_child(persistent_label)

	intro_panel = PanelContainer.new()
	intro_panel.position = Vector2(58, 826)
	intro_panel.size = Vector2(460, 112)
	intro_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.07, 0.035, 0.94)))
	intro_panel.visible = false
	add_child(intro_panel)
	intro_label = Label.new()
	intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	intro_label.add_theme_font_size_override("font_size", 19)
	intro_label.add_theme_color_override("font_color", Color("#fff0bd"))
	intro_label.add_theme_color_override("font_outline_color", Color("#4b2918"))
	intro_label.add_theme_constant_override("outline_size", 4)
	intro_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_panel.add_child(intro_label)
	intro_pointer = UISymbolIconClass.new()
	intro_pointer.symbol = "pointer"
	intro_pointer.icon_color = Color("#ffe48d")
	intro_pointer.position = Vector2(95, 55)
	intro_pointer.size = Vector2(42, 42)
	intro_panel.add_child(intro_pointer)


func update_hint(locale: String, arrangement_active: bool, transition_direction: float, should_show: bool) -> void:
	if intro_playing:
		visible = true
		persistent_panel.visible = false
		return
	visible = should_show
	if not should_show:
		return
	intro_panel.visible = false
	persistent_panel.visible = true
	var direction := signf(transition_direction)
	if is_zero_approx(direction):
		direction = 1.0
	if arrangement_active:
		direction *= -1.0
	var arrow := "→" if direction > 0.0 else "←"
	var key := "main_game_mode_hint" if arrangement_active else "arrangement_mode_hint"
	var title := Localizer.text(locale, key)
	persistent_label.text = "%s  %s" % [title, arrow] if direction > 0.0 else "%s  %s" % [arrow, title]
	persistent_panel.position = Vector2(326, 956) if direction > 0.0 else Vector2(18, 956)


func play_intro(locale: String, transition_direction: float) -> void:
	if intro_playing:
		return
	if intro_tween and intro_tween.is_valid():
		intro_tween.kill()
	intro_playing = true
	visible = true
	persistent_panel.visible = false
	intro_panel.visible = true
	intro_panel.modulate.a = 1.0
	intro_label.text = Localizer.text(locale, "arrangement_swipe_intro")
	var direction := signf(transition_direction)
	if is_zero_approx(direction):
		direction = 1.0
	var start_x := 92.0 if direction > 0.0 else 326.0
	var end_x := 326.0 if direction > 0.0 else 92.0
	intro_pointer.position = Vector2(start_x, 55)
	intro_pointer.modulate.a = 0.0
	intro_tween = create_tween()
	for cycle in 2:
		intro_tween.tween_property(intro_pointer, "modulate:a", 1.0, 0.16)
		intro_tween.tween_property(intro_pointer, "position:x", end_x, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		intro_tween.parallel().tween_property(intro_pointer, "modulate:a", 0.18, 0.72)
		if cycle == 0:
			intro_tween.tween_callback(func(): intro_pointer.position.x = start_x)
			intro_tween.tween_interval(0.12)
	intro_tween.tween_interval(0.35)
	intro_tween.tween_property(intro_panel, "modulate:a", 0.0, 0.24)
	intro_tween.finished.connect(_finish_intro, CONNECT_ONE_SHOT)


func _finish_intro() -> void:
	intro_playing = false
	intro_panel.visible = false
	intro_panel.modulate.a = 1.0
	intro_finished.emit()


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(1.0, 0.82, 0.52, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 6
	return style
