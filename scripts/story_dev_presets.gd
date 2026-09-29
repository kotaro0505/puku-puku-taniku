class_name StoryDevPresets
extends RefCounted

const StoryProgressionClass = preload("res://scripts/story_progression.gd")
const HabitatRestorationClass = preload("res://scripts/habitat_restoration.gd")

const ACT3_READY := "act3_ready"
const CRISIS_READY := "crisis_ready"
const RESTORATION_ZERO := "restoration_zero"
const RESTORATION_FOUR := "restoration_four"
const ENDING_READY := "ending_ready"
const THANK_YOU_READY := "thank_you_ready"

const PRESET_IDS := [
	ACT3_READY,
	CRISIS_READY,
	RESTORATION_ZERO,
	RESTORATION_FOUR,
	ENDING_READY,
	THANK_YOU_READY,
]

const RETURNED_PLANT_IDS := ["colorata", "laui", "kannte", "affinis", "shaviana"]
const RETURNED_PLANT_SIZES := [104.0, 112.0, 121.0, 133.0, 146.0]


static func available(debug_enabled: bool) -> bool:
	return debug_enabled


static func options() -> Array[Dictionary]:
	return [
		{"id": ACT3_READY, "label": "第三幕直前"},
		{"id": CRISIS_READY, "label": "弱り直前（ジュレ団7種）"},
		{"id": RESTORATION_ZERO, "label": "回復開始 0/5"},
		{"id": RESTORATION_FOUR, "label": "回復 4/5"},
		{"id": ENDING_READY, "label": "エンディング直前"},
		{"id": THANK_YOU_READY, "label": "Thank you直前"},
	]


static func apply(game, preset_id: String) -> Dictionary:
	if not available(bool(game.habitat_debug_enabled)):
		return {"ok": false, "error": "development_only"}
	if preset_id not in PRESET_IDS:
		return {"ok": false, "error": "unknown_preset"}

	# Begin from the same clean payload used by the existing development reset.
	# All preset construction stays here so main.gd remains only the UI bridge.
	game._reset_progression_state()
	_prepare_common_progress(game)

	var target_mode := "greenhouse"
	var should_resume_story := true
	match preset_id:
		ACT3_READY:
			_prepare_act3_ready(game)
		CRISIS_READY:
			_prepare_crisis_ready(game)
			target_mode = "habitat"
		RESTORATION_ZERO:
			_prepare_restoration(game, 0)
		RESTORATION_FOUR:
			_prepare_restoration(game, 4)
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

	_prepare_runtime_view(game, target_mode)
	return {
		"ok": true,
		"preset_id": preset_id,
		"target_mode": target_mode,
		"resume_story": should_resume_story,
	}


static func spawn_101cm_colorata(game) -> bool:
	if not available(bool(game.habitat_debug_enabled)):
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
	game.play_puku_earned_total = 0
	game.play_harvest_count = 0
	game.play_max_size = 0.0
	game.play_previous_global_best = game._global_best_size()
	game.play_updated_global_best = false
	game.play_share_record.clear()
	game.play_notable_species.clear()
	game.result_new_species_queue.clear()
	game.result_deferred_species_queue.clear()
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
	game.puku_points = maxi(20, int(game.puku_points))
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
		"puku_puku_battle", "forest_gacha_ui", "secret_gacha_ui", "species_get_overlay",
		"habitat_plant_panel",
	]:
		var control = game.get(property_name)
		if control != null:
			control.visible = false
	if game.arrangement_ui != null:
		game.arrangement_ui.visible = false
	if game.habitat_restoration_ui != null:
		game.habitat_restoration_ui.reset_view()
