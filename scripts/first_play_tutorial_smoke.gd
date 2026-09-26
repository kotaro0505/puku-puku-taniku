extends Node

const Localizer = preload("res://scripts/game_localizer.gd")
const FIRST_SPECIES_ID := "colorata"

func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game._reset_progression_state()
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	game.opening_story_complete = true
	game.opening_story_overlay.visible = false
	game._update_play_ui()
	assert(not game.puku_gauge_area.visible and not game.encyclopedia_icon_button.visible)

	# The picture-book already established the old book and shared seed. The
	# hand-off now gives exactly the player's single seed, with no duplicate
	# "leftover seed" story.
	game._start_intro_story()
	assert(game.intro_dialogue_label.text == Localizer.text("ja", "intro_old_seed"))
	assert(not "売れ残った" in game.intro_dialogue_label.text)
	game._advance_intro_story()
	assert(game.intro_dialogue_label.text == Localizer.text("ja", "intro_old_seed_get"))
	assert(not game.intro_portrait_slot.visible and not game.intro_continue_button.visible)
	assert(game.intro_fullscreen_continue_button.visible)
	assert(game.intro_dialogue_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER)
	game._advance_intro_story()
	assert(game.intro_story_complete and game.old_seed_bags == 1)
	assert(game.OLD_SEED_GERMINATION_COUNT == 1)

	game._hide_first_play_tutorial_overlay()
	game._start_greenhouse_play("old")
	await get_tree().create_timer(0.45).timeout
	game.set_process(false)
	assert(game.play_active and not game.first_play_tutorial_active)
	assert(game.plants.size() == 1 and game.first_tutorial_species_id == FIRST_SPECIES_ID)
	var first_plant = game.plants[0]
	assert(str(first_plant.data.get("species_id", "")) == FIRST_SPECIES_ID)
	assert(not game._allow_plant_jelly(first_plant))
	game._update_play_ui()
	game._update_labels()
	assert(not game.best_panel.visible and not first_plant.label.visible)
	first_plant.jelly_checks_enabled = true
	first_plant.jelly_safe_end_seconds = 0.0
	first_plant.jelly_ramp_end_seconds = 0.0
	first_plant.jelly_final_chance = 1.0
	var state_before := str(first_plant.state)
	first_plant.simulate(1.0)
	assert(str(first_plant.state) == state_before)
	assert(not game.tutorial_guide_overlay.visible)
	assert(is_zero_approx(game.puku_gauge_cm) and is_zero_approx(game.puku_coin_gauge_cm))
	first_plant.fast_forward_to_diameter(game.OLD_SEED_REACTION_SPROUT_CM)
	game._process(0.01)
	assert(game.scripted_dialog_kind == "old_seed_growth_reaction")
	assert(game.scripted_dialog_pages.size() == 3)
	assert([game.scripted_dialog_pages[0].speaker, game.scripted_dialog_pages[1].speaker, game.scripted_dialog_pages[2].speaker] == ["armadillo", "trio", "girl"])
	assert(game.intro_dialogue_label.text == Localizer.text("ja", "old_seed_reaction_sprout"))
	game._advance_scripted_dialog()
	assert(game.intro_dialogue_label.text == Localizer.text("ja", "old_seed_reaction_trio") and game.intro_trio_portraits.visible)
	assert(game.intro_trio_portraits.get_child_count() == 3)
	for trio_portrait in game.intro_trio_portraits.get_children():
		assert((trio_portrait as TextureRect).size.is_equal_approx(Vector2(86, 126)))
	game._advance_scripted_dialog()
	assert(game.intro_dialogue_label.text == Localizer.text("ja", "old_seed_reaction_girl"))
	game._advance_scripted_dialog()
	first_plant.fast_forward_to_diameter(game.OLD_SEED_REACTION_GROWTH_CM)
	game._process(0.01)
	assert(game.scripted_dialog_kind == "old_seed_growth_reaction")
	assert(game.scripted_dialog_pages.size() == 1 and game.scripted_dialog_pages[0].speaker == "panda")
	assert(game.intro_dialogue_label.text == Localizer.text("ja", "old_seed_reaction_growth"))
	game._advance_scripted_dialog()
	first_plant.fast_forward_to_diameter(game.TUTORIAL_HARVEST_CM + 4.0)
	game._process(0.01)
	assert(game.old_seed_harvest_guide_active and game.tutorial_harvest_plant == first_plant)
	assert(is_equal_approx(first_plant.diameter_cm, game.TUTORIAL_HARVEST_CM))
	assert(game.tutorial_guide_overlay.visible and not game.tutorial_panda_portrait.visible)
	var stopped_old_seed_size: float = first_plant.diameter_cm
	game._process(1.0)
	assert(is_equal_approx(first_plant.diameter_cm, stopped_old_seed_size))
	var old_seed_tap: Vector2 = game.camera.unproject_position(first_plant.global_position + Vector3(0, first_plant.visual_scale * .48, 0))
	game._try_harvest(old_seed_tap)
	assert(not game.old_seed_harvest_guide_active)
	await get_tree().create_timer(1.25).timeout
	game._poll_greenhouse_play_completion()
	await get_tree().create_timer(0.65).timeout
	assert(not game.play_active and not game.result_overlay.visible and game.total_play_count == 1)
	assert(not game.best_panel.visible and not game.play_updated_global_best)
	assert(not game.bests.has(FIRST_SPECIES_ID))
	assert(bool(game.discovered.get(FIRST_SPECIES_ID, false)))
	assert(not game.first_colorata_confirmed)
	assert(game.species_get_overlay.visible)
	assert(game.species_get_overlay.badge_label.text == Localizer.text("ja", "new"))
	assert(game.species_get_overlay.name_label.text == Localizer.species_name("ja", game._catalog_entry(FIRST_SPECIES_ID)))
	game.species_get_overlay.close_overlay()
	await get_tree().create_timer(0.2).timeout
	assert(game.scripted_dialog_kind == "first_colorata_discovery")
	assert(game.scripted_dialog_pages.size() == 3)
	assert([game.scripted_dialog_pages[0].speaker, game.scripted_dialog_pages[1].speaker, game.scripted_dialog_pages[2].speaker] == ["panda", "armadillo", "panda"])
	var discovery_text := ""
	for page in game.scripted_dialog_pages:
		discovery_text += str(page.get("text", ""))
	assert("本当に多肉植物のタネだったなんて" in discovery_text)
	assert("世界に多肉植物が帰って来てくれたんだ" in discovery_text)
	assert("本当に育った" not in discovery_text and "図鑑に描いてある植物" not in discovery_text)
	assert(Localizer.species_name("ja", game._catalog_entry(FIRST_SPECIES_ID)) in discovery_text)
	while not game.scripted_dialog_kind.is_empty():
		var speaker_id := str(game.scripted_dialog_pages[game.scripted_dialog_index].get("speaker", ""))
		if speaker_id in ["girl", "panda", "armadillo"]:
			assert(game.intro_panda_portrait.visible and game.intro_panda_portrait.texture != null)
		game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.first_colorata_confirmed and not game.encyclopedia_unlocked)
	assert(not game.best_panel.visible)
	assert(bool(game.unlocked_series.get("base", false)) and not game.encyclopedia_overlay.visible)
	assert(game.scripted_dialog_kind == "trio_originals")
	assert(game.scripted_dialog_pages.size() == 7)
	assert([game.scripted_dialog_pages[0].speaker, game.scripted_dialog_pages[1].speaker, game.scripted_dialog_pages[2].speaker, game.scripted_dialog_pages[3].speaker, game.scripted_dialog_pages[4].speaker] == ["panda", "armadillo", "armadillo", "girl", "panda"])
	for locale in Localizer.SUPPORTED_LANGUAGES:
		assert(not Localizer.text(locale, "old_seed_reaction_sprout").is_empty())
		assert(not Localizer.text(locale, "old_seed_reaction_trio").is_empty())
		assert(not Localizer.text(locale, "old_seed_reaction_girl").is_empty())
		assert(not Localizer.text(locale, "old_seed_reaction_growth").is_empty())
		assert(Localizer.species_name(locale, game._catalog_entry("affinis")) in Localizer.text(locale, "story_trio_1", [Localizer.species_name(locale, game._catalog_entry("affinis"))]))
		assert(Localizer.species_name(locale, game._catalog_entry("shaviana")) in Localizer.text(locale, "story_trio_2", [Localizer.species_name(locale, game._catalog_entry("shaviana"))]))
		for key in ["story_trio_3", "story_trio_4", "story_trio_5"]:
			assert(not Localizer.text(locale, key).is_empty())
	var trio_text := ""
	for page in game.scripted_dialog_pages:
		trio_text += str(page.get("text", ""))
	assert(Localizer.species_name("ja", game._catalog_entry("affinis")) in trio_text)
	assert(Localizer.species_name("ja", game._catalog_entry("shaviana")) in trio_text)
	assert("こうして見られるなんて" in trio_text)
	assert("ぷくぷくしてて可愛いね" in trio_text)
	assert("この世界が多肉植物でいっぱいになってほしいね" in trio_text)
	assert("はじめまして" not in trio_text)
	assert("昔、多肉が生えていたと言われる場所" in trio_text)
	while not game.scripted_dialog_kind.is_empty():
		var speaker_id := str(game.scripted_dialog_pages[game.scripted_dialog_index].get("speaker", ""))
		if speaker_id in ["girl", "panda", "armadillo"]:
			assert(game.intro_panda_portrait.visible and game.intro_panda_portrait.texture != null)
		game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.trio_originals_confirmed and game.habitat_unlocked)
	assert(bool(game.discovered.get("colorata", false)))
	assert(bool(game.discovered.get("affinis", false)))
	assert(bool(game.discovered.get("shaviana", false)))
	assert(not game.mystery_items_acquired and not game.encyclopedia_unlocked)
	game._update_play_ui();assert(not game.puku_gauge_area.visible and not game.encyclopedia_icon_button.visible)
	assert(game.main_story_stage == game.StoryProgressionClass.STAGE_FIND_HABITAT)
	assert(game.tutorial_guide_overlay.visible and str(game.tutorial_guide_button.get_meta("target", "")) == "habitat")
	assert(game.tutorial_guide_button.size.is_equal_approx(game.mode_button.size))
	assert(game.tutorial_guide_button.custom_minimum_size.is_equal_approx(game.mode_button.size))

	# The actual controls tutorial starts only with the first normal bag after
	# the awakening items have been acquired.
	game.mystery_items_acquired=true;game.encyclopedia_unlocked=true;game.seed_shop_open=true;game.habitat_awakened=true;game.habitat_tutorial_complete=true;game.mystery_catalog_tutorial_complete=true;game.normal_seed_bags=4;game.current_mode="greenhouse";game.normal_play_tutorial_complete=false;game.seed_pod_gauge_discovery_complete=false;game.puku_buyback_tutorial_complete=false;game.puku_gauge_cm=0.0;game.puku_coin_gauge_cm=0.0
	game._update_play_ui();assert(game.best_panel.visible)
	game._hide_first_play_tutorial_overlay();game._start_greenhouse_play("normal")
	await get_tree().create_timer(.45).timeout
	assert(game.play_active and game.first_play_tutorial_active and game.normal_seed_bags==3 and game.current_target_count==12)
	game._process(game.FIRST_PLAY_TUTORIAL_INITIAL_DELAY+.01)
	assert(game.first_play_tutorial_dialog_visible and game.tutorial_guide_message.text==Localizer.text("ja","tutorial_normal_sow_1"))
	game._dismiss_first_play_tutorial_dialog();assert(game.tutorial_guide_message.text==Localizer.text("ja","tutorial_normal_sow_2"))
	game._dismiss_first_play_tutorial_dialog();assert(not game.first_play_tutorial_dialog_visible and game.first_play_tutorial_message_index==2)
	game._process(.21);game._process(.01)
	assert(game.first_play_tutorial_dialog_visible and game.tutorial_guide_message.text==Localizer.text("ja","tutorial_normal_sprout"))
	game._dismiss_first_play_tutorial_dialog()
	for plant in game.plants:plant.fast_forward_to_diameter(game.FIRST_PLAY_TUTORIAL_GROWTH_DIALOG_CM)
	game._process(.21)
	assert(game.first_play_tutorial_dialog_visible and game.tutorial_guide_message.text==Localizer.text("ja","tutorial_normal_growth"))
	game._dismiss_first_play_tutorial_dialog()
	for plant in game.plants:plant.fast_forward_to_diameter(game.FIRST_PLAY_TUTORIAL_JELLY_DIALOG_CM)
	game._process(.21)
	assert(game.first_play_tutorial_dialog_visible and game.tutorial_guide_message.text==Localizer.text("ja","tutorial_normal_jelly"))
	game._dismiss_first_play_tutorial_dialog();assert(game.first_play_tutorial_sequence_complete)
	game._process(.05);await get_tree().process_frame
	assert(game.puku_gauge_cm>0.0 and is_zero_approx(game.puku_coin_gauge_cm))
	assert(game.seed_pod_gauge_discovery_complete and game.scripted_dialog_kind=="seed_pod_gauge_discovery" and game.scripted_dialog_pages.size()==2)
	while not game.scripted_dialog_kind.is_empty():game._advance_scripted_dialog()
	for plant in game.plants:plant.fast_forward_to_diameter(game.TUTORIAL_HARVEST_CM + .1)
	game.play_seed_animations_pending=0;game._process(.01)
	assert(game.first_play_harvest_guide_active and game.tutorial_guide_message.text==Localizer.text("ja","tutorial_harvest_tap"))
	assert(is_equal_approx(game.tutorial_harvest_plant.diameter_cm, game.TUTORIAL_HARVEST_CM))
	game.tutorial_harvest_plant.harvest();await get_tree().process_frame
	assert(game.normal_play_tutorial_complete and game.puku_coin_gauge_cm>=game.TUTORIAL_HARVEST_CM and game.puku_buyback_tutorial_active)
	assert(game.tutorial_guide_message.text==Localizer.text("ja","puku_buyback_1"));game._advance_puku_buyback_tutorial()
	assert(bool(game.first_play_harvest_spotlight_material.get_shader_parameter("focus_ellipse")))
	var puku_center: Vector2 = game.first_play_harvest_spotlight_material.get_shader_parameter("focus_uv_a")
	var puku_half_size: Vector2 = game.first_play_harvest_spotlight_material.get_shader_parameter("focus_half_size_uv")
	var seed_center: Vector2 = (game.seed_pod_gauge_area.global_position + game.seed_pod_gauge_area.size * .5) / game.get_viewport().get_visible_rect().size
	assert(((seed_center - puku_center) / puku_half_size).length() > 1.0)
	assert(game.tutorial_guide_message.text==Localizer.text("ja","puku_buyback_2"));game._advance_puku_buyback_tutorial()
	assert(game.puku_buyback_tutorial_complete and not game.puku_buyback_tutorial_active)

	assert(Localizer.text("ja","puku_buyback_1") == "育てた多肉はうちのお店で買い取るよ！")
	print("FIRST_PLAY_TUTORIAL_SMOKE_OK old_seed=manual_25cm_harvest normal=staged_25cm_harvest pod_discovery=true buyback=ellipse")
	get_tree().quit()
