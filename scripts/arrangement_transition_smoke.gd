extends Node

const EPSILON := 0.9
const SCREENSHOT_DIR := "res://artifacts/greenhouse-master-scroll"

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.story_progression_state["arrangement_unlocked"]=true;game.story_progression_state["arrangement_intro_seen"]=true;game.intro_story_complete=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.habitat_awakened=true;game.habitat_awakening_event_complete=true;game.habitat_tutorial_complete=true;game.seed_shop_open=true;game.panda_beacon_unlocked=true;game.puku_gauge_intro_complete=true;game.total_play_count=3;game.formal_play_count=3
	game._sync_arrangement_ui()
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
	_test_cultivation_depth_parallax(game)

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
	assert(game.arrangement_ui.pot_select_grid.get_child_count()==1 and _has_button_text(game.arrangement_ui.home_page,"作った作品を見る") and not _has_button_text(game.arrangement_ui.home_page,"＋ 新しく作る"))
	assert(not game.main_status_hud.visible and not game.labels_layer.visible)
	assert(game.arrangement_ui.world_backdrop_enabled)
	var expected_anchor:Vector2=viewport_size*game.ARRANGEMENT_POT_ANCHOR
	assert(game.arrangement_ui.world_pot_anchor_screen.distance_to(expected_anchor)<EPSILON)
	var table_center:Vector2=game.greenhouse_backdrop.position+game.ARRANGEMENT_TABLE_SOURCE_CENTER*backdrop_scale
	assert(table_center.distance_to(viewport_size*game.ARRANGEMENT_TABLE_SCREEN_TARGET_RATIO)<EPSILON)
	game.arrangement_ui._select_editor_pot("shallow_terracotta")
	# The placement guide was intentionally removed; the pot holder is now the only layer child.
	assert(game.arrangement_ui.editor_pot_layer.get_child_count()==1)
	var pot_holder:Control=game.arrangement_ui.editor_pot_layer.get_child(0)
	assert(pot_holder.size.is_equal_approx(game.arrangement_ui.POT_HOLDER_SIZE))
	assert(pot_holder.size.x>=432.0*1.19 and pot_holder.size.x<=432.0*1.25)
	var holder_anchor:Vector2=game.arrangement_ui.editor_canvas.position+pot_holder.position+Vector2(pot_holder.size.x*.5,pot_holder.size.y*.94)
	var lowered_anchor:=expected_anchor+Vector2(0,game.arrangement_ui.POT_VERTICAL_OFFSET)
	assert(game.arrangement_ui.POT_VERTICAL_OFFSET>0.0 and holder_anchor.distance_to(lowered_anchor)<EPSILON)
	assert(game.arrangement_ui.is_editor_active() and not game._greenhouse_area_navigation_available())
	game._begin_greenhouse_area_drag(Vector2(520,450),true)
	game._update_greenhouse_area_drag(Vector2(300,450))
	assert(not game.greenhouse_area_drag_tracking and not game.arrangement_transitioning)
	game.arrangement_ui._return_home_from_editor()
	assert(not game.arrangement_ui.is_editor_active() and game._greenhouse_area_navigation_available())
	game.arrangement_ui._open_viewer({"arrangement_id":"gesture_viewer","name":"完成作品","pot_id":"shallow_terracotta","completed":true,"plants":[]})
	assert(game.arrangement_ui.is_viewer_active() and game.arrangement_ui.viewer_page.visible and not game._greenhouse_area_navigation_available() and not game.arrangement_ui.is_navigation_hint_safe())
	var viewer_press:=InputEventScreenTouch.new();viewer_press.index=0;viewer_press.position=Vector2(520,450);viewer_press.pressed=true;game.arrangement_ui._on_viewer_world_scroll_input(viewer_press)
	game._on_arrangement_world_scroll_input(viewer_press);assert(not game.greenhouse_area_drag_tracking and not game.arrangement_transitioning)
	var artwork_start:Vector2=game.arrangement_ui.viewer_artwork_root.position
	var preview_artwork_scale:float=game.arrangement_ui.viewer_artwork_canvas.scale.x
	var viewer_mouse_press:=InputEventMouseButton.new();viewer_mouse_press.button_index=MOUSE_BUTTON_LEFT;viewer_mouse_press.pressed=true;viewer_mouse_press.position=Vector2(260,300);game.arrangement_ui._on_viewer_canvas_gui_input(viewer_mouse_press)
	var viewer_motion:=InputEventMouseMotion.new();viewer_motion.position=Vector2(300,330);game.arrangement_ui._on_viewer_canvas_gui_input(viewer_motion)
	var viewer_mouse_release:=InputEventMouseButton.new();viewer_mouse_release.button_index=MOUSE_BUTTON_LEFT;viewer_mouse_release.pressed=false;viewer_mouse_release.position=viewer_motion.position;game.arrangement_ui._on_viewer_canvas_gui_input(viewer_mouse_release)
	assert(game.arrangement_ui.viewer_page.visible and game.arrangement_ui.viewer_artwork_root.position.is_equal_approx(artwork_start+Vector2(40,30)/preview_artwork_scale) and not game.greenhouse_area_drag_tracking and not game.arrangement_transitioning)
	game.arrangement_ui._return_from_viewer();assert(game.arrangement_ui.home_page.visible and game._greenhouse_area_navigation_available())

	game._begin_greenhouse_area_drag(Vector2(520,450),true)
	game._update_greenhouse_area_drag(Vector2(520-expected_arrangement_transition*.20,450))
	game.greenhouse_area_drag_velocity_x=-game.GREENHOUSE_AREA_FLICK_THRESHOLD-10.0
	game._finish_greenhouse_area_drag(Vector2(520-expected_arrangement_transition*.20,450))
	await get_tree().create_timer(game.ARRANGEMENT_TRANSITION_SECONDS+.08).timeout
	assert(not game.arrangement_scene_active and not game.arrangement_transitioning and absf(game.arrangement_transition_x)<EPSILON)
	assert(absf(game.greenhouse_background_position_x-game.greenhouse_main_position_x)<EPSILON)
	assert(game.main_status_hud.visible and game.labels_layer.visible)

	game.play_active=true;game._update_play_ui()
	var play_touch:=InputEventScreenTouch.new();play_touch.pressed=true;play_touch.position=Vector2(280,520);game._input(play_touch)
	var play_drag:=InputEventScreenDrag.new();play_drag.position=Vector2(400,520);play_drag.relative=Vector2(120,0);game._input(play_drag)
	var expected_pan:=clampf((120.0-game.GREENHOUSE_DRAG_DEAD_ZONE)*game.GREENHOUSE_DRAG_SCALE,-game.greenhouse_pan_limit,game.greenhouse_pan_limit)
	var legacy_pan:=clampf((120.0-game.GREENHOUSE_DRAG_DEAD_ZONE)*.30,-game.greenhouse_pan_limit,game.greenhouse_pan_limit)
	assert(is_equal_approx(game.GREENHOUSE_DRAG_SCALE,.40) and expected_pan>legacy_pan*1.32 and expected_pan<legacy_pan*1.34,"greenhouse drag response was not raised from 0.30 to 0.40 legacy=%.3f tuned=%.3f"%[legacy_pan,expected_pan])
	assert(is_equal_approx(game.greenhouse_pan_target_x,expected_pan))
	assert(game.greenhouse_pan_limit>77.0 and game.greenhouse_pan_limit<79.0,"greenhouse pan range changed unexpectedly limit=%.3f"%game.greenhouse_pan_limit)
	game._update_greenhouse_pan_follow(1.0/60.0)
	assert(game.greenhouse_pan_x>0.0 and game.greenhouse_pan_x<expected_pan,"greenhouse pan follow jumped instead of smoothing current=%.3f target=%.3f"%[game.greenhouse_pan_x,expected_pan])
	print("GREENHOUSE_DRAG_TUNING_OK scale_before=.30 scale_after=%.2f same_drag_before=%.3f same_drag_after=%.3f limit=%.3f follow_frame=%.3f"%[game.GREENHOUSE_DRAG_SCALE,legacy_pan,expected_pan,game.greenhouse_pan_limit,game.greenhouse_pan_x])
	game.play_active=false;game.pointer_down=false;game.greenhouse_pan_x=0.0;game.greenhouse_pan_target_x=0.0;game._update_greenhouse_pan();game._update_play_ui()

	if DisplayServer.get_name()=="headless":print("GREENHOUSE_SCREENSHOTS_SKIPPED_DUMMY_RENDERER")
	else:
		var screenshot_dir_absolute:=ProjectSettings.globalize_path(SCREENSHOT_DIR)
		DirAccess.make_dir_recursive_absolute(screenshot_dir_absolute)
		game.owned_pots["classic_terracotta"]=1;game._sync_arrangement_ui()
		game.arrangement_ui.visible=false
		for shot in [{"ratio":0.0,"name":"00-main.png"},{"ratio":.25,"name":"25-percent.png"},{"ratio":.50,"name":"50-percent.png"},{"ratio":.75,"name":"75-percent.png"},{"ratio":1.0,"name":"100-arrangement.png"}]:
			game.arrangement_transition_x=expected_arrangement_transition*float(shot.ratio);game._update_greenhouse_pan();game._resolve_crowding(0.0);game._update_labels()
			await get_tree().process_frame;RenderingServer.force_draw()
			var image:=get_viewport().get_texture().get_image()
			assert(image!=null and image.get_size()==Vector2i(576,1024))
			assert(image.save_png(screenshot_dir_absolute.path_join(str(shot.name)))==OK)
		game.arrangement_scene_active=true;game.arrangement_ui.set_world_backdrop_mode(true,expected_anchor);game.arrangement_ui.open_home();game.arrangement_ui._select_editor_pot("classic_terracotta");game._update_play_ui()
		await get_tree().process_frame;RenderingServer.force_draw()
		var anchor_image:=get_viewport().get_texture().get_image()
		assert(anchor_image!=null and anchor_image.save_png(screenshot_dir_absolute.path_join("100-arrangement-pot-anchor.png"))==OK)
		game.arrangement_scene_active=false;game.arrangement_ui.visible=false;game.arrangement_transition_x=0.0;game._update_play_ui()
		_spawn_visual_comparison_plants(game)
		# Freeze the main loop so its normal per-frame crowding pass cannot replace
		# the baseline transform between setup and screenshot capture.
		game.set_process(false)
		for pan_shot in [{"ratio":-.75,"side":"left"},{"ratio":0.0,"side":"center"},{"ratio":.75,"side":"right"}]:
			game.greenhouse_pan_x=game.greenhouse_pan_limit*float(pan_shot.ratio);game.greenhouse_pan_target_x=game.greenhouse_pan_x;game._update_greenhouse_pan()
			# Capture the previous common-world-offset projection with the exact same
			# plant instances before applying the tuned foreground gain.
			for comparison_plant in game.plants:
				comparison_plant.position.x=comparison_plant.original_pos.x+game.greenhouse_world_pan_x
				comparison_plant.position.z=comparison_plant.original_pos.z
			game._sync_plant_screen_visuals();game._update_labels()
			var baseline_front_root_x:float=game.camera.unproject_position(game.plants[0].global_position).x
			await get_tree().process_frame;RenderingServer.force_draw()
			var baseline_image:=get_viewport().get_texture().get_image()
			assert(baseline_image!=null and baseline_image.save_png(screenshot_dir_absolute.path_join("baseline-030-pan-%s.png"%str(pan_shot.side)))==OK)
			game._resolve_crowding(0.0);game._sync_plant_screen_visuals();game._update_labels()
			var tuned_front_root_x:float=game.camera.unproject_position(game.plants[0].global_position).x
			if not is_zero_approx(float(pan_shot.ratio)):
				assert(absf(tuned_front_root_x-baseline_front_root_x)>5.0,"visual comparison did not apply the foreground gain side=%s baseline=%.3f tuned=%.3f"%[str(pan_shot.side),baseline_front_root_x,tuned_front_root_x])
				print("GREENHOUSE_SCREENSHOT_COMPARISON side=%s baseline_front_root=%.3f tuned_front_root=%.3f delta=%.3f"%[str(pan_shot.side),baseline_front_root_x,tuned_front_root_x,tuned_front_root_x-baseline_front_root_x])
			await get_tree().process_frame;RenderingServer.force_draw()
			var tuned_image:=get_viewport().get_texture().get_image()
			assert(tuned_image!=null and tuned_image.save_png(screenshot_dir_absolute.path_join("tuned-040-pan-%s.png"%str(pan_shot.side)))==OK)
		game.greenhouse_pan_x=0.0;game.greenhouse_pan_target_x=0.0;game._update_greenhouse_pan()

	print("ARRANGEMENT_TRANSITION_SMOKE_OK main_x=",game.greenhouse_main_position_x," arrangement_x=",game.greenhouse_arrangement_position_x," transition=",expected_arrangement_transition," soil=",game.SOIL_SOURCE_CENTER," table=",game.ARRANGEMENT_TABLE_SOURCE_CENTER," anchor=",expected_anchor)
	get_tree().quit()

func _test_cultivation_depth_parallax(game)->void:
	# The restored Sprite3D projection supplies the base depth cue. The tuned
	# foreground gain may strengthen only the near side; centre/rear movement is
	# compared independently with the unmodified common-world-offset baseline.
	game.arrangement_transition_x=0.0
	game.greenhouse_pan_x=0.0;game.greenhouse_pan_target_x=0.0;game._update_greenhouse_pan()
	var front:=Vector3(0,.12,2.5)
	var center:=Vector3(0,.12,0)
	var rear:=Vector3(0,.12,-2.5)
	var front_before:float=game.camera.unproject_position(front).x
	var center_before:float=game.camera.unproject_position(center).x
	var rear_before:float=game.camera.unproject_position(rear).x
	game.greenhouse_pan_x=game.greenhouse_pan_limit*.75;game.greenhouse_pan_target_x=game.greenhouse_pan_x;game._update_greenhouse_pan()
	var front_offset:float=game._greenhouse_world_offset_for_position(front)
	var center_offset:float=game._greenhouse_world_offset_for_position(center)
	var rear_offset:float=game._greenhouse_world_offset_for_position(rear)
	var expected_front_ratio:float=1.0+float(game.GREENHOUSE_FOREGROUND_PAN_BOOST)*clampf(front.z/float(game.GREENHOUSE_FOREGROUND_PAN_DEPTH),0.0,1.0)
	assert(absf(front_offset-game.greenhouse_world_pan_x*expected_front_ratio)<.0001,"foreground boost did not match the bounded depth gain front=%.5f base=%.5f ratio=%.5f"%[front_offset,game.greenhouse_world_pan_x,expected_front_ratio])
	assert(absf(center_offset-game.greenhouse_world_pan_x)<.0001 and absf(rear_offset-game.greenhouse_world_pan_x)<.0001,"centre/rear world motion changed center=%.5f rear=%.5f base=%.5f"%[center_offset,rear_offset,game.greenhouse_world_pan_x])
	var front_delta:float=game.camera.unproject_position(front+Vector3(front_offset,0,0)).x-front_before
	var center_delta:float=game.camera.unproject_position(center+Vector3(center_offset,0,0)).x-center_before
	var rear_delta:float=game.camera.unproject_position(rear+Vector3(rear_offset,0,0)).x-rear_before
	var baseline_front_delta:float=game.camera.unproject_position(front+Vector3(game.greenhouse_world_pan_x,0,0)).x-front_before
	var baseline_center_delta:float=game.camera.unproject_position(center+Vector3(game.greenhouse_world_pan_x,0,0)).x-center_before
	var baseline_rear_delta:float=game.camera.unproject_position(rear+Vector3(game.greenhouse_world_pan_x,0,0)).x-rear_before
	var background_delta:float=game.greenhouse_background_position_x-game.greenhouse_main_position_x
	assert(absf(center_delta-background_delta)<EPSILON,"soil-centre root no longer tracks the greenhouse background center=%.3f background=%.3f"%[center_delta,background_delta])
	var foreground_screen_gain:=absf(front_delta/baseline_front_delta)
	assert(foreground_screen_gain>=1.10 and foreground_screen_gain<=1.15,"foreground screen gain left the requested 10-15%% band baseline=%.3f tuned=%.3f gain=%.3f"%[baseline_front_delta,front_delta,foreground_screen_gain])
	assert(absf(center_delta-baseline_center_delta)<.01 and absf(rear_delta-baseline_rear_delta)<.01,"tuning changed centre/rear projection baseline_center=%.3f tuned_center=%.3f baseline_rear=%.3f tuned_rear=%.3f"%[baseline_center_delta,center_delta,baseline_rear_delta,rear_delta])
	assert(absf(front_delta)>absf(center_delta)+.5 and absf(center_delta)>absf(rear_delta)+.5,"depth motion was flattened front=%.3f center=%.3f rear=%.3f"%[front_delta,center_delta,rear_delta])
	assert(absf(front_delta)<absf(background_delta)*1.55 and absf(rear_delta)>absf(background_delta)*.70,"tuned depth cue became excessive front=%.3f background=%.3f rear=%.3f"%[front_delta,background_delta,rear_delta])
	# Signed gain must be mirror-symmetric when the user pans the other way.
	game.greenhouse_pan_x=-game.greenhouse_pan_limit*.75;game.greenhouse_pan_target_x=game.greenhouse_pan_x;game._update_greenhouse_pan()
	var left_deltas:Array[float]=[]
	for world_position in [front,center,rear]:
		var left_offset:float=game._greenhouse_world_offset_for_position(world_position)
		left_deltas.append(game.camera.unproject_position(world_position+Vector3(left_offset,0,0)).x-game.camera.unproject_position(world_position).x)
	for index in range(3):
		var right_delta:float=[front_delta,center_delta,rear_delta][index]
		assert(right_delta*float(left_deltas[index])<0.0 and absf(absf(right_delta)-absf(float(left_deltas[index])))<.01,"left/right depth motion lost symmetry index=%d right=%.3f left=%.3f"%[index,right_delta,float(left_deltas[index])])
	game.greenhouse_pan_x=game.greenhouse_pan_limit*.75;game.greenhouse_pan_target_x=game.greenhouse_pan_x;game._update_greenhouse_pan()
	# Arrangement navigation is a scene transition, not cultivation parallax. It
	# must still translate every already-panned root by exactly the backdrop delta.
	var roots_before_transition:Array[float]=[]
	for world_position in [front,center,rear]:
		var before_offset:float=game._greenhouse_world_offset_for_position(world_position)
		roots_before_transition.append(game.camera.unproject_position(world_position+Vector3(before_offset,0,0)).x)
	var backdrop_before_transition:float=game.greenhouse_background_position_x
	game.arrangement_transition_x=game._arrangement_focus_transition_for_pan(game.greenhouse_pan_x)*.35;game._update_greenhouse_pan()
	var transition_delta:float=game.greenhouse_background_position_x-backdrop_before_transition
	for index in range(3):
		var world_position:Vector3=[front,center,rear][index]
		var after_offset:float=game._greenhouse_world_offset_for_position(world_position)
		var root_transition_delta:float=game.camera.unproject_position(world_position+Vector3(after_offset,0,0)).x-float(roots_before_transition[index])
		assert(absf(root_transition_delta-transition_delta)<EPSILON,"arrangement transition inherited cultivation parallax index=%d root=%.3f backdrop=%.3f"%[index,root_transition_delta,transition_delta])
	print("GREENHOUSE_DEPTH_PARALLAX_OK baseline_front=%.3f baseline_center=%.3f baseline_rear=%.3f tuned_front=%.3f tuned_center=%.3f tuned_rear=%.3f foreground_gain=%.3f world=%.5f"%[baseline_front_delta,baseline_center_delta,baseline_rear_delta,front_delta,center_delta,rear_delta,foreground_screen_gain,center_offset])
	game.arrangement_transition_x=0.0;game.greenhouse_pan_x=0.0;game.greenhouse_pan_target_x=0.0;game._update_greenhouse_pan()

func _spawn_visual_comparison_plants(game)->void:
	game._clear_greenhouse_plants()
	var samples:Array=[
		{"species":"colorata","position":Vector3(-2.15,.12,2.45),"cm":60.0},
		{"species":"laui","position":Vector3(.25,.12,2.05),"cm":40.0},
		{"species":"yumekawa_milky_dream","position":Vector3(2.0,.12,1.15),"cm":80.0},
		{"species":"colorata","position":Vector3(-.55,.12,.35),"cm":100.0},
		{"species":"laui","position":Vector3(-2.25,.12,-.75),"cm":20.0},
		{"species":"yumekawa_milky_dream","position":Vector3(.85,.12,-1.15),"cm":120.0},
		{"species":"colorata","position":Vector3(2.15,.12,-2.25),"cm":5.0},
		{"species":"laui","position":Vector3(-.1,.12,-2.55),"cm":150.0}
	]
	for sample in samples:
		var species_id:=str(sample.species);game.species_get_counts[species_id]=1;game._spawn_specific_plant(species_id)
		var plant=game.plants.back();plant.jelly_checks_enabled=false;plant.original_pos=sample.position;plant.position=sample.position;plant.fast_forward_to_diameter(float(sample.cm));plant.plant_sprite.position.x=0.0;plant.plant_sprite.rotation.z=0.0
	game.show_growing_plant_labels=false
	game._resolve_crowding(0.0);game._sync_plant_screen_visuals();game._update_labels()

func _has_button_text(root:Node,text:String)->bool:
	for node in root.find_children("*","Button",true,false):
		if node is Button and (node as Button).text==text:return true
	return false
