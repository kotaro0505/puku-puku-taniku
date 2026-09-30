class_name EndlessGreenhouseExperiment
extends RefCounted

# The experiment is compiled into the trial build, but remains opt-in.  Normal
# players use the finite greenhouse unless the explicit Web query/CLI switch is
# present.
const FEATURE_ENABLED := true
const NORMAL_SAVE_PATH := "user://records.json"
const EXPERIMENT_SAVE_PATH := "user://records_endless_experiment.json"
const VIRTUAL_BATCH_SIZE := 12
const DISCOVERY_SET_SIZE := 12
const DISCOVERY_BACKGROUND_MAX_CHANCE := 0.03
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

var enabled := false
var spawned_in_virtual_batch := 0
var discovery_settled_count := 0
var discovery_set_max_harvest_cm := 0.0
var discovery_cycle_best_cm := 0.0
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
	var result := {
		"set_completed": false,
		"set_max_harvest_cm": discovery_set_max_harvest_cm,
		"cycle_best_before_cm": discovery_cycle_best_cm,
		"cycle_best_after_cm": discovery_cycle_best_cm,
		"improved_cycle_best": false,
		"base_chance": 0.0,
		"new_chance": 0.0,
		"roll_allowed": false,
	}
	if not enabled:
		return result
	discovery_settled_count += 1
	if harvested:
		discovery_set_max_harvest_cm = maxf(discovery_set_max_harvest_cm, maxf(0.0, diameter_cm))
	result["set_max_harvest_cm"] = discovery_set_max_harvest_cm
	if discovery_settled_count < DISCOVERY_SET_SIZE:
		return result

	var completed_set_max := discovery_set_max_harvest_cm
	var previous_cycle_best := discovery_cycle_best_cm
	var improved := completed_set_max > previous_cycle_best
	var base_chance := discovery_base_chance_for_cm(completed_set_max)
	if improved:
		discovery_cycle_best_cm = completed_set_max
	var new_chance := base_chance if improved else minf(DISCOVERY_BACKGROUND_MAX_CHANCE, base_chance)
	discovery_settled_count = 0
	discovery_set_max_harvest_cm = 0.0
	return {
		"set_completed": true,
		"set_max_harvest_cm": completed_set_max,
		"cycle_best_before_cm": previous_cycle_best,
		"cycle_best_after_cm": discovery_cycle_best_cm,
		"improved_cycle_best": improved,
		"base_chance": base_chance,
		"new_chance": new_chance,
		"roll_allowed": not has_forced_new(),
	}


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


func complete_discovery_cycle() -> void:
	discovery_settled_count = 0
	discovery_set_max_harvest_cm = 0.0
	discovery_cycle_best_cm = 0.0
	forced_new_pending = false
	forced_new_active_species_id = ""
	forced_new_reserved_species_id = ""


func reset_discovery_state() -> void:
	complete_discovery_cycle()


func discovery_state_for_save() -> Dictionary:
	return {
		"discovery_settled_count": discovery_settled_count,
		"discovery_set_max_harvest_cm": discovery_set_max_harvest_cm,
		"discovery_cycle_best_cm": discovery_cycle_best_cm,
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
	if not FEATURE_ENABLED:
		return false
	if OS.has_feature("web"):
		var requested = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('endless')", true)
		return str(requested) == "1"
	return "--endless" in OS.get_cmdline_user_args()
