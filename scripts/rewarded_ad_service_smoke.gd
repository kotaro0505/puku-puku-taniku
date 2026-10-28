extends Node

const ServiceClass = preload("res://scripts/rewarded_ad_service.gd")
const AdmobClass = preload("res://addons/AdmobPlugin/Admob.gd")
const LoadAdErrorClass = preload("res://addons/AdmobPlugin/model/LoadAdError.gd")
const LocalizerClass = preload("res://scripts/game_localizer.gd")

var completions: Array[Dictionary] = []
var privacy_requirements: Array[bool] = []
var privacy_results: Array[bool] = []


class FakePrivacyAdmob:
	extends RefCounted
	signal privacy_options_form_dismissed(error_data)
	var requirement_status := "REQUIRED"
	var ads_allowed := true
	var loaded := true
	var presentation_count := 0
	var removal_count := 0
	var load_count := 0
	var initialize_count := 0

	func is_privacy_options_supported() -> bool:return true
	func get_privacy_options_requirement_status() -> String:return requirement_status
	func can_request_ads() -> bool:return ads_allowed
	func present_privacy_options_form() -> bool:presentation_count+=1;return true
	func initialize() -> void:initialize_count+=1
	func is_rewarded_ad_loaded() -> bool:return loaded
	func remove_rewarded_ad() -> void:removal_count+=1;loaded=false
	func load_rewarded_ad() -> void:load_count+=1


class FakeNativePrivacyPlugin:
	extends RefCounted
	signal privacy_options_form_dismissed(error_data)
	var requirement_status := 0
	var presentation_count := 0
	var presentation_result := OK
	func get_privacy_options_requirement_status() -> int:return requirement_status
	func present_privacy_options_form() -> int:presentation_count+=1;return presentation_result
	func can_request_ads() -> bool:return true


class FakeRewardedAdmob:
	extends RefCounted
	var loaded := false
	var load_count := 0
	var show_count := 0

	func is_rewarded_ad_loaded() -> bool:return loaded
	func load_rewarded_ad() -> void:load_count+=1;loaded=false
	func show_rewarded_ad() -> void:assert(loaded);show_count+=1;loaded=false


func _ready() -> void:
	var service := ServiceClass.new()
	service.reward_finished.connect(_on_reward_finished)
	add_child(service)
	await get_tree().process_frame

	# Reward is emitted exactly once even if the SDK repeats the callback and
	# dismissal follows it.
	service.state = ServiceClass.State.SHOWING
	service._showing_context = "shop_seed_rescue"
	service._completion_sent = false
	service._on_rewarded_ad_user_earned_reward()
	service._on_rewarded_ad_user_earned_reward()
	service._on_rewarded_ad_dismissed()
	assert(completions.size() == 1)
	assert(completions[0].context == "shop_seed_rescue")
	assert(completions[0].earned)

	# Closing before the earned callback never grants the reward.
	service.state = ServiceClass.State.SHOWING
	service._showing_context = "shop_puku_rescue"
	service._completion_sent = false
	service._on_rewarded_ad_dismissed()
	assert(completions.size() == 2)
	assert(completions[1].context == "shop_puku_rescue")
	assert(not completions[1].earned)

	# A presentation failure may not be followed by dismissal. It must finish the
	# current request without reward and release the request lock for recovery.
	service.state = ServiceClass.State.SHOWING
	service._showing_context = "shop_seed_rescue"
	service._completion_sent = false
	service._on_rewarded_ad_failed_to_show()
	assert(completions.size() == 3)
	assert(completions[2].context == "shop_seed_rescue")
	assert(not completions[2].earned)
	assert(service._showing_context.is_empty() and not service._completion_sent)
	assert(service.user_diagnostic_code() == "ADS-SHOW")

	# A real rewarded-ad lifecycle must leave SHOWING before requesting the next
	# ad. Verify the initial load, tap spam while loading, five consecutive earned
	# rewards, early dismissal, load/show failure recovery, and duplicate terminal
	# callbacks without restarting the application.
	var cycle_service := ServiceClass.new()
	var fake_rewarded := FakeRewardedAdmob.new()
	var cycle_results: Array[Dictionary] = []
	cycle_service._admob = fake_rewarded
	cycle_service.reward_finished.connect(func(context: String, earned: bool) -> void:
		cycle_results.append({"context": context, "earned": earned})
	)
	add_child(cycle_service)
	cycle_service.state = ServiceClass.State.INITIALIZING
	cycle_service._on_initialization_completed()
	assert(cycle_service.state == ServiceClass.State.LOADING)
	assert(cycle_service.is_preparing())
	assert(cycle_service.user_diagnostic_code() == "ADS-WAIT-LOAD")
	assert(fake_rewarded.load_count == 1)
	for tap_index in range(3):
		assert(not cycle_service.request_reward("loading_tap_%d" % tap_index))
	assert(fake_rewarded.load_count == 1 and cycle_service.state == ServiceClass.State.LOADING)
	assert(cycle_results.size() == 3)
	fake_rewarded.loaded = true
	cycle_service._on_rewarded_ad_loaded()
	assert(cycle_service.state == ServiceClass.State.READY and cycle_service.is_available())

	for view_index in range(5):
		var result_count_before := cycle_results.size()
		var load_count_before := fake_rewarded.load_count
		var context := "repeat_%d" % view_index
		assert(cycle_service.request_reward(context))
		assert(cycle_service.state == ServiceClass.State.SHOWING)
		assert(fake_rewarded.show_count == view_index + 1)
		assert(not cycle_service.request_reward("already_showing"))
		assert(fake_rewarded.show_count == view_index + 1)
		cycle_service._on_rewarded_ad_user_earned_reward()
		cycle_service._on_rewarded_ad_user_earned_reward()
		assert(cycle_results.size() == result_count_before + 1)
		assert(cycle_results[-1].context == context and cycle_results[-1].earned)
		cycle_service._on_rewarded_ad_dismissed()
		assert(cycle_service.state == ServiceClass.State.LOADING)
		assert(fake_rewarded.load_count == load_count_before + 1)
		cycle_service._on_rewarded_ad_dismissed()
		assert(fake_rewarded.load_count == load_count_before + 1)
		assert(cycle_results.size() == result_count_before + 1)
		fake_rewarded.loaded = true
		cycle_service._on_rewarded_ad_loaded()
		assert(cycle_service.state == ServiceClass.State.READY)
	var earned_count := 0
	for result in cycle_results:
		if bool(result.earned):earned_count+=1
	assert(earned_count == 5 and fake_rewarded.show_count == 5)

	# Closing before earning finishes once without a reward, then immediately
	# starts one fresh load for the following view.
	var early_close_result_count := cycle_results.size()
	var early_close_load_count := fake_rewarded.load_count
	assert(cycle_service.request_reward("early_close"))
	cycle_service._on_rewarded_ad_dismissed()
	assert(cycle_results.size() == early_close_result_count + 1)
	assert(cycle_results[-1].context == "early_close" and not cycle_results[-1].earned)
	cycle_service._on_rewarded_ad_user_earned_reward()
	assert(cycle_results.size() == early_close_result_count + 1)
	assert(cycle_service.state == ServiceClass.State.LOADING)
	assert(fake_rewarded.load_count == early_close_load_count + 1)
	fake_rewarded.loaded = true
	cycle_service._on_rewarded_ad_loaded()

	# A failed load retries once, ignores a duplicate failure callback, and
	# returns to READY when that retry completes.
	fake_rewarded.loaded = false
	cycle_service._load_rewarded_ad()
	var failed_load_count := fake_rewarded.load_count
	cycle_service._on_rewarded_ad_failed_to_load(null, {"code": 1})
	assert(cycle_service.state == ServiceClass.State.UNAVAILABLE)
	assert(cycle_service._retry_count == 1)
	cycle_service._on_rewarded_ad_failed_to_load(null, {"code": 1})
	assert(cycle_service._retry_count == 1)
	await get_tree().create_timer(1.1).timeout
	assert(cycle_service.state == ServiceClass.State.LOADING)
	assert(fake_rewarded.load_count == failed_load_count + 1)
	fake_rewarded.loaded = true
	cycle_service._on_rewarded_ad_loaded()

	# A failed presentation emits one failure, clears the active context, and
	# retries once even if the SDK repeats failure/dismissal terminal callbacks.
	var show_failure_results := cycle_results.size()
	var show_failure_load_count := fake_rewarded.load_count
	assert(cycle_service.request_reward("show_failure"))
	cycle_service._on_rewarded_ad_failed_to_show(null, {"code": 2})
	assert(cycle_results.size() == show_failure_results + 1)
	assert(not cycle_results[-1].earned)
	assert(cycle_service._showing_context.is_empty())
	assert(cycle_service.state == ServiceClass.State.UNAVAILABLE)
	assert(cycle_service._retry_count == 1)
	cycle_service._on_rewarded_ad_failed_to_show(null, {"code": 2})
	cycle_service._on_rewarded_ad_dismissed()
	assert(cycle_service._retry_count == 1)
	assert(cycle_results.size() == show_failure_results + 1)
	await get_tree().create_timer(1.1).timeout
	assert(cycle_service.state == ServiceClass.State.LOADING)
	assert(fake_rewarded.load_count == show_failure_load_count + 1)
	fake_rewarded.loaded = true
	cycle_service._on_rewarded_ad_loaded()

	# Resuming while a reload is in flight cannot duplicate it. A new service
	# instance (the process-restart path) starts exactly one initial load.
	fake_rewarded.loaded = false
	cycle_service._load_rewarded_ad()
	var resume_load_count := fake_rewarded.load_count
	cycle_service._recover_after_resume()
	assert(fake_rewarded.load_count == resume_load_count)
	var restarted_service := ServiceClass.new()
	var restarted_fake := FakeRewardedAdmob.new()
	restarted_service._admob = restarted_fake
	add_child(restarted_service)
	restarted_service.state = ServiceClass.State.INITIALIZING
	restarted_service._on_initialization_completed()
	assert(restarted_service.state == ServiceClass.State.LOADING)
	assert(restarted_fake.load_count == 1)

	# Loading gets a preparation message rather than a misleading connection
	# error in all supported languages. The main UI selects it from service state.
	assert(LocalizerClass.text("ja", "ad_loading").contains("準備"))
	assert(LocalizerClass.text("hiragana", "ad_loading").contains("じゅんび"))
	assert(LocalizerClass.text("en", "ad_loading").contains("prepared"))
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(main_source.contains("rewarded_ad_service.is_preparing()"))

	# SDK diagnostics retain only a stable stage and numeric code. They never
	# include ad unit IDs, response identifiers, or localized SDK messages.
	service._record_failure("rewarded_ad_load_failed", "load", {"code": 1, "message": "must not be retained"})
	assert(service.user_diagnostic_code() == "ADS-LOAD-1")
	var diagnostic_json := JSON.stringify(service.diagnostic_snapshot())
	assert(not diagnostic_json.contains("must not be retained"))
	assert(not diagnostic_json.contains("ca-app-pub"))
	service._record_failure("rewarded_ad_load_failed", "load", LoadAdErrorClass.new({"code": 2, "message": "also discarded"}))
	assert(service.user_diagnostic_code() == "ADS-LOAD-2")
	assert(not JSON.stringify(service.diagnostic_snapshot()).contains("also discarded"))
	# Configuration failures are distinguishable without exposing either ad ID.
	for config_case in [
		["mobile_ads_config_file_missing", "ADS-CONFIG-MISSING"],
		["mobile_ads_config_load_failed", "ADS-CONFIG-PARSE"],
		["mobile_ads_mode_invalid", "ADS-CONFIG-MODE"],
		["rewarded_id_invalid", "ADS-CONFIG-ID"],
		["production_ads_in_development", "ADS-CONFIG-PROFILE"],
	]:
		service._mark_unavailable(str(config_case[0]))
		assert(service.user_diagnostic_code() == str(config_case[1]))
	assert(service._valid_rewarded_id(ServiceClass.TEST_REWARDED_ID, ServiceClass.AD_MODE_TEST))
	assert(not service._valid_rewarded_id(ServiceClass.TEST_REWARDED_ID, ServiceClass.AD_MODE_PRODUCTION))
	var fake_production_id := "ca-app-pub-" + "1".repeat(16) + "/" + "2".repeat(10)
	assert(service._valid_rewarded_id(fake_production_id, ServiceClass.AD_MODE_PRODUCTION))
	assert(not JSON.stringify(service.diagnostic_snapshot()).contains("ca-app-pub"))

	# Unsupported editor/Web or untouched upstream binaries must fail closed
	# instead of showing the wrong UMP form.
	var wrapper := AdmobClass.new()
	assert(not wrapper.is_privacy_options_supported())
	assert(wrapper.get_privacy_options_requirement_status() == "UNKNOWN")
	assert(not wrapper.can_request_ads())
	assert(not wrapper.present_privacy_options_form())
	var native := FakeNativePrivacyPlugin.new()
	wrapper._plugin_singleton = native
	assert(wrapper.is_privacy_options_supported())
	for status_case in [[0, "UNKNOWN"], [1, "REQUIRED"], [2, "NOT_REQUIRED"], [99, "UNKNOWN"]]:
		native.requirement_status = int(status_case[0])
		assert(wrapper.get_privacy_options_requirement_status() == str(status_case[1]))
	native.requirement_status = 1
	assert(wrapper.can_request_ads() and wrapper.present_privacy_options_form())
	assert(native.presentation_count == 1)
	native.presentation_result = FAILED
	assert(not wrapper.present_privacy_options_form())
	assert(native.presentation_count == 2)
	wrapper.free()

	# A compatible native bridge opts into the UI through capability detection.
	# A successful consent change discards the old loaded ad and loads
	# a fresh request without creating a reward callback.
	var fake := FakePrivacyAdmob.new()
	service._admob = fake
	service.privacy_options_requirement_changed.connect(_on_privacy_requirement_changed)
	service.privacy_options_form_finished.connect(_on_privacy_form_finished)
	fake.privacy_options_form_dismissed.connect(service._on_privacy_options_form_dismissed)
	service._refresh_privacy_options_requirement()
	assert(service.is_privacy_options_required())
	assert(privacy_requirements == [true])
	service._initialized = false
	service._on_consent_info_update_failed()
	assert(service.state == ServiceClass.State.INITIALIZING and fake.initialize_count == 1)
	service._initialized = true
	var reward_count_before_privacy := completions.size()
	assert(service.present_privacy_options())
	assert(service.is_privacy_options_form_open() and fake.presentation_count == 1)
	fake.privacy_options_form_dismissed.emit({})
	assert(not service.is_privacy_options_form_open())
	assert(fake.removal_count == 1 and fake.load_count == 1)
	assert(service.state == ServiceClass.State.LOADING)
	assert(privacy_results == [true])
	assert(completions.size() == reward_count_before_privacy)

	# If UMP says ads cannot be requested after a change, the service stays
	# unavailable and never fabricates a successful ad view.
	fake.ads_allowed = false
	fake.loaded = true
	assert(service.present_privacy_options())
	fake.privacy_options_form_dismissed.emit(null)
	assert(service.state == ServiceClass.State.UNAVAILABLE)
	assert(service.last_failure_reason == "consent_disallows_ads")
	assert(fake.removal_count == 2)
	assert(privacy_results == [true, true])
	assert(completions.size() == reward_count_before_privacy)

	fake.requirement_status = "NOT_REQUIRED"
	service._refresh_privacy_options_requirement()
	assert(not service.is_privacy_options_required())
	assert(privacy_requirements == [true, false])
	assert(not service.present_privacy_options())

	# Presentation errors close/re-enable the UI path but do not change consent,
	# reload an ad, or create a reward.
	fake.requirement_status = "REQUIRED"
	fake.ads_allowed = true
	service._refresh_privacy_options_requirement()
	var load_count_before_error := fake.load_count
	var removal_count_before_error := fake.removal_count
	assert(service.present_privacy_options())
	fake.privacy_options_form_dismissed.emit({"message": "presentation failed"})
	assert(not service.is_privacy_options_form_open())
	assert(service.last_failure_reason == "privacy_options_form_failed")
	assert(fake.load_count == load_count_before_error and fake.removal_count == removal_count_before_error)
	assert(privacy_results == [true, true, false])
	assert(completions.size() == reward_count_before_privacy)

	# A user tap while consent, initialization, or a load is already in flight
	# must not start a duplicate request. An unavailable service may start one
	# fresh recovery load, and an app resume uses that same guarded path.
	service._retry_generation += 1
	service._initialized = true
	fake.loaded = false
	service.state = ServiceClass.State.LOADING
	var load_count_before_guard := fake.load_count
	service._recover_after_request()
	assert(fake.load_count == load_count_before_guard)
	service.state = ServiceClass.State.UNAVAILABLE
	service._recover_after_resume()
	assert(fake.load_count == load_count_before_guard + 1)
	assert(service.state == ServiceClass.State.LOADING)

	print("REWARDED_AD_SERVICE_SMOKE_OK earned_once=true early_close_no_reward=true repeated_views=5 dismissal_reloads=true duplicate_terminal_guarded=true load_failure_recovers=true show_failure_recovers=true loading_message_specific=true privacy_capability_gated=true consent_change_reloads=true sanitized_diagnostics=true config_diagnostics_specific=true duplicate_load_guarded=true resume_recovers=true restart_reloads=true desktop_inactive=true")
	get_tree().quit()


func _on_reward_finished(reward_context: String, reward_earned: bool) -> void:
	completions.append({"context": reward_context, "earned": reward_earned})


func _on_privacy_requirement_changed(required: bool) -> void:
	privacy_requirements.append(required)


func _on_privacy_form_finished(succeeded: bool) -> void:
	privacy_results.append(succeeded)
