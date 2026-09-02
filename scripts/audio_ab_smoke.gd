extends Node

func _ready()->void:
	var manager=load("res://scripts/audio_manager.gd").new();add_child(manager)
	await get_tree().process_frame
	manager.bgm_format="ogg"
	var ogg=manager._stream_for("bgm","greenhouse")
	assert(ogg is AudioStreamOggVorbis)
	manager.bgm_format="wav"
	var wav=manager._stream_for("bgm","greenhouse")
	assert(wav is AudioStreamWAV)
	var player:AudioStreamPlayer=manager.bgm_players[0]
	player.stream=ogg;manager.release_stream_on_stop=false;manager._stop_and_release_bgm_player(player)
	assert(player.stream==ogg)
	manager.release_stream_on_stop=true;manager._stop_and_release_bgm_player(player)
	assert(player.stream==null)
	assert(ogg!=wav)
	manager.bgm_format="ogg";manager.release_stream_on_stop=false;manager.play_bgm("greenhouse",true)
	await get_tree().create_timer(.5).timeout;manager.play_bgm("habitat",true);await get_tree().create_timer(.5).timeout
	assert(manager.bgm_players[1-manager.active_bgm].stream!=null)
	manager.release_stream_on_stop=true;manager.play_bgm("greenhouse",true);await get_tree().create_timer(.5).timeout
	assert(manager.bgm_players[1-manager.active_bgm].stream==null)
	manager.bgm_format="wav";manager.play_bgm("habitat",true)
	assert(manager.bgm_players[manager.active_bgm].stream is AudioStreamWAV)
	print("AUDIO_AB_SMOKE_OK ogg=",ogg.get_class()," wav=",wav.get_class())
	get_tree().quit()
