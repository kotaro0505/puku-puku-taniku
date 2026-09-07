extends Node

const PodSystem=preload("res://scripts/mystery_pod_system.gd")
const IAPService=preload("res://scripts/consumable_iap_service.gd")

class FakeStore:
	extends RefCounted
	var events:Array=[]
	var finished:Array[String]=[]
	var auto_finish:=true
	func set_auto_finish_transaction(value:bool)->void:auto_finish=value
	func request_product_info(_request:Dictionary)->int:return OK
	func purchase(_request:Dictionary)->int:return OK
	func get_pending_event_count()->int:return events.size()
	func pop_pending_event()->Dictionary:return events.pop_front()
	func finish_transaction(product_id:String)->void:finished.append(product_id)

func _ready()->void:
	_test_core_draws()
	await _test_game_loop()
	_test_iap_event_routing()
	print("MYSTERY_POD_SMOKE_OK")
	get_tree().quit()

func _test_core_draws()->void:
	var system=PodSystem.new();system.load_config()
	var series_data:Array=[
		{"series_id":"base","display_name":"基本","species_ids":["base_a","base_b"],"pod_seed_weight":1.0},
		{"series_id":"gummy","display_name":"グミ","species_ids":["gummy_a","gummy_b"],"pod_seed_weight":1.0},
		{"series_id":"locked","display_name":"未開放","species_ids":["locked_a"],"pod_seed_weight":1.0}
	]
	var species_data:Array=[
		{"species_id":"base_a","series_seed_weight":1.0,"spawn_weight":1.0},
		{"species_id":"base_b","series_seed_weight":1.0,"spawn_weight":1.0},
		{"species_id":"gummy_a","series_seed_weight":1.0,"spawn_weight":0.0,"catalog_only":true},
		{"species_id":"gummy_b","series_seed_weight":3.0,"spawn_weight":0.0,"catalog_only":true},
		{"species_id":"locked_a","series_seed_weight":1.0,"spawn_weight":0.0,"catalog_only":true}
	]
	system.configure_catalog(series_data,species_data)
	var unlocked:Dictionary={"base":true,"gummy":true};var discovered:Dictionary={};var test_rng:=RandomNumberGenerator.new();test_rng.seed=77123
	var sample:=system.open_pod(unlocked,discovered,test_rng);assert(sample.size()==3)
	var seed_slots:=0;var yen_slots:=0
	for pod_index in range(12000):
		for result in system.open_pod(unlocked,discovered,test_rng):
			if str(result.get("kind",""))=="series_seed":
				seed_slots+=1;assert(str(result.get("series_id","")) in ["base","gummy"] and not result.has("species_id"))
			else:
				yen_slots+=1;assert(int(result.get("amount",0))>=1000)
	var seed_rate:=float(seed_slots)/float(seed_slots+yen_slots);assert(absf(seed_rate-.85)<.015)
	assert(system.eligible_series({"locked":true},{})[0].series_id=="locked")
	assert(system.eligible_series(unlocked,{}).size()==2)
	var incomplete:=system.eligible_series(unlocked,{})
	var complete:=system.eligible_series(unlocked,{"base_a":true,"base_b":true})
	var base_incomplete:Dictionary=incomplete.filter(func(entry):return str(entry.series_id)=="base")[0]
	var base_complete:Dictionary=complete.filter(func(entry):return str(entry.series_id)=="base")[0]
	assert(is_equal_approx(float(base_complete._pod_weight),float(base_incomplete._pod_weight)*.20))
	assert(is_equal_approx(system.species_weight_for_series("gummy_a",{}),1.0))
	assert(is_equal_approx(system.species_weight_for_series("gummy_a",{"gummy_a":true}),.10))
	assert(is_equal_approx(system.species_weight_for_series("gummy_b",{}),3.0))
	system.set_setting("discovered_species_weight_multiplier",0.0);assert(is_zero_approx(system.species_weight_for_series("gummy_a",{"gummy_a":true})))
	system.reset_formal();assert(system.setting_int("slots_per_pod")==3 and is_equal_approx(system.setting_float("main_play_pod_chance"),.20))

func _test_game_loop()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	assert(game._mystery_pod_dev_tools_allowed_for_environment(true,false,false))
	assert(game._mystery_pod_dev_tools_allowed_for_environment(false,true,false))
	assert(not game._mystery_pod_dev_tools_allowed_for_environment(false,false,true))
	assert(not game._mystery_pod_dev_tools_allowed_for_environment(true,false,true))
	assert(not game._mystery_pod_dev_tools_allowed_for_environment(false,false,false))
	assert(game.mystery_pod_dev!=null and game.mystery_pod_settings_button!=null)
	game._open_mystery_pod_dev();assert(game.mystery_pod_dev.visible);game.mystery_pod_dev.visible=false
	game._reset_progression_state();game.intro_story_complete=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.buyback_unlocked=true;game.total_play_count=3
	var gummy:Dictionary=game._series_entry("gummy");assert(not game._is_series_unlocked(gummy) and game._can_browse_series(gummy))
	game.current_encyclopedia_series_id="gummy";game.coins=10000;game._acquire_current_catalog("yen")
	assert(game._is_series_unlocked(gummy) and game.coins==0 and game._series_found_count("gummy")==0)
	game.unlocked_series.erase("gummy");game.mystery_pod_count=10;game._acquire_current_catalog("pods")
	assert(game._is_series_unlocked(gummy) and game.mystery_pod_count==0 and game._series_found_count("gummy")==0)
	game.series_seed_inventory["gummy"]=1;game._start_greenhouse_play("series:gummy")
	assert(game.play_active and game.current_target_count==1 and int(game.series_seed_inventory.gummy)==0)
	await get_tree().create_timer(.45).timeout
	assert(game.plants.size()==1)
	var grown=game.plants[0];var grown_id:=str(grown.data.species_id)
	assert(grown_id.begins_with("gummy_") and not bool(grown.get_meta("catalog_preview",false)))
	grown.jelly_checks_enabled=false;grown.diameter_cm=18.0;grown.harvest()
	assert(bool(game.discovered.get(grown_id,false)) and bool(game.greenhouse_available.get(grown_id,false)) and bool(game.unlocked_species.get(grown_id,false)))
	assert(game.species.any(func(entry):return str(entry.species_id)==grown_id) and game._species_get_count(grown_id)==1)
	game._clear_greenhouse_plants();game.play_active=false;game.greenhouse_available={grown_id:true};game.discovered={grown_id:true}
	for choice in range(12):assert(str(game._select_species_for_seed("normal").species_id)==grown_id)
	game.intro_story_complete=true;game.habitat_unlocked=true;game.buyback_unlocked=true;game.total_play_count=3;game.active_seed_type="normal";game.play_active=true;game.main_pod_pending=false
	game.mystery_pod_system.set_setting("main_play_pod_chance",1.0);game._prepare_main_pod_for_play();assert(game.main_pod_pending)
	var control_rng:=RandomNumberGenerator.new();control_rng.seed=43210;var expected:=control_rng.randi()
	game.rng.seed=43210;game.main_pod_pending=false;game._prepare_main_pod_for_play();assert(game.rng.randi()==expected)
	game.mystery_pod_system.set_setting("habitat_pod_chance",0.0);game.habitat_pod_roll_date="";game.habitat_pod_pending=false;game._ensure_habitat_pod_daily_roll();assert(not game.habitat_pod_pending)
	game.mystery_pod_system.set_setting("habitat_pod_chance",1.0);game._ensure_habitat_pod_daily_roll();assert(not game.habitat_pod_pending)
	game.habitat_pod_roll_date="";game._ensure_habitat_pod_daily_roll();assert(game.habitat_pod_pending)
	var pods_before:int=game.mystery_pod_count;game._on_mystery_pod_purchase_verified("com.ohanayanouen.pukupukutaniku.pods.6","txn-smoke-001");assert(game.mystery_pod_count==pods_before+6)
	game._on_mystery_pod_purchase_verified("com.ohanayanouen.pukupukutaniku.pods.6","txn-smoke-001");assert(game.mystery_pod_count==pods_before+6 and game.processed_iap_transactions.has("txn-smoke-001"))
	game._save();game.mystery_pod_count=0;game.processed_iap_transactions.clear();game._load_save();assert(game.mystery_pod_count==pods_before+6 and game.processed_iap_transactions.has("txn-smoke-001"))
	var legacy:=FileAccess.open("user://records.json",FileAccess.WRITE);legacy.store_string(JSON.stringify({"yen":321,"discovered":{"colorata":true},"greenhouse_available":{"colorata":true}}));legacy.close();game.mystery_pod_count=99;game.series_seed_inventory={"gummy":4};game._load_save();assert(game.coins==321 and game.mystery_pod_count==0 and game.series_seed_inventory.is_empty())
	game.queue_free()

func _test_iap_event_routing()->void:
	var service=IAPService.new();add_child(service);var fake:=FakeStore.new();service.product_definitions=[{"product_id":"pod.test","product_type":"consumable"}];service.set_store_bridge_for_test(fake);assert(not fake.auto_finish)
	var counts:Dictionary={"verified":0,"cancelled":0,"failed":0,"restores":0}
	service.purchase_verified.connect(func(_product:String,_transaction:String):counts.verified+=1)
	service.purchase_cancelled.connect(func(_product:String):counts.cancelled+=1)
	service.purchase_failed.connect(func(_product:String,_message:String):counts.failed+=1)
	service.restore_event_ignored.connect(func(_product:String):counts.restores+=1)
	service.process_store_event({"type":"purchase","result":"ok","product_id":"pod.test","transaction_id":"txn-a"})
	service.process_store_event({"type":"purchase","result":"error","product_id":"pod.test","error":"Payment cancelled"})
	service.process_store_event({"type":"purchase","result":"error","product_id":"pod.test","error":"Network failed"})
	service.process_store_event({"type":"restore","result":"ok","product_id":"pod.test"})
	assert(counts.verified==1 and counts.cancelled==1 and counts.failed==1 and counts.restores==1)
	service.finish_transaction("pod.test");assert(fake.finished==["pod.test"])
