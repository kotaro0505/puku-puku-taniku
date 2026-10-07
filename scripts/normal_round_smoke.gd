extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled":false,"se_enabled":false})
	game._reset_progression_state()
	game._set_language("ja")
	game.endless_greenhouse.configure(true)
	game.opening_finished=true;game.opening_story_complete=true;game.intro_story_complete=true;game.opening_overlay.visible=false;game.opening_story_overlay.visible=false
	game.first_habitat_gift_claimed=true;game.initial_seed_stock_notice_complete=true;game.habitat_awakened=true;game.seed_shop_open=true
	game.habitat_tutorial_complete=true;game.mystery_items_acquired=true;game.mystery_catalog_tutorial_complete=true
	game.normal_play_tutorial_complete=true;game.puku_buyback_tutorial_complete=true;game.puku_gauge_intro_complete=true
	game.current_mode="greenhouse";game.puku_balance_units=999;game._apply_mode();game._update_play_ui()
	assert(game.play_open_button.visible and not game.play_open_button.disabled)
	assert(game.play_open_button.text=="パンダのお手伝いをする\n＋1ぷくコイン")
	game._open_play_modal();assert(not game.play_active and game.puku_balance_units==999 and game.shop_overlay.visible)
	game._close_shop()
	game.puku_balance_units=5000;game._update_play_ui()
	assert(game.play_open_button.visible and game.play_open_button.text=="たねをまく　1ぷくコイン")
	game._open_play_modal()
	assert(game.play_active and game.puku_balance_units==4000 and game.endless_economy_seed_cost_units==1000)
	assert(game.play_concurrent_target>=7 and game.play_concurrent_target<=10)
	assert(game.play_seeds_remaining==12-game.play_concurrent_target)
	await get_tree().create_timer(.42).timeout
	assert(game.plants.size()==game.play_concurrent_target and game.endless_economy_seed_count==game.play_concurrent_target)
	for settlement_index in range(12):
		assert(game.play_active and not game.plants.is_empty(),"round ended before all 12 seeds settled")
		var plant=game.plants[0];plant.jelly_checks_enabled=false;plant.jelly()
		await get_tree().process_frame
		if game.play_active and game.play_spawn_queue>0:
			game.play_spawn_timer=0.0;game._process(.01)
			await get_tree().create_timer(.32).timeout
	await get_tree().create_timer(.12).timeout
	assert(not game.play_active and game.result_overlay.visible)
	assert(game.endless_economy_seed_count==12 and game.endless_economy_jelly_count==12 and game.endless_economy_harvest_count==0)
	assert(game.puku_balance_units==4000 and game.endless_economy_seed_cost_units==1000 and game.endless_economy_harvest_reward_units==0)
	assert(game.result_count_label.text.contains("収穫　0株") and game.result_count_label.text.contains("ジュレ　12株"))
	assert(game.result_total_label.text.contains("-1.00ぷく") and game.result_total_label.text.contains("今回の収支　-1.00ぷく"))
	game._close_result();game._process(.2)
	assert(not game.play_active)
	game.queue_free()
	print("NORMAL_ROUND_SMOKE_OK seeds=12 concurrent=7-10 entry_cost=1 refill_cost=0 all_jelly_net=-1 result=true no_autostart=true")
	get_tree().quit()
