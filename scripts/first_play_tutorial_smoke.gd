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
	game._advance_intro_story()
	assert(game.intro_story_complete and game.old_seed_bags == 1)
	assert(game.OLD_SEED_GERMINATION_COUNT == 1)

	game._start_greenhouse_play("old")
	await get_tree().create_timer(0.45).timeout
	game.set_process(false)
	assert(game.play_active and game.first_play_tutorial_active)
	assert(game.plants.size() == 1 and game.first_tutorial_species_id == FIRST_SPECIES_ID)
	var first_plant = game.plants[0]
	assert(str(first_plant.data.get("species_id", "")) == FIRST_SPECIES_ID)
	assert(not game._allow_plant_jelly(first_plant))
	first_plant.jelly_checks_enabled = true
	first_plant.jelly_safe_end_seconds = 0.0
	first_plant.jelly_ramp_end_seconds = 0.0
	first_plant.jelly_final_chance = 1.0
	var state_before := str(first_plant.state)
	first_plant.simulate(1.0)
	assert(str(first_plant.state) == state_before)

	game._process(game.FIRST_PLAY_TUTORIAL_INITIAL_DELAY + 0.01)
	assert(game.first_play_tutorial_dialog_visible)
	assert(game.FIRST_PLAY_TUTORIAL_SPEAKERS == ["armadillo", "panda", "panda", "armadillo", "panda"])
	assert("armadillo-dialogue.png" in game.tutorial_panda_portrait.texture.resource_path)
	for message_index in range(game.FIRST_PLAY_TUTORIAL_MESSAGE_KEYS.size()):
		var message_key := str(game.FIRST_PLAY_TUTORIAL_MESSAGE_KEYS[message_index])
		for locale in Localizer.SUPPORTED_LANGUAGES:
			assert(not Localizer.text(locale, message_key).is_empty())
		assert(game.tutorial_guide_message.text == Localizer.text(game.language_code, message_key))
		game.tutorial_guide_button.pressed.emit()
	assert(game.first_play_tutorial_sequence_complete)
	assert(Localizer.text("ja", "tutorial_harvest_tap") == "ジュレてしまう前にタップで収穫！")
	assert(game.first_play_harvest_guide_active)
	assert(game.tutorial_guide_message.text == Localizer.text("ja", "tutorial_harvest_tap"))
	assert(not game.tutorial_panda_portrait.visible)

	first_plant.harvest()
	await get_tree().create_timer(0.75).timeout
	game._poll_greenhouse_play_completion()
	await get_tree().process_frame
	assert(not game.play_active and game.result_overlay.visible and game.total_play_count == 1)
	assert(bool(game.discovered.get(FIRST_SPECIES_ID, false)))
	assert(not game.first_colorata_confirmed)
	assert(game.species_get_overlay.visible)
	assert(game.species_get_overlay.badge_label.text == Localizer.text("ja", "new"))
	assert(game.species_get_overlay.name_label.text == Localizer.species_name("ja", game._catalog_entry(FIRST_SPECIES_ID)))
	game.species_get_overlay.close_overlay()
	await get_tree().create_timer(0.2).timeout

	game._close_result()
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
	assert(bool(game.unlocked_series.get("base", false)) and not game.encyclopedia_overlay.visible)
	assert(game.scripted_dialog_kind == "trio_originals")
	assert(game.scripted_dialog_pages.size() == 7)
	assert([game.scripted_dialog_pages[0].speaker, game.scripted_dialog_pages[1].speaker, game.scripted_dialog_pages[2].speaker, game.scripted_dialog_pages[3].speaker, game.scripted_dialog_pages[4].speaker] == ["panda", "armadillo", "armadillo", "girl", "panda"])
	for locale in Localizer.SUPPORTED_LANGUAGES:
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

	print("FIRST_PLAY_TUTORIAL_SMOKE_OK seed=1 plant=1 species=colorata safe=true discovery=major trio=colorata+affinis+shaviana")
	get_tree().quit()
