extends Node

const StoryProgressionClass = preload("res://scripts/story_progression.gd")


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	_test_catalog_contract(game)
	await _test_three_act_sequence(game)
	_test_retired_unlock_conditions(game)
	_test_legacy_three_act_migration(game)
	game._reset_progression_state()
	print("STORY_PROGRESSION_SMOKE_OK acts=3 first_battle=act2 fantasy=1+6+24 act3=next_habitat crisis=visual_only old_objectives=removed old_gates=retired migration=preserved")
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
	for ordinary_id in ["hyalina_san_luis_de_la_paz", "purpusorum", "pinwheel", "tovarensis_tovar", "strictiflora_bustamante"]:
		var ordinary_entry: Dictionary = game._catalog_entry(ordinary_id)
		assert(not ordinary_entry.is_empty())
		assert(bool(ordinary_entry.get("main_story_original", false)))
		assert(str(ordinary_entry.get("rarity", "")) == "通常")
		assert(float(ordinary_entry.get("spawn_weight", 0.0)) > 0.0)
		assert(not bool(ordinary_entry.get("special_route_only", false)))
	var unlock_rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/unlock-rules.json"))
	assert(unlock_rules is Array and unlock_rules.is_empty())
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var localizer_source := FileAccess.get_file_as_string("res://scripts/game_localizer.gd")
	assert(not main_source.contains("objective_") and not localizer_source.contains("objective_"))
	assert(not main_source.contains("unlock_after_plays") and not localizer_source.contains("unlock_after_plays"))
	assert(not localizer_source.contains("catalog_field"))
	var progression_source := FileAccess.get_file_as_string("res://scripts/story_progression.gd")
	for retired_stage_name in ["STAGE_ORIGINALS_5", "STAGE_SIZE_50", "STAGE_ORIGINALS_8", "STAGE_SIZE_100", "STAGE_ORIGINALS_12", "STAGE_SECOND_AWAKENING"]:
		assert(not progression_source.contains(retired_stage_name))
	assert(game.find_child("*Objective*", true, false) == null)


func _test_three_act_sequence(game: Node) -> void:
	game._reset_progression_state()
	game.opening_story_overlay.visible = false
	game.intro_overlay.visible = false
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.trio_originals_confirmed = true
	game.habitat_unlocked = true
	game.habitat_arrival_started = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_tutorial_started = true
	game.habitat_tutorial_complete = true
	game.habitat_tutorial_returned_to_greenhouse = true
	game.mystery_items_acquired = true
	game.mystery_catalog_tutorial_complete = true
	game.seed_shop_open = true
	game.puku_gauge_intro_complete = true
	game.jurejure_intro_complete = true
	game.jurejure_enabled = true
	game.current_mode = "greenhouse"
	game._apply_mode()
	game._update_main_story_progress(false)
	assert(game.main_story_stage == StoryProgressionClass.ACT_1)

	# Old completion numbers no longer move the story at all.
	for species_id in StoryProgressionClass.MAIN_STORY_ORIGINAL_IDS:
		game.discovered[species_id] = true
	game.bests["colorata"] = 150.0
	game.total_play_count = 20
	game.formal_play_count = 20
	game.armadillo_research_total = 30
	game._update_main_story_progress(false)
	assert(game.main_story_stage == StoryProgressionClass.ACT_1)
	assert(not game.act2_unlocked and not game.forest_gacha_unlocked)

	# Any normally resolved first battle, including a loss, opens Act 2.
	game._on_puku_puku_battle_resolved({"won": false, "player_score": 1.0, "opponent_score": 2.0})
	assert(game.jurejure_battle_count == 1 and game.jurejure_battle_win_count == 0)
	assert(game.act2_unlocked and game.forest_gacha_unlocked and not game.forest_gacha_intro_seen)
	assert(game.main_story_stage == StoryProgressionClass.ACT_2)
	game.forest_gacha_intro_seen = true

	var fantasy_ids: Array[String] = []
	for entry in game.catalog_species:
		if game._is_fantasy_species(entry):
			fantasy_ids.append(str(entry.get("species_id", "")))
	assert(fantasy_ids.size() >= 24)
	# Encyclopedia discovery by itself is not a real GET.
	for index in range(24):
		game.discovered[fantasy_ids[index]] = true
	assert(game._unique_fantasy_species_get_count() == 0)
	assert(not game.act3_unlocked)

	game._record_species_get(fantasy_ids[0])
	assert(game._unique_fantasy_species_get_count() == 1)
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind == "fantasy_first_discovery")
	assert(game.scripted_dialog_pages.size() == 3)
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == "……なにこれ！？")
	_finish_dialog(game)
	assert(game.fantasy_first_discovery_seen)

	for index in range(1, 6):
		game._record_species_get(fantasy_ids[index])
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind == "fantasy_realization")
	assert(game.scripted_dialog_pages.size() == 3)
	assert("想像したものが、多肉になってる？" in str(game.scripted_dialog_pages[2].get("text", "")))
	_finish_dialog(game)
	assert(game.fantasy_realization_seen)

	for index in range(6, 24):
		game._record_species_get(fantasy_ids[index])
	assert(game._unique_fantasy_species_get_count() == 24)
	assert(game.act3_unlocked and game.act3_intro_pending and not game.act3_intro_seen)
	assert(game.main_story_stage == StoryProgressionClass.ACT_3)
	assert(game.scripted_dialog_kind.is_empty())
	# Merely assigning habitat mode is not a visit; the intro waits for the next
	# real navigation entry and therefore cannot appear behind a GET screen.
	game.current_mode = "habitat"
	game._apply_mode()
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind.is_empty())
	game.current_mode = "greenhouse"
	game._apply_mode()
	game._toggle_mode()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.current_mode == "habitat" and game.scripted_dialog_kind == "act3_intro")
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == "つまり、欲しいものを想像すればいいんだチュー！？")
	assert(str(game.scripted_dialog_pages[1].get("text", "")) == "だったら、もっともっと作らせるチュー！")
	_finish_dialog(game)
	assert(game.act3_intro_seen and not game.act3_intro_pending)

	# The crisis also waits for a later habitat visit and changes presentation
	# only. It must not revive the retired rain bonus or mutate collection state.
	var settled_before: Dictionary = game.habitat_returned_species.duplicate(true)
	var discovered_before: Dictionary = game.discovered.duplicate(true)
	var get_counts_before: Dictionary = game.species_get_counts.duplicate(true)
	var seeds_before: int = game.normal_seed_bags
	game.habitat_crisis_pending = true
	game.habitat_crisis_started = false
	game.finale_complete = false
	game.habitat_crisis_eligible_visit_id = game.habitat_visit_id
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind.is_empty())
	game._toggle_mode()
	game._toggle_mode()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.current_mode == "habitat" and game.scripted_dialog_kind == "habitat_crisis")
	assert(game.habitat_crisis_started and not game.habitat_crisis_pending)
	assert(game.habitat_crisis_atmosphere.crisis_active and game.habitat_crisis_atmosphere.visible)
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == "……おかしい。")
	assert("自然の中で創造していることを" in str(game.scripted_dialog_pages[5].get("text", "")))
	assert(not game.rain_bonus_active and not game.rain_bonus_in_progress and game.rain_bag_count == 0)
	assert(game.rain_visual == null)
	assert(game.habitat_returned_species == settled_before)
	assert(game.discovered == discovered_before and game.species_get_counts == get_counts_before)
	assert(game.normal_seed_bags == seeds_before)
	_finish_dialog(game)
	assert(game.finale_complete and game.main_story_stage == StoryProgressionClass.ACT_FINALE)


func _test_retired_unlock_conditions(game: Node) -> void:
	game._reset_progression_state()
	var special_ids := ["hyalina_san_luis_de_la_paz", "purpusorum", "pinwheel", "tovarensis_tovar", "strictiflora_bustamante"]
	game.bests = {"colorata": 100.0, "lutea": 60.0, "shaviana": 60.0}
	game.total_play_count = 13
	game.normal_play_count = 13
	game.formal_play_count = 13
	game.armadillo_research_total = 25
	game._evaluate_unlock_rules("harvest_size", 100.0)
	assert(not game._evaluate_best_spawn_unlocks())
	game._queue_armadillo_progress_event()
	game._prepare_tovar_event_for_play()
	assert(game.pending_armadillo_story_event.is_empty() and not game.tovar_event_active)
	for species_id in special_ids:
		assert(not bool(game.discovered.get(species_id, false)))
	assert(game.mystery_route_assignments.is_empty())

	# Formal-play counts no longer unlock inventory. Existing inventory remains
	# usable with no count gate.
	game.volume_seed_unlocked = false
	game.premium_seed_unlocked = false
	game.volume_seed_bags = 0
	game.premium_seed_bags = 0
	game._refresh_seed_pack_unlocks()
	assert(not game._volume_seed_unlocked() and not game._premium_seed_unlocked())
	game.volume_seed_bags = 1
	game.premium_seed_bags = 1
	assert(game._volume_seed_unlocked() and game._premium_seed_unlocked())


func _test_legacy_three_act_migration(game: Node) -> void:
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
	game.mystery_items_acquired = true
	game.seed_shop_open = true
	game.puku_gauge_intro_complete = true
	game.habitat_second_awakened = true
	game.normal_seed_bags = 6
	game.volume_seed_bags = 2
	game.premium_seed_bags = 1
	game.mystery_seed_bags = 3
	game.bests = {"colorata": 100.0, "laui": 62.0}
	game.discovered = {"colorata": true, "hyalina_san_luis_de_la_paz": true, "purpusorum": true, "pinwheel": true, "tovarensis_tovar": true, "transparent_succulent": true}
	game.species_get_counts = {"colorata": 3, "hyalina_san_luis_de_la_paz": 1, "purpusorum": 1, "pinwheel": 1, "tovarensis_tovar": 1, "transparent_succulent": 1}
	game.greenhouse_available = game.discovered.duplicate(true)
	game.unlocked_species = game.greenhouse_available.duplicate(true)
	game.habitat_returned_species = {"colorata": true, "laui": true, "transparent_succulent": true}
	var fantasy_ids: Array[String] = []
	for entry in game.catalog_species:
		if game._is_fantasy_species(entry):
			fantasy_ids.append(str(entry.get("species_id", "")))
	for index in range(24):
		game.discovered[fantasy_ids[index]] = true
		game.species_get_counts[fantasy_ids[index]] = 1
		game.greenhouse_available[fantasy_ids[index]] = true
		game.habitat_returned_species[fantasy_ids[index]] = true
	game.completed_unlock_conditions = {"legacy_40cm": true, "legacy_play_13": true}
	game._save()
	var payload = JSON.parse_string(FileAccess.get_file_as_string("user://records.json"))
	assert(payload is Dictionary)
	payload["progression_version"] = 23
	for key in ["act2_unlocked", "forest_gacha_unlocked", "forest_gacha_intro_seen", "fantasy_first_discovery_seen", "fantasy_realization_seen", "act3_unlocked", "act3_intro_pending", "act3_intro_seen", "jurejure_species_first_seen", "habitat_crisis_pending", "habitat_crisis_started", "finale_complete"]:
		payload.erase(key)
	var file := FileAccess.open("user://records.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()

	game.discovered.clear();game.species_get_counts.clear();game.habitat_returned_species.clear();game.normal_seed_bags=0
	game._load_save()
	assert(game.act2_unlocked and game.forest_gacha_unlocked)
	assert(game.fantasy_first_discovery_seen and game.fantasy_realization_seen)
	assert(game._unique_fantasy_species_get_count() == 24)
	assert(game.act3_unlocked and game.act3_intro_pending and not game.act3_intro_seen)
	assert(game.scripted_dialog_kind.is_empty())
	assert(game.normal_seed_bags == 6 and game.volume_seed_bags == 2 and game.premium_seed_bags == 1 and game.mystery_seed_bags == 3)
	assert(bool(game.discovered.get("pinwheel", false)) and game._species_get_count("pinwheel") == 1)
	assert(bool(game.discovered.get("transparent_succulent", false)) and game._species_get_count("transparent_succulent") == 1)
	assert(bool(game.habitat_returned_species.get("laui", false)) and bool(game.habitat_returned_species.get("transparent_succulent", false)))
	assert(bool(game.completed_unlock_conditions.get("legacy_40cm", false)) and bool(game.completed_unlock_conditions.get("legacy_play_13", false)))
	game._evaluate_unlock_rules("harvest_size", 100.0)
	assert(game._species_get_count("pinwheel") == 1 and game._species_get_count("transparent_succulent") == 1)


func _finish_dialog(game: Node) -> void:
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
