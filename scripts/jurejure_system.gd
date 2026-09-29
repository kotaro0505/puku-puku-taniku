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

const BATTLE_PLANTS_PER_SIDE := 12
const LOSS_TAKE_MIN_RATIO := 0.40
const LOSS_TAKE_MAX_RATIO := 0.80

const EXPLOITATION_DIALOG_PATTERNS := [
	[
		{"speaker":"mouse","text_key":"jurejure_exploit_mouse_treasure"},
		{"speaker":"peccary","text_key":"jurejure_exploit_peccary_more"},
	],
	[
		{"speaker":"skunk","text_key":"jurejure_exploit_skunk_price"},
		{"speaker":"mouse","text_key":"jurejure_exploit_mouse_no_rest"},
	],
	[
		{"speaker":"peccary","text_key":"jurejure_exploit_peccary_imagine"},
		{"speaker":"skunk","text_key":"jurejure_exploit_skunk_money"},
	],
]

const CRISIS_CONCERN_PATTERNS := [
	{"speaker":"panda","text_key":"habitat_exploit_concern_panda"},
	{"speaker":"armadillo","text_key":"habitat_exploit_concern_armadillo"},
	{"speaker":"girl","text_key":"habitat_exploit_concern_girl"},
]

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
		exploitation_started: bool,
		waiting_for_seed_pod_reward: bool
	) -> bool:
	return habitat_awakened \
		and returned_to_greenhouse \
		and (exploitation_started or not waiting_for_seed_pod_reward)


static func habitat_bgm_key(exploitation_started: bool, habitat_crisis_started: bool) -> String:
	# Exploitation owns the habitat's soundscape until the separate rain/crisis
	# phase begins. Keeping this decision here prevents screen-return paths from
	# drifting back to different interpretations of the same story phase.
	return "jurejure" if exploitation_started and not habitat_crisis_started else "habitat"


static func focus_yaw(current_yaw: float, target_position: Vector3) -> float:
	return current_yaw + wrapf(rad_to_deg(atan2(-target_position.x, -target_position.z)) - current_yaw, -180.0, 180.0)


static func choose_exploitation_dialog(last_index: int, rng: RandomNumberGenerator) -> Dictionary:
	if EXPLOITATION_DIALOG_PATTERNS.is_empty():
		return {"index": -1, "pages": []}
	var candidates: Array[int] = []
	for index in range(EXPLOITATION_DIALOG_PATTERNS.size()):
		if index != last_index or EXPLOITATION_DIALOG_PATTERNS.size() == 1:
			candidates.append(index)
	var chosen_index := candidates[rng.randi_range(0, candidates.size() - 1)]
	return {"index": chosen_index, "pages": EXPLOITATION_DIALOG_PATTERNS[chosen_index].duplicate(true)}


static func concern_for_visit(state: Dictionary, visit_id: int) -> Dictionary:
	if visit_id <= 0 or int(state.get("last_crisis_concern_visit", -1)) == visit_id:
		return {}
	# Keep normal visits light: one short reaction every third new visit.
	if visit_id % 3 != 0:
		return {}
	state["last_crisis_concern_visit"] = visit_id
	var pattern_index := posmod(int(visit_id / 3) - 1, CRISIS_CONCERN_PATTERNS.size())
	return CRISIS_CONCERN_PATTERNS[pattern_index].duplicate(true)


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
