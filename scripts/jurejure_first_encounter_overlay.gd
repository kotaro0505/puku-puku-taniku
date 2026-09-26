class_name JureJureFirstEncounterOverlay
extends Control

signal story_finished

const Localizer = preload("res://scripts/game_localizer.gd")
const STORY_TEXTURE: Texture2D = preload("res://assets/story/jurejure-first-encounter.jpg")
const DIALOG_KEYS := [
	"jurejure_first_peccary",
	"jurejure_first_skunk",
	"jurejure_first_mouse"
]
const SPEAKER_IDS := ["peccary", "skunk", "mouse"]

var language_code := "ja"
var page_index := 0
var transitioning := false
var speaker_label: Label
var speaker_portrait: TextureRect
var dialogue_label: Label
var tap_hint: Label
var fade_tween: Tween
var text_tween: Tween


func _ready() -> void:
	name = "JureJureFirstEncounterOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 925
	_build_ui()
	visible = false


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color.BLACK
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
	text_panel.position = Vector2(24, 758)
	text_panel.size = Vector2(528, 220)
	text_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.045, 0.025, 0.92)
	panel_style.border_color = Color(0.92, 0.69, 0.35, 0.68)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(24)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	panel_style.shadow_size = 8
	text_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(text_panel)

	speaker_portrait = TextureRect.new()
	speaker_portrait.name = "SpeakerPortrait"
	speaker_portrait.position = Vector2(40, 795)
	speaker_portrait.size = Vector2(116, 126)
	speaker_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	speaker_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	speaker_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(speaker_portrait)

	speaker_label = Label.new()
	speaker_label.position = Vector2(170, 774)
	speaker_label.size = Vector2(354, 30)
	speaker_label.add_theme_font_size_override("font_size", 15)
	speaker_label.add_theme_color_override("font_color", Color("#f4ca7b"))
	speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(speaker_label)

	dialogue_label = Label.new()
	dialogue_label.position = Vector2(170, 802)
	dialogue_label.size = Vector2(354, 116)
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 20)
	dialogue_label.add_theme_color_override("font_color", Color("#fff6df"))
	dialogue_label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02, 0.85))
	dialogue_label.add_theme_constant_override("outline_size", 4)
	dialogue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dialogue_label)

	tap_hint = Label.new()
	tap_hint.position = Vector2(168, 936)
	tap_hint.size = Vector2(240, 30)
	tap_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_hint.add_theme_font_size_override("font_size", 13)
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
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	if text_tween and text_tween.is_valid():
		text_tween.kill()
	language_code = Localizer.normalize_language(requested_language)
	page_index = 0
	transitioning = true
	tap_hint.text = Localizer.text(language_code, "opening_story_tap")
	modulate.a = 0.0
	visible = true
	move_to_front()
	_show_page()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_tween.finished.connect(func(): transitioning = false, CONNECT_ONE_SHOT)


func advance() -> void:
	if not visible or transitioning:
		return
	if page_index >= DIALOG_KEYS.size() - 1:
		transitioning = true
		fade_tween = create_tween()
		fade_tween.tween_property(self, "modulate:a", 0.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		fade_tween.tween_callback(func():
			visible = false
			transitioning = false
			story_finished.emit()
		)
		return
	transitioning = true
	page_index += 1
	text_tween = create_tween()
	text_tween.tween_property(dialogue_label, "modulate:a", 0.0, 0.08)
	text_tween.tween_callback(_show_page)
	text_tween.tween_property(dialogue_label, "modulate:a", 1.0, 0.14)
	text_tween.finished.connect(func(): transitioning = false, CONNECT_ONE_SHOT)


func _show_page() -> void:
	var speaker_id: String = str(SPEAKER_IDS[page_index])
	speaker_label.text = Localizer.text(language_code, "jurejure_%s_name" % speaker_id)
	speaker_portrait.texture = _portrait_texture(speaker_id)
	dialogue_label.text = Localizer.text(language_code, DIALOG_KEYS[page_index])
	dialogue_label.modulate = Color.WHITE


func _portrait_texture(speaker_id: String) -> Texture2D:
	var source: Texture2D
	var normalized_region := Rect2()
	match speaker_id:
		"mouse":
			source = load("res://assets/jurejure/mouse.png") as Texture2D
			normalized_region = Rect2(0.089, 0.0, 0.822, 0.642)
		"skunk":
			source = load("res://assets/jurejure/skunk.png") as Texture2D
			normalized_region = Rect2(0.0, 0.057, 0.82, 0.656)
		"peccary":
			source = load("res://assets/jurejure/peccary.png") as Texture2D
			normalized_region = Rect2(0.16, 0.014, 0.802, 0.642)
		_:
			return null
	if source == null:
		return null
	var portrait := AtlasTexture.new()
	portrait.atlas = source
	portrait.region = Rect2(normalized_region.position * source.get_size(), normalized_region.size * source.get_size())
	return portrait
