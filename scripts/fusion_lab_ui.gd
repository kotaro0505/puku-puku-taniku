class_name FusionLabUI
extends Control

signal close_requested
signal parent_selected(slot: int, species_id: String)
signal fuse_requested(parent_a_id: String, parent_b_id: String)
signal candidate_image_requested(entry: Dictionary, target: TextureRect, high_priority: bool)

const Localizer = preload("res://scripts/game_localizer.gd")
const UI_BROWN := Color("#4a2618")
const HYBRID_LAB_BACKGROUND_PATH := "res://assets/fusion/hybrid-lab-background.jpg"
# One particle keeps the exact pre-revision travel/fade timing.  Extending the
# emission to three waves makes the energy keep flowing for roughly three times
# as long without turning any individual mote into slow motion.
const ENERGY_WAVE_COUNT := 3
const ENERGY_PARTICLES_PER_WAVE := 8
const ENERGY_PARTICLE_TRAVEL_SECONDS := 0.42
const ENERGY_PARTICLE_FADE_SECONDS := 0.18
const ENERGY_PARTICLE_STAGGER_SECONDS := 0.035
const SERIES_LABELS := {
	"ja": {
		"gummy": "グミ", "metal": "金属", "sweets": "スイーツ", "glow": "蓄光", "jewel": "宝石",
		"jure": "ジュレジュレ団", "stone": "ストーン", "sea": "海", "yumekawa": "ゆめふわ", "forest_amber": "森と琥珀", "jelly": "ゼリー",
	},
	"hiragana": {
		"gummy": "ぐみ", "metal": "きんぞく", "sweets": "すいーつ", "glow": "ちっこう", "jewel": "ほうせき",
		"jure": "じゅれじゅれだん", "stone": "すとーん", "sea": "うみ", "yumekawa": "ゆめふわ", "forest_amber": "もりと こはく", "jelly": "ぜりー",
	},
	"en": {
		"gummy": "Gummy", "metal": "Metal", "sweets": "Sweets", "glow": "Glow", "jewel": "Jewel",
		"jure": "JureJure Gang", "stone": "Stone", "sea": "Sea", "yumekawa": "Dreamy", "forest_amber": "Forest & Amber", "jelly": "Jelly",
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
var parent_a_image: TextureRect
var parent_b_image: TextureRect
var parent_a_name_label: Label
var parent_b_name_label: Label
var result_image: TextureRect
var result_name_label: Label
var result_status_label: Label
var result_new_label: Label
var fusion_cost_label: Label
var fuse_button: Button
var back_button: Button
var picker_page: Control
var picker_title_label: Label
var picker_back_button: Button
var picker_scroll: ScrollContainer
var picker_grid: GridContainer
var candidate_cards_by_id: Dictionary = {}
var candidate_images_by_id: Dictionary = {}
var candidate_name_labels_by_id: Dictionary = {}
var candidate_selected_badges_by_id: Dictionary = {}
var current_cost := 1
var fusion_processing := false
var result_revealed := false
var silhouette_material: ShaderMaterial
var background_image: TextureRect

func _ready() -> void:
	name = "FusionLabUI"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()
	set_language(language)

func _build_ui() -> void:
	background_image = TextureRect.new()
	background_image.name = "HybridLabBackground"
	background_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_image.texture = load(HYBRID_LAB_BACKGROUND_PATH)
	background_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_image.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background_image)

	title_label = Label.new()
	title_label.position = Vector2(102, 178)
	title_label.size = Vector2(330, 52)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 27)
	title_label.add_theme_color_override("font_color", UI_BROWN)
	title_label.add_theme_color_override("font_outline_color", Color("#fff5db"))
	title_label.add_theme_constant_override("outline_size", 3)
	add_child(title_label)

	close_button = Button.new()
	close_button.position = Vector2(447, 181)
	close_button.size = Vector2(72, 44)
	_skin_button(close_button, Color("#ead8b1"), 16)
	close_button.pressed.connect(func(): close_requested.emit())
	add_child(close_button)

	main_page = Control.new()
	main_page.position = Vector2(46, 230)
	main_page.size = Vector2(484, 520)
	main_page.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(main_page)
	_build_main_page()

	picker_page = Control.new()
	picker_page.position = Vector2(46, 230)
	picker_page.size = Vector2(484, 532)
	picker_page.mouse_filter = Control.MOUSE_FILTER_PASS
	picker_page.visible = false
	add_child(picker_page)
	_build_picker_page()

func _build_main_page() -> void:
	instruction_label = Label.new()
	instruction_label.position = Vector2(8, 0)
	instruction_label.size = Vector2(468, 56)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.add_theme_font_size_override("font_size", 14)
	instruction_label.add_theme_color_override("font_color", Color("#674431"))
	main_page.add_child(instruction_label)

	parent_a_button = Button.new()
	parent_a_button.position = Vector2(2, 54)
	parent_a_button.size = Vector2(140, 210)
	_skin_button(parent_a_button, Color("#d8ece5"), 16)
	parent_a_button.pressed.connect(_open_picker.bind(0))
	main_page.add_child(parent_a_button)
	var parent_a_heading := Label.new()
	parent_a_heading.name = "ParentAHeading"
	parent_a_heading.position = Vector2(8, 7)
	parent_a_heading.size = Vector2(124, 27)
	parent_a_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent_a_heading.add_theme_font_size_override("font_size", 15)
	parent_a_heading.add_theme_color_override("font_color", UI_BROWN)
	parent_a_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_a_button.add_child(parent_a_heading)
	parent_a_image = TextureRect.new()
	parent_a_image.name = "ParentAImage"
	parent_a_image.position = Vector2(8, 34)
	parent_a_image.size = Vector2(124, 120)
	parent_a_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	parent_a_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent_a_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_a_button.add_child(parent_a_image)
	parent_a_name_label = Label.new()
	parent_a_name_label.position = Vector2(8, 156)
	parent_a_name_label.size = Vector2(124, 46)
	parent_a_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent_a_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent_a_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent_a_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent_a_name_label.add_theme_font_size_override("font_size", 13)
	parent_a_name_label.add_theme_color_override("font_color", UI_BROWN)
	parent_a_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_a_button.add_child(parent_a_name_label)

	parent_b_button = Button.new()
	parent_b_button.position = Vector2(342, 54)
	parent_b_button.size = Vector2(140, 210)
	_skin_button(parent_b_button, Color("#f0dbe5"), 16)
	parent_b_button.pressed.connect(_open_picker.bind(1))
	main_page.add_child(parent_b_button)
	var parent_b_heading := Label.new()
	parent_b_heading.name = "ParentBHeading"
	parent_b_heading.position = Vector2(8, 7)
	parent_b_heading.size = Vector2(124, 27)
	parent_b_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent_b_heading.add_theme_font_size_override("font_size", 15)
	parent_b_heading.add_theme_color_override("font_color", UI_BROWN)
	parent_b_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_b_button.add_child(parent_b_heading)
	parent_b_image = TextureRect.new()
	parent_b_image.name = "ParentBImage"
	parent_b_image.position = Vector2(8, 34)
	parent_b_image.size = Vector2(124, 120)
	parent_b_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	parent_b_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent_b_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_b_button.add_child(parent_b_image)
	parent_b_name_label = Label.new()
	parent_b_name_label.position = Vector2(8, 156)
	parent_b_name_label.size = Vector2(124, 46)
	parent_b_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent_b_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent_b_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent_b_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent_b_name_label.add_theme_font_size_override("font_size", 13)
	parent_b_name_label.add_theme_color_override("font_color", UI_BROWN)
	parent_b_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_b_button.add_child(parent_b_name_label)

	for marker_data in [{"x": 137.0, "text": "→"}, {"x": 327.0, "text": "←"}]:
		var inward_marker := Label.new()
		inward_marker.text = str(marker_data["text"])
		inward_marker.position = Vector2(float(marker_data["x"]), 142)
		inward_marker.size = Vector2(20, 40)
		inward_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inward_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		inward_marker.add_theme_font_size_override("font_size", 18)
		inward_marker.add_theme_color_override("font_color", Color("#9a6949"))
		main_page.add_child(inward_marker)

	var result_frame := PanelContainer.new()
	result_frame.position = Vector2(154, 44)
	result_frame.size = Vector2(176, 238)
	var result_style := _box(Color("#241c27"), Color("#e0bc72"), 25, 3)
	result_style.shadow_color = Color(0.4, 0.2, 0.5, 0.3)
	result_style.shadow_size = 8
	result_frame.add_theme_stylebox_override("panel", result_style)
	main_page.add_child(result_frame)
	var result_content := Control.new()
	result_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_frame.add_child(result_content)
	result_image = TextureRect.new()
	result_image.position = Vector2(9, 12)
	result_image.size = Vector2(158, 166)
	result_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_image.pivot_offset = result_image.size * 0.5
	result_content.add_child(result_image)
	silhouette_material = create_silhouette_material()

	result_name_label = Label.new()
	result_name_label.position = Vector2(8, 178)
	result_name_label.size = Vector2(160, 50)
	result_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result_name_label.add_theme_font_size_override("font_size", 16)
	result_name_label.add_theme_color_override("font_color", Color("#fff2d0"))
	result_content.add_child(result_name_label)
	result_new_label = Label.new()
	result_new_label.text = "NEW"
	result_new_label.position = Vector2(105, 13)
	result_new_label.size = Vector2(58, 30)
	result_new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_new_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_new_label.add_theme_font_size_override("font_size", 15)
	result_new_label.add_theme_color_override("font_color", Color.WHITE)
	result_new_label.add_theme_stylebox_override("normal", _box(Color("#d36077"), Color("#ffe9a8"), 14, 2))
	result_new_label.visible = false
	result_content.add_child(result_new_label)

	result_status_label = Label.new()
	result_status_label.position = Vector2(18, 290)
	result_status_label.size = Vector2(448, 54)
	result_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_status_label.add_theme_font_size_override("font_size", 15)
	result_status_label.add_theme_color_override("font_color", Color("#7b4d38"))
	main_page.add_child(result_status_label)

	fusion_cost_label = Label.new()
	fusion_cost_label.position = Vector2(92, 348)
	fusion_cost_label.size = Vector2(300, 44)
	fusion_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fusion_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fusion_cost_label.add_theme_font_size_override("font_size", 21)
	fusion_cost_label.add_theme_color_override("font_color", Color("#845021"))
	main_page.add_child(fusion_cost_label)

	fuse_button = Button.new()
	fuse_button.position = Vector2(62, 398)
	fuse_button.size = Vector2(360, 64)
	_skin_button(fuse_button, Color("#d69a45"), 22)
	fuse_button.pressed.connect(_request_fusion)
	main_page.add_child(fuse_button)

	back_button = Button.new()
	back_button.position = Vector2(132, 470)
	back_button.size = Vector2(220, 48)
	_skin_button(back_button, Color("#ead8b1"), 18)
	back_button.pressed.connect(_back_to_parent_selection)
	main_page.add_child(back_button)

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
	picker_scroll.size = Vector2(475, 466)
	picker_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	picker_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	picker_scroll.scroll_deadzone = 12
	picker_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	picker_page.add_child(picker_scroll)
	picker_grid = GridContainer.new()
	picker_grid.columns = 2
	picker_grid.custom_minimum_size = Vector2(452, 0)
	picker_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker_grid.mouse_filter = Control.MOUSE_FILTER_PASS
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
	current_cost = 1
	result_revealed = false
	result_image.texture = null
	result_image.material = null
	result_new_label.visible = false
	set_processing_state(false)
	visible = true
	_show_main_page()
	refresh_selection(selected_a_id, selected_b_id, {}, false)

func close_lab() -> void:
	visible = false
	result_image.texture = null
	result_image.material = null
	result_image.modulate = Color.WHITE
	result_image.scale = Vector2.ONE
	result_new_label.visible = false
	set_processing_state(false)
	current_result = {}

func set_language(value: String) -> void:
	language = Localizer.normalize_language(value)
	if title_label == null:
		return
	title_label.text = Localizer.text(language, "fusion_title")
	close_button.text = Localizer.text(language, "close")
	instruction_label.text = Localizer.text(language, "fusion_owned_hint")
	fuse_button.text = Localizer.text(language, "fusion_fuse")
	back_button.text = Localizer.text(language, "back")
	picker_back_button.text = Localizer.text(language, "back")
	var parent_a_heading := parent_a_button.find_child("ParentAHeading", true, false) as Label
	var parent_b_heading := parent_b_button.find_child("ParentBHeading", true, false) as Label
	if parent_a_heading:
		parent_a_heading.text = Localizer.text(language, "fusion_parent_a")
	if parent_b_heading:
		parent_b_heading.text = Localizer.text(language, "fusion_parent_b")
	result_new_label.text = Localizer.text(language, "fusion_new")
	refresh_selection(selected_a_id, selected_b_id, current_result, current_result_is_new)
	if picker_page.visible:
		_rebuild_picker()

func refresh_selection(parent_a_id: String, parent_b_id: String, result: Dictionary, is_new: bool) -> void:
	selected_a_id = parent_a_id
	selected_b_id = parent_b_id
	current_result = result.duplicate(true)
	current_result_is_new = is_new
	current_cost = maxi(1, int(current_result.get("fusion_cost_puku", 1)))
	result_revealed = false
	if parent_a_button == null:
		return
	_refresh_parent_card(0, selected_a_id)
	_refresh_parent_card(1, selected_b_id)
	fusion_cost_label.text = Localizer.text(language, "fusion_cost", [current_cost])
	result_new_label.visible = false
	var result_entry: Dictionary = current_result.get("result_entry", {})
	if result_entry.is_empty():
		result_image.texture = null
		result_image.material = null
		result_name_label.text = Localizer.text(language, "fusion_result_unknown")
		result_status_label.text = Localizer.text(language, "fusion_result_hint")
		fuse_button.disabled = true
	else:
		result_name_label.text = Localizer.species_name(language, result_entry)
		result_status_label.text = Localizer.text(language, "fusion_result_new" if is_new else "fusion_result_known")
		result_image.material = silhouette_material if is_new else null
		fuse_button.disabled = fusion_processing or not is_new

func set_result_texture(texture: Texture2D) -> void:
	if result_image:
		result_image.texture = texture
		result_image.material = silhouette_material if current_result_is_new and not result_revealed else null

func show_error(message: String) -> void:
	if result_status_label:
		result_status_label.text = message

func set_processing_state(value: bool) -> void:
	fusion_processing = value
	if close_button:
		close_button.disabled = value
	if parent_a_button:
		parent_a_button.disabled = value
	if parent_b_button:
		parent_b_button.disabled = value
	if back_button:
		back_button.disabled = value
	if fuse_button:
		fuse_button.disabled = value or current_result.is_empty() or not current_result_is_new

func play_fusion_reveal(texture: Texture2D, is_new: bool) -> void:
	set_processing_state(true)
	result_revealed = false
	result_new_label.visible = false
	if texture:
		result_image.texture = texture
	result_image.material = silhouette_material if is_new else null
	result_image.modulate = Color(1, 1, 1, 0)
	result_image.scale = Vector2.ONE
	parent_a_button.pivot_offset = parent_a_button.size * 0.5
	parent_b_button.pivot_offset = parent_b_button.size * 0.5
	var parent_in := create_tween().set_parallel(true)
	parent_in.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	parent_in.tween_property(parent_a_button, "scale", Vector2(1.04, 1.04), 0.18)
	parent_in.tween_property(parent_b_button, "scale", Vector2(1.04, 1.04), 0.18)
	await parent_in.finished
	var parent_out := create_tween().set_parallel(true)
	parent_out.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	parent_out.tween_property(parent_a_button, "scale", Vector2.ONE, 0.18)
	parent_out.tween_property(parent_b_button, "scale", Vector2.ONE, 0.18)
	await parent_out.finished

	var result_center := result_image.global_position - main_page.global_position + result_image.size * 0.5
	for _wave_index in range(ENERGY_WAVE_COUNT):
		await _play_energy_gather_wave(result_center)

	result_revealed = true
	result_image.material = null
	result_image.scale = Vector2(0.92, 0.92)
	if is_new:
		result_new_label.visible = true
		result_new_label.modulate = Color(1, 1, 1, 0)
	var reveal := create_tween().set_parallel(true)
	reveal.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal.tween_property(result_image, "modulate:a", 1.0, 0.28)
	reveal.tween_property(result_image, "scale", Vector2(1.06, 1.06), 0.28)
	if is_new:
		reveal.tween_property(result_new_label, "modulate:a", 1.0, 0.22).set_delay(0.08)
	await reveal.finished
	var settle := create_tween()
	settle.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	settle.tween_property(result_image, "scale", Vector2.ONE, 0.18)
	await settle.finished
	await get_tree().create_timer(0.18).timeout

func _play_energy_gather_wave(result_center: Vector2) -> void:
	var particles: Array[ColorRect] = []
	var gather := create_tween().set_parallel(true)
	for index in range(ENERGY_PARTICLES_PER_WAVE):
		var particle := ColorRect.new()
		particle.color = Color(1.0, 0.9, 0.58, 0.88)
		particle.size = Vector2(6, 6) if index % 2 == 0 else Vector2(4, 4)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.z_index = 20
		var source_button := parent_a_button if index % 2 == 0 else parent_b_button
		particle.position = source_button.position + Vector2(source_button.size.x * 0.5, 70.0 + float((index * 23) % 100))
		main_page.add_child(particle)
		particles.append(particle)
		gather.tween_property(particle, "position", result_center - particle.size * 0.5, ENERGY_PARTICLE_TRAVEL_SECONDS).set_delay(float(index % 4) * ENERGY_PARTICLE_STAGGER_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		gather.tween_property(particle, "modulate:a", 0.0, ENERGY_PARTICLE_FADE_SECONDS).set_delay(0.30 + float(index % 4) * ENERGY_PARTICLE_STAGGER_SECONDS)
	await gather.finished
	for particle in particles:
		particle.queue_free()

func _parent_button_text(slot: int, species_id: String) -> String:
	var slot_key := "fusion_parent_a" if slot == 0 else "fusion_parent_b"
	if species_id.is_empty() or not candidate_by_id.has(species_id):
		return "%s\n%s" % [Localizer.text(language, slot_key), Localizer.text(language, "fusion_choose")]
	var entry: Dictionary = candidate_by_id[species_id]
	var series := str(entry.get("fusion_display_series", entry.get("fusion_series", "")))
	var series_names: Dictionary = SERIES_LABELS.get(language, SERIES_LABELS["ja"])
	return "%s\n%s\n[%s]" % [Localizer.text(language, slot_key), Localizer.species_name(language, entry), str(series_names.get(series, series))]

func _refresh_parent_card(slot: int, species_id: String) -> void:
	var image := parent_a_image if slot == 0 else parent_b_image
	var name_label := parent_a_name_label if slot == 0 else parent_b_name_label
	image.texture = null
	if species_id.is_empty() or not candidate_by_id.has(species_id):
		name_label.text = Localizer.text(language, "fusion_choose")
		return
	var entry: Dictionary = candidate_by_id[species_id]
	name_label.text = Localizer.species_name(language, entry)
	candidate_image_requested.emit(entry, image, true)

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
		# Let the ScrollContainer claim a touch drag after its deadzone. Selection
		# remains release-only, so a swipe that began on a card is not a tap.
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.mouse_force_pass_scroll_events = true
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

func _back_to_parent_selection() -> void:
	if fusion_processing:
		return
	_open_picker(1 if not selected_b_id.is_empty() else 0)

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

static func create_silhouette_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float distance_from_white = distance(tex.rgb, vec3(1.0));
	float shape_alpha = smoothstep(0.035, 0.11, distance_from_white) * tex.a;
	COLOR = vec4(vec3(0.012), shape_alpha * COLOR.a);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func _box(background: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
