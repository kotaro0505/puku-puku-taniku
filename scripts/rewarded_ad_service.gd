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
var _admob
var _initialized := false
var _retry_count := 0
var _retry_generation := 0
var _showing_context := ""
var _completion_sent := false
var _privacy_options_required := false
var _privacy_options_form_open := false


func _ready() -> void:
	call_deferred("_start_if_supported")


func is_available() -> bool:
	return state == State.READY and _admob != null and _admob.is_rewarded_ad_loaded()


func is_privacy_options_required() -> bool:
	return _privacy_options_required


func is_privacy_options_form_open() -> bool:
	return _privacy_options_form_open


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

	_admob = AdmobClass.new()
	_admob.is_real = BuildProfileClass.is_app_store_release()
	_admob.max_ad_content_rating = AdmobConfigClass.ContentRating.G
	# The app has no verified age signal. UNSPECIFIED means unknown, not adult.
	# GMA 12.14.0/plugin v7.0 only expose the legacy TFCD/TFUA settings;
	# neither can represent the newer TEEN TFAT value.
	_admob.child_directed = AdmobConfigClass.TagForChildDirectedTreatment.UNSPECIFIED
	_admob.under_age_of_consent = AdmobConfigClass.TagForUnderAgeOfConsent.UNSPECIFIED
	_admob.first_party_id_enabled = false
	_admob.personalization_state = AdmobConfigClass.PersonalizationState.DISABLED
	_admob.att_enabled = false
	if BuildProfileClass.is_app_store_release():
		var rewarded_id := _load_production_rewarded_id()
		if rewarded_id.is_empty():
			_mark_unavailable("production_rewarded_id_missing")
			_admob = null
			return
		_admob.ios_real_rewarded_id = rewarded_id

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

	if BuildProfileClass.is_app_store_release():
		_request_consent_update()
	else:
		_initialize_ads()


func _load_production_rewarded_id() -> String:
	var config := ConfigFile.new()
	if config.load(MOBILE_ADS_CONFIG_PATH) != OK:
		return ""
	return str(config.get_value("ios", "rewarded_ad_unit_id", "")).strip_edges()


func _request_consent_update() -> void:
	if _admob == null:
		return
	_set_state(State.CONSENT)
	_admob.update_consent_info()


func _on_consent_info_updated() -> void:
	if _admob == null:
		return
	_refresh_privacy_options_requirement()
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


func _on_consent_info_update_failed(_error_data = null) -> void:
	_refresh_privacy_options_requirement()
	if _admob != null and _admob.is_privacy_options_supported() and _admob.can_request_ads():
		_initialize_ads()
		return
	_retry_or_unavailable("consent_update_failed", true)


func _on_consent_form_loaded() -> void:
	if _admob != null:
		_admob.show_consent_form()


func _on_consent_form_failed_to_load(_error_data = null) -> void:
	_retry_or_unavailable("consent_form_load_failed", true)


func _on_consent_form_dismissed(_error_data = null) -> void:
	if _admob == null:
		return
	_refresh_privacy_options_requirement()
	if _admob.is_privacy_options_supported():
		if _admob.can_request_ads():
			_initialize_ads()
		else:
			_retry_or_unavailable("consent_disallows_ads", true)
		return
	var consent = _admob.get_consent_status()
	var status: String = "UNKNOWN" if consent == null else str(consent.to_status_string())
	if status in ["NOT_REQUIRED", "OBTAINED"]:
		_initialize_ads()
	else:
		_retry_or_unavailable("consent_not_obtained", true)


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
		last_failure_reason = "privacy_options_form_failed"
	privacy_options_form_finished.emit(succeeded)


func _initialize_ads() -> void:
	if _admob == null or _initialized:
		return
	_set_state(State.INITIALIZING)
	_admob.initialize()


func _on_initialization_completed(_status_data = null) -> void:
	_initialized = true
	_retry_count = 0
	_load_rewarded_ad()


func _load_rewarded_ad() -> void:
	if _admob == null or not _initialized or state == State.SHOWING:
		return
	_set_state(State.LOADING)
	_admob.load_rewarded_ad()


func _on_rewarded_ad_loaded(_ad_info = null, _response_info = null) -> void:
	_retry_count = 0
	_set_state(State.READY)


func _on_rewarded_ad_failed_to_load(_ad_info = null, _error_data = null) -> void:
	_retry_or_unavailable("rewarded_ad_load_failed", false)


func _on_rewarded_ad_failed_to_show(_ad_info = null, _error_data = null) -> void:
	_finish_show(false)
	# A failed presentation does not reliably produce a dismissal callback. Clear
	# the active request here so the retry can load a fresh ad and future requests
	# are not permanently blocked.
	_showing_context = ""
	_completion_sent = false
	_retry_or_unavailable("rewarded_ad_show_failed", false)


func _on_rewarded_ad_user_earned_reward(_ad_info = null, _reward_data = null) -> void:
	# The SDK can issue dismissal after the reward callback. Grant at the earned
	# callback, once, so an already-earned reward is not lost during dismissal.
	_finish_show(true)


func _on_rewarded_ad_dismissed(_ad_info = null) -> void:
	_finish_show(false)
	_showing_context = ""
	_completion_sent = false
	_load_rewarded_ad()


func _finish_show(reward_earned: bool) -> void:
	if _showing_context.is_empty() or _completion_sent:
		return
	_completion_sent = true
	reward_finished.emit(_showing_context, reward_earned)


func _retry_or_unavailable(reason: String, retry_consent: bool) -> void:
	last_failure_reason = reason
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
	_retry_generation += 1
	_retry_count = 0
	if not _initialized:
		if BuildProfileClass.is_app_store_release():
			_request_consent_update()
		else:
			_initialize_ads()
	elif not _admob.is_rewarded_ad_loaded():
		_load_rewarded_ad()


func _mark_unavailable(reason: String) -> void:
	last_failure_reason = reason
	_set_state(State.UNAVAILABLE)


func _set_state(next_state: State) -> void:
	var was_available := state == State.READY
	state = next_state
	var now_available := state == State.READY
	if was_available != now_available:
		availability_changed.emit(now_available)
