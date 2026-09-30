extends Node

const EndlessClass = preload("res://scripts/endless_greenhouse_experiment.gd")
const JellyBalanceClass = preload("res://scripts/jelly_balance.gd")
const StoryProgressionClass = preload("res://scripts/story_progression.gd")
const HabitatRestorationClass = preload("res://scripts/habitat_restoration.gd")
const Localizer = preload("res://scripts/game_localizer.gd")
const NORMAL_PATH := "user://endless_gameplay_normal_smoke.json"
const EXPERIMENT_PATH := "user://endless_gameplay_experiment_smoke.json"


func _ready() -> void:
	_remove_test_file(NORMAL_PATH)
	_remove_test_file(EXPERIMENT_PATH)
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	game.endless_greenhouse.set_save_paths_for_test(NORMAL_PATH, EXPERIMENT_PATH)
	game.endless_greenhouse.configure(false)
	_configure_ready_greenhouse(game)
	game.puku_points = 4
	game.bests = {"colorata": 31.0}
	game._save()
	var normal_bytes_before := FileAccess.get_file_as_bytes(NORMAL_PATH)

	game.endless_greenhouse.configure(true)
	var namespace_result: Dictionary = game.endless_greenhouse.prepare_save_namespace()
	assert(bool(namespace_result.get("copied", false)))
	assert(game._active_save_path() == EXPERIMENT_PATH)
	assert(FileAccess.get_file_as_bytes(EXPERIMENT_PATH) == normal_bytes_before)

	_test_discovery_probability_and_set_state()
	_test_per_spawn_new_switch_and_story_guarantee(game)
	_test_localized_trial_tutorial(game)
	game.rng.seed = 880031
	await _test_endless_first_play_tutorial(game)
	game._update_play_ui()
	assert(game.play_active and game.active_seed_type == "normal")
	assert(game.normal_seed_bags == 0)
	assert(game.plants.size() >= game.PLAY_INITIAL_MIN_PLANTS and game.plants.size() <= game.PLAY_INITIAL_MAX_PLANTS)
	assert(not game.play_open_button.visible and not game.play_overlay.visible and not game.normal_play_button.visible)
	assert(not game.seed_bag_panel.visible and not game.seed_pod_gauge_area.visible and not game.puku_gauge_area.visible)
	assert(not game.result_overlay.visible)
	for plant in game.plants:
		plant.jelly_checks_enabled = false

	var concurrent_target: int = game.play_concurrent_target
	var harvested = game.plants[0]
	harvested.diameter_cm = 30.0
	harvested.harvest()
	await get_tree().create_timer(1.55).timeout
	assert(game.play_active and game.plants.size() == concurrent_target)
	var jellied = game.plants[0]
	jellied.jelly()
	await get_tree().create_timer(1.75).timeout
	assert(game.play_active and game.plants.size() == concurrent_target)
	assert(game.play_seeds_remaining == 0)
	game._finish_greenhouse_play()
	assert(game.play_active and not game.result_overlay.visible)

	var total_before_batch: int = game.total_play_count
	var formal_before_batch: int = game.formal_play_count
	var normal_before_batch: int = game.normal_play_count
	game._complete_endless_virtual_batch()
	assert(game.total_play_count == total_before_batch + 1)
	assert(game.formal_play_count == formal_before_batch + 1)
	assert(game.normal_play_count == normal_before_batch + 1)
	assert(game.play_active and not game.result_overlay.visible)

	await _test_immediate_species_get_and_pause(game)
	await _test_forced_new_lifecycle(game)
	await _test_navigation_pause_resume(game)
	await _test_trial_dev_controls_and_gacha(game)
	await _test_fusion_lab_flow(game)
	_test_gauges(game)
	await _test_restoration_pending_until_habitat(game)
	_test_large_plant_screen_hits(game)

	game.puku_points = 88
	game.bests["colorata"] = 101.0
	game.story_progression_state["endless_smoke_marker"] = "B"
	game._save()
	assert(FileAccess.get_file_as_bytes(NORMAL_PATH) == normal_bytes_before)
	var experiment_payload = JSON.parse_string(FileAccess.get_file_as_string(EXPERIMENT_PATH))
	assert(experiment_payload is Dictionary and int(experiment_payload.get("puku_points", -1)) == 88)

	_test_finite_mode_unchanged(game)
	assert(FileAccess.get_file_as_bytes(NORMAL_PATH) != PackedByteArray())

	game.free()
	await get_tree().process_frame
	_remove_test_file(NORMAL_PATH)
	_remove_test_file(EXPERIMENT_PATH)
	print("ENDLESS_GREENHOUSE_SMOKE_OK autostart=true modal=false infinite=true refill=harvest+jelly result=false longevity=35/35/22/8 per_spawn_new=false discovery_set=12 forced_new=true immediate_get=true pause=true navigation=true trial_dev=settings+story+jelly+gacha dev_gacha_saved=true fusion=entrance+open+parents+execute+species_get pod=false puku=false restoration_pending=true finite=true save_isolated=true")
	get_tree().quit()


func _configure_ready_greenhouse(game: Node) -> void:
	game.opening_finished = true
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.trio_originals_confirmed = true
	game.habitat_unlocked = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_tutorial_started = true
	game.habitat_tutorial_complete = true
	game.habitat_tutorial_returned_to_greenhouse = true
	game.seed_shop_open = true
	game.mystery_items_acquired = true
	game.mystery_catalog_tutorial_complete = true
	game.puku_gauge_intro_complete = true
	game.normal_play_tutorial_complete = true
	game.seed_pod_gauge_discovery_complete = true
	game.seed_pod_first_reward_seen = true
	game.initial_seed_stock_notice_complete = true
	game.puku_buyback_tutorial_complete = true
	game.jurejure_intro_complete = true
	game.jurejure_enabled = true
	game.act2_unlocked = false
	game.act3_unlocked = false
	game.act3_intro_pending = false
	game.act3_intro_seen = false
	game.fantasy_first_discovery_seen = true
	game.fantasy_realization_seen = true
	game.jurejure_species_first_seen = true
	game.habitat_crisis_pending = false
	game.habitat_crisis_started = false
	game.finale_complete = false
	game.current_mode = "greenhouse"
	game.story_progression_state = StoryProgressionClass.default_runtime_state()
	game.story_progression_state["arrangement_unlocked"] = true
	game.story_progression_state["arrangement_intro_seen"] = true
	game.discovered = {"colorata": true}
	game.species_get_counts = {"colorata": 1}
	game.greenhouse_available = {"colorata": true}
	game.unlocked_species = game.greenhouse_available.duplicate(true)
	game.unlocked_series = {"base": true}
	game.species = [game._catalog_entry("colorata")]
	game.opening_overlay.visible = false
	game.opening_story_overlay.visible = false
	game.intro_overlay.visible = false
	game.result_overlay.visible = false
	game.shop_overlay.visible = false
	game.settings_overlay.visible = false
	game.encyclopedia_overlay.visible = false
	game.play_overlay.visible = false
	game.tutorial_guide_overlay.visible = false
	game.species_get_overlay.visible = false
	game._apply_mode()
	game._update_play_ui()


func _complete_discovery_set(trial, max_harvest_cm: float) -> Dictionary:
	var result: Dictionary
	if max_harvest_cm > 0.0:
		result = trial.register_discovery_settlement(true, max_harvest_cm)
	else:
		result = trial.register_discovery_settlement(false, 0.0)
	for index in range(1, trial.DISCOVERY_SET_SIZE):
		result = trial.register_discovery_settlement(false, 0.0)
	return result


func _test_discovery_probability_and_set_state() -> void:
	var trial = EndlessClass.new()
	trial.configure(true)
	assert(is_zero_approx(EndlessClass.discovery_base_chance_for_cm(0.0)))
	assert(is_equal_approx(EndlessClass.discovery_base_chance_for_cm(20.0), 0.005))
	assert(is_equal_approx(EndlessClass.discovery_base_chance_for_cm(30.0), 0.01))
	assert(is_equal_approx(EndlessClass.discovery_base_chance_for_cm(40.0), 0.02))
	assert(is_equal_approx(EndlessClass.discovery_base_chance_for_cm(50.0), 0.05))
	assert(is_equal_approx(EndlessClass.discovery_base_chance_for_cm(55.0), 0.075))
	assert(is_equal_approx(EndlessClass.discovery_base_chance_for_cm(60.0), 0.10))
	assert(is_equal_approx(EndlessClass.discovery_base_chance_for_cm(70.0), 0.18))
	assert(is_equal_approx(EndlessClass.discovery_base_chance_for_cm(80.0), 0.30))
	assert(is_equal_approx(EndlessClass.discovery_base_chance_for_cm(90.0), 0.45))
	assert(is_equal_approx(EndlessClass.discovery_base_chance_for_cm(100.0), 0.65))
	assert(is_equal_approx(EndlessClass.discovery_base_chance_for_cm(110.0), 0.82))
	assert(is_equal_approx(EndlessClass.discovery_base_chance_for_cm(120.0), 0.95))
	assert(is_equal_approx(EndlessClass.discovery_base_chance_for_cm(200.0), 0.95))
	assert(EndlessClass.discovery_base_chance_for_cm(200.0) < 1.0)

	# Harvest and jelly both settle plants, while only harvested centimeters set
	# the hidden maximum. Eleven settlements never evaluate the set.
	for index in range(10):
		assert(not bool(trial.register_discovery_settlement(false, 999.0).get("set_completed", false)))
	assert(not bool(trial.register_discovery_settlement(true, 55.0).get("set_completed", false)))
	assert(trial.discovery_settled_count == 11 and is_equal_approx(trial.discovery_set_max_harvest_cm, 55.0))
	var first: Dictionary = trial.register_discovery_settlement(false, 999.0)
	assert(bool(first.get("set_completed", false)))
	assert(is_equal_approx(float(first.get("set_max_harvest_cm", -1.0)), 55.0))
	assert(is_equal_approx(float(first.get("new_chance", -1.0)), 0.075))
	assert(trial.discovery_settled_count == 0 and is_zero_approx(trial.discovery_set_max_harvest_cm))

	var repeat: Dictionary = _complete_discovery_set(trial, 55.0)
	assert(not bool(repeat.get("improved_cycle_best", true)))
	assert(is_equal_approx(float(repeat.get("new_chance", -1.0)), 0.03))
	var repeat_again: Dictionary = _complete_discovery_set(trial, 55.0)
	assert(is_equal_approx(float(repeat_again.get("new_chance", -1.0)), 0.03))
	var improved: Dictionary = _complete_discovery_set(trial, 60.0)
	assert(bool(improved.get("improved_cycle_best", false)))
	assert(is_equal_approx(float(improved.get("new_chance", -1.0)), 0.10))

	trial.reset_discovery_state()
	assert(is_equal_approx(float(_complete_discovery_set(trial, 80.0).get("new_chance", -1.0)), 0.30))
	assert(is_equal_approx(float(_complete_discovery_set(trial, 79.0).get("new_chance", -1.0)), 0.03))
	assert(is_equal_approx(float(_complete_discovery_set(trial, 90.0).get("new_chance", -1.0)), 0.45))
	trial.reset_discovery_state()
	assert(is_equal_approx(float(_complete_discovery_set(trial, 20.0).get("new_chance", -1.0)), 0.005))
	assert(is_equal_approx(float(_complete_discovery_set(trial, 20.0).get("new_chance", -1.0)), 0.005))
	trial.reset_discovery_state()
	assert(is_equal_approx(float(_complete_discovery_set(trial, 120.0).get("new_chance", -1.0)), 0.95))
	assert(is_equal_approx(float(_complete_discovery_set(trial, 150.0).get("new_chance", -1.0)), 0.95))

	# Active forced plants are restored as one reserved pending seed because live
	# Plant nodes themselves are intentionally not serialized.
	trial.complete_discovery_cycle()
	trial.discovery_settled_count = 7
	trial.discovery_set_max_harvest_cm = 62.0
	trial.discovery_cycle_best_cm = 80.0
	assert(trial.queue_forced_new())
	assert(trial.consume_forced_new("laui"))
	assert(not trial.queue_forced_new())
	var saved_state: Dictionary = trial.discovery_state_for_save()
	var restored = EndlessClass.new()
	restored.configure(true)
	restored.restore_discovery_state(saved_state)
	assert(restored.discovery_settled_count == 7)
	assert(is_equal_approx(restored.discovery_set_max_harvest_cm, 62.0))
	assert(is_equal_approx(restored.discovery_cycle_best_cm, 80.0))
	assert(restored.forced_new_pending and restored.forced_new_active_species_id.is_empty())
	assert(restored.forced_new_candidate_hint() == "laui")


func _test_per_spawn_new_switch_and_story_guarantee(game: Node) -> void:
	var candidates: Dictionary = game._eligible_endless_forced_new_candidates()
	var unlocked: Array = candidates.get("unlocked", [])
	var locked: Array = candidates.get("locked", [])
	assert(not unlocked.is_empty() or not locked.is_empty())
	var finite_roll: Dictionary = game._select_normal_seed_species(0.0, true)
	assert(game._species_get_count(str(finite_roll.get("species_id", ""))) == 0)
	var endless_roll: Dictionary = game._select_normal_seed_species(0.0, false)
	assert(game._species_get_count(str(endless_roll.get("species_id", ""))) > 0)

	# Explicit story guarantees stay ahead of the ENDLESS random selection path.
	var guaranteed: Dictionary = (unlocked[0] if not unlocked.is_empty() else locked[0]).duplicate(true)
	game.opening_species = [guaranteed]
	game.play_active = true
	game.active_seed_type = "normal"
	game.spawn_plant(false, Vector3.ZERO)
	var spawned = game.plants.back()
	assert(str(spawned.data.get("species_id", "")) == str(guaranteed.get("species_id", "")))
	assert(bool(spawned.get_meta("new_species_candidate", false)))
	assert(not bool(spawned.get_meta("endless_forced_new", false)))
	game._clear_greenhouse_plants()
	game.play_active = false


func _test_localized_trial_tutorial(game: Node) -> void:
	for language in ["ja", "hiragana", "en"]:
		assert(not Localizer.text(language, "initial_seed_stock_endless_girl").is_empty())
		assert(not Localizer.text(language, "initial_seed_stock_endless_armadillo").is_empty())
		assert(not Localizer.text(language, "tutorial_normal_pre_sow_endless").is_empty())
		assert(not Localizer.text(language, "play_normal_seed_endless").is_empty())
		assert(not Localizer.text(language, "endless_record_update", [87.4]).is_empty())


func _test_endless_first_play_tutorial(game: Node) -> void:
	game._clear_greenhouse_plants()
	game.play_active = false
	game.play_modal_open = false
	game.normal_play_tutorial_complete = false
	game.puku_buyback_tutorial_complete = false
	game.seed_pod_first_reward_seen = false
	game.first_seed_pod_reward_event_active = false
	game.initial_seed_stock_notice_complete = false
	game.first_habitat_gift_claimed = false
	game.normal_seed_bags = 0
	game.tutorial_steps.erase(game.ENDLESS_AUTO_SOW_TUTORIAL_STEP)
	game.play_overlay.visible = false
	game.tutorial_guide_overlay.visible = false
	assert(not game._normal_seed_play_available())
	game._start_initial_seed_stock_notice()
	assert(game.scripted_dialog_kind == "initial_seed_stock")
	assert(game.scripted_dialog_pages.size() == 2)
	assert(game.scripted_dialog_pages[0].text == Localizer.text("ja", "initial_seed_stock_endless_girl"))
	assert(game.scripted_dialog_pages[1].text == Localizer.text("ja", "initial_seed_stock_endless_armadillo"))
	assert(game.scripted_dialog_pages.all(func(page: Dictionary) -> bool: return str(page.get("text", "")) != Localizer.text("ja", "initial_seed_stock_received")))
	assert(not game.first_habitat_gift_claimed)
	game._advance_scripted_dialog()
	assert(game.scripted_dialog_index == 1 and not game.first_habitat_gift_claimed)
	game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.initial_seed_stock_notice_complete)
	assert(game.first_habitat_gift_claimed and game.normal_seed_bags == 0 and game._normal_seed_play_available())
	assert(game.scripted_dialog_kind == "first_normal_sow_prompt")
	assert(game.scripted_dialog_pages.size() == 1)
	assert(game.scripted_dialog_pages[0].text == Localizer.text("ja", "tutorial_normal_pre_sow_endless"))
	assert(not game.play_modal_open and not game.play_overlay.visible and not game.tutorial_guide_overlay.visible)
	game._advance_scripted_dialog()
	await get_tree().create_timer(.72).timeout
	assert(game.play_active and game.first_play_tutorial_active)
	assert(game.active_seed_type == "normal")
	assert(game.plants.size() >= game.PLAY_INITIAL_MIN_PLANTS and game.plants.size() <= game.PLAY_INITIAL_MAX_PLANTS)
	assert(not game.play_modal_open and not game.play_overlay.visible and not game.normal_play_button.visible)
	var tutorial_plant = game.plants[0]
	var tutorial_species_id := str(tutorial_plant.data.get("species_id", ""))
	game.discovered[tutorial_species_id] = true
	game.species_get_counts[tutorial_species_id] = 1
	game.first_play_tutorial_sequence_complete = true
	game.first_play_harvest_guide_active = true
	game.tutorial_harvest_plant = tutorial_plant
	tutorial_plant.diameter_cm = 25.0
	tutorial_plant.harvest()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.play_active and game.normal_play_tutorial_complete)
	assert(not game.first_play_tutorial_active)
	assert(not game.first_seed_pod_reward_event_active and not game.result_overlay.visible)
	assert(game.puku_buyback_tutorial_active)
	assert(game.tutorial_guide_message.text == Localizer.text("ja", "puku_buyback_1"))
	game._advance_puku_buyback_tutorial()
	assert(game.puku_buyback_tutorial_complete and not game.puku_buyback_tutorial_active)
	await get_tree().create_timer(1.55).timeout
	assert(game.play_active and game.plants.size() == game.play_concurrent_target)


func _test_immediate_species_get_and_pause(game: Node) -> void:
	var species_id := "laui"
	game.discovered.erase(species_id)
	game.species_get_counts.erase(species_id)
	game._spawn_specific_plant(species_id)
	var newcomer = game.plants.back()
	newcomer.jelly_checks_enabled = false
	newcomer.diameter_cm = 34.0
	newcomer.harvest()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.species_get_overlay.visible)
	assert(game.result_new_species_queue.is_empty())
	assert(not game._should_simulate_endless_greenhouse())
	var observer = game.plants[0]
	observer.jelly_checks_enabled = false
	var age_before: float = observer.age
	var spawn_queue_before: int = game.play_spawn_queue
	game._process(1.0)
	assert(is_equal_approx(observer.age, age_before))
	assert(game.play_spawn_queue == spawn_queue_before)
	await get_tree().create_timer(.55).timeout
	game.species_get_overlay.close_overlay()
	await get_tree().create_timer(.24).timeout
	assert(not game.species_get_overlay.visible)
	assert(game._should_simulate_endless_greenhouse())


func _test_forced_new_lifecycle(game: Node) -> void:
	game.story_progression_state["pending_story_events"] = []
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.intro_overlay.visible = false
	game.endless_greenhouse.reset_discovery_state()
	# The twelfth settlement performs one roll but does not reveal a card yet.
	for index in range(11):
		var partial: Dictionary = game._record_endless_discovery_settlement(index == 0, 60.0 if index == 0 else 0.0, 0.0)
		assert(not bool(partial.get("set_completed", false)))
	var completed: Dictionary = game._record_endless_discovery_settlement(false, 0.0, 0.0)
	assert(bool(completed.get("set_completed", false)))
	assert(is_equal_approx(float(completed.get("new_chance", -1.0)), 0.10))
	assert(game.endless_greenhouse.forced_new_pending)
	assert(not game.species_get_overlay.visible)

	var before_count: int = game.plants.size()
	game.spawn_plant(false, Vector3(0.0, 0.0, 0.0))
	var forced_plant = game.plants.back()
	var forced_species_id := str(forced_plant.data.get("species_id", ""))
	assert(bool(forced_plant.get_meta("endless_forced_new", false)))
	assert(game._species_get_count(forced_species_id) == 0)
	assert(not game.endless_greenhouse.forced_new_pending)
	assert(game.endless_greenhouse.forced_new_active_species_id == forced_species_id)
	game.spawn_plant(false, Vector3(0.5, 0.0, 0.0))
	var ordinary_plant = game.plants.back()
	assert(not bool(ordinary_plant.get_meta("endless_forced_new", false)))
	assert(game.plants.size() == before_count + 2)

	forced_plant.jelly_checks_enabled = false
	forced_plant.diameter_cm = 35.0
	forced_plant.harvest()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.species_get_overlay.visible)
	assert(not game.endless_greenhouse.has_forced_new())
	assert(is_zero_approx(game.endless_greenhouse.discovery_cycle_best_cm))
	await get_tree().create_timer(.55).timeout
	game.species_get_overlay.close_overlay()
	await get_tree().create_timer(.24).timeout
	game.story_progression_state["pending_story_events"] = []
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.intro_overlay.visible = false
	game._clear_greenhouse_plants()
	game.play_spawn_queue = 0
	game.play_seed_animations_pending = 0

	# Losing the guaranteed plant preserves the cycle best and only clears that
	# one in-world reservation, allowing a later set to roll again.
	game.endless_greenhouse.reset_discovery_state()
	game.endless_greenhouse.discovery_cycle_best_cm = 80.0
	assert(game.endless_greenhouse.queue_forced_new())
	game.spawn_plant(false, Vector3.ZERO)
	var doomed = game.plants.back()
	var doomed_species_id := str(doomed.data.get("species_id", ""))
	assert(bool(doomed.get_meta("endless_forced_new", false)))
	doomed.jelly()
	assert(game.endless_greenhouse.forced_new_active_species_id.is_empty())
	assert(is_equal_approx(game.endless_greenhouse.discovery_cycle_best_cm, 80.0))
	assert(game._species_get_count(doomed_species_id) == 0)
	game._clear_greenhouse_plants()
	game.play_spawn_queue = 0
	game.play_seed_animations_pending = 0

	# No eligible species means no fake reservation and no cycle reset.
	var saved_counts: Dictionary = game.species_get_counts.duplicate(true)
	var eligible: Dictionary = game._eligible_endless_forced_new_candidates()
	for entry in (eligible.get("unlocked", []) as Array) + (eligible.get("locked", []) as Array):
		game.species_get_counts[str(entry.get("species_id", ""))] = 1
	game.endless_greenhouse.reset_discovery_state()
	for index in range(11):
		game._record_endless_discovery_settlement(index == 0, 50.0 if index == 0 else 0.0, 0.0)
	game._record_endless_discovery_settlement(false, 0.0, 0.0)
	assert(not game.endless_greenhouse.has_forced_new())
	assert(is_equal_approx(game.endless_greenhouse.discovery_cycle_best_cm, 50.0))
	game.species_get_counts = saved_counts

	# The hidden counters and reservation are persisted only in the experiment
	# save payload, preventing save/reload probability exploits.
	game.endless_greenhouse.discovery_settled_count = 5
	game.endless_greenhouse.discovery_set_max_harvest_cm = 44.0
	game.endless_greenhouse.discovery_cycle_best_cm = 73.0
	game._save()
	var saved_payload = JSON.parse_string(FileAccess.get_file_as_string(EXPERIMENT_PATH))
	assert(saved_payload is Dictionary)
	var saved_discovery: Dictionary = saved_payload.get("endless_discovery_state", {})
	assert(int(saved_discovery.get("discovery_settled_count", -1)) == 5)
	assert(is_equal_approx(float(saved_discovery.get("discovery_set_max_harvest_cm", -1.0)), 44.0))
	assert(is_equal_approx(float(saved_discovery.get("discovery_cycle_best_cm", -1.0)), 73.0))
	game.endless_greenhouse.reset_discovery_state()
	game._queue_greenhouse_replacements()
	await get_tree().create_timer(1.6).timeout
	assert(not game.plants.is_empty())


func _test_navigation_pause_resume(game: Node) -> void:
	game.story_progression_state["pending_story_events"] = []
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.intro_overlay.visible = false
	assert(game._greenhouse_area_navigation_available())
	var observer = game.plants[0]
	observer.jelly_checks_enabled = false
	var age_before_habitat: float = observer.age
	game._toggle_mode()
	assert(game.current_mode == "habitat" and game.play_active)
	assert(game.mode_button.visible)
	assert(not game._should_simulate_endless_greenhouse())
	game._process(1.0)
	assert(is_equal_approx(observer.age, age_before_habitat))
	game._toggle_mode()
	assert(game.current_mode == "greenhouse" and game.play_active)
	var age_before_resume: float = observer.age
	game._process(.25)
	assert(observer.age > age_before_resume)
	game.arrangement_scene_active = true
	var age_before_arrangement: float = observer.age
	game._process(1.0)
	assert(is_equal_approx(observer.age, age_before_arrangement))
	game.arrangement_scene_active = false
	game._update_play_ui()
	assert(game._greenhouse_area_navigation_available())
	var age_before_dialog: float = observer.age
	game._start_scripted_dialog("endless_smoke_pause", [{"speaker": "panda", "text": "pause"}], false)
	game._process(1.0)
	assert(is_equal_approx(observer.age, age_before_dialog))
	game._advance_scripted_dialog()
	await get_tree().process_frame
	var age_before_dialog_resume: float = observer.age
	game._process(.25)
	assert(observer.age > age_before_dialog_resume)

	# If a safe transition ever leaves the loop inactive, returning to the plain
	# greenhouse reconstructs it without exposing a start button or seed modal.
	game.current_mode = "habitat"
	game.play_active = false
	game.play_spawn_queue = 0
	game.play_seed_animations_pending = 0
	game._clear_greenhouse_plants()
	game._apply_mode()
	game._process(.1)
	assert(not game.play_active)
	game.current_mode = "greenhouse"
	game._apply_mode()
	game._process(.01)
	await get_tree().create_timer(.72).timeout
	assert(game.play_active and game.active_seed_type == "normal")
	assert(not game.play_open_button.visible and not game.play_overlay.visible)


func _test_trial_dev_controls_and_gacha(game: Node) -> void:
	# Release ENDLESS is a contained trial-dev surface even without the separate
	# habitat debug query. The normal release URL remains production-only.
	game.habitat_debug_enabled = false
	assert(game._trial_dev_controls_enabled())
	var trial_balance:Dictionary=game._greenhouse_jelly_balance_for_spawn()
	assert(is_equal_approx(float(trial_balance.short_weight),35.0))
	assert(is_equal_approx(float(trial_balance.normal_weight),35.0))
	assert(is_equal_approx(float(trial_balance.long_weight),22.0))
	assert(is_equal_approx(float(trial_balance.ultra_weight),8.0))
	assert(is_equal_approx(float(JellyBalanceClass.FORMAL.short_weight),45.0))
	assert(is_equal_approx(float(JellyBalanceClass.FORMAL.normal_weight),35.0))
	assert(is_equal_approx(float(JellyBalanceClass.FORMAL.long_weight),16.0))
	assert(is_equal_approx(float(JellyBalanceClass.FORMAL.ultra_weight),4.0))

	game._update_play_ui()
	assert(game.settings_button.visible and game.encyclopedia_icon_button.visible)
	var observer=game.plants[0]
	observer.jelly_checks_enabled=false
	var age_before_settings:float=observer.age
	game._open_settings()
	assert(game.settings_overlay.visible and not game._should_simulate_endless_greenhouse())
	assert(not game.settings_button.visible and not game.encyclopedia_icon_button.visible)
	game._process(1.0)
	assert(is_equal_approx(observer.age,age_before_settings))
	assert(game.find_child("JellyDevOpen",true,false)!=null)
	assert(game.find_child("StoryDevOpen",true,false)!=null)
	assert(game.find_child("TrialDevGachaOpen",true,false)!=null)

	game._open_story_dev()
	assert(game.story_dev_panel!=null and game.story_dev_panel.visible)
	assert(not game._should_simulate_endless_greenhouse())
	game.story_dev_panel.close()
	game._open_settings()
	game._open_jelly_dev()
	assert(game.jelly_dev_overlay.visible and not game._should_simulate_endless_greenhouse())
	game._dev_reset_jelly()
	game._close_jelly_dev()
	assert(game._should_simulate_endless_greenhouse())

	# Pick a deterministic not-yet-discovered result, then exercise the real
	# ForestGacha UI path with a synthetic wallet. The actual puku balance must
	# remain byte-for-byte untouched while discovery state is saved normally.
	var selected_seed:=-1
	var next_draw:int=game.forest_gacha_draw_count+1
	for seed_value in range(2000):
		var probe:=RandomNumberGenerator.new();probe.seed=seed_value
		var candidate:Dictionary=game.forest_gacha_system.draw(next_draw,game.unlocked_series,game.discovered,game.forest_gacha_encountered,probe,-1.0,StoryProgressionClass.fantasy_is_unlocked(game.story_progression_state),game.jurejure_species_unlocked)
		if not candidate.is_empty() and not bool(game.discovered.get(str(candidate.get("species_id","")),false)):
			selected_seed=seed_value;break
	assert(selected_seed>=0)
	var puku_before:int=game.puku_points
	game._open_settings()
	game._open_trial_dev_forest_gacha()
	assert(game.forest_gacha_trial_dev_mode and game.forest_gacha_ui.visible)
	assert(game.forest_gacha_ui.current_puku_points==game.TRIAL_DEV_GACHA_WALLET)
	assert(not game._should_simulate_endless_greenhouse())
	game.forest_gacha_ui.animation_time_scale=.001
	game.forest_gacha_rng.seed=selected_seed
	game._spin_forest_gacha()
	var result:Dictionary=game.forest_gacha_ui.pending_result
	var species_id:=str(result.get("species_id",""))
	assert(not species_id.is_empty() and bool(game.discovered.get(species_id,false)))
	assert(bool(game.greenhouse_available.get(species_id,false)))
	assert(bool(game.arrangement_ui.discovered.get(species_id,false)))
	assert(game.species.any(func(entry:Dictionary)->bool:return str(entry.get("species_id",""))==species_id))
	assert(game.puku_points==puku_before)
	var saved_payload=JSON.parse_string(FileAccess.get_file_as_string(EXPERIMENT_PATH))
	assert(saved_payload is Dictionary)
	assert(bool((saved_payload.get("discovered",{}) as Dictionary).get(species_id,false)))
	await get_tree().create_timer(.12).timeout
	assert(game.forest_gacha_ui.capsule_ready)
	game.forest_gacha_ui._reveal_result()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.species_get_overlay.visible)
	await get_tree().create_timer(.55).timeout
	game.species_get_overlay.close_overlay()
	await get_tree().create_timer(.24).timeout
	assert(not game.species_get_overlay.visible)
	game._close_forest_gacha()
	assert(not game.forest_gacha_trial_dev_mode and game.puku_points==puku_before)
	game.story_progression_state["pending_story_events"]=[]
	game.scripted_dialog_kind="";game.scripted_dialog_pages.clear();game.intro_overlay.visible=false
	assert(game._should_simulate_endless_greenhouse())
	var age_before_resume:float=observer.age
	game._process(.25)
	assert(observer.age>age_before_resume)


func _test_fusion_lab_flow(game: Node) -> void:
	assert(game._is_endless_normal_play())
	var gummy_id := "gummy_peach_milk"
	var metal_id := "metal_silver_rosette"
	var hybrid_id := "hyb_gummy_metal"
	for parent_id in [gummy_id, metal_id]:
		game.discovered[parent_id] = true
		game.greenhouse_available[parent_id] = true
		game.unlocked_species[parent_id] = true
		game.species_get_counts[parent_id] = 1
	game.discovered.erase(hybrid_id)
	game.greenhouse_available.erase(hybrid_id)
	game.unlocked_species.erase(hybrid_id)
	game.species_get_counts.erase(hybrid_id)
	game._apply_saved_unlocks()
	game._update_play_ui()
	assert(game._fusion_lab_available())
	assert(game.fusion_lab_button.visible)

	var observer = game.plants[0]
	observer.jelly_checks_enabled = false
	var age_before_lab: float = observer.age
	var spawn_queue_before: int = game.play_spawn_queue
	game.fusion_lab_button.pressed.emit()
	assert(game.fusion_lab_ui.visible)
	assert(not game._should_simulate_endless_greenhouse())
	game._process(1.0)
	assert(is_equal_approx(observer.age, age_before_lab))
	assert(game.play_spawn_queue == spawn_queue_before)

	game.fusion_lab_ui.parent_a_button.pressed.emit()
	assert(game.fusion_lab_ui.picker_page.visible and game.fusion_lab_ui.picker_slot == 0)
	game.fusion_lab_ui._choose_candidate(gummy_id)
	assert(game.fusion_parent_a_id == gummy_id)
	game.fusion_lab_ui.parent_b_button.pressed.emit()
	assert(game.fusion_lab_ui.picker_page.visible and game.fusion_lab_ui.picker_slot == 1)
	game.fusion_lab_ui._choose_candidate(metal_id)
	assert(game.fusion_parent_b_id == metal_id)
	assert(str(game.fusion_lab_ui.current_result.get("result_species_id", "")) == hybrid_id)
	assert(not game.fusion_lab_ui.fuse_button.disabled)

	var gummy_before: int = game._species_get_count(gummy_id)
	var metal_before: int = game._species_get_count(metal_id)
	game.fusion_lab_ui.fuse_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game._species_get_count(gummy_id) == gummy_before)
	assert(game._species_get_count(metal_id) == metal_before)
	assert(game._species_get_count(hybrid_id) == 1)
	assert(bool(game.discovered.get(hybrid_id, false)))
	assert(game.species_get_overlay.visible)
	assert(game.species_get_overlay.name_label.text == "金箔グミ")
	assert(not game._should_simulate_endless_greenhouse())

	await get_tree().create_timer(.55).timeout
	game.species_get_overlay.close_overlay()
	await get_tree().create_timer(.24).timeout
	assert(not game.species_get_overlay.visible)
	assert(game._is_endless_normal_play() and game._should_simulate_endless_greenhouse())
	var age_before_resume: float = observer.age
	game._process(.25)
	assert(observer.age > age_before_resume)


func _test_gauges(game: Node) -> void:
	game.puku_gauge_cm = 123.0
	game.puku_coin_gauge_cm = 321.0
	game.puku_points = 7
	game._update_play_ui()
	assert(not game.seed_pod_gauge_area.visible and not game.puku_gauge_area.visible)
	assert(game.add_seed_pod_gauge_cm(700.0, false, false) == 0)
	assert(is_equal_approx(game.puku_gauge_cm, 123.0))
	assert(game.add_puku_coin_gauge_cm(1500.0, false, false) == 0)
	assert(is_equal_approx(game.puku_coin_gauge_cm, 321.0) and game.puku_points == 7)
	game._spawn_specific_plant("colorata")
	var gauge_probe = game.plants.back()
	gauge_probe.jelly_checks_enabled = false
	gauge_probe.diameter_cm = 100.0
	gauge_probe.harvest()
	assert(is_equal_approx(game.puku_gauge_cm, 123.0))
	assert(is_equal_approx(game.puku_coin_gauge_cm, 321.0) and game.puku_points == 7)
	game._clear_greenhouse_plants()
	game.play_spawn_queue = 0
	game.play_seed_animations_pending = 0
	game.jurejure_waiting_for_seed_pod_reward = true
	assert(not game._should_show_jurejure_group())
	assert(game.add_seed_pod_gauge_cm(2000.0, false, false) == 0)
	assert(game.jurejure_waiting_for_seed_pod_reward)
	assert(game.add_puku_coin_gauge_cm(2000.0, false, false) == 0)
	assert(game.jurejure_waiting_for_seed_pod_reward)
	game.endless_greenhouse.reset_discovery_state()
	for index in range(11):
		game._record_endless_discovery_settlement(false, 0.0, 0.0)
	assert(game.jurejure_waiting_for_seed_pod_reward)
	game._record_endless_discovery_settlement(false, 0.0, 0.0)
	assert(not game.jurejure_waiting_for_seed_pod_reward and game._should_show_jurejure_group())
	assert(not game._queue_first_seed_pod_max_event())


func _test_restoration_pending_until_habitat(game: Node) -> void:
	game.story_progression_state["pending_story_events"]=[]
	var restoration := HabitatRestorationClass.default_state()
	restoration["tracking_started"] = true
	restoration["join_home_seen"] = true
	restoration["jurejure_joined"] = true
	restoration["started"] = true
	game.story_progression_state["restoration"] = restoration
	game.current_mode = "greenhouse"
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.intro_overlay.visible = false
	game._apply_mode()
	for diameter in [101.0, 108.0]:
		game._spawn_specific_plant("colorata")
		var plant = game.plants.back()
		plant.jelly_checks_enabled = false
		plant.diameter_cm = diameter
		plant.harvest()
	await get_tree().process_frame
	var saved_restoration: Dictionary = game._restoration_state()
	assert(HabitatRestorationClass.returned_count(saved_restoration) == 2)
	assert(HabitatRestorationClass.pending_return_stages(saved_restoration) == [1, 2])
	assert(game.current_mode == "greenhouse" and game.play_active)
	assert(game.scripted_dialog_kind.is_empty())
	game._toggle_mode()
	await get_tree().create_timer(.12).timeout
	assert(game.current_mode == "habitat")
	assert(game.scripted_dialog_kind == "restoration_return_1")
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.scripted_dialog_index = -1
	game.intro_overlay.visible = false
	game.current_mode = "greenhouse"
	game._apply_mode()


func _test_large_plant_screen_hits(game: Node) -> void:
	game._clear_greenhouse_plants()
	game.play_active = false
	game.current_mode = "greenhouse"
	game._apply_mode()
	game.bests["colorata"] = 1000.0
	for diameter in [30.0, 60.0, 100.0, 155.0]:
		game._spawn_specific_plant("colorata")
		var plant = game.plants.back()
		plant.jelly_checks_enabled = false
		plant.fast_forward_to_diameter(diameter)
		var center_probe: Dictionary = plant.screen_hit_test(game.camera, Vector2(-10000, -10000))
		var visible_rect: Rect2 = center_probe.get("rect", Rect2())
		assert(visible_rect.size.x > 0.0 and visible_rect.size.y > 0.0)
		var leaf_point := visible_rect.get_center()
		assert(bool(plant.screen_hit_test(game.camera, leaf_point).get("hit", false)))
		game._try_harvest(leaf_point)
		assert(plant.state == "harvested")
		game._clear_greenhouse_plants()

	# Move a 155 cm plant until its root projects beyond the left edge while a
	# substantial part of the billboard remains visible, then harvest that part.
	game._spawn_specific_plant("colorata")
	var edge_plant = game.plants.back()
	edge_plant.jelly_checks_enabled = false
	edge_plant.fast_forward_to_diameter(155.0)
	var edge_rect := Rect2()
	var edge_found := false
	for world_x in [-2.0, -3.0, -4.0, -5.0, -6.0, -7.0, -8.0, -9.0, -10.0]:
		edge_plant.position.x = world_x
		var probe: Dictionary = edge_plant.screen_hit_test(game.camera, Vector2(-10000, -10000))
		edge_rect = probe.get("rect", Rect2())
		var root_screen: Vector2 = game.camera.unproject_position(edge_plant.global_position)
		if root_screen.x < 0.0 and edge_rect.end.x > 40.0:
			edge_found = true
			break
	assert(edge_found)
	var visible_viewport := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	var visible_part := edge_rect.intersection(visible_viewport)
	assert(visible_part.size.x > 20.0 and visible_part.size.y > 20.0)
	var visible_leaf_point := visible_part.get_center()
	assert(bool(edge_plant.screen_hit_test(game.camera, visible_leaf_point).get("hit", false)))
	game._try_harvest(visible_leaf_point)
	assert(edge_plant.state == "harvested")
	game._clear_greenhouse_plants()

	# When a normal plant is visibly centered over a giant, the normalized
	# screen-space score should select the plant the player actually touched.
	game._spawn_specific_plant("colorata")
	var giant = game.plants.back()
	giant.fast_forward_to_diameter(155.0)
	game._spawn_specific_plant("colorata")
	var normal = game.plants.back()
	normal.position = giant.position
	normal.fast_forward_to_diameter(30.0)
	var normal_probe: Dictionary = normal.screen_hit_test(game.camera, Vector2(-10000, -10000))
	var normal_rect: Rect2 = normal_probe.get("rect", Rect2())
	game._try_harvest(normal_rect.get_center())
	assert(normal.state == "harvested" and giant.state == "growing")
	game._clear_greenhouse_plants()


func _test_finite_mode_unchanged(game: Node) -> void:
	game._clear_greenhouse_plants()
	game.play_active = false
	game.scripted_dialog_kind="";game.scripted_dialog_pages.clear();game.species_get_queue.clear()
	game.intro_overlay.visible=false;game.settings_overlay.visible=false;game.encyclopedia_overlay.visible=false
	if game.story_dev_panel:game.story_dev_panel.visible=false
	if game.jelly_dev_overlay:game.jelly_dev_overlay.visible=false
	if game.forest_gacha_ui:game.forest_gacha_ui.visible=false
	game.arrangement_scene_active=false;game.arrangement_transitioning=false
	game.endless_greenhouse.configure(false)
	game.habitat_debug_enabled=false
	assert(not game._trial_dev_controls_enabled())
	assert(game._greenhouse_jelly_balance_for_spawn().is_empty())
	assert(is_equal_approx(float(JellyBalanceClass.FORMAL.short_weight),45.0))
	assert(is_equal_approx(float(JellyBalanceClass.FORMAL.normal_weight),35.0))
	assert(is_equal_approx(float(JellyBalanceClass.FORMAL.long_weight),16.0))
	assert(is_equal_approx(float(JellyBalanceClass.FORMAL.ultra_weight),4.0))
	game.normal_seed_bags = 1
	game.volume_seed_unlocked = true
	game.volume_seed_bags = 1
	game.puku_gauge_cm = 0.0
	game.current_mode = "greenhouse"
	game._apply_mode()
	game.result_overlay.visible = false
	game.play_modal_open = false
	game._update_play_ui()
	assert(game.play_open_button.visible)
	game._open_play_modal()
	assert(game.play_overlay.visible and game.normal_play_button.visible and game.volume_play_button.visible)
	game._close_play_modal()
	var finite_new_roll: Dictionary = game._select_normal_seed_species(0.0, true)
	assert(game._species_get_count(str(finite_new_roll.get("species_id", ""))) == 0)
	game._start_greenhouse_play("normal")
	assert(game.play_active and game.normal_seed_bags == 0)
	assert(is_equal_approx(game._puku_gauge_target_cm(), 500.0) and game._puku_gauge_reward_puku() == 3)
	assert(game.play_seeds_remaining < game.NORMAL_GERMINATION_COUNT)
	assert(game.seed_pod_gauge_area.visible and game.puku_gauge_area.visible)
	game._clear_greenhouse_plants()
	game.play_seeds_remaining = 0
	game.play_spawn_queue = 0
	game.play_seed_animations_pending = 0
	game.first_play_tutorial_active = false
	game.puku_buyback_tutorial_active = false
	game._finish_greenhouse_play()
	assert(not game.play_active and game.result_overlay.visible)
	assert(game.add_seed_pod_gauge_cm(10.0, false, false) == 0)
	assert(is_equal_approx(game.puku_gauge_cm, 10.0))
	game.puku_points = 0
	game.puku_coin_gauge_cm = 0.0
	assert(game.add_puku_coin_gauge_cm(500.0, false, false) == 3)
	assert(game.puku_points == 3)
	game.jurejure_waiting_for_seed_pod_reward = true
	game.puku_gauge_cm = 740.0
	assert(game.add_seed_pod_gauge_cm(10.0, false, false) == game.SEED_POD_GAUGE_REWARD_BAGS)
	assert(not game.jurejure_waiting_for_seed_pod_reward)
	game._save()
	var finite_payload = JSON.parse_string(FileAccess.get_file_as_string(NORMAL_PATH))
	assert(finite_payload is Dictionary and not finite_payload.has("endless_discovery_state"))


func _remove_test_file(path: String) -> void:
	if FileAccess.file_exists(path):
		assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
