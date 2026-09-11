class_name HabitatWildSystem
extends RefCounted

const INITIAL_POPULATION_MIN := 10
const INITIAL_POPULATION_MAX := 14
const MAX_POPULATION := 24
const HARVEST_MIN_CM := 30.0
const MAIN_GROWTH_CM_PER_SECOND := 1.365625
const NORMAL_GROWTH_SCALE := 0.01
const TUTORIAL_GROWTH_SCALE := 0.08
const MIN_SPAWN_INTERVAL_SECONDS := 45 * 60
const MAX_SPAWN_INTERVAL_SECONDS := 4 * 60 * 60
const MAX_EMPTY_INTERVAL_SECONDS := 2 * 60 * 60
const SAFE_POINT_X_RADIUS := 46.0
const SAFE_POINT_Y_RADIUS := 28.0

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
		# Never cap a saved diameter. Old giant plants must retain their exact size.
		plant["diameter_cm"] = maxf(1.6, float(plant.get("diameter_cm", 1.6)))
		plant["jellied"] = bool(plant.get("jellied", false))
		plant["tutorial"] = bool(plant.get("tutorial", false))
		plant["jelly_immune"] = bool(plant.get("jelly_immune", plant["tutorial"]))
		plant["base_growth_rate"] = maxf(0.05, float(plant.get("base_growth_rate", 1.0)))
		plant["jelly_risk_curve"] = maxf(0.05, float(plant.get("jelly_risk_curve", 1.0)))
		plant["last_updated_unix"] = maxi(0, int(plant.get("last_updated_unix", now_unix)))
		plant["jelly_elapsed_seconds"] = maxf(0.0, float(plant.get("jelly_elapsed_seconds", 0.0)))
		plant["jelly_hazard_accumulated"] = maxf(0.0, float(plant.get("jelly_hazard_accumulated", 0.0)))
		plant["jelly_threshold"] = maxf(0.000001, float(plant.get("jelly_threshold", _stable_jelly_threshold(str(plant["individual_id"])))))
		# Keep legacy coordinates untouched here. Main performs a one-time ground
		# validation using the actual safe points after the save is loaded.
		plant["panorama_x"] = float(plant.get("panorama_x", 80.0 + normalized.size() * 78.0))
		plant["panorama_y"] = float(plant.get("panorama_y", 410.0))
		plant["position_validated"] = bool(plant.get("position_validated", false))
		_update_growth_state(plant)
		normalized.append(plant)
	return normalized

static func initialize_population(
	plants: Array[Dictionary],
	candidate_species_ids: Array[String],
	original_species_ids: Array[String],
	tutorial_complete: bool,
	now_unix: int,
	rng: RandomNumberGenerator,
	safe_points: Array = []
) -> void:
	if not plants.is_empty() or candidate_species_ids.is_empty():
		return
	var initial_count := rng.randi_range(INITIAL_POPULATION_MIN, INITIAL_POPULATION_MAX)
	if not tutorial_complete and not original_species_ids.is_empty():
		var tutorial_id := original_species_ids[rng.randi_range(0, original_species_ids.size() - 1)]
		plants.append(_make_plant(tutorial_id, true, rng.randf_range(29.76, 29.84), now_unix, plants, rng, safe_points))
	while plants.size() < initial_count:
		var species_id := candidate_species_ids[rng.randi_range(0, candidate_species_ids.size() - 1)]
		plants.append(_make_plant(species_id, false, rng.randf_range(3.5, 28.9), now_unix, plants, rng, safe_points))

static func add_pending_species(plants: Array[Dictionary], species_id: String, now_unix: int, rng: RandomNumberGenerator, safe_points: Array = []) -> void:
	if species_id.is_empty() or plants.size() >= MAX_POPULATION:
		return
	for plant in plants:
		if str(plant.get("species_id", "")) == species_id:
			return
	plants.append(_make_plant(species_id, false, rng.randf_range(2.0, 7.5), now_unix, plants, rng, safe_points))

static func spawn_one(plants: Array[Dictionary], candidate_species_ids: Array[String], now_unix: int, rng: RandomNumberGenerator, safe_points: Array = []) -> bool:
	if plants.size() >= MAX_POPULATION or candidate_species_ids.is_empty():
		return false
	var species_id := candidate_species_ids[rng.randi_range(0, candidate_species_ids.size() - 1)]
	plants.append(_make_plant(species_id, false, rng.randf_range(1.6, 6.5), now_unix, plants, rng, safe_points))
	return true

static func next_spawn_unix(now_unix: int, rng: RandomNumberGenerator, population: int) -> int:
	var maximum := MAX_EMPTY_INTERVAL_SECONDS if population <= 0 else MAX_SPAWN_INTERVAL_SECONDS
	return now_unix + rng.randi_range(MIN_SPAWN_INTERVAL_SECONDS, maximum)

static func repair_unsafe_positions(plants: Array[Dictionary], safe_points: Array, rng: RandomNumberGenerator) -> bool:
	if safe_points.is_empty():
		return false
	var changed := false
	for plant in plants:
		if bool(plant.get("position_validated", false)):
			continue
		if bool(plant.get("tutorial", false)):
			plant["position_validated"] = true
			changed = true
			continue
		var point := Vector2(float(plant.get("panorama_x", 640.0)), float(plant.get("panorama_y", 410.0)))
		if not is_safe_ground_point(point, safe_points):
			var replacement := _choose_safe_point(plants, rng, safe_points, plant)
			plant["panorama_x"] = replacement.x
			plant["panorama_y"] = replacement.y
		plant["position_validated"] = true
		changed = true
	return changed

static func is_safe_ground_point(point: Vector2, safe_points: Array) -> bool:
	for safe_value in safe_points:
		var safe_point: Vector2 = safe_value
		var dx := (point.x - safe_point.x) / SAFE_POINT_X_RADIUS
		var dy := (point.y - safe_point.y) / SAFE_POINT_Y_RADIUS
		if dx * dx + dy * dy <= 1.0:
			return true
	return false

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
			var tutorial := bool(plant.get("tutorial", false))
			var growth_scale := TUTORIAL_GROWTH_SCALE if tutorial else NORMAL_GROWTH_SCALE
			var growth_rate := maxf(0.05, float(plant.get("base_growth_rate", 1.0)))
			var diameter_before := maxf(1.6, float(plant.get("diameter_cm", 1.6)))
			var diameter_after := diameter_before + elapsed * MAIN_GROWTH_CM_PER_SECOND * growth_rate * growth_scale
			plant["diameter_cm"] = diameter_after
			if not tutorial and not bool(plant.get("jelly_immune", false)):
				var hazard := jelly_hazard_for_interval(diameter_before, diameter_after, float(elapsed), float(plant.get("jelly_risk_curve", 1.0)))
				plant["jelly_hazard_accumulated"] = maxf(0.0, float(plant.get("jelly_hazard_accumulated", 0.0))) + hazard
				if float(plant["jelly_hazard_accumulated"]) >= maxf(0.000001, float(plant.get("jelly_threshold", _stable_jelly_threshold(str(plant.get("individual_id", "")))))):
					plant["jellied"] = true
		_update_growth_state(plant)
		changed = true
	return changed

static func jelly_hazard_for_interval(start_diameter_cm: float, end_diameter_cm: float, elapsed_seconds: float, risk_curve: float = 1.0) -> float:
	if elapsed_seconds <= 0.0:
		return 0.0
	# A small hourly hazard rises smoothly with size. It is deliberately never
	# certain: 100 cm and larger survivors remain possible, including offline.
	var midpoint_cm := (maxf(1.6, start_diameter_cm) + maxf(1.6, end_diameter_cm)) * 0.5
	var hourly_probability := 0.00015
	if midpoint_cm > 20.0:
		hourly_probability += minf(0.0045, (midpoint_cm - 20.0) * 0.000055)
	if midpoint_cm > 100.0:
		hourly_probability += minf(0.0100, log(1.0 + (midpoint_cm - 100.0) / 45.0) * 0.0025)
	hourly_probability = clampf(hourly_probability * maxf(0.05, risk_curve), 0.00001, 0.018)
	return -log(1.0 - hourly_probability) * (elapsed_seconds / 3600.0)

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

static func _make_plant(species_id: String, tutorial: bool, diameter_cm: float, now_unix: int, plants: Array[Dictionary], rng: RandomNumberGenerator, safe_points: Array) -> Dictionary:
	var point := Vector2(810.0, 385.0) if tutorial else _choose_safe_point(plants, rng, safe_points)
	var threshold_roll := clampf(rng.randf(), 0.000001, 0.999999)
	var plant := {
		"individual_id": "wild_%d_%d_%d" % [now_unix, plants.size(), rng.randi_range(1000, 999999)],
		"species_id": species_id,
		"diameter_cm": diameter_cm,
		"growth_state": "growing",
		"jellied": false,
		"jelly_immune": tutorial,
		"jelly_elapsed_seconds": 0.0,
		"jelly_hazard_accumulated": 0.0,
		"jelly_threshold": -log(1.0 - threshold_roll),
		"jelly_risk_curve": 1.0,
		"tutorial": tutorial,
		"base_growth_rate": 1.0,
		"last_updated_unix": now_unix,
		"panorama_x": point.x,
		"panorama_y": point.y,
		"position_validated": true
	}
	_update_growth_state(plant)
	return plant

static func _choose_safe_point(plants: Array[Dictionary], rng: RandomNumberGenerator, safe_points: Array, ignored_plant: Dictionary = {}) -> Vector2:
	if safe_points.is_empty():
		return Vector2(640.0, 410.0)
	var best := Vector2(safe_points[0])
	var best_clearance := -1.0
	for attempt in range(24):
		var anchor: Vector2 = safe_points[rng.randi_range(0, safe_points.size() - 1)]
		var candidate := Vector2(anchor.x + rng.randf_range(-24.0, 24.0), anchor.y + rng.randf_range(-9.0, 9.0))
		var clearance := 99999.0
		for other in plants:
			if other == ignored_plant:
				continue
			var other_point := Vector2(float(other.get("panorama_x", 0.0)), float(other.get("panorama_y", 0.0)))
			clearance = minf(clearance, candidate.distance_to(other_point))
		if clearance > best_clearance:
			best = candidate
			best_clearance = clearance
		if clearance >= 58.0:
			break
	return best

static func _stable_jelly_threshold(individual_id: String) -> float:
	var stable_rng := RandomNumberGenerator.new()
	stable_rng.seed = absi(individual_id.hash()) + 1
	var roll := clampf(stable_rng.randf(), 0.000001, 0.999999)
	return -log(1.0 - roll)

static func _update_growth_state(plant: Dictionary) -> void:
	if bool(plant.get("jellied", false)):
		plant["growth_state"] = "jellied"
	elif float(plant.get("diameter_cm", 0.0)) >= HARVEST_MIN_CM:
		plant["growth_state"] = "ready"
	else:
		plant["growth_state"] = "growing"
