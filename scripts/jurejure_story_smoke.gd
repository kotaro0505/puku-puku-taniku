extends Node

const JureJureSystemClass = preload("res://scripts/jurejure_system.gd")


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	await _test_intro_gate(game)
	_test_target_rules(game)
	_test_creative_gate(game)
	game._reset_progression_state()
	print("JUREJURE_STORY_SMOKE_OK intro=true active_max=1 defense=true habitat_take=true harvest_race=retired beacon=retired settlement_persists=true save=true creative_gate=true")
	get_tree().quit()


func _test_intro_gate(game: Node) -> void:
	game._reset_progression_state()
	game.current_mode = "habitat"
	game.habitat_unlocked = true
	game.habitat_awakened = true
	game.habitat_tutorial_complete = true
	game.puku_gauge_intro_complete = true
	game._start_jurejure_intro_event()
	assert(game.scripted_dialog_kind.is_empty())
	assert(not game.jurejure_intro_complete and not game.jurejure_enabled)
	game._toggle_mode()
	assert(game.current_mode == "greenhouse" and game.habitat_tutorial_returned_to_greenhouse)
	game._toggle_mode()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.scripted_dialog_kind == "jurejure_intro")
	var all_text := ""
	for page in game.scripted_dialog_pages:
		all_text += str(page.get("text", ""))
	assert("見つかったチュー" in all_text)
	assert("逃げるスカ" in all_text)
	assert("重いっぺ" in all_text)
	assert("〜ジュレ" not in all_text)
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
	assert(game.jurejure_intro_complete and game.jurejure_enabled)
	game.jurejure_growth_stage = JureJureSystemClass.GROWTH_LATE
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind == "jurejure_growth_mid")
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
	assert((game.jurejure_growth_event_mask & 1) != 0)
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind == "jurejure_growth_late")
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
	assert(game.jurejure_growth_event_mask == 3)


func _test_target_rules(game: Node) -> void:
	var now := Time.get_unix_time_from_system()
	game.discovered = {"colorata": true}
	game.species_get_counts = {"colorata": 2}
	game.habitat_returned_species = {"colorata": true}
	var valid_species_ids: Array[String] = ["colorata"]
	game.habitat_wild_plants = game.HabitatWildSystemClass.normalize_saved([
		_plant("small_target", 12.0, now)
	], valid_species_ids, now)
	assert(JureJureSystemClass.is_safe_target(game.habitat_wild_plants[0], game.habitat_returned_species))
	assert(game._start_random_jurejure_event(now))
	assert(not game.active_jurejure_event.is_empty())
	assert(str(game.active_jurejure_event.get("event_type", "")) == "habitat_take")
	assert(not game.active_jurejure_event.has("harvest_race"))
	assert(not game._start_random_jurejure_event(now))
	game._on_jurejure_display_pressed()
	assert(game.active_jurejure_event.is_empty())
	assert(not game._habitat_wild_plant_by_id("small_target").is_empty())

	assert(game._start_random_jurejure_event(now + 1.0))
	game._resolve_jurejure_deadline(game._habitat_wild_plant_by_id("small_target"), now + 2.0)
	assert(game._habitat_wild_plant_by_id("small_target").is_empty())
	assert(bool(game.habitat_returned_species.get("colorata", false)))
	assert(game.panda_beacon_unread_log.is_empty())

	# Size is irrelevant: the gang takes an individual from nature, never races
	# the player for a 30 cm harvest.
	game.habitat_wild_plants = game.HabitatWildSystemClass.normalize_saved([
		_plant("large_target", 48.0, now)
	], valid_species_ids, now)
	assert(game._start_random_jurejure_event(now + 3.0))
	assert(str(game.active_jurejure_event.get("event_type", "")) == "habitat_take")
	game._on_jurejure_display_pressed()
	assert(game.active_jurejure_event.is_empty())
	assert(not game._habitat_wild_plant_by_id("large_target").is_empty())

	var protected := _plant("protected", 20.0, now)
	protected["tutorial"] = true
	assert(not JureJureSystemClass.is_safe_target(protected, game.habitat_returned_species))
	var unsettled := _plant("unsettled", 20.0, now)
	unsettled["species_id"] = "lutea"
	assert(not JureJureSystemClass.is_safe_target(unsettled, game.habitat_returned_species))

	game.habitat_wild_plants = game.HabitatWildSystemClass.normalize_saved([
		_plant("saved_target", 20.0, now)
	], valid_species_ids, now)
	assert(game._start_random_jurejure_event(now + 5.0))
	game._save()
	game.active_jurejure_event = {}
	game._load_save()
	assert(str(game.active_jurejure_event.get("individual_id", "")) == "saved_target")
	assert(str(game.active_jurejure_event.get("event_type", "")) == "habitat_take")


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
	for entry in game.forest_gacha_system.eligible_species("base", false):
		assert(bool(entry.get("main_story_original", false)))
	for draw in range(40):
		var seed_choice: Dictionary = game._select_species_for_seed("normal", 0.0)
		assert(bool(seed_choice.get("main_story_original", false)))
	var secret_rng := RandomNumberGenerator.new()
	secret_rng.seed = 20260917
	for draw in range(20):
		var secret_result: Dictionary = game.secret_gacha_system.draw(game.unlocked_series, game.discovered, game.owned_pots, secret_rng, "species", false)
		if str(secret_result.get("category", "")) == "species":
			assert(bool(secret_result.get("species_entry", {}).get("main_story_original", false)))
	game.discovered["metal_laui"] = true
	assert(game._species_available_in_current_era(creative))
	game.discovered.erase("metal_laui")
	game.habitat_second_awakened = true
	assert(game._species_available_in_current_era(creative))
	assert(not game.forest_gacha_system.eligible_species("metal", true).is_empty())


func _plant(individual_id: String, diameter: float, now: float) -> Dictionary:
	return {
		"individual_id": individual_id,
		"species_id": "colorata",
		"diameter_cm": diameter,
		"jellied": false,
		"tutorial": false,
		"jelly_immune": false,
		"base_growth_rate": 1.0,
		"jelly_risk_curve": 1.0,
		"mature_diameter_cm": 30.8,
		"jelly_threshold": 999999.0,
		"jelly_hazard_accumulated": 0.0,
		"jelly_elapsed_seconds": 0.0,
		"last_updated_unix": now,
		"spawned_unix": now,
		"habitat_timing_version": game_version(),
		"panorama_x": 640.0,
		"panorama_y": 410.0,
		"position_validated": true
	}


func game_version() -> int:
	return 3
