extends Node

const StoryProgressionClass = preload("res://scripts/story_progression.gd")

const RETIRED_IDS := [
	"glow_colorata",
	"metal_laui",
	"seaglass_veria",
	"amber_agavoides",
	"yumefuwa_jelly",
	"peach_jelly_succulent",
]
const PROTECTED_IDS := ["transparent_succulent", "golden_laui", "golden_kannte"]
const RETIRED_IMAGE_PATHS := [
	"assets/plants/mystery-glow-colorata.png",
	"assets/plants/habitat/mystery-glow-colorata.png",
	"assets/plants/mystery-metal-laui.png",
	"assets/plants/habitat/mystery-metal-laui.png",
	"assets/plants/mystery-seaglass-veria.png",
	"assets/plants/habitat/mystery-seaglass-veria.png",
	"assets/plants/mystery-amber-agavoides.png",
	"assets/plants/habitat/mystery-amber-agavoides.png",
	"assets/plants/mystery-yumefuwa-jelly.png",
	"assets/plants/habitat/mystery-yumefuwa-jelly.png",
	"assets/plants/mystery-peach-jelly.png",
	"assets/plants/habitat/mystery-peach-jelly.png",
]


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	_test_catalog_and_runtime_retirement(game)
	_test_secret_gacha_tombstone()
	_test_legacy_save_migration(game)
	_test_export_exclusions_and_source_retention()
	game._reset_progression_state()
	print("RETIRED_FEATURES_SMOKE_OK secret_runtime=absent secret_tombstone=progression retired_species=6 legacy_state=sanitized arrangements=preserved pots=preserved protected=3 forest=active exports=web+ios")
	get_tree().quit()


func _test_catalog_and_runtime_retirement(game: Node) -> void:
	assert(game.catalog_species.size() == 232)
	for species_id in RETIRED_IDS:
		assert(game._catalog_entry(species_id).is_empty())
		assert(species_id not in game._collection_complete_species_ids())
	for species_id in PROTECTED_IDS:
		assert(not game._catalog_entry(species_id).is_empty())
	assert(not game.has_method("_mystery_route_candidates"))
	assert(not game.has_method("_assign_mystery_route"))
	assert(not game.has_method("_grant_mystery_route_reward"))
	assert(not game.has_method("_start_mystery_route_dialog"))
	assert(game.find_child("SecretGachaButton", true, false) == null)
	assert(game.find_child("SecretGachaUI", true, false) == null)
	assert(game.forest_gacha_system != null)
	assert(game.forest_gacha_ui != null)
	assert(FileAccess.file_exists("res://assets/forest_gacha/temporary-dial.png"))

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(main_source.find("SecretGachaSystemClass") == -1)
	assert(main_source.find("SecretGachaUIClass") == -1)
	assert(main_source.find("--secret-gacha-preview") == -1)
	assert(main_source.find("_secret_gacha_preview_requested") == -1)
	assert(main_source.find("special_route_only") == -1)
	assert(main_source.find("func _mystery_route_") == -1)
	assert(not FileAccess.file_exists("res://scripts/secret_gacha_system.gd"))
	assert(not FileAccess.file_exists("res://scripts/secret_gacha_ui.gd"))
	assert(not FileAccess.file_exists("res://data/secret-gacha.json"))


func _test_secret_gacha_tombstone() -> void:
	var legacy_state := {
		"version": 8,
		"secret_gacha_unlocked": true,
		"secret_gacha_install_seen": true,
		"pending_story_events": [
			StoryProgressionClass.RETIRED_EVENT_SECRET_GACHA_INSTALL,
			StoryProgressionClass.EVENT_FANTASY_FIRST,
		],
	}
	var normalized := StoryProgressionClass.normalize_runtime_state(legacy_state)
	assert(bool(normalized.get("exploitation_started", false)))
	assert(bool(normalized.get("act3_battle_intro_seen", false)))
	assert(bool(normalized.get("exploitation_midpoint_seen", false)))
	assert(not normalized.has("secret_gacha_unlocked"))
	assert(not normalized.has("secret_gacha_install_seen"))
	assert(StoryProgressionClass.RETIRED_EVENT_SECRET_GACHA_INSTALL not in normalized.get("pending_story_events", []))
	assert(StoryProgressionClass.EVENT_FANTASY_FIRST in normalized.get("pending_story_events", []))
	var outer_evidence := StoryProgressionClass.normalize_runtime_state({}, {"secret_gacha_evidence": true})
	assert(bool(outer_evidence.get("exploitation_started", false)))
	assert(bool(outer_evidence.get("exploitation_midpoint_seen", false)))


func _test_legacy_save_migration(game: Node) -> void:
	game._reset_progression_state()
	var save_path: String = game._active_save_path()
	var legacy_payload = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	assert(legacy_payload is Dictionary)
	legacy_payload["retired_content_version"] = 0
	legacy_payload["puku_balance_units"] = 777
	legacy_payload["secret_gacha_active"] = true
	legacy_payload["secret_gacha_draws_remaining"] = 2
	legacy_payload["secret_gacha_last_roll_play_count"] = 12
	legacy_payload["mystery_route_assignments"] = {"research_25": RETIRED_IDS[0]}
	legacy_payload["mystery_route_completed"] = {"research_25": true}
	legacy_payload["mystery_route_dialog_seen"] = {"research_25": true}
	legacy_payload["story_progression_state"] = {
		"version": 8,
		"secret_gacha_install_seen": true,
		"pending_story_events": [StoryProgressionClass.RETIRED_EVENT_SECRET_GACHA_INSTALL],
	}
	for dictionary_key in ["bests", "discovered", "species_get_counts", "greenhouse_available", "unlocked_species", "forest_gacha_encountered", "hidden_species_acquired", "habitat_returned_species"]:
		var legacy_dictionary: Dictionary = legacy_payload.get(dictionary_key, {})
		legacy_dictionary[RETIRED_IDS[0]] = 91.0 if dictionary_key == "bests" else true
		legacy_dictionary["colorata"] = 42.0 if dictionary_key == "bests" else true
		legacy_payload[dictionary_key] = legacy_dictionary
	legacy_payload["catalog_cover_species"] = {"neon": RETIRED_IDS[0], "base": "colorata"}
	legacy_payload["pending_habitat_species"] = [RETIRED_IDS[0], "colorata"]
	legacy_payload["pending_round_new_species_ids"] = [RETIRED_IDS[1], "lutea"]
	legacy_payload["first_tutorial_species_id"] = RETIRED_IDS[2]
	legacy_payload["habitat_tutorial_species_id"] = RETIRED_IDS[3]
	legacy_payload["armadillo_gift_species_id"] = RETIRED_IDS[4]
	legacy_payload["owned_pots"] = {"shallow_terracotta": 3}
	legacy_payload["saved_arrangements"] = [
		{
			"arrangement_id": "legacy_mixed",
			"name": "mixed",
			"pot_id": "shallow_terracotta",
			"plants": [_plant(RETIRED_IDS[0], 100.0), _plant("colorata", 200.0)],
		},
		{
			"arrangement_id": "legacy_retired_only",
			"name": "empty-safe",
			"pot_id": "shallow_terracotta",
			"plants": [_plant(RETIRED_IDS[5], 300.0)],
		},
	]
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(legacy_payload))
	file.close()

	game._load_save()
	assert(game.retired_content_migration_dirty)
	assert(game.puku_balance_units == 777)
	for species_id in RETIRED_IDS:
		for state_dictionary in [game.bests, game.discovered, game.species_get_counts, game.greenhouse_available, game.unlocked_species, game.forest_gacha_encountered, game.hidden_species_acquired, game.habitat_returned_species]:
			assert(not state_dictionary.has(species_id))
	assert(bool(game.discovered.get("colorata", false)))
	assert(float(game.bests.get("colorata", 0.0)) == 42.0)
	assert(str(game.catalog_cover_species.get("base", "")) == "colorata")
	assert(not game.catalog_cover_species.has("neon"))
	assert(game.pending_habitat_species == ["colorata"])
	assert(game.pending_round_new_species_ids == ["lutea"])
	assert(game.first_tutorial_species_id.is_empty())
	assert(game.habitat_tutorial_species_id.is_empty())
	assert(game.armadillo_gift_species_id.is_empty())
	assert(game.saved_arrangements.size() == 2)
	assert(str(game.saved_arrangements[0].get("pot_id", "")) == "shallow_terracotta")
	assert(game.saved_arrangements[0].get("plants", []).size() == 1)
	assert(str(game.saved_arrangements[0].get("plants", [])[0].get("species_id", "")) == "colorata")
	assert(game.saved_arrangements[1].get("plants", []).is_empty())
	assert(game._pot_usage_count("shallow_terracotta") == 2)
	assert(game._pot_available_count("shallow_terracotta") == 1)
	assert(bool(game.story_progression_state.get("exploitation_started", false)))
	assert(bool(game.story_progression_state.get("exploitation_midpoint_seen", false)))
	assert(StoryProgressionClass.RETIRED_EVENT_SECRET_GACHA_INSTALL not in game.story_progression_state.get("pending_story_events", []))

	game._save()
	var migrated_payload = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	assert(migrated_payload is Dictionary)
	assert(int(migrated_payload.get("retired_content_version", 0)) == game.RETIRED_CONTENT_VERSION)
	for retired_key in ["secret_gacha_active", "secret_gacha_draws_remaining", "secret_gacha_last_roll_play_count", "mystery_route_assignments", "mystery_route_completed", "mystery_route_dialog_seen"]:
		assert(not migrated_payload.has(retired_key))
	var migrated_story: Dictionary = migrated_payload.get("story_progression_state", {})
	assert(not migrated_story.has("secret_gacha_unlocked"))
	assert(not migrated_story.has("secret_gacha_install_seen"))
	assert(StoryProgressionClass.RETIRED_EVENT_SECRET_GACHA_INSTALL not in migrated_story.get("pending_story_events", []))


func _test_export_exclusions_and_source_retention() -> void:
	var export_source := FileAccess.get_file_as_string("res://export_presets.cfg")
	assert(export_source.count("assets/secret_gacha/*") == 2)
	for asset_path in RETIRED_IMAGE_PATHS:
		assert(FileAccess.file_exists("res://" + asset_path))
		assert(export_source.count(asset_path) == 2)
	var runtime_sources := "\n".join([
		FileAccess.get_file_as_string("res://scripts/main.gd"),
		FileAccess.get_file_as_string("res://scripts/succulent.gd"),
		FileAccess.get_file_as_string("res://data/species-v2.json"),
		FileAccess.get_file_as_string("res://data/series.json"),
	])
	for asset_path in RETIRED_IMAGE_PATHS:
		assert(runtime_sources.find(asset_path) == -1)
	assert(runtime_sources.find("assets/secret_gacha/") == -1)


func _plant(species_id: String, x: float) -> Dictionary:
	return {"species_id": species_id, "x": x, "y": 250.0, "scale": 1.0, "rotation": 0.0, "z_index": 0}
