extends Node
func _ready()->void:
	_verify_jelly_probability()
	var scene:PackedScene=load("res://main.tscn");var game:Node=scene.instantiate();add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.opening_overlay.visible and game.opening_prompt.size==Vector2(404,136) and game.opening_prompt.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED and game.audio_manager.current_bgm_key=="opening");game._finish_opening();assert(not game.opening_overlay.visible)
	game._reset_progression_state();game.intro_story_complete=true;game.habitat_unlocked=true;game.encyclopedia_unlocked=true;game.buyback_unlocked=true;game.tutorial_steps["habitat_scroll_dialog"]=true;game.tutorial_steps["habitat_get_dialog"]=true;game.tutorial_steps["play1_dialog"]=true;game.intro_overlay.visible=false;game.shop_overlay.visible=false;game._update_play_ui()
	game._prepare_shop_visit(true);assert(game.shop_visit_count==1 and game.armadillo_present and game.armadillo_tap_button.visible);game._on_armadillo_tapped();assert(bool(game.hidden_species_acquired.get("pinwheel",false)) and bool(game.discovered.get("pinwheel",false)));var hidden_count:int=game.hidden_species_acquired.size();game._on_armadillo_tapped();assert(game.hidden_species_acquired.size()==hidden_count);game._hide_shop_chatter(true)
	game.mystery_seed_count=0;game.shop_visit_count=100;game.rng.seed=20260901;var random_armadillo_visits:=0
	for visit in range(25):game._prepare_shop_visit();random_armadillo_visits+=1 if game.armadillo_present else 0
	assert(random_armadillo_visits>0 and random_armadillo_visits<25)
	game.mystery_seed_count=3;game._prepare_shop_visit();assert(game.armadillo_present and game.armadillo_tap_button.visible);game._on_armadillo_tapped();assert(game.armadillo_dialog_mode=="research_offer" and game.shop_chatter_action_button.visible and game.shop_chatter_decline_button.visible);game._decline_armadillo_research();assert(game.mystery_seed_count==3 and game.armadillo_research_total==0);game._on_armadillo_tapped();game._accept_armadillo_research();assert(game.mystery_seed_count==0 and game.armadillo_research_total==3 and game.shop_transfer_notice.text=="渡した謎のたね ×3個")
	game.armadillo_research_total=6;game.armadillo_research_rewards.clear();game.mystery_seed_count=39;var research_bags_before:int=game.normal_seed_bags;game._accept_armadillo_research();assert(game.armadillo_research_total==45 and game.mystery_seed_count==0 and game.normal_seed_bags>=research_bags_before+3)
	for milestone in ["8","13","18","35","40","45"]:assert(bool(game.armadillo_research_rewards.get(milestone,false)))
	assert(not bool(game.armadillo_research_rewards.get("25",false)));assert(bool(game.discovered.get("golden_laui",false)));game._save();game.armadillo_research_total=0;game.armadillo_research_rewards.clear();game._load_save();assert(game.armadillo_research_total==45 and bool(game.armadillo_research_rewards.get("45",false)))
	game.bests.erase("pinwheel");game._open_species_detail(game._catalog_entry("pinwheel"));await get_tree().process_frame;var detail_image:TextureRect=game.encyclopedia_detail_page.find_child("SpeciesImage",true,false);var detail_frame:MarginContainer=game.encyclopedia_detail_page.find_child("SpeciesImageFrame",true,false);var detail_best:Label=game.encyclopedia_detail_page.find_child("SpeciesBest",true,false);assert(detail_image.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED and detail_frame.get_theme_constant("margin_left")==22 and detail_best.text=="自己ベスト　ー");game.bests["pinwheel"]=12.3;game._open_species_detail(game._catalog_entry("pinwheel"));detail_best=game.encyclopedia_detail_page.find_child("SpeciesBest",true,false);assert(detail_best.text=="自己ベスト  12.3 cm");game.bests.erase("pinwheel")
	assert(game.shop_wallet_label.position.y==842.0 and game.shop_premium_buy_button.position==Vector2(296,899) and game.shop_premium_buy_button.size==Vector2(232,55) and game.armadillo_tap_button.position.y+game.armadillo_tap_button.size.y<836.0)
	game.coins=1000;var purchased_bags_before:int=game.normal_seed_bags;game._buy_seed_bag("normal");assert(game.coins==500 and game.normal_seed_bags==purchased_bags_before+1);game.coins=1000
	game.shop_visit_count=7;game._prepare_shop_visit(false);assert(game.shop_visit_count==8 and bool(game.hidden_species_acquired.get("strictiflora_bustamante",false)) and bool(game.discovered.get("strictiflora_bustamante",false)));game._hide_shop_chatter(true)
	game.hidden_species_acquired.erase("tovarensis_tovar");game.discovered.erase("tovarensis_tovar");game.normal_play_count=5;game.tovar_next_play=6;game.tovar_attempt_count=0;game.active_seed_type="normal";game.play_active=true;game._prepare_tovar_event_for_play();assert(game.tovar_event_active and game.tovar_attempt_count==0 and game.plants.filter(func(p):return str(p.data.species_id)=="tovarensis_tovar").size()==3);game._clear_greenhouse_plants();game._resolve_tovar_event_after_play();assert(game.normal_play_count==6 and game.tovar_attempt_count==1 and game.tovar_next_play==8 and not bool(game.discovered.get("tovarensis_tovar",false)))
	game.normal_play_count=7;game._prepare_tovar_event_for_play();assert(game.tovar_event_active and game.tovar_attempt_count==1);game._clear_greenhouse_plants();game._resolve_tovar_event_after_play();assert(game.normal_play_count==8 and game.tovar_attempt_count==2 and game.tovar_next_play==11);game.normal_play_count=10;game._prepare_tovar_event_for_play();var captured_tovar=game.plants.filter(func(p):return str(p.data.species_id)=="tovarensis_tovar")[0];captured_tovar.harvest();assert(game.tovar_harvested_this_play and not bool(game.discovered.get("tovarensis_tovar",false)));game._clear_greenhouse_plants();game._resolve_tovar_event_after_play();assert(game.normal_play_count==11 and game.tovar_attempt_count==3 and game.tovar_next_play==0 and bool(game.discovered.get("tovarensis_tovar",false)) and bool(game.hidden_species_acquired.get("tovarensis_tovar",false)));game.active_seed_type="old";game._resolve_tovar_event_after_play();assert(game.normal_play_count==11);game.play_active=false
	game._show_opening();game._show_opening();var opening_stream:AudioStream=game.audio_manager._stream_for("bgm","opening");var opening_players:=0
	for player in game.audio_manager.bgm_players:opening_players+=1 if player.playing and player.stream==opening_stream else 0
	assert(game.opening_overlay.visible and game.audio_manager.current_bgm_key=="opening" and opening_players<=1 and opening_stream is AudioStreamWAV and opening_stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and game.audio_manager._bgm_target_db("opening")<game.audio_manager._bgm_target_db("greenhouse"));game._finish_opening();assert(not game.opening_overlay.visible)
	assert(game.best_label.get_parent().position==Vector2(204,54))
	assert(game.mode_button.position==Vector2(398,198) and game.mode_button.size==Vector2(153,55));assert(game.shop_button.position==Vector2(398,262) and game.shop_button.size==Vector2(153,55));assert(game.result_confetti_layer.get_parent()==game.result_overlay)
	game._toggle_mode();assert(game.current_mode=="habitat" and game.audio_manager.current_bgm_key=="habitat" and not game.shop_button.visible and not game.habitat_status_label.visible and game.habitat_status_label.text.is_empty());game._start_habitat_scroll_tutorial();assert(game.intro_panda_portrait.visible and game.intro_panda_portrait.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED and game.intro_dialog_panel.position in [Vector2(40,725),Vector2(40,385)]);game.intro_overlay.visible=false;game.tutorial_dialog_kind="";game._toggle_mode();assert(game.current_mode=="greenhouse" and game.audio_manager.current_bgm_key=="greenhouse" and game.shop_button.visible);game._toggle_mode();var habitat_stream:AudioStream=game.audio_manager._stream_for("bgm","habitat");var habitat_players:=0
	for player in game.audio_manager.bgm_players:habitat_players+=1 if player.playing and player.stream==habitat_stream else 0
	assert(game.current_mode=="habitat" and game.audio_manager.current_bgm_key=="habitat" and habitat_players<=1 and habitat_stream is AudioStreamWAV and habitat_stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and game.audio_manager.bgm_players[game.audio_manager.active_bgm].get_playback_position()<1.0);game._toggle_mode();assert(game.current_mode=="greenhouse" and game.audio_manager.current_bgm_key=="greenhouse");game._start_post_play_dialog("play2");assert(not game.intro_panda_portrait.visible);game.intro_overlay.visible=false;game.shop_overlay.visible=false;game.tutorial_dialog_kind="";game._update_play_ui()
	game._open_shop();game._on_shop_panda_tapped();var first_chatter:String=game.shop_chatter_label.text;assert(game.shop_chatter_bubble.visible and is_equal_approx(game.shop_chatter_bubble.position.x+game.shop_chatter_bubble.size.x*.5,288.0) and game.shop_chatter_bubble.position.y==276.0 and game.shop_chatter_bubble.size.y<=118.0 and not game.shop_chatter_action_button.visible);game._on_shop_panda_tapped();assert(game.shop_chatter_label.text!=first_chatter);var dismiss:=InputEventMouseButton.new();dismiss.button_index=MOUSE_BUTTON_LEFT;dismiss.pressed=true;game._on_shop_chatter_gui_input(dismiss);assert(not game.shop_chatter_bubble.visible)
	game.coins=499;game.old_seed_bags=0;game.normal_seed_bags=0;game.premium_seed_bags=0;game._on_shop_panda_tapped();assert(game.shop_chatter_action_button.visible and game.shop_chatter_bubble.position==Vector2(22,86) and "広告" not in game.shop_chatter_label.text);game._on_shop_background_gui_input(dismiss);assert(game.shop_chatter_bubble.visible);game.rescue_reward_in_progress=true;game._on_rescue_reward_ad_completed(false);assert(game.normal_seed_bags==0 and game.shop_chatter_bubble.visible);game._request_rescue_reward_ad();await get_tree().create_timer(.8).timeout;assert(game.normal_seed_bags==1 and not game.rescue_reward_in_progress);game._on_rescue_reward_ad_completed(true);assert(game.normal_seed_bags==1);game._close_shop();game.coins=1000
	assert(game.plants.is_empty() and not game.play_active)
	assert(game.play_open_button.visible and not game.play_overlay.visible)
	game._open_play_modal();assert(game.play_overlay.visible);game._close_play_modal();assert(not game.play_overlay.visible)
	game.normal_seed_bags=maxi(3,game.normal_seed_bags);game._update_play_ui();var bags_before:int=game.normal_seed_bags;game._start_greenhouse_play("normal");assert(game.play_active and game.normal_seed_bags==bags_before-1);assert(game.play_time_remaining==0.0 and game.seed_bag_panel.visible and game.play_timer_label.visible)
	for control in game.external_navigation_controls:assert(not control.visible)
	assert(game.plants.is_empty() and game.play_seed_animations_pending>=9 and game.play_seed_animations_pending<=12);assert(game.play_seeds_remaining==24-game.play_seed_animations_pending);assert(game.play_timer_label.text=="● たね袋 ●\n残り %d粒"%game.play_seeds_remaining);await get_tree().create_timer(.45).timeout
	assert(game.plants.size()>=9 and game.plants.size()<=12 and game.play_seed_animations_pending==0);assert(game.play_seeds_remaining==24-game.plants.size())
	assert(game.catalog_species.size()==13)
	assert(game.harvest_reward_yen(9.9)==0 and game.harvest_reward_yen(10.0)==10 and game.harvest_reward_yen(99.9)==1000 and game.harvest_reward_yen(150.0)==4000)
	var species_ids:Array=[]
	for entry in game.catalog_species:species_ids.append(str(entry.species_id))
	for required in ["laui","golden_laui","colorata","affinis","lutea","shaviana","kannte","pinwheel","tovarensis_tovar","strictiflora_bustamante"]:assert(required in species_ids)
	var succulent_assets = load("res://scripts/succulent.gd")
	assert(succulent_assets.SPRITES.pinwheel=="res://assets/plants/sprite-pinwheel.png" and ResourceLoader.exists(succulent_assets.SPRITES.pinwheel))
	var pinwheel_bitmap:Image=(load(succulent_assets.SPRITES.pinwheel) as Texture2D).get_image();var pinwheel_used:=pinwheel_bitmap.get_used_rect();assert(pinwheel_used.position.x>0 and pinwheel_used.position.y>0 and pinwheel_used.end.x<pinwheel_bitmap.get_width() and pinwheel_used.end.y<pinwheel_bitmap.get_height())
	var opening_ids:Array=[]
	for plant in game.plants:opening_ids.append(str(plant.data.species_id))
	for spawned_id in opening_ids:assert(spawned_id in species_ids and spawned_id=="colorata")
	for plant in game.plants:
		plant.jelly_checks_enabled=false
		assert(plant.growth_rhythm_period >= 16.0 and plant.growth_rhythm_period <= 28.0)
		assert(is_equal_approx(plant._integrated_growth_multiplier(0.0,plant.growth_rhythm_period),plant.growth_rhythm_period))
		var diameter_before:float=plant.diameter_cm
		plant.simulate(0.01)
		assert(plant.diameter_cm>diameter_before)
	var unique_positions:Dictionary={}
	for plant in game.plants:
		unique_positions["%.2f,%.2f"%[plant.original_pos.x,plant.original_pos.z]]=true
		assert(game._spawn_center_inside_soil(plant.original_pos))
	assert(unique_positions.size()>=game.plants.size()-1)
	var initial_count:int=game.plants.size()
	var harvest_target=game.plants[0]
	harvest_target.jelly_checks_enabled=false
	var rooted_position:Vector3=harvest_target.position
	var initial_sprite_scale:float=harvest_target.plant_sprite.scale.x
	for i in range(700): harvest_target.simulate(.1)
	assert(harvest_target.plant_sprite.scale.x>initial_sprite_scale)
	assert(harvest_target.diameter_cm>70.0)
	assert(harvest_target.position.is_equal_approx(rooted_position))
	assert(harvest_target.scale.is_equal_approx(Vector3.ONE))
	assert(harvest_target.plant_sprite.texture!=null)
	var grown_scale:float=harvest_target.plant_sprite.scale.x
	var grown_diameter:float=harvest_target.diameter_cm
	assert(game.current_mode=="greenhouse" and not game.pot_root.visible)
	game._toggle_mode();assert(game.current_mode=="habitat" and not game.pot_root.visible)
	game.view_yaw=0.0;game._apply_view_rotation();var first_basis:Basis=game.camera.transform.basis
	game.view_yaw=360.0;game._apply_view_rotation();assert(game.camera.transform.basis.is_equal_approx(first_basis))
	game.view_yaw=0.0;game.view_pitch=-3.0;var count_before_drag:int=game.plants.size();var yaw_before:float=game.view_yaw;var pitch_before:float=game.view_pitch;var paused_age:float=game.plants[0].age;game._begin_pointer(Vector2(300,500));game._drag_pointer(Vector2(380,560),Vector2(80,60));assert(game.habitat_target_yaw>yaw_before and game.habitat_target_pitch>pitch_before);game._update_habitat_view_follow(.5);game._end_pointer(Vector2(380,560));assert(game.plants.size()==count_before_drag);assert(game.view_yaw>yaw_before and game.view_pitch>pitch_before);game._process(.2);assert(is_equal_approx(game.plants[0].age,paused_age));assert(game.habitat_pickups.size()>=10)
	game._toggle_mode();assert(game.current_mode=="greenhouse")
	var pan_target=game.plants[0];var pan_screen_before:Vector2=game.camera.unproject_position(pan_target.global_position);var backdrop_y:float=game.greenhouse_backdrop.position.y
	game._begin_pointer(Vector2(280,500));game._drag_pointer(Vector2(282,500),Vector2(2,0));assert(is_equal_approx(game.greenhouse_pan_target_x,game.greenhouse_pan_x));game._drag_pointer(Vector2(380,500),Vector2(98,0));assert(game.greenhouse_pan_target_x>game.greenhouse_pan_x);game._update_greenhouse_pan_follow(.5);game._resolve_crowding(0.0);game._end_pointer(Vector2(380,500));var pan_screen_after:Vector2=game.camera.unproject_position(pan_target.global_position)
	assert(game.greenhouse_pan_x>0.0 and game.greenhouse_pan_x<=game.greenhouse_pan_limit);assert(game.greenhouse_pan_limit<80.0);assert(pan_screen_after.x>pan_screen_before.x);assert(is_equal_approx(game.greenhouse_backdrop.position.y,backdrop_y))
	game.greenhouse_pan_x=0.0;game._update_greenhouse_pan();game._resolve_crowding(0.0)
	for plant in game.plants:assert(game._spawn_center_inside_soil(plant.original_pos))
	var species_id:String=harvest_target.data.species_id;harvest_target.diameter_cm=21.7;harvest_target.harvest()
	await get_tree().create_timer(1.2).timeout
	assert(float(game.bests.get(species_id,0.0))>=21.7)
	assert(bool(game.discovered.get(species_id,false)))
	game._open_encyclopedia();await get_tree().process_frame;assert(game.encyclopedia_overlay.visible);assert(game.encyclopedia_grid.get_child_count()==game.catalog_species.size());assert(game.encyclopedia_scroll.vertical_scroll_mode==ScrollContainer.SCROLL_MODE_AUTO and game.encyclopedia_scroll.get_v_scroll_bar().max_value>game.encyclopedia_scroll.size.y and game.encyclopedia_grid.mouse_filter==Control.MOUSE_FILTER_PASS and game.encyclopedia_grid.get_parent().get_child(1).custom_minimum_size.y==54.0);var pinwheel_card_index:=-1
	for catalog_index in range(game.catalog_species.size()):
		if str(game.catalog_species[catalog_index].species_id)=="pinwheel":pinwheel_card_index=catalog_index;break
	var pinwheel_card:Button=game.encyclopedia_grid.get_child(pinwheel_card_index);var pinwheel_card_frame:MarginContainer=pinwheel_card.find_child("SpeciesCardImageFrame",true,false);assert(pinwheel_card.mouse_filter==Control.MOUSE_FILTER_PASS and pinwheel_card.action_mode==BaseButton.ACTION_MODE_BUTTON_RELEASE and pinwheel_card.pressed.get_connections().size()>0 and pinwheel_card_frame.get_theme_constant("margin_left")==10 and pinwheel_card_frame.get_theme_constant("margin_right")==10);game.encyclopedia_scroll.scroll_vertical=int(game.encyclopedia_scroll.get_v_scroll_bar().max_value);assert(game.encyclopedia_scroll.scroll_vertical>0);pinwheel_card.pressed.emit();assert(game.encyclopedia_detail_page.visible);var list_back:Button=game.encyclopedia_detail_page.get_child(0);assert(list_back.text=="一覧へ");list_back.pressed.emit();assert(game.encyclopedia_list_page.visible and not game.encyclopedia_detail_page.visible);game._close_encyclopedia()
	assert(game.play_active and game.play_seeds_remaining<24-initial_count)
	for plant in game.plants:plant.jelly_checks_enabled=false
	var jelly_target=game.plants[0]
	jelly_target.jelly()
	assert(jelly_target.state=="jelly")
	await get_tree().create_timer(1.2).timeout
	assert(game.play_active)
	var drain_guard:=0
	while game.play_active and drain_guard<100:
		for plant in game.plants.duplicate():plant.harvest()
		game._process(1.0);await get_tree().process_frame;drain_guard+=1
	assert(game.plants.is_empty() and not game.play_active);assert(game.result_overlay.visible);assert(game.play_harvest_count>=1 and game.play_earnings_total>=50 and game.play_max_size>=21.7);assert(game.play_updated_global_best and "最大サイズ更新" in game.result_max_label.text and game.result_confetti_layer.get_child_count()>0);assert(not game.play_open_button.visible);game._close_result();assert(game.play_open_button.visible)
	for control in game.external_navigation_controls:assert(control.visible)
	print("SMOKE_OK panorama360 plants=",game.plants.size()," diameter=",grown_diameter," sprite_scale=",grown_scale," rooted=true species=",species_id)
	get_tree().quit()

func _verify_jelly_probability()->void:
	var succulent_script = load("res://scripts/succulent.gd")
	for profile in [[3.8,8.3],[4.7,15.0],[5.4,24.0],[6.2,42.0]]:
		var safe_end:float=profile[0];var ramp_end:float=profile[1];var midpoint:float=(safe_end+ramp_end)*.5
		assert(is_zero_approx(succulent_script.jelly_chance_per_second(0.0,safe_end,ramp_end)))
		assert(is_zero_approx(succulent_script.jelly_chance_per_second(safe_end,safe_end,ramp_end)))
		assert(succulent_script.jelly_chance_per_second(midpoint,safe_end,ramp_end)>0.0 and succulent_script.jelly_chance_per_second(midpoint,safe_end,ramp_end)<0.06)
		assert(absf(succulent_script.jelly_chance_per_second(ramp_end,safe_end,ramp_end)-0.06)<0.000001)
		assert(is_zero_approx(succulent_script.jelly_probability_for_interval(0.0,safe_end,safe_end,ramp_end)))
		var reference_probability = succulent_script.jelly_probability_for_interval(0.0,50.0,safe_end,ramp_end)
		for fps in [30,60,120]:
			var delta := 1.0/float(fps);var survival:=1.0
			for frame in range(50*fps):survival*=1.0-succulent_script.jelly_probability_for_interval(frame*delta,delta,safe_end,ramp_end)
			assert(is_equal_approx(1.0-survival,reference_probability))
