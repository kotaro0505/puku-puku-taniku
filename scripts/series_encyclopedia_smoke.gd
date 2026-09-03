extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.tutorial_steps["habitat_scroll_dialog"]=true;game.tutorial_steps["habitat_get_dialog"]=true
	assert(game.series_catalog.size()==14)
	var expected_ids:=["base","metal","jewel","jelly","sweets","gummy","stardust","glow","neon","stone","sea","halloween","christmas","yumekawa"]
	for index in range(expected_ids.size()):
		var series_entry:Dictionary=game.series_catalog[index]
		assert(str(series_entry.get("series_id",""))==expected_ids[index])
		for required_key in ["series_id","display_name","subtitle","description","cover_image_path","species_ids","field_id","unlock_type","unlock_condition","iap_product_id","sort_order"]:assert(series_entry.has(required_key))
	var base:Dictionary=game._series_entry("base");assert(game._is_series_unlocked(base));assert(game._series_species_entries("base").size()==game.catalog_species.size())
	var unique_base_ids:Dictionary={}
	for entry in game._series_species_entries("base"):unique_base_ids[str(entry.species_id)]=true
	assert(unique_base_ids.size()==game.catalog_species.size())
	for future_id in expected_ids.slice(1):
		var future_entry:Dictionary=game._series_entry(str(future_id));assert(not game._is_series_unlocked(future_entry) and future_entry.species_ids.is_empty())
		var future_field:Dictionary=game._field_entry(str(future_entry.field_id));assert(not bool(future_field.get("implemented",true)))
	game._open_encyclopedia();assert(game.encyclopedia_series_page.visible and not game.encyclopedia_list_page.visible and game.series_title_label.text=="基本図鑑" and game.series_cover_placeholder.visible)
	var counts_before:Dictionary=game.species_get_counts.duplicate(true);game._refresh_series_selection();game._refresh_series_selection();assert(game.species_get_counts==counts_before)
	var swipe_start:=InputEventScreenTouch.new();swipe_start.pressed=true;swipe_start.position=Vector2(350,200);game._on_series_swipe_input(swipe_start);var swipe_end:=InputEventScreenTouch.new();swipe_end.pressed=false;swipe_end.position=Vector2(100,200);game._on_series_swipe_input(swipe_end)
	assert(game._current_series_entry().series_id=="metal" and game.series_open_button.disabled and game.series_lock_label.visible and "今後追加予定" in game.series_open_button.text)
	game._open_selected_series_encyclopedia();assert(game.encyclopedia_series_page.visible and not game.encyclopedia_list_page.visible)
	game._change_series_selection(-1);assert(game._current_series_entry().series_id=="base")
	for repeat in range(2):
		game._spawn_specific_plant("colorata");var harvested=game.plants.back();harvested.diameter_cm=12.0+repeat;harvested.harvest()
	assert(game._grant_hidden_species("pinwheel") and not game._grant_hidden_species("pinwheel"))
	assert(game._species_get_count("colorata")==2 and game._series_get_count("base")==3 and game._all_series_get_count()==3 and game._series_found_count("base")==2)
	game._save();game.species_get_counts.clear();game._load_save();assert(game._species_get_count("colorata")==2 and game._species_get_count("pinwheel")==1)
	game._open_encyclopedia();game._open_selected_series_encyclopedia();await get_tree().process_frame
	assert(game.encyclopedia_list_page.visible and game.encyclopedia_grid.get_child_count()==game.catalog_species.size() and game.encyclopedia_list_title.text=="基本図鑑" and game.encyclopedia_list_get.text=="シリーズ総GET 3")
	assert(not game.encyclopedia_field_button.disabled and game.encyclopedia_field_button.text=="このシリーズの原生地へ")
	game._open_current_series_field();assert(not game.encyclopedia_overlay.visible and game.current_mode=="habitat")
	game._toggle_mode();assert(game.current_mode=="greenhouse")
	print("SERIES_ENCYCLOPEDIA_SMOKE_OK series=",game.series_catalog.size()," base_species=",game._series_species_entries("base").size()," total_get=",game._all_series_get_count())
	get_tree().quit()
