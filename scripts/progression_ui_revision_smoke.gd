extends Node

const Localizer = preload("res://scripts/game_localizer.gd")
const StoryProgression = preload("res://scripts/story_progression.gd")
const JureJureSystem = preload("res://scripts/jurejure_system.gd")


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	_prepare_safe_greenhouse(game)
	_test_localized_copy()
	_test_habitat_attention_glow(game)
	_test_arrangement_gate_and_direction(game)
	_test_progression_thresholds()
	_test_phase_bgm_policy(game)
	game._reset_progression_state()
	print("PROGRESSION_UI_REVISION_SMOKE_OK copy=3 glow=gang_only arrangement=1+swipe forest=6 bgm=phase-aware migration=preserved")
	get_tree().quit()


func _prepare_safe_greenhouse(game: Node) -> void:
	game._reset_progression_state()
	game.opening_story_overlay.visible = false
	game.opening_overlay.visible = false
	game.intro_overlay.visible = false
	game.result_overlay.visible = false
	game.shop_overlay.visible = false
	game.settings_overlay.visible = false
	game.encyclopedia_overlay.visible = false
	game.play_overlay.visible = false
	game.opening_finished = true
	game.intro_story_complete = true
	game.habitat_unlocked = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_tutorial_complete = true
	game.habitat_tutorial_returned_to_greenhouse = true
	game.seed_shop_open = true
	game.puku_gauge_intro_complete = true
	game.current_mode = "greenhouse"
	game.play_active = false
	game._apply_mode()
	game._update_play_ui()


func _test_localized_copy() -> void:
	assert(Localizer.text("ja", "puku_buyback_1") == "そうだ！育った多肉はうちで買い取るよ！")
	assert(Localizer.text("ja", "jurejure_first_peccary") == "いっぱい生えてるッペー！\nぜーんぶ頂きだッペー！")
	assert(Localizer.text("ja", "fantasy_first_armadillo") == "こんな多肉、あの本には載ってないよ…。")
	assert(Localizer.text("ja", "habitat_crisis_no_battle") == "今はバトルする気にならないチュー…")
	for locale in Localizer.SUPPORTED_LANGUAGES:
		for key in [
			"puku_buyback_1", "jurejure_first_peccary", "fantasy_first_armadillo",
			"arrangement_unlock_panda", "arrangement_swipe_intro",
			"arrangement_mode_hint", "main_game_mode_hint",
			"act3_exploitation_battle_intro", "habitat_crisis_no_battle",
		]:
			assert(not Localizer.text(locale, key).is_empty())


func _test_habitat_attention_glow(game: Node) -> void:
	game.habitat_old_catalog_page_pending = false
	game.habitat_mystery_seeds_pending = 3
	game.jurejure_waiting_for_seed_pod_reward = true
	game.story_progression_state["exploitation_started"] = false
	game._update_habitat_button_glow()
	assert(not bool(game.mode_button.get_meta("habitat_glow_active", false)))

	game.habitat_old_catalog_page_pending = true
	game._update_habitat_button_glow()
	assert(bool(game.mode_button.get_meta("habitat_glow_active", false)))
	game.habitat_old_catalog_page_pending = false
	game._update_habitat_button_glow()
	assert(not bool(game.mode_button.get_meta("habitat_glow_active", false)))

	game.jurejure_waiting_for_seed_pod_reward = false
	assert(game._should_show_jurejure_group())
	game._update_habitat_button_glow()
	assert(bool(game.mode_button.get_meta("habitat_glow_active", false)))


func _test_arrangement_gate_and_direction(game: Node) -> void:
	game.jurejure_waiting_for_seed_pod_reward = true
	game._update_habitat_button_glow()
	assert(not StoryProgression.arrangement_is_unlocked(game.story_progression_state))
	assert(not game._greenhouse_area_navigation_available())
	assert(game.arrangement_button == null)

	game.story_progression_state["arrangement_unlocked"] = true
	game.story_progression_state["arrangement_intro_seen"] = true
	# A progressed save still starts on the title screen. Unlock state alone must
	# never make the persistent hint leak over that boot layer or Opening Story.
	game.opening_finished = false
	game.opening_overlay.visible = true
	game._update_play_ui()
	assert(not game.arrangement_navigation_hint.visible)
	game.opening_finished = true
	game.opening_overlay.visible = false
	game.opening_story_overlay.visible = true
	game._update_play_ui()
	assert(not game.arrangement_navigation_hint.visible)
	game.opening_story_overlay.visible = false
	game._update_play_ui()
	assert(game._greenhouse_area_navigation_available())
	var transition: float = game._arrangement_focus_transition_for_pan(game.saved_greenhouse_pan_x)
	assert(not is_zero_approx(transition))
	assert(game.arrangement_navigation_hint.visible)
	assert(game.arrangement_navigation_hint.persistent_label.text == "← 寄せ植えモード")
	assert(game.arrangement_navigation_hint.persistent_panel.position.is_equal_approx(Vector2(18, 956)))
	assert(is_equal_approx(transition, game._arrangement_focus_transition_for_pan(game.saved_greenhouse_pan_x)))

	game.arrangement_scene_active = true
	game.arrangement_ui.set_world_backdrop_mode(true, game._arrangement_pot_anchor_screen())
	game.arrangement_ui.open_home()
	game._update_play_ui()
	assert(game.arrangement_navigation_hint.persistent_label.text == "メインゲーム画面 →")
	assert(game.arrangement_navigation_hint.persistent_panel.position.is_equal_approx(Vector2(326, 956)))
	assert(is_equal_approx(transition, game._arrangement_focus_transition_for_pan(game.saved_greenhouse_pan_x)))
	game.arrangement_scene_active = false
	game.arrangement_ui.visible = false
	game._update_play_ui()

	var migrated_from_fantasy := StoryProgression.normalize_runtime_state({"version": 2}, {"fantasy_get_count": 1})
	assert(StoryProgression.arrangement_is_unlocked(migrated_from_fantasy))
	assert(bool(migrated_from_fantasy.get("arrangement_intro_seen", false)))
	var migrated_from_work := StoryProgression.normalize_runtime_state({"version": 2}, {"arrangement_evidence": true})
	assert(StoryProgression.arrangement_is_unlocked(migrated_from_work))


func _test_progression_thresholds() -> void:
	var state := StoryProgression.default_runtime_state()
	state["fantasy_unlocked"] = true
	for count in range(1, 6):
		StoryProgression.record_new_get(state, {
			"act2_unlocked": true,
			"is_original": false,
			"is_fantasy": true,
			"fantasy_get_count": count,
			"fantasy_first_seen": count > 1,
			"fantasy_six_seen": false,
			"forest_gacha_unlocked": false,
		})
		assert(not bool(state.get("forest_gacha_unlock_pending", false)))
	assert(bool(state.get("arrangement_intro_pending", false)))
	StoryProgression.record_new_get(state, {
		"act2_unlocked": true,
		"is_original": false,
		"is_fantasy": true,
		"fantasy_get_count": 6,
		"fantasy_first_seen": true,
		"fantasy_six_seen": false,
		"forest_gacha_unlocked": false,
	})
	assert(bool(state.get("forest_gacha_unlock_pending", false)))
	assert(StoryProgression.EVENT_FANTASY_SIX in (state.get("pending_story_events", []) as Array))
	assert(StoryProgression.take_forest_gacha_unlock(state))
	assert(not StoryProgression.take_forest_gacha_unlock(state))


func _test_phase_bgm_policy(game: Node) -> void:
	assert(JureJureSystem.habitat_bgm_key(false, false) == "habitat")
	assert(JureJureSystem.habitat_bgm_key(true, false) == "jurejure")
	assert(JureJureSystem.habitat_bgm_key(true, true) == "habitat")
	game.current_mode = "habitat"
	game.story_progression_state["exploitation_started"] = true
	game.habitat_crisis_started = false
	game._play_current_area_bgm()
	assert(game.audio_manager.current_bgm_key == "jurejure")
	game.habitat_crisis_started = true
	game._play_current_area_bgm()
	assert(game.audio_manager.current_bgm_key == "habitat")
