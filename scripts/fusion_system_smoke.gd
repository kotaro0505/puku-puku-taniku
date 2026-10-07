extends Node

const FusionSystemClass = preload("res://scripts/fusion_system.gd")
const FusionLabUIClass = preload("res://scripts/fusion_lab_ui.gd")
const Localizer = preload("res://scripts/game_localizer.gd")
const CatalogImageLoaderClass = preload("res://scripts/catalog_image_loader.gd")
const SERIES := ["gummy", "metal", "sweets", "glow", "jewel", "jure", "stone", "sea", "yumekawa", "forest_amber", "jelly"]
const JELLY_BASIC_RECIPES := [
	["jelly", "jelly", "hyb_jelly_jelly"],
	["gummy", "jelly", "hyb_gummy_jelly"],
	["metal", "jelly", "hyb_metal_jelly"],
	["sweets", "jelly", "hyb_sweets_jelly"],
	["glow", "jelly", "hyb_glow_jelly"],
	["jewel", "jelly", "hyb_jewel_jelly"],
	["jure", "jelly", "hyb_jure_jelly"],
	["stone", "jelly", "hyb_stone_jelly"],
	["sea", "jelly", "hyb_sea_jelly"],
	["yumekawa", "jelly", "hyb_yumekawa_jelly"],
	["forest_amber", "jelly", "hyb_forest_amber_jelly"],
]
const TIER1_RECIPES := [
	["hyb_gummy_sea", "hyb_glow_jewel", "fus1_rainbow_bubble"],
	["hyb_gummy_gummy", "hyb_stone_yumekawa", "fus1_pukupuku_planet"],
	["hyb_metal_forest_amber", "hyb_glow_glow", "fus1_moon_clock"],
	["hyb_metal_yumekawa", "hyb_metal_sea", "fus1_diving_sphere"],
	["hyb_sweets_sweets", "hyb_glow_sea", "fus1_jellyfish_parfait"],
	["hyb_sweets_sea", "hyb_jewel_yumekawa", "fus1_sunset_jelly"],
	["hyb_glow_glow", "hyb_jewel_sea", "fus1_moon_pool"],
	["hyb_glow_forest_amber", "hyb_glow_yumekawa", "fus1_firefly_dome"],
	["hyb_jewel_jewel", "hyb_metal_yumekawa", "fus1_kaleidoscope"],
	["hyb_jewel_forest_amber", "hyb_sweets_glow", "fus1_prism_drop"],
	["hyb_jure_jure", "hyb_sweets_sweets", "fus1_bonus_time"],
	["hyb_jure_sea", "hyb_jure_yumekawa", "fus1_on_vacation"],
	["hyb_stone_stone", "hyb_stone_forest_amber", "fus1_geode"],
	["hyb_stone_yumekawa", "hyb_yumekawa_forest_amber", "fus1_moss_garden"],
	["hyb_sea_sea", "hyb_glow_yumekawa", "fus1_deep_sea_aquarium"],
	["hyb_stone_sea", "hyb_glow_jewel", "fus1_tide_pool"],
	["hyb_yumekawa_yumekawa", "hyb_gummy_glow", "fus1_dream_balloon"],
	["hyb_jewel_yumekawa", "hyb_sweets_yumekawa", "fus1_dream_specimen"],
	["hyb_forest_amber_forest_amber", "hyb_jewel_stone", "fus1_strata"],
	["hyb_sea_forest_amber", "hyb_sweets_forest_amber", "fus1_amber_forest"],
	["hyb_gummy_jelly", "hyb_gummy_gummy", "fus1_jelly_bomb"],
	["hyb_sweets_jelly", "hyb_sweets_sweets", "fus1_fruit_terrine"],
]
const TIER2_EXACT_RECIPES := [
	["fus1_rainbow_bubble", "fus1_moon_clock", "fus2_moonbow"],
	["fus1_jellyfish_parfait", "fus1_deep_sea_aquarium", "fus2_abyss_glass"],
	["fus1_kaleidoscope", "fus1_geode", "fus2_kaleido_geode"],
	["fus1_firefly_dome", "fus1_amber_forest", "fus2_amber_lantern"],
	["fus1_pukupuku_planet", "fus1_dream_specimen", "fus2_planet_specimen"],
	["fus1_jelly_bomb", "fus1_bonus_time", "fus2_toro_pork_jelly"],
]
const TERMINAL_TIER2_EXACT_RECIPES := [
	["sweets_blueberry_galaxy", "hyb_sweets_jure", "fus2_whip_blue_cherry", "sweets"],
	["fus1_fruit_terrine", "sweets_strawberry_shortcake", "fus2_fruit_sweets", "sweets"],
	["fus1_sunset_jelly", "sweets_fairy_sugar", "fus2_jelly_lilac", "yumekawa"],
	["fus1_firefly_dome", "hyb_sweets_yumekawa", "fus2_yumefuwa_firefly", "glow"],
	["hyb_sweets_glow", "hyb_glow_stone", "fus2_mochi_moonstone", "stone"],
	["sweets_chocolate_gold", "hyb_sweets_forest_amber", "fus2_happy_cacao", "sweets"],
	["sweets_strawberry_shortcake", "sweets_raspberry_jewel", "fus2_love_topping", "jewel"],
	["hyb_glow_sea", "hyb_sweets_stone", "fus2_soda_sugar", "sea"],
	["hyb_sweets_yumekawa", "hyb_sweets_forest_amber", "fus2_cosmos_montblanc", "yumekawa"],
	["hyb_metal_sweets", "hyb_sweets_sea", "fus2_warm_cacao", "sweets"],
]
const TIER2_SERIES_RECIPES := [
	["fus1_diving_sphere", "glow", "glow_emerald_rosette", "fus2_deep_sea_light"],
	["fus1_sunset_jelly", "stone", "stone_black_lava_rosette", "fus2_sunset_stone"],
	["fus1_moon_pool", "jure", "jurejure_pure_gold", "fus2_moon_resort"],
	["fus1_bonus_time", "sea", "sea_coralline_drops", "fus2_fever_lagoon"],
	["fus1_moss_garden", "metal", "metal_silver_rosette", "fus2_rust_garden"],
]
const TIER3_EXACT_RECIPES := [
	["fus2_moon_resort", "shaviana", "fus3_black_hole", "jurejure"],
	["fus2_rust_garden", "laui", "fus3_golden_crown", "metal"],
	["fus2_moonbow", "kannte", "fus3_star_fragment", "yumekawa"],
	["fus2_abyss_glass", "lutea", "fus3_lagoon_lutea", "sea"],
	["fus2_sunset_stone", "colorata", "fus3_heart_of_magma", "stone"],
]

func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game._reset_progression_state()
	print("FUSION_SYSTEM_STAGE presentation")
	_test_hybrid_lab_presentation(game)
	print("FUSION_SYSTEM_STAGE catalog")
	_test_catalog_and_recipes(game)
	print("FUSION_SYSTEM_STAGE precedence")
	_test_special_recipe_precedence(game)
	_test_original_fallbacks(game)
	_test_tier1_recipes(game)
	_test_tier2_recipes(game)
	_test_tier3_recipes(game)
	print("FUSION_SYSTEM_STAGE base_flow")
	await _test_game_flow(game)
	print("FUSION_SYSTEM_STAGE tier1_flow")
	await _test_tier1_game_flow(game)
	print("FUSION_SYSTEM_STAGE tier2_flow")
	await _test_tier2_game_flow(game)
	print("FUSION_SYSTEM_STAGE terminal_tier2_flow")
	await _test_terminal_tier2_discovery_flow(game)
	print("FUSION_SYSTEM_STAGE tier3_flow")
	await _test_tier3_game_flow(game)
	game._reset_progression_state()
	game.queue_free()
	print("FUSION_SYSTEM_SMOKE_OK hybrid_lab_name=true attached_background=720x1280 result_heading_removed=true instruction_cards_separated=true symmetric_margins=true top_close_removed=true main_back=close picker_back=main processing_exit_guard=true energy_speed_unchanged=true energy_emission_3x=true fusion_series=11 basic_species=66 basic_recipes=66 tier1_species=22 tier1_special=22 tier2_species=21 tier2_exact=16 tier2_terminal=10 tier2_series=5 tier3_species=5 tier3_exact=5 transparent_images=114 jelly_catalog=24 picker_touch_contract=true unordered=true originals=fallback exact_then_series_special=priority parents=GET_only terminal_results=true cost=atomic silhouette=species_specific double_submit=blocked known_result=disabled return_after_GET=lab seeds=after_GET languages=3")
	get_tree().quit()

func _test_hybrid_lab_presentation(game) -> void:
	assert(FileAccess.file_exists(FusionLabUIClass.HYBRID_LAB_BACKGROUND_PATH))
	assert(game.fusion_lab_ui.background_image != null)
	assert(game.fusion_lab_ui.background_image.texture != null)
	assert(game.fusion_lab_ui.background_image.texture.resource_path == FusionLabUIClass.HYBRID_LAB_BACKGROUND_PATH)
	assert(game.fusion_lab_ui.background_image.texture.get_width() == 720)
	assert(game.fusion_lab_ui.background_image.texture.get_height() == 1280)
	assert(game.fusion_lab_ui.background_image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert(game.fusion_lab_ui.find_child("ResultHeading", true, false) == null)
	var result_frame := game.fusion_lab_ui.find_child("FusionResultFrame", true, false) as Control
	assert(result_frame != null)
	var instruction_bottom: float = game.fusion_lab_ui.instruction_label.position.y + game.fusion_lab_ui.instruction_label.size.y
	assert(instruction_bottom <= game.fusion_lab_ui.parent_a_button.position.y)
	assert(instruction_bottom <= game.fusion_lab_ui.parent_b_button.position.y)
	assert(instruction_bottom <= result_frame.position.y)
	var left_margin: float = game.fusion_lab_ui.parent_a_button.position.x
	var right_margin: float = game.fusion_lab_ui.main_page.size.x - (game.fusion_lab_ui.parent_b_button.position.x + game.fusion_lab_ui.parent_b_button.size.x)
	assert(is_equal_approx(left_margin, right_margin))
	var left_gap: float = result_frame.position.x - (game.fusion_lab_ui.parent_a_button.position.x + game.fusion_lab_ui.parent_a_button.size.x)
	var right_gap: float = game.fusion_lab_ui.parent_b_button.position.x - (result_frame.position.x + result_frame.size.x)
	assert(is_equal_approx(left_gap, right_gap) and left_gap >= 8.0)
	assert(game.fusion_lab_ui.main_page.position.y + game.fusion_lab_ui.back_button.position.y + game.fusion_lab_ui.back_button.size.y <= 1024.0)
	var top_level_buttons: Array = game.fusion_lab_ui.get_children().filter(func(child: Node) -> bool: return child is Button)
	assert(top_level_buttons.is_empty())
	var no_candidates: Array[Dictionary] = []
	game.fusion_lab_ui.open_lab(no_candidates, {})
	game.fusion_lab_ui._open_picker(0)
	game.fusion_lab_ui.picker_back_button.pressed.emit()
	assert(game.fusion_lab_ui.visible and game.fusion_lab_ui.main_page.visible and not game.fusion_lab_ui.picker_page.visible)
	game.fusion_lab_ui.set_processing_state(true)
	assert(game.fusion_lab_ui.back_button.disabled)
	game.fusion_lab_ui._request_close()
	assert(game.fusion_lab_ui.visible)
	game.fusion_lab_ui.set_processing_state(false)
	game.fusion_lab_ui.back_button.pressed.emit()
	assert(not game.fusion_lab_ui.visible)
	assert(Localizer.text("ja", "fusion_title") == "ハイブリッドラボ")
	assert(Localizer.text("hiragana", "fusion_title") == "はいぶりっどらぼ")
	assert(Localizer.text("en", "fusion_title") == "Hybrid Lab")
	assert("配合結果" not in Localizer.text("ja", "fusion_result_hint"))
	assert(FusionLabUIClass.ENERGY_WAVE_COUNT == 3)
	assert(FusionLabUIClass.ENERGY_PARTICLES_PER_WAVE == 8)
	assert(is_equal_approx(FusionLabUIClass.ENERGY_PARTICLE_TRAVEL_SECONDS, 0.42))
	assert(is_equal_approx(FusionLabUIClass.ENERGY_PARTICLE_FADE_SECONDS, 0.18))
	assert(is_equal_approx(FusionLabUIClass.ENERGY_PARTICLE_STAGGER_SECONDS, 0.035))
	assert(str(FusionLabUIClass.SERIES_LABELS["ja"].get("jelly", "")) == "ゼリー")
	assert(str(FusionLabUIClass.SERIES_LABELS["hiragana"].get("jelly", "")) == "ぜりー")
	assert(str(FusionLabUIClass.SERIES_LABELS["en"].get("jelly", "")) == "Jelly")

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
		if catalog_series in ["gummy", "metal", "sweets", "glow", "jewel", "jurejure", "stone", "sea", "yumekawa", "forest_amber", "jelly"]:
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
		_assert_transparent_catalog_image(image_path, Vector2i(768, 768))
	assert(hybrid_entries.size() == 66 and ids.size() == 66)
	assert(result_series_counts == {"gummy":6,"metal":5,"sweets":5,"glow":5,"jewel":5,"jure":6,"stone":6,"sea":6,"yumekawa":5,"forest_amber":6,"jelly":11})
	assert(game.fusion_system.basic_recipes_by_pair.size() == 66)
	assert(game.fusion_system.special_recipes_by_pair.size() == 43)
	assert(game.fusion_system.series_special_recipes_by_species.size() == 5)
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
	for recipe in JELLY_BASIC_RECIPES:
		var first_id := str(parent_for_series[str(recipe[0])])
		var second_id := str(parent_for_series[str(recipe[1])])
		assert(str(game.fusion_system.resolve(first_id, second_id).get("result_species_id", "")) == str(recipe[2]))
		assert(str(game.fusion_system.resolve(second_id, first_id).get("result_species_id", "")) == str(recipe[2]))
	assert(str(game._catalog_entry("hyb_gummy_stone").get("fusion_series", "")) == "stone")
	assert(str(game._catalog_entry("hyb_jure_forest_amber").get("fusion_series", "")) == "forest_amber")
	assert(str(game._catalog_entry("jurejure_pure_gold").get("fusion_series", "")) == "jure")
	assert(str(game._catalog_entry("jelly_green_apple").get("fusion_series", "")) == "jelly")
	var jelly_parent_ids: Array[String] = []
	for entry in game.fusion_system.eligible_parents({"jelly_green_apple": 1}):
		jelly_parent_ids.append(str(entry.get("species_id", "")))
	assert("jelly_green_apple" in jelly_parent_ids)
	var jelly_catalog_ids: Array[String] = []
	for entry in game._catalog_display_entries_for_series("jelly"):
		jelly_catalog_ids.append(str(entry.get("species_id", "")))
	assert(jelly_catalog_ids.size() == 24)
	for recipe in JELLY_BASIC_RECIPES:
		assert(str(recipe[2]) in jelly_catalog_ids)
	assert("fus1_jelly_bomb" in jelly_catalog_ids and "fus1_fruit_terrine" in jelly_catalog_ids and "fus2_toro_pork_jelly" in jelly_catalog_ids)

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
	game.fusion_system.set_series_special_recipes([{
		"parent_species_id": gummy_id,
		"parent_series": "metal",
		"result_species_id": "hyb_gummy_stone",
	}])
	var exact_still_wins: Dictionary = game.fusion_system.resolve(gummy_id, metal_id)
	assert(str(exact_still_wins.get("source", "")) == "special")
	assert(str(exact_still_wins.get("result_species_id", "")) == "hyb_sea_sea")
	game.fusion_system.set_special_recipes([])
	var series_special: Dictionary = game.fusion_system.resolve(metal_id, gummy_id)
	assert(str(series_special.get("source", "")) == "series_special")
	assert(str(series_special.get("result_species_id", "")) == "hyb_gummy_stone")
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

func _test_tier1_recipes(game) -> void:
	var tier1_ids: Dictionary = {}
	for recipe in TIER1_RECIPES:
		var parent_a_id := str(recipe[0])
		var parent_b_id := str(recipe[1])
		var result_id := str(recipe[2])
		var forward: Dictionary = game.fusion_system.resolve(parent_a_id, parent_b_id)
		var reverse: Dictionary = game.fusion_system.resolve(parent_b_id, parent_a_id)
		assert(str(forward.get("source", "")) == "special")
		assert(str(forward.get("result_species_id", "")) == result_id)
		assert(str(reverse.get("result_species_id", "")) == result_id)
		assert(int(forward.get("fusion_cost_puku", 0)) == 2)
		var entry: Dictionary = game._catalog_entry(result_id)
		assert(not entry.is_empty() and int(entry.get("fusion_tier", 0)) == 1)
		assert(bool(entry.get("fusion_parent_enabled", false)))
		assert(str(entry.get("fusion_series", "")).is_empty())
		assert(str(entry.get("fusion_display_series", "")) in SERIES)
		assert(game.fusion_system.fusion_series_for_entry(entry).is_empty())
		assert(str(entry.get("series_id", "")) == "fusion_tier1")
		var image_path := str(entry.get("image_path", ""))
		assert(image_path == "res://assets/catalog/fusion_tier1/%s.png" % result_id)
		assert(FileAccess.file_exists(image_path) and ResourceLoader.exists(image_path))
		var texture := load(image_path) as Texture2D
		assert(texture != null and texture.get_width() == 1254 and texture.get_height() == 1254)
		_assert_transparent_catalog_image(image_path, Vector2i(1254, 1254))
		tier1_ids[result_id] = true
	assert(tier1_ids.size() == 22)
	var tier1_series: Dictionary = game._series_entry("fusion_tier1")
	assert(not tier1_series.is_empty())
	assert((tier1_series.get("species_ids", []) as Array).size() == 22)
	# Higher-tier parents are selectable after GET but never enter a basic
	# series fallback when no species-id recipe exists.
	var ownership := {"fus1_rainbow_bubble": 1, "fus1_pukupuku_planet": 1}
	var eligible_ids: Array[String] = []
	for entry in game.fusion_system.eligible_parents(ownership):
		eligible_ids.append(str(entry.get("species_id", "")))
	assert("fus1_rainbow_bubble" in eligible_ids and "fus1_pukupuku_planet" in eligible_ids)
	assert(game.fusion_system.resolve("fus1_rainbow_bubble", "fus1_pukupuku_planet").is_empty())
	assert(game.fusion_system.resolve("fus1_rainbow_bubble", "metal_silver_rosette").is_empty())

func _test_tier2_recipes(game) -> void:
	var tier2_ids: Dictionary = {}
	var terminal_tier2_ids: Dictionary = {}
	var terminal_display_series: Dictionary = {}
	for recipe in TIER2_EXACT_RECIPES:
		var parent_a_id := str(recipe[0])
		var parent_b_id := str(recipe[1])
		var result_id := str(recipe[2])
		var forward: Dictionary = game.fusion_system.resolve(parent_a_id, parent_b_id)
		var reverse: Dictionary = game.fusion_system.resolve(parent_b_id, parent_a_id)
		assert(str(forward.get("source", "")) == "special")
		assert(str(forward.get("result_species_id", "")) == result_id)
		assert(str(reverse.get("result_species_id", "")) == result_id)
		assert(int(forward.get("fusion_cost_puku", 0)) == 3)
		tier2_ids[result_id] = true
	for recipe in TERMINAL_TIER2_EXACT_RECIPES:
		var parent_a_id := str(recipe[0])
		var parent_b_id := str(recipe[1])
		var result_id := str(recipe[2])
		var display_series := str(recipe[3])
		var forward: Dictionary = game.fusion_system.resolve(parent_a_id, parent_b_id)
		var reverse: Dictionary = game.fusion_system.resolve(parent_b_id, parent_a_id)
		assert(str(forward.get("source", "")) == "special")
		assert(str(forward.get("result_species_id", "")) == result_id)
		assert(str(reverse.get("source", "")) == "special")
		assert(str(reverse.get("result_species_id", "")) == result_id)
		assert(int(forward.get("fusion_cost_puku", 0)) == 3)
		var result_entry: Dictionary = game._catalog_entry(result_id)
		assert(str(result_entry.get("fusion_display_series", "")) == display_series)
		assert((result_entry.get("fusion_parent_species_ids", []) as Array) == [parent_a_id, parent_b_id])
		terminal_tier2_ids[result_id] = true
		terminal_display_series[result_id] = display_series
		tier2_ids[result_id] = true
	for recipe in TIER2_SERIES_RECIPES:
		var fixed_id := str(recipe[0])
		var expected_series := str(recipe[1])
		var series_parent_id := str(recipe[2])
		var result_id := str(recipe[3])
		assert(game.fusion_system.fusion_series_for_species(series_parent_id) == expected_series)
		var forward: Dictionary = game.fusion_system.resolve(fixed_id, series_parent_id)
		var reverse: Dictionary = game.fusion_system.resolve(series_parent_id, fixed_id)
		assert(str(forward.get("source", "")) == "series_special")
		assert(str(forward.get("result_species_id", "")) == result_id)
		assert(str(reverse.get("result_species_id", "")) == result_id)
		assert(int(forward.get("fusion_cost_puku", 0)) == 3)
		var matching_parent_count := 0
		for candidate_value in game.catalog_species:
			if not candidate_value is Dictionary:
				continue
			var candidate: Dictionary = candidate_value
			if game.fusion_system.fusion_series_for_entry(candidate) != expected_series:
				continue
			matching_parent_count += 1
			var candidate_id := str(candidate.get("species_id", ""))
			assert(str(game.fusion_system.resolve(fixed_id, candidate_id).get("result_species_id", "")) == result_id)
			assert(str(game.fusion_system.resolve(candidate_id, fixed_id).get("result_species_id", "")) == result_id)
		assert(matching_parent_count > 0)
		tier2_ids[result_id] = true
	assert(tier2_ids.size() == 21)
	assert(terminal_tier2_ids.size() == 10)
	for result_id_value in tier2_ids:
		var result_id := str(result_id_value)
		var entry: Dictionary = game._catalog_entry(result_id)
		assert(not entry.is_empty() and int(entry.get("fusion_tier", 0)) == 2)
		assert(bool(entry.get("fusion_parent_enabled", false)) != terminal_tier2_ids.has(result_id))
		assert(str(entry.get("fusion_series", "")).is_empty())
		assert(str(entry.get("fusion_display_series", "")) in SERIES)
		assert(game.fusion_system.fusion_series_for_entry(entry).is_empty())
		assert(str(entry.get("series_id", "")) == "fusion_tier2")
		assert(int(entry.get("fusion_cost_puku", 0)) == 3)
		assert(str(entry.get("name_ja", "")) != "")
		assert(str(entry.get("name_hiragana", "")) != "")
		assert(str(entry.get("name_en", "")) != "")
		assert(Localizer.species_name("ja", entry) == str(entry.get("name_ja", "")))
		assert(Localizer.species_name("hiragana", entry) == str(entry.get("name_hiragana", "")))
		assert(Localizer.species_name("en", entry) == str(entry.get("name_en", "")))
		if terminal_tier2_ids.has(result_id):
			var display_series := str(terminal_display_series.get(result_id, ""))
			assert(str(entry.get("fusion_display_series", "")) == display_series)
			assert(game._catalog_display_entries_for_series(display_series).any(func(candidate: Dictionary) -> bool: return str(candidate.get("species_id", "")) == result_id))
			assert(game._seed_new_species_blocked(result_id))
		var image_path := str(entry.get("image_path", ""))
		assert(image_path == "res://assets/catalog/fusion_tier2/%s.png" % result_id)
		assert(FileAccess.file_exists(image_path) and ResourceLoader.exists(image_path))
		var texture := load(image_path) as Texture2D
		var expected_size := Vector2i(1278, 1230) if result_id == "fus2_toro_pork_jelly" else Vector2i(1254, 1254)
		assert(texture != null and Vector2i(texture.get_width(), texture.get_height()) == expected_size)
		_assert_transparent_catalog_image(image_path, expected_size)
	var tier2_series: Dictionary = game._series_entry("fusion_tier2")
	assert(not tier2_series.is_empty())
	assert((tier2_series.get("species_ids", []) as Array).size() == 21)
	assert(str(tier2_series.get("cover_image_path", "")) == "res://assets/catalog/fusion_tier2/fus2_moonbow.png")
	var image_loader = CatalogImageLoaderClass.new()
	assert(image_loader._versioned_relative_path("assets/catalog/hybrid/hyb_gummy_gummy.png") == "assets/catalog/hybrid/hyb_gummy_gummy.png?v=hybrid-20261002-2")
	assert(image_loader._versioned_relative_path("assets/catalog/fusion_tier2/fus2_moonbow.png") == "assets/catalog/fusion_tier2/fus2_moonbow.png?v=fusion-tier2-20261007-3")
	assert(image_loader._versioned_relative_path("assets/catalog/fusion_tier1/fus1_rainbow_bubble.png") == "assets/catalog/fusion_tier1/fus1_rainbow_bubble.png?v=fusion-tier1-20261002-2")
	assert(image_loader._versioned_relative_path("assets/catalog/fusion_tier3/fus3_black_hole.png") == "assets/catalog/fusion_tier3/fus3_black_hole.png?v=fusion-tier3-20261006-1")
	image_loader.free()
	# Wrong series do not match, and a higher-tier display family never acts as
	# the series side of a species-to-series recipe.
	assert(game.fusion_system.resolve("fus1_diving_sphere", "sea_coralline_drops").is_empty())
	assert(game.fusion_system.resolve("fus1_sunset_jelly", "glow_emerald_rosette").is_empty())
	assert(game.fusion_system.resolve("fus1_diving_sphere", "fus1_firefly_dome").is_empty())
	assert(game.fusion_system.resolve("fus1_diving_sphere", "fus2_deep_sea_light").is_empty())
	# GET makes tier-2 species selectable as future exact-recipe parents, but it
	# still cannot enter the 66 basic recipe matrix.
	var ownership := {"fus2_moonbow": 1, "fus2_abyss_glass": 1, "fus2_whip_blue_cherry": 1, "fus2_warm_cacao": 1}
	var eligible_ids: Array[String] = []
	for entry in game.fusion_system.eligible_parents(ownership):
		eligible_ids.append(str(entry.get("species_id", "")))
	assert("fus2_moonbow" in eligible_ids and "fus2_abyss_glass" in eligible_ids)
	assert("fus2_whip_blue_cherry" not in eligible_ids and "fus2_warm_cacao" not in eligible_ids)
	assert(game.fusion_system.resolve("fus2_moonbow", "metal_silver_rosette").is_empty())

func _test_tier3_recipes(game) -> void:
	var tier3_ids: Dictionary = {}
	for recipe in TIER3_EXACT_RECIPES:
		var parent_a_id := str(recipe[0])
		var parent_b_id := str(recipe[1])
		var result_id := str(recipe[2])
		var display_series_id := str(recipe[3])
		assert(game.fusion_system.is_original_species(parent_b_id))
		var forward: Dictionary = game.fusion_system.resolve(parent_a_id, parent_b_id)
		var reverse: Dictionary = game.fusion_system.resolve(parent_b_id, parent_a_id)
		assert(str(forward.get("source", "")) == "special")
		assert(str(reverse.get("source", "")) == "special")
		assert(str(forward.get("result_species_id", "")) == result_id)
		assert(str(reverse.get("result_species_id", "")) == result_id)
		assert(int(forward.get("fusion_cost_puku", 0)) == 3)
		var entry: Dictionary = game._catalog_entry(result_id)
		assert(not entry.is_empty() and str(entry.get("series_id", "")) == "fusion_tier3")
		assert(int(entry.get("fusion_tier", 0)) == 3 and bool(entry.get("fusion_parent_enabled", false)))
		assert(str(entry.get("fusion_display_series", "")) == ("jure" if display_series_id == "jurejure" else display_series_id))
		assert(game._catalog_display_series_id_for_entry(entry) == display_series_id)
		assert(game._catalog_display_entries_for_series(display_series_id).any(func(candidate: Dictionary) -> bool: return str(candidate.get("species_id", "")) == result_id))
		assert(game.fusion_system.fusion_series_for_entry(entry).is_empty())
		assert(str(entry.get("name_ja", "")) != "" and str(entry.get("name_hiragana", "")) != "" and str(entry.get("name_en", "")) != "")
		assert(Localizer.species_name("ja", entry) == str(entry.get("name_ja", "")))
		assert(Localizer.species_name("hiragana", entry) == str(entry.get("name_hiragana", "")))
		assert(Localizer.species_name("en", entry) == str(entry.get("name_en", "")))
		var image_path := str(entry.get("image_path", ""))
		assert(image_path == "res://assets/catalog/fusion_tier3/%s.png" % result_id)
		assert(FileAccess.file_exists(image_path) and ResourceLoader.exists(image_path))
		var texture := load(image_path) as Texture2D
		assert(texture != null and texture.get_width() == 1254 and texture.get_height() == 1254)
		_assert_transparent_catalog_image(image_path, Vector2i(1254, 1254))
		assert(game._seed_new_species_blocked(result_id))
		tier3_ids[result_id] = true
	assert(tier3_ids.size() == 5)
	var tier3_series: Dictionary = game._series_entry("fusion_tier3")
	assert(not tier3_series.is_empty() and (tier3_series.get("species_ids", []) as Array).size() == 5)
	assert(game._catalog_series_hidden_from_navigation(tier3_series))
	var ownership := {"fus3_black_hole": 1, "fus3_golden_crown": 1}
	var eligible_ids: Array[String] = []
	for entry in game.fusion_system.eligible_parents(ownership):
		eligible_ids.append(str(entry.get("species_id", "")))
	assert("fus3_black_hole" in eligible_ids and "fus3_golden_crown" in eligible_ids)
	assert(game.fusion_system.resolve("fus3_black_hole", "metal_silver_rosette").is_empty())

func _assert_transparent_catalog_image(image_path: String, expected_size: Vector2i) -> void:
	var file := FileAccess.open(image_path, FileAccess.READ)
	assert(file != null)
	var image_bytes := file.get_buffer(file.get_length())
	var image := Image.new()
	assert(image.load_png_from_buffer(image_bytes) == OK)
	assert(Vector2i(image.get_width(), image.get_height()) == expected_size)
	assert(image.get_format() == Image.FORMAT_RGBA8)
	assert(image.detect_alpha() != Image.ALPHA_NONE)
	assert(image.get_pixel(0, 0).a <= 0.001)
	assert(image.get_pixel(image.get_width() - 1, 0).a <= 0.001)
	assert(image.get_pixel(0, image.get_height() - 1).a <= 0.001)
	assert(image.get_pixel(image.get_width() - 1, image.get_height() - 1).a <= 0.001)
	assert(image.get_pixel(image.get_width() / 2, image.get_height() / 2).a >= 0.99)

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
	await _test_parent_picker_touch_scrolling(game)
	game.fusion_parent_a_id = ""
	game.fusion_parent_b_id = ""
	game.fusion_lab_ui.close_lab()
	game._open_fusion_lab()
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
	assert(game.fusion_in_progress)
	assert(game.fusion_lab_ui.result_image.modulate.a <= 0.01)
	await get_tree().create_timer(1.05).timeout
	assert(game.fusion_lab_ui.result_image.material == null)
	assert(game.fusion_lab_ui.result_new_label.visible)
	assert(game.fusion_lab_ui.result_new_label.text == "NEW")
	await get_tree().create_timer(0.85).timeout
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
	while game.species_get_overlay.busy:
		await get_tree().process_frame
	game.species_get_overlay.close_overlay()
	await get_tree().create_timer(.25).timeout
	await get_tree().process_frame
	assert(game.fusion_lab_ui.visible)
	assert(game.fusion_parent_a_id == gummy_id and game.fusion_parent_b_id == metal_id)
	assert(game.fusion_lab_ui.result_name_label.text == "金箔グミ")
	assert(game.fusion_lab_ui.result_image.texture != null)
	assert(game.fusion_lab_ui.result_image.material == null)
	assert(not game.fusion_lab_ui.result_new_label.visible)
	assert(game.fusion_lab_ui.fuse_button.disabled)
	game.puku_points = 2
	var known_balance_before: int = game.puku_balance_units
	game._perform_fusion(gummy_id, metal_id)
	assert(game._species_get_count(hybrid_id) == 1)
	assert(game.puku_balance_units == known_balance_before)
	assert(game.fusion_lab_ui.visible)
	assert(not game.fusion_lab_ui.result_new_label.visible)
	assert(not game.species_get_overlay.visible)
	assert(game.fusion_lab_ui.result_status_label.text == Localizer.text("ja", "fusion_result_known"))
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
	assert(game.puku_points == 2)
	assert(game._species_get_count(hybrid_id) == 1)
	assert(bool(game.discovered.get(hybrid_id, false)) and bool(game.greenhouse_available.get(hybrid_id, false)))
	hybrid_entry.erase("fusion_cost_puku")

func _test_parent_picker_touch_scrolling(game) -> void:
	var scroll_candidates: Array[Dictionary] = []
	for entry_value in game.fusion_lab_ui.candidates:
		if entry_value is Dictionary:
			scroll_candidates.append((entry_value as Dictionary).duplicate(true))
	for entry_value in game.catalog_species:
		if not (entry_value is Dictionary):
			continue
		var entry := entry_value as Dictionary
		var species_id := str(entry.get("species_id", ""))
		if species_id.is_empty() or scroll_candidates.any(func(candidate: Dictionary) -> bool: return str(candidate.get("species_id", "")) == species_id):
			continue
		scroll_candidates.append(entry.duplicate(true))
		if scroll_candidates.size() == 12:
			break
	assert(scroll_candidates.size() == 12)
	game.fusion_lab_ui.open_lab(scroll_candidates, game.species_get_counts)
	game.fusion_lab_ui._open_picker(0)
	await get_tree().process_frame
	await get_tree().process_frame
	var picker_scroll: ScrollContainer = game.fusion_lab_ui.picker_scroll
	assert(picker_scroll.scroll_deadzone == 12)
	assert(picker_scroll.mouse_filter == Control.MOUSE_FILTER_STOP)
	assert(game.fusion_lab_ui.picker_grid.mouse_filter == Control.MOUSE_FILTER_PASS)
	assert(picker_scroll.get_v_scroll_bar().max_value > picker_scroll.size.y)
	var first_card := game.fusion_lab_ui.picker_grid.get_child(0) as Button
	assert(first_card != null)
	assert(first_card.action_mode == BaseButton.ACTION_MODE_BUTTON_RELEASE)
	assert(first_card.mouse_filter == Control.MOUSE_FILTER_PASS)
	assert(first_card.mouse_force_pass_scroll_events)
	var first_species_id := str(first_card.get_meta("species_id", ""))
	picker_scroll.scroll_vertical = 100000
	await get_tree().process_frame
	assert(picker_scroll.scroll_vertical > 0)
	assert(game.fusion_lab_ui.picker_page.visible)
	assert(game.fusion_parent_a_id.is_empty())
	first_card.pressed.emit()
	await get_tree().process_frame
	assert(game.fusion_parent_a_id == first_species_id)
	assert(game.fusion_lab_ui.main_page.visible and not game.fusion_lab_ui.picker_page.visible)

func _test_tier1_game_flow(game) -> void:
	game._reset_progression_state()
	game.fusion_lab_ui.close_lab()
	game.species_get_overlay.visible = false
	game.species_get_queue.clear()
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
	var parent_a_id := "hyb_gummy_sea"
	var parent_b_id := "hyb_glow_jewel"
	var result_id := "fus1_rainbow_bubble"
	for parent_id in [parent_a_id, parent_b_id]:
		game.discovered[parent_id] = true
		game.greenhouse_available[parent_id] = true
		game.unlocked_species[parent_id] = true
		game.species_get_counts[parent_id] = 1
	game._apply_saved_unlocks()

	# Unknown fusion species live at the end of their visual-family page. Their
	# own image supplies the silhouette, while identity stays hidden until GET.
	game.current_encyclopedia_series_id = "gummy"
	game._refresh_encyclopedia_cards()
	assert(game.encyclopedia_card_entries.size() == game._catalog_display_entries_for_series("gummy").size())
	var unknown_index := -1
	for index in range(game.encyclopedia_card_entries.size()):
		if str(game.encyclopedia_card_entries[index].get("species_id", "")) == result_id:
			unknown_index = index
			break
	assert(unknown_index >= 0)
	var unknown_image: TextureRect = game.encyclopedia_card_images[unknown_index]
	game._request_species_texture(game._catalog_entry(result_id), unknown_image, true)
	assert(unknown_image.texture != null)
	assert(unknown_image.material == game.encyclopedia_silhouette_material)
	assert(unknown_image.material != null)
	var unknown_card: Button = unknown_image.get_parent().get_parent().get_parent()
	var formal_name_visible := false
	var unknown_name_visible := false
	for label_value in unknown_card.find_children("*", "Label", true, false):
		var label := label_value as Label
		if label and label.text == "レインボーバブル":
			formal_name_visible = true
		if label and label.text == "？？？":
			unknown_name_visible = true
	assert(not formal_name_visible and unknown_name_visible and unknown_card.disabled)
	unknown_card.pressed.emit()
	assert(not game.encyclopedia_detail_page.visible)

	game._open_fusion_lab()
	game._on_fusion_parent_selected(0, parent_a_id)
	game._on_fusion_parent_selected(1, parent_b_id)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(str(game.fusion_lab_ui.current_result.get("result_species_id", "")) == result_id)
	assert(game.fusion_lab_ui.result_name_label.text == "レインボーバブル")
	assert(game.fusion_lab_ui.fusion_cost_label.text == "2ぷくコイン")
	assert(game.fusion_lab_ui.result_image.texture != null)
	assert(game.fusion_lab_ui.result_image.material == game.fusion_lab_ui.silhouette_material)
	var parent_a_before: int = game._species_get_count(parent_a_id)
	var parent_b_before: int = game._species_get_count(parent_b_id)
	game.puku_points = 1
	game._perform_fusion(parent_a_id, parent_b_id)
	assert(game.puku_points == 1)
	assert(game._species_get_count(result_id) == 0)
	assert(game.fusion_lab_ui.result_status_label.text == Localizer.text("ja", "not_enough_puku"))

	game.puku_points = 2
	game._perform_fusion(parent_a_id, parent_b_id)
	game._perform_fusion(parent_a_id, parent_b_id)
	assert(game.fusion_in_progress)
	assert(game.puku_points == 0)
	assert(game._species_get_count(result_id) == 1)
	await get_tree().create_timer(3.1).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not game.fusion_in_progress)
	assert(game._species_get_count(parent_a_id) == parent_a_before)
	assert(game._species_get_count(parent_b_id) == parent_b_before)
	assert(game._species_get_count(result_id) == 1)
	assert(bool(game.discovered.get(result_id, false)))
	assert(bool(game.greenhouse_available.get(result_id, false)))
	assert(bool(game.unlocked_series.get("fusion_tier1", false)))
	assert(game.species_get_overlay.visible)
	assert(game.species_get_overlay.name_label.text == "レインボーバブル")
	assert(game.species_get_overlay.result_image.texture != null)
	var eligible_after_get: Array[Dictionary] = game.fusion_system.eligible_parents(game.species_get_counts)
	assert(eligible_after_get.any(func(entry: Dictionary) -> bool: return str(entry.get("species_id", "")) == result_id))

	game.species_get_overlay.visible = false
	game.species_get_queue.clear()
	game.current_encyclopedia_series_id = "gummy"
	game._refresh_encyclopedia_cards()
	var known_index := -1
	for index in range(game.encyclopedia_card_entries.size()):
		if str(game.encyclopedia_card_entries[index].get("species_id", "")) == result_id:
			known_index = index
			break
	assert(known_index >= 0)
	var known_image: TextureRect = game.encyclopedia_card_images[known_index]
	game._request_species_texture(game._catalog_entry(result_id), known_image, true)
	assert(known_image.texture != null and known_image.material == null)
	var normal_pools: Dictionary = game._normal_seed_selection_pools()
	assert((normal_pools.get("all_known", []) as Array).any(func(entry: Dictionary) -> bool: return str(entry.get("species_id", "")) == result_id))
	assert(game._seed_new_species_blocked("fus1_pukupuku_planet"))
	game._save()
	game.discovered.erase(result_id)
	game.greenhouse_available.erase(result_id)
	game.species_get_counts.erase(result_id)
	game.unlocked_series.erase("fusion_tier1")
	game._load_save()
	assert(game._species_get_count(result_id) == 1)
	assert(bool(game.discovered.get(result_id, false)) and bool(game.greenhouse_available.get(result_id, false)))
	assert(bool(game.unlocked_series.get("fusion_tier1", false)))

func _test_tier2_game_flow(game) -> void:
	game._reset_progression_state()
	game.fusion_lab_ui.close_lab()
	game.species_get_overlay.visible = false
	game.species_get_queue.clear()
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
	var parent_a_id := "fus1_rainbow_bubble"
	var parent_b_id := "fus1_moon_clock"
	var result_id := "fus2_moonbow"
	for parent_id in [parent_a_id, parent_b_id]:
		game.discovered[parent_id] = true
		game.greenhouse_available[parent_id] = true
		game.unlocked_species[parent_id] = true
		game.species_get_counts[parent_id] = 1
	game._apply_saved_unlocks()
	game._open_fusion_lab()
	game._on_fusion_parent_selected(0, parent_a_id)
	game._on_fusion_parent_selected(1, parent_b_id)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(str(game.fusion_lab_ui.current_result.get("result_species_id", "")) == result_id)
	assert(game.fusion_lab_ui.result_name_label.text == "ムーンボウ")
	assert(game.fusion_lab_ui.fusion_cost_label.text == "3ぷくコイン")
	assert(game.fusion_lab_ui.result_image.texture != null)
	assert(game.fusion_lab_ui.result_image.material == game.fusion_lab_ui.silhouette_material)
	var parent_a_before: int = game._species_get_count(parent_a_id)
	var parent_b_before: int = game._species_get_count(parent_b_id)
	game.puku_points = 2
	game._perform_fusion(parent_a_id, parent_b_id)
	assert(game.puku_points == 2)
	assert(game._species_get_count(result_id) == 0)
	assert(game.fusion_lab_ui.result_status_label.text == Localizer.text("ja", "not_enough_puku"))
	game.puku_points = 3
	game._perform_fusion(parent_a_id, parent_b_id)
	game._perform_fusion(parent_a_id, parent_b_id)
	assert(game.fusion_in_progress)
	assert(game.puku_points == 0)
	assert(game._species_get_count(result_id) == 1)
	await get_tree().create_timer(3.1).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not game.fusion_in_progress)
	assert(game._species_get_count(parent_a_id) == parent_a_before)
	assert(game._species_get_count(parent_b_id) == parent_b_before)
	assert(game._species_get_count(result_id) == 1)
	assert(bool(game.discovered.get(result_id, false)))
	assert(bool(game.greenhouse_available.get(result_id, false)))
	assert(bool(game.unlocked_series.get("fusion_tier2", false)))

	assert(game.species_get_overlay.visible)
	assert(game.species_get_overlay.name_label.text == "ムーンボウ")
	assert(game.species_get_overlay.result_image.texture != null)
	var eligible_after_get: Array[Dictionary] = game.fusion_system.eligible_parents(game.species_get_counts)
	assert(eligible_after_get.any(func(entry: Dictionary) -> bool: return str(entry.get("species_id", "")) == result_id))
	game.species_get_overlay.visible = false
	game.species_get_queue.clear()
	game.current_encyclopedia_series_id = "yumekawa"
	game._refresh_encyclopedia_cards()
	assert(game.encyclopedia_card_entries.size() == game._catalog_display_entries_for_series("yumekawa").size())
	var known_index := -1
	for index in range(game.encyclopedia_card_entries.size()):
		if str(game.encyclopedia_card_entries[index].get("species_id", "")) == result_id:
			known_index = index
			break
	assert(known_index >= 0)
	var known_image: TextureRect = game.encyclopedia_card_images[known_index]
	game._request_species_texture(game._catalog_entry(result_id), known_image, true)
	assert(known_image.texture != null and known_image.material == null)
	var normal_pools: Dictionary = game._normal_seed_selection_pools()
	assert((normal_pools.get("all_known", []) as Array).any(func(entry: Dictionary) -> bool: return str(entry.get("species_id", "")) == result_id))
	assert(game._seed_new_species_blocked("fus2_abyss_glass"))
	game._save()
	game.discovered.erase(result_id)
	game.greenhouse_available.erase(result_id)
	game.species_get_counts.erase(result_id)
	game.unlocked_series.erase("fusion_tier2")
	game._load_save()
	assert(game.puku_points == 0)
	assert(game._species_get_count(result_id) == 1)
	assert(bool(game.discovered.get(result_id, false)) and bool(game.greenhouse_available.get(result_id, false)))
	assert(bool(game.unlocked_series.get("fusion_tier2", false)))

func _test_terminal_tier2_discovery_flow(game) -> void:
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
	var result_ids: Array[String] = []
	for recipe in TERMINAL_TIER2_EXACT_RECIPES:
		var result_id := str(recipe[2])
		result_ids.append(result_id)
		assert(game._seed_new_species_blocked(result_id))
		assert(game._register_species_discovery(result_id, true))
		assert(game._species_get_count(result_id) == 1)
		assert(bool(game.discovered.get(result_id, false)))
		assert(bool(game.greenhouse_available.get(result_id, false)))
		assert(not game._seed_new_species_blocked(result_id))
	assert(bool(game.unlocked_series.get("fusion_tier2", false)))
	var normal_pool_ids: Array[String] = []
	for entry in game._normal_seed_selection_pools().get("all_known", []):
		normal_pool_ids.append(str(entry.get("species_id", "")))
	var eligible_parent_ids: Array[String] = []
	for entry in game.fusion_system.eligible_parents(game.species_get_counts):
		eligible_parent_ids.append(str(entry.get("species_id", "")))
	for result_id in result_ids:
		assert(result_id in normal_pool_ids)
		assert(result_id not in eligible_parent_ids)
	game._save()
	for result_id in result_ids:
		game.discovered.erase(result_id)
		game.greenhouse_available.erase(result_id)
		game.unlocked_species.erase(result_id)
		game.species_get_counts.erase(result_id)
	game.unlocked_series.erase("fusion_tier2")
	game._load_save()
	await get_tree().process_frame
	for result_id in result_ids:
		assert(game._species_get_count(result_id) == 1)
		assert(bool(game.discovered.get(result_id, false)))
		assert(bool(game.greenhouse_available.get(result_id, false)))
		assert(not game._seed_new_species_blocked(result_id))
	assert(bool(game.unlocked_series.get("fusion_tier2", false)))

func _test_tier3_game_flow(game) -> void:
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
	var parent_a_id := "fus2_sunset_stone"
	var parent_b_id := "colorata"
	var result_id := "fus3_heart_of_magma"
	for parent_id in [parent_a_id, parent_b_id]:
		game.discovered[parent_id] = true
		game.greenhouse_available[parent_id] = true
		game.unlocked_species[parent_id] = true
		game.species_get_counts[parent_id] = 1
	game._apply_saved_unlocks()
	game.puku_points = 3
	game._open_fusion_lab()
	game._on_fusion_parent_selected(0, parent_a_id)
	game._on_fusion_parent_selected(1, parent_b_id)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(str(game.fusion_lab_ui.current_result.get("result_species_id", "")) == result_id)
	assert(game.fusion_lab_ui.result_name_label.text == "ハート・オブ・マグマ")
	assert(game.fusion_lab_ui.fusion_cost_label.text == "3ぷくコイン")
	assert(not game.fusion_lab_ui.fuse_button.disabled)
	game._perform_fusion(parent_a_id, parent_b_id)
	assert(game.fusion_in_progress and game.puku_points == 0)
	assert(game._species_get_count(result_id) == 1)
	await get_tree().create_timer(3.1).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not game.fusion_in_progress)
	assert(game.species_get_overlay.visible and game.species_get_overlay.name_label.text == "ハート・オブ・マグマ")
	assert(bool(game.discovered.get(result_id, false)) and bool(game.greenhouse_available.get(result_id, false)))
	assert(bool(game.unlocked_series.get("fusion_tier3", false)))
	game.species_get_overlay.busy = false
	game.species_get_overlay.close_overlay()
	await get_tree().create_timer(.22).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.fusion_lab_ui.visible)
	assert(str(game.fusion_lab_ui.current_result.get("result_species_id", "")) == result_id)
	assert(game.fusion_lab_ui.fuse_button.disabled)
	game._close_fusion_lab()
	game._save()
	game.discovered.erase(result_id)
	game.greenhouse_available.erase(result_id)
	game.species_get_counts.erase(result_id)
	game.unlocked_series.erase("fusion_tier3")
	game._load_save()
	assert(game._species_get_count(result_id) == 1)
	assert(bool(game.discovered.get(result_id, false)) and bool(game.greenhouse_available.get(result_id, false)))
	assert(bool(game.unlocked_series.get("fusion_tier3", false)))
