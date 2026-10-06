class_name EndlessGreenhouseExperiment
extends RefCounted

# The endless greenhouse is the formal default progression on every platform.
# The legacy experiment class/save names remain in place so existing installs
# keep their progress and the finite flow stays available for rollback tests.
const FEATURE_ENABLED := true
const DEFAULT_ENABLED := true
const NORMAL_SAVE_PATH := "user://records.json"
const EXPERIMENT_SAVE_PATH := "user://records_endless_experiment.json"
const VIRTUAL_BATCH_SIZE := 12
# Kept only for the existing 12-settlement progression hook. NEW carryover is
# updated by each harvest and consumed independently as seeds advance.
const DISCOVERY_SET_SIZE := 12
const DISCOVERY_CHANCE_ANCHORS := [
	Vector2(0.0, 0.0),
	Vector2(20.0, 0.005),
	Vector2(30.0, 0.01),
	Vector2(40.0, 0.02),
	Vector2(50.0, 0.05),
	Vector2(60.0, 0.10),
	Vector2(70.0, 0.18),
	Vector2(80.0, 0.30),
	Vector2(90.0, 0.45),
	Vector2(100.0, 0.65),
	Vector2(110.0, 0.82),
	Vector2(120.0, 0.95),
]
const DISCOVERY_CARRYOVER_DECAY := 0.4
const DISCOVERY_CARRYOVER_MIN_CHANCE := 0.01

var enabled := DEFAULT_ENABLED
var spawned_in_virtual_batch := 0
var discovery_settled_count := 0
var discovery_set_max_harvest_cm := 0.0
var discovery_cycle_best_cm := 0.0
var discovery_carryover_chance := 0.0
var forced_new_pending := false
var forced_new_active_species_id := ""
var forced_new_reserved_species_id := ""
var normal_save_path := NORMAL_SAVE_PATH
var experiment_save_path := EXPERIMENT_SAVE_PATH


func configure(requested: bool) -> void:
	enabled = FEATURE_ENABLED and requested
	spawned_in_virtual_batch = 0
	reset_discovery_state()


func active_save_path(normal_path_override := "", experiment_path_override := "") -> String:
	var normal_path := normal_save_path if normal_path_override.is_empty() else normal_path_override
	var endless_path := experiment_save_path if experiment_path_override.is_empty() else experiment_path_override
	return endless_path if enabled else normal_path


func prepare_save_namespace(normal_path_override := "", experiment_path_override := "") -> Dictionary:
	var normal_path := normal_save_path if normal_path_override.is_empty() else normal_path_override
	var endless_path := experiment_save_path if experiment_path_override.is_empty() else experiment_path_override
	var result := {
		"enabled": enabled,
		"active_path": active_save_path(normal_path, endless_path),
		"copied": false,
		"error": OK,
	}
	if not enabled or FileAccess.file_exists(endless_path) or not FileAccess.file_exists(normal_path):
		return result
	var source := FileAccess.open(normal_path, FileAccess.READ)
	if source == null:
		result["error"] = FileAccess.get_open_error()
		return result
	var bytes := source.get_buffer(source.get_length())
	source.close()
	var destination := FileAccess.open(endless_path, FileAccess.WRITE)
	if destination == null:
		result["error"] = FileAccess.get_open_error()
		return result
	destination.store_buffer(bytes)
	destination.close()
	result["copied"] = true
	return result


func set_save_paths_for_test(normal_path_value: String, experiment_path_value: String) -> void:
	if not OS.is_debug_build():
		return
	normal_save_path = normal_path_value
	experiment_save_path = experiment_path_value


func begin_play() -> void:
	spawned_in_virtual_batch = 0


func register_spawn() -> bool:
	if not enabled:
		return false
	spawned_in_virtual_batch += 1
	if spawned_in_virtual_batch < VIRTUAL_BATCH_SIZE:
		return false
	spawned_in_virtual_batch -= VIRTUAL_BATCH_SIZE
	return true


static func discovery_base_chance_for_cm(diameter_cm: float) -> float:
	var clamped_cm := maxf(0.0, diameter_cm)
	if clamped_cm >= DISCOVERY_CHANCE_ANCHORS[-1].x:
		return DISCOVERY_CHANCE_ANCHORS[-1].y
	for index in range(1, DISCOVERY_CHANCE_ANCHORS.size()):
		var upper: Vector2 = DISCOVERY_CHANCE_ANCHORS[index]
		if clamped_cm > upper.x:
			continue
		var lower: Vector2 = DISCOVERY_CHANCE_ANCHORS[index - 1]
		var weight := inverse_lerp(lower.x, upper.x, clamped_cm)
		return lerpf(lower.y, upper.y, weight)
	return DISCOVERY_CHANCE_ANCHORS[-1].y


func register_discovery_settlement(harvested: bool, diameter_cm: float = 0.0) -> Dictionary:
	var harvested_cm := maxf(0.0, diameter_cm) if harvested else 0.0
	var previous_cycle_best := discovery_cycle_best_cm
	var improved := harvested and harvested_cm > previous_cycle_best
	var base_chance := discovery_base_chance_for_cm(harvested_cm) if harvested else 0.0
	var carryover_before := discovery_carryover_chance
	var result := {
		"set_completed": false,
		"set_max_harvest_cm": discovery_set_max_harvest_cm,
		"cycle_best_before_cm": previous_cycle_best,
		"cycle_best_after_cm": previous_cycle_best,
		"improved_cycle_best": improved,
		"base_chance": base_chance,
		"new_chance": discovery_carryover_chance,
		"carryover_before": carryover_before,
		"carryover_after": discovery_carryover_chance,
		"roll_allowed": false,
	}
	if not enabled:
		result["base_chance"] = 0.0
		result["new_chance"] = 0.0
		result["roll_allowed"] = false
		return result
	discovery_settled_count += 1
	if harvested:
		discovery_set_max_harvest_cm = maxf(discovery_set_max_harvest_cm, harvested_cm)
		if improved:
			discovery_cycle_best_cm = harvested_cm
		discovery_carryover_chance = maxf(discovery_carryover_chance, base_chance)
	result["new_chance"] = discovery_carryover_chance
	result["carryover_after"] = discovery_carryover_chance
	result["roll_allowed"] = harvested and discovery_carryover_chance > 0.0 and not has_forced_new()
	result["cycle_best_after_cm"] = discovery_cycle_best_cm
	result["set_max_harvest_cm"] = discovery_set_max_harvest_cm
	if discovery_settled_count < DISCOVERY_SET_SIZE:
		return result

	var completed_set_max := discovery_set_max_harvest_cm
	discovery_settled_count = 0
	discovery_set_max_harvest_cm = 0.0
	result["set_completed"] = true
	result["set_max_harvest_cm"] = completed_set_max
	return result


func carryover_chance_for_next_seed() -> float:
	if not enabled:
		return 0.0
	return maxf(0.0, discovery_carryover_chance)


func take_carryover_chance_for_seed() -> float:
	if not enabled or has_forced_new():
		return 0.0
	var chance := carryover_chance_for_next_seed()
	if chance <= 0.0:
		discovery_carryover_chance = 0.0
		return 0.0
	var decayed := chance * DISCOVERY_CARRYOVER_DECAY
	discovery_carryover_chance = decayed if decayed >= DISCOVERY_CARRYOVER_MIN_CHANCE else 0.0
	return chance


func clear_discovery_carryover() -> void:
	discovery_carryover_chance = 0.0


func has_forced_new() -> bool:
	return forced_new_pending or not forced_new_active_species_id.is_empty()


func queue_forced_new() -> bool:
	if not enabled or has_forced_new():
		return false
	forced_new_pending = true
	forced_new_reserved_species_id = ""
	return true


func forced_new_candidate_hint() -> String:
	return forced_new_reserved_species_id if forced_new_pending else ""


func consume_forced_new(species_id: String) -> bool:
	if not enabled or not forced_new_pending or species_id.is_empty():
		return false
	forced_new_pending = false
	forced_new_reserved_species_id = ""
	forced_new_active_species_id = species_id
	return true


func cancel_forced_new_pending() -> void:
	forced_new_pending = false
	forced_new_reserved_species_id = ""


func fail_forced_new(species_id: String) -> bool:
	if species_id.is_empty() or forced_new_active_species_id != species_id:
		return false
	forced_new_active_species_id = ""
	forced_new_reserved_species_id = ""
	return true


func complete_forced_new() -> void:
	# NEW acquisition no longer defines the 12-settlement progression window.
	# Clear only the one-slot NEW reservation and legacy best marker.
	discovery_cycle_best_cm = 0.0
	forced_new_pending = false
	forced_new_active_species_id = ""
	forced_new_reserved_species_id = ""


func complete_discovery_cycle() -> void:
	discovery_settled_count = 0
	discovery_set_max_harvest_cm = 0.0
	clear_discovery_carryover()
	complete_forced_new()


func reset_discovery_state() -> void:
	complete_discovery_cycle()


func discovery_state_for_save() -> Dictionary:
	var saved_carryover_chance := discovery_carryover_chance if discovery_carryover_chance >= DISCOVERY_CARRYOVER_MIN_CHANCE else 0.0
	return {
		"discovery_settled_count": discovery_settled_count,
		"discovery_set_max_harvest_cm": discovery_set_max_harvest_cm,
		"discovery_cycle_best_cm": discovery_cycle_best_cm,
		"discovery_carryover_chance": saved_carryover_chance,
		"forced_new_pending": forced_new_pending,
		"forced_new_active_species_id": forced_new_active_species_id,
		"forced_new_reserved_species_id": forced_new_reserved_species_id,
	}


func restore_discovery_state(raw_state: Variant) -> void:
	reset_discovery_state()
	if not enabled or not raw_state is Dictionary:
		return
	var state: Dictionary = raw_state
	discovery_settled_count = clampi(int(state.get("discovery_settled_count", 0)), 0, DISCOVERY_SET_SIZE - 1)
	discovery_set_max_harvest_cm = maxf(0.0, float(state.get("discovery_set_max_harvest_cm", 0.0)))
	discovery_cycle_best_cm = maxf(0.0, float(state.get("discovery_cycle_best_cm", 0.0)))
	discovery_carryover_chance = clampf(float(state.get("discovery_carryover_chance", 0.0)), 0.0, DISCOVERY_CHANCE_ANCHORS[-1].y)
	if discovery_carryover_chance < DISCOVERY_CARRYOVER_MIN_CHANCE:
		discovery_carryover_chance = 0.0
	forced_new_pending = bool(state.get("forced_new_pending", false))
	forced_new_reserved_species_id = str(state.get("forced_new_reserved_species_id", ""))
	var saved_active_species_id := str(state.get("forced_new_active_species_id", ""))
	# Greenhouse Plant nodes are intentionally not persisted.  A forced NEW that
	# was alive at shutdown therefore returns to the one-slot pending queue with
	# the same candidate reserved, instead of disappearing or duplicating.
	if not saved_active_species_id.is_empty():
		forced_new_pending = true
		forced_new_reserved_species_id = saved_active_species_id
	forced_new_active_species_id = ""
	if not forced_new_pending:
		forced_new_reserved_species_id = ""


static func requested_by_runtime() -> bool:
	# Web query parameters and native command-line flags no longer gate the
	# production progression. Keeping this entry point lets old callers and the
	# legacy finite implementation coexist without a broad refactor.
	return FEATURE_ENABLED and DEFAULT_ENABLED
