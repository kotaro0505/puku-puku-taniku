class_name HabitatAwakeningOverlay
extends Control

signal awakening_finished
signal lookaround_requested(context: String)

const Localizer = preload("res://scripts/game_localizer.gd")
const DialoguePortraits = preload("res://scripts/dialogue_portraits.gd")
const UISymbolIconClass = preload("res://scripts/ui_symbol_icon.gd")
const DIALOG_KEYS := [
	"awakening_empty_1", "awakening_empty_2", "awakening_overharvest", "awakening_sow",
	"_pause_before_memory", "awakening_surprise", "awakening_memory", "awakening_thanks",
	"awakening_apology", "awakening_promise_1", "awakening_promise_2", "awakening_promise_3",
	"awakening_rain_stopping", "awakening_sprout_look", "awakening_sprout_panda"
]
const SPEAKER_KEYS := [
	"story_speaker_armadillo", "story_speaker_panda", "story_speaker_armadillo",
	"story_speaker_panda", "", "story_speaker_panda", "story_speaker_armadillo",
	"story_speaker_girl", "story_speaker_girl", "story_speaker_armadillo",
	"story_speaker_girl", "story_speaker_girl", "story_speaker_panda", "story_speaker_girl",
	"story_speaker_panda"
]
const GHOST_TEXTURES: Array[Texture2D] = [
	preload("res://assets/plants/habitat/sprite-colorata.png"),
	preload("res://assets/plants/habitat/sprite-lutea.png"),
	preload("res://assets/plants/habitat/sprite-shaviana.png"),
	preload("res://assets/plants/habitat/sprite-laui.png"),
	preload("res://assets/plants/habitat/sprite-kante.png")
]
const GHOST_CENTER_RATIOS := [
	Vector2(0.115, 0.34), Vector2(0.30, 0.52), Vector2(0.50, 0.29),
	Vector2(0.70, 0.49), Vector2(0.885, 0.36)
]
const SPROUT_TEXTURES: Array[Texture2D] = [
	preload("res://assets/plants/habitat/sprite-colorata.png"),
	preload("res://assets/plants/habitat/sprite-affinis.png"),
	preload("res://assets/plants/habitat/sprite-shaviana.png")
]
const SPROUT_CENTERS := [Vector2(105, 635), Vector2(288, 570), Vector2(470, 642)]

var language_code := "ja"
var page_index := 0
var rain_active := false
var rain_soft := false
var transitioning := false
var waiting_for_arrival_lookaround := false
var dialogue_label: Label
var speaker_label: Label
var speaker_portrait: TextureRect
var instruction_label: Label
var text_back: Panel
var darkness: ColorRect
var rain_tint: ColorRect
var ghost_layer: Control
var sprout_layer: Control
var seed_layer: Control
var ghosts: Array[TextureRect] = []
var rain_drops: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var sow_animation_played := false

func _ready() -> void:
	name = "HabitatAwakeningOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 880
	rng.seed = 20260917
	_build_ui()
	resized.connect(_layout_ghosts)
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
	for index in GHOST_TEXTURES.size():
		var ghost := TextureRect.new()
		ghost.texture = GHOST_TEXTURES[index]
		ghost.size = Vector2(132, 132)
		ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ghost.modulate = Color(0.72, 0.92, 1.0, 0.0)
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost_layer.add_child(ghost)
		ghosts.append(ghost)
	_layout_ghosts()

	sprout_layer = Control.new()
	sprout_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sprout_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sprout_layer)
	for index in SPROUT_TEXTURES.size():
		var sprout_group := Control.new()
		sprout_group.name = "StorySprout%d" % index
		sprout_group.position = SPROUT_CENTERS[index] - Vector2(66, 66)
		sprout_group.size = Vector2(132, 132)
		sprout_group.pivot_offset = sprout_group.size * 0.5
		sprout_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprout_group.set_meta("story_sprout_group", true)
		sprout_layer.add_child(sprout_group)
		var plant := TextureRect.new()
		plant.name = "Plant"
		plant.texture = SPROUT_TEXTURES[index]
		plant.position = Vector2.ZERO
		plant.size = Vector2(132, 132)
		plant.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plant.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		plant.pivot_offset = plant.size * 0.5
		plant.scale = Vector2(0.08, 0.08)
		plant.modulate = Color(1.0, 1.0, 1.0, 0.0)
		plant.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plant.set_meta("story_sprout_plant", true)
		sprout_group.add_child(plant)

	seed_layer = Control.new()
	seed_layer.name = "StorySeedLayer"
	seed_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	seed_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(seed_layer)

	text_back = Panel.new()
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

	speaker_portrait = TextureRect.new()
	speaker_portrait.name = "SpeakerPortrait"
	speaker_portrait.position = Vector2(40, 786)
	speaker_portrait.size = Vector2(116, 126)
	speaker_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	speaker_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	speaker_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(speaker_portrait)

	speaker_label = Label.new()
	speaker_label.position = Vector2(40, 752)
	speaker_label.size = Vector2(116, 30)
	speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speaker_label.add_theme_font_size_override("font_size", 14)
	speaker_label.add_theme_color_override("font_color", Color("#f4ca7b"))
	speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(speaker_label)

	dialogue_label = Label.new()
	dialogue_label.position = Vector2(170, 784)
	dialogue_label.size = Vector2(354, 131)
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
	sow_animation_played = false
	waiting_for_arrival_lookaround = true
	darkness.color.a = 0.12
	rain_tint.color.a = 0.0
	for ghost in ghosts:
		ghost.modulate.a = 0.0
		ghost.scale = Vector2.ONE
	for sprout_group in sprout_layer.get_children():
		sprout_group.modulate = Color.WHITE
		for sprout_part in sprout_group.get_children():
			sprout_part.modulate = Color(1.0, 1.0, 1.0, 0.0)
			sprout_part.scale = Vector2(0.08, 0.08)
	for seed in seed_layer.get_children():
		seed.queue_free()
	instruction_label.text = Localizer.text(language_code, "opening_story_tap")
	_set_dialogue_visible(true)
	visible = true
	move_to_front()
	_show_page()
	lookaround_requested.emit("arrival")

func advance() -> void:
	if not visible or transitioning:
		return
	if page_index == 0 and waiting_for_arrival_lookaround:
		return
	if page_index == 3 and not sow_animation_played:
		_begin_sow_animation()
		return
	if page_index >= DIALOG_KEYS.size() - 1:
		visible = false
		rain_active = false
		awakening_finished.emit()
		return
	page_index += 1
	_show_page()

func complete_lookaround(context: String) -> void:
	if context != "arrival" or not visible or page_index != 0 or not waiting_for_arrival_lookaround:
		return
	waiting_for_arrival_lookaround = false
	advance()

func _layout_ghosts() -> void:
	var area := size
	if area.x <= 0.0 or area.y <= 0.0:
		area = get_viewport_rect().size
	if area.x <= 0.0 or area.y <= 0.0:
		area = Vector2(576, 1024)
	var side := clampf(minf(area.x * 0.23, area.y * 0.13), 104.0, 145.0)
	for index in mini(ghosts.size(), GHOST_CENTER_RATIOS.size()):
		var ghost := ghosts[index]
		ghost.size = Vector2(side, side)
		ghost.position = Vector2(area.x * GHOST_CENTER_RATIOS[index].x, area.y * GHOST_CENTER_RATIOS[index].y) - ghost.size * 0.5

func _show_page() -> void:
	if page_index == 3:
		_show_current_dialogue()
		return
	if page_index == 4:
		_begin_memory_reveal()
		return
	if page_index == 11:
		_begin_rain_softening()
		return
	if page_index == 12:
		_begin_sprout_reveal()
		return
	if page_index == 13:
		_begin_three_species_reveal()
		return
	_show_current_dialogue()


func _begin_sow_animation() -> void:
	sow_animation_played = true
	transitioning = true
	# The seeds are story-only sprites. They deliberately do not touch the
	# player's seed inventory or the habitat population.
	var destinations := [Vector2(118, 646), Vector2(286, 594), Vector2(458, 648)]
	for index in destinations.size():
		var seed := UISymbolIconClass.new()
		seed.name = "StorySeed%d" % index
		seed.symbol = "seed"
		seed.icon_color = Color("#8b5629")
		seed.size = Vector2(20, 20)
		seed.position = Vector2(390 + index * 22, 436 - index * 7)
		seed.modulate.a = 0.0
		seed_layer.add_child(seed)
		var destination: Vector2 = destinations[index] - seed.size * 0.5
		var midpoint := Vector2(lerpf(seed.position.x, destination.x, 0.48), minf(seed.position.y, destination.y) - 58.0)
		var flight := create_tween().bind_node(seed)
		flight.tween_interval(float(index) * 0.14)
		flight.tween_property(seed, "modulate:a", 1.0, 0.08)
		flight.tween_property(seed, "position", midpoint, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flight.tween_property(seed, "position", destination, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		flight.tween_property(seed, "scale", Vector2(0.72, 0.72), 0.10).set_trans(Tween.TRANS_BACK)
		flight.tween_interval(0.24)
		flight.tween_property(seed, "modulate:a", 0.0, 0.20)
		flight.tween_callback(seed.queue_free)
	await get_tree().create_timer(1.28).timeout
	if visible and page_index == 3:
		page_index += 1
		transitioning = false
		_show_page()

func _show_current_dialogue() -> void:
	_set_dialogue_visible(true)
	var speaker_key := str(SPEAKER_KEYS[page_index])
	speaker_label.text = "" if speaker_key.is_empty() else Localizer.text(language_code, speaker_key)
	speaker_label.visible = not speaker_key.is_empty()
	speaker_portrait.texture = DialoguePortraits.texture(DialoguePortraits.speaker_id_from_key(speaker_key))
	speaker_portrait.visible = speaker_portrait.texture != null
	dialogue_label.text = Localizer.text(language_code, DIALOG_KEYS[page_index])

func _set_dialogue_visible(show: bool) -> void:
	text_back.visible = show
	var speaker_key := str(SPEAKER_KEYS[page_index]) if page_index >= 0 and page_index < SPEAKER_KEYS.size() else ""
	speaker_label.visible = show and not speaker_key.is_empty()
	speaker_portrait.visible = show and speaker_portrait.texture != null
	dialogue_label.visible = show
	instruction_label.visible = show

func _begin_memory_reveal() -> void:
	transitioning = true
	_set_dialogue_visible(false)
	var sequence := create_tween()
	sequence.tween_interval(0.65)
	sequence.tween_property(darkness, "color:a", 0.56, 0.55)
	sequence.tween_callback(func():
		rain_active = true
		rain_tint.color.a = 0.20
		queue_redraw()
	)
	sequence.tween_interval(0.35)
	sequence.tween_callback(_show_ghosts)
	sequence.tween_interval(0.90)
	sequence.tween_callback(func():
		page_index += 1
		transitioning = false
		_show_page()
	)

func _show_ghosts() -> void:
	for index in ghosts.size():
		var ghost := ghosts[index]
		var tween := create_tween()
		tween.tween_interval(float(index) * 0.10)
		tween.tween_property(ghost, "modulate:a", 0.58, 0.42)
		tween.tween_property(ghost, "modulate:a", 0.34, 0.36)

func _begin_rain_softening() -> void:
	transitioning = true
	_set_dialogue_visible(false)
	rain_soft = true
	var soften := create_tween().set_parallel()
	soften.tween_property(darkness, "color:a", 0.24, 0.7)
	soften.tween_property(rain_tint, "color:a", 0.07, 0.7)
	soften.finished.connect(func():
		transitioning = false
		_show_current_dialogue()
	, CONNECT_ONE_SHOT)

func _begin_sprout_reveal() -> void:
	transitioning = true
	_set_dialogue_visible(false)
	var reveal := create_tween().set_parallel()
	for ghost in ghosts:
		reveal.tween_property(ghost, "position:y", ghost.position.y + 110.0, 0.75)
		reveal.tween_property(ghost, "modulate", Color(1.15, 1.08, 0.72, 0.0), 0.75)
	reveal.set_parallel(false)
	reveal.tween_interval(0.45)
	reveal.tween_callback(func():
		page_index += 1
		transitioning = false
		_show_page()
	)

func _begin_three_species_reveal() -> void:
	transitioning = true
	_set_dialogue_visible(false)
	var sequence := create_tween()
	for index in sprout_layer.get_child_count():
		var sprout_group: Control = sprout_layer.get_child(index)
		var plant: Control = sprout_group.get_node("Plant")
		sequence.tween_property(plant, "modulate:a", 1.0, 0.28)
		sequence.parallel().tween_property(plant, "scale", Vector2(0.54, 0.54), 0.46).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		sequence.tween_interval(0.08)
	sequence.tween_interval(0.18)
	sequence.tween_callback(func():
		transitioning = false
		_show_current_dialogue()
	)

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
