class_name StoryProgression
extends RefCounted

const HabitatRestorationClass = preload("res://scripts/habitat_restoration.gd")

# Older saves may still contain an integer `main_story_stage`. Keep only its
# numeric bounds for tolerant deserialization; it is never consulted to decide
# current progression.
const LEGACY_STAGE_MIN := 0
const LEGACY_STAGE_MAX := 10

# v24+ story progression is expressed only by independent act flags.
const ACT_1 := 1
const ACT_2 := 2
const ACT_3 := 3
const ACT_FINALE := 4

# New Act II/III gates live in one versioned payload instead of adding another
# row of unrelated booleans to main.gd.  The root scene only forwards gameplay
# milestones and persists this dictionary.
const RUNTIME_STATE_VERSION := 9
# Lifetime ending counters are optional scalar fields normalized to zero below,
# so they do not require replaying the story-phase migrations for existing v7 saves.
const EVENT_POST_ENCOUNTER_HOME := "post_jurejure_encounter_home"
const EVENT_POST_CRISIS_GREENHOUSE := "post_crisis_greenhouse"
const EVENT_FANTASY_FIRST := "fantasy_first_discovery"
const EVENT_ARRANGEMENT_INTRO := "arrangement_intro"
const EVENT_FANTASY_SIX := "fantasy_realization"
const EVENT_FOREST_GACHA_INTRO := "forest_gacha_intro"
const EVENT_FUSION_LAB_INTRO := "fusion_lab_intro"
const EVENT_ACT3_BATTLE_INTRO := "act3_exploitation_battle_intro"
const EVENT_EXPLOITATION_MIDPOINT := "exploitation_midpoint"
# Tombstone only. This ID is accepted as evidence from old saves, but is never
# queued or returned by current runtime progression.
const RETIRED_EVENT_SECRET_GACHA_INSTALL := "secret_gacha_install"
const EVENT_RESTORATION_JOIN_HOME := "restoration_join_home"
const CRISIS_ROUTE_NONE := ""
const CRISIS_ROUTE_SAME_HABITAT := "same_habitat"
const CRISIS_ROUTE_FORCE_TRAVEL := "force_travel"
const RUNTIME_EVENT_IDS := [
	EVENT_POST_ENCOUNTER_HOME,
	EVENT_POST_CRISIS_GREENHOUSE,
	EVENT_FANTASY_FIRST,
	EVENT_ARRANGEMENT_INTRO,
	EVENT_FANTASY_SIX,
	EVENT_FOREST_GACHA_INTRO,
	EVENT_FUSION_LAB_INTRO,
	EVENT_ACT3_BATTLE_INTRO,
	EVENT_EXPLOITATION_MIDPOINT,
	EVENT_RESTORATION_JOIN_HOME,
]

const ARRANGEMENT_UNLOCK_FANTASY_COUNT := 3
const FOREST_GACHA_UNLOCK_FANTASY_COUNT := 8
const FUSION_LAB_UNLOCK_FANTASY_COUNT := 12
const EARLY_FANTASY_REQUIRED_SERIES_COUNT := 4
# Completed normal 12-seed games before the guaranteed opportunity for the
# next required series. Index 0 is the existing first-fantasy guarantee; the
# remaining entries place the next opportunities in games 3, 5, and 6.
const EARLY_FANTASY_GUARANTEE_COMPLETED_GAME_THRESHOLDS := [0, 2, 4, 5]

static func act_stage(act2_unlocked:bool,act3_unlocked:bool,finale_complete:bool)->int:
	if finale_complete:return ACT_FINALE
	if act3_unlocked:return ACT_3
	if act2_unlocked:return ACT_2
	return ACT_1


static func default_runtime_state() -> Dictionary:
	return {
		"version": RUNTIME_STATE_VERSION,
		"original_new_guarantee_pending": false,
		"original_new_guarantee_consumed": false,
		"fantasy_unlocked": false,
		"fantasy_new_guarantee_pending": false,
		"fantasy_new_guarantee_consumed": false,
		"early_fantasy_tracking_started": false,
		"early_fantasy_completed_games": 0,
		"early_fantasy_guarantee_pending": false,
		"early_fantasy_active_species_id": "",
		"early_fantasy_active_series_id": "",
		"early_fantasy_reserved_species_id": "",
		"early_fantasy_reserved_series_id": "",
		"post_encounter_greenhouse_pending": false,
		"post_encounter_greenhouse_seen": false,
		"post_crisis_greenhouse_pending": false,
		"post_crisis_greenhouse_seen": false,
		"arrangement_unlocked": false,
		"arrangement_intro_pending": false,
		"arrangement_intro_seen": false,
		"forest_gacha_unlock_pending": false,
		"fusion_lab_unlocked": false,
		"fusion_lab_intro_pending": false,
		"fusion_lab_intro_seen": false,
		"exploitation_started": false,
		"act3_battle_intro_pending": false,
		"act3_battle_intro_seen": false,
		"act3_first_battle_pending": false,
		"act3_first_battle_completed": false,
		"exploitation_midpoint_pending": false,
		"exploitation_midpoint_seen": false,
		"pending_story_events": [],
		"last_exploitation_dialog_index": -1,
		"last_crisis_concern_visit": -1,
		"last_exploitation_concern_phase": "",
		"last_exploitation_concern_index": -1,
		"habitat_crisis_route": CRISIS_ROUTE_NONE,
		"lifetime_harvest_count": 0,
		"lifetime_harvest_cm_total": 0.0,
		"restoration": HabitatRestorationClass.default_state(),
	}


static func normalize_runtime_state(raw_state: Variant, migration: Dictionary = {}) -> Dictionary:
	var state := default_runtime_state()
	var saved_runtime_version := 0
	var raw_dictionary: Dictionary = raw_state if raw_state is Dictionary else {}
	var had_first_battle_state := raw_dictionary.has("act3_first_battle_pending") \
			or raw_dictionary.has("act3_first_battle_completed")
	var had_fusion_lab_state := raw_dictionary.has("fusion_lab_unlocked") \
			or raw_dictionary.has("fusion_lab_intro_pending") \
			or raw_dictionary.has("fusion_lab_intro_seen")
	var had_early_fantasy_state := raw_dictionary.has("early_fantasy_tracking_started") \
			or raw_dictionary.has("early_fantasy_guarantee_pending") \
			or raw_dictionary.has("early_fantasy_active_species_id")
	var fantasy_get_count := maxi(0, int(migration.get("fantasy_get_count", 0)))
	var forest_gacha_evidence := bool(migration.get("forest_gacha_evidence", false))
	var forest_gacha_intro_seen := bool(migration.get("forest_gacha_intro_seen", false))
	var retired_secret_evidence := bool(migration.get("secret_gacha_evidence", false)) \
			or bool(raw_dictionary.get("secret_gacha_unlocked", false)) \
			or bool(raw_dictionary.get("secret_gacha_install_seen", false))
	var raw_pending_events: Variant = raw_dictionary.get("pending_story_events", [])
	if raw_pending_events is Array and RETIRED_EVENT_SECRET_GACHA_INSTALL in raw_pending_events:
		retired_secret_evidence = true
	if raw_state is Dictionary:
		saved_runtime_version = int(raw_state.get("version", 0))
		for key in state:
			if raw_state.has(key):
				state[key] = raw_state[key]
	var events: Array[String] = []
	var raw_events: Variant = state.get("pending_story_events", [])
	if raw_events is Array:
		for event_value in raw_events:
			var event_id := str(event_value)
			if event_id in RUNTIME_EVENT_IDS and event_id not in events:
				events.append(event_id)
	state["pending_story_events"] = events
	state["version"] = RUNTIME_STATE_VERSION
	state["last_exploitation_dialog_index"] = int(state.get("last_exploitation_dialog_index", -1))
	state["last_crisis_concern_visit"] = int(state.get("last_crisis_concern_visit", -1))
	state["last_exploitation_concern_phase"] = str(state.get("last_exploitation_concern_phase", ""))
	state["last_exploitation_concern_index"] = int(state.get("last_exploitation_concern_index", -1))
	state["lifetime_harvest_count"] = maxi(0, int(state.get("lifetime_harvest_count", 0)))
	state["lifetime_harvest_cm_total"] = maxf(0.0, float(state.get("lifetime_harvest_cm_total", 0.0)))
	state["early_fantasy_completed_games"] = maxi(0, int(state.get("early_fantasy_completed_games", 0)))
	state["early_fantasy_active_species_id"] = str(state.get("early_fantasy_active_species_id", ""))
	state["early_fantasy_active_series_id"] = str(state.get("early_fantasy_active_series_id", ""))
	state["early_fantasy_reserved_species_id"] = str(state.get("early_fantasy_reserved_species_id", ""))
	state["early_fantasy_reserved_series_id"] = str(state.get("early_fantasy_reserved_series_id", ""))
	# Plant nodes are not serialized. An in-flight guaranteed fantasy therefore
	# returns to the one-slot pending reservation after a restart.
	if not str(state.get("early_fantasy_active_species_id", "")).is_empty():
		state["early_fantasy_guarantee_pending"] = true
		state["early_fantasy_reserved_species_id"] = str(state.get("early_fantasy_active_species_id", ""))
		state["early_fantasy_reserved_series_id"] = str(state.get("early_fantasy_active_series_id", ""))
	state["early_fantasy_active_species_id"] = ""
	state["early_fantasy_active_series_id"] = ""
	if not bool(state.get("early_fantasy_guarantee_pending", false)):
		state["early_fantasy_reserved_species_id"] = ""
		state["early_fantasy_reserved_series_id"] = ""
	var crisis_route := str(state.get("habitat_crisis_route", CRISIS_ROUTE_NONE))
	if crisis_route not in [CRISIS_ROUTE_NONE, CRISIS_ROUTE_SAME_HABITAT, CRISIS_ROUTE_FORCE_TRAVEL]:
		crisis_route = CRISIS_ROUTE_NONE
	if bool(migration.get("habitat_crisis_started", false)):
		crisis_route = CRISIS_ROUTE_NONE
	elif crisis_route.is_empty() and bool(migration.get("habitat_crisis_pending", false)):
		# The outer save never persisted the active screen. Loading resumes in the
		# greenhouse, so a legacy pending crisis uses the new guided travel route.
		crisis_route = CRISIS_ROUTE_FORCE_TRAVEL
	state["habitat_crisis_route"] = crisis_route
	state["restoration"] = HabitatRestorationClass.normalize_state(
		state.get("restoration", {}),
		{"habitat_crisis_started": bool(migration.get("habitat_crisis_started", false))}
	)
	var normalized_restoration: Dictionary = state.get("restoration", {})
	if bool(state.get("post_crisis_greenhouse_seen", false)):
		HabitatRestorationClass.start_large_plant_mission(normalized_restoration)
	if not bool(normalized_restoration.get("join_home_pending", false)):
		state["pending_story_events"].erase(EVENT_RESTORATION_JOIN_HOME)
	state["restoration"] = normalized_restoration

	# Saves made before this payload existed must not lose already available
	# content.  New games never enter this branch and follow the new gates.
	if bool(migration.get("legacy", false)):
		if bool(migration.get("act2_unlocked", false)) or int(migration.get("fantasy_get_count", 0)) > 0:
			state["fantasy_unlocked"] = true
			state["original_new_guarantee_pending"] = false
			state["original_new_guarantee_consumed"] = true
			state["fantasy_new_guarantee_pending"] = false
			state["fantasy_new_guarantee_consumed"] = true
	var phase_migration_needed := saved_runtime_version < RUNTIME_STATE_VERSION or bool(migration.get("legacy", false))
	if phase_migration_needed:
		# The old inline warning already played in the habitat. Do not replay its
		# corrected greenhouse placement for an existing save.
		if bool(migration.get("jurejure_intro_complete", false)):
			state["post_encounter_greenhouse_pending"] = false
			state["post_encounter_greenhouse_seen"] = true
			state["pending_story_events"].erase(EVENT_POST_ENCOUNTER_HOME)
		var old_crisis_started := bool(migration.get("habitat_crisis_started", false))
		var old_act3_intro_seen := bool(migration.get("act3_intro_seen", false))
		var old_jurejure_count := maxi(0, int(migration.get("jurejure_get_count", 0)))
		var old_fantasy_count := fantasy_get_count
		var old_arrangement_evidence := bool(migration.get("arrangement_evidence", false))
		var old_forest_gacha_evidence := forest_gacha_evidence
		if old_fantasy_count >= 1 or old_arrangement_evidence:
			# Arrangement play existed before this state was introduced. Do not
			# take it away or replay the new gift tutorial for established saves.
			state["arrangement_unlocked"] = true
			state["arrangement_intro_pending"] = false
			state["arrangement_intro_seen"] = true
			state["pending_story_events"].erase(EVENT_ARRANGEMENT_INTRO)
		if old_forest_gacha_evidence:
			state["forest_gacha_unlock_pending"] = false
		if old_act3_intro_seen or old_crisis_started or retired_secret_evidence:
			state["exploitation_started"] = true
			# The dedicated camera/battle introduction is new in v3. Existing
			# Act III saves have already crossed this story beat.
			state["act3_battle_intro_pending"] = false
			state["act3_battle_intro_seen"] = true
			state["pending_story_events"].erase(EVENT_ACT3_BATTLE_INTRO)
		if old_crisis_started or retired_secret_evidence:
			state["exploitation_midpoint_pending"] = false
			state["exploitation_midpoint_seen"] = true
			state["pending_story_events"].erase(EVENT_EXPLOITATION_MIDPOINT)
		elif bool(state.get("exploitation_started", false)) and old_jurejure_count >= 4:
			state["exploitation_midpoint_pending"] = true
			queue_story_event(state, EVENT_EXPLOITATION_MIDPOINT)
	# The post-crisis greenhouse scene did not exist before v4.  Established
	# crisis saves have already returned to normal play, so never surprise them
	# with a newly inserted historical conversation on load.
	if saved_runtime_version < 4 and bool(migration.get("habitat_crisis_started", false)):
		state["post_crisis_greenhouse_pending"] = false
		state["post_crisis_greenhouse_seen"] = true
		state["pending_story_events"].erase(EVENT_POST_CRISIS_GREENHOUSE)
	# A v1 runtime payload can be loaded independently of the outer save version
	# in tests and tools. Infer the phase from its own durable evidence as a
	# final guard.
	if retired_secret_evidence:
		state["exploitation_started"] = true
		state["act3_battle_intro_pending"] = false
		state["act3_battle_intro_seen"] = true
		state["pending_story_events"].erase(EVENT_ACT3_BATTLE_INTRO)
		state["exploitation_midpoint_pending"] = false
		state["exploitation_midpoint_seen"] = true
		state["pending_story_events"].erase(EVENT_EXPLOITATION_MIDPOINT)
	if bool(state.get("post_encounter_greenhouse_seen", false)):
		state["post_encounter_greenhouse_pending"] = false
		state["pending_story_events"].erase(EVENT_POST_ENCOUNTER_HOME)
	elif bool(state.get("post_encounter_greenhouse_pending", false)):
		queue_story_event(state, EVENT_POST_ENCOUNTER_HOME)
	if bool(state.get("post_crisis_greenhouse_seen", false)):
		state["post_crisis_greenhouse_pending"] = false
		state["pending_story_events"].erase(EVENT_POST_CRISIS_GREENHOUSE)
	if bool(state.get("arrangement_intro_seen", false)):
		state["arrangement_unlocked"] = true
		state["arrangement_intro_pending"] = false
		state["pending_story_events"].erase(EVENT_ARRANGEMENT_INTRO)
	elif bool(state.get("arrangement_unlocked", false)):
		# Never take an already available feature away from an established save.
		state["arrangement_intro_pending"] = false
		state["pending_story_events"].erase(EVENT_ARRANGEMENT_INTRO)
	elif fantasy_get_count >= ARRANGEMENT_UNLOCK_FANTASY_COUNT:
		state["arrangement_intro_pending"] = true
		queue_story_event(state, EVENT_ARRANGEMENT_INTRO)
	else:
		# v28 could queue this at the first fantasy GET. The new three-GET rule
		# applies until the unlock dialogue has actually completed.
		state["arrangement_intro_pending"] = false
		state["pending_story_events"].erase(EVENT_ARRANGEMENT_INTRO)
	if forest_gacha_intro_seen:
		state["forest_gacha_unlock_pending"] = false
		state["pending_story_events"].erase(EVENT_FOREST_GACHA_INTRO)
	elif forest_gacha_evidence:
		# Existing access is authoritative even below the new eight-GET gate.
		state["forest_gacha_unlock_pending"] = false
		queue_story_event(state, EVENT_FOREST_GACHA_INTRO)
	elif fantasy_get_count >= FOREST_GACHA_UNLOCK_FANTASY_COUNT:
		state["forest_gacha_unlock_pending"] = true
		queue_story_event(state, EVENT_FOREST_GACHA_INTRO)
	else:
		# A pre-change six-GET pending flag was not an unlocked feature yet.
		state["forest_gacha_unlock_pending"] = false
		state["pending_story_events"].erase(EVENT_FOREST_GACHA_INTRO)
	var fusion_lab_unlocked := bool(state.get("fusion_lab_unlocked", false))
	if not had_fusion_lab_state and bool(migration.get("fusion_lab_legacy_access", false)):
		fusion_lab_unlocked = true
	state["fusion_lab_unlocked"] = fusion_lab_unlocked
	if bool(state.get("fusion_lab_intro_seen", false)):
		state["fusion_lab_unlocked"] = true
		state["fusion_lab_intro_pending"] = false
		state["pending_story_events"].erase(EVENT_FUSION_LAB_INTRO)
	elif fantasy_get_count >= FUSION_LAB_UNLOCK_FANTASY_COUNT \
			or bool(state.get("fusion_lab_intro_pending", false)):
		state["fusion_lab_intro_pending"] = true
		queue_story_event(state, EVENT_FUSION_LAB_INTRO)
	else:
		state["fusion_lab_intro_pending"] = false
		state["pending_story_events"].erase(EVENT_FUSION_LAB_INTRO)
	if bool(state.get("act3_battle_intro_seen", false)):
		state["act3_battle_intro_pending"] = false
		state["pending_story_events"].erase(EVENT_ACT3_BATTLE_INTRO)
	elif bool(state.get("act3_battle_intro_pending", false)):
		queue_story_event(state, EVENT_ACT3_BATTLE_INTRO)
	# The linked first battle adds optional durable booleans without replaying the
	# broader phase migrations. A save without these fields but with a JureJure
	# GET (or later crisis evidence) has already earned that battle's
	# reward and must never receive it twice. If its introduction was seen but no
	# reward exists, resume the mandatory battle instead of silently losing it.
	var first_exploitation_battle_completed := bool(state.get("act3_first_battle_completed", false))
	if not had_first_battle_state and bool(state.get("act3_battle_intro_seen", false)):
		first_exploitation_battle_completed = int(migration.get("jurejure_get_count", 0)) > 0 \
				or bool(migration.get("habitat_crisis_pending", false)) \
				or bool(migration.get("habitat_crisis_started", false)) \
				or retired_secret_evidence
	state["act3_first_battle_completed"] = first_exploitation_battle_completed
	state["act3_first_battle_pending"] = not first_exploitation_battle_completed \
			and bool(state.get("exploitation_started", false)) \
			and bool(state.get("act3_battle_intro_seen", false))
	if bool(state.get("exploitation_midpoint_seen", false)):
		state["exploitation_midpoint_pending"] = false
		state["pending_story_events"].erase(EVENT_EXPLOITATION_MIDPOINT)
	elif bool(state.get("exploitation_midpoint_pending", false)):
		queue_story_event(state, EVENT_EXPLOITATION_MIDPOINT)
	if bool(migration.get("habitat_crisis_pending", false)) \
			or bool(migration.get("habitat_crisis_started", false)):
		cancel_exploitation_events_for_crisis(state)
	var restoration: Dictionary = state.get("restoration", {})
	if HabitatRestorationClass.can_queue_join_home(
			restoration, bool(state.get("post_crisis_greenhouse_seen", false))):
		queue_story_event(state, EVENT_RESTORATION_JOIN_HOME)
	if migration.has("fantasy_required_series_complete"):
		var required_complete := bool(migration.get("fantasy_required_series_complete", false))
		var realization_seen := bool(migration.get("fantasy_realization_seen", false))
		var required_series_count := clampi(
			int(migration.get("fantasy_required_series_get_count", 0)),
			0,
			EARLY_FANTASY_REQUIRED_SERIES_COUNT
		)
		if realization_seen:
			consume_story_event(state, EVENT_FANTASY_SIX)
			finish_early_fantasy_guarantees(state)
		elif required_complete:
			queue_story_event(state, EVENT_FANTASY_SIX)
			cancel_early_fantasy_guarantee(state)
		elif bool(state.get("fantasy_unlocked", false)):
			begin_early_fantasy_tracking(state)
			# Saves from before this state existed have no reliable unlock-relative
			# round counter. Give their next missing series its already-earned
			# opportunity immediately instead of making an established player wait.
			if not had_early_fantasy_state:
				var deadline_index := mini(
					required_series_count,
					EARLY_FANTASY_GUARANTEE_COMPLETED_GAME_THRESHOLDS.size() - 1
				)
				state["early_fantasy_completed_games"] = maxi(
					int(state.get("early_fantasy_completed_games", 0)),
					int(EARLY_FANTASY_GUARANTEE_COMPLETED_GAME_THRESHOLDS[deadline_index])
				)
			state["pending_story_events"].erase(EVENT_FANTASY_SIX)
	return state


static func record_greenhouse_harvest(state: Dictionary, diameter_cm: float) -> void:
	if diameter_cm <= 0.0:
		return
	state["lifetime_harvest_count"] = lifetime_harvest_count(state) + 1
	state["lifetime_harvest_cm_total"] = lifetime_harvest_cm_total(state) + diameter_cm


static func lifetime_harvest_count(state: Dictionary) -> int:
	return maxi(0, int(state.get("lifetime_harvest_count", 0)))


static func lifetime_harvest_cm_total(state: Dictionary) -> float:
	return maxf(0.0, float(state.get("lifetime_harvest_cm_total", 0.0)))


static func begin_act_two(state: Dictionary) -> void:
	if bool(state.get("original_new_guarantee_consumed", false)):
		return
	state["original_new_guarantee_pending"] = true


static func take_normal_play_guarantee(
		state: Dictionary,
		original_candidates: Array[Dictionary],
		fantasy_candidates: Array[Dictionary],
		draw_rng: RandomNumberGenerator
	) -> Dictionary:
	if bool(state.get("original_new_guarantee_pending", false)):
		state["original_new_guarantee_pending"] = false
		state["original_new_guarantee_consumed"] = true
		if not original_candidates.is_empty():
			return original_candidates[draw_rng.randi_range(0, original_candidates.size() - 1)]
		return {}
	if bool(state.get("fantasy_new_guarantee_pending", false)):
		state["fantasy_new_guarantee_pending"] = false
		state["fantasy_new_guarantee_consumed"] = true
		if not fantasy_candidates.is_empty():
			return fantasy_candidates[draw_rng.randi_range(0, fantasy_candidates.size() - 1)]
	return {}


static func begin_early_fantasy_tracking(state: Dictionary) -> void:
	if not bool(state.get("fantasy_unlocked", false)):
		return
	if bool(state.get("early_fantasy_tracking_started", false)):
		return
	state["early_fantasy_tracking_started"] = true
	state["early_fantasy_completed_games"] = 0


static func record_early_fantasy_game_completed(state: Dictionary) -> bool:
	if not bool(state.get("fantasy_unlocked", false)) \
			or not bool(state.get("early_fantasy_tracking_started", false)):
		return false
	state["early_fantasy_completed_games"] = maxi(
		0, int(state.get("early_fantasy_completed_games", 0))
	) + 1
	return true


static func early_fantasy_guarantee_due(state: Dictionary, required_series_get_count: int) -> bool:
	var collected := clampi(required_series_get_count, 0, EARLY_FANTASY_REQUIRED_SERIES_COUNT)
	if not bool(state.get("fantasy_unlocked", false)) \
			or not bool(state.get("early_fantasy_tracking_started", false)) \
			or collected >= EARLY_FANTASY_REQUIRED_SERIES_COUNT \
			or has_early_fantasy_guarantee(state):
		return false
	var completed_games := maxi(0, int(state.get("early_fantasy_completed_games", 0)))
	return completed_games >= int(EARLY_FANTASY_GUARANTEE_COMPLETED_GAME_THRESHOLDS[collected])


static func has_early_fantasy_guarantee(state: Dictionary) -> bool:
	return bool(state.get("early_fantasy_guarantee_pending", false)) \
			or not str(state.get("early_fantasy_active_species_id", "")).is_empty()


static func early_fantasy_guarantee_is_pending(state: Dictionary) -> bool:
	return bool(state.get("early_fantasy_guarantee_pending", false))


static func queue_early_fantasy_guarantee(
		state: Dictionary, species_id := "", series_id := ""
	) -> bool:
	if not bool(state.get("fantasy_unlocked", false)) or has_early_fantasy_guarantee(state):
		return false
	state["early_fantasy_guarantee_pending"] = true
	state["early_fantasy_reserved_species_id"] = species_id
	state["early_fantasy_reserved_series_id"] = series_id
	return true


static func early_fantasy_candidate_hint(state: Dictionary) -> Dictionary:
	if not early_fantasy_guarantee_is_pending(state):
		return {}
	return {
		"species_id": str(state.get("early_fantasy_reserved_species_id", "")),
		"series_id": str(state.get("early_fantasy_reserved_series_id", "")),
	}


static func consume_early_fantasy_guarantee(
		state: Dictionary, species_id: String, series_id: String
	) -> bool:
	if not early_fantasy_guarantee_is_pending(state) or species_id.is_empty() or series_id.is_empty():
		return false
	state["early_fantasy_guarantee_pending"] = false
	state["early_fantasy_reserved_species_id"] = ""
	state["early_fantasy_reserved_series_id"] = ""
	state["early_fantasy_active_species_id"] = species_id
	state["early_fantasy_active_series_id"] = series_id
	return true


static func fail_early_fantasy_guarantee(state: Dictionary, species_id: String) -> bool:
	if species_id.is_empty() or str(state.get("early_fantasy_active_species_id", "")) != species_id:
		return false
	state["early_fantasy_active_species_id"] = ""
	state["early_fantasy_active_series_id"] = ""
	state["early_fantasy_guarantee_pending"] = true
	# A retry deliberately redraws both the missing series and the species. The
	# player is never forced to repeat the exact plant that jellied.
	state["early_fantasy_reserved_species_id"] = ""
	state["early_fantasy_reserved_series_id"] = ""
	return true


static func complete_early_fantasy_guarantee(state: Dictionary, species_id: String) -> bool:
	if species_id.is_empty() or str(state.get("early_fantasy_active_species_id", "")) != species_id:
		return false
	cancel_early_fantasy_guarantee(state)
	return true


static func cancel_early_fantasy_guarantee(state: Dictionary) -> void:
	state["early_fantasy_guarantee_pending"] = false
	state["early_fantasy_active_species_id"] = ""
	state["early_fantasy_active_series_id"] = ""
	state["early_fantasy_reserved_species_id"] = ""
	state["early_fantasy_reserved_series_id"] = ""


static func finish_early_fantasy_guarantees(state: Dictionary) -> void:
	cancel_early_fantasy_guarantee(state)
	state["early_fantasy_tracking_started"] = false
	state["fantasy_new_guarantee_pending"] = false
	if bool(state.get("fantasy_unlocked", false)):
		state["fantasy_new_guarantee_consumed"] = true


static func record_new_get(state: Dictionary, milestone: Dictionary) -> Dictionary:
	var actions := {
		"fantasy_unlocked_now": false,
		"arrangement_intro_queued_now": false,
		"forest_gacha_unlock_ready": false,
		"fusion_lab_intro_queued_now": false,
	}
	if not bool(milestone.get("act2_unlocked", false)):
		return actions
	if bool(milestone.get("is_original", false)) and not bool(state.get("fantasy_unlocked", false)):
		state["fantasy_unlocked"] = true
		state["fantasy_new_guarantee_pending"] = true
		state["fantasy_new_guarantee_consumed"] = false
		begin_early_fantasy_tracking(state)
		actions["fantasy_unlocked_now"] = true
	if not bool(milestone.get("is_fantasy", false)):
		return actions
	var fantasy_count := maxi(0, int(milestone.get("fantasy_get_count", 0)))
	if fantasy_count >= 1 and not bool(milestone.get("fantasy_first_seen", false)):
		queue_story_event(state, EVENT_FANTASY_FIRST)
	if fantasy_count >= ARRANGEMENT_UNLOCK_FANTASY_COUNT \
			and not bool(state.get("arrangement_unlocked", false)) \
			and not bool(state.get("arrangement_intro_pending", false)):
		state["arrangement_intro_pending"] = true
		queue_story_event(state, EVENT_ARRANGEMENT_INTRO)
		actions["arrangement_intro_queued_now"] = true
	if bool(milestone.get("fantasy_required_series_complete", false)) \
			and not bool(milestone.get("fantasy_six_seen", false)):
		queue_story_event(state, EVENT_FANTASY_SIX)
	if bool(state.get("fantasy_unlocked", false)) \
			and fantasy_count >= FOREST_GACHA_UNLOCK_FANTASY_COUNT \
			and not bool(milestone.get("forest_gacha_intro_seen", false)):
		if not bool(milestone.get("forest_gacha_unlocked", false)):
			state["forest_gacha_unlock_pending"] = true
			actions["forest_gacha_unlock_ready"] = true
		queue_story_event(state, EVENT_FOREST_GACHA_INTRO)
	if fantasy_count >= FUSION_LAB_UNLOCK_FANTASY_COUNT \
			and not bool(state.get("fusion_lab_intro_seen", false)) \
			and not bool(state.get("fusion_lab_intro_pending", false)):
		state["fusion_lab_intro_pending"] = true
		queue_story_event(state, EVENT_FUSION_LAB_INTRO)
		actions["fusion_lab_intro_queued_now"] = true
	return actions


static func complete_arrangement_intro(state: Dictionary) -> void:
	consume_story_event(state, EVENT_ARRANGEMENT_INTRO)
	state["arrangement_intro_pending"] = false
	state["arrangement_intro_seen"] = true
	state["arrangement_unlocked"] = true


static func take_forest_gacha_unlock(state: Dictionary) -> bool:
	if not bool(state.get("forest_gacha_unlock_pending", false)):
		return false
	state["forest_gacha_unlock_pending"] = false
	return true


static func complete_forest_gacha_intro(state: Dictionary) -> void:
	consume_story_event(state, EVENT_FOREST_GACHA_INTRO)
	state["forest_gacha_unlock_pending"] = false


static func fusion_lab_is_unlocked(state: Dictionary) -> bool:
	return bool(state.get("fusion_lab_unlocked", false))


static func fusion_lab_intro_is_pending(state: Dictionary) -> bool:
	return bool(state.get("fusion_lab_intro_pending", false)) \
			and not bool(state.get("fusion_lab_intro_seen", false))


static func complete_fusion_lab_intro(state: Dictionary) -> void:
	consume_story_event(state, EVENT_FUSION_LAB_INTRO)
	state["fusion_lab_intro_pending"] = false
	state["fusion_lab_intro_seen"] = true
	state["fusion_lab_unlocked"] = true


static func queue_story_event(state: Dictionary, event_id: String) -> void:
	if event_id not in RUNTIME_EVENT_IDS:
		return
	var events: Array = state.get("pending_story_events", [])
	if event_id not in events:
		events.append(event_id)
	state["pending_story_events"] = events


static func peek_story_event(state: Dictionary) -> String:
	var events: Array = state.get("pending_story_events", [])
	return "" if events.is_empty() else str(events[0])


static func consume_story_event(state: Dictionary, event_id: String) -> void:
	var events: Array = state.get("pending_story_events", [])
	events.erase(event_id)
	state["pending_story_events"] = events


static func queue_post_encounter_greenhouse(state: Dictionary) -> void:
	if bool(state.get("post_encounter_greenhouse_seen", false)):
		return
	state["post_encounter_greenhouse_pending"] = true
	queue_story_event(state, EVENT_POST_ENCOUNTER_HOME)


static func complete_post_encounter_greenhouse(state: Dictionary) -> void:
	consume_story_event(state, EVENT_POST_ENCOUNTER_HOME)
	state["post_encounter_greenhouse_pending"] = false
	state["post_encounter_greenhouse_seen"] = true


static func mark_habitat_crisis_dialog_complete(state: Dictionary) -> void:
	begin_habitat_crisis(state)
	if bool(state.get("post_crisis_greenhouse_seen", false)):
		return
	state["post_crisis_greenhouse_pending"] = true


static func queue_post_crisis_greenhouse_on_return(state: Dictionary) -> void:
	if not bool(state.get("post_crisis_greenhouse_pending", false)) \
			or bool(state.get("post_crisis_greenhouse_seen", false)):
		return
	queue_story_event(state, EVENT_POST_CRISIS_GREENHOUSE)


static func complete_post_crisis_greenhouse(state: Dictionary) -> void:
	consume_story_event(state, EVENT_POST_CRISIS_GREENHOUSE)
	state["post_crisis_greenhouse_pending"] = false
	state["post_crisis_greenhouse_seen"] = true
	var restoration: Dictionary = state.get("restoration", {})
	HabitatRestorationClass.start_large_plant_mission(restoration)
	state["restoration"] = restoration


static func begin_habitat_crisis(state: Dictionary) -> void:
	state["habitat_crisis_route"] = CRISIS_ROUTE_NONE
	var restoration: Dictionary = state.get("restoration", HabitatRestorationClass.default_state())
	HabitatRestorationClass.begin_tracking(restoration)
	state["restoration"] = restoration


static func queue_habitat_crisis_transition(state: Dictionary, acquired_in_habitat: bool) -> void:
	cancel_exploitation_events_for_crisis(state)
	state["habitat_crisis_route"] = CRISIS_ROUTE_SAME_HABITAT \
		if acquired_in_habitat else CRISIS_ROUTE_FORCE_TRAVEL


static func cancel_exploitation_events_for_crisis(state: Dictionary) -> void:
	var events: Array = state.get("pending_story_events", [])
	events.erase(EVENT_ACT3_BATTLE_INTRO)
	events.erase(EVENT_EXPLOITATION_MIDPOINT)
	state["pending_story_events"] = events
	state["act3_battle_intro_pending"] = false
	state["exploitation_midpoint_pending"] = false


static func habitat_crisis_route(state: Dictionary) -> String:
	var route := str(state.get("habitat_crisis_route", CRISIS_ROUTE_NONE))
	return route if route in [CRISIS_ROUTE_SAME_HABITAT, CRISIS_ROUTE_FORCE_TRAVEL] else CRISIS_ROUTE_NONE


static func clear_habitat_crisis_transition(state: Dictionary) -> void:
	state["habitat_crisis_route"] = CRISIS_ROUTE_NONE


static func record_restoration_new_get(
		state: Dictionary, species_id: String, habitat_crisis_started: bool
	) -> bool:
	if not habitat_crisis_started:
		return false
	var restoration: Dictionary = state.get("restoration", HabitatRestorationClass.default_state())
	HabitatRestorationClass.begin_tracking(restoration)
	var became_ready := HabitatRestorationClass.record_new_species(restoration, species_id)
	state["restoration"] = restoration
	return became_ready


static func record_normal_seed_sown_after_crisis(
		state: Dictionary, habitat_crisis_started: bool, amount := 1
	) -> bool:
	if not habitat_crisis_started or amount <= 0:
		return false
	var restoration: Dictionary = state.get(
		"restoration", HabitatRestorationClass.default_state()
	)
	HabitatRestorationClass.begin_tracking(restoration)
	var became_ready := HabitatRestorationClass.record_normal_seed_sown_after_crisis(
		restoration, amount
	)
	state["restoration"] = restoration
	return became_ready


static func complete_restoration_join_home(state: Dictionary) -> void:
	consume_story_event(state, EVENT_RESTORATION_JOIN_HOME)
	var restoration: Dictionary = state.get("restoration", HabitatRestorationClass.default_state())
	HabitatRestorationClass.complete_join_home(restoration)
	state["restoration"] = restoration


static func complete_restoration_join_habitat(state: Dictionary) -> void:
	var restoration: Dictionary = state.get("restoration", HabitatRestorationClass.default_state())
	HabitatRestorationClass.complete_join_habitat(restoration)
	state["restoration"] = restoration


static func restoration_state(state: Dictionary) -> Dictionary:
	var restoration: Variant = state.get("restoration", {})
	if not restoration is Dictionary:
		restoration = HabitatRestorationClass.default_state()
		state["restoration"] = restoration
	return restoration


static func restoration_is_started(state: Dictionary) -> bool:
	return HabitatRestorationClass.is_started(restoration_state(state))


static func restoration_is_complete(state: Dictionary) -> bool:
	return HabitatRestorationClass.is_complete(restoration_state(state))


static func begin_exploitation(state: Dictionary, jurejure_get_count: int = 0) -> void:
	state["exploitation_started"] = true
	if not bool(state.get("act3_battle_intro_seen", false)):
		state["act3_battle_intro_pending"] = true
		queue_story_event(state, EVENT_ACT3_BATTLE_INTRO)
	update_jurejure_progress(state, jurejure_get_count)


static func complete_act3_battle_intro(state: Dictionary) -> void:
	consume_story_event(state, EVENT_ACT3_BATTLE_INTRO)
	state["act3_battle_intro_pending"] = false
	state["act3_battle_intro_seen"] = true
	if not bool(state.get("act3_first_battle_completed", false)):
		state["act3_first_battle_pending"] = true


static func act3_first_battle_is_pending(state: Dictionary) -> bool:
	return bool(state.get("act3_first_battle_pending", false)) \
			and not bool(state.get("act3_first_battle_completed", false))


static func complete_act3_first_battle(state: Dictionary) -> void:
	state["act3_first_battle_pending"] = false
	state["act3_first_battle_completed"] = true


static func update_jurejure_progress(state: Dictionary, jurejure_get_count: int) -> void:
	if not bool(state.get("exploitation_started", false)):
		return
	if jurejure_get_count < 4 or bool(state.get("exploitation_midpoint_seen", false)):
		return
	state["exploitation_midpoint_pending"] = true
	queue_story_event(state, EVENT_EXPLOITATION_MIDPOINT)


static func complete_exploitation_midpoint(state: Dictionary) -> void:
	consume_story_event(state, EVENT_EXPLOITATION_MIDPOINT)
	state["exploitation_midpoint_pending"] = false
	state["exploitation_midpoint_seen"] = true


static func fantasy_is_unlocked(state: Dictionary) -> bool:
	return bool(state.get("fantasy_unlocked", false))


static func arrangement_is_unlocked(state: Dictionary) -> bool:
	return bool(state.get("arrangement_unlocked", false))


static func exploitation_is_started(state: Dictionary) -> bool:
	return bool(state.get("exploitation_started", false))


static func exploitation_midpoint_is_seen(state: Dictionary) -> bool:
	return bool(state.get("exploitation_midpoint_seen", false))


const REMOVED_COMMON_SPECIES_IDS := [
	"momotaro", "lola", "black_prince", "perle_von_nurnberg", "shirobotan",
	"shurei", "bronze_hime", "nijinotama", "pink_pretty", "prolidety"
]

const RETIRED_SPECIAL_BASE_SPECIES_IDS := [
	"glow_colorata", "metal_laui", "seaglass_veria", "amber_agavoides",
	"yumefuwa_jelly", "peach_jelly_succulent"
]

const MAIN_STORY_ORIGINAL_IDS := [
	"colorata", "lutea", "hyalina_san_luis_de_la_paz", "purpusorum",
	"shaviana", "pinwheel", "juliana", "affinis", "laui", "kannte",
	"tovarensis_tovar", "strictiflora_bustamante"
]

static func original_count(discovered: Dictionary) -> int:
	var count := 0
	for species_id in MAIN_STORY_ORIGINAL_IDS:
		if bool(discovered.get(species_id, false)):
			count += 1
	return count

static func originals_complete(discovered: Dictionary) -> bool:
	return original_count(discovered) >= MAIN_STORY_ORIGINAL_IDS.size()

static func is_removed_species(species_id: String) -> bool:
	return species_id in REMOVED_COMMON_SPECIES_IDS


static func is_retired_special_base_species(species_id: String) -> bool:
	return species_id in RETIRED_SPECIAL_BASE_SPECIES_IDS
