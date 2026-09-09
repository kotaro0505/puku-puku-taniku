extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.old_seed_bags=1;game.total_play_count=0;game.intro_overlay.visible=false;game.shop_overlay.visible=false
	game._start_greenhouse_play("old");await get_tree().create_timer(.4).timeout;game.set_process(false);game._begin_first_play_tutorial()
	assert(game.play_active and game.first_play_tutorial_active and game.plants.size()==game.OLD_SEED_GERMINATION_COUNT)
	for plant in game.plants:assert(not plant.jelly_checks_enabled)
	var tracked=game.plants[0];var age_before_first:float=tracked.age
	game._process(1.99);assert(not game.first_play_tutorial_dialog_visible and tracked.age>age_before_first)
	game._process(.02);assert(game.first_play_tutorial_dialog_visible and game.tutorial_guide_overlay.visible)
	for message_index in range(game.FIRST_PLAY_TUTORIAL_MESSAGES.size()):
		assert(game.tutorial_guide_message.text==str(game.FIRST_PLAY_TUTORIAL_MESSAGES[message_index]))
		assert(game.tutorial_guide_button.visible and game.tutorial_guide_button.icon==null and game.tutorial_guide_button.position==Vector2.ZERO and game.tutorial_guide_button.size==get_viewport().get_visible_rect().size)
		var paused_age:float=tracked.age;game._process(4.0);assert(is_equal_approx(tracked.age,paused_age))
		game.tutorial_guide_button.pressed.emit();assert(not game.first_play_tutorial_dialog_visible and not game.tutorial_guide_overlay.visible)
		if message_index<game.FIRST_PLAY_TUTORIAL_MESSAGES.size()-1:
			var delay:float=float(game.FIRST_PLAY_TUTORIAL_DELAYS[message_index+1]);var resumed_age:float=tracked.age
			game._process(delay-.01);assert(not game.first_play_tutorial_dialog_visible and tracked.age>resumed_age)
			game._process(.02);assert(game.first_play_tutorial_dialog_visible)
	assert(game.first_play_tutorial_sequence_complete and bool(game.tutorial_steps.get("first_play_growth_dialogs",false)))
	for plant in game.plants:assert(plant.jelly_checks_enabled)
	assert(not game._should_trigger_first_play_rescue(tracked))
	for plant in game.plants.duplicate():
		if plant==tracked:continue
		game.plants.erase(plant)
		if is_instance_valid(plant.label):plant.label.free()
		plant.free()
	game.play_seeds_remaining=0;game.play_spawn_queue=0;game.play_seed_animations_pending=0;game.play_harvest_count=0;game.last_jelly_claim_msec=-1000000000
	assert(game._should_trigger_first_play_rescue(tracked) and not game._allow_plant_jelly(tracked))
	assert(game.first_play_rescue_active and game.first_play_rescue_plant==tracked and tracked.state=="growing")
	assert(game.tutorial_guide_overlay.visible and game.tutorial_guide_overlay.mouse_filter==Control.MOUSE_FILTER_IGNORE and not game.tutorial_guide_button.visible and game.tutorial_guide_button.icon==null)
	assert(game.tutorial_guide_message.text=="よし、いまだ！\n多肉をタップして収穫してみて！" and game.tutorial_guide_shade.material==game.first_play_rescue_spotlight_material)
	var rescue_age:float=tracked.age;game._process(3.0);assert(is_equal_approx(tracked.age,rescue_age))
	var rescue_center:Vector2=game.camera.unproject_position(tracked.global_position+Vector3(0,tracked.visual_scale*.48,0));game._try_harvest(rescue_center)
	assert(tracked.state=="harvested" and not game.first_play_rescue_active and game.play_harvest_count==1 and not game.tutorial_guide_overlay.visible)
	print("FIRST_PLAY_TUTORIAL_SMOKE_OK messages=",game.FIRST_PLAY_TUTORIAL_MESSAGES.size())
	get_tree().quit()
