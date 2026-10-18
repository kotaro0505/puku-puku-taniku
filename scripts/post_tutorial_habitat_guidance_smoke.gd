extends Node

const MainScene = preload("res://main.tscn")
const Localizer = preload("res://scripts/game_localizer.gd")
const StoryProgressionClass = preload("res://scripts/story_progression.gd")
const NORMAL_PATH := "user://post_tutorial_habitat_guidance_normal_smoke.json"
const ENDLESS_PATH := "user://post_tutorial_habitat_guidance_endless_smoke.json"


func _ready() -> void:
	_remove_test_file(NORMAL_PATH)
	_remove_test_file(ENDLESS_PATH)
	var expected_copy := {
		"ja": "ねえねえ！\n原生地の様子、見に行ってみない？",
		"hiragana": "ねえねえ！\nげんせいちの ようす、みに いってみない？",
		"en": "Hey, hey!\nWant to go see how the habitat is doing?",
	}
	for locale in Localizer.SUPPORTED_LANGUAGES:
		assert(Localizer.text(locale, "post_tutorial_habitat_guidance") == expected_copy[locale])
		assert(str(expected_copy[locale]).count("\n") == 1)

	var game = await _boot_game()
	game._reset_progression_state()
	_configure_ready_state(game)

	# Finishing the tutorial's own twelve-seed round never enters the reminder
	# count, even though the completion flag becomes true before that round ends.
	game.normal_play_tutorial_complete = true
	await _finish_empty_normal_round(game, false)
	assert(game.post_tutorial_normal_games_completed == 0)
	assert(not game._post_tutorial_habitat_guidance_due())

	# The first and second complete post-tutorial rounds remain silent.
	await _finish_empty_normal_round(game, true)
	assert(game.post_tutorial_normal_games_completed == 1)
	assert(game.scripted_dialog_kind.is_empty())
	await _finish_empty_normal_round(game, true)
	assert(game.post_tutorial_normal_games_completed == 2)
	assert(game.scripted_dialog_kind.is_empty())

	# A queued GET foreground owns the screen first. Once it is gone, the third
	# round's reminder starts through the ordinary pending-story dispatcher.
	await _finish_empty_normal_round(game, true, true)
	assert(game.post_tutorial_normal_games_completed == 3)
	assert(game.scripted_dialog_kind.is_empty())
	game.species_get_queue.clear()
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind == "post_tutorial_habitat_guidance")
	await _assert_dialog(game, expected_copy["ja"])
	game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.post_tutorial_habitat_guidance_completed_game_count == 3)
	assert(not game._post_tutorial_habitat_guidance_due())

	# Every later completed game queues the same one-page reminder again.
	await _finish_empty_normal_round(game, true)
	assert(game.post_tutorial_normal_games_completed == 4)
	assert(game.scripted_dialog_kind == "post_tutorial_habitat_guidance")
	await _assert_dialog(game, expected_copy["ja"])

	# Kill the process while the fourth-game reminder is still pending/open. The
	# completed count is persisted but the acknowledgement is not, so cold start
	# replays the reminder after the title without duplicating a round.
	await _shutdown_game(game)
	game = await _boot_game()
	assert(game.post_tutorial_normal_games_completed == 4)
	assert(game.post_tutorial_habitat_guidance_completed_game_count == 3)
	assert(not game.post_tutorial_habitat_visited)
	game._finish_opening()
	assert(await _wait_until(func() -> bool: return game.scripted_dialog_kind == "post_tutorial_habitat_guidance"))
	await _assert_dialog(game, expected_copy["ja"])
	game._advance_scripted_dialog()
	assert(await _wait_until(func() -> bool: return game.scripted_dialog_kind.is_empty()))

	# The first post-tutorial habitat visit permanently retires the reminder and
	# persists that decision across another cold start.
	game._toggle_mode()
	assert(game.current_mode == "habitat")
	assert(game.post_tutorial_habitat_visited)
	assert(not game._post_tutorial_habitat_guidance_due())
	await _shutdown_game(game)
	game = await _boot_game()
	assert(game.post_tutorial_habitat_visited)
	assert(not game._post_tutorial_habitat_guidance_due())

	# A pre-feature save has no reliable post-tutorial visit timestamp. Its
	# existing completed tutorial/progress is preserved and the new early prompt
	# is treated as already retired rather than being resurrected unexpectedly.
	var legacy_payload := _read_payload()
	legacy_payload.erase("post_tutorial_normal_games_completed")
	legacy_payload.erase("post_tutorial_habitat_guidance_completed_game_count")
	legacy_payload.erase("post_tutorial_habitat_visited")
	legacy_payload["jurejure_intro_complete"] = true
	_write_payload(legacy_payload)
	await _shutdown_game(game)
	game = await _boot_game()
	assert(game.normal_play_tutorial_complete)
	assert(game.post_tutorial_habitat_visited)
	assert(not game._post_tutorial_habitat_guidance_due())

	await _shutdown_game(game)
	_remove_test_file(NORMAL_PATH)
	_remove_test_file(ENDLESS_PATH)
	print("POST_TUTORIAL_HABITAT_GUIDANCE_SMOKE_OK tutorial_excluded=true games_1_2_silent=true game_3_required=true game_4_repeats=true get_priority=true restart_pending=true visit_permanent=true legacy_safe=true languages=ja+hiragana+en")
	get_tree().quit()


func _boot_game() -> Node:
	var game = MainScene.instantiate()
	game.endless_greenhouse.set_save_paths_for_test(NORMAL_PATH, ENDLESS_PATH)
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	return game


func _shutdown_game(game: Node) -> void:
	if is_instance_valid(game):
		game.free()
	await get_tree().process_frame
	await get_tree().process_frame


func _configure_ready_state(game: Node) -> void:
	game.language_code = "ja"
	game.language_selected = true
	game.opening_finished = true
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.first_old_seed_stage = game.FIRST_OLD_SEED_STAGE_CONFIRMED
	game.trio_originals_confirmed = true
	game.total_play_count = 10
	game.formal_play_count = 1
	game.encyclopedia_unlocked = true
	game.habitat_unlocked = true
	game.habitat_arrival_started = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_tutorial_started = true
	game.habitat_tutorial_complete = true
	game.habitat_tutorial_returned_to_greenhouse = true
	game.seed_shop_open = true
	game.mystery_items_acquired = true
	game.mystery_catalog_tutorial_complete = true
	game.normal_play_tutorial_complete = false
	game.seed_pod_gauge_discovery_complete = true
	game.seed_pod_first_reward_seen = true
	game.initial_seed_stock_notice_complete = true
	game.puku_buyback_tutorial_complete = true
	game.puku_gauge_intro_complete = true
	game.first_habitat_gift_claimed = true
	game.login_bonus_date = Time.get_date_string_from_system()
	game.current_mode = "greenhouse"
	game.play_active = false
	game.post_tutorial_normal_games_completed = 0
	game.post_tutorial_habitat_guidance_completed_game_count = 0
	game.post_tutorial_habitat_visited = false
	game.normal_round_started_after_tutorial = false
	game.story_progression_state = StoryProgressionClass.default_runtime_state()
	_hide_foreground(game)
	game._save()


func _finish_empty_normal_round(game: Node, started_after_tutorial: bool, hold_get_foreground := false) -> void:
	_hide_foreground(game)
	if hold_get_foreground:
		game.species_get_queue.append({"context": "priority_sentinel"})
	game.current_mode = "greenhouse"
	game.play_active = true
	game.active_seed_type = "normal"
	game.current_target_count = game.NORMAL_GERMINATION_COUNT
	game.play_seeds_remaining = 0
	game.play_spawn_queue = 0
	game.play_seed_animations_pending = 0
	game.plants.clear()
	game.puku_gauge_animation_running = false
	game.puku_gauge_animation_queue.clear()
	game.first_play_tutorial_active = false
	game.first_seed_pod_reward_event_active = false
	game.puku_buyback_tutorial_active = false
	game.normal_round_started_after_tutorial = started_after_tutorial
	game.greenhouse_round_followup_started = false
	game._finish_greenhouse_play()
	await get_tree().process_frame
	await get_tree().process_frame


func _assert_dialog(game: Node, expected_text: String) -> void:
	assert(game.scripted_dialog_pages.size() == 1)
	assert(str(game.scripted_dialog_pages[0].get("speaker", "")) == "panda")
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == expected_text)
	assert(game.intro_dialogue_label.text == expected_text)
	assert(game.intro_dialog_panel.position == Vector2(40, 725))
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.intro_dialogue_label.get_visible_line_count() == game.intro_dialogue_label.get_line_count())


func _hide_foreground(game: Node) -> void:
	for property_name in [
		"opening_overlay", "opening_story_overlay", "habitat_awakening_overlay",
		"seed_pod_story_overlay", "habitat_second_awakening_overlay",
		"jurejure_first_encounter_overlay", "intro_overlay", "tutorial_guide_overlay",
		"result_overlay", "play_overlay", "species_get_overlay",
		"catalog_series_unlock_overlay", "forest_gacha_ui", "fusion_lab_ui",
		"encyclopedia_overlay", "shop_overlay", "settings_overlay",
		"habitat_plant_panel", "habitat_dev_panel", "story_dev_panel",
	]:
		var control = game.get(property_name)
		if control is CanvasItem:
			control.visible = false
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.scripted_dialog_index = -1
	game.species_get_queue.clear()
	game.pending_round_new_species_ids.clear()
	game.result_new_species_queue.clear()
	game.result_deferred_species_queue.clear()
	game.round_result_species_finalize_queue.clear()
	game.round_result_species_finalize_active = false
	game.catalog_series_unlock_notice_queue.clear()
	game.catalog_series_unlock_notice_ready.clear()


func _wait_until(predicate: Callable, max_frames := 240) -> bool:
	for _frame in range(max_frames):
		if predicate.call():
			return true
		await get_tree().process_frame
	return bool(predicate.call())


func _read_payload() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(ENDLESS_PATH))
	assert(parsed is Dictionary)
	return parsed


func _write_payload(payload: Dictionary) -> void:
	var file := FileAccess.open(ENDLESS_PATH, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(payload))
	file.close()


func _remove_test_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
