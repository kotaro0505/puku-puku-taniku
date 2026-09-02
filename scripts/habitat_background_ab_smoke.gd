extends Node

func _ready()->void:
	var args:=OS.get_cmdline_user_args();var mode:="current" if args.size()<2 else str(args[1])
	assert(mode in ["current","no_sky","panorama_mesh"])
	var game=load("res://main.tscn").instantiate();game.habitat_texture_mode="thumb";game.habitat_background_mode=mode;add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._finish_opening();game.audio_manager.apply_settings({"bgm_enabled":false,"se_enabled":false});game.intro_story_complete=true;game.habitat_unlocked=true
	game.discovered={"colorata":true};game.pending_habitat_species.clear();game.habitat_mystery_seeds_pending=0
	game.current_mode="habitat";game._apply_mode()
	assert(game.habitat_texture_mode=="thumb" and game.habitat_full_texture_loads_during_build==0)
	match mode:
		"current":
			assert(game.habitat_environment.background_mode==Environment.BG_SKY and game.habitat_environment.sky!=null and game.habitat_panorama_mesh==null)
			assert(game.habitat_environment.sky.radiance_size==Sky.RADIANCE_SIZE_512)
			assert(game.habitat_environment.sky.sky_material is PanoramaSkyMaterial)
		"no_sky":
			assert(game.habitat_environment.background_mode==Environment.BG_COLOR and game.habitat_environment.sky==null and game.habitat_panorama_mesh==null)
		"panorama_mesh":
			assert(game.habitat_environment.background_mode==Environment.BG_COLOR and game.habitat_environment.sky==null and game.habitat_panorama_mesh!=null and game.habitat_panorama_mesh.visible)
			var material:=game.habitat_panorama_mesh.material_override as StandardMaterial3D
			assert(material!=null and material.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED and material.cull_mode==BaseMaterial3D.CULL_FRONT and material.no_depth_test)
			assert(material.albedo_texture!=null and material.albedo_texture.resource_path=="res://assets/highland-panorama.jpg")
	game.current_mode="greenhouse";game._apply_mode()
	assert(game.habitat_environment.background_mode==Environment.BG_CANVAS)
	if game.habitat_panorama_mesh:assert(not game.habitat_panorama_mesh.visible)
	assert(game.audio_manager._stream_for("bgm","habitat") is AudioStreamOggVorbis)
	print("HABITAT_BACKGROUND_AB_SMOKE_OK mode=",mode," texture_mode=",game.habitat_texture_mode," full_texture_loads=",game.habitat_full_texture_loads_during_build)
	game.free();await get_tree().process_frame;get_tree().quit()
