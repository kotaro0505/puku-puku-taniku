class_name SeedPodStoryOverlay
extends Control

signal story_finished

const Localizer = preload("res://scripts/game_localizer.gd")
const DialoguePortraits = preload("res://scripts/dialogue_portraits.gd")
const StandardStoryDialoguePanelClass = preload("res://scripts/standard_story_dialogue_panel.gd")
const STORY_TEXTURE: Texture2D = preload("res://assets/story/first-awakening-seed-pod.jpg")
const IMAGE_AREA_SIZE := Vector2(576, 744)
const DIALOG_KEYS := [
	"seed_pod_story_1",
	"seed_pod_story_2",
	"seed_pod_story_3"
]
const SPEAKER_KEYS := [
	"story_speaker_panda",
	"story_speaker_girl",
	"story_speaker_armadillo"
]

var language_code := "ja"
var page_index := 0
var story_text: Label
var story_image: TextureRect
var speaker_label: Label
var speaker_portrait: TextureRect
var tap_hint: Button
var text_tween: Tween
var fade_tween: Tween
var transitioning := false
var exit_fade: ColorRect
var dialogue_panel


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

	story_image = TextureRect.new()
	story_image.name = "StoryImage"
	story_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	story_image.stretch_mode = TextureRect.STRETCH_SCALE
	var contain_scale := minf(
		IMAGE_AREA_SIZE.x / float(STORY_TEXTURE.get_width()),
		IMAGE_AREA_SIZE.y / float(STORY_TEXTURE.get_height())
	)
	story_image.texture = STORY_TEXTURE
	story_image.size = Vector2(STORY_TEXTURE.get_size()) * contain_scale
	story_image.position = (IMAGE_AREA_SIZE - story_image.size) * 0.5
	story_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(story_image)

	var tap_area := Button.new()
	tap_area.name = "StoryTapArea"
	tap_area.flat = true
	tap_area.focus_mode = Control.FOCUS_NONE
	tap_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tap_area.pressed.connect(advance)
	add_child(tap_area)
	dialogue_panel = StandardStoryDialoguePanelClass.new()
	add_child(dialogue_panel)
	speaker_portrait = dialogue_panel.speaker_portrait
	speaker_label = dialogue_panel.speaker_label
	story_text = dialogue_panel.dialogue_label
	tap_hint = dialogue_panel.continue_button
	tap_hint.pressed.connect(advance)

	exit_fade = ColorRect.new()
	exit_fade.name = "ExitFade"
	exit_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	exit_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	exit_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exit_fade.z_index = 20
	add_child(exit_fade)


func start(requested_language := "ja") -> void:
	if text_tween and text_tween.is_valid():
		text_tween.kill()
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	language_code = Localizer.normalize_language(requested_language)
	page_index = 0
	transitioning = true
	exit_fade.color.a = 0.0
	story_image.modulate.a = 0.0
	tap_hint.text = Localizer.text(language_code, "continue")
	modulate.a = 0.0
	visible = true
	move_to_front()
	_show_page()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.52).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_tween.finished.connect(func(): transitioning = false, CONNECT_ONE_SHOT)


func advance() -> void:
	if not visible or transitioning:
		return
	if page_index == 0 and story_image.modulate.a < 0.99:
		transitioning = true
		fade_tween = create_tween()
		fade_tween.tween_property(story_image, "modulate:a", 1.0, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		fade_tween.tween_interval(0.18)
		fade_tween.tween_callback(_advance_after_image_fade)
		return
	if page_index >= DIALOG_KEYS.size() - 1:
		transitioning = true
		fade_tween = create_tween()
		fade_tween.tween_property(exit_fade, "color:a", 1.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		fade_tween.tween_callback(func(): story_finished.emit())
		return
	transitioning = true
	page_index += 1
	text_tween = create_tween()
	text_tween.tween_property(story_text, "modulate:a", 0.0, 0.08)
	text_tween.tween_callback(_show_page)
	text_tween.tween_property(story_text, "modulate:a", 1.0, 0.14)
	text_tween.finished.connect(func(): transitioning = false, CONNECT_ONE_SHOT)


func _advance_after_image_fade() -> void:
	transitioning = false
	advance()


func _show_page() -> void:
	var speaker_key := str(SPEAKER_KEYS[page_index])
	dialogue_panel.set_speaker(
		Localizer.text(language_code, speaker_key),
		DialoguePortraits.texture(DialoguePortraits.speaker_id_from_key(speaker_key))
	)
	story_text.text = Localizer.text(language_code, DIALOG_KEYS[page_index])
	story_text.modulate = Color.WHITE
