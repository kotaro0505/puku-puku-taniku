extends Node

const ShareBackgrounds = preload("res://scripts/arrangement_share_backgrounds.gd")
const ShareRenderer = preload("res://scripts/arrangement_share_renderer.gd")
const Localizer = preload("res://scripts/game_localizer.gd")

func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game._reset_progression_state()
	game.discovered = {"colorata": true, "laui": true}
	game.species_get_counts = {"colorata": 2, "laui": 1}
	game.owned_pots = {"shallow_terracotta": 1}
	var arrangement := {
		"arrangement_id": "share_smoke",
		"name": "共有テスト",
		"pot_id": "shallow_terracotta",
		"created_at": "share-test",
		"completed": true,
		"share_background_id": "greenhouse",
		"viewer_transform": {"x": 34.0, "y": -18.0, "scale": 1.28},
		"plants": [
			{"species_id": "colorata", "x": 214.0, "y": 268.0, "scale": 2.35, "rotation": 123.0, "z_index": 5},
			{"species_id": "laui", "x": 356.0, "y": 310.0, "scale": 0.78, "rotation": 27.0, "z_index": 2},
		],
	}
	game.saved_arrangements = [game._normalize_arrangement(arrangement)]
	game._sync_arrangement_ui()
	var ui = game.arrangement_ui
	ui.set_world_backdrop_mode(true, Vector2(288.0, 716.0))
	ui.visible = true
	ui._open_viewer(arrangement, "saved")
	await get_tree().process_frame
	assert(ui.viewer_artwork_root.position.is_zero_approx() and is_equal_approx(ui.viewer_artwork_root.scale.x, 1.0))
	assert(not ui.viewer_canvas.clip_contents and ui.viewer_canvas.position == ui.ARRANGEMENT_CANVAS_POSITION and ui.viewer_canvas.size.is_equal_approx(ShareRenderer.VIEWER_CANVAS_SIZE))
	assert(ui.viewer_canvas.find_children("*", "Sprite2D", true, false).is_empty() and ui.last_share_preview_debug.is_empty())
	assert(not _has_button_text(ui.viewer_page, "共有背景") and _has_button_text(ui.viewer_page, "共有"))
	var state_before := JSON.stringify(arrangement)
	var inventory_before: Dictionary = game.owned_pots.duplicate(true)
	var output_directory := "user://arrangement-share-qa"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory))
	await get_tree().process_frame
	RenderingServer.force_draw()
	var normal_viewer_image := get_viewport().get_texture().get_image()
	assert(normal_viewer_image != null and normal_viewer_image.save_png("%s/normal-viewer-screen.png" % output_directory) == OK)
	ui.viewer_share_button.pressed.emit()
	assert(ui.is_share_editor_active() and not ui.viewer_page.visible and ui.share_editor_canvas.clip_contents and is_equal_approx(ui.share_editor_canvas.size.x / ui.share_editor_canvas.size.y, 9.0 / 16.0))
	assert(ui.share_editor_canvas.position.y + ui.share_editor_canvas.size.y < ui.share_editor_share_button.position.y)
	assert(_has_button_text(ui.share_editor_page, "共有背景") and _has_button_text(ui.share_editor_page, "共有する"))
	var share_back_button := _button_with_text(ui.share_editor_page, Localizer.text(game.language_code, "back"))
	assert(share_back_button != null and share_back_button.is_visible_in_tree() and share_back_button.get_global_rect().position.is_equal_approx(Vector2(20.0, 24.0)))
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw()
	var share_editor_image := get_viewport().get_texture().get_image()
	assert(share_editor_image != null and share_editor_image.save_png("%s/share-editor-screen.png" % output_directory) == OK)
	var hashes: Dictionary = {}
	for entry_value in ShareBackgrounds.catalog():
		var entry: Dictionary = entry_value
		var background_id := str(entry.get("id", ""))
		var snapshot := arrangement.duplicate(true)
		snapshot["share_background_id"] = background_id
		var output_path := "%s/%s.png" % [output_directory, background_id]
		var generated_path: String = await game._create_arrangement_share_image(snapshot, output_path)
		assert(generated_path == output_path and FileAccess.file_exists(output_path))
		var png_bytes := FileAccess.get_file_as_bytes(output_path)
		assert(png_bytes.size() > 8 and Array(png_bytes.slice(0, 8)) == [137, 80, 78, 71, 13, 10, 26, 10])
		var image := Image.load_from_file(output_path)
		assert(image != null and image.get_size() == ShareRenderer.OUTPUT_SIZE)
		for point in [Vector2i(0, 0), Vector2i(1079, 0), Vector2i(0, 1919), Vector2i(1079, 1919)]:
			assert(image.get_pixelv(point).a > 0.99)
		var debug: Dictionary = ui.last_share_render_debug
		var preview: Dictionary = ui.last_share_preview_debug
		assert(str(debug.background_id) == background_id and Vector2i(debug.output_size) == ShareRenderer.OUTPUT_SIZE)
		assert(str(preview.background_id) == background_id and str(preview.texture_path) == str(entry.texture_path))
		assert(debug.root_children == ["ShareBackground", "ShareArtworkCanvas"])
		assert(int(debug.pot_count) == 1 and int(debug.plant_count) == 2)
		assert(debug.z_indexes == [5, 2] and is_equal_approx(float(debug.rotations[0]), 123.0) and is_equal_approx(float(debug.rotations[1]), 27.0))
		assert(is_equal_approx(float(debug.plant_scales[0]), 2.35) and is_equal_approx(float(debug.plant_scales[1]), 0.78))
		var mapped: Dictionary = debug.mapped_viewer_transform
		var layout: Dictionary = ShareRenderer.artwork_layout(entry)
		assert((mapped.position as Vector2).is_equal_approx((layout.position as Vector2) + Vector2(34.0, -18.0) * float(layout.scale)))
		assert(is_equal_approx(float(mapped.scale), float(layout.scale) * 1.28))
		assert((preview.background_layout.position as Vector2).is_equal_approx(debug.background_layout.position as Vector2))
		assert(is_equal_approx(float(preview.background_layout.scale), float(debug.background_layout.scale)))
		assert((preview.artwork_layout.position as Vector2).is_equal_approx(debug.artwork_layout.position as Vector2))
		assert(is_equal_approx(float(preview.artwork_layout.scale), float(debug.artwork_layout.scale)))
		assert((preview.mapped_viewer_transform.position as Vector2).is_equal_approx(mapped.position as Vector2))
		assert(is_equal_approx(float(preview.mapped_viewer_transform.scale), float(mapped.scale)))
		var output_to_preview_scale := float(preview.output_to_preview_scale)
		assert((preview.preview_mapped_position as Vector2).is_equal_approx((mapped.position as Vector2) * output_to_preview_scale))
		assert(is_equal_approx(float(preview.preview_mapped_scale), float(mapped.scale) * output_to_preview_scale))
		assert(ui.share_editor_background.texture != null and ui.share_editor_artwork_canvas.get_parent() == ui.share_editor_canvas and ui.share_editor_artwork_root.get_parent() == ui.share_editor_artwork_canvas)
		hashes[background_id] = FileAccess.get_sha256(output_path)
	var unique_hashes: Dictionary = {}
	for hash_value in hashes.values():unique_hashes[str(hash_value)] = true
	assert(unique_hashes.size() == 4)
	var vertical_texture := load(str(ShareBackgrounds.entry("puku_members").texture_path)) as Texture2D
	var vertical_layout := ShareRenderer.background_layout(vertical_texture.get_size(), Vector2(0.5, 0.5))
	assert((vertical_layout.position as Vector2).is_zero_approx() and (vertical_layout.scaled_size as Vector2).is_equal_approx(Vector2(1080.0, 1920.0)))
	var greenhouse_entry := ShareBackgrounds.entry("greenhouse")
	assert(str(greenhouse_entry.texture_path) == "res://assets/arrangement/greenhouse-arrangement-area.jpg")
	assert(str(greenhouse_entry.texture_path) != "res://assets/greenhouse-master-horizontal.png")
	var greenhouse_texture := load(str(greenhouse_entry.texture_path)) as Texture2D
	assert(greenhouse_texture.get_size() == Vector2(960.0, 1280.0))
	var greenhouse_layout := ShareRenderer.background_layout(greenhouse_texture.get_size(), greenhouse_entry.focus)
	assert(float(greenhouse_layout.scale) > 0.0 and (greenhouse_layout.scaled_size as Vector2).x >= 1080.0 and (greenhouse_layout.scaled_size as Vector2).y >= 1920.0)
	assert((greenhouse_layout.crop_origin as Vector2).x >= 0.0 and (greenhouse_layout.crop_origin as Vector2).x <= (greenhouse_layout.scaled_size as Vector2).x - 1080.0)
	var default_snapshot := arrangement.duplicate(true)
	default_snapshot["viewer_transform"] = {"x": 0.0, "y": 0.0, "scale": 1.0}
	var default_path := "%s/greenhouse-default-transform.png" % output_directory
	assert(await game._create_arrangement_share_image(default_snapshot, default_path) == default_path)
	assert(FileAccess.get_sha256(default_path) != str(hashes.greenhouse))
	assert(JSON.stringify(arrangement) == state_before and game.owned_pots == inventory_before)
	var old_arrangement: Dictionary = game._normalize_arrangement({"arrangement_id": "old_share", "name": "旧作品", "pot_id": "shallow_terracotta", "plants": []})
	assert(str(old_arrangement.share_background_id) == "greenhouse")
	var web_script: String = game._web_share_file_script("YQ==", "puku-arrangement.png", Localizer.text("ja", "game_title"), "share_smoke_token")
	assert(web_script.contains("navigator.share") and web_script.contains("navigator.canShare") and web_script.contains("x.download=f.name") and web_script.contains("puku-arrangement.png"))
	assert(web_script.contains(".then(()=>finish('shared'))") and web_script.contains("AbortError") and web_script.contains("finish('downloaded')"))
	assert(not web_script.contains(".catch(save)"))
	assert(web_script.contains("ぷくぷく！たにくらいふ"))
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(main_source.contains('_open_native_share_or_fallback(image_path,image_path.get_file(),"arrangement")'))
	assert(main_source.contains('has_method("share")') and main_source.contains('share_plugin.call("share",{'))
	for key in ['"title"', '"subject"', '"content"', '"file_path"', '"mime_type"']:
		assert(main_source.contains(key))
	assert(not main_source.contains('has_method("share_image")') and not main_source.contains('OS.shell_open(absolute_path)'))
	assert(not main_source.contains('return "%s: %s"'))
	assert(FileAccess.get_file_as_string("res://export_presets.cfg").contains("plugins/SharePlugin=true"))
	for button in [ui.viewer_share_background_button, ui.share_editor_share_button]:
		var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
		var hover := button.get_theme_stylebox("hover") as StyleBoxFlat
		var pressed := button.get_theme_stylebox("pressed") as StyleBoxFlat
		var hover_pressed := button.get_theme_stylebox("hover_pressed") as StyleBoxFlat
		assert(normal != null and hover != null and pressed != null and hover_pressed != null)
		assert(normal.border_color == hover.border_color and normal.border_color == pressed.border_color and normal.border_color == hover_pressed.border_color)
		assert(normal.get_border_width(SIDE_LEFT) == 3 and hover.get_border_width(SIDE_LEFT) == 3 and pressed.get_border_width(SIDE_LEFT) == 3 and hover_pressed.get_border_width(SIDE_LEFT) == 3)
		assert(normal.corner_radius_top_left == 18 and hover.corner_radius_top_left == 18 and pressed.corner_radius_top_left == 18 and hover_pressed.corner_radius_top_left == 18)
		assert(button.get_theme_stylebox("focus") is StyleBoxEmpty)
	ui._open_share_background_panel()
	assert(ui.share_background_panel.visible and ui.share_editor_share_button.disabled and not ui.viewer_share_button.disabled)
	ui._select_share_background("puku_members")
	assert(not ui.share_background_panel.visible and not ui.share_editor_share_button.disabled and str(ui.last_share_preview_debug.background_id) == "puku_members")
	var share_handler := Callable(game, "_on_arrangement_share_requested")
	assert(ui.share_requested.is_connected(share_handler))
	ui.share_requested.disconnect(share_handler)
	var captured_requests: Array = []
	var capture_request := func(value: Dictionary) -> void: captured_requests.append(value)
	ui.share_requested.connect(capture_request)
	ui._set_viewer_artwork_transform(Vector2(21.0, 13.0), 1.1, true)
	ui._request_current_arrangement_share()
	assert(captured_requests.size() == 1 and ui.viewer_share_in_progress and ui.share_editor_share_button.disabled and ui.viewer_share_background_button.disabled)
	assert(ui.share_editor_status.visible and ui.share_editor_status.text == Localizer.text(game.language_code, "share_creating"))
	var captured_transform: Dictionary = captured_requests[0].viewer_transform
	assert(is_equal_approx(float(captured_transform.x), 21.0) and is_equal_approx(float(captured_transform.y), 13.0) and is_equal_approx(float(captured_transform.scale), 1.1))
	assert(not game.saved_arrangements[0].has("viewer_transform"))
	game.native_share_context = "arrangement"
	ui.set_share_state(Localizer.text(game.language_code, "share_opening"), true)
	game._on_native_share_canceled()
	assert(game.native_share_context.is_empty() and not ui.viewer_share_in_progress and not ui.share_editor_status.visible)
	game.native_share_context = "arrangement"
	ui.set_share_state(Localizer.text(game.language_code, "share_opening"), true)
	game._on_native_share_failed("share smoke")
	assert(game.native_share_context.is_empty() and not ui.viewer_share_in_progress and ui.share_editor_status.text == Localizer.text(game.language_code, "share_native_failed"))
	assert(not ui.share_editor_status.text.contains("/var/mobile/") and not ui.share_editor_status.text.contains("user://"))
	game.native_share_context = "arrangement"
	ui.set_share_state(Localizer.text(game.language_code, "share_opening"), true)
	game._on_native_share_completed("activity")
	assert(game.native_share_context.is_empty() and not ui.viewer_share_in_progress and ui.share_editor_status.text == Localizer.text(game.language_code, "share_complete"))
	ui.set_share_state("", false)
	assert(not ui.viewer_share_in_progress and not ui.share_editor_share_button.disabled and not ui.viewer_share_background_button.disabled)
	var saved_state_before_back := JSON.stringify(game.saved_arrangements[0])
	share_back_button.pressed.emit()
	assert(ui.viewer_page.visible and not ui.share_editor_page.visible and ui.viewer_artwork_root.position.is_zero_approx() and is_equal_approx(ui.viewer_artwork_root.scale.x, 1.0))
	assert(JSON.stringify(game.saved_arrangements[0]) == saved_state_before_back and not game.saved_arrangements[0].has("viewer_transform"))
	print("ARRANGEMENT_SHARE_IMAGE_SMOKE_OK backgrounds=4 output=1080x1920")
	get_tree().quit()

func _has_button_text(root: Node, text: String) -> bool:
	return _button_with_text(root, text) != null

func _button_with_text(root: Node, text: String) -> Button:
	for node in root.find_children("*", "Button", true, false):
		if node is Button and (node as Button).text == text:
			return node as Button
	return null
