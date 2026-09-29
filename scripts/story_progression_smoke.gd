extends Node

const StoryProgressionClass = preload("res://scripts/story_progression.gd")
const JureJureSystemClass = preload("res://scripts/jurejure_system.gd")
const Localizer = preload("res://scripts/game_localizer.gd")


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	_test_catalog_contract(game)
	await _test_three_act_sequence(game)
	_test_retired_unlock_conditions(game)
	_test_legacy_three_act_migration(game)
	game._reset_progression_state()
	print("STORY_PROGRESSION_SMOKE_OK acts=3 first_battle=act2 original_guarantee=true fantasy_gate=original_get fantasy_guarantee=true arrangement_gate=1 forest_gate=6 fantasy=1+6+24 safe_queue=true exploitation=act3 midpoint=4 crisis=8 post_crisis_home=once secret_gacha=disabled migration=preserved")
	get_tree().quit()


func _test_catalog_contract(game: Node) -> void:
	assert(game.INITIAL_SERIES_ID == "base")
	assert(game._series_entry("common").is_empty())
	assert(bool(game.unlocked_series.get("base", false)))
	assert(game.catalog_species.size() == 134)
	var jurejure_entries: Array[Dictionary] = game._series_species_entries("jurejure")
	assert(jurejure_entries.size() == 10)
	for entry in jurejure_entries:
		assert(game._is_jurejure_species(entry) and game._is_fantasy_species(entry))
		var image_path := str(entry.get("image_path", ""))
		assert(image_path.ends_with(".png") and FileAccess.file_exists(image_path))
		var texture := load(image_path) as Texture2D
		var image := texture.get_image()
		assert(image != null and image.detect_alpha() != Image.ALPHA_NONE)
		assert(image.get_pixel(0, 0).a < 0.02 and image.get_pixel(image.get_width() - 1, image.get_height() - 1).a < 0.02)
	for removed_id in StoryProgressionClass.REMOVED_COMMON_SPECIES_IDS:
		assert(game._catalog_entry(str(removed_id)).is_empty())
	var originals: Array[String] = []
	var modern_annotations: Array[String] = []
	for entry in game._series_species_entries("base"):
		if bool(entry.get("main_story_original", false)):
			originals.append(str(entry.get("species_id", "")))
			assert(str(entry.get("catalog_origin", "")) == "historic_record")
		elif str(entry.get("catalog_origin", "")) == "modern_annotation":
			modern_annotations.append(str(entry.get("species_id", "")))
	assert(originals == StoryProgressionClass.MAIN_STORY_ORIGINAL_IDS)
	assert(originals.size() == 12 and modern_annotations.size() == 9)
	for ordinary_id in ["hyalina_san_luis_de_la_paz", "purpusorum", "pinwheel", "tovarensis_tovar", "strictiflora_bustamante"]:
		var ordinary_entry: Dictionary = game._catalog_entry(ordinary_id)
		assert(not ordinary_entry.is_empty())
		assert(bool(ordinary_entry.get("main_story_original", false)))
		assert(str(ordinary_entry.get("rarity", "")) == "通常")
		assert(float(ordinary_entry.get("spawn_weight", 0.0)) > 0.0)
		assert(not bool(ordinary_entry.get("special_route_only", false)))
	var unlock_rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/unlock-rules.json"))
	assert(unlock_rules is Array and unlock_rules.is_empty())
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var localizer_source := FileAccess.get_file_as_string("res://scripts/game_localizer.gd")
	assert(not main_source.contains("objective_") and not localizer_source.contains("objective_"))
	assert(not main_source.contains("unlock_after_plays") and not localizer_source.contains("unlock_after_plays"))
	assert(not localizer_source.contains("catalog_field"))
	var progression_source := FileAccess.get_file_as_string("res://scripts/story_progression.gd")
	for retired_stage_name in ["STAGE_ORIGINALS_5", "STAGE_SIZE_50", "STAGE_ORIGINALS_8", "STAGE_SIZE_100", "STAGE_ORIGINALS_12", "STAGE_SECOND_AWAKENING"]:
		assert(not progression_source.contains(retired_stage_name))
	assert(game.find_child("*Objective*", true, false) == null)


func _test_three_act_sequence(game: Node) -> void:
	game._reset_progression_state()
	game.opening_story_overlay.visible = false
	game.intro_overlay.visible = false
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.trio_originals_confirmed = true
	game.habitat_unlocked = true
	game.habitat_arrival_started = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_tutorial_started = true
	game.habitat_tutorial_complete = true
	game.habitat_tutorial_returned_to_greenhouse = true
	game.mystery_items_acquired = true
	game.mystery_catalog_tutorial_complete = true
	game.seed_shop_open = true
	game.puku_gauge_intro_complete = true
	game.jurejure_intro_complete = true
	game.jurejure_enabled = true
	game.current_mode = "greenhouse"
	game._apply_mode()
	game._update_main_story_progress(false)
	assert(game.main_story_stage == StoryProgressionClass.ACT_1)

	# Old completion numbers no longer move the story at all.
	for species_id in StoryProgressionClass.MAIN_STORY_ORIGINAL_IDS:
		game.discovered[species_id] = true
	game.bests["colorata"] = 150.0
	game.total_play_count = 20
	game.formal_play_count = 20
	game.armadillo_research_total = 30
	game._update_main_story_progress(false)
	assert(game.main_story_stage == StoryProgressionClass.ACT_1)
	assert(not game.act2_unlocked and not game.forest_gacha_unlocked)

	# Any normally resolved first battle, including a loss, opens Act 2.
	game._on_puku_puku_battle_resolved({"won": false, "player_score": 1.0, "opponent_score": 2.0})
	assert(game.jurejure_battle_count == 1 and game.jurejure_battle_win_count == 0)
	assert(game.act2_unlocked and not game.forest_gacha_unlocked and not game.forest_gacha_intro_seen)
	assert(not StoryProgressionClass.fantasy_is_unlocked(game.story_progression_state))
	assert(bool(game.story_progression_state.get("original_new_guarantee_pending", false)))
	assert(game.main_story_stage == StoryProgressionClass.ACT_2)

	# The first normal game after the battle consumes one appearance guarantee,
	# without awarding ownership. A later real GET of an unowned original opens
	# fantasy and arms the separate fantasy appearance guarantee.
	game.opening_species.clear()
	game._prepare_story_spawn_guarantee()
	assert(game.opening_species.size() == 1)
	var guaranteed_original: Dictionary = game.opening_species[0]
	assert(bool(guaranteed_original.get("main_story_original", false)))
	assert(game._species_get_count(str(guaranteed_original.get("species_id", ""))) == 0)
	assert(not bool(game.story_progression_state.get("original_new_guarantee_pending", true)))
	game.opening_species.clear()
	game._record_species_get(str(guaranteed_original.get("species_id", "")))
	assert(StoryProgressionClass.fantasy_is_unlocked(game.story_progression_state))
	assert(bool(game.story_progression_state.get("fantasy_new_guarantee_pending", false)))
	assert(not game.forest_gacha_unlocked)
	game._prepare_story_spawn_guarantee()
	assert(game.opening_species.size() == 1)
	var guaranteed_fantasy: Dictionary = game.opening_species[0]
	assert(game._is_fantasy_species(guaranteed_fantasy) and not game._is_jurejure_species(guaranteed_fantasy))
	assert(game._species_get_count(str(guaranteed_fantasy.get("species_id", ""))) == 0)
	game.opening_species.clear()

	var fantasy_ids: Array[String] = []
	for entry in game.catalog_species:
		if game._is_fantasy_species(entry) and not game._is_jurejure_species(entry):
			fantasy_ids.append(str(entry.get("species_id", "")))
	assert(fantasy_ids.size() >= 24)
	# Encyclopedia discovery by itself is not a real GET.
	for index in range(24):
		game.discovered[fantasy_ids[index]] = true
	assert(game._unique_fantasy_species_get_count() == 0)
	assert(not game.act3_unlocked)

	# A GET reached during another flow is queued, never injected into that
	# flow. Closing the battle surface exposes the same event immediately.
	game.puku_puku_battle.visible = true
	game._record_species_get(fantasy_ids[0])
	assert(game._unique_fantasy_species_get_count() == 1)
	assert(not game.forest_gacha_unlocked)
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind.is_empty())
	game.puku_puku_battle.visible = false
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind == "fantasy_first_discovery")
	assert(game.scripted_dialog_pages.size() == 3)
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == "……なにこれ！？")
	assert(str(game.scripted_dialog_pages[1].get("text", "")) == "こんな多肉、あの本には載ってないよ…。")
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.fantasy_first_discovery_seen)
	assert(game.scripted_dialog_kind == "arrangement_intro")
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == "品種も集まって来たね！\n鉢をプレゼントするから寄せ植えしてみてよ！")
	_finish_dialog(game)
	await get_tree().process_frame
	assert(StoryProgressionClass.arrangement_is_unlocked(game.story_progression_state))
	assert(bool(game.story_progression_state.get("arrangement_intro_seen", false)))
	assert(game.arrangement_button == null and game.arrangement_navigation_hint.intro_playing)
	if game.arrangement_navigation_hint.intro_tween and game.arrangement_navigation_hint.intro_tween.is_valid():
		game.arrangement_navigation_hint.intro_tween.kill()
	game.arrangement_navigation_hint._finish_intro()
	await get_tree().process_frame
	game._record_species_get(fantasy_ids[1])
	assert(game._unique_fantasy_species_get_count() == 2)
	assert(not game.forest_gacha_unlocked and not game.forest_gacha_intro_seen)

	for index in range(2, 5):
		game._record_species_get(fantasy_ids[index])
		assert(not game.forest_gacha_unlocked)
	game.puku_puku_battle.visible = true
	game._record_species_get(fantasy_ids[5])
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind.is_empty())
	game.puku_puku_battle.visible = false
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind == "fantasy_realization")
	assert(game.scripted_dialog_pages.size() == 3)
	assert("想像したものが、多肉になってる？" in str(game.scripted_dialog_pages[2].get("text", "")))
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.fantasy_realization_seen)
	assert(game.forest_gacha_unlocked and not game.forest_gacha_intro_seen)
	assert(game.scripted_dialog_kind == "forest_gacha_intro")
	_finish_dialog(game)
	assert(game.forest_gacha_intro_seen)

	for index in range(6, 24):
		game._record_species_get(fantasy_ids[index])
	assert(game._unique_fantasy_species_get_count() == 24)
	assert(game.act3_unlocked and game.act3_intro_pending and not game.act3_intro_seen)
	assert(game.main_story_stage == StoryProgressionClass.ACT_3)
	assert(game.scripted_dialog_kind.is_empty())
	# Merely assigning habitat mode is not a visit; the intro waits for the next
	# real navigation entry and therefore cannot appear behind a GET screen.
	game.current_mode = "habitat"
	game._apply_mode()
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind.is_empty())
	game.current_mode = "greenhouse"
	game._apply_mode()
	game._toggle_mode()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.current_mode == "habitat" and game.scripted_dialog_kind == "act3_intro")
	assert(game.audio_manager.current_bgm_key == "jurejure")
	assert(game.scripted_dialog_index == 0)
	assert(game.intro_dialogue_label.text == "つまり、欲しいものを想像すればいいんだチュー！？")
	assert(game.scripted_dialog_pages.size() == 4)
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == "つまり、欲しいものを想像すればいいんだチュー！？")
	assert(str(game.scripted_dialog_pages[1].get("text", "")) == "だったら、もっともっと作らせるチュー！")
	assert(str(game.scripted_dialog_pages[2].get("text", "")) == "食べきれないくらいのごちそうを作らせるッペー！")
	assert(str(game.scripted_dialog_pages[3].get("text", "")) == "金になるものなら、いくらでも作れるッスカ！？")
	_finish_dialog(game)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.act3_intro_seen and not game.act3_intro_pending)
	assert(StoryProgressionClass.exploitation_is_started(game.story_progression_state))
	assert(not game.habitat_crisis_started)
	assert(game.jurejure_intro_camera_active)
	game._update_habitat_view_follow(1.0)
	await get_tree().process_frame
	assert(game.scripted_dialog_kind == "act3_exploitation_battle_intro")
	assert(game.scripted_dialog_pages.size() == 3)
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == "まだまだ作らせるチュー！")
	assert(str(game.scripted_dialog_pages[1].get("text", "")) == "好き勝手にはさせないぞ！")
	assert(str(game.scripted_dialog_pages[2].get("text", "")) == "だったら、ぷくぷくバトルで勝負だチュー！")
	assert(not game.puku_puku_battle.visible)
	_finish_dialog(game)
	await get_tree().process_frame
	assert(game.puku_puku_battle.visible and game.puku_puku_battle.choice_layer.visible)
	assert(not game.puku_puku_battle.battle_active and bool(game.story_progression_state.get("act3_battle_intro_seen", false)))
	game.puku_puku_battle._decline_battle()
	assert(game.audio_manager.current_bgm_key == "jurejure")
	game.jurejure_waiting_for_seed_pod_reward = true
	assert(game._should_show_jurejure_group())
	game.habitat_visit_id = 3
	var early_visit_yaw: float = game.view_yaw
	game._maybe_start_habitat_exploitation_concern()
	assert(game.scripted_dialog_kind == "habitat_exploitation_concern")
	assert(game.scripted_dialog_pages.size() == 1)
	var early_visit_texts: Array[String] = []
	for pattern in JureJureSystemClass.EXPLOITATION_EARLY_VISIT_PATTERNS:
		early_visit_texts.append(Localizer.text("ja", str(pattern.get("text_key", ""))))
	assert(str(game.scripted_dialog_pages[0].get("text", "")) in early_visit_texts)
	assert(not game.jurejure_intro_camera_active and is_equal_approx(game.view_yaw, early_visit_yaw))
	_finish_dialog(game)

	# JureJure progress now has three distinct phases: Act III starts
	# exploitation, four unique GETs trigger the confrontation midpoint, and only
	# eight unique GETs schedule the weakening/rain crisis.
	var jurejure_ids: Array[String] = []
	for entry in game._series_species_entries("jurejure"):
		jurejure_ids.append(str(entry.get("species_id", "")))
	assert(game._unlock_jurejure_pool())
	game.jurejure_species_first_seen = true
	for index in range(3):
		assert(game._register_species_discovery(jurejure_ids[index], true))
	assert(game._unique_jurejure_species_get_count() == 3)
	assert(not bool(game.story_progression_state.get("exploitation_midpoint_pending", false)))
	assert(not game.habitat_crisis_pending and not game.habitat_crisis_started)
	game._register_species_discovery(jurejure_ids[0], true)
	assert(game._unique_jurejure_species_get_count() == 3 and not game.habitat_crisis_pending)
	assert(game._register_species_discovery(jurejure_ids[3], true))
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
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == "おい……もうやめた方がいいんじゃないか？")
	assert(str(game.scripted_dialog_pages[1].get("text", "")) == "原生地、さっきより疲れてるように見えるよ。")
	assert(str(game.scripted_dialog_pages[2].get("text", "")) == "気のせいだチュー！まだまだ作れるチュー！")
	assert(str(game.scripted_dialog_pages[3].get("text", "")) == "まだ欲しいものがいっぱいあるッペー！")
	assert(str(game.scripted_dialog_pages[4].get("text", "")) == "でも……このまま続けたら、本当にまずいかもしれない。")
	assert(str(game.scripted_dialog_pages[5].get("text", "")) == "そんなの知らないチュー！")
	_finish_dialog(game)
	await get_tree().process_frame
	assert(StoryProgressionClass.exploitation_midpoint_is_seen(game.story_progression_state))
	StoryProgressionClass.update_jurejure_progress(game.story_progression_state, 4)
	assert(not bool(game.story_progression_state.get("exploitation_midpoint_pending", false)))
	assert(not StoryProgressionClass.secret_gacha_feature_enabled())
	assert(StoryProgressionClass.peek_story_event(game.story_progression_state) != StoryProgressionClass.EVENT_SECRET_GACHA_INSTALL)
	assert(not StoryProgressionClass.secret_gacha_is_unlocked(game.story_progression_state))
	assert(not game.secret_gacha_active and not game.secret_gacha_button.visible)
	assert(not game.habitat_crisis_started and not game.habitat_crisis_atmosphere.crisis_active)
	game.habitat_visit_id = 6
	assert(not game.jurejure_intro_camera_active)
	var late_visit_yaw: float = game.view_yaw
	game._maybe_start_habitat_exploitation_concern()
	assert(game.scripted_dialog_kind == "habitat_exploitation_concern")
	assert(game.scripted_dialog_pages.size() == 1)
	var late_visit_texts: Array[String] = []
	for pattern in JureJureSystemClass.EXPLOITATION_LATE_VISIT_PATTERNS:
		late_visit_texts.append(Localizer.text("ja", str(pattern.get("text_key", ""))))
	assert(str(game.scripted_dialog_pages[0].get("text", "")) in late_visit_texts)
	assert(not game.jurejure_intro_camera_active and is_equal_approx(game.view_yaw, late_visit_yaw))
	_finish_dialog(game)

	for index in range(4, 7):
		assert(game._register_species_discovery(jurejure_ids[index], true))
	assert(game._unique_jurejure_species_get_count() == 7)
	assert(not game.habitat_crisis_pending and not game.habitat_crisis_started)
	game._register_species_discovery(jurejure_ids[0], true)
	assert(game._unique_jurejure_species_get_count() == 7 and not game.habitat_crisis_pending)
	assert(game._register_species_discovery(jurejure_ids[7], true))
	assert(game._unique_jurejure_species_get_count() == 8)
	assert(game.habitat_crisis_pending and not game.habitat_crisis_started)

	# The crisis also waits for a later habitat visit and changes presentation
	# only. It must not revive the retired rain bonus or mutate collection state.
	var settled_before: Dictionary = game.habitat_returned_species.duplicate(true)
	var discovered_before: Dictionary = game.discovered.duplicate(true)
	var get_counts_before: Dictionary = game.species_get_counts.duplicate(true)
	var seeds_before: int = game.normal_seed_bags
	game.habitat_crisis_started = false
	game.finale_complete = false
	game.habitat_crisis_eligible_visit_id = game.habitat_visit_id
	game._try_start_pending_story_event()
	assert(game.scripted_dialog_kind.is_empty())
	game._toggle_mode()
	game._toggle_mode()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.current_mode == "habitat" and game.jurejure_intro_camera_active)
	game._update_habitat_view_follow(1.0)
	await get_tree().process_frame
	assert(game.scripted_dialog_kind == "habitat_crisis")
	assert(game.habitat_crisis_started and not game.habitat_crisis_pending)
	assert(game.habitat_crisis_atmosphere.crisis_active and game.habitat_crisis_atmosphere.visible)
	assert(game.scripted_dialog_pages.size() == 6)
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == "……おかしい。")
	assert(str(game.scripted_dialog_pages[1].get("text", "")) == "原生地が、明らかに弱ってる。")
	assert(str(game.scripted_dialog_pages[2].get("text", "")) == "やっぱり……ずっと無理してたんだ。")
	assert(str(game.scripted_dialog_pages[3].get("text", "")) == "……そんなはずないチュー。")
	assert(str(game.scripted_dialog_pages[4].get("text", "")) == "さっきまで、もっと作れてたッペ……。")
	assert(str(game.scripted_dialog_pages[5].get("text", "")) == "オレたち……のせいっスカ……？")
	assert(not game.rain_bonus_active and not game.rain_bonus_in_progress and game.rain_bag_count == 0)
	assert(game.rain_visual == null)
	assert(game.habitat_returned_species == settled_before)
	assert(game.discovered == discovered_before and game.species_get_counts == get_counts_before)
	assert(game.normal_seed_bags == seeds_before)
	_finish_dialog(game)
	assert(not game.finale_complete and game.main_story_stage == StoryProgressionClass.ACT_3)
	assert(bool(game.story_progression_state.get("post_crisis_greenhouse_pending", false)))
	assert(not bool(game.story_progression_state.get("post_crisis_greenhouse_seen", false)))
	assert(StoryProgressionClass.peek_story_event(game.story_progression_state) != StoryProgressionClass.EVENT_POST_CRISIS_GREENHOUSE)
	assert(not StoryProgressionClass.secret_gacha_is_unlocked(game.story_progression_state))
	assert(not game.secret_gacha_active and not game.secret_gacha_button.visible)
	assert(StoryProgressionClass.peek_story_event(game.story_progression_state) != StoryProgressionClass.EVENT_SECRET_GACHA_INSTALL)
	game.jurejure_waiting_for_seed_pod_reward = true
	assert(game._should_show_jurejure_group())
	game._toggle_mode()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.current_mode == "greenhouse" and game.scripted_dialog_kind == "post_crisis_greenhouse")
	assert(game.scripted_dialog_pages.size() == 4)
	assert(str(game.scripted_dialog_pages[0].get("text", "")) == "原生地は限界だったんだ…")
	assert(str(game.scripted_dialog_pages[1].get("text", "")) == "これじゃあ歴史の繰り返しだ…")
	assert(str(game.scripted_dialog_pages[2].get("text", "")) == "私たちにできる事は原生地からもらった種をとにかく蒔き続ける事…")
	assert(str(game.scripted_dialog_pages[3].get("text", "")) == "うん、そうだね！とにかく蒔こう。多肉植物を絶やさないように！")
	_finish_dialog(game)
	assert(bool(game.story_progression_state.get("post_crisis_greenhouse_seen", false)))
	assert(not bool(game.story_progression_state.get("post_crisis_greenhouse_pending", true)))
	game._toggle_mode();await get_tree().process_frame
	game._toggle_mode();await get_tree().process_frame
	assert(game.current_mode == "greenhouse" and game.scripted_dialog_kind.is_empty())
	game._save()
	var phase_payload = JSON.parse_string(FileAccess.get_file_as_string("user://records.json"))
	assert(phase_payload is Dictionary and bool(phase_payload.get("habitat_crisis_started", false)))
	var saved_phase_state := StoryProgressionClass.normalize_runtime_state(phase_payload.get("story_progression_state", {}))
	assert(StoryProgressionClass.exploitation_is_started(saved_phase_state))
	assert(StoryProgressionClass.exploitation_midpoint_is_seen(saved_phase_state))
	assert(bool(saved_phase_state.get("post_crisis_greenhouse_seen", false)))
	assert(not bool(saved_phase_state.get("post_crisis_greenhouse_pending", true)))


func _test_retired_unlock_conditions(game: Node) -> void:
	game._reset_progression_state()
	var special_ids := ["hyalina_san_luis_de_la_paz", "purpusorum", "pinwheel", "tovarensis_tovar", "strictiflora_bustamante"]
	game.bests = {"colorata": 100.0, "lutea": 60.0, "shaviana": 60.0}
	game.total_play_count = 13
	game.normal_play_count = 13
	game.formal_play_count = 13
	game.armadillo_research_total = 25
	game._evaluate_unlock_rules("harvest_size", 100.0)
	assert(not game._evaluate_best_spawn_unlocks())
	game._queue_armadillo_progress_event()
	game._prepare_tovar_event_for_play()
	assert(game.pending_armadillo_story_event.is_empty() and not game.tovar_event_active)
	for species_id in special_ids:
		assert(not bool(game.discovered.get(species_id, false)))
	assert(game.mystery_route_assignments.is_empty())

	# Formal-play counts no longer unlock inventory. Existing inventory remains
	# usable with no count gate.
	game.volume_seed_unlocked = false
	game.premium_seed_unlocked = false
	game.volume_seed_bags = 0
	game.premium_seed_bags = 0
	game._refresh_seed_pack_unlocks()
	assert(not game._volume_seed_unlocked() and not game._premium_seed_unlocked())
	game.volume_seed_bags = 1
	game.premium_seed_bags = 1
	assert(game._volume_seed_unlocked() and game._premium_seed_unlocked())


func _test_legacy_three_act_migration(game: Node) -> void:
	game._reset_progression_state()
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.trio_originals_confirmed = true
	game.habitat_unlocked = true
	game.habitat_arrival_started = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_tutorial_started = true
	game.habitat_tutorial_complete = true
	game.mystery_items_acquired = true
	game.seed_shop_open = true
	game.puku_gauge_intro_complete = true
	game.habitat_second_awakened = true
	game.normal_seed_bags = 6
	game.volume_seed_bags = 2
	game.premium_seed_bags = 1
	game.mystery_seed_bags = 3
	game.bests = {"colorata": 100.0, "laui": 62.0}
	game.discovered = {"colorata": true, "hyalina_san_luis_de_la_paz": true, "purpusorum": true, "pinwheel": true, "tovarensis_tovar": true, "transparent_succulent": true}
	game.species_get_counts = {"colorata": 3, "hyalina_san_luis_de_la_paz": 1, "purpusorum": 1, "pinwheel": 1, "tovarensis_tovar": 1, "transparent_succulent": 1}
	game.greenhouse_available = game.discovered.duplicate(true)
	game.unlocked_species = game.greenhouse_available.duplicate(true)
	game.habitat_returned_species = {"colorata": true, "laui": true, "transparent_succulent": true}
	var fantasy_ids: Array[String] = []
	for entry in game.catalog_species:
		if game._is_fantasy_species(entry) and not game._is_jurejure_species(entry):
			fantasy_ids.append(str(entry.get("species_id", "")))
	for index in range(24):
		game.discovered[fantasy_ids[index]] = true
		game.species_get_counts[fantasy_ids[index]] = 1
		game.greenhouse_available[fantasy_ids[index]] = true
		game.habitat_returned_species[fantasy_ids[index]] = true
	var migrated_jurejure_id := "jurejure_luxury_watch"
	game.discovered[migrated_jurejure_id] = true
	game.species_get_counts[migrated_jurejure_id] = 2
	game.greenhouse_available[migrated_jurejure_id] = true
	game.habitat_returned_species[migrated_jurejure_id] = true
	game.completed_unlock_conditions = {"legacy_40cm": true, "legacy_play_13": true}
	game._save()
	var payload = JSON.parse_string(FileAccess.get_file_as_string("user://records.json"))
	assert(payload is Dictionary)
	payload["progression_version"] = 24
	for key in ["act2_unlocked", "forest_gacha_unlocked", "forest_gacha_intro_seen", "fantasy_first_discovery_seen", "fantasy_realization_seen", "act3_unlocked", "act3_intro_pending", "act3_intro_seen", "jurejure_pool_unlocked", "jurejure_species_unlocked", "jurejure_species_first_seen", "habitat_crisis_pending", "habitat_crisis_started", "finale_complete"]:
		payload.erase(key)
	var file := FileAccess.open("user://records.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()

	game.discovered.clear();game.species_get_counts.clear();game.habitat_returned_species.clear();game.normal_seed_bags=0
	game._load_save()
	assert(game.act2_unlocked and game.forest_gacha_unlocked)
	assert(game.fantasy_first_discovery_seen and game.fantasy_realization_seen)
	assert(game._unique_fantasy_species_get_count() == 25)
	assert(game.act3_unlocked and game.act3_intro_pending and not game.act3_intro_seen)
	assert(game.scripted_dialog_kind.is_empty())
	assert(game.normal_seed_bags == 6 and game.volume_seed_bags == 2 and game.premium_seed_bags == 1 and game.mystery_seed_bags == 3)
	assert(bool(game.discovered.get("pinwheel", false)) and game._species_get_count("pinwheel") == 1)
	assert(bool(game.discovered.get("transparent_succulent", false)) and game._species_get_count("transparent_succulent") == 1)
	assert(bool(game.habitat_returned_species.get("laui", false)) and bool(game.habitat_returned_species.get("transparent_succulent", false)))
	assert(game._is_jurejure_species_unlocked(migrated_jurejure_id))
	assert(game.jurejure_pool_unlocked and game.jurejure_species_unlocked.size() == 10)
	for jure_entry in game._series_species_entries("jurejure"):
		var jure_id := str(jure_entry.get("species_id", ""))
		assert(game._is_jurejure_species_unlocked(jure_id))
		if jure_id != migrated_jurejure_id:
			assert(game._species_get_count(jure_id) == 0 and not bool(game.discovered.get(jure_id, false)))
	assert(bool(game.greenhouse_available.get(migrated_jurejure_id, false)) and game._species_get_count(migrated_jurejure_id) == 2)
	assert(not bool(game.habitat_returned_species.get(migrated_jurejure_id, false)))
	assert(bool(game.completed_unlock_conditions.get("legacy_40cm", false)) and bool(game.completed_unlock_conditions.get("legacy_play_13", false)))
	game._evaluate_unlock_rules("harvest_size", 100.0)
	assert(game._species_get_count("pinwheel") == 1 and game._species_get_count("transparent_succulent") == 1)

	# v27 saves used habitat_crisis_started as both exploitation and crisis.
	# Preserve their reached content while translating it into all three durable
	# phase states and never replay the relocated post-encounter warning.
	var old_crisis_state := StoryProgressionClass.normalize_runtime_state({"version": 1}, {
		"legacy": true,
		"act3_intro_seen": true,
		"jurejure_get_count": 8,
		"jurejure_intro_complete": true,
		"habitat_crisis_started": true,
		"secret_gacha_evidence": false,
	})
	assert(StoryProgressionClass.exploitation_is_started(old_crisis_state))
	assert(StoryProgressionClass.exploitation_midpoint_is_seen(old_crisis_state))
	assert(StoryProgressionClass.secret_gacha_is_unlocked(old_crisis_state))
	assert(bool(old_crisis_state.get("post_encounter_greenhouse_seen", false)))
	assert(not bool(old_crisis_state.get("post_encounter_greenhouse_pending", false)))
	assert(bool(old_crisis_state.get("post_crisis_greenhouse_seen", false)))
	assert(not bool(old_crisis_state.get("post_crisis_greenhouse_pending", true)))

	# A save that saw Act III and reached four species, but not the old crisis,
	# resumes at the new midpoint rather than skipping forward to rain.
	var old_midpoint_state := StoryProgressionClass.normalize_runtime_state({"version": 1}, {
		"legacy": true,
		"act3_intro_seen": true,
		"jurejure_get_count": 4,
		"habitat_crisis_started": false,
		"secret_gacha_evidence": false,
	})
	assert(StoryProgressionClass.exploitation_is_started(old_midpoint_state))
	assert(bool(old_midpoint_state.get("exploitation_midpoint_pending", false)))
	assert(StoryProgressionClass.peek_story_event(old_midpoint_state) == StoryProgressionClass.EVENT_EXPLOITATION_MIDPOINT)
	assert(not StoryProgressionClass.secret_gacha_is_unlocked(old_midpoint_state))

	# A queued install from the immediately preceding build cannot block the
	# normal story queue while the feature flag is off. Its durable milestone is
	# retained so switching the single flag back on can reconnect the event.
	var disabled_secret_pending := StoryProgressionClass.normalize_runtime_state({
		"version": StoryProgressionClass.RUNTIME_STATE_VERSION,
		"exploitation_started": true,
		"exploitation_midpoint_seen": true,
		"secret_gacha_unlocked": false,
		"secret_gacha_install_seen": false,
		"pending_story_events": [StoryProgressionClass.EVENT_SECRET_GACHA_INSTALL],
	})
	assert(StoryProgressionClass.exploitation_midpoint_is_seen(disabled_secret_pending))
	assert(StoryProgressionClass.peek_story_event(disabled_secret_pending).is_empty())
	assert(not StoryProgressionClass.secret_gacha_is_unlocked(disabled_secret_pending))
	assert(not bool(disabled_secret_pending.get("secret_gacha_install_seen", false)))


func _finish_dialog(game: Node) -> void:
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
