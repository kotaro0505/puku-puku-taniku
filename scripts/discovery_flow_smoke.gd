extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.habitat_tutorial_complete=true;game.puku_gauge_intro_complete=true;game.total_play_count=3
	# This regression test exercises the established creative-series flow, which
	# is intentionally available only after the second awakening for new saves.
	game.habitat_awakened=true;game.habitat_awakening_event_complete=true;game.habitat_second_awakened=true
	game.unlocked_series["sweets"]=true
	var candidates:Array[Dictionary]=game._habitat_new_species_candidates()
	assert(candidates.is_empty())
	game.pending_habitat_species.append("sweets_strawberry_shortcake")
	assert(game._habitat_new_species_candidates().is_empty())
	game.pending_habitat_species.erase("sweets_strawberry_shortcake")
	var products:Array=game._seed_shop_products()
	assert(not products.any(func(product):return str(product.get("seed_type",""))=="series:sweets"))
	game.puku_points=10;game._buy_seed_bag("series:sweets")
	assert(game.puku_points==10 and int(game.series_seed_inventory.get("sweets",0))==0)
	game.play_active=true;game.active_seed_type="normal"
	game._spawn_specific_plant("sweets_strawberry_shortcake");var large=game.plants.back();large.jelly_checks_enabled=false;large.diameter_cm=18.4;large.harvest()
	assert(bool(game.discovered.get("sweets_strawberry_shortcake",false)) and bool(game.greenhouse_available.get("sweets_strawberry_shortcake",false)))
	assert(bool(game.habitat_returned_species.get("sweets_strawberry_shortcake",false)))
	assert("sweets_strawberry_shortcake" in game._habitat_population_candidate_ids())
	game.rain_event_pending=false;game.rain_bonus_active=false;game._roll_rain_event();assert(not game.rain_event_pending and not game.rain_bonus_active)
	assert(not game.get_property_list().any(func(property:Dictionary)->bool:return str(property.get("name",""))=="mystery_pod_count"))
	game._reset_progression_state();game.queue_free()
	print("DISCOVERY_FLOW_SMOKE_OK greenhouse_get=true settled=true habitat_unknown=false rain_bonus=retired")
	get_tree().quit()
