extends Node

const Localizer=preload("res://scripts/game_localizer.gd")

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.opening_story_complete=true;game.intro_story_complete=true;game.first_colorata_confirmed=true;game.trio_originals_confirmed=true;game.total_play_count=3;game.formal_play_count=3;game.habitat_unlocked=true;game.habitat_arrival_started=true;game.habitat_awakened=true;game.habitat_awakening_event_complete=true;game.habitat_tutorial_started=true;game.habitat_tutorial_complete=true;game.mystery_items_acquired=true;game.mystery_catalog_tutorial_complete=true;game.seed_shop_open=true;game.panda_beacon_unlocked=true;game.panda_beacon_count=1;game.puku_gauge_intro_complete=true;game.encyclopedia_unlocked=true;game.first_tutorial_species_id="colorata";game.unlocked_series={"base":true}
	assert(game.play_open_button.text=="たねをまく")
	for guide_target in ["play_open","encyclopedia","habitat","old_seed"]:
		game._show_tutorial_guide(guide_target)
		var pressed_position:Vector2=game._tutorial_finger_position_for(game.tutorial_guide_button,true)
		var pressed_tip:Vector2=pressed_position+game.tutorial_guide_finger.pivot_offset+(game.TUTORIAL_FINGER_TIP_LOCAL-game.tutorial_guide_finger.pivot_offset).rotated(game.tutorial_guide_finger.rotation)
		var expected_tip:Vector2=game.tutorial_guide_button.global_position+game.tutorial_guide_button.size*game.TUTORIAL_FINGER_PRESS_RATIO
		var button_rect:Rect2=Rect2(game.tutorial_guide_button.global_position,game.tutorial_guide_button.size)
		assert(is_equal_approx(game.tutorial_guide_finger.rotation_degrees,28.0) and pressed_tip.distance_to(expected_tip)<.01 and button_rect.has_point(pressed_tip) and pressed_tip.y>button_rect.position.y+8.0)
	game.tutorial_guide_overlay.visible=false
	# The post-awakening rain bonus is retired. The first-awakening story overlay
	# still owns its rain/ghost presentation and remains available.
	game.rain_event_pending=false;game.rain_bonus_active=false;game._roll_rain_event()
	assert(not game.rain_event_pending and not game.rain_bonus_active)
	assert(game.habitat_awakening_overlay!=null and game.habitat_awakening_overlay.DIALOG_KEYS.has("_pause_before_memory"))
	game.play_harvest_cm_total=12.0;game.play_puku_earned_total=0;game.play_harvest_count=1;game.play_max_size=12.0;game.play_updated_global_best=false;game.play_notable_species={"colorata":{"name":"コロラータ","size":12.0}};game.result_new_species_queue.clear();game.result_new_species_queue.append("colorata");game._show_play_result();await get_tree().process_frame
	assert(game.result_new_species_label.visible and game.result_new_species_label.text=="コロラータを図鑑登録！" and game.result_new_species_label.get_theme_font_size("font_size")>=23 and game.result_new_species_pulse_tween!=null)
	game.result_overlay.visible=false;game.result_new_species_queue.clear();game._show_play_result();assert(not game.result_new_species_label.visible)
	print("TUTORIAL_RAIN_UI_SMOKE_OK tutorial_finger=true story_rain=preserved rain_bonus=retired new_species_ui=true")
	get_tree().quit()
