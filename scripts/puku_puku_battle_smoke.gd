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


func _ready() -> void:
	JellyBalanceClass.reset_formal()
	var battle := BattleClass.new()
	add_child(battle)
	await get_tree().process_frame
	var texture := load("res://assets/plants/sprite-colorata.png") as Texture2D
	battle.start_battle([SAMPLE_SPECIES], {"colorata": texture}, "ja", 20260926)

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
	assert(_marker_count(battle) == BattleClass.PLANTS_PER_SIDE * 2)
	assert(is_zero_approx(battle.opponent_score) and is_zero_approx(battle.player_score))
	await get_tree().create_timer(BattleClass.SOW_SECONDS + BattleClass.GERMINATION_SECONDS + 0.08).timeout
	assert(battle.battle_phase == "growing" and battle.battle_active)
	assert(battle.units.size() == BattleClass.PLANTS_PER_SIDE * 2)
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
	assert(player_count == 6 and opponent_count == 6)

	_verify_shared_growth_source()
	_verify_clipped_layout(battle)
	_verify_jelly_precedes_ai_harvest(battle)

	var ai_stats := _simulate_ai_population(73000)
	var same_policy_reference := _simulate_ai_population(73000)
	assert(int(ai_stats.jellied) > 0)
	assert(int(ai_stats.harvested) + int(ai_stats.jellied) == SAMPLE_COUNT)
	assert(is_equal_approx(float(ai_stats.jelly_rate), float(same_policy_reference.jelly_rate)))
	assert(is_equal_approx(float(ai_stats.average_harvest_cm), float(same_policy_reference.average_harvest_cm)))
	assert(is_equal_approx(float(ai_stats.average_score), float(same_policy_reference.average_score)))

	print(
		"PUKU_PUKU_BATTLE_SMOKE_OK sow=manual plants=6v6 shared_growth=true shared_jelly=true " +
		"ai_jelly_rate=%.3f ai_average_harvest_cm=%.3f ai_average_score=%.3f condition_delta=0.000 clipped_fields=true" % [
			float(ai_stats.jelly_rate),
			float(ai_stats.average_harvest_cm),
			float(ai_stats.average_score)
		]
	)
	get_tree().quit()


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


func _verify_clipped_layout(battle: Control) -> void:
	assert(battle.opponent_field.clip_contents)
	assert(battle.player_field.clip_contents)
	assert(BattleClass.OPPONENT_FIELD_RECT.end.y < BattleClass.PLAYER_FIELD_RECT.position.y)
	for unit_index in range(battle.units.size()):
		var unit: Dictionary = battle.units[unit_index]
		var logic = unit.get("logic")
		logic.diameter_cm = 1000.0
		unit["size_cm"] = 1000.0
		battle.units[unit_index] = unit
		battle._update_unit_visual(unit_index)
		var button := unit.get("node") as TextureButton
		var field := unit.get("field") as Control
		assert(is_equal_approx(float(logic.diameter_cm), 1000.0))
		assert(button.size.x <= BattleClass.MAX_DISPLAY_SIZE_PX + 0.01)
		assert(button.position.x >= -0.01 and button.position.y >= -0.01)
		assert(button.position.x + button.size.x <= field.size.x + 0.01)
		assert(button.position.y + button.size.y <= field.size.y + 0.01)


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
