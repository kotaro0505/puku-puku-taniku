extends Node

const FusionSystemClass = preload("res://scripts/fusion_system.gd")
const Localizer = preload("res://scripts/game_localizer.gd")
const SERIES := ["gummy", "metal", "sweets", "glow", "jewel", "jure", "stone", "sea", "yumekawa", "forest_amber"]

func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	_test_catalog_and_recipes(game)
	_test_special_recipe_precedence(game)
	_test_original_fallbacks(game)
	await _test_game_flow(game)
	game._reset_progression_state()
	game.queue_free()
	print("FUSION_SYSTEM_SMOKE_OK species=55 recipes=55 unordered=55 originals=fallback special=priority parents=GET_only cost=atomic silhouette=species_specific double_submit=blocked seeds=after_GET languages=3")
	get_tree().quit()

func _test_catalog_and_recipes(game) -> void:
	var hybrid_entries: Array[Dictionary] = []
	var ids: Dictionary = {}
	var result_series_counts: Dictionary = {}
	for entry_value in game.catalog_species:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		var fusion_series := str(entry.get("fusion_series", ""))
		var catalog_series := str(entry.get("series_id", ""))
		if catalog_series in ["gummy", "metal", "sweets", "glow", "jewel", "jurejure", "stone", "sea", "yumekawa", "forest_amber"]:
			assert(fusion_series in SERIES)
		if catalog_series != "hybrid":
			continue
		hybrid_entries.append(entry)
		var species_id := str(entry.get("species_id", ""))
		assert(species_id.begins_with("hyb_") and not ids.has(species_id))
		ids[species_id] = true
		assert(fusion_series in SERIES)
		result_series_counts[fusion_series] = int(result_series_counts.get(fusion_series, 0)) + 1
		assert(str(entry.get("name_ja", "")) != "")
		assert(str(entry.get("name_hiragana", "")) != "")
		assert(str(entry.get("name_en", "")) != "")
		assert(Localizer.species_name("ja", entry) == str(entry.get("name_ja", "")))
		assert(Localizer.species_name("hiragana", entry) == str(entry.get("name_hiragana", "")))
		assert(Localizer.species_name("en", entry) == str(entry.get("name_en", "")))
		assert(bool(entry.get("fusion_only_until_discovered", false)))
		assert(bool(entry.get("mystery_pack_eligible", false)))
		var image_path := str(entry.get("image_path", ""))
		assert(image_path == "res://assets/catalog/hybrid/%s.png" % species_id)
		assert(FileAccess.file_exists(image_path) and ResourceLoader.exists(image_path))
		var texture := load(image_path) as Texture2D
		assert(texture != null and texture.get_width() == 768 and texture.get_height() == 768)
	assert(hybrid_entries.size() == 55 and ids.size() == 55)
	assert(result_series_counts == {"gummy":6,"metal":5,"sweets":5,"glow":5,"jewel":5,"jure":6,"stone":6,"sea":6,"yumekawa":5,"forest_amber":6})
	assert(game.fusion_system.basic_recipes_by_pair.size() == 55)
	assert(game.fusion_system.special_recipes_by_pair.is_empty())
	var parent_for_series: Dictionary = {}
	for entry_value in game.catalog_species:
		if entry_value is Dictionary:
			var entry: Dictionary = entry_value
			var fusion_series := str(entry.get("fusion_series", ""))
			if fusion_series in SERIES and not parent_for_series.has(fusion_series):
				parent_for_series[fusion_series] = str(entry.get("species_id", ""))
	for first_index in range(SERIES.size()):
		for second_index in range(first_index, SERIES.size()):
			var first_id := str(parent_for_series[SERIES[first_index]])
			var second_id := str(parent_for_series[SERIES[second_index]])
			var forward: Dictionary = game.fusion_system.resolve(first_id, second_id)
			var reverse: Dictionary = game.fusion_system.resolve(second_id, first_id)
			assert(not forward.is_empty() and str(forward.get("source", "")) == "basic")
			assert(str(forward.get("result_species_id", "")) == str(reverse.get("result_species_id", "")))
	assert(str(game._catalog_entry("hyb_gummy_stone").get("fusion_series", "")) == "stone")
	assert(str(game._catalog_entry("hyb_jure_forest_amber").get("fusion_series", "")) == "forest_amber")
	assert(str(game._catalog_entry("jurejure_pure_gold").get("fusion_series", "")) == "jure")
	assert(str(game._catalog_entry("jelly_green_apple").get("fusion_series", "")) == "")

func _test_special_recipe_precedence(game) -> void:
	var gummy_id := "gummy_peach_milk"
	var metal_id := "metal_silver_rosette"
	assert(str(game.fusion_system.resolve(gummy_id, metal_id).get("result_species_id", "")) == "hyb_gummy_metal")
	game.fusion_system.set_special_recipes([{
		"parent_species_ids": [gummy_id, metal_id],
		"result_species_id": "hyb_sea_sea",
	}])
	var special: Dictionary = game.fusion_system.resolve(metal_id, gummy_id)
	assert(str(special.get("source", "")) == "special")
	assert(str(special.get("result_species_id", "")) == "hyb_sea_sea")
	game.fusion_system.configure(game.catalog_species)

func _test_original_fallbacks(game) -> void:
	var laui_id := "laui"
	var kannte_id := "kannte"
	var gummy_id := "gummy_peach_milk"
	var metal_id := "metal_silver_rosette"
	assert(game.fusion_system.is_original_species(laui_id))
	assert(game.fusion_system.is_original_species(kannte_id))
	assert(not game.fusion_system.is_original_species("golden_laui"))
	assert(str(game.fusion_system.resolve(laui_id, gummy_id).get("result_species_id", "")) == laui_id)
	assert(str(game.fusion_system.resolve(gummy_id, laui_id).get("result_species_id", "")) == laui_id)
	assert(str(game.fusion_system.resolve(laui_id, kannte_id).get("result_species_id", "")) == laui_id)
	assert(str(game.fusion_system.resolve(kannte_id, laui_id).get("result_species_id", "")) == kannte_id)
	assert(str(game.fusion_system.resolve(gummy_id, metal_id).get("result_species_id", "")) == "hyb_gummy_metal")

	game.fusion_system.set_special_recipes([{
		"parent_species_ids": [laui_id, gummy_id],
		"result_species_id": "hyb_sea_sea",
	}])
	var special: Dictionary = game.fusion_system.resolve(laui_id, gummy_id)
	assert(str(special.get("source", "")) == "special")
	assert(str(special.get("result_species_id", "")) == "hyb_sea_sea")
	game.fusion_system.configure(game.catalog_species)

	var ownership := {gummy_id: 1, "golden_laui": 1}
	var eligible_before: Array[Dictionary] = game.fusion_system.eligible_parents(ownership)
	var eligible_before_ids: Array[String] = []
	for entry in eligible_before:
		eligible_before_ids.append(str(entry.get("species_id", "")))
	assert(laui_id not in eligible_before_ids)
	assert("golden_laui" not in eligible_before_ids)
	ownership[laui_id] = 1
	var eligible_after: Array[Dictionary] = game.fusion_system.eligible_parents(ownership)
	var eligible_after_ids: Array[String] = []
	for entry in eligible_after:
		eligible_after_ids.append(str(entry.get("species_id", "")))
	assert(laui_id in eligible_after_ids)

func _test_game_flow(game) -> void:
	game._reset_progression_state()
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.habitat_awakened = true
	game.habitat_tutorial_complete = true
	game.seed_shop_open = true
	game.puku_gauge_intro_complete = true
	game.mystery_items_acquired = true
	game.mystery_catalog_tutorial_complete = true
	game.encyclopedia_unlocked = true
	game.current_mode = "greenhouse"
	var gummy_id := "gummy_peach_milk"
	var metal_id := "metal_silver_rosette"
	var glow_id := "glow_emerald_rosette"
	var laui_id := "laui"
	var hybrid_id := "hyb_gummy_metal"
	for parent_id in [gummy_id, metal_id, glow_id]:
		game.discovered[parent_id] = true
		game.greenhouse_available[parent_id] = true
		game.unlocked_species[parent_id] = true
		game.species_get_counts[parent_id] = 1
	game._apply_saved_unlocks()
	game._update_play_ui()
	assert(game.fusion_lab_button.visible)
	var eligible: Array[Dictionary] = game.fusion_system.eligible_parents(game.species_get_counts)
	assert(eligible.size() == 3)
	assert(not eligible.any(func(entry: Dictionary) -> bool: return str(entry.get("species_id", "")) == laui_id))
	game.discovered[laui_id] = true
	game.greenhouse_available[laui_id] = true
	game.unlocked_species[laui_id] = true
	game.species_get_counts[laui_id] = 1
	eligible = game.fusion_system.eligible_parents(game.species_get_counts)
	assert(eligible.any(func(entry: Dictionary) -> bool: return str(entry.get("species_id", "")) == laui_id))
	game.species_get_counts["hyb_gummy_gummy"] = 0
	assert(game.fusion_system.eligible_parents(game.species_get_counts).size() == 4)
	game._open_fusion_lab()
	assert(game.fusion_lab_ui.visible and game.fusion_lab_ui.candidates.size() == 4)
	game._on_fusion_parent_selected(0, gummy_id)
	game._on_fusion_parent_selected(1, metal_id)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(str(game.fusion_lab_ui.current_result.get("result_species_id", "")) == hybrid_id)
	assert(game.fusion_lab_ui.result_name_label.text == "金箔グミ")
	assert(game.fusion_lab_ui.result_image.texture != null)
	assert(game.fusion_lab_ui.result_image.material == game.fusion_lab_ui.silhouette_material)
	assert(str(game.fusion_lab_ui.result_image.get_meta("catalog_loaded_path", "")) == str(game._catalog_entry(hybrid_id).get("image_path", "")))
	assert(not game.fusion_lab_ui.fuse_button.disabled)
	assert(int(game.fusion_lab_ui.current_result.get("fusion_cost_puku", 0)) == 1)
	assert(game.fusion_lab_ui.fusion_cost_label.text == "1ぷくコイン")

	var hybrid_entry: Dictionary = game._catalog_entry(hybrid_id)
	hybrid_entry["fusion_cost_puku"] = 2
	game._refresh_fusion_lab_result()
	assert(int(game.fusion_lab_ui.current_result.get("fusion_cost_puku", 0)) == 2)
	assert(game.fusion_lab_ui.fusion_cost_label.text == "2ぷくコイン")
	var gummy_before: int = game._species_get_count(gummy_id)
	var metal_before: int = game._species_get_count(metal_id)
	game.puku_points = 1
	game._perform_fusion(gummy_id, metal_id)
	assert(game.puku_points == 1)
	assert(game._species_get_count(hybrid_id) == 0)
	assert(not game.fusion_in_progress)
	assert(game.fusion_lab_ui.result_status_label.text == Localizer.text("ja", "not_enough_puku"))

	game.puku_points = 3
	game._perform_fusion(gummy_id, metal_id)
	game._perform_fusion(gummy_id, metal_id)
	assert(game.fusion_in_progress)
	assert(game.puku_points == 1)
	assert(game._species_get_count(hybrid_id) == 1)
	await get_tree().create_timer(1.25).timeout
	assert(game.fusion_lab_ui.result_image.material == null)
	assert(game.fusion_lab_ui.result_new_label.visible)
	assert(game.fusion_lab_ui.result_new_label.text == "NEW")
	await get_tree().create_timer(0.75).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not game.fusion_in_progress)
	assert(game._species_get_count(gummy_id) == gummy_before)
	assert(game._species_get_count(metal_id) == metal_before)
	assert(game._species_get_count(hybrid_id) == 1)
	assert(game.puku_points == 1)
	assert(bool(game.discovered.get(hybrid_id, false)))
	assert(bool(game.greenhouse_available.get(hybrid_id, false)))
	assert(bool(game.unlocked_series.get("hybrid", false)))
	assert(game.species_get_overlay.visible)
	assert(game.species_get_overlay.name_label.text == "金箔グミ")
	assert(game.species_get_overlay.result_image.texture != null)
	game.species_get_overlay.visible = false
	game.species_get_queue.clear()
	game._open_fusion_lab()
	game._on_fusion_parent_selected(0, gummy_id)
	game._on_fusion_parent_selected(1, metal_id)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.fusion_lab_ui.result_name_label.text == "金箔グミ")
	assert(game.fusion_lab_ui.result_image.texture != null)
	assert(game.fusion_lab_ui.result_image.material == null)
	assert(not game.fusion_lab_ui.result_new_label.visible)
	game.puku_points = 2
	game._perform_fusion(gummy_id, metal_id)
	await get_tree().create_timer(2.0).timeout
	assert(game._species_get_count(hybrid_id) == 2)
	assert(game.puku_points == 0)
	assert(game.fusion_lab_ui.visible)
	assert(not game.fusion_lab_ui.result_new_label.visible)
	assert(not game.species_get_overlay.visible)
	var normal_pools: Dictionary = game._normal_seed_selection_pools()
	var known_ids: Dictionary = {}
	for entry in normal_pools.get("all_known", []):
		known_ids[str(entry.get("species_id", ""))] = true
	assert(known_ids.has(hybrid_id))
	assert(game._seed_new_species_blocked("hyb_gummy_glow"))
	assert(str(game._select_species_for_seed("mystery").get("species_id", "")) == hybrid_id)
	var hybrid_resolution: Dictionary = game.fusion_system.resolve(hybrid_id, glow_id)
	assert(str(hybrid_resolution.get("result_species_id", "")) == "hyb_gummy_glow")
	game._save()
	game.puku_points = 99
	game.discovered.erase(hybrid_id)
	game.greenhouse_available.erase(hybrid_id)
	game.species_get_counts.erase(hybrid_id)
	game._load_save()
	assert(game.puku_points == 0)
	assert(game._species_get_count(hybrid_id) == 2)
	assert(bool(game.discovered.get(hybrid_id, false)) and bool(game.greenhouse_available.get(hybrid_id, false)))
	hybrid_entry.erase("fusion_cost_puku")
