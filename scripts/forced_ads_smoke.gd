extends Node

const PolicyClass = preload("res://scripts/forced_interstitial_policy.gd")
const InterstitialServiceClass = preload("res://scripts/interstitial_ad_service.gd")
const Localizer = preload("res://scripts/game_localizer.gd")
const StoryDevPanelClass = preload("res://scripts/story_dev_panel.gd")
const MainClass = preload("res://scripts/main.gd")
const StoryProgressionClass = preload("res://scripts/story_progression.gd")


class FakeAdmob:
	extends Node
	signal interstitial_ad_loaded(ad_info, response_info)
	signal interstitial_ad_failed_to_load(ad_info, error_data)
	signal interstitial_ad_showed_full_screen_content(ad_info)
	signal interstitial_ad_failed_to_show_full_screen_content(ad_info, error_data)
	signal interstitial_ad_dismissed_full_screen_content(ad_info)

	var loaded := false
	var load_count := 0
	var show_count := 0
	var remove_count := 0

	func is_interstitial_ad_loaded() -> bool:return loaded
	func load_interstitial_ad() -> void:load_count+=1;loaded=false
	func show_interstitial_ad() -> void:assert(loaded);show_count+=1;loaded=false
	func remove_interstitial_ad() -> void:remove_count+=1;loaded=false


class FakeInterstitialRuntime:
	extends RefCounted

	var available := true
	var present_count := 0
	var last_context := ""

	func try_present(context:String) -> bool:
		present_count+=1
		last_context=context
		return available

	func diagnostic_snapshot() -> Dictionary:
		return {"state":"READY" if available else "UNAVAILABLE","available":available}


class FakeGachaSurface:
	extends Control
	var transition_ready := true

	func is_ready_for_forced_interstitial_transition() -> bool:return transition_ready


class FakeFusionSurface:
	extends Control
	var transition_ready := true

	func is_ready_for_forced_interstitial_transition() -> bool:return transition_ready


func _ready() -> void:
	_test_counter_policy()
	await _test_interstitial_lifecycle()
	_test_main_transition_regression()
	await _test_story_panel_scope()
	_test_integration_contracts()
	print("FORCED_ADS_SMOKE_OK independent_counters=true persisted_modulo=true fifth_transition=true unavailable_skips=true separation=true lifecycle=true removal_iap=true internal_story_gate=true")
	get_tree().quit()


func _test_counter_policy() -> void:
	var policy := PolicyClass.new()
	var presentation_actions:Array[int]=[]
	policy.restore_counts(0,0)
	for action_index in range(1,16):
		var interval_due:=policy.record_success(PolicyClass.SOURCE_FOREST_GACHA)
		assert(interval_due==(action_index%PolicyClass.DISPLAY_INTERVAL==0))
		if interval_due:
			assert(policy.consume_transition_candidate(PolicyClass.SOURCE_FOREST_GACHA))
			presentation_actions.append(action_index);policy.mark_presented()
	assert(presentation_actions==[5,10,15],"gacha interstitial cadence changed: %s"%[presentation_actions])
	var fusion_presentation_actions:Array[int]=[]
	policy.restore_counts(0,0)
	for action_index in range(1,16):
		var interval_due:=policy.record_success(PolicyClass.SOURCE_FUSION_LAB)
		assert(interval_due==(action_index%PolicyClass.DISPLAY_INTERVAL==0))
		if interval_due:
			assert(policy.consume_transition_candidate(PolicyClass.SOURCE_FUSION_LAB))
			fusion_presentation_actions.append(action_index);policy.mark_presented()
	assert(fusion_presentation_actions==[5,10,15],"fusion interstitial cadence changed: %s"%[fusion_presentation_actions])
	policy.restore_counts(0, 0)
	for draw_index in range(1, PolicyClass.DISPLAY_INTERVAL):
		assert(not policy.record_success(PolicyClass.SOURCE_FOREST_GACHA))
		assert(policy.success_count(PolicyClass.SOURCE_FOREST_GACHA) == draw_index)
		assert(not policy.has_pending_transition(PolicyClass.SOURCE_FOREST_GACHA))
	assert(policy.success_count(PolicyClass.SOURCE_FUSION_LAB) == 0)
	assert(policy.record_success(PolicyClass.SOURCE_FOREST_GACHA))
	assert(policy.transition_candidate_status(PolicyClass.SOURCE_FOREST_GACHA)=="ready")
	assert(policy.success_count(PolicyClass.SOURCE_FOREST_GACHA) == 0)
	assert(policy.consume_transition_candidate(PolicyClass.SOURCE_FOREST_GACHA))
	assert(not policy.consume_transition_candidate(PolicyClass.SOURCE_FOREST_GACHA))

	# Four saved successes survive a restart, while a pending presentation does
	# not. The next completed action is the fifth and creates a fresh candidate.
	policy.restore_counts(4, 2)
	assert(not policy.has_pending_transition(PolicyClass.SOURCE_FOREST_GACHA))
	assert(policy.success_count(PolicyClass.SOURCE_FUSION_LAB) == 2)
	assert(policy.record_success(PolicyClass.SOURCE_FOREST_GACHA))
	assert(policy.has_pending_transition(PolicyClass.SOURCE_FOREST_GACHA))
	policy.restore_counts(policy.success_count(PolicyClass.SOURCE_FOREST_GACHA), 2)
	assert(not policy.has_pending_transition(PolicyClass.SOURCE_FOREST_GACHA))

	# A shown gacha ad and an immediately due fusion ad cannot be back-to-back.
	policy.restore_counts(4, 4)
	assert(policy.record_success(PolicyClass.SOURCE_FOREST_GACHA))
	assert(policy.consume_transition_candidate(PolicyClass.SOURCE_FOREST_GACHA))
	policy.mark_presented()
	assert(policy.record_success(PolicyClass.SOURCE_FUSION_LAB))
	assert(not policy.consume_transition_candidate(PolicyClass.SOURCE_FUSION_LAB))

	# A completed game action separates later full-screen ads without a clock-
	# based cooldown. The fifth following fusion can therefore display normally.
	for fusion_index in range(PolicyClass.DISPLAY_INTERVAL):
		var reached := policy.record_success(PolicyClass.SOURCE_FUSION_LAB)
		assert(reached == (fusion_index == PolicyClass.DISPLAY_INTERVAL - 1))
	assert(policy.consume_transition_candidate(PolicyClass.SOURCE_FUSION_LAB))

	# Removal keeps the persisted modulo counter deterministic but never creates
	# a forced-ad candidate.
	policy.restore_counts(4, 4)
	assert(policy.record_success(PolicyClass.SOURCE_FOREST_GACHA, true))
	assert(not policy.has_pending_transition(PolicyClass.SOURCE_FOREST_GACHA))
	assert(not policy.consume_transition_candidate(PolicyClass.SOURCE_FOREST_GACHA, true))
	assert(not policy.record_success("unknown_source"))
	policy.restore_counts(4,0)
	assert(policy.record_success(PolicyClass.SOURCE_FOREST_GACHA))
	assert(policy.discard_transition_candidate(PolicyClass.SOURCE_FOREST_GACHA))
	assert(not policy.has_pending_transition(PolicyClass.SOURCE_FOREST_GACHA))


func _test_interstitial_lifecycle() -> void:
	var fake := FakeAdmob.new()
	add_child(fake)
	var service := InterstitialServiceClass.new()
	var starts := [0]
	var finishes: Array[Dictionary] = []
	service.presentation_started.connect(func() -> void:starts[0]+=1)
	service.presentation_finished.connect(func(context:String, displayed:bool) -> void:
		finishes.append({"context":context,"displayed":displayed})
	)
	add_child(service)
	service.configure_for_test(fake)
	assert(service.state == InterstitialServiceClass.State.LOADING)
	assert(fake.load_count == 1)
	# A tap while loading never queues a later surprise and never duplicates the
	# in-flight load.
	assert(not service.try_present("forest_gacha"))
	assert(fake.load_count == 1 and fake.show_count == 0)
	fake.loaded=true
	fake.interstitial_ad_loaded.emit(null,null)
	assert(service.is_available() and fake.show_count == 0)
	assert(service.try_present("forest_gacha"))
	assert(service.is_showing() and fake.show_count == 1)
	assert(not service.try_present("forest_gacha"))
	fake.interstitial_ad_showed_full_screen_content.emit(null)
	fake.interstitial_ad_showed_full_screen_content.emit(null)
	assert(starts[0] == 1)
	fake.interstitial_ad_dismissed_full_screen_content.emit(null)
	assert(finishes.size() == 1 and finishes[0].context == "forest_gacha" and finishes[0].displayed)
	assert(service.state == InterstitialServiceClass.State.LOADING and fake.load_count == 2)
	fake.interstitial_ad_dismissed_full_screen_content.emit(null)
	assert(finishes.size() == 1 and fake.load_count == 2)

	# A failed load remains playable. The next eligible transition starts one
	# fresh preload but is itself skipped instead of being shown later.
	fake.interstitial_ad_failed_to_load.emit(null,{"code":1,"domain":"load.test"})
	assert(service.state == InterstitialServiceClass.State.UNAVAILABLE)
	var failed_load_diag:Dictionary=service.diagnostic_snapshot()
	assert(failed_load_diag.last_event=="load_failed" and failed_load_diag.last_error_stage=="load")
	assert(int(failed_load_diag.last_error_code)==1 and failed_load_diag.last_error_domain=="load.test")
	assert(not service.try_present("fusion_lab"))
	assert(service.state == InterstitialServiceClass.State.LOADING and fake.load_count == 3)
	fake.loaded=true
	fake.interstitial_ad_loaded.emit(null,null)
	assert(fake.show_count == 1)
	assert(service.try_present("fusion_lab"))
	fake.interstitial_ad_showed_full_screen_content.emit(null)
	fake.interstitial_ad_failed_to_show_full_screen_content.emit(null,{"code":2,"domain":"show.test"})
	await get_tree().process_frame
	assert(finishes.size() == 2 and finishes[-1].context == "fusion_lab" and not finishes[-1].displayed)
	assert(service.state == InterstitialServiceClass.State.LOADING and fake.load_count == 4)
	var failed_show_diag:Dictionary=service.diagnostic_snapshot()
	assert(failed_show_diag.last_error_stage=="show" and int(failed_show_diag.last_error_code)==2)
	assert(failed_show_diag.last_error_domain=="show.test")
	fake.interstitial_ad_failed_to_show_full_screen_content.emit(null,{"code":2,"domain":"show.test"})
	assert(finishes.size() == 2 and fake.load_count == 4)

	service.queue_free()
	fake.queue_free()
	await get_tree().process_frame


func _test_main_transition_regression() -> void:
	var game:=MainClass.new()
	game.current_mode="greenhouse"
	game.story_progression_state=StoryProgressionClass.default_runtime_state()
	# This event is intentionally waiting for a habitat visit. It is not an
	# active greenhouse story and must not suppress a natural gacha transition.
	StoryProgressionClass.queue_story_event(game.story_progression_state,StoryProgressionClass.EVENT_ACT3_BATTLE_INTRO)
	assert(StoryProgressionClass.peek_story_event(game.story_progression_state)==StoryProgressionClass.EVENT_ACT3_BATTLE_INTRO)
	assert(game._forced_interstitial_transition_block_reason().is_empty())
	var runtime:=FakeInterstitialRuntime.new()
	game.interstitial_ad_service=runtime
	game.forced_interstitial_policy=PolicyClass.new()
	game.forced_interstitial_policy.restore_counts(4,0)
	assert(game._record_forced_interstitial_success(PolicyClass.SOURCE_FOREST_GACHA))
	assert(game._try_present_forced_interstitial(PolicyClass.SOURCE_FOREST_GACHA))
	assert(runtime.present_count==1 and runtime.last_context==PolicyClass.SOURCE_FOREST_GACHA)

	# The originating surface is allowed only after its result flow has returned
	# to an idle main page. Other sources and busy result states remain blocked.
	var gacha_surface:=FakeGachaSurface.new();gacha_surface.visible=true;game.forest_gacha_ui=gacha_surface
	assert(game._forced_interstitial_transition_block_reason()=="gacha_open")
	assert(game._forced_interstitial_transition_block_reason(PolicyClass.SOURCE_FOREST_GACHA).is_empty())
	gacha_surface.transition_ready=false
	assert(game._forced_interstitial_transition_block_reason(PolicyClass.SOURCE_FOREST_GACHA)=="gacha_busy")
	gacha_surface.visible=false
	var fusion_surface:=FakeFusionSurface.new();fusion_surface.visible=true;game.fusion_lab_ui=fusion_surface
	assert(game._forced_interstitial_transition_block_reason()=="fusion_open")
	assert(game._forced_interstitial_transition_block_reason(PolicyClass.SOURCE_FUSION_LAB).is_empty())
	fusion_surface.transition_ready=false
	assert(game._forced_interstitial_transition_block_reason(PolicyClass.SOURCE_FUSION_LAB)=="fusion_busy")
	fusion_surface.visible=false;game.forest_gacha_ui=null;game.fusion_lab_ui=null;gacha_surface.free();fusion_surface.free()

	# A story that actually owns the foreground skips exactly this due event and
	# never reappears after the story is closed.
	game.forced_interstitial_policy.restore_counts(4,0)
	assert(game._record_forced_interstitial_success(PolicyClass.SOURCE_FOREST_GACHA))
	game.scripted_dialog_kind="active_story"
	assert(not game._try_present_forced_interstitial(PolicyClass.SOURCE_FOREST_GACHA))
	assert(game.forced_ad_last_decision=="skipped_unsafe")
	assert(game.forced_ad_last_block_reason=="scripted_dialog")
	assert(not game.forced_interstitial_policy.has_pending_transition(PolicyClass.SOURCE_FOREST_GACHA))
	game.scripted_dialog_kind=""
	assert(not game._try_present_forced_interstitial(PolicyClass.SOURCE_FOREST_GACHA))
	assert(runtime.present_count==1)

	# An unavailable ad is consumed once and triggers no delayed presentation.
	runtime.available=false
	game.forced_interstitial_policy.restore_counts(4,0)
	assert(game._record_forced_interstitial_success(PolicyClass.SOURCE_FOREST_GACHA))
	assert(not game._try_present_forced_interstitial(PolicyClass.SOURCE_FOREST_GACHA))
	assert(game.forced_ad_last_decision=="skipped_ad_not_ready")
	assert(game.forced_ad_last_block_reason=="ad_unavailable")
	assert(not game.forced_interstitial_policy.has_pending_transition(PolicyClass.SOURCE_FOREST_GACHA))
	game.free()


func _test_story_panel_scope() -> void:
	var internal_panel := StoryDevPanelClass.new()
	add_child(internal_panel)
	await get_tree().process_frame
	assert(internal_panel.find_child("StoryDevReset", true, false) != null)
	assert(internal_panel.find_child("StoryDevSpawn101", true, false) == null)
	internal_panel.queue_free()
	await get_tree().process_frame

	var full_development_panel := StoryDevPanelClass.new()
	full_development_panel.allow_species_spawn = true
	add_child(full_development_panel)
	await get_tree().process_frame
	assert(full_development_panel.find_child("StoryDevSpawn101", true, false) != null)
	full_development_panel.queue_free()
	await get_tree().process_frame


func _test_integration_contracts() -> void:
	for locale in ["ja","hiragana","en"]:
		for key in [
			"forced_ads_removal_name",
			"forced_ads_removal_description",
			"forced_ads_removal_buy",
			"forced_ads_removal_owned",
			"forced_ads_removal_success",
		]:
			var args:Array=["$0.99"] if key=="forced_ads_removal_buy" else []
			assert(Localizer.text(locale,key,args) != key)
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(main_source.contains('const FORCED_ADS_REMOVAL_PRODUCT_ID := "forced_ads_removal"'))
	assert(main_source.contains('"forest_gacha_interstitial_count":forest_gacha_interstitial_count'))
	assert(main_source.contains('"fusion_interstitial_count":fusion_interstitial_count'))
	assert(main_source.contains('if mode=="live":_record_forced_interstitial_success'))
	assert(main_source.contains('_record_forced_interstitial_success(ForcedInterstitialPolicyClass.SOURCE_FUSION_LAB)'))
	assert(main_source.contains('_schedule_forced_interstitial_transition(ForcedInterstitialPolicyClass.SOURCE_FOREST_GACHA)'))
	assert(main_source.contains('_schedule_forced_interstitial_transition(ForcedInterstitialPolicyClass.SOURCE_FUSION_LAB)'))
	assert(main_source.contains('forest_gacha_ui.resume_after_species_reveal()'))
	assert(main_source.contains('func _resume_fusion_lab_after_get()'))
	assert(main_source.contains('_forced_interstitial_transition_block_reason(source)'))
	assert(main_source.contains('_try_present_forced_interstitial(source)'))
	assert(main_source.contains('internal_forced_ad_diagnostic_button.name="InternalForcedAdDiagnosticButton"'))
	assert(not main_source.contains('if not str(StoryProgressionClass.peek_story_event(story_progression_state)).is_empty():return false'))
	assert(main_source.contains('BuildProfileClass.internal_test_story_jump_enabled()'))
	assert(main_source.contains('internal_story_jump_button.name="InternalStoryJumpButton"'))
	assert(main_source.contains('story_dev_panel.allow_species_spawn=_trial_dev_controls_enabled()'))
	var profile_source := FileAccess.get_file_as_string("res://scripts/build_profile.gd")
	assert(profile_source.contains('const INTERNAL_TEST_STORY_JUMP_FEATURE := "puku_internal_test_story_jump"'))
	var arrangement_source := FileAccess.get_file_as_string("res://scripts/arrangement_ui.gd")
	assert(arrangement_source.contains('card.name="ForcedAdsRemovalCard"'))
	assert(arrangement_source.contains('buy.name="ForcedAdsRemovalBuyButton"'))
