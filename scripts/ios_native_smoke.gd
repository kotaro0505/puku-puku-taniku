extends Node

func _ready() -> void:
	assert(not OS.has_feature("web"))
	assert(ProjectSettings.get_setting("application/config/name") == "ぷくぷく多肉")
	assert(ProjectSettings.get_setting("application/config/version") == "1.0.0")
	assert(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility")
	assert(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile") == "gl_compatibility")
	assert(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc"))
	assert(FileAccess.file_exists("res://ios/plugins/SharePlugin.gdip"))
	assert(FileAccess.file_exists("res://ios/plugins/SharePlugin.debug.xcframework/ios-arm64/SharePlugin.a"))
	assert(FileAccess.file_exists("res://ios/plugins/SharePlugin.release.xcframework/ios-arm64/SharePlugin.a"))
	assert(FileAccess.get_file_as_string("res://export_presets.cfg").contains("plugins/SharePlugin=true"))
	var main_source:=FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(main_source.contains('Engine.has_singleton("SharePlugin")'))
	assert(main_source.contains('has_method("share_image")'))
	assert(main_source.contains('"share_image",'))
	assert(not main_source.contains('has_method("share")'))
	assert(main_source.contains("navigator.share"))

	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.habitat_texture_mode == "full")
	assert(game.habitat_background_mode == "current")
	game.current_mode = "habitat"
	game._apply_mode()
	assert(game.habitat_environment.background_mode == Environment.BG_SKY)
	assert(game.habitat_environment.sky != null)
	assert(game.habitat_environment.sky.radiance_size == Sky.RADIANCE_SIZE_512)
	assert(game.habitat_panorama_mesh == null)
	assert(game.audio_manager.web_audio_unlocked)
	assert(game.audio_manager._stream_for("bgm", "greenhouse") is AudioStreamOggVorbis)
	assert(game.arrangement_ui!=null and game.pot_catalog.size()>=1)
	assert(bool(game.owned_pots.get("shallow_terracotta",false)))
	# Habitat plants have their own persistent size; greenhouse records do not alter them.
	game.habitat_wild_plants.clear()
	game.habitat_wild_initialized=false
	game.habitat_wild_next_spawn_unix=0
	game.pending_habitat_species.clear()
	game.habitat_tutorial_complete=true
	game._build_habitat_items(true)
	assert(game.habitat_wild_plants.size()>=game.HabitatWildSystemClass.INITIAL_POPULATION_MIN and game.habitat_wild_plants.size()<=game.HabitatWildSystemClass.INITIAL_POPULATION_MAX)
	var first_wild_item:Dictionary=game.habitat_pickups.filter(func(item):return str(item.kind)=="wild_plant")[0]
	var first_wild_id:=str(first_wild_item.individual_id)
	var first_wild_scale:Vector3=first_wild_item.node.scale
	game.bests["colorata"] = 100.0
	game._build_habitat_items(true)
	var rebuilt_matches:Array=game.habitat_pickups.filter(func(item):return str(item.kind)=="wild_plant" and str(item.individual_id)==first_wild_id)
	assert(rebuilt_matches.size()==1)
	# A second may tick during this native smoke, so allow only the tiny independent
	# habitat-growth delta. A 100 cm greenhouse record must never resize the plant.
	assert((rebuilt_matches[0].node.scale as Vector3).distance_to(first_wild_scale)<0.03)

	var save_probe_path := "user://ios-native-save-probe.tmp"
	var probe := FileAccess.open(save_probe_path, FileAccess.WRITE)
	assert(probe != null)
	probe.store_string("ios-native-save-ok")
	probe.close()
	assert(FileAccess.get_file_as_string(save_probe_path) == "ios-native-save-ok")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_probe_path))

	print("IOS_NATIVE_SMOKE_OK renderer=gl_compatibility texture=full background=current audio=ogg share=plugin+web-fallback save=user")
	game.free()
	await get_tree().process_frame
	get_tree().quit()
