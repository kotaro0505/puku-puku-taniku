class_name OpeningStoryOverlay
extends Control

signal story_finished(replay_mode: bool)

const Localizer = preload("res://scripts/game_localizer.gd")

const PAGE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/opening_story/page-1.jpg"),
	preload("res://assets/opening_story/page-2.jpg"),
	preload("res://assets/opening_story/page-3.jpg"),
	preload("res://assets/opening_story/page-4.jpg")
]
const PAGE_TEXT_KEYS := ["opening_story_1", "opening_story_2", "opening_story_3", "opening_story_4"]
const PAGE_FONT_SIZES := [20, 20, 20, 20]

var current_page_index := -1
var replay_mode := false
var transitioning := false
var page_image: TextureRect
var text_panel: Panel
var story_text: Label
var page_count_label: Label
var tap_area: Button
var page_tween: Tween
var tap_hint: Label
var language_code := "ja"

func _ready() -> void:
	name = "OpeningStoryOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 900
	_build_ui()
	visible = false

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#1b100c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	page_image = TextureRect.new()
	page_image.name = "StoryImage"
	page_image.position = Vector2.ZERO
	page_image.size = Vector2(576, 768)
	page_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	page_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	page_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page_image)

	text_panel = Panel.new()
	text_panel.name = "StoryTextPanel"
	text_panel.position = Vector2(14, 586)
	text_panel.size = Vector2(548, 414)
	text_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.105, 0.055, 0.035, 0.92)
	panel_style.border_color = Color(0.89, 0.68, 0.39, 0.48)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(24)
	panel_style.shadow_color = Color(0.04, 0.02, 0.01, 0.35)
	panel_style.shadow_size = 8
	text_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(text_panel)

	story_text = Label.new()
	story_text.name = "StoryText"
	story_text.position = Vector2(24, 600)
	story_text.size = Vector2(528, 346)
	story_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_text.add_theme_color_override("font_color", Color("#fff6df"))
	story_text.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	story_text.add_theme_constant_override("shadow_offset_x", 1)
	story_text.add_theme_constant_override("shadow_offset_y", 2)
	story_text.add_theme_constant_override("line_spacing", 1)
	story_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(story_text)

	page_count_label = Label.new()
	page_count_label.name = "StoryPageCount"
	page_count_label.position = Vector2(454, 24)
	page_count_label.size = Vector2(90, 38)
	page_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	page_count_label.add_theme_font_size_override("font_size", 15)
	page_count_label.add_theme_color_override("font_color", Color("#fff4da"))
	page_count_label.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.03, 0.82))
	page_count_label.add_theme_constant_override("outline_size", 5)
	page_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page_count_label)

	tap_hint = Label.new()
	tap_hint.name = "StoryTapHint"
	tap_hint.position = Vector2(148, 954)
	tap_hint.size = Vector2(280, 36)
	tap_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tap_hint.add_theme_font_size_override("font_size", 14)
	tap_hint.add_theme_color_override("font_color", Color("#d9c8aa"))
	tap_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tap_hint)

	tap_area = Button.new()
	tap_area.name = "StoryTapArea"
	tap_area.flat = true
	tap_area.focus_mode = Control.FOCUS_NONE
	tap_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tap_area.pressed.connect(advance_page)
	add_child(tap_area)

func start(as_replay := false, start_page := 0, requested_language := "ja") -> void:
	if page_tween and page_tween.is_valid():
		page_tween.kill()
	replay_mode = as_replay
	language_code = Localizer.normalize_language(requested_language)
	tap_hint.text = Localizer.text(language_code, "opening_story_tap")
	transitioning = false
	modulate = Color.WHITE
	tap_area.disabled = false
	visible = true
	move_to_front()
	_show_page(clampi(start_page, 0, PAGE_TEXTURES.size() - 1))

func advance_page() -> void:
	if not visible or transitioning:
		return
	if current_page_index >= PAGE_TEXTURES.size() - 1:
		transitioning = true
		tap_area.disabled = true
		page_tween = create_tween()
		page_tween.tween_property(self, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		page_tween.finished.connect(_finish_story, CONNECT_ONE_SHOT)
		return
	transitioning = true
	page_tween = create_tween().set_parallel()
	page_tween.tween_property(page_image, "modulate:a", 0.0, 0.09)
	page_tween.tween_property(story_text, "modulate:a", 0.0, 0.09)
	page_tween.finished.connect(_swap_to_next_page, CONNECT_ONE_SHOT)

func _swap_to_next_page() -> void:
	_show_page(current_page_index + 1)
	page_image.modulate.a = 0.0
	story_text.modulate.a = 0.0
	page_tween = create_tween().set_parallel()
	page_tween.tween_property(page_image, "modulate:a", 1.0, 0.16)
	page_tween.tween_property(story_text, "modulate:a", 1.0, 0.16)
	page_tween.finished.connect(_finish_page_transition, CONNECT_ONE_SHOT)

func _finish_page_transition() -> void:
	transitioning = false

func _finish_story() -> void:
	visible = false
	modulate = Color.WHITE
	transitioning = false
	tap_area.disabled = false
	story_finished.emit(replay_mode)

func _show_page(index: int) -> void:
	current_page_index = index
	page_image.texture = PAGE_TEXTURES[index]
	page_image.modulate = Color.WHITE
	if index==3:
		text_panel.position.y=506
		text_panel.size.y=494
		story_text.position.y=520
		story_text.size.y=410
	else:
		text_panel.position.y=586
		text_panel.size.y=414
		story_text.position.y=600
		story_text.size.y=346
	story_text.text = Localizer.text(language_code, PAGE_TEXT_KEYS[index])
	story_text.add_theme_font_size_override("font_size", int(PAGE_FONT_SIZES[index]))
	story_text.modulate = Color.WHITE
	page_count_label.text = "%d / %d" % [index + 1, PAGE_TEXTURES.size()]
