extends Node

const MainScene = preload("res://main.tscn")
const Localizer = preload("res://scripts/game_localizer.gd")
const StoryProgressionClass = preload("res://scripts/story_progression.gd")
const NORMAL_PATH := "user://first_old_seed_restart_normal_smoke.json"
const ENDLESS_PATH := "user://first_old_seed_restart_endless_smoke.json"


func _ready() -> void:
	_remove_test_file(NORMAL_PATH)
	_remove_test_file(ENDLESS_PATH)

	# Case 1: completing the opening without receiving the old seed must not grant
	# one during an ordinary cold start.
	var game = await _boot_game()
	game._reset_progression_state()
	game.language_code="ja";game.language_selected=true
	game.opening_story_complete=true;game.intro_story_complete=false
	game.first_old_seed_stage=game.FIRST_OLD_SEED_STAGE_NOT_RECEIVED
	game.old_seed_bags=0;game._save()
	await _shutdown_game(game)
	game=await _boot_game()
	assert(not game.intro_story_complete and game.old_seed_bags==0)
	assert(game.first_old_seed_stage==game.FIRST_OLD_SEED_STAGE_NOT_RECEIVED)

	# Case 2: a received but unsown seed remains a single usable seed.
	game.intro_story_complete=true;game.old_seed_bags=1
	game.first_old_seed_stage=game.FIRST_OLD_SEED_STAGE_READY
	game.tutorial_steps["play_open_guide"]=true
	game.login_bonus_date=Time.get_date_string_from_system();game._save()
	await _shutdown_game(game)
	game=await _boot_game()
	_assert_retry_ready(game)
	for locale in Localizer.SUPPORTED_LANGUAGES:
		game._set_language(locale);game._update_play_ui()
		assert(game.play_open_button.text==Localizer.text(locale,"play_first_old_seed"))
	game._set_language("ja")

	# Case 3: closing immediately after sowing consumes the runtime seed, then a
	# new process restores exactly one retry because Plant nodes are not saved.
	game._open_play_modal()
	assert(game.play_active and game.old_seed_bags==0)
	assert(game.first_old_seed_stage==game.FIRST_OLD_SEED_STAGE_GROWING)
	await _shutdown_game(game)
	game=await _boot_game()
	_assert_retry_ready(game)
	# The recovered main button must start the old-seed retry directly; the
	# unusable "choose a seed" modal with only its close button must not appear.
	game._open_play_modal()
	assert(game.play_active and not game.play_overlay.visible)
	assert(game.old_seed_bags==0 and game.first_old_seed_stage==game.FIRST_OLD_SEED_STAGE_GROWING)
	await _shutdown_game(game)
	game=await _boot_game()
	_assert_retry_ready(game)

	# Case 9: migrate the exact legacy soft-lock (no stage key, no stock, no GET)
	# and persist it once. Repeated cold starts must never duplicate the bag.
	var legacy_payload:=_read_payload()
	legacy_payload.erase("first_old_seed_stage")
	legacy_payload["intro_story_complete"]=true
	legacy_payload["opening_story_complete"]=true
	legacy_payload["total_play_count"]=0
	legacy_payload["old_seed_bags"]=0
	legacy_payload["first_colorata_confirmed"]=false
	legacy_payload["trio_originals_confirmed"]=false
	legacy_payload["encyclopedia_unlocked"]=false
	legacy_payload["habitat_unlocked"]=false
	legacy_payload["mystery_items_acquired"]=false
	legacy_payload["first_habitat_gift_claimed"]=false
	legacy_payload["discovered"]={}
	legacy_payload["species_get_counts"]={}
	legacy_payload["bests"]={}
	_write_payload(legacy_payload)
	await _shutdown_game(game)
	game=await _boot_game()
	_assert_retry_ready(game)
	assert(_read_payload().get("first_old_seed_stage","")==game.FIRST_OLD_SEED_STAGE_READY)
	await _shutdown_game(game)
	game=await _boot_game()
	_assert_retry_ready(game)
	assert(game.old_seed_bags==1)

	# Case 4: an interruption after sprouting restarts the one-seed tutorial.
	game._start_greenhouse_play("old")
	assert(await _wait_until(func()->bool:return game.plants.size()==1))
	assert(str(game.plants[0].state) in ["seed","growing"])
	await _shutdown_game(game)
	game=await _boot_game()
	_assert_retry_ready(game)

	# Case 5: diameter is intentionally not serialized, so an interruption after
	# visible growth also returns to a clean single-seed retry.
	game._start_greenhouse_play("old")
	assert(await _wait_until(func()->bool:return game.plants.size()==1))
	game.plants[0].fast_forward_to_diameter(30.0)
	assert(float(game.plants[0].diameter_cm)>=30.0)
	await _shutdown_game(game)
	game=await _boot_game()
	_assert_retry_ready(game)

	# Case 6: persist the formal GET immediately at harvest, before the cleanup
	# timer finishes the round. A cold start must not grant another seed or GET.
	game._start_greenhouse_play("old")
	assert(await _wait_until(func()->bool:return game.plants.size()==1 and str(game.plants[0].state)=="growing"))
	var first_plant=game.plants[0]
	first_plant.fast_forward_to_diameter(game.TUTORIAL_HARVEST_CM+4.0)
	var harvest_commit_before:int=game.harvest_commit_count
	first_plant.harvest()
	assert(await _wait_until(func()->bool:return game.harvest_commit_count==harvest_commit_before+1))
	assert(game.first_old_seed_stage==game.FIRST_OLD_SEED_STAGE_HARVESTED)
	assert(game._species_get_count(game.FIRST_STORY_SPECIES_ID)==1)
	await _shutdown_game(game)
	game=await _boot_game()
	assert(not game.play_active and game.plants.is_empty() and game.old_seed_bags==0)
	assert(game.total_play_count==1 and game._species_get_count(game.FIRST_STORY_SPECIES_ID)==1)
	assert(game.first_old_seed_stage==game.FIRST_OLD_SEED_STAGE_HARVESTED)
	await _finish_opening_and_wait_for(game,func()->bool:return game.species_get_overlay.visible)
	assert(game.species_get_active_context=="first_colorata")

	# Case 7a: killing the process while the GET card is visible re-shows only the
	# card; ownership remains exactly one.
	await _shutdown_game(game)
	game=await _boot_game()
	await _finish_opening_and_wait_for(game,func()->bool:return game.species_get_overlay.visible)
	assert(game.species_get_active_context=="first_colorata")
	assert(game._species_get_count(game.FIRST_STORY_SPECIES_ID)==1)
	assert(await _wait_until(func()->bool:return not game.species_get_overlay.busy))
	await game.species_get_overlay.close_overlay()
	assert(await _wait_until(func()->bool:return game.scripted_dialog_kind=="first_colorata_discovery"))
	assert(game.first_old_seed_stage==game.FIRST_OLD_SEED_STAGE_CARD_CLOSED)

	# Case 7b/D: after the card is closed, a cold start resumes the discovery
	# conversation from page one without showing or awarding the card again.
	await _shutdown_game(game)
	game=await _boot_game()
	await _finish_opening_and_wait_for(game,func()->bool:return game.scripted_dialog_kind=="first_colorata_discovery")
	assert(not game.species_get_overlay.visible)
	assert(game.scripted_dialog_index==0)
	assert(game._species_get_count(game.FIRST_STORY_SPECIES_ID)==1)
	for locale in Localizer.SUPPORTED_LANGUAGES:
		assert(not Localizer.text(locale,"story_colorata_1").is_empty())
		assert(not Localizer.text(locale,"story_colorata_2",[Localizer.species_name(locale,game._catalog_entry(game.FIRST_STORY_SPECIES_ID))]).is_empty())

	# Case 8/11: completing the discovery makes the stage terminal. Subsequent
	# boots continue the normal story and never restore an old seed.
	while game.scripted_dialog_kind=="first_colorata_discovery":
		game._advance_scripted_dialog()
		await get_tree().process_frame
	assert(game.first_colorata_confirmed)
	assert(game.first_old_seed_stage==game.FIRST_OLD_SEED_STAGE_CONFIRMED)
	await _shutdown_game(game)
	game=await _boot_game()
	assert(game.first_colorata_confirmed and game.first_old_seed_stage==game.FIRST_OLD_SEED_STAGE_CONFIRMED)
	assert(game.old_seed_bags==0 and not game._first_old_seed_play_pending())

	# Case 12: a normal 12-seed round remains intentionally abandoned on restart.
	# The one-puku start charge and a committed harvest reward are each persisted
	# once, while runtime plants cannot duplicate either transaction.
	_configure_normal_round_ready(game)
	game._save()
	await _shutdown_game(game)
	game=await _boot_game()
	game._finish_opening()
	await get_tree().process_frame
	await get_tree().process_frame
	var balance_before_round:int=game.puku_balance_units
	game._start_greenhouse_play("normal")
	assert(game.play_active and game.puku_balance_units==balance_before_round-game.NORMAL_ROUND_COST_UNITS)
	await get_tree().create_timer(0.45).timeout
	assert(await _wait_until(func()->bool:return not game.plants.is_empty()))
	var normal_plant=game.plants[0]
	var normal_species_id:=str(normal_plant.data.get("species_id",""))
	game.discovered[normal_species_id]=true;game.species_get_counts[normal_species_id]=1;game._save()
	normal_plant.fast_forward_to_diameter(30.0)
	var normal_commit_before:int=game.harvest_commit_count
	normal_plant.harvest()
	assert(await _wait_until(func()->bool:return game.harvest_commit_count==normal_commit_before+1))
	var balance_after_harvest:int=game.puku_balance_units
	var count_after_harvest:int=game._species_get_count(normal_species_id)
	assert(count_after_harvest==2)
	await _shutdown_game(game)
	game=await _boot_game()
	assert(not game.play_active and game.plants.is_empty())
	assert(game.puku_balance_units==balance_after_harvest)
	assert(game._species_get_count(normal_species_id)==count_after_harvest)
	await _shutdown_game(game)
	game=await _boot_game()
	assert(game.puku_balance_units==balance_after_harvest)
	assert(game._species_get_count(normal_species_id)==count_after_harvest)

	await _shutdown_game(game)
	_remove_test_file(NORMAL_PATH)
	_remove_test_file(ENDLESS_PATH)
	print("FIRST_OLD_SEED_RESTART_SMOKE_OK before_receive=true ready=true sow_restart=true sprout_restart=true growth_restart=true legacy_softlock_repaired=true single_seed=true harvest_persisted=true get_card_resume=true dialog_resume=true confirmed=true normal_round_no_double_charge_or_reward=true languages=ja+hiragana+en")
	get_tree().quit()


func _boot_game() -> Node:
	var game=MainScene.instantiate()
	game.endless_greenhouse.set_save_paths_for_test(NORMAL_PATH,ENDLESS_PATH)
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled":false,"se_enabled":false})
	return game


func _shutdown_game(game:Node)->void:
	if is_instance_valid(game):game.free()
	await get_tree().process_frame
	await get_tree().process_frame


func _assert_retry_ready(game:Node)->void:
	assert(not game.play_active and game.plants.is_empty())
	assert(game.total_play_count==0 and game.old_seed_bags==1)
	assert(game.first_old_seed_stage==game.FIRST_OLD_SEED_STAGE_READY)
	assert(game._first_old_seed_play_pending())


func _finish_opening_and_wait_for(game:Node,predicate:Callable)->void:
	game._finish_opening()
	assert(await _wait_until(predicate))


func _wait_until(predicate:Callable,max_frames:=240)->bool:
	for _frame in range(max_frames):
		if predicate.call():return true
		await get_tree().process_frame
	return bool(predicate.call())


func _configure_normal_round_ready(game:Node)->void:
	game.opening_story_complete=true;game.intro_story_complete=true
	game.first_colorata_confirmed=true;game.first_old_seed_stage=game.FIRST_OLD_SEED_STAGE_CONFIRMED
	game.trio_originals_confirmed=true;game.total_play_count=maxi(4,game.total_play_count)
	game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.habitat_arrival_started=true
	game.habitat_awakened=true;game.habitat_awakening_event_complete=true
	game.habitat_tutorial_started=true;game.habitat_tutorial_complete=true;game.habitat_tutorial_returned_to_greenhouse=true
	game.seed_shop_open=true;game.mystery_items_acquired=true;game.mystery_catalog_tutorial_complete=true
	game.normal_play_tutorial_complete=true;game.seed_pod_gauge_discovery_complete=true;game.seed_pod_first_reward_seen=true
	game.initial_seed_stock_notice_complete=true;game.puku_buyback_tutorial_complete=true;game.puku_gauge_intro_complete=true
	game.first_habitat_gift_claimed=true;game.old_seed_bags=0;game.puku_balance_units=5000
	game.current_mode="greenhouse";game.play_active=false;game.story_progression_state=StoryProgressionClass.default_runtime_state()
	game.tutorial_steps[game.ENDLESS_AUTO_SOW_TUTORIAL_STEP]=true


func _read_payload()->Dictionary:
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(ENDLESS_PATH))
	assert(parsed is Dictionary)
	return parsed


func _write_payload(payload:Dictionary)->void:
	var file:=FileAccess.open(ENDLESS_PATH,FileAccess.WRITE)
	assert(file!=null)
	file.store_string(JSON.stringify(payload));file.close()


func _remove_test_file(path:String)->void:
	if FileAccess.file_exists(path):assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path))==OK)
