class_name FusionSystem
extends RefCounted

const RECIPE_PATH := "res://data/fusion-recipes.json"
const FUSION_SERIES_BY_CATALOG_SERIES := {
	"gummy": "gummy",
	"metal": "metal",
	"sweets": "sweets",
	"glow": "glow",
	"jewel": "jewel",
	"jurejure": "jure",
	"stone": "stone",
	"sea": "sea",
	"yumekawa": "yumekawa",
	"forest_amber": "forest_amber",
}

var species_by_id: Dictionary = {}
var basic_recipes_by_pair: Dictionary = {}
var special_recipes_by_pair: Dictionary = {}

static func default_fusion_series_for_catalog_series(series_id: String) -> String:
	return str(FUSION_SERIES_BY_CATALOG_SERIES.get(series_id, ""))

static func normalized_pair(first: String, second: String) -> String:
	return "%s|%s" % [first, second] if first <= second else "%s|%s" % [second, first]

func configure(species_catalog: Array, recipe_config: Dictionary = {}) -> void:
	species_by_id.clear()
	for raw_entry in species_catalog:
		if raw_entry is Dictionary:
			var species_id := str(raw_entry.get("species_id", ""))
			if not species_id.is_empty():
				species_by_id[species_id] = raw_entry
	var config := recipe_config
	if config.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(RECIPE_PATH))
		if parsed is Dictionary:
			config = parsed
	_load_recipes(config)

func _load_recipes(config: Dictionary) -> void:
	basic_recipes_by_pair.clear()
	special_recipes_by_pair.clear()
	for raw_recipe in config.get("basic_recipes", []):
		if raw_recipe is Dictionary:
			_register_recipe(raw_recipe, false)
	for raw_recipe in config.get("special_recipes", []):
		if raw_recipe is Dictionary:
			_register_recipe(raw_recipe, true)

func _register_recipe(recipe: Dictionary, is_special: bool) -> void:
	var parents: Array = recipe.get("parent_species_ids" if is_special else "parent_series", [])
	if parents.size() != 2:
		return
	var first := str(parents[0])
	var second := str(parents[1])
	var result_species_id := str(recipe.get("result_species_id", ""))
	if first.is_empty() or second.is_empty() or result_species_id.is_empty():
		return
	var stored := recipe.duplicate(true)
	stored["source"] = "special" if is_special else "basic"
	var target := special_recipes_by_pair if is_special else basic_recipes_by_pair
	target[normalized_pair(first, second)] = stored

func set_special_recipes(recipes: Array) -> void:
	special_recipes_by_pair.clear()
	for raw_recipe in recipes:
		if raw_recipe is Dictionary:
			_register_recipe(raw_recipe, true)

func fusion_series_for_entry(entry: Dictionary) -> String:
	# Higher-tier fusion species only participate through species-id recipes.
	# Their display family is intentionally stored separately and must never
	# route them into the 55 basic series recipes.
	if int(entry.get("fusion_tier", 0)) > 0:
		return ""
	var explicit := str(entry.get("fusion_series", ""))
	if not explicit.is_empty():
		return explicit
	return default_fusion_series_for_catalog_series(str(entry.get("series_id", "")))

func fusion_series_for_species(species_id: String) -> String:
	return fusion_series_for_entry(species_by_id.get(species_id, {}))

func is_original_entry(entry: Dictionary) -> bool:
	return str(entry.get("series_id", "")) == "base" and bool(entry.get("main_story_original", false))

func is_original_species(species_id: String) -> bool:
	return is_original_entry(species_by_id.get(species_id, {}))

func is_eligible_parent_species(species_id: String) -> bool:
	var entry: Dictionary = species_by_id.get(species_id, {})
	if entry.is_empty():
		return false
	return bool(entry.get("fusion_parent_enabled", false)) or is_original_entry(entry) or not fusion_series_for_entry(entry).is_empty()

func resolve(parent_a_id: String, parent_b_id: String) -> Dictionary:
	if parent_a_id.is_empty() or parent_b_id.is_empty():
		return {}
	var special_key := normalized_pair(parent_a_id, parent_b_id)
	if special_recipes_by_pair.has(special_key):
		return _resolution(special_recipes_by_pair[special_key])
	var parent_a: Dictionary = species_by_id.get(parent_a_id, {})
	var parent_b: Dictionary = species_by_id.get(parent_b_id, {})
	if parent_a.is_empty() or parent_b.is_empty():
		return {}
	# Species-specific recipes always win. Otherwise an original species returns
	# to itself; when both parents are originals, the left-side parent wins.
	if is_original_entry(parent_a):
		return _resolution({
			"source": "original_fallback",
			"parent_species_ids": [parent_a_id, parent_b_id],
			"result_species_id": parent_a_id,
		})
	if is_original_entry(parent_b):
		return _resolution({
			"source": "original_fallback",
			"parent_species_ids": [parent_a_id, parent_b_id],
			"result_species_id": parent_b_id,
		})
	var series_a := fusion_series_for_entry(parent_a)
	var series_b := fusion_series_for_entry(parent_b)
	if series_a.is_empty() or series_b.is_empty():
		return {}
	var recipe_key := normalized_pair(series_a, series_b)
	if not basic_recipes_by_pair.has(recipe_key):
		return {}
	return _resolution(basic_recipes_by_pair[recipe_key])

func _resolution(recipe_value: Variant) -> Dictionary:
	if not recipe_value is Dictionary:
		return {}
	var recipe: Dictionary = recipe_value
	var result_species_id := str(recipe.get("result_species_id", ""))
	var result_entry: Dictionary = species_by_id.get(result_species_id, {})
	if result_entry.is_empty():
		return {}
	return {
		"source": str(recipe.get("source", "basic")),
		"recipe": recipe.duplicate(true),
		"result_species_id": result_species_id,
		"result_entry": result_entry,
		"fusion_cost_puku": maxi(1, int(result_entry.get("fusion_cost_puku", 1))),
	}

func eligible_parents(species_get_counts: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for species_id_value in species_by_id:
		var species_id := str(species_id_value)
		if int(species_get_counts.get(species_id, 0)) <= 0:
			continue
		var entry: Dictionary = species_by_id[species_id]
		if not is_eligible_parent_species(species_id):
			continue
		result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("species_id", "")) < str(b.get("species_id", ""))
	)
	return result

func parents_are_owned(parent_a_id: String, parent_b_id: String, species_get_counts: Dictionary) -> bool:
	return int(species_get_counts.get(parent_a_id, 0)) > 0 and int(species_get_counts.get(parent_b_id, 0)) > 0

func hybrid_seed_is_available(entry: Dictionary, species_get_counts: Dictionary) -> bool:
	if not bool(entry.get("fusion_only_until_discovered", false)):
		return true
	return int(species_get_counts.get(str(entry.get("species_id", "")), 0)) > 0
