extends Node

const StoryProgressionClass = preload("res://scripts/story_progression.gd")

func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	_test_catalog_contract(game)
	_test_objective_sequence(game)
	_test_legacy_migration(game)
	game._reset_progression_state()
	print("STORY_PROGRESSION_SMOKE_OK originals=12 stages=9 completion=true common_migration=true preservation=true")
	get_tree().quit()

func _test_catalog_contract(game: Node) -> void:
	assert(game.INITIAL_SERIES_ID == "base")
	assert(game._series_entry("common").is_empty())
	assert(bool(game.unlocked_series.get("base", false)))
	assert(game.catalog_species.size() == 124)
	for removed_id in StoryProgressionClass.REMOVED_COMMON_SPECIES_IDS:
		assert(game._catalog_entry(str(removed_id)).is_empty())
	var originals: Array[String] = []
	var modern_annotations: Array[String] = []
	for entry in game._series_species_entries("base"):
		if bool(entry.get("main_story_original", false)):
			originals.append(str(entry.get("species_id", "")))
			assert(str(entry.get("catalog_origin", "")) == "historic_record")
		elif str(entry.get("catalog_origin", "")) == "modern_annotation":
			modern_annotations.append(str(entry.get("species_id", "")))
	assert(originals == StoryProgressionClass.MAIN_STORY_ORIGINAL_IDS)
	assert(originals.size() == 12 and modern_annotations.size() == 9)

func _test_objective_sequence(game: Node) -> void:
	game._reset_progression_state()
	game.intro_story_complete = true
	game._update_main_story_progress(false)
	assert(game.main_story_stage == StoryProgressionClass.STAGE_OLD_SEED)
	game.first_colorata_confirmed = true
	game.discovered = {"colorata": true}
	game._update_main_story_progress(false)
	assert(game.main_story_stage == StoryProgressionClass.STAGE_TRIO)
	game.trio_originals_confirmed = true
	game.discovered["lutea"] = true
	game.discovered["shaviana"] = true
	game.habitat_unlocked = true
	game._update_main_story_progress(false)
	assert(game.main_story_stage == StoryProgressionClass.STAGE_FIND_HABITAT)
	game.habitat_arrival_started = true
	game._update_main_story_progress(false)
	assert(game.main_story_stage == StoryProgressionClass.STAGE_AWAKEN_HABITAT)
	game.habitat_awakened = true
	game._update_main_story_progress(false)
	assert(game.main_story_stage == StoryProgressionClass.STAGE_ORIGINALS_5)
	for species_id in ["hyalina_san_luis_de_la_paz", "purpusorum"]:
		game.discovered[species_id] = true
	game._update_main_story_progress(false)
	assert(game.main_story_stage == StoryProgressionClass.STAGE_SIZE_50)
	game.bests["colorata"] = 50.0
	game._update_main_story_progress(false)
	assert(game.main_story_stage == StoryProgressionClass.STAGE_ORIGINALS_8)
	for species_id in ["pinwheel", "juliana", "affinis"]:
		game.discovered[species_id] = true
	game._update_main_story_progress(false)
	assert(game.main_story_stage == StoryProgressionClass.STAGE_SIZE_100)
	game.bests["lutea"] = 100.0
	game._update_main_story_progress(false)
	assert(game.main_story_stage == StoryProgressionClass.STAGE_ORIGINALS_12)
	for species_id in StoryProgressionClass.MAIN_STORY_ORIGINAL_IDS:
		game.discovered[species_id] = true
	game._update_main_story_progress(false)
	assert(game.main_story_stage == StoryProgressionClass.STAGE_COMPLETE and game.main_story_complete)
	assert(not game.main_story_completion_seen)
	game._start_main_story_complete_event()
	assert(game.scripted_dialog_kind == "main_story_complete")
	var completion_text := ""
	for page in game.scripted_dialog_pages:
		completion_text += str(page.get("text", ""))
	assert("全部この世界に戻ってきた" in completion_text)
	assert("まだ新しい多肉を生み続けている" in completion_text)
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
	assert(game.main_story_completion_seen and game.main_story_complete)

func _test_legacy_migration(game: Node) -> void:
	game._reset_progression_state()
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.habitat_unlocked = true
	game.habitat_tutorial_started = true
	game.habitat_tutorial_complete = true
	game.puku_gauge_intro_complete = true
	game.panda_beacon_unlocked = true
	game.panda_beacon_count = 4
	game.panda_beacon_unread_log.clear()
	game.panda_beacon_unread_log.append({"individual_id": "legacy_notice", "species_id": "laui", "diameter_cm": 42.3, "jellied_unix": 12345.0})
	game.puku_points = 37
	game.puku_gauge_cm = 123.5
	game.bests = {"colorata": 100.0, "laui": 62.0, "momotaro": 999.0}
	game.discovered = {"colorata": true, "laui": true, "momotaro": true}
	game.species_get_counts = {"colorata": 5, "laui": 2, "momotaro": 8}
	game.unlocked_series = {"common": true, "metal": true}
	game.greenhouse_available = {"colorata": true, "laui": true, "momotaro": true}
	game.unlocked_species = game.greenhouse_available.duplicate(true)
	game.pending_habitat_species = ["laui", "momotaro"]
	game.series_seed_inventory = {"common": 4, "metal": 2}
	game.forest_gacha_encountered = {"momotaro": true, "metal_gold_cluster": true}
	game.habitat_returned_species = {"momotaro": true, "laui": true}
	game.normal_seed_bags = 6
	game.volume_seed_bags = 2
	game.premium_seed_bags = 1
	game.mystery_seed_bags = 3
	game.rain_event_pending = true
	game.rain_bonus_in_progress = true
	game.rain_time_remaining = 17.0
	game.saved_arrangements = [{
		"arrangement_id": "legacy_arrangement", "name": "残す寄せ植え", "pot_id": game.DEFAULT_POT_ID,
		"created_at": "legacy", "completed": true,
		"plants": [
			{"species_id": "colorata", "x": 200.0, "y": 260.0, "scale": 1.0, "rotation": 0.0, "z_index": 0},
			{"species_id": "momotaro", "x": 300.0, "y": 260.0, "scale": 1.0, "rotation": 0.0, "z_index": 1}
		]
	}]
	var migration_rng := RandomNumberGenerator.new()
	migration_rng.seed = 180917
	game.habitat_wild_plants.clear()
	var migration_species: Array[String] = ["colorata", "laui"]
	game.HabitatWildSystemClass.initialize_population(game.habitat_wild_plants, migration_species, migration_species, true, Time.get_unix_time_from_system(), migration_rng, game.HABITAT_SAFE_PLANT_POINTS)
	game.habitat_wild_initialized = true
	game.habitat_wild_next_spawn_unix = Time.get_unix_time_from_system() + 7200.0
	var preserved_habitat_id := str(game.habitat_wild_plants[0].get("individual_id", ""))
	game._save()
	var payload = JSON.parse_string(FileAccess.get_file_as_string("user://records.json"))
	assert(payload is Dictionary)
	payload["progression_version"] = 17
	for new_key in ["first_colorata_confirmed", "trio_originals_confirmed", "habitat_arrival_started", "habitat_awakened", "habitat_awakening_event_complete", "seed_shop_open", "special_series_explanation_seen", "main_story_stage", "main_story_complete", "main_story_completion_seen"]:
		payload.erase(new_key)
	var file := FileAccess.open("user://records.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()

	game._load_save()
	assert(game.opening_story_complete and game.intro_story_complete)
	assert(game.first_colorata_confirmed and game.trio_originals_confirmed)
	assert(game.habitat_unlocked and game.habitat_arrival_started and game.habitat_awakened and game.habitat_awakening_event_complete)
	assert(game.seed_shop_open and bool(game.unlocked_series.get("base", false)) and bool(game.unlocked_series.get("metal", false)))
	assert(not bool(game.unlocked_series.get("common", false)) and not game.series_seed_inventory.has("common"))
	for removed_id in StoryProgressionClass.REMOVED_COMMON_SPECIES_IDS:
		assert(not game.bests.has(removed_id) and not game.discovered.has(removed_id))
		assert(not game.species_get_counts.has(removed_id) and not game.greenhouse_available.has(removed_id))
		assert(not game.forest_gacha_encountered.has(removed_id) and not game.habitat_returned_species.has(removed_id))
	assert(game.puku_points == 37 and is_equal_approx(game.puku_gauge_cm, 123.5))
	assert(is_equal_approx(float(game.bests.get("colorata", 0.0)), 100.0) and int(game.species_get_counts.get("laui", 0)) == 2)
	assert(game.normal_seed_bags == 6 and game.volume_seed_bags == 2 and game.premium_seed_bags == 1 and game.mystery_seed_bags == 3)
	assert(game.panda_beacon_unlocked and game.panda_beacon_count == 4 and game.panda_beacon_unread_log.size() == 1)
	assert(game.rain_event_pending and game.rain_bonus_in_progress and is_equal_approx(game.rain_time_remaining, 17.0))
	assert(not game._habitat_wild_plant_by_id(preserved_habitat_id).is_empty())
	assert(game.saved_arrangements.size() == 1 and game.saved_arrangements[0].plants.size() == 1)
	assert(str(game.saved_arrangements[0].plants[0].species_id) == "colorata")
	for species_id in ["colorata", "lutea", "shaviana", "laui"]:
		assert(bool(game.habitat_returned_species.get(species_id, false)))
	game._save()
	var migrated = JSON.parse_string(FileAccess.get_file_as_string("user://records.json"))
	assert(int(migrated.get("progression_version", 0)) == game.PROGRESSION_VERSION)
	assert(bool(migrated.get("habitat_awakened", false)) and migrated.has("main_story_stage"))
