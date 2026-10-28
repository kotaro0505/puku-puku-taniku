class_name RewardedAdService
extends Node

signal reward_finished(reward_context: String, reward_earned: bool)
signal availability_changed(available: bool)
signal privacy_options_requirement_changed(required: bool)
signal privacy_options_form_finished(succeeded: bool)

const BuildProfileClass = preload("res://scripts/build_profile.gd")
const AdmobClass = preload("res://addons/AdmobPlugin/Admob.gd")
const AdmobConfigClass = preload("res://addons/AdmobPlugin/model/AdmobConfig.gd")
const MOBILE_ADS_CONFIG_PATH := "res://data/mobile-ads.cfg"
const MAX_AUTOMATIC_RETRIES := 3
const UNKNOWN_SDK_ERROR_CODE := -1
const AD_MODE_PRODUCTION := "production"
const AD_MODE_TEST := "test"
const TEST_REWARDED_ID := "ca-app-pub-3940256099942544/1712485313"
const AD_UNIT_PATTERN := "^ca-app-pub-[0-9]{16}/[0-9]{10}$"

enum State {
	INACTIVE,
	CONSENT,
	INITIALIZING,
	LOADING,
	READY,
	SHOWING,
	UNAVAILABLE,
}

var state := State.INACTIVE
var last_failure_reason := ""
var last_failure_stage := ""
var last_failure_code := UNKNOWN_SDK_ERROR_CODE
var _admob
var _initialized := false
var _retry_count := 0
var _retry_generation := 0
var _consent_update_attempt_count := 0
var _load_attempt_count := 0
var _showing_context := ""
var _completion_sent := false
var _privacy_options_required := false
var _privacy_options_form_open := false
var _ads_mode := "unknown"
var _plugin_detected := false
var _privacy_bridge_supported := false
var _initialization_callback_received := false
var _mobile_ads_config_failure_reason := ""


func _ready() -> void:
	call_deferred("_start_if_supported")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and is_inside_tree():
		call_deferred("_recover_after_resume")


func is_available() -> bool:
	return state == State.READY and _admob != null and _admob.is_rewarded_ad_loaded()


func is_preparing() -> bool:
	return state in [State.CONSENT, State.INITIALIZING, State.LOADING]


func is_privacy_options_required() -> bool:
	return _privacy_options_required


func is_privacy_options_form_open() -> bool:
	return _privacy_options_form_open


func diagnostic_snapshot() -> Dictionary:
	var can_request_ads := false
	var privacy_requirement := "UNSUPPORTED"
	if _admob != null and _privacy_bridge_supported:
		can_request_ads = _admob.can_request_ads()
		privacy_requirement = _admob.get_privacy_options_requirement_status()
	return {
		"state": _state_name(state),
		"ads_mode": _ads_mode,
		"plugin_detected": _plugin_detected,
		"privacy_bridge_supported": _privacy_bridge_supported,
		"privacy_requirement": privacy_requirement,
		"can_request_ads": can_request_ads,
		"initialization_callback_received": _initialization_callback_received,
		"initialized": _initialized,
		"consent_update_attempts": _consent_update_attempt_count,
		"load_attempts": _load_attempt_count,
		"retry_count": _retry_count,
		"failure_reason": last_failure_reason,
		"failure_stage": last_failure_stage,
		"failure_code": last_failure_code,
		"diagnostic_code": user_diagnostic_code(),
	}


func user_diagnostic_code() -> String:
	var stage_code := _diagnostic_stage_code(last_failure_reason, last_failure_stage)
	if not stage_code.is_empty():
		return "ADS-%s-%d" % [stage_code, last_failure_code] if last_failure_code >= 0 else "ADS-%s" % stage_code
	match state:
		State.CONSENT:
			return "ADS-WAIT-CONSENT"
		State.INITIALIZING:
			return "ADS-WAIT-INIT"
		State.LOADING:
			return "ADS-WAIT-LOAD"
		State.READY:
			return "ADS-READY"
		State.SHOWING:
			return "ADS-SHOWING"
		State.UNAVAILABLE:
			return "ADS-UNAVAILABLE"
		_:
			return "ADS-INACTIVE"


func present_privacy_options() -> bool:
	if (
		not _privacy_options_required
		or _privacy_options_form_open
		or _admob == null
		or not _admob.is_privacy_options_supported()
	):
		return false
	_privacy_options_form_open = true
	if not _admob.present_privacy_options_form():
		_privacy_options_form_open = false
		return false
	return true


func request_reward(reward_context: String) -> bool:
	if reward_context.is_empty() or not _showing_context.is_empty():
		return false
	if not is_available():
		_log_diagnostic("request_not_ready")
		_recover_after_request()
		reward_finished.emit(reward_context, false)
		return false
	_showing_context = reward_context
	_completion_sent = false
	_set_state(State.SHOWING)
	_admob.show_rewarded_ad()
	return true


func _start_if_supported() -> void:
	if BuildProfileClass.rewarded_ad_stub_enabled():
		return
	if not OS.has_feature("ios"):
		return
	if not BuildProfileClass.is_app_store_release() and not BuildProfileClass.ios_test_ads_enabled():
		return
	if not Engine.has_singleton("AdmobPlugin"):
		_mark_unavailable("admob_plugin_missing")
		return
	_plugin_detected = true
	var mobile_ads_config := _load_mobile_ads_config()
	if mobile_ads_config.is_empty():
		_mark_unavailable(
			_mobile_ads_config_failure_reason
			if not _mobile_ads_config_failure_reason.is_empty()
			else "mobile_ads_config_invalid"
		)
		return
	_ads_mode = str(mobile_ads_config.get("mode", ""))
	if _ads_mode not in [AD_MODE_PRODUCTION, AD_MODE_TEST]:
		_mark_unavailable("mobile_ads_mode_invalid")
		return
	if _ads_mode == AD_MODE_PRODUCTION and not BuildProfileClass.is_app_store_release():
		_mark_unavailable("production_ads_in_development")
		return
	var rewarded_id := str(mobile_ads_config.get("rewarded_ad_unit_id", ""))
	if rewarded_id.is_empty():
		_mark_unavailable("rewarded_id_missing")
		return

	_admob = AdmobClass.new()
	_admob.is_real = _ads_mode == AD_MODE_PRODUCTION
	_admob.max_ad_content_rating = AdmobConfigClass.ContentRating.G
	# The app has no verified age signal. UNSPECIFIED means unknown, not adult.
	# GMA 12.14.0/plugin v7.0 only expose the legacy TFCD/TFUA settings;
	# neither can represent the newer TEEN TFAT value.
	_admob.child_directed = AdmobConfigClass.TagForChildDirectedTreatment.UNSPECIFIED
	_admob.under_age_of_consent = AdmobConfigClass.TagForUnderAgeOfConsent.UNSPECIFIED
	_admob.first_party_id_enabled = false
	_admob.personalization_state = AdmobConfigClass.PersonalizationState.DISABLED
	_admob.att_enabled = false
	if _admob.is_real:
		_admob.ios_real_rewarded_id = rewarded_id
	else:
		_admob.ios_debug_rewarded_id = rewarded_id

	_admob.initialization_completed.connect(_on_initialization_completed)
	_admob.rewarded_ad_loaded.connect(_on_rewarded_ad_loaded)
	_admob.rewarded_ad_failed_to_load.connect(_on_rewarded_ad_failed_to_load)
	_admob.rewarded_ad_failed_to_show_full_screen_content.connect(_on_rewarded_ad_failed_to_show)
	_admob.rewarded_ad_dismissed_full_screen_content.connect(_on_rewarded_ad_dismissed)
	_admob.rewarded_ad_user_earned_reward.connect(_on_rewarded_ad_user_earned_reward)
	_admob.consent_info_updated.connect(_on_consent_info_updated)
	_admob.consent_info_update_failed.connect(_on_consent_info_update_failed)
	_admob.consent_form_loaded.connect(_on_consent_form_loaded)
	_admob.consent_form_failed_to_load.connect(_on_consent_form_failed_to_load)
	_admob.consent_form_dismissed.connect(_on_consent_form_dismissed)
	_admob.privacy_options_form_dismissed.connect(_on_privacy_options_form_dismissed)
	add_child(_admob)
	_privacy_bridge_supported = _admob.is_privacy_options_supported()
	_log_diagnostic("service_configured")

	if BuildProfileClass.is_app_store_release():
		_request_consent_update()
	else:
		_initialize_ads()


func _load_mobile_ads_config() -> Dictionary:
	_mobile_ads_config_failure_reason = ""
	if not FileAccess.file_exists(MOBILE_ADS_CONFIG_PATH):
		_mobile_ads_config_failure_reason = "mobile_ads_config_file_missing"
		return {}
	var config := ConfigFile.new()
	if config.load(MOBILE_ADS_CONFIG_PATH) != OK:
		_mobile_ads_config_failure_reason = "mobile_ads_config_load_failed"
		return {}
	var mode := str(config.get_value("ios", "mode", "")).strip_edges().to_lower()
	var rewarded_id := str(config.get_value("ios", "rewarded_ad_unit_id", "")).strip_edges()
	if mode not in [AD_MODE_PRODUCTION, AD_MODE_TEST]:
		_mobile_ads_config_failure_reason = "mobile_ads_mode_invalid"
		return {}
	if rewarded_id.is_empty():
		_mobile_ads_config_failure_reason = "rewarded_id_missing"
		return {}
	if not _valid_rewarded_id(rewarded_id, mode):
		_mobile_ads_config_failure_reason = "rewarded_id_invalid"
		return {}
	return {"mode": mode, "rewarded_ad_unit_id": rewarded_id}


func _valid_rewarded_id(rewarded_id: String, mode: String) -> bool:
	if mode == AD_MODE_TEST:
		return rewarded_id == TEST_REWARDED_ID
	if rewarded_id == TEST_REWARDED_ID:
		return false
	var regex := RegEx.new()
	if regex.compile(AD_UNIT_PATTERN) != OK:
		return false
	return regex.search(rewarded_id) != null


func _request_consent_update() -> void:
	if _admob == null:
		return
	_set_state(State.CONSENT)
	_consent_update_attempt_count += 1
	_log_diagnostic("consent_update_requested")
	_admob.update_consent_info()


func _on_consent_info_updated() -> void:
	if _admob == null:
		return
	_refresh_privacy_options_requirement()
	_log_diagnostic("consent_info_updated")
	if _admob.is_privacy_options_supported() and _admob.can_request_ads():
		_initialize_ads()
		return
	var consent = _admob.get_consent_status()
	var status: String = "UNKNOWN" if consent == null else str(consent.to_status_string())
	match status:
		"NOT_REQUIRED", "OBTAINED":
			_initialize_ads()
		"REQUIRED":
			_admob.load_consent_form()
		_:
			_retry_or_unavailable("consent_status_unknown", true)


func _on_consent_info_update_failed(error_data = null) -> void:
	_refresh_privacy_options_requirement()
	if _admob != null and _admob.is_privacy_options_supported() and _admob.can_request_ads():
		_record_failure("consent_update_failed_previous_consent_usable", "consent", error_data)
		_initialize_ads()
		return
	_retry_or_unavailable("consent_update_failed", true, error_data, "consent")


func _on_consent_form_loaded() -> void:
	if _admob != null:
		_admob.show_consent_form()


func _on_consent_form_failed_to_load(error_data = null) -> void:
	_retry_or_unavailable("consent_form_load_failed", true, error_data, "consent")


func _on_consent_form_dismissed(error_data = null) -> void:
	if _admob == null:
		return
	_refresh_privacy_options_requirement()
	if _admob.is_privacy_options_supported():
		if _admob.can_request_ads():
			_initialize_ads()
		else:
			_retry_or_unavailable("consent_disallows_ads", true, error_data, "consent")
		return
	var consent = _admob.get_consent_status()
	var status: String = "UNKNOWN" if consent == null else str(consent.to_status_string())
	if status in ["NOT_REQUIRED", "OBTAINED"]:
		_initialize_ads()
	else:
		_retry_or_unavailable("consent_not_obtained", true, error_data, "consent")


func _refresh_privacy_options_requirement() -> void:
	var required := false
	if _admob != null and _admob.is_privacy_options_supported():
		required = _admob.get_privacy_options_requirement_status() == "REQUIRED"
	if required == _privacy_options_required:
		return
	_privacy_options_required = required
	privacy_options_requirement_changed.emit(required)


func _on_privacy_options_form_dismissed(error_data = null) -> void:
	_privacy_options_form_open = false
	_refresh_privacy_options_requirement()
	var succeeded:bool=error_data == null or (error_data is Dictionary and error_data.is_empty())
	if succeeded and _admob != null and _admob.can_request_ads():
		# A consent change must affect the next request. Discard an ad loaded
		# under the previous choice and request a fresh one.
		if _initialized:
			if _admob.is_rewarded_ad_loaded():
				_admob.remove_rewarded_ad()
			_load_rewarded_ad()
		else:
			_initialize_ads()
	elif succeeded:
		if _admob != null and _initialized and _admob.is_rewarded_ad_loaded():
			_admob.remove_rewarded_ad()
		_mark_unavailable("consent_disallows_ads")
	else:
		_record_failure("privacy_options_form_failed", "privacy", error_data)
	privacy_options_form_finished.emit(succeeded)


func _initialize_ads() -> void:
	if _admob == null or _initialized:
		return
	_set_state(State.INITIALIZING)
	_admob.initialize()


func _on_initialization_completed(_status_data = null) -> void:
	_initialization_callback_received = true
	_initialized = true
	_retry_count = 0
	last_failure_reason = ""
	last_failure_stage = ""
	last_failure_code = UNKNOWN_SDK_ERROR_CODE
	_log_diagnostic("initialization_completed")
	_load_rewarded_ad()


func _load_rewarded_ad(allow_showing_transition := false) -> void:
	if _admob == null or not _initialized or state == State.LOADING:
		return
	if state == State.SHOWING and not allow_showing_transition:
		return
	_set_state(State.LOADING)
	_load_attempt_count += 1
	_log_diagnostic("rewarded_load_requested")
	_admob.load_rewarded_ad()


func _on_rewarded_ad_loaded(_ad_info = null, _response_info = null) -> void:
	if state != State.LOADING:
		return
	_retry_count = 0
	last_failure_reason = ""
	last_failure_stage = ""
	last_failure_code = UNKNOWN_SDK_ERROR_CODE
	_set_state(State.READY)
	_log_diagnostic("rewarded_loaded")


func _on_rewarded_ad_failed_to_load(_ad_info = null, error_data = null) -> void:
	if state != State.LOADING:
		return
	_retry_or_unavailable("rewarded_ad_load_failed", false, error_data, "load")


func _on_rewarded_ad_failed_to_show(_ad_info = null, error_data = null) -> void:
	if state != State.SHOWING or _showing_context.is_empty():
		return
	_retry_or_unavailable("rewarded_ad_show_failed", false, error_data, "show")
	_finish_show(false)
	# A failed presentation does not reliably produce a dismissal callback. Clear
	# the active request here so the retry can load a fresh ad and future requests
	# are not permanently blocked.
	_showing_context = ""
	_completion_sent = false


func _on_rewarded_ad_user_earned_reward(_ad_info = null, _reward_data = null) -> void:
	# The SDK can issue dismissal after the reward callback. Grant at the earned
	# callback, once, so an already-earned reward is not lost during dismissal.
	_finish_show(true)


func _on_rewarded_ad_dismissed(_ad_info = null) -> void:
	if state != State.SHOWING or _showing_context.is_empty():
		return
	_finish_show(false)
	_showing_context = ""
	_completion_sent = false
	# The dismissal callback is the terminal event for the displayed ad. Start a
	# fresh request while explicitly allowing this SHOWING -> LOADING transition;
	# a duplicate dismissal then sees LOADING and cannot create a second request.
	_load_rewarded_ad(true)


func _finish_show(reward_earned: bool) -> void:
	if _showing_context.is_empty() or _completion_sent:
		return
	_completion_sent = true
	reward_finished.emit(_showing_context, reward_earned)


func _retry_or_unavailable(reason: String, retry_consent: bool, error_data = null, stage := "") -> void:
	_record_failure(reason, stage, error_data)
	if _retry_count >= MAX_AUTOMATIC_RETRIES:
		_mark_unavailable(reason)
		return
	_retry_count += 1
	_retry_generation += 1
	var generation := _retry_generation
	_set_state(State.UNAVAILABLE)
	await get_tree().create_timer(float(1 << (_retry_count - 1))).timeout
	if generation != _retry_generation or _admob == null or not _showing_context.is_empty():
		return
	if retry_consent:
		_request_consent_update()
	else:
		_load_rewarded_ad()


func _recover_after_request() -> void:
	if _admob == null:
		return
	if state in [State.CONSENT, State.INITIALIZING, State.LOADING, State.SHOWING]:
		return
	_retry_generation += 1
	_retry_count = 0
	if not _initialized:
		if BuildProfileClass.is_app_store_release():
			_request_consent_update()
		else:
			_initialize_ads()
	elif not _admob.is_rewarded_ad_loaded():
		_load_rewarded_ad()


func _recover_after_resume() -> void:
	if state in [State.INACTIVE, State.READY, State.SHOWING]:
		return
	_log_diagnostic("application_resumed")
	_recover_after_request()


func _mark_unavailable(reason: String) -> void:
	if last_failure_reason != reason:
		_record_failure(reason, _diagnostic_stage_code(reason, "").to_lower())
	_set_state(State.UNAVAILABLE)


func _set_state(next_state: State) -> void:
	var was_available := state == State.READY
	var changed := state != next_state
	state = next_state
	var now_available := state == State.READY
	if was_available != now_available:
		availability_changed.emit(now_available)
	if changed:
		_log_diagnostic("state_changed")


func _record_failure(reason: String, stage: String, error_data = null) -> void:
	last_failure_reason = reason
	last_failure_stage = stage
	last_failure_code = _safe_error_code(error_data)
	_log_diagnostic("failure")


func _safe_error_code(error_data) -> int:
	if error_data == null:
		return UNKNOWN_SDK_ERROR_CODE
	if error_data is Dictionary:
		return int(error_data.get("code", UNKNOWN_SDK_ERROR_CODE))
	if error_data is Object and error_data.has_method("get_code"):
		return int(error_data.call("get_code"))
	return UNKNOWN_SDK_ERROR_CODE


func _diagnostic_stage_code(reason: String, stage: String) -> String:
	var normalized_stage := stage.to_upper()
	if normalized_stage in [
		"CONFIG",
		"CONFIG-MISSING",
		"CONFIG-PARSE",
		"CONFIG-MODE",
		"CONFIG-ID",
		"CONFIG-PROFILE",
		"PLUGIN",
		"CONSENT",
		"PRIVACY",
		"INIT",
		"LOAD",
		"SHOW",
	]:
		return normalized_stage
	if reason in ["admob_plugin_missing"]:
		return "PLUGIN"
	if reason in ["mobile_ads_config_file_missing", "mobile_ads_config_missing"]:
		return "CONFIG-MISSING"
	if reason == "mobile_ads_config_load_failed":
		return "CONFIG-PARSE"
	if reason == "mobile_ads_mode_invalid":
		return "CONFIG-MODE"
	if reason in ["rewarded_id_missing", "rewarded_id_invalid"]:
		return "CONFIG-ID"
	if reason == "production_ads_in_development":
		return "CONFIG-PROFILE"
	if reason == "mobile_ads_config_invalid":
		return "CONFIG"
	if reason.begins_with("consent_"):
		return "CONSENT"
	if reason.begins_with("privacy_"):
		return "PRIVACY"
	if reason.begins_with("rewarded_ad_load"):
		return "LOAD"
	if reason.begins_with("rewarded_ad_show"):
		return "SHOW"
	return ""


func _state_name(value: int) -> String:
	match value:
		State.INACTIVE:return "INACTIVE"
		State.CONSENT:return "CONSENT"
		State.INITIALIZING:return "INITIALIZING"
		State.LOADING:return "LOADING"
		State.READY:return "READY"
		State.SHOWING:return "SHOWING"
		State.UNAVAILABLE:return "UNAVAILABLE"
		_:return "UNKNOWN"


func _log_diagnostic(event: String) -> void:
	var snapshot := diagnostic_snapshot()
	snapshot["event"] = event
	# This deliberately contains only state enums, counters, booleans, and SDK
	# error codes. Never add ad unit IDs, response identifiers, messages, or user data.
	print("REWARDED_AD_DIAGNOSTIC ", JSON.stringify(snapshot))
