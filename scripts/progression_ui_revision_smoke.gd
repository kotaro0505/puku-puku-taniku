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
	_test_language_ui_geometry(game)
	_test_top_hud_and_speaker_geometry(game)
	_test_shop_chatter_contract(game)
	_test_habitat_attention_glow(game)
	_test_arrangement_gate_and_direction(game)
	_test_progression_thresholds()
	_test_phase_bgm_policy(game)
	game._reset_progression_state()
	print("PROGRESSION_UI_REVISION_SMOKE_OK copy=updated language_ui=fixed shop_chatter=5 glow=gang_only arrangement=1+swipe forest=6 bgm=phase-aware migration=preserved")
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
	assert(Localizer.text("ja", "puku_buyback_1") == "そうだ！育てた多肉はうちのお店で買い取るよ！")
	assert(Localizer.text("ja", "puku_buyback_2") == "大きい株ほど高く買い取るからね！")
	assert(Localizer.text("ja", "puku_buyback_2_endless") == "大きい株を収穫するほど\nぷくゲージが溜まります。\n満タンになると +1ぷくコインGET！")
	assert(Localizer.text("ja", "jurejure_first_peccary") == "いっぱい生えてるッペー！\nぜーんぶ頂きだッペー！")
	assert(Localizer.text("ja", "fantasy_first_armadillo") == "こんな多肉、あの本には載ってないよ…。")
	assert(Localizer.text("ja", "habitat_crisis_no_battle") == "……今はバトルする気にならないチュー……。")
	assert(Localizer.text("ja", "puku_gauge") == "ぷくゲージ")
	assert(Localizer.text("hiragana", "puku_gauge") == "ぷくげーじ")
	assert(Localizer.text("en", "puku_gauge") == "Puku Gauge")
	assert(Localizer.text("hiragana", "new") == "にゅー！")
	assert(Localizer.text("hiragana", "original_catalog_new") == "にゅー！")
	assert(Localizer.text("hiragana", "fusion_new") == "にゅー")
	assert(Localizer.text("hiragana", "self_best", [12.3]).begins_with("こじこべすと"))
	assert(Localizer.text("hiragana", "self_best_none") == "こじこべすと　ー")
	assert(Localizer.text("hiragana", "share_record") == "こじこべすと！")
	for locale in Localizer.SUPPORTED_LANGUAGES:
		for key in [
			"puku_buyback_1", "puku_buyback_2", "puku_buyback_2_endless", "jurejure_first_peccary", "fantasy_first_armadillo",
			"arrangement_unlock_panda", "arrangement_swipe_intro",
			"arrangement_mode_hint", "main_game_mode_hint",
			"act3_exploitation_battle_intro", "act3_exploitation_battle_intro_panda",
			"act3_exploitation_battle_intro_mouse_2", "habitat_crisis_no_battle",
			"post_crisis_greenhouse_panda_1", "post_crisis_greenhouse_armadillo",
			"post_crisis_greenhouse_girl", "post_crisis_greenhouse_panda_2",
		]:
			assert(not Localizer.text(locale, key).is_empty())


func _test_language_ui_geometry(game: Node) -> void:
	var settings_panel := game.settings_overlay.get_child(1) as PanelContainer
	var original_panel_rect := Rect2(settings_panel.position, settings_panel.size)
	var original_play_rect := Rect2(game.play_open_button.position, game.play_open_button.size)
	for locale in Localizer.SUPPORTED_LANGUAGES:
		game._set_language(locale)
		assert(Rect2(settings_panel.position, settings_panel.size) == original_panel_rect)
		assert(Rect2(game.play_open_button.position, game.play_open_button.size) == original_play_rect)
		assert(game.settings_title_label.custom_minimum_size.x == 420.0)
		assert(game.settings_language_heading.custom_minimum_size.x == 420.0)
		for language_button_value in game.language_buttons.values():
			var language_button := language_button_value as Button
			assert(language_button.custom_minimum_size.x == 134.0 and language_button.clip_text)
		var bgm_toggle := game.find_child("BgmToggle", true, false) as CheckButton
		var se_toggle := game.find_child("SeToggle", true, false) as CheckButton
		assert(bgm_toggle.custom_minimum_size.x == 145.0 and se_toggle.custom_minimum_size.x == 145.0)
		assert(bgm_toggle.text == "BGM" and se_toggle.text == "SE")
	game._set_language("ja")


func _test_top_hud_and_speaker_geometry(game: Node) -> void:
	var logo := game.main_status_hud.find_child("MainLogo", true, false) as Label
	assert(logo != null and logo.position == Vector2(16, 34) and logo.position.x + logo.size.x <= game.best_panel.position.x)
	assert(game.best_panel.position == Vector2(204, 122) and game.best_panel.size == Vector2(168, 65))
	assert(game.seed_bag_panel.position == Vector2(210, 198))
	assert(not Rect2(logo.position, logo.size).intersects(Rect2(game.best_panel.position, game.best_panel.size)))
	assert(not Rect2(game.best_panel.position, game.best_panel.size).intersects(Rect2(game.seed_bag_panel.position, game.seed_bag_panel.size)))
	assert(game.intro_speaker_label.get_parent() == game.intro_portrait_slot)
	assert(game.intro_speaker_label.position.y + game.intro_speaker_label.size.y <= game.intro_panda_portrait.position.y + 2.0)
	for overlay in [game.habitat_awakening_overlay, game.seed_pod_story_overlay, game.habitat_second_awakening_overlay, game.jurejure_first_encounter_overlay]:
		assert(overlay.speaker_label.position.x == overlay.speaker_portrait.position.x)
		assert(overlay.speaker_label.position.y + overlay.speaker_label.size.y <= overlay.speaker_portrait.position.y)


func _test_shop_chatter_contract(game: Node) -> void:
	assert(game.SHOP_CHATTER_KEYS == [
		"shop_chatter_today", "shop_chatter_share", "shop_chatter_welcome",
		"shop_chatter_living_jewel", "shop_chatter_puku_help",
	])
	assert(Localizer.text("ja", "shop_chatter_today") == "今日はどんな多肉に出会えるかな。")
	assert(Localizer.text("ja", "shop_chatter_share") == "沢山の人に多肉植物を知ってもらうにはどうしたらいいんだろうね。")
	assert(Localizer.text("ja", "shop_chatter_welcome") == "いらっしゃい！")
	assert(Localizer.text("ja", "shop_chatter_living_jewel") == "多肉はまさに生きる宝石だよね。")
	assert(Localizer.text("ja", "shop_chatter_puku_help") == "もし、ぷくコインがなくなったら僕に声かけてよ！")
	for locale in Localizer.SUPPORTED_LANGUAGES:
		for chatter_key in game.SHOP_CHATTER_KEYS:
			assert(not Localizer.text(locale, chatter_key).is_empty())


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
	assert(JureJureSystem.habitat_bgm_key(true, true) == "habitat_crisis")
	assert(JureJureSystem.habitat_bgm_key(false, true) == "habitat_crisis")
	var crisis_stream: AudioStream = game.audio_manager._stream_for("bgm", "habitat_crisis")
	assert(crisis_stream is AudioStreamMP3 and crisis_stream.loop)
	game.current_mode = "habitat"
	game.story_progression_state["exploitation_started"] = true
	game.habitat_crisis_started = false
	game._play_current_area_bgm()
	assert(game.audio_manager.current_bgm_key == "jurejure")
	game.habitat_crisis_started = true
	game._play_current_area_bgm()
	assert(game.audio_manager.current_bgm_key == "habitat_crisis")
