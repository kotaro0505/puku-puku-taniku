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
	assert(game.main_story_stage == game.StoryProgressionClass.ACT_1)
	assert(game.habitat_lookaround_active and game.habitat_lookaround_context == "arrival")
	var arrival_start_yaw: float = game.view_yaw
	game.habitat_awakening_overlay.advance()
	assert(game.habitat_awakening_overlay.page_index == 0)
	game._update_habitat_view_follow(game.HABITAT_LOOKAROUND_DURATION_SECONDS * 0.5)
	assert(game.habitat_lookaround_active and absf(game.view_yaw - arrival_start_yaw) > 170.0)
	game._update_habitat_view_follow(game.HABITAT_LOOKAROUND_DURATION_SECONDS)
	await get_tree().process_frame
	assert(not game.habitat_lookaround_active and is_equal_approx(game.view_yaw, arrival_start_yaw))
	assert(game.habitat_awakening_overlay.page_index == 1)
	var ghost_centers: Array[Vector2] = []
	for ghost in game.habitat_awakening_overlay.ghosts:
		ghost_centers.append(ghost.position + ghost.size * 0.5)
	assert(ghost_centers[0].x < 0.2 * 576.0 and ghost_centers[2].x > 0.4 * 576.0 and ghost_centers[2].x < 0.6 * 576.0 and ghost_centers[4].x > 0.8 * 576.0)
	assert(not is_equal_approx(ghost_centers[0].y, ghost_centers[1].y) and not is_equal_approx(ghost_centers[2].y, ghost_centers[3].y))
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
	assert(game.habitat_awakening_overlay.SPEAKER_KEYS == ["story_speaker_armadillo", "story_speaker_panda", "story_speaker_armadillo", "story_speaker_panda", "", "story_speaker_panda", "story_speaker_armadillo", "story_speaker_girl", "story_speaker_girl", "story_speaker_armadillo", "story_speaker_girl", "story_speaker_girl", "story_speaker_panda", "", "story_speaker_girl", "story_speaker_panda"])
	assert(Localizer.text("ja", "awakening_overharvest") == "乱獲や密猟も、絶滅の大きな原因だったみたいだ……。")
	assert(Localizer.text("ja", "awakening_promise_2") == "これから新しく見つけた品種は、\nここにお返していきます。")
	assert(Localizer.text("ja", "awakening_promise_3") == "だから、また沢山の可愛い多肉植物を\n私たちにも見せてください！")
	for expected_page in range(1, 4):
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
	assert(not game.habitat_lookaround_active and game.habitat_lookaround_context != "sprouts")
	assert(game.habitat_awakening_overlay.sprout_layer.get_child_count() == 3)
	for sprout_group in game.habitat_awakening_overlay.sprout_layer.get_children():
		var glow := sprout_group.get_node("GreenGlow") as Control
		var story_plant := sprout_group.get_node("Plant") as Control
		assert(glow.modulate.a > 0.95 and story_plant.modulate.a > 0.95)
		assert(story_plant.scale.is_equal_approx(Vector2(.54, .54)))
		assert(is_equal_approx(story_plant.modulate.r, 1.0) and is_equal_approx(story_plant.modulate.g, 1.0) and is_equal_approx(story_plant.modulate.b, 1.0))
	assert(Localizer.text("ja", "awakening_sprout_panda") == "あ、芽が出てる！")
	assert(game.habitat_wild_plants.size() == 3)
	assert(game.habitat_pickups.filter(func(item): return str(item.get("kind", "")) == "wild_plant").size() == 3)
	var awakening_ids: Array[String] = []
	var awakening_xs: Array[float] = []
	for plant in game.habitat_wild_plants:
		awakening_ids.append(str(plant.get("species_id", "")))
		awakening_xs.append(float(plant.get("panorama_x", 0.0)))
	awakening_ids.sort()
	awakening_xs.sort()
	assert(awakening_ids == ["affinis", "colorata", "shaviana"])
	assert(awakening_xs[0] < 300.0 and awakening_xs[1] > 500.0 and awakening_xs[1] < 900.0 and awakening_xs[2] > 1000.0)
	for species_id in ["colorata", "affinis", "shaviana"]:
		assert(bool(game.habitat_returned_species.get(species_id, false)))
	assert(game.scripted_dialog_kind.is_empty() and game.habitat_tutorial_started)

	# Looking around the first sprouts is the whole habitat introduction. Plants
	# are observed, never harvested, and the seed-pod story follows directly.
	assert(game.habitat_tutorial_complete)
	for plant in game.habitat_wild_plants:
		assert(not bool(plant.get("tutorial", false)) and not bool(plant.get("jelly_immune", false)))
	var now_unix := Time.get_unix_time_from_system()
	var first_plant_id := str(game.habitat_wild_plants[0].get("individual_id", ""))
	var first_item: Dictionary = game._habitat_wild_item_by_id(first_plant_id)
	var first_count := int(game.species_get_counts.get(str(game.habitat_wild_plants[0].get("species_id", "")), 0))
	game._collect_habitat_wild_plant(first_item)
	assert(not game._habitat_wild_plant_by_id(first_plant_id).is_empty())
	assert(int(game.species_get_counts.get(str(game.habitat_wild_plants[0].get("species_id", "")), 0)) == first_count)
	assert(game.habitat_plant_panel.visible)
	game.habitat_plant_panel.close()
	for frame in range(4):
		await get_tree().process_frame
	assert(game.seed_pod_story_overlay.visible and game.current_mode == "habitat")
	assert(game.scripted_dialog_kind.is_empty() and not bool(game.tutorial_steps.get("seed_pod_story_seen", false)))
	assert(game.seed_pod_story_overlay.DIALOG_KEYS.size() == 3)
	assert(game.seed_pod_story_overlay.SPEAKER_KEYS == ["story_speaker_panda", "story_speaker_girl", "story_speaker_armadillo"])
	assert(game.seed_pod_story_overlay.STORY_TEXTURE.get_width() == 960 and game.seed_pod_story_overlay.STORY_TEXTURE.get_height() == 1280)
	var seed_pod_story_image := game.seed_pod_story_overlay.get_node("StoryImage") as TextureRect
	assert(seed_pod_story_image != null)
	assert(seed_pod_story_image.stretch_mode == TextureRect.STRETCH_SCALE)
	print("SEED_POD_STORY_LAYOUT image_position=", seed_pod_story_image.position, " image_size=", seed_pod_story_image.size)
	assert(seed_pod_story_image.size.is_equal_approx(Vector2(558.0, 744.0)))
	assert(seed_pod_story_image.position.is_equal_approx(Vector2(9.0, 0.0)))
	assert(game.seed_pod_story_overlay.modulate.a < 1.0 and game.seed_pod_story_overlay.transitioning)
	await get_tree().create_timer(.58).timeout
	assert(is_equal_approx(game.seed_pod_story_overlay.modulate.a, 1.0) and not game.seed_pod_story_overlay.transitioning)
	assert(is_zero_approx(seed_pod_story_image.modulate.a))
	for locale in Localizer.SUPPORTED_LANGUAGES:
		for key in game.seed_pod_story_overlay.DIALOG_KEYS:
			assert(not Localizer.text(locale, str(key)).is_empty())
	assert(game.seed_pod_story_overlay.page_index == 0)
	assert(game.seed_pod_story_overlay.story_text.text == Localizer.text("ja", "seed_pod_story_1"))
	game.seed_pod_story_overlay.advance()
	assert(game.seed_pod_story_overlay.transitioning)
	await get_tree().create_timer(1.65).timeout
	assert(is_equal_approx(seed_pod_story_image.modulate.a, 1.0))
	for expected_page in range(1, 3):
		assert(game.seed_pod_story_overlay.page_index == expected_page)
		assert(game.seed_pod_story_overlay.story_text.text == Localizer.text("ja", game.seed_pod_story_overlay.DIALOG_KEYS[expected_page]))
		assert(game.seed_pod_story_overlay.speaker_portrait.visible and game.seed_pod_story_overlay.speaker_portrait.texture != null)
		assert(game.seed_pod_story_overlay.speaker_portrait.position.x < game.seed_pod_story_overlay.story_text.position.x)
		game.seed_pod_story_overlay.advance()
		if expected_page < 2:
			await get_tree().create_timer(0.25).timeout
	assert(game.seed_pod_story_overlay.visible and game.seed_pod_story_overlay.transitioning)
	await get_tree().create_timer(.50).timeout
	assert(not game.seed_pod_story_overlay.visible and game.current_mode == "greenhouse")
	assert(game.scene_transition_fade.visible and game.scripted_dialog_kind.is_empty())
	await get_tree().create_timer(.82).timeout
	assert(not game.seed_pod_story_overlay.visible and bool(game.tutorial_steps.get("seed_pod_story_seen", false)))
	assert(game.mystery_items_acquired and game.seed_shop_open and game.normal_seed_bags == 0 and game.puku_points == 0)
	assert(game.current_mode == "greenhouse" and game.seed_pod_gauge_area.visible and game.puku_gauge_area.visible and game.encyclopedia_icon_button.visible)
	assert(not game.scene_transition_fade.visible and game.scripted_dialog_kind == "habitat_return")
	assert(game.scripted_dialog_pages.size() == 5)
	var return_keys := ["habitat_return_panda", "habitat_return_girl_1", "habitat_return_armadillo_1", "habitat_return_girl_2", "habitat_return_armadillo_2"]
	for expected_page in range(return_keys.size()):
		assert(game.intro_dialogue_label.text == Localizer.text("ja", return_keys[expected_page]))
		game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.tutorial_guide_overlay.visible and str(game.tutorial_guide_button.get_meta("target", "")) == "encyclopedia")
	assert(game.tutorial_guide_shade.color.a >= .7 and game.tutorial_highlight_tween != null)
	assert(game.tutorial_guide_overlay.find_child("*Finger*", true, false) == null)
	game._complete_tutorial_guide()
	await get_tree().process_frame
	assert(game.encyclopedia_overlay.visible and game.current_encyclopedia_series_id == "base")
	for species_id in ["colorata", "affinis", "shaviana"]:assert(bool(game.discovered.get(species_id, false)))
	assert(game.scripted_dialog_kind == "mystery_catalog_tutorial" and game.scripted_dialog_pages.size() == 4)
	assert(str(game.scripted_dialog_pages.back().get("text", "")) == Localizer.text("ja", "mystery_catalog_tutorial_4"))
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.mystery_catalog_tutorial_complete and game.encyclopedia_overlay.visible)
	game._close_encyclopedia()
	await get_tree().process_frame
	assert(game.scripted_dialog_kind == "initial_seed_stock")
	assert(game.normal_seed_bags == 0 and game.scripted_dialog_pages.size() == 3)
	assert(game.intro_dialogue_label.text == Localizer.text("ja", "initial_seed_stock_girl"))
	game._advance_scripted_dialog()
	assert(game.intro_dialogue_label.text == Localizer.text("ja", "initial_seed_stock_armadillo"))
	game._advance_scripted_dialog()
	assert(game.intro_dialogue_label.text == Localizer.text("ja", "initial_seed_stock_received"))
	assert(game.normal_seed_bags == 1 and game.first_habitat_gift_claimed)
	game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.initial_seed_stock_notice_complete and game.tutorial_guide_overlay.visible and str(game.tutorial_guide_button.get_meta("target", "")) == "play_open_normal")
	game._hide_first_play_tutorial_overlay();game.normal_play_tutorial_complete=true;game._save()
	assert(not game.panda_beacon_unlocked and game.panda_beacon_count == 0)
	assert(game.puku_gauge_intro_complete and game._tutorial_fully_complete())

	# A legitimate greenhouse/event GET becomes settled. Unknown species never
	# enter the natural population merely because the habitat exists.
	assert(game._register_species_discovery("lutea", true))
	assert(bool(game.habitat_returned_species.get("lutea", false)))
	assert("lutea" in game._habitat_population_candidate_ids())
	assert("jelly_grape" not in game._habitat_population_candidate_ids())

	# Once awake, the shared offline/spawn engine resumes normally.
	var population_before: int = game.habitat_wild_plants.size()
	game.habitat_wild_next_spawn_unix = now_unix - 1.0
	game._ensure_habitat_wild_state(now_unix, false)
	assert(game.habitat_wild_plants.size() >= population_before)

	print("EARLY_GAME_HABITAT_SMOKE_OK empty=true dormant=true awakening=rain+ghosts+three_green_sprouts promise=two_pages observation=true items=pod+catalog image_fade=true return_dialog=5 stock=1x12 catalog_tutorial=4 shop=true beacon=retired settlement=true")
	get_tree().quit()

func _prepare_trio_complete(game: Node) -> void:
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.trio_originals_confirmed = true
	game.encyclopedia_unlocked = false
	game.habitat_unlocked = true
	game.unlocked_series = {"base": true}
	game._register_species_discovery("colorata", true)
	game._register_story_catalog_species("affinis")
	game._register_story_catalog_species("shaviana")
	assert(game._species_get_count("affinis") == 0 and game._species_get_count("shaviana") == 0)
	game._update_main_story_progress(false)
