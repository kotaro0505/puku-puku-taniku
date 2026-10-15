extends Node

const SucculentClass=preload("res://scripts/succulent.gd")
const Localizer=preload("res://scripts/game_localizer.gd")
var sprite3d_render_oracle_status:="not_run"
var sprite3d_render_max_edge_error_px:=0

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game.endless_greenhouse.configure(false)
	game._reset_progression_state();game.intro_story_complete=true;game.mystery_items_acquired=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.habitat_tutorial_complete=true;game.puku_gauge_intro_complete=true;game.normal_play_tutorial_complete=true;game.seed_pod_gauge_discovery_complete=true;game.seed_pod_first_reward_seen=true;game.puku_buyback_tutorial_complete=true;game.total_play_count=3
	# This economy suite invokes the GET close handler directly without a real
	# close tap. Input-response profiling is covered by its dedicated smoke.
	game.get_close_profile_enabled=false
	_test_seed_pod_thresholds(game)
	game.endless_greenhouse.configure(true)
	_test_fixed_point_and_harvest_curve(game)
	await _test_sprite3d_render_alignment(game)
	_test_giant_plant_display_and_hit(game)
	_test_greenhouse_pan_depth_and_hit(game)
	_test_live_harvest_preview(game)
	_test_plant_label_visibility_toggle(game)
	await _test_giant_harvest_reward(game)
	await _test_signed_balance_animation(game)
	await _test_round_entry_and_harvest(game)
	_test_catalog_auto_record(game)
	_test_save_and_legacy_load(game)
	await _test_panda_rescue(game)
	_test_max_size_record_is_silent(game)
	game._reset_progression_state();game.queue_free()
	print("PUKU_POINTS_SMOKE_OK unit=1/1000 round_cost=1.00 direct_harvest=true sprite3d_render_oracle="+sprite3d_render_oracle_status+" legacy_sprite3d_match=1.6,5,10,20,30,40,60,80,100,120cm giant=150,200,300,500,700,1000,1500,2000,10000cm_species3_positions3_speeds1.6+10 transition120=true depth_pan=front_center_rear+left_center_right+tap60+120+150 label_toggle=localized_persistent_on_off+main_only_live_recalc max_record=silent_visual_preserved reward1000+2000=true new_floor=.20 migration=points+legacy_gauge forest_cost=1 rescue=wallet_plus_1 combo=true fly_removed=true result=removed automatic_get=true")
	get_tree().quit()

func _test_seed_pod_thresholds(game)->void:
	# The finite-mode seed-pod gauge is independent of the new puku wallet.
	assert(is_equal_approx(game.SEED_POD_GAUGE_TARGET_CM,750.0))
	assert(game.SEED_POD_GAUGE_REWARD_BAGS==3 and game.SEED_PACK_CONFIG.normal.count==12)
	game.puku_gauge_cm=0.0;game.puku_balance_units=0;game.normal_seed_bags=0;game._update_puku_ui()
	assert(game.add_seed_pod_gauge_cm(749.0,false,false)==0 and is_equal_approx(game.puku_gauge_cm,749.0) and game.normal_seed_bags==0)
	assert(game.add_seed_pod_gauge_cm(1.0,false,false)==3 and is_zero_approx(game.puku_gauge_cm) and game.normal_seed_bags==3)
	game.puku_gauge_cm=0.0;game.normal_seed_bags=0
	assert(game.add_seed_pod_gauge_cm(1600.0,false,false)==6 and is_equal_approx(game.puku_gauge_cm,100.0) and game.normal_seed_bags==6)

func _test_max_size_record_is_silent(game)->void:
	var plant:=SucculentClass.new();plant.diameter_cm=321.0
	game.endless_greenhouse.configure(true);game.play_active=true;game.active_seed_type="normal";game.language_code="ja"
	game.audio_manager.last_se_key="";game.record_card.visible=false;game.record_card.modulate.a=1.0
	game._show_record(plant)
	assert(game.audio_manager.last_se_key.is_empty(),"maximum-size update still played SE: %s"%game.audio_manager.last_se_key)
	assert(game.record_card.visible and game.record_text.text=="最大サイズ更新！\n321.0 cm","maximum-size text presentation changed: %s"%game.record_text.text)
	assert(game.record_card.scale==Vector2(.72,.72),"maximum-size animation did not start from its established scale")
	plant.free()

func _test_fixed_point_and_harvest_curve(game)->void:
	assert(game.PUKU_UNITS_PER_PUKU==1000)
	assert(game.NORMAL_ROUND_COST_UNITS==1000 and game.FIRST_GET_MIN_REWARD_UNITS==200)
	assert(game.INITIAL_PUKU_CAPITAL_UNITS==5000)
	for sample in [[0.0,0],[20.0,50],[30.0,120],[40.0,230],[50.0,360],[60.0,540],[70.0,800],[80.0,1390],[90.0,2430],[100.0,3750],[110.0,4980],[120.0,6000],[125.0,7570],[130.0,10320],[135.0,13600],[140.0,16990],[145.0,20270],[150.0,23320],[160.0,28570],[170.0,32710],[180.0,35950],[200.0,40700],[250.0,48650],[300.0,55490],[500.0,82500],[700.0,109500],[1000.0,150000]]:
		assert(game._harvest_puku_reward_units(float(sample[0]),false)==int(sample[1]))
	var previous_units:=-1
	for step in range(0,4801):
		var units:int=game._harvest_puku_reward_units(float(step)*.25,false)
		assert(units>=previous_units,"reward curve decreased at %.2fcm"%(float(step)*.25));previous_units=units
	assert(game._harvest_puku_reward_units(25.0,false)>50 and game._harvest_puku_reward_units(25.0,false)<120)
	assert(game._harvest_puku_reward_units(1001.0,false)>150000)
	var peak_slope:=-INF;var peak_cm:=0.0
	for quarter_step in range(480,640):
		var cm:=float(quarter_step)*.25;var slope:float=(game._harvest_puku_curve_units(cm+.05)-game._harvest_puku_curve_units(cm-.05))/.1
		if slope>peak_slope:peak_slope=slope;peak_cm=cm
	assert(peak_cm>=135.0 and peak_cm<=145.0,"reward growth peak was not near 140cm: %.2f"%peak_cm)
	assert(game._harvest_puku_curve_units(1100.0)-game._harvest_puku_curve_units(1000.0)<=14000.0)
	assert(game._harvest_puku_reward_units(8.0,true)==200)
	assert(game._harvest_puku_reward_units(50.0,true)==360)
	game.puku_balance_units=100;assert(game._change_puku_balance(-200,"test",false,false)==-100 and game.puku_balance_units==0)
	assert(game._puku_whole_count(4300)==4 and game._puku_fraction_units(4300)==300)
	assert(game._format_puku_units(2700)=="2.70")

func _test_live_harvest_preview(game)->void:
	assert(game.growing_puku_preview_toggle and game.growing_puku_preview_toggle.button_pressed and game.growing_puku_preview_toggle.text=="育成中のぷくコイン表示　ON")
	var foreground_ui:=game.labels_layer.get_parent() as CanvasLayer;var foreground_hud:Node=game.main_status_hud.get_parent()
	assert(game.greenhouse_layer.layer<game.best_record_layer.layer and game.best_record_layer.layer<game.plant_screen_layer.layer,"best record canvas is not behind the screen-space plants")
	assert(game.best_panel.get_parent()==game.best_record_layer and foreground_ui and game.plant_screen_layer.layer<foreground_ui.layer,"plants, best record, or growing labels are on the wrong canvas")
	assert(game.labels_layer.get_index()<foreground_hud.get_index(),"growing labels would cover the logo, gauges, or operation HUD")
	game._clear_greenhouse_plants();game.current_mode="greenhouse";game.play_active=true;game.active_seed_type="normal";game.current_target_count=12;game.puku_gauge_intro_complete=true;game.show_growing_puku_preview=true;game.species_get_counts["colorata"]=1
	game._spawn_specific_plant("colorata");var known=game.plants.back();known.jelly_checks_enabled=false;known.diameter_cm=70.0;game._update_labels()
	assert(known.label.text=="70.0 cm\n+0.80ぷくコイン")
	assert(known.label.visible and known.label.size.x<170.0 and known.label.size.y<58.0 and known.label.get_global_rect().position.x>=0.0 and known.label.get_global_rect().end.x<=game.get_viewport().get_visible_rect().end.x)
	game.species_get_counts.erase("colorata");known.set_meta("new_species_candidate",true);known.fast_forward_to_diameter(8.0);game._update_labels()
	assert(known.label.text=="NEW！\n8.0 cm\n+0.20ぷくコイン")
	game.language_code="hiragana";game._update_labels();assert(known.label.text.ends_with("+0.20ぷくこいん"))
	game.language_code="en";game._update_labels();assert(known.label.text.ends_with("+0.20 Puku Coins"))
	game.language_code="ja";game._change_growing_puku_preview(false);game._update_labels();assert(known.label.text=="NEW！\n8.0 cm" and known.label.size.x<=92.1 and known.label.size.y<68.0 and game.growing_puku_preview_toggle.text.ends_with("OFF"),"OFF label did not compact text=%s size=%s toggle=%s"%[known.label.text,known.label.size,game.growing_puku_preview_toggle.text])
	game._change_growing_puku_preview(true);game.puku_gauge_intro_complete=false;game._update_labels();assert(known.label.text=="NEW！\n8.0 cm")
	game.puku_gauge_intro_complete=true;game.active_seed_type="old";game._update_labels();assert(known.label.text=="NEW！\n8.0 cm")
	var sample_label:Label=game._plant_label();var long_lines:Array[String]=["NEW！","150.0 cm","+150.00ぷくコイン"];var long_size:Vector2=game._plant_label_size(sample_label,long_lines,true);var sample_width:=sample_label.get_theme_font("font").get_string_size(long_lines[-1],HORIZONTAL_ALIGNMENT_LEFT,-1,15).x;assert(long_size.x>=sample_width+16.0 and long_size.x<170.0 and long_size.y<76.0);sample_label.free()
	var occupied:Array[Rect2]=[];var viewport_rect:=Rect2(0,0,576,1024)
	for index in range(8):
		var plant_screen:=Vector2(68.0+float(index)*63.0,650.0);var rect:Rect2=game._plant_label_rect(plant_screen,long_size,occupied,viewport_rect)
		assert(viewport_rect.encloses(rect))
		assert(rect.end.y<=plant_screen.y-10.0 and rect.end.y>=plant_screen.y-48.0,"preview label drifted away from its plant")
		occupied.append(rect)
	game.play_active=false;game._clear_greenhouse_plants();game.show_growing_puku_preview=true

func _test_plant_label_visibility_toggle(game)->void:
	game.language_code="ja";game._update_plant_label_visibility_button()
	assert(game.show_growing_plant_labels and game.plant_label_visibility_button and game.plant_label_visibility_button.text=="表示ON")
	assert(Localizer.text("ja","plant_labels_on")=="表示ON" and Localizer.text("ja","plant_labels_off")=="表示OFF")
	assert(Localizer.text("hiragana","plant_labels_on")=="ひょうじON" and Localizer.text("hiragana","plant_labels_off")=="ひょうじOFF")
	assert(Localizer.text("en","plant_labels_on")=="Display ON" and Localizer.text("en","plant_labels_off")=="Display OFF")
	var button_rect:Rect2=game.plant_label_visibility_button.get_rect()
	assert(button_rect==Rect2(Vector2(18,952),Vector2(124,48)),"label toggle position or size changed: %s"%button_rect)
	var on_style:=game.plant_label_visibility_button.get_theme_stylebox("normal") as StyleBoxFlat
	var unrelated_style:=game.settings_button.get_theme_stylebox("normal") as StyleBoxFlat
	assert(on_style and unrelated_style)
	var on_luminance:=on_style.bg_color.get_luminance()
	var unrelated_color:=unrelated_style.bg_color
	game.opening_finished=true;game.opening_overlay.visible=false;game.intro_story_complete=true;game.habitat_awakened=true;game.habitat_tutorial_complete=true;game.seed_shop_open=true;game.puku_gauge_intro_complete=true
	game.first_play_tutorial_active=false;game.puku_buyback_tutorial_active=false;game.first_seed_pod_reward_event_active=false;game.scripted_dialog_kind="";game.tutorial_dialog_kind="";game.current_mode="greenhouse";game.arrangement_scene_active=false;game.arrangement_transitioning=false;game.catalog_preview_mode_active=false
	for overlay in [game.intro_overlay,game.result_overlay,game.play_overlay,game.shop_overlay,game.settings_overlay,game.encyclopedia_overlay,game.species_get_overlay,game.catalog_series_unlock_overlay,game.forest_gacha_ui,game.fusion_lab_ui,game.arrangement_ui,game.puku_puku_battle]:
		if overlay:overlay.visible=false
	game._clear_greenhouse_plants();game.play_active=true;game.active_seed_type="normal";game.current_target_count=12;game.show_growing_puku_preview=true;game.species_get_counts["colorata"]=1;game.species_get_counts.erase("laui")
	game._spawn_specific_plant("colorata");var known=game.plants.back();known.jelly_checks_enabled=false;known.fast_forward_to_diameter(70.0)
	game._spawn_specific_plant("laui");var new_plant=game.plants.back();new_plant.jelly_checks_enabled=false;new_plant.set_meta("new_species_candidate",true);new_plant.fast_forward_to_diameter(150.0)
	game._update_play_ui();game._update_labels()
	assert(game.plant_label_visibility_button.visible and known.label.visible and new_plant.label.visible)
	assert(known.label.text=="70.0 cm\n+0.80ぷくコイン" and new_plant.label.text.begins_with("NEW！\n150.0 cm\n"))
	game.plant_label_visibility_button.pressed.emit()
	assert(not game.show_growing_plant_labels and game.plant_label_visibility_button.visible and game.plant_label_visibility_button.text=="表示OFF")
	var off_style:=game.plant_label_visibility_button.get_theme_stylebox("normal") as StyleBoxFlat
	assert(off_style and off_style.bg_color.get_luminance()<on_luminance,"OFF state did not stay visibly darker than ON")
	assert((game.settings_button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color==unrelated_color,"label toggle styling leaked to another button")
	for localized_off in [{"code":"hiragana","text":"ひょうじOFF"},{"code":"en","text":"Display OFF"},{"code":"ja","text":"表示OFF"}]:
		game.language_code=str(localized_off.code);game._update_plant_label_visibility_button();assert(game.plant_label_visibility_button.text==str(localized_off.text))
	game._update_play_ui();assert((game.plant_label_visibility_button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color.get_luminance()<on_luminance,"OFF style only lasted for the press frame")
	assert(not known.label.visible and not new_plant.label.visible and game.show_growing_puku_preview,"whole-label toggle changed the separate reward-preview setting")
	assert(known.visible and known.screen_sprite.visible and new_plant.visible and new_plant.screen_sprite.visible,"hiding labels also hid plant artwork")
	game._spawn_specific_plant("colorata");var hidden_spawn=game.plants.back();hidden_spawn.jelly_checks_enabled=false
	assert(not hidden_spawn.label.visible,"a plant spawned while labels were hidden flashed its label before the next update")
	known.fast_forward_to_diameter(100.0);new_plant.fast_forward_to_diameter(200.0);game._update_labels();assert(not known.label.visible and not new_plant.label.visible)
	game.plant_label_visibility_button.pressed.emit()
	assert(game.show_growing_plant_labels and game.plant_label_visibility_button.text=="表示ON" and known.label.visible and new_plant.label.visible and hidden_spawn.label.visible)
	assert((game.plant_label_visibility_button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color.get_luminance()==on_luminance,"ON style did not return immediately with the state")
	assert(game.plant_label_visibility_button.get_rect()==button_rect,"label toggle layout changed while switching state")
	assert(known.label.text=="100.0 cm\n+3.75ぷくコイン" and new_plant.label.text.begins_with("NEW！\n200.0 cm\n"),"restored labels did not recalculate live values known=%s new=%s"%[known.label.text,new_plant.label.text])
	game._change_growing_puku_preview(false);assert(game.show_growing_plant_labels and known.label.text=="100.0 cm" and new_plant.label.text=="NEW！\n200.0 cm")
	game._toggle_growing_plant_labels();game._toggle_growing_plant_labels();assert(not game.show_growing_puku_preview and known.label.visible and known.label.text=="100.0 cm","whole-label toggle was not independent from reward-preview setting")
	known.fast_forward_to_diameter(1000.0);known.original_pos=Vector3(0,.12,2.5);known.position=known.original_pos;game._update_labels()
	var button_hit_point:=Vector2(-1,-1);var toggle_rect:Rect2=game.plant_label_visibility_button.get_global_rect()
	for target_cm in [1000.0,2000.0,5000.0,10000.0]:
		for position_x in [-4.0,-3.0,-2.0,-1.0,0.0,1.0]:
			known.fast_forward_to_diameter(target_cm);known.original_pos=Vector3(position_x,.12,2.5);known.position=known.original_pos;known.sync_screen_visual(game.camera)
			for row in range(1,8):
				for column in range(1,12):
					var candidate:=toggle_rect.position+Vector2(toggle_rect.size.x*float(column)/12.0,toggle_rect.size.y*float(row)/8.0)
					if bool(known.screen_hit_test(game.camera,candidate).get("opaque_artwork_hit",false)):button_hit_point=candidate;break
				if button_hit_point.x>=0.0:break
			if button_hit_point.x>=0.0:break
		if button_hit_point.x>=0.0:break
	assert(button_hit_point.x>=0.0,"input-isolation test did not place a giant leaf behind the label toggle")
	var press:=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.position=button_hit_point;press.pressed=true
	var release:=InputEventMouseButton.new();release.button_index=MOUSE_BUTTON_LEFT;release.position=button_hit_point;release.pressed=false
	game._input(press);game._input(release);assert(known.state=="growing" and not game.pointer_down,"label-toggle tap harvested the giant leaf behind the button")
	game.active_seed_type="old";game.first_colorata_confirmed=false;game.play_active=true;game._update_play_ui();assert(not game.plant_label_visibility_button.visible,"label toggle appeared during the old-seed story")
	game.active_seed_type="normal"
	game.play_active=false;game._update_play_ui();assert(game.plant_label_visibility_button.visible,"label toggle disappeared after a normal game ended")
	game.play_active=true;game.current_mode="habitat";game._update_play_ui();assert(not game.plant_label_visibility_button.visible,"label toggle appeared in habitat")
	game.current_mode="greenhouse";game.arrangement_scene_active=true;game._update_play_ui();assert(not game.plant_label_visibility_button.visible,"label toggle appeared in arrangement")
	game.arrangement_scene_active=false;game.first_play_tutorial_active=true;game._update_play_ui();assert(not game.plant_label_visibility_button.visible,"label toggle covered the first-play tutorial")
	game.first_play_tutorial_active=false;game.intro_overlay.visible=true;game._update_play_ui();assert(not game.plant_label_visibility_button.visible,"label toggle appeared over story UI")
	game.intro_overlay.visible=false;game.puku_puku_battle.visible=true;game._update_play_ui();assert(not game.plant_label_visibility_button.visible,"label toggle appeared in battle")
	game.puku_puku_battle.visible=false;assert(not game.result_overlay.visible and game.result_overlay.get_child_count()==0,"removed round result still has UI content")
	game.play_active=false;game.show_growing_plant_labels=true;game.show_growing_puku_preview=true;game._update_play_ui();game._clear_greenhouse_plants()

func _opaque_hit_point(plant,camera:Camera3D,visible_rect:Rect2)->Vector2:
	for row in range(1,48):
		for column in range(1,48):
			var point:=visible_rect.position+Vector2(visible_rect.size.x*float(column)/48.0,visible_rect.size.y*float(row)/48.0)
			var hit:Dictionary=plant.screen_hit_test(camera,point)
			if bool(hit.get("hit",false)) and bool(hit.get("opaque_artwork_hit",false)):return point
	# At extreme unbounded scales only a narrow source-image slice may intersect
	# the viewport. Inspect that exact slice so the regression proves that a real
	# visible leaf pixel, rather than merely the projected rectangle, is tappable.
	if plant.screen_texture_transform_valid and plant.screen_hit_image!=null and not plant.screen_hit_image.is_empty():
		var inverse:Transform2D=plant.screen_texture_transform.affine_inverse()
		var source_bounds:=Rect2(inverse*visible_rect.position,Vector2.ZERO)
		for corner in [Vector2(visible_rect.end.x,visible_rect.position.y),visible_rect.end,Vector2(visible_rect.position.x,visible_rect.end.y)]:source_bounds=source_bounds.expand(inverse*corner)
		var used:Rect2=plant._screen_hit_used_rect();source_bounds=source_bounds.intersection(used)
		var image_size:Vector2i=plant.screen_hit_image.get_size()
		for y in range(clampi(floori(source_bounds.position.y),0,image_size.y-1),clampi(ceili(source_bounds.end.y),0,image_size.y)):
			for x in range(clampi(floori(source_bounds.position.x),0,image_size.x-1),clampi(ceili(source_bounds.end.x),0,image_size.x)):
				if plant.screen_hit_image.get_pixel(x,y).a<=plant.SCREEN_ALPHA_HIT_THRESHOLD:continue
				var point:Vector2=plant.screen_texture_transform*Vector2(float(x)+.5,float(y)+.5)
				if not visible_rect.has_point(point):continue
				var hit:Dictionary=plant.screen_hit_test(camera,point)
				if bool(hit.get("hit",false)) and bool(hit.get("opaque_artwork_hit",false)):return point
	return Vector2(-10000,-10000)

func _sprite3d_item_rect_polygon(plant,camera:Camera3D)->PackedVector2Array:
	# Ask Godot's Sprite3D for its own item rectangle instead of duplicating the
	# production offset formula. Sprite3D maps the texture's top edge to the item
	# rectangle's bottom edge because screen-space Y and billboard-local Y oppose.
	var points:=PackedVector2Array()
	var texture_size:Vector2=plant.plant_sprite.texture.get_size()
	var item_rect:Rect2=plant.plant_sprite.get_item_rect()
	var basis:Basis=camera.global_transform.basis
	var angle:float=plant.plant_sprite.rotation.z
	var plane_right:Vector3=basis.x*cos(angle)+basis.y*sin(angle)
	var plane_up:Vector3=-basis.x*sin(angle)+basis.y*cos(angle)
	var global_scale:Vector3=plant.plant_sprite.global_transform.basis.get_scale()
	var origin:Vector3=plant.plant_sprite.global_position
	for pixel_point in [Vector2.ZERO,Vector2(texture_size.x,0.0),texture_size,Vector2(0.0,texture_size.y)]:
		var local_pixels:=Vector2(
			item_rect.position.x+pixel_point.x,
			item_rect.end.y-pixel_point.y
		)
		var world_point:Vector3=origin+plane_right*local_pixels.x*plant.plant_sprite.pixel_size*global_scale.x+plane_up*local_pixels.y*plant.plant_sprite.pixel_size*global_scale.y
		points.append(camera.unproject_position(world_point))
	return points

func _texture_transform_from_full_polygon(points:PackedVector2Array,texture_size:Vector2)->Transform2D:
	return Transform2D((points[1]-points[0])/texture_size.x,(points[3]-points[0])/texture_size.y,points[0])

func _copy_probe_camera(source:Camera3D,target:Camera3D)->void:
	target.projection=source.projection
	target.keep_aspect=source.keep_aspect
	target.fov=source.fov
	target.size=source.size
	target.frustum_offset=source.frustum_offset
	target.near=source.near
	target.far=source.far
	target.h_offset=source.h_offset
	target.v_offset=source.v_offset
	target.global_transform=source.global_transform

func _copy_probe_sprite(source:Sprite3D,target:Sprite3D)->void:
	target.texture=source.texture
	target.billboard=source.billboard
	target.pixel_size=source.pixel_size
	target.offset=source.offset
	target.centered=source.centered
	target.flip_h=source.flip_h
	target.flip_v=source.flip_v
	target.axis=source.axis
	target.alpha_cut=source.alpha_cut
	target.texture_filter=source.texture_filter
	target.global_transform=source.global_transform

func _capture_probe(viewport:SubViewport)->Image:
	await get_tree().process_frame
	await get_tree().process_frame
	return viewport.get_texture().get_image()

func _rect_edge_error(a:Rect2i,b:Rect2i)->int:
	return maxi(maxi(absi(a.position.x-b.position.x),absi(a.position.y-b.position.y)),maxi(absi(a.end.x-b.end.x),absi(a.end.y-b.end.y)))

func _test_sprite3d_render_alignment(game)->void:
	# Render Godot's real Sprite3D and the production Polygon2D separately into
	# the same transparent viewport. This catches a shared algebra mistake that a
	# formula-vs-formula test cannot detect.
	var display_driver:=DisplayServer.get_name()
	var rendering_driver:=RenderingServer.get_current_rendering_driver_name()
	if display_driver=="headless" or rendering_driver=="dummy" or rendering_driver.is_empty():
		sprite3d_render_oracle_status="skipped_dummy_renderer"
		print("SPRITE3D_RENDER_ORACLE_SKIPPED display=%s renderer=%s"%[display_driver,rendering_driver])
		return
	game._clear_greenhouse_plants();game.current_mode="greenhouse";game.play_active=true;game.active_seed_type="normal";game.current_target_count=12
	var probe_viewport:=SubViewport.new()
	probe_viewport.name="Sprite3DProjectionOracle"
	probe_viewport.size=Vector2i(game.get_viewport().get_visible_rect().size)
	probe_viewport.transparent_bg=true
	probe_viewport.own_world_3d=true
	probe_viewport.render_target_clear_mode=SubViewport.CLEAR_MODE_ALWAYS
	probe_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(probe_viewport)
	var probe_camera:=Camera3D.new();probe_viewport.add_child(probe_camera);_copy_probe_camera(game.camera,probe_camera);probe_camera.current=true
	var probe_sprite:=Sprite3D.new();probe_viewport.add_child(probe_sprite)
	var probe_polygon:=Polygon2D.new();probe_viewport.add_child(probe_polygon);probe_polygon.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var render_sizes:Array[float]=[1.6,5.0,10.0,20.0,30.0,40.0,60.0,80.0,100.0,120.0]
	var positions:Array[Vector3]=[Vector3(0,.12,2.5),Vector3(0,.12,0),Vector3(0,.12,-2.5)]
	var species_ids:Array[String]=["colorata","laui","yumekawa_milky_dream"]
	var offset_direction_checked:=false
	for species_id in species_ids:
		game.species_get_counts[species_id]=1;game._spawn_specific_plant(species_id);var plant=game.plants.back();plant.jelly_checks_enabled=false
		for position in positions:
			plant.original_pos=position;plant.position=position
			for target_cm in render_sizes:
				plant.fast_forward_to_diameter(target_cm);plant.plant_sprite.position.x=0.0;plant.plant_sprite.rotation.z=0.0
				_copy_probe_camera(game.camera,probe_camera);_copy_probe_sprite(plant.plant_sprite,probe_sprite)
				var projected:PackedVector2Array=plant._projected_texture_polygon(game.camera)
				assert(projected.size()==4,"render oracle projection missing species=%s pos=%s cm=%.1f"%[species_id,position,target_cm])
				probe_polygon.texture=plant.plant_sprite.texture
				probe_polygon.polygon=projected
				var texture_size:Vector2=plant.plant_sprite.texture.get_size()
				probe_polygon.uv=PackedVector2Array([Vector2.ZERO,Vector2(texture_size.x,0.0),texture_size,Vector2(0.0,texture_size.y)])
				probe_sprite.visible=true;probe_polygon.visible=false
				var sprite_image:Image=await _capture_probe(probe_viewport);var sprite_rect:Rect2i=sprite_image.get_used_rect()
				probe_sprite.visible=false;probe_polygon.visible=true
				var polygon_image:Image=await _capture_probe(probe_viewport);var polygon_rect:Rect2i=polygon_image.get_used_rect()
				assert(sprite_rect.has_area() and polygon_rect.has_area(),"render oracle produced empty artwork species=%s pos=%s cm=%.1f sprite=%s polygon=%s"%[species_id,position,target_cm,sprite_rect,polygon_rect])
				var edge_error:=_rect_edge_error(sprite_rect,polygon_rect);sprite3d_render_max_edge_error_px=maxi(sprite3d_render_max_edge_error_px,edge_error)
				assert(edge_error<=3,"Polygon2D does not match rendered Sprite3D species=%s pos=%s cm=%.1f sprite=%s polygon=%s"%[species_id,position,target_cm,sprite_rect,polygon_rect])
				if not offset_direction_checked and species_id=="colorata" and position==positions[1] and is_equal_approx(target_cm,20.0):
					probe_polygon.visible=false;probe_sprite.visible=true
					var negative_offset_rect:=sprite_rect
					probe_sprite.offset.y=0.0
					var zero_offset_image:Image=await _capture_probe(probe_viewport);var zero_offset_rect:Rect2i=zero_offset_image.get_used_rect()
					assert(zero_offset_rect.has_area() and negative_offset_rect.get_center().y>zero_offset_rect.get_center().y,"negative Sprite3D offset.y did not move the rendered image downward negative=%s zero=%s"%[negative_offset_rect,zero_offset_rect])
					offset_direction_checked=true
		game._clear_greenhouse_plants()
	assert(offset_direction_checked,"Sprite3D offset direction render check did not run")
	probe_sprite.visible=false;probe_polygon.visible=false
	var overlap_difference_ratio:float=await _test_sprite3d_overlap_render_alignment(game,probe_viewport,probe_camera)
	assert(overlap_difference_ratio<.05,"overlapping Polygon2D composition diverged from Sprite3D ratio=%.5f"%overlap_difference_ratio)
	sprite3d_render_oracle_status="pass_negative_offset_down_max_edge_%dpx_overlap_diff_%.4f"%[sprite3d_render_max_edge_error_px,overlap_difference_ratio]
	probe_viewport.queue_free();await get_tree().process_frame
	game.play_active=false;game._clear_greenhouse_plants()

func _test_sprite3d_overlap_render_alignment(game,probe_viewport:SubViewport,probe_camera:Camera3D)->float:
	game._clear_greenhouse_plants()
	var samples:Array=[
		{"species":"laui","position":Vector3(-.65,.12,-1.35),"cm":40.0},
		{"species":"yumekawa_milky_dream","position":Vector3(.55,.12,.35),"cm":50.0},
		{"species":"colorata","position":Vector3(-.2,.12,2.2),"cm":30.0}
	]
	for sample in samples:
		var species_id:=str(sample.species);game.species_get_counts[species_id]=1;game._spawn_specific_plant(species_id)
		var plant=game.plants.back();plant.jelly_checks_enabled=false;plant.original_pos=sample.position;plant.position=sample.position;plant.fast_forward_to_diameter(float(sample.cm));plant.plant_sprite.position.x=0.0;plant.plant_sprite.rotation.z=0.0
	game._sync_plant_screen_visuals();_copy_probe_camera(game.camera,probe_camera)
	var sprites:Array[Sprite3D]=[]
	var polygons:Array[Polygon2D]=[]
	for plant in game.plants:
		var sprite:=Sprite3D.new();probe_viewport.add_child(sprite);_copy_probe_sprite(plant.plant_sprite,sprite);sprites.append(sprite)
		var polygon:=Polygon2D.new();probe_viewport.add_child(polygon);polygon.texture=plant.plant_sprite.texture;polygon.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS;polygon.z_as_relative=false;polygon.z_index=plant.screen_draw_order()
		var projected:PackedVector2Array=plant._projected_texture_polygon(game.camera);var texture_size:Vector2=plant.plant_sprite.texture.get_size()
		polygon.polygon=projected;polygon.uv=PackedVector2Array([Vector2.ZERO,Vector2(texture_size.x,0.0),texture_size,Vector2(0.0,texture_size.y)]);polygon.visible=false;polygons.append(polygon)
	var sprite_image:Image=await _capture_probe(probe_viewport)
	for sprite in sprites:sprite.visible=false
	for polygon in polygons:polygon.visible=true
	var polygon_image:Image=await _capture_probe(probe_viewport)
	var occupied_pixels:=0
	var differing_pixels:=0
	for y in range(sprite_image.get_height()):
		for x in range(sprite_image.get_width()):
			var sprite_color:=sprite_image.get_pixel(x,y);var polygon_color:=polygon_image.get_pixel(x,y)
			if maxf(sprite_color.a,polygon_color.a)<=.02:continue
			occupied_pixels+=1
			var difference:=maxf(maxf(absf(sprite_color.r-polygon_color.r),absf(sprite_color.g-polygon_color.g)),maxf(absf(sprite_color.b-polygon_color.b),absf(sprite_color.a-polygon_color.a)))
			if difference>.08:differing_pixels+=1
	for sprite in sprites:sprite.free()
	for polygon in polygons:polygon.free()
	game._clear_greenhouse_plants()
	assert(occupied_pixels>0,"overlap render oracle produced no pixels")
	return float(differing_pixels)/float(occupied_pixels)

func _test_giant_plant_display_and_hit(game)->void:
	var viewport_rect:Rect2=game.get_viewport().get_visible_rect()
	var normal_sizes:Array[float]=[1.6,5.0,10.0,20.0,30.0,40.0,60.0,80.0,100.0,120.0]
	var giant_sizes:Array[float]=[150.0,200.0,300.0,500.0,700.0,1000.0,1500.0,2000.0,10000.0]
	var sizes:Array[float]=normal_sizes+giant_sizes
	var positions:Array=[Vector3(0,.12,2.5),Vector3(0,.12,0),Vector3(0,.12,-2.5)]
	var shape_species:Array[String]=["colorata","laui","yumekawa_milky_dream"]
	for target_cm in sizes:
		assert(is_equal_approx(SucculentClass.visual_scale_for_diameter(target_cm),.18+(target_cm-1.6)*.058),"visual scale stopped being linear at %.0fcm"%target_cm)
	var scale_ratio:=SucculentClass.visual_scale_for_diameter(1000.0)/SucculentClass.visual_scale_for_diameter(500.0)
	assert(scale_ratio>1.95 and scale_ratio<2.05,"500cm to 1000cm is not approximately 2x: %.4f"%scale_ratio)
	assert(SucculentClass.visual_scale_for_diameter(2000.0)>SucculentClass.visual_scale_for_diameter(1000.0)*1.99,"2000cm visual scale stopped growing linearly")
	assert(SucculentClass.visual_scale_for_diameter(10000.0)>SucculentClass.visual_scale_for_diameter(2000.0)*4.99,"10000cm visual scale introduced a practical cap")
	game._clear_greenhouse_plants();game.current_mode="greenhouse";game.play_active=true;game.active_seed_type="normal";game.current_target_count=12;game.puku_gauge_intro_complete=true;game.show_growing_puku_preview=true
	var harvest_handler:=Callable(game,"_on_harvested")
	var plant=null
	for species_id in shape_species:
		game.species_get_counts[species_id]=1;game._spawn_specific_plant(species_id);plant=game.plants.back();plant.jelly_checks_enabled=false
		if plant.harvested.is_connected(harvest_handler):plant.harvested.disconnect(harvest_handler)
		var used_rect:Rect2=plant._screen_hit_used_rect();var anchor_pixel:Vector2=plant._screen_growth_anchor_pixel();var texture_size:Vector2=plant.plant_sprite.texture.get_size()
		assert(used_rect.has_point(anchor_pixel),"growth anchor left opaque bounds species=%s anchor=%s used=%s"%[species_id,anchor_pixel,used_rect])
		assert(anchor_pixel.y<used_rect.position.y+used_rect.size.y*.80,"growth anchor still follows the bottom fringe species=%s anchor=%s used=%s"%[species_id,anchor_pixel,used_rect])
		assert(is_equal_approx(plant.plant_sprite.offset.y,-texture_size.y*.18),"legacy texture offset changed species=%s offset=%.4f expected=%.4f"%[species_id,plant.plant_sprite.offset.y,-texture_size.y*.18])
		for growth_speed in [1.6,10.0]:
			plant.growth_speed_multiplier=growth_speed
			for position in positions:
				plant.original_pos=position;plant.position=position
				plant.fast_forward_to_diameter(120.0);plant.plant_sprite.position.x=0.0;plant.plant_sprite.rotation.z=0.0
				var threshold_before:PackedVector2Array=plant._projected_texture_polygon(game.camera)
				plant.fast_forward_to_diameter(120.01);plant.plant_sprite.position.x=0.0;plant.plant_sprite.rotation.z=0.0
				var threshold_after:PackedVector2Array=plant._projected_texture_polygon(game.camera)
				assert(threshold_before.size()==4 and threshold_after.size()==4,"120cm transition polygon was missing species=%s speed=%.1f pos=%s"%[species_id,growth_speed,position])
				for corner in range(4):assert(threshold_before[corner].distance_to(threshold_after[corner])<.25,"artwork jumped at 120cm transition species=%s speed=%.1f pos=%s corner=%d before=%s after=%s"%[species_id,growth_speed,position,corner,threshold_before[corner],threshold_after[corner]])
				var previous_extent:=0.0;var width_500:=0.0;var width_1000:=0.0;var reference_root:=Vector2.ZERO;var reference_root_set:=false;var reference_main:=Vector2.ZERO;var reference_top_y:=INF;var reference_bottom_y:=-INF;var previous_normal_top_y:=INF;var previous_normal_bottom_y:=-INF
				for target_cm in sizes:
					plant.state="growing";plant.fast_forward_to_diameter(target_cm)
					# Compare the exact legacy Sprite3D projection without ambient sway.
					plant.plant_sprite.position.x=0.0;plant.plant_sprite.rotation.z=0.0;plant.sync_screen_visual(game.camera);game._update_labels()
					var rect:Rect2=plant.screen_visual_rect(game.camera);var visible_rect:=rect.intersection(viewport_rect);var root_screen:Vector2=game.camera.unproject_position(plant.global_position);var main_screen:Vector2=plant.screen_texture_transform*anchor_pixel;var top_screen:Vector2=plant.screen_texture_transform*Vector2(anchor_pixel.x,used_rect.position.y);var bottom_screen:Vector2=plant.screen_texture_transform*Vector2(anchor_pixel.x,used_rect.end.y)
					assert(plant.screen_sprite!=null and plant.screen_sprite.visible and not plant.plant_sprite.visible,"plant did not use the screen compositor species=%s speed=%.1f pos=%s cm=%.0f"%[species_id,growth_speed,position,target_cm])
					assert(plant.screen_sprite.polygon.size()>=3,"viewport-clipped giant artwork had no render polygon species=%s speed=%.1f pos=%s cm=%.0f"%[species_id,growth_speed,position,target_cm])
					for rendered_point in plant.screen_sprite.polygon:assert(viewport_rect.grow(3.0).has_point(rendered_point),"giant render polygon escaped viewport clipping species=%s speed=%.1f pos=%s cm=%.0f point=%s"%[species_id,growth_speed,position,target_cm,rendered_point])
					assert(plant.screen_depth(game.camera)>game.camera.near and viewport_rect.has_point(root_screen),"giant root crossed or left the camera view species=%s speed=%.1f pos=%s cm=%.0f"%[species_id,growth_speed,position,target_cm])
					assert(rect.has_area() and visible_rect.has_area(),"giant artwork disappeared species=%s speed=%.1f pos=%s cm=%.0f rect=%s"%[species_id,growth_speed,position,target_cm,rect])
					var extent:=maxf(rect.size.x,rect.size.y);assert(extent>previous_extent,"giant artwork stopped growing species=%s speed=%.1f pos=%s cm=%.0f extent=%.2f previous=%.2f"%[species_id,growth_speed,position,target_cm,extent,previous_extent]);previous_extent=extent
					if not reference_root_set:reference_root=root_screen;reference_root_set=true
					assert(root_screen.distance_to(reference_root)<.01,"soil planting point moved species=%s speed=%.1f pos=%s cm=%.1f root=%s reference=%s"%[species_id,growth_speed,position,target_cm,root_screen,reference_root])
					if target_cm<=120.0:
						assert(absf(plant.plant_sprite.position.y-(.10+plant.visual_scale*.62))<.00001,"legacy Sprite3D origin formula changed species=%s speed=%.1f pos=%s cm=%.1f y=%.6f expected=%.6f"%[species_id,growth_speed,position,target_cm,plant.plant_sprite.position.y,.10+plant.visual_scale*.62])
						assert(plant.plant_sprite.scale.is_equal_approx(Vector3.ONE*plant.visual_scale),"legacy Sprite3D scale changed species=%s speed=%.1f pos=%s cm=%.1f scale=%s expected=%.6f"%[species_id,growth_speed,position,target_cm,plant.plant_sprite.scale,plant.visual_scale])
						var expected_points:=_sprite3d_item_rect_polygon(plant,game.camera);var actual_points:PackedVector2Array=plant._projected_texture_polygon(game.camera)
						assert(expected_points.size()==4 and actual_points.size()==4,"legacy comparison polygon missing species=%s speed=%.1f pos=%s cm=%.1f"%[species_id,growth_speed,position,target_cm])
						for corner in range(4):assert(actual_points[corner].distance_to(expected_points[corner])<.01,"legacy corner mismatch species=%s speed=%.1f pos=%s cm=%.1f corner=%d actual=%s expected=%s"%[species_id,growth_speed,position,target_cm,corner,actual_points[corner],expected_points[corner]])
						var expected_transform:=_texture_transform_from_full_polygon(expected_points,texture_size)
						var texture_center:=texture_size*.5;var opaque_bottom_center:=Vector2(used_rect.get_center().x,used_rect.end.y)
						assert((plant.screen_texture_transform*texture_center).distance_to(expected_transform*texture_center)<.01,"legacy texture center mismatch species=%s speed=%.1f pos=%s cm=%.1f"%[species_id,growth_speed,position,target_cm])
						assert((plant.screen_texture_transform*opaque_bottom_center).distance_to(expected_transform*opaque_bottom_center)<.01,"legacy opaque bottom mismatch species=%s speed=%.1f pos=%s cm=%.1f"%[species_id,growth_speed,position,target_cm])
						if not is_inf(previous_normal_top_y):
							assert(top_screen.y<previous_normal_top_y,"normal artwork stopped expanding upward species=%s speed=%.1f pos=%s cm=%.1f top=%.3f previous=%.3f"%[species_id,growth_speed,position,target_cm,top_screen.y,previous_normal_top_y])
							assert(bottom_screen.y>previous_normal_bottom_y,"normal artwork floated upward instead of expanding downward species=%s speed=%.1f pos=%s cm=%.1f bottom=%.3f previous=%.3f"%[species_id,growth_speed,position,target_cm,bottom_screen.y,previous_normal_bottom_y])
						previous_normal_top_y=top_screen.y;previous_normal_bottom_y=bottom_screen.y
					if is_equal_approx(target_cm,120.0):reference_main=main_screen;reference_top_y=top_screen.y;reference_bottom_y=bottom_screen.y
					elif target_cm>120.0:
						assert(main_screen.distance_to(reference_main)<.05,"giant leaf-mass pivot moved from the legacy 120cm transform species=%s speed=%.1f pos=%s cm=%.1f main=%s reference=%s"%[species_id,growth_speed,position,target_cm,main_screen,reference_main])
						assert(top_screen.y<reference_top_y and bottom_screen.y>reference_bottom_y,"giant artwork stopped expanding around the legacy 120cm transform species=%s speed=%.1f pos=%s cm=%.1f top=%.3f/%.3f bottom=%.3f/%.3f"%[species_id,growth_speed,position,target_cm,top_screen.y,reference_top_y,bottom_screen.y,reference_bottom_y])
					if is_equal_approx(target_cm,500.0):width_500=rect.size.x
					if is_equal_approx(target_cm,1000.0):width_1000=rect.size.x
					assert(plant.label.visible,"plant label disappeared species=%s speed=%.1f pos=%s cm=%.1f"%[species_id,growth_speed,position,target_cm])
					if target_cm>=100.0:assert(plant.label.position.y<viewport_rect.get_center().y,"giant label disappeared or jumped downward species=%s speed=%.1f pos=%s cm=%.0f label=%s"%[species_id,growth_speed,position,target_cm,plant.label.position])
					var tap_point:=_opaque_hit_point(plant,game.camera,visible_rect);var hit:Dictionary=plant.screen_hit_test(game.camera,tap_point)
					assert(tap_point.x>-9999.0 and bool(hit.get("hit",false)) and bool(hit.get("opaque_artwork_hit",false)),"visible giant leaf was not alpha-hittable species=%s speed=%.1f pos=%s cm=%.0f tap=%s"%[species_id,growth_speed,position,target_cm,tap_point])
					# Advance one real frame at each configured speed as well as checking the
					# exact checkpoint, then harvest through the visible alpha-tested leaf.
					plant.simulate(1.0/12.0 if growth_speed>=10.0 else 1.0/60.0);plant.sync_screen_visual(game.camera)
					var live_visible_rect:Rect2=plant.screen_visual_rect(game.camera).intersection(viewport_rect)
					assert(plant.screen_sprite.visible and live_visible_rect.has_area(),"giant artwork failed after a live growth frame species=%s speed=%.1f pos=%s cm=%.0f"%[species_id,growth_speed,position,target_cm])
					if not plant.uses_giant_screen_transform():
						var live_expected:=_sprite3d_item_rect_polygon(plant,game.camera);var live_actual:PackedVector2Array=plant._projected_texture_polygon(game.camera)
						for corner in range(4):assert(live_actual[corner].distance_to(live_expected[corner])<.01,"live legacy projection mismatch species=%s speed=%.1f pos=%s cm=%.1f corner=%d"%[species_id,growth_speed,position,plant.diameter_cm,corner])
					tap_point=_opaque_hit_point(plant,game.camera,live_visible_rect)
					assert(tap_point.x>-9999.0,"live growth frame left no tappable visible leaf species=%s speed=%.1f pos=%s cm=%.1f"%[species_id,growth_speed,position,target_cm])
					game._try_harvest(tap_point);assert(plant.state=="harvested","visible giant leaf did not harvest species=%s speed=%.1f pos=%s cm=%.0f"%[species_id,growth_speed,position,target_cm])
				assert(width_500>0.0 and width_1000/width_500>1.95 and width_1000/width_500<2.05,"rendered 500cm to 1000cm ratio was not approximately 2x species=%s: %.4f"%[species_id,width_1000/width_500])
		game._clear_greenhouse_plants();plant=null
	game.species_get_counts["colorata"]=1;game._spawn_specific_plant("colorata");plant=game.plants.back();plant.jelly_checks_enabled=false
	if plant.harvested.is_connected(harvest_handler):plant.harvested.disconnect(harvest_handler)
	# Horizontal scrolling, harvesting and jelly must still control visibility.
	plant.state="growing";plant.growth_speed_multiplier=1.6;plant.fast_forward_to_diameter(1000.0);plant.original_pos=Vector3(0,.12,0);plant.position=plant.original_pos;game._update_labels();assert(plant.label.visible)
	var saved_original_pos:Vector3=plant.original_pos;var saved_position:Vector3=plant.position;plant.original_pos.x+=1000.0;plant.position.x+=1000.0;game._update_labels();assert(not game._plant_is_visible_for_label(plant,viewport_rect) and not plant.label.visible,"fully scrolled-off giant plant kept its label")
	plant.original_pos=saved_original_pos;plant.position=saved_position;game._update_labels();assert(plant.label.visible,"giant label did not return with its plant after horizontal scrolling")
	plant.state="harvested";game._update_labels();assert(not plant.label.visible,"harvested giant plant kept its label");plant.state="jelly";game._update_labels();assert(not plant.label.visible,"jellied giant plant kept its label");plant.state="growing";game._update_labels();assert(plant.label.visible)
	# When two opaque leaves overlap, the front root is drawn and picked on top.
	plant.fast_forward_to_diameter(500.0);plant.original_pos=Vector3(0,.12,-1.0);plant.position=plant.original_pos
	game._spawn_specific_plant("colorata");var front_plant=game.plants.back();front_plant.jelly_checks_enabled=false;front_plant.original_pos=Vector3(0,.12,2.5);front_plant.position=front_plant.original_pos;front_plant.fast_forward_to_diameter(100.0)
	if front_plant.harvested.is_connected(harvest_handler):front_plant.harvested.disconnect(harvest_handler)
	game._update_labels()
	var overlap_rect:Rect2=plant.screen_visual_rect(game.camera).intersection(front_plant.screen_visual_rect(game.camera)).intersection(viewport_rect);var overlap_point:=Vector2(-1,-1)
	for row in range(1,10):
		for column in range(1,10):
			var candidate:=overlap_rect.position+Vector2(overlap_rect.size.x*float(column)/10.0,overlap_rect.size.y*float(row)/10.0);var back_hit:Dictionary=plant.screen_hit_test(game.camera,candidate);var front_hit:Dictionary=front_plant.screen_hit_test(game.camera,candidate)
			if bool(back_hit.get("opaque_artwork_hit",false)) and bool(front_hit.get("opaque_artwork_hit",false)):overlap_point=candidate;break
		if overlap_point.x>=0.0:break
	assert(overlap_point.x>=0.0,"overlap regression could not find two visible leaves")
	assert(front_plant.screen_draw_order()>plant.screen_draw_order(),"front plant was not drawn above the rear giant")
	game._try_harvest(overlap_point);assert(front_plant.state=="harvested" and plant.state=="growing","overlapping harvest did not select the topmost visible leaf")
	game.play_active=false;game._clear_greenhouse_plants()

func _test_giant_harvest_reward(game)->void:
	game._cancel_puku_gauge_animations();game.puku_gauge_animation_speed_scale=.02;game._clear_greenhouse_plants();game.current_mode="greenhouse";game.play_active=true;game.active_seed_type="normal";game.current_target_count=12;game.play_seeds_remaining=0;game.play_spawn_queue=0;game.play_seed_animations_pending=1;game.puku_gauge_intro_complete=true;game.species_get_counts["colorata"]=1
	for target_cm in [1000.0,2000.0]:
		game.puku_balance_units=0;game.bests["colorata"]=0.0
		game._spawn_specific_plant("colorata");var plant=game.plants.back();plant.jelly_checks_enabled=false;plant.original_pos=Vector3(0,.12,0);plant.position=plant.original_pos;plant.fast_forward_to_diameter(target_cm);game._update_labels()
		var expected_units:int=game._harvest_puku_reward_units(plant.diameter_cm,false);var visible_rect:Rect2=plant.screen_visual_rect(game.camera).intersection(game.get_viewport().get_visible_rect());var tap_point:=_opaque_hit_point(plant,game.camera,visible_rect)
		assert(tap_point.x>-9999.0,"could not find a visible leaf for %.0fcm reward test"%target_cm)
		game._try_harvest(tap_point);await get_tree().process_frame;await get_tree().process_frame
		assert(game.puku_balance_units==expected_units,"%.0fcm screen-tap harvest paid the wrong reward expected=%d actual=%d"%[target_cm,expected_units,game.puku_balance_units]);assert(is_equal_approx(float(game.bests.get("colorata",0.0)),target_cm),"giant screen-tap harvest did not preserve the %.0fcm record"%target_cm)
		game._clear_greenhouse_plants();game._cancel_puku_gauge_animations()
	game.play_active=false;game.play_seed_animations_pending=0;game._clear_greenhouse_plants();game._cancel_puku_gauge_animations();game.puku_gauge_animation_speed_scale=1.0
	for result_panel in game.effects_layer.find_children("HarvestResult","",true,false):result_panel.free()

func _test_greenhouse_pan_depth_and_hit(game)->void:
	var viewport_rect:Rect2=game.get_viewport().get_visible_rect()
	var positions:Array[Vector3]=[Vector3(0,.12,2.5),Vector3(0,.12,0),Vector3(0,.12,-2.5)]
	var harvest_handler:=Callable(game,"_on_harvested")
	for target_cm in [60.0,120.0,150.0]:
		for pan_ratio in [-.65,0.0,.65]:
			var screen_deltas:Array[float]=[]
			for original_position in positions:
				game._clear_greenhouse_plants();game.current_mode="greenhouse";game.play_active=true;game.active_seed_type="normal";game.current_target_count=12
				game.greenhouse_pan_x=0.0;game.greenhouse_pan_target_x=0.0;game.arrangement_transition_x=0.0;game._update_greenhouse_pan()
				game.species_get_counts["colorata"]=1;game._spawn_specific_plant("colorata");var plant=game.plants.back();plant.jelly_checks_enabled=false
				if plant.harvested.is_connected(harvest_handler):plant.harvested.disconnect(harvest_handler)
				plant.original_pos=original_position;plant.position=original_position;plant.fast_forward_to_diameter(target_cm);plant.plant_sprite.position.x=0.0;plant.plant_sprite.rotation.z=0.0
				game._resolve_crowding(0.0);game._sync_plant_screen_visuals()
				var root_before:Vector2=game.camera.unproject_position(plant.global_position)
				game.greenhouse_pan_x=game.greenhouse_pan_limit*float(pan_ratio);game.greenhouse_pan_target_x=game.greenhouse_pan_x;game._update_greenhouse_pan();game._resolve_crowding(0.0);game._sync_plant_screen_visuals()
				var root_after:Vector2=game.camera.unproject_position(plant.global_position)
				screen_deltas.append(absf(root_after.x-root_before.x))
				assert(absf(root_after.y-root_before.y)<.01,"horizontal pan moved the planted root vertically cm=%.0f pan=%.2f pos=%s before=%s after=%s"%[target_cm,pan_ratio,original_position,root_before,root_after])
				var visible_rect:Rect2=plant.screen_visual_rect(game.camera).intersection(viewport_rect)
				assert(visible_rect.has_area(),"panned plant disappeared cm=%.0f pan=%.2f pos=%s"%[target_cm,pan_ratio,original_position])
				var tap_point:=_opaque_hit_point(plant,game.camera,visible_rect)
				assert(tap_point.x>-9999.0 and bool(plant.screen_hit_test(game.camera,tap_point).get("opaque_artwork_hit",false)),"panned visible leaf lost its matching hit area cm=%.0f pan=%.2f pos=%s"%[target_cm,pan_ratio,original_position])
				game._try_harvest(tap_point)
				assert(plant.state=="harvested","panned visible leaf did not harvest cm=%.0f pan=%.2f pos=%s"%[target_cm,pan_ratio,original_position])
			if is_zero_approx(float(pan_ratio)):
				assert(screen_deltas[0]<.01 and screen_deltas[1]<.01 and screen_deltas[2]<.01,"centred pan moved roots cm=%.0f deltas=%s"%[target_cm,screen_deltas])
			else:
				assert(screen_deltas[0]>screen_deltas[1]+.5 and screen_deltas[1]>screen_deltas[2]+.5,"front/centre/rear pan lost perspective cm=%.0f pan=%.2f deltas=%s"%[target_cm,pan_ratio,screen_deltas])
	game.greenhouse_pan_x=0.0;game.greenhouse_pan_target_x=0.0;game.arrangement_transition_x=0.0;game._update_greenhouse_pan();game._clear_greenhouse_plants();game.play_active=false

func _wait_for_puku_animation(game)->void:
	for _i in range(240):
		if not game.puku_gauge_animation_running and game.puku_gauge_animation_queue.is_empty():return
		await get_tree().process_frame
	assert(false,"puku balance animation timed out")

func _test_signed_balance_animation(game)->void:
	game._cancel_puku_gauge_animations();game.puku_balance_units=4300;game.puku_gauge_threshold_flash_count=0;game.puku_gauge_animation_speed_scale=.02;game._update_puku_ui()
	assert(game._change_puku_balance(400,"test_gain",false,true)==400)
	await _wait_for_puku_animation(game)
	assert(game.puku_balance_units==4700 and game.puku_points_display==4 and roundi(game.puku_gauge_display_units)==700)
	game._cancel_puku_gauge_animations();game.puku_balance_units=4000;game.puku_gauge_threshold_flash_count=0;game._update_puku_ui()
	assert(game._change_puku_balance(2400,"test_gain",false,true)==2400)
	await _wait_for_puku_animation(game)
	assert(game.puku_balance_units==6400 and game.puku_points_display==6 and roundi(game.puku_gauge_display_units)==400 and game.puku_gauge_threshold_flash_count==2)
	assert(not game.puku_combo_label.visible and game.puku_gauge_combo_count==0)
	var combo_generation: int = game.puku_gauge_animation_generation
	game.puku_gauge_animation_speed_scale=.02
	await game._play_puku_balance_boundary(1,combo_generation)
	assert(game.puku_gauge_combo_count==1 and not game.puku_combo_label.visible)
	await game._play_puku_balance_boundary(1,combo_generation)
	assert(game.puku_combo_label.visible and game.puku_combo_label.text=="×2")
	await game._play_puku_balance_boundary(1,combo_generation)
	assert(game.puku_combo_label.visible and game.puku_combo_label.text=="×3")
	game._reset_puku_combo_display()
	game.puku_gauge_threshold_flash_count=2
	assert(game._change_puku_balance(-200,"test_spend",false,true)==-200)
	await _wait_for_puku_animation(game)
	assert(game.puku_balance_units==6200 and game.puku_points_display==6 and roundi(game.puku_gauge_display_units)==200)
	assert(game._change_puku_balance(-2000,"test_spend",false,true)==-2000)
	await _wait_for_puku_animation(game)
	assert(game.puku_balance_units==4200 and game.puku_points_display==4 and roundi(game.puku_gauge_display_units)==200 and game.puku_gauge_threshold_flash_count==4)
	game._cancel_puku_gauge_animations();game.puku_balance_units=0;game.puku_gauge_threshold_flash_count=0;game._update_puku_ui();var large_start:=Time.get_ticks_msec()
	assert(game._change_puku_balance(150000,"test_jackpot",false,true)==150000)
	await _wait_for_puku_animation(game)
	assert(game.puku_balance_units==150000 and game.puku_points_display==150 and game.puku_gauge_threshold_flash_count==150)
	assert(Time.get_ticks_msec()-large_start<2000,"150 Puku animation took too long")
	game.puku_gauge_animation_speed_scale=1.0

func _test_round_entry_and_harvest(game)->void:
	game._cancel_puku_gauge_animations();game.puku_gauge_animation_speed_scale=.02;game._clear_greenhouse_plants();game.opening_finished=true;game.opening_overlay.visible=false;game.current_mode="greenhouse";game._apply_mode();game.first_habitat_gift_claimed=true;game.puku_balance_units=1400;game.normal_round_free_plays=0
	# Isolate this entry check from any deferred round state produced while the
	# preceding live-label test advances frames for the wallet animation.
	game.play_active=false
	game._start_greenhouse_play("normal")
	assert(game.play_active and game.current_target_count==12 and game.play_concurrent_target>=game.ENDLESS_NORMAL_MIN_PLANTS and game.play_concurrent_target<=game.ENDLESS_NORMAL_MAX_PLANTS,"normal round did not start active=%s endless=%s target=%d concurrent=%d range=%d-%d balance=%d"%[game.play_active,game._is_endless_greenhouse_enabled(),game.current_target_count,game.play_concurrent_target,game.ENDLESS_NORMAL_MIN_PLANTS,game.ENDLESS_NORMAL_MAX_PLANTS,game.puku_balance_units])
	assert(game.puku_balance_units==400 and game.endless_economy_seed_cost_units==1000)
	assert(game.play_seeds_remaining==12-game.play_concurrent_target)
	await get_tree().create_timer(.4).timeout
	assert(game.endless_economy_seed_count==game.play_concurrent_target and game.puku_balance_units==400)
	game.play_active=false;game._clear_greenhouse_plants();game.play_seed_animations_pending=0;game.play_spawn_queue=0
	# Use a fresh direct plant after verifying the one-time round entry charge.
	game.puku_balance_units=0;game.play_active=true;game.active_seed_type="normal";game.play_seeds_remaining=0;game.play_concurrent_target=0;game._reset_endless_economy_stats();game._spawn_specific_plant("colorata");var harvested=game.plants.back();harvested.jelly_checks_enabled=false;harvested.diameter_cm=100.0
	var preexisting_count:int=int(game._species_get_count("colorata"));game.species_get_counts["colorata"]=maxi(1,preexisting_count)
	harvested.harvest();await get_tree().process_frame
	assert(game.puku_balance_units==3750 and game.play_puku_reward_units_total==3750 and game.endless_economy_harvest_reward_units==3750)
	assert(game._puku_gauge_is_only_finish_blocker())
	assert(is_equal_approx(game._puku_gauge_effective_speed_scale(),game.puku_gauge_animation_speed_scale*game.PUKU_GAUGE_FINISH_SPEED_SCALE))
	var panel:=game.effects_layer.find_child("HarvestResult",true,false) as PanelContainer
	assert(panel and (panel.find_child("PukuRewardGain",true,false) as Label).text=="+3.75ぷく")
	assert(game.effects_layer.find_child("PukuBalanceFly",true,false)==null)
	assert(game.play_active and not game.result_overlay.visible and game._greenhouse_finish_block_reason()=="puku_gauge_animation")
	await _wait_for_puku_animation(game);await get_tree().process_frame;await get_tree().process_frame
	assert(not game.play_active and not game.result_overlay.visible and game.greenhouse_finish_completed_count==1)
	game._clear_greenhouse_plants();game.species_get_counts.erase("colorata");game.puku_balance_units=0;game.play_active=true;game.active_seed_type="normal";game.play_seeds_remaining=0;game.play_concurrent_target=0;game._reset_endless_economy_stats();game._spawn_specific_plant("colorata");var new_plant=game.plants.back();new_plant.jelly_checks_enabled=false;new_plant.diameter_cm=8.0;new_plant.harvest();await get_tree().process_frame
	assert(game.puku_balance_units==200 and game._species_get_count("colorata")==0 and "colorata" in game.pending_round_new_species_ids)
	game.play_active=false;game.greenhouse_round_followup_started=false;game._continue_after_greenhouse_round();await get_tree().process_frame
	assert(game._species_get_count("colorata")==1 and "colorata" not in game.pending_round_new_species_ids)
	assert(game.species_get_overlay.visible and game.species_get_active_context=="round_result_new")
	game.species_get_overlay.visible=false;game._on_species_get_overlay_closed("round_result_new");await get_tree().process_frame
	game._clear_greenhouse_plants();game._cancel_puku_gauge_animations();game.puku_gauge_animation_speed_scale=1.0

func _test_catalog_auto_record(game)->void:
	var gummy:Dictionary=game._series_entry("gummy");game.unlocked_series.erase("gummy");game.current_encyclopedia_series_id="gummy";game.puku_balance_units=5500
	game._refresh_encyclopedia_header();assert(not game.encyclopedia_unlock_panel.visible and not game.encyclopedia_unlock_puku_button.visible and not game._catalog_purchase_enabled(gummy))
	game._acquire_current_catalog("puku");assert(not game._is_series_unlocked(gummy) and game.puku_balance_units==5500)
	var first_gummy_id:=str(game._series_species_entries("gummy")[0].get("species_id",""));assert(game._register_species_discovery(first_gummy_id,true));assert(game._is_series_unlocked(gummy) and game.puku_balance_units==5500)

func _test_save_and_legacy_load(game)->void:
	var save_path:String=str(game._active_save_path())
	game.puku_gauge_cm=250.5;game.puku_balance_units=4375;game.normal_round_free_plays=1;game.show_growing_puku_preview=false;game._save();var current=JSON.parse_string(FileAccess.get_file_as_string(save_path));assert(current is Dictionary and int(current.get("puku_balance_units",-1))==4375 and int(current.get("normal_round_free_plays",0))==1 and not bool(current.get("show_growing_puku_preview",true)));game.puku_gauge_cm=0.0;game.puku_balance_units=0;game.normal_round_free_plays=0;game.show_growing_puku_preview=true;game._load_save()
	assert(is_equal_approx(game.puku_gauge_cm,250.5) and game.puku_balance_units==4375 and game.puku_points==4 and game.normal_round_free_plays==1 and not game.show_growing_puku_preview)
	# A legacy wallet keeps both whole coins and the old 500cm=>3 puku partial gauge.
	current.erase("puku_balance_units");current.erase("show_growing_puku_preview");current["puku_points"]=4;current["puku_coin_gauge_cm"]=125.0;current["puku_gauge_intro_complete"]=false;current["mystery_items_acquired"]=false;current["habitat_awakened"]=false;current["habitat_tutorial_started"]=false;current["habitat_tutorial_complete"]=false;current["habitat_unlocked"]=false;current["tutorial_steps"]={}
	var legacy_wallet:=FileAccess.open(save_path,FileAccess.WRITE);legacy_wallet.store_string(JSON.stringify(current));legacy_wallet.close();game.puku_balance_units=0;game._load_save()
	assert(game.puku_balance_units==4750 and game.show_growing_puku_preview)
	# Already-unlocked old saves receive the one-time minimum operating capital.
	current.erase("puku_balance_units");current["puku_points"]=1;current["puku_coin_gauge_cm"]=0.0;current["puku_gauge_intro_complete"]=true
	legacy_wallet=FileAccess.open(save_path,FileAccess.WRITE);legacy_wallet.store_string(JSON.stringify(current));legacy_wallet.close();game.puku_balance_units=0;game._load_save()
	assert(game.puku_balance_units==5000)
	game._save();var migrated=JSON.parse_string(FileAccess.get_file_as_string(save_path));assert(int(migrated.get("puku_balance_units",-1))==5000)

func _test_panda_rescue(game)->void:
	game.play_active=false;game.active_seed_type="normal";game.current_mode="greenhouse";game.first_habitat_gift_claimed=true;game.puku_gauge_intro_complete=true;game.mystery_items_acquired=true;game.mystery_catalog_tutorial_complete=true;game.initial_seed_stock_notice_complete=true;game.normal_play_tutorial_complete=true;game.habitat_awakened=true;game.habitat_tutorial_complete=true;game.seed_shop_open=true;game.puku_balance_units=100;game.normal_round_free_plays=0
	game.opening_finished=true;game.opening_overlay.visible=false;game.play_modal_open=false;game.result_overlay.visible=false;game.shop_overlay.visible=false;game.encyclopedia_overlay.visible=false;game.settings_overlay.visible=false;game.fusion_lab_ui.visible=false;game.species_get_overlay.visible=false;game.catalog_series_unlock_overlay.visible=false;game.forest_gacha_ui.visible=false;game.arrangement_ui.visible=false
	assert(game._shop_puku_rescue_needed())
	game._update_play_ui()
	assert(game.play_open_button.visible and not game.play_open_button.disabled)
	assert(game.play_open_button.text=="パンダのお手伝いをする\n＋1ぷくコイン")
	game._open_play_modal();assert(game.shop_overlay.visible and game.shop_chatter_action_button.visible and not game.play_active)
	game._request_rescue_reward_ad();await get_tree().create_timer(.8).timeout
	assert(game.puku_balance_units==1100 and game.normal_round_free_plays==0 and not game.rescue_reward_in_progress and not game.play_active)
	game._close_shop();game._update_play_ui()
	assert(game.play_open_button.text=="たねをまく\n1ぷくコイン消費")
	game._start_greenhouse_play("normal");assert(game.play_active and game.normal_round_free_plays==0 and game.puku_balance_units==100 and game.endless_economy_seed_cost_units==1000)
	assert(game.FOREST_GACHA_SPIN_COST==1)
	game.play_active=false
