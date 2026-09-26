class_name HabitatSecondAwakeningOverlay
extends Control

signal awakening_finished

const Localizer = preload("res://scripts/game_localizer.gd")
const DialoguePortraits = preload("res://scripts/dialogue_portraits.gd")
const DIALOG_KEYS := [
	"second_awakening_light",
	"second_awakening_panda",
	"second_awakening_armadillo",
	"second_awakening_future"
]
const SPEAKER_KEYS := [
	"", "story_speaker_panda", "story_speaker_armadillo", ""
]

var language_code := "ja"
var page_index := 0
var dialogue_label: Label
var speaker_label: Label
var speaker_portrait: TextureRect
var instruction_label: Label
var color_tint: ColorRect
var light_layer: Control
var light_tweens: Array[Tween] = []


func _ready() -> void:
	name = "HabitatSecondAwakeningOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 890
	_build_ui()
	visible = false


func _build_ui() -> void:
	color_tint = ColorRect.new()
	color_tint.color = Color(0.30, 0.12, 0.42, 0.30)
	color_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_tint)
	light_layer = Control.new()
	light_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	light_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(light_layer)
	var colors := [Color("#63e6ff"), Color("#ff75c8"), Color("#ffe36d"), Color("#8dff8a"), Color("#b58cff"), Color("#ff9e62")]
	for index in colors.size():
		var light := Panel.new()
		light.position = Vector2(-130.0 - index * 90.0, 330.0 + index * 67.0)
		light.size = Vector2(190, 18)
		light.rotation = -0.18 + index * 0.06
		light.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(colors[index], 0.72)
		style.set_corner_radius_all(10)
		style.shadow_color = Color(colors[index], 0.70)
		style.shadow_size = 18
		light.add_theme_stylebox_override("panel", style)
		light_layer.add_child(light)

	var text_back := Panel.new()
	text_back.position = Vector2(24, 744)
	text_back.size = Vector2(528, 226)
	text_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text_style := StyleBoxFlat.new()
	text_style.bg_color = Color(0.07, 0.045, 0.09, 0.92)
	text_style.border_color = Color("#f0a8ff")
	text_style.set_border_width_all(2)
	text_style.set_corner_radius_all(24)
	text_back.add_theme_stylebox_override("panel", text_style)
	add_child(text_back)
	speaker_portrait = TextureRect.new()
	speaker_portrait.name = "SpeakerPortrait"
	speaker_portrait.position = Vector2(40, 786)
	speaker_portrait.size = Vector2(116, 126)
	speaker_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	speaker_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	speaker_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(speaker_portrait)
	speaker_label = Label.new()
	speaker_label.position = Vector2(170, 757)
	speaker_label.size = Vector2(354, 30)
	speaker_label.add_theme_font_size_override("font_size", 14)
	speaker_label.add_theme_color_override("font_color", Color("#ffd4ff"))
	speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(speaker_label)
	dialogue_label = Label.new()
	dialogue_label.position = Vector2(170, 784)
	dialogue_label.size = Vector2(354, 131)
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 20)
	dialogue_label.add_theme_color_override("font_color", Color("#fff7ff"))
	dialogue_label.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.11, 0.85))
	dialogue_label.add_theme_constant_override("outline_size", 4)
	dialogue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dialogue_label)
	instruction_label = Label.new()
	instruction_label.position = Vector2(138, 924)
	instruction_label.size = Vector2(300, 30)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 13)
	instruction_label.add_theme_color_override("font_color", Color("#ead7ef"))
	instruction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(instruction_label)
	var tap_area := Button.new()
	tap_area.flat = true
	tap_area.focus_mode = Control.FOCUS_NONE
	tap_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap_area.pressed.connect(advance)
	add_child(tap_area)


func start(requested_language := "ja") -> void:
	language_code = Localizer.normalize_language(requested_language)
	page_index = 0
	_stop_light_animation()
	color_tint.color.a = 0.30
	instruction_label.text = Localizer.text(language_code, "opening_story_tap")
	visible = true
	move_to_front()
	_show_page()
	_animate_lights()


func advance() -> void:
	if not visible:
		return
	if page_index >= DIALOG_KEYS.size() - 1:
		_stop_light_animation()
		visible = false
		awakening_finished.emit()
		return
	page_index += 1
	_show_page()


func _show_page() -> void:
	var speaker_key := str(SPEAKER_KEYS[page_index])
	speaker_label.text = "" if speaker_key.is_empty() else Localizer.text(language_code, speaker_key)
	speaker_portrait.texture = DialoguePortraits.texture(DialoguePortraits.speaker_id_from_key(speaker_key))
	speaker_portrait.visible = speaker_portrait.texture != null
	dialogue_label.text = Localizer.text(language_code, DIALOG_KEYS[page_index])


func _animate_lights() -> void:
	for index in light_layer.get_child_count():
		var light: Control = light_layer.get_child(index)
		var tween := create_tween().set_loops()
		light_tweens.append(tween)
		tween.tween_interval(index * 0.07)
		tween.tween_property(light, "position:x", 610.0, 1.25 + index * 0.08).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(func(): light.position.x = -220.0)


func _stop_light_animation() -> void:
	for tween in light_tweens:
		if tween and tween.is_valid():
			tween.kill()
	light_tweens.clear()
