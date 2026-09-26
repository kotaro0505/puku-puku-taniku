class_name PukuPukuBattle
extends Control

signal battle_requested
signal battle_declined
signal battle_resolved(result: Dictionary)
signal return_requested

const Localizer = preload("res://scripts/game_localizer.gd")
const BACKGROUND_PATH := "res://assets/jurejure/puku-puku-battle-background.jpg"
const PLANTS_PER_SIDE := 12

const OPPONENT_POINTS := [
	Vector2(62, 306), Vector2(150, 292), Vector2(240, 315), Vector2(330, 292), Vector2(420, 315), Vector2(510, 298),
	Vector2(88, 410), Vector2(176, 390), Vector2(266, 416), Vector2(356, 392), Vector2(446, 416), Vector2(522, 392)
]
const PLAYER_POINTS := [
	Vector2(62, 800), Vector2(150, 784), Vector2(240, 810), Vector2(330, 786), Vector2(420, 810), Vector2(510, 790),
	Vector2(88, 912), Vector2(176, 890), Vector2(266, 920), Vector2(356, 894), Vector2(446, 920), Vector2(522, 896)
]

var language_code := "ja"
var choice_layer: Control
var battle_layer: Control
var unit_layer: Control
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
	opponent_score_label = _score_label(Vector2(316, 202), Color("#ffd6b1"))
	battle_layer.add_child(opponent_score_label)
	player_score_label = _score_label(Vector2(316, 680), Color("#e0ffd2"))
	battle_layer.add_child(player_score_label)

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
	battle_active = true
	var usable_entries: Array[Dictionary] = entries.duplicate(true)
	if usable_entries.is_empty():
		battle_active = false
		return
	for index in range(PLANTS_PER_SIDE):
		_create_unit(false, index, usable_entries, textures)
		_create_unit(true, index, usable_entries, textures)
	_update_scores()
	move_to_front()


func _create_unit(opponent: bool, point_index: int, entries: Array[Dictionary], textures: Dictionary) -> void:
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
	unit_layer.add_child(button)
	var jelly_cm := rng.randf_range(34.0, 58.0)
	var unit := {
		"node": button,
		"opponent": opponent,
		"point": (OPPONENT_POINTS if opponent else PLAYER_POINTS)[point_index],
		"size_cm": 1.6,
		"growth_rate": rng.randf_range(5.2, 7.4),
		"jelly_cm": jelly_cm,
		"ai_harvest_cm": rng.randf_range(18.0, jelly_cm - 2.5),
		"done": false,
		"species_id": species_id
	}
	var unit_index := units.size()
	units.append(unit)
	if not opponent:
		button.pressed.connect(_harvest_player.bind(unit_index))
	_update_unit_visual(unit_index)


func _process(delta: float) -> void:
	if not battle_active:
		return
	for unit_index in range(units.size()):
		var unit: Dictionary = units[unit_index]
		if bool(unit.get("done", false)):
			continue
		unit["size_cm"] = float(unit.get("size_cm", 1.6)) + float(unit.get("growth_rate", 6.0)) * delta
		units[unit_index] = unit
		if bool(unit.get("opponent", false)) and float(unit["size_cm"]) >= float(unit.get("ai_harvest_cm", 22.0)):
			_resolve_unit(unit_index, false)
		elif float(unit["size_cm"]) >= float(unit.get("jelly_cm", 45.0)):
			_resolve_unit(unit_index, true)
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
	unit["done"] = true
	units[unit_index] = unit
	var opponent := bool(unit.get("opponent", false))
	var score := 0.0 if jellied else float(unit.get("size_cm", 0.0))
	if opponent:
		opponent_resolved += 1
		opponent_score += score
	else:
		player_resolved += 1
		player_score += score
	_update_scores()
	_show_unit_result(unit, score, jellied)
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
	var size_px := clampf(31.0 + float(unit.get("size_cm", 1.6)) * 1.02, 34.0, 88.0)
	button.size = Vector2(size_px, size_px)
	button.position = Vector2(unit.get("point", Vector2.ZERO)) - button.size * 0.5
	button.pivot_offset = button.size * 0.5


func _complete_battle() -> void:
	if resolution_emitted:
		return
	battle_active = false
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
	return_requested.emit()


func _clear_units() -> void:
	battle_active = false
	for child in unit_layer.get_children():
		child.free()
	units.clear()


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
