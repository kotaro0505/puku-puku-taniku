extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.puku_gauge_intro_complete=true;game.total_play_count=3
	game.unlocked_series["sweets"]=true
	assert(game.RAIN_TRIGGER_CHANCES==[0.01,0.02,0.03,0.05,0.08,0.12,0.20])
	var candidates:Array[Dictionary]=game._habitat_new_species_candidates()
	assert(candidates.any(func(entry):return str(entry.species_id)=="sweets_strawberry_shortcake"))
	assert(not candidates.any(func(entry):return bool(entry.get("special_route_only",false))))
	game.pending_habitat_species.append("sweets_strawberry_shortcake")
	assert(not game._habitat_new_species_candidates().any(func(entry):return str(entry.species_id)=="sweets_strawberry_shortcake"))
	game.pending_habitat_species.erase("sweets_strawberry_shortcake")
	var products:Array=game._seed_shop_products();var sweets_product:Dictionary={}
	for product in products:
		if str(product.get("seed_type",""))=="series:sweets":sweets_product=product;break
	assert(not sweets_product.is_empty() and sweets_product.price_puku==null and not bool(sweets_product.purchasable) and int(sweets_product.count)==1)
	game.puku_points=10;game._buy_seed_bag("series:sweets")
	assert(game.puku_points==10 and int(game.series_seed_inventory.get("sweets",0))==0)
	var rain_pool:Array=game._rain_species_pool()
	assert(rain_pool.any(func(entry):return str(entry.species_id)=="sweets_strawberry_shortcake"))
	game.rain_bonus_active=true;game.play_active=true
	game._spawn_specific_plant("sweets_strawberry_shortcake");var small=game.plants.back();small.jelly_checks_enabled=false;small.diameter_cm=29.9;small.harvest()
	assert(not bool(game.discovered.get("sweets_strawberry_shortcake",false)))
	game._spawn_specific_plant("sweets_strawberry_shortcake");var large=game.plants.back();large.jelly_checks_enabled=false;large.diameter_cm=30.0;large.harvest()
	assert(bool(game.discovered.get("sweets_strawberry_shortcake",false)) and bool(game.greenhouse_available.get("sweets_strawberry_shortcake",false)))
	game._sync_mystery_pod_ui();assert(game.mystery_pod_ui.rates_button.text=="提供割合を見る" and not game.mystery_pod_ui.rates_label.visible and game.mystery_pod_ui.open_button.size.x>=300.0)
	game._reset_progression_state();game.queue_free()
	print("DISCOVERY_FLOW_SMOKE_OK")
	get_tree().quit()
