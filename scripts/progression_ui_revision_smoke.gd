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
	_test_habitat_button_stays_plain(game)
	_test_arrangement_gate_and_direction(game)
	_test_progression_thresholds()
	_test_phase_bgm_policy(game)
	game._reset_progression_state()
	print("PROGRESSION_UI_REVISION_SMOKE_OK copy=updated language_ui=fixed panda_chatter=5 armadillo_chatter=5 habitat_button=always_plain arrangement=3+swipe forest=8 fusion=12 bgm=phase-aware migration=preserved")
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
	assert(Localizer.text("ja", "puku_buyback_1") == "そうだ！育てた多肉は\nうちのお店で買い取るよ！")
	assert(Localizer.text("ja", "puku_buyback_2") == "大きい株ほど\n高く買い取るからね！")
	assert(Localizer.text("ja", "puku_buyback_2_endless") == "大きい株を収穫するほど\nぷくゲージが溜まります。\n満タンになると +1ぷくコインGET！")
	assert(Localizer.text("ja", "jurejure_first_peccary") == "多肉植物が生えてるッペー！\nぜーんぶ頂きだッペー！")
	assert(Localizer.text("hiragana", "jurejure_first_peccary") == "たにくしょくぶつが はえてるッペー！\nぜーんぶ いただきだッペー！")
	assert(Localizer.text("en", "jurejure_first_peccary") == "There are succulents growing here!\nWe're taking every last one!")
	assert(Localizer.text("ja", "restoration_final_girl_2") == "自然の中で、私たちは創造をしてるってことを忘れちゃダメだね。")
	assert(Localizer.text("hiragana", "restoration_final_girl_2") == "しぜんの なかで、わたしたちは ものを つくりだしてるってことを わすれちゃ だめだね。")
	assert(Localizer.text("en", "restoration_final_girl_2") == "We must never forget that we create within nature.")
	assert(Localizer.text("ja", "fantasy_first_armadillo") == "こんな多肉、あの本には載ってないよ…。")
	assert(Localizer.text("ja", "habitat_crisis_no_battle") == "…今は、バトルする気にならない\nチュー")
	assert(Localizer.text("ja", "puku_gauge") == "ぷくゲージ")
	assert(Localizer.text("hiragana", "puku_gauge") == "ぷくげーじ")
	assert(Localizer.text("en", "puku_gauge") == "Puku Gauge")
	assert(Localizer.text("hiragana", "new") == "にゅー！")
	assert(Localizer.text("hiragana", "original_catalog_new") == "にゅー！")
	assert(Localizer.text("hiragana", "fusion_new") == "にゅー")
	assert(Localizer.text("ja", "main_forest_gacha") == "ガチャ")
	assert(Localizer.text("hiragana", "main_forest_gacha") == "がちゃ")
	assert(Localizer.text("en", "main_forest_gacha") == "Gacha")
	assert(Localizer.text("ja", "fusion_lab_intro_armadillo_3") == "多肉植物同士をかけあわせて\n新たな品種を作れるよ！")
	assert(Localizer.text("ja", "self_best", [12.3]) == "最大サイズ 12.3cm")
	assert(Localizer.text("ja", "self_best_none") == "最大サイズ ー")
	assert(Localizer.text("hiragana", "self_best", [12.3]) == "さいだいさいず 12.3cm")
	assert(Localizer.text("hiragana", "self_best_none") == "さいだいさいず ー")
	assert(Localizer.text("en", "self_best", [12.3]) == "Max Size 12.3 cm")
	assert(Localizer.text("en", "self_best_none") == "Max Size —")
	assert(Localizer.text("hiragana", "share_record") == "こじこべすと！")
	for locale in Localizer.SUPPORTED_LANGUAGES:
		for key in [
			"puku_buyback_1", "puku_buyback_2", "puku_buyback_2_endless", "jurejure_first_peccary", "fantasy_first_armadillo",
			"arrangement_unlock_panda", "arrangement_swipe_intro",
			"arrangement_mode_hint", "main_game_mode_hint",
			"fusion_lab_intro_armadillo_1", "fusion_lab_intro_girl_1",
			"fusion_lab_intro_armadillo_2", "fusion_lab_intro_armadillo_3",
			"fusion_lab_intro_girl_2", "fusion_lab_intro_armadillo_4",
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
	assert(Localizer.text("ja", "shop_puku_rescue_offer") == "ぷくコインが足りないの？\nお店を手伝ってくれたら、1ぷくコイン渡すよ！")
	assert(Localizer.text("ja", "shop_puku_rescue_success") == "お手伝いありがとう！\n1ぷくコインを受け取ってね。")
	var expected_armadillo_pages := [
		["原生地にお還しした品種は原生地で\n自然に増えてるみたいだ。"],
		["原生地からもらった種のさやと図鑑、\n大切にしよう。"],
		["絶滅したはずの多肉植物が見れるなんて\nすごいことだよね。"],
		["新しく発見した品種はぼくが原生地に\nお還しておくからね。"],
		["多肉の葉をもいで土に挿しておくと\n根と芽が出て増えるんだ。", "「葉挿し」って言うんだよ。"],
	]
	assert(game.ARMADILLO_SHOP_CHATTER_KEY_PAGES.size() == 5)
	for pattern_index in range(game.ARMADILLO_SHOP_CHATTER_KEY_PAGES.size()):
		var localized_pages: Array[String] = []
		for key in game.ARMADILLO_SHOP_CHATTER_KEY_PAGES[pattern_index]:localized_pages.append(Localizer.text("ja", str(key)))
		assert(localized_pages == expected_armadillo_pages[pattern_index])
	var previous_armadillo_index := -1
	for sample_index in range(30):
		var pages: Array[String] = game._pick_armadillo_shop_chatter_pages()
		assert(not pages.is_empty())
		assert(game.last_armadillo_shop_chatter_index != previous_armadillo_index)
		previous_armadillo_index = game.last_armadillo_shop_chatter_index
	game.last_armadillo_shop_chatter_index = -1
	for locale in Localizer.SUPPORTED_LANGUAGES:
		assert(not Localizer.text(locale, "shop_preparing_arrangement").is_empty())
		assert(not Localizer.text(locale, "shop_puku_rescue_offer").is_empty())
		assert(not Localizer.text(locale, "shop_puku_rescue_success").is_empty())
		assert(not Localizer.text(locale, "catalog_first_new_armadillo").is_empty())
		for chatter_key in game.SHOP_CHATTER_KEYS:
			assert(not Localizer.text(locale, chatter_key).is_empty())
		for armadillo_pattern in game.ARMADILLO_SHOP_CHATTER_KEY_PAGES:
			for chatter_key in armadillo_pattern:assert(not Localizer.text(locale, str(chatter_key)).is_empty())


func _test_habitat_button_stays_plain(game: Node) -> void:
	assert(not game.has_method("_update_habitat_button_glow"))
	var normal_modulate: Color = game.mode_button.self_modulate
	var normal_child_count: int = game.mode_button.get_child_count()
	assert(normal_modulate.is_equal_approx(Color.WHITE))
	assert(not game.mode_button.has_meta("habitat_glow_active"))

	# Normal greenhouse state.
	game.habitat_old_catalog_page_pending = false
	game.jurejure_waiting_for_seed_pod_reward = true
	game.story_progression_state["exploitation_started"] = false
	game._update_play_ui()
	_assert_habitat_button_plain(game, normal_modulate, normal_child_count)

	# An old catalog page waiting in the habitat must not alter the button.
	game.habitat_old_catalog_page_pending = true
	game._update_play_ui()
	_assert_habitat_button_plain(game, normal_modulate, normal_child_count)
	game.habitat_old_catalog_page_pending = false

	# The Jurejure gang's presence must not alter the button either.
	game.jurejure_waiting_for_seed_pod_reward = false
	assert(game._should_show_jurejure_group())
	game._update_habitat_ui()
	_assert_habitat_button_plain(game, normal_modulate, normal_child_count)

	# Navigation remains intact in both directions.
	game.jurejure_waiting_for_seed_pod_reward = true
	game._toggle_mode()
	assert(game.current_mode == "habitat")
	game._toggle_mode()
	assert(game.current_mode == "greenhouse")
	_assert_habitat_button_plain(game, normal_modulate, normal_child_count)


func _assert_habitat_button_plain(game: Node, expected_modulate: Color, expected_child_count: int) -> void:
	assert(game.mode_button.self_modulate.is_equal_approx(expected_modulate))
	assert(game.mode_button.get_child_count() == expected_child_count)
	assert(not game.mode_button.has_meta("habitat_glow_active"))


func _test_arrangement_gate_and_direction(game: Node) -> void:
	game.jurejure_waiting_for_seed_pod_reward = true
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

	var current_one_fantasy := StoryProgression.normalize_runtime_state({"version": StoryProgression.RUNTIME_STATE_VERSION}, {"fantasy_get_count": 1})
	assert(not StoryProgression.arrangement_is_unlocked(current_one_fantasy))
	assert(not bool(current_one_fantasy.get("arrangement_intro_pending", false)))
	var current_three_fantasy := StoryProgression.normalize_runtime_state({"version": StoryProgression.RUNTIME_STATE_VERSION}, {"fantasy_get_count": 3})
	assert(not StoryProgression.arrangement_is_unlocked(current_three_fantasy))
	assert(bool(current_three_fantasy.get("arrangement_intro_pending", false)))
	# Old saves really had access at one GET, so migration preserves it.
	var migrated_from_fantasy := StoryProgression.normalize_runtime_state({"version": 2}, {"fantasy_get_count": 1})
	assert(StoryProgression.arrangement_is_unlocked(migrated_from_fantasy))
	assert(bool(migrated_from_fantasy.get("arrangement_intro_seen", false)))
	var migrated_from_work := StoryProgression.normalize_runtime_state({"version": 2}, {"arrangement_evidence": true})
	assert(StoryProgression.arrangement_is_unlocked(migrated_from_work))


func _test_progression_thresholds() -> void:
	var state := StoryProgression.default_runtime_state()
	state["fantasy_unlocked"] = true
	for count in range(1, 3):
		StoryProgression.record_new_get(state, {
			"act2_unlocked": true,
			"is_original": false,
			"is_fantasy": true,
			"fantasy_get_count": count,
			"fantasy_first_seen": count > 1,
			"fantasy_six_seen": false,
			"forest_gacha_unlocked": false,
			"forest_gacha_intro_seen": false,
		})
		assert(not bool(state.get("arrangement_intro_pending", false)))
		assert(not bool(state.get("forest_gacha_unlock_pending", false)))
	StoryProgression.record_new_get(state, {
		"act2_unlocked": true,
		"is_original": false,
		"is_fantasy": true,
		"fantasy_get_count": 3,
		"fantasy_first_seen": true,
		"fantasy_six_seen": false,
		"forest_gacha_unlocked": false,
		"forest_gacha_intro_seen": false,
	})
	assert(bool(state.get("arrangement_intro_pending", false)))
	assert(StoryProgression.EVENT_ARRANGEMENT_INTRO in (state.get("pending_story_events", []) as Array))
	StoryProgression.complete_arrangement_intro(state)
	StoryProgression.record_new_get(state, {
		"act2_unlocked": true,
		"is_original": false,
		"is_fantasy": true,
		"fantasy_get_count": 4,
		"fantasy_required_series_complete": true,
		"fantasy_first_seen": true,
		"fantasy_six_seen": false,
		"forest_gacha_unlocked": false,
		"forest_gacha_intro_seen": false,
	})
	assert(not bool(state.get("forest_gacha_unlock_pending", false)))
	assert(StoryProgression.EVENT_FANTASY_SIX in (state.get("pending_story_events", []) as Array))
	StoryProgression.consume_story_event(state, StoryProgression.EVENT_FANTASY_SIX)
	for count in range(5, 8):
		StoryProgression.record_new_get(state, {
			"act2_unlocked": true,
			"is_original": false,
			"is_fantasy": true,
			"fantasy_get_count": count,
			"fantasy_required_series_complete": true,
			"fantasy_first_seen": true,
			"fantasy_six_seen": true,
			"forest_gacha_unlocked": false,
			"forest_gacha_intro_seen": false,
		})
		assert(not bool(state.get("forest_gacha_unlock_pending", false)))
	StoryProgression.record_new_get(state, {
		"act2_unlocked": true,
		"is_original": false,
		"is_fantasy": true,
		"fantasy_get_count": 8,
		"fantasy_required_series_complete": true,
		"fantasy_first_seen": true,
		"fantasy_six_seen": true,
		"forest_gacha_unlocked": false,
		"forest_gacha_intro_seen": false,
	})
	assert(bool(state.get("forest_gacha_unlock_pending", false)))
	assert(StoryProgression.EVENT_FOREST_GACHA_INTRO in (state.get("pending_story_events", []) as Array))
	assert(StoryProgression.take_forest_gacha_unlock(state))
	assert(not StoryProgression.take_forest_gacha_unlock(state))
	StoryProgression.complete_forest_gacha_intro(state)
	for count in range(9, 12):
		StoryProgression.record_new_get(state, {
			"act2_unlocked": true,
			"is_original": false,
			"is_fantasy": true,
			"fantasy_get_count": count,
			"fantasy_first_seen": true,
			"fantasy_six_seen": true,
			"forest_gacha_unlocked": true,
			"forest_gacha_intro_seen": true,
		})
		assert(not StoryProgression.fusion_lab_intro_is_pending(state))
	StoryProgression.record_new_get(state, {
		"act2_unlocked": true,
		"is_original": false,
		"is_fantasy": true,
		"fantasy_get_count": 12,
		"fantasy_first_seen": true,
		"fantasy_six_seen": true,
		"forest_gacha_unlocked": true,
		"forest_gacha_intro_seen": true,
	})
	assert(StoryProgression.fusion_lab_intro_is_pending(state))
	assert(not StoryProgression.fusion_lab_is_unlocked(state))
	assert(StoryProgression.EVENT_FUSION_LAB_INTRO in (state.get("pending_story_events", []) as Array))
	StoryProgression.complete_fusion_lab_intro(state)
	assert(StoryProgression.fusion_lab_is_unlocked(state))
	assert(not StoryProgression.fusion_lab_intro_is_pending(state))
	StoryProgression.record_new_get(state, {
		"act2_unlocked": true,
		"is_original": false,
		"is_fantasy": true,
		"fantasy_get_count": 13,
		"fantasy_first_seen": true,
		"fantasy_six_seen": true,
		"forest_gacha_unlocked": true,
		"forest_gacha_intro_seen": true,
	})
	assert(not StoryProgression.fusion_lab_intro_is_pending(state))
	assert(StoryProgression.EVENT_FUSION_LAB_INTRO not in (state.get("pending_story_events", []) as Array))

	# Loading a current-format six-GET save clears the old pending unlock, while
	# genuine feature access from an established save remains authoritative.
	var interrupted_old_six := StoryProgression.default_runtime_state()
	interrupted_old_six["forest_gacha_unlock_pending"] = true
	var normalized_old_six := StoryProgression.normalize_runtime_state(interrupted_old_six, {
		"fantasy_get_count": 6,
	})
	assert(not bool(normalized_old_six.get("forest_gacha_unlock_pending", false)))
	assert(StoryProgression.EVENT_FOREST_GACHA_INTRO not in (normalized_old_six.get("pending_story_events", []) as Array))
	var preserved_gacha := StoryProgression.normalize_runtime_state(StoryProgression.default_runtime_state(), {
		"fantasy_get_count": 2,
		"forest_gacha_evidence": true,
		"forest_gacha_intro_seen": false,
	})
	assert(StoryProgression.EVENT_FOREST_GACHA_INTRO in (preserved_gacha.get("pending_story_events", []) as Array))

	# Pre-change saves had no lab fields; preserve their old tutorial access and
	# still queue the new twelve-GET introduction exactly once.
	var legacy_lab_state := StoryProgression.default_runtime_state()
	for key in ["fusion_lab_unlocked", "fusion_lab_intro_pending", "fusion_lab_intro_seen"]:
		legacy_lab_state.erase(key)
	legacy_lab_state = StoryProgression.normalize_runtime_state(legacy_lab_state, {
		"fantasy_get_count": 12,
		"fusion_lab_legacy_access": true,
	})
	assert(StoryProgression.fusion_lab_is_unlocked(legacy_lab_state))
	assert(StoryProgression.fusion_lab_intro_is_pending(legacy_lab_state))


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
