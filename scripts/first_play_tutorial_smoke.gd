extends Node

const Localizer = preload("res://scripts/game_localizer.gd")
const StoryContinueButtonStyleClass = preload("res://scripts/story_continue_button_style.gd")
const StandardStoryDialoguePanelClass = preload("res://scripts/standard_story_dialogue_panel.gd")
const FIRST_SPECIES_ID := "colorata"
const MANUAL_SETTLEMENT_PLANT_TIMEOUT_SECONDS := 5.0

var manual_settlement_wait_failure := ""

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
	assert(game.intro_dialogue_label.text == "はい、これ。きみの分の1粒。古いから、芽が出るかは分からないけど…")
	assert(Localizer.text("hiragana", "intro_old_seed") == "はい、これ。きみの ぶんの 1つぶ。ふるいから、めが でるかは わからないけど…")
	assert(Localizer.text("en", "intro_old_seed") == "Here, one seed for you. It's old, so I don't know if it will sprout...")
	assert("ぼくが まいた たね" in Localizer.text("hiragana", "story_trio_1"))
	assert("The seed I planted" in Localizer.text("en", "story_trio_1"))
	assert(not "売れ残った" in game.intro_dialogue_label.text)
	game._advance_intro_story()
	assert(game.intro_dialogue_label.text == Localizer.text("ja", "intro_old_seed_get"))
	assert(not game.intro_portrait_slot.visible and game.intro_continue_button.visible)
	assert(game.intro_continue_button.text == Localizer.text("ja", "continue"))
	assert(game.intro_fullscreen_continue_button.visible)
	assert(game.intro_fullscreen_continue_button.get_index() < game.intro_dialog_panel.get_index())
	assert(game.intro_continue_button.mouse_filter == Control.MOUSE_FILTER_STOP)
	assert(game.intro_dialogue_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER)
	game.intro_continue_button.pressed.emit()
	assert(game.intro_story_complete and game.old_seed_bags == 1)
	assert(game.first_old_seed_stage == game.FIRST_OLD_SEED_STAGE_READY)
	assert(game.OLD_SEED_GERMINATION_COUNT == 1)
	assert(game.tutorial_guide_overlay.visible and str(game.tutorial_guide_button.get_meta("target", "")) == "play_open")
	assert(game._first_old_seed_play_pending())
	game.normal_seed_bags = 1
	assert(not game._first_old_seed_play_pending())
	game.normal_seed_bags = 0
	game._update_play_ui()
	assert(game.play_open_button.text == Localizer.text("ja", "play_first_old_seed"))
	game._complete_tutorial_guide()
	assert(game.play_active and not game.play_overlay.visible)
	assert(game.old_seed_bags == 0 and game.first_old_seed_stage == game.FIRST_OLD_SEED_STAGE_GROWING)
	await get_tree().create_timer(0.45).timeout
	game.set_process(false)
	assert(game.play_active and not game.first_play_tutorial_active)
	assert(game.plants.size() == 1 and game.first_tutorial_species_id == FIRST_SPECIES_ID)
	var first_plant = game.plants[0]
	assert(str(first_plant.data.get("species_id", "")) == FIRST_SPECIES_ID)
	assert(is_equal_approx(first_plant.growth_rate, game.FIRST_STORY_COLORATA_GROWTH_MULTIPLIER))
	assert(is_equal_approx(first_plant.growth_speed_multiplier,1.0) and not first_plant.kakuhen_enabled)
	assert(first_plant.jelly_rates_per_second==[0.01,0.02,0.03,0.04])
	assert(is_equal_approx(float(first_plant.get_meta("first_story_growth_multiplier", 0.0)), 1.3))
	assert(not game._allow_plant_jelly(first_plant))
	game._update_play_ui()
	game._update_labels()
	assert(not game.best_panel.visible and not first_plant.label.visible)
	first_plant.jelly_checks_enabled = true
	first_plant.jelly_rates_per_second.assign([1.0, 1.0, 1.0, 1.0])
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
		assert((trio_portrait as TextureRect).size.is_equal_approx(Vector2(86, 112)))
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
	assert(game.first_old_seed_stage == game.FIRST_OLD_SEED_STAGE_HARVESTED)
	assert(game.species_get_overlay.visible)
	assert(game.species_get_overlay.badge_label.visible and game.species_get_overlay.badge_label.text == Localizer.text("ja", "new"))
	assert(game.species_get_overlay.name_label.text == Localizer.species_name("ja", game._catalog_entry(FIRST_SPECIES_ID)))
	assert(game.species_get_overlay.series_label.text == "原種")
	game.species_get_overlay.close_overlay()
	await get_tree().create_timer(0.2).timeout
	assert(game.first_old_seed_stage == game.FIRST_OLD_SEED_STAGE_CARD_CLOSED)
	assert(game.scripted_dialog_kind == "first_colorata_discovery")
	assert(game.scripted_dialog_pages.size() == 3)
	assert([game.scripted_dialog_pages[0].speaker, game.scripted_dialog_pages[1].speaker, game.scripted_dialog_pages[2].speaker] == ["panda", "armadillo", "panda"])
	assert([game.scripted_dialog_pages[0].text, game.scripted_dialog_pages[1].text, game.scripted_dialog_pages[2].text] == ["本当に多肉植物のたねだったなんて！", "この本によると、これは『コロラータ』っていう種類らしいよ！", "すごい。世界に多肉植物が帰って来てくれたんだ……！"])
	var discovery_text := ""
	for page in game.scripted_dialog_pages:
		discovery_text += str(page.get("text", ""))
	assert("本当に多肉植物のたねだったなんて" in discovery_text)
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
	assert(game.first_old_seed_stage == game.FIRST_OLD_SEED_STAGE_CONFIRMED)
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
	assert(game.species_get_overlay.badge_label.visible and game.species_get_overlay.badge_label.text == Localizer.text("ja", "original_catalog_new"))
	assert(game.species_get_overlay.series_label.text == "原種")
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
	game.species_get_overlay.show_species(game._catalog_entry("affinis"),game._species_texture(game._catalog_entry("affinis")),true,"input_probe_affinis","ja","原種")
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
	assert(game.species_get_overlay.badge_label.visible and game.species_get_overlay.badge_label.text == Localizer.text("ja", "original_catalog_new"))
	assert(game.species_get_overlay.series_label.text == "原種")
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
	assert(game.tutorial_guide_overlay.find_child("FirstNormalCostNote",true,false)==null)
	assert(game.tutorial_guide_button.text=="たねをまく\n1ぷくコイン消費")
	assert(not game.tutorial_steps.has("first_normal_cost_notice_seen"))
	var puku_before_round: int = game.puku_balance_units
	game._complete_tutorial_guide()
	assert(game._should_simulate_endless_greenhouse(), "formal round remained blocked: intro=%s play_overlay=%s result=%s tutorial=%s scripted=%s" % [game.intro_overlay.visible, game.play_overlay.visible, game.result_overlay.visible, game.tutorial_guide_overlay.visible, game.scripted_dialog_kind])
	await get_tree().create_timer(.45).timeout
	assert(game.play_active and game.first_play_tutorial_active and game.normal_seed_bags==0 and game.current_target_count==12)
	assert(game.puku_balance_units == puku_before_round - game.NORMAL_ROUND_COST_UNITS)
	assert(game.ENDLESS_NORMAL_MIN_PLANTS==5 and game.ENDLESS_NORMAL_MAX_PLANTS==8)
	assert(game.play_concurrent_target >= game.ENDLESS_NORMAL_MIN_PLANTS and game.play_concurrent_target <= game.ENDLESS_NORMAL_MAX_PLANTS)
	assert(game.play_seeds_remaining == 12 - game.play_concurrent_target)
	assert(game.plants.size()+game.play_spawn_queue+game.play_seed_animations_pending<=game.ENDLESS_NORMAL_MAX_PLANTS)
	assert(game.first_play_tutorial_reserved_seed_pending)
	assert(not game.first_play_tutorial_reserved_species_id.is_empty())
	for normal_tutorial_plant in game.plants:
		assert(is_equal_approx(normal_tutorial_plant.growth_rate, 1.0))
		assert(is_equal_approx(normal_tutorial_plant.growth_speed_multiplier,1.6))
		assert(normal_tutorial_plant.jelly_rates_per_second==[0.01,0.025,0.05,0.08])
		assert(normal_tutorial_plant.kakuhen_enabled)
		assert(not normal_tutorial_plant.has_meta("first_story_growth_multiplier"))
	assert(not game.tutorial_guide_overlay.visible and str(game.tutorial_guide_button.get_meta("target", "")) != "normal_seed")
	for plant in game.plants:plant.fast_forward_to_diameter(2.0)
	game._process(game.FIRST_PLAY_TUTORIAL_INITIAL_DELAY+.01)
	assert(game.first_play_tutorial_dialog_visible and game.tutorial_guide_message.text==Localizer.text("ja","tutorial_normal_sprout"), "sprout dialog missing: active=%s play=%s plants=%s message_index=%s wait=%s text=%s" % [game.first_play_tutorial_active, game.play_active, game.plants.size(), game.first_play_tutorial_message_index, game.first_play_tutorial_wait_remaining, game.tutorial_guide_message.text])
	await get_tree().process_frame
	_assert_visible_tutorial_continue(game,"ja","panda")
	var sprout_message_index:int=game.first_play_tutorial_message_index
	game.tutorial_continue_button.pressed.emit()
	assert(game.first_play_tutorial_message_index==sprout_message_index+1 and not game.first_play_tutorial_dialog_visible)
	for plant in game.plants:plant.fast_forward_to_diameter(game.FIRST_PLAY_TUTORIAL_GROWTH_DIALOG_CM)
	var growth_diameters: Array[float] = []
	for plant in game.plants:
		growth_diameters.append(float(plant.diameter_cm))
		assert(float(plant.diameter_cm) >= game.FIRST_PLAY_TUTORIAL_GROWTH_DIALOG_CM, "fast-forward undershot growth threshold: %.12f" % float(plant.diameter_cm))
	var growth_wait_before_process: float = game.first_play_tutorial_wait_remaining
	assert(growth_wait_before_process > 0.0)
	game._process(growth_wait_before_process + .001)
	assert(game.first_play_tutorial_dialog_visible and game.tutorial_guide_message.text==Localizer.text("ja","tutorial_normal_growth"), "growth dialog missing: phase=%s index=%s wait=%.9f visible=%s overlay=%s fade=%s diameters=%s text=%s" % [game.first_play_tutorial_phase, game.first_play_tutorial_message_index, game.first_play_tutorial_wait_remaining, game.first_play_tutorial_dialog_visible, game.tutorial_guide_overlay.visible, game.scene_transition_fade.visible, growth_diameters, game.tutorial_guide_message.text])
	await get_tree().process_frame
	_assert_visible_tutorial_continue(game,"ja","girl")
	var growth_message_index:int=game.first_play_tutorial_message_index
	game.tutorial_guide_button.pressed.emit()
	assert(game.first_play_tutorial_message_index==growth_message_index+1 and not game.first_play_tutorial_dialog_visible)
	var jelly_diameters: Array[float] = []
	for plant in game.plants:
		plant.fast_forward_to_diameter(game.FIRST_PLAY_TUTORIAL_JELLY_DIALOG_CM)
		jelly_diameters.append(float(plant.diameter_cm))
		assert(float(plant.diameter_cm) >= game.FIRST_PLAY_TUTORIAL_JELLY_DIALOG_CM, "fast-forward undershot jelly threshold: %.12f" % float(plant.diameter_cm))
	var jelly_wait_before_process: float = game.first_play_tutorial_wait_remaining
	assert(jelly_wait_before_process > 0.0)
	game._process(jelly_wait_before_process + .001)
	assert(game.first_play_tutorial_dialog_visible and game.tutorial_guide_message.text==Localizer.text("ja","tutorial_normal_jelly"), "jelly dialog missing: phase=%s index=%s wait=%.9f visible=%s overlay=%s fade=%s diameters=%s text=%s" % [game.first_play_tutorial_phase, game.first_play_tutorial_message_index, game.first_play_tutorial_wait_remaining, game.first_play_tutorial_dialog_visible, game.tutorial_guide_overlay.visible, game.scene_transition_fade.visible, jelly_diameters, game.tutorial_guide_message.text])
	await get_tree().process_frame
	_assert_visible_tutorial_continue(game,"ja","armadillo")
	var initially_spawned_count: int = game.endless_economy_seed_count
	var remaining_before_forced_jelly: int = game.play_seeds_remaining
	game.tutorial_continue_button.pressed.emit()
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
	await get_tree().process_frame
	_assert_visible_tutorial_continue(game,"ja","panda")
	game.tutorial_continue_button.pressed.emit()
	assert(game.first_play_tutorial_phase == "reserved_seed_sowing")
	await get_tree().create_timer(.36).timeout
	assert(game.endless_economy_seed_count == initially_spawned_count + 1)
	assert(game.play_seeds_remaining == remaining_before_forced_jelly - 1)
	assert(game.plants.size()+game.play_spawn_queue+game.play_seed_animations_pending<=game.ENDLESS_NORMAL_MAX_PLANTS)
	assert(game.first_play_tutorial_phase == "reserved_seed_observe")
	assert(is_instance_valid(game.first_play_tutorial_reserved_plant))
	var reserved_spawn_position:Vector3=game.first_play_tutorial_reserved_plant.original_pos
	assert(reserved_spawn_position.z>=game.FIRST_PLAY_TUTORIAL_FRONT_SPAWN_MIN_Z)
	assert(game._spawn_center_inside_soil(reserved_spawn_position))
	var front_position_rng:=RandomNumberGenerator.new();front_position_rng.seed=12012026
	var sampled_front_positions:Array[Vector3]=[]
	for sample_index in range(6):
		var sampled_position:Vector3=game._find_spawn_position(front_position_rng,true)
		assert(sampled_position.z>=game.FIRST_PLAY_TUTORIAL_FRONT_SPAWN_MIN_Z)
		assert(game._spawn_center_inside_soil(sampled_position))
		sampled_front_positions.append(sampled_position)
	var found_distinct_front_position:=false
	for sample_index in range(1,sampled_front_positions.size()):
		if sampled_front_positions[sample_index].distance_to(sampled_front_positions[0])>.05:
			found_distinct_front_position=true;break
	assert(found_distinct_front_position)
	var tutorial_harvest_species_id := str(game.first_play_tutorial_reserved_plant.data.get("species_id", ""))
	var tutorial_new_entry: Dictionary = game._catalog_entry(tutorial_harvest_species_id)
	assert(tutorial_harvest_species_id == game.first_play_tutorial_reserved_species_id)
	assert(bool(tutorial_new_entry.get("main_story_original", false)))
	assert(str(tutorial_new_entry.get("rarity", "")) == "通常")
	assert(game._species_get_count(tutorial_harvest_species_id) == 0)
	assert(not game.first_play_tutorial_reserved_plant.jelly_checks_enabled)
	var reserved_observe_start_cm: float = game.first_play_tutorial_reserved_plant.diameter_cm
	game._process(game.FIRST_PLAY_TUTORIAL_NEW_OBSERVE_SECONDS - .01)
	assert(not game.first_play_tutorial_dialog_visible)
	assert(game.first_play_tutorial_reserved_plant.diameter_cm > reserved_observe_start_cm)
	game._process(.02)
	assert(game.first_play_tutorial_dialog_visible)
	assert(game.tutorial_guide_message.text == "見て！\nはじめて見る品種が出てる！")
	await get_tree().process_frame
	_assert_visible_tutorial_continue(game,"ja","panda")
	game.tutorial_continue_button.pressed.emit()
	assert(game.first_play_tutorial_phase == "new_species_girl")
	assert(game.tutorial_guide_message.text == "ジュレる前に収穫しよう！")
	await get_tree().process_frame
	_assert_visible_tutorial_continue(game,"ja","girl")
	game.tutorial_guide_button.pressed.emit()
	assert(game.first_play_tutorial_sequence_complete)
	assert(game.first_play_harvest_guide_active)
	assert(game.tutorial_harvest_plant == game.first_play_tutorial_reserved_plant)
	assert(game.tutorial_guide_message.text == Localizer.text("ja", "tutorial_harvest_tap"))
	assert(game.tutorial_guide_overlay.visible)
	assert(not game.tutorial_continue_button.visible and not game.tutorial_continue_button.is_visible_in_tree())
	assert(not game.tutorial_portrait_slot.visible and not game.tutorial_speaker_label.visible and game.tutorial_speaker_label.text.is_empty())
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
	assert(game.tutorial_guide_message.text=="そうだ！育てた多肉は\nうちのお店で買い取るよ！")
	assert(game.tutorial_panda_portrait.visible)
	await get_tree().process_frame
	_assert_visible_tutorial_continue(game,"ja","panda")
	game.tutorial_continue_button.pressed.emit()
	assert(game.tutorial_guide_message.text=="大きい株ほど\n高く買い取るからね！")
	assert(game.tutorial_panda_portrait.visible)
	await get_tree().process_frame
	_assert_visible_tutorial_continue(game,"ja","panda")
	game.tutorial_guide_button.pressed.emit()
	assert(bool(game.first_play_harvest_spotlight_material.get_shader_parameter("focus_ellipse")))
	var puku_center: Vector2 = game.first_play_harvest_spotlight_material.get_shader_parameter("focus_uv_a")
	var puku_half_size: Vector2 = game.first_play_harvest_spotlight_material.get_shader_parameter("focus_half_size_uv")
	var seed_center: Vector2 = (game.seed_pod_gauge_area.global_position + game.seed_pod_gauge_area.size * .5) / game.get_viewport().get_visible_rect().size
	assert(((seed_center - puku_center) / puku_half_size).length() > 1.0)
	assert(game.tutorial_guide_message.text==Localizer.text("ja","puku_buyback_2_endless"))
	assert(not game.tutorial_panda_portrait.visible)
	await get_tree().process_frame
	_assert_visible_tutorial_continue(game,"ja","")
	game.tutorial_continue_button.pressed.emit()
	assert(game.puku_buyback_tutorial_complete and not game.puku_buyback_tutorial_active)
	assert(not game.tutorial_continue_button.visible)
	assert(not Localizer.text("ja","puku_buyback_2").contains("1ぷく未満"))
	assert(not game.first_seed_pod_reward_event_active and game.normal_seed_bags == 0 and is_zero_approx(game.puku_gauge_cm))

	# The scripted jelly and NEW harvest settled two seeds. This final section
	# deliberately drives the other settlements itself, so disable automatic
	# jelly checks on every currently growing plant before each manual tick.
	# Production rates stay untouched and are covered by jelly_dev_smoke; this
	# keeps this tutorial-flow test deterministic on slower CI machines too.
	assert(game.endless_economy_harvest_count == 1 and game.endless_economy_jelly_count == 1)
	var manual_settlements_remaining: int = game.NORMAL_GERMINATION_COUNT - game.endless_economy_harvest_count - game.endless_economy_jelly_count
	assert(manual_settlements_remaining == 10)
	for settlement_index in range(manual_settlements_remaining):
		var expected_settled_before: int = 2 + settlement_index
		var plant_ready: bool = await _wait_for_manual_settlement_plant(game, expected_settled_before)
		assert(plant_ready, "first normal round ended before all 12 seeds settled: reason=%s %s" % [manual_settlement_wait_failure, _first_normal_round_state(game, settlement_index)])
		_disable_automatic_jelly_for_current_plants(game)
		var plant_to_jelly = game.plants[0]
		assert(is_instance_valid(plant_to_jelly) and plant_to_jelly.state == "growing", "manual jelly target was not growing: %s" % _first_normal_round_state(game, settlement_index))
		plant_to_jelly.jelly()
		await get_tree().process_frame
		assert(game.endless_economy_harvest_count + game.endless_economy_jelly_count == expected_settled_before + 1, "manual settlement count did not advance exactly once: %s" % _first_normal_round_state(game, settlement_index))
	assert(await _wait_until(func()->bool:return not game.play_active and game._species_get_count(tutorial_harvest_species_id)==1 and game.species_get_overlay.visible), "automatic NEW reveal did not wait for/complete the Puku gauge queue: active=%s result=%s puku_running=%s puku_queue=%s plants=%s seeds_remaining=%s spawn_queue=%s" % [game.play_active, game.result_overlay.visible, game.puku_gauge_animation_running, game.puku_gauge_animation_queue.size(), game.plants.size(), game.play_seeds_remaining, game.play_spawn_queue])
	assert(game.endless_economy_seed_count == 12 and game.endless_economy_harvest_count == 1 and game.endless_economy_jelly_count == 11)
	assert(game.endless_economy_seed_cost_units == game.NORMAL_ROUND_COST_UNITS)
	assert(not game.result_overlay.visible and game.result_overlay.get_child_count() == 0)
	assert(game._species_get_count(tutorial_harvest_species_id) == 1)
	assert(bool(game.discovered.get(tutorial_harvest_species_id, false)))
	assert(bool(game.greenhouse_available.get(tutorial_harvest_species_id, false)))
	assert(game.species_get_overlay.visible)
	assert(game.species_get_overlay.badge_label.visible and game.species_get_overlay.badge_label.text == Localizer.text("ja", "new"))
	assert(game.species_get_overlay.name_label.text == Localizer.species_name("ja", tutorial_new_entry))
	assert(game.species_get_overlay.series_label.text == "原種")
	assert(not game.act2_unlocked)
	assert(not game.StoryProgressionClass.fantasy_is_unlocked(game.story_progression_state))
	assert(not bool(game.story_progression_state.get("original_new_guarantee_pending", false)))
	assert(not bool(game.story_progression_state.get("original_new_guarantee_consumed", false)))

	assert(Localizer.text("ja","puku_buyback_1") == "そうだ！育てた多肉は\nうちのお店で買い取るよ！")
	assert(Localizer.text("ja","puku_buyback_2") == "大きい株ほど\n高く買い取るからね！")
	print("FIRST_PLAY_TUTORIAL_SMOKE_OK old_colorata_growth=1.3 normal_growth=1.6 normal_kakuhen=true cost_note=removed button_cost_copy=preserved trio_cards=catalog_only pre_sow=true start_guide=play_open_normal tutorial_continue=9_pages_visible tutorial_speakers=8_correct+system_none button+fullscreen_single_step=true operation_prompt_continue=false forced_jelly=true reserved_original_new=true reserved_front_random=true observed_3s=true automatic_GET=true act2_guarantee_untouched=true total=12 settled=1_harvest+11_jelly result=removed")
	get_tree().quit()


func _wait_for_manual_settlement_plant(game:Node,expected_settled:int)->bool:
	manual_settlement_wait_failure=""
	var deadline_msec: int = Time.get_ticks_msec() + int(MANUAL_SETTLEMENT_PLANT_TIMEOUT_SECONDS * 1000.0)
	while Time.get_ticks_msec() < deadline_msec:
		_disable_automatic_jelly_for_current_plants(game)
		if game.plants.size()+game.play_spawn_queue+game.play_seed_animations_pending>game.ENDLESS_NORMAL_MAX_PLANTS:
			manual_settlement_wait_failure="scheduled population exceeded %s"%game.ENDLESS_NORMAL_MAX_PLANTS
			return false
		var settled_count: int = game.endless_economy_harvest_count + game.endless_economy_jelly_count
		if settled_count != expected_settled:
			manual_settlement_wait_failure="unexpected settlement count %s (expected %s)" % [settled_count,expected_settled]
			return false
		if not game.play_active:
			manual_settlement_wait_failure="play became inactive while waiting for a replacement plant"
			return false
		if not game.plants.is_empty():
			return true
		# The smoke disables Main._process() so it can drive tutorial thresholds
		# deterministically. Advance only a queued replacement here; the seed drop
		# tween itself is awaited by state instead of assuming it finishes in .32s.
		if game.play_spawn_queue>0 and game.play_seed_animations_pending==0:
			game.play_spawn_timer=0.0
			game._process(.01)
		await get_tree().process_frame
	manual_settlement_wait_failure="timed out after %.1fs waiting for a replacement plant or seed animation" % MANUAL_SETTLEMENT_PLANT_TIMEOUT_SECONDS
	return false


func _disable_automatic_jelly_for_current_plants(game:Node)->void:
	for remaining_plant in game.plants:
		if is_instance_valid(remaining_plant) and remaining_plant.state=="growing":
			remaining_plant.jelly_checks_enabled=false


func _first_normal_round_state(game:Node,settlement_index:int)->String:
	var plant_states:Array[String]=[]
	for plant in game.plants:
		if is_instance_valid(plant):plant_states.append(str(plant.state))
		else:plant_states.append("invalid")
	return "settlement_index=%s play_active=%s plants.size()=%s plant_states=%s play_seeds_remaining=%s play_spawn_queue=%s play_seed_animations_pending=%s harvest_count=%s jelly_count=%s seeds_used=%s target=%s planned=%s" % [settlement_index,game.play_active,game.plants.size(),plant_states,game.play_seeds_remaining,game.play_spawn_queue,game.play_seed_animations_pending,game.endless_economy_harvest_count,game.endless_economy_jelly_count,game.endless_economy_seed_count,game.play_concurrent_target,game.plants.size()+game.play_spawn_queue+game.play_seed_animations_pending]


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


func _assert_visible_tutorial_continue(game:Node,locale:String,speaker_id:String)->void:
	var button:=game.tutorial_continue_button as Button
	var panel:=game.tutorial_dialog_panel as Control
	var dialogue:=game.tutorial_guide_message as Label
	var portrait_slot:=game.tutorial_portrait_slot as Control
	var portrait:=game.tutorial_panda_portrait as TextureRect
	var speaker:=game.tutorial_speaker_label as Label
	var has_speaker:=not speaker_id.is_empty()
	assert(button.visible and button.is_visible_in_tree())
	assert(panel.visible and game.tutorial_guide_overlay.visible)
	assert(panel.is_ancestor_of(button))
	assert(game.tutorial_guide_button.get_index()<panel.get_index())
	assert(button.text==Localizer.text(locale,"continue"))
	assert(button.custom_minimum_size.is_equal_approx(StoryContinueButtonStyleClass.BUTTON_SIZE))
	assert(button.size.is_equal_approx(StoryContinueButtonStyleClass.BUTTON_SIZE))
	assert(panel.get_global_rect().grow(.5).encloses(button.get_global_rect()))
	assert(not button.get_global_rect().intersects(_visible_label_text_rect(dialogue)))
	assert(dialogue.get_line_count()*dialogue.get_line_height()<=dialogue.size.y+.5)
	assert(portrait_slot.visible==has_speaker)
	assert(portrait.visible==has_speaker)
	assert(speaker.visible==has_speaker)
	if has_speaker:
		assert(portrait_slot.is_visible_in_tree() and portrait.is_visible_in_tree() and speaker.is_visible_in_tree())
		assert(speaker.text==Localizer.text(locale,"story_speaker_"+speaker_id))
		assert(speaker.position.is_equal_approx(StandardStoryDialoguePanelClass.SPEAKER_LABEL_POSITION))
		assert(speaker.size.y==StandardStoryDialoguePanelClass.SPEAKER_LABEL_SIZE.y)
		assert(speaker.get_theme_font_size("font_size")==17)
		assert(speaker.get_theme_color("font_color").is_equal_approx(StandardStoryDialoguePanelClass.SPEAKER_COLOR))
		assert(speaker.get_line_height()<=speaker.size.y+.5)
		assert(portrait_slot.get_global_rect().grow(.5).encloses(speaker.get_global_rect()))
		assert(portrait_slot.get_global_rect().grow(.5).encloses(portrait.get_global_rect()))
		assert(speaker.get_global_rect().end.y<=portrait.get_global_rect().position.y+.5)
		assert(not portrait.get_global_rect().intersects(button.get_global_rect()))
		assert(not portrait.get_global_rect().intersects(dialogue.get_global_rect()))
	else:
		assert(speaker.text.is_empty())


func _visible_label_text_rect(label:Label)->Rect2:
	var content_height:=minf(label.size.y,float(label.get_line_count()*label.get_line_height()))
	var top:=label.global_position.y
	if label.vertical_alignment==VERTICAL_ALIGNMENT_CENTER:top+=(label.size.y-content_height)*.5
	elif label.vertical_alignment==VERTICAL_ALIGNMENT_BOTTOM:top+=label.size.y-content_height
	return Rect2(Vector2(label.global_position.x,top),Vector2(label.size.x,content_height))
