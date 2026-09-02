extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._finish_opening();game.audio_manager.apply_settings({"bgm_enabled":false,"se_enabled":false})
	game.intro_story_complete=true;game.habitat_unlocked=true;game.encyclopedia_unlocked=true
	game.current_mode="habitat";game.pending_habitat_species.clear();game.habitat_mystery_seeds_pending=0
	game.discovered.clear();game.bests.clear()
	var expected_paths:Dictionary={};var missing:Array[String]=[];var best_values:=[0.0,30.0,60.0,100.0]
	for i in range(game.catalog_species.size()):
		var entry:Dictionary=game.catalog_species[i];var species_id:=str(entry.species_id);var path:=str(entry.get("habitat_image_path",""))
		if path.is_empty():missing.append(species_id);continue
		assert(ResourceLoader.exists(path));var texture:=load(path) as Texture2D;assert(texture!=null and maxi(texture.get_width(),texture.get_height())<=320)
		expected_paths[path]=true;game.discovered[species_id]=true;game.bests[species_id]=best_values[i%best_values.size()]
	game.habitat_texture_mode="full";game._build_habitat_items(true)
	assert(game.habitat_full_texture_loads_during_build>0)
	var full_visuals:=_capture_visuals(game)
	assert(not full_visuals.is_empty())
	for value in full_visuals.values():assert("/habitat/" not in str(value.path))
	game.habitat_texture_mode="thumb";game._build_habitat_items(true)
	assert(game.habitat_full_texture_loads_during_build==0)
	assert(game.habitat_texture_count==expected_paths.size())
	assert(game.habitat_texture_max_size.x<=320 and game.habitat_texture_max_size.y<=320)
	var thumb_visuals:=_capture_visuals(game);assert(thumb_visuals.keys()==full_visuals.keys())
	for species_id in thumb_visuals:
		var full:Dictionary=full_visuals[species_id];var thumb:Dictionary=thumb_visuals[species_id]
		assert("/habitat/" in str(thumb.path));assert(is_equal_approx(float(full.scale),float(thumb.scale)))
		assert(absf(float(full.world_width)-float(thumb.world_width))<0.0001)
		assert(absf(float(full.world_height)-float(thumb.world_height))<0.006)
		assert(absf(float(full.world_offset)-float(thumb.world_offset))<0.002)
	for best_cm in [0.0,30.0,60.0,100.0]:
		game.bests["colorata"]=best_cm
		var expected:=1.0 if best_cm<=0.0 else clampf(.18+(best_cm-1.6)*.058,.55,3.25)
		assert(is_equal_approx(game._habitat_best_visual_scale("colorata"),expected))
	game.discovered={"colorata":true};game.pending_habitat_species=["lutea"];game.habitat_mystery_seeds_pending=2;game._build_habitat_items(true)
	assert(game.habitat_full_texture_loads_during_build==0)
	var new_items:Array=game.habitat_pickups.filter(func(item):return str(item.kind)=="new_species")
	assert(new_items.size()==1 and new_items[0].node.get_children().any(func(child):return child is Label3D and child.text=="NEW!"))
	assert(game.habitat_pickups.filter(func(item):return str(item.kind)=="seed").size()==2)
	var full_texture=game._species_texture(game._catalog_entry("colorata"));assert(full_texture!=null and "/habitat/" not in full_texture.resource_path)
	var bgm=game.audio_manager._stream_for("bgm","greenhouse");assert(bgm is AudioStreamOggVorbis)
	var audio_config=JSON.parse_string(FileAccess.get_file_as_string("res://data/audio-config.json"));assert(audio_config is Dictionary and not audio_config.has("bgm_wav"))
	print("HABITAT_TEXTURE_AB_SMOKE_OK thumbnails=",expected_paths.size()," missing=",missing," scale_cases=0,30,60,100 full_loads_thumb=",game.habitat_full_texture_loads_during_build)
	game.free();await get_tree().process_frame;get_tree().quit()

func _capture_visuals(game:Node)->Dictionary:
	var captured:Dictionary={}
	for item in game.habitat_pickups:
		if str(item.kind)!="found_species":continue
		var sprite:Sprite3D=item.node;var texture:Texture2D=sprite.texture
		captured[str(item.species_id)]={
			"path":texture.resource_path,
			"scale":sprite.scale.x,
			"world_width":texture.get_width()*sprite.pixel_size*sprite.scale.x,
			"world_height":texture.get_height()*sprite.pixel_size*sprite.scale.y,
			"world_offset":sprite.offset.y*sprite.pixel_size*sprite.scale.y,
		}
	return captured
