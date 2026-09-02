extends Node

const TRANSITION_CYCLES := 20
const ENCYCLOPEDIA_CYCLES := 10

func _snapshot(stage:String, game:Node)->void:
	var values:={
		"stage":stage,
		"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"orphans":int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"static_max_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC_MAX)),
		"render_objects":int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"render_primitives":int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"video_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
		"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
		"habitat_children":game.habitat_items_root.get_child_count(),
		"catalog_cards":game.encyclopedia_grid.get_child_count()
	}
	print("MEMORY_REGRESSION ",JSON.stringify(values))

func _settle(frames:=3)->void:
	for _i in range(frames):await get_tree().process_frame

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await _settle(4)
	if game.opening_overlay.visible:game._finish_opening()
	game.audio_settings["bgm_enabled"]=false;game.audio_manager.apply_settings(game.audio_settings)
	game.intro_story_complete=true;game.habitat_unlocked=true;game.encyclopedia_unlocked=true
	game.tutorial_steps["habitat_scroll_dialog"]=true;game.tutorial_steps["rain_first_dialog"]=true
	game.rain_event_pending=false;game.rain_bonus_active=false
	for entry in game.catalog_species:game.discovered[str(entry.species_id)]=true
	game.current_mode="greenhouse";game._apply_mode();await _settle()
	var audio_path:="res://assets/audio/puku-puku-taniku-main.ogg" if ResourceLoader.exists("res://assets/audio/puku-puku-taniku-main.ogg") else "res://assets/audio/puku-puku-taniku-main.wav"
	var ogg_a=load(audio_path)
	var ogg_b=load(audio_path)
	var first_texture=game._species_texture(game.catalog_species[0])
	var second_texture=game._species_texture(game.catalog_species[0])
	print("RESOURCE_IDENTITY ogg_same=",ogg_a==ogg_b," texture_same=",first_texture==second_texture)
	_snapshot("baseline",game)
	for cycle in range(TRANSITION_CYCLES):
		game._toggle_mode();await _settle()
		if cycle in [0,9,19]:_snapshot("habitat_enter_%d"%(cycle+1),game)
		game._toggle_mode();await _settle()
		if cycle in [0,9,19]:_snapshot("habitat_exit_%d"%(cycle+1),game)
	for cycle in range(ENCYCLOPEDIA_CYCLES):
		game._open_encyclopedia();await _settle(5)
		game.encyclopedia_scroll.scroll_vertical=100000;game._update_encyclopedia_visible_textures();await _settle()
		if cycle in [0,4,9]:_snapshot("encyclopedia_bottom_%d"%(cycle+1),game)
		game._close_encyclopedia();await _settle()
		if cycle in [0,4,9]:_snapshot("encyclopedia_close_%d"%(cycle+1),game)
	if "jelly_dev_overlay" in game and game.jelly_dev_overlay:
		print("JELLY_UI_RESIDENT_NODES ",game.jelly_dev_overlay.find_children("*","",true,false).size()+1," visible=",game.jelly_dev_overlay.visible)
	_snapshot("final",game)
	if "jelly_dev_overlay" in game and game.jelly_dev_overlay:
		game.jelly_dev_overlay.free();game.jelly_dev_overlay=null;await _settle()
		_snapshot("after_jelly_ui_free_for_measurement",game)
	print("MEMORY_REGRESSION_PROBE_OK")
	get_tree().quit()
