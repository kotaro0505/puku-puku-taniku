extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.buyback_unlocked=true;game.total_play_count=3
	_test_thresholds(game)
	_test_harvest_integration(game)
	_test_catalog_purchase(game)
	_test_save_and_legacy_load(game)
	game._reset_progression_state();game.queue_free()
	print("PUKU_POINTS_SMOKE_OK gauge_target=1000 catalog_cost=3")
	get_tree().quit()

func _test_thresholds(game)->void:
	game.puku_gauge_cm=0.0;game.puku_points=0
	game._update_puku_ui();assert(not game.puku_gauge_glow.visible)
	game.puku_gauge_cm=100.0;game._update_puku_ui();var low_alpha:float=game.puku_gauge_glow.self_modulate.a;var low_shadow:int=game.puku_gauge_glow_style.shadow_size
	game.puku_gauge_cm=900.0;game._update_puku_ui();assert(game.puku_gauge_glow.visible and game.puku_gauge_glow.self_modulate.a>low_alpha and game.puku_gauge_glow_style.shadow_size>low_shadow and game.puku_gauge_glow_style.shadow_color.b>game.puku_gauge_glow_style.shadow_color.r and game.puku_gauge_glow_style.bg_color.a==0.0 and game.puku_gauge_fill_style.bg_color.b>game.puku_gauge_fill_style.bg_color.r and game.puku_gauge_glow.size.x<game.puku_gauge_meter.size.x and game.puku_gauge_glow_tween!=null)
	game.puku_gauge_cm=0.0;game._update_puku_ui()
	assert(game.add_puku_gauge_cm(999.0,false,false)==0 and is_equal_approx(game.puku_gauge_cm,999.0) and game.puku_points==0 and game.puku_gauge_label.text=="ぷくゲージ" and is_equal_approx(game.puku_gauge_meter.value,999.0) and not game.puku_gauge_meter.show_percentage)
	var gauge_area:Control=game.puku_gauge_meter.get_parent().get_parent();assert(not gauge_area is PanelContainer and gauge_area.name=="PukuGaugeArea" and gauge_area.size.x>=150.0 and gauge_area.size.x<=160.0 and gauge_area.position.x<200.0 and gauge_area.visible and game.puku_gauge_meter.size.y<=10.0)
	game.puku_gauge_cm=0.0;game.puku_points=0
	assert(game.add_puku_gauge_cm(1000.0,false,false)==1 and is_zero_approx(game.puku_gauge_cm) and game.puku_points==1)
	game.puku_gauge_cm=0.0;game.puku_points=0
	assert(game.add_puku_gauge_cm(1250.0,false,false)==1 and is_equal_approx(game.puku_gauge_cm,250.0) and game.puku_points==1)
	game.puku_gauge_cm=0.0;game.puku_points=0
	assert(game.add_puku_gauge_cm(2150.0,false,false)==2 and is_equal_approx(game.puku_gauge_cm,150.0) and game.puku_points==2 and game.puku_point_label.text=="ぷくコイン ×2" and is_equal_approx(game.puku_gauge_meter.value,150.0))
	game.puku_gauge_cm=999.0;game.puku_points=0
	assert(game.add_puku_gauge_cm(1.0,false,true)==1 and game.puku_gain_label.visible and game.puku_gain_label.text=="ぷくコイン +1")
	game.add_puku_points(2,false,false);assert(game.puku_points==3)

func _test_harvest_integration(game)->void:
	game._clear_greenhouse_plants();game.puku_gauge_cm=0.0;game.puku_points=0;game.play_active=true;game.active_seed_type="normal"
	game._spawn_specific_plant("colorata");var plant=game.plants.back();plant.jelly_checks_enabled=false;plant.diameter_cm=12.5;plant.harvest()
	assert(is_equal_approx(game.puku_gauge_cm,12.5) and game.puku_points==0)
	game.play_active=false;game._clear_greenhouse_plants()

func _test_catalog_purchase(game)->void:
	var gummy:Dictionary=game._series_entry("gummy");game.unlocked_series.erase("gummy");game.current_encyclopedia_series_id="gummy";game.puku_points=2;game.coins=10000;game.mystery_pod_count=10
	game._refresh_encyclopedia_header();assert(game.encyclopedia_unlock_panel.visible and game.encyclopedia_unlock_puku_button.disabled and "必要 3ぷくコイン" in game.encyclopedia_unlock_status.text)
	game.add_puku_points(1,false,false);game._refresh_encyclopedia_header();assert(not game.encyclopedia_unlock_puku_button.disabled)
	game._acquire_current_catalog("puku");assert(game._is_series_unlocked(gummy) and game.puku_points==0 and game.coins==10000 and game.mystery_pod_count==10)

func _test_save_and_legacy_load(game)->void:
	game.puku_gauge_cm=250.5;game.puku_points=4;game._save();game.puku_gauge_cm=0.0;game.puku_points=0;game._load_save()
	assert(is_equal_approx(game.puku_gauge_cm,250.5) and game.puku_points==4)
	var legacy:=FileAccess.open("user://records.json",FileAccess.WRITE);legacy.store_string(JSON.stringify({"yen":321,"discovered":{"colorata":true},"greenhouse_available":{"colorata":true}}));legacy.close()
	game.puku_gauge_cm=777.0;game.puku_points=9;game._load_save();assert(is_zero_approx(game.puku_gauge_cm) and game.puku_points==0 and game.coins==321)
