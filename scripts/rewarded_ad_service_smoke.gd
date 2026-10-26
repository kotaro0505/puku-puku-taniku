extends Node

const ServiceClass = preload("res://scripts/rewarded_ad_service.gd")
const AdmobClass = preload("res://addons/AdmobPlugin/Admob.gd")

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
	func get_privacy_options_requirement_status() -> int:return requirement_status
	func present_privacy_options_form() -> void:presentation_count+=1
	func can_request_ads() -> bool:return true


func _ready() -> void:
	var service := ServiceClass.new()
	service.reward_finished.connect(_on_reward_finished)
	add_child(service)
	await get_tree().process_frame

	# Reward is emitted exactly once even if the SDK repeats the callback and
	# dismissal follows it.
	service._showing_context = "shop_seed_rescue"
	service._completion_sent = false
	service._on_rewarded_ad_user_earned_reward()
	service._on_rewarded_ad_user_earned_reward()
	service._on_rewarded_ad_dismissed()
	assert(completions.size() == 1)
	assert(completions[0].context == "shop_seed_rescue")
	assert(completions[0].earned)

	# Closing before the earned callback never grants the reward.
	service._showing_context = "shop_puku_rescue"
	service._completion_sent = false
	service._on_rewarded_ad_dismissed()
	assert(completions.size() == 2)
	assert(completions[1].context == "shop_puku_rescue")
	assert(not completions[1].earned)

	# A presentation failure may not be followed by dismissal. It must finish the
	# current request without reward and release the request lock for recovery.
	service._showing_context = "shop_seed_rescue"
	service._completion_sent = false
	service._on_rewarded_ad_failed_to_show()
	assert(completions.size() == 3)
	assert(completions[2].context == "shop_seed_rescue")
	assert(not completions[2].earned)
	assert(service._showing_context.is_empty() and not service._completion_sent)

	# The vendored native v7.0 plugin does not expose Google's privacy-options
	# APIs. The wrapper must fail closed instead of showing the wrong UMP form.
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
	wrapper.free()

	# A future compatible native bridge can opt into the UI through capability
	# detection. A successful consent change discards the old loaded ad and loads
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

	print("REWARDED_AD_SERVICE_SMOKE_OK earned_once=true early_close_no_reward=true show_failure_recovers=true privacy_capability_gated=true consent_change_reloads=true desktop_inactive=true")
	get_tree().quit()


func _on_reward_finished(reward_context: String, reward_earned: bool) -> void:
	completions.append({"context": reward_context, "earned": reward_earned})


func _on_privacy_requirement_changed(required: bool) -> void:
	privacy_requirements.append(required)


func _on_privacy_form_finished(succeeded: bool) -> void:
	privacy_results.append(succeeded)
