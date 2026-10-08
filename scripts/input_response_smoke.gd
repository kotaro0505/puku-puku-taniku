extends Node

const MAX_FIRST_FEEDBACK_MSEC := 100

func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game._reset_progression_state()
	_prepare_quiet_progress(game)
	var get_metrics: Dictionary = await _test_get_card_response(game)
	if OS.has_feature("web") and bool(JavaScriptBridge.eval("new URL(window.location.href).searchParams.has('get_close_profile')")):
		print("INPUT_RESPONSE_SMOKE_OK get_close_profile_total_ms=",get_metrics.profile_total)
		game.queue_free()
		await get_tree().process_frame
		get_tree().quit()
		return
	var gacha_latency: int = await _test_gacha_response(game)
	var harvest_latency: int = await _test_old_seed_harvest_response(game)
	var loader_source := FileAccess.get_file_as_string("res://scripts/catalog_image_loader.gd")
	assert(loader_source.contains("_decode_queue") and loader_source.contains("await RenderingServer.frame_post_draw"))
	print("INPUT_RESPONSE_SMOKE_OK get_first_visual_ms=", get_metrics.visual, " get_hidden_ms=", get_metrics.hidden, " gacha_first_visual_ms=", gacha_latency, " harvest_first_visual_ms=", harvest_latency, " multi_new=batch_save catalog_decode=one_per_frame")
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _prepare_quiet_progress(game: Node) -> void:
	game.opening_story_complete = true
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.trio_originals_confirmed = true
	game.encyclopedia_unlocked = true
	game.habitat_unlocked = true
	game.habitat_arrival_started = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_tutorial_started = true
	game.habitat_tutorial_complete = true
	game.normal_play_tutorial_complete = true
	game.seed_pod_gauge_discovery_complete = true
	game.seed_pod_first_reward_seen = true
	game.initial_seed_stock_notice_complete = true
	game.puku_buyback_tutorial_complete = true
	game.current_mode = "greenhouse"
	game.intro_overlay.visible = false
	game.result_overlay.visible = false
	game.play_overlay.visible = false
	game.catalog_series_unlock_notice_queue.clear()
	game.catalog_series_unlock_notice_ready.clear()

func _test_get_card_response(game: Node) -> Dictionary:
	var overlay = game.species_get_overlay
	var main_handler := Callable(game, "_on_species_get_overlay_closed")
	assert(overlay.closed.is_connected(main_handler))
	overlay.closed.disconnect(main_handler)
	var closed_contexts: Array[String] = []
	var capture := func(context: String) -> void: closed_contexts.append(context)
	overlay.closed.connect(capture)
	var entry: Dictionary = game._catalog_entry("colorata")
	overlay.show_species(entry, CatalogImageLoader.placeholder_texture, true, "latency_probe", "ja")
	assert(await _wait_until(func() -> bool: return not overlay.busy, 900))
	var expected_path: String = game._species_image_path(entry)
	overlay.result_image.set_meta("catalog_loaded_path", expected_path)
	overlay.result_image.set_meta("catalog_request_path", expected_path)
	await overlay.close_overlay()
	var feedback_latency: int = overlay.last_close_feedback_msec - overlay.last_close_input_msec
	var hidden_latency: int = overlay.last_close_hidden_msec - overlay.last_close_input_msec
	assert(feedback_latency >= 0 and feedback_latency < MAX_FIRST_FEEDBACK_MSEC)
	assert(overlay.last_close_first_visual_latency_msec >= 0 and overlay.last_close_first_visual_latency_msec < MAX_FIRST_FEEDBACK_MSEC)
	assert(hidden_latency >= 120 and hidden_latency < 400)
	assert(overlay.last_close_presented_msec >= overlay.last_close_hidden_msec)
	assert(not overlay.visible and overlay.result_image.texture == null and overlay.current_context.is_empty())
	assert(str(overlay.result_image.get_meta("catalog_loaded_path", "")).is_empty())
	assert(str(overlay.result_image.get_meta("catalog_request_path", "")).is_empty())
	game._apply_requested_species_texture(CatalogImageLoader.placeholder_texture, overlay.result_image, expected_path)
	assert(overlay.result_image.texture == null and closed_contexts == ["latency_probe"])
	overlay.closed.disconnect(capture)
	overlay.closed.connect(main_handler)

	# The final NEW card must run through the production handler, finish the
	# round-result queue, persist the formal registration, and restore input.
	var single_id := "kannte"
	for state in [game.discovered,game.species_get_counts,game.greenhouse_available,game.unlocked_species]:state.erase(single_id)
	game.species_get_queue.clear()
	game.pending_round_new_species_ids.assign([single_id])
	game.round_result_species_finalize_queue.clear()
	game.round_result_species_finalize_queue.append({"species_id":single_id,"formalize":true,"is_new":true})
	game.round_result_species_finalize_active=true;game.round_result_species_save_pending=false
	game.get_close_profile_enabled=true;game.get_close_profile_total_msec=-1
	game._show_next_round_result_species()
	assert(await _wait_until(func()->bool:return overlay.visible and game.species_get_active_species_id==single_id,800))
	assert(game.round_result_species_save_pending and game._species_get_count(single_id)==1)
	assert(await _wait_until(func()->bool:return not overlay.busy,900))
	_tap_get_overlay(overlay)
	assert(await _wait_until(func()->bool:return not game.round_result_species_finalize_active,900))
	assert(await _wait_until(func()->bool:return game.get_close_profile_total_msec>=0,900))
	assert(game.get_close_profile_save_count==1 and not game.round_result_species_save_pending)
	var saved_payload=JSON.parse_string(FileAccess.get_file_as_string(game._active_save_path()))
	assert(saved_payload is Dictionary and int(saved_payload.get("species_get_counts",{}).get(single_id,0))==1)

	# Two NEW cards formalize in sequence while the durable write remains batched
	# until the queue is empty. Each card still owns the correct species/context.
	var ids: Array[String] = ["lutea", "laui"]
	for species_id in ids:
		game.discovered.erase(species_id)
		game.species_get_counts.erase(species_id)
		game.greenhouse_available.erase(species_id)
		game.unlocked_species.erase(species_id)
	game.species_get_queue.clear()
	game.pending_round_new_species_ids.assign(ids)
	game.round_result_species_finalize_queue.clear()
	game.round_result_species_finalize_queue.append({"species_id": ids[0], "formalize": true, "is_new": true})
	game.round_result_species_finalize_queue.append({"species_id": ids[1], "formalize": true, "is_new": true})
	game.round_result_species_finalize_active = true
	game.round_result_species_save_pending = false
	game.get_close_profile_total_msec = -1
	game._show_next_round_result_species()
	assert(await _wait_until(func() -> bool: return overlay.visible and game.species_get_active_species_id == ids[0], 800))
	assert(game.round_result_species_save_pending and game._species_get_count(ids[0]) == 1)
	assert(await _wait_until(func() -> bool: return not overlay.busy, 900))
	_tap_get_overlay(overlay)
	assert(await _wait_until(func() -> bool: return overlay.visible and game.species_get_active_species_id == ids[1], 900))
	assert(game.round_result_species_save_pending and game._species_get_count(ids[1]) == 1)
	assert(await _wait_until(func() -> bool: return not overlay.busy, 900))
	_tap_get_overlay(overlay)
	assert(await _wait_until(func() -> bool: return not game.round_result_species_finalize_active, 900))
	assert(await _wait_until(func() -> bool: return game.get_close_profile_total_msec >= 0, 900))
	assert(not game.round_result_species_save_pending and game.round_result_species_finalize_queue.is_empty())
	assert(game.pending_round_new_species_ids.is_empty() and not overlay.visible)
	assert(game.get_close_profile_save_count == 1)
	if not OS.has_feature("web"):
		var main_source:=FileAccess.get_file_as_string("res://scripts/main.gd")
		var queue_start:=main_source.find("func _show_next_round_result_species")
		var queue_end:=main_source.find("func _start_result_new_species_pulse",queue_start)
		assert(main_source.substr(queue_start,queue_end-queue_start).count("_save()") == 1)
	return {"feedback": feedback_latency, "visual": overlay.last_close_first_visual_latency_msec, "hidden": hidden_latency, "profile_total": game.get_close_profile_total_msec}

func _test_gacha_response(game: Node) -> int:
	game.forest_gacha_preview_mode = false
	game.forest_gacha_trial_dev_mode = false
	game.act2_unlocked = true
	game.forest_gacha_unlocked = true
	game.forest_gacha_intro_seen = true
	game.story_progression_state["fantasy_unlocked"] = true
	game.puku_points = 5
	game.forest_gacha_draw_count = 0
	game.forest_gacha_encountered.clear()
	game.last_forest_gacha_persist_started_msec = -1
	var ui = game.forest_gacha_ui
	ui.animation_time_scale = .08
	ui.open_gacha(game.puku_points, game.forest_gacha_draw_count)
	var rotation_before: float = ui.dial_texture.rotation
	ui._request_spin()
	ui._request_spin()
	assert(not ui.busy and ui._spin_feedback_active and ui._spin_turn_tween != null and ui._spin_turn_tween.is_valid())
	assert(ui.spin_request_started_msec >= 0 and ui.spin_started_msec >= ui.spin_request_started_msec)
	assert(ui.last_spin_start_latency_msec >= 0 and ui.last_spin_start_latency_msec < MAX_FIRST_FEEDBACK_MSEC)
	assert(game.last_forest_gacha_persist_started_msec == -1)
	await _await_presented_frame()
	await get_tree().process_frame
	assert(ui.busy and not ui._spin_feedback_active)
	assert(not is_equal_approx(ui.dial_texture.rotation, rotation_before))
	assert(ui.last_spin_visual_latency_msec >= 0 and ui.last_spin_visual_latency_msec < MAX_FIRST_FEEDBACK_MSEC)
	assert(game.last_forest_gacha_persist_started_msec == -1 and game.puku_points == 5 and game.forest_gacha_draw_count == 0)
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var spin_start := main_source.find("func _spin_forest_gacha")
	var spin_end := main_source.find("func _unlock_forest_gacha_series", spin_start)
	var spin_source := main_source.substr(spin_start, spin_end - spin_start)
	assert(spin_source.find("play_spin") < spin_source.find("func _on_forest_gacha_spin_animation_completed"))
	assert(spin_source.find("_sync_arrangement_ui") > spin_source.find("func _on_forest_gacha_spin_animation_completed"))
	var capsule_became_ready:=await _wait_until(func() -> bool: return ui.capsule_ready, 900)
	assert(capsule_became_ready)
	assert(game.last_forest_gacha_persist_started_msec >= ui.spin_first_visual_msec)
	assert(game.puku_points == 4 and game.forest_gacha_draw_count == 1)
	ui.close_gacha()
	return ui.last_spin_visual_latency_msec

func _test_old_seed_harvest_response(game: Node) -> int:
	game.species_get_overlay.visible = false
	game.species_get_queue.clear()
	game.catalog_series_unlock_notice_queue.clear()
	game.catalog_series_unlock_notice_ready.clear()
	game._clear_greenhouse_plants()
	game.discovered.erase("colorata")
	game.species_get_counts.erase("colorata")
	game.greenhouse_available.erase("colorata")
	game.unlocked_species.erase("colorata")
	game.result_new_species_queue.clear()
	game.result_deferred_species_queue.clear()
	game.pending_round_new_species_ids.clear()
	game.round_result_species_finalize_queue.clear()
	game.round_result_species_finalize_active = false
	game.round_result_species_save_pending = false
	game.first_colorata_confirmed = false
	game.first_play_tutorial_active = false
	game.first_play_harvest_guide_active = false
	game.old_seed_reaction_stage = 2
	game.play_active = true
	game.active_seed_type = "old"
	game.total_play_count = 1
	game.play_seeds_remaining = 0
	game.play_spawn_queue = 0
	game.play_seed_animations_pending = 0
	game.play_concurrent_target = 0
	game._spawn_specific_plant("colorata")
	var plant = game.plants.back()
	plant.jelly_checks_enabled = false
	plant.fast_forward_to_diameter(game.TUTORIAL_HARVEST_CM)
	game.old_seed_harvest_guide_active = true
	game.tutorial_harvest_plant = plant
	game._show_tutorial_harvest_spotlight()
	await get_tree().process_frame
	assert(game.tutorial_guide_overlay.visible)
	var harvest_commit_before:int=game.harvest_commit_count
	var start_position: Vector3 = plant.position
	var tap_position: Vector2 = game.camera.unproject_position(plant.global_position + Vector3(0, plant.visual_scale * .48, 0))
	game._try_harvest(tap_position)
	game._try_harvest(tap_position)
	assert(plant.state == "harvested" and bool(plant.get_meta("harvest_feedback_started", false)))
	assert(not game.old_seed_harvest_guide_active and not game.tutorial_guide_overlay.visible)
	assert(game.last_harvest_feedback_latency_msec >= 0 and game.last_harvest_feedback_latency_msec < MAX_FIRST_FEEDBACK_MSEC)
	await _await_presented_frame()
	await get_tree().process_frame
	assert(not plant.position.is_equal_approx(start_position))
	assert(game.last_harvest_presented_latency_msec >= 0 and game.last_harvest_presented_latency_msec < MAX_FIRST_FEEDBACK_MSEC)
	assert(game.harvest_commit_count == harvest_commit_before + 1)
	assert(bool(game.discovered.get("colorata", false)) and "colorata" in game.result_new_species_queue)
	assert(game.old_seed_reaction_stage >= 2 and game.first_colorata_confirmed == false)
	return game.last_harvest_presented_latency_msec

func _wait_until(predicate: Callable, timeout_msec: int) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_msec
	while Time.get_ticks_msec() < deadline:
		if bool(predicate.call()):
			return true
		await get_tree().process_frame
	return bool(predicate.call())

func _tap_get_overlay(overlay:Control)->void:
	var event:=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
	overlay._input(event)

func _await_presented_frame() -> void:
	if DisplayServer.get_name()=="headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
