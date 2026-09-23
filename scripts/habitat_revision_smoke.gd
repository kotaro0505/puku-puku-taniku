extends Node

const HabitatWildSystemClass=preload("res://scripts/habitat_wild_system.gd")

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game.opening_story_complete=true;game._finish_opening();game.audio_manager.apply_settings({"bgm_enabled":false,"se_enabled":false})
	game._reset_progression_state()
	_test_normal_seed_routes(game)
	_test_growth_and_jelly()
	_test_population_and_safe_positions(game)
	await _test_beacon_jelly_log_and_visuals(game)
	_test_legacy_population_migration(game)
	await _test_save_persistence_and_stale_cleanup(game)
	game._reset_progression_state();game.free();await get_tree().process_frame
	print("HABITAT_REVISION_SMOKE_OK growth=1/120000 safe_until=30 jelly=1/15000 terminal_jelly=true batch_removal=true beacon_device=true beacon_se=true unread_log=true log_persistence=true fixed_small_labels=true")
	get_tree().quit()

func _test_normal_seed_routes(game:Node)->void:
	assert(is_equal_approx(game.NORMAL_SEED_UNLOCKED_NEW_RATE,.03))
	assert(is_equal_approx(game.NORMAL_SEED_LOCKED_NEW_RATE,.01))
	game.habitat_second_awakened=true
	game.rng.seed=20260911
	var unlocked_choice:Dictionary=game._select_species_for_seed("normal",.02)
	var unlocked_id:=str(unlocked_choice.get("species_id",""))
	assert(not unlocked_id.is_empty() and game._species_is_in_unlocked_series(unlocked_id))
	assert(not bool(unlocked_choice.get("_deferred_series_get",false)))
	var locked_choice:Dictionary=game._select_species_for_seed("normal",.035)
	var locked_id:=str(locked_choice.get("species_id",""));var locked_series:String=game._series_id_for_species(locked_id)
	assert(not locked_id.is_empty() and not locked_series.is_empty())
	assert(bool(locked_choice.get("_deferred_series_get",false)))
	assert(not bool(game.unlocked_series.get(locked_series,false)))
	assert(game._register_deferred_seed_get(locked_id))
	assert(bool(game.forest_gacha_encountered.get(locked_id,false)))
	assert(not bool(game.discovered.get(locked_id,false)) and not bool(game.unlocked_series.get(locked_series,false)))
	var registered:Array[String]=game._unlock_series_and_register_encounters(locked_series)
	assert(locked_id in registered and bool(game.discovered.get(locked_id,false)))

func _test_growth_and_jelly()->void:
	assert(is_equal_approx(HabitatWildSystemClass.NORMAL_HABITAT_GROWTH_SCALE,1.0/120000.0))
	assert(is_equal_approx(HabitatWildSystemClass.NORMAL_HABITAT_JELLY_SCALE,1.0/15000.0))
	assert(is_equal_approx(HabitatWildSystemClass.NORMAL_HABITAT_JELLY_PROBABILITY_PER_SECOND,0.000004))
	var now:=200000.0
	var normal:=_plant("normal",10.0,1.08,now-120.0);normal.jelly_threshold=.000001
	var expected:=10.0+120.0*HabitatWildSystemClass.MAIN_GROWTH_CM_PER_SECOND*1.08*HabitatWildSystemClass.NORMAL_HABITAT_GROWTH_SCALE
	var normal_plants:Array[Dictionary]=[normal];HabitatWildSystemClass.advance_time(normal_plants,now)
	assert(normal_plants.size()==1 and is_equal_approx(float(normal.diameter_cm),expected) and not bool(normal.jellied) and is_zero_approx(float(normal.jelly_hazard_accumulated)))
	var offline:=_plant("offline",8.0,.92,now-7200.0)
	var offline_expected:=8.0+7200.0*HabitatWildSystemClass.MAIN_GROWTH_CM_PER_SECOND*.92*HabitatWildSystemClass.NORMAL_HABITAT_GROWTH_SCALE
	var offline_plants:Array[Dictionary]=[offline];HabitatWildSystemClass.advance_time(offline_plants,now)
	assert(is_equal_approx(float(offline.diameter_cm),offline_expected))
	var day_growth:=86400.0*HabitatWildSystemClass.MAIN_GROWTH_CM_PER_SECOND*HabitatWildSystemClass.NORMAL_HABITAT_GROWTH_SCALE
	assert(absf(day_growth-.98325)<.00001)
	var tutorial:=_plant("tutorial",29.8,1.0,now-3.0,true);tutorial.jelly_threshold=.000001
	var tutorial_plants:Array[Dictionary]=[tutorial];HabitatWildSystemClass.advance_time(tutorial_plants,now)
	assert(float(tutorial.diameter_cm)>=30.0 and not bool(tutorial.jellied) and HabitatWildSystemClass.can_harvest(tutorial))
	var crossing:=_plant("crossing",29.99,1.0,now-2000.0);crossing.jelly_threshold=999999.0
	var crossing_plants:Array[Dictionary]=[crossing];var crossing_events:=HabitatWildSystemClass.advance_time_with_events(crossing_plants,now)
	assert(str(crossing.individual_id) in crossing_events.ready and crossing_plants.size()==1 and float(crossing.harvest_ready_reached_unix)>now-2000.0 and float(crossing.harvest_ready_reached_unix)<now)
	var hazard_rate:=HabitatWildSystemClass.jelly_hazard_rate_per_second()
	var jelly_fast:=_plant("jelly_fast",30.0,1.0,now-300.0);jelly_fast.jelly_threshold=hazard_rate*60.0
	var jelly_slow:=_plant("jelly_slow",30.0,1.0,now-300.0);jelly_slow.jelly_threshold=hazard_rate*180.0
	var jelly_plants:Array[Dictionary]=[jelly_fast,jelly_slow];var jelly_events:=HabitatWildSystemClass.advance_time_with_events(jelly_plants,now)
	assert(jelly_plants.is_empty() and jelly_events.jellied.size()==2 and jelly_events.removed.size()==2 and jelly_events.jellied_details.size()==2)
	assert(bool(jelly_fast.jellied) and bool(jelly_slow.jellied) and float(jelly_fast.jellied_unix)<float(jelly_slow.jellied_unix))
	assert(is_zero_approx(HabitatWildSystemClass.jelly_hazard_for_interval(5.0,10.0,3600.0)))
	assert(HabitatWildSystemClass.jelly_hazard_for_interval(30.0,31.0,3600.0)>0.0)
	var stale:=_plant("already_jellied",42.0,1.0,now);stale.jellied=true
	var stale_plants:Array[Dictionary]=[stale];var stale_events:=HabitatWildSystemClass.advance_time_with_events(stale_plants,now)
	assert(stale_plants.is_empty() and stale_events.jellied.is_empty() and stale_events.removed==["already_jellied"])

func _test_beacon_jelly_log_and_visuals(game:Node)->void:
	game._reset_progression_state();game.opening_story_complete=true;game.intro_story_complete=true;game.first_colorata_confirmed=true;game.trio_originals_confirmed=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.habitat_arrival_started=true;game.habitat_awakened=true;game.habitat_awakening_event_complete=true;game.total_play_count=3;game.formal_play_count=1;game.habitat_tutorial_started=true;game.habitat_tutorial_complete=true;game.seed_shop_open=true;game.original_catalog_gifted=true;game.puku_gauge_intro_complete=true;game.panda_beacon_unlocked=true;game.panda_beacon_count=3;game.puku_points=10;game.current_mode="habitat";game._apply_mode();game._build_habitat_items(true)
	game._update_play_ui();assert(game.habitat_dev_open_button!=null and game.habitat_dev_open_button.visible)
	var wall_now:=Time.get_unix_time_from_system()
	for plant in game.habitat_wild_plants:
		plant.jellied=false;plant.jelly_threshold=999999.0;plant.jelly_hazard_accumulated=0.0;plant.last_updated_unix=wall_now;plant.spawned_unix=wall_now-3600.0
		game._refresh_habitat_growth_profile(plant)
	var target:Dictionary=game.habitat_wild_plants[0];target.diameter_cm=29.5;game._refresh_habitat_growth_profile(target)
	game.audio_manager.se_enabled=true
	game._install_panda_beacon(str(target.individual_id))
	var target_item:Dictionary=game._habitat_wild_item_by_id(str(target.individual_id));var installed_device=target_item.get("beacon_node")
	assert(bool(target.panda_beacon_installed) and game._panda_beacon_used_count()==1 and is_instance_valid(installed_device))
	assert(installed_device.name=="PandaBeaconDevice" and installed_device.scale.x<1.0 and game.audio_manager.last_se_key=="beacon_set")
	assert("設置中" in game.habitat_plant_panel.message_label.text)
	assert(game.habitat_notification_service.scheduled_snapshot().has(str(target.individual_id)))
	game._remove_panda_beacon(str(target.individual_id))
	assert(not bool(target.panda_beacon_installed) and game._panda_beacon_used_count()==0 and game.audio_manager.last_se_key=="beacon_remove")
	assert(target_item.get("beacon_node")==null and "回収" in game.habitat_plant_panel.message_label.text)
	await get_tree().create_timer(.24).timeout
	assert(not is_instance_valid(installed_device))
	for multiplier in [1,60,3600,21600,86400]:game._debug_set_habitat_multiplier(multiplier);assert(game.habitat_time_multiplier==multiplier)
	game._install_panda_beacon(str(target.individual_id));game._debug_jump_habitat_time(86400)
	assert(float(target.diameter_cm)>=30.0 and not bool(target.jellied) and bool(target.panda_beacon_installed))
	assert(game.habitat_debug_log.any(func(line):return "30cm" in str(line)))
	game.current_mode="habitat";game._build_habitat_items(true);target_item=game._habitat_wild_item_by_id(str(target.individual_id));assert(not target_item.is_empty());game._collect_habitat_wild_plant(target_item)
	assert(game._habitat_wild_plant_by_id(str(target.individual_id)).is_empty() and game._panda_beacon_used_count()==0)

	# Exercise the real x86,400 realtime route.
	var jelly_target:Dictionary=game.habitat_wild_plants[0];var jelly_id:=str(jelly_target.individual_id)
	wall_now=Time.get_unix_time_from_system();jelly_target.diameter_cm=29.999;jelly_target.jellied=false;jelly_target.jelly_hazard_accumulated=0.0;jelly_target.jelly_threshold=HabitatWildSystemClass.jelly_hazard_rate_per_second()*3.0;jelly_target.last_updated_unix=wall_now;game._refresh_habitat_growth_profile(jelly_target)
	game._install_panda_beacon(jelly_id);game.habitat_wild_update_accumulator=0.0;game._debug_set_habitat_multiplier(86400);game._update_habitat_wild_growth(1.1)
	assert(game._habitat_wild_plant_by_id(jelly_id).is_empty() and game._habitat_wild_item_by_id(jelly_id).is_empty())
	assert(game._panda_beacon_used_count()==0 and game.panda_beacon_unread_log.size()==1 and str(game.panda_beacon_unread_log[0].individual_id)==jelly_id)
	assert(not game.habitat_plant_panel.visible and game.panda_beacon_log_button.visible)
	game._open_panda_beacon_log();assert(game.panda_beacon_log_panel.visible and game.panda_beacon_log_panel.entry_list.get_child_count()==1)
	game.panda_beacon_log_panel._confirm();assert(game.panda_beacon_unread_log.is_empty() and not game.panda_beacon_log_button.visible)

	# Three plants jelly in one interval; only the two monitored plants log.
	wall_now=Time.get_unix_time_from_system();var hazard:=HabitatWildSystemClass.jelly_hazard_rate_per_second()
	var first:=_plant("batch_beacon_1",30.0,1.0,wall_now);first.panda_beacon_installed=true;first.jelly_threshold=hazard*10.0
	var second:=_plant("batch_plain",30.0,1.0,wall_now);second.jelly_threshold=hazard*10.0;second.panorama_x=535.0
	var third:=_plant("batch_beacon_2",30.0,1.0,wall_now);third.panda_beacon_installed=true;third.jelly_threshold=hazard*10.0;third.panorama_x=705.0
	game.habitat_wild_plants.assign([first,second,third]);game.habitat_wild_initialized=true;game.habitat_wild_next_spawn_unix=wall_now+999999.0;game.panda_beacon_unread_log.clear();game._build_habitat_items(true)
	var batch_result:Dictionary=game._ensure_habitat_wild_state(wall_now+20.0,false);game._build_habitat_items(true)
	assert(batch_result.removed.size()==3 and batch_result.jellied.size()==3 and game.habitat_wild_plants.is_empty())
	assert(game.habitat_pickups.filter(func(item):return str(item.get("kind",""))=="wild_plant").is_empty() and game._panda_beacon_used_count()==0)
	assert(game.panda_beacon_unread_log.size()==2 and game.panda_beacon_unread_log.all(func(entry):return str(entry.individual_id)!="batch_plain"))
	game._confirm_panda_beacon_unread_log()

	# Fixed-size Label3D is identical at 10/30/60/100 cm.
	game._clear_habitat_items()
	var visual_sizes:=[10.0,30.0,60.0,100.0]
	for index in range(visual_sizes.size()):
		var preview:=_plant("label_%d"%index,float(visual_sizes[index]),1.0,wall_now,true);preview.panorama_x=70.0+index*120.0;game._add_habitat_wild_plant(preview)
	var visual_items:Array=game.habitat_pickups.filter(func(item):return str(item.get("kind",""))=="wild_plant")
	assert(visual_items.size()==4)
	for item in visual_items:
		var badge:Label3D=item.status_label
		assert(badge.fixed_size and badge.scale==Vector3.ONE and badge.font_size==game.HABITAT_BADGE_FONT_SIZE and badge.outline_size==game.HABITAT_BADGE_OUTLINE_SIZE and is_equal_approx(badge.pixel_size,game.HABITAT_BADGE_PIXEL_SIZE))
		assert("ビーコン" not in badge.text and "◆" not in badge.text)
	assert(game.habitat_dev_panel.find_child("HabitatLabelPreview",true,false)!=null)
	game._debug_prepare_habitat_label_preview()
	for index in range(4):assert(absf(float(game.habitat_wild_plants[index].diameter_cm)-[10.0,30.0,60.0,100.0][index])<0.01)
	var owned_before:int=game.panda_beacon_count;var unlocked_before:bool=game.panda_beacon_unlocked;game._debug_reset_normal_habitat()
	assert(game.panda_beacon_count==owned_before and game.panda_beacon_unlocked==unlocked_before and game._panda_beacon_used_count()==0)
	for jump_seconds in [3600,21600,86400,604800]:game._debug_jump_habitat_time(jump_seconds)
	assert(game._seed_shop_products().any(func(product):return str(product.get("seed_type",""))=="panda_beacon"))
	game._buy_seed_bag("panda_beacon");assert(game.panda_beacon_count==owned_before+1)
	game.tutorial_steps["rain_first_dialog"]=true;game._debug_start_habitat_rain();assert(game.rain_bonus_active and game.rain_event_pending)
	game._debug_stop_habitat_rain();assert(not game.rain_bonus_active and not game.rain_event_pending)
	game._debug_set_habitat_multiplier(1);assert(game.habitat_time_multiplier==1)

func _test_population_and_safe_positions(game:Node)->void:
	var test_rng:=RandomNumberGenerator.new();test_rng.seed=911
	var plants:Array[Dictionary]=[];var ids:Array[String]=["colorata","lutea"]
	HabitatWildSystemClass.initialize_population(plants,ids,ids,true,1000,test_rng,game.HABITAT_SAFE_PLANT_POINTS)
	var initial_count:=plants.size()
	assert(initial_count>=HabitatWildSystemClass.INITIAL_POPULATION_MIN and initial_count<=HabitatWildSystemClass.INITIAL_POPULATION_MAX and initial_count!=15)
	for plant in plants:assert(HabitatWildSystemClass.is_safe_ground_point(Vector2(float(plant.panorama_x),float(plant.panorama_y)),game.HABITAT_SAFE_PLANT_POINTS))
	var removed_id:=str(plants[0].individual_id);HabitatWildSystemClass.remove_individual(plants,removed_id)
	HabitatWildSystemClass.initialize_population(plants,ids,ids,true,1001,test_rng,game.HABITAT_SAFE_PLANT_POINTS)
	assert(plants.size()==initial_count-1)
	assert(HabitatWildSystemClass.spawn_one(plants,ids,1002,test_rng,game.HABITAT_SAFE_PLANT_POINTS) and plants.size()==initial_count)
	var legacy:=_plant("legacy",44.5,1.0,1000);legacy.panorama_x=640.0;legacy.panorama_y=100.0;legacy.position_validated=false
	var legacy_plants:Array[Dictionary]=[legacy];assert(HabitatWildSystemClass.repair_unsafe_positions(legacy_plants,game.HABITAT_SAFE_PLANT_POINTS,test_rng))
	assert(is_equal_approx(float(legacy.diameter_cm),44.5) and HabitatWildSystemClass.is_safe_ground_point(Vector2(float(legacy.panorama_x),float(legacy.panorama_y)),game.HABITAT_SAFE_PLANT_POINTS))

func _test_legacy_population_migration(game:Node)->void:
	game._reset_progression_state();game.intro_story_complete=true;game.habitat_unlocked=true;game.habitat_tutorial_started=true;game.habitat_tutorial_complete=true;game.original_catalog_gifted=true
	game.puku_points=31;game.bests={"colorata":44.8};game.discovered={"colorata":true};game.species_get_counts={"colorata":7};game.panda_beacon_unlocked=true;game.panda_beacon_count=3
	var small:=_plant("legacy_small",24.0,1.0,1000);small.panda_beacon_installed=true
	var giant:=_plant("legacy_giant",16527.6,1.0,1000);giant.panda_beacon_installed=true
	var old_population:Array[Dictionary]=[small,giant]
	assert(HabitatWildSystemClass.has_legacy_runaway_population(old_population))
	assert(not HabitatWildSystemClass.has_legacy_runaway_population([_plant("valid_ready",44.8,1.0,1000)]))
	game.habitat_wild_plants=old_population.duplicate(true);game.habitat_wild_initialized=true;game.habitat_wild_next_spawn_unix=9999999999.0;game._save()
	var payload=JSON.parse_string(FileAccess.get_file_as_string("user://records.json"));assert(payload is Dictionary);payload["progression_version"]=16
	var file:=FileAccess.open("user://records.json",FileAccess.WRITE);file.store_string(JSON.stringify(payload));file.close()
	game.puku_points=0;game.bests.clear();game.discovered.clear();game.species_get_counts.clear();game.panda_beacon_unlocked=false;game.panda_beacon_count=0;game.habitat_wild_plants.clear();game.habitat_wild_initialized=false
	game._load_save()
	assert(game.legacy_habitat_migration_dirty and game.habitat_wild_plants.is_empty() and not game.habitat_wild_initialized and is_zero_approx(game.habitat_wild_next_spawn_unix))
	assert("legacy_small" in game.legacy_habitat_notification_ids_to_cancel and "legacy_giant" in game.legacy_habitat_notification_ids_to_cancel)
	assert(game.puku_points==31 and is_equal_approx(float(game.bests.get("colorata",0.0)),44.8) and int(game.species_get_counts.get("colorata",0))==7)
	assert(game.panda_beacon_unlocked and game.panda_beacon_count==3)
	game.rng.seed=170917;game._ensure_habitat_wild_state(Time.get_unix_time_from_system(),false)
	assert(game.habitat_wild_plants.size()>=HabitatWildSystemClass.INITIAL_POPULATION_MIN and game.habitat_wild_plants.size()<=HabitatWildSystemClass.INITIAL_POPULATION_MAX)
	for plant in game.habitat_wild_plants:
		assert(float(plant.diameter_cm)<30.0 and not bool(plant.panda_beacon_installed) and str(plant.individual_id) not in ["legacy_small","legacy_giant"])
	game.current_mode="habitat";game._build_habitat_items(true)
	var item:Dictionary=game.habitat_pickups.filter(func(value):return str(value.get("kind",""))=="wild_plant")[0]
	var badge:Label3D=item.status_label
	assert(badge.get_parent()==game.habitat_items_root and badge.get_parent()!=item.node)
	assert(badge.billboard==BaseMaterial3D.BILLBOARD_ENABLED and badge.fixed_size and badge.no_depth_test and badge.scale==Vector3.ONE and not badge.text.is_empty())
	game._save();var migrated=JSON.parse_string(FileAccess.get_file_as_string("user://records.json"));assert(int(migrated.get("progression_version",0))==game.PROGRESSION_VERSION and not HabitatWildSystemClass.has_legacy_runaway_population(migrated.get("habitat_wild_plants",[])))

func _test_save_persistence_and_stale_cleanup(game:Node)->void:
	var now:=int(Time.get_unix_time_from_system())
	var saved_plant:=_plant("saved",42.5,1.0,now+3600);saved_plant.species_id="colorata";saved_plant.panorama_x=430.0;saved_plant.panorama_y=405.0;saved_plant.position_validated=true;saved_plant.panda_beacon_installed=true
	var stale_plant:=_plant("saved_stale_jelly",43.2,1.0,now+3600);stale_plant.jellied=true;stale_plant.panda_beacon_installed=true
	game.panda_beacon_unlocked=true;game.panda_beacon_count=3;game.panda_beacon_unread_log.clear();game.panda_beacon_unread_log.append({"individual_id":"prior_unread","species_id":"colorata","diameter_cm":41.2,"jellied_unix":now-60})
	game.habitat_wild_plants.assign([saved_plant,stale_plant]);game.habitat_wild_initialized=true;game.habitat_wild_next_spawn_unix=now+7200;game._save()
	game.habitat_wild_plants.clear();game.habitat_wild_initialized=false;game.habitat_wild_next_spawn_unix=0;game.panda_beacon_unlocked=false;game.panda_beacon_count=0;game.panda_beacon_unread_log.clear();game._load_save()
	assert(game.habitat_wild_plants.size()==1 and str(game.habitat_wild_plants[0].individual_id)=="saved")
	assert(is_equal_approx(float(game.habitat_wild_plants[0].diameter_cm),42.5) and bool(game.habitat_wild_plants[0].panda_beacon_installed))
	assert(is_equal_approx(float(game.habitat_wild_plants[0].panorama_x),430.0) and is_equal_approx(float(game.habitat_wild_plants[0].panorama_y),405.0))
	assert(game.habitat_wild_initialized and game.habitat_wild_next_spawn_unix==now+7200 and game.panda_beacon_unlocked and game.panda_beacon_count==3)
	assert("saved_stale_jelly" in game.legacy_habitat_notification_ids_to_cancel and game.legacy_habitat_migration_dirty)
	assert(game.panda_beacon_unread_log.size()==1 and str(game.panda_beacon_unread_log[0].individual_id)=="prior_unread")
	game._confirm_panda_beacon_unread_log();game.panda_beacon_unread_log.append({"individual_id":"memory_only","species_id":"colorata","diameter_cm":35.0,"jellied_unix":now});game._load_save()
	assert(game.panda_beacon_unread_log.is_empty())
	await get_tree().process_frame

func _plant(individual_id:String,diameter:float,growth_rate:float,last_updated:float,tutorial:=false)->Dictionary:
	return {
		"individual_id":individual_id,"species_id":"colorata","diameter_cm":diameter,"growth_state":"growing","jellied":false,"jellied_unix":0.0,
		"jelly_immune":tutorial,"jelly_elapsed_seconds":0.0,"jelly_hazard_accumulated":0.0,"jelly_threshold":999999.0,"jelly_risk_curve":1.0,
		"tutorial":tutorial,"base_growth_rate":growth_rate,"spawned_unix":last_updated,"last_updated_unix":last_updated,"panda_beacon_installed":false,"habitat_timing_version":HabitatWildSystemClass.TIMING_VERSION,"panorama_x":430.0,"panorama_y":405.0,"position_validated":true
	}
