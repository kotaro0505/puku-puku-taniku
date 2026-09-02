extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game._finish_opening()
	game.intro_story_complete=true
	game.habitat_unlocked=true
	game.encyclopedia_unlocked=true
	game.discovered["colorata"]=true
	var retained_habitat_ids:Array=[]
	for cycle in range(12):
		if game.current_mode!="greenhouse":game._toggle_mode()
		game._toggle_mode()
		assert(game.current_mode=="habitat" and game.habitat_items_root.get_child_count()>0)
		var current_ids:Array=game.habitat_items_root.get_children().map(func(node):return node.get_instance_id())
		if retained_habitat_ids.is_empty():retained_habitat_ids=current_ids
		else:assert(current_ids==retained_habitat_ids)
		game._toggle_mode()
		assert(game.current_mode=="greenhouse" and game.habitat_items_root.get_child_count()>0 and not game.habitat_pickups.is_empty())
		game._open_shop();game._close_shop()
		game._open_encyclopedia()
		await get_tree().process_frame
		await get_tree().process_frame
		var loaded_cards:int=game.encyclopedia_card_images.filter(func(image):return image.texture!=null).size()
		assert(loaded_cards>0 and loaded_cards<game.catalog_species.size())
		game._close_encyclopedia()
		assert(game.encyclopedia_card_images.all(func(image):return image.texture==null))
	for rain_cycle in range(6):
		if game.current_mode!="habitat":game._toggle_mode()
		game.rain_event_pending=true
		game._start_rain_bonus()
		assert(game.rain_visual!=null and game.rain_drops.size()==30)
		game._finish_rain_bonus()
		assert(game.rain_visual==null and game.rain_drops.is_empty())
		game._toggle_mode()
		assert(game.habitat_items_root.get_child_count()>0)
	game.habitat_reuse_ab_enabled=false
	game._toggle_mode();assert(game.current_mode=="habitat" and game.habitat_items_root.get_child_count()>0)
	game._toggle_mode();assert(game.current_mode=="greenhouse" and game.habitat_items_root.get_child_count()==0)
	game.audio_manager.play_bgm("greenhouse",true)
	await get_tree().create_timer(.55).timeout
	game.audio_manager.play_bgm("habitat",true)
	await get_tree().create_timer(.55).timeout
	var inactive_player=game.audio_manager.bgm_players[1-game.audio_manager.active_bgm]
	assert(inactive_player.stream==null and not inactive_player.playing)
	print("WEB_MEMORY_SMOKE_OK cycles=12 rain=6 loaded_cards=",game.encyclopedia_card_images.filter(func(image):return image.texture!=null).size())
	game.free()
	await get_tree().process_frame
	get_tree().quit()
