class_name JureJureSystem
extends RefCounted

# Legacy growth values remain readable so saves from the old timed-event
# implementation migrate without losing their story state. Act I no longer
# uses those values to soften the gang's behaviour.
const GROWTH_EARLY := 0
const GROWTH_MID := 1
const GROWTH_LATE := 2
const MID_STAGE_ORIGINAL_COUNT := 6
const LATE_STAGE_ORIGINAL_COUNT := 10

const BATTLE_PLANTS_PER_SIDE := 6
const LOSS_TAKE_MIN_RATIO := 0.40
const LOSS_TAKE_MAX_RATIO := 0.80

# Ground-tested panorama positions. A visit chooses one point and keeps it
# until the player leaves, so a habitat refresh cannot teleport the group.
const HABITAT_GROUP_POINTS := [
	Vector2(85, 414), Vector2(286, 420), Vector2(514, 410),
	Vector2(742, 424), Vector2(963, 408), Vector2(1180, 418)
]


static func growth_stage(original_count: int) -> int:
	if original_count >= LATE_STAGE_ORIGINAL_COUNT:
		return GROWTH_LATE
	if original_count >= MID_STAGE_ORIGINAL_COUNT:
		return GROWTH_MID
	return GROWTH_EARLY


static func should_be_present(
		habitat_awakened: bool,
		returned_to_greenhouse: bool,
		habitat_second_awakened: bool,
		waiting_for_seed_pod_reward: bool
	) -> bool:
	return habitat_awakened \
		and returned_to_greenhouse \
		and not habitat_second_awakened \
		and not waiting_for_seed_pod_reward


static func choose_visit_point(
		plants: Array[Dictionary],
		rng: RandomNumberGenerator
	) -> Vector2:
	var clear_points: Array[Vector2] = []
	for point in HABITAT_GROUP_POINTS:
		var clear := true
		for plant in plants:
			if bool(plant.get("jellied", false)):
				continue
			var plant_point := Vector2(
				float(plant.get("panorama_x", 640.0)),
				float(plant.get("panorama_y", 410.0))
			)
			var wrapped_dx := absf(point.x - plant_point.x)
			wrapped_dx = minf(wrapped_dx, 1280.0 - wrapped_dx)
			if wrapped_dx < 76.0 and absf(point.y - plant_point.y) < 42.0:
				clear = false
				break
		if clear:
			clear_points.append(point)
	var source: Array[Vector2] = clear_points
	if source.is_empty():
		for fallback_point in HABITAT_GROUP_POINTS:
			source.append(fallback_point)
	return source[rng.randi_range(0, source.size() - 1)]


static func loss_take_count(population_size: int, ratio: float) -> int:
	if population_size <= 0:
		return 0
	var safe_ratio := clampf(ratio, LOSS_TAKE_MIN_RATIO, LOSS_TAKE_MAX_RATIO)
	return clampi(ceili(float(population_size) * safe_ratio), 1, population_size)


static func choose_loss_ids(
		plants: Array[Dictionary],
		rng: RandomNumberGenerator,
		ratio: float
	) -> Array[String]:
	var candidates: Array[String] = []
	for plant in plants:
		if bool(plant.get("jellied", false)) or bool(plant.get("story_protected", false)):
			continue
		var individual_id := str(plant.get("individual_id", ""))
		if not individual_id.is_empty():
			candidates.append(individual_id)
	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = held
	return candidates.slice(0, loss_take_count(candidates.size(), ratio))
