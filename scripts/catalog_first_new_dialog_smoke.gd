extends Node

const Localizer = preload("res://scripts/game_localizer.gd")
const FIRST_NEW_ID := "purpusorum"
const SECOND_NEW_ID := "laui"


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	_assert_localization()
	_test_source_gates(game)
	await _test_normal_new_card_then_dialog(game)
	await _test_seen_state_survives_reload_and_blocks_repeat(game)
	game._reset_progression_state()
	print("CATALOG_FIRST_NEW_DIALOG_SMOKE_OK source=normal_round card_then_dialog=true once=true save_reload=true locales=ja+hiragana+en")
	get_tree().quit()


func _prepare_visible_greenhouse(game: Node) -> void:
	game.opening_finished = true
	game.opening_overlay.visible = false
	game.opening_story_overlay.visible = false
	game.intro_overlay.visible = false
	game.result_overlay.visible = false
	game.shop_overlay.visible = false
	game.settings_overlay.visible = false
	game.encyclopedia_overlay.visible = false
	game.play_overlay.visible = false
	game.species_get_overlay.visible = false
	game.catalog_series_unlock_overlay.reset_overlay()
	game.catalog_series_unlock_notice_queue.clear()
	game.catalog_series_unlock_notice_ready.clear()
	game.species_get_queue.clear()
	game.species_get_active_context = ""
	game.species_get_active_species_id = ""
	game.species_get_active_series_id = ""
	game.round_result_species_finalize_queue.clear()
	game.round_result_species_finalize_active = false
	game.scripted_dialog_kind = ""
	game.scripted_dialog_pages.clear()
	game.scripted_dialog_index = -1
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.trio_originals_confirmed = true
	game.habitat_unlocked = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_tutorial_complete = true
	game.normal_play_tutorial_complete = true
	game.initial_seed_stock_notice_complete = true
	game.puku_buyback_tutorial_complete = true
	game.current_mode = "greenhouse"
	game.active_seed_type = "normal"
	game.play_active = false
	game._apply_mode()
	game._update_play_ui()


func _assert_localization() -> void:
	assert(Localizer.text("ja", "catalog_first_new_armadillo") == "新しく発見した品種は僕が原生地に\nお還しておくからね。")
	assert(Localizer.text("hiragana", "catalog_first_new_armadillo") == "あたらしく はっけんした ひんしゅは ぼくが げんせいちに\nおかえししておくからね。")
	assert(Localizer.text("en", "catalog_first_new_armadillo") == "I'll return every newly discovered species\nto the habitat for you.")


func _test_source_gates(game: Node) -> void:
	game._reset_progression_state()
	_prepare_visible_greenhouse(game)
	game.mystery_items_acquired = true
	game.encyclopedia_unlocked = true
	game.mystery_catalog_tutorial_complete = false
	game._arm_catalog_first_new_dialog(FIRST_NEW_ID)
	assert(not game.catalog_first_new_dialog_pending)
	game.mystery_catalog_tutorial_complete = true
	game.active_seed_type = "premium"
	game._arm_catalog_first_new_dialog(FIRST_NEW_ID)
	assert(not game.catalog_first_new_dialog_pending)
	game.active_seed_type = "normal"
	assert(game._register_species_discovery(FIRST_NEW_ID, true))
	game._queue_species_get_by_id(FIRST_NEW_ID, true, "forest_gacha")
	assert(not game.catalog_first_new_dialog_pending)
	game.species_get_queue.clear()


func _test_normal_new_card_then_dialog(game: Node) -> void:
	game._reset_progression_state()
	_prepare_visible_greenhouse(game)
	game.mystery_items_acquired = true
	game.encyclopedia_unlocked = true
	game.mystery_catalog_tutorial_complete = true
	game.pending_round_new_species_ids.clear()
	game.pending_round_new_species_ids.append(FIRST_NEW_ID)
	game.round_result_species_finalize_active = true
	game.round_result_species_finalize_queue.clear()
	game.round_result_species_finalize_queue.append({"species_id": FIRST_NEW_ID, "formalize": true, "is_new": true})
	game._show_next_round_result_species()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.catalog_first_new_dialog_pending and not game.catalog_first_new_dialog_card_closed)
	assert(game.catalog_first_new_dialog_species_id == FIRST_NEW_ID)
	assert(game.species_get_overlay.visible and game.species_get_overlay.current_context == "round_result_new")
	assert(game.scripted_dialog_kind.is_empty())
	game.species_get_overlay.busy = false
	await game.species_get_overlay.close_overlay()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.catalog_first_new_dialog_card_closed)
	assert(game.scripted_dialog_kind == "catalog_first_new")
	assert(game.scripted_dialog_pages.size() == 1)
	assert(game.intro_speaker_label.text == "アルマジロ")
	assert(game.intro_dialogue_label.text == "新しく発見した品種は僕が原生地に\nお還しておくからね。")
	assert(game.intro_overlay.visible)
	game._advance_scripted_dialog()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.catalog_first_new_dialog_seen)
	assert(not game.catalog_first_new_dialog_pending and not game.catalog_first_new_dialog_card_closed)
	assert(game.catalog_first_new_dialog_species_id.is_empty())
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game._active_save_path()))
	assert(bool(saved.get("catalog_first_new_dialog_seen", false)))
	assert(not bool(saved.get("catalog_first_new_dialog_pending", true)))


func _test_seen_state_survives_reload_and_blocks_repeat(game: Node) -> void:
	game.catalog_first_new_dialog_seen = false
	game._load_save()
	_prepare_visible_greenhouse(game)
	assert(game.catalog_first_new_dialog_seen and not game.catalog_first_new_dialog_pending)
	game.mystery_items_acquired = true
	game.encyclopedia_unlocked = true
	game.mystery_catalog_tutorial_complete = true
	game.pending_round_new_species_ids.clear()
	game.pending_round_new_species_ids.append(SECOND_NEW_ID)
	game.round_result_species_finalize_active = true
	game.round_result_species_finalize_queue.clear()
	game.round_result_species_finalize_queue.append({"species_id": SECOND_NEW_ID, "formalize": true, "is_new": true})
	game._show_next_round_result_species()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not game.catalog_first_new_dialog_pending)
	assert(game.species_get_overlay.visible and game.species_get_overlay.current_context == "round_result_new")
	game.species_get_overlay.busy = false
	await game.species_get_overlay.close_overlay()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.scripted_dialog_kind != "catalog_first_new")
