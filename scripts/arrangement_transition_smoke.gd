extends Node

const EPSILON := 0.8

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.buyback_unlocked=true;game.total_play_count=3;game.formal_play_count=3
	game.opening_overlay.visible=false;game.intro_overlay.visible=false;game.result_overlay.visible=false;game.shop_overlay.visible=false;game.settings_overlay.visible=false;game.encyclopedia_overlay.visible=false;game.play_overlay.visible=false
	game._update_play_ui();game._update_greenhouse_pan()
	assert(is_equal_approx(game.GREENHOUSE_DRAG_SCALE,0.30))
	assert(is_equal_approx(game.GREENHOUSE_DRAG_DEAD_ZONE,3.0))
	assert(is_equal_approx(game.GREENHOUSE_PAN_FOLLOW_SECONDS,0.075))
	assert(game.greenhouse_backdrop.texture.resource_path=="res://assets/greenhouse-main.jpg")
	assert(game.arrangement_backdrop.texture.resource_path=="res://assets/arrangement/greenhouse-arrangement-area.jpg")
	assert(game.arrangement_backdrop.texture.get_size()==Vector2(790,971))
	var viewport_size:Vector2=get_viewport().get_visible_rect().size
	var main_texture_size:Vector2=game.greenhouse_backdrop.texture.get_size();var main_scale:=maxf(viewport_size.x/main_texture_size.x,viewport_size.y/main_texture_size.y);var main_display_size:=main_texture_size*main_scale;var main_base:=Vector2((viewport_size.x-main_display_size.x)*.5,(viewport_size.y-main_display_size.y)*.5)
	var original_limit:=maxf(0.0,(main_display_size.x-viewport_size.x)*.5);assert(is_equal_approx(game.greenhouse_pan_limit,original_limit))
	for pan_x in [-original_limit,0.0,original_limit]:
		game.greenhouse_pan_x=pan_x;game.greenhouse_pan_target_x=pan_x;game.arrangement_transition_x=0.0;game._update_greenhouse_pan()
		assert(game.greenhouse_backdrop.position.is_equal_approx(main_base+Vector2(pan_x,0.0)))
		var focus_x:float=game._arrangement_focus_transition_for_pan(pan_x);game.arrangement_transition_x=focus_x;game._update_greenhouse_pan()
		var arrangement_scale:float=game._arrangement_backdrop_scale(viewport_size);var displayed_table_center:Vector2=game.arrangement_backdrop.position+game.ARRANGEMENT_TABLE_SOURCE_CENTER*arrangement_scale
		assert(displayed_table_center.distance_to(viewport_size*game.ARRANGEMENT_TABLE_SCREEN_TARGET_RATIO)<EPSILON)
	game.arrangement_transition_x=0.0;game.greenhouse_pan_x=0.0;game.greenhouse_pan_target_x=0.0;game._update_greenhouse_pan()
	var idle_target_before:float=game.greenhouse_pan_target_x
	var idle_touch:=InputEventScreenTouch.new();idle_touch.pressed=true;idle_touch.position=Vector2(280,520);game._input(idle_touch)
	var idle_drag:=InputEventScreenDrag.new();idle_drag.position=Vector2(400,520);idle_drag.relative=Vector2(120,0);game._input(idle_drag)
	assert(is_equal_approx(game.greenhouse_pan_target_x,idle_target_before) and not game.pointer_down)
	game.play_active=true;game._update_play_ui();game._input(idle_touch);game._input(idle_drag)
	var expected_target:=clampf((120.0-game.GREENHOUSE_DRAG_DEAD_ZONE)*game.GREENHOUSE_DRAG_SCALE,-original_limit,original_limit)
	assert(is_equal_approx(game.greenhouse_pan_target_x,expected_target))
	var before_follow:float=float(game.greenhouse_pan_x);game._update_greenhouse_pan_follow(game.GREENHOUSE_PAN_FOLLOW_SECONDS)
	assert(game.greenhouse_pan_x>before_follow and game.greenhouse_pan_x<game.greenhouse_pan_target_x)
	game.play_active=false;game.pointer_down=false;game.greenhouse_pan_target_x=game.greenhouse_pan_x;var stopped_pan:float=game.greenhouse_pan_x;game._input(idle_touch);game._input(idle_drag);assert(is_equal_approx(game.greenhouse_pan_x,stopped_pan) and is_equal_approx(game.greenhouse_pan_target_x,stopped_pan))
	game._spawn_specific_plant("colorata");var plant=game.plants[0];game._resolve_crowding(0.0);game._update_labels();var plant_screen_before:Vector2=game.camera.unproject_position(plant.global_position);var backdrop_x_before:float=game.greenhouse_backdrop.position.x
	game._update_play_ui();assert(game.arrangement_button.visible)
	game._open_arrangements();assert(game.arrangement_scene_active and game.arrangement_transitioning and not game.arrangement_ui.visible and is_equal_approx(game.saved_greenhouse_pan_x,stopped_pan) and is_equal_approx(game.greenhouse_pan_target_x,stopped_pan))
	await get_tree().create_timer(.24).timeout
	game._resolve_crowding(0.0);game._update_labels();var backdrop_delta:float=game.greenhouse_backdrop.position.x-backdrop_x_before;var plant_delta:float=game.camera.unproject_position(plant.global_position).x-plant_screen_before.x
	assert(absf(backdrop_delta-plant_delta)<EPSILON and backdrop_delta>0.0)
	await get_tree().create_timer(.48).timeout
	assert(game.arrangement_scene_active and not game.arrangement_transitioning and game.arrangement_ui.visible and game.arrangement_ui.home_page.visible)
	var arrangement_scale:float=game._arrangement_backdrop_scale(viewport_size);var table_center:Vector2=game.arrangement_backdrop.position+game.ARRANGEMENT_TABLE_SOURCE_CENTER*arrangement_scale;var expected_anchor:Vector2=viewport_size*game.ARRANGEMENT_POT_ANCHOR
	assert(table_center.distance_to(viewport_size*game.ARRANGEMENT_TABLE_SCREEN_TARGET_RATIO)<EPSILON and table_center.y>viewport_size.y*.60 and table_center.y<viewport_size.y*.63)
	assert(game.arrangement_ui.world_backdrop_enabled and game.arrangement_ui.world_pot_anchor_screen.is_equal_approx(expected_anchor) and game.arrangement_ui.backdrop_shade.color.a<.3)
	game.arrangement_ui._start_new_arrangement();game.arrangement_ui._select_editor_pot("starter_terracotta")
	var pot_holder:Control=game.arrangement_ui.editor_pot_layer.get_child(1);var holder_anchor:Vector2=game.arrangement_ui.editor_canvas.position+pot_holder.position+Vector2(pot_holder.size.x*.5,pot_holder.size.y*.94)
	assert(holder_anchor.distance_to(expected_anchor)<EPSILON)
	game.arrangement_ui._return_home_from_editor();game.arrangement_ui.close();assert(game.arrangement_scene_active and game.arrangement_transitioning and not game.arrangement_ui.visible)
	await get_tree().create_timer(.72).timeout
	assert(not game.arrangement_scene_active and not game.arrangement_transitioning and is_equal_approx(game.arrangement_transition_x,0.0) and is_equal_approx(game.greenhouse_pan_x,stopped_pan) and is_equal_approx(game.greenhouse_pan_target_x,stopped_pan))
	assert(game.greenhouse_backdrop.position.is_equal_approx(main_base+Vector2(stopped_pan,0.0)))
	game.shop_overlay.visible=true;game._open_pot_shop();assert(game.arrangement_ui.visible and game.arrangement_ui.shop_page.visible and not game.arrangement_ui.world_backdrop_enabled and not game.arrangement_scene_active and is_equal_approx(game.arrangement_transition_x,0.0));game.arrangement_ui.close();assert(not game.arrangement_scene_active and not game.arrangement_transitioning)
	print("ARRANGEMENT_TRANSITION_SMOKE_OK pan_limit=",game.greenhouse_pan_limit," table_source=",game.ARRANGEMENT_TABLE_SOURCE_CENTER," target_ratio=",game.ARRANGEMENT_TABLE_SCREEN_TARGET_RATIO," restored_pan=",game.greenhouse_pan_x)
	get_tree().quit()
