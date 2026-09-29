class_name HabitatRestorationUI
extends Control

signal return_decided(accepted: bool)
signal slides_finished
signal thank_you_closed

const Localizer = preload("res://scripts/game_localizer.gd")
const DialoguePortraitsClass = preload("res://scripts/dialogue_portraits.gd")
const REQUIRED_PLANTS := 5
const LAMP_PANEL_POSITION := Vector2(93, 772)

var language_code := "ja"
var lamp_panel: PanelContainer
var lamp_title: Label
var lamp_labels: Array[Label] = []
var prompt_layer: Control
var prompt_title: Label
var prompt_detail: Label
var prompt_yes: Button
var prompt_no: Button
var ending_layer: Control
var ending_background: TextureRect
var ending_title: Label
var ending_body: Label
var ending_continue: Button
var character_row: HBoxContainer
var slide_index := -1
var current_snapshot: Dictionary = {}
var decision_sent := false


func _ready() -> void:
	name = "HabitatRestorationUI"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 950
	_build_lamps()
	_build_prompt()
	_build_ending()


func _panel_style(background: Color, border: Color, radius := 20, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


func _build_lamps() -> void:
	lamp_panel = PanelContainer.new()
	lamp_panel.name = "HabitatRestorationLamps"
	# Keep the final-chapter progress clear of both the lower-right record card
	# and the persistent arrangement swipe hint at the screen edge.
	lamp_panel.position = LAMP_PANEL_POSITION
	lamp_panel.size = Vector2(390, 82)
	lamp_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lamp_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.20, 0.16, 0.93), Color("#bde8b0"), 22, 2))
	add_child(lamp_panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 3)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lamp_panel.add_child(column)
	lamp_title = Label.new()
	lamp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lamp_title.add_theme_font_size_override("font_size", 15)
	lamp_title.add_theme_color_override("font_color", Color("#efffe9"))
	lamp_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(lamp_title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 19)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	for index in REQUIRED_PLANTS:
		var lamp := Label.new()
		lamp.name = "RestorationLamp%d" % (index + 1)
		lamp.text = "○"
		lamp.add_theme_font_size_override("font_size", 29)
		lamp.add_theme_color_override("font_color", Color("#82988a"))
		lamp.add_theme_color_override("font_outline_color", Color("#243b2d"))
		lamp.add_theme_constant_override("outline_size", 3)
		lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lamp)
		lamp_labels.append(lamp)
	lamp_panel.visible = false


func _build_prompt() -> void:
	prompt_layer = Control.new()
	prompt_layer.name = "RestorationReturnPrompt"
	prompt_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prompt_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(prompt_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.04, 0.035, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	prompt_layer.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(58, 318)
	panel.size = Vector2(460, 360)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#f4ead0"), Color("#75a377"), 28, 4))
	prompt_layer.add_child(panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)
	prompt_title = Label.new()
	prompt_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_title.add_theme_font_size_override("font_size", 25)
	prompt_title.add_theme_color_override("font_color", Color("#38251b"))
	content.add_child(prompt_title)
	prompt_detail = Label.new()
	prompt_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_detail.add_theme_font_size_override("font_size", 22)
	prompt_detail.add_theme_color_override("font_color", Color("#416148"))
	content.add_child(prompt_detail)
	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 22)
	content.add_child(button_row)
	prompt_no = Button.new()
	prompt_no.custom_minimum_size = Vector2(150, 64)
	prompt_no.pressed.connect(_decide.bind(false))
	button_row.add_child(prompt_no)
	prompt_yes = Button.new()
	prompt_yes.custom_minimum_size = Vector2(150, 64)
	prompt_yes.pressed.connect(_decide.bind(true))
	button_row.add_child(prompt_yes)
	prompt_layer.visible = false


func _build_ending() -> void:
	ending_layer = Control.new()
	ending_layer.name = "RestorationEndingOverlay"
	ending_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ending_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ending_layer)
	ending_background = TextureRect.new()
	ending_background.texture = load("res://assets/highland-panorama.jpg")
	ending_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ending_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ending_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ending_background.modulate = Color(1.05, 1.08, 1.0, 1.0)
	ending_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_layer.add_child(ending_background)
	var wash := ColorRect.new()
	wash.color = Color(0.95, 0.87, 0.63, 0.38)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_layer.add_child(wash)
	var card := PanelContainer.new()
	card.position = Vector2(38, 78)
	card.size = Vector2(500, 818)
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.18, 0.13, 0.84), Color("#f3df9d"), 30, 3))
	ending_layer.add_child(card)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 20)
	card.add_child(content)
	ending_title = Label.new()
	ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_title.add_theme_font_size_override("font_size", 31)
	ending_title.add_theme_color_override("font_color", Color("#fff3bd"))
	content.add_child(ending_title)
	ending_body = Label.new()
	ending_body.custom_minimum_size = Vector2(440, 220)
	ending_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ending_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_body.add_theme_font_size_override("font_size", 23)
	ending_body.add_theme_color_override("font_color", Color.WHITE)
	content.add_child(ending_body)
	character_row = HBoxContainer.new()
	character_row.custom_minimum_size = Vector2(440, 300)
	character_row.alignment = BoxContainer.ALIGNMENT_CENTER
	character_row.add_theme_constant_override("separation", -12)
	content.add_child(character_row)
	ending_continue = Button.new()
	ending_continue.custom_minimum_size = Vector2(300, 68)
	ending_continue.pressed.connect(_advance_ending)
	content.add_child(ending_continue)
	ending_layer.visible = false


func set_language(value: String) -> void:
	language_code = Localizer.normalize_language(value)
	lamp_title.text = Localizer.text(language_code, "restoration_lamp_title")
	prompt_yes.text = Localizer.text(language_code, "yes")
	prompt_no.text = Localizer.text(language_code, "no")


func update_lamps(count: int, should_show: bool) -> void:
	lamp_panel.visible = should_show and not prompt_layer.visible and not ending_layer.visible
	for index in lamp_labels.size():
		var lit := index < count
		lamp_labels[index].text = "●" if lit else "○"
		lamp_labels[index].add_theme_color_override("font_color", Color("#8ff29b") if lit else Color("#82988a"))


func show_return_prompt(snapshot: Dictionary) -> void:
	if prompt_layer.visible or ending_layer.visible:
		return
	current_snapshot = snapshot.duplicate(true)
	decision_sent = false
	set_language(language_code)
	prompt_title.text = Localizer.text(language_code, "restoration_return_confirm")
	prompt_detail.text = Localizer.text(language_code, "restoration_return_detail", [
		str(snapshot.get("display_name", "")), float(snapshot.get("diameter_cm", 0.0))
	])
	prompt_layer.visible = true
	prompt_layer.move_to_front()


func _decide(accepted: bool) -> void:
	if decision_sent or not prompt_layer.visible:
		return
	decision_sent = true
	prompt_layer.visible = false
	return_decided.emit(accepted)


func is_modal_visible() -> bool:
	return prompt_layer.visible or ending_layer.visible


func reset_view() -> void:
	current_snapshot.clear()
	decision_sent = false
	slide_index = -1
	prompt_layer.visible = false
	ending_layer.visible = false
	lamp_panel.visible = false


func start_recovery_slides() -> void:
	slide_index = 0
	ending_layer.visible = true
	ending_layer.move_to_front()
	_show_slide()


func _show_slide() -> void:
	_clear_character_row()
	ending_title.text = Localizer.text(language_code, "restoration_slide_title")
	ending_body.text = Localizer.text(language_code, "restoration_slide_%d" % (slide_index + 1))
	ending_continue.text = Localizer.text(language_code, "continue")
	var speakers: Array = [["girl", "panda", "armadillo"], ["panda", "armadillo", "mouse", "peccary", "skunk"], ["girl", "panda", "armadillo", "mouse", "peccary", "skunk"]][slide_index]
	_add_characters(speakers)


func show_thank_you() -> void:
	slide_index = 99
	ending_layer.visible = true
	ending_layer.move_to_front()
	ending_title.text = Localizer.text(language_code, "restoration_thank_you")
	ending_body.text = Localizer.text(language_code, "restoration_product_by")
	ending_continue.text = Localizer.text(language_code, "restoration_return_to_game")
	_clear_character_row()
	_add_characters(["girl", "panda", "armadillo", "mouse", "peccary", "skunk"])


func _advance_ending() -> void:
	if slide_index >= 0 and slide_index < 2:
		slide_index += 1
		_show_slide()
		return
	ending_layer.visible = false
	if slide_index == 2:
		slides_finished.emit()
	elif slide_index == 99:
		thank_you_closed.emit()
	slide_index = -1


func _clear_character_row() -> void:
	for child in character_row.get_children():
		child.queue_free()


func _add_characters(speakers: Array) -> void:
	for speaker_value in speakers:
		var speaker := str(speaker_value)
		var texture: Texture2D = null
		match speaker:
			"mouse": texture = load("res://assets/jurejure/mouse.png")
			"peccary": texture = load("res://assets/jurejure/peccary.png")
			"skunk": texture = load("res://assets/jurejure/skunk.png")
			_: texture = DialoguePortraitsClass.texture(speaker)
		if texture == null:
			continue
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(82, 280)
		portrait.texture = texture
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		character_row.add_child(portrait)
