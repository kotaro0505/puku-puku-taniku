extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.mystery_items_acquired=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true
	assert(game._owned_series_entries().map(func(entry):return str(entry.series_id))==["base"])
	assert(game._is_series_unlocked(game._series_entry("base")))
	assert(game._is_hidden_series("neon") and not game._is_normal_series("neon"))
	assert(game._series_cover_texture(game._series_entry("neon"))!=null)
	var all_normal_ids:=["metal","jewel","jelly","sweets","gummy","stardust","glow","stone","sea","yumekawa","forest_amber","jurejure"]
	assert(game._shop_series_catalog().map(func(entry):return str(entry.series_id))==all_normal_ids)
	game.formal_play_count=1;assert(game._shop_series_catalog().map(func(entry):return str(entry.series_id))==all_normal_ids)
	game.formal_play_count=46;assert(game._shop_series_catalog().map(func(entry):return str(entry.series_id))==all_normal_ids and game._is_normal_series("forest_amber"))
	assert(not game._shop_series_catalog().any(func(entry):return str(entry.series_id)=="neon"))
	assert(game.find_child("ShopCategoryCatalog",true,false)==null)
	game.puku_points=5;game._grant_old_catalog_page(1,true);assert(game.old_catalog_pages==0 and not game.old_catalog_intro_pending and game.puku_points==5 and bool(game.unlocked_series.get("neon",false)))
	assert(game._owned_series_entries().map(func(entry):return str(entry.series_id))==["base","neon"] and game._series_species_entries("neon").size()==3)
	game.unlocked_series.erase("neon");game.research_catalog_reward_pending=true;game.armadillo_research_rewards.erase("8");game.formal_play_count=10
	game._claim_research_catalog_reward("sweets");assert(bool(game.unlocked_series.get("sweets",false)) and bool(game.armadillo_research_rewards.get("8",false)) and not game.research_catalog_reward_pending)
	game.mystery_seed_count=1;game.armadillo_research_total=0;game.armadillo_research_rewards.clear();game._accept_armadillo_research();assert(game.mystery_seed_count==0 and game.armadillo_research_total==1)
	game.armadillo_research_total=7;game.mystery_seed_count=1;game._accept_armadillo_research();assert(game.research_catalog_reward_pending and not bool(game.armadillo_research_rewards.get("8",false)))
	for hidden_rule in game.catalog_progression.get("hidden_series",[]):assert(not bool(hidden_rule.get("old_page_spawn",{}).get("enabled",true)))
	game.old_catalog_pages=0;game._adjust_progression_dev_value("old_page",-1);game.puku_points=0;game._adjust_progression_dev_value("puku_coin",-1);assert(game.old_catalog_pages==0 and game.puku_points==0)
	_test_first_series_page_notice(game)
	print("CATALOG_PROGRESSION_SMOKE_OK purchase=removed auto_record=true owned=",game._owned_series_entries().size())
	get_tree().quit()

func _test_first_series_page_notice(game:Node)->void:
	game.catalog_series_unlock_notice_queue.clear()
	game.unlocked_series.erase("gummy")
	game.discovered.erase("gummy_peach_milk")
	game.discovered.erase("gummy_melon_milk")
	game.species_get_counts.erase("gummy_peach_milk")
	game.species_get_counts.erase("gummy_melon_milk")
	assert(game._register_species_discovery("gummy_peach_milk",true))
	assert(game.catalog_series_unlock_notice_queue==["gummy"])
	assert(game._try_start_catalog_series_unlock_notice())
	assert(game.scripted_dialog_kind=="catalog_series_unlock_notice")
	assert(str(game.scripted_dialog_pages[0].get("text","")).contains("『グミ多肉』"))
	while not game.scripted_dialog_kind.is_empty():game._advance_scripted_dialog()
	assert(game._register_species_discovery("gummy_melon_milk",true))
	assert(game.catalog_series_unlock_notice_queue.is_empty())
	game.unlocked_series["metal"]=true
	game.discovered.erase("metal_silver_rosette")
	game.species_get_counts.erase("metal_silver_rosette")
	assert(game._register_species_discovery("metal_silver_rosette",true))
	assert(game.catalog_series_unlock_notice_queue.is_empty())
