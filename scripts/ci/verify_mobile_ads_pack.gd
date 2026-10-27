extends SceneTree

const CONFIG_PATH := "res://data/mobile-ads.cfg"
const TEST_REWARDED_ID := "ca-app-pub-3940256099942544/1712485313"
const AD_UNIT_PATTERN := "^ca-app-pub-[0-9]{16}/[0-9]{10}$"


func _init() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 2:
		_fail("usage", "expected a PCK path and test|production")
		return

	var pack_path := arguments[0]
	var expected_mode := arguments[1]
	if expected_mode not in ["test", "production"]:
		_fail("expected_mode", "expected mode must be test or production")
		return
	if not FileAccess.file_exists(pack_path):
		_fail("pack.file_exists", "exported PCK was not found")
		return
	if not ProjectSettings.load_resource_pack(pack_path, true):
		_fail("pack.mount", "exported PCK could not be mounted")
		return
	if not FileAccess.file_exists(CONFIG_PATH):
		_fail("config.file_exists", "%s is missing from the exported PCK" % CONFIG_PATH)
		return

	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		_fail("config.parse", "%s is not a valid ConfigFile" % CONFIG_PATH)
		return
	var mode := str(config.get_value("ios", "mode", "")).strip_edges().to_lower()
	var rewarded_id := str(config.get_value("ios", "rewarded_ad_unit_id", "")).strip_edges()
	if mode != expected_mode:
		_fail("config.mode", "exported mode does not match the workflow mode")
		return
	if not _valid_rewarded_id(rewarded_id, expected_mode):
		_fail("config.rewarded_id", "exported rewarded ID is missing, malformed, or for the wrong mode")
		return

	print("MOBILE_ADS_PACK_OK mode=%s path=%s" % [expected_mode, CONFIG_PATH])
	quit(0)


func _valid_rewarded_id(rewarded_id: String, mode: String) -> bool:
	if mode == "test":
		return rewarded_id == TEST_REWARDED_ID
	if rewarded_id == TEST_REWARDED_ID:
		return false
	var regex := RegEx.new()
	if regex.compile(AD_UNIT_PATTERN) != OK:
		return false
	return regex.search(rewarded_id) != null


func _fail(check: String, detail: String) -> void:
	printerr("MOBILE_ADS_PACK_FAILED check=%s detail=%s" % [check, detail])
	quit(1)
