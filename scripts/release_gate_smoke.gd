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
	assert(game.internal_story_jump_button == null)
	assert(game.internal_forced_ad_diagnostic_button == null)
	assert(game.internal_forced_ad_diagnostic_overlay == null)
	assert(game.habitat_dev_panel == null)
	assert(game.jelly_dev_overlay == null)
	assert(game.catalog_preview_ui == null)
	assert(game.find_child("StoryDevOpen", true, false) == null)
	assert(game.find_child("InternalStoryJumpButton", true, false) == null)
	assert(game.find_child("InternalForcedAdDiagnosticButton", true, false) == null)
	assert(game.find_child("InternalForcedAdDiagnosticOverlay", true, false) == null)
	assert(game.find_child("ProgressionDevReset", true, false) == null)
	assert(game.find_child("TrialDevGachaOpen", true, false) == null)
	assert(not game._opening_story_preview_requested())
	assert(not game._habitat_test_preview_requested())
	assert(game.find_child("OpeningSettingsButton", true, false) == null and game.settings_version_button != null)
	game.language_selected = true
	game._show_opening()
	assert(game.opening_review_logo_tap_area != null and game.opening_review_logo_tap_area.is_visible_in_tree())
	for _tap in range(5):
		game.opening_review_logo_tap_area.pressed.emit()
	assert(game.app_review_code_overlay.visible and game.opening_overlay.visible and not game.opening_finished)
	game.app_review_code_input.text = "PUKU-REVIEW-37"
	assert(game._submit_app_review_code())
	await get_tree().process_frame
	var review_products: Dictionary = {}
	for card_value in game.arrangement_ui.shop_grid.get_children():
		if card_value is Control:
			var product_id := str((card_value as Control).get_meta("iap_product_id", ""))
			if not product_id.is_empty(): review_products[product_id] = true
	assert(review_products.size() == 37 and review_products.has("forced_ads_removal"))
	game.arrangement_ui.close()
	assert(not game.app_review_iap_access_active and game.opening_overlay.visible and not game.settings_overlay.visible)

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

	print("RELEASE_GATE_SMOKE_OK dev_ui_absent=true internal_ad_diagnostics_absent=true story_jump_blocked=true reset_blocked=true currency_grant_blocked=true preview_blocked=true app_review_iap=opening-logo+37-products+temporary")
	game.queue_free()
	get_tree().quit()
