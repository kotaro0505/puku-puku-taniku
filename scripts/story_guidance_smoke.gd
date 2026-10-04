extends Node

const StoryProgressionClass = preload("res://scripts/story_progression.gd")
const HabitatRestorationClass = preload("res://scripts/habitat_restoration.gd")
const Localizer = preload("res://scripts/game_localizer.gd")

const FORMER_BASE_SPECIALS := [
	"golden_laui",
	"golden_kannte",
	"transparent_succulent",
	"glow_colorata",
	"metal_laui",
	"seaglass_veria",
	"amber_agavoides",
	"yumefuwa_jelly",
	"peach_jelly_succulent",
]


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game._reset_progression_state()
	_hide_foreground(game)
	_test_base_catalog_contract(game)
	_test_mission_copy_and_progress(game)
	_test_round_navigation_lock(game)
	_test_new_gate(game)
	_test_fantasy_six_candidate_contract(game)
	_test_fusion_fantasy_count(game)
	_test_crisis_exploitation_lockout(game)
	await _test_result_before_new_card(game)
	_test_story_copy()
	game._reset_progression_state()
	game.queue_free()
	await get_tree().process_frame
	print("STORY_GUIDANCE_SMOKE_OK mission=single+live new_gate=first_encounter result_order=result_then_formal_get result_spoiler=none pending_duplicate=false nav=hidden arrangement=locked base=originals_only fantasy_six=four_series fusion_fantasy_count=display_series crisis=exploit_locked copy=updated dev_controls=all_builds")
	get_tree().quit()


func _hide_foreground(game: Node) -> void:
	for control_name in [
		"opening_overlay", "opening_story_overlay", "habitat_awakening_overlay",
		"seed_pod_story_overlay", "habitat_second_awakening_overlay",
		"jurejure_first_encounter_overlay", "intro_overlay", "tutorial_guide_overlay",
		"result_overlay", "play_overlay", "species_get_overlay",
		"catalog_series_unlock_overlay", "forest_gacha_ui", "secret_gacha_ui",
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
	for species_id in FORMER_BASE_SPECIALS:
		assert(species_id not in base_ids)
		assert(not game._catalog_entry(species_id).is_empty())
	assert("現代で生まれた" not in str(base_entry.get("description", "")))


func _test_mission_copy_and_progress(game: Node) -> void:
	game.language_code = "ja"
	game.species_get_counts.clear()
	game.act2_unlocked = true
	game.story_progression_state["fantasy_unlocked"] = true
	var fantasy_ids: Array[String] = []
	for entry_value in game.catalog_species:
		if entry_value is Dictionary and game._is_fantasy_species(entry_value) and not game._is_jurejure_species(entry_value):
			fantasy_ids.append(str(entry_value.get("species_id", "")))
	for index in range(17):
		game.species_get_counts[fantasy_ids[index]] = 1
	assert(game._current_mission_text() == "新しい品種を24種類見つけよう！　17/24")
	game._update_mission_ui()
	assert(game.mission_panel.visible)
	assert(game.mission_title_label.text == "ミッション")

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
	assert(game._current_mission_text() == "100cm以上の多肉を1株育てよう！　0/1")
	var snapshot := {
		"species_id": "colorata",
		"display_name": "コロラータ",
		"diameter_cm": 120.0,
		"visual_scale": 7.0,
		"rarity": "通常",
		"gold_star_count": 0,
	}
	assert(HabitatRestorationClass.queue_pending_return_snapshot(restoration, snapshot))
	assert(game._current_mission_text() == "100cm以上の多肉を1株育てよう！　1/1")
	assert(HabitatRestorationClass.commit_next_pending_return(restoration) == 1)
	HabitatRestorationClass.complete_return_event(restoration, 1)
	HabitatRestorationClass.complete_join_habitat(restoration)
	assert(game._current_mission_text() == "100cm以上の多肉を5株、原生地へ還そう！　1/5")


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
	assert(game.mission_panel.visible)
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
	assert(game.endless_greenhouse.forced_new_pending)
	game.endless_greenhouse.reset_discovery_state()
	game.play_active = false


func _test_fantasy_six_candidate_contract(game: Node) -> void:
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
		if display_series in game.FANTASY_SIX_REQUIRED_SERIES:
			if not required_entries.has(display_series):
				required_entries[display_series] = entry
			else:
				extra_required.append(entry)
		elif outside_entry.is_empty():
			outside_entry = entry
	assert(required_entries.size() == 4 and extra_required.size() >= 2 and not outside_entry.is_empty())
	for required_series in game.FANTASY_SIX_REQUIRED_SERIES:
		assert(game._fantasy_six_new_candidate_allowed(required_entries[required_series]))
	assert(not game._fantasy_six_new_candidate_allowed(outside_entry))
	for required_series in game.FANTASY_SIX_REQUIRED_SERIES:
		var entry: Dictionary = required_entries[required_series]
		game.species_get_counts[str(entry.get("species_id", ""))] = 1
	assert(game._fantasy_six_required_series_complete())
	game.species_get_counts[str(extra_required[0].get("species_id", ""))] = 1
	game.species_get_counts[str(extra_required[1].get("species_id", ""))] = 1
	game.current_mode = "habitat"
	game._start_fantasy_realization_event()
	assert(game.scripted_dialog_kind == "fantasy_realization")
	assert(game.scripted_dialog_pages.size() == 3)
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.intro_overlay.visible = false
	game.fantasy_realization_seen = true
	assert(game._fantasy_six_new_candidate_allowed(outside_entry))


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


func _test_result_before_new_card(game: Node) -> void:
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
	game.discovered.erase("lutea")
	game.species_get_counts.erase("lutea")
	game.play_notable_species = {"lutea": {"name": "ルテア", "size": 64.0}}
	game._show_play_result()
	assert(game.result_overlay.visible)
	assert(not game.species_get_overlay.visible)
	assert(not game.result_new_species_label.visible and game.result_new_species_label.text.is_empty())
	assert("ルテア" not in game.result_notable_label.text)
	assert(game._species_get_count("lutea") == 0 and not bool(game.discovered.get("lutea", false)))
	assert(game.pending_round_new_species_ids == ["lutea"])
	game._close_result()
	assert(not game.result_overlay.visible and not game.species_get_overlay.visible)
	await get_tree().create_timer(.62).timeout
	assert(game._species_get_count("lutea") == 1 and bool(game.discovered.get("lutea", false)))
	assert("lutea" not in game.pending_round_new_species_ids)
	assert(game.species_get_overlay.visible)
	assert(game.species_get_active_context == "round_result_new")
	game.species_get_overlay.visible = false
	game._on_species_get_overlay_closed("round_result_new")
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
