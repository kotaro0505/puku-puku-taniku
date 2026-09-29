class_name StoryDevPanel
extends Control

signal preset_requested(preset_id: String)
signal spawn_101_requested
signal close_requested

const StoryDevPresetsClass = preload("res://scripts/story_dev_presets.gd")


func _ready() -> void:
	name = "StoryDevPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()


func open() -> void:
	visible = true
	move_to_front()


func close() -> void:
	visible = false
	close_requested.emit()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.035, 0.03, 0.025, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(44, 72)
	panel.size = Vector2(488, 880)
	panel.add_theme_stylebox_override("panel", _box(Color("#f7e8c7"), Color("#8f633b"), 26, 4))
	add_child(panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 11)
	panel.add_child(content)

	var title := Label.new()
	title.text = "開発用：ストーリージャンプ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("#54351f"))
	content.add_child(title)

	var note := Label.new()
	note.text = "選択地点の進行状態を構築し、通常のトリガーへ接続します。"
	note.custom_minimum_size = Vector2(430, 52)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color("#76513b"))
	content.add_child(note)

	for option in StoryDevPresetsClass.options():
		var preset_id := str(option.get("id", ""))
		var button := _button(
			str(option.get("label", preset_id)),
			"StoryPreset_%s" % preset_id,
			Color("#c7d6ad")
		)
		button.pressed.connect(_emit_preset.bind(preset_id))
		content.add_child(button)

	var divider := HSeparator.new()
	divider.custom_minimum_size = Vector2(410, 12)
	content.add_child(divider)
	var spawn_button := _button("101cmコロラータ生成", "StoryDevSpawn101", Color("#d9c27d"))
	spawn_button.pressed.connect(func(): spawn_101_requested.emit())
	content.add_child(spawn_button)

	var close_button := _button("閉じる", "StoryDevClose", Color("#ead8b1"))
	close_button.pressed.connect(close)
	content.add_child(close_button)


func _emit_preset(preset_id: String) -> void:
	preset_requested.emit(preset_id)


func _button(text_value: String, node_name: String, background: Color) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text_value
	button.custom_minimum_size = Vector2(390, 58)
	button.add_theme_font_size_override("font_size", 17)
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
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style
