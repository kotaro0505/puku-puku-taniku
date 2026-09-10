extends Node

const Localizer=preload("res://scripts/game_localizer.gd")

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.old_seed_bags=1;game.total_play_count=0;game.intro_overlay.visible=false;game.shop_overlay.visible=false
	game._start_greenhouse_play("old");await get_tree().create_timer(.4).timeout;game.set_process(false);game._begin_first_play_tutorial()
	assert(game.play_active and game.first_play_tutorial_active and game.plants.size()==game.OLD_SEED_GERMINATION_COUNT)
	assert(game.first_tutorial_species_id in game.COMMON_SPECIES_IDS)
	for plant in game.plants:assert(not plant.jelly_checks_enabled and str(plant.data.species_id)==game.first_tutorial_species_id)
	var tracked=game.plants[0];var age_before_first:float=tracked.age
	var tracked_center:Vector2=game.camera.unproject_position(tracked.global_position+Vector3(0,tracked.visual_scale*.48,0));game._try_harvest(tracked_center);assert(tracked.state=="growing")
	game._process(2.99);assert(not game.first_play_tutorial_dialog_visible and tracked.age>age_before_first)
	game._process(.02);assert(game.first_play_tutorial_dialog_visible and game.tutorial_guide_overlay.visible)
	for message_index in range(game.FIRST_PLAY_TUTORIAL_MESSAGE_KEYS.size()):
		var message_key:=str(game.FIRST_PLAY_TUTORIAL_MESSAGE_KEYS[message_index])
		assert(game.tutorial_guide_message.text==Localizer.text(game.language_code,message_key))
		for locale in Localizer.SUPPORTED_LANGUAGES:
			assert(not Localizer.text(locale,message_key).is_empty())
		assert(game.tutorial_guide_button.visible and game.tutorial_guide_button.icon==null and game.tutorial_guide_button.position==Vector2.ZERO and game.tutorial_guide_button.size==get_viewport().get_visible_rect().size)
		var paused_age:float=tracked.age;game._process(4.0);assert(is_equal_approx(tracked.age,paused_age))
		game.tutorial_guide_button.pressed.emit()
		if message_index<game.FIRST_PLAY_TUTORIAL_MESSAGE_KEYS.size()-1:
			assert(game.first_play_tutorial_dialog_visible and game.tutorial_guide_overlay.visible)
			game._process(1.0);assert(is_equal_approx(tracked.age,paused_age))
		else:assert(not game.first_play_tutorial_dialog_visible and not game.tutorial_guide_overlay.visible)
	assert(game.first_play_tutorial_sequence_complete and bool(game.tutorial_steps.get("first_play_growth_dialogs",false)))
	assert(not bool(game.tutorial_steps.get("first_harvest_guide",false)))
	for plant in game.plants:assert(plant.jelly_checks_enabled)
	game.play_seeds_remaining=0;game.play_spawn_queue=0;game.play_seed_animations_pending=0;game.play_harvest_count=0;game.last_jelly_claim_msec=-1000000000
	for jelly_index in range(4):
		game.plants[jelly_index].jelly()
		assert(game.first_play_harvest_guide_active==(jelly_index==3))
	var growing:Array=game._first_play_growing_plants();assert(growing.size()==3)
	assert(game.tutorial_guide_overlay.visible and game.tutorial_guide_overlay.mouse_filter==Control.MOUSE_FILTER_IGNORE and not game.tutorial_guide_button.visible and game.tutorial_guide_button.icon==null)
	assert(not game.tutorial_guide_finger.visible and game.tutorial_guide_message.text==Localizer.text(game.language_code,"tutorial_harvest_tap") and game.tutorial_guide_shade.material==game.first_play_harvest_spotlight_material)
	assert(int(game.first_play_harvest_spotlight_material.get_shader_parameter("focus_count"))==3 and not game.has_method("_should_trigger_first_play_rescue"))
	var guide_age:float=growing[0].age;game._process(3.0);assert(is_equal_approx(growing[0].age,guide_age))
	var harvest_target=growing[1];var harvest_center:Vector2=game.camera.unproject_position(harvest_target.global_position+Vector3(0,harvest_target.visual_scale*.48,0));game._try_harvest(harvest_center)
	assert(harvest_target.state=="harvested" and game.first_play_has_harvested and not game.first_play_harvest_guide_active and game.play_harvest_count==1 and not game.tutorial_guide_overlay.visible and bool(game.tutorial_steps.get("first_harvest_guide",false)))
	assert(bool(game.discovered.get(game.first_tutorial_species_id,false)))
	game._reset_progression_state();game.intro_story_complete=true;game.old_seed_bags=1;game.total_play_count=0;game.intro_overlay.visible=false;game.shop_overlay.visible=false
	game._start_greenhouse_play("old");await get_tree().create_timer(.4).timeout;game.set_process(false);game._begin_first_play_tutorial();game._process(3.01)
	for message_index in range(game.FIRST_PLAY_TUTORIAL_MESSAGE_KEYS.size()):game.tutorial_guide_button.pressed.emit()
	assert(game.first_play_tutorial_sequence_complete and not game.first_play_has_harvested and game.play_harvest_count==0)
	var self_harvest_target=game._first_play_growing_plants()[0];var self_harvest_center:Vector2=game.camera.unproject_position(self_harvest_target.global_position+Vector3(0,self_harvest_target.visual_scale*.48,0));game._try_harvest(self_harvest_center)
	assert(self_harvest_target.state=="harvested" and game.first_play_has_harvested and game.play_harvest_count==1 and not game.first_play_harvest_guide_active and not game.tutorial_guide_overlay.visible)
	for jelly_index in range(3):game._first_play_growing_plants()[0].jelly()
	assert(game._first_play_growing_plants().size()==3 and not game._maybe_activate_first_play_harvest_guide() and not game.first_play_harvest_guide_active and not game.tutorial_guide_overlay.visible)
	game.queue_free();await get_tree().process_frame
	game=load("res://main.tscn").instantiate();add_child(game);await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game._start_intro_story()
	game.intro_continue_button.pressed.emit();game.intro_continue_button.pressed.emit()
	assert(game.intro_story_complete and game.old_seed_bags==3 and game.tutorial_guide_overlay.visible and str(game.tutorial_guide_button.get_meta("target",""))=="play_open")
	game.tutorial_guide_button.pressed.emit();await get_tree().process_frame
	assert(game.play_overlay.visible and game.tutorial_guide_overlay.visible and str(game.tutorial_guide_button.get_meta("target",""))=="old_seed")
	game.tutorial_guide_button.pressed.emit();await get_tree().create_timer(.5).timeout
	assert(game.play_active and game.plants.size()==game.OLD_SEED_GERMINATION_COUNT and game.play_seeds_remaining==0 and game.play_spawn_queue==0 and game.play_seed_animations_pending==0)
	await get_tree().create_timer(game.FIRST_PLAY_TUTORIAL_INITIAL_DELAY+.2).timeout
	assert(game.first_play_tutorial_dialog_visible)
	for message_index in range(game.FIRST_PLAY_TUTORIAL_MESSAGE_KEYS.size()):game.tutorial_guide_button.pressed.emit()
	assert(game.first_play_tutorial_sequence_complete and game.play_seeds_remaining==0 and game.play_spawn_queue==0 and game.play_seed_animations_pending==0 and game.plants.size()==game.OLD_SEED_GERMINATION_COUNT)
	for tap_index in range(game.OLD_SEED_GERMINATION_COUNT):
		var plant_count_before:int=game.plants.size()
		var tap_target=game.plants[0]
		var tap_position:Vector2=game.camera.unproject_position(tap_target.global_position+Vector3(0,tap_target.visual_scale*.48,0))
		var physical_tap_position:Vector2=game.get_viewport().get_screen_transform()*tap_position
		var press:=InputEventScreenTouch.new();press.position=physical_tap_position;press.pressed=true
		var release:=InputEventScreenTouch.new();release.position=physical_tap_position;release.pressed=false
		Input.parse_input_event(press);await get_tree().process_frame
		Input.parse_input_event(release);await get_tree().process_frame
		assert(game.plants.size()==plant_count_before-1)
		await get_tree().create_timer(.08).timeout
	await get_tree().process_frame;await get_tree().process_frame
	assert(game.play_seeds_remaining==0 and game.play_spawn_queue==0 and game.play_seed_animations_pending==0 and game.plants.is_empty() and game.first_play_tutorial_sequence_complete)
	assert(not game.play_active and game.total_play_count==1 and game.result_overlay.visible)
	assert(game.greenhouse_finish_attempt_count>0 and game.greenhouse_finish_completed_count==1 and game.greenhouse_finish_last_block_reason.is_empty())
	var finish_state:Dictionary=game.greenhouse_finish_last_snapshot
	print("FIRST_PLAY_FINISH_STATE snapshot=",finish_state," attempts=",game.greenhouse_finish_attempt_count," completed=",game.greenhouse_finish_completed_count," return_reason=",game.greenhouse_finish_last_block_reason," post_play_active=",game.play_active," post_result_visible=",game.result_overlay.visible)
	assert(bool(finish_state.get("play_active",false)) and int(finish_state.get("plants_size",-1))==0 and int(finish_state.get("play_seeds_remaining",-1))==0)
	assert(int(finish_state.get("play_spawn_queue",-1))==0 and int(finish_state.get("play_seed_animations_pending",-1))==0)
	assert(bool(finish_state.get("first_play_tutorial_active",false)) and bool(finish_state.get("first_play_tutorial_sequence_complete",false)) and not bool(finish_state.get("result_overlay_visible",true)))
	var result_close:Button=game.result_overlay.find_child("ResultCloseButton",true,false)
	var result_close_position:Vector2=result_close.global_position+result_close.size*.5
	var physical_result_close_position:Vector2=game.get_viewport().get_screen_transform()*result_close_position
	var result_press:=InputEventScreenTouch.new();result_press.position=physical_result_close_position;result_press.pressed=true
	var result_release:=InputEventScreenTouch.new();result_release.position=physical_result_close_position;result_release.pressed=false
	Input.parse_input_event(result_press);await get_tree().process_frame;Input.parse_input_event(result_release);await get_tree().process_frame
	assert(game.intro_overlay.visible and game.shop_overlay.visible and game.tutorial_dialog_kind=="play1")
	# Completion is level-triggered too: a missed/temporarily blocked deferred edge must not strand an empty play.
	game.intro_overlay.visible=false;game.shop_overlay.visible=false;game.result_overlay.visible=false;game.current_mode="greenhouse";game.play_active=true;game.rain_bonus_active=false
	game.first_play_tutorial_active=true;game.first_play_tutorial_sequence_complete=true;game.play_seeds_remaining=0;game.play_spawn_queue=0;game.play_seed_animations_pending=0;game.plants.clear()
	game.greenhouse_finish_attempt_count=0;game.greenhouse_finish_completed_count=0;game.greenhouse_finish_last_block_reason="not_checked";game.greenhouse_finish_last_snapshot.clear()
	game._process(.016)
	assert(not game.play_active and game.result_overlay.visible and game.greenhouse_finish_attempt_count==1 and game.greenhouse_finish_completed_count==1 and game.greenhouse_finish_last_block_reason.is_empty())
	print("FIRST_PLAY_TUTORIAL_SMOKE_OK messages=",game.FIRST_PLAY_TUTORIAL_MESSAGE_KEYS.size()," languages=",Localizer.SUPPORTED_LANGUAGES.size())
	get_tree().quit()
