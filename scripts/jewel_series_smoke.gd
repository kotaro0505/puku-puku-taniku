extends Node

const JEWEL_IDS := [
	"jewel_diamond_rosette",
	"jewel_emerald_rosette",
	"jewel_sapphire_star",
	"jewel_opal_rosette",
	"jewel_amethyst_rosette",
	"jewel_rose_quartz_rosette",
	"jewel_fluorite_rosette",
	"jewel_labradorite_star",
	"jewel_citrine_rosette",
	"jewel_turquoise_cluster",
]

func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game._reset_progression_state()
	game.intro_story_complete = true
	game.encyclopedia_unlocked = true
	game.habitat_unlocked = true

	var jewel_series: Dictionary = game._series_entry("jewel")
	assert(not jewel_series.is_empty())
	assert(jewel_series.get("species_ids", []) == JEWEL_IDS)
	assert(bool(jewel_series.get("catalog_purchase_enabled", false)))
	assert(game._is_normal_series("jewel") and not game._is_hidden_series("jewel"))
	assert(game._shop_series_catalog().any(func(entry): return str(entry.get("series_id", "")) == "jewel"))
	assert(not game._habitat_new_species_candidates().any(func(entry): return str(entry.get("series_id", "")) == "jewel"))

	var jewel_entries: Array = game._series_species_entries("jewel")
	assert(jewel_entries.size() == 10)
	for index in range(jewel_entries.size()):
		var entry: Dictionary = jewel_entries[index]
		var species_id := str(entry.get("species_id", ""))
		var image_path := str(entry.get("image_path", ""))
		assert(species_id == JEWEL_IDS[index])
		assert(str(entry.get("series_id", "")) == "jewel")
		assert(bool(entry.get("catalog_only", false)))
		assert(not bool(entry.get("special_route_only", false)))
		assert(not bool(entry.get("series_seed_eligible", true)))
		assert(is_zero_approx(float(entry.get("spawn_weight", -1.0))))
		assert(is_equal_approx(float(entry.get("unlocked_spawn_weight", 0.0)), 1.0))
		assert(image_path.begins_with("res://assets/catalog/jewel/") and ResourceLoader.exists(image_path))
		assert(str(game.SucculentClass.SPRITES.get(str(entry.get("visual_variant", "")), "")) == image_path)
		var image: Image = (load(image_path) as Texture2D).get_image()
		var used := image.get_used_rect()
		assert(image.get_width() == 1254 and image.get_height() == 1254)
		assert(image.detect_alpha() != Image.ALPHA_NONE)
		assert(image.get_pixel(0, 0).a < 0.01 and image.get_pixel(1253, 0).a < 0.01)
		assert(image.get_pixel(0, 1253).a < 0.01 and image.get_pixel(1253, 1253).a < 0.01)
		assert(used.position.x > 0 and used.position.y > 0 and used.end.x < 1254 and used.end.y < 1254)
	assert(game._series_cover_texture(jewel_series).resource_path == "res://assets/catalog/jewel/jewel-diamond-rosette.png")

	game.unlocked_series["jewel"] = true
	var habitat_candidates: Array[Dictionary] = game._habitat_new_species_candidates()
	for species_id in JEWEL_IDS:
		assert(not habitat_candidates.any(func(entry): return str(entry.get("species_id", "")) == species_id))

	game.selected_series_index = 1
	game._open_encyclopedia()
	await get_tree().process_frame
	assert(game._current_series_entry().get("series_id", "") == "jewel")
	assert(game.encyclopedia_list_title.text == "宝石多肉")
	assert(game.encyclopedia_grid.get_child_count() == 10)
	assert(game.series_cover_image.texture.resource_path == "res://assets/catalog/jewel/jewel-diamond-rosette.png")
	var first_card: Button = game.encyclopedia_grid.get_child(0)
	assert(first_card.disabled)
	game._register_species_discovery(JEWEL_IDS[0], false)
	game.species_get_counts[JEWEL_IDS[0]] = 1
	game._refresh_encyclopedia_header()
	game._refresh_encyclopedia_cards()
	await get_tree().process_frame
	first_card = game.encyclopedia_grid.get_child(0)
	assert(not first_card.disabled)
	first_card.pressed.emit()
	assert(game.encyclopedia_detail_page.find_child("SpeciesName", true, false).text == "ダイヤモンドロゼット")
	assert(game.encyclopedia_detail_page.find_child("SpeciesImage", true, false).texture.resource_path == "res://assets/catalog/jewel/jewel-diamond-rosette.png")
	game._close_encyclopedia()

	game.catalog_species = jewel_entries
	game.discovered.clear()
	game.greenhouse_available.clear()
	game.unlocked_species.clear()
	game.species.clear()
	assert(game._select_species_for_seed("normal").is_empty())
	assert(game._register_species_discovery(JEWEL_IDS[0], false))
	game.rng.seed=20260913
	var registered_draws:=0
	for draw in range(120):
		var chosen_id:=str(game._select_species_for_seed("normal").get("species_id", ""))
		assert(chosen_id in JEWEL_IDS and not game._seed_new_species_blocked(chosen_id))
		if chosen_id==JEWEL_IDS[0]:registered_draws+=1
		else:assert(not bool(game.discovered.get(chosen_id,false)))
	assert(registered_draws>=100)

	print("JEWEL_SERIES_SMOKE_OK species=", jewel_entries.size(), " habitat_candidates=", habitat_candidates.size())
	get_tree().quit()
