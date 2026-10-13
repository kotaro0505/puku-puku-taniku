extends Node

const SucculentClass=preload("res://scripts/succulent.gd")

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
	_test_giant_plant_display_and_hit(game)
	_test_live_harvest_preview(game)
	await _test_giant_harvest_reward(game)
	await _test_signed_balance_animation(game)
	await _test_round_entry_and_harvest(game)
	_test_catalog_auto_record(game)
	_test_save_and_legacy_load(game)
	await _test_panda_rescue(game)
	game._reset_progression_state();game.queue_free()
	print("PUKU_POINTS_SMOKE_OK unit=1/1000 round_cost=1.00 direct_harvest=true giant=100..1500cm_positions3_speeds1.6+10 reward709=true new_floor=.20 migration=points+legacy_gauge forest_cost=1 rescue=wallet_plus_1 combo=true fly_removed=true result_waits=true")
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
	assert(game.greenhouse_layer.layer<game.best_record_layer.layer and game.best_record_layer.layer<0,"best record canvas is not between the greenhouse backdrop and 3D plants")
	assert(game.best_panel.get_parent()==game.best_record_layer and foreground_ui and foreground_ui.layer>0,"best record or growing labels are on the wrong canvas")
	assert(game.labels_layer.get_index()<foreground_hud.get_index(),"growing labels would cover the logo, gauges, or operation HUD")
	game._clear_greenhouse_plants();game.current_mode="greenhouse";game.play_active=true;game.active_seed_type="normal";game.current_target_count=12;game.puku_gauge_intro_complete=true;game.show_growing_puku_preview=true;game.species_get_counts["colorata"]=1
	game._spawn_specific_plant("colorata");var known=game.plants.back();known.jelly_checks_enabled=false;known.diameter_cm=70.0;game._update_labels()
	assert(known.label.text=="70.0 cm\n+0.80ぷくコイン")
	assert(known.label.visible and known.label.size.x<170.0 and known.label.size.y<58.0 and known.label.get_global_rect().position.x>=0.0 and known.label.get_global_rect().end.x<=game.get_viewport().get_visible_rect().end.x)
	game.species_get_counts.erase("colorata");known.set_meta("new_species_candidate",true);known.fast_forward_to_diameter(8.0);game._update_labels()
	assert(known.label.text=="NEW！\n8.0 cm\n+0.20ぷくコイン")
	game.language_code="hiragana";game._update_labels();assert(known.label.text.ends_with("+0.20ぷくこいん"))
	game.language_code="en";game._update_labels();assert(known.label.text.ends_with("+0.20 Puku Coins"))
	game.language_code="ja";game._change_growing_puku_preview(false);game._update_labels();assert(known.label.text=="NEW！\n8.0 cm" and known.label.size.x<=92.0 and known.label.size.y<68.0 and game.growing_puku_preview_toggle.text.ends_with("OFF"),"OFF label did not compact text=%s size=%s toggle=%s"%[known.label.text,known.label.size,game.growing_puku_preview_toggle.text])
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

func _opaque_hit_point(plant,camera:Camera3D,visible_rect:Rect2)->Vector2:
	for row in range(1,8):
		for column in range(1,8):
			var point:=visible_rect.position+Vector2(visible_rect.size.x*float(column)/8.0,visible_rect.size.y*float(row)/8.0)
			var hit:Dictionary=plant.screen_hit_test(camera,point)
			if bool(hit.get("hit",false)) and bool(hit.get("opaque_artwork_hit",false)):return point
	return visible_rect.get_center()

func _test_giant_plant_display_and_hit(game)->void:
	var viewport_rect:Rect2=game.get_viewport().get_visible_rect();var viewport_area:=viewport_rect.get_area()
	var sizes:Array[float]=[100.0,150.0,160.0,200.0,300.0,400.0,468.0,486.0,500.0,709.0,1000.0,1500.0]
	var positions:Array=[Vector3(0,.12,2.5),Vector3(0,.12,0),Vector3(0,.12,-2.5)]
	assert(is_equal_approx(SucculentClass.visual_scale_for_diameter(100.0),.18+(100.0-1.6)*.058),"100cm appearance changed before giant-size compression")
	assert(is_equal_approx(SucculentClass.visual_scale_for_diameter(120.0),.18+(120.0-1.6)*.058),"compression transition is not continuous")
	assert(SucculentClass.visual_scale_for_diameter(1500.0)<=SucculentClass.GIANT_VISUAL_SCALE_LIMIT and SucculentClass.visual_scale_for_diameter(1500.0)>SucculentClass.visual_scale_for_diameter(120.0),"giant display scale is capped incorrectly")
	game._clear_greenhouse_plants();game.current_mode="greenhouse";game.play_active=true;game.active_seed_type="normal";game.current_target_count=12;game.puku_gauge_intro_complete=true;game.show_growing_puku_preview=true;game.species_get_counts["colorata"]=1
	game._spawn_specific_plant("colorata");var plant=game.plants.back();plant.jelly_checks_enabled=false
	var harvest_handler:=Callable(game,"_on_harvested")
	if plant.harvested.is_connected(harvest_handler):plant.harvested.disconnect(harvest_handler)
	for growth_speed in [1.6,10.0]:
		plant.growth_speed_multiplier=growth_speed
		for position in positions:
			plant.original_pos=position;plant.position=position
			var previous_scale:=0.0
			for target_cm in sizes:
				plant.state="growing";plant.fast_forward_to_diameter(target_cm);plant.simulate(1.0/60.0);game._update_labels()
				var rect:Rect2=plant.screen_visual_rect(game.camera);var visible_rect:=rect.intersection(viewport_rect);var center_world:Vector3=plant.plant_sprite.global_position;var center_screen:Vector2=game.camera.unproject_position(center_world)
				assert(not game.camera.is_position_behind(center_world) and plant.screen_depth(game.camera)>game.camera.near,"giant sprite crossed the camera plane speed=%.1f pos=%s cm=%.0f"%[growth_speed,position,target_cm])
				assert(plant.plant_sprite.visible and rect.has_area() and visible_rect.has_area(),"giant sprite left the viewport speed=%.1f pos=%s cm=%.0f rect=%s"%[growth_speed,position,target_cm,rect])
				assert(viewport_rect.grow(24.0).has_point(center_screen),"giant sprite center projected outside the safe viewport speed=%.1f pos=%s cm=%.0f center=%s"%[growth_speed,position,target_cm,center_screen])
				assert(visible_rect.get_area()/viewport_area<.80,"giant artwork covered too much of the screen speed=%.1f pos=%s cm=%.0f coverage=%.3f"%[growth_speed,position,target_cm,visible_rect.get_area()/viewport_area])
				assert(plant.visual_scale>=previous_scale and plant.visual_scale<=plant.GIANT_VISUAL_SCALE_LIMIT+.001,"display scale was not safely compressed speed=%.1f cm=%.0f scale=%.3f"%[growth_speed,target_cm,plant.visual_scale]);previous_scale=plant.visual_scale
				assert(plant.label.visible and plant.label.position.y<viewport_rect.get_center().y,"giant label disappeared or jumped downward speed=%.1f pos=%s cm=%.0f label=%s"%[growth_speed,position,target_cm,plant.label.position])
				var tap_point:=_opaque_hit_point(plant,game.camera,visible_rect);var hit:Dictionary=plant.screen_hit_test(game.camera,tap_point)
				assert(bool(hit.get("hit",false)),"visible giant leaf was not hittable speed=%.1f pos=%s cm=%.0f tap=%s"%[growth_speed,position,target_cm,tap_point])
				game._try_harvest(tap_point);assert(plant.state=="harvested","visible giant leaf did not harvest speed=%.1f pos=%s cm=%.0f"%[growth_speed,position,target_cm])
	# Horizontal scrolling, harvesting and jelly must still control visibility.
	plant.state="growing";plant.growth_speed_multiplier=1.6;plant.fast_forward_to_diameter(1000.0);plant.original_pos=Vector3(0,.12,0);plant.position=plant.original_pos;game._update_labels();assert(plant.label.visible)
	var saved_original_pos:Vector3=plant.original_pos;var saved_position:Vector3=plant.position;plant.original_pos.x+=1000.0;plant.position.x+=1000.0;game._update_labels();assert(not game._plant_is_visible_for_label(plant,viewport_rect) and not plant.label.visible,"fully scrolled-off giant plant kept its label")
	plant.original_pos=saved_original_pos;plant.position=saved_position;game._update_labels();assert(plant.label.visible,"giant label did not return with its plant after horizontal scrolling")
	plant.state="harvested";game._update_labels();assert(not plant.label.visible,"harvested giant plant kept its label");plant.state="jelly";game._update_labels();assert(not plant.label.visible,"jellied giant plant kept its label");plant.state="growing";game._update_labels();assert(plant.label.visible)
	# When two opaque billboards overlap, normalized tap proximity owns the tap;
	# camera depth resolves a tie rather than array order.
	plant.fast_forward_to_diameter(500.0);plant.original_pos=Vector3(0,.12,-1.0);plant.position=plant.original_pos
	game._spawn_specific_plant("colorata");var front_plant=game.plants.back();front_plant.jelly_checks_enabled=false;front_plant.original_pos=Vector3(0,.12,2.5);front_plant.position=front_plant.original_pos;front_plant.fast_forward_to_diameter(100.0)
	if front_plant.harvested.is_connected(harvest_handler):front_plant.harvested.disconnect(harvest_handler)
	var overlap_rect:Rect2=plant.screen_visual_rect(game.camera).intersection(front_plant.screen_visual_rect(game.camera)).intersection(viewport_rect);var overlap_point:=Vector2(-1,-1)
	for row in range(1,10):
		for column in range(1,10):
			var candidate:=overlap_rect.position+Vector2(overlap_rect.size.x*float(column)/10.0,overlap_rect.size.y*float(row)/10.0);var back_hit:Dictionary=plant.screen_hit_test(game.camera,candidate);var front_hit:Dictionary=front_plant.screen_hit_test(game.camera,candidate)
			if bool(back_hit.get("opaque_artwork_hit",false)) and bool(front_hit.get("opaque_artwork_hit",false)):overlap_point=candidate;break
		if overlap_point.x>=0.0:break
	assert(overlap_point.x>=0.0,"overlap regression could not find two visible leaves")
	var giant_overlap_hit:Dictionary=plant.screen_hit_test(game.camera,overlap_point);var normal_overlap_hit:Dictionary=front_plant.screen_hit_test(game.camera,overlap_point)
	var normal_wins:bool=float(normal_overlap_hit.get("score",INF))<float(giant_overlap_hit.get("score",INF)) or (is_equal_approx(float(normal_overlap_hit.get("score",INF)),float(giant_overlap_hit.get("score",INF))) and front_plant.screen_depth(game.camera)<plant.screen_depth(game.camera))
	var expected_selected=front_plant if normal_wins else plant;var expected_unselected=plant if normal_wins else front_plant
	game._try_harvest(overlap_point);assert(expected_selected.state=="harvested" and expected_unselected.state=="growing","overlapping harvest did not select the intended visible leaf")
	game.play_active=false;game._clear_greenhouse_plants()

func _test_giant_harvest_reward(game)->void:
	game._cancel_puku_gauge_animations();game.puku_gauge_animation_speed_scale=.02;game._clear_greenhouse_plants();game.current_mode="greenhouse";game.play_active=true;game.active_seed_type="normal";game.current_target_count=12;game.play_seeds_remaining=0;game.play_spawn_queue=0;game.play_seed_animations_pending=1;game.puku_gauge_intro_complete=true;game.puku_balance_units=0;game.species_get_counts["colorata"]=1;game.bests["colorata"]=0.0
	game._spawn_specific_plant("colorata");var plant=game.plants.back();plant.jelly_checks_enabled=false;plant.original_pos=Vector3(0,.12,0);plant.position=plant.original_pos;plant.fast_forward_to_diameter(709.0);game._update_labels()
	var expected_units:int=game._harvest_puku_reward_units(plant.diameter_cm,false);var visible_rect:Rect2=plant.screen_visual_rect(game.camera).intersection(game.get_viewport().get_visible_rect());var tap_point:=_opaque_hit_point(plant,game.camera,visible_rect)
	game._try_harvest(tap_point);await get_tree().process_frame;await get_tree().process_frame
	assert(game.puku_balance_units==expected_units,"giant screen-tap harvest paid the wrong reward expected=%d actual=%d"%[expected_units,game.puku_balance_units]);assert(is_equal_approx(float(game.bests.get("colorata",0.0)),709.0),"giant screen-tap harvest did not preserve the real-size record")
	game.play_active=false;game.play_seed_animations_pending=0;game._clear_greenhouse_plants();game._cancel_puku_gauge_animations();game.puku_gauge_animation_speed_scale=1.0
	for result_panel in game.effects_layer.find_children("HarvestResult","",true,false):result_panel.free()

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
	assert(not game.play_active and game.result_overlay.visible)
	game._close_result();await get_tree().process_frame
	game._clear_greenhouse_plants();game.species_get_counts.erase("colorata");game.puku_balance_units=0;game.play_active=true;game.active_seed_type="normal";game.play_seeds_remaining=0;game.play_concurrent_target=0;game._reset_endless_economy_stats();game._spawn_specific_plant("colorata");var new_plant=game.plants.back();new_plant.jelly_checks_enabled=false;new_plant.diameter_cm=8.0;new_plant.harvest();await get_tree().process_frame
	assert(game.puku_balance_units==200 and game._species_get_count("colorata")==0 and "colorata" in game.pending_round_new_species_ids)
	game.play_active=false;game._play_result_new_species_animations();await get_tree().create_timer(.62).timeout
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
