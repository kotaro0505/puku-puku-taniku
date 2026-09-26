extends Node

const HabitatWildSystemClass = preload("res://scripts/habitat_wild_system.gd")


func _ready() -> void:
	print("HABITAT_REVISION_SMOKE_STAGE instantiate")
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	print("HABITAT_REVISION_SMOKE_STAGE lifecycle")
	_test_natural_growth_and_lifecycle()
	print("HABITAT_REVISION_SMOKE_STAGE settlement")
	_test_settlement_and_ownership(game)
	print("HABITAT_REVISION_SMOKE_STAGE population")
	_test_uniform_population_and_safe_positions(game)
	print("HABITAT_REVISION_SMOKE_STAGE observation")
	await _test_observation_without_harvest(game)
	print("HABITAT_REVISION_SMOKE_STAGE retired")
	_test_retired_runtime_features(game)
	print("HABITAT_REVISION_SMOKE_STAGE migration")
	_test_legacy_save_migration(game)
	game._reset_progression_state()
	game.free()
	await get_tree().process_frame
	print("HABITAT_REVISION_SMOKE_OK settlement=true uniform_spawn=true population_cap=true natural_lifecycle=true observation_only=true beacon_retired=true rain_bonus_retired=true legacy_safe=true")
	get_tree().quit()


func _test_natural_growth_and_lifecycle() -> void:
	assert(is_equal_approx(HabitatWildSystemClass.NORMAL_HABITAT_GROWTH_SCALE, 1.0 / 120000.0))
	assert(is_equal_approx(HabitatWildSystemClass.NORMAL_HABITAT_JELLY_SCALE, 1.0 / 15000.0))
	assert(is_equal_approx(HabitatWildSystemClass.NORMAL_HABITAT_JELLY_PROBABILITY_PER_SECOND, 0.000004))
	var now := 200000.0
	var growing := _plant("growing", "colorata", 8.0, now - 7200.0)
	var expected := 8.0 + 7200.0 * HabitatWildSystemClass.MAIN_GROWTH_CM_PER_SECOND * HabitatWildSystemClass.NORMAL_HABITAT_GROWTH_SCALE
	var growing_plants: Array[Dictionary] = [growing]
	HabitatWildSystemClass.advance_time(growing_plants, now)
	assert(growing_plants.size() == 1)
	assert(is_equal_approx(float(growing.get("diameter_cm", 0.0)), expected))
	assert(is_zero_approx(float(growing.get("jelly_hazard_accumulated", 0.0))))

	var day_growth := 86400.0 * HabitatWildSystemClass.MAIN_GROWTH_CM_PER_SECOND * HabitatWildSystemClass.NORMAL_HABITAT_GROWTH_SCALE
	assert(absf(day_growth - 0.98325) < 0.00001)
	assert(is_zero_approx(HabitatWildSystemClass.jelly_hazard_for_interval(5.0, 10.0, 3600.0)))
	assert(HabitatWildSystemClass.jelly_hazard_for_interval(HabitatWildSystemClass.MATURITY_MIN_CM, HabitatWildSystemClass.MATURITY_MIN_CM + 1.0, 3600.0) > 0.0)

	var hazard_rate := HabitatWildSystemClass.jelly_hazard_rate_per_second()
	var mature := _plant("mature", "colorata", 24.0, now - 300.0)
	mature["mature_diameter_cm"] = 24.0
	mature["jelly_threshold"] = hazard_rate * 60.0
	var mature_plants: Array[Dictionary] = [mature]
	var mature_events := HabitatWildSystemClass.advance_time_with_events(mature_plants, now)
	assert(mature_plants.is_empty())
	assert(mature_events.get("jellied", []) == ["mature"])
	assert(mature_events.get("removed", []) == ["mature"])
	assert(not mature_events.has("ready"))

	var stale := _plant("stale", "colorata", 40.0, now)
	stale["jellied"] = true
	var stale_plants: Array[Dictionary] = [stale]
	var stale_events := HabitatWildSystemClass.advance_time_with_events(stale_plants, now)
	assert(stale_plants.is_empty())
	assert(stale_events.get("jellied", []).is_empty())
	assert(stale_events.get("removed", []) == ["stale"])


func _test_settlement_and_ownership(game: Node) -> void:
	game._reset_progression_state()
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.discovered = {"colorata": true}
	game.species_get_counts = {"colorata": 1}
	game.habitat_returned_species.clear()
	game._migrate_habitat_settlement()
	for story_id in [game.FIRST_STORY_SPECIES_ID, game.PANDA_STORY_SPECIES_ID, game.ARMADILLO_STORY_SPECIES_ID]:
		assert(bool(game.habitat_returned_species.get(story_id, false)))
	assert(int(game.species_get_counts.get(game.PANDA_STORY_SPECIES_ID, 0)) == 0)
	assert(int(game.species_get_counts.get(game.ARMADILLO_STORY_SPECIES_ID, 0)) == 0)

	assert(game._register_species_discovery("lutea", true))
	assert(bool(game.habitat_returned_species.get("lutea", false)))
	assert(int(game.species_get_counts.get("lutea", 0)) == 1)
	var candidates: Array[String] = game._habitat_population_candidate_ids()
	for settled_id in game.habitat_returned_species:
		if bool(game.habitat_returned_species.get(settled_id, false)):
			assert(str(settled_id) in candidates)
	var unknown_id := ""
	for entry in game.catalog_species:
		var species_id := str(entry.get("species_id", ""))
		if not species_id.is_empty() and not bool(game.discovered.get(species_id, false)) and not bool(game.habitat_returned_species.get(species_id, false)):
			unknown_id = species_id
			break
	assert(not unknown_id.is_empty())
	assert(unknown_id not in candidates)

	var settled_before: Dictionary = game.habitat_returned_species.duplicate(true)
	var dying: Array[Dictionary] = [_plant("temporary_individual", "lutea", 25.0, 1000.0)]
	dying[0]["mature_diameter_cm"] = 24.0
	dying[0]["jelly_threshold"] = HabitatWildSystemClass.jelly_hazard_rate_per_second() * 1.0
	HabitatWildSystemClass.advance_time_with_events(dying, 1010.0)
	assert(dying.is_empty())
	assert(game.habitat_returned_species == settled_before)


func _test_uniform_population_and_safe_positions(game: Node) -> void:
	var test_rng := RandomNumberGenerator.new()
	test_rng.seed = 20260926
	var draws := {"colorata": 0, "affinis": 0}
	for draw_index in range(800):
		var one: Array[Dictionary] = []
		assert(HabitatWildSystemClass.spawn_one(one, ["colorata", "affinis"], 1000.0 + draw_index, test_rng, game.HABITAT_SAFE_PLANT_POINTS))
		draws[str(one[0].get("species_id", ""))] = int(draws.get(str(one[0].get("species_id", "")), 0)) + 1
	var colorata_ratio := float(draws["colorata"]) / 800.0
	assert(colorata_ratio > 0.42 and colorata_ratio < 0.58)

	var plants: Array[Dictionary] = []
	while plants.size() < HabitatWildSystemClass.MAX_POPULATION:
		assert(HabitatWildSystemClass.spawn_one(plants, ["colorata", "affinis"], 3000.0 + plants.size(), test_rng, game.HABITAT_SAFE_PLANT_POINTS))
	assert(plants.size() == HabitatWildSystemClass.MAX_POPULATION)
	assert(not HabitatWildSystemClass.spawn_one(plants, ["colorata"], 9000.0, test_rng, game.HABITAT_SAFE_PLANT_POINTS))
	var panorama_sectors: Dictionary = {}
	for plant in plants:
		var point := Vector2(float(plant.get("panorama_x", 0.0)), float(plant.get("panorama_y", 0.0)))
		assert(HabitatWildSystemClass.is_safe_ground_point(point, game.HABITAT_SAFE_PLANT_POINTS))
		panorama_sectors[int(floor(point.x / 320.0))] = true
	assert(panorama_sectors.size() >= 3)

	var removed_id := str(plants[0].get("individual_id", ""))
	HabitatWildSystemClass.remove_individual(plants, removed_id)
	assert(plants.size() == HabitatWildSystemClass.MAX_POPULATION - 1)
	assert(HabitatWildSystemClass.spawn_one(plants, ["colorata"], 10000.0, test_rng, game.HABITAT_SAFE_PLANT_POINTS))
	assert(str(plants.back().get("species_id", "")) == "colorata")


func _test_observation_without_harvest(game: Node) -> void:
	game._reset_progression_state()
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.trio_originals_confirmed = true
	game.habitat_unlocked = true
	game.habitat_arrival_started = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_tutorial_started = true
	game.habitat_tutorial_complete = true
	game.habitat_returned_species = {"colorata": true, "affinis": true, "shaviana": true}
	var now := Time.get_unix_time_from_system()
	var observed := _plant("observe_me", "colorata", 42.6, now)
	observed["panorama_x"] = 430.0
	observed["panorama_y"] = 405.0
	game.habitat_wild_plants.assign([observed])
	game.habitat_wild_initialized = true
	game.habitat_wild_next_spawn_unix = now + 999999.0
	game.current_mode = "habitat"
	game._apply_mode()
	game._build_habitat_items(true)
	var item: Dictionary = game._habitat_wild_item_by_id("observe_me")
	assert(not item.is_empty())
	assert(not item.has("status_label") and not item.has("beacon_node"))
	var get_count_before := int(game.species_get_counts.get("colorata", 0))
	game._collect_habitat_wild_plant(item)
	assert(not game._habitat_wild_plant_by_id("observe_me").is_empty())
	assert(int(game.species_get_counts.get("colorata", 0)) == get_count_before)
	assert(game.habitat_plant_panel.visible)
	assert(game.habitat_plant_panel.title_label.text == game._habitat_species_name("colorata"))
	assert("cm" in game.habitat_plant_panel.detail_label.text)
	var panel_buttons: Array[Node] = game.habitat_plant_panel.find_children("*", "Button", true, false)
	assert(panel_buttons.size() == 1)
	assert(panel_buttons[0].name == "HabitatPlantClose")
	assert("30" not in game.habitat_plant_panel.detail_label.text)
	assert("収穫" not in game.habitat_plant_panel.detail_label.text)
	assert("ビーコン" not in game.habitat_plant_panel.detail_label.text)
	game.habitat_plant_panel.close()
	await get_tree().process_frame


func _test_retired_runtime_features(game: Node) -> void:
	assert(game._seed_shop_products().is_empty())
	assert(game.find_child("PandaBeaconLogPanel", true, false) == null)
	assert(game.find_child("PandaBeaconLogButton", true, false) == null)
	game.rain_event_pending = false
	game.rain_bonus_active = false
	game._roll_rain_event()
	assert(not game.rain_event_pending and not game.rain_bonus_active)
	assert(game.habitat_awakening_overlay != null)
	assert(game.habitat_status_label == null or not game.habitat_status_label.visible)


func _test_legacy_save_migration(game: Node) -> void:
	game._reset_progression_state()
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.habitat_unlocked = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.puku_points = 37
	game.bests = {"colorata": 44.8}
	game.discovered = {"colorata": true, "lutea": true}
	game.species_get_counts = {"colorata": 7, "lutea": 2}
	game.habitat_returned_species = {"colorata": true}
	var now := Time.get_unix_time_from_system()
	var legacy := _plant("legacy_beacon", "colorata", 18.0, now)
	legacy["panda_beacon_installed"] = true
	game.habitat_wild_plants.assign([legacy])
	game.habitat_wild_initialized = true
	game.habitat_wild_next_spawn_unix = now + 7200.0
	game._save()
	var payload = JSON.parse_string(FileAccess.get_file_as_string("user://records.json"))
	assert(payload is Dictionary)
	payload["progression_version"] = 21
	payload["panda_beacon_unlocked"] = true
	payload["panda_beacon_count"] = 4
	payload["panda_beacon_unread_log"] = [{"individual_id": "legacy_beacon", "species_id": "colorata"}]
	payload["rain_event_pending"] = true
	payload["rain_bonus_in_progress"] = true
	payload["rain_bonus_active"] = true
	payload["rain_time_remaining"] = 99.0
	var save_file := FileAccess.open("user://records.json", FileAccess.WRITE)
	save_file.store_string(JSON.stringify(payload))
	save_file.close()

	game.puku_points = 0
	game.bests.clear()
	game.discovered.clear()
	game.species_get_counts.clear()
	game.habitat_returned_species.clear()
	game.habitat_wild_plants.clear()
	game.habitat_wild_initialized = false
	game.panda_beacon_unlocked = true
	game.panda_beacon_count = 99
	game.panda_beacon_unread_log.assign([{"individual_id": "memory_only"}])
	game.rain_event_pending = true
	game.rain_bonus_active = true
	game._load_save()
	assert(game.puku_points == 37)
	assert(is_equal_approx(float(game.bests.get("colorata", 0.0)), 44.8))
	assert(int(game.species_get_counts.get("colorata", 0)) == 7)
	assert(int(game.species_get_counts.get("lutea", 0)) == 2)
	for settled_id in ["colorata", "lutea", "affinis", "shaviana"]:
		assert(bool(game.habitat_returned_species.get(settled_id, false)))
	assert(not game.panda_beacon_unlocked and game.panda_beacon_count == 0 and game.panda_beacon_unread_log.is_empty())
	assert(not game.rain_event_pending and not game.rain_bonus_in_progress and not game.rain_bonus_active)
	assert(game.habitat_wild_plants.size() == 1)
	assert(str(game.habitat_wild_plants[0].get("individual_id", "")) == "legacy_beacon")
	assert(not game.habitat_wild_plants[0].has("panda_beacon_installed"))
	assert("legacy_beacon" in game.legacy_habitat_notification_ids_to_cancel)


func _plant(individual_id: String, species_id: String, diameter: float, last_updated: float) -> Dictionary:
	return {
		"individual_id": individual_id,
		"species_id": species_id,
		"diameter_cm": diameter,
		"growth_state": "growing",
		"jellied": false,
		"jellied_unix": 0.0,
		"jelly_immune": false,
		"jelly_elapsed_seconds": 0.0,
		"jelly_hazard_accumulated": 0.0,
		"jelly_threshold": 999999.0,
		"jelly_risk_curve": 1.0,
		"mature_diameter_cm": 30.8,
		"jelly_eligible_since_unix": 0.0,
		"tutorial": false,
		"base_growth_rate": 1.0,
		"spawned_unix": last_updated,
		"last_updated_unix": last_updated,
		"habitat_timing_version": HabitatWildSystemClass.TIMING_VERSION,
		"panorama_x": 430.0,
		"panorama_y": 405.0,
		"position_validated": true
	}
