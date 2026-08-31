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

func _ready() -> void:
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

func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH): return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if parsed is Dictionary: config = parsed

func apply_settings(saved: Dictionary) -> void:
	bgm_enabled = bool(saved.get("bgm_enabled", true))
	se_enabled = bool(saved.get("se_enabled", true))
	bgm_volume = clampf(float(saved.get("bgm_volume", 0.65)), 0.0, 1.0)
	se_volume = clampf(float(saved.get("se_volume", 0.62)), 0.0, 1.0)
	if not bgm_enabled:
		for player in bgm_players: player.stop()
	elif not current_bgm_key.is_empty():
		play_bgm(current_bgm_key, true)

func settings_dictionary() -> Dictionary:
	return {"bgm_enabled":bgm_enabled,"se_enabled":se_enabled,"bgm_volume":bgm_volume,"se_volume":se_volume}

func play_bgm(key: String, restart := false) -> void:
	current_bgm_key = key
	if not bgm_enabled: return
	var stream := _stream_for("bgm", key)
	if stream == null:
		for player in bgm_players: player.stop()
		return
	var current := bgm_players[active_bgm]
	if not restart and current.playing and current.stream == stream: return
	var next_index := 1 - active_bgm
	var next := bgm_players[next_index]
	next.stream = stream
	next.volume_db = -60.0
	next.play()
	var target_db := linear_to_db(maxf(bgm_volume, 0.001))
	var tween := create_tween().set_parallel()
	tween.tween_property(next, "volume_db", target_db, BGM_FADE_SECONDS)
	if current.playing: tween.tween_property(current, "volume_db", -60.0, BGM_FADE_SECONDS)
	tween.chain().tween_callback(current.stop)
	active_bgm = next_index

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
	var paths = config.get(section, {})
	if paths is Dictionary:
		var path := str(paths.get(key, ""))
		if not path.is_empty() and ResourceLoader.exists(path): return load(path) as AudioStream
	if section == "se": return _fallback_se(key)
	return null

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
