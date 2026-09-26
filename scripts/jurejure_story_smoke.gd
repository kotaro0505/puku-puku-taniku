extends Node

const JureJureSystemClass = preload("res://scripts/jurejure_system.gd")


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	await _test_habitat_group_and_intro(game)
	await _test_battle_win_and_respawn(game)
	await _test_battle_loss(game)
	_test_act_one_stays_hostile(game)
	_test_creative_gate(game)
	await _test_save_compatibility(game)
	game._reset_progression_state()
	print("JUREJURE_STORY_SMOKE_OK group=three present=100_percent choice=true battle=6v6 sow=manual shared_rules=true win_reward=true pod_respawn=true loss=40_to_80_percent puku_clamped=true softening=disabled save=true")
	get_tree().quit()


func _prepare_act_one(game: Node) -> void:
	game._reset_progression_state()
	game.opening_story_overlay.visible = false
	game.intro_overlay.visible = false
	game.habitat_unlocked = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_tutorial_started = true
	game.habitat_tutorial_complete = true
	game.habitat_tutorial_returned_to_greenhouse = true
	game.mystery_items_acquired = true
	game.seed_shop_open = true
	game.original_catalog_gifted = true
	game.unlocked_series["base"] = true
	game.discovered = {"colorata": true, "affinis": true, "shaviana": true}
	game.species_get_counts = {"colorata": 1}
	game.habitat_returned_species = {"colorata": true, "affinis": true, "shaviana": true}
	game.habitat_wild_initialized = true
	game.habitat_wild_plants = _population(game, 10)
	game.current_mode = "habitat"
	game.jurejure_intro_complete = false
	game.jurejure_enabled = false
	game.jurejure_waiting_for_seed_pod_reward = false
	game.habitat_second_awakened = false
	game._apply_mode()


func _test_habitat_group_and_intro(game: Node) -> void:
	_prepare_act_one(game)
	assert(game.audio_manager.current_bgm_key == "habitat")
	assert(JureJureSystemClass.should_be_present(true, true, false, false))
	assert(not JureJureSystemClass.should_be_present(true, true, false, true))
	assert(not JureJureSystemClass.should_be_present(true, true, true, false))
	var group_item := _group_item(game)
	assert(not group_item.is_empty())
	var group := group_item.get("group_node") as Node3D
	assert(is_instance_valid(group))
	assert(group.get_node_or_null("Skunk") is Sprite3D)
	assert(group.get_node_or_null("Mouse") is Sprite3D)
	assert(group.get_node_or_null("Peccary") is Sprite3D)
	assert(_count_named_nodes(game, "JureJureEventDisplay") == 0)
	assert(FileAccess.file_exists("res://assets/jurejure/mouse.png"))
	assert(FileAccess.file_exists("res://assets/jurejure/skunk.png"))
	assert(FileAccess.file_exists("res://assets/jurejure/peccary.png"))
	assert(FileAccess.file_exists("res://assets/jurejure/puku-puku-battle-background.jpg"))

	game._on_jurejure_group_pressed()
	assert(game.scripted_dialog_kind == "jurejure_intro")
	assert(game.audio_manager.current_bgm_key == "jurejure")
	var all_text := ""
	for page in game.scripted_dialog_pages:
		all_text += str(page.get("text", ""))
	assert("勝手に持っていくなよ" in all_text)
	assert("絶滅したのよ" in all_text)
	assert("ぷくぷくバトル" in all_text)
	assert("まだ小さい" not in all_text)
	assert("守ってるわけじゃない" not in all_text)
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.jurejure_intro_complete and game.jurejure_enabled)
	assert(game.puku_puku_battle.visible)
	assert(game.puku_puku_battle.choice_layer.visible)
	assert(not game.puku_puku_battle.battle_active)
	assert(game.audio_manager.current_bgm_key == "jurejure")
	game.puku_puku_battle._decline_battle()
	assert(not game.puku_puku_battle.visible)
	assert(game.audio_manager.current_bgm_key == "habitat")
	assert(not _group_item(game).is_empty())

	game._on_jurejure_group_pressed()
	assert(game.scripted_dialog_kind == "jurejure_challenge")
	assert(game.audio_manager.current_bgm_key == "jurejure")
	assert(game.scripted_dialog_pages.size() == 2)
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.puku_puku_battle.choice_layer.visible)
	assert(game.audio_manager.current_bgm_key == "jurejure")

	var position_samples := {}
	var position_rng := RandomNumberGenerator.new()
	position_rng.seed = 20260926
	for sample in range(24):
		var point := JureJureSystemClass.choose_visit_point([], position_rng)
		assert(point in JureJureSystemClass.HABITAT_GROUP_POINTS)
		position_samples[str(point)] = true
	assert(position_samples.size() > 1)


func _test_battle_win_and_respawn(game: Node) -> void:
	game.puku_puku_battle._accept_battle()
	await get_tree().process_frame
	assert(game.audio_manager.current_bgm_key == "puku_battle")
	assert(game.puku_puku_battle.visible and not game.puku_puku_battle.battle_active)
	assert(game.puku_puku_battle.battle_phase == "awaiting_sow")
	assert(game.puku_puku_battle.units.is_empty())
	assert(game.puku_puku_battle.sow_button.visible)
	assert(is_equal_approx(game.puku_puku_battle.player_score, 0.0))
	assert(is_equal_approx(game.puku_puku_battle.opponent_score, 0.0))
	game.puku_puku_battle.debug_sow_immediately()
	assert(game.puku_puku_battle.battle_active)
	assert(game.puku_puku_battle.battle_phase == "growing")
	assert(game.puku_puku_battle.units.size() == JureJureSystemClass.BATTLE_PLANTS_PER_SIDE * 2)
	var player_units := 0
	var opponent_units := 0
	for unit in game.puku_puku_battle.units:
		if bool(unit.get("opponent", false)):
			opponent_units += 1
		else:
			player_units += 1
	assert(player_units == 6 and opponent_units == 6)
	assert(game.puku_puku_battle.battle_layer.get_node_or_null("BattleBackground") is TextureRect)

	game.puku_puku_battle.debug_force_result(420.0, 180.0)
	await get_tree().process_frame
	assert(game.audio_manager.current_bgm_key == "puku_battle")
	assert(game.jurejure_waiting_for_seed_pod_reward)
	assert(game.jurejure_battle_count == 1 and game.jurejure_battle_win_count == 1)
	var reward_id: String = game.jurejure_pending_reward_species_id
	assert(not reward_id.is_empty())
	assert(bool(game.discovered.get(reward_id, false)))
	assert(int(game.species_get_counts.get(reward_id, 0)) == 1)
	assert(bool(game.habitat_returned_species.get(reward_id, false)))
	assert(game.jurejure_return_event_complete == false)
	assert(game.habitat_second_awakened == false)
	assert(_group_item(game).is_empty())

	game.puku_puku_battle._return_to_habitat()
	assert(game.audio_manager.current_bgm_key == "habitat")
	assert(game.scripted_dialog_kind == "jurejure_battle_win")
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.species_get_overlay.visible)
	game.species_get_overlay.close_overlay()
	await get_tree().process_frame

	game.puku_gauge_cm = game.SEED_POD_GAUGE_TARGET_CM - 10.0
	var bags_before: int = game.normal_seed_bags
	var earned: int = game.add_seed_pod_gauge_cm(10.0, false, false)
	assert(earned == game.SEED_POD_GAUGE_REWARD_BAGS)
	assert(game.normal_seed_bags == bags_before + game.SEED_POD_GAUGE_REWARD_BAGS)
	assert(not game.jurejure_waiting_for_seed_pod_reward)
	game.current_mode = "greenhouse"
	game._apply_mode()
	game.current_mode = "habitat"
	game._apply_mode()
	assert(not _group_item(game).is_empty())


func _test_battle_loss(game: Node) -> void:
	game.puku_points = 1
	game.habitat_wild_plants = _population(game, 10)
	var settled_before: Dictionary = game.habitat_returned_species.duplicate(true)
	game._on_jurejure_group_pressed()
	assert(game.scripted_dialog_kind == "jurejure_challenge")
	_finish_dialog(game)
	await get_tree().process_frame
	game.puku_puku_battle._accept_battle()
	await get_tree().process_frame
	assert(game.audio_manager.current_bgm_key == "puku_battle")
	assert(game.puku_puku_battle.units.is_empty())
	game.puku_puku_battle.debug_sow_immediately()
	game.puku_puku_battle.debug_force_result(20.0, 260.0)
	await get_tree().process_frame
	var remaining: int = game.habitat_wild_plants.size()
	assert(remaining >= 2 and remaining <= 6)
	assert(game.puku_points == 0)
	assert(game.habitat_returned_species == settled_before)
	assert(not game.jurejure_waiting_for_seed_pod_reward)
	assert(not _group_item(game).is_empty())
	game.puku_puku_battle._return_to_habitat()
	assert(game.audio_manager.current_bgm_key == "habitat")
	assert(game.scripted_dialog_kind == "jurejure_battle_loss")
	_finish_dialog(game)
	await get_tree().process_frame

	game.puku_points = 0
	game.habitat_wild_plants = _population(game, 5)
	var zero_penalty: Dictionary = game._apply_jurejure_battle_loss()
	assert(int(zero_penalty.get("puku_lost", -1)) == 0)
	assert(game.puku_points == 0)


func _test_act_one_stays_hostile(game: Node) -> void:
	game.scripted_dialog_kind = ""
	game.jurejure_growth_event_mask = 0
	game._start_jurejure_growth_event(JureJureSystemClass.GROWTH_MID)
	game._start_jurejure_growth_event(JureJureSystemClass.GROWTH_LATE)
	assert(game.scripted_dialog_kind.is_empty())
	assert(game.jurejure_growth_event_mask == 3)


func _test_save_compatibility(game: Node) -> void:
	game.habitat_second_awakened = false
	game.habitat_second_awakening_complete = false
	game.jurejure_intro_complete = true
	game.jurejure_enabled = true
	game.jurejure_waiting_for_seed_pod_reward = true
	game.jurejure_battle_count = 7
	game.jurejure_battle_win_count = 4
	game.active_jurejure_event = {"individual_id": "legacy_target", "deadline_unix": 1.0}
	game._save()
	game.jurejure_waiting_for_seed_pod_reward = false
	game.jurejure_battle_count = 0
	game.jurejure_battle_win_count = 0
	game.active_jurejure_event = {"individual_id": "stale"}
	game._load_save()
	assert(game.jurejure_waiting_for_seed_pod_reward)
	assert(game.jurejure_battle_count == 7)
	assert(game.jurejure_battle_win_count == 4)
	assert(game.active_jurejure_event.is_empty())


func _test_creative_gate(game: Node) -> void:
	game.habitat_second_awakened = false
	game.discovered = {"colorata": true}
	game.greenhouse_available = {"colorata": true}
	game.unlocked_series["base"] = true
	game.unlocked_series["metal"] = true
	var original: Dictionary = game._catalog_entry("colorata")
	var creative: Dictionary = game._catalog_entry("metal_laui")
	assert(not original.is_empty() and not creative.is_empty())
	assert(game._species_available_in_current_era(original))
	assert(not game._species_available_in_current_era(creative))
	game.discovered["metal_laui"] = true
	assert(game._species_available_in_current_era(creative))
	game.discovered.erase("metal_laui")
	game.habitat_second_awakened = true
	assert(game._species_available_in_current_era(creative))


func _group_item(game: Node) -> Dictionary:
	for item in game.habitat_pickups:
		if str(item.get("kind", "")) == "jurejure_group":
			return item
	return {}


func _count_named_nodes(root: Node, target_name: String) -> int:
	var count := 1 if root.name == target_name else 0
	for child in root.get_children():
		count += _count_named_nodes(child, target_name)
	return count


func _finish_dialog(game: Node) -> void:
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()


func _population(game: Node, count: int) -> Array[Dictionary]:
	var source: Array = []
	var valid_species_ids: Array[String] = ["colorata"]
	var now := Time.get_unix_time_from_system()
	for index in range(count):
		source.append(_plant("battle_target_%02d" % index, 8.0 + float(index), now, index))
	return game.HabitatWildSystemClass.normalize_saved(source, valid_species_ids, now)


func _plant(individual_id: String, diameter: float, now: float, index: int) -> Dictionary:
	return {
		"individual_id": individual_id,
		"species_id": "colorata",
		"diameter_cm": diameter,
		"jellied": false,
		"tutorial": false,
		"jelly_immune": false,
		"story_protected": false,
		"base_growth_rate": 1.0,
		"jelly_risk_curve": 1.0,
		"mature_diameter_cm": 30.8,
		"jelly_threshold": 999999.0,
		"jelly_hazard_accumulated": 0.0,
		"jelly_elapsed_seconds": 0.0,
		"last_updated_unix": now,
		"spawned_unix": now,
		"habitat_timing_version": 3,
		"panorama_x": 90.0 + float(index) * 105.0,
		"panorama_y": 405.0 + float(index % 3) * 11.0,
		"position_validated": true
	}
