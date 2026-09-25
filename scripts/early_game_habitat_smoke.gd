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
	game._update_play_ui()
	assert(not game.puku_gauge_area.visible and not game.encyclopedia_icon_button.visible)

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
			if not str(key).begins_with("_pause_"):
				assert(not Localizer.text(locale, str(key)).is_empty())
	var awakening_text := ""
	for key in game.habitat_awakening_overlay.DIALOG_KEYS:
		if not str(key).begins_with("_pause_"):
			awakening_text += Localizer.text("ja", str(key))
	assert("思い出しているように見える" in awakening_text)
	assert("ありがとう" in awakening_text and "ごめんなさい" in awakening_text)
	assert("もう同じことはしない" in awakening_text and "返していきます" in awakening_text)
	assert("……何も起こらない。" not in awakening_text and "聞いてくれたのかな" not in awakening_text)
	assert(game.habitat_awakening_overlay.SPEAKER_KEYS.slice(0, 14) == ["story_speaker_armadillo", "story_speaker_panda", "story_speaker_armadillo", "story_speaker_panda", "", "story_speaker_panda", "story_speaker_armadillo", "story_speaker_girl", "story_speaker_girl", "story_speaker_armadillo", "story_speaker_girl", "story_speaker_panda", "", "story_speaker_girl"])
	for expected_page in range(4):
		assert(game.habitat_awakening_overlay.page_index == expected_page)
		assert(game.habitat_awakening_overlay.speaker_portrait.visible)
		assert(game.habitat_awakening_overlay.speaker_portrait.texture != null)
		assert(game.habitat_awakening_overlay.speaker_portrait.position.x < game.habitat_awakening_overlay.dialogue_label.position.x)
		game.habitat_awakening_overlay.advance()
		await get_tree().process_frame
	assert(game.habitat_awakening_overlay.page_index == 4 and game.habitat_awakening_overlay.transitioning)
	assert(not game.habitat_awakening_overlay.text_back.visible)
	while game.habitat_awakening_overlay.transitioning:
		await get_tree().create_timer(0.25).timeout
	assert(game.habitat_awakening_overlay.page_index == 5 and game.habitat_awakening_overlay.rain_active)
	assert(game.habitat_awakening_overlay.dialogue_label.text == Localizer.text("ja", "awakening_surprise"))
	assert(game.habitat_awakening_overlay.speaker_portrait.visible and game.habitat_awakening_overlay.speaker_portrait.texture != null)
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
	for species_id in ["colorata", "affinis", "shaviana"]:
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
	assert(game.seed_pod_story_overlay.visible and game.current_mode == "habitat")
	assert(game.scripted_dialog_kind.is_empty() and not bool(game.tutorial_steps.get("seed_pod_story_seen", false)))
	assert(game.seed_pod_story_overlay.DIALOG_KEYS.size() == 3)
	assert(game.seed_pod_story_overlay.SPEAKER_KEYS == ["story_speaker_panda", "story_speaker_girl", "story_speaker_armadillo"])
	assert(game.seed_pod_story_overlay.STORY_TEXTURE.get_width() == 960 and game.seed_pod_story_overlay.STORY_TEXTURE.get_height() == 1280)
	var seed_pod_story_image := game.seed_pod_story_overlay.get_node("StoryImage") as TextureRect
	assert(seed_pod_story_image != null)
	assert(seed_pod_story_image.stretch_mode == TextureRect.STRETCH_SCALE)
	print("SEED_POD_STORY_LAYOUT image_position=", seed_pod_story_image.position, " image_size=", seed_pod_story_image.size)
	assert(seed_pod_story_image.size.is_equal_approx(Vector2(487.5, 650.0)))
	assert(seed_pod_story_image.position.is_equal_approx(Vector2(44.25, 0.0)))
	for locale in Localizer.SUPPORTED_LANGUAGES:
		for key in game.seed_pod_story_overlay.DIALOG_KEYS:
			assert(not Localizer.text(locale, str(key)).is_empty())
	for expected_page in range(3):
		assert(game.seed_pod_story_overlay.page_index == expected_page)
		assert(game.seed_pod_story_overlay.story_text.text == Localizer.text("ja", game.seed_pod_story_overlay.DIALOG_KEYS[expected_page]))
		assert(game.seed_pod_story_overlay.speaker_portrait.visible and game.seed_pod_story_overlay.speaker_portrait.texture != null)
		assert(game.seed_pod_story_overlay.speaker_portrait.position.x < game.seed_pod_story_overlay.story_text.position.x)
		game.seed_pod_story_overlay.advance()
		if expected_page < 2:
			await get_tree().create_timer(0.25).timeout
	await get_tree().process_frame
	assert(not game.seed_pod_story_overlay.visible and bool(game.tutorial_steps.get("seed_pod_story_seen", false)))
	assert(game.mystery_items_acquired and game.seed_shop_open and game.normal_seed_bags == 4 and game.puku_points == 0)
	assert(game.current_mode == "greenhouse" and game.seed_pod_gauge_area.visible and game.puku_gauge_area.visible and game.encyclopedia_icon_button.visible)
	assert(game.tutorial_guide_overlay.visible and str(game.tutorial_guide_button.get_meta("target", "")) == "encyclopedia")
	game._complete_tutorial_guide()
	await get_tree().process_frame
	assert(game.encyclopedia_overlay.visible and game.current_encyclopedia_series_id == "base")
	for species_id in ["colorata", "affinis", "shaviana"]:assert(bool(game.discovered.get(species_id, false)))
	assert(game.scripted_dialog_kind == "mystery_catalog_tutorial" and game.scripted_dialog_pages.size() == 3)
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.mystery_catalog_tutorial_complete and game.encyclopedia_overlay.visible)
	game._close_encyclopedia()
	await get_tree().process_frame
	assert(game.scripted_dialog_kind == "initial_seed_stock")
	game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.initial_seed_stock_notice_complete and game.tutorial_guide_overlay.visible and str(game.tutorial_guide_button.get_meta("target", "")) == "play_open_normal")
	game._hide_first_play_tutorial_overlay();game.normal_play_tutorial_complete=true;game._save()
	game._start_panda_beacon_unlock_event()
	assert(game.scripted_dialog_kind == "panda_beacon_unlock")
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.panda_beacon_unlocked and game.panda_beacon_count == 1)
	assert(game.puku_gauge_intro_complete and game._tutorial_fully_complete())

	# A legacy/direct modern discovery remains usable for save compatibility,
	# but it does not run the old "creative era" explanation prematurely. New
	# creative discoveries are still blocked at every normal acquisition route.
	assert(game._register_species_discovery("jelly_grape", true))
	assert(bool(game.habitat_returned_species.get("jelly_grape", false)))
	assert(not game.pending_special_series_explanation and not game.special_series_explanation_seen)
	assert("jelly_grape" in game._habitat_population_candidate_ids())

	# Once awake, the shared offline/spawn engine resumes normally.
	var population_before: int = game.habitat_wild_plants.size()
	game.habitat_wild_next_spawn_unix = now_unix - 1.0
	game._ensure_habitat_wild_state(now_unix, false)
	assert(game.habitat_wild_plants.size() >= population_before)

	print("EARLY_GAME_HABITAT_SMOKE_OK empty=true dormant=true awakening=rain+ghosts+promise sprouts=3 items=pod+catalog stock=4x12 catalog_tutorial=true shop=true beacon=true return_loop=true")
	get_tree().quit()

func _prepare_trio_complete(game: Node) -> void:
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.trio_originals_confirmed = true
	game.encyclopedia_unlocked = false
	game.habitat_unlocked = true
	game.unlocked_series = {"base": true}
	for species_id in ["colorata", "affinis", "shaviana"]:
		game._register_species_discovery(species_id, true)
	game._update_main_story_progress(false)
