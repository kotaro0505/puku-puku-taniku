extends Node

const Localizer=preload("res://scripts/game_localizer.gd")

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.opening_story_complete=true;game.intro_story_complete=true;game.first_colorata_confirmed=true;game.trio_originals_confirmed=true;game.total_play_count=3;game.formal_play_count=3;game.habitat_unlocked=true;game.habitat_arrival_started=true;game.habitat_awakened=true;game.habitat_awakening_event_complete=true;game.habitat_tutorial_started=true;game.habitat_tutorial_complete=true;game.mystery_items_acquired=true;game.mystery_catalog_tutorial_complete=true;game.seed_shop_open=true;game.panda_beacon_unlocked=true;game.panda_beacon_count=1;game.puku_gauge_intro_complete=true;game.encyclopedia_unlocked=true;game.first_tutorial_species_id="colorata";game.unlocked_series={"base":true}
	assert(game.play_open_button.text=="たねをまく")
	for guide_target in ["play_open","encyclopedia","habitat","old_seed"]:
		game._show_tutorial_guide(guide_target)
		assert(game.tutorial_guide_overlay.visible and game.tutorial_guide_shade.visible)
		assert(game.tutorial_guide_shade.color.a>=.7 and game.tutorial_highlight_tween!=null)
		assert(game.tutorial_guide_button.visible and str(game.tutorial_guide_button.get_meta("target",""))==guide_target)
		assert(game.tutorial_guide_overlay.find_child("*Finger*",true,false)==null)
		if game.tutorial_highlight_tween and game.tutorial_highlight_tween.is_valid():game.tutorial_highlight_tween.kill()
	game.tutorial_guide_overlay.visible=false
	# The post-awakening rain bonus is retired. The first-awakening story overlay
	# still owns its rain/ghost presentation and remains available.
	game.rain_event_pending=false;game.rain_bonus_active=false;game._roll_rain_event()
	assert(not game.rain_event_pending and not game.rain_bonus_active)
	assert(game.habitat_awakening_overlay!=null and game.habitat_awakening_overlay.DIALOG_KEYS.has("_pause_before_memory"))
	game.play_harvest_cm_total=12.0;game.play_puku_earned_total=0;game.play_harvest_count=1;game.play_max_size=12.0;game.play_updated_global_best=false;game.play_notable_species={"colorata":{"name":"コロラータ","size":12.0}};game.result_new_species_queue.clear();game.result_new_species_queue.append("colorata");game._show_play_result();await get_tree().process_frame
	assert(game.result_new_species_label.visible and game.result_new_species_label.text=="コロラータを図鑑登録！" and game.result_new_species_label.get_theme_font_size("font_size")>=23 and game.result_new_species_pulse_tween!=null)
	game.result_overlay.visible=false;game.result_new_species_queue.clear();game._show_play_result();assert(not game.result_new_species_label.visible)
	print("TUTORIAL_RAIN_UI_SMOKE_OK tutorial_finger=retired dark_highlight=true story_rain=preserved rain_bonus=retired new_species_ui=true")
	get_tree().quit()
