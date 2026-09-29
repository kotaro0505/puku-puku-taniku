class_name EndlessGreenhouseExperiment
extends RefCounted

# The experiment is compiled into the trial build, but remains opt-in.  Normal
# players use the finite greenhouse unless the explicit Web query/CLI switch is
# present.
const FEATURE_ENABLED := true
const NORMAL_SAVE_PATH := "user://records.json"
const EXPERIMENT_SAVE_PATH := "user://records_endless_experiment.json"
const VIRTUAL_BATCH_SIZE := 12

var enabled := false
var spawned_in_virtual_batch := 0
var normal_save_path := NORMAL_SAVE_PATH
var experiment_save_path := EXPERIMENT_SAVE_PATH


func configure(requested: bool) -> void:
	enabled = FEATURE_ENABLED and requested
	spawned_in_virtual_batch = 0


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


static func requested_by_runtime() -> bool:
	if not FEATURE_ENABLED:
		return false
	if OS.has_feature("web"):
		var requested = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('endless')", true)
		return str(requested) == "1"
	return "--endless" in OS.get_cmdline_user_args()
