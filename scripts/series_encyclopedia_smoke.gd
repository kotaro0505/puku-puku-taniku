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
	var base:Dictionary=game._series_entry("base");assert(game._is_series_unlocked(base));assert(game._series_species_entries("base").size()==21 and game.catalog_species.size()==61)
	var unique_base_ids:Dictionary={}
	for entry in game._series_species_entries("base"):unique_base_ids[str(entry.species_id)]=true
	assert(unique_base_ids.size()==21)
	for future_id in expected_ids.slice(1):
		var future_entry:Dictionary=game._series_entry(str(future_id));assert(not game._is_series_unlocked(future_entry))
		if str(future_id) in ["metal","sweets"]:assert(future_entry.species_ids.size()==10 and game._can_browse_series(future_entry) and bool(future_entry.get("preview_catalog_when_locked",false)) and game._catalog_purchase_enabled(future_entry))
		elif str(future_id)=="gummy":assert(future_entry.species_ids.size()==8 and game._can_browse_series(future_entry) and bool(future_entry.get("preview_catalog_when_locked",false)))
		elif str(future_id)=="glow":assert(future_entry.species_ids.size()==12 and game._can_browse_series(future_entry) and bool(future_entry.get("preview_catalog_when_locked",false)) and game._catalog_purchase_enabled(future_entry))
		else:assert(future_entry.species_ids.is_empty())
		var future_field:Dictionary=game._field_entry(str(future_entry.field_id));assert(not bool(future_field.get("implemented",true)))
	var gummy_ids:Dictionary={}
	for gummy_entry in game._series_species_entries("gummy"):
		var gummy_id:=str(gummy_entry.get("species_id",""));var image_path:=str(gummy_entry.get("image_path",""));gummy_ids[gummy_id]=true
		assert(str(gummy_entry.get("series_id",""))=="gummy" and bool(gummy_entry.get("catalog_only",false)) and is_zero_approx(float(gummy_entry.get("spawn_weight",-1.0))))
		assert(not bool(game.greenhouse_available.get(gummy_id,false)) and gummy_entry not in game.species and image_path.ends_with(".png") and ResourceLoader.exists(image_path))
		assert(str(game.SucculentClass.SPRITES.get(str(gummy_entry.get("visual_variant","")),""))==image_path)
		var gummy_texture:=load(image_path) as Texture2D;var gummy_source:=gummy_texture.get_image();var gummy_used:=gummy_source.get_used_rect();assert(gummy_texture.get_size()==Vector2(1254,1254) and gummy_source.detect_alpha()!=Image.ALPHA_NONE and gummy_source.get_pixel(0,0).a<.01 and gummy_used.position.x>0 and gummy_used.position.y>0 and gummy_used.end.x<1254 and gummy_used.end.y<1254)
	assert(gummy_ids.size()==8)
	var sweets_ids:Dictionary={}
	for sweets_entry in game._series_species_entries("sweets"):
		var sweets_id:=str(sweets_entry.get("species_id",""));var image_path:=str(sweets_entry.get("image_path",""));sweets_ids[sweets_id]=true
		assert(str(sweets_entry.get("series_id",""))=="sweets" and bool(sweets_entry.get("catalog_only",false)) and is_zero_approx(float(sweets_entry.get("spawn_weight",-1.0))))
		assert(not bool(game.greenhouse_available.get(sweets_id,false)) and sweets_entry not in game.species and image_path.begins_with("res://assets/catalog/sweets/") and ResourceLoader.exists(image_path))
		assert(str(game.SucculentClass.SPRITES.get(str(sweets_entry.get("visual_variant","")),""))==image_path)
		var sweets_texture:=load(image_path) as Texture2D;var sweets_source:=sweets_texture.get_image();var sweets_used:=sweets_source.get_used_rect();assert(sweets_texture.get_size()==Vector2(1254,1254) and sweets_source.detect_alpha()!=Image.ALPHA_NONE and sweets_source.get_pixel(0,0).a<.01 and sweets_used.position.x>0 and sweets_used.position.y>0 and sweets_used.end.x<1254 and sweets_used.end.y<1254)
	assert(sweets_ids.size()==10)
	var metal_ids:Dictionary={}
	for metal_entry in game._series_species_entries("metal"):
		var metal_id:=str(metal_entry.get("species_id",""));var image_path:=str(metal_entry.get("image_path",""));metal_ids[metal_id]=true
		assert(str(metal_entry.get("series_id",""))=="metal" and bool(metal_entry.get("catalog_only",false)) and is_zero_approx(float(metal_entry.get("spawn_weight",-1.0))))
		assert(not bool(game.greenhouse_available.get(metal_id,false)) and metal_entry not in game.species and image_path.begins_with("res://assets/catalog/metal/") and ResourceLoader.exists(image_path))
		assert(str(game.SucculentClass.SPRITES.get(str(metal_entry.get("visual_variant","")),""))==image_path)
		var metal_texture:=load(image_path) as Texture2D;var metal_source:=metal_texture.get_image();var metal_used:=metal_source.get_used_rect();var metal_w:=metal_source.get_width();var metal_h:=metal_source.get_height();assert(metal_w>=900 and metal_h>=900 and metal_source.detect_alpha()!=Image.ALPHA_NONE and metal_source.get_pixel(0,0).a<.01 and metal_source.get_pixel(metal_w-1,0).a<.01 and metal_source.get_pixel(0,metal_h-1).a<.01 and metal_source.get_pixel(metal_w-1,metal_h-1).a<.01 and metal_used.size.x*metal_used.size.y<metal_w*metal_h, "%s size=%s alpha=%s used=%s" % [metal_id,metal_texture.get_size(),metal_source.detect_alpha(),metal_used])
	assert(metal_ids.size()==10 and game._series_cover_texture(game._series_entry("metal")).resource_path=="res://assets/catalog/metal/metal-silver-rosette.png")
	for cover_series in game.series_catalog:
		var cover_species:Array=game._series_species_entries(str(cover_series.get("series_id","")))
		if not cover_species.is_empty():assert(game._series_cover_texture(cover_series).resource_path==game._species_texture(cover_species[0]).resource_path)
	var base_style:=TextureRect.new();var gummy_style:=TextureRect.new();game._apply_encyclopedia_image_style(base_style,game._series_species_entries("base")[0],false);game._apply_encyclopedia_image_style(gummy_style,game._series_species_entries("gummy")[0],false);assert(base_style.material==null and gummy_style.material==null and base_style.modulate.is_equal_approx(Color(0.12,0.09,0.08,0.82)) and gummy_style.modulate.is_equal_approx(base_style.modulate))
	game.pending_habitat_species.clear();game._queue_random_species("シリーズ未解禁");assert(game.pending_habitat_species.is_empty())
	game.greenhouse_available["gummy_peach_milk"]=true;game.discovered["gummy_peach_milk"]=true;game._apply_saved_unlocks();assert(game.species.any(func(entry):return str(entry.species_id)=="gummy_peach_milk"));game.greenhouse_available.erase("gummy_peach_milk");game.discovered.erase("gummy_peach_milk");game._apply_saved_unlocks()
	game._sync_arrangement_ui();game.arrangement_ui.open_catalog_shop();assert(game.arrangement_ui.catalog_shop_grid.get_child_count()==game.series_catalog.size());game.arrangement_ui.visible=false
	game._open_encyclopedia();assert(game._owned_series_entries().size()==1 and game._current_series_entry().series_id=="base" and game.series_position_label.text=="1 / 1" and game.series_cover_image.texture.resource_path=="res://assets/plants/sprite-colorata.png")
	for carousel_card in game.series_carousel_cards:assert(str(carousel_card.container.get_meta("series_id"))=="base")
	game._close_encyclopedia();game.unlocked_series["sweets"]=true;game.unlocked_series["gummy"]=true;assert(game._owned_series_entries().map(func(entry):return str(entry.series_id))==["base","sweets","gummy"])
	assert(game._series_cover_texture(game._series_entry("sweets")).resource_path=="res://assets/catalog/sweets/sweets-strawberry-shortcake.png" and game._series_cover_texture(game._series_entry("gummy")).resource_path=="res://assets/catalog/gummy/gummy-peach-milk.png")
	game.selected_series_index=2;game._open_encyclopedia();assert(game.series_open_button.text=="図鑑をひらく" and not game.series_lock_label.visible and game.series_cover_image.texture.resource_path=="res://assets/catalog/gummy/gummy-peach-milk.png");game._open_selected_series_encyclopedia();await get_tree().process_frame
	assert(game.encyclopedia_list_page.visible and game.encyclopedia_list_title.text=="グミ多肉" and game.encyclopedia_grid.get_child_count()==8 and game.encyclopedia_list_progress.text=="0 / 8種" and game.encyclopedia_field_button.disabled)
	for gummy_card in game.encyclopedia_grid.get_children():
		assert(gummy_card.disabled)
		var card_texts:Array[String]=[]
		for label in gummy_card.find_children("*","Label",true,false):card_texts.append(str(label.text))
		assert("？？？" in card_texts and "未発見" in card_texts and "GET 0" in card_texts)
	game._update_encyclopedia_visible_textures()
	for gummy_image in game.encyclopedia_card_images:
		assert(gummy_image.material==null and gummy_image.modulate.is_equal_approx(Color(0.12,0.09,0.08,0.82)) and gummy_image.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		if gummy_image.texture!=null:assert(str(gummy_image.texture.resource_path).begins_with("res://assets/catalog/gummy/") and str(gummy_image.texture.resource_path).ends_with(".png"))
	base_style.free();gummy_style.free()
	var first_gummy_card:Button=game.encyclopedia_grid.get_child(0);first_gummy_card.pressed.emit();assert(not game.encyclopedia_detail_page.visible and game.encyclopedia_list_page.visible)
	game.discovered["gummy_peach_milk"]=true;game.species_get_counts["gummy_peach_milk"]=3;game._refresh_encyclopedia_header();game._refresh_encyclopedia_cards();await get_tree().process_frame;game._update_encyclopedia_visible_textures()
	var found_card:Button=game.encyclopedia_grid.get_child(0);var found_texts:Array[String]=[]
	for label in found_card.find_children("*","Label",true,false):found_texts.append(str(label.text))
	assert(not found_card.disabled and "ももミルクグミ" in found_texts and "GET 3" in found_texts and game.encyclopedia_card_images[0].material==null and game.encyclopedia_card_images[0].modulate.is_equal_approx(Color.WHITE))
	found_card.pressed.emit();assert(game.encyclopedia_detail_page.find_child("SpeciesName",true,false).text=="ももミルクグミ" and not game.encyclopedia_detail_page.find_child("SpeciesDescription",true,false).text.is_empty() and game.encyclopedia_detail_page.find_child("SpeciesGetCount",true,false).text=="GET 3" and game.encyclopedia_detail_page.find_child("SpeciesImage",true,false).material==null)
	game._close_encyclopedia();game.discovered.erase("gummy_peach_milk");game.species_get_counts.erase("gummy_peach_milk");game.selected_series_index=0
	game.selected_series_index=1;game._open_encyclopedia();assert(game.series_open_button.text=="図鑑をひらく" and game.series_cover_image.texture.resource_path=="res://assets/catalog/sweets/sweets-strawberry-shortcake.png");game._open_selected_series_encyclopedia();await get_tree().process_frame
	assert(game.encyclopedia_list_page.visible and game.encyclopedia_list_title.text=="スイーツ多肉" and game.encyclopedia_grid.get_child_count()==10 and game.encyclopedia_list_progress.text=="0 / 10種" and game.encyclopedia_field_button.disabled)
	game.discovered["sweets_strawberry_shortcake"]=true;game.species_get_counts["sweets_strawberry_shortcake"]=1;game._refresh_encyclopedia_header();game._refresh_encyclopedia_cards();await get_tree().process_frame;game._update_encyclopedia_visible_textures()
	var first_sweets_card:Button=game.encyclopedia_grid.get_child(0);assert(not first_sweets_card.disabled);first_sweets_card.pressed.emit();assert(game.encyclopedia_detail_page.find_child("SpeciesName",true,false).text=="いちごショート多肉" and game.encyclopedia_detail_page.find_child("SpeciesImage",true,false).texture.resource_path=="res://assets/catalog/sweets/sweets-strawberry-shortcake.png")
	game._close_encyclopedia();game.discovered.erase("sweets_strawberry_shortcake");game.species_get_counts.erase("sweets_strawberry_shortcake");game.selected_series_index=0
	game._open_encyclopedia();assert(game.encyclopedia_series_page.visible and not game.encyclopedia_list_page.visible and game.series_title_label.text=="基本図鑑" and not game.series_cover_placeholder.visible and game.series_cover_image.texture.resource_path=="res://assets/plants/sprite-colorata.png")
	assert(game.series_carousel_cards.size()==3)
	var previous_card:Dictionary=game.series_carousel_cards[0];var current_card:Dictionary=game.series_carousel_cards[1];var next_card:Dictionary=game.series_carousel_cards[2]
	assert(str(previous_card.container.get_meta("series_id"))=="gummy" and str(current_card.container.get_meta("series_id"))=="base" and str(next_card.container.get_meta("series_id"))=="sweets")
	assert(previous_card.container.position.x<0.0 and next_card.container.position.x>0.0)
	for detail_node in current_card.detail_nodes:assert(detail_node.get_parent()==current_card.container)
	var counts_before:Dictionary=game.species_get_counts.duplicate(true);game._refresh_series_selection();game._refresh_series_selection();assert(game.species_get_counts==counts_before)
	var swipe_start:=InputEventScreenTouch.new();swipe_start.pressed=true;swipe_start.position=Vector2(350,200);game._on_series_swipe_input(swipe_start)
	var swipe_drag:=InputEventScreenDrag.new();swipe_drag.position=Vector2(210,202);game._on_series_swipe_input(swipe_drag)
	assert(game.series_carousel_offset==-140.0 and game.series_carousel_track.position.x<game.SERIES_CAROUSEL_TRACK_ORIGIN.x and next_card.title.self_modulate.a>0.0)
	var swipe_end:=InputEventScreenTouch.new();swipe_end.pressed=false;swipe_end.position=Vector2(210,202);game._on_series_swipe_input(swipe_end);assert(game.series_carousel_animating)
	await get_tree().create_timer(.36).timeout
	assert(game._current_series_entry().series_id=="sweets" and not game.series_open_button.disabled and not game.series_lock_label.visible)
	assert(is_zero_approx(game.series_carousel_offset) and str(previous_card.container.get_meta("series_id"))=="base" and str(next_card.container.get_meta("series_id"))=="gummy")
	var short_start:=InputEventScreenTouch.new();short_start.pressed=true;short_start.position=Vector2(300,200);game._on_series_swipe_input(short_start)
	var short_drag:=InputEventScreenDrag.new();short_drag.position=Vector2(270,200);game._on_series_swipe_input(short_drag)
	var short_end:=InputEventScreenTouch.new();short_end.pressed=false;short_end.position=Vector2(270,200);game._on_series_swipe_input(short_end);await get_tree().create_timer(.28).timeout
	assert(game._current_series_entry().series_id=="sweets" and is_zero_approx(game.series_carousel_offset))
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
