extends Node

const Localizer = preload("res://scripts/game_localizer.gd")
const SPECIES_ID := "lutea"


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	game._reset_progression_state()
	_prepare_visible_gameplay(game)
	_assert_localized_pages(game)
	await _test_first_get_card_then_dialog(game)
	await _test_saved_completion_and_repeat_get(game)
	await _test_interrupted_pending_recovery(game)
	await _test_existing_story_followup_order(game)
	_test_legacy_owned_save_migration(game)
	game._reset_progression_state()
	print("LUTEA_FIRST_GET_STORY_SMOKE_OK card_then_dialog=true pages=4 speakers=armadillo+girl languages=ja+hiragana+en once=true reload=true interrupted_recovery=true legacy_owned_suppressed=true queued_card_order=true story_followup_order=true")
	get_tree().quit()


func _prepare_visible_gameplay(game: Node) -> void:
	game.opening_finished = true
	game.opening_overlay.visible = false
	game.opening_story_overlay.visible = false
	game.intro_overlay.visible = false
	game.result_overlay.visible = false
	game.shop_overlay.visible = false
	game.settings_overlay.visible = false
	game.encyclopedia_overlay.visible = false
	game.play_overlay.visible = false
	game.species_get_overlay.visible = false
	game.catalog_series_unlock_overlay.reset_overlay()
	game.catalog_series_unlock_notice_queue.clear()
	game.catalog_series_unlock_notice_ready.clear()
	game.species_get_queue.clear()
	game.species_get_active_context = ""
	game.species_get_active_species_id = ""
	game.species_get_active_series_id = ""
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.scripted_dialog_index = -1
	game.intro_story_complete = true
	game.opening_story_complete = true
	game.current_mode = "greenhouse"
	game.play_active = false
	game._apply_mode()
	game._update_play_ui()


func _assert_localized_pages(game: Node) -> void:
	var expected := {
		"ja": [
			"ルテア　ファンタスマスだ！",
			"不思議な形の多肉だね！",
			"スペイン語で、\n「幽霊たち」って意味らしいよ。",
			"そう言われてみると幽霊みたいに\n見えるかも…。",
		],
		"hiragana": [
			"るてあ　ふぁんたすますだ！",
			"ふしぎな かたちの たにくだね！",
			"すぺいんごで、\n「ゆうれいたち」って いみらしいよ。",
			"そう いわれてみると ゆうれいみたいに\nみえるかも…。",
		],
		"en": [
			"It's Lutea Phantasmas!",
			"What a mysterious shape for a succulent!",
			"Apparently, in Spanish,\nit means \"ghosts.\"",
			"Now that you mention it, it does\nlook like a ghost...",
		],
	}
	var keys := [
		"lutea_first_get_armadillo_1",
		"lutea_first_get_girl_1",
		"lutea_first_get_armadillo_2",
		"lutea_first_get_girl_2",
	]
	for language in expected:
		var pages: Array[Dictionary] = game._lutea_first_get_dialog_pages(language)
		assert(pages.size() == 4)
		assert([pages[0].speaker, pages[1].speaker, pages[2].speaker, pages[3].speaker] == ["armadillo", "girl", "armadillo", "girl"])
		assert([pages[0].text, pages[1].text, pages[2].text, pages[3].text] == expected[language])
		for index in range(keys.size()):
			assert(Localizer.text(language, keys[index]) == expected[language][index])


func _test_first_get_card_then_dialog(game: Node) -> void:
	assert(not bool(game.discovered.get(SPECIES_ID, false)))
	assert(game._species_get_count(SPECIES_ID) == 0)
	assert(not game.lutea_first_get_dialog_seen and not game.lutea_first_get_dialog_pending)
	assert(game._register_species_discovery(SPECIES_ID, true))
	assert(game._species_get_count(SPECIES_ID) == 1)
	assert(game.lutea_first_get_dialog_pending and not game.lutea_first_get_dialog_seen)
	game._queue_species_get_by_id(SPECIES_ID, true, "lutea_story_smoke")
	game._queue_species_get_by_id("laui", true, "queued_after_lutea_smoke")
	game._show_next_species_get()
	assert(game.species_get_overlay.visible)
	assert(game.species_get_overlay.current_context == "lutea_story_smoke")
	assert(game.species_get_overlay.name_label.text == Localizer.species_name("ja", game._catalog_entry(SPECIES_ID)))
	assert(game.species_get_overlay.badge_label.visible and game.species_get_overlay.badge_label.text == Localizer.text("ja", "new"))
	assert(game.scripted_dialog_kind.is_empty())
	game.species_get_overlay.busy = false
	await game.species_get_overlay.close_overlay()
	await get_tree().process_frame
	assert(game.scripted_dialog_kind == "lutea_first_get")
	var expected_pages: Array[Dictionary] = game._lutea_first_get_dialog_pages("ja")
	for index in range(expected_pages.size()):
		assert(game.intro_overlay.visible and game.intro_continue_button.visible and game.intro_continue_button.is_visible_in_tree())
		assert(game.scripted_dialog_index == index)
		var expected_speaker := str(expected_pages[index].speaker)
		assert(game.intro_speaker_label.text == _speaker_name("ja", expected_speaker))
		assert(game.intro_dialogue_label.text == str(expected_pages[index].text))
		assert(_texture_path(game.intro_panda_portrait.texture) == _texture_path(game._speaker_portrait_texture(expected_speaker)))
		_assert_standard_dialog_layout(game)
		game._advance_scripted_dialog()
		await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.scripted_dialog_kind.is_empty() and not game.intro_overlay.visible)
	assert(game.lutea_first_get_dialog_seen and not game.lutea_first_get_dialog_pending)
	assert(game.species_get_overlay.visible and game.species_get_overlay.current_context == "queued_after_lutea_smoke")
	assert(game.species_get_overlay.name_label.text == Localizer.species_name("ja", game._catalog_entry("laui")))
	game.species_get_overlay.busy = false
	await game.species_get_overlay.close_overlay()
	await get_tree().process_frame
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game._active_save_path()))
	assert(bool(saved.get("lutea_first_get_dialog_seen", false)))
	assert(not bool(saved.get("lutea_first_get_dialog_pending", true)))


func _test_saved_completion_and_repeat_get(game: Node) -> void:
	game.lutea_first_get_dialog_seen = false
	game.lutea_first_get_dialog_pending = true
	game._load_save()
	_prepare_visible_gameplay(game)
	assert(game.lutea_first_get_dialog_seen and not game.lutea_first_get_dialog_pending)
	assert(not game._register_species_discovery(SPECIES_ID, true))
	assert(game._species_get_count(SPECIES_ID) == 2)
	assert(not game.lutea_first_get_dialog_pending)
	game._queue_species_get_by_id(SPECIES_ID, false, "repeat_get_smoke")
	game._show_next_species_get()
	assert(game.species_get_overlay.visible and not game.species_get_overlay.badge_label.visible)
	game.species_get_overlay.busy = false
	await game.species_get_overlay.close_overlay()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.scripted_dialog_kind.is_empty())


func _test_interrupted_pending_recovery(game: Node) -> void:
	var save_path: String = game._active_save_path()
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	payload["discovered"][SPECIES_ID] = true
	payload["species_get_counts"][SPECIES_ID] = 1
	payload["lutea_first_get_dialog_seen"] = false
	payload["lutea_first_get_dialog_pending"] = true
	_write_payload(save_path, payload)
	game._load_save()
	_prepare_visible_gameplay(game)
	assert(not game.lutea_first_get_dialog_seen and game.lutea_first_get_dialog_pending)
	game._try_start_pending_story_event()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.species_get_overlay.visible)
	assert(game.species_get_overlay.current_context == "lutea_first_get_recovery")
	assert(game.scripted_dialog_kind.is_empty())
	game.species_get_overlay.busy = false
	await game.species_get_overlay.close_overlay()
	await get_tree().process_frame
	assert(game.scripted_dialog_kind == "lutea_first_get")
	for page_index in range(4):
		assert(game.scripted_dialog_index == page_index)
		game._advance_scripted_dialog()
		await get_tree().process_frame
	await get_tree().process_frame
	assert(game.lutea_first_get_dialog_seen and not game.lutea_first_get_dialog_pending)


func _test_existing_story_followup_order(game: Node) -> void:
	game._reset_progression_state()
	_prepare_visible_gameplay(game)
	game.mystery_items_acquired = true
	game.encyclopedia_unlocked = true
	game.mystery_catalog_tutorial_complete = true
	game.active_seed_type = "normal"
	assert(game._register_species_discovery(SPECIES_ID, true))
	game._arm_catalog_first_new_dialog(SPECIES_ID)
	assert(game.catalog_first_new_dialog_pending and not game.catalog_first_new_dialog_card_closed)
	game._queue_species_get_by_id(SPECIES_ID, true, "lutea_with_story_followup_smoke")
	game._show_next_species_get()
	game.species_get_overlay.busy = false
	await game.species_get_overlay.close_overlay()
	await get_tree().process_frame
	assert(game.scripted_dialog_kind == "lutea_first_get")
	assert(game.catalog_first_new_dialog_card_closed)
	for page_index in range(4):
		assert(game.scripted_dialog_index == page_index)
		game._advance_scripted_dialog()
		await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.scripted_dialog_kind == "catalog_first_new")
	assert(game.intro_dialogue_label.text == Localizer.text("ja", "catalog_first_new_armadillo"))
	game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.catalog_first_new_dialog_seen and not game.catalog_first_new_dialog_pending)


func _test_legacy_owned_save_migration(game: Node) -> void:
	var save_path: String = game._active_save_path()
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	payload.erase("lutea_first_get_dialog_seen")
	payload.erase("lutea_first_get_dialog_pending")
	payload["discovered"][SPECIES_ID] = true
	payload["species_get_counts"][SPECIES_ID] = 1
	_write_payload(save_path, payload)
	game.lutea_first_get_dialog_seen = false
	game.lutea_first_get_dialog_pending = true
	game._load_save()
	_prepare_visible_gameplay(game)
	assert(game.lutea_first_get_dialog_seen and not game.lutea_first_get_dialog_pending)
	game._try_start_pending_story_event()
	assert(game.species_get_queue.is_empty() and not game.species_get_overlay.visible and game.scripted_dialog_kind.is_empty())


func _assert_standard_dialog_layout(game: Node) -> void:
	var panel_rect: Rect2 = game.intro_dialog_panel.get_global_rect()
	var button_rect: Rect2 = game.intro_continue_button.get_global_rect()
	var text_rect: Rect2 = game.intro_dialogue_label.get_global_rect()
	assert(panel_rect.grow(0.5).encloses(button_rect))
	assert(not text_rect.intersects(button_rect))
	assert(game.intro_continue_button.text == Localizer.text(game.language_code, "continue"))


func _texture_path(texture: Texture2D) -> String:
	return texture.resource_path if texture != null else ""


func _speaker_name(for_language: String, speaker_id: String) -> String:
	var key := "story_speaker_girl" if speaker_id == "girl" else "armadillo_name"
	return Localizer.text(for_language, key)


func _write_payload(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(payload))
	file.close()
