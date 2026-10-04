class_name StoryDevPresets
extends RefCounted

const StoryProgressionClass = preload("res://scripts/story_progression.gd")
const HabitatRestorationClass = preload("res://scripts/habitat_restoration.gd")

const POST_FIRST_NORMAL_TUTORIAL := "post_first_normal_tutorial"
const ACT3_READY := "act3_ready"
const EXPLOITATION_ACTIVE := "exploitation_active"
const CRISIS_READY := "crisis_ready"
const CRISIS_ACTIVE := "crisis_active"
const FIRST_RETURN_READY := "first_return_ready"
const RESTORATION_ZERO := "restoration_zero"
const RESTORATION_ONE := "restoration_one"
const RESTORATION_FOUR := "restoration_four"
const RESTORATION_FIVE_READY := "restoration_five_ready"
const ENDING_READY := "ending_ready"
const THANK_YOU_READY := "thank_you_ready"
const COMPLETE := "complete"

const PRESET_IDS := [
	POST_FIRST_NORMAL_TUTORIAL,
	ACT3_READY,
	EXPLOITATION_ACTIVE,
	CRISIS_READY,
	CRISIS_ACTIVE,
	FIRST_RETURN_READY,
	RESTORATION_ZERO,
	RESTORATION_ONE,
	RESTORATION_FOUR,
	RESTORATION_FIVE_READY,
	ENDING_READY,
	THANK_YOU_READY,
	COMPLETE,
]

const RETURNED_PLANT_IDS := ["colorata", "laui", "kannte", "affinis", "shaviana"]
const RETURNED_PLANT_SIZES := [104.0, 112.0, 121.0, 133.0, 146.0]


static func available(debug_enabled: bool) -> bool:
	return debug_enabled


static func _available_for_game(game) -> bool:
	if game.has_method("_trial_dev_controls_enabled"):
		return available(bool(game._trial_dev_controls_enabled()))
	# Never fall back to an unrelated runtime/debug flag. A caller without the
	# project's single master-gate method is not authorized to mutate progress.
	return false


static func options() -> Array[Dictionary]:
	return [
		{"id": POST_FIRST_NORMAL_TUTORIAL, "label": "12粒チュート後"},
		{"id": ACT3_READY, "label": "第三幕直前"},
		{"id": EXPLOITATION_ACTIVE, "label": "酷使中"},
		{"id": CRISIS_READY, "label": "弱り直前（ジュレ団7種）"},
		{"id": CRISIS_ACTIVE, "label": "弱り直後（大株 0/1）"},
		{"id": FIRST_RETURN_READY, "label": "1株目返還直前"},
		{"id": RESTORATION_ZERO, "label": "回復開始 0/5"},
		{"id": RESTORATION_ONE, "label": "ジュレ団加入直後 1/5"},
		{"id": RESTORATION_FOUR, "label": "回復 4/5"},
		{"id": RESTORATION_FIVE_READY, "label": "5株目返還直前"},
		{"id": ENDING_READY, "label": "エンディング直前"},
		{"id": THANK_YOU_READY, "label": "Thank you直前"},
		{"id": COMPLETE, "label": "クリア後"},
	]


static func apply(game, preset_id: String) -> Dictionary:
	if not _available_for_game(game):
		return {"ok": false, "error": "development_only"}
	if preset_id not in PRESET_IDS:
		return {"ok": false, "error": "unknown_preset"}

	# Begin from the same clean payload used by the existing development reset.
	# All preset construction stays here so main.gd remains only the UI bridge.
	game._reset_progression_state()
	if preset_id == POST_FIRST_NORMAL_TUTORIAL:
		_prepare_post_first_normal_tutorial(game)
	else:
		_prepare_common_progress(game)

	var target_mode := "greenhouse"
	var should_resume_story := true
	match preset_id:
		POST_FIRST_NORMAL_TUTORIAL:
			should_resume_story = false
		ACT3_READY:
			_prepare_act3_ready(game)
		EXPLOITATION_ACTIVE:
			_prepare_exploitation(game)
			target_mode = "habitat"
		CRISIS_READY:
			_prepare_crisis_ready(game)
			target_mode = "habitat"
		CRISIS_ACTIVE:
			_prepare_crisis_active(game)
		FIRST_RETURN_READY:
			_prepare_crisis_active(game)
			_queue_story_return(game, 0)
		RESTORATION_ZERO:
			_prepare_restoration(game, 0)
		RESTORATION_ONE:
			_prepare_restoration(game, 1)
		RESTORATION_FOUR:
			_prepare_restoration(game, 4)
		RESTORATION_FIVE_READY:
			_prepare_restoration(game, 4)
			_queue_story_return(game, 4)
		ENDING_READY:
			_prepare_restoration(game, 5)
			var ending_restoration: Dictionary = _restoration(game)
			HabitatRestorationClass.begin_recovery_slides(ending_restoration)
			game.story_progression_state["restoration"] = ending_restoration
			target_mode = "habitat"
		THANK_YOU_READY:
			_prepare_restoration(game, 5)
			var thank_you_restoration: Dictionary = _restoration(game)
			HabitatRestorationClass.begin_recovery_slides(thank_you_restoration)
			HabitatRestorationClass.reveal_full_recovery(thank_you_restoration)
			HabitatRestorationClass.mark_final_dialog_complete(thank_you_restoration)
			HabitatRestorationClass.mark_epilogue_complete(thank_you_restoration)
			game.story_progression_state["restoration"] = thank_you_restoration
			target_mode = "habitat"
		COMPLETE:
			_prepare_restoration(game, 5)
			var complete_restoration: Dictionary = _restoration(game)
			HabitatRestorationClass.complete_ending(complete_restoration)
			game.story_progression_state["restoration"] = complete_restoration
			game.finale_complete = true
			game.main_story_complete = true
			game.main_story_completion_seen = true
			target_mode = "greenhouse"
			should_resume_story = false

	_prepare_runtime_view(game, target_mode)
	return {
		"ok": true,
		"preset_id": preset_id,
		"target_mode": target_mode,
		"resume_story": should_resume_story,
	}


static func _prepare_post_first_normal_tutorial(game) -> void:
	# Match the playable state immediately after the first paid twelve-seed round:
	# the tutorial NEW is a real catalog GET, while the separate Act 2 original
	# guarantee has not even been queued, much less consumed.
	game.opening_finished = true
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.trio_originals_confirmed = true
	game.habitat_arrival_started = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_tutorial_started = true
	game.habitat_tutorial_complete = true
	game.habitat_tutorial_returned_to_greenhouse = true
	game.first_habitat_gift_claimed = true
	game.seed_shop_open = true
	game.mystery_items_acquired = true
	game.mystery_catalog_tutorial_complete = true
	game.original_catalog_gifted = true
	game.encyclopedia_unlocked = true
	game.habitat_unlocked = true
	game.puku_gauge_intro_complete = true
	game.normal_play_tutorial_complete = true
	game.initial_seed_stock_notice_complete = true
	game.puku_buyback_tutorial_complete = true
	game.puku_buyback_tutorial_active = false
	game.seed_pod_gauge_discovery_complete = false
	game.seed_pod_first_reward_seen = false
	game.total_play_count = 2
	game.formal_play_count = 1
	game.normal_play_count = 1
	game.normal_seed_bags = 0
	game.main_story_stage = StoryProgressionClass.ACT_1
	game.main_story_complete = false
	game.main_story_completion_seen = false
	game.act2_unlocked = false
	game.jurejure_intro_complete = false
	game.jurejure_enabled = false
	game.jurejure_battle_count = 0
	game.jurejure_battle_win_count = 0
	game.jurejure_return_event_complete = false
	game.jurejure_waiting_for_seed_pod_reward = false
	game.active_jurejure_event.clear()
	game.story_progression_state = StoryProgressionClass.default_runtime_state()
	game.unlocked_series["base"] = true
	_grant_species(game, "colorata")
	game._remember_catalog_cover_species("colorata")
	for catalog_only_id in ["affinis", "shaviana"]:
		game.discovered[catalog_only_id] = true
		game.greenhouse_available.erase(catalog_only_id)
		game.unlocked_species.erase(catalog_only_id)
		game.species_get_counts.erase(catalog_only_id)
	var tutorial_species_id := "lutea"
	var tutorial_entry: Dictionary = game._catalog_entry(tutorial_species_id)
	if tutorial_entry.is_empty() or str(tutorial_entry.get("rarity", "")) != "通常":
		var candidates: Array[Dictionary] = game._first_play_tutorial_original_candidates()
		if not candidates.is_empty():
			tutorial_species_id = str(candidates[0].get("species_id", ""))
	_grant_species(game, tutorial_species_id)
	game.tutorial_steps["first_play_growth_dialogs"] = true
	game.tutorial_steps["first_harvest_guide"] = true
	game.tutorial_steps["first_normal_tutorial_species_id"] = tutorial_species_id
	game.first_play_has_harvested = true
	game.puku_balance_units = maxi(4200, int(game.puku_balance_units))


static func spawn_101cm_colorata(game) -> bool:
	if not _available_for_game(game):
		return false
	_prepare_runtime_view(game, "greenhouse")
	game.active_seed_type = "normal"
	game.current_target_count = 1
	game.play_active = true
	game.play_seeds_remaining = 0
	game.play_spawn_queue = 0
	game.play_seed_animations_pending = 0
	game.play_spawn_timer = 0.0
	game.play_concurrent_target = 1
	game.play_harvest_cm_total = 0.0
	game.play_puku_reward_units_total = 0
	game.play_harvest_count = 0
	game.play_max_size = 0.0
	game.play_previous_global_best = game._global_best_size()
	game.play_updated_global_best = false
	game.play_share_record.clear()
	game.play_notable_species.clear()
	game.result_new_species_queue.clear()
	game.result_deferred_species_queue.clear()
	game.pending_round_new_species_ids.clear()
	game.round_result_species_finalize_queue.clear()
	game.round_result_species_finalize_active = false
	game._spawn_specific_plant("colorata")
	if game.plants.is_empty():
		return false
	var plant = game.plants.back()
	plant.fast_forward_to_diameter(101.0)
	plant.jelly_checks_enabled = false
	plant.set_meta("story_dev_101", true)
	return true


static func _prepare_common_progress(game) -> void:
	game.opening_finished = true
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.trio_originals_confirmed = true
	game.habitat_arrival_started = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_tutorial_started = true
	game.habitat_tutorial_complete = true
	game.habitat_tutorial_returned_to_greenhouse = true
	game.seed_shop_open = true
	game.mystery_items_acquired = true
	game.mystery_catalog_tutorial_complete = true
	game.normal_play_tutorial_complete = true
	game.seed_pod_gauge_discovery_complete = true
	game.seed_pod_first_reward_seen = true
	game.initial_seed_stock_notice_complete = true
	game.puku_buyback_tutorial_complete = true
	game.puku_buyback_tutorial_active = false
	game.original_catalog_gifted = true
	game.original_catalog_complete_event_seen = true
	game.puku_gauge_intro_complete = true
	game.encyclopedia_unlocked = true
	game.habitat_unlocked = true
	game.habitat_second_awakened = true
	game.habitat_second_awakening_complete = true
	game.first_habitat_gift_claimed = true
	game.total_play_count = maxi(12, int(game.total_play_count))
	game.formal_play_count = maxi(10, int(game.formal_play_count))
	game.normal_play_count = maxi(10, int(game.normal_play_count))
	game.normal_seed_bags = maxi(5, int(game.normal_seed_bags))
	var preset_puku_units:int = 20 * int(game.PUKU_UNITS_PER_PUKU)
	if int(game.puku_balance_units) < preset_puku_units:
		game._change_puku_balance(preset_puku_units - int(game.puku_balance_units), "story_dev_preset", false, false)
	game.unlocked_series["base"] = true

	game.act2_unlocked = true
	game.jurejure_intro_complete = true
	game.jurejure_enabled = true
	game.jurejure_return_event_complete = true
	game.jurejure_waiting_for_seed_pod_reward = false
	game.jurejure_battle_count = 1
	game.jurejure_battle_win_count = 1
	game.jurejure_pending_reward_species_id = ""
	game.jurejure_last_battle_result.clear()
	game.active_jurejure_event.clear()
	game.fantasy_first_discovery_seen = true
	game.fantasy_realization_seen = true
	game.forest_gacha_unlocked = true
	game.forest_gacha_intro_seen = true

	var progression := StoryProgressionClass.default_runtime_state()
	progression["original_new_guarantee_pending"] = false
	progression["original_new_guarantee_consumed"] = true
	progression["fantasy_unlocked"] = true
	progression["fantasy_new_guarantee_pending"] = false
	progression["fantasy_new_guarantee_consumed"] = true
	progression["post_encounter_greenhouse_pending"] = false
	progression["post_encounter_greenhouse_seen"] = true
	progression["arrangement_unlocked"] = true
	progression["arrangement_intro_pending"] = false
	progression["arrangement_intro_seen"] = true
	progression["forest_gacha_unlock_pending"] = false
	progression["pending_story_events"] = []
	game.story_progression_state = progression

	for species_id in ["colorata", "affinis", "shaviana", "laui", "kannte"]:
		_grant_species(game, species_id)
	_grant_non_jurejure_fantasy(game, 24)
	for species_id in ["colorata", "affinis", "shaviana"]:
		game.habitat_returned_species[species_id] = true


static func _prepare_act3_ready(game) -> void:
	game.act3_unlocked = false
	game.act3_intro_pending = false
	game.act3_intro_seen = false
	game.habitat_crisis_pending = false
	game.habitat_crisis_started = false
	game.act3_intro_eligible_visit_id = int(game.habitat_visit_id)
	game._refresh_narrative_species_progress()


static func _prepare_crisis_ready(game) -> void:
	_prepare_exploitation(game)
	_grant_jurejure_species(game, 7)
	game.jurejure_battle_count = 7
	game.jurejure_battle_win_count = 7
	game.jurejure_species_first_seen = true
	game.habitat_crisis_pending = false
	game.habitat_crisis_started = false
	game.habitat_crisis_eligible_visit_id = int(game.habitat_visit_id)
	game.story_progression_state["last_crisis_concern_visit"] = int(game.habitat_visit_id)


static func _prepare_exploitation(game) -> void:
	game.act3_unlocked = true
	game.act3_intro_pending = false
	game.act3_intro_seen = true
	var progression: Dictionary = game.story_progression_state
	StoryProgressionClass.begin_exploitation(progression, 0)
	StoryProgressionClass.complete_act3_battle_intro(progression)
	progression["exploitation_midpoint_pending"] = false
	progression["exploitation_midpoint_seen"] = true
	StoryProgressionClass.consume_story_event(
		progression, StoryProgressionClass.EVENT_EXPLOITATION_MIDPOINT
	)
	game.story_progression_state = progression
	game.jurejure_pool_unlocked = true
	game.unlocked_series["jurejure"] = true
	for entry_value in game.catalog_species:
		if entry_value is Dictionary and str(entry_value.get("story_group", "")).to_lower() == "jurejure":
			game.jurejure_species_unlocked[str(entry_value.get("species_id", ""))] = true


static func _prepare_crisis_active(game) -> void:
	_prepare_exploitation(game)
	_grant_jurejure_species(game, 8)
	game.jurejure_battle_count = 8
	game.jurejure_battle_win_count = 8
	game.jurejure_species_first_seen = true
	game.habitat_crisis_pending = false
	game.habitat_crisis_started = true
	var progression: Dictionary = game.story_progression_state
	StoryProgressionClass.begin_habitat_crisis(progression)
	progression["post_crisis_greenhouse_pending"] = false
	progression["post_crisis_greenhouse_seen"] = true
	var restoration: Dictionary = StoryProgressionClass.restoration_state(progression)
	HabitatRestorationClass.start_large_plant_mission(restoration)
	progression["restoration"] = restoration
	game.story_progression_state = progression


static func _queue_story_return(game, index: int) -> void:
	var restoration: Dictionary = _restoration(game)
	var safe_index := clampi(index, 0, RETURNED_PLANT_IDS.size() - 1)
	var species_id: String = RETURNED_PLANT_IDS[safe_index]
	var entry: Dictionary = game._catalog_entry(species_id)
	HabitatRestorationClass.queue_pending_return_snapshot(restoration, {
		"species_id": species_id,
		"display_name": str(entry.get("name_ja", species_id)),
		"diameter_cm": RETURNED_PLANT_SIZES[safe_index],
		"visual_scale": 0.18 + (RETURNED_PLANT_SIZES[safe_index] - 1.6) * 0.058,
		"rarity": str(entry.get("rarity", "")),
		"gold_star_count": int(entry.get("gold_star_count", 0)),
	})
	game.story_progression_state["restoration"] = restoration


static func _prepare_restoration(game, returned_count: int) -> void:
	_prepare_exploitation(game)
	_grant_jurejure_species(game, 8)
	game.jurejure_battle_count = 8
	game.jurejure_battle_win_count = 8
	game.jurejure_species_first_seen = true
	game.habitat_crisis_pending = false
	game.habitat_crisis_started = true
	var progression: Dictionary = game.story_progression_state
	StoryProgressionClass.begin_habitat_crisis(progression)
	progression["post_crisis_greenhouse_pending"] = false
	progression["post_crisis_greenhouse_seen"] = true
	for species_id in ["colorata", "affinis", "shaviana"]:
		StoryProgressionClass.record_restoration_new_get(progression, species_id, true)
	StoryProgressionClass.complete_restoration_join_home(progression)
	StoryProgressionClass.complete_restoration_join_habitat(progression)
	var restoration: Dictionary = StoryProgressionClass.restoration_state(progression)
	for index in range(clampi(returned_count, 0, HabitatRestorationClass.REQUIRED_RETURNED_PLANTS)):
		var species_id: String = RETURNED_PLANT_IDS[index]
		var entry: Dictionary = game._catalog_entry(species_id)
		var diameter: float = RETURNED_PLANT_SIZES[index]
		var stage := HabitatRestorationClass.add_returned_plant(restoration, {
			"species_id": species_id,
			"display_name": str(entry.get("name_ja", species_id)),
			"diameter_cm": diameter,
			"visual_scale": 0.18 + (diameter - 1.6) * 0.058,
			"rarity": str(entry.get("rarity", "")),
			"gold_star_count": int(entry.get("gold_star_count", 0)),
		})
		HabitatRestorationClass.complete_return_event(restoration, stage)
	progression["restoration"] = restoration
	game.story_progression_state = progression
	game.finale_complete = false


static func _grant_non_jurejure_fantasy(game, count: int) -> void:
	var granted := 0
	for entry_value in game.catalog_species:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		if str(entry.get("story_group", "")).to_lower() == "jurejure":
			continue
		if not bool(game._is_fantasy_species(entry)):
			continue
		_grant_species(game, str(entry.get("species_id", "")))
		granted += 1
		if granted >= count:
			return


static func _grant_jurejure_species(game, count: int) -> void:
	var granted := 0
	for entry_value in game.catalog_species:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		if str(entry.get("story_group", "")).to_lower() != "jurejure":
			continue
		_grant_species(game, str(entry.get("species_id", "")))
		granted += 1
		if granted >= count:
			return


static func _grant_species(game, species_id: String) -> void:
	var entry: Dictionary = game._catalog_entry(species_id)
	if entry.is_empty():
		return
	game.species_get_counts[species_id] = maxi(1, int(game.species_get_counts.get(species_id, 0)))
	game.discovered[species_id] = true
	game.greenhouse_available[species_id] = true
	game.unlocked_species[species_id] = true
	var series_id := str(entry.get("series_id", ""))
	if not series_id.is_empty():
		game.unlocked_series[series_id] = true
	if str(entry.get("story_group", "")).to_lower() != "jurejure":
		game.habitat_returned_species[species_id] = true


static func _restoration(game) -> Dictionary:
	return StoryProgressionClass.restoration_state(game.story_progression_state)


static func _prepare_runtime_view(game, target_mode: String) -> void:
	game._end_first_play_tutorial_context()
	game.current_mode = target_mode
	game.play_active = false
	game.play_modal_open = false
	game.play_seeds_remaining = 0
	game.play_spawn_queue = 0
	game.play_seed_animations_pending = 0
	game.pending_restoration_snapshot.clear()
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.scripted_dialog_index = -1
	game.jurejure_first_encounter_active = false
	game.jurejure_intro_camera_active = false
	game.habitat_lookaround_active = false
	game.arrangement_scene_active = false
	game.arrangement_transitioning = false
	game._clear_greenhouse_plants()
	for property_name in [
		"opening_overlay", "opening_story_overlay", "intro_overlay", "result_overlay",
		"play_overlay", "shop_overlay", "encyclopedia_overlay", "settings_overlay",
		"tutorial_guide_overlay", "jelly_dev_overlay", "jurejure_first_encounter_overlay",
		"puku_puku_battle", "forest_gacha_ui", "secret_gacha_ui", "species_get_overlay", "catalog_series_unlock_overlay",
		"habitat_plant_panel",
	]:
		var control = game.get(property_name)
		if control != null:
			control.visible = false
	if game.arrangement_ui != null:
		game.arrangement_ui.visible = false
	if game.habitat_restoration_ui != null:
		game.habitat_restoration_ui.reset_view()
