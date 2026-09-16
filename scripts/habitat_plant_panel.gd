class_name HabitatPlantPanel
extends Control

signal install_requested(individual_id: String)
signal remove_requested(individual_id: String)
signal close_requested

var individual_id := ""
var title_label: Label
var detail_label: Label
var beacon_button: Button
var message_label: Label
var beacon_installed := false


func _ready() -> void:
	name = "HabitatPlantPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()


func open_for(plant: Dictionary, species_name: String, beacon_unlocked: bool, beacon_total: int, beacon_used: int, eta_text: String, texts: Dictionary) -> void:
	individual_id = str(plant.get("individual_id", ""))
	var diameter := float(plant.get("diameter_cm", 0.0))
	var installed := bool(plant.get("panda_beacon_installed", false))
	beacon_installed = installed
	title_label.text = species_name
	detail_label.text = str(texts.get("size", "現在 %.3fcm") % diameter) + "\n" + str(texts.get("growing", "30cmまでゆっくり成長中")) + "\n" + str(texts.get("eta", "30cm到達予定：%s") % eta_text)
	if not beacon_unlocked:
		message_label.text = str(texts.get("locked", "パンダビーコンはまだ使えません"))
	elif installed:
		message_label.text = str(texts.get("installed", "パンダビーコン設置中")) + "\n" + str(texts.get("usage", "パンダビーコン %d個中 %d個使用中") % [beacon_total, beacon_used])
	else:
		message_label.text = str(texts.get("usage", "パンダビーコン %d個中 %d個使用中") % [beacon_total, beacon_used])
	beacon_button.visible = beacon_unlocked
	if installed:
		beacon_button.text = str(texts.get("remove", "パンダビーコンを外す"))
		beacon_button.disabled = false
	elif beacon_used >= beacon_total:
		beacon_button.text = str(texts.get("full", "空きビーコンがありません"))
		beacon_button.disabled = true
	else:
		beacon_button.text = str(texts.get("install", "パンダビーコンを設置"))
		beacon_button.disabled = diameter >= 30.0
	visible = true


func show_message(message: String) -> void:
	message_label.text = message


func close() -> void:
	visible = false
	individual_id = ""
	beacon_installed = false
	close_requested.emit()


func _toggle_beacon() -> void:
	if individual_id.is_empty():
		return
	if beacon_installed:
		remove_requested.emit(individual_id)
	else:
		install_requested.emit(individual_id)


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.035, 0.025, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(42, 258)
	panel.size = Vector2(492, 478)
	panel.add_theme_stylebox_override("panel", _box(Color("#f7e8c7"), Color("#9b6739"), 28, 4))
	add_child(panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 16)
	panel.add_child(content)
	title_label = Label.new()
	title_label.name = "HabitatPlantTitle"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 29)
	title_label.add_theme_color_override("font_color", Color("#54351f"))
	content.add_child(title_label)
	detail_label = Label.new()
	detail_label.name = "HabitatPlantDetails"
	detail_label.custom_minimum_size = Vector2(430, 150)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size", 19)
	detail_label.add_theme_color_override("font_color", Color("#65452e"))
	content.add_child(detail_label)
	message_label = Label.new()
	message_label.name = "HabitatBeaconStatus"
	message_label.custom_minimum_size = Vector2(430, 60)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.add_theme_color_override("font_color", Color("#76513b"))
	content.add_child(message_label)
	beacon_button = _button("パンダビーコンを設置", "PandaBeaconToggle", Color("#d9c77d"), Vector2(370, 62))
	beacon_button.pressed.connect(_toggle_beacon)
	content.add_child(beacon_button)
	var close_button := _button("閉じる", "HabitatPlantClose", Color("#ead8b1"), Vector2(270, 54))
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
	button.add_theme_stylebox_override("disabled", _box(Color("#d8d0bd"), Color("#9c907c"), 14, 2))
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
