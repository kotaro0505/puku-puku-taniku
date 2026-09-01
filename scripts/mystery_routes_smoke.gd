extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.total_play_count=3;game.formal_play_count=1;game.habitat_unlocked=true;game.buyback_unlocked=true
	game.tutorial_steps["habitat_scroll_dialog"]=true;game.tutorial_steps["habitat_get_dialog"]=true;game.tutorial_steps["play1_dialog"]=true
	# First rain completion has no route reward; the second assigns one pending plant.
	game.rain_bonus_active=true;game._finish_rain_bonus();assert(game.rain_completion_count==1 and not game.mystery_route_assignments.has(game.MYSTERY_ROUTE_RAIN))
	game.rain_bonus_active=true;game._finish_rain_bonus();var mystery_ids:Array[String]=game._mystery_event_species_ids();var rain_id:=str(game.mystery_route_assignments.get(game.MYSTERY_ROUTE_RAIN,""));assert(mystery_ids.size()==6 and rain_id in mystery_ids and rain_id in game.pending_habitat_species and not bool(game.discovered.get(rain_id,false)))
	# Research at cumulative 25 grants a different species immediately.
	game.armadillo_research_total=24;game.mystery_seed_count=1;game.armadillo_research_rewards.clear();game._accept_armadillo_research();var research_id:=str(game.mystery_route_assignments.get(game.MYSTERY_ROUTE_RESEARCH,""));assert(research_id in mystery_ids and research_id!=rain_id and bool(game.discovered.get(research_id,false)) and game.shop_chatter_acquired_species==[research_id])
	game._hide_shop_chatter(true)
	# A formal-play 100 cm harvest assigns, but does not discover, a third species.
	game.active_seed_type="normal";game.play_active=true;game._spawn_specific_plant("colorata");var giant=game.plants.back();giant.diameter_cm=100.0;giant.harvest();var best_id:=str(game.mystery_route_assignments.get(game.MYSTERY_ROUTE_BEST_100,""));assert(best_id in mystery_ids and best_id not in [rain_id,research_id] and best_id in game.pending_habitat_species and not bool(game.discovered.get(best_id,false)))
	game.play_active=false;game._clear_greenhouse_plants()
	# Completing the normal habitat collection assigns the fourth and final ID.
	for normal_id in game._normal_habitat_collection_ids():game.discovered[normal_id]=true
	game._evaluate_normal_habitat_completion();var complete_id:=str(game.mystery_route_assignments.get(game.MYSTERY_ROUTE_HABITAT_COMPLETE,""));var all_ids:=[rain_id,research_id,best_id,complete_id];var unique:={}
	for species_id in all_ids:unique[species_id]=true
	assert(complete_id in mystery_ids and unique.size()==4 and complete_id in game.pending_habitat_species and not bool(game.discovered.get(complete_id,false)) and game._mystery_route_candidates().size()==2)
	# All ordinary seed packs exclude all four, even if mistakenly marked available.
	for species_id in mystery_ids:game.greenhouse_available[species_id]=true;game.discovered[species_id]=true
	game._apply_saved_unlocks()
	for seed_type in ["normal","volume","premium"]:
		for draw in range(120):assert(str(game._select_species_for_seed(seed_type).species_id) not in mystery_ids)
	game.discovered["transparent_succulent"]=true;game._refresh_seed_pack_unlocks();assert(game._mystery_seed_pack_unlocked())
	for draw in range(30):assert(str(game._select_species_for_seed("mystery").species_id)=="transparent_succulent")
	game._save();var saved_assignments:Dictionary=game.mystery_route_assignments.duplicate(true);game.mystery_route_assignments.clear();game._load_save();assert(game.mystery_route_assignments==saved_assignments and game.rain_completion_count==2 and game.best_100_achieved and game.normal_habitat_complete)
	print("MYSTERY_ROUTES_SMOKE_OK assignments=",all_ids)
	get_tree().quit()
