extends Node

const SEA_IDS := [
	"sea_coralline_drops",
	"sea_sandy_tide",
	"sea_coral_fingers",
	"sea_jellyfish_rosette",
	"sea_seafoam_bubbles",
	"sea_starlight_lagoon",
	"sea_sandy_lagoon",
	"sea_neon_coral",
	"sea_pearl_shell",
	"sea_tropical_bubbles",
]

func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	get_tree().paused = false
	game._reset_progression_state()
	game.intro_story_complete = true
	game.encyclopedia_unlocked = true
	game.habitat_unlocked = true

	var series: Dictionary = game._series_entry("sea")
	assert(not series.is_empty())
	assert(str(series.get("display_name", "")) == "海")
	assert(series.get("species_ids", []) == SEA_IDS)
	assert(bool(series.get("catalog_purchase_enabled", false)))
	assert(bool(series.get("preview_catalog_when_locked", false)))
	assert(game._is_normal_series("sea") and not game._is_hidden_series("sea"))
	assert(game._shop_series_catalog().any(func(entry): return str(entry.get("series_id", "")) == "sea"))
	assert(not game._habitat_new_species_candidates().any(func(entry): return str(entry.get("series_id", "")) == "sea"))

	var entries: Array = game._series_species_entries("sea")
	assert(entries.size() == 10)
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		var species_id := str(entry.get("species_id", ""))
		var image_path := str(entry.get("image_path", ""))
		assert(species_id == SEA_IDS[index])
		assert(str(entry.get("series_id", "")) == "sea")
		assert(bool(entry.get("catalog_only", false)))
		assert(not bool(entry.get("special_route_only", false)))
		assert(not bool(entry.get("series_seed_eligible", true)))
		assert(is_zero_approx(float(entry.get("spawn_weight", -1.0))))
		assert(is_equal_approx(float(entry.get("unlocked_spawn_weight", 0.0)), 1.0))
		assert(image_path.begins_with("res://assets/catalog/sea/") and ResourceLoader.exists(image_path))
		assert(str(game.SucculentClass.SPRITES.get(str(entry.get("visual_variant", "")), "")) == image_path)
		var image: Image = (load(image_path) as Texture2D).get_image()
		var used := image.get_used_rect()
		var width := image.get_width()
		var height := image.get_height()
		assert(width >= 1200 and height >= 1200)
		assert(image.detect_alpha() != Image.ALPHA_NONE)
		assert(image.get_pixel(0, 0).a < 0.01 and image.get_pixel(width - 1, 0).a < 0.01)
		assert(image.get_pixel(0, height - 1).a < 0.01 and image.get_pixel(width - 1, height - 1).a < 0.01)
		assert(used.position.x > 0 and used.position.y > 0 and used.end.x < width and used.end.y < height)
	assert(game._series_cover_texture(series).resource_path == "res://assets/catalog/sea/sea-coralline-drops.png")

	game.unlocked_series["sea"] = true
	var habitat_candidates: Array[Dictionary] = game._habitat_new_species_candidates()
	for species_id in SEA_IDS:
		assert(not habitat_candidates.any(func(entry): return str(entry.get("species_id", "")) == species_id))

	game.selected_series_index = 1
	game._open_encyclopedia()
	await get_tree().process_frame
	assert(game._current_series_entry().get("series_id", "") == "sea")
	assert(game.encyclopedia_list_title.text == "海")
	assert(game.encyclopedia_grid.get_child_count() == 10)
	assert(game.series_cover_image.texture.resource_path == "res://assets/catalog/sea/sea-coralline-drops.png")
	var first_card: Button = game.encyclopedia_grid.get_child(0)
	assert(first_card.disabled)
	game._register_species_discovery(SEA_IDS[0], false)
	game.species_get_counts[SEA_IDS[0]] = 1
	game._refresh_encyclopedia_header()
	game._refresh_encyclopedia_cards()
	await get_tree().process_frame
	first_card = game.encyclopedia_grid.get_child(0)
	assert(not first_card.disabled)
	first_card.pressed.emit()
	assert(game.encyclopedia_detail_page.find_child("SpeciesName", true, false).text == "サンゴしずく")
	assert(game.encyclopedia_detail_page.find_child("SpeciesImage", true, false).texture.resource_path == "res://assets/catalog/sea/sea-coralline-drops.png")
	game._close_encyclopedia()

	game.catalog_species = entries
	game.discovered.clear()
	game.greenhouse_available.clear()
	game.unlocked_species.clear()
	game.species.clear()
	assert(game._select_species_for_seed("normal").is_empty())
	assert(game._register_species_discovery(SEA_IDS[0], false))
	game.rng.seed=20260912
	var registered_draws:=0
	for draw in range(120):
		var chosen_id:=str(game._select_species_for_seed("normal").get("species_id", ""))
		assert(chosen_id in SEA_IDS and not game._seed_new_species_blocked(chosen_id))
		if chosen_id==SEA_IDS[0]:registered_draws+=1
		else:assert(not bool(game.discovered.get(chosen_id,false)))
	assert(registered_draws>=100)

	print("SEA_SERIES_SMOKE_OK species=", entries.size(), " habitat_candidates=", habitat_candidates.size())
	get_tree().quit()
