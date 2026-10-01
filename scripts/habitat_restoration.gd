class_name HabitatRestoration
extends RefCounted

const Localizer = preload("res://scripts/game_localizer.gd")

# Durable state for the post-crisis final chapter.  It is stored as one nested
# payload in StoryProgression rather than spreading one-off flags through
# main.gd.
const STATE_VERSION := 3
const REQUIRED_NEW_SPECIES := 3
const REQUIRED_SEEDS_SOWN_AFTER_CRISIS := 48
const REQUIRED_RETURNED_PLANTS := 5
const MIN_RETURN_DIAMETER_CM := 100.0
const JUREJURE_PHASE_CRISIS := "crisis"
const JUREJURE_PHASE_RESTORATION := "restoration"
const JUREJURE_PHASE_POST_ENDING := "post_ending"


static func dialog_pages(language_code: String, kind: String, stage := 0) -> Array[Dictionary]:
	var specs: Array = []
	match kind:
		"post_crisis_greenhouse":
			specs = [
				["panda", "post_crisis_greenhouse_panda_1"],
				["armadillo", "post_crisis_greenhouse_armadillo"],
				["girl", "post_crisis_greenhouse_girl"],
				["armadillo", "post_crisis_greenhouse_armadillo_2"],
				["panda", "post_crisis_greenhouse_panda_2"],
				["girl", "post_crisis_greenhouse_girl_2"],
				["panda", "post_crisis_greenhouse_panda_3"],
			]
		"join_home":
			specs = [
				["armadillo", "restoration_join_home_armadillo"],
				["panda", "restoration_join_home_panda"],
				["girl", "restoration_join_home_girl"],
			]
		"join_habitat":
			specs = [
				["mouse", "restoration_join_mouse_1"],
				["peccary", "restoration_join_peccary_1"],
				["skunk", "restoration_join_skunk_1"],
				["panda", "restoration_join_panda_1"],
				["armadillo", "restoration_join_armadillo_call"],
				["mouse", "restoration_join_mouse_2"],
				["armadillo", "restoration_join_armadillo_plan"],
				["girl", "restoration_join_girl_request"],
				["mouse", "restoration_join_mouse_question"],
				["armadillo", "restoration_join_armadillo_answer"],
				["peccary", "restoration_join_peccary_question"],
				["panda", "restoration_join_panda_maybe"],
				["skunk", "restoration_join_skunk_question"],
				["panda", "restoration_join_panda_no"],
				["mouse", "restoration_join_mouse_silence"],
				["mouse", "restoration_join_mouse_decide"],
				["peccary", "restoration_join_peccary_carry"],
				["skunk", "restoration_join_skunk_best"],
				["mouse", "restoration_join_mouse_hurry"],
			]
		"return":
			var stage_specs := {
				1: [["armadillo", "restoration_return_1_armadillo"], ["panda", "restoration_return_1_panda"], ["mouse", "restoration_return_1_mouse"], ["peccary", "restoration_return_1_peccary"], ["skunk", "restoration_return_1_skunk"]],
				2: [["girl", "restoration_return_2_girl"], ["armadillo", "restoration_return_2_armadillo"], ["mouse", "restoration_return_2_mouse"], ["peccary", "restoration_return_2_peccary"], ["skunk", "restoration_return_2_skunk"]],
				3: [["girl", "restoration_return_3_girl_1"], ["panda", "restoration_return_3_panda"], ["armadillo", "restoration_return_3_armadillo"], ["girl", "restoration_return_3_girl_2"], ["mouse", "restoration_return_3_mouse"], ["peccary", "restoration_return_3_peccary"], ["skunk", "restoration_return_3_skunk"]],
				4: [["girl", "restoration_return_4_girl"], ["armadillo", "restoration_return_4_armadillo"], ["girl", "restoration_return_4_girl_2"], ["mouse", "restoration_return_4_mouse"], ["peccary", "restoration_return_4_peccary"], ["skunk", "restoration_return_4_skunk"], ["panda", "restoration_return_4_panda"]],
				5: [["", "restoration_return_5_system"], ["girl", "restoration_return_5_girl"]],
			}
			specs = stage_specs.get(stage, [])
		"final":
			specs = [
				["girl", "restoration_final_girl_1"],
				["armadillo", "restoration_final_armadillo"],
				["panda", "restoration_final_panda"],
				["girl", "restoration_final_girl_2"],
			]
		"epilogue":
			specs = [
				["mouse", "restoration_epilogue_mouse"],
				["armadillo", "restoration_epilogue_armadillo"],
				["peccary", "restoration_epilogue_peccary"],
				["skunk", "restoration_epilogue_skunk"],
				["panda", "restoration_epilogue_panda"],
				["girl", "restoration_epilogue_girl"],
			]
	var pages: Array[Dictionary] = []
	for spec in specs:
		pages.append({
			"speaker": str(spec[0]),
			"text": Localizer.text(language_code, str(spec[1])),
		})
	return pages


static func default_state() -> Dictionary:
	return {
		"version": STATE_VERSION,
		"tracking_started": false,
		"new_species_ids": [],
		"seeds_sown_since_crisis": 0,
		"join_home_pending": false,
		"join_home_seen": false,
		"join_habitat_pending": false,
		"jurejure_joined": false,
		"started": false,
		"returned_plants": [],
		"return_event_pending_stage": 0,
		"return_event_pending_stages": [],
		"full_recovery_revealed": false,
		"ending_phase": "",
		"ending_seen": false,
		"thank_you_seen": false,
		"last_post_ending_dialog_index": -1,
	}


static func normalize_state(raw_state: Variant, migration: Dictionary = {}) -> Dictionary:
	var state := default_state()
	if raw_state is Dictionary:
		for key in state:
			if raw_state.has(key):
				state[key] = raw_state[key]
	state["version"] = STATE_VERSION

	var new_species: Array[String] = []
	var raw_species: Variant = state.get("new_species_ids", [])
	if raw_species is Array:
		for value in raw_species:
			var species_id := str(value)
			if not species_id.is_empty() and species_id not in new_species:
				new_species.append(species_id)
	state["new_species_ids"] = new_species
	state["seeds_sown_since_crisis"] = maxi(
		0, int(state.get("seeds_sown_since_crisis", 0))
	)

	var returned: Array[Dictionary] = []
	var raw_returned: Variant = state.get("returned_plants", [])
	if raw_returned is Array:
		for value in raw_returned:
			if not value is Dictionary or returned.size() >= REQUIRED_RETURNED_PLANTS:
				continue
			var species_id := str(value.get("species_id", ""))
			var diameter_cm := float(value.get("diameter_cm", 0.0))
			if species_id.is_empty() or diameter_cm < MIN_RETURN_DIAMETER_CM:
				continue
			returned.append({
				"species_id": species_id,
				"display_name": str(value.get("display_name", species_id)),
				"diameter_cm": diameter_cm,
				"visual_scale": maxf(0.01, float(value.get("visual_scale", 1.0))),
				"rarity": str(value.get("rarity", "")),
				"gold_star_count": clampi(int(value.get("gold_star_count", 0)), 0, 2),
				"slot": returned.size(),
			})
	state["returned_plants"] = returned
	# v1 could keep only the latest stage. v2 keeps every stage reached during a
	# single greenhouse play so the rooted-plant scenes can run in order after
	# the normal result card closes.
	var pending_stages: Array[int] = []
	var raw_pending_stages: Variant = state.get("return_event_pending_stages", [])
	if raw_pending_stages is Array:
		for value in raw_pending_stages:
			var pending_stage := int(value)
			if pending_stage >= 1 and pending_stage <= returned.size() and pending_stage not in pending_stages:
				pending_stages.append(pending_stage)
	var legacy_pending_stage := clampi(
		int(state.get("return_event_pending_stage", 0)), 0, returned.size()
	)
	if pending_stages.is_empty() and legacy_pending_stage > 0:
		pending_stages.append(legacy_pending_stage)
	pending_stages.sort()
	state["return_event_pending_stages"] = pending_stages
	state["return_event_pending_stage"] = pending_stages[0] if not pending_stages.is_empty() else 0
	state["last_post_ending_dialog_index"] = int(state.get("last_post_ending_dialog_index", -1))
	var ending_phase := str(state.get("ending_phase", ""))
	if ending_phase not in ["", "slides", "final", "epilogue", "thank_you", "complete"]:
		ending_phase = ""
	if returned.size() < REQUIRED_RETURNED_PLANTS:
		ending_phase = ""
	state["ending_phase"] = ending_phase

	# Saves made before this counter existed begin tracking future normal
	# greenhouse sowings once the already-persisted crisis state is active.
	# Historical sowings cannot be dated reliably, so they are not inferred.
	if bool(migration.get("habitat_crisis_started", false)):
		state["tracking_started"] = true
	if not returned.is_empty():
		state["tracking_started"] = true
		state["join_home_seen"] = true
		state["join_habitat_pending"] = false
		state["jurejure_joined"] = true
		state["started"] = true
	if returned.size() >= REQUIRED_RETURNED_PLANTS and bool(state.get("ending_seen", false)):
		state["full_recovery_revealed"] = true
	if bool(state.get("thank_you_seen", false)):
		state["ending_seen"] = true
		state["full_recovery_revealed"] = true
		state["ending_phase"] = "complete"
	state["join_home_pending"] = bool(state.get("join_home_pending", false)) \
		and not bool(state.get("join_home_seen", false))
	return state


static func begin_tracking(state: Dictionary) -> void:
	state["tracking_started"] = true


static func record_new_species(state: Dictionary, species_id: String) -> bool:
	if not bool(state.get("tracking_started", false)) \
			or bool(state.get("jurejure_joined", false)) \
			or species_id.is_empty():
		return false
	var ids: Array = state.get("new_species_ids", [])
	if species_id not in ids:
		ids.append(species_id)
	state["new_species_ids"] = ids
	return false


static func new_species_count(state: Dictionary) -> int:
	return mini(REQUIRED_NEW_SPECIES, (state.get("new_species_ids", []) as Array).size())


static func record_normal_seed_sown_after_crisis(state: Dictionary, amount := 1) -> bool:
	if amount <= 0 \
			or not bool(state.get("tracking_started", false)) \
			or bool(state.get("join_home_pending", false)) \
			or bool(state.get("join_home_seen", false)) \
			or bool(state.get("jurejure_joined", false)):
		return false
	var previous := maxi(0, int(state.get("seeds_sown_since_crisis", 0)))
	var current := previous + amount
	state["seeds_sown_since_crisis"] = current
	if previous < REQUIRED_SEEDS_SOWN_AFTER_CRISIS \
			and current >= REQUIRED_SEEDS_SOWN_AFTER_CRISIS \
			and not bool(state.get("join_home_pending", false)):
		state["join_home_pending"] = true
		return true
	return false


static func seeds_sown_since_crisis(state: Dictionary) -> int:
	return maxi(0, int(state.get("seeds_sown_since_crisis", 0)))


static func can_queue_join_home(state: Dictionary, post_crisis_greenhouse_seen: bool) -> bool:
	return post_crisis_greenhouse_seen \
		and bool(state.get("join_home_pending", false)) \
		and not bool(state.get("join_home_seen", false))


static func complete_join_home(state: Dictionary) -> void:
	state["join_home_pending"] = false
	state["join_home_seen"] = true
	state["join_habitat_pending"] = true


static func complete_join_habitat(state: Dictionary) -> void:
	state["join_habitat_pending"] = false
	state["jurejure_joined"] = true
	state["started"] = true


static func is_started(state: Dictionary) -> bool:
	return bool(state.get("started", false))


static func returned_plants(state: Dictionary) -> Array:
	var value: Variant = state.get("returned_plants", [])
	return value if value is Array else []


static func returned_count(state: Dictionary) -> int:
	return returned_plants(state).size()


static func can_offer_return(state: Dictionary, diameter_cm: float) -> bool:
	return is_started(state) \
		and returned_count(state) < REQUIRED_RETURNED_PLANTS \
		and diameter_cm >= MIN_RETURN_DIAMETER_CM


static func add_returned_plant(state: Dictionary, snapshot: Dictionary) -> int:
	if not can_offer_return(state, float(snapshot.get("diameter_cm", 0.0))):
		return 0
	var species_id := str(snapshot.get("species_id", ""))
	if species_id.is_empty():
		return 0
	var returned: Array = returned_plants(state)
	var stored := {
		"species_id": species_id,
		"display_name": str(snapshot.get("display_name", species_id)),
		"diameter_cm": float(snapshot.get("diameter_cm", MIN_RETURN_DIAMETER_CM)),
		"visual_scale": maxf(0.01, float(snapshot.get("visual_scale", 1.0))),
		"rarity": str(snapshot.get("rarity", "")),
		"gold_star_count": clampi(int(snapshot.get("gold_star_count", 0)), 0, 2),
		"slot": returned.size(),
	}
	returned.append(stored)
	state["returned_plants"] = returned
	var stage := returned.size()
	var pending_stages: Array = state.get("return_event_pending_stages", [])
	if stage not in pending_stages:
		pending_stages.append(stage)
	state["return_event_pending_stages"] = pending_stages
	state["return_event_pending_stage"] = int(pending_stages[0])
	return returned.size()


static func pending_return_stage(state: Dictionary) -> int:
	var pending_stages: Variant = state.get("return_event_pending_stages", [])
	if pending_stages is Array and not pending_stages.is_empty():
		return clampi(int(pending_stages[0]), 0, returned_count(state))
	return clampi(int(state.get("return_event_pending_stage", 0)), 0, returned_count(state))


static func pending_return_stages(state: Dictionary) -> Array[int]:
	var result: Array[int] = []
	var value: Variant = state.get("return_event_pending_stages", [])
	if value is Array:
		for raw_stage in value:
			var stage := clampi(int(raw_stage), 0, returned_count(state))
			if stage > 0 and stage not in result:
				result.append(stage)
	if result.is_empty():
		var legacy_stage := clampi(int(state.get("return_event_pending_stage", 0)), 0, returned_count(state))
		if legacy_stage > 0:
			result.append(legacy_stage)
	return result


static func complete_return_event(state: Dictionary, stage: int) -> void:
	var pending_stages := pending_return_stages(state)
	if not pending_stages.is_empty() and pending_stages[0] == stage:
		pending_stages.remove_at(0)
	else:
		pending_stages.erase(stage)
	state["return_event_pending_stages"] = pending_stages
	state["return_event_pending_stage"] = pending_stages[0] if not pending_stages.is_empty() else 0


static func begin_recovery_slides(state: Dictionary) -> void:
	if returned_count(state) < REQUIRED_RETURNED_PLANTS:
		return
	state["return_event_pending_stage"] = 0
	state["return_event_pending_stages"] = []
	state["ending_phase"] = "slides"


static func ending_phase(state: Dictionary) -> String:
	return str(state.get("ending_phase", ""))


static func reveal_full_recovery(state: Dictionary) -> void:
	if returned_count(state) >= REQUIRED_RETURNED_PLANTS:
		state["full_recovery_revealed"] = true
		state["ending_phase"] = "final"


static func mark_final_dialog_complete(state: Dictionary) -> void:
	if bool(state.get("full_recovery_revealed", false)):
		state["ending_phase"] = "epilogue"


static func mark_epilogue_complete(state: Dictionary) -> void:
	if bool(state.get("full_recovery_revealed", false)):
		state["ending_phase"] = "thank_you"


static func restoration_stage(state: Dictionary) -> int:
	var count := returned_count(state)
	if count >= REQUIRED_RETURNED_PLANTS and not bool(state.get("full_recovery_revealed", false)):
		return REQUIRED_RETURNED_PLANTS - 1
	return clampi(count, 0, REQUIRED_RETURNED_PLANTS)


static func is_complete(state: Dictionary) -> bool:
	return bool(state.get("full_recovery_revealed", false))


static func should_show_progress(state: Dictionary) -> bool:
	return is_started(state) \
		and not bool(state.get("ending_seen", false)) \
		and not bool(state.get("thank_you_seen", false)) \
		and ending_phase(state) != "complete"


static func jurejure_interaction_phase(state: Dictionary) -> String:
	var phase := ending_phase(state)
	if bool(state.get("ending_seen", false)) or phase in ["thank_you", "complete"]:
		return JUREJURE_PHASE_POST_ENDING
	if bool(state.get("jurejure_joined", false)) and is_started(state):
		return JUREJURE_PHASE_RESTORATION
	return JUREJURE_PHASE_CRISIS


static func last_post_ending_dialog_index(state: Dictionary) -> int:
	return int(state.get("last_post_ending_dialog_index", -1))


static func set_last_post_ending_dialog_index(state: Dictionary, index: int) -> void:
	state["last_post_ending_dialog_index"] = index


static func complete_ending(state: Dictionary) -> void:
	state["full_recovery_revealed"] = true
	state["ending_seen"] = true
	state["thank_you_seen"] = true
	state["ending_phase"] = "complete"
