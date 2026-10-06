extends Node

const Localizer = preload("res://scripts/game_localizer.gd")
const StoryDevPresetsClass = preload("res://scripts/story_dev_presets.gd")

const TARGET_COUNT := 229
const FINAL_SPECIES_ID := "hyb_jelly_jelly"
const FUSION_PARENT_ID := "jelly_grape"
const ROUTE_SAMPLES := [
	"jelly_grape",             # normal cultivation / normal fantasy pool
	"forest_amber_insect_rosette", # forest-gacha catalog series
	"pinwheel",                # hidden research/story route
	FINAL_SPECIES_ID,           # fusion-only route
]


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled": false, "se_enabled": false})
	_test_target_definition(game)
	_test_route_agnostic_completion_detection(game)
	await _test_full_fusion_completion_flow(game)
	await _test_unseen_presentation_recovery(game)
	# Leave the shared smoke-test save small and neutral for the following scene.
	game._reset_progression_state()
	print("COLLECTION_COMPLETE_SMOKE_OK target=229 unique=true get_card_first=true hidden_prep=true silhouette=true complete_overlay=true localized=true save_history=true unseen_resume=true fusion_return=true")
	get_tree().quit()


func _test_target_definition(game) -> void:
	var target_ids: Array[String] = game._collection_complete_species_ids()
	assert(target_ids.size() == TARGET_COUNT)
	var unique_ids: Dictionary = {}
	for species_id in target_ids:
		assert(not unique_ids.has(species_id))
		unique_ids[species_id] = true
	for required_id in ["colorata", "pinwheel", "jelly_grape", "jurejure_pure_gold", "hyb_jelly_jelly", "fus1_jelly_bomb", "fus1_fruit_terrine", "fus2_moonbow"]:
		assert(unique_ids.has(required_id))
	# These route species deliberately have no card on any current catalog page;
	# their acquisition routes remain valid, but they cannot be an empty catalog
	# slot and therefore are not part of the page-completion denominator.
	for unlisted_id in ["golden_laui", "golden_kannte", "transparent_succulent", "glow_colorata", "metal_laui", "seaglass_veria", "amber_agavoides", "yumefuwa_jelly", "peach_jelly_succulent"]:
		assert(not unique_ids.has(unlisted_id))
	assert(Localizer.text("ja", "collection_complete_title") == "図鑑 COMPLETE！")
	assert(Localizer.text("ja", "collection_complete_message") == "すべての多肉植物を見つけました！")
	assert(Localizer.text("hiragana", "collection_complete_title") == "ずかん COMPLETE！")
	assert(Localizer.text("en", "collection_complete_title") == "CATALOG COMPLETE!")
	assert(Localizer.text("en", "collection_complete_message") == "You found every succulent!")


func _test_route_agnostic_completion_detection(game) -> void:
	for missing_species_id in ROUTE_SAMPLES:
		game.species_get_counts.clear()
		game.discovered.clear()
		game.greenhouse_available.clear()
		game.unlocked_species.clear()
		for species_id in game._collection_complete_species_ids():
			if species_id == missing_species_id:
				continue
			game.species_get_counts[species_id] = 1
			game.discovered[species_id] = true
		game.collection_complete_versions.clear()
		assert(game._collection_complete_get_count() == TARGET_COUNT - 1)
		assert(game._register_species_discovery(missing_species_id, true))
		assert(game._collection_complete_get_count() == TARGET_COUNT)
		var record: Dictionary = game._collection_complete_current_record()
		assert(bool(record.get("completed", false)))
		assert(not bool(record.get("presentation_seen", false)))
		assert(str(record.get("last_species_id", "")) == missing_species_id)
		# Keep deferred story checks from starting an animation between samples.
		record["presentation_seen"] = true
		game.collection_complete_versions[game._game_version_key()] = record


func _test_full_fusion_completion_flow(game) -> void:
	var preset_result: Dictionary = game._apply_story_dev_preset(StoryDevPresetsClass.COLLECTION_ONE_REMAINING)
	assert(bool(preset_result.get("ok", false)))
	await get_tree().process_frame
	assert(game._collection_complete_get_count() == TARGET_COUNT - 1)
	assert(game._species_get_count(FINAL_SPECIES_ID) == 0)
	game.collection_complete_animation_speed_scale = 0.12
	game.fusion_parent_a_id = FUSION_PARENT_ID
	game.fusion_parent_b_id = FUSION_PARENT_ID
	game.fusion_return_pending = true
	game.fusion_lab_ui.open_lab(
		game.fusion_system.eligible_parents(game.species_get_counts),
		game.species_get_counts,
		FUSION_PARENT_ID,
		FUSION_PARENT_ID
	)
	game.fusion_lab_ui.visible = false

	assert(game._register_species_discovery(FINAL_SPECIES_ID, true))
	var saved_payload = JSON.parse_string(FileAccess.get_file_as_string(game._active_save_path()))
	assert(saved_payload is Dictionary)
	assert(int(saved_payload.get("species_get_counts", {}).get(FINAL_SPECIES_ID, 0)) == 1)
	assert(bool(saved_payload.get("discovered", {}).get(FINAL_SPECIES_ID, false)))
	var saved_record: Dictionary = saved_payload.get("collection_complete_versions", {}).get(game._game_version_key(), {})
	assert(bool(saved_record.get("completed", false)) and not bool(saved_record.get("presentation_seen", false)))
	assert(not bool(saved_record.get("last_get_card_seen", false)))

	game._queue_species_get_by_id(FINAL_SPECIES_ID, true, "fusion_lab")
	await _wait_until(func() -> bool: return game.species_get_overlay.visible)
	assert(not game.collection_complete_presentation_active)
	assert(game.species_get_overlay.current_context == "fusion_lab")
	assert(game.species_get_overlay.name_label.text == "ジェリードーム")
	await _wait_until(func() -> bool: return not game.species_get_overlay.busy)
	game.species_get_overlay.close_overlay()

	await _wait_until(func() -> bool: return game.collection_complete_presentation_phase == "silhouette")
	assert(game._collection_complete_get_card_seen())
	assert(game.collection_complete_presentation_active)
	assert(game.collection_complete_catalog_ready_before_fade_in)
	assert(game.collection_complete_prepared_series_id == "jelly")
	assert(game.collection_complete_prepared_species_id == FINAL_SPECIES_ID)
	assert(game.current_encyclopedia_series_id == "jelly")
	assert(game.encyclopedia_overlay.visible)
	assert(game.collection_complete_overlay.visible)
	assert(is_instance_valid(game.collection_complete_target_image))
	assert(is_instance_valid(game.collection_complete_silhouette_image))
	assert(game.collection_complete_target_image.modulate.a < 0.01)
	var target_card := game.collection_complete_target_image.get_parent().get_parent().get_parent() as Control
	var viewport_rect := Rect2(game.encyclopedia_scroll.global_position, game.encyclopedia_scroll.size)
	assert(viewport_rect.intersects(target_card.get_global_rect()))
	var target_center_y := target_card.global_position.y + target_card.size.y * 0.5
	assert(target_center_y > viewport_rect.position.y + 80.0)
	assert(target_center_y < viewport_rect.end.y - 60.0)
	var prepared_scroll: int = game.encyclopedia_scroll.scroll_vertical
	game._close_encyclopedia()
	assert(game.encyclopedia_overlay.visible)
	assert(game.encyclopedia_scroll.scroll_vertical == prepared_scroll)

	await _wait_until(func() -> bool: return game.collection_complete_presentation_phase == "complete")
	assert(game.collection_complete_card.visible)
	assert(game.collection_complete_title_label.text == "図鑑 COMPLETE！")
	assert(game.collection_complete_message_label.text == "すべての多肉植物を見つけました！")
	assert(game.collection_complete_version_label.text == "COLLECTION COMPLETE\nVer.%s" % game._game_version_key())
	assert(game.collection_complete_target_image.modulate.a > 0.99)
	assert(not is_instance_valid(game.collection_complete_silhouette_image))
	var current_record: Dictionary = game._collection_complete_current_record()
	assert(not bool(current_record.get("presentation_seen", false)))
	game.collection_complete_versions["0.9.0"] = {
		"completed": true,
		"presentation_seen": true,
		"completed_at": "2025-12-31T23:59:59",
		"species_count": 200,
		"last_species_id": "colorata",
	}

	game._on_collection_complete_card_closed()
	await _wait_until(func() -> bool: return game.scripted_dialog_kind == "collection_complete")
	var expected_speakers := ["girl", "armadillo", "panda", "girl", "armadillo", "panda"]
	var expected_texts := [
		"全部……見つけたんだ！",
		"この図鑑、最初はほとんど空っぽだったのにね。",
		"すごいなあ。こんなにたくさんの多肉が、この世界にいるんだ。",
		"でも、きっとまだ見たことない多肉もあるよね！",
		"うん。この世界なら、これからも新しい品種が生まれるかもしれない。",
		"じゃあ、この図鑑はまだ大事に持っておかないとね！",
	]
	assert(game.scripted_dialog_pages.size() == expected_texts.size())
	for index in range(expected_texts.size()):
		assert(str(game.scripted_dialog_pages[index].get("speaker", "")) == expected_speakers[index])
		assert(str(game.scripted_dialog_pages[index].get("text", "")) == expected_texts[index])
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
	await _wait_until(func() -> bool: return not game.collection_complete_presentation_active)
	await _wait_until(func() -> bool: return game.fusion_lab_ui.visible)
	assert(not game.fusion_return_pending)
	assert(game.fusion_parent_a_id == FUSION_PARENT_ID and game.fusion_parent_b_id == FUSION_PARENT_ID)
	assert(str(game.fusion_lab_ui.current_result.get("result_species_id", "")) == FINAL_SPECIES_ID)
	assert(game.fusion_lab_ui.fuse_button.disabled)
	assert(not game.encyclopedia_overlay.visible)
	current_record = game._collection_complete_current_record()
	assert(bool(current_record.get("presentation_seen", false)))
	assert(game.encyclopedia_complete_badge_label.visible)
	assert(game.encyclopedia_complete_badge_label.text.begins_with("Ver.%s COMPLETE" % game._game_version_key()))

	game._save()
	game.collection_complete_versions.clear()
	game._load_save()
	assert(bool(game._collection_complete_current_record().get("presentation_seen", false)))
	assert(bool(game.collection_complete_versions.get("0.9.0", {}).get("completed", false)))


func _test_unseen_presentation_recovery(game) -> void:
	game.fusion_lab_ui.close_lab()
	game.fusion_return_pending = false
	var current_record: Dictionary = game._collection_complete_current_record()
	current_record["presentation_seen"] = false
	current_record["last_get_card_seen"] = false
	game.collection_complete_versions[game._game_version_key()] = current_record
	game._save()
	game.collection_complete_versions.clear()
	game._load_save()
	assert(game._collection_completion_pending())
	assert(game.collection_complete_pending_species_id == FINAL_SPECIES_ID)
	game.collection_complete_animation_speed_scale = 0.02
	game.current_mode = "greenhouse"
	game._apply_mode()
	# A recovered presentation must wait behind the boot screen, then resume from
	# the ordinary post-opening dispatcher without a test-only direct start.
	game.opening_finished = false
	game.opening_overlay.visible = true
	game.language_selected = true
	game._try_start_pending_story_event()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not game.species_get_overlay.visible)
	assert(not game.collection_complete_presentation_active)
	game._finish_opening()
	await _wait_until(func() -> bool: return game.species_get_overlay.visible)
	assert(game.species_get_overlay.current_context == "collection_complete_recovery")
	assert(not game.collection_complete_presentation_active)
	await _wait_until(func() -> bool: return not game.species_get_overlay.busy)
	game.species_get_overlay.close_overlay()
	await _wait_until(func() -> bool: return game.collection_complete_presentation_phase == "complete")
	game._on_collection_complete_card_closed()
	await _wait_until(func() -> bool: return game.scripted_dialog_kind == "collection_complete")
	while not game.scripted_dialog_kind.is_empty():
		game._advance_scripted_dialog()
	await _wait_until(func() -> bool: return not game.collection_complete_presentation_active)
	assert(bool(game._collection_complete_current_record().get("presentation_seen", false)))
	game._try_start_pending_story_event()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not game.collection_complete_presentation_active)
	assert(game.scripted_dialog_kind.is_empty())
	assert(bool(game.collection_complete_versions.get("0.9.0", {}).get("completed", false)))


func _wait_until(predicate: Callable, max_frames := 900) -> void:
	for _frame in range(max_frames):
		if bool(predicate.call()):
			return
		await get_tree().process_frame
	assert(bool(predicate.call()))
