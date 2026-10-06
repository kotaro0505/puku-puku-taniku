extends Node

const Localizer = preload("res://scripts/game_localizer.gd")
const FIRST_SPECIES_ID := "colorata"

func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	# This suite deliberately preserves the complete legacy finite tutorial flow.
	game.endless_greenhouse.configure(false)
	game._reset_progression_state()
	game._set_language("ja")
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
	assert(game.intro_dialogue_label.text == "はい、これ。きみの分の1粒だよ。古いから、芽が出るかは分からないけど…")
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
	assert(is_equal_approx(first_plant.growth_rate, game.FIRST_STORY_COLORATA_GROWTH_MULTIPLIER))
	assert(is_equal_approx(float(first_plant.get_meta("first_story_growth_multiplier", 0.0)), 1.3))
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
	assert(is_zero_approx(game.puku_gauge_cm) and game.puku_balance_units==0)
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
	assert([game.scripted_dialog_pages[0].text, game.scripted_dialog_pages[1].text, game.scripted_dialog_pages[2].text] == ["本当に多肉植物のタネだったなんて！", "この本によると、これは『コロラータ』っていう種類らしいよ！", "すごい。世界に多肉植物が帰って来てくれたんだ……！"])
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
	# Each companion's catalog-only card appears immediately after that
	# companion names the species, then the same dialogue resumes. Full-screen
	# input closes both the card center and dim background exactly once.
	var species_card_closes:Array[String]=[]
	game.species_get_overlay.closed.connect(func(context:String):species_card_closes.append(context))
	assert(game.scripted_dialog_index == 0)
	game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.species_get_overlay.visible and game.species_get_overlay.busy)
	_press_species_overlay(game.species_get_overlay,game.species_get_overlay.card.position+game.species_get_overlay.card.size*.5,true)
	assert(game.species_get_overlay.visible and game.species_get_overlay.busy)
	await get_tree().create_timer(.65).timeout
	assert(game.species_get_overlay.visible)
	assert(game.species_get_overlay.name_label.text == Localizer.species_name("ja", game._catalog_entry("affinis")))
	assert(game.species_get_overlay.badge_label.text == Localizer.text("ja", "original_catalog_new"))
	assert(bool(game.discovered.get("affinis", false)))
	assert(game._species_get_count("affinis") == 0 and not bool(game.greenhouse_available.get("affinis", false)))
	_press_species_overlay(game.species_get_overlay,game.species_get_overlay.card.position+game.species_get_overlay.card.size*.5,true)
	await get_tree().create_timer(.45).timeout
	assert(species_card_closes.count("scripted_dialog_card:affinis")==1)
	_press_species_overlay(game.species_get_overlay,Vector2(8,8),false)
	assert(species_card_closes.count("scripted_dialog_card:affinis")==1)
	assert(game.scripted_dialog_kind == "trio_originals" and game.scripted_dialog_index == 1)
	assert(Localizer.species_name("ja", game._catalog_entry("shaviana")) in game.intro_dialogue_label.text)
	# Re-open an Affinis probe to verify that the dimmed edge is the same close
	# target as the card itself, without changing the story sequence.
	game.species_get_overlay.show_species(game._catalog_entry("affinis"),game._species_texture(game._catalog_entry("affinis")),true,"input_probe_affinis","ja")
	await get_tree().create_timer(.65).timeout
	_press_species_overlay(game.species_get_overlay,Vector2(8,8),false)
	await get_tree().create_timer(.35).timeout
	assert(species_card_closes.count("input_probe_affinis")==1)
	assert(game.scripted_dialog_kind == "trio_originals" and game.scripted_dialog_index == 1)
	game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.species_get_overlay.visible and game.species_get_overlay.busy)
	await get_tree().create_timer(.65).timeout
	assert(game.species_get_overlay.visible)
	assert(game.species_get_overlay.name_label.text == Localizer.species_name("ja", game._catalog_entry("shaviana")))
	assert(game.species_get_overlay.badge_label.text == Localizer.text("ja", "original_catalog_new"))
	assert(bool(game.discovered.get("shaviana", false)))
	assert(game._species_get_count("shaviana") == 0 and not bool(game.greenhouse_available.get("shaviana", false)))
	_press_species_overlay(game.species_get_overlay,game.species_get_overlay.card.position+game.species_get_overlay.card.size*.5,true)
	await get_tree().create_timer(.45).timeout
	assert(species_card_closes.count("scripted_dialog_card:shaviana")==1)
	assert(game.scripted_dialog_kind == "trio_originals" and game.scripted_dialog_index == 2)
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
	assert(game._species_get_count("affinis") == 0 and game._species_get_count("shaviana") == 0)
	assert(not bool(game.greenhouse_available.get("affinis", false)) and not bool(game.greenhouse_available.get("shaviana", false)))
	assert(not game.species_get_overlay.visible)
	assert(not game.mystery_items_acquired and not game.encyclopedia_unlocked)
	game._update_play_ui();assert(not game.puku_gauge_area.visible and not game.encyclopedia_icon_button.visible)
	assert(game.main_story_stage == game.StoryProgressionClass.ACT_1)
	assert(game.tutorial_guide_overlay.visible and str(game.tutorial_guide_button.get_meta("target", "")) == "habitat")
	assert(game.tutorial_guide_button.size.is_equal_approx(game.mode_button.size))
	assert(game.tutorial_guide_button.custom_minimum_size.is_zero_approx())
	for locale in ["ja", "hiragana", "en"]:
		game._set_language(locale)
		game._show_tutorial_guide("habitat")
		await get_tree().process_frame
		await get_tree().process_frame
		var source_rect:Rect2=game.mode_button.get_global_rect()
		var guide_rect:Rect2=game.tutorial_guide_button.get_global_rect()
		assert(source_rect.position.is_equal_approx(Vector2(398,198)))
		assert(source_rect.size.is_equal_approx(Vector2(153,55)))
		assert(guide_rect.position.is_equal_approx(source_rect.position))
		assert(guide_rect.size.is_equal_approx(source_rect.size))
		assert(game.tutorial_guide_button.scale.is_equal_approx(Vector2.ONE))
		assert(game.tutorial_guide_button.custom_minimum_size.is_zero_approx())
		assert(guide_rect.end.x<=game.get_viewport().get_visible_rect().end.x)
		assert(game.tutorial_guide_button.get_theme_font_size("font_size")==game.mode_button.get_theme_font_size("font_size"))
		print("HABITAT_GUIDE_RECT locale=",locale," source=",source_rect," guide=",guide_rect)
	game._set_language("ja")
	game._show_tutorial_guide("habitat")
	assert(game.tutorial_guide_button.pressed.is_connected(Callable(game,"_complete_tutorial_guide")))
	var normal_habitat_rect:Rect2=game.mode_button.get_global_rect()
	game._hide_first_play_tutorial_overlay()
	await get_tree().process_frame
	assert(game.mode_button.get_global_rect().is_equal_approx(normal_habitat_rect))

	# The formal normal game uses the current twelve-seed round flow.  Keep the
	# finite compatibility mode above for the old-seed prologue only, then verify
	# the production order: pre-sow dialog -> start-button guide -> round start.
	game.endless_greenhouse.configure(true)
	game.opening_finished=true;game.opening_overlay.visible=false;game.opening_story_overlay.visible=false
	game.mystery_items_acquired=true;game.encyclopedia_unlocked=true;game.seed_shop_open=true;game.habitat_awakened=true;game.habitat_tutorial_complete=true;game.mystery_catalog_tutorial_complete=true;game.initial_seed_stock_notice_complete=true;game.first_habitat_gift_claimed=true;game.normal_seed_bags=0;game.current_mode="greenhouse";game.normal_play_tutorial_complete=false;game.seed_pod_gauge_discovery_complete=false;game.seed_pod_first_reward_seen=false;game.puku_buyback_tutorial_complete=false;game.puku_gauge_intro_complete=true;game.puku_gauge_cm=0.0;game.puku_balance_units=game.INITIAL_PUKU_CAPITAL_UNITS
	game._update_play_ui();assert(game.best_panel.visible)
	game._start_first_normal_sow_prompt()
	assert(game.scripted_dialog_kind == "first_normal_sow_prompt")
	assert(game.intro_dialogue_label.text == Localizer.text("ja", "tutorial_normal_pre_sow_endless"))
	game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.scripted_dialog_kind.is_empty())
	assert(str(game.tutorial_guide_button.get_meta("target", "")) == "play_open_normal")
	assert(game.tutorial_guide_overlay.visible)
	assert(game.tutorial_cost_note_panel.visible)
	assert(game.tutorial_cost_note_label.text == "1ぷくコインを消費します")
	assert(bool(game.tutorial_steps.get("first_normal_cost_notice_seen", false)))
	var puku_before_round: int = game.puku_balance_units
	game._complete_tutorial_guide()
	assert(not game.tutorial_cost_note_panel.visible)
	assert(game._should_simulate_endless_greenhouse(), "formal round remained blocked: intro=%s play_overlay=%s result=%s tutorial=%s scripted=%s" % [game.intro_overlay.visible, game.play_overlay.visible, game.result_overlay.visible, game.tutorial_guide_overlay.visible, game.scripted_dialog_kind])
	await get_tree().create_timer(.45).timeout
	assert(game.play_active and game.first_play_tutorial_active and game.normal_seed_bags==0 and game.current_target_count==12)
	assert(game.puku_balance_units == puku_before_round - game.NORMAL_ROUND_COST_UNITS)
	assert(game.play_concurrent_target >= game.ENDLESS_NORMAL_MIN_PLANTS and game.play_concurrent_target <= game.ENDLESS_NORMAL_MAX_PLANTS)
	assert(game.play_seeds_remaining == 12 - game.play_concurrent_target)
	assert(game.first_play_tutorial_reserved_seed_pending)
	assert(not game.first_play_tutorial_reserved_species_id.is_empty())
	for normal_tutorial_plant in game.plants:
		assert(is_equal_approx(normal_tutorial_plant.growth_rate, 1.0))
		assert(not normal_tutorial_plant.has_meta("first_story_growth_multiplier"))
	assert(not game.tutorial_guide_overlay.visible and str(game.tutorial_guide_button.get_meta("target", "")) != "normal_seed")
	for plant in game.plants:plant.fast_forward_to_diameter(2.0)
	game._process(game.FIRST_PLAY_TUTORIAL_INITIAL_DELAY+.01)
	assert(game.first_play_tutorial_dialog_visible and game.tutorial_guide_message.text==Localizer.text("ja","tutorial_normal_sprout"), "sprout dialog missing: active=%s play=%s plants=%s message_index=%s wait=%s text=%s" % [game.first_play_tutorial_active, game.play_active, game.plants.size(), game.first_play_tutorial_message_index, game.first_play_tutorial_wait_remaining, game.tutorial_guide_message.text])
	game._dismiss_first_play_tutorial_dialog()
	for plant in game.plants:plant.fast_forward_to_diameter(game.FIRST_PLAY_TUTORIAL_GROWTH_DIALOG_CM)
	var growth_diameters: Array[float] = []
	for plant in game.plants:
		growth_diameters.append(float(plant.diameter_cm))
		assert(float(plant.diameter_cm) >= game.FIRST_PLAY_TUTORIAL_GROWTH_DIALOG_CM, "fast-forward undershot growth threshold: %.12f" % float(plant.diameter_cm))
	var growth_wait_before_process: float = game.first_play_tutorial_wait_remaining
	assert(growth_wait_before_process > 0.0)
	game._process(growth_wait_before_process + .001)
	assert(game.first_play_tutorial_dialog_visible and game.tutorial_guide_message.text==Localizer.text("ja","tutorial_normal_growth"), "growth dialog missing: phase=%s index=%s wait=%.9f visible=%s overlay=%s fade=%s diameters=%s text=%s" % [game.first_play_tutorial_phase, game.first_play_tutorial_message_index, game.first_play_tutorial_wait_remaining, game.first_play_tutorial_dialog_visible, game.tutorial_guide_overlay.visible, game.scene_transition_fade.visible, growth_diameters, game.tutorial_guide_message.text])
	game._dismiss_first_play_tutorial_dialog()
	var jelly_diameters: Array[float] = []
	for plant in game.plants:
		plant.fast_forward_to_diameter(game.FIRST_PLAY_TUTORIAL_JELLY_DIALOG_CM)
		jelly_diameters.append(float(plant.diameter_cm))
		assert(float(plant.diameter_cm) >= game.FIRST_PLAY_TUTORIAL_JELLY_DIALOG_CM, "fast-forward undershot jelly threshold: %.12f" % float(plant.diameter_cm))
	var jelly_wait_before_process: float = game.first_play_tutorial_wait_remaining
	assert(jelly_wait_before_process > 0.0)
	game._process(jelly_wait_before_process + .001)
	assert(game.first_play_tutorial_dialog_visible and game.tutorial_guide_message.text==Localizer.text("ja","tutorial_normal_jelly"), "jelly dialog missing: phase=%s index=%s wait=%.9f visible=%s overlay=%s fade=%s diameters=%s text=%s" % [game.first_play_tutorial_phase, game.first_play_tutorial_message_index, game.first_play_tutorial_wait_remaining, game.first_play_tutorial_dialog_visible, game.tutorial_guide_overlay.visible, game.scene_transition_fade.visible, jelly_diameters, game.tutorial_guide_message.text])
	var initially_spawned_count: int = game.endless_economy_seed_count
	var remaining_before_forced_jelly: int = game.play_seeds_remaining
	game._dismiss_first_play_tutorial_dialog()
	await get_tree().process_frame
	assert(not game.first_play_tutorial_sequence_complete)
	assert(game.first_play_tutorial_phase == "jelly_observe")
	assert(game.endless_economy_jelly_count == 1)
	assert(game.endless_economy_seed_count == initially_spawned_count)
	assert(game.play_seeds_remaining == remaining_before_forced_jelly)
	assert(not is_instance_valid(game.first_play_tutorial_forced_jelly_plant) or game.first_play_tutorial_forced_jelly_plant.state == "jelly")
	game._process(game.FIRST_PLAY_TUTORIAL_JELLY_OBSERVE_SECONDS + .01)
	assert(game.first_play_tutorial_dialog_visible)
	assert(game.tutorial_guide_message.text == "うわ、ジュレた！")
	assert(game.endless_economy_seed_count == initially_spawned_count)
	game._dismiss_first_play_tutorial_dialog()
	assert(game.first_play_tutorial_phase == "reserved_seed_sowing")
	await get_tree().create_timer(.36).timeout
	assert(game.endless_economy_seed_count == initially_spawned_count + 1)
	assert(game.play_seeds_remaining == remaining_before_forced_jelly - 1)
	assert(game.first_play_tutorial_phase == "reserved_seed_observe")
	assert(is_instance_valid(game.first_play_tutorial_reserved_plant))
	var tutorial_harvest_species_id := str(game.first_play_tutorial_reserved_plant.data.get("species_id", ""))
	var tutorial_new_entry: Dictionary = game._catalog_entry(tutorial_harvest_species_id)
	assert(tutorial_harvest_species_id == game.first_play_tutorial_reserved_species_id)
	assert(bool(tutorial_new_entry.get("main_story_original", false)))
	assert(str(tutorial_new_entry.get("rarity", "")) == "通常")
	assert(game._species_get_count(tutorial_harvest_species_id) == 0)
	assert(not game.first_play_tutorial_reserved_plant.jelly_checks_enabled)
	game._process(game.FIRST_PLAY_TUTORIAL_NEW_OBSERVE_SECONDS - .01)
	assert(not game.first_play_tutorial_dialog_visible)
	game._process(.02)
	assert(game.first_play_tutorial_dialog_visible)
	assert(game.tutorial_guide_message.text == "見て！はじめて見る品種が出てる！")
	game._dismiss_first_play_tutorial_dialog()
	assert(game.first_play_tutorial_phase == "new_species_girl")
	assert(game.tutorial_guide_message.text == "ジュレる前に収穫しよう！")
	game._dismiss_first_play_tutorial_dialog()
	assert(game.first_play_tutorial_sequence_complete)
	assert(game.first_play_harvest_guide_active)
	assert(game.tutorial_harvest_plant == game.first_play_tutorial_reserved_plant)
	assert(game.tutorial_guide_message.text == Localizer.text("ja", "tutorial_harvest_tap"))
	assert(game.tutorial_guide_overlay.visible)
	assert(is_zero_approx(game.puku_gauge_cm) and game.puku_balance_units == puku_before_round - game.NORMAL_ROUND_COST_UNITS)
	assert(not game.seed_pod_gauge_discovery_complete and game.scripted_dialog_kind.is_empty())
	var tutorial_harvest_was_new: bool = game._species_get_count(tutorial_harvest_species_id) <= 0
	var tutorial_harvest_reward: int = game._harvest_puku_reward_units(game.tutorial_harvest_plant.diameter_cm, tutorial_harvest_was_new)
	var puku_before_harvest: int = game.puku_balance_units
	var tutorial_new_tap: Vector2 = game.camera.unproject_position(game.tutorial_harvest_plant.global_position + Vector3(0, game.tutorial_harvest_plant.visual_scale * .48, 0))
	game._try_harvest(tutorial_new_tap)
	await get_tree().process_frame
	assert(game.normal_play_tutorial_complete and not game.first_play_tutorial_active)
	assert(game.puku_balance_units == puku_before_harvest + tutorial_harvest_reward)
	assert(tutorial_harvest_reward >= game.FIRST_GET_MIN_REWARD_UNITS)
	assert(tutorial_harvest_species_id in game.pending_round_new_species_ids)
	assert(game._species_get_count(tutorial_harvest_species_id) == 0)
	assert(not game.species_get_overlay.visible)
	await get_tree().process_frame
	assert(game.puku_buyback_tutorial_active)
	assert(game.tutorial_guide_message.text=="そうだ！育てた多肉はうちのお店で買い取るよ！")
	assert(game.tutorial_panda_portrait.visible)
	game._advance_puku_buyback_tutorial()
	assert(game.tutorial_guide_message.text=="大きい株ほど高く買い取るからね！")
	assert(game.tutorial_panda_portrait.visible)
	game._advance_puku_buyback_tutorial()
	assert(bool(game.first_play_harvest_spotlight_material.get_shader_parameter("focus_ellipse")))
	var puku_center: Vector2 = game.first_play_harvest_spotlight_material.get_shader_parameter("focus_uv_a")
	var puku_half_size: Vector2 = game.first_play_harvest_spotlight_material.get_shader_parameter("focus_half_size_uv")
	var seed_center: Vector2 = (game.seed_pod_gauge_area.global_position + game.seed_pod_gauge_area.size * .5) / game.get_viewport().get_visible_rect().size
	assert(((seed_center - puku_center) / puku_half_size).length() > 1.0)
	assert(game.tutorial_guide_message.text==Localizer.text("ja","puku_buyback_2_endless"))
	assert(not game.tutorial_panda_portrait.visible)
	game._advance_puku_buyback_tutorial()
	assert(game.puku_buyback_tutorial_complete and not game.puku_buyback_tutorial_active)
	assert(not Localizer.text("ja","puku_buyback_2").contains("1ぷく未満"))
	assert(not game.first_seed_pod_reward_event_active and game.normal_seed_bags == 0 and is_zero_approx(game.puku_gauge_cm))

	# The scripted jelly and NEW harvest settled two seeds. Settle the remaining
	# ten as jelly so this tutorial suite also proves
	# that the first formal round ends at exactly twelve settlements.
	for settlement_index in range(10):
		assert(game.play_active and not game.plants.is_empty(), "first normal round ended before all 12 seeds settled")
		var plant_to_jelly = game.plants[0]
		plant_to_jelly.jelly_checks_enabled=false
		plant_to_jelly.jelly()
		await get_tree().process_frame
		if game.play_active and game.play_spawn_queue>0:
			game.play_spawn_timer=0.0;game._process(.01)
			await get_tree().create_timer(.32).timeout
	assert(await _wait_until(func()->bool:return not game.play_active and game.result_overlay.visible), "round result did not wait for/complete the Puku gauge queue: active=%s result=%s puku_running=%s puku_queue=%s plants=%s seeds_remaining=%s spawn_queue=%s" % [game.play_active, game.result_overlay.visible, game.puku_gauge_animation_running, game.puku_gauge_animation_queue.size(), game.plants.size(), game.play_seeds_remaining, game.play_spawn_queue])
	assert(game.endless_economy_seed_count == 12 and game.endless_economy_harvest_count == 1 and game.endless_economy_jelly_count == 11)
	assert(game.endless_economy_seed_cost_units == game.NORMAL_ROUND_COST_UNITS)
	assert(game.result_count_label.text.contains("収穫　1株") and game.result_count_label.text.contains("ジュレ　11株"))
	assert(game.result_new_species_label.text.is_empty() and not game.result_new_species_label.visible)
	assert(game._species_get_count(tutorial_harvest_species_id) == 0)
	game._close_result()
	assert(await _wait_until(func()->bool:return game._species_get_count(tutorial_harvest_species_id)==1 and game.species_get_overlay.visible), "post-result NEW reveal did not complete: count=%s overlay=%s pending=%s" % [game._species_get_count(tutorial_harvest_species_id), game.species_get_overlay.visible, game.pending_round_new_species_ids])
	assert(game._species_get_count(tutorial_harvest_species_id) == 1)
	assert(bool(game.discovered.get(tutorial_harvest_species_id, false)))
	assert(bool(game.greenhouse_available.get(tutorial_harvest_species_id, false)))
	assert(game.species_get_overlay.visible)
	assert(game.species_get_overlay.badge_label.text == Localizer.text("ja", "new"))
	assert(game.species_get_overlay.name_label.text == Localizer.species_name("ja", tutorial_new_entry))
	assert(not game.act2_unlocked)
	assert(not game.StoryProgressionClass.fantasy_is_unlocked(game.story_progression_state))
	assert(not bool(game.story_progression_state.get("original_new_guarantee_pending", false)))
	assert(not bool(game.story_progression_state.get("original_new_guarantee_consumed", false)))

	assert(Localizer.text("ja","puku_buyback_1") == "そうだ！育てた多肉はうちのお店で買い取るよ！")
	assert(Localizer.text("ja","puku_buyback_2") == "大きい株ほど高く買い取るからね！")
	print("FIRST_PLAY_TUTORIAL_SMOKE_OK old_colorata_growth=1.3 normal_growth=unchanged cost_note=once trio_cards=catalog_only pre_sow=true start_guide=play_open_normal forced_jelly=true reserved_original_new=true observed_3s=true post_result_GET=true act2_guarantee_untouched=true total=12 result=1_harvest+11_jelly")
	get_tree().quit()


func _wait_until(predicate:Callable,timeout_seconds:=5.0)->bool:
	var elapsed:=0.0
	while elapsed<timeout_seconds and not bool(predicate.call()):
		await get_tree().create_timer(.02).timeout
		elapsed+=.02
	return bool(predicate.call())


func _press_species_overlay(overlay:Control,position:Vector2,touch:bool)->void:
	if touch:
		var event:=InputEventScreenTouch.new();event.pressed=true;event.position=position
		overlay._input(event)
	else:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=position
		overlay._input(event)
