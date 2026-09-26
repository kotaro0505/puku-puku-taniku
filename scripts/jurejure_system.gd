class_name JureJureSystem
extends RefCounted

# All pacing knobs live here so the event can be tuned without touching the
# habitat simulation. A roll only happens while the game is running.
const EVENT_CHECK_INTERVAL_SECONDS := 60.0
const EVENT_CHANCE_PER_CHECK := 0.02
const EVENT_COOLDOWN_SECONDS := 21600.0
const EVENT_GRACE_SECONDS := 1800.0
const MID_STAGE_ORIGINAL_COUNT := 6
const LATE_STAGE_ORIGINAL_COUNT := 10
const GROWTH_EARLY := 0
const GROWTH_MID := 1
const GROWTH_LATE := 2


static func growth_stage(original_count: int) -> int:
	if original_count >= LATE_STAGE_ORIGINAL_COUNT:
		return GROWTH_LATE
	if original_count >= MID_STAGE_ORIGINAL_COUNT:
		return GROWTH_MID
	return GROWTH_EARLY


static func is_safe_target(plant: Dictionary, settled_species: Dictionary) -> bool:
	var individual_id := str(plant.get("individual_id", ""))
	var species_id := str(plant.get("species_id", ""))
	if individual_id.is_empty() or species_id.is_empty():
		return false
	if not bool(settled_species.get(species_id, false)):
		return false
	if bool(plant.get("tutorial", false)) or bool(plant.get("story_protected", false)):
		return false
	if bool(plant.get("jelly_immune", false)) or bool(plant.get("jellied", false)):
		return false
	return true


static func choose_target(
	plants: Array[Dictionary],
	settled_species: Dictionary,
	rng: RandomNumberGenerator
	) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for plant in plants:
		if not is_safe_target(plant, settled_species):
			continue
		candidates.append(plant)
	if candidates.is_empty():
		return {}
	return candidates[rng.randi_range(0, candidates.size() - 1)]


static func make_event(plant: Dictionary, now_unix: float) -> Dictionary:
	return {
		"individual_id": str(plant.get("individual_id", "")),
		"species_id": str(plant.get("species_id", "")),
		"diameter_at_start": maxf(0.0, float(plant.get("diameter_cm", 0.0))),
		"event_type": "habitat_take",
		"started_unix": now_unix,
		"deadline_unix": now_unix + EVENT_GRACE_SECONDS
	}


static func normalize_active_event(source: Variant, plants: Array[Dictionary], now_unix: float) -> Dictionary:
	if not source is Dictionary:
		return {}
	var event: Dictionary = source.duplicate(true)
	var individual_id := str(event.get("individual_id", ""))
	if individual_id.is_empty():
		return {}
	var found := false
	for plant in plants:
		if str(plant.get("individual_id", "")) == individual_id:
			found = true
			break
	if not found:
		return {}
	event["species_id"] = str(event.get("species_id", ""))
	event["diameter_at_start"] = maxf(0.0, float(event.get("diameter_at_start", 0.0)))
	event.erase("harvest_race")
	event["event_type"] = "habitat_take"
	event["started_unix"] = maxf(0.0, float(event.get("started_unix", now_unix)))
	event["deadline_unix"] = maxf(float(event["started_unix"]), float(event.get("deadline_unix", now_unix + EVENT_GRACE_SECONDS)))
	return event
