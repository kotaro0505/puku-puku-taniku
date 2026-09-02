extends Node

func _ready()->void:
	var args:=OS.get_cmdline_user_args();var mode:="thumb" if args.size()>1 and str(args[1])=="thumb" else "full"
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._finish_opening();game.audio_manager.apply_settings({"bgm_enabled":false,"se_enabled":false});game.habitat_texture_mode=mode
	game.intro_story_complete=true;game.habitat_unlocked=true;game.current_mode="greenhouse";game._clear_habitat_items();game.pending_habitat_species.clear();game.habitat_mystery_seeds_pending=0
	game.discovered.clear();game.bests.clear()
	for entry in game.catalog_species:
		if str(entry.get("habitat_image_path",""))!="":game.discovered[str(entry.species_id)]=true;game.bests[str(entry.species_id)]=60.0
	await _settle_frames(4)
	var before:=_snapshot("before",mode)
	game.current_mode="habitat";game._apply_mode()
	var immediate:=_snapshot("immediate_after",mode)
	await _settle_frames(4)
	var after:=_snapshot("after",mode)
	var full_loads:int=game.habitat_full_texture_loads_during_build
	game.current_mode="greenhouse";game._apply_mode();await _settle_frames(4)
	var exited:=_snapshot("exit",mode)
	if mode=="thumb":assert(full_loads==0)
	print("HABITAT_TEXTURE_PROBE mode=",mode," before=",before.memory_static," immediate_after=",immediate.memory_static," immediate_delta=",int(immediate.memory_static)-int(before.memory_static)," settled_after=",after.memory_static," settled_delta=",int(after.memory_static)-int(before.memory_static)," exit=",exited.memory_static," full_texture_loads_during_habitat_build=",full_loads," gpu_memory=unavailable")
	game.free();await get_tree().process_frame;get_tree().quit()

func _snapshot(point:String,mode:String)->Dictionary:
	var values:={
		"memory_static":int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"memory_static_max":int(Performance.get_monitor(Performance.MEMORY_STATIC_MAX)),
		"object_count":int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"resource_count":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"node_count":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
	}
	print("HABITAT_TEXTURE_PROBE_SNAPSHOT mode=",mode," point=",point," values=",values)
	return values

func _settle_frames(count:int)->void:
	for i in range(count):await get_tree().process_frame
