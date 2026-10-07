extends Node

func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game._reset_progression_state()
	game.story_progression_state["arrangement_unlocked"] = true
	game.story_progression_state["arrangement_intro_seen"] = true
	game.discovered = {"colorata": true}
	game.species_get_counts = {"colorata": 20}
	game.owned_pots = {"shallow_terracotta": 20}
	game.saved_arrangements = []
	for index in range(20):
		game.saved_arrangements.append(game._normalize_arrangement({
			"arrangement_id": "gallery_%02d" % index,
			"name": "寄せ植え%d" % (index + 1),
			"pot_id": "shallow_terracotta",
			"created_at": "2026-10-07T00:%02d:00" % index,
			"completed": true,
			"plants": [{"species_id": "colorata", "x": 200.0 + index, "y": 276.0, "scale": 1.0, "rotation": float(index), "z_index": index % 3}],
			"viewer_transform": {"x": 90.0, "y": -45.0, "scale": 2.0},
			"share_background_id": "greenhouse" if index % 2 == 0 else "puku_members",
		}))
	game._sync_arrangement_ui()
	var ui = game.arrangement_ui
	ui.open_home()
	ui._open_saved_arrangements()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(ui.viewer_gallery_mode and ui.saved_arrangements_page == ui.viewer_page)
	assert(ui.saved_arrangements_tabs.get_child_count() == 20)
	assert(ui.saved_arrangements_tab_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO)
	assert(ui.saved_arrangements_tab_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
	assert(ui.saved_arrangements_tab_scroll.position.y + ui.saved_arrangements_tab_scroll.size.y <= ui.viewer_canvas.position.y)
	assert(str(ui.current_arrangement.arrangement_id) == "gallery_19")
	assert(ui.viewer_artwork_root.position.is_zero_approx() and is_equal_approx(ui.viewer_artwork_root.scale.x, 1.0))
	assert("✓" in (ui.saved_arrangements_tabs.get_child(19) as Button).text)
	assert(ui.saved_arrangements_tab_scroll.scroll_horizontal > 0)
	assert(ui.selected_saved_tab_button.position.x >= ui.saved_arrangements_tab_scroll.scroll_horizontal)
	assert(ui.selected_saved_tab_button.position.x + ui.selected_saved_tab_button.size.x <= ui.saved_arrangements_tab_scroll.scroll_horizontal + ui.saved_arrangements_tab_scroll.size.x + 1.0)
	assert(not _has_button_text(ui.saved_arrangements_page, "見る"))
	assert(not FileAccess.get_file_as_string("res://scripts/arrangement_ui.gd").contains("saved_arrangements_list"))

	# A background metadata sync preserves the current session-only framing.
	ui._set_viewer_artwork_transform(Vector2(44.0, -21.0), 1.4, false)
	ui._select_share_background("greenhouse")
	assert(ui.viewer_artwork_root.position.is_equal_approx(Vector2(44.0, -21.0)))
	assert(is_equal_approx(ui.viewer_artwork_root.scale.x, 1.4))
	assert(str(game.saved_arrangements[19].share_background_id) == "greenhouse")
	assert(not game.saved_arrangements[19].has("viewer_transform"))

	# Sharing receives the live framing without adding it to persistent state.
	var real_share_handler := Callable(game, "_on_arrangement_share_requested")
	ui.share_requested.disconnect(real_share_handler)
	var captured: Array = []
	ui.share_requested.connect(func(snapshot: Dictionary) -> void: captured.append(snapshot))
	ui._request_current_arrangement_share()
	assert(captured.size() == 1)
	var captured_transform: Dictionary = captured[0].viewer_transform
	assert(Vector2(float(captured_transform.x), float(captured_transform.y)).is_equal_approx(Vector2(44.0, -21.0)) and is_equal_approx(float(captured_transform.scale), 1.4))
	assert(not game.saved_arrangements[19].has("viewer_transform"))
	ui.set_share_state("", false)

	# Every newly displayed work starts at the standard framing, even when
	# returning to a work adjusted earlier in the same session.
	ui._select_saved_arrangement("gallery_00")
	assert(ui.viewer_artwork_root.position.is_zero_approx() and is_equal_approx(ui.viewer_artwork_root.scale.x, 1.0))
	ui._set_viewer_artwork_transform(Vector2(33.0, 18.0), 1.7, false)
	ui._select_saved_arrangement("gallery_01")
	assert(ui.viewer_artwork_root.position.is_zero_approx() and is_equal_approx(ui.viewer_artwork_root.scale.x, 1.0))
	assert(str(ui.current_arrangement.share_background_id) == "puku_members")
	ui._select_saved_arrangement("gallery_00")
	assert(ui.viewer_artwork_root.position.is_zero_approx() and is_equal_approx(ui.viewer_artwork_root.scale.x, 1.0))
	assert(str(ui.current_arrangement.share_background_id) == "greenhouse")
	ui._return_from_viewer()
	ui._open_saved_arrangements()
	assert(str(ui.current_arrangement.arrangement_id) == "gallery_19")
	assert(ui.viewer_artwork_root.position.is_zero_approx() and is_equal_approx(ui.viewer_artwork_root.scale.x, 1.0))

	# Legacy framing is accepted on input but discarded from normalized/new save data.
	var legacy: Dictionary = game._normalize_arrangement({"arrangement_id": "legacy", "name": "旧作品", "pot_id": "shallow_terracotta", "plants": [], "viewer_transform": {"x": 120.0, "y": 80.0, "scale": 2.1}})
	assert(not legacy.has("viewer_transform"))
	game._save()
	var save_value = JSON.parse_string(FileAccess.get_file_as_string(game._active_save_path()))
	assert(save_value is Dictionary)
	for saved_value in save_value.get("saved_arrangements", []):
		assert(saved_value is Dictionary and not saved_value.has("viewer_transform"))

	# One work is still shown directly; zero works uses only the empty state.
	ui.sync_state({"shallow_terracotta": 1}, [game.saved_arrangements[0]], 20)
	ui._open_saved_arrangements()
	assert(ui.saved_arrangements_tabs.get_child_count() == 1 and ui.viewer_canvas.visible)
	assert(not _has_button_text(ui.saved_arrangements_page, "見る"))
	ui.sync_state({"shallow_terracotta": 1}, [], 20)
	assert(ui.saved_arrangements_empty.visible and not ui.viewer_canvas.visible)
	assert(not ui.viewer_share_button.visible and not ui.viewer_share_background_button.visible and not ui.viewer_dismantle_button.visible)

	# Removing the selected work chooses its neighbour and resets that work.
	game.owned_pots = {"shallow_terracotta": 20}
	game.saved_arrangements = []
	for index in range(3):
		game.saved_arrangements.append(game._normalize_arrangement({"arrangement_id": "remove_%d" % index, "name": "削除%d" % index, "pot_id": "shallow_terracotta", "plants": []}))
	game._sync_arrangement_ui()
	ui._open_saved_arrangements()
	ui._select_saved_arrangement("remove_1")
	ui._set_viewer_artwork_transform(Vector2(28.0, 16.0), 1.5, false)
	ui._show_dismantle_confirmation()
	ui._confirm_dismantle()
	assert(game.saved_arrangements.size() == 2 and str(ui.current_arrangement.arrangement_id) == "remove_2")
	assert(ui.viewer_artwork_root.position.is_zero_approx() and is_equal_approx(ui.viewer_artwork_root.scale.x, 1.0))
	assert(game._pot_usage_count("shallow_terracotta") == 2 and game._pot_available_count("shallow_terracotta") == 18)
	print("ARRANGEMENT_GALLERY_SMOKE_OK tabs=20 transient_share=true reset=true")
	get_tree().quit()

func _has_button_text(root: Node, text: String) -> bool:
	for node in root.find_children("*", "Button", true, false):
		if node is Button and (node as Button).text == text:
			return true
	return false
