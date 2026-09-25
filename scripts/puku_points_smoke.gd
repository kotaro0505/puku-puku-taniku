extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.mystery_items_acquired=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.habitat_tutorial_complete=true;game.puku_gauge_intro_complete=true;game.total_play_count=3
	_test_thresholds(game)
	await _test_animated_queue(game)
	_test_harvest_integration(game)
	_test_catalog_auto_record(game)
	_test_save_and_legacy_load(game)
	game._reset_progression_state();game.queue_free()
	print("PUKU_POINTS_SMOKE_OK gauge_target=600 reward=seed1+puku3 catalog=auto animation=queued legacy_yen=ignored")
	get_tree().quit()

func _test_thresholds(game)->void:
	assert(is_equal_approx(game.PUKU_GAUGE_TARGET_CM,600.0))
	game.puku_gauge_cm=0.0;game.puku_points=0;game.normal_seed_bags=0
	game._update_puku_ui();assert(not game.puku_gauge_glow.visible)
	game.puku_gauge_cm=60.0;game._update_puku_ui();var low_alpha:float=game.puku_gauge_glow.self_modulate.a;var low_shadow:int=game.puku_gauge_glow_style.shadow_size
	game.puku_gauge_cm=540.0;game._update_puku_ui();assert(game.puku_gauge_glow.visible and game.puku_gauge_glow.self_modulate.a>low_alpha and game.puku_gauge_glow_style.shadow_size>low_shadow and game.puku_gauge_glow_style.shadow_color.b>game.puku_gauge_glow_style.shadow_color.r and game.puku_gauge_glow_style.bg_color.a==0.0 and game.puku_gauge_fill_style.bg_color.b>game.puku_gauge_fill_style.bg_color.r and game.puku_gauge_glow.size.x<game.puku_gauge_meter.size.x and game.puku_gauge_glow_tween!=null)
	game.puku_gauge_cm=0.0;game.puku_points=0;game._update_puku_ui()
	assert(game.add_puku_gauge_cm(599.0,false,false)==0 and is_equal_approx(game.puku_gauge_cm,599.0) and game.puku_points==0 and game.puku_gauge_label.text=="ぷくゲージ" and is_equal_approx(game.puku_gauge_meter.value,599.0) and not game.puku_gauge_meter.show_percentage)
	assert(game.add_puku_gauge_cm(1.0,false,false)==3 and is_zero_approx(game.puku_gauge_cm) and game.puku_points==3 and game.normal_seed_bags==1)
	var gauge_area:Control=game.puku_gauge_meter.get_parent().get_parent();assert(not gauge_area is PanelContainer and gauge_area.name=="PukuGaugeArea" and gauge_area.size.x>=150.0 and gauge_area.size.x<=160.0 and gauge_area.position.x<200.0 and gauge_area.visible and game.puku_gauge_meter.size.y<=10.0)
	game.puku_gauge_cm=580.0;game.puku_points=0;game.normal_seed_bags=0
	assert(game.add_puku_gauge_cm(50.0,false,false)==3 and is_equal_approx(game.puku_gauge_cm,30.0) and game.puku_points==3 and game.normal_seed_bags==1)
	game.puku_gauge_cm=0.0;game.puku_points=0;game.normal_seed_bags=0
	assert(game.add_puku_gauge_cm(1250.0,false,false)==6 and is_equal_approx(game.puku_gauge_cm,50.0) and game.puku_points==6 and game.normal_seed_bags==2)
	game.puku_gauge_cm=0.0;game.puku_points=0;game.normal_seed_bags=0
	assert(game.add_puku_gauge_cm(2150.0,false,false)==9 and is_equal_approx(game.puku_gauge_cm,350.0) and game.puku_points==9 and game.normal_seed_bags==3 and game.puku_point_label.text=="ぷくコイン ×9" and is_equal_approx(game.puku_gauge_meter.value,350.0))

func _test_animated_queue(game)->void:
	game._cancel_puku_gauge_animations();game.puku_gauge_cm=580.0;game.puku_gauge_display_cm=580.0;game.puku_points=0;game.normal_seed_bags=0;game.puku_gauge_threshold_flash_count=0;game.puku_gauge_animation_speed_scale=.05;game._update_puku_ui()
	assert(game.add_puku_gauge_cm(50.0,false,true,Vector2(280,520))==3)
	assert(game.add_puku_gauge_cm(50.0,false,true,Vector2(300,520))==0)
	assert(is_equal_approx(game.puku_gauge_cm,80.0) and game.puku_points==3 and game.normal_seed_bags==1 and game.puku_points_display==0 and game.puku_point_label.text=="ぷくコイン ×0" and game.puku_gauge_animation_running and game.puku_gauge_animation_queue.size()>=1)
	await get_tree().create_timer(.35).timeout
	assert(not game.puku_gauge_animation_running and game.puku_gauge_animation_queue.is_empty() and is_equal_approx(game.puku_gauge_display_cm,80.0) and is_equal_approx(game.puku_gauge_meter.value,80.0) and game.puku_points_display==3 and game.puku_point_label.text=="ぷくコイン ×3" and game.puku_gauge_threshold_flash_count==1)
	game.puku_gauge_animation_speed_scale=1.0

func _test_harvest_integration(game)->void:
	game._cancel_puku_gauge_animations();game._clear_greenhouse_plants();game.puku_gauge_cm=590.0;game.puku_points=0;game.normal_seed_bags=0;game.play_harvest_cm_total=0.0;game.play_puku_earned_total=0;game.play_active=true;game.active_seed_type="normal"
	game._spawn_specific_plant("colorata");var plant=game.plants.back();plant.jelly_checks_enabled=false;plant.diameter_cm=12.5;plant.harvest()
	assert(is_equal_approx(game.puku_gauge_cm,2.5) and game.puku_points==3 and game.normal_seed_bags==1 and is_equal_approx(game.play_harvest_cm_total,12.5) and game.play_puku_earned_total==3)
	game._show_play_result();assert("収穫サイズ合計" in game.result_total_label.text and "ぷくゲージ +12.5cm" in game.result_total_label.text and "ぷくコイン +3" in game.result_total_label.text and not "¥" in game.result_total_label.text)
	game.result_overlay.visible=false;game.play_active=false;game._clear_greenhouse_plants();game._cancel_puku_gauge_animations()

func _test_catalog_auto_record(game)->void:
	var gummy:Dictionary=game._series_entry("gummy");game.unlocked_series.erase("gummy");game.current_encyclopedia_series_id="gummy";game.puku_points=5
	game._refresh_encyclopedia_header();assert(not game.encyclopedia_unlock_panel.visible and not game.encyclopedia_unlock_puku_button.visible and not game._catalog_purchase_enabled(gummy))
	game._acquire_current_catalog("puku");assert(not game._is_series_unlocked(gummy) and game.puku_points==5)
	var first_gummy_id:=str(game._series_species_entries("gummy")[0].get("species_id",""));assert(game._register_species_discovery(first_gummy_id,true));assert(game._is_series_unlocked(gummy) and game.puku_points==5)

func _test_save_and_legacy_load(game)->void:
	game.puku_gauge_cm=250.5;game.puku_points=4;game._save();var current=JSON.parse_string(FileAccess.get_file_as_string("user://records.json"));assert(current is Dictionary and not current.has("yen") and not current.has("money") and not current.has("coins"));game.puku_gauge_cm=0.0;game.puku_points=0;game._load_save()
	assert(is_equal_approx(game.puku_gauge_cm,250.5) and game.puku_points==4)
	current["progression_version"]=19;current.erase("mystery_items_acquired");current.erase("mystery_catalog_tutorial_complete");current["habitat_awakened"]=true;current["habitat_awakening_event_complete"]=true;current["habitat_tutorial_complete"]=true;current["puku_points"]=7;current["normal_seed_bags"]=4
	var previous_version:=FileAccess.open("user://records.json",FileAccess.WRITE);previous_version.store_string(JSON.stringify(current));previous_version.close()
	game.mystery_items_acquired=false;game.mystery_catalog_tutorial_complete=false;game.puku_points=0;game.normal_seed_bags=0;game._load_save()
	assert(game.mystery_items_acquired and game.mystery_catalog_tutorial_complete and game.puku_points==7 and game.normal_seed_bags==4)
	var legacy:=FileAccess.open("user://records.json",FileAccess.WRITE);legacy.store_string(JSON.stringify({"yen":321,"money":987,"discovered":{"colorata":true},"greenhouse_available":{"colorata":true}}));legacy.close()
	game.puku_gauge_cm=577.0;game.puku_points=9;game._load_save();assert(is_zero_approx(game.puku_gauge_cm) and game.puku_points==0)
