extends Node

const STONE_IDS := [
	"stone_black_lava_rosette",
	"stone_serpentine_rosette",
	"stone_granite_rosette",
	"stone_red_lava_rosette",
	"stone_sandstone_rosette",
	"stone_slate_rosette",
	"stone_green_schist_rosette",
	"stone_silver_gneiss_rosette",
	"stone_obsidian_rosette",
	"stone_white_marble_rosette",
]

func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game._reset_progression_state()
	game.intro_story_complete = true
	game.encyclopedia_unlocked = true

	var stone_series: Dictionary = game._series_entry("stone")
	assert(not stone_series.is_empty())
	assert(stone_series.get("species_ids", []) == STONE_IDS)
	assert(str(stone_series.get("display_name", "")) == "ストーン")
	assert(bool(stone_series.get("catalog_purchase_enabled", false)))
	assert(bool(stone_series.get("preview_catalog_when_locked", false)))
	assert(game._is_normal_series("stone") and not game._is_hidden_series("stone"))
	assert(game._shop_series_catalog().any(func(entry): return str(entry.get("series_id", "")) == "stone"))

	var stone_entries: Array = game._series_species_entries("stone")
	assert(stone_entries.size() == 10)
	for index in range(stone_entries.size()):
		var entry: Dictionary = stone_entries[index]
		var species_id := str(entry.get("species_id", ""))
		var image_path := str(entry.get("image_path", ""))
		assert(species_id == STONE_IDS[index])
		assert(str(entry.get("series_id", "")) == "stone")
		assert(bool(entry.get("catalog_only", false)))
		assert(not bool(entry.get("special_route_only", false)))
		assert(not bool(entry.get("series_seed_eligible", true)))
		assert(is_zero_approx(float(entry.get("spawn_weight", -1.0))))
		assert(image_path.begins_with("res://assets/catalog/stone/") and ResourceLoader.exists(image_path))
		assert(str(game.SucculentClass.SPRITES.get(str(entry.get("visual_variant", "")), "")) == image_path)
		var image: Image = (load(image_path) as Texture2D).get_image()
		var used := image.get_used_rect()
		assert(image.get_width() == 1254 and image.get_height() == 1254)
		assert(image.detect_alpha() != Image.ALPHA_NONE)
		assert(image.get_pixel(0, 0).a < 0.01 and image.get_pixel(1253, 0).a < 0.01)
		assert(image.get_pixel(0, 1253).a < 0.01 and image.get_pixel(1253, 1253).a < 0.01)
		assert(used.position.x > 0 and used.position.y > 0 and used.end.x < 1254 and used.end.y < 1254)
	assert(game._series_cover_texture(stone_series).resource_path == "res://assets/catalog/stone/stone-black-lava-rosette.png")

	game.unlocked_series["stone"] = true
	game.selected_series_index = 1
	game._open_encyclopedia()
	await get_tree().process_frame
	assert(game._current_series_entry().get("series_id", "") == "stone")
	assert(game.encyclopedia_list_title.text == "ストーン")
	assert(game.encyclopedia_grid.get_child_count() == 10)
	assert(game.series_cover_image.texture.resource_path == "res://assets/catalog/stone/stone-black-lava-rosette.png")
	var first_card: Button = game.encyclopedia_grid.get_child(0)
	assert(first_card.disabled)
	game._register_species_discovery(STONE_IDS[0], false)
	game.species_get_counts[STONE_IDS[0]] = 1
	game._refresh_encyclopedia_header()
	game._refresh_encyclopedia_cards()
	await get_tree().process_frame
	first_card = game.encyclopedia_grid.get_child(0)
	assert(not first_card.disabled)
	first_card.pressed.emit()
	assert(game.encyclopedia_detail_page.find_child("SpeciesName", true, false).text == "黒溶岩ロゼット")
	assert(game.encyclopedia_detail_page.find_child("SpeciesImage", true, false).texture.resource_path == "res://assets/catalog/stone/stone-black-lava-rosette.png")

	print("STONE_SERIES_SMOKE_OK species=", stone_entries.size())
	get_tree().quit()
