extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.mystery_items_acquired=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true
	assert(game._owned_series_entries().map(func(entry):return str(entry.series_id))==["base"])
	assert(game._is_series_unlocked(game._series_entry("base")))
	assert(game._series_entry("neon").is_empty() and game._series_species_entries("neon").is_empty())
	assert(not game._is_hidden_series("neon") and not game._is_normal_series("neon"))
	assert((game.catalog_progression.get("hidden_series",[]) as Array).is_empty())
	var all_normal_ids:=["metal","jewel","jelly","sweets","gummy","stardust","glow","stone","sea","yumekawa","forest_amber","jurejure"]
	assert(game._shop_series_catalog().map(func(entry):return str(entry.series_id))==all_normal_ids)
	game.formal_play_count=1;assert(game._shop_series_catalog().map(func(entry):return str(entry.series_id))==all_normal_ids)
	game.formal_play_count=46;assert(game._shop_series_catalog().map(func(entry):return str(entry.series_id))==all_normal_ids and game._is_normal_series("forest_amber"))
	assert(not game._shop_series_catalog().any(func(entry):return str(entry.series_id)=="neon"))
	assert(game.find_child("ShopCategoryCatalog",true,false)==null)
	game.puku_points=5;game._grant_old_catalog_page(1,true);assert(game.old_catalog_pages==0 and not game.old_catalog_intro_pending and game.puku_points==5 and not game.unlocked_series.has("neon"))
	assert(game._owned_series_entries().map(func(entry):return str(entry.series_id))==["base"])
	assert(not game.has_method("_accept_armadillo_research") and not game.has_method("_claim_research_catalog_reward"))
	assert(game._select_species_for_seed("mystery").is_empty())
	assert((game.catalog_progression.get("hidden_series",[]) as Array).is_empty())
	game.old_catalog_pages=0;game._adjust_progression_dev_value("old_page",-1);game.puku_points=0;game._adjust_progression_dev_value("puku_coin",-1);assert(game.old_catalog_pages==0 and game.puku_points==0)
	await _test_first_series_page_notice(game)
	print("CATALOG_PROGRESSION_SMOKE_OK purchase=removed hidden_series=0 neon=absent owned=",game._owned_series_entries().size())
	get_tree().quit()

func _test_first_series_page_notice(game:Node)->void:
	var audio_config:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/audio-config.json"))
	assert(audio_config is Dictionary and str((audio_config as Dictionary).get("se",{}).get("new_species_card",""))=="res://assets/audio/pukupuku_new_card.mp3")
	assert(load("res://assets/audio/pukupuku_new_card.mp3") is AudioStreamMP3)
	game.catalog_series_unlock_notice_queue.clear()
	game.catalog_series_unlock_notice_ready.clear()
	game.catalog_series_unlock_overlay.reset_overlay();game.species_get_overlay.visible=false;game.species_get_queue.clear();game.scripted_dialog_kind="";game.scripted_dialog_pages.clear()
	game.unlocked_series.erase("gummy")
	game.discovered.erase("gummy_peach_milk")
	game.discovered.erase("gummy_melon_milk")
	game.species_get_counts.erase("gummy_peach_milk")
	game.species_get_counts.erase("gummy_melon_milk")
	assert(game._register_species_discovery("gummy_peach_milk",true))
	assert(game.catalog_series_unlock_notice_queue==["gummy"])
	game.audio_manager.se_enabled=true
	game.audio_manager.last_se_key=""
	game._queue_species_get_by_id("gummy_peach_milk",true,"catalog_notice_test");game._show_next_species_get()
	assert(game.species_get_overlay.visible and not game.catalog_series_unlock_overlay.visible)
	assert(game.audio_manager.last_se_key=="new_species_card")
	game.audio_manager.last_se_key=""
	game.species_get_overlay.busy=false;await game.species_get_overlay.close_overlay()
	assert(not game.species_get_overlay.visible and game.catalog_series_unlock_overlay.visible and game.scripted_dialog_kind.is_empty())
	assert(game.audio_manager.last_se_key.is_empty())
	assert(game.catalog_series_unlock_overlay.title_label.text=="図鑑ページ解放！")
	assert(game.catalog_series_unlock_overlay.message_label.text=="不思議な多肉図鑑に\n新しく『グミ多肉』の\n図鑑ページが現れました！")
	assert(game.catalog_series_unlock_overlay.cover_image.texture!=null and game.catalog_series_unlock_overlay.cover_image.texture.resource_path=="res://assets/catalog/gummy/gummy-peach-milk.png")
	game.catalog_series_unlock_overlay.busy=false;await game.catalog_series_unlock_overlay.close_overlay()
	assert(not game.catalog_series_unlock_overlay.visible)
	game.audio_manager.last_se_key=""
	game._queue_species_get_by_id("gummy_peach_milk",false,"catalog_duplicate_sound_test");game._show_next_species_get()
	assert(game.species_get_overlay.visible and game.audio_manager.last_se_key=="new_species")
	game.species_get_overlay.busy=false;await game.species_get_overlay.close_overlay()
	assert(game._register_species_discovery("gummy_melon_milk",true))
	assert(game.catalog_series_unlock_notice_queue.is_empty())
	game.unlocked_series["metal"]=true
	game.discovered.erase("metal_silver_rosette")
	game.species_get_counts.erase("metal_silver_rosette")
	assert(game._register_species_discovery("metal_silver_rosette",true))
	assert(game.catalog_series_unlock_notice_queue.is_empty())
	game.catalog_series_unlock_overlay.show_series({},null,"画像なし多肉","catalog_notice_missing_cover","ja")
	assert(game.catalog_series_unlock_overlay.visible and not game.catalog_series_unlock_overlay.cover_placeholder.visible and game.catalog_series_unlock_overlay.cover_placeholder.text.is_empty() and game.catalog_series_unlock_overlay.card.size==Vector2(508,770))
	game.catalog_series_unlock_overlay.busy=false;await game.catalog_series_unlock_overlay.close_overlay()
