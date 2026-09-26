class_name PukuPukuBattle
extends Control

signal battle_requested
signal battle_declined
signal battle_resolved(result: Dictionary)
signal return_requested

const Localizer = preload("res://scripts/game_localizer.gd")
const SucculentClass = preload("res://scripts/succulent.gd")
const BACKGROUND_PATH := "res://assets/jurejure/puku-puku-battle-background.jpg"
const PLANTS_PER_SIDE := 6
const INITIAL_DIAMETER_CM := 1.6
const MAX_DISPLAY_SIZE_PX := 106.0
const SOW_SECONDS := 0.46
const GERMINATION_SECONDS := 0.54

# Coordinates are local to clipped soil-only fields. The generous margins keep
# a normally grown plant's complete visual on dirt, while clipping guarantees
# that an exceptionally large plant can never cross the central VS divider.
const OPPONENT_FIELD_RECT := Rect2(30, 260, 516, 218)
const PLAYER_FIELD_RECT := Rect2(30, 690, 516, 300)
const OPPONENT_POINTS := [
	Vector2(78, 66), Vector2(258, 53), Vector2(438, 68),
	Vector2(126, 158), Vector2(310, 148), Vector2(438, 162)
]
const PLAYER_POINTS := [
	Vector2(80, 76), Vector2(258, 58), Vector2(436, 80),
	Vector2(128, 210), Vector2(310, 192), Vector2(436, 214)
]

var language_code := "ja"
var choice_layer: Control
var battle_layer: Control
var unit_layer: Control
var opponent_field: Control
var player_field: Control
var logic_root: Node
var sow_button: Button
var opponent_score_label: Label
var player_score_label: Label
var result_panel: PanelContainer
var result_label: Label
var return_button: Button
var battle_active := false
var player_score := 0.0
var opponent_score := 0.0
var player_resolved := 0
var opponent_resolved := 0
var resolution_emitted := false
var units: Array[Dictionary] = []
var battle_phase := "idle"
var pending_entries: Array[Dictionary] = []
var pending_textures: Dictionary = {}
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "PukuPukuBattle"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 950
	_build_ui()
	visible = false
	set_process(true)


func _build_ui() -> void:
	choice_layer = Control.new()
	choice_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choice_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(choice_layer)
	var choice_dim := ColorRect.new()
	choice_dim.color = Color(0.02, 0.012, 0.008, 0.76)
	choice_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choice_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	choice_layer.add_child(choice_dim)
	var choice_panel := PanelContainer.new()
	choice_panel.name = "ChoicePanel"
	choice_panel.position = Vector2(68, 344)
	choice_panel.size = Vector2(440, 314)
	choice_panel.add_theme_stylebox_override("panel", _box(Color("#f7e5bd"), Color("#7a421f"), 28, 4))
	choice_layer.add_child(choice_panel)
	var choice_content := VBoxContainer.new()
	choice_content.name = "ChoiceContent"
	choice_content.alignment = BoxContainer.ALIGNMENT_CENTER
	choice_content.add_theme_constant_override("separation", 20)
	choice_panel.add_child(choice_content)
	var title := Label.new()
	title.name = "ChoiceTitle"
	title.custom_minimum_size = Vector2(380, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("#4f2919"))
	choice_content.add_child(title)
	var battle_button := Button.new()
	battle_button.name = "BattleButton"
	battle_button.custom_minimum_size = Vector2(342, 62)
	_style_button(battle_button, Color("#d98235"), 22)
	battle_button.pressed.connect(_accept_battle)
	choice_content.add_child(battle_button)
	var decline_button := Button.new()
	decline_button.name = "DeclineButton"
	decline_button.custom_minimum_size = Vector2(342, 58)
	_style_button(decline_button, Color("#e9d6ae"), 20)
	decline_button.pressed.connect(_decline_battle)
	choice_content.add_child(decline_button)

	battle_layer = Control.new()
	battle_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(battle_layer)
	var background := TextureRect.new()
	background.name = "BattleBackground"
	background.texture = load(BACKGROUND_PATH) as Texture2D
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_layer.add_child(background)

	unit_layer = Control.new()
	unit_layer.name = "BattlePlants"
	unit_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	unit_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_layer.add_child(unit_layer)
	opponent_field = _field_control("OpponentSoilField", OPPONENT_FIELD_RECT)
	player_field = _field_control("PlayerSoilField", PLAYER_FIELD_RECT)
	unit_layer.add_child(opponent_field)
	unit_layer.add_child(player_field)
	logic_root = Node.new()
	logic_root.name = "BattlePlantLogic"
	add_child(logic_root)
	opponent_score_label = _score_label(Vector2(316, 202), Color("#ffd6b1"))
	battle_layer.add_child(opponent_score_label)
	player_score_label = _score_label(Vector2(316, 680), Color("#e0ffd2"))
	battle_layer.add_child(player_score_label)
	sow_button = Button.new()
	sow_button.name = "SowBattleSeedsButton"
	sow_button.position = Vector2(166, 884)
	sow_button.size = Vector2(244, 64)
	_style_button(sow_button, Color("#8fc45d"), 23)
	sow_button.pressed.connect(_on_sow_pressed)
	sow_button.visible = false
	battle_layer.add_child(sow_button)

	result_panel = PanelContainer.new()
	result_panel.position = Vector2(78, 394)
	result_panel.size = Vector2(420, 236)
	result_panel.add_theme_stylebox_override("panel", _box(Color(0.12, 0.065, 0.035, 0.96), Color("#f2c966"), 28, 4))
	battle_layer.add_child(result_panel)
	var result_content := VBoxContainer.new()
	result_content.alignment = BoxContainer.ALIGNMENT_CENTER
	result_content.add_theme_constant_override("separation", 18)
	result_panel.add_child(result_content)
	result_label = Label.new()
	result_label.custom_minimum_size = Vector2(370, 90)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 30)
	result_label.add_theme_color_override("font_color", Color("#fff3be"))
	result_label.add_theme_color_override("font_outline_color", Color("#4f2518"))
	result_label.add_theme_constant_override("outline_size", 6)
	result_content.add_child(result_label)
	return_button = Button.new()
	return_button.custom_minimum_size = Vector2(330, 58)
	_style_button(return_button, Color("#e4a846"), 20)
	return_button.pressed.connect(_return_to_habitat)
	result_content.add_child(return_button)
	result_panel.visible = false
	battle_layer.visible = false


func show_choice(language: String) -> void:
	language_code = Localizer.normalize_language(language)
	visible = true
	choice_layer.visible = true
	battle_layer.visible = false
	var title := choice_layer.get_node("ChoicePanel/ChoiceContent/ChoiceTitle") as Label
	var battle_button := choice_layer.get_node("ChoicePanel/ChoiceContent/BattleButton") as Button
	var decline_button := choice_layer.get_node("ChoicePanel/ChoiceContent/DeclineButton") as Button
	title.text = Localizer.text(language_code, "jurejure_battle_choice_title")
	battle_button.text = Localizer.text(language_code, "jurejure_battle_yes")
	decline_button.text = Localizer.text(language_code, "jurejure_battle_no")
	move_to_front()


func start_battle(entries: Array[Dictionary], textures: Dictionary, language: String, random_seed: int = 0) -> void:
	language_code = Localizer.normalize_language(language)
	_clear_units()
	if random_seed == 0:
		rng.randomize()
	else:
		rng.seed = random_seed
	visible = true
	choice_layer.visible = false
	battle_layer.visible = true
	result_panel.visible = false
	player_score = 0.0
	opponent_score = 0.0
	player_resolved = 0
	opponent_resolved = 0
	resolution_emitted = false
	battle_active = false
	battle_phase = "awaiting_sow"
	pending_entries = entries.duplicate(true)
	pending_textures = textures.duplicate()
	sow_button.text = Localizer.text(language_code, "jurejure_battle_sow")
	sow_button.disabled = false
	sow_button.modulate = Color.WHITE
	sow_button.visible = true
	if pending_entries.is_empty():
		battle_phase = "invalid"
		sow_button.visible = false
		return
	_update_scores()
	move_to_front()


func _on_sow_pressed() -> void:
	if battle_phase != "awaiting_sow":
		return
	_run_sow_sequence()


func _run_sow_sequence() -> void:
	battle_phase = "sowing"
	sow_button.disabled = true
	var button_fade := create_tween().bind_node(sow_button)
	button_fade.tween_property(sow_button, "modulate:a", 0.0, 0.18)
	button_fade.tween_callback(sow_button.hide)
	_spawn_seed_markers()
	await get_tree().create_timer(SOW_SECONDS).timeout
	if battle_phase != "sowing" or not is_inside_tree():
		return
	_clear_seed_markers()
	_create_all_units(true)
	battle_phase = "germinating"
	await get_tree().create_timer(GERMINATION_SECONDS).timeout
	if battle_phase != "germinating" or not is_inside_tree():
		return
	battle_phase = "growing"
	battle_active = true


func debug_sow_immediately() -> void:
	if battle_phase != "awaiting_sow":
		return
	sow_button.visible = false
	sow_button.disabled = true
	_clear_seed_markers()
	_create_all_units(false)
	battle_phase = "growing"
	battle_active = true


func _spawn_seed_markers() -> void:
	for index in range(PLANTS_PER_SIDE):
		_spawn_seed_marker(opponent_field, OPPONENT_POINTS[index], true, index)
		_spawn_seed_marker(player_field, PLAYER_POINTS[index], false, index)


func _spawn_seed_marker(field: Control, point: Vector2, opponent: bool, index: int) -> void:
	var marker := Panel.new()
	marker.name = ("Opponent" if opponent else "Player") + "Seed%02d" % index
	marker.position = point - Vector2(7, 34)
	marker.size = Vector2(14, 14)
	marker.pivot_offset = marker.size * 0.5
	marker.scale = Vector2(0.2, 0.2)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_to_group("battle_seed_marker")
	var seed_style := StyleBoxFlat.new()
	seed_style.bg_color = Color("#604021") if opponent else Color("#dfb85b")
	seed_style.border_color = Color("#f4d58a")
	seed_style.set_border_width_all(2)
	seed_style.set_corner_radius_all(7)
	marker.add_theme_stylebox_override("panel", seed_style)
	field.add_child(marker)
	var fall := create_tween().bind_node(marker).set_parallel(true)
	fall.tween_property(marker, "position", point - marker.size * 0.5, SOW_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(marker, "scale", Vector2.ONE, SOW_SECONDS * 0.72).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _clear_seed_markers() -> void:
	for field in [opponent_field, player_field]:
		if field == null:
			continue
		for child in field.get_children():
			if child.is_in_group("battle_seed_marker"):
				child.free()


func _create_all_units(animate_germination: bool) -> void:
	if not units.is_empty():
		return
	for index in range(PLANTS_PER_SIDE):
		_create_unit(false, index, pending_entries, pending_textures, animate_germination)
		_create_unit(true, index, pending_entries, pending_textures, animate_germination)


func _create_unit(opponent: bool, point_index: int, entries: Array[Dictionary], textures: Dictionary, animate_germination: bool) -> void:
	var entry: Dictionary = entries[rng.randi_range(0, entries.size() - 1)]
	var species_id := str(entry.get("species_id", ""))
	var texture := textures.get(species_id) as Texture2D
	if texture == null:
		for candidate in textures.values():
			if candidate is Texture2D:
				texture = candidate
				break
	var button := TextureButton.new()
	button.name = ("Opponent" if opponent else "Player") + "Plant%02d" % point_index
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_normal = texture
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE if opponent else Control.MOUSE_FILTER_STOP
	var field := opponent_field if opponent else player_field
	field.add_child(button)
	var point: Vector2 = (OPPONENT_POINTS if opponent else PLAYER_POINTS)[point_index]
	button.z_index = int(point.y)
	var logic_seed := int(rng.randi())
	var logic = SucculentClass.new()
	logic.name = ("Opponent" if opponent else "Player") + "Logic%02d" % point_index
	logic_root.add_child(logic)
	logic.setup(entry, logic_seed, null, null, true)
	var harvest_plan := ai_harvest_plan(
		float(logic.jelly_safe_end_seconds),
		float(logic.jelly_ramp_end_seconds),
		rng.randf(),
		rng.randf()
	) if opponent else {"style": "player", "age": -1.0}
	var unit := {
		"node": button,
		"logic": logic,
		"opponent": opponent,
		"field": field,
		"point": point,
		"size_cm": float(logic.diameter_cm),
		"logic_seed": logic_seed,
		"ai_style": str(harvest_plan.get("style", "player")),
		"ai_harvest_age": float(harvest_plan.get("age", -1.0)),
		"done": false,
		"jellied": false,
		"score": 0.0,
		"species_id": species_id
	}
	var unit_index := units.size()
	units.append(unit)
	if not opponent:
		button.pressed.connect(_harvest_player.bind(unit_index))
	_update_unit_visual(unit_index)
	if animate_germination:
		button.scale = Vector2(0.12, 0.12)
		button.modulate.a = 0.18
		var germinate := create_tween().bind_node(button).set_parallel(true)
		germinate.tween_property(button, "scale", Vector2.ONE, GERMINATION_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		germinate.tween_property(button, "modulate:a", 1.0, GERMINATION_SECONDS * 0.72)


static func ai_harvest_plan(safe_end: float, ramp_end: float, style_roll: float, timing_roll: float) -> Dictionary:
	var safe := maxf(0.1, safe_end)
	var ramp_span := maxf(0.1, ramp_end - safe)
	var timing := clampf(timing_roll, 0.0, 1.0)
	if style_roll < 0.24:
		return {"style": "cautious", "age": lerpf(safe * 0.72, safe * 0.98, timing)}
	if style_roll < 0.62:
		return {"style": "steady", "age": safe + ramp_span * lerpf(0.22, 0.58, timing)}
	if style_roll < 0.88:
		return {"style": "greedy", "age": safe + ramp_span * lerpf(0.64, 0.98, timing)}
	return {"style": "reckless", "age": ramp_end + lerpf(1.5, 7.0, timing)}


func _process(delta: float) -> void:
	if not battle_active or battle_phase != "growing":
		return
	for unit_index in range(units.size()):
		var unit: Dictionary = units[unit_index]
		if bool(unit.get("done", false)):
			continue
		var logic = unit.get("logic")
		if not is_instance_valid(logic):
			continue
		# Succulent.simulate() is also the greenhouse source of truth. It applies
		# the shared growth rhythm, individual traits and FPS-independent jelly
		# hazard before the gang gets a chance to make its harvest decision.
		logic.simulate(delta)
		unit["size_cm"] = float(logic.diameter_cm)
		units[unit_index] = unit
		if str(logic.state) == "jelly":
			_resolve_unit(unit_index, true)
		elif bool(unit.get("opponent", false)) and float(logic.age) >= float(unit.get("ai_harvest_age", INF)):
			_resolve_unit(unit_index, false)
		else:
			_update_unit_visual(unit_index)


func _harvest_player(unit_index: int) -> void:
	if not battle_active or unit_index < 0 or unit_index >= units.size():
		return
	var unit: Dictionary = units[unit_index]
	if bool(unit.get("opponent", false)) or bool(unit.get("done", false)):
		return
	_resolve_unit(unit_index, false)


func _resolve_unit(unit_index: int, jellied: bool) -> void:
	if unit_index < 0 or unit_index >= units.size():
		return
	var unit: Dictionary = units[unit_index]
	if bool(unit.get("done", false)):
		return
	var logic = unit.get("logic")
	var resolved_as_jelly := jellied or (is_instance_valid(logic) and str(logic.state) == "jelly")
	if not resolved_as_jelly and is_instance_valid(logic):
		logic.harvest()
		unit["size_cm"] = float(logic.diameter_cm)
	unit["done"] = true
	unit["jellied"] = resolved_as_jelly
	var opponent := bool(unit.get("opponent", false))
	var score := 0.0 if resolved_as_jelly else float(unit.get("size_cm", 0.0))
	unit["score"] = score
	units[unit_index] = unit
	if opponent:
		opponent_resolved += 1
		opponent_score += score
	else:
		player_resolved += 1
		player_score += score
	_update_scores()
	_show_unit_result(unit, score, resolved_as_jelly)
	if player_resolved >= PLANTS_PER_SIDE and opponent_resolved >= PLANTS_PER_SIDE:
		_complete_battle()


func _show_unit_result(unit: Dictionary, score: float, jellied: bool) -> void:
	var button := unit.get("node") as TextureButton
	if is_instance_valid(button):
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shrink := create_tween().bind_node(button).set_parallel(true)
		shrink.tween_property(button, "scale", Vector2(0.18, 0.18), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		shrink.tween_property(button, "modulate:a", 0.0, 0.24)
		if jellied:
			shrink.tween_property(button, "modulate", Color(0.72, 0.45, 0.82, 0.0), 0.24)
		shrink.chain().tween_callback(button.queue_free)
	var popup := Label.new()
	popup.text = Localizer.text(language_code, "jelly_float") if jellied else "+%.1fcm" % score
	popup.position = Vector2(unit.get("point", Vector2.ZERO)) - Vector2(62, 40)
	popup.size = Vector2(124, 42)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.add_theme_font_size_override("font_size", 20)
	popup.add_theme_color_override("font_color", Color("#dfa6ff") if jellied else Color("#fff3a0"))
	popup.add_theme_color_override("font_outline_color", Color("#4a2518"))
	popup.add_theme_constant_override("outline_size", 5)
	var field := unit.get("field") as Control
	if is_instance_valid(field):
		field.add_child(popup)
	else:
		unit_layer.add_child(popup)
	var float_tween := create_tween().bind_node(popup).set_parallel(true)
	float_tween.tween_property(popup, "position:y", popup.position.y - 44.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	float_tween.tween_property(popup, "modulate:a", 0.0, 0.65).set_delay(0.18)
	float_tween.chain().tween_callback(popup.queue_free)


func _update_unit_visual(unit_index: int) -> void:
	if unit_index < 0 or unit_index >= units.size():
		return
	var unit: Dictionary = units[unit_index]
	var button := unit.get("node") as TextureButton
	if not is_instance_valid(button):
		return
	# Only the 2D presentation is capped. The shared Succulent logic retains the
	# complete real diameter for scoring, however large the plant becomes.
	var diameter_cm := float(unit.get("size_cm", INITIAL_DIAMETER_CM))
	var size_px := clampf(30.0 + maxf(0.0, diameter_cm - INITIAL_DIAMETER_CM) * 1.16, 30.0, MAX_DISPLAY_SIZE_PX)
	button.size = Vector2(size_px, size_px)
	button.position = Vector2(unit.get("point", Vector2.ZERO)) - button.size * 0.5
	button.pivot_offset = button.size * 0.5


func _complete_battle() -> void:
	if resolution_emitted:
		return
	battle_active = false
	battle_phase = "result"
	resolution_emitted = true
	var won := player_score >= opponent_score
	result_label.text = Localizer.text(language_code, "jurejure_battle_win" if won else "jurejure_battle_loss")
	return_button.text = Localizer.text(language_code, "jurejure_battle_return")
	result_panel.visible = true
	result_panel.scale = Vector2(0.65, 0.65)
	result_panel.pivot_offset = result_panel.size * 0.5
	create_tween().bind_node(result_panel).tween_property(result_panel, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	battle_resolved.emit({
		"won": won,
		"player_score": player_score,
		"opponent_score": opponent_score
	})


func _update_scores() -> void:
	opponent_score_label.text = Localizer.text(language_code, "jurejure_battle_enemy_score", [opponent_score])
	player_score_label.text = Localizer.text(language_code, "jurejure_battle_player_score", [player_score])


func _accept_battle() -> void:
	choice_layer.visible = false
	battle_requested.emit()


func _decline_battle() -> void:
	visible = false
	choice_layer.visible = false
	battle_declined.emit()


func _return_to_habitat() -> void:
	visible = false
	battle_layer.visible = false
	result_panel.visible = false
	_clear_units()
	return_requested.emit()


func _clear_units() -> void:
	battle_active = false
	battle_phase = "idle"
	if sow_button != null:
		sow_button.visible = false
	_clear_seed_markers()
	for field in [opponent_field, player_field]:
		if field == null:
			continue
		for child in field.get_children():
			child.free()
	if logic_root != null:
		for child in logic_root.get_children():
			child.free()
	units.clear()
	pending_entries.clear()
	pending_textures.clear()


func debug_force_result(forced_player_score: float, forced_opponent_score: float) -> void:
	battle_active = false
	player_score = maxf(0.0, forced_player_score)
	opponent_score = maxf(0.0, forced_opponent_score)
	player_resolved = PLANTS_PER_SIDE
	opponent_resolved = PLANTS_PER_SIDE
	for unit_index in range(units.size()):
		var unit: Dictionary = units[unit_index]
		unit["done"] = true
		units[unit_index] = unit
	_update_scores()
	_complete_battle()


func _score_label(position_value: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.position = position_value
	label.size = Vector2(244, 58)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#452316"))
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_stylebox_override("normal", _box(Color(0.10, 0.045, 0.022, 0.82), Color(0.92, 0.72, 0.35, 0.72), 16, 2))
	return label


func _field_control(field_name: String, field_rect: Rect2) -> Control:
	var field := Control.new()
	field.name = field_name
	field.position = field_rect.position
	field.size = field_rect.size
	field.clip_contents = true
	field.mouse_filter = Control.MOUSE_FILTER_PASS
	return field


func _style_button(button: Button, color: Color, font_size: int) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("#4b2819") if color.get_luminance() > 0.55 else Color.WHITE)
	button.add_theme_stylebox_override("normal", _box(color, color.lightened(0.18), 20, 3))
	button.add_theme_stylebox_override("hover", _box(color.lightened(0.08), Color.WHITE, 20, 3))
	button.add_theme_stylebox_override("pressed", _box(color.darkened(0.10), color.lightened(0.10), 20, 3))


func _box(background: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.04, 0.02, 0.01, 0.34)
	style.shadow_size = 7
	return style
