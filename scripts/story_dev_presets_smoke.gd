extends Node

const StoryDevPresetsClass = preload("res://scripts/story_dev_presets.gd")
const StoryProgressionClass = preload("res://scripts/story_progression.gd")
const HabitatRestorationClass = preload("res://scripts/habitat_restoration.gd")


func _ready() -> void:
	assert(not StoryDevPresetsClass.available(false))
	assert(StoryDevPresetsClass.available(true))
	await _test_post_first_normal_tutorial_preset()
	await _test_act3_and_crisis_presets()
	await _test_new_route_presets()
	await _test_restoration_and_101cm_presets()
	await _test_ending_presets()
	print("STORY_DEV_PRESETS_SMOKE_OK post_12_seed_tutorial=true tutorial_original_GET=true act2_original_guarantee_unconsumed=true all_platforms=true release_switch=true habitat_debug_independent=true act3_ready=true exploitation=true crisis_ready=7 weak=0/1 first_return=pending restoration=0,1,4 fifth=pending ending=true thank_you=true complete=true harvestable_101=true")
	get_tree().quit()


func _new_game():
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	assert(game.TRIAL_DEV_CONTROLS_ENABLED)
	assert(game.DEVELOPMENT_CATALOG_PREVIEW_ENABLED == game.TRIAL_DEV_CONTROLS_ENABLED)
	assert(game.story_dev_panel != null)
	assert(game.habitat_dev_panel != null)
	assert(game.jelly_dev_overlay != null)
	assert(game.catalog_preview_ui != null)
	assert(game.find_child("StoryDevOpen", true, false) != null)
	assert(game.find_child("ProgressionDevReset", true, false) != null)
	assert(game.find_child("JellyDevOpen", true, false) != null)
	assert(game.find_child("TrialDevGachaOpen", true, false) != null)
	assert(game.find_child("HabitatDevOpen", true, false) != null)
	assert(game.find_child("OpeningStoryReplay", true, false) != null)
	assert(game.find_child("CatalogPreviewDevOpen", true, false) != null)
	for preset_id in StoryDevPresetsClass.PRESET_IDS:
		assert(game.story_dev_panel.find_child("StoryPreset_%s" % preset_id, true, false) != null)
	assert(game.story_dev_panel.find_child("StoryDevSpawn101", true, false) != null)
	game.habitat_debug_enabled = false
	assert(game._trial_dev_controls_enabled())
	assert(game._trial_dev_controls_enabled_for_context(true))
	assert(game._trial_dev_controls_enabled_for_context(false))
	game._open_story_dev()
	assert(game.story_dev_panel.visible)
	game.story_dev_panel.close()
	game.settings_overlay.visible = true
	game._open_habitat_dev()
	assert(game.habitat_dev_panel.visible)
	assert(not game.settings_overlay.visible)
	game.habitat_dev_panel.close()
	var puku_before_units: int = game.puku_balance_units
	game._adjust_progression_dev_value("puku_coin", 1)
	assert(game.puku_balance_units == puku_before_units + game.PUKU_UNITS_PER_PUKU)
	game._adjust_progression_dev_value("puku_coin", -1)
	assert(game.puku_balance_units == puku_before_units)
	game.endless_greenhouse.configure(true)
	assert(game._trial_dev_controls_enabled())
	game.settings_overlay.visible = true
	game._open_story_dev()
	assert(game.story_dev_panel.visible)
	assert(not game.settings_overlay.visible)
	game.story_dev_panel.close()
	assert(game._is_endless_greenhouse_enabled())
	game.settings_overlay.visible = true
	game._open_story_dev()
	assert(game.story_dev_panel.visible)
	assert(not game.settings_overlay.visible)
	game.story_dev_panel.close()
	return game


func _test_post_first_normal_tutorial_preset() -> void:
	var game = await _new_game()
	var result: Dictionary = game._apply_story_dev_preset(StoryDevPresetsClass.POST_FIRST_NORMAL_TUTORIAL)
	assert(bool(result.get("ok", false)))
	await get_tree().process_frame
	assert(game.current_mode == "greenhouse")
	assert(not game.play_active and not game.play_modal_open and not game.result_overlay.visible)
	assert(not game.first_play_tutorial_active and not game.tutorial_guide_overlay.visible)
	assert(game.normal_play_tutorial_complete)
	assert(bool(game.tutorial_steps.get("first_normal_cost_notice_seen", false)))
	assert(game.total_play_count == 2 and game.formal_play_count == 1 and game.normal_play_count == 1)
	var tutorial_species_id := str(game.tutorial_steps.get("first_normal_tutorial_species_id", ""))
	var tutorial_entry: Dictionary = game._catalog_entry(tutorial_species_id)
	assert(not tutorial_species_id.is_empty() and not tutorial_entry.is_empty())
	assert(bool(tutorial_entry.get("main_story_original", false)))
	assert(str(tutorial_entry.get("rarity", "")) == "通常")
	assert(game._species_get_count(tutorial_species_id) == 1)
	assert(bool(game.discovered.get(tutorial_species_id, false)))
	assert(bool(game.greenhouse_available.get(tutorial_species_id, false)))
	assert(not game.jurejure_intro_complete and game.jurejure_battle_count == 0)
	assert(game.main_story_stage == StoryProgressionClass.ACT_1 and not game.act2_unlocked)
	assert(not StoryProgressionClass.fantasy_is_unlocked(game.story_progression_state))
	assert(not bool(game.story_progression_state.get("original_new_guarantee_pending", false)))
	assert(not bool(game.story_progression_state.get("original_new_guarantee_consumed", false)))

	# The later first-battle transition independently arms the Act 2 guarantee.
	# Its candidate pool must exclude the original already earned in this tutorial.
	StoryProgressionClass.begin_act_two(game.story_progression_state)
	assert(bool(game.story_progression_state.get("original_new_guarantee_pending", false)))
	assert(not bool(game.story_progression_state.get("original_new_guarantee_consumed", false)))
	var act2_candidates: Array[Dictionary] = game._story_spawn_guarantee_candidates(false)
	assert(not act2_candidates.is_empty())
	assert(not act2_candidates.any(func(entry: Dictionary) -> bool: return str(entry.get("species_id", "")) == tutorial_species_id))
	game.free()
	await get_tree().process_frame


func _test_act3_and_crisis_presets() -> void:
	var game = await _new_game()
	var result: Dictionary = game._apply_story_dev_preset(StoryDevPresetsClass.ACT3_READY)
	assert(bool(result.get("ok", false)))
	await get_tree().process_frame
	assert(game.current_mode == "greenhouse")
	assert(game._unique_fantasy_species_get_count() == 24)
	assert(game.act3_unlocked)
	assert(game.act3_intro_pending)
	assert(not game.act3_intro_seen)
	game.current_mode = "habitat"
	game.habitat_visit_id += 1
	game._apply_mode()
	game._try_start_pending_story_event()
	await get_tree().create_timer(1.0).timeout
	assert(game.scripted_dialog_kind == "act3_intro")
	game.free()
	await get_tree().process_frame

	game = await _new_game()
	result = game._apply_story_dev_preset(StoryDevPresetsClass.CRISIS_READY)
	assert(bool(result.get("ok", false)))
	await get_tree().process_frame
	assert(game.current_mode == "habitat")
	assert(game._unique_jurejure_species_get_count() == 7)
	assert(game.jurejure_battle_count == 7)
	assert(game.jurejure_battle_win_count == 7)
	assert(StoryProgressionClass.exploitation_is_started(game.story_progression_state))
	assert(StoryProgressionClass.exploitation_midpoint_is_seen(game.story_progression_state))
	assert(not game.habitat_crisis_started)
	assert(not game.habitat_crisis_pending)
	assert(game._jurejure_reward_candidates().size() == 3)
	var reward_id: String = game._grant_jurejure_battle_reward()
	assert(not reward_id.is_empty())
	assert(game._unique_jurejure_species_get_count() == 8)
	assert(game.habitat_crisis_pending)
	assert(not game.habitat_crisis_started)
	game.current_mode = "greenhouse"
	game._apply_mode()
	game.habitat_visit_id += 1
	game.current_mode = "habitat"
	game._apply_mode()
	game._try_start_pending_story_event()
	await get_tree().create_timer(1.0).timeout
	assert(game.habitat_crisis_started)
	game.free()
	await get_tree().process_frame


func _test_new_route_presets() -> void:
	var game = await _new_game()
	var result: Dictionary = StoryDevPresetsClass.apply(game, StoryDevPresetsClass.EXPLOITATION_ACTIVE)
	assert(bool(result.get("ok", false)))
	assert(StoryProgressionClass.exploitation_is_started(game.story_progression_state))
	assert(game._unique_jurejure_species_get_count() == 0)

	result = StoryDevPresetsClass.apply(game, StoryDevPresetsClass.CRISIS_ACTIVE)
	assert(bool(result.get("ok", false)))
	assert(game.habitat_crisis_started)
	assert(HabitatRestorationClass.large_plant_mission_started(game._restoration_state()))
	assert(not bool(game._restoration_state().get("jurejure_joined", false)))
	assert(game._current_mission_text() == "100cm以上の多肉を5株、原生地へ還そう！　0/5")

	result = StoryDevPresetsClass.apply(game, StoryDevPresetsClass.FIRST_RETURN_READY)
	assert(bool(result.get("ok", false)))
	assert(HabitatRestorationClass.returned_count(game._restoration_state()) == 0)
	assert(HabitatRestorationClass.pending_return_count(game._restoration_state()) == 1)
	assert(not bool(game._restoration_state().get("jurejure_joined", false)))

	result = StoryDevPresetsClass.apply(game, StoryDevPresetsClass.RESTORATION_ONE)
	assert(bool(result.get("ok", false)))
	assert(HabitatRestorationClass.returned_count(game._restoration_state()) == 1)
	assert(bool(game._restoration_state().get("jurejure_joined", false)))
	assert(game._current_mission_text() == "100cm以上の多肉を5株、原生地へ還そう！　1/5")

	result = StoryDevPresetsClass.apply(game, StoryDevPresetsClass.RESTORATION_FIVE_READY)
	assert(bool(result.get("ok", false)))
	assert(HabitatRestorationClass.returned_count(game._restoration_state()) == 4)
	assert(HabitatRestorationClass.pending_return_count(game._restoration_state()) == 1)

	result = StoryDevPresetsClass.apply(game, StoryDevPresetsClass.COMPLETE)
	assert(bool(result.get("ok", false)))
	assert(HabitatRestorationClass.ending_phase(game._restoration_state()) == "complete")
	assert(game.finale_complete)
	game.free()
	await get_tree().process_frame


func _test_restoration_and_101cm_presets() -> void:
	var game = await _new_game()
	var result: Dictionary = game._apply_story_dev_preset(StoryDevPresetsClass.RESTORATION_ZERO)
	assert(bool(result.get("ok", false)))
	await get_tree().process_frame
	assert(StoryProgressionClass.restoration_is_started(game.story_progression_state))
	assert(HabitatRestorationClass.returned_count(game._restoration_state()) == 0)
	assert(bool(game._restoration_state().get("jurejure_joined", false)))
	assert(HabitatRestorationClass.new_species_count(game._restoration_state()) == 3)
	assert(game.habitat_restoration_ui.lamp_panel.visible)
	for lamp in game.habitat_restoration_ui.lamp_labels:
		assert(lamp.text == "○")
	game.free()
	await get_tree().process_frame

	game = await _new_game()
	result = game._apply_story_dev_preset(StoryDevPresetsClass.RESTORATION_FOUR)
	assert(bool(result.get("ok", false)))
	await get_tree().process_frame
	var restoration: Dictionary = game._restoration_state()
	assert(HabitatRestorationClass.returned_count(restoration) == 4)
	for index in 4:
		var snapshot: Dictionary = HabitatRestorationClass.returned_plants(restoration)[index]
		assert(not game._catalog_entry(str(snapshot.get("species_id", ""))).is_empty())
		assert(float(snapshot.get("diameter_cm", 0.0)) >= 100.0)
		assert(game.habitat_restoration_ui.lamp_labels[index].text == "●")
	assert(game.habitat_restoration_ui.lamp_labels[4].text == "○")
	game._save()
	game.free()
	await get_tree().process_frame
	game = await _new_game()
	restoration = game._restoration_state()
	assert(HabitatRestorationClass.returned_count(restoration) == 4)
	assert(game.habitat_crisis_started)
	assert(StoryProgressionClass.restoration_is_started(game.story_progression_state))

	game._spawn_story_dev_101_colorata()
	assert(game.current_mode == "greenhouse")
	assert(game.play_active)
	assert(game.plants.size() == 1)
	var plant = game.plants[0]
	assert(str(plant.data.get("species_id", "")) == "colorata")
	assert(is_equal_approx(float(plant.diameter_cm), 101.0))
	assert(plant.state == "growing")
	assert(not plant.jelly_checks_enabled)
	game.puku_gauge_animation_speed_scale = .02
	plant.harvest()
	assert(not game.habitat_restoration_ui.prompt_layer.visible)
	assert(HabitatRestorationClass.returned_count(restoration) == 4)
	assert(HabitatRestorationClass.pending_return_count(restoration) == 1)
	assert(str(HabitatRestorationClass.pending_return_snapshots(restoration)[0].get("species_id", "")) == "colorata")
	assert(float(HabitatRestorationClass.pending_return_snapshots(restoration)[0].get("diameter_cm", 0.0)) >= 100.0)
	assert(game.current_mode == "greenhouse")
	for _frame in range(300):
		if game.result_overlay.visible:
			break
		await get_tree().process_frame
	# The 101 cm helper is a one-plant development round. Under the formal
	# 12-seed round result flow, settling its only plant opens the round result
	# before queued story transitions are resumed.
	assert(game.result_overlay.visible)
	assert(not game.puku_gauge_animation_running and game.puku_gauge_animation_queue.is_empty())
	game.puku_gauge_animation_speed_scale = 1.0
	game._close_result()
	await get_tree().process_frame
	assert(game.scene_transition_fade.visible)
	assert(game.scene_transition_fade.color.r > 0.99 and game.scene_transition_fade.color.g > 0.99 and game.scene_transition_fade.color.b > 0.99)
	await get_tree().create_timer(2.8).timeout
	assert(game.current_mode == "habitat")
	assert(game.scripted_dialog_kind == "restoration_return_5")
	assert(HabitatRestorationClass.returned_count(restoration) == 5)
	assert(str(HabitatRestorationClass.returned_plants(restoration)[4].get("species_id", "")) == "colorata")
	_finish_dialog(game)
	await get_tree().create_timer(1.2).timeout
	assert(HabitatRestorationClass.ending_phase(restoration) == "slides")
	assert(game.habitat_restoration_ui.ending_layer.visible)
	game.free()
	await get_tree().process_frame


func _test_ending_presets() -> void:
	var game = await _new_game()
	var result: Dictionary = game._apply_story_dev_preset(StoryDevPresetsClass.ENDING_READY)
	assert(bool(result.get("ok", false)))
	assert(HabitatRestorationClass.returned_count(game._restoration_state()) == 5)
	assert(HabitatRestorationClass.ending_phase(game._restoration_state()) == "slides")
	assert(not bool(game._restoration_state().get("full_recovery_revealed", false)))
	await get_tree().create_timer(1.2).timeout
	assert(game.habitat_restoration_ui.ending_layer.visible)
	assert(game.habitat_restoration_ui.slide_index == 0)
	game.habitat_restoration_ui._advance_ending()
	game.habitat_restoration_ui._advance_ending()
	game.habitat_restoration_ui._advance_ending()
	await get_tree().create_timer(1.0).timeout
	assert(game.scripted_dialog_kind == "restoration_final")
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.scripted_dialog_kind == "restoration_epilogue")
	game.habitat_restoration_ui.ending_sequence_time_scale = 0.005
	_finish_dialog(game)
	for _frame in range(240):
		if game.habitat_restoration_ui.ending_current_phase == "await_return":
			break
		await get_tree().process_frame
	assert(game.habitat_restoration_ui.ending_sequence_layer.visible)
	assert(game.habitat_restoration_ui.ending_current_phase == "await_return")
	assert(HabitatRestorationClass.ending_phase(game._restoration_state()) == "thank_you")
	game.habitat_restoration_ui.ending_return_button.pressed.emit()
	await get_tree().create_timer(game.ENDING_BGM_FADE_OUT_SECONDS + 0.1).timeout
	assert(bool(game._restoration_state().get("thank_you_seen", false)))
	assert(game.finale_complete)
	assert(game.current_mode == "greenhouse")
	game.free()
	await get_tree().process_frame

	game = await _new_game()
	game.habitat_restoration_ui.ending_sequence_time_scale = 0.005
	result = game._apply_story_dev_preset(StoryDevPresetsClass.THANK_YOU_READY)
	assert(bool(result.get("ok", false)))
	assert(HabitatRestorationClass.ending_phase(game._restoration_state()) == "thank_you")
	assert(bool(game._restoration_state().get("full_recovery_revealed", false)))
	assert(not bool(game._restoration_state().get("thank_you_seen", false)))
	for _frame in range(240):
		if game.habitat_restoration_ui.ending_current_phase == "await_return":
			break
		await get_tree().process_frame
	assert(game.habitat_restoration_ui.ending_sequence_layer.visible)
	assert(game.habitat_restoration_ui.ending_current_phase == "await_return")
	assert(game.audio_manager.current_bgm_key == "ending")
	game.free()
	await get_tree().process_frame


func _finish_dialog(game) -> void:
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
