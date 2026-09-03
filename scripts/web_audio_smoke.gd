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

	print("WEB_AUDIO_SMOKE_OK locked_start=silent playback=stream crossfade=single visibility=pause_resume")
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
