extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true
	assert(game._owned_series_entries().map(func(entry):return str(entry.series_id))==["base"])
	assert(game._is_hidden_series("neon") and not game._is_normal_series("neon"))
	assert(game._series_cover_texture(game._series_entry("neon"))!=null)
	assert(game._shop_series_catalog().is_empty())
	game.formal_play_count=1;assert(game._shop_series_catalog().map(func(entry):return str(entry.series_id))==["gummy"])
	game.formal_play_count=10;assert(game._shop_series_catalog().map(func(entry):return str(entry.series_id))==["metal","sweets","gummy","glow"])
	game.formal_play_count=46;assert(game._shop_series_catalog().any(func(entry):return str(entry.series_id)=="forest_amber") and game._is_normal_series("forest_amber"))
	assert(not game._shop_series_catalog().any(func(entry):return str(entry.series_id)=="neon"))
	game._sync_arrangement_ui();game.arrangement_ui.open_catalog_shop();assert(game.arrangement_ui.catalog_shop_grid.get_child_count()==game._shop_series_catalog().size());game.arrangement_ui.visible=false
	game._grant_old_catalog_page(1,true);assert(game.old_catalog_pages==1 and game.old_catalog_intro_pending)
	game.puku_points=2;game._accept_hidden_catalog_restoration();assert(game.old_catalog_pages==1 and not bool(game.unlocked_series.get("neon",false)))
	game.puku_points=3;game._accept_hidden_catalog_restoration();assert(game.old_catalog_pages==0 and game.puku_points==0 and bool(game.unlocked_series.get("neon",false)))
	assert(game._owned_series_entries().map(func(entry):return str(entry.series_id))==["base","neon"] and game._series_species_entries("neon").size()==3)
	game.unlocked_series.erase("neon");game.research_catalog_reward_pending=true;game.armadillo_research_rewards.erase("8");game.formal_play_count=10
	game._claim_research_catalog_reward("sweets");assert(bool(game.unlocked_series.get("sweets",false)) and bool(game.armadillo_research_rewards.get("8",false)) and not game.research_catalog_reward_pending)
	var pod_count_before:int=int(game.mystery_pod_count);game.mystery_seed_count=1;game.armadillo_research_total=0;game.armadillo_research_rewards.clear();game._accept_armadillo_research();assert(game.mystery_pod_count==pod_count_before)
	game.armadillo_research_total=7;game.mystery_seed_count=1;game._accept_armadillo_research();assert(game.research_catalog_reward_pending and not bool(game.armadillo_research_rewards.get("8",false)))
	for hidden_rule in game.catalog_progression.get("hidden_series",[]):assert(not bool(hidden_rule.get("old_page_spawn",{}).get("enabled",true)))
	game.old_catalog_pages=0;game._adjust_progression_dev_value("old_page",-1);game.puku_points=0;game._adjust_progression_dev_value("puku_coin",-1);assert(game.old_catalog_pages==0 and game.puku_points==0)
	print("CATALOG_PROGRESSION_SMOKE_OK stocked=",game._shop_series_catalog().size()," owned=",game._owned_series_entries().size())
	get_tree().quit()
