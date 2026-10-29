extends Node

const Localizer = preload("res://scripts/game_localizer.gd")
const ARMADILLO_CHATTER_KEYS := [
	["armadillo_idle_1"],
	["armadillo_idle_2"],
	["armadillo_idle_3"],
	["armadillo_idle_4"],
	["armadillo_idle_5_1", "armadillo_idle_5_2"],
]
const PANDA_CHATTER_KEYS := [
	"shop_chatter_today", "shop_chatter_share", "shop_chatter_welcome",
	"shop_chatter_living_jewel", "shop_chatter_puku_help",
]
const ARMADILLO_TOUCH_POINTS := {
	"upper": Vector2(165, 650),
	"center": Vector2(165, 710),
	"lower": Vector2(165, 770),
}

var game: Node


func _ready() -> void:
	game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	_prepare_unlocked_shop()
	await get_tree().process_frame
	_assert_input_layout()
	await _test_armadillo_touch_regions()
	await _test_all_idle_conversations()
	await _test_localized_touch_conversations()
	await _test_old_catalog_intro_sequence()
	await _test_catalog_restoration()
	await _test_absent_armadillo()
	await _test_panda_touch()
	await _test_category_button_and_back()
	game._reset_progression_state()
	print("SHOP_ARMADILLO_INPUT_SMOKE_OK touch=upper-center-lower idle=5 two-page=pass restore=pass absent=pass panda=pass categories=pass locales=ja-hiragana-en")
	get_tree().quit()


func _prepare_unlocked_shop() -> void:
	game._reset_progression_state()
	game.opening_finished = true
	game.opening_story_complete = true
	game.opening_overlay.visible = false
	game.opening_story_overlay.visible = false
	game.intro_overlay.visible = false
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.trio_originals_confirmed = true
	game.total_play_count = 3
	game.habitat_unlocked = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_tutorial_complete = true
	game.mystery_items_acquired = true
	game.mystery_catalog_tutorial_complete = true
	game.encyclopedia_unlocked = true
	game.seed_shop_open = true
	game.puku_gauge_intro_complete = true
	game.puku_points = 2
	game.normal_seed_bags = 1
	game.story_progression_state["arrangement_unlocked"] = true
	game.story_progression_state["arrangement_intro_seen"] = true
	game._update_play_ui()
	game._open_shop()
	game._hide_shop_chatter(true)
	game._prepare_shop_visit(true)


func _assert_input_layout() -> void:
	assert(game.shop_overlay.visible)
	assert(game.armadillo_present and game.armadillo_tap_button.is_visible_in_tree())
	assert(game.armadillo_tap_button.get_global_rect() == game.SHOP_ARMADILLO_TAP_RECT)
	var category_panel := game.shop_category_controls[0] as PanelContainer
	var category_content := category_panel.get_child(0) as Control
	assert(category_panel.is_visible_in_tree())
	assert(category_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(category_content.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(game.shop_pot_button.mouse_filter == Control.MOUSE_FILTER_STOP)
	for point in ARMADILLO_TOUCH_POINTS.values():
		assert(game.armadillo_tap_button.get_global_rect().has_point(point))


func _test_armadillo_touch_regions() -> void:
	for region in ["upper", "center", "lower"]:
		game._hide_shop_chatter(true)
		await _touch(ARMADILLO_TOUCH_POINTS[region])
		assert(game.shop_chatter_bubble.visible, "armadillo %s touch did not open chatter" % region)
		assert(game.shop_chatter_sequence_kind == "armadillo_idle")
		assert(game.shop_chatter_sequence_speaker == "armadillo")


func _test_all_idle_conversations() -> void:
	game._set_language("ja")
	game.rng.seed = 20261029
	var seen: Dictionary = {}
	for attempt in range(64):
		game._hide_shop_chatter(true)
		await _touch(ARMADILLO_TOUCH_POINTS["center"])
		var chatter_index: int = game.last_armadillo_shop_chatter_index
		assert(chatter_index >= 0 and chatter_index < ARMADILLO_CHATTER_KEYS.size())
		var expected_keys: Array = ARMADILLO_CHATTER_KEYS[chatter_index]
		assert(game.shop_chatter_label.text == Localizer.text("ja", expected_keys[0]))
		assert(game.shop_chatter_pages.size() == expected_keys.size())
		seen[chatter_index] = true
		if expected_keys.size() == 2:
			await _touch(ARMADILLO_TOUCH_POINTS["center"])
			assert(game.shop_chatter_bubble.visible)
			assert(game.shop_chatter_page_index == 1)
			assert(game.shop_chatter_label.text == Localizer.text("ja", expected_keys[1]))
		await _touch(ARMADILLO_TOUCH_POINTS["center"])
		assert(not game.shop_chatter_bubble.visible)
		if seen.size() == ARMADILLO_CHATTER_KEYS.size():
			break
	assert(seen.size() == ARMADILLO_CHATTER_KEYS.size(), "not all five armadillo chatter patterns were reached")


func _test_localized_touch_conversations() -> void:
	for locale in ["ja", "hiragana", "en"]:
		game._set_language(locale)
		game._hide_shop_chatter(true)
		await _touch(ARMADILLO_TOUCH_POINTS["upper"])
		var chatter_index: int = game.last_armadillo_shop_chatter_index
		var first_key: String = ARMADILLO_CHATTER_KEYS[chatter_index][0]
		assert(not game.shop_chatter_label.text.is_empty())
		assert(game.shop_chatter_label.text == Localizer.text(locale, first_key))


func _test_old_catalog_intro_sequence() -> void:
	game._set_language("ja")
	game._hide_shop_chatter(true)
	game.old_catalog_intro_pending = true
	game.old_catalog_intro_seen = false
	game._prepare_shop_visit(true)
	assert(game.shop_chatter_sequence_kind == "old_catalog_intro")
	assert(game.shop_chatter_label.text == Localizer.text("ja", "old_page_intro_1"))
	await _touch(ARMADILLO_TOUCH_POINTS["lower"])
	assert(game.shop_chatter_bubble.visible and game.shop_chatter_page_index == 1)
	assert(game.shop_chatter_label.text == Localizer.text("ja", "old_page_intro_2"))
	await _touch(ARMADILLO_TOUCH_POINTS["lower"])
	assert(not game.shop_chatter_bubble.visible)


func _test_catalog_restoration() -> void:
	var original_hidden_series: Variant = game.catalog_progression.get("hidden_series", []).duplicate(true)
	game.catalog_progression["hidden_series"] = [{"series_id": "sea"}]
	game.unlocked_series.erase("sea")
	game.act2_unlocked = true
	game.old_catalog_page_inventory = {"sea": 1}
	game._sync_old_catalog_page_count()
	game._hide_shop_chatter(true)
	await _touch(ARMADILLO_TOUCH_POINTS["lower"])
	var restored_entry: Dictionary = game._series_entry("sea")
	assert(game.old_catalog_pages == 0)
	assert(bool(game.unlocked_series.get("sea", false)))
	assert(game.armadillo_dialog_mode == "catalog_restore_result")
	assert(game.shop_chatter_label.text == Localizer.text("ja", "restore_success", [Localizer.series_name("ja", restored_entry)]))
	game.catalog_progression["hidden_series"] = original_hidden_series
	game.act2_unlocked = false
	game._hide_shop_chatter(true)


func _test_absent_armadillo() -> void:
	game._prepare_shop_visit(false)
	assert(not game.armadillo_present)
	assert(not game.armadillo_tap_button.is_visible_in_tree())
	for point in ARMADILLO_TOUCH_POINTS.values():
		await _touch(point)
		assert(not game.shop_chatter_bubble.visible)
	game._prepare_shop_visit(true)
	assert(game.armadillo_present and game.armadillo_tap_button.is_visible_in_tree())


func _test_panda_touch() -> void:
	game._hide_shop_chatter(true)
	await _touch(Vector2(300, 560))
	var localized_panda_chatter: Array[String] = []
	for key in PANDA_CHATTER_KEYS:
		localized_panda_chatter.append(Localizer.text(game.language_code, key))
	assert(game.shop_chatter_bubble.visible)
	assert(localized_panda_chatter.has(game.shop_chatter_label.text))
	assert(game.shop_chatter_sequence_kind.is_empty() and game.armadillo_dialog_mode == "normal")
	assert(game.shop_chatter_portrait.visible and game.shop_chatter_portrait.texture != null)
	game._hide_shop_chatter(true)


func _test_category_button_and_back() -> void:
	assert(game.shop_category_controls[0].is_visible_in_tree())
	assert(game.shop_pot_button.is_visible_in_tree())
	await _touch(game.shop_pot_button.get_global_rect().get_center())
	assert(game.arrangement_ui.visible and game.arrangement_ui.shop_page.visible)
	game.arrangement_ui.close()
	await get_tree().process_frame
	assert(game.shop_overlay.visible and game.shop_category_controls[0].is_visible_in_tree())
	var back_button := game.find_child("ShopCloseButton", true, false) as Button
	assert(back_button != null and back_button.is_visible_in_tree())
	await _touch(back_button.get_global_rect().get_center())
	assert(not game.shop_overlay.visible)


func _touch(position: Vector2) -> void:
	_push_touch(position, true)
	await get_tree().process_frame
	_push_touch(position, false)
	await get_tree().process_frame


func _push_touch(position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.pressed = pressed
	event.position = position
	get_viewport().push_input(event, true)
