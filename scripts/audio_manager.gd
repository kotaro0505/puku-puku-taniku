extends Node

const CONFIG_PATH := "res://data/audio-config.json"
const BGM_FADE_SECONDS := 0.45
const SE_POOL_SIZE := 8
const FALLBACK_MIX_RATE := 22050

var bgm_enabled := true
var se_enabled := true
var bgm_volume := 0.65
var se_volume := 0.62
var config: Dictionary = {"bgm": {}, "se": {}}
var bgm_players: Array[AudioStreamPlayer] = []
var se_players: Array[AudioStreamPlayer] = []
var active_bgm := 0
var current_bgm_key := ""
var fallback_se_cache: Dictionary = {}
var web_audio_unlocked := not OS.has_feature("web")
var bgm_restart_queued := false
var bgm_fade_tween: Tween
var bgm_format := "ogg"
var release_stream_on_stop := true

func _ready() -> void:
	_configure_audio_ab()
	_load_config()
	for i in range(2):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		bgm_players.append(player)
	for i in range(SE_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		se_players.append(player)
	print("AUDIO_AB format=",bgm_format," release=",("null" if release_stream_on_stop else "retain"))

func _configure_audio_ab()->void:
	if not OS.has_feature("web"):return
	var requested_format=JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('audio_format')",true)
	var requested_release=JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('audio_release')",true)
	bgm_format="wav" if str(requested_format)=="wav" else "ogg"
	release_stream_on_stop=str(requested_release)!="retain"

func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH): return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if parsed is Dictionary: config = parsed

func apply_settings(saved: Dictionary) -> void:
	var was_bgm_enabled := bgm_enabled
	bgm_enabled = bool(saved.get("bgm_enabled", true))
	se_enabled = bool(saved.get("se_enabled", true))
	bgm_volume = clampf(float(saved.get("bgm_volume", 0.65)), 0.0, 1.0)
	se_volume = clampf(float(saved.get("se_volume", 0.62)), 0.0, 1.0)
	if not bgm_enabled:
		_cancel_bgm_fade()
		for player in bgm_players: _stop_and_release_bgm_player(player)
	elif not was_bgm_enabled and not current_bgm_key.is_empty():
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
		_queue_bgm_restart()
	else:
		var target_db := _bgm_target_db(current_bgm_key)
		for player in bgm_players:
			if player.playing: player.volume_db = target_db

func settings_dictionary() -> Dictionary:
	return {"bgm_enabled":bgm_enabled,"se_enabled":se_enabled,"bgm_volume":bgm_volume,"se_volume":se_volume}

func play_bgm(key: String, restart := false) -> void:
	current_bgm_key = key
	if not bgm_enabled: return
	var stream := _stream_for("bgm", key)
	if stream == null:
		for player in bgm_players: _stop_and_release_bgm_player(player)
		return
	var current := bgm_players[active_bgm]
	if not restart and current.playing and current.stream == stream: return
	_cancel_bgm_fade()
	var next_index := 1 - active_bgm
	var next := bgm_players[next_index]
	_stop_and_release_bgm_player(next)
	next.stream = stream
	next.volume_db = -60.0
	next.play()
	var target_db := _bgm_target_db(key)
	bgm_fade_tween = create_tween().set_parallel()
	bgm_fade_tween.tween_property(next, "volume_db", target_db, BGM_FADE_SECONDS)
	if current.playing: bgm_fade_tween.tween_property(current, "volume_db", -60.0, BGM_FADE_SECONDS)
	bgm_fade_tween.chain().tween_callback(_stop_and_release_bgm_player.bind(current))
	active_bgm = next_index

func _bgm_target_db(key:String)->float:
	var gains=config.get("bgm_gain",{})
	var gain:=1.0
	if gains is Dictionary:gain=clampf(float(gains.get(key,1.0)),0.0,1.0)
	return linear_to_db(maxf(bgm_volume*gain,0.001))

func notify_user_gesture() -> void:
	if not bgm_enabled or current_bgm_key.is_empty(): return
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	if not web_audio_unlocked:
		web_audio_unlocked = true
		_queue_bgm_restart()
	elif not _has_audible_bgm_player():
		_queue_bgm_restart()

func _queue_bgm_restart() -> void:
	if bgm_restart_queued: return
	bgm_restart_queued = true
	call_deferred("_restart_current_bgm")

func _restart_current_bgm() -> void:
	bgm_restart_queued = false
	if not bgm_enabled or current_bgm_key.is_empty(): return
	_cancel_bgm_fade()
	for player in bgm_players: _stop_and_release_bgm_player(player)
	play_bgm(current_bgm_key, true)

func _stop_and_release_bgm_player(player:AudioStreamPlayer)->void:
	player.stop()
	if release_stream_on_stop:player.stream=null

func _cancel_bgm_fade() -> void:
	if bgm_fade_tween and bgm_fade_tween.is_valid(): bgm_fade_tween.kill()
	bgm_fade_tween = null

func _has_audible_bgm_player() -> bool:
	for player in bgm_players:
		if player.playing and player.volume_db > -50.0: return true
	return false

func play_se(key: String, gain := 1.0) -> void:
	if not se_enabled: return
	var stream := _stream_for("se", key)
	if stream == null: return
	var player: AudioStreamPlayer = se_players[0]
	for candidate in se_players:
		if not candidate.playing:
			player = candidate
			break
	player.stream = stream
	player.volume_db = linear_to_db(maxf(se_volume * clampf(gain, 0.0, 1.0), 0.001))
	player.play()

func _stream_for(section: String, key: String) -> AudioStream:
	var config_section:=section
	if section=="bgm" and bgm_format=="wav":config_section="bgm_wav"
	var paths = config.get(config_section, {})
	if paths is Dictionary:
		var path := str(paths.get(key, ""))
		if not path.is_empty() and ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			if section == "bgm": _enable_bgm_loop(stream)
			return stream
	if section == "se": return _fallback_se(key)
	return null

func _enable_bgm_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		if stream.loop_end <= stream.loop_begin:
			stream.loop_begin = 0
			stream.loop_end = maxi(1, roundi(stream.get_length() * stream.mix_rate))
	elif stream is AudioStreamOggVorbis:
		stream.loop = true

func _fallback_se(key: String) -> AudioStreamWAV:
	if fallback_se_cache.has(key): return fallback_se_cache[key]
	var specs := {
		"ui_tap":[680.0,920.0,.055,.18], "watering":[310.0,470.0,.34,.20],
		"sprout":[430.0,760.0,.13,.22], "harvest":[520.0,980.0,.18,.24],
		"jelly":[280.0,185.0,.30,.24], "squish":[220.0,330.0,.20,.22],
		"level_up":[520.0,1120.0,.42,.23], "new_species":[740.0,1480.0,.48,.24],
		"seed_bag":[190.0,520.0,.22,.20], "purchase":[660.0,990.0,.18,.20],
		"payment":[880.0,1240.0,.12,.16], "rare_seed":[410.0,1080.0,.34,.22],
		"daily":[620.0,1260.0,.38,.22], "result":[390.0,760.0,.36,.22],
		"result_new_best":[700.0,1560.0,.52,.24]
	}
	var spec:Array=specs.get(key,specs["ui_tap"])
	var start_hz:float=spec[0];var end_hz:float=spec[1];var duration:float=spec[2];var amplitude:float=spec[3]
	var frames:=maxi(1,int(duration*FALLBACK_MIX_RATE));var bytes:=PackedByteArray();bytes.resize(frames*2)
	var phase:=0.0
	for i in range(frames):
		var t:=float(i)/FALLBACK_MIX_RATE;var progress:=float(i)/maxf(1.0,float(frames-1));var hz:=lerpf(start_hz,end_hz,smoothstep(0.0,1.0,progress));phase+=TAU*hz/FALLBACK_MIX_RATE
		var attack:=smoothstep(0.0,.08,progress);var release:=pow(1.0-progress,2.2);var envelope:=attack*release
		var tone:=sin(phase)+sin(phase*2.01)*.22
		if key in ["watering","seed_bag"]:tone+=sin(float(i)*12.9898)*.16*(1.0-progress)
		if key in ["level_up","new_species","daily","result_new_best"]:tone+=sin(phase*1.5)*.25*smoothstep(.28,.75,progress)
		var sample:=clampi(int(tone*envelope*amplitude*32767.0),-32768,32767);bytes.encode_s16(i*2,sample)
	var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=FALLBACK_MIX_RATE;stream.stereo=false;stream.data=bytes
	fallback_se_cache[key]=stream
	return stream
