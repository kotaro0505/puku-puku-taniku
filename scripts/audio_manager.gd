extends Node

const CONFIG_PATH := "res://data/audio-config.json"
const BGM_FADE_SECONDS := 0.45
const SE_POOL_SIZE := 8

var bgm_enabled := true
var se_enabled := true
var bgm_volume := 0.65
var se_volume := 0.62
var config: Dictionary = {"bgm": {}, "se": {}}
var bgm_players: Array[AudioStreamPlayer] = []
var se_players: Array[AudioStreamPlayer] = []
var active_bgm := 0
var current_bgm_key := ""

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
	if not paths is Dictionary: return null
	var path := str(paths.get(key, ""))
	if path.is_empty() or not ResourceLoader.exists(path): return null
	return load(path) as AudioStream
