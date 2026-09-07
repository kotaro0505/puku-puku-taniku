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
	var base:Dictionary=game._series_entry("base");assert(game._is_series_unlocked(base));assert(game._series_species_entries("base").size()==21 and game.catalog_species.size()==29)
	var unique_base_ids:Dictionary={}
	for entry in game._series_species_entries("base"):unique_base_ids[str(entry.species_id)]=true
	assert(unique_base_ids.size()==21)
	for future_id in expected_ids.slice(1):
		var future_entry:Dictionary=game._series_entry(str(future_id));assert(not game._is_series_unlocked(future_entry))
		if str(future_id)=="gummy":assert(future_entry.species_ids.size()==8)
		else:assert(future_entry.species_ids.is_empty())
		var future_field:Dictionary=game._field_entry(str(future_entry.field_id));assert(not bool(future_field.get("implemented",true)))
	var gummy_ids:Dictionary={}
	for gummy_entry in game._series_species_entries("gummy"):
		var gummy_id:=str(gummy_entry.get("species_id",""));var image_path:=str(gummy_entry.get("image_path",""));gummy_ids[gummy_id]=true
		assert(str(gummy_entry.get("series_id",""))=="gummy" and bool(gummy_entry.get("catalog_only",false)) and is_zero_approx(float(gummy_entry.get("spawn_weight",-1.0))))
		assert(not bool(game.greenhouse_available.get(gummy_id,false)) and gummy_entry not in game.species and not image_path.is_empty() and ResourceLoader.exists(image_path))
		var gummy_texture:=load(image_path) as Texture2D;assert(gummy_texture!=null and gummy_texture.get_size()==Vector2(1254,1254))
	assert(gummy_ids.size()==8)
	game.pending_habitat_species.clear();game._queue_random_species("シリーズ未解禁");assert(game.pending_habitat_species.is_empty())
	game.greenhouse_available["gummy_peach_milk"]=true;game.discovered["gummy_peach_milk"]=true;game._apply_saved_unlocks();assert(game.species.all(func(entry):return str(entry.species_id)!="gummy_peach_milk"));game.greenhouse_available.erase("gummy_peach_milk");game.discovered.erase("gummy_peach_milk");game._apply_saved_unlocks()
	game.unlocked_series["gummy"]=true;game.selected_series_index=5;game._open_encyclopedia();game._open_selected_series_encyclopedia();await get_tree().process_frame
	assert(game.encyclopedia_list_page.visible and game.encyclopedia_list_title.text=="グミ多肉" and game.encyclopedia_grid.get_child_count()==8)
	for gummy_card in game.encyclopedia_grid.get_children():assert(gummy_card.disabled)
	game._update_encyclopedia_visible_textures()
	for gummy_image in game.encyclopedia_card_images:
		if gummy_image.texture!=null:assert(str(gummy_image.texture.resource_path).begins_with("res://assets/plants/gummy/"))
	game._close_encyclopedia();game.unlocked_series.erase("gummy");game.selected_series_index=0
	game._open_encyclopedia();assert(game.encyclopedia_series_page.visible and not game.encyclopedia_list_page.visible and game.series_title_label.text=="基本図鑑" and game.series_cover_placeholder.visible)
	assert(game.series_carousel_cards.size()==3)
	var previous_card:Dictionary=game.series_carousel_cards[0];var current_card:Dictionary=game.series_carousel_cards[1];var next_card:Dictionary=game.series_carousel_cards[2]
	assert(str(previous_card.container.get_meta("series_id"))=="yumekawa" and str(current_card.container.get_meta("series_id"))=="base" and str(next_card.container.get_meta("series_id"))=="metal")
	assert(previous_card.container.position.x<0.0 and next_card.container.position.x>0.0)
	for detail_node in current_card.detail_nodes:assert(detail_node.get_parent()==current_card.container)
	var counts_before:Dictionary=game.species_get_counts.duplicate(true);game._refresh_series_selection();game._refresh_series_selection();assert(game.species_get_counts==counts_before)
	var swipe_start:=InputEventScreenTouch.new();swipe_start.pressed=true;swipe_start.position=Vector2(350,200);game._on_series_swipe_input(swipe_start)
	var swipe_drag:=InputEventScreenDrag.new();swipe_drag.position=Vector2(210,202);game._on_series_swipe_input(swipe_drag)
	assert(game.series_carousel_offset==-140.0 and game.series_carousel_track.position.x<game.SERIES_CAROUSEL_TRACK_ORIGIN.x and next_card.title.self_modulate.a>0.0)
	var swipe_end:=InputEventScreenTouch.new();swipe_end.pressed=false;swipe_end.position=Vector2(210,202);game._on_series_swipe_input(swipe_end);assert(game.series_carousel_animating)
	await get_tree().create_timer(.36).timeout
	assert(game._current_series_entry().series_id=="metal" and game.series_open_button.disabled and game.series_lock_label.visible and "今後追加予定" in game.series_open_button.text)
	assert(is_zero_approx(game.series_carousel_offset) and str(previous_card.container.get_meta("series_id"))=="base" and str(next_card.container.get_meta("series_id"))=="jewel")
	var short_start:=InputEventScreenTouch.new();short_start.pressed=true;short_start.position=Vector2(300,200);game._on_series_swipe_input(short_start)
	var short_drag:=InputEventScreenDrag.new();short_drag.position=Vector2(270,200);game._on_series_swipe_input(short_drag)
	var short_end:=InputEventScreenTouch.new();short_end.pressed=false;short_end.position=Vector2(270,200);game._on_series_swipe_input(short_end);await get_tree().create_timer(.28).timeout
	assert(game._current_series_entry().series_id=="metal" and is_zero_approx(game.series_carousel_offset))
	game._open_selected_series_encyclopedia();assert(game.encyclopedia_series_page.visible and not game.encyclopedia_list_page.visible)
	game._change_series_selection(-1);assert(game.series_carousel_animating);await get_tree().create_timer(.36).timeout;assert(game._current_series_entry().series_id=="base" and is_zero_approx(game.series_carousel_offset))
	for repeat in range(2):
		game._spawn_specific_plant("colorata");var harvested=game.plants.back();harvested.diameter_cm=12.0+repeat;harvested.harvest()
	assert(game._grant_hidden_species("pinwheel") and not game._grant_hidden_species("pinwheel"))
	assert(game._species_get_count("colorata")==2 and game._series_get_count("base")==3 and game._all_series_get_count()==3 and game._series_found_count("base")==2)
	game._save();game.species_get_counts.clear();game._load_save();assert(game._species_get_count("colorata")==2 and game._species_get_count("pinwheel")==1)
	game._open_encyclopedia();game._open_selected_series_encyclopedia();await get_tree().process_frame
	assert(game.encyclopedia_list_page.visible and game.encyclopedia_grid.get_child_count()==game._series_species_entries("base").size() and game.encyclopedia_list_title.text=="基本図鑑" and game.encyclopedia_list_get.text=="シリーズ総GET 3")
	assert(not game.encyclopedia_field_button.disabled and game.encyclopedia_field_button.text=="このシリーズの原生地へ")
	game._open_current_series_field();assert(not game.encyclopedia_overlay.visible and game.current_mode=="habitat")
	game._toggle_mode();assert(game.current_mode=="greenhouse")
	print("SERIES_ENCYCLOPEDIA_SMOKE_OK series=",game.series_catalog.size()," base_species=",game._series_species_entries("base").size()," total_get=",game._all_series_get_count())
	get_tree().quit()
