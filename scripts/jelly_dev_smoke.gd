extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._open_jelly_dev()
	assert(game.jelly_dev_overlay.visible)
	assert(is_equal_approx(float(game.JellyBalanceClass.values.final_chance),.06))
	assert(is_equal_approx(float(game.JellyBalanceClass.values.cooldown),1.0))
	assert(is_equal_approx(float(game.JellyBalanceClass.values.safe_min),3.8) and is_equal_approx(float(game.JellyBalanceClass.values.safe_max),6.2))
	assert(is_equal_approx(game.JellyBalanceClass.weight_total(),100.0) and "100%" in game.jelly_dev_total_label.text)
	game._change_jelly_dev_value("ultra_weight",4.0);assert(is_equal_approx(float(game.JellyBalanceClass.values.ultra_weight),8.0) and "⚠" in game.jelly_dev_total_label.text)
	game._change_jelly_dev_value("long_weight",4.0);assert(is_equal_approx(float(game.JellyBalanceClass.values.long_weight),20.0))
	game._change_jelly_dev_value("growth_speed",.5);game._change_jelly_dev_value("rhythm_amplitude",.05)
	game._dev_spawn_50cm();assert(game.dev_jelly_test_active and game.plants.size()==4 and not game.play_active)
	var profiles:Dictionary={}
	for plant in game.plants:
		assert(absf(plant.diameter_cm-50.0)<.01 and plant.age>20.0 and plant.growth_time>0.0)
		assert(plant.jelly_safe_end_seconds>=3.8 and plant.jelly_safe_end_seconds<=6.2)
		profiles["%.3f/%.3f"%[plant.jelly_safe_end_seconds,plant.jelly_ramp_end_seconds]]=true
	assert(profiles.size()>1)
	game.last_jelly_claim_msec=-1000000000;assert(game._try_claim_jelly() and not game._try_claim_jelly())
	game._dev_reset_jelly();assert(not game.JellyBalanceClass.override_enabled and is_equal_approx(float(game.JellyBalanceClass.values.cooldown),0.0) and is_equal_approx(float(game.JellyBalanceClass.values.rhythm_amplitude),.10))
	print("JELLY_DEV_SMOKE_OK")
	get_tree().quit()
