extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.opening_story_complete=true
	game._finish_opening()
	game._reset_progression_state()
	game.intro_story_complete=true
	game.first_colorata_confirmed=true
	game.trio_originals_confirmed=true
	game.habitat_unlocked=true
	game.habitat_arrival_started=true
	game.habitat_awakened=true
	game.habitat_awakening_event_complete=true
	game.habitat_tutorial_started=true
	game.habitat_tutorial_complete=true
	game.mystery_items_acquired=true
	game.mystery_catalog_tutorial_complete=true
	game.seed_shop_open=true
	game.puku_gauge_intro_complete=true
	game.encyclopedia_unlocked=true
	game.unlocked_series["base"]=true
	game.selected_series_index=0
	game.discovered["colorata"]=true
	game.habitat_returned_species={"colorata":true,"affinis":true,"shaviana":true}
	for cycle in range(12):
		if game.current_mode!="greenhouse":game._toggle_mode()
		game._toggle_mode()
		assert(game.current_mode=="habitat" and game.habitat_items_root.get_child_count()>0)
		game._toggle_mode()
		assert(game.current_mode=="greenhouse" and game.habitat_items_root.get_child_count()==0 and game.habitat_pickups.is_empty())
		game._open_shop();game._close_shop()
		game._open_encyclopedia()
		game._open_selected_series_encyclopedia()
		await get_tree().process_frame
		await get_tree().process_frame
		var loaded_cards:int=game.encyclopedia_card_images.filter(func(image):return image.texture!=null).size()
		assert(loaded_cards>0 and loaded_cards<game.catalog_species.size())
		game._close_encyclopedia()
		assert(game.encyclopedia_card_images.all(func(image):return image.texture==null))
	game.rain_event_pending=false;game.rain_bonus_active=false;game._roll_rain_event()
	assert(not game.rain_event_pending and not game.rain_bonus_active and game.rain_visual==null and game.rain_drops.is_empty())
	game.audio_manager.play_bgm("greenhouse",true)
	await get_tree().create_timer(.55).timeout
	game.audio_manager.play_bgm("habitat",true)
	await get_tree().create_timer(.55).timeout
	var inactive_player=game.audio_manager.bgm_players[1-game.audio_manager.active_bgm]
	assert(inactive_player.stream==null and not inactive_player.playing)
	print("WEB_MEMORY_SMOKE_OK cycles=12 observation_habitat=true rain_bonus=retired loaded_cards=",game.encyclopedia_card_images.filter(func(image):return image.texture!=null).size())
	game.free()
	await get_tree().process_frame
	get_tree().quit()
