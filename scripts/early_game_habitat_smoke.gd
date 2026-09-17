extends Node

const Localizer = preload("res://scripts/game_localizer.gd")

func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game._reset_progression_state()
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	_prepare_trio_complete(game)

	# Before awakening there is no population, no offline spawning and no rain.
	game.current_mode = "habitat"
	game._build_habitat_items(true)
	assert(game.habitat_wild_plants.is_empty() and game.habitat_pickups.is_empty())
	var future := Time.get_unix_time_from_system() + 86400.0 * 30.0
	var dormant_result: Dictionary = game._ensure_habitat_wild_state(future, false)
	assert(game.habitat_wild_plants.is_empty() and not bool(dormant_result.get("changed", false)))
	game.rain_draws_unlocked = true
	game.rain_bag_count = 99
	for attempt in range(20):
		game._roll_rain_event()
	assert(not game.rain_event_pending)

	# Entering the historical site starts the one-tap story on an empty habitat.
	game._start_habitat_awakening_event()
	assert(game.habitat_arrival_started and not game.habitat_awakened)
	assert(game.habitat_awakening_overlay.visible and game.habitat_wild_plants.is_empty())
	assert(game.main_story_stage == game.StoryProgressionClass.STAGE_AWAKEN_HABITAT)
	for locale in Localizer.SUPPORTED_LANGUAGES:
		for key in game.habitat_awakening_overlay.DIALOG_KEYS:
			assert(not Localizer.text(locale, str(key)).is_empty())
	var awakening_text := ""
	for key in game.habitat_awakening_overlay.DIALOG_KEYS:
		awakening_text += Localizer.text("ja", str(key))
	assert("思い出しているように見える" in awakening_text)
	assert("ありがとう" in awakening_text and "ごめんなさい" in awakening_text)
	assert("もう同じことはしない" in awakening_text and "返していきます" in awakening_text)
	while game.habitat_awakening_overlay.visible:
		if game.habitat_awakening_overlay.transitioning:
			await get_tree().create_timer(0.55).timeout
		else:
			game.habitat_awakening_overlay.advance()
			await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	assert(game.habitat_awakened and game.habitat_awakening_event_complete)
	assert(game.habitat_wild_plants.size() == 3)
	assert(game.habitat_pickups.filter(func(item): return str(item.get("kind", "")) == "wild_plant").size() == 3)
	for species_id in ["colorata", "lutea", "shaviana"]:
		assert(bool(game.habitat_returned_species.get(species_id, false)))
	assert(game.scripted_dialog_kind == "first_habitat_intro")
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
	assert(game.habitat_tutorial_started)

	# The first awakened sprout is nearly ready, but it still uses the real
	# habitat growth/30cm/jelly logic.
	var tutorial: Dictionary = game.HabitatWildSystemClass.tutorial_plant(game.habitat_wild_plants)
	assert(not tutorial.is_empty() and float(tutorial.get("diameter_cm", 0.0)) < 30.1)
	assert(bool(tutorial.get("jelly_immune", false)))
	var tutorial_id := str(tutorial.get("individual_id", ""))
	var now_unix := Time.get_unix_time_from_system()
	tutorial["last_updated_unix"] = now_unix - 120.0
	game._ensure_habitat_wild_state(now_unix, false)
	game._build_habitat_items(true)
	var tutorial_item: Dictionary = game._habitat_wild_item_by_id(tutorial_id)
	assert(not tutorial_item.is_empty() and game.HabitatWildSystemClass.can_harvest(tutorial))
	game._collect_habitat_wild_plant(tutorial_item)
	assert(game.habitat_tutorial_complete)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.species_get_active_context == "habitat_tutorial")
	game.species_get_overlay.busy = false
	game.species_get_overlay.close_overlay()
	await get_tree().create_timer(0.35).timeout
	assert(game.scripted_dialog_kind == "seed_origin")
	var seed_origin_text := ""
	for page in game.scripted_dialog_pages:
		seed_origin_text += str(page.get("text", ""))
	assert("原生地" in seed_origin_text and "タネ" in seed_origin_text and "パンダのたねや" in seed_origin_text)
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.seed_shop_open and game.normal_seed_bags == 3 and game.puku_points == 10)
	assert(game.scripted_dialog_kind == "panda_beacon_unlock")
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.panda_beacon_unlocked and game.panda_beacon_count == 1)
	assert(game.scripted_dialog_kind == "puku_gauge_first_gift")
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
	assert(game.puku_gauge_intro_complete and game._tutorial_fully_complete())
	game._close_shop()

	# Every first discovery is returned automatically. The first modern form
	# queues one explanation and does not masquerade as a historical original.
	assert(game._register_species_discovery("jelly_grape", true))
	assert(bool(game.habitat_returned_species.get("jelly_grape", false)))
	assert(game.pending_special_series_explanation and not game.special_series_explanation_seen)
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind == "special_origin")
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
	assert(game.special_series_explanation_seen and not game.pending_special_series_explanation)

	# Once awake, the shared offline/spawn engine resumes normally.
	var population_before: int = game.habitat_wild_plants.size()
	game.habitat_wild_next_spawn_unix = now_unix - 1.0
	game._ensure_habitat_wild_state(now_unix, false)
	assert(game.habitat_wild_plants.size() >= population_before)

	print("EARLY_GAME_HABITAT_SMOKE_OK empty=true dormant=true awakening=rain+ghosts+promise sprouts=3 shop=true beacon=true return_loop=true")
	get_tree().quit()

func _prepare_trio_complete(game: Node) -> void:
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.trio_originals_confirmed = true
	game.encyclopedia_unlocked = true
	game.habitat_unlocked = true
	game.unlocked_series = {"base": true}
	for species_id in ["colorata", "lutea", "shaviana"]:
		game._register_species_discovery(species_id, true)
	game._update_main_story_progress(false)
