class_name HabitatWildSystem
extends RefCounted

const TARGET_POPULATION := 15
const HARVEST_MIN_CM := 30.0
const MAIN_GROWTH_CM_PER_SECOND := 1.365625
const NORMAL_GROWTH_SCALE := 0.01
const TUTORIAL_GROWTH_SCALE := 0.08

static func normalize_saved(source: Variant, valid_species_ids: Array[String], now_unix: int) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	if not source is Array:
		return normalized
	var valid: Dictionary = {}
	for species_id in valid_species_ids:
		valid[species_id] = true
	for raw_value in source:
		if not raw_value is Dictionary:
			continue
		var raw: Dictionary = raw_value
		var species_id := str(raw.get("species_id", ""))
		if species_id.is_empty() or not valid.has(species_id):
			continue
		var plant := raw.duplicate(true)
		plant["individual_id"] = str(plant.get("individual_id", "wild_%d" % normalized.size()))
		plant["species_id"] = species_id
		plant["diameter_cm"] = maxf(1.6, float(plant.get("diameter_cm", 1.6)))
		plant["jellied"] = bool(plant.get("jellied", false))
		plant["tutorial"] = bool(plant.get("tutorial", false))
		plant["jelly_immune"] = bool(plant.get("jelly_immune", plant["tutorial"]))
		plant["base_growth_rate"] = maxf(0.05, float(plant.get("base_growth_rate", 1.0)))
		plant["last_updated_unix"] = maxi(0, int(plant.get("last_updated_unix", now_unix)))
		plant["jelly_elapsed_seconds"] = maxf(0.0, float(plant.get("jelly_elapsed_seconds", 0.0)))
		plant["panorama_x"] = clampf(float(plant.get("panorama_x", 80.0 + normalized.size() * 78.0)), 24.0, 1256.0)
		plant["panorama_y"] = clampf(float(plant.get("panorama_y", 410.0)), 360.0, 470.0)
		_update_growth_state(plant)
		normalized.append(plant)
	return normalized

static func ensure_population(
	plants: Array[Dictionary],
	candidate_species_ids: Array[String],
	original_species_ids: Array[String],
	tutorial_complete: bool,
	now_unix: int,
	rng: RandomNumberGenerator
) -> Array[Dictionary]:
	if candidate_species_ids.is_empty():
		return plants
	if plants.is_empty() and not tutorial_complete and not original_species_ids.is_empty():
		var tutorial_id := original_species_ids[rng.randi_range(0, original_species_ids.size() - 1)]
		plants.append(_make_plant(tutorial_id, true, rng.randf_range(29.76, 29.84), now_unix, 0, rng))
		while plants.size() < TARGET_POPULATION:
			var species_id := candidate_species_ids[rng.randi_range(0, candidate_species_ids.size() - 1)]
			plants.append(_make_plant(species_id, false, rng.randf_range(3.5, 28.9), now_unix, plants.size(), rng))
		return plants
	while plants.size() < TARGET_POPULATION:
		var species_id := candidate_species_ids[rng.randi_range(0, candidate_species_ids.size() - 1)]
		plants.append(_make_plant(species_id, false, rng.randf_range(1.6, 6.5), now_unix, plants.size(), rng))
	return plants

static func add_pending_species(plants: Array[Dictionary], species_id: String, now_unix: int, rng: RandomNumberGenerator) -> void:
	if species_id.is_empty():
		return
	for plant in plants:
		if str(plant.get("species_id", "")) == species_id:
			return
	plants.append(_make_plant(species_id, false, rng.randf_range(2.0, 7.5), now_unix, plants.size(), rng))

static func advance_time(plants: Array[Dictionary], now_unix: int) -> bool:
	var changed := false
	for plant in plants:
		var previous_update := maxi(0, int(plant.get("last_updated_unix", now_unix)))
		var elapsed := maxi(0, now_unix - previous_update)
		if elapsed <= 0:
			continue
		plant["last_updated_unix"] = now_unix
		plant["jelly_elapsed_seconds"] = maxf(0.0, float(plant.get("jelly_elapsed_seconds", 0.0))) + elapsed
		if not bool(plant.get("jellied", false)):
			var growth_scale := TUTORIAL_GROWTH_SCALE if bool(plant.get("tutorial", false)) else NORMAL_GROWTH_SCALE
			var growth_rate := maxf(0.05, float(plant.get("base_growth_rate", 1.0)))
			plant["diameter_cm"] = maxf(1.6, float(plant.get("diameter_cm", 1.6))) + elapsed * MAIN_GROWTH_CM_PER_SECOND * growth_rate * growth_scale
		_update_growth_state(plant)
		changed = true
	return changed

static func can_harvest(plant: Dictionary) -> bool:
	return not bool(plant.get("jellied", false)) and float(plant.get("diameter_cm", 0.0)) >= HARVEST_MIN_CM

static func remove_individual(plants: Array[Dictionary], individual_id: String) -> Dictionary:
	for index in range(plants.size()):
		if str(plants[index].get("individual_id", "")) == individual_id:
			var removed := plants[index]
			plants.remove_at(index)
			return removed
	return {}

static func tutorial_plant(plants: Array[Dictionary]) -> Dictionary:
	for plant in plants:
		if bool(plant.get("tutorial", false)):
			return plant
	return {}

static func _make_plant(species_id: String, tutorial: bool, diameter_cm: float, now_unix: int, slot_index: int, rng: RandomNumberGenerator) -> Dictionary:
	var column := slot_index % TARGET_POPULATION
	var panorama_x := 44.0 + column * (1192.0 / float(TARGET_POPULATION - 1))
	var panorama_y := rng.randf_range(392.0, 454.0)
	if tutorial:
		panorama_x = 810.0
		panorama_y = 385.0
	var plant := {
		"individual_id": "wild_%d_%d_%d" % [now_unix, slot_index, rng.randi_range(1000, 999999)],
		"species_id": species_id,
		"diameter_cm": diameter_cm,
		"growth_state": "growing",
		"jellied": false,
		"jelly_immune": tutorial,
		"jelly_elapsed_seconds": 0.0,
		"tutorial": tutorial,
		"base_growth_rate": 1.0,
		"last_updated_unix": now_unix,
		"panorama_x": clampf(panorama_x + rng.randf_range(-16.0, 16.0), 24.0, 1256.0),
		"panorama_y": panorama_y
	}
	_update_growth_state(plant)
	return plant

static func _update_growth_state(plant: Dictionary) -> void:
	if bool(plant.get("jellied", false)):
		plant["growth_state"] = "jellied"
	elif float(plant.get("diameter_cm", 0.0)) >= HARVEST_MIN_CM:
		plant["growth_state"] = "ready"
	else:
		plant["growth_state"] = "growing"
