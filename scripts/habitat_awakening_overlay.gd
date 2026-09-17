class_name HabitatAwakeningOverlay
extends Control

signal awakening_finished

const Localizer = preload("res://scripts/game_localizer.gd")
const DIALOG_KEYS := [
	"awakening_empty_1", "awakening_empty_2", "awakening_sow", "awakening_wait",
	"awakening_memory", "awakening_thanks", "awakening_apology", "awakening_promise_1",
	"awakening_promise_2", "awakening_listened"
]
const SPEAKER_KEYS := [
	"story_speaker_armadillo", "story_speaker_panda", "story_speaker_panda", "",
	"story_speaker_panda", "story_speaker_girl", "story_speaker_girl",
	"story_speaker_armadillo", "story_speaker_girl", "story_speaker_panda"
]
const GHOST_TEXTURES: Array[Texture2D] = [
	preload("res://assets/plants/habitat/sprite-colorata.png"),
	preload("res://assets/plants/habitat/sprite-lutea.png"),
	preload("res://assets/plants/habitat/sprite-shaviana.png"),
	preload("res://assets/plants/habitat/sprite-laui.png"),
	preload("res://assets/plants/habitat/sprite-kante.png")
]

var language_code := "ja"
var page_index := 0
var rain_active := false
var rain_soft := false
var transitioning := false
var dialogue_label: Label
var speaker_label: Label
var instruction_label: Label
var darkness: ColorRect
var rain_tint: ColorRect
var ghost_layer: Control
var sprout_layer: Control
var ghosts: Array[TextureRect] = []
var rain_drops: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	name = "HabitatAwakeningOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 880
	rng.seed = 20260917
	_build_ui()
	set_process(true)
	visible = false

func _build_ui() -> void:
	darkness = ColorRect.new()
	darkness.color = Color(0.035, 0.055, 0.08, 0.0)
	darkness.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(darkness)

	rain_tint = ColorRect.new()
	rain_tint.color = Color(0.18, 0.27, 0.38, 0.0)
	rain_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rain_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rain_tint)

	ghost_layer = Control.new()
	ghost_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ghost_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ghost_layer)
	var ghost_positions := [Vector2(58, 315), Vector2(190, 272), Vector2(330, 330), Vector2(102, 510), Vector2(363, 500)]
	for index in GHOST_TEXTURES.size():
		var ghost := TextureRect.new()
		ghost.texture = GHOST_TEXTURES[index]
		ghost.position = ghost_positions[index]
		ghost.size = Vector2(145, 145)
		ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ghost.modulate = Color(0.72, 0.92, 1.0, 0.0)
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost_layer.add_child(ghost)
		ghosts.append(ghost)

	sprout_layer = Control.new()
	sprout_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sprout_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sprout_layer)
	for position in [Vector2(110, 680), Vector2(250, 635), Vector2(405, 690)]:
		var glow := Panel.new()
		glow.position = position
		glow.size = Vector2(54, 26)
		glow.scale = Vector2(0.1, 0.1)
		glow.modulate.a = 0.0
		glow.pivot_offset = glow.size * 0.5
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.62, 1.0, 0.58, 0.8)
		style.set_corner_radius_all(18)
		style.shadow_color = Color(0.42, 1.0, 0.5, 0.65)
		style.shadow_size = 14
		glow.add_theme_stylebox_override("panel", style)
		sprout_layer.add_child(glow)

	var text_back := Panel.new()
	text_back.position = Vector2(24, 744)
	text_back.size = Vector2(528, 226)
	text_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text_style := StyleBoxFlat.new()
	text_style.bg_color = Color(0.08, 0.06, 0.05, 0.90)
	text_style.border_color = Color(0.91, 0.75, 0.48, 0.62)
	text_style.set_border_width_all(2)
	text_style.set_corner_radius_all(24)
	text_back.add_theme_stylebox_override("panel", text_style)
	add_child(text_back)

	speaker_label = Label.new()
	speaker_label.position = Vector2(58, 757)
	speaker_label.size = Vector2(460, 30)
	speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	speaker_label.add_theme_font_size_override("font_size", 14)
	speaker_label.add_theme_color_override("font_color", Color("#f4ca7b"))
	speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(speaker_label)

	dialogue_label = Label.new()
	dialogue_label.position = Vector2(52, 784)
	dialogue_label.size = Vector2(472, 131)
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 20)
	dialogue_label.add_theme_color_override("font_color", Color("#fff6df"))
	dialogue_label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02, 0.8))
	dialogue_label.add_theme_constant_override("outline_size", 4)
	dialogue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dialogue_label)

	instruction_label = Label.new()
	instruction_label.position = Vector2(138, 924)
	instruction_label.size = Vector2(300, 30)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 13)
	instruction_label.add_theme_color_override("font_color", Color("#d9c8aa"))
	instruction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(instruction_label)

	var tap_area := Button.new()
	tap_area.flat = true
	tap_area.focus_mode = Control.FOCUS_NONE
	tap_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap_area.pressed.connect(advance)
	add_child(tap_area)

	for index in 52:
		rain_drops.append({
			"x": rng.randf_range(0.0, 576.0),
			"y": rng.randf_range(-1024.0, 1024.0),
			"speed": rng.randf_range(560.0, 980.0),
			"length": rng.randf_range(18.0, 38.0)
		})

func start(requested_language := "ja") -> void:
	language_code = Localizer.normalize_language(requested_language)
	page_index = 0
	rain_active = false
	rain_soft = false
	transitioning = false
	darkness.color.a = 0.12
	rain_tint.color.a = 0.0
	for ghost in ghosts:
		ghost.modulate.a = 0.0
		ghost.scale = Vector2.ONE
	for sprout in sprout_layer.get_children():
		sprout.modulate.a = 0.0
		sprout.scale = Vector2(0.1, 0.1)
	instruction_label.text = Localizer.text(language_code, "opening_story_tap")
	visible = true
	move_to_front()
	_show_page()

func advance() -> void:
	if not visible or transitioning:
		return
	if page_index >= DIALOG_KEYS.size() - 1:
		visible = false
		rain_active = false
		awakening_finished.emit()
		return
	page_index += 1
	_show_page()

func _show_page() -> void:
	var speaker_key := str(SPEAKER_KEYS[page_index])
	speaker_label.text = "" if speaker_key.is_empty() else Localizer.text(language_code, speaker_key)
	dialogue_label.text = Localizer.text(language_code, DIALOG_KEYS[page_index])
	if page_index == 3:
		transitioning = true
		var dark_tween := create_tween()
		dark_tween.tween_property(darkness, "color:a", 0.56, 0.5)
		dark_tween.finished.connect(func(): transitioning = false, CONNECT_ONE_SHOT)
	elif page_index == 4:
		rain_active = true
		rain_tint.color.a = 0.20
		_show_ghosts()
	elif page_index == 9:
		_soften_and_answer()

func _show_ghosts() -> void:
	for index in ghosts.size():
		var ghost := ghosts[index]
		var tween := create_tween()
		tween.tween_interval(float(index) * 0.10)
		tween.tween_property(ghost, "modulate:a", 0.58, 0.42)
		tween.tween_property(ghost, "modulate:a", 0.34, 0.36)

func _soften_and_answer() -> void:
	rain_soft = true
	var answer := create_tween().set_parallel()
	answer.tween_property(darkness, "color:a", 0.24, 0.7)
	answer.tween_property(rain_tint, "color:a", 0.07, 0.7)
	for ghost in ghosts:
		answer.tween_property(ghost, "position:y", ghost.position.y + 110.0, 0.75)
		answer.tween_property(ghost, "modulate:a", 0.0, 0.75)
	for sprout in sprout_layer.get_children():
		answer.tween_property(sprout, "modulate:a", 1.0, 0.55).set_delay(0.35)
		answer.tween_property(sprout, "scale", Vector2.ONE, 0.55).set_delay(0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if not visible or not rain_active:
		return
	var speed_scale := 0.34 if rain_soft else 1.0
	for drop in rain_drops:
		drop["y"] = float(drop["y"]) + float(drop["speed"]) * delta * speed_scale
		if float(drop["y"]) > 1040.0:
			drop["y"] = rng.randf_range(-220.0, -20.0)
			drop["x"] = rng.randf_range(0.0, 576.0)
	queue_redraw()

func _draw() -> void:
	if not visible or not rain_active:
		return
	var alpha := 0.25 if rain_soft else 0.58
	for drop in rain_drops:
		var start := Vector2(float(drop["x"]), float(drop["y"]))
		var finish := start + Vector2(-5.0, float(drop["length"]))
		draw_line(start, finish, Color(0.72, 0.86, 1.0, alpha), 1.4)
