extends Node

func _ready() -> void:
	assert(not OS.has_feature("web"))
	assert(ProjectSettings.get_setting("application/config/name") == "ぷくぷく多肉")
	assert(ProjectSettings.get_setting("application/config/version") == "1.0.0")
	assert(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility")
	assert(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile") == "gl_compatibility")
	assert(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc"))

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
	assert(bool(game.owned_pots.get("starter_terracotta",false)))
	# Keep this scale check independent from saves written by earlier smoke tests.
	game.bests.erase("colorata")
	assert(is_equal_approx(game._habitat_best_visual_scale("colorata"), 1.0))
	game.bests["colorata"] = 100.0
	assert(is_equal_approx(game._habitat_best_visual_scale("colorata"), 3.25))

	var save_probe_path := "user://ios-native-save-probe.tmp"
	var probe := FileAccess.open(save_probe_path, FileAccess.WRITE)
	assert(probe != null)
	probe.store_string("ios-native-save-ok")
	probe.close()
	assert(FileAccess.get_file_as_string(save_probe_path) == "ios-native-save-ok")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_probe_path))

	print("IOS_NATIVE_SMOKE_OK renderer=gl_compatibility texture=full background=current audio=ogg save=user")
	game.free()
	await get_tree().process_frame
	get_tree().quit()
