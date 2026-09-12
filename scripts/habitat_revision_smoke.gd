extends Node

const HabitatWildSystemClass=preload("res://scripts/habitat_wild_system.gd")

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._finish_opening();game.audio_manager.apply_settings({"bgm_enabled":false,"se_enabled":false})
	game._reset_progression_state()
	_test_normal_seed_routes(game)
	_test_growth_and_jelly()
	_test_population_and_safe_positions(game)
	_test_giant_visual_and_label(game)
	await _test_save_persistence(game)
	game._reset_progression_state();game.free();await get_tree().process_frame
	print("HABITAT_REVISION_SMOKE_OK seed_new=3+1 growth=1/100 offline=true tutorial=true population=variable jelly=true giant=100 label=fixed safe_spawn=true")
	get_tree().quit()

func _test_normal_seed_routes(game:Node)->void:
	assert(is_equal_approx(game.NORMAL_SEED_UNLOCKED_NEW_RATE,.03))
	assert(is_equal_approx(game.NORMAL_SEED_LOCKED_NEW_RATE,.01))
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
	var now:=200000
	var normal:=_plant("normal",10.0,1.08,now-120)
	var expected:=10.0+120.0*HabitatWildSystemClass.MAIN_GROWTH_CM_PER_SECOND*1.08*HabitatWildSystemClass.NORMAL_GROWTH_SCALE
	var normal_plants:Array[Dictionary]=[normal];HabitatWildSystemClass.advance_time(normal_plants,now)
	assert(is_equal_approx(float(normal.diameter_cm),expected))
	var offline:=_plant("offline",8.0,.92,now-7200)
	var offline_expected:=8.0+7200.0*HabitatWildSystemClass.MAIN_GROWTH_CM_PER_SECOND*.92*.01
	var offline_plants:Array[Dictionary]=[offline];HabitatWildSystemClass.advance_time(offline_plants,now)
	assert(is_equal_approx(float(offline.diameter_cm),offline_expected))
	var tutorial:=_plant("tutorial",29.8,1.0,now-3,true);tutorial.jelly_threshold=.000001
	var tutorial_plants:Array[Dictionary]=[tutorial];HabitatWildSystemClass.advance_time(tutorial_plants,now)
	assert(float(tutorial.diameter_cm)>=30.0 and not bool(tutorial.jellied) and HabitatWildSystemClass.can_harvest(tutorial))
	var jelly:=_plant("jelly",60.0,1.0,now-3600);jelly.jelly_threshold=.000001
	var jelly_plants:Array[Dictionary]=[jelly];HabitatWildSystemClass.advance_time(jelly_plants,now)
	assert(bool(jelly.jellied) and str(jelly.growth_state)=="jellied")
	assert(HabitatWildSystemClass.jelly_hazard_for_interval(60.0,100.0,3600.0)>HabitatWildSystemClass.jelly_hazard_for_interval(5.0,10.0,3600.0))

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
	var legacy:=_plant("legacy",101.5,1.0,1000);legacy.panorama_x=640.0;legacy.panorama_y=100.0;legacy.position_validated=false
	var legacy_plants:Array[Dictionary]=[legacy];assert(HabitatWildSystemClass.repair_unsafe_positions(legacy_plants,game.HABITAT_SAFE_PLANT_POINTS,test_rng))
	assert(is_equal_approx(float(legacy.diameter_cm),101.5) and HabitatWildSystemClass.is_safe_ground_point(Vector2(float(legacy.panorama_x),float(legacy.panorama_y)),game.HABITAT_SAFE_PLANT_POINTS))

func _test_giant_visual_and_label(game:Node)->void:
	var scales:Array[float]=[]
	for diameter in [30.0,40.0,60.0,100.0]:scales.append(game._habitat_wild_visual_scale(diameter))
	assert(scales[0]<scales[1] and scales[1]<scales[2] and scales[2]<scales[3] and scales[3]>5.0)
	var normalized:=HabitatWildSystemClass.normalize_saved([_plant("giant",123.4,1.0,999999)], ["colorata"],999999)
	normalized[0].species_id="colorata"
	# Re-normalize with a valid id to prove no migration caps existing giants.
	normalized=HabitatWildSystemClass.normalize_saved([normalized[0]], ["colorata"],999999)
	assert(normalized.size()==1 and is_equal_approx(float(normalized[0].diameter_cm),123.4))
	game.habitat_wild_plants.clear();game.habitat_wild_plants.append(normalized[0]);game.habitat_wild_initialized=true;game.habitat_wild_next_spawn_unix=9999999999;game.current_mode="habitat";game._build_habitat_items(true)
	var item:Dictionary=game.habitat_pickups.filter(func(value):return str(value.get("kind",""))=="wild_plant")[0]
	var badge:Label3D=item.status_label
	assert(badge.get_parent()==game.habitat_items_root and badge.get_parent()!=item.node)
	assert(badge.billboard==BaseMaterial3D.BILLBOARD_ENABLED and badge.fixed_size and badge.no_depth_test)
	assert(badge.scale==Vector3.ONE and item.node.scale.x>5.0 and not badge.text.is_empty())

func _test_save_persistence(game:Node)->void:
	var now:=int(Time.get_unix_time_from_system())
	var saved_plant:=_plant("saved",42.5,1.0,now+3600);saved_plant.species_id="colorata";saved_plant.panorama_x=430.0;saved_plant.panorama_y=405.0;saved_plant.position_validated=true
	game.habitat_wild_plants.clear();game.habitat_wild_plants.append(saved_plant);game.habitat_wild_initialized=true;game.habitat_wild_next_spawn_unix=now+7200;game._save()
	game.habitat_wild_plants.clear();game.habitat_wild_initialized=false;game.habitat_wild_next_spawn_unix=0;game._load_save()
	assert(game.habitat_wild_plants.size()==1 and str(game.habitat_wild_plants[0].individual_id)=="saved")
	assert(is_equal_approx(float(game.habitat_wild_plants[0].diameter_cm),42.5))
	assert(is_equal_approx(float(game.habitat_wild_plants[0].panorama_x),430.0) and is_equal_approx(float(game.habitat_wild_plants[0].panorama_y),405.0))
	assert(game.habitat_wild_initialized and game.habitat_wild_next_spawn_unix==now+7200)
	await get_tree().process_frame

func _plant(individual_id:String,diameter:float,growth_rate:float,last_updated:int,tutorial:=false)->Dictionary:
	return {
		"individual_id":individual_id,"species_id":"colorata","diameter_cm":diameter,"growth_state":"growing","jellied":false,
		"jelly_immune":tutorial,"jelly_elapsed_seconds":0.0,"jelly_hazard_accumulated":0.0,"jelly_threshold":999999.0,"jelly_risk_curve":1.0,
		"tutorial":tutorial,"base_growth_rate":growth_rate,"last_updated_unix":last_updated,"panorama_x":430.0,"panorama_y":405.0,"position_validated":true
	}
