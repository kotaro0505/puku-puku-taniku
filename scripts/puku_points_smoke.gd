extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game.endless_greenhouse.configure(false)
	game._reset_progression_state();game.intro_story_complete=true;game.mystery_items_acquired=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.habitat_tutorial_complete=true;game.puku_gauge_intro_complete=true;game.normal_play_tutorial_complete=true;game.seed_pod_gauge_discovery_complete=true;game.seed_pod_first_reward_seen=true;game.puku_buyback_tutorial_complete=true;game.total_play_count=3
	_test_seed_pod_thresholds(game)
	game.endless_greenhouse.configure(true)
	_test_fixed_point_and_harvest_curve(game)
	await _test_signed_balance_animation(game)
	await _test_endless_seed_cost_and_harvest(game)
	_test_catalog_auto_record(game)
	_test_save_and_legacy_load(game)
	await _test_panda_rescue(game)
	game._reset_progression_state();game.queue_free()
	print("PUKU_POINTS_SMOKE_OK unit=1/1000 seed_cost=.20 direct_harvest=true new_floor=.20 migration=points+legacy_gauge forest_cost=3 rescue=5")
	get_tree().quit()

func _test_seed_pod_thresholds(game)->void:
	# The finite-mode seed-pod gauge is independent of the new puku wallet.
	assert(is_equal_approx(game.SEED_POD_GAUGE_TARGET_CM,750.0))
	assert(game.SEED_POD_GAUGE_REWARD_BAGS==3 and game.SEED_PACK_CONFIG.normal.count==12)
	game.puku_gauge_cm=0.0;game.puku_balance_units=0;game.normal_seed_bags=0;game._update_puku_ui()
	assert(game.add_seed_pod_gauge_cm(749.0,false,false)==0 and is_equal_approx(game.puku_gauge_cm,749.0) and game.normal_seed_bags==0)
	assert(game.add_seed_pod_gauge_cm(1.0,false,false)==3 and is_zero_approx(game.puku_gauge_cm) and game.normal_seed_bags==3)
	game.puku_gauge_cm=0.0;game.normal_seed_bags=0
	assert(game.add_seed_pod_gauge_cm(1600.0,false,false)==6 and is_equal_approx(game.puku_gauge_cm,100.0) and game.normal_seed_bags==6)

func _test_fixed_point_and_harvest_curve(game)->void:
	assert(game.PUKU_UNITS_PER_PUKU==1000)
	assert(game.ENDLESS_NORMAL_SEED_COST_UNITS==200)
	assert(game.INITIAL_PUKU_CAPITAL_UNITS==5000 and game.PANDA_HELP_REWARD_UNITS==5000)
	for sample in [[0.0,0],[20.0,200],[30.0,360],[40.0,620],[50.0,1100],[60.0,1700],[70.0,2700],[80.0,4200],[90.0,6500],[100.0,9000],[110.0,12500],[120.0,17500],[130.0,23000],[140.0,30000],[150.0,38000],[160.0,46000]]:
		assert(game._harvest_puku_reward_units(float(sample[0]),false)==int(sample[1]))
	assert(game._harvest_puku_reward_units(25.0,false)==280)
	assert(game._harvest_puku_reward_units(8.0,false)==80)
	assert(game._harvest_puku_reward_units(8.0,true)==200)
	assert(game._harvest_puku_reward_units(50.0,true)==1100)
	game.puku_balance_units=100;assert(game._change_puku_balance(-200,"test",false,false)==-100 and game.puku_balance_units==0)
	assert(game._puku_whole_count(4300)==4 and game._puku_fraction_units(4300)==300)
	assert(game._format_puku_units(2700)=="2.70")

func _wait_for_puku_animation(game)->void:
	for _i in range(240):
		if not game.puku_gauge_animation_running and game.puku_gauge_animation_queue.is_empty():return
		await get_tree().process_frame
	assert(false,"puku balance animation timed out")

func _test_signed_balance_animation(game)->void:
	game._cancel_puku_gauge_animations();game.puku_balance_units=4300;game.puku_gauge_threshold_flash_count=0;game.puku_gauge_animation_speed_scale=.02;game._update_puku_ui()
	assert(game._change_puku_balance(400,"test_gain",false,true)==400)
	await _wait_for_puku_animation(game)
	assert(game.puku_balance_units==4700 and game.puku_points_display==4 and roundi(game.puku_gauge_display_units)==700)
	game._cancel_puku_gauge_animations();game.puku_balance_units=4000;game.puku_gauge_threshold_flash_count=0;game._update_puku_ui()
	assert(game._change_puku_balance(2400,"test_gain",false,true)==2400)
	await _wait_for_puku_animation(game)
	assert(game.puku_balance_units==6400 and game.puku_points_display==6 and roundi(game.puku_gauge_display_units)==400 and game.puku_gauge_threshold_flash_count==2)
	assert(game._change_puku_balance(-200,"test_spend",false,true)==-200)
	await _wait_for_puku_animation(game)
	assert(game.puku_balance_units==6200 and game.puku_points_display==6 and roundi(game.puku_gauge_display_units)==200)
	assert(game._change_puku_balance(-2000,"test_spend",false,true)==-2000)
	await _wait_for_puku_animation(game)
	assert(game.puku_balance_units==4200 and game.puku_points_display==4 and roundi(game.puku_gauge_display_units)==200 and game.puku_gauge_threshold_flash_count==4)
	game.puku_gauge_animation_speed_scale=1.0

func _test_endless_seed_cost_and_harvest(game)->void:
	game._cancel_puku_gauge_animations();game._clear_greenhouse_plants();game.puku_balance_units=1400;game.play_active=true;game.active_seed_type="normal";game.play_concurrent_target=7;game.play_seed_animations_pending=0;game.play_spawn_queue=0;game._reset_endless_economy_stats()
	for _i in range(7):assert(game._spawn_greenhouse_seed(true))
	assert(game.puku_balance_units==0 and game.endless_economy_seed_count==7 and game.endless_economy_seed_cost_units==1400)
	assert(not game._spawn_greenhouse_seed(true) and game.puku_balance_units==0)
	game.play_active=false;await get_tree().create_timer(.4).timeout;assert(game.play_seed_animations_pending==0 and game.plants.is_empty())
	# Use a fresh direct plant after verifying the seven paid sprouts.
	game.play_active=true;game._clear_greenhouse_plants();game.play_concurrent_target=0;game._spawn_specific_plant("colorata");var harvested=game.plants.back();harvested.jelly_checks_enabled=false;harvested.diameter_cm=100.0
	var preexisting_count:int=int(game._species_get_count("colorata"));game.species_get_counts["colorata"]=maxi(1,preexisting_count)
	harvested.harvest();await get_tree().process_frame
	assert(game.puku_balance_units==9000 and game.play_puku_reward_units_total==9000 and game.endless_economy_harvest_reward_units==9000)
	var panel:=game.effects_layer.find_child("HarvestResult",true,false) as PanelContainer
	assert(panel and (panel.find_child("PukuRewardGain",true,false) as Label).text=="+9.00ぷく")
	game._clear_greenhouse_plants();game.species_get_counts.erase("colorata");game.puku_balance_units=0;game._spawn_specific_plant("colorata");var new_plant=game.plants.back();new_plant.jelly_checks_enabled=false;new_plant.diameter_cm=8.0;new_plant.harvest();await get_tree().process_frame
	assert(game.puku_balance_units==200)
	# One recovered seed budget is enough to queue exactly one replacement.
	game._clear_greenhouse_plants();game.play_concurrent_target=7;game.play_seed_animations_pending=0;game.play_spawn_queue=0;game._queue_greenhouse_replacements();assert(game.play_spawn_queue==1)
	game.play_active=false;game._clear_greenhouse_plants();game._cancel_puku_gauge_animations()

func _test_catalog_auto_record(game)->void:
	var gummy:Dictionary=game._series_entry("gummy");game.unlocked_series.erase("gummy");game.current_encyclopedia_series_id="gummy";game.puku_balance_units=5500
	game._refresh_encyclopedia_header();assert(not game.encyclopedia_unlock_panel.visible and not game.encyclopedia_unlock_puku_button.visible and not game._catalog_purchase_enabled(gummy))
	game._acquire_current_catalog("puku");assert(not game._is_series_unlocked(gummy) and game.puku_balance_units==5500)
	var first_gummy_id:=str(game._series_species_entries("gummy")[0].get("species_id",""));assert(game._register_species_discovery(first_gummy_id,true));assert(game._is_series_unlocked(gummy) and game.puku_balance_units==5500)

func _test_save_and_legacy_load(game)->void:
	var save_path:String=str(game._active_save_path())
	game.puku_gauge_cm=250.5;game.puku_balance_units=4375;game._save();var current=JSON.parse_string(FileAccess.get_file_as_string(save_path));assert(current is Dictionary and int(current.get("puku_balance_units",-1))==4375);game.puku_gauge_cm=0.0;game.puku_balance_units=0;game._load_save()
	assert(is_equal_approx(game.puku_gauge_cm,250.5) and game.puku_balance_units==4375 and game.puku_points==4)
	# A legacy wallet keeps both whole coins and the old 500cm=>3 puku partial gauge.
	current.erase("puku_balance_units");current["puku_points"]=4;current["puku_coin_gauge_cm"]=125.0;current["puku_gauge_intro_complete"]=false;current["mystery_items_acquired"]=false;current["habitat_awakened"]=false;current["habitat_tutorial_started"]=false;current["habitat_tutorial_complete"]=false;current["habitat_unlocked"]=false;current["tutorial_steps"]={}
	var legacy_wallet:=FileAccess.open(save_path,FileAccess.WRITE);legacy_wallet.store_string(JSON.stringify(current));legacy_wallet.close();game.puku_balance_units=0;game._load_save()
	assert(game.puku_balance_units==4750)
	# Already-unlocked old saves receive the one-time minimum operating capital.
	current.erase("puku_balance_units");current["puku_points"]=1;current["puku_coin_gauge_cm"]=0.0;current["puku_gauge_intro_complete"]=true
	legacy_wallet=FileAccess.open(save_path,FileAccess.WRITE);legacy_wallet.store_string(JSON.stringify(current));legacy_wallet.close();game.puku_balance_units=0;game._load_save()
	assert(game.puku_balance_units==5000)
	game._save();var migrated=JSON.parse_string(FileAccess.get_file_as_string(save_path));assert(int(migrated.get("puku_balance_units",-1))==5000)

func _test_panda_rescue(game)->void:
	game.play_active=true;game.active_seed_type="normal";game.current_mode="greenhouse";game.puku_gauge_intro_complete=true;game.mystery_items_acquired=true;game.habitat_tutorial_complete=true;game.puku_balance_units=100
	assert(game._shop_puku_rescue_needed())
	game._request_rescue_reward_ad();await get_tree().create_timer(.8).timeout
	assert(game.puku_balance_units==5100 and not game.rescue_reward_in_progress)
	assert(game.FOREST_GACHA_SPIN_COST==3)
	game.play_active=false
