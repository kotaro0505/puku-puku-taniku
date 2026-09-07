extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.DEVELOPMENT_CATALOG_PREVIEW_ENABLED)
	assert(game.catalog_preview_ui!=null)
	assert(game.catalog_preview_settings_button!=null)
	var settings_panel:Control=game.settings_overlay.get_child(1)
	assert(settings_panel.position.y+settings_panel.size.y<=get_viewport().get_visible_rect().size.y)
	var preview_panel:Control=game.catalog_preview_ui.overlay.get_child(1)
	assert(preview_panel.position.y+preview_panel.size.y<=get_viewport().get_visible_rect().size.y)
	assert(game.catalog_preview_ui.group_count()==game.series_catalog.size())
	var gummy_ids:Array=game.catalog_preview_ui.species_ids_for_series("gummy")
	assert(gummy_ids.size()==8)
	var future_species:Array=game.catalog_species.duplicate(true)
	future_species.append({"species_id":"future_preview_probe","name_ja":"将来品種","series_id":"future_preview","spawn_weight":0.0,"catalog_only":true})
	var future_series:Array=game.series_catalog.duplicate(true)
	future_series.append({"series_id":"future_preview","display_name":"将来シリーズ","species_ids":[]})
	game.catalog_preview_ui.configure(future_species,future_series)
	assert(game.catalog_preview_ui.species_ids_for_series("future_preview")==["future_preview_probe"])
	game.catalog_preview_ui.configure(game.catalog_species,game.series_catalog)
	for species_id_value in gummy_ids:
		var entry:Dictionary=game._catalog_entry(str(species_id_value))
		assert(bool(entry.get("catalog_only",false)))
		assert(is_zero_approx(float(entry.get("spawn_weight",-1.0))))
		for formal_entry in game.species:assert(str(formal_entry.get("species_id",""))!=str(species_id_value))
	var preview_source:=FileAccess.get_file_as_string("res://scripts/catalog_preview_dev.gd")
	assert("gummy_" not in preview_source)
	var saved_before:=""
	if FileAccess.file_exists("user://records.json"):saved_before=FileAccess.get_file_as_string("user://records.json")
	var bests_before:Dictionary=game.bests.duplicate(true)
	var discovered_before:Dictionary=game.discovered.duplicate(true)
	var get_counts_before:Dictionary=game.species_get_counts.duplicate(true)
	var unlocked_before:Dictionary=game.unlocked_species.duplicate(true)
	var greenhouse_before:Dictionary=game.greenhouse_available.duplicate(true)
	var coins_before:int=game.coins
	var total_play_before:int=game.total_play_count
	var formal_play_before:int=game.formal_play_count
	var main_rng_state_before:int=game.rng.state
	game.opening_overlay.visible=false
	game.intro_overlay.visible=false
	game.settings_overlay.visible=false
	game.result_overlay.visible=false
	game.shop_overlay.visible=false
	game.encyclopedia_overlay.visible=false
	game.play_overlay.visible=false
	game._open_catalog_preview_dev()
	assert(game.catalog_preview_ui.is_overlay_open())
	game.catalog_preview_ui._close_overlay()
	assert(not game.catalog_preview_ui.is_overlay_open())
	game.catalog_species.append({"species_id":"future_image_probe","name_ja":"将来画像テスト","series_id":"future_preview","visual_variant":"not_in_sprite_table","image_path":"res://assets/plants/gummy/gummy-soda.png","spawn_weight":0.0,"catalog_only":true})
	game._preview_catalog_species("future_image_probe")
	assert(game._catalog_preview_plants().size()==1)
	assert(game._catalog_preview_plants()[0].plant_sprite.texture.resource_path=="res://assets/plants/gummy/gummy-soda.png")
	game._clear_catalog_preview_plants()
	game.catalog_species.pop_back()
	game._preview_catalog_species(str(gummy_ids[0]))
	assert(game.catalog_preview_mode_active)
	assert(game._catalog_preview_plants().size()==1)
	assert(game.rng.state==main_rng_state_before)
	var preview_plant=game._catalog_preview_plants()[0]
	assert(bool(preview_plant.get_meta("catalog_preview",false)))
	assert(str(preview_plant.data.get("species_id",""))==str(gummy_ids[0]))
	assert(preview_plant.jelly_checks_enabled)
	preview_plant.jelly_checks_enabled=false
	var diameter_before:float=preview_plant.diameter_cm
	preview_plant.simulate(.5)
	assert(preview_plant.diameter_cm>diameter_before)
	preview_plant.fast_forward_to_diameter(100.0)
	assert(preview_plant.diameter_cm>99.9)
	preview_plant.harvest()
	assert(game._catalog_preview_plants().is_empty())
	game._preview_catalog_batch(gummy_ids,"グミ多肉")
	assert(game._catalog_preview_plants().size()==8)
	var spawned_ids:Dictionary={}
	for plant in game._catalog_preview_plants():spawned_ids[str(plant.data.get("species_id",""))]=true
	for species_id_value in gummy_ids:assert(spawned_ids.has(str(species_id_value)))
	game.catalog_preview_ui._preview_next_series_batch()
	var base_ids:Array=game.catalog_preview_ui.species_ids_for_series("base")
	assert(game._catalog_preview_plants().size()==mini(base_ids.size(),game.catalog_preview_ui.MAX_PLANTS_PER_BATCH))
	game._clear_catalog_preview_plants()
	assert(not game.catalog_preview_mode_active and game._catalog_preview_plants().is_empty())
	assert(game.bests==bests_before)
	assert(game.discovered==discovered_before)
	assert(game.species_get_counts==get_counts_before)
	assert(game.unlocked_species==unlocked_before)
	assert(game.greenhouse_available==greenhouse_before)
	assert(game.coins==coins_before)
	assert(game.total_play_count==total_play_before)
	assert(game.formal_play_count==formal_play_before)
	assert(game.rng.state==main_rng_state_before)
	if FileAccess.file_exists("user://records.json"):assert(FileAccess.get_file_as_string("user://records.json")==saved_before)
	print("CATALOG_PREVIEW_DEV_SMOKE_OK series=",game.catalog_preview_ui.group_count()," gummy=",gummy_ids.size()," base_batch=",mini(base_ids.size(),game.catalog_preview_ui.MAX_PLANTS_PER_BATCH)," save_unchanged=true rng_isolated=true")
	get_tree().quit()
