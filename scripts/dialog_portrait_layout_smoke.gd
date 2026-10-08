extends Node


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	_prepare_visible_gameplay(game)
	await _test_single_speaker_portraits(game)
	_test_dialog_hides_navigation(game)
	game._reset_progression_state()
	print("DIALOG_PORTRAIT_LAYOUT_SMOKE_OK speakers=6 portrait=clipped+contained text_overlap=false continue_overlap=false navigation=hidden")
	get_tree().quit()


func _prepare_visible_gameplay(game: Node) -> void:
	game.opening_overlay.visible = false
	game.opening_story_overlay.visible = false
	game.intro_overlay.visible = false
	game.result_overlay.visible = false
	game.shop_overlay.visible = false
	game.settings_overlay.visible = false
	game.encyclopedia_overlay.visible = false
	game.play_overlay.visible = false
	game.opening_finished = true
	game.intro_story_complete = true
	game.habitat_unlocked = true
	game.current_mode = "greenhouse"
	game.play_active = false
	game._apply_mode()
	game._update_play_ui()


func _test_single_speaker_portraits(game: Node) -> void:
	game._start_scripted_dialog("dialog_portrait_layout_smoke", [{"speaker": "panda", "text": "layout"}])
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.intro_portrait_slot.clip_contents)
	for speaker_id in ["girl", "panda", "armadillo", "mouse", "skunk", "peccary"]:
		game._set_intro_speaker(speaker_id)
		await get_tree().process_frame
		var slot_rect: Rect2 = game.intro_portrait_slot.get_global_rect()
		var portrait_rect: Rect2 = game.intro_panda_portrait.get_global_rect()
		var dialogue_rect: Rect2 = game.intro_dialogue_label.get_global_rect()
		var continue_rect: Rect2 = game.intro_continue_button.get_global_rect()
		assert(game.intro_panda_portrait.visible and game.intro_panda_portrait.texture != null)
		assert(slot_rect.grow(0.5).encloses(portrait_rect))
		assert(not portrait_rect.intersects(dialogue_rect))
		assert(not portrait_rect.intersects(continue_rect))
		assert(is_equal_approx(portrait_rect.position.y, slot_rect.position.y + 32.0))
		assert(is_equal_approx(portrait_rect.size.y, slot_rect.size.y - 32.0))


func _test_dialog_hides_navigation(game: Node) -> void:
	for control_value in game.external_navigation_controls:
		var control := control_value as Control
		control.visible = true
	game.habitat_dev_open_button.visible = true
	game._update_play_ui()
	for control_value in game.external_navigation_controls:
		assert(not (control_value as Control).visible)
	assert(not game.mode_button.visible)
	assert(not game.shop_button.visible)
	assert(not game.forest_gacha_button.visible)
	assert(not game.fusion_lab_button.visible)
	assert(not game.habitat_dev_open_button.visible)
	assert(not game.arrangement_navigation_hint.visible)
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.intro_overlay.visible = false
	game._update_play_ui()
