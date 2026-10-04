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
	await _test_round_entry_and_harvest(game)
	_test_catalog_auto_record(game)
	_test_save_and_legacy_load(game)
	await _test_panda_rescue(game)
	game._reset_progression_state();game.queue_free()
	print("PUKU_POINTS_SMOKE_OK unit=1/1000 round_cost=1.00 direct_harvest=true new_floor=.20 migration=points+legacy_gauge forest_cost=1 rescue=wallet_plus_1 combo=true fly_removed=true result_waits=true")
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
	assert(game.NORMAL_ROUND_COST_UNITS==1000 and game.FIRST_GET_MIN_REWARD_UNITS==200)
	assert(game.INITIAL_PUKU_CAPITAL_UNITS==5000)
	for sample in [[0.0,0],[20.0,50],[30.0,120],[40.0,220],[50.0,400],[60.0,650],[70.0,1050],[80.0,1650],[90.0,2500],[100.0,3750],[110.0,5600],[120.0,8400],[130.0,12000],[140.0,17000],[150.0,24000],[160.0,31000]]:
		assert(game._harvest_puku_reward_units(float(sample[0]),false)==int(sample[1]))
	assert(game._harvest_puku_reward_units(25.0,false)==85)
	assert(game._harvest_puku_reward_units(8.0,false)==20)
	assert(game._harvest_puku_reward_units(8.0,true)==200)
	assert(game._harvest_puku_reward_units(50.0,true)==400)
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
	assert(not game.puku_combo_label.visible and game.puku_gauge_combo_count==0)
	var combo_generation: int = game.puku_gauge_animation_generation
	game.puku_gauge_animation_speed_scale=.02
	await game._play_puku_balance_boundary(1,combo_generation)
	assert(game.puku_gauge_combo_count==1 and not game.puku_combo_label.visible)
	await game._play_puku_balance_boundary(1,combo_generation)
	assert(game.puku_combo_label.visible and game.puku_combo_label.text=="×2")
	await game._play_puku_balance_boundary(1,combo_generation)
	assert(game.puku_combo_label.visible and game.puku_combo_label.text=="×3")
	game._reset_puku_combo_display()
	game.puku_gauge_threshold_flash_count=2
	assert(game._change_puku_balance(-200,"test_spend",false,true)==-200)
	await _wait_for_puku_animation(game)
	assert(game.puku_balance_units==6200 and game.puku_points_display==6 and roundi(game.puku_gauge_display_units)==200)
	assert(game._change_puku_balance(-2000,"test_spend",false,true)==-2000)
	await _wait_for_puku_animation(game)
	assert(game.puku_balance_units==4200 and game.puku_points_display==4 and roundi(game.puku_gauge_display_units)==200 and game.puku_gauge_threshold_flash_count==4)
	game.puku_gauge_animation_speed_scale=1.0

func _test_round_entry_and_harvest(game)->void:
	game._cancel_puku_gauge_animations();game.puku_gauge_animation_speed_scale=.02;game._clear_greenhouse_plants();game.opening_finished=true;game.opening_overlay.visible=false;game.current_mode="greenhouse";game._apply_mode();game.first_habitat_gift_claimed=true;game.puku_balance_units=1400;game.normal_round_free_plays=0
	game._start_greenhouse_play("normal")
	assert(game.play_active and game.current_target_count==12 and game.play_concurrent_target>=7 and game.play_concurrent_target<=10)
	assert(game.puku_balance_units==400 and game.endless_economy_seed_cost_units==1000)
	assert(game.play_seeds_remaining==12-game.play_concurrent_target)
	await get_tree().create_timer(.4).timeout
	assert(game.endless_economy_seed_count==game.play_concurrent_target and game.puku_balance_units==400)
	game.play_active=false;game._clear_greenhouse_plants();game.play_seed_animations_pending=0;game.play_spawn_queue=0
	# Use a fresh direct plant after verifying the one-time round entry charge.
	game.puku_balance_units=0;game.play_active=true;game.active_seed_type="normal";game.play_seeds_remaining=0;game.play_concurrent_target=0;game._reset_endless_economy_stats();game._spawn_specific_plant("colorata");var harvested=game.plants.back();harvested.jelly_checks_enabled=false;harvested.diameter_cm=100.0
	var preexisting_count:int=int(game._species_get_count("colorata"));game.species_get_counts["colorata"]=maxi(1,preexisting_count)
	harvested.harvest();await get_tree().process_frame
	assert(game.puku_balance_units==3750 and game.play_puku_reward_units_total==3750 and game.endless_economy_harvest_reward_units==3750)
	var panel:=game.effects_layer.find_child("HarvestResult",true,false) as PanelContainer
	assert(panel and (panel.find_child("PukuRewardGain",true,false) as Label).text=="+3.75ぷく")
	assert(game.effects_layer.find_child("PukuBalanceFly",true,false)==null)
	assert(game.play_active and not game.result_overlay.visible and game._greenhouse_finish_block_reason()=="puku_gauge_animation")
	await _wait_for_puku_animation(game);await get_tree().process_frame;await get_tree().process_frame
	assert(not game.play_active and game.result_overlay.visible)
	game._close_result();await get_tree().process_frame
	game._clear_greenhouse_plants();game.species_get_counts.erase("colorata");game.puku_balance_units=0;game.play_active=true;game.active_seed_type="normal";game.play_seeds_remaining=0;game.play_concurrent_target=0;game._reset_endless_economy_stats();game._spawn_specific_plant("colorata");var new_plant=game.plants.back();new_plant.jelly_checks_enabled=false;new_plant.diameter_cm=8.0;new_plant.harvest();await get_tree().process_frame
	assert(game.puku_balance_units==200 and game._species_get_count("colorata")==0 and "colorata" in game.pending_round_new_species_ids)
	game.play_active=false;game._play_result_new_species_animations();await get_tree().create_timer(.62).timeout
	assert(game._species_get_count("colorata")==1 and "colorata" not in game.pending_round_new_species_ids)
	assert(game.species_get_overlay.visible and game.species_get_active_context=="round_result_new")
	game.species_get_overlay.visible=false;game._on_species_get_overlay_closed("round_result_new");await get_tree().process_frame
	game._clear_greenhouse_plants();game._cancel_puku_gauge_animations();game.puku_gauge_animation_speed_scale=1.0

func _test_catalog_auto_record(game)->void:
	var gummy:Dictionary=game._series_entry("gummy");game.unlocked_series.erase("gummy");game.current_encyclopedia_series_id="gummy";game.puku_balance_units=5500
	game._refresh_encyclopedia_header();assert(not game.encyclopedia_unlock_panel.visible and not game.encyclopedia_unlock_puku_button.visible and not game._catalog_purchase_enabled(gummy))
	game._acquire_current_catalog("puku");assert(not game._is_series_unlocked(gummy) and game.puku_balance_units==5500)
	var first_gummy_id:=str(game._series_species_entries("gummy")[0].get("species_id",""));assert(game._register_species_discovery(first_gummy_id,true));assert(game._is_series_unlocked(gummy) and game.puku_balance_units==5500)

func _test_save_and_legacy_load(game)->void:
	var save_path:String=str(game._active_save_path())
	game.puku_gauge_cm=250.5;game.puku_balance_units=4375;game.normal_round_free_plays=1;game._save();var current=JSON.parse_string(FileAccess.get_file_as_string(save_path));assert(current is Dictionary and int(current.get("puku_balance_units",-1))==4375 and int(current.get("normal_round_free_plays",0))==1);game.puku_gauge_cm=0.0;game.puku_balance_units=0;game.normal_round_free_plays=0;game._load_save()
	assert(is_equal_approx(game.puku_gauge_cm,250.5) and game.puku_balance_units==4375 and game.puku_points==4 and game.normal_round_free_plays==1)
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
	game.play_active=false;game.active_seed_type="normal";game.current_mode="greenhouse";game.first_habitat_gift_claimed=true;game.puku_gauge_intro_complete=true;game.mystery_items_acquired=true;game.mystery_catalog_tutorial_complete=true;game.initial_seed_stock_notice_complete=true;game.normal_play_tutorial_complete=true;game.habitat_awakened=true;game.habitat_tutorial_complete=true;game.seed_shop_open=true;game.puku_balance_units=100;game.normal_round_free_plays=0
	game.opening_finished=true;game.opening_overlay.visible=false;game.play_modal_open=false;game.result_overlay.visible=false;game.shop_overlay.visible=false;game.encyclopedia_overlay.visible=false;game.settings_overlay.visible=false;game.fusion_lab_ui.visible=false;game.species_get_overlay.visible=false;game.catalog_series_unlock_overlay.visible=false;game.forest_gacha_ui.visible=false;game.secret_gacha_ui.visible=false;game.arrangement_ui.visible=false
	assert(game._shop_puku_rescue_needed())
	game._update_play_ui()
	assert(game.play_open_button.visible and not game.play_open_button.disabled)
	assert(game.play_open_button.text=="パンダのお手伝いをする\n＋1ぷくコイン")
	game._open_play_modal();assert(game.shop_overlay.visible and game.shop_chatter_action_button.visible and not game.play_active)
	game._request_rescue_reward_ad();await get_tree().create_timer(.8).timeout
	assert(game.puku_balance_units==1100 and game.normal_round_free_plays==0 and not game.rescue_reward_in_progress and not game.play_active)
	game._close_shop();game._update_play_ui()
	assert(game.play_open_button.text=="たねをまく　1ぷく")
	game._start_greenhouse_play("normal");assert(game.play_active and game.normal_round_free_plays==0 and game.puku_balance_units==100 and game.endless_economy_seed_cost_units==1000)
	assert(game.FOREST_GACHA_SPIN_COST==1)
	game.play_active=false
