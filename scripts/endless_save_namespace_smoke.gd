extends Node

const EndlessClass = preload("res://scripts/endless_greenhouse_experiment.gd")
const NORMAL_PATH := "user://endless_namespace_normal_smoke.json"
const EXPERIMENT_PATH := "user://endless_namespace_experiment_smoke.json"


func _ready() -> void:
	assert(EndlessClass.DEFAULT_ENABLED)
	assert(EndlessClass.requested_by_runtime())
	var default_progression := EndlessClass.new()
	default_progression.configure(EndlessClass.requested_by_runtime())
	assert(default_progression.enabled)
	_remove_test_file(NORMAL_PATH)
	_remove_test_file(EXPERIMENT_PATH)
	var state_a := {
		"puku_points": 7,
		"bests": {"colorata": 42.5},
		"story_progression_state": {"phase": "A"},
	}
	_write_json(NORMAL_PATH, state_a)
	var normal_bytes_before := FileAccess.get_file_as_bytes(NORMAL_PATH)

	var endless := EndlessClass.new()
	endless.configure(true)
	var setup := endless.prepare_save_namespace(NORMAL_PATH, EXPERIMENT_PATH)
	assert(bool(setup.get("copied", false)))
	assert(str(setup.get("active_path", "")) == EXPERIMENT_PATH)
	assert(FileAccess.get_file_as_bytes(EXPERIMENT_PATH) == normal_bytes_before)

	var state_b := state_a.duplicate(true)
	state_b["puku_points"] = 99
	state_b["bests"]["colorata"] = 101.0
	state_b["story_progression_state"]["phase"] = "B"
	_write_json(endless.active_save_path(NORMAL_PATH, EXPERIMENT_PATH), state_b)
	assert(FileAccess.get_file_as_bytes(NORMAL_PATH) == normal_bytes_before)

	var normal := EndlessClass.new()
	normal.configure(false)
	assert(normal.active_save_path(NORMAL_PATH, EXPERIMENT_PATH) == NORMAL_PATH)
	var loaded_normal = JSON.parse_string(FileAccess.get_file_as_string(normal.active_save_path(NORMAL_PATH, EXPERIMENT_PATH)))
	assert(loaded_normal is Dictionary)
	assert(int(loaded_normal.get("puku_points", -1)) == 7)
	assert(is_equal_approx(float(loaded_normal.get("bests", {}).get("colorata", 0.0)), 42.5))
	assert(str(loaded_normal.get("story_progression_state", {}).get("phase", "")) == "A")

	# Existing experiment progress is never overwritten by another startup copy.
	var second_setup := endless.prepare_save_namespace(NORMAL_PATH, EXPERIMENT_PATH)
	assert(not bool(second_setup.get("copied", true)))
	var loaded_experiment = JSON.parse_string(FileAccess.get_file_as_string(EXPERIMENT_PATH))
	assert(int(loaded_experiment.get("puku_points", -1)) == 99)

	_remove_test_file(NORMAL_PATH)
	_remove_test_file(EXPERIMENT_PATH)
	print("ENDLESS_SAVE_NAMESPACE_SMOKE_OK default_without_flags=true normal_unchanged=true one_way_copy=true legacy_finite=true")
	get_tree().quit()


func _write_json(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(payload))
	file.close()


func _remove_test_file(path: String) -> void:
	if FileAccess.file_exists(path):
		assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
