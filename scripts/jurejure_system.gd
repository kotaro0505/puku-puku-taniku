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


static func is_safe_target(plant: Dictionary, discovered: Dictionary, species_get_counts: Dictionary) -> bool:
	var individual_id := str(plant.get("individual_id", ""))
	var species_id := str(plant.get("species_id", ""))
	if individual_id.is_empty() or species_id.is_empty():
		return false
	if not bool(discovered.get(species_id, false)):
		return false
	if int(species_get_counts.get(species_id, 0)) <= 0:
		return false
	if bool(plant.get("tutorial", false)) or bool(plant.get("story_protected", false)):
		return false
	if bool(plant.get("jelly_immune", false)) or bool(plant.get("jellied", false)):
		return false
	return true


static func candidate_weight(plant: Dictionary, current_growth_stage: int, second_awakened: bool) -> float:
	var is_small := float(plant.get("diameter_cm", 0.0)) < 30.0
	if not is_small:
		return 1.0
	if second_awakened:
		return 0.0
	match clampi(current_growth_stage, 0, 2):
		1:
			return 0.35
		2:
			return 0.10
		_:
			return 1.0


static func choose_target(
	plants: Array[Dictionary],
	discovered: Dictionary,
	species_get_counts: Dictionary,
	current_growth_stage: int,
	second_awakened: bool,
	rng: RandomNumberGenerator
	) -> Dictionary:
	var weighted: Array[Dictionary] = []
	var total := 0.0
	for plant in plants:
		if not is_safe_target(plant, discovered, species_get_counts):
			continue
		var weight := candidate_weight(plant, current_growth_stage, second_awakened)
		if weight <= 0.0:
			continue
		total += weight
		weighted.append({"plant": plant, "weight": weight})
	if weighted.is_empty() or total <= 0.0:
		return {}
	var roll := rng.randf() * total
	for value in weighted:
		roll -= float(value.get("weight", 0.0))
		if roll <= 0.0:
			return value.get("plant", {})
	return weighted.back().get("plant", {})


static func make_event(plant: Dictionary, now_unix: float) -> Dictionary:
	return {
		"individual_id": str(plant.get("individual_id", "")),
		"species_id": str(plant.get("species_id", "")),
		"diameter_at_start": maxf(0.0, float(plant.get("diameter_cm", 0.0))),
		"harvest_race": float(plant.get("diameter_cm", 0.0)) >= 30.0,
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
	event["harvest_race"] = bool(event.get("harvest_race", event["diameter_at_start"] >= 30.0))
	event["started_unix"] = maxf(0.0, float(event.get("started_unix", now_unix)))
	event["deadline_unix"] = maxf(float(event["started_unix"]), float(event.get("deadline_unix", now_unix + EVENT_GRACE_SECONDS)))
	return event
