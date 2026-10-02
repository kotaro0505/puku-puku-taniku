class_name HabitatRestorationUI
extends Control

signal return_decided(accepted: bool)
signal slides_finished
signal thank_you_closed
signal ending_bgm_requested
signal ending_slide_started(kind: String, index: int, payload: Dictionary)

const Localizer = preload("res://scripts/game_localizer.gd")
const DialoguePortraitsClass = preload("res://scripts/dialogue_portraits.gd")
const REQUIRED_PLANTS := 5
const LAMP_PANEL_POSITION := Vector2(93, 772)
const FINAL_IMAGE_PATH := "res://assets/ending/restoration-finale.jpg"
const ENDING_DARKEN_SECONDS := 1.1
const ENDING_SLIDE_FADE_SECONDS := 0.8
const ENDING_SLIDE_HOLD_SECONDS := 2.7
const ENDING_FINAL_IMAGE_FADE_SECONDS := 1.8
const ENDING_FINAL_IMAGE_HOLD_SECONDS := 4.0
const ENDING_THANK_YOU_FADE_SECONDS := 1.0
const ENDING_RETURN_BUTTON_DELAY_SECONDS := 1.1
const ENDING_RETURN_BUTTON_FADE_SECONDS := 0.8

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
var ending_sequence_layer: Control
var ending_record_label: Label
var ending_plant_content: Control
var ending_plant_heading: Label
var ending_plant_image: TextureRect
var ending_plant_name: Label
var ending_plant_size: Label
var ending_final_image: TextureRect
var ending_final_shade: ColorRect
var ending_final_text_group: Control
var ending_thank_you_label: Label
var ending_product_label: Label
var ending_return_button: Button
var slide_index := -1
var current_snapshot: Dictionary = {}
var decision_sent := false
var ending_records: Array[Dictionary] = []
var ending_returned_plants: Array[Dictionary] = []
var ending_texture_cache: Dictionary = {}
var ending_sequence_generation := 0
var ending_sequence_time_scale := 1.0
var ending_current_phase := ""
var ending_current_index := -1
var ending_sequence_history: Array[Dictionary] = []


func _ready() -> void:
	name = "HabitatRestorationUI"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 950
	_build_lamps()
	_build_prompt()
	_build_ending()
	_build_record_ending()


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


func _build_record_ending() -> void:
	ending_sequence_layer = Control.new()
	ending_sequence_layer.name = "RestorationRecordEnding"
	ending_sequence_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ending_sequence_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ending_sequence_layer)

	var black_background := ColorRect.new()
	black_background.color = Color.BLACK
	black_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_sequence_layer.add_child(black_background)

	ending_record_label = Label.new()
	ending_record_label.position = Vector2(38, 230)
	ending_record_label.size = Vector2(500, 520)
	ending_record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_record_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ending_record_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_record_label.add_theme_font_size_override("font_size", 32)
	ending_record_label.add_theme_color_override("font_color", Color("#fff8df"))
	ending_record_label.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.04, 0.96))
	ending_record_label.add_theme_constant_override("outline_size", 9)
	ending_record_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_sequence_layer.add_child(ending_record_label)

	ending_plant_content = Control.new()
	ending_plant_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ending_plant_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_sequence_layer.add_child(ending_plant_content)
	ending_plant_heading = Label.new()
	ending_plant_heading.position = Vector2(34, 102)
	ending_plant_heading.size = Vector2(508, 72)
	ending_plant_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_plant_heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ending_plant_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_plant_heading.add_theme_font_size_override("font_size", 25)
	ending_plant_heading.add_theme_color_override("font_color", Color("#e8ddb9"))
	ending_plant_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_plant_content.add_child(ending_plant_heading)
	ending_plant_image = TextureRect.new()
	ending_plant_image.position = Vector2(66, 182)
	ending_plant_image.size = Vector2(444, 478)
	ending_plant_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ending_plant_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ending_plant_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_plant_content.add_child(ending_plant_image)
	ending_plant_name = Label.new()
	ending_plant_name.position = Vector2(34, 692)
	ending_plant_name.size = Vector2(508, 78)
	ending_plant_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_plant_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ending_plant_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_plant_name.add_theme_font_size_override("font_size", 31)
	ending_plant_name.add_theme_color_override("font_color", Color.WHITE)
	ending_plant_name.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.04, 0.96))
	ending_plant_name.add_theme_constant_override("outline_size", 8)
	ending_plant_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_plant_content.add_child(ending_plant_name)
	ending_plant_size = Label.new()
	ending_plant_size.position = Vector2(34, 772)
	ending_plant_size.size = Vector2(508, 62)
	ending_plant_size.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_plant_size.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ending_plant_size.add_theme_font_size_override("font_size", 27)
	ending_plant_size.add_theme_color_override("font_color", Color("#ffe9aa"))
	ending_plant_size.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.04, 0.96))
	ending_plant_size.add_theme_constant_override("outline_size", 7)
	ending_plant_size.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_plant_content.add_child(ending_plant_size)

	ending_final_image = TextureRect.new()
	ending_final_image.texture = load(FINAL_IMAGE_PATH) as Texture2D
	ending_final_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ending_final_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ending_final_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ending_final_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_sequence_layer.add_child(ending_final_image)
	ending_final_shade = ColorRect.new()
	ending_final_shade.color = Color(0.015, 0.01, 0.025, 0.48)
	ending_final_shade.position = Vector2(0, 742)
	ending_final_shade.size = Vector2(576, 282)
	ending_final_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_sequence_layer.add_child(ending_final_shade)
	ending_final_text_group = Control.new()
	ending_final_text_group.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ending_final_text_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_sequence_layer.add_child(ending_final_text_group)
	ending_thank_you_label = Label.new()
	ending_thank_you_label.position = Vector2(28, 770)
	ending_thank_you_label.size = Vector2(520, 104)
	ending_thank_you_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_thank_you_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ending_thank_you_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_thank_you_label.add_theme_font_size_override("font_size", 29)
	ending_thank_you_label.add_theme_color_override("font_color", Color.WHITE)
	ending_thank_you_label.add_theme_color_override("font_outline_color", Color(0.08, 0.035, 0.02, 0.98))
	ending_thank_you_label.add_theme_constant_override("outline_size", 9)
	ending_thank_you_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_final_text_group.add_child(ending_thank_you_label)
	ending_product_label = Label.new()
	ending_product_label.position = Vector2(28, 872)
	ending_product_label.size = Vector2(520, 44)
	ending_product_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_product_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ending_product_label.add_theme_font_size_override("font_size", 18)
	ending_product_label.add_theme_color_override("font_color", Color("#fff0c5"))
	ending_product_label.add_theme_color_override("font_outline_color", Color(0.08, 0.035, 0.02, 0.98))
	ending_product_label.add_theme_constant_override("outline_size", 6)
	ending_product_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_final_text_group.add_child(ending_product_label)
	ending_return_button = Button.new()
	ending_return_button.position = Vector2(138, 932)
	ending_return_button.size = Vector2(300, 66)
	ending_return_button.add_theme_font_size_override("font_size", 22)
	ending_return_button.add_theme_color_override("font_color", Color("#fff5d4"))
	ending_return_button.add_theme_stylebox_override("normal", _panel_style(Color(0.05, 0.035, 0.06, 0.88), Color("#f0cc72"), 24, 2))
	ending_return_button.add_theme_stylebox_override("hover", _panel_style(Color(0.10, 0.065, 0.11, 0.94), Color("#ffe6a1"), 24, 3))
	ending_return_button.add_theme_stylebox_override("pressed", _panel_style(Color(0.03, 0.02, 0.04, 0.96), Color("#ddb95c"), 24, 2))
	ending_return_button.pressed.connect(_on_ending_return_pressed)
	ending_sequence_layer.add_child(ending_return_button)
	ending_sequence_layer.visible = false


func set_language(value: String) -> void:
	language_code = Localizer.normalize_language(value)
	lamp_title.text = Localizer.text(language_code, "restoration_lamp_title")
	prompt_yes.text = Localizer.text(language_code, "yes")
	prompt_no.text = Localizer.text(language_code, "no")
	if ending_thank_you_label:
		ending_thank_you_label.text = Localizer.text(language_code, "restoration_thank_you")
		ending_product_label.text = Localizer.text(language_code, "restoration_product_by")
		ending_return_button.text = Localizer.text(language_code, "restoration_return_to_game")


func update_lamps(count: int, should_show: bool) -> void:
	lamp_panel.visible = should_show and not prompt_layer.visible and not ending_layer.visible and not ending_sequence_layer.visible
	for index in lamp_labels.size():
		var lit := index < count
		lamp_labels[index].text = "●" if lit else "○"
		lamp_labels[index].add_theme_color_override("font_color", Color("#8ff29b") if lit else Color("#82988a"))


func show_return_prompt(snapshot: Dictionary) -> void:
	if prompt_layer.visible or ending_layer.visible or ending_sequence_layer.visible:
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
	return prompt_layer.visible or ending_layer.visible or ending_sequence_layer.visible


func reset_view() -> void:
	ending_sequence_generation += 1
	current_snapshot.clear()
	decision_sent = false
	slide_index = -1
	prompt_layer.visible = false
	ending_layer.visible = false
	ending_sequence_layer.visible = false
	ending_current_phase = ""
	ending_current_index = -1
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


func show_thank_you(records: Array[Dictionary] = [], returned_plants: Array[Dictionary] = []) -> void:
	start_ending_sequence(records, returned_plants)


func _advance_ending() -> void:
	if slide_index >= 0 and slide_index < 2:
		slide_index += 1
		_show_slide()
		return
	ending_layer.visible = false
	if slide_index == 2:
		slides_finished.emit()
	slide_index = -1


func start_ending_sequence(records: Array[Dictionary], returned_plants: Array[Dictionary]) -> void:
	ending_sequence_generation += 1
	var generation := ending_sequence_generation
	ending_records.clear()
	for record_value in records:
		ending_records.append(record_value.duplicate(true))
	ending_returned_plants.clear()
	for snapshot_value in returned_plants:
		ending_returned_plants.append(snapshot_value.duplicate(true))
	ending_texture_cache.clear()
	ending_sequence_history.clear()
	ending_current_phase = "darkening"
	ending_current_index = -1
	set_language(language_code)
	prompt_layer.visible = false
	ending_layer.visible = false
	lamp_panel.visible = false
	ending_record_label.visible = false
	ending_plant_content.visible = false
	ending_final_image.visible = false
	ending_final_shade.visible = false
	ending_final_text_group.visible = false
	ending_return_button.visible = false
	ending_return_button.disabled = true
	ending_sequence_layer.modulate.a = 0.0
	ending_sequence_layer.visible = true
	ending_sequence_layer.move_to_front()
	_prefetch_ending_plant_textures()
	call_deferred("_run_ending_sequence", generation)


func _prefetch_ending_plant_textures() -> void:
	for snapshot in ending_returned_plants:
		var path := str(snapshot.get("image_path", ""))
		if path.is_empty() or ending_texture_cache.has(path):
			continue
		var immediate := CatalogImageLoader.get_texture(path)
		ending_texture_cache[path] = immediate if immediate != null else CatalogImageLoader.placeholder_texture
		CatalogImageLoader.request_texture(path, _on_ending_plant_texture_loaded.bind(path), true)


func _on_ending_plant_texture_loaded(texture: Texture2D, path: String) -> void:
	ending_texture_cache[path] = texture if texture != null else CatalogImageLoader.placeholder_texture
	if ending_current_phase != "plant" or ending_current_index < 0 or ending_current_index >= ending_returned_plants.size():
		return
	var current_path := str(ending_returned_plants[ending_current_index].get("image_path", ""))
	if current_path == path:
		ending_plant_image.texture = ending_texture_cache[path] as Texture2D


func _run_ending_sequence(generation: int) -> void:
	var darken := create_tween()
	darken.tween_property(ending_sequence_layer, "modulate:a", 1.0, _ending_duration(ENDING_DARKEN_SECONDS)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await darken.finished
	if generation != ending_sequence_generation:
		return
	for index in ending_records.size():
		ending_current_phase = "record"
		ending_current_index = index
		var record := ending_records[index]
		ending_record_label.text = str(record.get("text", ""))
		ending_record_label.modulate.a = 0.0
		ending_record_label.visible = true
		_record_ending_slide("record", index, record)
		if index == 0:
			# This signal is synchronous. The BGM starts at 0:00 in the same frame
			# that the first record begins its visual fade-in.
			ending_bgm_requested.emit()
		await _fade_hold_fade(ending_record_label)
		ending_record_label.visible = false
		if generation != ending_sequence_generation:
			return
	for index in ending_returned_plants.size():
		ending_current_phase = "plant"
		ending_current_index = index
		var snapshot := ending_returned_plants[index]
		ending_plant_heading.text = str(snapshot.get("heading", ""))
		ending_plant_name.text = str(snapshot.get("display_name", snapshot.get("species_id", "")))
		ending_plant_size.text = "%scm" % str(snapshot.get("diameter_text", "0"))
		var image_path := str(snapshot.get("image_path", ""))
		var image_texture: Texture2D = ending_texture_cache.get(image_path, CatalogImageLoader.get_texture(image_path)) as Texture2D
		ending_plant_image.texture = image_texture if image_texture != null else CatalogImageLoader.placeholder_texture
		ending_plant_content.modulate.a = 0.0
		ending_plant_content.visible = true
		_record_ending_slide("plant", index, snapshot)
		await _fade_hold_fade(ending_plant_content)
		ending_plant_content.visible = false
		if generation != ending_sequence_generation:
			return
	ending_current_phase = "final_black"
	ending_current_index = -1
	_record_ending_slide("black", 0, {})
	await get_tree().create_timer(_ending_duration(0.45)).timeout
	if generation != ending_sequence_generation:
		return
	ending_current_phase = "final_image"
	ending_final_image.modulate.a = 0.0
	ending_final_image.visible = true
	_record_ending_slide("final_image", 0, {"image_path": FINAL_IMAGE_PATH})
	var image_fade := create_tween()
	image_fade.tween_property(ending_final_image, "modulate:a", 1.0, _ending_duration(ENDING_FINAL_IMAGE_FADE_SECONDS)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await image_fade.finished
	if generation != ending_sequence_generation:
		return
	await get_tree().create_timer(_ending_duration(ENDING_FINAL_IMAGE_HOLD_SECONDS)).timeout
	if generation != ending_sequence_generation:
		return
	ending_current_phase = "thank_you"
	ending_final_shade.modulate.a = 0.0
	ending_final_shade.visible = true
	ending_final_text_group.modulate.a = 0.0
	ending_final_text_group.visible = true
	_record_ending_slide("thank_you", 0, {})
	var text_fade := create_tween().set_parallel()
	text_fade.tween_property(ending_final_shade, "modulate:a", 1.0, _ending_duration(ENDING_THANK_YOU_FADE_SECONDS)).set_trans(Tween.TRANS_SINE)
	text_fade.tween_property(ending_final_text_group, "modulate:a", 1.0, _ending_duration(ENDING_THANK_YOU_FADE_SECONDS)).set_trans(Tween.TRANS_SINE)
	await text_fade.finished
	if generation != ending_sequence_generation:
		return
	await get_tree().create_timer(_ending_duration(ENDING_RETURN_BUTTON_DELAY_SECONDS)).timeout
	if generation != ending_sequence_generation:
		return
	ending_current_phase = "return_button"
	ending_return_button.modulate.a = 0.0
	ending_return_button.visible = true
	_record_ending_slide("return_button", 0, {})
	var button_fade := create_tween()
	button_fade.tween_property(ending_return_button, "modulate:a", 1.0, _ending_duration(ENDING_RETURN_BUTTON_FADE_SECONDS)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await button_fade.finished
	if generation != ending_sequence_generation:
		return
	ending_return_button.disabled = false
	ending_current_phase = "await_return"


func _fade_hold_fade(control: Control) -> void:
	var fade_in := create_tween()
	fade_in.tween_property(control, "modulate:a", 1.0, _ending_duration(ENDING_SLIDE_FADE_SECONDS)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_in.finished
	await get_tree().create_timer(_ending_duration(ENDING_SLIDE_HOLD_SECONDS)).timeout
	var fade_out := create_tween()
	fade_out.tween_property(control, "modulate:a", 0.0, _ending_duration(ENDING_SLIDE_FADE_SECONDS)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_out.finished


func _record_ending_slide(kind: String, index: int, payload: Dictionary) -> void:
	var event := {"kind": kind, "index": index, "payload": payload.duplicate(true)}
	ending_sequence_history.append(event)
	ending_slide_started.emit(kind, index, payload.duplicate(true))


func _ending_duration(seconds: float) -> float:
	return maxf(0.001, seconds * maxf(0.001, ending_sequence_time_scale))


func _on_ending_return_pressed() -> void:
	if ending_current_phase != "await_return" or ending_return_button.disabled:
		return
	ending_return_button.disabled = true
	thank_you_closed.emit()


func fade_out_ending_sequence(duration_seconds := 1.2) -> void:
	if not ending_sequence_layer.visible:
		return
	ending_sequence_generation += 1
	var fade := create_tween()
	fade.tween_property(ending_sequence_layer, "modulate:a", 0.0, maxf(0.01, duration_seconds)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade.finished
	ending_sequence_layer.visible = false
	ending_current_phase = ""
	ending_current_index = -1


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
