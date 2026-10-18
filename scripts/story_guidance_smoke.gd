extends Node

const StoryProgressionClass = preload("res://scripts/story_progression.gd")
const HabitatRestorationClass = preload("res://scripts/habitat_restoration.gd")
const Localizer = preload("res://scripts/game_localizer.gd")

const PROTECTED_BASE_SPECIALS := [
	"golden_laui",
	"golden_kannte",
	"transparent_succulent",
]


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game._reset_progression_state()
	# This story-flow suite invokes the GET close handler directly. Leave the
	# input-latency profiler to input_response_smoke, which supplies real taps.
	game.get_close_profile_enabled=false
	_hide_foreground(game)
	_test_base_catalog_contract(game)
	_test_mission_copy_and_progress(game)
	await _test_progress_hud_boot_and_get_card_lifecycle(game)
	_test_round_navigation_lock(game)
	_test_new_gate(game)
	await _test_early_fantasy_candidate_contract(game)
	_test_fusion_fantasy_count(game)
	_test_crisis_exploitation_lockout(game)
	await _test_round_completion_before_new_cards(game)
	_test_story_copy()
	game._reset_progression_state()
	game.queue_free()
	await get_tree().process_frame
	print("STORY_GUIDANCE_SMOKE_OK mission=single+live+boot_3_phases progress_hud=get_card_hidden+restored+no_chain_flash new_gate=first_encounter result=removed automatic_formal_get=ordered_multiple pending_duplicate=false nav=hidden arrangement=locked base=originals_only early_fantasy=four_series realization=7_pages_3_locales fusion_fantasy_count=display_series crisis=exploit_locked copy=updated dev_controls=all_builds")
	get_tree().quit()


func _hide_foreground(game: Node) -> void:
	for control_name in [
		"opening_overlay", "opening_story_overlay", "habitat_awakening_overlay",
		"seed_pod_story_overlay", "habitat_second_awakening_overlay",
		"jurejure_first_encounter_overlay", "intro_overlay", "tutorial_guide_overlay",
		"result_overlay", "play_overlay", "species_get_overlay",
		"catalog_series_unlock_overlay", "forest_gacha_ui",
		"fusion_lab_ui", "encyclopedia_overlay", "shop_overlay", "settings_overlay",
		"habitat_plant_panel", "habitat_dev_panel", "story_dev_panel",
	]:
		var control = game.get(control_name)
		if control is CanvasItem:
			control.visible = false
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.species_get_queue.clear()
	game.catalog_series_unlock_notice_queue.clear()
	game.catalog_series_unlock_notice_ready.clear()
	game.pending_round_new_species_ids.clear()
	game.round_result_species_finalize_queue.clear()
	game.round_result_species_finalize_active = false


func _test_base_catalog_contract(game: Node) -> void:
	var base_entry: Dictionary = game._series_entry("base")
	var base_ids: Array = base_entry.get("species_ids", [])
	assert(base_ids.size() == StoryProgressionClass.MAIN_STORY_ORIGINAL_IDS.size())
	for original_id in StoryProgressionClass.MAIN_STORY_ORIGINAL_IDS:
		assert(original_id in base_ids)
	for species_id in PROTECTED_BASE_SPECIALS:
		assert(species_id not in base_ids)
		assert(not game._catalog_entry(species_id).is_empty())
	for species_id in StoryProgressionClass.RETIRED_SPECIAL_BASE_SPECIES_IDS:
		assert(species_id not in base_ids)
		assert(game._catalog_entry(species_id).is_empty())
	assert("現代で生まれた" not in str(base_entry.get("description", "")))


func _test_mission_copy_and_progress(game: Node) -> void:
	game.language_code = "ja"
	game.species_get_counts.clear()
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.habitat_tutorial_complete = true
	game.jurejure_intro_complete = false
	game.act2_unlocked = false
	assert(game._current_mission_text().is_empty())
	game.act2_unlocked = true
	game.story_progression_state["fantasy_unlocked"] = true
	var original_ids: Array[String] = []
	var fantasy_ids: Array[String] = []
	var jurejure_ids: Array[String] = []
	for entry_value in game.catalog_species:
		if not entry_value is Dictionary:
			continue
		if bool(entry_value.get("main_story_original", false)):
			original_ids.append(str(entry_value.get("species_id", "")))
		elif game._is_fantasy_species(entry_value) and not game._is_jurejure_species(entry_value):
			fantasy_ids.append(str(entry_value.get("species_id", "")))
		elif game._is_jurejure_species(entry_value):
			jurejure_ids.append(str(entry_value.get("species_id", "")))
	assert(original_ids.size() == 12 and fantasy_ids.size() >= 12 and jurejure_ids.size() >= 8)
	for index in range(5):
		game.species_get_counts[original_ids[index]] = 1
	for index in range(10):
		game.species_get_counts[fantasy_ids[index]] = 1
	assert(game._unique_fantasy_species_get_count() == 10)
	assert(game._unique_act2_species_get_count() == 15)
	assert(game._current_mission_text() == "最高記録を目指しながら、新しい品種を\n24種類見つけよう！　15/24")
	game._update_mission_ui()
	assert(game.mission_panel.visible)
	assert(game.mission_title_label.text == "ミッション")
	var localized_missions := {
		"ja": "最高記録を目指しながら、新しい品種を\n24種類見つけよう！　15/24",
		"hiragana": "さいこうきろくを めざしながら、あたらしい ひんしゅを\n24しゅるい みつけよう！　15/24",
		"en": "Aim for a new personal best while discovering 24 new varieties!  15/24",
	}
	for locale in Localizer.SUPPORTED_LANGUAGES:
		game.language_code = locale
		game._update_mission_ui()
		assert(game.mission_text_label.text == localized_missions[locale])
		assert(game.mission_text_label.get_visible_line_count() == game.mission_text_label.get_line_count(), "mission text clipped locale=%s visible=%d total=%d size=%s" % [locale, game.mission_text_label.get_visible_line_count(), game.mission_text_label.get_line_count(), game.mission_text_label.size])
	assert(str(localized_missions["ja"]).count("\n") == 1)
	game.language_code = "ja"
	game._update_mission_ui()
	game.play_active = true
	game._update_mission_ui()
	assert(not game.mission_panel.visible)
	game.play_active = false
	game._update_mission_ui()
	assert(game.mission_panel.visible)

	game.species_get_counts.clear()
	for species_id in original_ids:
		game.species_get_counts[species_id] = 1
	for index in range(11):
		game.species_get_counts[fantasy_ids[index]] = 1
	game.act3_unlocked = false
	game.act3_intro_pending = false
	game.act3_intro_seen = false
	assert(game._unique_fantasy_species_get_count() == 11)
	assert(game._unique_act2_species_get_count() == 23)
	assert(game._current_mission_text() == "最高記録を目指しながら、新しい品種を\n24種類見つけよう！　23/24")
	game._refresh_narrative_species_progress()
	assert(not game.act3_unlocked)
	game.species_get_counts[fantasy_ids[11]] = 1
	game._refresh_narrative_species_progress()
	assert(game._unique_fantasy_species_get_count() == 12)
	assert(game._unique_act2_species_get_count() == 24)
	assert(game.act3_unlocked and game.act3_intro_pending)

	game.species_get_counts.clear()
	for species_id in original_ids:
		game.species_get_counts[species_id] = 1
	for index in range(10):
		game.species_get_counts[fantasy_ids[index]] = 1
	for index in range(8):
		game.species_get_counts[jurejure_ids[index]] = 1
	game.act3_unlocked = false
	game.act3_intro_pending = false
	assert(game._unique_fantasy_species_get_count() == 10)
	assert(game._unique_act2_species_get_count() == 22)
	assert(game._current_mission_text() == "最高記録を目指しながら、新しい品種を\n24種類見つけよう！　22/24")

	game.species_get_counts.clear()
	game.act3_intro_seen = true
	game.act3_unlocked = true
	game.story_progression_state["exploitation_started"] = true
	var jure_count := 0
	for entry_value in game.catalog_species:
		if entry_value is Dictionary and game._is_jurejure_species(entry_value) and jure_count < 5:
			game.species_get_counts[str(entry_value.get("species_id", ""))] = 1
			jure_count += 1
	assert(game._current_mission_text() == "ジュレジュレ団品種を8種類集めよう！　5/8")

	game.habitat_crisis_pending = false
	game.habitat_crisis_started = true
	game.story_progression_state["post_crisis_greenhouse_seen"] = true
	var restoration := HabitatRestorationClass.default_state()
	HabitatRestorationClass.start_large_plant_mission(restoration)
	game.story_progression_state["restoration"] = restoration
	assert(game._current_mission_text() == "100cm以上の多肉を5株、原生地へ還そう！　0/5")
	var snapshot := {
		"species_id": "colorata",
		"display_name": "コロラータ",
		"diameter_cm": 120.0,
		"visual_scale": 7.0,
		"rarity": "通常",
		"gold_star_count": 0,
	}
	assert(HabitatRestorationClass.queue_pending_return_snapshot(restoration, snapshot))
	assert(game._current_mission_text() == "100cm以上の多肉を5株、原生地へ還そう！　0/5")
	assert(HabitatRestorationClass.commit_next_pending_return(restoration) == 1)
	HabitatRestorationClass.complete_return_event(restoration, 1)
	HabitatRestorationClass.complete_join_habitat(restoration)
	assert(game._current_mission_text() == "100cm以上の多肉を5株、原生地へ還そう！　1/5")


func _test_progress_hud_boot_and_get_card_lifecycle(game: Node) -> void:
	_hide_foreground(game)
	game.language_selected = true
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.habitat_tutorial_complete = true
	game.mystery_items_acquired = true
	game.mystery_catalog_tutorial_complete = true
	game.normal_play_tutorial_complete = true
	game.total_play_count = 2
	game.current_mode = "greenhouse"
	game.play_active = false
	game.arrangement_scene_active = false
	game.arrangement_transitioning = false
	# Keep unrelated pending story work inert while exercising the title-close
	# refresh that a loaded save uses on a cold start.
	game.collection_complete_presentation_active = true

	var original_ids: Array[String] = []
	var fantasy_ids: Array[String] = []
	var jurejure_ids: Array[String] = []
	for entry_value in game.catalog_species:
		if not entry_value is Dictionary:
			continue
		if bool(entry_value.get("main_story_original", false)):
			original_ids.append(str(entry_value.get("species_id", "")))
		elif game._is_jurejure_species(entry_value):
			jurejure_ids.append(str(entry_value.get("species_id", "")))
		elif game._is_fantasy_species(entry_value):
			fantasy_ids.append(str(entry_value.get("species_id", "")))
	assert(original_ids.size() >= 8 and fantasy_ids.size() >= 5 and jurejure_ids.size() >= 3)

	# Loaded Act II save: the 24-species mission appears immediately after the
	# title closes, without requiring a greenhouse round.
	game.species_get_counts.clear()
	for index in range(8):game.species_get_counts[original_ids[index]] = 1
	for index in range(5):game.species_get_counts[fantasy_ids[index]] = 1
	game.story_progression_state = StoryProgressionClass.default_runtime_state()
	game.act2_unlocked = true
	game.act3_unlocked = false
	game.act3_intro_seen = false
	game.habitat_crisis_pending = false
	game.habitat_crisis_started = false
	for locale in Localizer.SUPPORTED_LANGUAGES:
		await _assert_loaded_mission_after_title_close(game, locale, Localizer.text(locale, "mission_fantasy_species", [13]))

	# Loaded exploitation save: the JureJure collection mission and its saved
	# count are present on the first greenhouse frame.
	game.species_get_counts.clear()
	for index in range(3):game.species_get_counts[jurejure_ids[index]] = 1
	game.story_progression_state = StoryProgressionClass.default_runtime_state()
	game.story_progression_state["exploitation_started"] = true
	game.act2_unlocked = true
	game.act3_unlocked = true
	game.act3_intro_seen = true
	game.habitat_crisis_pending = false
	game.habitat_crisis_started = false
	for locale in Localizer.SUPPORTED_LANGUAGES:
		await _assert_loaded_mission_after_title_close(game, locale, Localizer.text(locale, "mission_jurejure_species", [3]))

	# Loaded restoration save: both the mission text and the saved lamp count
	# are restored at title close in every language.
	game.species_get_counts.clear()
	game.story_progression_state = StoryProgressionClass.default_runtime_state()
	game.story_progression_state["exploitation_started"] = true
	game.story_progression_state["post_crisis_greenhouse_seen"] = true
	game.act3_unlocked = true
	game.act3_intro_seen = true
	game.habitat_crisis_pending = false
	game.habitat_crisis_started = true
	var restoration := _restoration_with_returned_count(2)
	game.story_progression_state["restoration"] = restoration
	for locale in Localizer.SUPPORTED_LANGUAGES:
		await _assert_loaded_mission_after_title_close(game, locale, Localizer.text(locale, "mission_return_large", [2]))
		assert(game.habitat_restoration_ui.lamp_panel.visible)
		_assert_lit_restoration_lamps(game, 2)

	# The progress widget preserves all saved values at 0/5, mid-progress, and
	# 5/5. Completion hides mission copy as before, but never mutates the lamps.
	game.language_code = "ja"
	for returned_count in [0, 2, 5]:
		restoration = _restoration_with_returned_count(returned_count)
		game.story_progression_state["restoration"] = restoration
		game._refresh_progress_hud()
		assert(game.habitat_restoration_ui.lamp_panel.visible)
		_assert_lit_restoration_lamps(game, returned_count)
		assert(game.mission_panel.visible == (returned_count < HabitatRestorationClass.REQUIRED_RETURNED_PLANTS))

	# A GET card must suppress the complete restoration panel, despite that
	# panel's higher z-index, then restore it after the final card closes.
	restoration = _restoration_with_returned_count(2)
	game.story_progression_state["restoration"] = restoration
	game._refresh_progress_hud()
	assert(game.mission_panel.visible and game.habitat_restoration_ui.lamp_panel.visible)
	game._queue_species_get(game._catalog_entry(original_ids[0]), true, "progress_hud_single", true)
	assert(game.species_get_overlay.visible)
	assert(not game.mission_panel.visible and not game.habitat_restoration_ui.lamp_panel.visible)
	await _close_species_get_for_progress_test(game)
	assert(game.mission_panel.visible and game.habitat_restoration_ui.lamp_panel.visible)
	_assert_lit_restoration_lamps(game, 2)

	# Consecutive cards keep the panel hidden across the inter-card render frame.
	game._queue_species_get(game._catalog_entry(original_ids[0]), true, "progress_hud_chain_1", true)
	game._queue_species_get(game._catalog_entry(original_ids[1]), true, "progress_hud_chain_2")
	assert(game.species_get_overlay.visible and not game.habitat_restoration_ui.lamp_panel.visible)
	game.species_get_overlay.busy = false
	game.species_get_overlay.close_overlay()
	var second_card_opened := false
	for _frame in range(180):
		await get_tree().process_frame
		if not game.species_get_overlay.visible:
			assert(not game.habitat_restoration_ui.lamp_panel.visible, "restoration panel flashed between consecutive GET cards")
		if game.species_get_overlay.visible and game.species_get_active_context == "progress_hud_chain_2":
			second_card_opened = true
			break
	assert(second_card_opened)
	assert(not game.mission_panel.visible and not game.habitat_restoration_ui.lamp_panel.visible)
	await _close_species_get_for_progress_test(game)
	assert(game.mission_panel.visible and game.habitat_restoration_ui.lamp_panel.visible)
	_assert_lit_restoration_lamps(game, 2)

	game.collection_complete_presentation_active = false
	game.language_code = "ja"
	game._apply_language_to_ui()


func _assert_loaded_mission_after_title_close(game: Node, locale: String, expected_text: String) -> void:
	game.language_code = locale
	game.opening_finished = false
	game.opening_overlay.visible = true
	game.opening_prompt_tween = null
	game._refresh_progress_hud()
	assert(not game.mission_panel.visible)
	game._finish_opening()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.opening_finished and not game.opening_overlay.visible)
	assert(game.mission_panel.visible, "loaded mission missing after title close locale=%s expected=%s" % [locale, expected_text])
	assert(game.mission_text_label.text == expected_text)


func _restoration_with_returned_count(count: int) -> Dictionary:
	var restoration := HabitatRestorationClass.default_state()
	restoration["started"] = true
	restoration["large_plant_mission_started"] = true
	var species_ids := ["colorata", "laui", "lutea", "shaviana", "affinis"]
	for index in range(count):
		assert(HabitatRestorationClass.add_returned_plant(restoration, {
			"species_id": species_ids[index],
			"display_name": species_ids[index],
			"diameter_cm": 100.0 + float(index) * 10.0,
			"visual_scale": 7.0,
			"rarity": "normal",
			"gold_star_count": 0,
		}) == index + 1)
	return restoration


func _assert_lit_restoration_lamps(game: Node, expected_count: int) -> void:
	for index in range(game.habitat_restoration_ui.lamp_labels.size()):
		assert(game.habitat_restoration_ui.lamp_labels[index].text == ("●" if index < expected_count else "○"))


func _close_species_get_for_progress_test(game: Node) -> void:
	game.species_get_overlay.busy = false
	game.species_get_overlay.close_overlay()
	for _frame in range(180):
		if not game.species_get_overlay.visible:
			break
		await get_tree().process_frame
	assert(not game.species_get_overlay.visible)
	await get_tree().process_frame
	await get_tree().process_frame


func _test_round_navigation_lock(game: Node) -> void:
	_hide_foreground(game)
	game.current_mode = "greenhouse"
	game.intro_story_complete = true
	game.habitat_awakened = true
	game.habitat_tutorial_complete = true
	game.seed_shop_open = true
	game.puku_gauge_intro_complete = true
	game.story_progression_state["arrangement_unlocked"] = true
	game.story_progression_state["arrangement_intro_seen"] = true
	game.arrangement_scene_active = false
	game.arrangement_transitioning = false
	game.catalog_preview_mode_active = false
	game.play_active = false
	game._update_play_ui()
	assert(game._greenhouse_area_navigation_available())
	var had_visible_navigation := false
	for control in game.external_navigation_controls:
		had_visible_navigation = had_visible_navigation or control.visible
	assert(had_visible_navigation)

	game.play_active = true
	game.active_seed_type = "normal"
	game._update_play_ui()
	for control in game.external_navigation_controls:
		assert(not control.visible)
	assert(not game.mode_button.visible)
	assert(not game.shop_button.visible)
	assert(not game.forest_gacha_button.visible)
	assert(not game.fusion_lab_button.visible)
	assert(not game._greenhouse_area_navigation_available())
	game._open_arrangements()
	assert(not game.arrangement_scene_active and not game.arrangement_transitioning)
	assert(not game.mission_panel.visible)
	game.play_active = false
	game._update_play_ui()
	assert(game._greenhouse_area_navigation_available())
	assert(game.TRIAL_DEV_CONTROLS_ENABLED and game._trial_dev_controls_enabled())
	assert(game._trial_dev_controls_enabled_for_context(false))


func _test_new_gate(game: Node) -> void:
	game.endless_greenhouse.reset_discovery_state()
	game.play_active = true
	game.active_seed_type = "normal"
	game.unlocked_series["base"] = true
	game.jurejure_intro_complete = false
	assert(game.endless_greenhouse.queue_forced_new())
	game._record_endless_discovery_settlement(true, 120.0, 0.0)
	assert(not game.endless_greenhouse.has_forced_new())
	game.jurejure_intro_complete = true
	game._record_endless_discovery_settlement(true, 120.0, 0.0)
	assert(not game.endless_greenhouse.forced_new_pending)
	assert(is_equal_approx(game.endless_greenhouse.carryover_chance_for_next_seed(), 0.95))
	assert(bool(game._roll_endless_carryover_for_seed(0.0).get("queued", false)))
	assert(game.endless_greenhouse.forced_new_pending)
	game.endless_greenhouse.reset_discovery_state()
	game.play_active = false


func _test_early_fantasy_candidate_contract(game: Node) -> void:
	game.species_get_counts.clear()
	game.story_progression_state["fantasy_unlocked"] = true
	game.act2_unlocked = true
	game.fantasy_realization_seen = false
	var required_entries: Dictionary = {}
	var extra_required: Array[Dictionary] = []
	var outside_entry: Dictionary = {}
	for entry_value in game.catalog_species:
		if not entry_value is Dictionary or not game._is_fantasy_species(entry_value) or game._is_jurejure_species(entry_value):
			continue
		var entry: Dictionary = entry_value
		var display_series: String = str(game._catalog_display_series_id_for_entry(entry))
		if display_series in game.EARLY_FANTASY_REQUIRED_SERIES:
			if not required_entries.has(display_series):
				required_entries[display_series] = entry
			else:
				extra_required.append(entry)
		elif outside_entry.is_empty():
			outside_entry = entry
	assert(required_entries.size() == 4 and extra_required.size() >= 2 and not outside_entry.is_empty())
	for required_series in game.EARLY_FANTASY_REQUIRED_SERIES:
		assert(game._early_fantasy_new_candidate_allowed(required_entries[required_series]))
	assert(not game._early_fantasy_new_candidate_allowed(outside_entry))
	for required_series in game.EARLY_FANTASY_REQUIRED_SERIES:
		var entry: Dictionary = required_entries[required_series]
		game.species_get_counts[str(entry.get("species_id", ""))] = 1
	assert(game._early_fantasy_required_series_complete())
	assert(game._unique_fantasy_species_get_count()==4)
	game.current_mode = "habitat"
	var page_keys := ["fantasy_six_girl_1", "fantasy_six_armadillo", "fantasy_six_girl_2", "fantasy_six_armadillo_2", "fantasy_six_armadillo_3", "fantasy_six_armadillo_4", "fantasy_six_armadillo_5"]
	var speakers := ["girl", "armadillo", "girl", "armadillo", "armadillo", "armadillo", "armadillo"]
	var expected_pages := {
		"ja": ["ゼリーに、ゆめふわ……私が好きなものばっかり。", "石に宝石……僕が集めてるものと同じだ。", "……もしかして、私たちが想像したものが、多肉になってる？", "そうかもしれない…", "もしかして、あの原生地には、ぼくたちの想像を多肉に変える力があるのかもしれないね。", "本当に不思議だ…", "それと、大きな株を収穫するほど、新しい品種が出るような気がするよ"],
		"hiragana": ["ぜりーに、ゆめふわ……わたしが すきなもの ばっかり。", "いしに ほうせき……ぼくが あつめてるものと おなじだ。", "……もしかして、わたしたちが そうぞうしたものが、たにくに なってる？", "そうかもしれない…", "もしかして、あの げんせいちには、ぼくたちの そうぞうを たにくに かえる ちからが あるのかもしれないね。", "ほんとうに ふしぎだ…", "それと、おおきな かぶを しゅうかくするほど、あたらしい ひんしゅが でるような きがするよ"],
		"en": ["Jelly and dreamy colors... They are all things I love.", "Stone and jewels... just like the things I collect.", "...Could the things we imagine be turning into succulents?", "Maybe you're right...", "Maybe that habitat has the power to turn what we imagine into succulents.", "It's really strange...", "And it feels like the bigger the plant you harvest, the more likely a new variety is to appear."],
	}
	for test_language in ["ja", "hiragana", "en"]:
		game._set_language(test_language)
		game._start_fantasy_realization_event()
		assert(game.scripted_dialog_kind == "fantasy_realization")
		assert(game.scripted_dialog_pages.size() == 7)
		for page_index in range(page_keys.size()):
			assert(str(game.scripted_dialog_pages[page_index].get("speaker", "")) == speakers[page_index])
			assert(str(game.scripted_dialog_pages[page_index].get("text", "")) == Localizer.text(test_language, page_keys[page_index]))
			assert(Localizer.text(test_language, page_keys[page_index]) == expected_pages[test_language][page_index])
			if page_index > 0:
				game._advance_scripted_dialog()
			await get_tree().process_frame
			assert(game.intro_dialogue_label.text == expected_pages[test_language][page_index])
			assert(game.intro_dialogue_label.get_visible_line_count() == game.intro_dialogue_label.get_line_count(), "fantasy realization text clipped locale=%s page=%d" % [test_language, page_index + 1])
		game.scripted_dialog_kind = ""
		game.scripted_dialog_pages.clear()
		game.scripted_dialog_index = -1
		game.intro_overlay.visible = false
	game._set_language("ja")
	game.fantasy_realization_seen = true
	assert(game._early_fantasy_new_candidate_allowed(outside_entry))


func _test_crisis_exploitation_lockout(game: Node) -> void:
	var state := StoryProgressionClass.default_runtime_state()
	state["exploitation_started"] = true
	state["act3_battle_intro_pending"] = true
	state["exploitation_midpoint_pending"] = true
	StoryProgressionClass.queue_story_event(state, StoryProgressionClass.EVENT_ACT3_BATTLE_INTRO)
	StoryProgressionClass.queue_story_event(state, StoryProgressionClass.EVENT_EXPLOITATION_MIDPOINT)
	StoryProgressionClass.queue_habitat_crisis_transition(state, false)
	assert(not bool(state.get("act3_battle_intro_pending", true)))
	assert(not bool(state.get("exploitation_midpoint_pending", true)))
	assert(StoryProgressionClass.EVENT_ACT3_BATTLE_INTRO not in state.get("pending_story_events", []))
	assert(StoryProgressionClass.EVENT_EXPLOITATION_MIDPOINT not in state.get("pending_story_events", []))

	game.story_progression_state = state
	game.current_mode = "habitat"
	game.jurejure_intro_complete = true
	game.habitat_crisis_pending = true
	game.habitat_crisis_started = false
	game.scripted_dialog_kind = ""
	game._start_jurejure_challenge_event()
	assert(game.scripted_dialog_kind.is_empty())
	game.habitat_crisis_pending = false
	game.habitat_crisis_started = true
	game._start_jurejure_challenge_event()
	assert(game.scripted_dialog_kind.is_empty())
	var restoration: Dictionary = game._restoration_state()
	HabitatRestorationClass.begin_tracking(restoration)
	assert(not StoryProgressionClass.record_normal_seed_sown_after_crisis(game.story_progression_state, true, 48))
	assert(not bool(restoration.get("jurejure_joined", false)))


func _test_round_completion_before_new_cards(game: Node) -> void:
	_hide_foreground(game)
	game.current_mode = "greenhouse"
	game.play_active = false
	game.active_seed_type = "normal"
	game.total_play_count = 2
	game.mystery_items_acquired = true
	game.play_harvest_count = 1
	game.play_max_size = 64.0
	game.play_harvest_cm_total = 64.0
	game.endless_economy_harvest_count = 1
	game.endless_economy_jelly_count = 11
	game.endless_economy_seed_cost_units = 1000
	game.endless_economy_harvest_reward_units = 650
	game.result_new_species_queue.clear()
	game.result_deferred_species_queue.clear()
	game.pending_round_new_species_ids.clear()
	game.pending_round_new_species_ids.append("lutea")
	game.pending_round_new_species_ids.append("shaviana")
	game.discovered.erase("lutea")
	game.discovered.erase("shaviana")
	game.species_get_counts.erase("lutea")
	game.species_get_counts.erase("shaviana")
	game.play_notable_species = {"lutea": {"name": "ルテア", "size": 64.0}}
	game.greenhouse_round_followup_started = false
	game._continue_after_greenhouse_round()
	assert(not game.result_overlay.visible and game.result_overlay.get_child_count() == 0)
	assert(not game.species_get_overlay.visible)
	assert(game._species_get_count("lutea") == 0 and not bool(game.discovered.get("lutea", false)))
	assert(game.pending_round_new_species_ids == ["lutea", "shaviana"])
	await get_tree().process_frame
	assert(game._species_get_count("lutea") == 1 and bool(game.discovered.get("lutea", false)))
	assert("lutea" not in game.pending_round_new_species_ids)
	assert(game.species_get_overlay.visible)
	assert(game.species_get_active_context == "round_result_new")
	game.species_get_overlay.busy = false
	game.species_get_overlay.close_overlay()
	while game.species_get_overlay.visible:
		await get_tree().process_frame
	await get_tree().process_frame
	assert(game._species_get_count("shaviana") == 1 and bool(game.discovered.get("shaviana", false)))
	assert("shaviana" not in game.pending_round_new_species_ids)
	assert(game.species_get_overlay.visible and game.species_get_active_context == "round_result_new")
	game.species_get_overlay.busy = false
	game.species_get_overlay.close_overlay()
	while game.species_get_overlay.visible:
		await get_tree().process_frame
	await get_tree().process_frame


func _test_fusion_fantasy_count(game: Node) -> void:
	game.species_get_counts.clear()
	var fantasy_fusions := ["hyb_gummy_sea", "fus1_rainbow_bubble", "fus2_planet_specimen"]
	for species_id in fantasy_fusions:
		var entry: Dictionary = game._catalog_entry(species_id)
		assert(not entry.is_empty() and game._is_fantasy_species(entry))
		game.species_get_counts[species_id] = 1
	var jure_fusion: Dictionary = game._catalog_entry("fus1_bonus_time")
	assert(not jure_fusion.is_empty())
	assert(game._catalog_display_series_id_for_entry(jure_fusion) == "jurejure")
	assert(not game._is_fantasy_species(jure_fusion))
	for entry_value in game.catalog_species:
		if entry_value is Dictionary and game._is_jurejure_species(entry_value):
			assert(not game._is_fantasy_species(entry_value))
			break
	assert(game._unique_fantasy_species_get_count() == fantasy_fusions.size())


func _test_story_copy() -> void:
	assert(Localizer.text("ja", "forest_gacha_intro_panda") == "僕が見つけた品種をガチャにしてみたんだ！良かったらやってみてよ！")
	assert("アルマジロ君" in Localizer.text("ja", "restoration_epilogue_mouse"))
	assert(Localizer.text("ja", "restoration_return_5_girl") == "これで5株目だよ。")
	assert(Localizer.text("ja", "mission_title") == "ミッション")
