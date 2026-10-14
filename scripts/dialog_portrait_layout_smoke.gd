extends Node

const StandardStoryDialoguePanelClass = preload("res://scripts/standard_story_dialogue_panel.gd")


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	_prepare_visible_gameplay(game)
	await _test_single_speaker_portraits(game)
	_test_dialog_hides_navigation(game)
	await _test_habitat_dialog_position(game)
	game._reset_progression_state()
	print("DIALOG_PORTRAIT_LAYOUT_SMOKE_OK speakers=6 speaker_top_gap=8 name_portrait_overlap=false portrait=clipped+contained text_overlap=false continue_overlap=false navigation=hidden habitat_position=center habitat_avoidance=true internal_layout=unchanged greenhouse_shop=unchanged")
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
		var speaker_rect: Rect2 = game.intro_speaker_label.get_global_rect()
		var dialogue_rect: Rect2 = game.intro_dialogue_label.get_global_rect()
		var continue_rect: Rect2 = game.intro_continue_button.get_global_rect()
		assert(game.intro_panda_portrait.visible and game.intro_panda_portrait.texture != null)
		assert(slot_rect.grow(0.5).encloses(portrait_rect))
		assert(not portrait_rect.intersects(dialogue_rect))
		assert(not portrait_rect.intersects(continue_rect))
		assert(game.intro_speaker_label.position.is_equal_approx(StandardStoryDialoguePanelClass.SPEAKER_LABEL_POSITION))
		assert(game.intro_speaker_label.size.is_equal_approx(StandardStoryDialoguePanelClass.SPEAKER_LABEL_SIZE))
		assert(game.intro_speaker_label.get_line_height() <= game.intro_speaker_label.size.y + 0.5)
		assert(speaker_rect.end.y <= portrait_rect.position.y + 0.5)
		assert(is_equal_approx(portrait_rect.position.y, slot_rect.position.y + StandardStoryDialoguePanelClass.PORTRAIT_TOP_OFFSET))
		assert(is_equal_approx(portrait_rect.size.y, slot_rect.size.y - StandardStoryDialoguePanelClass.PORTRAIT_TOP_OFFSET))


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


func _test_habitat_dialog_position(game: Node) -> void:
	var baseline_layout := _control_layout_snapshot(game.intro_dialog_panel)
	var panel_size: Vector2 = game.intro_dialog_panel.size
	var panel_scale: Vector2 = game.intro_dialog_panel.scale
	var dialogue_font_size: int = game.intro_dialogue_label.get_theme_font_size("font_size")
	var dialogue_wrap: int = game.intro_dialogue_label.autowrap_mode
	var continue_font_size: int = game.intro_continue_button.get_theme_font_size("font_size")
	game.habitat_pickups.clear()
	game.tutorial_habitat_item.clear()
	game.current_mode = "habitat"
	game._apply_mode()
	game._start_scripted_dialog("habitat_dialog_position_smoke", [
		{"speaker": "peccary", "text": "layout"},
		{"speaker": "peccary", "text": "layout 2"}
	])
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.intro_dialog_panel.position == Vector2(40, 385))
	_assert_panel_inside_viewport(game)
	_assert_internal_layout_unchanged(game, baseline_layout, panel_size, panel_scale, dialogue_font_size, dialogue_wrap, continue_font_size)
	game.intro_continue_button.pressed.emit()
	await get_tree().process_frame
	assert(game.scripted_dialog_index == 1)
	assert(game.intro_dialogue_label.text == "layout 2")
	assert(game.intro_dialog_panel.position == Vector2(40, 385))
	_assert_internal_layout_unchanged(game, baseline_layout, panel_size, panel_scale, dialogue_font_size, dialogue_wrap, continue_font_size)

	var target := Node3D.new()
	game.add_child(target)
	target.global_position = game.camera.project_position(Vector2(288, 510), 6.0)
	var target_item := {"node": target, "kind": "jurejure_group"}
	game.habitat_pickups.append(target_item)
	game._position_intro_dialog()
	var avoid_rect: Rect2 = game._dialog_avoid_rect_for_world_node(target, Vector2(150, 150))
	var moved_panel_rect := Rect2(game.intro_dialog_panel.position, game.intro_dialog_panel.size)
	assert(not moved_panel_rect.intersects(avoid_rect))
	assert(game.intro_dialog_panel.position.x == 40)
	assert(game.intro_dialog_panel.position.y != 385)
	_assert_panel_inside_viewport(game)
	_assert_internal_layout_unchanged(game, baseline_layout, panel_size, panel_scale, dialogue_font_size, dialogue_wrap, continue_font_size)
	game.habitat_pickups.erase(target_item)
	target.queue_free()

	_clear_test_dialog(game)
	game.current_mode = "greenhouse"
	game._apply_mode()
	game._start_scripted_dialog("greenhouse_dialog_position_smoke", [{"speaker": "peccary", "text": "layout"}])
	await get_tree().process_frame
	assert(game.intro_dialog_panel.position == Vector2(40, 725))
	_assert_internal_layout_unchanged(game, baseline_layout, panel_size, panel_scale, dialogue_font_size, dialogue_wrap, continue_font_size)
	_clear_test_dialog(game)
	game._start_scripted_dialog("shop_dialog_position_smoke", [{"speaker": "peccary", "text": "layout"}], true)
	await get_tree().process_frame
	assert(game.intro_dialog_panel.position == Vector2(40, 725))
	_assert_internal_layout_unchanged(game, baseline_layout, panel_size, panel_scale, dialogue_font_size, dialogue_wrap, continue_font_size)
	_clear_test_dialog(game)


func _control_layout_snapshot(root: Control) -> Dictionary:
	var result := {}
	for child_value in root.find_children("*", "Control", true, false):
		var child := child_value as Control
		result[str(root.get_path_to(child))] = _control_layout_values(child)
	return result


func _control_layout_values(control: Control) -> Dictionary:
	return {
		"position": control.position,
		"size": control.size,
		"scale": control.scale,
		"minimum_size": control.custom_minimum_size
	}


func _assert_internal_layout_unchanged(game: Node, baseline_layout: Dictionary, panel_size: Vector2, panel_scale: Vector2, dialogue_font_size: int, dialogue_wrap: int, continue_font_size: int) -> void:
	assert(game.intro_dialog_panel.size == panel_size)
	assert(game.intro_dialog_panel.scale == panel_scale)
	assert(_control_layout_snapshot(game.intro_dialog_panel) == baseline_layout)
	assert(game.intro_dialogue_label.get_theme_font_size("font_size") == dialogue_font_size)
	assert(game.intro_dialogue_label.autowrap_mode == dialogue_wrap)
	assert(game.intro_continue_button.get_theme_font_size("font_size") == continue_font_size)


func _assert_panel_inside_viewport(game: Node) -> void:
	var panel_rect := Rect2(game.intro_dialog_panel.position, game.intro_dialog_panel.size)
	var viewport_rect := Rect2(Vector2.ZERO, game.get_viewport().get_visible_rect().size)
	assert(viewport_rect.encloses(panel_rect))


func _clear_test_dialog(game: Node) -> void:
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.scripted_dialog_index = -1
	game.scripted_dialog_shop_context = false
	game.intro_overlay.visible = false
	game.shop_overlay.visible = false
	game._update_play_ui()
