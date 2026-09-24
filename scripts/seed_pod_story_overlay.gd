class_name SeedPodStoryOverlay
extends Control

signal story_finished

const Localizer = preload("res://scripts/game_localizer.gd")
const STORY_TEXTURE: Texture2D = preload("res://assets/story/first-awakening-seed-pod.jpg")
const DIALOG_KEYS := [
	"seed_pod_story_1",
	"seed_pod_story_2",
	"seed_pod_story_3",
	"seed_pod_story_4",
	"seed_pod_story_5"
]
const SPEAKER_KEYS := [
	"story_speaker_panda",
	"story_speaker_armadillo",
	"story_speaker_girl",
	"story_speaker_panda",
	"story_speaker_girl"
]

var language_code := "ja"
var page_index := 0
var story_text: Label
var speaker_label: Label
var page_count_label: Label
var tap_hint: Label
var text_tween: Tween
var transitioning := false


func _ready() -> void:
	name = "SeedPodStoryOverlay"
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

	var story_image := TextureRect.new()
	story_image.name = "StoryImage"
	story_image.texture = STORY_TEXTURE
	story_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	story_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	story_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	story_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(story_image)

	var text_panel := Panel.new()
	text_panel.name = "StoryTextPanel"
	text_panel.position = Vector2(0, 650)
	text_panel.size = Vector2(576, 374)
	text_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.105, 0.055, 0.035, 0.92)
	panel_style.border_color = Color(0.89, 0.68, 0.39, 0.48)
	panel_style.border_width_top = 2
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.shadow_color = Color(0.04, 0.02, 0.01, 0.35)
	panel_style.shadow_size = 8
	text_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(text_panel)

	speaker_label = Label.new()
	speaker_label.name = "StorySpeaker"
	speaker_label.position = Vector2(42, 674)
	speaker_label.size = Vector2(492, 32)
	speaker_label.add_theme_font_size_override("font_size", 16)
	speaker_label.add_theme_color_override("font_color", Color("#f2cf92"))
	speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(speaker_label)

	story_text = Label.new()
	story_text.name = "StoryText"
	story_text.position = Vector2(36, 708)
	story_text.size = Vector2(504, 220)
	story_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_text.add_theme_font_size_override("font_size", 20)
	story_text.add_theme_color_override("font_color", Color("#fff6df"))
	story_text.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	story_text.add_theme_constant_override("shadow_offset_x", 1)
	story_text.add_theme_constant_override("shadow_offset_y", 2)
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
	tap_hint.position = Vector2(148, 970)
	tap_hint.size = Vector2(280, 36)
	tap_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tap_hint.add_theme_font_size_override("font_size", 14)
	tap_hint.add_theme_color_override("font_color", Color("#d9c8aa"))
	tap_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tap_hint)

	var tap_area := Button.new()
	tap_area.name = "StoryTapArea"
	tap_area.flat = true
	tap_area.focus_mode = Control.FOCUS_NONE
	tap_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tap_area.pressed.connect(advance)
	add_child(tap_area)


func start(requested_language := "ja") -> void:
	if text_tween and text_tween.is_valid():
		text_tween.kill()
	language_code = Localizer.normalize_language(requested_language)
	page_index = 0
	transitioning = false
	tap_hint.text = Localizer.text(language_code, "opening_story_tap")
	visible = true
	move_to_front()
	_show_page()


func advance() -> void:
	if not visible or transitioning:
		return
	if page_index >= DIALOG_KEYS.size() - 1:
		visible = false
		story_finished.emit()
		return
	transitioning = true
	page_index += 1
	text_tween = create_tween()
	text_tween.tween_property(story_text, "modulate:a", 0.0, 0.08)
	text_tween.tween_callback(_show_page)
	text_tween.tween_property(story_text, "modulate:a", 1.0, 0.14)
	text_tween.finished.connect(func(): transitioning = false, CONNECT_ONE_SHOT)


func _show_page() -> void:
	speaker_label.text = Localizer.text(language_code, SPEAKER_KEYS[page_index])
	story_text.text = Localizer.text(language_code, DIALOG_KEYS[page_index])
	story_text.modulate = Color.WHITE
	page_count_label.text = "%d / %d" % [page_index + 1, DIALOG_KEYS.size()]
