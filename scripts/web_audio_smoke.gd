extends Node

const AudioManagerClass = preload("res://scripts/audio_manager.gd")

func _ready() -> void:
	var audio = AudioManagerClass.new()
	audio.web_audio_mode = true
	audio.web_audio_unlocked = false
	add_child(audio)
	await get_tree().process_frame
	assert(audio.bgm_players.size() == 2)
	assert(audio.se_players.size() == audio.SE_POOL_SIZE)
	for player in audio.bgm_players:
		assert(player.playback_type == AudioServer.PLAYBACK_TYPE_STREAM)
	for player in audio.se_players:
		assert(player.playback_type == AudioServer.PLAYBACK_TYPE_DEFAULT)

	audio.apply_settings({"bgm_enabled":true,"se_enabled":true,"bgm_volume":0.65,"se_volume":0.62})
	var existing_harvest:=audio._stream_for("se","harvest")
	assert(existing_harvest is AudioStreamWAV and is_equal_approx(existing_harvest.get_length(),.18))
	audio.set_harvest_test_variant(1,true)
	var firefly_1:=audio._stream_for("se","harvest") as AudioStreamWAV
	assert(firefly_1!=null and is_equal_approx(firefly_1.get_length(),3551.0/48000.0))
	audio.play_se("harvest",.55)
	assert(audio.last_se_key=="harvest" and audio.se_players[0].stream==firefly_1)
	audio.set_harvest_test_variant(2,true)
	var firefly_2:=audio._stream_for("se","harvest") as AudioStreamWAV
	assert(firefly_2!=null and is_equal_approx(firefly_2.get_length(),2086.0/48000.0) and firefly_2!=firefly_1)
	for i in range(audio.SE_POOL_SIZE+2):audio.play_se("harvest",.55)
	assert(audio.se_players.all(func(player:AudioStreamPlayer)->bool:return player.stream==firefly_2))
	audio.apply_settings({"bgm_enabled":true,"se_enabled":false,"bgm_volume":0.65,"se_volume":0.62})
	audio.last_se_key="";audio.play_se("harvest",.55);assert(audio.last_se_key.is_empty())
	audio.set_harvest_test_variant(2,false)
	assert(audio.harvest_test_variant==0 and audio._stream_for("se","harvest")==existing_harvest)
	audio.apply_settings({"bgm_enabled":true,"se_enabled":true,"bgm_volume":0.65,"se_volume":0.62})
	audio.play_bgm("opening")
	assert(audio.current_bgm_key == "opening")
	assert(_playing_count(audio) == 0)
	for player in audio.bgm_players: assert(player.stream == null)

	audio.notify_user_gesture()
	assert(audio.web_audio_unlocked)
	assert(_playing_count(audio) == 1)
	var first_active:int = int(audio.active_bgm)
	audio.notify_user_gesture()
	assert(audio.active_bgm == first_active and _playing_count(audio) == 1)

	audio.play_bgm("greenhouse")
	await get_tree().create_timer(audio.BGM_FADE_SECONDS + 0.10).timeout
	_assert_single_finished_crossfade(audio, "greenhouse")
	audio.play_bgm("shop")
	audio.play_bgm("habitat")
	await get_tree().create_timer(audio.BGM_FADE_SECONDS + 0.10).timeout
	_assert_single_finished_crossfade(audio, "habitat")

	var bgm_config:Dictionary = audio.config.get("bgm", {})
	assert(str(bgm_config.get("jurejure", "")) == "res://assets/audio/jurejure-gang-theme.mp3")
	assert(str(bgm_config.get("puku_battle", "")) == "res://assets/audio/puku-puku-battle.mp3")
	assert(str(bgm_config.get("habitat_crisis", "")) == "res://assets/audio/habitat-weakened-theme.mp3")
	assert(str(bgm_config.get("ending", "")) == "res://assets/audio/ending-pssshh-new-batch.mp3")
	audio.play_bgm("jurejure")
	await get_tree().create_timer(audio.BGM_FADE_SECONDS + 0.10).timeout
	_assert_single_finished_crossfade(audio, "jurejure")
	var jurejure_stream:AudioStreamMP3 = audio.bgm_players[audio.active_bgm].stream as AudioStreamMP3
	assert(jurejure_stream != null and jurejure_stream.loop)
	audio.play_bgm("puku_battle")
	await get_tree().create_timer(audio.BGM_FADE_SECONDS + 0.10).timeout
	_assert_single_finished_crossfade(audio, "puku_battle")
	var battle_stream:AudioStreamMP3 = audio.bgm_players[audio.active_bgm].stream as AudioStreamMP3
	assert(battle_stream != null and battle_stream.loop)
	audio.play_bgm("habitat_crisis")
	await get_tree().create_timer(audio.BGM_FADE_SECONDS + 0.10).timeout
	_assert_single_finished_crossfade(audio, "habitat_crisis")
	var crisis_stream:AudioStreamMP3 = audio.bgm_players[audio.active_bgm].stream as AudioStreamMP3
	assert(crisis_stream != null and crisis_stream.loop)
	audio.play_bgm("habitat")
	await get_tree().create_timer(audio.BGM_FADE_SECONDS + 0.10).timeout
	_assert_single_finished_crossfade(audio, "habitat")
	audio.play_bgm("ending", true, 0.08)
	assert(is_equal_approx(audio.last_bgm_fade_seconds, 0.08))
	await get_tree().create_timer(0.18).timeout
	_assert_single_finished_crossfade(audio, "ending")
	var ending_stream:AudioStreamMP3 = audio.bgm_players[audio.active_bgm].stream as AudioStreamMP3
	assert(ending_stream != null and ending_stream.loop)

	audio._pause_bgm_for_background()
	assert(audio.application_audio_paused and _unpaused_playing_count(audio) == 0)
	audio._resume_bgm_from_background()
	assert(not audio.application_audio_paused and _unpaused_playing_count(audio) == 1)

	audio._pause_bgm_for_background()
	audio.play_bgm("shop")
	assert(audio.current_bgm_key == "shop" and audio.bgm_changed_while_paused)
	audio._resume_bgm_from_background()
	await get_tree().create_timer(audio.BGM_FADE_SECONDS + 0.10).timeout
	_assert_single_finished_crossfade(audio, "shop")

	audio._pause_bgm_for_background()
	audio.apply_settings({"bgm_enabled":false,"se_enabled":true,"bgm_volume":0.65,"se_volume":0.62})
	audio._resume_bgm_from_background()
	assert(_playing_count(audio) == 0)
	for player in audio.bgm_players: assert(player.stream == null)
	audio.apply_settings({"bgm_enabled":true,"se_enabled":true,"bgm_volume":0.65,"se_volume":0.62})
	await get_tree().process_frame
	await get_tree().create_timer(audio.BGM_FADE_SECONDS + 0.10).timeout
	_assert_single_finished_crossfade(audio, "shop")

	audio.queue_free()
	await get_tree().process_frame
	print("WEB_AUDIO_SMOKE_OK locked_start=silent playback=stream crossfade=single harvest_variants=3 se_off=true harvest_pool=true jurejure_sequence=true crisis_sequence=true ending=true custom_fade=true mp3_loop=true visibility=pause_resume")
	get_tree().quit()

func _playing_count(audio:Node) -> int:
	var count := 0
	for player in audio.bgm_players:
		if player.playing: count += 1
	return count

func _unpaused_playing_count(audio:Node) -> int:
	var count := 0
	for player in audio.bgm_players:
		if player.playing and not player.stream_paused: count += 1
	return count

func _assert_single_finished_crossfade(audio:Node, expected_key:String) -> void:
	assert(audio.current_bgm_key == expected_key)
	assert(_playing_count(audio) == 1)
	var inactive:AudioStreamPlayer = audio.bgm_players[1 - int(audio.active_bgm)]
	assert(not inactive.playing and inactive.stream == null)
