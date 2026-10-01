extends Node

const JureJureSystemClass = preload("res://scripts/jurejure_system.gd")
const StoryProgressionClass = preload("res://scripts/story_progression.gd")
const Localizer = preload("res://scripts/game_localizer.gd")
const JUREJURE_SPECIES_IDS: Array[String] = [
	"jurejure_pure_gold", "jurejure_guilty_burger", "jurejure_motemote",
	"jurejure_compressed_cash", "jurejure_chateaubriand", "jurejure_crown",
	"jurejure_luxury_watch", "jurejure_luxury_cruise_ship",
	"jurejure_pool_mansion", "jurejure_supercar"
]


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	await _test_habitat_group_and_intro(game)
	await _test_battle_win_and_respawn(game)
	await _test_battle_loss(game)
	_test_act_one_stays_hostile(game)
	_test_creative_gate(game)
	await _test_act_three_reward_flow(game)
	await _test_jurejure_crisis_threshold(game)
	await _test_external_crisis_transition(game)
	_test_first_loss_unlocks_act_two(game)
	await _test_save_compatibility(game)
	game._reset_progression_state()
	print("JUREJURE_STORY_SMOKE_OK group=three_close first_encounter=camera+bgm home_warning=once battle=active6_total12 act2_only=true exploitation=act3+choice+permanent midpoint=4+camera crisis=8 exploit_dialog=three-pattern-nonrepeat secret_gacha=disabled pool_unlock=all_10 ownership=exact reward=random save_fresh=true")
	get_tree().quit()


func _prepare_act_one(game: Node) -> void:
	game._reset_progression_state()
	game.opening_story_overlay.visible = false
	game.intro_overlay.visible = false
	game.habitat_unlocked = true
	game.intro_story_complete = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_tutorial_started = true
	game.habitat_tutorial_complete = true
	game.habitat_tutorial_returned_to_greenhouse = true
	game.mystery_items_acquired = true
	game.seed_shop_open = true
	game.puku_gauge_intro_complete = true
	game.original_catalog_gifted = true
	game.unlocked_series["base"] = true
	game.discovered = {"colorata": true, "affinis": true, "shaviana": true}
	game.species_get_counts = {"colorata": 1}
	game.habitat_returned_species = {"colorata": true, "affinis": true, "shaviana": true}
	game.habitat_wild_initialized = true
	game.habitat_wild_plants = _population(game, 10)
	game.current_mode = "greenhouse"
	game.jurejure_intro_complete = false
	game.jurejure_enabled = false
	game.jurejure_waiting_for_seed_pod_reward = false
	game.jurejure_pool_unlocked = false
	game.jurejure_species_unlocked.clear()
	game.habitat_second_awakened = false
	game.act2_unlocked = false
	game.forest_gacha_unlocked = false
	game.forest_gacha_intro_seen = false
	game._apply_mode()


func _test_habitat_group_and_intro(game: Node) -> void:
	_prepare_act_one(game)
	assert(game.audio_manager.current_bgm_key == "greenhouse")
	assert(JureJureSystemClass.should_be_present(true, true, false, false))
	assert(not JureJureSystemClass.should_be_present(true, true, false, true))
	assert(JureJureSystemClass.should_be_present(true, true, true, false))
	assert(JureJureSystemClass.should_be_present(true, true, true, true))
	game.jurejure_habitat_visit_point = Vector2(995, 418)
	game._toggle_mode()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.current_mode == "habitat")
	var group_item := _group_item(game)
	assert(not group_item.is_empty())
	var group := group_item.get("group_node") as Node3D
	assert(is_instance_valid(group))
	assert(group.get_node_or_null("Skunk") is Sprite3D)
	assert(group.get_node_or_null("Mouse") is Sprite3D)
	assert(group.get_node_or_null("Peccary") is Sprite3D)
	var skunk := group.get_node("Skunk") as Sprite3D
	var mouse := group.get_node("Mouse") as Sprite3D
	var peccary := group.get_node("Peccary") as Sprite3D
	assert(skunk.position.distance_to(mouse.position) > 1.25 and skunk.position.distance_to(mouse.position) < 1.75)
	assert(mouse.position.distance_to(peccary.position) > 1.25 and mouse.position.distance_to(peccary.position) < 1.80)
	assert(_count_named_nodes(game, "JureJureEventDisplay") == 0)
	assert(FileAccess.file_exists("res://assets/jurejure/mouse.png"))
	assert(FileAccess.file_exists("res://assets/jurejure/skunk.png"))
	assert(FileAccess.file_exists("res://assets/jurejure/peccary.png"))
	assert(FileAccess.file_exists("res://assets/jurejure/puku-puku-battle-background.jpg"))
	assert(FileAccess.file_exists("res://assets/story/jurejure-first-encounter.jpg"))

	# The first habitat entry starts with Panda noticing the gang. Only after the
	# camera captures them does their theme begin and the event still fade in.
	assert(game.scripted_dialog_kind == "jurejure_first_notice")
	assert(game.intro_dialogue_label.text == Localizer.text("ja", "jurejure_first_notice"))
	assert(game.jurejure_first_encounter_active and game.audio_manager.current_bgm_key == "habitat")
	game._advance_scripted_dialog()
	await get_tree().process_frame
	assert(game.jurejure_intro_camera_active)
	var camera_start_yaw: float = game.view_yaw
	game._update_habitat_view_follow(.41)
	assert(game.jurejure_intro_camera_active and not is_equal_approx(game.view_yaw, camera_start_yaw))
	game._update_habitat_view_follow(.41)
	assert(not game.jurejure_intro_camera_active and game.audio_manager.current_bgm_key == "jurejure")
	for _frame in range(90):
		if game.jurejure_first_encounter_overlay.visible:
			break
		await get_tree().process_frame
	assert(game.jurejure_first_encounter_overlay.visible and game.jurejure_first_encounter_overlay.transitioning)
	assert(game.jurejure_first_encounter_overlay.STORY_TEXTURE.get_size() == Vector2(720,1280))
	for _frame in range(90):
		if not game.jurejure_first_encounter_overlay.transitioning:
			break
		await get_tree().process_frame
	assert(not game.jurejure_first_encounter_overlay.transitioning)
	var expected_speakers := ["peccary", "skunk", "mouse"]
	var expected_keys := ["jurejure_first_peccary", "jurejure_first_skunk", "jurejure_first_mouse"]
	for page_index in range(3):
		assert(game.jurejure_first_encounter_overlay.page_index == page_index)
		assert(game.jurejure_first_encounter_overlay.dialogue_label.text == Localizer.text("ja", expected_keys[page_index]))
		assert(game.jurejure_first_encounter_overlay.SPEAKER_IDS[page_index] == expected_speakers[page_index])
		game.jurejure_first_encounter_overlay.advance()
		for _frame in range(90):
			if page_index < 2 and not game.jurejure_first_encounter_overlay.transitioning:
				break
			if page_index == 2 and not game.jurejure_first_encounter_overlay.visible:
				break
			await get_tree().process_frame
	assert(not game.jurejure_first_encounter_overlay.visible)
	assert(game.scripted_dialog_kind == "jurejure_intro")
	assert(game.audio_manager.current_bgm_key == "jurejure")
	var all_text := ""
	for page in game.scripted_dialog_pages:
		all_text += str(page.get("text", ""))
	assert("勝手に持っていくなよ" in all_text)
	assert("絶滅したのよ" in all_text)
	assert("ぷくぷくバトル" in all_text)
	assert("定期的に原生地へ行こう" not in all_text)
	assert(str(game.scripted_dialog_pages[-1].get("text", "")) == Localizer.text("ja", "jurejure_confront_mouse_battle"))
	assert("まだ小さい" not in all_text)
	assert("守ってるわけじゃない" not in all_text)
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.jurejure_intro_complete and game.jurejure_enabled)
	assert(game.puku_puku_battle.visible)
	assert(game.puku_puku_battle.choice_layer.visible)
	assert(not game.puku_puku_battle.battle_active)
	assert(game.audio_manager.current_bgm_key == "jurejure")
	game.puku_puku_battle._decline_battle()
	assert(not game.puku_puku_battle.visible)
	assert(game.audio_manager.current_bgm_key == "habitat")
	assert(not _group_item(game).is_empty())
	assert(bool(game.story_progression_state.get("post_encounter_greenhouse_pending", false)))
	game._toggle_mode();await get_tree().process_frame;await get_tree().process_frame
	assert(game.current_mode == "greenhouse" and game.scripted_dialog_kind == "post_jurejure_encounter_home")
	assert(game.scripted_dialog_pages.size() == 2)
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == Localizer.text("ja", "jurejure_after_encounter_panda"))
	assert(str(game.scripted_dialog_pages[1].get("text", "")) == Localizer.text("ja", "jurejure_after_encounter_armadillo"))
	_finish_dialog(game)
	assert(bool(game.story_progression_state.get("post_encounter_greenhouse_seen", false)))
	game._toggle_mode();await get_tree().process_frame
	assert(game.current_mode == "habitat" and game.scripted_dialog_kind.is_empty() and not game.jurejure_first_encounter_overlay.visible)

	game._on_jurejure_group_pressed()
	assert(game.scripted_dialog_kind == "jurejure_challenge")
	assert(game.audio_manager.current_bgm_key == "jurejure")
	assert(game.scripted_dialog_pages.size() == 2)
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.puku_puku_battle.choice_layer.visible)
	assert(game.audio_manager.current_bgm_key == "jurejure")

	var position_samples := {}
	var position_rng := RandomNumberGenerator.new()
	position_rng.seed = 20260926
	for sample in range(24):
		var point := JureJureSystemClass.choose_visit_point([], position_rng)
		assert(point in JureJureSystemClass.HABITAT_GROUP_POINTS)
		position_samples[str(point)] = true
	assert(position_samples.size() > 1)


func _test_battle_win_and_respawn(game: Node) -> void:
	var pre_reward_ids: Array[String] = []
	for entry in game._jurejure_reward_candidates():
		pre_reward_ids.append(str(entry.get("species_id", "")))
	assert("affinis" in pre_reward_ids and "shaviana" in pre_reward_ids)
	game.puku_puku_battle._accept_battle()
	await get_tree().process_frame
	assert(game.audio_manager.current_bgm_key == "puku_battle")
	assert(game.puku_puku_battle.visible and not game.puku_puku_battle.battle_active)
	assert(game.puku_puku_battle.battle_phase == "awaiting_sow")
	assert(game.puku_puku_battle.units.is_empty())
	assert(game.puku_puku_battle.sow_button.visible)
	assert(is_equal_approx(game.puku_puku_battle.player_score, 0.0))
	assert(is_equal_approx(game.puku_puku_battle.opponent_score, 0.0))
	game.puku_puku_battle.debug_sow_immediately()
	assert(game.puku_puku_battle.battle_active)
	assert(game.puku_puku_battle.battle_phase == "growing")
	assert(game.puku_puku_battle.units.size() == game.puku_puku_battle.MAX_ACTIVE_PER_SIDE * 2)
	var player_units := 0
	var opponent_units := 0
	for unit in game.puku_puku_battle.units:
		if bool(unit.get("opponent", false)):
			opponent_units += 1
		else:
			player_units += 1
	assert(player_units == 6 and opponent_units == 6)
	assert(game.puku_puku_battle.player_spawned == 6 and game.puku_puku_battle.opponent_spawned == 6)
	assert(game.puku_puku_battle.battle_layer.get_node_or_null("BattleBackground") is TextureRect)

	game.puku_puku_battle.debug_force_result(420.0, 180.0)
	await get_tree().process_frame
	assert(game.audio_manager.current_bgm_key == "puku_battle")
	assert(game.jurejure_waiting_for_seed_pod_reward)
	assert(game.jurejure_battle_count == 1 and game.jurejure_battle_win_count == 1)
	assert(game.act2_unlocked and not game.forest_gacha_unlocked and not game.forest_gacha_intro_seen)
	assert(not game.StoryProgressionClass.fantasy_is_unlocked(game.story_progression_state))
	assert(game.main_story_stage == game.StoryProgressionClass.ACT_2)
	var reward_id: String = game.jurejure_pending_reward_species_id
	assert(not reward_id.is_empty())
	assert(bool(game._catalog_entry(reward_id).get("main_story_original",false)))
	assert(bool(game.discovered.get(reward_id, false)))
	assert(int(game.species_get_counts.get(reward_id, 0)) == 1)
	assert(bool(game.habitat_returned_species.get(reward_id, false)))
	assert(game.jurejure_return_event_complete == false)
	assert(game.habitat_second_awakened == false)
	assert(_group_item(game).is_empty())

	game.puku_puku_battle._return_to_habitat()
	assert(game.audio_manager.current_bgm_key == "habitat")
	assert(game.scripted_dialog_kind == "jurejure_battle_win")
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.species_get_overlay.visible)
	while game.species_get_overlay.busy:
		await get_tree().process_frame
	await game.species_get_overlay.close_overlay()

	# Formal endless progression releases the early JureJure wait on the next
	# completed 12-plant discovery set, while normal seed bags remain unlimited.
	game.play_active = true
	game.active_seed_type = "normal"
	var bags_before: int = game.normal_seed_bags
	var settlement_result: Dictionary
	for index in range(game.endless_greenhouse.DISCOVERY_SET_SIZE):
		settlement_result = game._record_endless_discovery_settlement(false, 0.0, 1.0)
	assert(bool(settlement_result.get("set_completed", false)))
	assert(game.normal_seed_bags == bags_before)
	assert(not game.jurejure_waiting_for_seed_pod_reward)
	game._toggle_mode()
	await get_tree().process_frame
	assert(game.current_mode=="greenhouse" and game.scripted_dialog_kind.is_empty())
	assert(not game.forest_gacha_intro_seen and not game.forest_gacha_button.visible)
	game._toggle_mode()
	await get_tree().process_frame
	assert(not _group_item(game).is_empty())


func _test_battle_loss(game: Node) -> void:
	game.puku_points = 1
	game.habitat_wild_plants = _population(game, 10)
	var settled_before: Dictionary = game.habitat_returned_species.duplicate(true)
	assert(game.current_mode=="habitat")
	assert(game._should_show_jurejure_group())
	assert(game.scripted_dialog_kind.is_empty() and not game.jurejure_first_encounter_active)
	assert(not game.puku_puku_battle.visible)
	game._on_jurejure_group_pressed()
	assert(game.scripted_dialog_kind == "jurejure_challenge")
	_finish_dialog(game)
	await get_tree().process_frame
	game.puku_puku_battle._accept_battle()
	await get_tree().process_frame
	assert(game.audio_manager.current_bgm_key == "puku_battle")
	assert(game.puku_puku_battle.units.is_empty())
	game.puku_puku_battle.debug_sow_immediately()
	game.puku_puku_battle.debug_force_result(20.0, 260.0)
	await get_tree().process_frame
	var remaining: int = game.habitat_wild_plants.size()
	assert(remaining >= 2 and remaining <= 6)
	assert(game.puku_points == 0)
	assert(game.habitat_returned_species == settled_before)
	assert(not game.jurejure_waiting_for_seed_pod_reward)
	assert(not _group_item(game).is_empty())
	game.puku_puku_battle._return_to_habitat()
	assert(game.audio_manager.current_bgm_key == "habitat")
	assert(game.scripted_dialog_kind == "jurejure_battle_loss")
	_finish_dialog(game)
	await get_tree().process_frame

	game.puku_points = 0
	game.habitat_wild_plants = _population(game, 5)
	var zero_penalty: Dictionary = game._apply_jurejure_battle_loss()
	assert(int(zero_penalty.get("puku_lost", -1)) == 0)
	assert(game.puku_points == 0)


func _test_act_one_stays_hostile(game: Node) -> void:
	game.scripted_dialog_kind = ""
	game.jurejure_growth_event_mask = 0
	game._start_jurejure_growth_event(JureJureSystemClass.GROWTH_MID)
	game._start_jurejure_growth_event(JureJureSystemClass.GROWTH_LATE)
	assert(game.scripted_dialog_kind.is_empty())
	assert(game.jurejure_growth_event_mask == 3)


func _test_save_compatibility(game: Node) -> void:
	game.habitat_second_awakened = false
	game.habitat_second_awakening_complete = false
	game.act2_unlocked = false
	game.forest_gacha_unlocked = false
	game.forest_gacha_intro_seen = false
	game.jurejure_intro_complete = true
	game.jurejure_enabled = true
	game.jurejure_waiting_for_seed_pod_reward = true
	game.jurejure_battle_count = 7
	game.jurejure_battle_win_count = 4
	game.active_jurejure_event = {"individual_id": "legacy_target", "deadline_unix": 1.0}
	game._save()
	game.jurejure_waiting_for_seed_pod_reward = false
	game.jurejure_battle_count = 0
	game.jurejure_battle_win_count = 0
	game.active_jurejure_event = {"individual_id": "stale"}
	game._load_save()
	assert(game.jurejure_waiting_for_seed_pod_reward)
	assert(game.jurejure_battle_count == 7)
	assert(game.jurejure_battle_win_count == 4)
	assert(game.active_jurejure_event.is_empty())
	assert(game.act2_unlocked and not game.forest_gacha_unlocked)


func _test_creative_gate(game: Node) -> void:
	game.habitat_second_awakened = false
	game.act2_unlocked = false
	game.discovered = {"colorata": true}
	game.greenhouse_available = {"colorata": true}
	game.unlocked_series["base"] = true
	game.unlocked_series["metal"] = true
	var original: Dictionary = game._catalog_entry("colorata")
	var creative: Dictionary = game._catalog_entry("metal_laui")
	assert(not original.is_empty() and not creative.is_empty())
	assert(game._species_available_in_current_era(original))
	assert(not game._species_available_in_current_era(creative))
	game.discovered["metal_laui"] = true
	assert(game._species_available_in_current_era(creative))
	game.discovered.erase("metal_laui")
	game.habitat_second_awakened = true
	assert(not game._species_available_in_current_era(creative))
	game.act2_unlocked = true
	game.story_progression_state["fantasy_unlocked"] = true
	assert(game._species_available_in_current_era(creative))
	var official_entry: Dictionary = game._catalog_entry(JUREJURE_SPECIES_IDS[0])
	assert(game._is_jurejure_species(official_entry) and game._is_fantasy_species(official_entry))
	assert(not game._species_available_in_current_era(official_entry))
	assert(not game._register_species_discovery(JUREJURE_SPECIES_IDS[0], true))
	game.act3_intro_seen = true
	var candidates: Array[Dictionary] = game._jurejure_reward_candidates()
	assert(candidates.size() == 10)
	for entry in candidates:
		assert(str(entry.get("species_id", "")) in JUREJURE_SPECIES_IDS)
	game.act3_intro_seen = false


func _prepare_act_three_reward(game: Node) -> void:
	_prepare_act_one(game)
	game.jurejure_intro_complete = true
	game.jurejure_enabled = true
	game.act2_unlocked = true
	game.story_progression_state["fantasy_unlocked"] = true
	game.forest_gacha_unlocked = true
	game.forest_gacha_intro_seen = true
	game.fantasy_first_discovery_seen = true
	game.fantasy_realization_seen = true
	game.story_progression_state["arrangement_unlocked"] = true
	game.story_progression_state["arrangement_intro_seen"] = true
	game.story_progression_state["arrangement_intro_pending"] = false
	game.act3_unlocked = true
	game.act3_intro_pending = false
	game.act3_intro_seen = true
	StoryProgressionClass.begin_exploitation(game.story_progression_state, game._unique_jurejure_species_get_count())
	# These tests exercise repeat exploitation battles; the dedicated one-time
	# Act III camera introduction is covered by story_progression_smoke.
	StoryProgressionClass.complete_act3_battle_intro(game.story_progression_state)
	game.current_mode = "habitat"
	game._update_main_story_progress(false)
	game._apply_mode()
	assert(game.audio_manager.current_bgm_key == "jurejure")


func _test_act_three_reward_flow(game: Node) -> void:
	# Repeated fresh candidate sets must exercise more than one branch of the
	# real grant function; Pure Gold is neither fixed nor preferred.
	_prepare_act_three_reward(game)
	var sampled: Dictionary = {}
	for sample_seed in range(1, 17):
		game.jurejure_pool_unlocked = false
		game.jurejure_species_unlocked.clear()
		game.unlocked_series.erase("jurejure")
		for species_id in JUREJURE_SPECIES_IDS:
			game.discovered.erase(species_id);game.species_get_counts.erase(species_id)
			game.greenhouse_available.erase(species_id);game.unlocked_species.erase(species_id)
		game.rng.seed = sample_seed
		var sampled_id: String = game._grant_jurejure_battle_reward()
		assert(sampled_id in JUREJURE_SPECIES_IDS)
		sampled[sampled_id] = true
	assert(sampled.size() > 1)
	assert(sampled.keys().any(func(species_id: Variant) -> bool: return str(species_id) != "jurejure_pure_gold"))

	_prepare_act_three_reward(game)
	var first_candidates: Array[Dictionary] = game._jurejure_reward_candidates()
	assert(first_candidates.size() == 10)
	game.rng.seed = 20260927
	assert(game._should_show_jurejure_group())
	game._on_jurejure_group_pressed()
	assert(game.scripted_dialog_kind == "jurejure_exploitation_challenge")
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.puku_puku_battle.visible and game.puku_puku_battle.choice_layer.visible)
	game.puku_puku_battle._accept_battle()
	await get_tree().process_frame
	game.puku_puku_battle.debug_sow_immediately()
	game.puku_puku_battle.debug_force_result(420.0, 180.0)
	await get_tree().process_frame
	assert(not game.jurejure_waiting_for_seed_pod_reward)
	assert(game._should_show_jurejure_group() and not _group_item(game).is_empty())
	var reward_id: String = game.jurejure_pending_reward_species_id
	assert(reward_id in JUREJURE_SPECIES_IDS)
	assert(game.jurejure_pool_unlocked)
	assert(bool(game.discovered.get(reward_id, false)) and game._species_get_count(reward_id) == 1)
	assert(not bool(game.habitat_returned_species.get(reward_id, false)))
	assert(game.jurejure_species_unlocked.size() == 10)
	for species_id in JUREJURE_SPECIES_IDS:
		assert(game._is_jurejure_species_unlocked(species_id))
		if species_id != reward_id:
			assert(not bool(game.discovered.get(species_id, false)))
			assert(game._species_get_count(species_id) == 0)
	var normal_route_candidates: Array[Dictionary] = game._series_seed_draw_candidates("jurejure")
	assert(normal_route_candidates.size() == 10)
	var forest_route_candidates: Array[Dictionary] = game.forest_gacha_system.eligible_species("jurejure", true, game.jurejure_species_unlocked)
	assert(forest_route_candidates.size() == 10)
	var remaining: Array[Dictionary] = game._jurejure_reward_candidates()
	assert(remaining.size() == 9)
	for entry in remaining:
		assert(str(entry.get("species_id", "")) != reward_id)

	game.puku_puku_battle._return_to_habitat()
	assert(game.scripted_dialog_kind == "jurejure_battle_win")
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.species_get_overlay.visible)
	assert(game.species_get_overlay.name_label.text == str(game._catalog_entry(reward_id).get("name_ja", "")))
	assert(game.species_get_overlay.result_image.texture != null)
	while game.species_get_overlay.busy:
		await get_tree().process_frame
	await game.species_get_overlay.close_overlay()
	for _frame in range(120):
		if game.scripted_dialog_kind == "jurejure_species_first":
			break
		await get_tree().process_frame
	assert(game.scripted_dialog_kind == "jurejure_species_first")
	assert(game.scripted_dialog_pages.size() == 3)
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == "なにこの多肉！？")
	assert(str(game.scripted_dialog_pages[1].get("text", "")) == "ジュレジュレ団の頭の中がそのまま多肉になってるようだね……。")
	assert(str(game.scripted_dialog_pages[2].get("text", "")) == "……。")
	_finish_dialog(game)
	assert(game.jurejure_species_first_seen)

	# A genuinely fresh instance recovers the pool gate, while ownership remains
	# exact: only the actually awarded species is marked GET/discovered.
	game._save()
	var fresh_game = load("res://main.tscn").instantiate()
	add_child(fresh_game)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(fresh_game.jurejure_pool_unlocked and fresh_game.jurejure_species_unlocked.size() == 10)
	assert(fresh_game._species_get_count(reward_id) == 1 and bool(fresh_game.discovered.get(reward_id, false)))
	for species_id in JUREJURE_SPECIES_IDS:
		assert(fresh_game._is_jurejure_species_unlocked(species_id))
		if species_id != reward_id:
			assert(fresh_game._species_get_count(species_id) == 0)
			assert(not bool(fresh_game.discovered.get(species_id, false)))
	fresh_game.queue_free()
	await get_tree().process_frame

	# Exploitation starts at the Act III intro, so a victory and an old pod-wait
	# flag can no longer remove the gang before the eight-species rain crisis.
	game.jurejure_waiting_for_seed_pod_reward = true
	assert(game._should_show_jurejure_group())
	assert(not game.habitat_crisis_started)
	game._build_habitat_items(true)
	assert(not _group_item(game).is_empty())


func _test_jurejure_crisis_threshold(game: Node) -> void:
	_prepare_act_three_reward(game)
	# This case isolates the exploitation encounter. The separate first-Jure
	# acquisition flow is covered above and must not pre-empt this dialogue.
	game.jurejure_species_first_seen = true
	assert(StoryProgressionClass.exploitation_is_started(game.story_progression_state))
	assert(game._unlock_jurejure_pool())
	for index in range(3):
		game._register_species_discovery(JUREJURE_SPECIES_IDS[index], true)
	assert(game._unique_jurejure_species_get_count() == 3)
	assert(not game.habitat_crisis_pending and not game.habitat_crisis_started)
	game.jurejure_waiting_for_seed_pod_reward = true
	assert(game._should_show_jurejure_group())
	# Normal visit reactions retain the one-in-three frequency, but the eligible
	# visit now samples its phase pool rather than deriving an index from visit_id.
	var sampled_early_keys: Dictionary = {}
	var early_keys: Array[String] = []
	for pattern in JureJureSystemClass.EXPLOITATION_EARLY_VISIT_PATTERNS:
		early_keys.append(str(pattern.get("text_key", "")))
	var late_keys: Array[String] = []
	for pattern in JureJureSystemClass.EXPLOITATION_LATE_VISIT_PATTERNS:
		late_keys.append(str(pattern.get("text_key", "")))
	for sample_seed in range(1, 25):
		var sample_state := StoryProgressionClass.default_runtime_state()
		var sample_rng := RandomNumberGenerator.new()
		sample_rng.seed = sample_seed
		var sampled := JureJureSystemClass.concern_for_visit(sample_state, 3, false, sample_rng)
		assert(str(sampled.get("text_key", "")) in early_keys)
		sampled_early_keys[str(sampled.get("text_key", ""))] = true
	assert(sampled_early_keys.size() > 1)
	var concern_state := StoryProgressionClass.default_runtime_state()
	var concern_rng := RandomNumberGenerator.new()
	concern_rng.seed = 20260929
	assert(JureJureSystemClass.concern_for_visit(concern_state, 1, false, concern_rng).is_empty())
	var first_concern := JureJureSystemClass.concern_for_visit(concern_state, 3, false, concern_rng)
	var second_concern := JureJureSystemClass.concern_for_visit(concern_state, 6, false, concern_rng)
	assert(not first_concern.is_empty() and not second_concern.is_empty())
	assert(str(first_concern.get("text_key", "")) != str(second_concern.get("text_key", "")))
	var late_concern := JureJureSystemClass.concern_for_visit(concern_state, 9, true, concern_rng)
	assert(str(late_concern.get("text_key", "")) in late_keys)
	var dialog_rng := RandomNumberGenerator.new()
	dialog_rng.seed = 20260928
	var first_pattern := JureJureSystemClass.choose_exploitation_dialog(-1, dialog_rng)
	var second_pattern := JureJureSystemClass.choose_exploitation_dialog(int(first_pattern.get("index", -1)), dialog_rng)
	assert(int(first_pattern.get("index", -1)) != int(second_pattern.get("index", -1)))
	assert((first_pattern.get("pages", []) as Array).size() == 3 and (second_pattern.get("pages", []) as Array).size() == 3)
	assert(JureJureSystemClass.EXPLOITATION_DIALOG_PATTERNS.size() == 3)
	assert(str(JureJureSystemClass.EXPLOITATION_DIALOG_PATTERNS[0][0].get("text_key", "")) == "jurejure_exploit_touch_mouse_more")
	assert(str(JureJureSystemClass.EXPLOITATION_DIALOG_PATTERNS[1][0].get("text_key", "")) == "jurejure_exploit_touch_peccary_more")
	assert(str(JureJureSystemClass.EXPLOITATION_DIALOG_PATTERNS[2][0].get("text_key", "")) == "jurejure_exploit_touch_skunk_price")
	game._build_habitat_items(true)
	game._on_jurejure_group_pressed()
	assert(game.scripted_dialog_kind == "jurejure_exploitation_challenge")
	var first_live_pattern := int(game.story_progression_state.get("last_exploitation_dialog_index", -1))
	assert(game.scripted_dialog_pages.size() == 3)
	_finish_dialog(game)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.puku_puku_battle.visible and game.puku_puku_battle.choice_layer.visible)
	assert(not game.puku_puku_battle.battle_active)
	game.puku_puku_battle._decline_battle()
	assert(game.current_mode == "habitat")
	assert(game.scripted_dialog_kind.is_empty())
	assert(game.audio_manager.current_bgm_key == "jurejure")
	assert(game._should_show_jurejure_group())
	assert(not game.jurejure_first_encounter_active)
	game._on_jurejure_group_pressed()
	assert(game.scripted_dialog_kind == "jurejure_exploitation_challenge")
	assert(int(game.story_progression_state.get("last_exploitation_dialog_index", -1)) != first_live_pattern)
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.puku_puku_battle.visible and game.puku_puku_battle.choice_layer.visible)
	game.puku_puku_battle._decline_battle()

	# Four unique GETs schedule the one-off midpoint, but rain remains off.
	game._register_species_discovery(JUREJURE_SPECIES_IDS[3], true)
	assert(game._unique_jurejure_species_get_count() == 4)
	assert(bool(game.story_progression_state.get("exploitation_midpoint_pending", false)))
	assert(not game.habitat_crisis_pending and not game.habitat_crisis_started)
	await get_tree().process_frame
	assert(game.jurejure_intro_camera_active and game.jurejure_camera_focus_context == "exploitation_midpoint")
	assert(game.scripted_dialog_kind.is_empty())
	game._update_habitat_view_follow(1.0)
	await get_tree().process_frame
	assert(game.scripted_dialog_kind == "exploitation_midpoint")
	assert(game.scripted_dialog_pages.size() == 6)
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == Localizer.text("ja", "habitat_exploit_midpoint_panda_1"))
	assert(str(game.scripted_dialog_pages[5].get("text", "")) == Localizer.text("ja", "habitat_exploit_midpoint_mouse_2"))
	_finish_dialog(game)
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind.is_empty())
	assert(not StoryProgressionClass.secret_gacha_feature_enabled())
	assert(StoryProgressionClass.peek_story_event(game.story_progression_state) != StoryProgressionClass.EVENT_SECRET_GACHA_INSTALL)
	assert(not StoryProgressionClass.secret_gacha_is_unlocked(game.story_progression_state))
	assert(not game.secret_gacha_button.visible)
	assert(not game.habitat_crisis_started)

	for index in range(4, 7):
		game._register_species_discovery(JUREJURE_SPECIES_IDS[index], true)
	assert(game._unique_jurejure_species_get_count() == 7)
	assert(not game.habitat_crisis_pending and not game.habitat_crisis_started)
	# Mirror the safe boundary of a real habitat battle: while its full-screen UI
	# is open the deferred story check cannot pre-empt the reward card. Closing
	# that eighth Species GET card starts rain in this same habitat stay.
	game.puku_puku_battle.visible = true
	game._register_species_discovery(JUREJURE_SPECIES_IDS[7], true)
	assert(game._unique_jurejure_species_get_count() == 8)
	assert(game.habitat_crisis_pending and not game.habitat_crisis_started)
	assert(StoryProgressionClass.habitat_crisis_route(game.story_progression_state) == StoryProgressionClass.CRISIS_ROUTE_SAME_HABITAT)
	await get_tree().process_frame
	assert(not game.habitat_crisis_started)
	game.puku_puku_battle.visible = false
	game._queue_species_get_by_id(JUREJURE_SPECIES_IDS[7], true, "jurejure_battle")
	await get_tree().process_frame
	assert(game.species_get_overlay.visible)
	while game.species_get_overlay.busy:
		await get_tree().process_frame
	assert(not game.habitat_crisis_started)
	game._register_species_discovery(JUREJURE_SPECIES_IDS[0], true)
	assert(game._unique_jurejure_species_get_count() == 8)
	for index in range(8, 10):
		game._register_species_discovery(JUREJURE_SPECIES_IDS[index], true)
	assert(game._jurejure_reward_candidates().size() == 10)
	var total_gets_before := 0
	for species_id in JUREJURE_SPECIES_IDS:total_gets_before += game._species_get_count(species_id)
	var repeat_id: String = game._grant_jurejure_battle_reward()
	var total_gets_after := 0
	for species_id in JUREJURE_SPECIES_IDS:total_gets_after += game._species_get_count(species_id)
	assert(repeat_id in JUREJURE_SPECIES_IDS and total_gets_after == total_gets_before + 1)

	game.species_get_overlay.close_overlay()
	while game.species_get_overlay.visible:
		await get_tree().process_frame
	await get_tree().process_frame
	# Eight unique species begin the distinct rain/crisis phase without a
	# greenhouse round trip. Tapping the
	# resident gang then produces one subdued line only: the crisis theme stays
	# active and no Jure theme, choice, or battle can be started.
	assert(game.habitat_crisis_started and game.audio_manager.current_bgm_key == "habitat_crisis")
	assert(game.jurejure_intro_camera_active)
	game._update_habitat_view_follow(1.0)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.scripted_dialog_kind == "habitat_crisis")
	assert(game.scripted_dialog_pages.size() == 6)
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == Localizer.text("ja", "habitat_crisis_armadillo_1"))
	assert(str(game.scripted_dialog_pages[5].get("text", "")) == Localizer.text("ja", "habitat_crisis_skunk"))
	_finish_dialog(game)
	await get_tree().process_frame
	assert(bool(game.story_progression_state.get("post_crisis_greenhouse_pending", false)))
	assert(not bool(game.story_progression_state.get("post_crisis_greenhouse_seen", false)))
	assert(not game.puku_puku_battle.visible)
	game._on_jurejure_group_pressed()
	assert(game.scripted_dialog_kind == "jurejure_crisis_unavailable")
	assert(game.intro_dialogue_label.text == Localizer.text("ja", "habitat_crisis_no_battle"))
	assert(game.audio_manager.current_bgm_key == "habitat_crisis")
	_finish_dialog(game)
	await get_tree().process_frame
	assert(not game.puku_puku_battle.visible)
	assert(game.audio_manager.current_bgm_key == "habitat_crisis")
	game._toggle_mode()
	await get_tree().process_frame
	assert(game.current_mode == "greenhouse" and game.audio_manager.current_bgm_key == "greenhouse")
	if game.scripted_dialog_kind == "post_crisis_greenhouse":
		_finish_dialog(game)
		await get_tree().process_frame
	game._toggle_mode()
	await get_tree().process_frame
	assert(game.current_mode == "habitat" and game.audio_manager.current_bgm_key == "habitat_crisis")


func _test_external_crisis_transition(game: Node) -> void:
	_prepare_act_three_reward(game)
	game.jurejure_species_first_seen = true
	assert(game._unlock_jurejure_pool())
	game.current_mode = "greenhouse"
	game._apply_mode()
	for index in range(7):
		game._register_species_discovery(JUREJURE_SPECIES_IDS[index], true)
	assert(game._unique_jurejure_species_get_count() == 7)
	# The Species card may close before Today's Harvest. The pending route must
	# wait for both, then present Panda's line instead of silently jumping modes.
	game.result_overlay.visible = true
	game._register_species_discovery(JUREJURE_SPECIES_IDS[7], true)
	assert(game.habitat_crisis_pending and not game.habitat_crisis_started)
	assert(StoryProgressionClass.habitat_crisis_route(game.story_progression_state) == StoryProgressionClass.CRISIS_ROUTE_FORCE_TRAVEL)
	game._queue_species_get_by_id(JUREJURE_SPECIES_IDS[7], true, "main_result")
	await get_tree().process_frame
	while game.species_get_overlay.busy:
		await get_tree().process_frame
	game.species_get_overlay.close_overlay()
	while game.species_get_overlay.visible:
		await get_tree().process_frame
	await get_tree().process_frame
	assert(game.scripted_dialog_kind.is_empty() and game.result_overlay.visible)
	game._close_result()
	await get_tree().process_frame
	assert(game.scripted_dialog_kind == "habitat_crisis_departure")
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == Localizer.text("ja", "habitat_crisis_departure_panda"))
	assert(game.current_mode == "greenhouse")
	_finish_dialog(game)
	await get_tree().create_timer(1.2).timeout
	assert(game.current_mode == "habitat" and game.habitat_crisis_started)
	assert(game.jurejure_intro_camera_active)
	game._update_habitat_view_follow(1.0)
	await get_tree().process_frame
	assert(game.scripted_dialog_kind == "habitat_crisis")
	_finish_dialog(game)


func _test_first_loss_unlocks_act_two(game: Node) -> void:
	_prepare_act_one(game)
	game.puku_points=1
	game._on_puku_puku_battle_resolved({"won":false,"player_score":10.0,"opponent_score":20.0})
	assert(game.jurejure_battle_count==1 and game.jurejure_battle_win_count==0)
	assert(game.act2_unlocked and not game.forest_gacha_unlocked and not game.forest_gacha_intro_seen)
	assert(game.main_story_stage==game.StoryProgressionClass.ACT_2)


func _group_item(game: Node) -> Dictionary:
	for item in game.habitat_pickups:
		if str(item.get("kind", "")) == "jurejure_group":
			return item
	return {}


func _count_named_nodes(root: Node, target_name: String) -> int:
	var count := 1 if root.name == target_name else 0
	for child in root.get_children():
		count += _count_named_nodes(child, target_name)
	return count


func _finish_dialog(game: Node) -> void:
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()


func _population(game: Node, count: int) -> Array[Dictionary]:
	var source: Array = []
	var valid_species_ids: Array[String] = ["colorata"]
	var now := Time.get_unix_time_from_system()
	for index in range(count):
		source.append(_plant("battle_target_%02d" % index, 8.0 + float(index), now, index))
	return game.HabitatWildSystemClass.normalize_saved(source, valid_species_ids, now)


func _plant(individual_id: String, diameter: float, now: float, index: int) -> Dictionary:
	return {
		"individual_id": individual_id,
		"species_id": "colorata",
		"diameter_cm": diameter,
		"jellied": false,
		"tutorial": false,
		"jelly_immune": false,
		"story_protected": false,
		"base_growth_rate": 1.0,
		"jelly_risk_curve": 1.0,
		"mature_diameter_cm": 30.8,
		"jelly_threshold": 999999.0,
		"jelly_hazard_accumulated": 0.0,
		"jelly_elapsed_seconds": 0.0,
		"last_updated_unix": now,
		"spawned_unix": now,
		"habitat_timing_version": 3,
		"panorama_x": 90.0 + float(index) * 105.0,
		"panorama_y": 405.0 + float(index % 3) * 11.0,
		"position_validated": true
	}
