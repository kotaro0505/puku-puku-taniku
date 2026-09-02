extends Node

const SucculentClass = preload("res://scripts/succulent.gd")
const CARD_IMAGE_AREA := Vector2(190.0, 121.0)
const EXPECTED := {
	"glow_colorata": {"variant": "mystery_glow_colorata", "file": "mystery-glow-colorata.png", "full_size": Vector2i(1280, 1181), "habitat_size": Vector2i(320, 295)},
	"metal_laui": {"variant": "mystery_metal_laui", "file": "mystery-metal-laui.png", "full_size": Vector2i(1280, 1174), "habitat_size": Vector2i(320, 294)},
	"seaglass_veria": {"variant": "mystery_seaglass_veria", "file": "mystery-seaglass-veria.png", "full_size": Vector2i(1280, 1169), "habitat_size": Vector2i(320, 292)},
	"amber_agavoides": {"variant": "mystery_amber_agavoides", "file": "mystery-amber-agavoides.png", "full_size": Vector2i(1280, 1187), "habitat_size": Vector2i(320, 297)},
	"yumefuwa_jelly": {"variant": "mystery_yumefuwa_jelly", "file": "mystery-yumefuwa-jelly.png", "full_size": Vector2i(1280, 1185), "habitat_size": Vector2i(320, 296)},
	"peach_jelly_succulent": {"variant": "mystery_peach_jelly", "file": "mystery-peach-jelly.png", "full_size": Vector2i(1280, 1141), "habitat_size": Vector2i(320, 285)},
}

func _assert_padded_texture(texture: Texture2D, expected_size: Vector2i, min_margin: int) -> void:
	assert(texture != null)
	var image := texture.get_image()
	assert(image != null and not image.is_empty())
	assert(image.get_size() == expected_size)
	assert(image.detect_alpha() != Image.ALPHA_NONE)
	var used := image.get_used_rect()
	assert(used.position.x >= min_margin and used.position.y >= min_margin)
	assert(image.get_width() - used.end.x >= min_margin)
	assert(image.get_height() - used.end.y >= min_margin)
	var used_center := Vector2(used.position) + Vector2(used.size) * 0.5
	var canvas_center := Vector2(expected_size) * 0.5
	assert(used_center.distance_to(canvas_center) <= float(mini(expected_size.x, expected_size.y)) * 0.035)

func _assert_card_fit(texture: Texture2D) -> void:
	var image := texture.get_image()
	var used := image.get_used_rect()
	var canvas_size := Vector2(image.get_size())
	var fit_scale := minf(CARD_IMAGE_AREA.x / canvas_size.x, CARD_IMAGE_AREA.y / canvas_size.y)
	var canvas_origin := (CARD_IMAGE_AREA - canvas_size * fit_scale) * 0.5
	var used_top_left := canvas_origin + Vector2(used.position) * fit_scale
	var used_bottom_right := canvas_origin + Vector2(used.end) * fit_scale
	assert(used_top_left.x >= 5.0 and used_top_left.y >= 5.0)
	assert(used_bottom_right.x <= CARD_IMAGE_AREA.x - 5.0)
	assert(used_bottom_right.y <= CARD_IMAGE_AREA.y - 5.0)

func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.encyclopedia_unlocked = true
	for species_id in EXPECTED:
		game.discovered.erase(species_id)
	game._refresh_encyclopedia_cards()
	await get_tree().process_frame

	for species_id in EXPECTED:
		var expected: Dictionary = EXPECTED[species_id]
		var entry: Dictionary = game._catalog_entry(species_id)
		assert(not entry.is_empty() and str(entry.get("rarity", "")) == "謎品種")
		assert(str(entry.get("visual_variant", "")) == str(expected.variant))
		var full_path := "res://assets/plants/" + str(expected.file)
		var habitat_path := "res://assets/plants/habitat/" + str(expected.file)
		assert(str(SucculentClass.SPRITES[expected.variant]) == full_path)
		assert(str(entry.get("habitat_image_path", "")) == habitat_path)
		var full_texture := load(full_path) as Texture2D
		var habitat_texture := load(habitat_path) as Texture2D
		_assert_padded_texture(full_texture, expected.full_size, 60)
		_assert_padded_texture(habitat_texture, expected.habitat_size, 14)
		_assert_card_fit(full_texture)

		var card_index := -1
		for i in range(game.catalog_species.size()):
			if str(game.catalog_species[i].get("species_id", "")) == species_id:
				card_index = i
				break
		assert(card_index >= 0)
		var card_image: TextureRect = game.encyclopedia_card_images[card_index]
		assert(card_image.expand_mode == TextureRect.EXPAND_IGNORE_SIZE)
		assert(card_image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		assert(card_image.modulate.is_equal_approx(Color(0.12, 0.09, 0.08, 0.82)))

		var plant := SucculentClass.new()
		game.add_child(plant)
		plant.setup(entry, 20260903, Label.new(), Label.new())
		assert(plant.plant_sprite.texture.resource_path == full_path)
		assert(not plant.plant_sprite.region_enabled)
		assert(is_equal_approx(plant.plant_sprite.pixel_size, 1.42 / float(expected.full_size.x)))
		plant.free()

		game.habitat_texture_mode = "thumb"
		assert(game._habitat_species_texture(entry).resource_path == habitat_path)
		game._open_species_detail(entry)
		var detail_image: TextureRect = game.encyclopedia_detail_page.find_child("SpeciesImage", true, false)
		assert(detail_image.texture.resource_path == full_path)
		assert(detail_image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		var acquisition_layer := Control.new()
		game.add_child(acquisition_layer)
		game._animate_species_to_encyclopedia(species_id, Vector2(180.0, 320.0), acquisition_layer)
		await get_tree().process_frame
		assert(acquisition_layer.get_child_count() == 1)
		var flying: TextureRect = acquisition_layer.get_child(0)
		assert(flying.texture.resource_path == full_path)
		assert(flying.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		await get_tree().create_timer(0.65).timeout
		await get_tree().process_frame
		acquisition_layer.free()

	for species_id in EXPECTED:
		game.discovered[species_id] = true
	game._refresh_encyclopedia_cards()
	await get_tree().process_frame
	for species_id in EXPECTED:
		for i in range(game.catalog_species.size()):
			if str(game.catalog_species[i].get("species_id", "")) == species_id:
				var found_image: TextureRect = game.encyclopedia_card_images[i]
				assert(found_image.modulate.is_equal_approx(Color.WHITE))
				assert(found_image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
				break

	print("MYSTERY_IMAGE_SMOKE_OK species=6 full=6 habitat=6 silhouette=fit discovered=fit greenhouse=fit detail=fit acquisition=fit")
	game.free()
	await get_tree().process_frame
	get_tree().quit()
