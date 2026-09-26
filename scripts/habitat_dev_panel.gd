class_name HabitatDevPanel
extends Control

signal close_requested
signal random_reset_requested
signal multiplier_requested(multiplier: int)
signal time_jump_requested(seconds: int)

const MULTIPLIERS := [1, 60, 3600, 21600, 86400]

var summary_label: Label
var plant_list: VBoxContainer
var event_log_label: Label
var multiplier_picker: OptionButton


func _ready() -> void:
	name = "HabitatDevPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()


func open() -> void:
	visible = true


func close() -> void:
	visible = false
	close_requested.emit()


func refresh(state: Dictionary, plants: Array, species_name_resolver: Callable, now_unix: float, logs: Array) -> void:
	if summary_label == null:
		return
	var multiplier := int(state.get("multiplier", 1))
	var picker_index := MULTIPLIERS.find(multiplier)
	if picker_index >= 0:
		multiplier_picker.select(picker_index)
	summary_label.text = "原生地時刻: %s\n倍率: ×%s\n表示個体: %d / %d　定着品種: %d" % [
		_format_unix(now_unix), _format_number(multiplier), int(state.get("population", 0)),
		int(state.get("max_population", 0)), int(state.get("settled_count", 0))
	]
	for child in plant_list.get_children():
		child.free()
	for plant_value in plants:
		if not plant_value is Dictionary:
			continue
		var plant: Dictionary = plant_value
		var species_name := str(species_name_resolver.call(str(plant.get("species_id", ""))))
		var diameter := float(plant.get("diameter_cm", 0.0))
		var status := "ジュレ済み" if bool(plant.get("jellied", false)) else ("成熟" if diameter >= float(plant.get("mature_diameter_cm", 30.0)) else "成長中")
		var age := maxf(0.0, now_unix - float(plant.get("spawned_unix", now_unix)))
		var label := Label.new()
		label.name = "HabitatPlantDebug_%s" % str(plant.get("individual_id", ""))
		label.text = "%s  %.3fcm  [%s]\n  経過 %s / 成熟目安 %.1fcm / ジュレ %s" % [
			species_name, diameter, status, _format_duration(age), float(plant.get("mature_diameter_cm", 30.0)),
			"はい" if bool(plant.get("jellied", false)) else "いいえ"
		]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(432, 72)
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color("#54351f"))
		label.add_theme_stylebox_override("normal", _box(Color("#fff8df"), Color("#d8b56b"), 12, 2))
		plant_list.add_child(label)
	var log_lines: Array[String] = []
	for index in range(maxi(0, logs.size() - 8), logs.size()):
		log_lines.append(str(logs[index]))
	event_log_label.text = "原生地イベントログ\n" + ("（まだありません）" if log_lines.is_empty() else "\n".join(log_lines))


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.035, 0.03, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(20, 22)
	panel.size = Vector2(536, 980)
	panel.add_theme_stylebox_override("panel", _box(Color("#f7e8c7"), Color("#8f633b"), 24, 4))
	add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)

	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(title_row)
	var title := Label.new()
	title.text = "通常原生地テスト"
	title.custom_minimum_size = Vector2(390, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("#54351f"))
	title_row.add_child(title)
	var close_button := _button("閉じる", "HabitatDevClose", Color("#ead8b1"), Vector2(100, 46))
	close_button.pressed.connect(close)
	title_row.add_child(close_button)

	summary_label = Label.new()
	summary_label.name = "HabitatDevSummary"
	summary_label.custom_minimum_size = Vector2(500, 78)
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary_label.add_theme_font_size_override("font_size", 15)
	summary_label.add_theme_color_override("font_color", Color("#54351f"))
	summary_label.add_theme_stylebox_override("normal", _box(Color("#fff5d9"), Color("#c99d57"), 13, 2))
	root.add_child(summary_label)

	var reset_row := HBoxContainer.new()
	reset_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reset_row.add_theme_constant_override("separation", 8)
	root.add_child(reset_row)
	var reset_button := _button("ランダムリセット", "HabitatRandomReset", Color("#d7c3a1"), Vector2(246, 48))
	reset_button.pressed.connect(func(): random_reset_requested.emit())
	reset_row.add_child(reset_button)

	var multiplier_row := HBoxContainer.new()
	multiplier_row.alignment = BoxContainer.ALIGNMENT_CENTER
	multiplier_row.add_theme_constant_override("separation", 10)
	root.add_child(multiplier_row)
	var multiplier_title := Label.new()
	multiplier_title.text = "時間早送り"
	multiplier_title.custom_minimum_size = Vector2(130, 44)
	multiplier_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	multiplier_title.add_theme_color_override("font_color", Color("#54351f"))
	multiplier_row.add_child(multiplier_title)
	multiplier_picker = OptionButton.new()
	multiplier_picker.name = "HabitatTimeMultiplier"
	multiplier_picker.custom_minimum_size = Vector2(230, 46)
	for multiplier in MULTIPLIERS:
		multiplier_picker.add_item("×%s" % _format_number(multiplier), multiplier)
	multiplier_picker.item_selected.connect(func(index: int): multiplier_requested.emit(int(multiplier_picker.get_item_id(index))))
	multiplier_row.add_child(multiplier_picker)

	var jump_row := HBoxContainer.new()
	jump_row.alignment = BoxContainer.ALIGNMENT_CENTER
	jump_row.add_theme_constant_override("separation", 6)
	root.add_child(jump_row)
	for jump in [{"label": "+1時間", "seconds": 3600}, {"label": "+6時間", "seconds": 21600}, {"label": "+1日", "seconds": 86400}, {"label": "+7日", "seconds": 604800}]:
		var jump_button := _button(str(jump.label), "HabitatJump%d" % int(jump.seconds), Color("#c7d6ad"), Vector2(118, 44))
		jump_button.pressed.connect(func(): time_jump_requested.emit(int(jump.seconds)))
		jump_row.add_child(jump_button)

	var plants_title := Label.new()
	plants_title.text = "各株の状態"
	plants_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plants_title.add_theme_font_size_override("font_size", 18)
	plants_title.add_theme_color_override("font_color", Color("#54351f"))
	root.add_child(plants_title)
	var scroll := ScrollContainer.new()
	scroll.name = "HabitatPlantDebugScroll"
	scroll.custom_minimum_size = Vector2(500, 450)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 12
	root.add_child(scroll)
	plant_list = VBoxContainer.new()
	plant_list.custom_minimum_size = Vector2(478, 0)
	plant_list.add_theme_constant_override("separation", 6)
	scroll.add_child(plant_list)

	event_log_label = Label.new()
	event_log_label.name = "HabitatEventDebugLog"
	event_log_label.custom_minimum_size = Vector2(500, 108)
	event_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_log_label.add_theme_font_size_override("font_size", 13)
	event_log_label.add_theme_color_override("font_color", Color("#54351f"))
	event_log_label.add_theme_stylebox_override("normal", _box(Color("#efe4ff"), Color("#9e82be"), 12, 2))
	root.add_child(event_log_label)


func _button(text_value: String, node_name: String, background: Color, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text_value
	button.custom_minimum_size = minimum_size
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("#54351f"))
	button.add_theme_stylebox_override("normal", _box(background, Color("#8f633b"), 11, 2))
	button.add_theme_stylebox_override("hover", _box(background.lightened(0.08), Color("#8f633b"), 11, 2))
	button.add_theme_stylebox_override("pressed", _box(background.darkened(0.08), Color("#8f633b"), 11, 2))
	return button


func _box(background: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


func _format_unix(value: float) -> String:
	if value <= 0.0:
		return "—"
	return Time.get_datetime_string_from_unix_time(int(value), true)


func _format_duration(seconds: float) -> String:
	var whole := maxi(0, int(seconds))
	var days := whole / 86400
	var hours := (whole % 86400) / 3600
	var minutes := (whole % 3600) / 60
	return "%d日 %d時間 %d分" % [days, hours, minutes]


func _format_number(value: int) -> String:
	return str(value) if value < 1000 else "%d,%03d" % [value / 1000, value % 1000]
