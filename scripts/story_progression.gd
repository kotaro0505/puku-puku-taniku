class_name StoryProgression
extends RefCounted

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
const RUNTIME_STATE_VERSION := 2
const EVENT_POST_ENCOUNTER_HOME := "post_jurejure_encounter_home"
const EVENT_FANTASY_FIRST := "fantasy_first_discovery"
const EVENT_FANTASY_SIX := "fantasy_realization"
const EVENT_EXPLOITATION_MIDPOINT := "exploitation_midpoint"
const EVENT_SECRET_GACHA_INSTALL := "secret_gacha_install"
const RUNTIME_EVENT_IDS := [
	EVENT_POST_ENCOUNTER_HOME,
	EVENT_FANTASY_FIRST,
	EVENT_FANTASY_SIX,
	EVENT_EXPLOITATION_MIDPOINT,
	EVENT_SECRET_GACHA_INSTALL,
]

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
		"post_encounter_greenhouse_pending": false,
		"post_encounter_greenhouse_seen": false,
		"exploitation_started": false,
		"exploitation_midpoint_pending": false,
		"exploitation_midpoint_seen": false,
		"pending_story_events": [],
		"secret_gacha_unlocked": false,
		"secret_gacha_install_seen": false,
		"last_exploitation_dialog_index": -1,
		"last_crisis_concern_visit": -1,
	}


static func normalize_runtime_state(raw_state: Variant, migration: Dictionary = {}) -> Dictionary:
	var state := default_runtime_state()
	var saved_runtime_version := 0
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
		var old_secret_evidence := bool(migration.get("secret_gacha_evidence", false))
		var old_act3_intro_seen := bool(migration.get("act3_intro_seen", false))
		var old_jurejure_count := maxi(0, int(migration.get("jurejure_get_count", 0)))
		if old_act3_intro_seen or old_crisis_started or old_secret_evidence:
			state["exploitation_started"] = true
		if old_crisis_started or old_secret_evidence:
			state["exploitation_midpoint_pending"] = false
			state["exploitation_midpoint_seen"] = true
			state["pending_story_events"].erase(EVENT_EXPLOITATION_MIDPOINT)
		elif bool(state.get("exploitation_started", false)) and old_jurejure_count >= 4:
			state["exploitation_midpoint_pending"] = true
			queue_story_event(state, EVENT_EXPLOITATION_MIDPOINT)
		if old_crisis_started or old_secret_evidence:
			state["secret_gacha_unlocked"] = true
			state["secret_gacha_install_seen"] = true
			state["pending_story_events"].erase(EVENT_SECRET_GACHA_INSTALL)
	# A v1 runtime payload can be loaded independently of the outer save version
	# in tests and tools. Infer the phase from its own durable evidence as a
	# final guard.
	if saved_runtime_version < RUNTIME_STATE_VERSION and bool(state.get("secret_gacha_unlocked", false)):
		state["exploitation_started"] = true
		state["exploitation_midpoint_pending"] = false
		state["exploitation_midpoint_seen"] = true
	if bool(state.get("post_encounter_greenhouse_seen", false)):
		state["post_encounter_greenhouse_pending"] = false
		state["pending_story_events"].erase(EVENT_POST_ENCOUNTER_HOME)
	elif bool(state.get("post_encounter_greenhouse_pending", false)):
		queue_story_event(state, EVENT_POST_ENCOUNTER_HOME)
	if bool(state.get("exploitation_midpoint_seen", false)):
		state["exploitation_midpoint_pending"] = false
		state["pending_story_events"].erase(EVENT_EXPLOITATION_MIDPOINT)
	elif bool(state.get("exploitation_midpoint_pending", false)):
		queue_story_event(state, EVENT_EXPLOITATION_MIDPOINT)
	if bool(state.get("secret_gacha_unlocked", false)) or bool(state.get("secret_gacha_install_seen", false)):
		state["secret_gacha_unlocked"] = true
		state["secret_gacha_install_seen"] = true
		state["pending_story_events"].erase(EVENT_SECRET_GACHA_INSTALL)
	return state


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


static func record_new_get(state: Dictionary, milestone: Dictionary) -> Dictionary:
	var actions := {
		"fantasy_unlocked_now": false,
		"forest_gacha_unlocked_now": false,
	}
	if not bool(milestone.get("act2_unlocked", false)):
		return actions
	if bool(milestone.get("is_original", false)) and not bool(state.get("fantasy_unlocked", false)):
		state["fantasy_unlocked"] = true
		state["fantasy_new_guarantee_pending"] = true
		state["fantasy_new_guarantee_consumed"] = false
		actions["fantasy_unlocked_now"] = true
	if not bool(milestone.get("is_fantasy", false)):
		return actions
	var fantasy_count := maxi(0, int(milestone.get("fantasy_get_count", 0)))
	if fantasy_count >= 1 and not bool(milestone.get("fantasy_first_seen", false)):
		queue_story_event(state, EVENT_FANTASY_FIRST)
	if fantasy_count >= 6 and not bool(milestone.get("fantasy_six_seen", false)):
		queue_story_event(state, EVENT_FANTASY_SIX)
	if bool(state.get("fantasy_unlocked", false)) and fantasy_count >= 2 and not bool(milestone.get("forest_gacha_unlocked", false)):
		actions["forest_gacha_unlocked_now"] = true
	return actions


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


static func begin_exploitation(state: Dictionary, jurejure_get_count: int = 0) -> void:
	state["exploitation_started"] = true
	update_jurejure_progress(state, jurejure_get_count)


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
	if not bool(state.get("secret_gacha_install_seen", false)):
		queue_story_event(state, EVENT_SECRET_GACHA_INSTALL)


static func complete_secret_gacha_install(state: Dictionary) -> void:
	consume_story_event(state, EVENT_SECRET_GACHA_INSTALL)
	state["secret_gacha_install_seen"] = true
	state["secret_gacha_unlocked"] = true


static func fantasy_is_unlocked(state: Dictionary) -> bool:
	return bool(state.get("fantasy_unlocked", false))


static func exploitation_is_started(state: Dictionary) -> bool:
	return bool(state.get("exploitation_started", false))


static func exploitation_midpoint_is_seen(state: Dictionary) -> bool:
	return bool(state.get("exploitation_midpoint_seen", false))


static func secret_gacha_is_unlocked(state: Dictionary) -> bool:
	return bool(state.get("secret_gacha_unlocked", false))

const REMOVED_COMMON_SPECIES_IDS := [
	"momotaro", "lola", "black_prince", "perle_von_nurnberg", "shirobotan",
	"shurei", "bronze_hime", "nijinotama", "pink_pretty", "prolidety"
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
