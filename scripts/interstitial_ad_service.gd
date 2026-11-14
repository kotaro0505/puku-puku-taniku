class_name InterstitialAdService
extends Node

signal availability_changed(available: bool)
signal presentation_started
signal presentation_finished(presentation_context: String, displayed: bool)

enum State {
	INACTIVE,
	LOADING,
	READY,
	SHOWING,
	UNAVAILABLE,
}

var state := State.INACTIVE
var _admob
var _rewarded_service
var _active_context := ""
var _presentation_active := false
var _signals_connected := false
var _load_request_count := 0
var _show_request_count := 0
var _last_event := "created"
var _last_error_stage := ""
var _last_error_code := -1
var _last_error_domain := ""


func bind_rewarded_service(rewarded_service) -> void:
	_rewarded_service = rewarded_service
	_last_event = "waiting_for_gma"
	if rewarded_service == null:
		return
	if rewarded_service.has_signal("mobile_ads_initialized"):
		rewarded_service.mobile_ads_initialized.connect(_on_mobile_ads_initialized)
	if rewarded_service.has_signal("ad_request_permission_changed"):
		rewarded_service.ad_request_permission_changed.connect(_on_ad_request_permission_changed)
	if rewarded_service.has_method("mobile_ads_is_initialized") \
			and rewarded_service.mobile_ads_is_initialized():
		_on_mobile_ads_initialized(rewarded_service.shared_admob())


func configure_for_test(admob) -> void:
	_attach_admob(admob)


func is_available() -> bool:
	return (
		state == State.READY
		and _admob != null
		and _admob.is_interstitial_ad_loaded()
	)


func is_showing() -> bool:
	return state == State.SHOWING or _presentation_active


func try_present(presentation_context: String) -> bool:
	if presentation_context.is_empty() or not _active_context.is_empty():
		_last_event = "show_rejected_context"
		return false
	if _rewarded_service != null \
			and _rewarded_service.has_method("is_full_screen_presentation_active") \
			and _rewarded_service.is_full_screen_presentation_active():
		_last_event = "show_rejected_other_fullscreen"
		return false
	if not is_available():
		# Preload for a future eligible transition, but never queue this one.
		_last_event = "show_skipped_not_ready"
		_request_load()
		return false
	_active_context = presentation_context
	_set_state(State.SHOWING)
	_show_request_count += 1
	_last_event = "show_requested"
	_admob.show_interstitial_ad()
	return true


func diagnostic_snapshot() -> Dictionary:
	return {
		"state": State.keys()[state],
		"load_requests": _load_request_count,
		"show_requests": _show_request_count,
		"presentation_active": _presentation_active,
		"has_context": not _active_context.is_empty(),
		"available": is_available(),
		"admob_attached": _admob != null,
		"signals_connected": _signals_connected,
		"last_event": _last_event,
		"last_error_stage": _last_error_stage,
		"last_error_code": _last_error_code,
		"last_error_domain": _last_error_domain,
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and state == State.UNAVAILABLE:
		call_deferred("_request_load")


func _on_mobile_ads_initialized(admob) -> void:
	_attach_admob(admob)


func _attach_admob(admob) -> void:
	if admob == null:
		_last_event = "attach_failed_null"
		return
	if _admob != null and _admob != admob:
		_disconnect_admob_signals()
	_admob = admob
	_connect_admob_signals()
	_last_event = "gma_attached"
	_request_load()


func _connect_admob_signals() -> void:
	if _admob == null or _signals_connected:
		return
	_admob.interstitial_ad_loaded.connect(_on_interstitial_ad_loaded)
	_admob.interstitial_ad_failed_to_load.connect(_on_interstitial_ad_failed_to_load)
	_admob.interstitial_ad_showed_full_screen_content.connect(_on_interstitial_ad_showed)
	_admob.interstitial_ad_failed_to_show_full_screen_content.connect(_on_interstitial_ad_failed_to_show)
	_admob.interstitial_ad_dismissed_full_screen_content.connect(_on_interstitial_ad_dismissed)
	_signals_connected = true


func _disconnect_admob_signals() -> void:
	if _admob == null or not _signals_connected:
		return
	if _admob.interstitial_ad_loaded.is_connected(_on_interstitial_ad_loaded):
		_admob.interstitial_ad_loaded.disconnect(_on_interstitial_ad_loaded)
	if _admob.interstitial_ad_failed_to_load.is_connected(_on_interstitial_ad_failed_to_load):
		_admob.interstitial_ad_failed_to_load.disconnect(_on_interstitial_ad_failed_to_load)
	if _admob.interstitial_ad_showed_full_screen_content.is_connected(_on_interstitial_ad_showed):
		_admob.interstitial_ad_showed_full_screen_content.disconnect(_on_interstitial_ad_showed)
	if _admob.interstitial_ad_failed_to_show_full_screen_content.is_connected(_on_interstitial_ad_failed_to_show):
		_admob.interstitial_ad_failed_to_show_full_screen_content.disconnect(_on_interstitial_ad_failed_to_show)
	if _admob.interstitial_ad_dismissed_full_screen_content.is_connected(_on_interstitial_ad_dismissed):
		_admob.interstitial_ad_dismissed_full_screen_content.disconnect(_on_interstitial_ad_dismissed)
	_signals_connected = false


func _on_ad_request_permission_changed(can_request_ads: bool) -> void:
	if _admob == null or state == State.SHOWING:
		return
	_discard_loaded_ad()
	if can_request_ads:
		_last_event = "consent_allows_ads"
		_request_load()
	else:
		_last_event = "consent_blocks_ads"
		_set_state(State.UNAVAILABLE)


func _request_load() -> void:
	if _admob == null or state in [State.LOADING, State.SHOWING]:
		return
	if _admob.is_interstitial_ad_loaded():
		_last_event = "native_ad_already_loaded"
		_set_state(State.READY)
		return
	_set_state(State.LOADING)
	_load_request_count += 1
	_last_event = "load_requested"
	_admob.load_interstitial_ad()


func _on_interstitial_ad_loaded(_ad_info = null, _response_info = null) -> void:
	if state != State.LOADING:
		# A consent change can invalidate a request while it is in flight. Never
		# retain that late result for a later presentation.
		_discard_loaded_ad()
		return
	_clear_error()
	_last_event = "loaded"
	_set_state(State.READY)


func _on_interstitial_ad_failed_to_load(_ad_info = null, error_data = null) -> void:
	if state != State.LOADING:
		return
	_capture_error("load", error_data)
	_last_event = "load_failed"
	_set_state(State.UNAVAILABLE)


func _on_interstitial_ad_showed(_ad_info = null) -> void:
	if state != State.SHOWING or _active_context.is_empty() or _presentation_active:
		return
	_presentation_active = true
	_last_event = "showed"
	presentation_started.emit()


func _on_interstitial_ad_failed_to_show(_ad_info = null, error_data = null) -> void:
	if state != State.SHOWING or _active_context.is_empty():
		return
	var finished_context := _active_context
	_capture_error("show", error_data)
	_last_event = "show_failed"
	_end_presentation()
	_active_context = ""
	_discard_loaded_ad()
	_set_state(State.UNAVAILABLE)
	presentation_finished.emit(finished_context, false)
	call_deferred("_request_load")


func _on_interstitial_ad_dismissed(_ad_info = null) -> void:
	if state != State.SHOWING or _active_context.is_empty():
		return
	var finished_context := _active_context
	_end_presentation()
	_active_context = ""
	_clear_error()
	_last_event = "dismissed"
	# Interstitial objects are single-use. The wrapper is configured to evict the
	# displayed object, and this load prepares only a future transition.
	_set_state(State.UNAVAILABLE)
	presentation_finished.emit(finished_context, true)
	_request_load()


func _discard_loaded_ad() -> void:
	if _admob != null and _admob.is_interstitial_ad_loaded():
		_admob.remove_interstitial_ad()


func _end_presentation() -> void:
	if not _presentation_active:
		return
	_presentation_active = false


func _capture_error(stage: String, error_data) -> void:
	_last_error_stage = stage
	_last_error_code = -1
	_last_error_domain = ""
	if error_data == null:
		return
	if error_data is Dictionary:
		_last_error_code = int(error_data.get("code", -1))
		_last_error_domain = str(error_data.get("domain", ""))
		return
	if typeof(error_data) == TYPE_OBJECT and error_data.has_method("get_code"):
		_last_error_code = int(error_data.get_code())
	if typeof(error_data) == TYPE_OBJECT and error_data.has_method("get_domain"):
		_last_error_domain = str(error_data.get_domain())


func _clear_error() -> void:
	_last_error_stage = ""
	_last_error_code = -1
	_last_error_domain = ""


func _set_state(next_state: State) -> void:
	var was_available := state == State.READY
	state = next_state
	var now_available := state == State.READY
	if was_available != now_available:
		availability_changed.emit(now_available)
