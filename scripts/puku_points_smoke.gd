extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.mystery_items_acquired=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.habitat_tutorial_complete=true;game.puku_gauge_intro_complete=true;game.normal_play_tutorial_complete=true;game.seed_pod_gauge_discovery_complete=true;game.seed_pod_first_reward_seen=true;game.puku_buyback_tutorial_complete=true;game.total_play_count=3
	_test_seed_pod_thresholds(game)
	_test_gold_thresholds(game)
	await _test_animated_gold_queue(game)
	_test_harvest_integration(game)
	_test_catalog_auto_record(game)
	_test_save_and_legacy_load(game)
	game._reset_progression_state();game.queue_free()
	print("PUKU_POINTS_SMOKE_OK pod_target=750 reward=3x12seeds gold_target=500 reward=puku3 harvest_only=true migration=ratio")
	get_tree().quit()

func _test_seed_pod_thresholds(game)->void:
	assert(is_equal_approx(game.SEED_POD_GAUGE_TARGET_CM,750.0))
	assert(game.SEED_POD_GAUGE_REWARD_BAGS==3 and game.SEED_PACK_CONFIG.normal.count==12)
	game.puku_gauge_cm=0.0;game.puku_coin_gauge_cm=0.0;game.puku_points=0;game.normal_seed_bags=0;game._update_puku_ui()
	assert(game.add_seed_pod_gauge_cm(749.0,false,false)==0 and is_equal_approx(game.puku_gauge_cm,749.0) and game.normal_seed_bags==0 and game.puku_points==0)
	assert(game.add_seed_pod_gauge_cm(1.0,false,false)==3 and is_zero_approx(game.puku_gauge_cm) and game.normal_seed_bags==3 and game.puku_points==0)
	game.puku_gauge_cm=0.0;game.normal_seed_bags=0
	assert(game.add_seed_pod_gauge_cm(1600.0,false,false)==6 and is_equal_approx(game.puku_gauge_cm,100.0) and game.normal_seed_bags==6)
	assert(game.seed_pod_gauge_label.text=="さやゲージ" and is_equal_approx(game.seed_pod_gauge_meter.value,100.0) and not game.seed_pod_gauge_meter.show_percentage)
	assert(game.seed_pod_gauge_area.visible and game.seed_pod_gauge_area.position.y<game.puku_gauge_area.position.y)

func _test_gold_thresholds(game)->void:
	assert(is_equal_approx(game.PUKU_GAUGE_TARGET_CM,500.0))
	game.puku_coin_gauge_cm=0.0;game.puku_points=0;game._update_puku_ui();assert(not game.puku_gauge_glow.visible)
	game.puku_coin_gauge_cm=350.0;game._update_puku_ui();var green_color:Color=game.puku_gauge_fill_style.bg_color;assert(not game.puku_gauge_glow.visible)
	game.puku_coin_gauge_cm=355.0;game._update_puku_ui();var early_glow_alpha:float=game.puku_gauge_glow.self_modulate.a;assert(game.puku_gauge_glow.visible)
	game.puku_coin_gauge_cm=490.0;game._update_puku_ui();assert(game.puku_gauge_glow.self_modulate.a>early_glow_alpha and game.puku_gauge_glow_style.shadow_size>2 and game.puku_gauge_fill_style.bg_color.r>green_color.r and game.puku_gauge_fill_style.bg_color.g>game.puku_gauge_fill_style.bg_color.b)
	game.puku_coin_gauge_cm=0.0;game.puku_points=0;game.normal_seed_bags=4;game._update_puku_ui()
	assert(game.add_puku_coin_gauge_cm(499.0,false,false)==0 and is_equal_approx(game.puku_coin_gauge_cm,499.0) and game.puku_points==0)
	assert(game.add_puku_coin_gauge_cm(1.0,false,false)==3 and is_zero_approx(game.puku_coin_gauge_cm) and game.puku_points==3 and game.normal_seed_bags==4)
	game.puku_coin_gauge_cm=0.0;game.puku_points=0
	assert(game.add_puku_coin_gauge_cm(1200.0,false,false)==6 and is_equal_approx(game.puku_coin_gauge_cm,200.0) and game.puku_points==6 and game.normal_seed_bags==4)
	assert(game.puku_gauge_label.text=="ぷくゲージ" and not game.puku_gauge_meter.show_percentage)

func _test_animated_gold_queue(game)->void:
	game._cancel_puku_gauge_animations();game.puku_coin_gauge_cm=490.0;game.puku_gauge_display_cm=490.0;game.puku_points=0;game.puku_gauge_threshold_flash_count=0;game.puku_gauge_animation_speed_scale=.05;game._update_puku_ui()
	assert(game.add_puku_coin_gauge_cm(20.0,false,true,Vector2(280,520))==3)
	assert(is_equal_approx(game.puku_coin_gauge_cm,10.0) and game.puku_points==3 and game.puku_gauge_animation_running)
	await get_tree().create_timer(.35).timeout
	assert(not game.puku_gauge_animation_running and game.puku_gauge_animation_queue.is_empty() and is_equal_approx(game.puku_gauge_display_cm,10.0) and game.puku_points_display==3 and game.puku_gauge_threshold_flash_count==1)
	game.puku_gauge_animation_speed_scale=1.0

func _test_harvest_integration(game)->void:
	game._cancel_puku_gauge_animations();game._clear_greenhouse_plants();game.puku_gauge_cm=111.0;game.puku_coin_gauge_cm=490.0;game.puku_points=0;game.normal_seed_bags=4;game.play_harvest_cm_total=0.0;game.play_puku_earned_total=0;game.play_active=true;game.active_seed_type="normal"
	game._spawn_specific_plant("colorata");var plant=game.plants.back();plant.jelly_checks_enabled=false;plant.diameter_cm=12.5;plant.harvest()
	assert(is_equal_approx(game.puku_gauge_cm,111.0) and is_equal_approx(game.puku_coin_gauge_cm,2.5) and game.puku_points==3 and game.normal_seed_bags==4 and is_equal_approx(game.play_harvest_cm_total,12.5) and game.play_puku_earned_total==3)
	game._show_play_result();assert("収穫サイズ合計" in game.result_total_label.text and "ぷくゲージ +12.5cm" in game.result_total_label.text and "ぷくコイン +3" in game.result_total_label.text and not "¥" in game.result_total_label.text)
	game.result_overlay.visible=false;game.play_active=false;game._clear_greenhouse_plants();game._cancel_puku_gauge_animations()

func _test_catalog_auto_record(game)->void:
	var gummy:Dictionary=game._series_entry("gummy");game.unlocked_series.erase("gummy");game.current_encyclopedia_series_id="gummy";game.puku_points=5
	game._refresh_encyclopedia_header();assert(not game.encyclopedia_unlock_panel.visible and not game.encyclopedia_unlock_puku_button.visible and not game._catalog_purchase_enabled(gummy))
	game._acquire_current_catalog("puku");assert(not game._is_series_unlocked(gummy) and game.puku_points==5)
	var first_gummy_id:=str(game._series_species_entries("gummy")[0].get("species_id",""));assert(game._register_species_discovery(first_gummy_id,true));assert(game._is_series_unlocked(gummy) and game.puku_points==5)

func _test_save_and_legacy_load(game)->void:
	game.puku_gauge_cm=250.5;game.puku_coin_gauge_cm=125.25;game.puku_points=4;game._save();var current=JSON.parse_string(FileAccess.get_file_as_string("user://records.json"));assert(current is Dictionary and not current.has("yen") and not current.has("money") and not current.has("coins"));game.puku_gauge_cm=0.0;game.puku_coin_gauge_cm=0.0;game.puku_points=0;game._load_save()
	assert(is_equal_approx(game.puku_gauge_cm,250.5) and is_equal_approx(game.puku_coin_gauge_cm,125.25) and game.puku_points==4)
	current["progression_version"]=20;current["puku_gauge_cm"]=300.0;current.erase("puku_coin_gauge_cm");current.erase("normal_play_tutorial_complete");current.erase("seed_pod_gauge_discovery_complete");current.erase("seed_pod_first_reward_seen");current.erase("initial_seed_stock_notice_complete");current.erase("puku_buyback_tutorial_complete");current["habitat_awakened"]=true;current["habitat_awakening_event_complete"]=true;current["habitat_tutorial_complete"]=true;current["puku_points"]=7;current["normal_seed_bags"]=4
	var previous_version:=FileAccess.open("user://records.json",FileAccess.WRITE);previous_version.store_string(JSON.stringify(current));previous_version.close()
	game.mystery_items_acquired=false;game.puku_gauge_cm=0.0;game.puku_coin_gauge_cm=99.0;game.puku_points=0;game.normal_seed_bags=0;game._load_save()
	assert(game.mystery_items_acquired and game.normal_play_tutorial_complete and game.seed_pod_gauge_discovery_complete and game.puku_buyback_tutorial_complete)
	assert(is_equal_approx(game.puku_gauge_cm,375.0) and is_zero_approx(game.puku_coin_gauge_cm) and game.puku_points==7 and game.normal_seed_bags==4)
	var legacy:=FileAccess.open("user://records.json",FileAccess.WRITE);legacy.store_string(JSON.stringify({"yen":321,"money":987,"discovered":{"colorata":true},"greenhouse_available":{"colorata":true}}));legacy.close()
	game.puku_gauge_cm=577.0;game.puku_coin_gauge_cm=222.0;game.puku_points=9;game._load_save();assert(is_zero_approx(game.puku_gauge_cm) and is_zero_approx(game.puku_coin_gauge_cm) and game.puku_points==0)
