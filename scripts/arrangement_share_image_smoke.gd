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
	var state_before := JSON.stringify(arrangement)
	var inventory_before: Dictionary = game.owned_pots.duplicate(true)
	var output_directory := "res://tmp/arrangement-share-qa"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory))
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
		assert(str(debug.background_id) == background_id and Vector2i(debug.output_size) == ShareRenderer.OUTPUT_SIZE)
		assert(debug.root_children == ["ShareBackground", "ShareArtworkCanvas"])
		assert(int(debug.pot_count) == 1 and int(debug.plant_count) == 2)
		assert(debug.z_indexes == [5, 2] and is_equal_approx(float(debug.rotations[0]), 123.0) and is_equal_approx(float(debug.rotations[1]), 27.0))
		assert(is_equal_approx(float(debug.plant_scales[0]), 2.35) and is_equal_approx(float(debug.plant_scales[1]), 0.78))
		var mapped: Dictionary = debug.mapped_viewer_transform
		var layout: Dictionary = ShareRenderer.artwork_layout(entry)
		assert((mapped.position as Vector2).is_equal_approx((layout.position as Vector2) + Vector2(34.0, -18.0) * float(layout.scale)))
		assert(is_equal_approx(float(mapped.scale), float(layout.scale) * 1.28))
		hashes[background_id] = FileAccess.get_sha256(output_path)
	var unique_hashes: Dictionary = {}
	for hash_value in hashes.values():unique_hashes[str(hash_value)] = true
	assert(unique_hashes.size() == 4)
	var vertical_texture := load(str(ShareBackgrounds.entry("puku_members").texture_path)) as Texture2D
	var vertical_layout := ShareRenderer.background_layout(vertical_texture.get_size(), Vector2(0.5, 0.5))
	assert((vertical_layout.position as Vector2).is_zero_approx() and (vertical_layout.scaled_size as Vector2).is_equal_approx(Vector2(1080.0, 1920.0)))
	var greenhouse_entry := ShareBackgrounds.entry("greenhouse")
	var greenhouse_texture := load(str(greenhouse_entry.texture_path)) as Texture2D
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
	var web_script: String = game._web_share_file_script("YQ==", "puku-arrangement.png", "ぷくぷく多肉")
	assert(web_script.contains("navigator.share") and web_script.contains("navigator.canShare") and web_script.contains("x.download=f.name") and web_script.contains("puku-arrangement.png"))
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(main_source.contains('_open_native_share_or_fallback(image_path,image_path.get_file(),"arrangement")'))
	assert(main_source.contains('has_method("share_image")') and main_source.contains('has_method("share_file")'))
	assert(FileAccess.get_file_as_string("res://export_presets.cfg").contains("plugins/SharePlugin=true"))
	ui._open_share_background_panel()
	assert(ui.share_background_panel.visible and ui.viewer_share_button.disabled)
	ui._close_share_background_panel()
	assert(not ui.viewer_share_button.disabled)
	var share_handler := Callable(game, "_on_arrangement_share_requested")
	assert(ui.share_requested.is_connected(share_handler))
	ui.share_requested.disconnect(share_handler)
	var captured_requests: Array = []
	var capture_request := func(value: Dictionary) -> void: captured_requests.append(value)
	ui.share_requested.connect(capture_request)
	ui._set_viewer_artwork_transform(Vector2(21.0, 13.0), 1.1, true)
	ui._request_current_arrangement_share()
	assert(captured_requests.size() == 1 and ui.viewer_share_in_progress and ui.viewer_share_button.disabled and ui.viewer_share_background_button.disabled)
	assert(ui.viewer_share_status.visible and ui.viewer_share_status.text == Localizer.text(game.language_code, "share_creating"))
	var captured_transform: Dictionary = captured_requests[0].viewer_transform
	assert(is_equal_approx(float(captured_transform.x), 21.0) and is_equal_approx(float(captured_transform.y), 13.0) and is_equal_approx(float(captured_transform.scale), 1.1))
	assert(not game.saved_arrangements[0].has("viewer_transform"))
	ui.set_share_state(Localizer.text(game.language_code, "share_opening"), false)
	assert(not ui.viewer_share_in_progress and not ui.viewer_share_button.disabled and not ui.viewer_share_background_button.disabled)
	print("ARRANGEMENT_SHARE_IMAGE_SMOKE_OK backgrounds=4 output=1080x1920")
	get_tree().quit()
