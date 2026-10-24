extends Node

const ServiceClass = preload("res://scripts/rewarded_ad_service.gd")

var completions: Array[Dictionary] = []


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

	print("REWARDED_AD_SERVICE_SMOKE_OK earned_once=true early_close_no_reward=true show_failure_recovers=true desktop_inactive=true")
	get_tree().quit()


func _on_reward_finished(reward_context: String, reward_earned: bool) -> void:
	completions.append({"context": reward_context, "earned": reward_earned})
