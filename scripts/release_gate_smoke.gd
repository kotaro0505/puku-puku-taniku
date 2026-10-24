extends Node

const MainScene = preload("res://main.tscn")
const StoryDevPresetsClass = preload("res://scripts/story_dev_presets.gd")


func _ready() -> void:
	# Override the runtime-derived fields before _ready() to exercise the exact
	# UI/action path used by the production feature profile.
	var game = MainScene.instantiate()
	game.TRIAL_DEV_CONTROLS_ENABLED = false
	game.DEVELOPMENT_CATALOG_PREVIEW_ENABLED = false
	game.REWARDED_AD_DEVELOPMENT_STUB_ENABLED = false
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	assert(not game._trial_dev_controls_enabled())
	assert(game.story_dev_panel == null)
	assert(game.habitat_dev_panel == null)
	assert(game.jelly_dev_overlay == null)
	assert(game.catalog_preview_ui == null)
	assert(game.find_child("StoryDevOpen", true, false) == null)
	assert(game.find_child("ProgressionDevReset", true, false) == null)
	assert(game.find_child("TrialDevGachaOpen", true, false) == null)
	assert(not game._opening_story_preview_requested())
	assert(not game._habitat_test_preview_requested())

	game.normal_seed_bags = 7
	game.puku_balance_units = 3210
	game._dev_add_seed_bag()
	game._adjust_progression_dev_value("puku_coin", 1)
	game._reset_progression_state()
	assert(game.normal_seed_bags == 7)
	assert(game.puku_balance_units == 3210)
	var preset_result: Dictionary = game._apply_story_dev_preset(StoryDevPresetsClass.COMPLETE)
	assert(not bool(preset_result.get("ok", false)))
	assert(str(preset_result.get("error", "")) == "development_only")

	print("RELEASE_GATE_SMOKE_OK dev_ui_absent=true story_jump_blocked=true reset_blocked=true currency_grant_blocked=true preview_blocked=true")
	game.queue_free()
	get_tree().quit()
