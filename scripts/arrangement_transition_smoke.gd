extends Node

const EPSILON := 0.9
const SCREENSHOT_DIR := "res://artifacts/greenhouse-master-scroll"

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.buyback_unlocked=true;game.total_play_count=3;game.formal_play_count=3
	game.opening_overlay.visible=false;game.intro_overlay.visible=false;game.result_overlay.visible=false;game.shop_overlay.visible=false;game.settings_overlay.visible=false;game.encyclopedia_overlay.visible=false;game.play_overlay.visible=false
	game.greenhouse_pan_x=0.0;game.greenhouse_pan_target_x=0.0;game.arrangement_transition_x=0.0;game.arrangement_transition_target_x=0.0
	game._update_play_ui();game._update_greenhouse_pan()

	var viewport_size:Vector2=get_viewport().get_visible_rect().size
	assert(viewport_size==Vector2(576,1024))
	assert(game.GREENHOUSE_MASTER_PATH=="res://assets/greenhouse-master-horizontal.png")
	assert(game.greenhouse_backdrop.texture.resource_path==game.GREENHOUSE_MASTER_PATH)
	assert(game.greenhouse_backdrop.texture.get_size()==game.GREENHOUSE_MASTER_SOURCE_SIZE)
	assert(game.GREENHOUSE_MASTER_SOURCE_SIZE==Vector2(1448,1086))
	assert(game.greenhouse_backdrop.material==null)
	assert(game.greenhouse_layer.get_node_or_null("ArrangementBackdrop")==null)
	assert(is_equal_approx(game.greenhouse_backdrop.size.y,viewport_size.y))
	var backdrop_scale:float=game.greenhouse_backdrop.size.x/game.greenhouse_backdrop.texture.get_width()
	assert(is_equal_approx(backdrop_scale,viewport_size.y/1086.0))

	var min_x:float=viewport_size.x-game.greenhouse_backdrop.size.x
	var max_x:float=0.0
	assert(game.greenhouse_main_position_x<game.greenhouse_arrangement_position_x)
	assert(game.greenhouse_main_position_x>=min_x-EPSILON and game.greenhouse_main_position_x<=max_x+EPSILON)
	assert(game.greenhouse_arrangement_position_x>=min_x-EPSILON and game.greenhouse_arrangement_position_x<=max_x+EPSILON)
	assert(absf((game.greenhouse_main_position_x+game.SOIL_SOURCE_CENTER.x*backdrop_scale)-viewport_size.x*.5)<EPSILON)
	assert(absf((game.greenhouse_arrangement_position_x+game.ARRANGEMENT_TABLE_SOURCE_CENTER.x*backdrop_scale)-viewport_size.x*game.ARRANGEMENT_TABLE_SCREEN_TARGET_RATIO.x)<EPSILON)
	var expected_arrangement_transition:float=game.greenhouse_arrangement_position_x-game.greenhouse_main_position_x
	assert(absf(game._arrangement_focus_transition_for_pan(0.0)-expected_arrangement_transition)<EPSILON)

	for ratio in [0.0,.25,.50,.75,1.0]:
		game.arrangement_transition_x=expected_arrangement_transition*ratio;game._update_greenhouse_pan()
		assert(game.greenhouse_background_position_x>=min_x-EPSILON and game.greenhouse_background_position_x<=max_x+EPSILON)
		assert(game.greenhouse_backdrop.position.x>=min_x-EPSILON and game.greenhouse_backdrop.position.x<=max_x+EPSILON)

	game.arrangement_transition_x=0.0;game._update_greenhouse_pan()
	var play_button_position:Vector2=game.play_open_button.position
	game._spawn_specific_plant("colorata");var plant=game.plants[0]
	game._resolve_crowding(0.0);game._update_labels()
	var plant_screen_before:Vector2=game.camera.unproject_position(plant.global_position)
	var backdrop_x_before:float=game.greenhouse_backdrop.position.x
	game.arrangement_transition_x=expected_arrangement_transition*.5;game._update_greenhouse_pan();game._resolve_crowding(0.0)
	var backdrop_delta:float=game.greenhouse_backdrop.position.x-backdrop_x_before
	var plant_delta:float=game.camera.unproject_position(plant.global_position).x-plant_screen_before.x
	assert(absf(backdrop_delta-plant_delta)<EPSILON)
	assert(game.play_open_button.position==play_button_position)

	game.arrangement_transition_x=0.0;game.arrangement_transitioning=false;game.arrangement_scene_active=false;game._update_greenhouse_pan();game._update_play_ui()
	game._begin_greenhouse_area_drag(Vector2(80,450),false)
	game._update_greenhouse_area_drag(Vector2(80+expected_arrangement_transition*.25,450))
	assert(game.greenhouse_area_drag_started and game.arrangement_transitioning)
	assert(absf(game.arrangement_transition_x-expected_arrangement_transition*.25)<EPSILON)
	game.greenhouse_area_drag_velocity_x=0.0;game._finish_greenhouse_area_drag(Vector2(80+expected_arrangement_transition*.25,450))
	await get_tree().create_timer(game.ARRANGEMENT_TRANSITION_SECONDS+.08).timeout
	assert(not game.arrangement_scene_active and not game.arrangement_transitioning and absf(game.arrangement_transition_x)<EPSILON)

	game._begin_greenhouse_area_drag(Vector2(40,450),false)
	game._update_greenhouse_area_drag(Vector2(40+expected_arrangement_transition*.75,450))
	assert(absf(game.arrangement_transition_x-expected_arrangement_transition*.75)<EPSILON)
	game.greenhouse_area_drag_velocity_x=0.0;game._finish_greenhouse_area_drag(Vector2(40+expected_arrangement_transition*.75,450))
	await get_tree().create_timer(game.ARRANGEMENT_TRANSITION_SECONDS+.08).timeout
	assert(game.arrangement_scene_active and not game.arrangement_transitioning and game.arrangement_ui.visible and game.arrangement_ui.home_page.visible)
	assert(game.arrangement_ui.world_backdrop_enabled)
	var expected_anchor:Vector2=viewport_size*game.ARRANGEMENT_POT_ANCHOR
	assert(game.arrangement_ui.world_pot_anchor_screen.distance_to(expected_anchor)<EPSILON)
	var table_center:Vector2=game.greenhouse_backdrop.position+game.ARRANGEMENT_TABLE_SOURCE_CENTER*backdrop_scale
	assert(table_center.distance_to(viewport_size*game.ARRANGEMENT_TABLE_SCREEN_TARGET_RATIO)<EPSILON)
	game.arrangement_ui._start_new_arrangement();game.arrangement_ui._select_editor_pot("starter_terracotta")
	# The placement guide was intentionally removed; the pot holder is now the only layer child.
	assert(game.arrangement_ui.editor_pot_layer.get_child_count()==1)
	var pot_holder:Control=game.arrangement_ui.editor_pot_layer.get_child(0)
	var holder_anchor:Vector2=game.arrangement_ui.editor_canvas.position+pot_holder.position+Vector2(pot_holder.size.x*.5,pot_holder.size.y*.94)
	assert(holder_anchor.distance_to(expected_anchor)<EPSILON)
	game.arrangement_ui._return_home_from_editor()

	game._begin_greenhouse_area_drag(Vector2(520,450),true)
	game._update_greenhouse_area_drag(Vector2(520-expected_arrangement_transition*.20,450))
	game.greenhouse_area_drag_velocity_x=-game.GREENHOUSE_AREA_FLICK_THRESHOLD-10.0
	game._finish_greenhouse_area_drag(Vector2(520-expected_arrangement_transition*.20,450))
	await get_tree().create_timer(game.ARRANGEMENT_TRANSITION_SECONDS+.08).timeout
	assert(not game.arrangement_scene_active and not game.arrangement_transitioning and absf(game.arrangement_transition_x)<EPSILON)
	assert(absf(game.greenhouse_background_position_x-game.greenhouse_main_position_x)<EPSILON)

	game.play_active=true;game._update_play_ui()
	var play_touch:=InputEventScreenTouch.new();play_touch.pressed=true;play_touch.position=Vector2(280,520);game._input(play_touch)
	var play_drag:=InputEventScreenDrag.new();play_drag.position=Vector2(400,520);play_drag.relative=Vector2(120,0);game._input(play_drag)
	var expected_pan:=clampf((120.0-game.GREENHOUSE_DRAG_DEAD_ZONE)*game.GREENHOUSE_DRAG_SCALE,-game.greenhouse_pan_limit,game.greenhouse_pan_limit)
	assert(is_equal_approx(game.greenhouse_pan_target_x,expected_pan))
	game.play_active=false;game.pointer_down=false;game.greenhouse_pan_x=0.0;game.greenhouse_pan_target_x=0.0;game._update_greenhouse_pan();game._update_play_ui()

	if DisplayServer.get_name()=="headless":print("GREENHOUSE_SCREENSHOTS_SKIPPED_DUMMY_RENDERER")
	else:
		var screenshot_dir_absolute:=ProjectSettings.globalize_path(SCREENSHOT_DIR)
		DirAccess.make_dir_recursive_absolute(screenshot_dir_absolute)
		game.owned_pots["classic_terracotta"]=true;game._sync_arrangement_ui()
		game.arrangement_ui.visible=false
		for shot in [{"ratio":0.0,"name":"00-main.png"},{"ratio":.25,"name":"25-percent.png"},{"ratio":.50,"name":"50-percent.png"},{"ratio":.75,"name":"75-percent.png"},{"ratio":1.0,"name":"100-arrangement.png"}]:
			game.arrangement_transition_x=expected_arrangement_transition*float(shot.ratio);game._update_greenhouse_pan();game._resolve_crowding(0.0);game._update_labels()
			await get_tree().process_frame;RenderingServer.force_draw()
			var image:=get_viewport().get_texture().get_image()
			assert(image!=null and image.get_size()==Vector2i(576,1024))
			assert(image.save_png(screenshot_dir_absolute.path_join(str(shot.name)))==OK)
		game.arrangement_scene_active=true;game.arrangement_ui.set_world_backdrop_mode(true,expected_anchor);game.arrangement_ui.open_home();game.arrangement_ui._start_new_arrangement();game.arrangement_ui._select_editor_pot("classic_terracotta")
		await get_tree().process_frame;RenderingServer.force_draw()
		var anchor_image:=get_viewport().get_texture().get_image()
		assert(anchor_image!=null and anchor_image.save_png(screenshot_dir_absolute.path_join("100-arrangement-pot-anchor.png"))==OK)

	print("ARRANGEMENT_TRANSITION_SMOKE_OK main_x=",game.greenhouse_main_position_x," arrangement_x=",game.greenhouse_arrangement_position_x," transition=",expected_arrangement_transition," soil=",game.SOIL_SOURCE_CENTER," table=",game.ARRANGEMENT_TABLE_SOURCE_CENTER," anchor=",expected_anchor)
	get_tree().quit()
