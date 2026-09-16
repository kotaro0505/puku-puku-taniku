class_name PandaBeaconLogPanel
extends Control

signal confirmed
signal close_requested

var title_label: Label
var count_label: Label
var entry_list: VBoxContainer
var confirm_button: Button
var later_button: Button


func _ready() -> void:
	name = "PandaBeaconLogPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()


func open(entries: Array, species_name_resolver: Callable, language_code: String) -> void:
	for child in entry_list.get_children():
		child.free()
	title_label.text = "Panda Beacon" if language_code == "en" else ("ぱんだびーこん" if language_code == "hiragana" else "パンダビーコン")
	count_label.text = ("%d unread alerts" % entries.size()) if language_code == "en" else ("みかくにん %dけん" % entries.size() if language_code == "hiragana" else "未確認のお知らせ %d件" % entries.size())
	for entry_value in entries:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		var species_name := str(species_name_resolver.call(str(entry.get("species_id", ""))))
		var diameter := float(entry.get("diameter_cm", 0.0))
		var message := "%s jellied before collection." % species_name if language_code == "en" else ("%sは じゅれて しまいました。" % species_name if language_code == "hiragana" else "%sはジュレてしまいました。" % species_name)
		var label := Label.new()
		label.name = "PandaBeaconUnreadEntry"
		label.text = "%s\n%.1fcm" % [message, diameter]
		label.custom_minimum_size = Vector2(406, 82)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", Color("#493224"))
		label.add_theme_stylebox_override("normal", _box(Color("#fff8df"), Color("#c7a064"), 14, 2))
		entry_list.add_child(label)
	confirm_button.text = "Confirm" if language_code == "en" else ("かくにん" if language_code == "hiragana" else "確認")
	later_button.text = "Later" if language_code == "en" else ("あとで" if language_code == "hiragana" else "あとで")
	visible = true


func close() -> void:
	visible = false
	close_requested.emit()


func _confirm() -> void:
	visible = false
	confirmed.emit()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.035, 0.03, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(46, 174)
	panel.size = Vector2(484, 676)
	panel.add_theme_stylebox_override("panel", _box(Color("#f7e8c7"), Color("#6e5846"), 26, 4))
	add_child(panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 13)
	panel.add_child(content)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 27)
	title_label.add_theme_color_override("font_color", Color("#3e3128"))
	content.add_child(title_label)
	count_label = Label.new()
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 16)
	count_label.add_theme_color_override("font_color", Color("#76513b"))
	content.add_child(count_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(430, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content.add_child(scroll)
	entry_list = VBoxContainer.new()
	entry_list.custom_minimum_size = Vector2(406, 0)
	entry_list.add_theme_constant_override("separation", 10)
	scroll.add_child(entry_list)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	later_button = _button("あとで", "PandaBeaconLogLater", Color("#ead8b1"), Vector2(150, 52))
	later_button.pressed.connect(close)
	row.add_child(later_button)
	confirm_button = _button("確認", "PandaBeaconLogConfirm", Color("#b8d3c2"), Vector2(210, 52))
	confirm_button.pressed.connect(_confirm)
	row.add_child(confirm_button)


func _button(text_value: String, node_name: String, background: Color, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text_value
	button.custom_minimum_size = minimum_size
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("#54351f"))
	button.add_theme_stylebox_override("normal", _box(background, Color("#8f633b"), 13, 2))
	button.add_theme_stylebox_override("hover", _box(background.lightened(0.08), Color("#8f633b"), 13, 2))
	button.add_theme_stylebox_override("pressed", _box(background.darkened(0.08), Color("#8f633b"), 13, 2))
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
