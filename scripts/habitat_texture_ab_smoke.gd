extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._finish_opening();game.audio_manager.apply_settings({"bgm_enabled":false,"se_enabled":false})
	game._reset_progression_state();game.intro_story_complete=true;game.habitat_unlocked=true;game.encyclopedia_unlocked=true
	game.current_mode="habitat";game.pending_habitat_species.clear();game.habitat_mystery_seeds_pending=0
	game._ensure_habitat_wild_state();assert(game.habitat_wild_plants.size()>=game.HabitatWildSystemClass.INITIAL_POPULATION_MIN and game.habitat_wild_plants.size()<=game.HabitatWildSystemClass.INITIAL_POPULATION_MAX)
	# Keep A/B captures deterministic: persistent habitat plants normally keep
	# growing between the two builds, which would legitimately change scale.
	var frozen_update:=int(Time.get_unix_time_from_system())+3600
	for plant in game.habitat_wild_plants:plant["last_updated_unix"]=frozen_update
	game.habitat_texture_mode="full";game._build_habitat_items(true)
	assert(game.habitat_full_texture_loads_during_build>0)
	var full_visuals:=_capture_visuals(game);assert(full_visuals.size()==game.habitat_wild_plants.size())
	for value in full_visuals.values():assert("/habitat/" not in str(value.path))
	game.habitat_texture_mode="thumb";game._build_habitat_items(true)
	assert(game.habitat_full_texture_loads_during_build==0)
	assert(game.habitat_texture_max_size.x<=320 and game.habitat_texture_max_size.y<=320)
	var thumb_visuals:=_capture_visuals(game);assert(thumb_visuals.keys()==full_visuals.keys())
	for individual_id in thumb_visuals:
		var full:Dictionary=full_visuals[individual_id];var thumb:Dictionary=thumb_visuals[individual_id]
		assert("/habitat/" in str(thumb.path),"missing habitat thumbnail for %s: %s"%[str(thumb.species_id),str(thumb.path)])
		assert(is_equal_approx(float(full.scale),float(thumb.scale)),"habitat scale changed for %s"%str(thumb.species_id))
		assert(absf(float(full.world_width)-float(thumb.world_width))<0.0001)
		assert(absf(float(full.world_height)-float(thumb.world_height))<0.006)
		assert(absf(float(full.world_offset)-float(thumb.world_offset))<0.002)
	var first_plant:Dictionary=game.habitat_wild_plants[0];var first_id:=str(first_plant.individual_id);var scale_before:float=float(thumb_visuals[first_id].scale)
	game.bests[str(first_plant.species_id)]=100.0;game._build_habitat_items(true)
	assert(is_equal_approx(float(_capture_visuals(game)[first_id].scale),scale_before))
	game.pending_habitat_species=["transparent_succulent"];game.habitat_mystery_seeds_pending=2;game._build_habitat_items(true)
	assert(game.habitat_pickups.filter(func(item):return str(item.kind)=="wild_plant").size()>=game.HabitatWildSystemClass.INITIAL_POPULATION_MIN)
	assert(game.habitat_pickups.filter(func(item):return str(item.kind) in ["new_species","found_species"]).is_empty())
	assert(game.habitat_pickups.filter(func(item):return str(item.kind)=="seed").size()==2)
	var bgm=game.audio_manager._stream_for("bgm","greenhouse");assert(bgm is AudioStreamOggVorbis)
	var audio_config=JSON.parse_string(FileAccess.get_file_as_string("res://data/audio-config.json"));assert(audio_config is Dictionary and not audio_config.has("bgm_wav"))
	print("HABITAT_TEXTURE_AB_SMOKE_OK wild=",game.habitat_wild_plants.size()," thumb_textures=",game.habitat_texture_count," no_best_sync=true")
	game.free();await get_tree().process_frame;get_tree().quit()

func _capture_visuals(game:Node)->Dictionary:
	var captured:Dictionary={}
	for item in game.habitat_pickups:
		if str(item.kind)!="wild_plant":continue
		var sprite:Sprite3D=item.node;var texture:Texture2D=sprite.texture
		captured[str(item.individual_id)]={
			"species_id":str(item.species_id),
			"path":texture.resource_path,
			"scale":sprite.scale.x,
			"world_width":texture.get_width()*sprite.pixel_size*sprite.scale.x,
			"world_height":texture.get_height()*sprite.pixel_size*sprite.scale.y,
			"world_offset":sprite.offset.y*sprite.pixel_size*sprite.scale.y,
		}
	return captured
