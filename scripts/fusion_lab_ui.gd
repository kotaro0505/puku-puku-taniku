class_name FusionLabUI
extends Control

signal close_requested
signal parent_selected(slot: int, species_id: String)
signal fuse_requested(parent_a_id: String, parent_b_id: String)
signal candidate_image_requested(entry: Dictionary, target: TextureRect, high_priority: bool)

const Localizer = preload("res://scripts/game_localizer.gd")
const UI_BROWN := Color("#4a2618")
const SERIES_LABELS := {
	"ja": {
		"gummy": "グミ", "metal": "金属", "sweets": "スイーツ", "glow": "蓄光", "jewel": "宝石",
		"jure": "ジュレジュレ団", "stone": "ストーン", "sea": "海", "yumekawa": "ゆめふわ", "forest_amber": "森と琥珀",
	},
	"hiragana": {
		"gummy": "ぐみ", "metal": "きんぞく", "sweets": "すいーつ", "glow": "ちっこう", "jewel": "ほうせき",
		"jure": "じゅれじゅれだん", "stone": "すとーん", "sea": "うみ", "yumekawa": "ゆめふわ", "forest_amber": "もりと こはく",
	},
	"en": {
		"gummy": "Gummy", "metal": "Metal", "sweets": "Sweets", "glow": "Glow", "jewel": "Jewel",
		"jure": "JureJure Gang", "stone": "Stone", "sea": "Sea", "yumekawa": "Dreamy", "forest_amber": "Forest & Amber",
	},
}

var language := "ja"
var candidates: Array[Dictionary] = []
var candidate_by_id: Dictionary = {}
var get_counts: Dictionary = {}
var selected_a_id := ""
var selected_b_id := ""
var current_result: Dictionary = {}
var current_result_is_new := false
var picker_slot := 0

var title_label: Label
var close_button: Button
var main_page: Control
var instruction_label: Label
var parent_a_button: Button
var parent_b_button: Button
var result_image: TextureRect
var result_name_label: Label
var result_status_label: Label
var fuse_button: Button
var picker_page: Control
var picker_title_label: Label
var picker_back_button: Button
var picker_scroll: ScrollContainer
var picker_grid: GridContainer
var candidate_cards_by_id: Dictionary = {}
var candidate_images_by_id: Dictionary = {}
var candidate_name_labels_by_id: Dictionary = {}
var candidate_selected_badges_by_id: Dictionary = {}

func _ready() -> void:
	name = "FusionLabUI"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()
	set_language(language)

func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.035, 0.025, 0.045, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(24, 42)
	panel.size = Vector2(528, 940)
	panel.add_theme_stylebox_override("panel", _box(Color("#f5ead4"), Color("#a87543"), 28, 4))
	add_child(panel)

	title_label = Label.new()
	title_label.position = Vector2(95, 58)
	title_label.size = Vector2(336, 62)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 29)
	title_label.add_theme_color_override("font_color", Color("#fff1c2"))
	title_label.add_theme_color_override("font_outline_color", Color("#57311f"))
	title_label.add_theme_constant_override("outline_size", 7)
	add_child(title_label)

	close_button = Button.new()
	close_button.position = Vector2(438, 65)
	close_button.size = Vector2(94, 50)
	_skin_button(close_button, Color("#ead8b1"), 16)
	close_button.pressed.connect(func(): close_requested.emit())
	add_child(close_button)

	main_page = Control.new()
	main_page.position = Vector2(46, 124)
	main_page.size = Vector2(484, 826)
	main_page.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(main_page)
	_build_main_page()

	picker_page = Control.new()
	picker_page.position = Vector2(46, 124)
	picker_page.size = Vector2(484, 826)
	picker_page.mouse_filter = Control.MOUSE_FILTER_PASS
	picker_page.visible = false
	add_child(picker_page)
	_build_picker_page()

func _build_main_page() -> void:
	instruction_label = Label.new()
	instruction_label.position = Vector2(8, 0)
	instruction_label.size = Vector2(468, 82)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.add_theme_font_size_override("font_size", 16)
	instruction_label.add_theme_color_override("font_color", Color("#674431"))
	main_page.add_child(instruction_label)

	parent_a_button = Button.new()
	parent_a_button.position = Vector2(8, 92)
	parent_a_button.size = Vector2(218, 132)
	parent_a_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_skin_button(parent_a_button, Color("#d8ece5"), 16)
	parent_a_button.pressed.connect(_open_picker.bind(0))
	main_page.add_child(parent_a_button)

	var plus := Label.new()
	plus.text = "＋"
	plus.position = Vector2(222, 126)
	plus.size = Vector2(40, 54)
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plus.add_theme_font_size_override("font_size", 30)
	plus.add_theme_color_override("font_color", Color("#8d5c3e"))
	main_page.add_child(plus)

	parent_b_button = Button.new()
	parent_b_button.position = Vector2(258, 92)
	parent_b_button.size = Vector2(218, 132)
	parent_b_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_skin_button(parent_b_button, Color("#f0dbe5"), 16)
	parent_b_button.pressed.connect(_open_picker.bind(1))
	main_page.add_child(parent_b_button)

	var arrow := Label.new()
	arrow.text = "▼"
	arrow.position = Vector2(197, 230)
	arrow.size = Vector2(90, 42)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 25)
	arrow.add_theme_color_override("font_color", Color("#b48346"))
	main_page.add_child(arrow)

	var result_frame := PanelContainer.new()
	result_frame.position = Vector2(68, 270)
	result_frame.size = Vector2(348, 332)
	var result_style := _box(Color("#241c27"), Color("#e0bc72"), 25, 3)
	result_style.shadow_color = Color(0.4, 0.2, 0.5, 0.3)
	result_style.shadow_size = 12
	result_frame.add_theme_stylebox_override("panel", result_style)
	main_page.add_child(result_frame)
	var result_content := Control.new()
	result_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_frame.add_child(result_content)

	result_image = TextureRect.new()
	result_image.position = Vector2(16, 14)
	result_image.size = Vector2(316, 248)
	result_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_content.add_child(result_image)

	result_name_label = Label.new()
	result_name_label.position = Vector2(8, 264)
	result_name_label.size = Vector2(332, 38)
	result_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result_name_label.add_theme_font_size_override("font_size", 21)
	result_name_label.add_theme_color_override("font_color", Color("#fff2d0"))
	result_content.add_child(result_name_label)

	result_status_label = Label.new()
	result_status_label.position = Vector2(18, 616)
	result_status_label.size = Vector2(448, 54)
	result_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_status_label.add_theme_font_size_override("font_size", 16)
	result_status_label.add_theme_color_override("font_color", Color("#7b4d38"))
	main_page.add_child(result_status_label)

	fuse_button = Button.new()
	fuse_button.position = Vector2(82, 686)
	fuse_button.size = Vector2(320, 72)
	_skin_button(fuse_button, Color("#d69a45"), 22)
	fuse_button.pressed.connect(_request_fusion)
	main_page.add_child(fuse_button)

func _build_picker_page() -> void:
	picker_back_button = Button.new()
	picker_back_button.position = Vector2(4, 0)
	picker_back_button.size = Vector2(98, 48)
	_skin_button(picker_back_button, Color("#ead8b1"), 16)
	picker_back_button.pressed.connect(_show_main_page)
	picker_page.add_child(picker_back_button)

	picker_title_label = Label.new()
	picker_title_label.position = Vector2(104, 0)
	picker_title_label.size = Vector2(370, 50)
	picker_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	picker_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	picker_title_label.add_theme_font_size_override("font_size", 22)
	picker_title_label.add_theme_color_override("font_color", UI_BROWN)
	picker_page.add_child(picker_title_label)

	picker_scroll = ScrollContainer.new()
	picker_scroll.position = Vector2(3, 62)
	picker_scroll.size = Vector2(475, 744)
	picker_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	picker_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	picker_page.add_child(picker_scroll)
	picker_grid = GridContainer.new()
	picker_grid.columns = 2
	picker_grid.custom_minimum_size = Vector2(452, 0)
	picker_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker_grid.add_theme_constant_override("h_separation", 8)
	picker_grid.add_theme_constant_override("v_separation", 8)
	picker_scroll.add_child(picker_grid)

func open_lab(parent_candidates: Array[Dictionary], counts: Dictionary, parent_a_id := "", parent_b_id := "") -> void:
	candidates = parent_candidates.duplicate(true)
	get_counts = counts.duplicate(true)
	candidate_by_id.clear()
	for entry in candidates:
		candidate_by_id[str(entry.get("species_id", ""))] = entry
	selected_a_id = parent_a_id if candidate_by_id.has(parent_a_id) else ""
	selected_b_id = parent_b_id if candidate_by_id.has(parent_b_id) else ""
	current_result = {}
	current_result_is_new = false
	result_image.texture = null
	visible = true
	_show_main_page()
	refresh_selection(selected_a_id, selected_b_id, {}, false)

func close_lab() -> void:
	visible = false
	result_image.texture = null
	current_result = {}

func set_language(value: String) -> void:
	language = Localizer.normalize_language(value)
	if title_label == null:
		return
	title_label.text = Localizer.text(language, "fusion_title")
	close_button.text = Localizer.text(language, "close")
	instruction_label.text = Localizer.text(language, "fusion_owned_hint")
	fuse_button.text = Localizer.text(language, "fusion_fuse")
	picker_back_button.text = Localizer.text(language, "back")
	refresh_selection(selected_a_id, selected_b_id, current_result, current_result_is_new)
	if picker_page.visible:
		_rebuild_picker()

func refresh_selection(parent_a_id: String, parent_b_id: String, result: Dictionary, is_new: bool) -> void:
	selected_a_id = parent_a_id
	selected_b_id = parent_b_id
	current_result = result.duplicate(true)
	current_result_is_new = is_new
	if parent_a_button == null:
		return
	parent_a_button.text = _parent_button_text(0, selected_a_id)
	parent_b_button.text = _parent_button_text(1, selected_b_id)
	var result_entry: Dictionary = current_result.get("result_entry", {})
	if result_entry.is_empty():
		result_image.texture = null
		result_name_label.text = Localizer.text(language, "fusion_result_unknown")
		result_status_label.text = Localizer.text(language, "fusion_result_hint")
		fuse_button.disabled = true
	else:
		result_name_label.text = Localizer.species_name(language, result_entry)
		result_status_label.text = Localizer.text(language, "fusion_result_new" if is_new else "fusion_result_known")
		fuse_button.disabled = false

func set_result_texture(texture: Texture2D) -> void:
	if result_image:
		result_image.texture = texture

func show_error(message: String) -> void:
	if result_status_label:
		result_status_label.text = message

func _parent_button_text(slot: int, species_id: String) -> String:
	var slot_key := "fusion_parent_a" if slot == 0 else "fusion_parent_b"
	if species_id.is_empty() or not candidate_by_id.has(species_id):
		return "%s\n%s" % [Localizer.text(language, slot_key), Localizer.text(language, "fusion_choose")]
	var entry: Dictionary = candidate_by_id[species_id]
	var series := str(entry.get("fusion_series", ""))
	var series_names: Dictionary = SERIES_LABELS.get(language, SERIES_LABELS["ja"])
	return "%s\n%s\n[%s]" % [Localizer.text(language, slot_key), Localizer.species_name(language, entry), str(series_names.get(series, series))]

func _open_picker(slot: int) -> void:
	picker_slot = slot
	main_page.visible = false
	picker_page.visible = true
	_rebuild_picker()

func _rebuild_picker() -> void:
	if picker_grid == null:
		return
	for child in picker_grid.get_children():
		child.free()
	candidate_cards_by_id.clear()
	candidate_images_by_id.clear()
	candidate_name_labels_by_id.clear()
	candidate_selected_badges_by_id.clear()
	picker_title_label.text = Localizer.text(language, "fusion_select_parent", ["A" if picker_slot == 0 else "B"])
	if candidates.is_empty():
		var empty_label := Label.new()
		empty_label.text = Localizer.text(language, "fusion_no_parents")
		empty_label.custom_minimum_size = Vector2(450, 100)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_color_override("font_color", UI_BROWN)
		picker_grid.add_child(empty_label)
		return
	var selected_id := selected_a_id if picker_slot == 0 else selected_b_id
	for candidate_index in range(candidates.size()):
		var entry: Dictionary = candidates[candidate_index]
		var species_id := str(entry.get("species_id", ""))
		var species_name := Localizer.species_name(language, entry)
		var is_selected := species_id == selected_id
		var button := Button.new()
		button.name = "FusionCandidate_%s" % species_id
		button.custom_minimum_size = Vector2(222, 222)
		button.toggle_mode = true
		button.button_pressed = is_selected
		button.tooltip_text = species_name
		button.set_meta("species_id", species_id)
		button.set_meta("selected_for_slot", is_selected)
		_skin_candidate_card(button)
		button.pressed.connect(_choose_candidate.bind(species_id))
		picker_grid.add_child(button)

		var image := TextureRect.new()
		image.name = "SpeciesImage"
		image.position = Vector2(12, 10)
		image.size = Vector2(198, 144)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(image)

		var name_label := Label.new()
		name_label.name = "SpeciesName"
		name_label.text = species_name
		name_label.position = Vector2(10, 155)
		name_label.size = Vector2(202, 38)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.add_theme_color_override("font_color", UI_BROWN)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(name_label)

		var count_label := Label.new()
		count_label.name = "GetCount"
		count_label.text = Localizer.text(language, "fusion_get_count", [int(get_counts.get(species_id, 0))])
		count_label.position = Vector2(10, 193)
		count_label.size = Vector2(202, 23)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 12)
		count_label.add_theme_color_override("font_color", Color("#805f47"))
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(count_label)

		var selected_badge := Label.new()
		selected_badge.name = "SelectedBadge"
		selected_badge.text = "✓"
		selected_badge.position = Vector2(174, 10)
		selected_badge.size = Vector2(36, 36)
		selected_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		selected_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		selected_badge.add_theme_font_size_override("font_size", 23)
		selected_badge.add_theme_color_override("font_color", Color.WHITE)
		selected_badge.add_theme_stylebox_override("normal", _box(Color("#d28a28"), Color("#fff2b8"), 18, 2))
		selected_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selected_badge.visible = is_selected
		button.add_child(selected_badge)

		candidate_cards_by_id[species_id] = button
		candidate_images_by_id[species_id] = image
		candidate_name_labels_by_id[species_id] = name_label
		candidate_selected_badges_by_id[species_id] = selected_badge
		candidate_image_requested.emit(entry, image, candidate_index < 6)

func _choose_candidate(species_id: String) -> void:
	parent_selected.emit(picker_slot, species_id)
	_show_main_page()

func _show_main_page() -> void:
	main_page.visible = true
	picker_page.visible = false

func _request_fusion() -> void:
	if selected_a_id.is_empty() or selected_b_id.is_empty() or current_result.is_empty():
		return
	fuse_requested.emit(selected_a_id, selected_b_id)

func _skin_button(button: Button, background: Color, font_size: int) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", UI_BROWN if background.get_luminance() > 0.55 else Color.WHITE)
	button.add_theme_color_override("font_hover_color", UI_BROWN)
	button.add_theme_stylebox_override("normal", _box(background, background.lightened(0.18), 18, 3))
	button.add_theme_stylebox_override("hover", _box(background.lightened(0.06), Color.WHITE, 18, 3))
	button.add_theme_stylebox_override("pressed", _box(background.darkened(0.08), background.lightened(0.18), 18, 3))

func _skin_candidate_card(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _box(Color("#f6efdf"), Color("#c6aa72"), 18, 2))
	button.add_theme_stylebox_override("hover", _box(Color("#fff8e8"), Color("#e0b75a"), 18, 4))
	button.add_theme_stylebox_override("pressed", _box(Color("#fff0c7"), Color("#d28a28"), 18, 5))
	button.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), Color("#f0c66a"), 18, 3))

func _box(background: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
