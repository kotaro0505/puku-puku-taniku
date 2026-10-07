extends Node

const HabitatRestorationClass = preload("res://scripts/habitat_restoration.gd")
const HabitatRestorationUIClass = preload("res://scripts/habitat_restoration_ui.gd")
const StoryProgressionClass = preload("res://scripts/story_progression.gd")
const JureJureSystemClass = preload("res://scripts/jurejure_system.gd")
const Localizer = preload("res://scripts/game_localizer.gd")


func _ready() -> void:
	_test_restoration_state_machine()
	_test_localization_contract()
	_test_ending_asset_contract()
	await _test_integrated_final_chapter()
	print("HABITAT_RESTORATION_SMOKE_OK post_crisis=4 sow_gate=retired first_large_before_join=true queued_returns=true joined_after_first=true lamps=5 threshold=100 returned=5 medals=5 stages=0..5 slides=3 finale=true epilogue=true ending_records=5 returned_recap=5 final_image=true ending_bgm=true post_ending_greenhouse_once=true lifetime_harvest=true save_resume=true")
	get_tree().quit()


func _test_restoration_state_machine() -> void:
	var legacy_runtime := StoryProgressionClass.normalize_runtime_state({"version": 7})
	assert(StoryProgressionClass.lifetime_harvest_count(legacy_runtime) == 0)
	assert(is_zero_approx(StoryProgressionClass.lifetime_harvest_cm_total(legacy_runtime)))
	StoryProgressionClass.record_greenhouse_harvest(legacy_runtime, 12.5)
	StoryProgressionClass.record_greenhouse_harvest(legacy_runtime, 27.75)
	assert(StoryProgressionClass.lifetime_harvest_count(legacy_runtime) == 2)
	assert(is_equal_approx(StoryProgressionClass.lifetime_harvest_cm_total(legacy_runtime), 40.25))
	var progression := StoryProgressionClass.default_runtime_state()
	StoryProgressionClass.begin_habitat_crisis(progression)
	var restoration: Dictionary = StoryProgressionClass.restoration_state(progression)
	assert(bool(restoration.get("tracking_started", false)))
	assert(not StoryProgressionClass.record_restoration_new_get(progression, "colorata", true))
	assert(not StoryProgressionClass.record_restoration_new_get(progression, "affinis", true))
	assert(not StoryProgressionClass.record_restoration_new_get(progression, "shaviana", true))
	assert(HabitatRestorationClass.new_species_count(restoration) == 3)
	assert(not bool(restoration.get("join_home_pending", false)))
	var before_crisis := StoryProgressionClass.default_runtime_state()
	assert(not StoryProgressionClass.record_normal_seed_sown_after_crisis(before_crisis, false, 48))
	assert(HabitatRestorationClass.seeds_sown_since_crisis(StoryProgressionClass.restoration_state(before_crisis)) == 0)
	assert(not StoryProgressionClass.record_normal_seed_sown_after_crisis(progression, true, 47))
	assert(HabitatRestorationClass.seeds_sown_since_crisis(restoration) == 47)
	assert(not bool(restoration.get("join_home_pending", false)))
	assert(not StoryProgressionClass.record_normal_seed_sown_after_crisis(progression, true, 1))
	assert(HabitatRestorationClass.seeds_sown_since_crisis(restoration) == 48)
	assert(not StoryProgressionClass.record_normal_seed_sown_after_crisis(progression, true, 1))
	assert(HabitatRestorationClass.seeds_sown_since_crisis(restoration) == 49)
	# The legacy sow count is telemetry only and can never queue the retired
	# pre-return join conversation.
	assert(StoryProgressionClass.peek_story_event(progression).is_empty())
	progression["post_crisis_greenhouse_pending"] = true
	StoryProgressionClass.complete_post_crisis_greenhouse(progression)
	assert(StoryProgressionClass.peek_story_event(progression).is_empty())
	assert(HabitatRestorationClass.large_plant_mission_started(restoration))
	assert(not StoryProgressionClass.restoration_is_started(progression))

	assert(not HabitatRestorationClass.can_offer_return(restoration, 99.99))
	assert(HabitatRestorationClass.can_offer_return(restoration, 100.0))
	var snapshot := {
		"species_id": "colorata",
		"display_name": "コロラータ",
		"diameter_cm": 100.0,
		"visual_scale": 5.9,
		"rarity": "通常",
		"gold_star_count": 0,
	}
	assert(HabitatRestorationClass.returned_count(restoration) == 0)
	assert(HabitatRestorationClass.queue_pending_return_snapshot(restoration, snapshot))
	assert(HabitatRestorationClass.returned_count(restoration) == 0)
	assert(HabitatRestorationClass.pending_return_count(restoration) == 1)
	assert(HabitatRestorationClass.commit_next_pending_return(restoration) == 1)
	assert(HabitatRestorationClass.returned_count(restoration) == 1)
	HabitatRestorationClass.complete_return_event(restoration, 1)
	StoryProgressionClass.complete_restoration_join_habitat(progression)
	assert(StoryProgressionClass.restoration_is_started(progression))
	for index in range(1, 5):
		var plant := snapshot.duplicate(true)
		plant["diameter_cm"] = 100.0 + float(index) * 20.0
		assert(HabitatRestorationClass.add_returned_plant(restoration, plant) == index + 1)
		assert(HabitatRestorationClass.pending_return_stage(restoration) == 2)
	assert(HabitatRestorationClass.pending_return_stages(restoration) == [2, 3, 4, 5])
	for stage in range(2, 6):
		assert(HabitatRestorationClass.pending_return_stage(restoration) == stage)
		HabitatRestorationClass.complete_return_event(restoration, stage)
	assert(HabitatRestorationClass.pending_return_stages(restoration).is_empty())
	assert(HabitatRestorationClass.returned_count(restoration) == 5)
	var returned: Array = HabitatRestorationClass.returned_plants(restoration)
	assert(str(returned[0].get("species_id", "")) == "colorata")
	assert(is_equal_approx(float(returned[0].get("diameter_cm", 0.0)), 100.0))
	assert(is_equal_approx(float(returned[4].get("diameter_cm", 0.0)), 180.0))
	# The rain does not fully clear before the ending slides reveal recovery.
	assert(HabitatRestorationClass.restoration_stage(restoration) == 4)
	HabitatRestorationClass.begin_recovery_slides(restoration)
	assert(HabitatRestorationClass.ending_phase(restoration) == "slides")
	HabitatRestorationClass.reveal_full_recovery(restoration)
	assert(HabitatRestorationClass.restoration_stage(restoration) == 5)
	assert(HabitatRestorationClass.ending_phase(restoration) == "final")
	assert(JureJureSystemClass.habitat_bgm_key(true, true, true) == "habitat")
	HabitatRestorationClass.mark_final_dialog_complete(restoration)
	assert(HabitatRestorationClass.ending_phase(restoration) == "epilogue")
	HabitatRestorationClass.mark_epilogue_complete(restoration)
	assert(HabitatRestorationClass.ending_phase(restoration) == "thank_you")
	assert(HabitatRestorationClass.jurejure_interaction_phase(restoration) == HabitatRestorationClass.JUREJURE_PHASE_POST_ENDING)
	var post_ending_rng := RandomNumberGenerator.new()
	post_ending_rng.seed = 41017
	var post_ending_first := JureJureSystemClass.choose_post_ending_dialog(-1, post_ending_rng)
	var post_ending_second := JureJureSystemClass.choose_post_ending_dialog(int(post_ending_first.get("index", -1)), post_ending_rng)
	assert(int(post_ending_first.get("index", -1)) != int(post_ending_second.get("index", -1)))

	var reloaded := StoryProgressionClass.normalize_runtime_state(progression.duplicate(true), {
		"habitat_crisis_started": true,
	})
	var restored_state: Dictionary = StoryProgressionClass.restoration_state(reloaded)
	assert(HabitatRestorationClass.seeds_sown_since_crisis(restored_state) == 49)
	assert(HabitatRestorationClass.returned_count(restored_state) == 5)
	assert(HabitatRestorationClass.ending_phase(restored_state) == "thank_you")
	HabitatRestorationClass.complete_ending(restored_state)
	assert(bool(restored_state.get("ending_seen", false)))
	assert(bool(restored_state.get("thank_you_seen", false)))
	assert(not HabitatRestorationClass.post_ending_greenhouse_dialog_seen(restored_state))
	HabitatRestorationClass.mark_post_ending_greenhouse_dialog_seen(restored_state)
	assert(HabitatRestorationClass.post_ending_greenhouse_dialog_seen(restored_state))
	assert(not HabitatRestorationClass.should_show_progress(restored_state))
	var legacy_completed := HabitatRestorationClass.normalize_state({
		"version": 4,
		"returned_plants": returned,
		"full_recovery_revealed": true,
		"ending_phase": "complete",
		"ending_seen": true,
		"thank_you_seen": true,
	})
	assert(HabitatRestorationClass.post_ending_greenhouse_dialog_seen(legacy_completed))


func _test_localization_contract() -> void:
	var keys := [
		"mission_title",
		"mission_first_large",
		"mission_return_large",
		"restoration_join_home_armadillo",
		"restoration_join_mouse_hurry",
		"habitat_crisis_departure_panda",
		"restoration_jurejure_hurry",
		"jurejure_post_ending_mouse_sprout",
		"jurejure_post_ending_mouse_water",
		"jurejure_post_ending_mouse_patrol",
		"jurejure_post_ending_peccary_patrol",
		"jurejure_post_ending_peccary_chateaubriand",
		"jurejure_post_ending_peccary_growth",
		"jurejure_post_ending_skunk_value",
		"jurejure_post_ending_skunk_fee",
		"jurejure_post_ending_skunk_land",
		"jurejure_post_ending_mouse_restricted",
		"jurejure_post_ending_peccary_sprouts",
		"jurejure_post_ending_skunk_club",
		"restoration_lamp_title",
		"restoration_return_confirm",
		"restoration_return_1_armadillo",
		"restoration_return_1_girl",
		"restoration_return_2_girl",
		"restoration_return_3_girl_2",
		"restoration_return_4_panda",
		"restoration_return_5_system",
		"restoration_return_5_girl",
		"restoration_slide_1",
		"restoration_slide_2",
		"restoration_slide_3",
		"restoration_final_girl_2",
		"restoration_epilogue_mouse",
		"post_ending_greenhouse_girl_1",
		"post_ending_greenhouse_panda_1",
		"post_ending_greenhouse_armadillo",
		"post_ending_greenhouse_girl_2",
		"post_ending_greenhouse_girl_3",
		"post_ending_greenhouse_girl_4",
		"post_ending_greenhouse_panda_2",
		"restoration_record_harvested",
		"restoration_record_size",
		"restoration_record_catalog",
		"restoration_record_battles",
		"restoration_record_wins",
		"restoration_returned_plant_heading",
		"restoration_thank_you",
		"restoration_product_by",
	]
	for language in ["ja", "hiragana", "en"]:
		for key in keys:
			var value := Localizer.text(language, key)
			assert(not value.is_empty() and value != key)


func _test_ending_asset_contract() -> void:
	var audio_config: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio-config.json"))
	assert(audio_config is Dictionary)
	var bgm_config: Dictionary = (audio_config as Dictionary).get("bgm", {}) as Dictionary
	assert(str(bgm_config.get("ending", "")) == "res://assets/audio/ending-pssshh-new-batch.mp3")
	var ending_stream := load("res://assets/audio/ending-pssshh-new-batch.mp3") as AudioStream
	assert(ending_stream is AudioStreamMP3)
	var ending_texture := load(HabitatRestorationUIClass.FINAL_IMAGE_PATH) as Texture2D
	assert(ending_texture != null and ending_texture.get_size() == Vector2(720, 1280))
	assert(HabitatRestorationUIClass.ENDING_FINAL_IMAGE_HOLD_SECONDS >= 4.0)


func _test_integrated_final_chapter() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	game._reset_progression_state()
	game.opening_finished = true
	game.opening_overlay.visible = false
	game.opening_story_overlay.visible = false
	game.intro_overlay.visible = false
	game.result_overlay.visible = false
	game.play_overlay.visible = false
	game.current_mode = "greenhouse"
	game.habitat_unlocked = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_tutorial_complete = true
	game.habitat_tutorial_returned_to_greenhouse = true
	game.puku_gauge_intro_complete = true
	game.story_progression_state = StoryProgressionClass.default_runtime_state()
	game.play_active = true
	game.active_seed_type = "normal"
	game.habitat_crisis_started = false
	assert(not game._record_normal_greenhouse_seed_sown())
	game.habitat_crisis_started = true
	game.active_seed_type = "old"
	assert(not game._record_normal_greenhouse_seed_sown())
	game.active_seed_type = "normal"
	game.dev_jelly_test_active = true
	assert(not game._record_normal_greenhouse_seed_sown())
	game.dev_jelly_test_active = false
	game.catalog_preview_mode_active = true
	assert(not game._record_normal_greenhouse_seed_sown())
	game.catalog_preview_mode_active = false
	assert(game._record_normal_greenhouse_seed_sown())
	assert(HabitatRestorationClass.seeds_sown_since_crisis(game._restoration_state()) == 1)
	game.play_active = false
	game.habitat_crisis_started = true
	game.story_progression_state = StoryProgressionClass.default_runtime_state()
	StoryProgressionClass.begin_habitat_crisis(game.story_progression_state)
	game.story_progression_state["post_crisis_greenhouse_pending"] = true
	game._start_post_crisis_greenhouse_event()
	assert(game.scripted_dialog_kind == "post_crisis_greenhouse")
	assert(game.scripted_dialog_pages.size() == 4)
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == "原生地を元に戻すには、どうしたらいいんだろう……。")
	assert(str(game.scripted_dialog_pages[2].get("text", "")) == "じゃあ、とにかく大きな株を作って持っていってみない？")
	assert(str(game.scripted_dialog_pages[3].get("text", "")) == "うん。やってみよう！")
	_finish_dialog(game)
	var restoration: Dictionary = game._restoration_state()
	assert(HabitatRestorationClass.large_plant_mission_started(restoration))
	assert(game._current_mission_text() == "100cm以上の多肉を5株、原生地へ還そう！　0/5")

	for species_id in ["colorata", "affinis", "shaviana"]:
		StoryProgressionClass.record_restoration_new_get(game.story_progression_state, species_id, true)
	assert(StoryProgressionClass.peek_story_event(game.story_progression_state).is_empty())
	assert(not StoryProgressionClass.record_normal_seed_sown_after_crisis(game.story_progression_state, true, 47))
	assert(not StoryProgressionClass.record_normal_seed_sown_after_crisis(game.story_progression_state, true, 1))
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind.is_empty())
	assert(not StoryProgressionClass.restoration_is_started(game.story_progression_state))

	for stage in range(1, 6):
		var pages: Array[Dictionary] = game._restoration_return_pages(stage)
		assert(pages.size() == [3, 5, 7, 7, 2][stage - 1])
	assert(Localizer.text("ja", "restoration_return_1_girl") == "さぁ、もっとここへ多肉を持ってこよう！")
	assert(Localizer.text("ja", "restoration_return_2_armadillo") == "届いてくれるといいな…")
	assert(Localizer.text("ja", "restoration_return_4_armadillo") == "少し明るくなってきた")
	assert(Localizer.text("ja", "restoration_return_4_mouse") == "頼むから早く元気になれチュー！")
	assert(Localizer.text("ja", "restoration_return_4_panda") == "…")
	assert(Localizer.text("hiragana", "restoration_return_2_armadillo") == "とどいてくれると いいな…")
	assert(Localizer.text("hiragana", "restoration_return_4_mouse") == "たのむから はやく げんきになれチュー！")
	assert(Localizer.text("en", "restoration_return_1_girl") == "Come on, let's bring more succulents here!")
	assert(Localizer.text("en", "restoration_return_4_panda") == "...")
	assert(str(game._restoration_return_pages(5)[0].get("text", "")) == "これで5株目だよ。")
	assert(str(game._restoration_return_pages(5)[1].get("text", "")) == "5株の多肉を原生地に還した！")

	var snapshot := {
		"species_id": "colorata",
		"display_name": "コロラータ",
		"diameter_cm": 120.0,
		"visual_scale": 7.0,
		"rarity": "通常",
		"gold_star_count": 0,
	}
	# A real harvest queues every eligible 100cm plant. It does not commit or
	# interrupt the twelve-seed round before the result card closes.
	game.discovered["colorata"] = true
	game.species_get_counts["colorata"] = 1
	game.first_colorata_confirmed = true
	game.intro_story_complete = true
	game.total_play_count = 4
	game.formal_play_count = 4
	game.normal_play_tutorial_complete = true
	game.puku_buyback_tutorial_complete = true
	game.mystery_items_acquired = true
	game.play_active = false
	game._spawn_specific_plant("colorata")
	var jellied_plant = game.plants.back()
	jellied_plant.fast_forward_to_diameter(118.0)
	game._on_jellied(jellied_plant)
	assert(StoryProgressionClass.lifetime_harvest_count(game.story_progression_state) == 0)
	assert(is_zero_approx(StoryProgressionClass.lifetime_harvest_cm_total(game.story_progression_state)))
	game.play_active = true
	game.active_seed_type = "normal"
	game.play_seeds_remaining = 2
	game.play_spawn_queue = 0
	game.play_seed_animations_pending = 0
	for diameter in [120.0, 130.0]:
		game._spawn_specific_plant("colorata")
		var harvested_plant = game.plants.back()
		harvested_plant.fast_forward_to_diameter(diameter)
		game._on_harvested(harvested_plant)
	assert(StoryProgressionClass.lifetime_harvest_count(game.story_progression_state) == 2)
	assert(is_equal_approx(StoryProgressionClass.lifetime_harvest_cm_total(game.story_progression_state), 250.0))
	restoration = game._restoration_state()
	assert(HabitatRestorationClass.returned_count(restoration) == 0)
	assert(HabitatRestorationClass.pending_return_count(restoration) == 2)
	assert(HabitatRestorationClass.pending_return_stages(restoration).is_empty())
	assert(not game.habitat_restoration_ui.prompt_layer.visible)
	assert(game.current_mode == "greenhouse" and game.scripted_dialog_kind.is_empty())
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not game.result_overlay.visible and game.current_mode == "greenhouse" and game.play_active)
	assert(game.scripted_dialog_kind.is_empty())
	# The result modal owns the foreground. Only its close may release the queued
	# automatic habitat transition.
	game.play_active = false
	game.result_overlay.visible = true
	game._try_start_pending_story_event()
	assert(game.current_mode == "greenhouse")
	game._close_result()
	await get_tree().create_timer(1.4).timeout
	assert(not game.result_overlay.visible and game.current_mode == "habitat", "return transition mode=%s dialog=%s fade=%s pending=%s" % [game.current_mode, game.scripted_dialog_kind, game.scene_transition_fade.visible, HabitatRestorationClass.pending_return_stages(game._restoration_state())])
	assert(game.scripted_dialog_kind == "restoration_return_1", "unexpected rooted event: %s pending=%s" % [game.scripted_dialog_kind, HabitatRestorationClass.pending_return_stages(game._restoration_state())])
	assert(game.jurejure_camera_focus_context == "restoration_return_1")
	var first_medal:Node3D=game._restoration_returned_plant_node(1)
	assert(is_instance_valid(first_medal))
	assert(int(first_medal.get_meta("restoration_stage",0))==1)
	assert(is_equal_approx(float((first_medal.get_meta("restoration_snapshot",{}) as Dictionary).get("diameter_cm",0.0)),120.0))
	_finish_dialog(game)
	await get_tree().create_timer(1.0).timeout
	assert(game.scripted_dialog_kind == "restoration_join_habitat")
	assert(game.scripted_dialog_pages.size() == 19)
	assert(str(game.scripted_dialog_pages[0].get("text", "")).begins_with("はぁー"))
	assert("早くするんだチュー" in str(game.scripted_dialog_pages[18].get("text", "")))
	_finish_dialog(game)
	await get_tree().process_frame
	assert(StoryProgressionClass.restoration_is_started(game.story_progression_state))
	# The second plant was queued in the same round and is committed as soon as
	# the join dialog closes, so the live mission has already advanced to 2/5.
	assert(game._current_mission_text() == "100cm以上の多肉を5株、原生地へ還そう！　2/5")
	assert(game.scripted_dialog_kind == "restoration_return_2")
	assert(game.jurejure_camera_focus_context == "restoration_return_2")
	var second_medal:Node3D=game._restoration_returned_plant_node(2)
	assert(is_equal_approx(float((second_medal.get_meta("restoration_snapshot",{}) as Dictionary).get("diameter_cm",0.0)),130.0))
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.current_mode == "habitat")
	await get_tree().create_timer(.9).timeout
	restoration = game._restoration_state()
	assert(HabitatRestorationClass.pending_return_stages(restoration).is_empty())
	assert(HabitatRestorationClass.pending_return_count(restoration) == 0)
	assert(game.habitat_restoration_ui.lamp_labels.size() == 5)
	# Fill stages three and four while already in the habitat. The pending event
	# queue must preserve their chronological order.
	var later_species := ["shaviana", "affinis"]
	for index in range(2, 4):
		var plant := snapshot.duplicate(true)
		plant["species_id"] = later_species[index - 2]
		plant["display_name"] = Localizer.species_name("ja", game._catalog_entry(str(plant["species_id"])))
		plant["diameter_cm"] = 115.0 + 15.0 * float(index)
		assert(HabitatRestorationClass.add_returned_plant(restoration, plant) == index + 1)
	game._try_start_pending_story_event()
	await get_tree().process_frame
	assert(game.scripted_dialog_kind=="restoration_return_3")
	_finish_dialog(game);await get_tree().process_frame
	assert(game.scene_transition_fade.visible and game.scene_transition_fade.color.r<.01)
	await get_tree().create_timer(1.16).timeout
	assert(game.scripted_dialog_kind=="restoration_return_4")
	_finish_dialog(game);await get_tree().process_frame
	assert(HabitatRestorationClass.pending_return_stages(restoration).is_empty())
	# Let the once-per-visit group focus finish before leaving the habitat.
	await get_tree().create_timer(.9).timeout
	game._toggle_mode();await get_tree().process_frame
	assert(game.current_mode=="greenhouse")
	var final_plant:=snapshot.duplicate(true)
	final_plant["species_id"]="laui"
	final_plant["display_name"]=Localizer.species_name("ja",game._catalog_entry("laui"))
	final_plant["diameter_cm"]=175.0
	assert(HabitatRestorationClass.queue_pending_return_snapshot(restoration,final_plant))
	game.story_progression_state["restoration"] = restoration
	game._try_start_pending_story_event()
	await get_tree().process_frame
	assert(game.scene_transition_fade.visible,"final return did not start: mode=%s pending=%s dialog=%s intro=%s camera=%s result=%s"%[game.current_mode,HabitatRestorationClass.pending_return_stages(restoration),game.scripted_dialog_kind,game.intro_overlay.visible,game.jurejure_intro_camera_active,game.result_overlay.visible])
	assert(game.scene_transition_fade.color.r>0.99 and game.scene_transition_fade.color.g>0.99 and game.scene_transition_fade.color.b>0.99)
	await get_tree().create_timer(2.8).timeout
	assert(game.current_mode=="habitat")
	assert(game.scripted_dialog_kind=="restoration_return_5")
	assert(game.habitat_items_root.find_children("RestorationMedalPlant*","Sprite3D",true,false).size()==5)
	assert(is_equal_approx(float((game._restoration_returned_plant_node(3).get_meta("restoration_snapshot",{}) as Dictionary).get("diameter_cm",0.0)),145.0))
	assert(is_equal_approx(float((game._restoration_returned_plant_node(4).get_meta("restoration_snapshot",{}) as Dictionary).get("diameter_cm",0.0)),160.0))
	assert(game.jurejure_camera_focus_context=="restoration_return_5")
	assert(is_equal_approx(float((game._restoration_returned_plant_node(5).get_meta("restoration_snapshot",{}) as Dictionary).get("diameter_cm",0.0)),175.0))
	_finish_dialog(game)
	await get_tree().create_timer(1.2).timeout
	assert(game.habitat_restoration_ui.ending_layer.visible)
	game.habitat_restoration_ui.reset_view()
	game.habitat_restoration_ui.update_lamps(5, true)
	for lamp in game.habitat_restoration_ui.lamp_labels:
		assert(lamp.text == "●")

	game.current_mode = "habitat"
	game._apply_mode()
	game._build_habitat_items(true)
	var medals: Array[Node] = []
	for child in game.habitat_items_root.get_children():
		if child.name.begins_with("RestorationMedalPlant"):
			medals.append(child)
	assert(medals.size() == 5)
	assert(medals[4].scale.x > medals[0].scale.x)
	game.habitat_crisis_atmosphere.activate()
	game.habitat_crisis_atmosphere.set_habitat_visible(true)
	game.habitat_crisis_atmosphere.set_restoration_stage(3)
	assert(game.habitat_crisis_atmosphere.visible)
	assert(game.habitat_items_root.find_children("RestorationWildSprout*", "Sprite3D", true, false).size() >= 1)
	HabitatRestorationClass.begin_recovery_slides(restoration)
	HabitatRestorationClass.reveal_full_recovery(restoration)
	game.habitat_crisis_atmosphere.set_restoration_stage(5)
	assert(not game.habitat_crisis_atmosphere.visible)
	assert(game._should_show_jurejure_group())
	# This integrated test jumps over the normal first-notice path; discard that
	# unrelated deferred dialog before exercising the post-ending interaction.
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.intro_overlay.visible = false
	# The real story can only reach restoration after the first encounter. This
	# test assembles the late-game state directly, so restore that prerequisite
	# explicitly before checking the post-ending interaction.
	game.jurejure_intro_complete = true
	game.jurejure_enabled = true
	HabitatRestorationClass.mark_final_dialog_complete(restoration)
	HabitatRestorationClass.mark_epilogue_complete(restoration)
	await get_tree().create_timer(.9).timeout
	game._on_jurejure_group_pressed()
	assert(game.scripted_dialog_kind == "jurejure_post_ending", "post-ending tap failed: dialog=%s camera=%s context=%s battle=%s mode=%s" % [game.scripted_dialog_kind, game.jurejure_intro_camera_active, game.jurejure_camera_focus_context, game.puku_puku_battle.visible, game.current_mode])
	assert(game.scripted_dialog_pages.size() == 1)
	var first_post_ending_text := str(game.scripted_dialog_pages[0].get("text", ""))
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.puku_puku_battle.visible and game.puku_puku_battle.choice_layer.visible)
	game.puku_puku_battle._decline_battle()
	game._on_jurejure_group_pressed()
	assert(game.scripted_dialog_kind == "jurejure_post_ending")
	assert(str(game.scripted_dialog_pages[0].get("text", "")) != first_post_ending_text)
	_finish_dialog(game)
	await get_tree().process_frame
	game.puku_puku_battle._decline_battle()

	game._start_restoration_final_event()
	assert(game.scripted_dialog_pages.size() == 4)
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == "戻ったね……。")
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.intro_overlay.visible = false
	game._start_restoration_epilogue_event()
	assert(game.scripted_dialog_pages.size() == 6)
	assert("SDGs" in str(game.scripted_dialog_pages[2].get("text", "")))
	assert(game.audio_manager.current_bgm_key != "ending")
	game._advance_scripted_dialog()
	assert(game.audio_manager.current_bgm_key != "ending")
	game._advance_scripted_dialog()
	assert(game.audio_manager.current_bgm_key == "ending")
	assert(is_equal_approx(game.audio_manager.last_bgm_fade_seconds, 2.5))
	game.species_get_counts["affinis"] = 2
	game.jurejure_battle_count = 7
	game.jurejure_battle_win_count = 4
	var ending_bgm_requests := {"count": 0}
	game.habitat_restoration_ui.ending_bgm_requested.connect(func() -> void: ending_bgm_requests["count"] = int(ending_bgm_requests["count"]) + 1)
	game.habitat_restoration_ui.ending_sequence_time_scale = 0.005
	# Finish the real epilogue path. Every remaining speaker, the generic
	# dialog cleanup, and the deferred ending sequence must preserve the track
	# that started on Peccary's SDGs line.
	game.audio_manager.last_bgm_fade_seconds = 9.75
	for expected_page in range(3, 6):
		game._advance_scripted_dialog()
		assert(game.scripted_dialog_index == expected_page)
		assert(game.audio_manager.current_bgm_key == "ending")
	game._advance_scripted_dialog()
	assert(game.scripted_dialog_kind.is_empty())
	assert(game.audio_manager.current_bgm_key == "ending")
	assert(is_equal_approx(game.audio_manager.last_bgm_fade_seconds, 9.75))
	await get_tree().process_frame
	assert(game.habitat_restoration_ui.ending_sequence_layer.visible)
	assert(not game.habitat_restoration_ui.ending_layer.visible)
	assert(not game.habitat_restoration_ui.ending_current_phase.is_empty())
	assert(game.audio_manager.current_bgm_key == "ending")
	for _frame in range(240):
		if game.habitat_restoration_ui.ending_current_phase == "await_return":
			break
		await get_tree().process_frame
	assert(game.habitat_restoration_ui.ending_current_phase == "await_return")
	assert(int(ending_bgm_requests["count"]) == 1)
	assert(game.audio_manager.current_bgm_key == "ending")
	assert(is_equal_approx(game.audio_manager.last_bgm_fade_seconds, 9.75))
	var record_events: Array[Dictionary] = []
	var plant_events: Array[Dictionary] = []
	for event_value in game.habitat_restoration_ui.ending_sequence_history:
		var event := event_value as Dictionary
		if str(event.get("kind", "")) == "record": record_events.append(event)
		elif str(event.get("kind", "")) == "plant": plant_events.append(event)
	assert(record_events.size() == 5)
	assert(str((record_events[0].get("payload", {}) as Dictionary).get("text", "")).contains("2株"))
	assert(str((record_events[1].get("payload", {}) as Dictionary).get("text", "")).contains("250cm"))
	assert(str((record_events[2].get("payload", {}) as Dictionary).get("text", "")).contains("2種"))
	assert(str((record_events[3].get("payload", {}) as Dictionary).get("text", "")).contains("7回"))
	assert(str((record_events[4].get("payload", {}) as Dictionary).get("text", "")).contains("4回"))
	assert(plant_events.size() == 5)
	var returned_snapshots := HabitatRestorationClass.returned_plants(game._restoration_state())
	for index in 5:
		var payload := plant_events[index].get("payload", {}) as Dictionary
		var expected := returned_snapshots[index] as Dictionary
		assert(str(payload.get("species_id", "")) == str(expected.get("species_id", "")))
		assert(is_equal_approx(float(payload.get("diameter_cm", 0.0)), float(expected.get("diameter_cm", 0.0))))
		assert(not str(payload.get("display_name", "")).is_empty())
		assert(not str(payload.get("image_path", "")).is_empty())
	assert(game.habitat_restoration_ui.ending_final_image.visible)
	assert(game.habitat_restoration_ui.ending_final_image.texture != null)
	assert(game.habitat_restoration_ui.ending_final_image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert(game.habitat_restoration_ui.ending_final_text_group.visible)
	assert(game.habitat_restoration_ui.ending_return_button.visible and not game.habitat_restoration_ui.ending_return_button.disabled)
	assert(game.habitat_restoration_ui.ending_thank_you_label.text == Localizer.text(game.language_code, "restoration_thank_you"))
	assert(game.habitat_restoration_ui.ending_product_label.text == Localizer.text(game.language_code, "restoration_product_by"))
	game.habitat_restoration_ui.ending_return_button.pressed.emit()
	await get_tree().create_timer(game.ENDING_BGM_FADE_OUT_SECONDS + 0.15).timeout
	assert(HabitatRestorationClass.ending_phase(game._restoration_state())=="complete")
	assert(game.current_mode == "greenhouse")
	assert(game.audio_manager.current_bgm_key == "greenhouse")
	assert(is_equal_approx(game.audio_manager.last_bgm_fade_seconds, game.ENDING_BGM_FADE_OUT_SECONDS))
	assert(not game.habitat_restoration_ui.ending_sequence_layer.visible)
	assert(not game.habitat_restoration_ui.lamp_panel.visible)
	assert(game.scripted_dialog_kind == "post_ending_greenhouse")
	var expected_post_ending_greenhouse_lines := [
		"原生地、元気になって良かったね",
		"ジュレジュレ団も、ジュレジュレ団なりにがんばってたしね",
		"うん。みんなで戻したんだ",
		"この先もずっと、多肉植物がある世界だといいね",
		"よーし",
		"これからも、いっぱいたね蒔こ！",
		"まだまだ、僕たちの多肉植物の世界は始まったばかりだ！",
	]
	assert(game.scripted_dialog_pages.size() == expected_post_ending_greenhouse_lines.size())
	for index in expected_post_ending_greenhouse_lines.size():
		assert(str(game.scripted_dialog_pages[index].get("text", "")) == expected_post_ending_greenhouse_lines[index])
	assert(HabitatRestorationClass.post_ending_greenhouse_dialog_seen(game._restoration_state()))
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.scripted_dialog_kind.is_empty())
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind.is_empty())
	assert(not game._resume_restoration_ending())
	game.current_mode="habitat";game._apply_mode();game._build_habitat_items(true)
	assert(game.habitat_items_root.find_children("RestorationMedalPlant*","Sprite3D",true,false).size()==5)
	game.free()
	await get_tree().process_frame


func _finish_dialog(game: Node) -> void:
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
