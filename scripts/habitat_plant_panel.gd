class_name HabitatPlantPanel
extends Control

signal close_requested

var individual_id := ""
var title_label: Label
var detail_label: Label
var close_button: Button


func _ready() -> void:
	name = "HabitatPlantPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()


func open_for(plant: Dictionary, species_name: String, size_text: String, observation_text: String, close_text: String) -> void:
	individual_id = str(plant.get("individual_id", ""))
	title_label.text = species_name
	detail_label.text = size_text
	if not observation_text.is_empty():
		detail_label.text += "\n\n" + observation_text
	close_button.text = close_text
	visible = true


func close() -> void:
	visible = false
	individual_id = ""
	close_requested.emit()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.035, 0.025, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(42, 315)
	panel.size = Vector2(492, 350)
	panel.add_theme_stylebox_override("panel", _box(Color("#f7e8c7"), Color("#9b6739"), 28, 4))
	add_child(panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 20)
	panel.add_child(content)

	title_label = Label.new()
	title_label.name = "HabitatPlantTitle"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 29)
	title_label.add_theme_color_override("font_color", Color("#54351f"))
	content.add_child(title_label)

	detail_label = Label.new()
	detail_label.name = "HabitatPlantDetails"
	detail_label.custom_minimum_size = Vector2(430, 145)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size", 20)
	detail_label.add_theme_color_override("font_color", Color("#65452e"))
	content.add_child(detail_label)

	close_button = _button("閉じる", "HabitatPlantClose", Color("#ead8b1"), Vector2(270, 54))
	close_button.pressed.connect(close)
	content.add_child(close_button)


func _button(text_value: String, node_name: String, background: Color, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text_value
	button.custom_minimum_size = minimum_size
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("#54351f"))
	button.add_theme_stylebox_override("normal", _box(background, Color("#8f633b"), 14, 2))
	button.add_theme_stylebox_override("hover", _box(background.lightened(0.08), Color("#8f633b"), 14, 2))
	button.add_theme_stylebox_override("pressed", _box(background.darkened(0.08), Color("#8f633b"), 14, 2))
	return button


func _box(background: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
