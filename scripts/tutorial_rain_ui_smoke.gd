extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.total_play_count=3;game.formal_play_count=3;game.habitat_unlocked=true;game.buyback_unlocked=true;game.encyclopedia_unlocked=true
	game._start_post_play_dialog("play1");assert(game.intro_dialogue_label.text=="コロラータのたねだったんだね！\n図鑑に登録したよ。見てみよう。")
	game.intro_overlay.visible=false;game.tutorial_dialog_kind="";game._start_post_play_dialog("play2");assert(game.intro_dialogue_label.text=="センスいいね！そうだ、今度一緒に多肉の原生地へ行こうよ。\n準備してくるから少し待ってね。")
	game.intro_overlay.visible=false;game.tutorial_dialog_kind="";assert(game.play_open_button.text=="たねをまく")
	for guide_target in ["play_open","encyclopedia","habitat","old_seed"]:
		game._show_tutorial_guide(guide_target)
		var pressed_position:Vector2=game._tutorial_finger_position_for(game.tutorial_guide_button,true)
		var pressed_tip:Vector2=pressed_position+game.tutorial_guide_finger.pivot_offset+(game.TUTORIAL_FINGER_TIP_LOCAL-game.tutorial_guide_finger.pivot_offset).rotated(game.tutorial_guide_finger.rotation)
		var expected_tip:Vector2=game.tutorial_guide_button.global_position+game.tutorial_guide_button.size*game.TUTORIAL_FINGER_PRESS_RATIO
		var button_rect:Rect2=Rect2(game.tutorial_guide_button.global_position,game.tutorial_guide_button.size)
		assert(is_equal_approx(game.tutorial_guide_finger.rotation_degrees,28.0) and pressed_tip.distance_to(expected_tip)<.01 and button_rect.has_point(pressed_tip) and pressed_tip.y>button_rect.position.y+8.0)
	game.tutorial_guide_overlay.visible=false
	var min_y:=999.0;var max_y:=-999.0;var longitudes:Array[float]=[]
	for i in range(240):
		var point:Vector3=game._find_rain_spawn_position();assert(point.length()>10.0 and point.length()<10.3);min_y=minf(min_y,point.y);max_y=maxf(max_y,point.y);longitudes.append(atan2(point.x,-point.z))
	assert(max_y-min_y>.35 and longitudes.max()-longitudes.min()>5.0)
	game.current_mode="habitat";game.rain_event_pending=true;game.rain_time_remaining=10.0;game.tutorial_steps.erase("rain_first_dialog");game._start_rain_bonus();await get_tree().process_frame
	assert(game.intro_overlay.visible and game.tutorial_dialog_kind=="rain_first" and game.intro_dialogue_label.text=="この雨で多肉のたねが一斉に発芽するよ。\nまさに恵みの雨だね。")
	game._advance_intro_story();assert(bool(game.tutorial_steps.get("rain_first_dialog",false)) and not game.intro_overlay.visible)
	game._clear_greenhouse_plants();game.rain_bonus_active=false;game.rain_event_pending=true;game._start_rain_bonus();await get_tree().process_frame;assert(not game.intro_overlay.visible)
	game.rain_bonus_active=false;game.rain_event_pending=false;game._clear_greenhouse_plants()
	game.play_earnings_total=0;game.play_harvest_count=1;game.play_max_size=12.0;game.play_updated_global_best=false;game.play_notable_species={"colorata":{"name":"コロラータ","size":12.0}};game.result_new_species_queue.clear();game.result_new_species_queue.append("colorata");game._show_play_result();await get_tree().process_frame
	assert(game.result_new_species_label.visible and game.result_new_species_label.text=="コロラータを図鑑登録！" and game.result_new_species_label.get_theme_font_size("font_size")>=23 and game.result_new_species_pulse_tween!=null)
	game.result_overlay.visible=false;game.result_new_species_queue.clear();game._show_play_result();assert(not game.result_new_species_label.visible)
	print("TUTORIAL_RAIN_UI_SMOKE_OK range_y=",max_y-min_y)
	get_tree().quit()
