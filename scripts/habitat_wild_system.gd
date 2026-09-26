class_name HabitatWildSystem
extends RefCounted

const INITIAL_POPULATION_MIN := 10
const INITIAL_POPULATION_MAX := 14
const MAX_POPULATION := 24
const MATURITY_MIN_CM := 24.0
const MATURITY_MAX_CM := 36.0

# Normal-habitat balance knobs. Changing these updates live play, offline
# catch-up, ETA calculation, and development time travel together.
const MAIN_GROWTH_CM_PER_SECOND := 1.365625
const NORMAL_HABITAT_GROWTH_SCALE := 1.0 / 120000.0
const MAIN_JELLY_PROBABILITY_PER_SECOND := 0.06
const NORMAL_HABITAT_JELLY_SCALE := 1.0 / 15000.0
const NORMAL_HABITAT_JELLY_PROBABILITY_PER_SECOND := MAIN_JELLY_PROBABILITY_PER_SECOND * NORMAL_HABITAT_JELLY_SCALE

# Compatibility alias for older callers.
const NORMAL_GROWTH_SCALE := NORMAL_HABITAT_GROWTH_SCALE
const TUTORIAL_GROWTH_SCALE := 0.08
const TIMING_VERSION := 3

# v16 and older saves can contain runaway normal-habitat plants produced by
# the former real-time growth loop. This is only a migration detector: normal
# play is never clamped to this value, and valid post-migration saves keep their
# exact diameters.
const LEGACY_RUNAWAY_DIAMETER_CM := 100.0

const MIN_SPAWN_INTERVAL_SECONDS := 45 * 60
const MAX_SPAWN_INTERVAL_SECONDS := 4 * 60 * 60
const MAX_EMPTY_INTERVAL_SECONDS := 2 * 60 * 60
const SAFE_POINT_X_RADIUS := 46.0
const SAFE_POINT_Y_RADIUS := 28.0


static func has_legacy_runaway_population(source: Variant) -> bool:
	if not source is Array:
		return false
	for raw_value in source:
		if raw_value is Dictionary and float(raw_value.get("diameter_cm", 0.0)) > LEGACY_RUNAWAY_DIAMETER_CM:
			return true
	return false


static func normalize_saved(source: Variant, valid_species_ids: Array[String], now_unix: float) -> Array[Dictionary]:
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
		# Normal-habitat jelly is terminal. Older saves kept these entries so the
		# player could tap them later; silently discard that legacy state now.
		if bool(raw.get("jellied", false)):
			continue
		var species_id := str(raw.get("species_id", ""))
		if species_id.is_empty() or not valid.has(species_id):
			continue
		var plant := raw.duplicate(true)
		plant["individual_id"] = str(plant.get("individual_id", "wild_%d" % normalized.size()))
		plant["species_id"] = species_id
		# Valid saved sizes are preserved exactly. Runaway legacy populations are
		# detected and regenerated once by main.gd before normalization reaches here.
		plant["diameter_cm"] = maxf(1.6, float(plant.get("diameter_cm", 1.6)))
		plant["jellied"] = false
		plant["tutorial"] = bool(plant.get("tutorial", false))
		plant["jelly_immune"] = bool(plant.get("jelly_immune", plant["tutorial"]))
		plant["base_growth_rate"] = maxf(0.05, float(plant.get("base_growth_rate", 1.0)))
		plant["jelly_risk_curve"] = maxf(0.05, float(plant.get("jelly_risk_curve", 1.0)))
		plant["last_updated_unix"] = maxf(0.0, float(plant.get("last_updated_unix", now_unix)))
		plant["spawned_unix"] = maxf(0.0, float(plant.get("spawned_unix", plant["last_updated_unix"])))
		# Panda Beacon and the old 30 cm harvest boundary were retired.  Read old
		# saves safely, but never carry either state into the observation habitat.
		plant.erase("panda_beacon_installed")
		plant["jelly_threshold"] = maxf(0.000001, float(plant.get("jelly_threshold", _stable_jelly_threshold(str(plant["individual_id"])))))
		plant["mature_diameter_cm"] = clampf(float(plant.get("mature_diameter_cm", _stable_maturity_diameter(str(plant["individual_id"])))), MATURITY_MIN_CM, MATURITY_MAX_CM)

		var saved_timing_version := int(plant.get("habitat_timing_version", 0))
		if saved_timing_version < TIMING_VERSION:
			# Start the natural-lifetime clock from the loaded state. Legacy 30 cm
			# readiness and beacon timing fields intentionally do not migrate.
			plant["jelly_hazard_accumulated"] = 0.0
			plant["jelly_elapsed_seconds"] = 0.0
			plant["jelly_eligible_since_unix"] = float(plant["last_updated_unix"]) if float(plant["diameter_cm"]) >= float(plant["mature_diameter_cm"]) else 0.0
			plant["jellied_unix"] = float(plant["last_updated_unix"]) if bool(plant["jellied"]) else 0.0
		else:
			plant["jelly_hazard_accumulated"] = maxf(0.0, float(plant.get("jelly_hazard_accumulated", 0.0)))
			plant["jelly_elapsed_seconds"] = maxf(0.0, float(plant.get("jelly_elapsed_seconds", 0.0)))
			plant["jelly_eligible_since_unix"] = maxf(0.0, float(plant.get("jelly_eligible_since_unix", 0.0)))
			plant["jellied_unix"] = maxf(0.0, float(plant.get("jellied_unix", 0.0)))
		plant["habitat_timing_version"] = TIMING_VERSION

		plant["panorama_x"] = float(plant.get("panorama_x", 80.0 + normalized.size() * 78.0))
		plant["panorama_y"] = float(plant.get("panorama_y", 410.0))
		plant["position_validated"] = bool(plant.get("position_validated", false))
		_refresh_timing_fields(plant, float(plant["last_updated_unix"]))
		_update_growth_state(plant)
		normalized.append(plant)
	return normalized


static func initialize_population(plants: Array[Dictionary], candidate_species_ids: Array[String], original_species_ids: Array[String], tutorial_complete: bool, now_unix: float, rng: RandomNumberGenerator, safe_points: Array = []) -> void:
	if not plants.is_empty() or candidate_species_ids.is_empty():
		return
	var initial_count := rng.randi_range(INITIAL_POPULATION_MIN, INITIAL_POPULATION_MAX)
	while plants.size() < initial_count:
		var species_id := candidate_species_ids[rng.randi_range(0, candidate_species_ids.size() - 1)]
		plants.append(_make_plant(species_id, false, rng.randf_range(3.5, 28.9), now_unix, plants, rng, safe_points))


static func initialize_awakened_population(plants: Array[Dictionary], candidate_species_ids: Array[String], original_species_ids: Array[String], now_unix: float, rng: RandomNumberGenerator, safe_points: Array = []) -> void:
	# The first sprouts belong to the awakening event. Start with only a few;
	# ordinary timed spawning enriches the habitat after the story moment.
	if not plants.is_empty() or (candidate_species_ids.is_empty() and original_species_ids.is_empty()):
		return
	var awakening_species: Array[String] = []
	for species_id in original_species_ids:
		if not species_id.is_empty() and species_id not in awakening_species:
			awakening_species.append(species_id)
			if awakening_species.size() == 3:
				break
	for species_id in candidate_species_ids:
		if awakening_species.size() == 3:
			break
		if not species_id.is_empty() and species_id not in awakening_species:
			awakening_species.append(species_id)
	var spread_points: Array[Vector2] = []
	if safe_points.size() >= 3:
		var last_point_index := safe_points.size() - 1
		for point_index in [int(round(last_point_index * 0.1)), int(round(last_point_index * 0.55)), int(round(last_point_index * 0.9))]:
			spread_points.append(Vector2(safe_points[point_index]))
	else:
		spread_points = [Vector2(155, 410), Vector2(625, 455), Vector2(1130, 400)]
	for index in mini(3, awakening_species.size()):
		var tutorial := index == 0
		var diameter := rng.randf_range(2.0, 5.5)
		var plant := _make_plant(awakening_species[index], tutorial, diameter, now_unix, plants, rng, safe_points)
		plant["panorama_x"] = spread_points[index].x
		plant["panorama_y"] = spread_points[index].y
		plant["position_validated"] = true
		plants.append(plant)


static func add_pending_species(plants: Array[Dictionary], species_id: String, now_unix: float, rng: RandomNumberGenerator, safe_points: Array = []) -> void:
	if species_id.is_empty() or plants.size() >= MAX_POPULATION:
		return
	for plant in plants:
		if str(plant.get("species_id", "")) == species_id:
			return
	plants.append(_make_plant(species_id, false, rng.randf_range(2.0, 7.5), now_unix, plants, rng, safe_points))


static func spawn_one(plants: Array[Dictionary], candidate_species_ids: Array[String], now_unix: float, rng: RandomNumberGenerator, safe_points: Array = []) -> bool:
	if plants.size() >= MAX_POPULATION or candidate_species_ids.is_empty():
		return false
	var species_id := candidate_species_ids[rng.randi_range(0, candidate_species_ids.size() - 1)]
	plants.append(_make_plant(species_id, false, rng.randf_range(1.6, 6.5), now_unix, plants, rng, safe_points))
	return true


static func next_spawn_unix(now_unix: float, rng: RandomNumberGenerator, population: int) -> float:
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


static func refresh_growth_profile(plant: Dictionary, base_growth_rate: float, jelly_risk_curve: float, reference_unix: float) -> bool:
	var normalized_growth := maxf(0.05, base_growth_rate)
	var normalized_risk := maxf(0.05, jelly_risk_curve)
	var changed := not is_equal_approx(float(plant.get("base_growth_rate", 1.0)), normalized_growth) or not is_equal_approx(float(plant.get("jelly_risk_curve", 1.0)), normalized_risk)
	plant["base_growth_rate"] = normalized_growth
	plant["jelly_risk_curve"] = normalized_risk
	_refresh_timing_fields(plant, reference_unix)
	return changed


static func advance_time(plants: Array[Dictionary], now_unix: float) -> bool:
	return bool(advance_time_with_events(plants, now_unix).get("changed", false))


static func advance_time_with_events(plants: Array[Dictionary], now_unix: float) -> Dictionary:
	var result := {
		"changed": false,
		"jellied": [],
		"jellied_details": [],
		"removed": []
	}
	var removal_indexes: Array[int] = []
	for index in range(plants.size()):
		var plant: Dictionary = plants[index]
		# A stale jellied entry can only come from an old save or inconsistent
		# caller. Remove it quietly; it is not a new player-facing event.
		if bool(plant.get("jellied", false)):
			result["changed"] = true
			result["removed"].append(str(plant.get("individual_id", "")))
			removal_indexes.append(index)
			continue
		var events := _advance_plant(plant, now_unix)
		if bool(events.get("changed", false)):
			result["changed"] = true
		if bool(events.get("became_jellied", false)):
			result["jellied"].append(str(plant.get("individual_id", "")))
			result["jellied_details"].append(_event_snapshot(plant))
			result["removed"].append(str(plant.get("individual_id", "")))
			removal_indexes.append(index)
	# Mutate only after every plant in the interval has been evaluated. Reverse
	# removal keeps indexes stable when several plants jelly in one jump/tick.
	removal_indexes.reverse()
	for index in removal_indexes:
		plants.remove_at(index)
	return result


static func _event_snapshot(plant: Dictionary) -> Dictionary:
	return {
		"individual_id": str(plant.get("individual_id", "")),
		"species_id": str(plant.get("species_id", "")),
		"diameter_cm": float(plant.get("diameter_cm", 0.0)),
		"jellied_unix": float(plant.get("jellied_unix", 0.0))
	}


static func _advance_plant(plant: Dictionary, now_unix: float) -> Dictionary:
	var previous_update := maxf(0.0, float(plant.get("last_updated_unix", now_unix)))
	var elapsed := maxf(0.0, now_unix - previous_update)
	if elapsed <= 0.0:
		_refresh_timing_fields(plant, previous_update)
		return {"changed": false, "became_jellied": false}

	var was_jellied := bool(plant.get("jellied", false))
	plant["last_updated_unix"] = now_unix
	if was_jellied:
		_refresh_timing_fields(plant, now_unix)
		_update_growth_state(plant)
		return {"changed": true, "became_jellied": false}

	var tutorial := bool(plant.get("tutorial", false))
	var growth_rate := growth_rate_cm_per_second(plant)
	var diameter_before := maxf(1.6, float(plant.get("diameter_cm", 1.6)))
	var mature_diameter := clampf(float(plant.get("mature_diameter_cm", _stable_maturity_diameter(str(plant.get("individual_id", ""))))), MATURITY_MIN_CM, MATURITY_MAX_CM)
	plant["mature_diameter_cm"] = mature_diameter
	var seconds_until_mature := 0.0 if diameter_before >= mature_diameter else (mature_diameter - diameter_before) / maxf(growth_rate, 0.0000000001)
	var matures_within_interval := seconds_until_mature <= elapsed
	var eligible_seconds := 0.0
	var eligible_start_unix := previous_update
	if not tutorial and not bool(plant.get("jelly_immune", false)):
		if diameter_before >= mature_diameter:
			eligible_seconds = elapsed
		elif matures_within_interval:
			eligible_start_unix = previous_update + seconds_until_mature
			eligible_seconds = maxf(0.0, elapsed - seconds_until_mature)

	var seconds_grown := elapsed
	var became_jellied := false
	if eligible_seconds > 0.0:
		if float(plant.get("jelly_eligible_since_unix", 0.0)) <= 0.0:
			plant["jelly_eligible_since_unix"] = eligible_start_unix
		var hazard_rate := jelly_hazard_rate_per_second(float(plant.get("jelly_risk_curve", 1.0)))
		var accumulated := maxf(0.0, float(plant.get("jelly_hazard_accumulated", 0.0)))
		var threshold := maxf(0.000001, float(plant.get("jelly_threshold", _stable_jelly_threshold(str(plant.get("individual_id", ""))))))
		var remaining_hazard := maxf(0.0, threshold - accumulated)
		var seconds_to_jelly := remaining_hazard / maxf(hazard_rate, 0.000000000001)
		if seconds_to_jelly <= eligible_seconds:
			var pre_eligible_seconds := elapsed - eligible_seconds
			seconds_grown = pre_eligible_seconds + seconds_to_jelly
			plant["jelly_hazard_accumulated"] = threshold
			plant["jelly_elapsed_seconds"] = maxf(0.0, float(plant.get("jelly_elapsed_seconds", 0.0))) + seconds_to_jelly
			plant["jellied"] = true
			plant["jellied_unix"] = eligible_start_unix + seconds_to_jelly
			became_jellied = true
		else:
			plant["jelly_hazard_accumulated"] = accumulated + hazard_rate * eligible_seconds
			plant["jelly_elapsed_seconds"] = maxf(0.0, float(plant.get("jelly_elapsed_seconds", 0.0))) + eligible_seconds

	plant["diameter_cm"] = diameter_before + growth_rate * seconds_grown
	if matures_within_interval and float(plant.get("jelly_eligible_since_unix", 0.0)) <= 0.0 and not tutorial and not bool(plant.get("jelly_immune", false)):
		plant["jelly_eligible_since_unix"] = previous_update + seconds_until_mature
	_refresh_timing_fields(plant, now_unix)
	_update_growth_state(plant)
	return {"changed": true, "became_jellied": became_jellied}


static func growth_rate_cm_per_second(plant: Dictionary) -> float:
	var scale := TUTORIAL_GROWTH_SCALE if bool(plant.get("tutorial", false)) else NORMAL_HABITAT_GROWTH_SCALE
	return MAIN_GROWTH_CM_PER_SECOND * maxf(0.05, float(plant.get("base_growth_rate", 1.0))) * scale


static func jelly_due_unix(plant: Dictionary, reference_unix: float = -1.0) -> float:
	var mature_diameter := float(plant.get("mature_diameter_cm", _stable_maturity_diameter(str(plant.get("individual_id", "")))))
	if bool(plant.get("jellied", false)) or bool(plant.get("jelly_immune", false)) or float(plant.get("diameter_cm", 0.0)) < mature_diameter:
		return 0.0
	var anchor := float(plant.get("last_updated_unix", 0.0)) if reference_unix < 0.0 else reference_unix
	var threshold := maxf(0.000001, float(plant.get("jelly_threshold", 0.000001)))
	var remaining := maxf(0.0, threshold - float(plant.get("jelly_hazard_accumulated", 0.0)))
	return anchor + remaining / maxf(jelly_hazard_rate_per_second(float(plant.get("jelly_risk_curve", 1.0))), 0.000000000001)


static func jelly_hazard_rate_per_second(risk_curve: float = 1.0) -> float:
	var probability := clampf(NORMAL_HABITAT_JELLY_PROBABILITY_PER_SECOND, 0.0, 0.999999)
	return -log(1.0 - probability) * maxf(0.05, risk_curve)


static func jelly_hazard_for_interval(start_diameter_cm: float, end_diameter_cm: float, elapsed_seconds: float, risk_curve: float = 1.0) -> float:
	# Used by deterministic tests and diagnostics. Natural habitat plants use
	# their per-individual maturity size. Use the start of the configured
	# maturity band here so this diagnostic never recreates a fixed 30 cm rule.
	var maturity := MATURITY_MIN_CM
	if elapsed_seconds <= 0.0 or maxf(start_diameter_cm, end_diameter_cm) < maturity:
		return 0.0
	var eligible_fraction := 1.0
	if start_diameter_cm < maturity and end_diameter_cm > start_diameter_cm:
		eligible_fraction = clampf((end_diameter_cm - maturity) / (end_diameter_cm - start_diameter_cm), 0.0, 1.0)
	return jelly_hazard_rate_per_second(risk_curve) * elapsed_seconds * eligible_fraction


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


static func _make_plant(species_id: String, tutorial: bool, diameter_cm: float, now_unix: float, plants: Array[Dictionary], rng: RandomNumberGenerator, safe_points: Array) -> Dictionary:
	var point := Vector2(810.0, 385.0) if tutorial else _choose_safe_point(plants, rng, safe_points)
	var threshold_roll := clampf(rng.randf(), 0.000001, 0.999999)
	var plant := {
		"individual_id": "wild_%d_%d_%d" % [int(now_unix), plants.size(), rng.randi_range(1000, 999999)],
		"species_id": species_id,
		"diameter_cm": diameter_cm,
		"growth_state": "growing",
		"jellied": false,
		"jellied_unix": 0.0,
		"jelly_immune": tutorial,
		"jelly_elapsed_seconds": 0.0,
		"jelly_hazard_accumulated": 0.0,
		"jelly_threshold": -log(1.0 - threshold_roll),
		"jelly_risk_curve": 1.0,
		"mature_diameter_cm": rng.randf_range(MATURITY_MIN_CM, MATURITY_MAX_CM),
		"jelly_eligible_since_unix": 0.0,
		"jelly_due_unix": 0.0,
		"tutorial": tutorial,
		"base_growth_rate": 1.0,
		"growth_rate_cm_per_second": 0.0,
		"spawned_unix": now_unix,
		"last_updated_unix": now_unix,
		"habitat_timing_version": TIMING_VERSION,
		"panorama_x": point.x,
		"panorama_y": point.y,
		"position_validated": true
	}
	_refresh_timing_fields(plant, now_unix)
	_update_growth_state(plant)
	return plant


static func _refresh_timing_fields(plant: Dictionary, reference_unix: float) -> void:
	plant["growth_rate_cm_per_second"] = growth_rate_cm_per_second(plant)
	plant["jelly_due_unix"] = jelly_due_unix(plant, reference_unix)


static func _choose_safe_point(plants: Array[Dictionary], rng: RandomNumberGenerator, safe_points: Array, ignored_plant: Dictionary = {}) -> Vector2:
	if safe_points.is_empty():
		return Vector2(640.0, 410.0)
	var best := Vector2(safe_points[0])
	var best_clearance_score := -99999.0
	var candidate_diameter := maxf(1.6, float(ignored_plant.get("diameter_cm", 4.0)))
	for _attempt in range(48):
		var anchor: Vector2 = safe_points[rng.randi_range(0, safe_points.size() - 1)]
		var candidate := Vector2(anchor.x + rng.randf_range(-24.0, 24.0), anchor.y + rng.randf_range(-9.0, 9.0))
		var clearance_score := 99999.0
		for other in plants:
			if other == ignored_plant:
				continue
			var other_point := Vector2(float(other.get("panorama_x", 0.0)), float(other.get("panorama_y", 0.0)))
			var other_diameter := maxf(1.6, float(other.get("diameter_cm", 4.0)))
			# Large plants reserve more panorama space.  This remains deliberately
			# soft so clusters still look natural instead of forming a rigid grid.
			var desired := 42.0 + minf(54.0, (candidate_diameter + other_diameter) * 0.72)
			clearance_score = minf(clearance_score, candidate.distance_to(other_point) - desired)
		if clearance_score > best_clearance_score:
			best = candidate
			best_clearance_score = clearance_score
		if clearance_score >= 0.0:
			break
	return best


static func _stable_jelly_threshold(individual_id: String) -> float:
	var stable_rng := RandomNumberGenerator.new()
	stable_rng.seed = absi(individual_id.hash()) + 1
	var roll := clampf(stable_rng.randf(), 0.000001, 0.999999)
	return -log(1.0 - roll)


static func _stable_maturity_diameter(individual_id: String) -> float:
	var stable_rng := RandomNumberGenerator.new()
	stable_rng.seed = absi((individual_id + ":maturity").hash()) + 1
	return stable_rng.randf_range(MATURITY_MIN_CM, MATURITY_MAX_CM)


static func _update_growth_state(plant: Dictionary) -> void:
	if bool(plant.get("jellied", false)):
		plant["growth_state"] = "jellied"
	elif float(plant.get("diameter_cm", 0.0)) >= float(plant.get("mature_diameter_cm", MATURITY_MAX_CM)):
		plant["growth_state"] = "mature"
	else:
		plant["growth_state"] = "growing"
