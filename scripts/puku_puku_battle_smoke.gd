extends Node

const BattleClass = preload("res://scripts/puku_puku_battle.gd")
const SucculentClass = preload("res://scripts/succulent.gd")
const JellyBalanceClass = preload("res://scripts/jelly_balance.gd")

const SAMPLE_SPECIES := {
	"species_id": "colorata",
	"name_ja": "コロラータ",
	"rarity": "通常",
	"visual_variant": "colorata",
	"colors": ["7f9f91", "d35f6f"]
}
const SAMPLE_COUNT := 600
const SIMULATION_STEP := 1.0 / 30.0
const OPPONENT_RIGHT_CHARACTER_MAJOR_RECT := Rect2(360, 142, 190, 150)
const PLAYER_RIGHT_CHARACTER_MAJOR_RECT := Rect2(382, 590, 170, 150)


func _ready() -> void:
	JellyBalanceClass.reset_formal()
	var battle := BattleClass.new()
	add_child(battle)
	await get_tree().process_frame
	var texture := load("res://assets/plants/sprite-colorata.png") as Texture2D
	_verify_alpha_hit_mask()
	battle.start_battle([SAMPLE_SPECIES], {"colorata": texture}, "ja", 20260926)
	_verify_score_label_layout_and_content(battle)
	assert(battle.player_points.size() == BattleClass.MAX_ACTIVE_PER_SIDE and battle.opponent_points.size() == BattleClass.MAX_ACTIVE_PER_SIDE)
	_verify_soil_points(battle.player_points, false)
	_verify_soil_points(battle.opponent_points, true)
	var first_player_layout: Array[Vector2] = battle.player_points.duplicate()
	var layout_probe := BattleClass.new()
	add_child(layout_probe)
	await get_tree().process_frame
	layout_probe.start_battle([SAMPLE_SPECIES], {"colorata": texture}, "ja", 20260927)
	_verify_soil_points(layout_probe.player_points, false)
	_verify_soil_points(layout_probe.opponent_points, true)
	assert(layout_probe.player_points != first_player_layout)
	for layout_seed in range(40):
		layout_probe.rng.seed = 310000 + layout_seed
		_verify_soil_points(layout_probe._generate_side_points(false), false)
		_verify_soil_points(layout_probe._generate_side_points(true), true)
	layout_probe.queue_free()

	# The dedicated screen starts on two empty dirt fields. No plant or score is
	# created until the player explicitly sows the battle seeds.
	assert(battle.battle_phase == "awaiting_sow")
	assert(not battle.battle_active)
	assert(battle.units.is_empty())
	assert(battle.opponent_field.get_child_count() == 0)
	assert(battle.player_field.get_child_count() == 0)
	assert(is_zero_approx(battle.opponent_score) and is_zero_approx(battle.player_score))
	battle._on_sow_pressed()
	assert(battle.battle_phase == "sowing")
	assert(_marker_count(battle) == BattleClass.MAX_ACTIVE_PER_SIDE * 2)
	_verify_seed_markers_match_points(battle)
	assert(is_zero_approx(battle.opponent_score) and is_zero_approx(battle.player_score))
	await get_tree().create_timer(BattleClass.SOW_SECONDS + BattleClass.GERMINATION_SECONDS + 0.08).timeout
	assert(battle.battle_phase == "growing" and battle.battle_active)
	assert(battle.units.size() == BattleClass.MAX_ACTIVE_PER_SIDE * 2)
	assert(is_zero_approx(battle.opponent_score) and is_zero_approx(battle.player_score))

	var player_count := 0
	var opponent_count := 0
	for unit in battle.units:
		if bool(unit.get("opponent", false)):
			opponent_count += 1
		else:
			player_count += 1
		assert(unit.get("logic").get_script() == SucculentClass)
		assert(not unit.has("growth_rate"))
		assert(not unit.has("jelly_cm"))
		assert(not unit.has("ai_harvest_cm"))
		assert(float(unit.get("size_cm", 0.0)) < 2.0)
		var live_size_label := unit.get("size_label") as Label
		assert(is_instance_valid(live_size_label))
		assert(live_size_label.text == "%.1fcm" % float(unit.get("size_cm", 0.0)))
	assert(player_count == BattleClass.MAX_ACTIVE_PER_SIDE and opponent_count == BattleClass.MAX_ACTIVE_PER_SIDE)
	_verify_player_hit_targets(battle)
	assert(battle.player_spawned == BattleClass.MAX_ACTIVE_PER_SIDE and battle.opponent_spawned == BattleClass.MAX_ACTIVE_PER_SIDE)
	var growth_unit: Dictionary = battle.units[0]
	var initial_visual_size: float = float((growth_unit.get("node") as TextureButton).size.x)
	for unit_index in range(battle.units.size()):
		var growing_unit: Dictionary = battle.units[unit_index]
		growing_unit.get("logic").jelly_checks_enabled = false
		if bool(growing_unit.get("opponent", false)):
			growing_unit["ai_harvest_age"] = INF
		battle.units[unit_index] = growing_unit
	battle._process(4.0)
	growth_unit = battle.units[0]
	assert(float(growth_unit.get("size_cm", 0.0)) > 6.4)
	assert(float((growth_unit.get("node") as TextureButton).size.x) > initial_visual_size + 8.0)
	assert((growth_unit.get("size_label") as Label).text == "%.1fcm" % float(growth_unit.get("size_cm", 0.0)))

	_verify_shared_growth_source()
	_verify_unclipped_layout(battle)
	_verify_jelly_precedes_ai_harvest(battle)
	await _verify_sequential_refill(texture)

	var ai_stats := _simulate_ai_population(73000)
	var same_policy_reference := _simulate_ai_population(73000)
	assert(int(ai_stats.jellied) > 0)
	assert(int(ai_stats.harvested) + int(ai_stats.jellied) == SAMPLE_COUNT)
	assert(is_equal_approx(float(ai_stats.jelly_rate), float(same_policy_reference.jelly_rate)))
	assert(is_equal_approx(float(ai_stats.average_harvest_cm), float(same_policy_reference.average_harvest_cm)))
	assert(is_equal_approx(float(ai_stats.average_score), float(same_policy_reference.average_score)))

	print(
		"PUKU_PUKU_BATTLE_SMOKE_OK sow=manual active=6v6 total=12v12 refill=true random_soil=true shared_growth=true shared_jelly=true " +
		"ai_jelly_rate=%.3f ai_average_harvest_cm=%.3f ai_average_score=%.3f condition_delta=0.000 main_scale_visual=true unclipped_plants=true alpha_hit=true frontmost_z=true" % [
			float(ai_stats.jelly_rate),
			float(ai_stats.average_harvest_cm),
			float(ai_stats.average_score)
		]
	)
	get_tree().quit()


func _verify_score_label_layout_and_content(battle: Control) -> void:
	var expected_x: float = BattleClass.BATTLE_VIEW_WIDTH - BattleClass.SCORE_LABEL_RIGHT_MARGIN - BattleClass.SCORE_LABEL_SIZE.x
	var expected_opponent_position := Vector2(expected_x, BattleClass.OPPONENT_FIELD_RECT.position.y - BattleClass.SCORE_LABEL_FIELD_TOP_GAP - BattleClass.OPPONENT_SCORE_RAISE)
	var expected_player_position := Vector2(expected_x, BattleClass.PLAYER_FIELD_RECT.position.y - BattleClass.SCORE_LABEL_FIELD_TOP_GAP)
	assert(battle.opponent_score_label.size == BattleClass.SCORE_LABEL_SIZE)
	assert(battle.player_score_label.size == BattleClass.SCORE_LABEL_SIZE)
	assert(battle.opponent_score_label.position == expected_opponent_position)
	assert(battle.player_score_label.position == expected_player_position)
	assert(is_equal_approx(BattleClass.OPPONENT_FIELD_RECT.position.y - battle.opponent_score_label.position.y, BattleClass.SCORE_LABEL_FIELD_TOP_GAP + BattleClass.OPPONENT_SCORE_RAISE))
	assert(is_equal_approx(BattleClass.PLAYER_FIELD_RECT.position.y - battle.player_score_label.position.y, BattleClass.SCORE_LABEL_FIELD_TOP_GAP))
	assert(is_equal_approx(battle.opponent_score_label.position.x + battle.opponent_score_label.size.x, BattleClass.BATTLE_VIEW_WIDTH - BattleClass.SCORE_LABEL_RIGHT_MARGIN))
	assert(is_equal_approx(battle.player_score_label.position.x + battle.player_score_label.size.x, BattleClass.BATTLE_VIEW_WIDTH - BattleClass.SCORE_LABEL_RIGHT_MARGIN))
	assert(not Rect2(battle.opponent_score_label.position, battle.opponent_score_label.size).intersects(OPPONENT_RIGHT_CHARACTER_MAJOR_RECT))
	assert(not Rect2(battle.player_score_label.position, battle.player_score_label.size).intersects(PLAYER_RIGHT_CHARACTER_MAJOR_RECT))
	assert(Rect2(Vector2.ZERO, Vector2(576, 1024)).encloses(Rect2(battle.opponent_score_label.position, battle.opponent_score_label.size)))
	assert(Rect2(Vector2.ZERO, Vector2(576, 1024)).encloses(Rect2(battle.player_score_label.position, battle.player_score_label.size)))
	assert(battle.result_panel.position == BattleClass.RESULT_PANEL_POSITION)
	assert(battle.result_panel.position.y + battle.result_panel.size.y <= battle.player_score_label.position.y - 12.0)
	var original_language: String = battle.language_code
	var original_opponent_score: float = battle.opponent_score
	var original_player_score: float = battle.player_score
	for score in [0.0, 38.3, 87.8, 999.9]:
		battle.opponent_score = score
		battle.player_score = score
		for locale in ["ja", "hiragana", "en"]:
			battle.language_code = locale
			battle._update_scores()
			var expected_text := "%.1f cm" % score
			assert(battle.opponent_score_label.text == expected_text)
			assert(battle.player_score_label.text == expected_text)
			_verify_score_text_fits(battle.opponent_score_label)
			_verify_score_text_fits(battle.player_score_label)
	battle.language_code = original_language
	battle.opponent_score = original_opponent_score
	battle.player_score = original_player_score
	battle._update_scores()


func _verify_score_text_fits(label: Label) -> void:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var text_width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	assert(text_width <= label.size.x - 20.0)


func _verify_alpha_hit_mask() -> void:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 0.0))
	image.set_pixel(1, 2, Color(0.3, 0.8, 0.4, 1.0))
	var texture := ImageTexture.create_from_image(image)
	var mask := BattleClass.texture_alpha_click_mask(texture)
	assert(mask != null)
	assert(not mask.get_bit(0, 0))
	assert(mask.get_bit(1, 2))


func _verify_player_hit_targets(battle: Control) -> void:
	var player_units: Array[Dictionary] = []
	for unit_value in battle.units:
		var unit: Dictionary = unit_value
		if bool(unit.get("opponent", false)):
			continue
		var button := unit.get("node") as TextureButton
		assert(is_instance_valid(button))
		assert(button.texture_click_mask != null)
		assert(button.mouse_filter == Control.MOUSE_FILTER_STOP)
		assert(button.z_index == int(float((unit.get("point", Vector2.ZERO) as Vector2).y)))
		player_units.append(unit)
	assert(player_units.size() == BattleClass.MAX_ACTIVE_PER_SIDE)
	player_units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int((a.get("node") as TextureButton).z_index) < int((b.get("node") as TextureButton).z_index)
	)
	assert(int((player_units.back().get("node") as TextureButton).z_index) >= int((player_units.front().get("node") as TextureButton).z_index))


func _verify_shared_growth_source() -> void:
	var normal_reference := SucculentClass.new()
	var battle_reference := SucculentClass.new()
	normal_reference.setup(SAMPLE_SPECIES, 445566, null, null, true)
	battle_reference.setup(SAMPLE_SPECIES, 445566, null, null, true)
	normal_reference.jelly_checks_enabled = false
	battle_reference.jelly_checks_enabled = false
	for tick in range(240):
		normal_reference.simulate(1.0 / 60.0)
		battle_reference.simulate(1.0 / 60.0)
	assert(is_equal_approx(normal_reference.diameter_cm, battle_reference.diameter_cm))
	assert(is_equal_approx(normal_reference.age, 4.0))
	assert(normal_reference.diameter_cm > 6.4 and normal_reference.diameter_cm < 7.8)
	assert(is_equal_approx(normal_reference.growth_rate, 1.0))
	normal_reference.free()
	battle_reference.free()


func _verify_sequential_refill(texture: Texture2D) -> void:
	var battle := BattleClass.new()
	add_child(battle)
	await get_tree().process_frame
	battle.start_battle([SAMPLE_SPECIES], {"colorata": texture}, "ja", 20260928)
	battle.debug_sow_immediately()
	var first_player_index := _first_live_unit_index(battle, false)
	var first_opponent_index := _first_live_unit_index(battle, true)
	assert(first_player_index >= 0 and first_opponent_index >= 0)
	battle._resolve_unit(first_player_index, false)
	battle._resolve_unit(first_opponent_index, true)
	assert(battle.player_resolved == 1 and battle.opponent_resolved == 1)
	assert(battle.player_spawned == 7 and battle.opponent_spawned == 7)
	assert(_marker_count(battle) == 2)
	await get_tree().create_timer(BattleClass.SOW_SECONDS * 0.72).timeout
	assert(_live_unit_count(battle, false) == BattleClass.MAX_ACTIVE_PER_SIDE)
	assert(_live_unit_count(battle, true) == BattleClass.MAX_ACTIVE_PER_SIDE)
	assert(battle.units.size() == BattleClass.MAX_ACTIVE_PER_SIDE * 2 + 2)
	# Drain both queues one slot at a time. Each side must create and resolve all
	# twelve plants without ever exceeding six simultaneously alive.
	while battle.player_resolved < BattleClass.PLANTS_PER_SIDE or battle.opponent_resolved < BattleClass.PLANTS_PER_SIDE:
		if battle.player_resolved < BattleClass.PLANTS_PER_SIDE:
			var player_index := _first_live_unit_index(battle, false)
			assert(player_index >= 0)
			battle._resolve_unit(player_index, false)
		if battle.opponent_resolved < BattleClass.PLANTS_PER_SIDE:
			var opponent_index := _first_live_unit_index(battle, true)
			assert(opponent_index >= 0)
			battle._resolve_unit(opponent_index, false)
		assert(_live_unit_count(battle, false) <= BattleClass.MAX_ACTIVE_PER_SIDE)
		assert(_live_unit_count(battle, true) <= BattleClass.MAX_ACTIVE_PER_SIDE)
		if battle.player_resolved < BattleClass.PLANTS_PER_SIDE or battle.opponent_resolved < BattleClass.PLANTS_PER_SIDE:
			await get_tree().create_timer(BattleClass.SOW_SECONDS * 0.72).timeout
	assert(battle.player_spawned == BattleClass.PLANTS_PER_SIDE)
	assert(battle.opponent_spawned == BattleClass.PLANTS_PER_SIDE)
	assert(battle.player_resolved == BattleClass.PLANTS_PER_SIDE)
	assert(battle.opponent_resolved == BattleClass.PLANTS_PER_SIDE)
	battle.queue_free()


func _verify_unclipped_layout(battle: Control) -> void:
	assert(not battle.opponent_field.clip_contents)
	assert(not battle.player_field.clip_contents)
	assert(BattleClass.OPPONENT_FIELD_RECT.end.y < BattleClass.PLAYER_FIELD_RECT.position.y)
	for unit_index in range(battle.units.size()):
		var unit: Dictionary = battle.units[unit_index]
		var opponent := bool(unit.get("opponent", false))
		var point: Vector2 = unit.get("point", Vector2.ZERO)
		assert(BattleClass.point_is_in_safe_soil(point, opponent))
		var logic = unit.get("logic")
		logic.diameter_cm = 20.0
		unit["size_cm"] = 20.0
		battle.units[unit_index] = unit
		battle._update_unit_visual(unit_index)
		var button := unit.get("node") as TextureButton
		assert(button.size.x > 106.0)
		assert(is_equal_approx(button.size.x, BattleClass.display_size_for_diameter(20.0)))
		logic.diameter_cm = 1000.0
		unit["size_cm"] = 1000.0
		battle.units[unit_index] = unit
		battle._update_unit_visual(unit_index)
		var size_label := unit.get("size_label") as Label
		var field := unit.get("field") as Control
		assert(is_equal_approx(float(logic.diameter_cm), 1000.0))
		assert(is_equal_approx(button.size.x, BattleClass.MAX_DISPLAY_SIZE_PX))
		assert(button.size.x > 106.0)
		assert((button.position + button.size * 0.5).is_equal_approx(point))
		assert(size_label.position.x >= -0.01 and size_label.position.y >= -0.01)
		assert(size_label.position.x + size_label.size.x <= field.size.x + 0.01)
		assert(size_label.position.y + size_label.size.y <= field.size.y + 0.01)
		assert(button.position.y < 0.0 or button.position.x < 0.0 or button.position.x + button.size.x > field.size.x)


func _verify_jelly_precedes_ai_harvest(battle: Control) -> void:
	var target_index := -1
	for unit_index in range(battle.units.size()):
		if bool(battle.units[unit_index].get("opponent", false)):
			target_index = unit_index
			break
	assert(target_index >= 0)
	var unit: Dictionary = battle.units[target_index]
	var logic = unit.get("logic")
	logic.state = "growing"
	logic.jelly_checks_enabled = true
	logic.age = 1.0
	logic.growth_time = 1.0
	logic.jelly_safe_end_seconds = 0.0
	logic.jelly_ramp_end_seconds = 0.01
	logic.jelly_final_chance = 0.999999999
	logic.rng.seed = 818181
	unit["done"] = false
	unit["jellied"] = false
	unit["ai_harvest_age"] = 0.0
	battle.units[target_index] = unit
	battle._process(1.0)
	var resolved: Dictionary = battle.units[target_index]
	assert(bool(resolved.get("done", false)))
	assert(bool(resolved.get("jellied", false)))
	assert(is_zero_approx(float(resolved.get("score", -1.0))))


func _simulate_ai_population(seed_offset: int) -> Dictionary:
	var jellied := 0
	var harvested := 0
	var harvest_total := 0.0
	var score_total := 0.0
	for sample in range(SAMPLE_COUNT):
		var plant := SucculentClass.new()
		var plant_seed := seed_offset + sample * 17
		plant.setup(SAMPLE_SPECIES, plant_seed, null, null, true)
		var plan_rng := RandomNumberGenerator.new()
		plan_rng.seed = plant_seed + 900000
		var plan := BattleClass.ai_harvest_plan(
			plant.jelly_safe_end_seconds,
			plant.jelly_ramp_end_seconds,
			plan_rng.randf(),
			plan_rng.randf()
		)
		while plant.state == "growing" and plant.age < 90.0:
			# This ordering is identical to the live battle: shared jelly simulation
			# first, then (only if still alive) the AI harvest decision.
			plant.simulate(SIMULATION_STEP)
			if plant.state == "growing" and plant.age >= float(plan.age):
				harvested += 1
				harvest_total += plant.diameter_cm
				score_total += plant.diameter_cm
				plant.harvest()
		if plant.state == "jelly":
			jellied += 1
		plant.free()
	return {
		"jellied": jellied,
		"harvested": harvested,
		"jelly_rate": float(jellied) / float(SAMPLE_COUNT),
		"average_harvest_cm": harvest_total / maxf(1.0, float(harvested)),
		"average_score": score_total / float(SAMPLE_COUNT)
	}


func _marker_count(battle: Control) -> int:
	var count := 0
	for field in [battle.opponent_field, battle.player_field]:
		for child in field.get_children():
			if child.is_in_group("battle_seed_marker"):
				count += 1
	return count


func _verify_soil_points(points: Array[Vector2], opponent: bool) -> void:
	assert(points.size() == BattleClass.MAX_ACTIVE_PER_SIDE)
	for index in range(points.size()):
		assert(BattleClass.point_is_in_safe_soil(points[index], opponent))
		for other_index in range(index):
			assert(points[index].distance_to(points[other_index]) >= BattleClass.MIN_POINT_SPACING_PX - 0.01)


func _verify_seed_markers_match_points(battle: Control) -> void:
	var opponent_seen := 0
	var player_seen := 0
	for field in [battle.opponent_field, battle.player_field]:
		for child in field.get_children():
			if not child.is_in_group("battle_seed_marker"):continue
			var opponent := bool(child.get_meta("opponent", false))
			var point: Vector2 = child.get_meta("soil_point", Vector2.ZERO)
			var expected: Array[Vector2] = battle.opponent_points if opponent else battle.player_points
			assert(point in expected)
			if opponent:opponent_seen += 1
			else:player_seen += 1
	assert(opponent_seen == BattleClass.MAX_ACTIVE_PER_SIDE and player_seen == BattleClass.MAX_ACTIVE_PER_SIDE)


func _first_live_unit_index(battle: Control, opponent: bool) -> int:
	for unit_index in range(battle.units.size()):
		var unit: Dictionary = battle.units[unit_index]
		if bool(unit.get("opponent", false)) == opponent and not bool(unit.get("done", false)):
			return unit_index
	return -1


func _live_unit_count(battle: Control, opponent: bool) -> int:
	var count := 0
	for unit in battle.units:
		if bool(unit.get("opponent", false)) == opponent and not bool(unit.get("done", false)):
			count += 1
	return count
