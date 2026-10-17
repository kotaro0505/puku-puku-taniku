extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.pot_design_unlocks={};game.story_progression_state["arrangement_unlocked"]=true;game.story_progression_state["arrangement_intro_seen"]=true;game.intro_story_complete=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.habitat_awakened=true;game.habitat_awakening_event_complete=true;game.habitat_tutorial_complete=true;game.seed_shop_open=true;game.panda_beacon_unlocked=true;game.puku_gauge_intro_complete=true;game.total_play_count=3;game.formal_play_count=3
	game.discovered={"colorata":true,"laui":false};game.species_get_counts={"colorata":4};game.bests={"colorata":11.1};game.puku_points=12;game._sync_arrangement_ui();game._update_play_ui()
	var ui=game.arrangement_ui
	var localizer=load("res://scripts/game_localizer.gd")
	assert(game.arrangement_save_capacity==50 and ui.save_capacity==50 and ui.MAX_PLANTS_PER_ARRANGEMENT==24)
	for locale in ["ja","hiragana","en"]:
		for key in ["pot_available_count","pot_all_in_use","pot_save_unavailable","pot_owned_total","pot_bought_count","pot_purchase_success","pot_purchase_owned_before","pot_purchase_owned_after","pot_locked_puku_price","arrangement_dismantle","arrangement_dismantle_confirm","arrangement_dismantle_confirm_button","arrangement_dismantle_cancel","arrangement_choose_pot_hint","arrangement_view_saved","arrangement_saved_title","arrangement_save_limit_help","arrangement_no_available_pots","share_action","share_editor_title","share_confirm_action","share_creating","share_failed","share_opening","share_background","share_background_greenhouse","share_background_puku_members","share_background_jurejure_gang","share_background_all_characters","share_background_selected","share_background_available_from_start","share_background_unlock_exploitation","share_background_unlock_story_clear","share_background_unlock_collection_complete"]:assert(localizer.text(locale,key)!=key)
	assert(localizer.text("ja","arrangement_no_available_pots")=="使用できる鉢がありません。おみせで鉢を購入するか、寄せ植えを解体してください。")
	assert(localizer.text("ja","pot_purchase_success",["黒陶器鉢"])=="黒陶器鉢を購入しました！" and "購入できた" not in localizer.text("ja","pot_purchase_success",["黒陶器鉢"]))
	assert(localizer.text("hiragana","pot_purchase_success",["くろとうきばち"])=="くろとうきばちを\nこうにゅうしました！" and localizer.text("en","pot_purchase_success",["Black Ceramic Pot"])=="Purchased Black Ceramic Pot!")
	var share_backgrounds=load("res://scripts/arrangement_share_backgrounds.gd");var share_catalog:Array=share_backgrounds.catalog();assert(share_catalog.size()==4)
	var share_ids:Array=[]
	for background_value in share_catalog:
		var background:Dictionary=background_value;share_ids.append(str(background.id));assert(ResourceLoader.exists(str(background.texture_path)) and background.has("name_key") and background.has("unlock_condition") and background.has("crop_mode") and background.get("focus") is Vector2 and background.get("artwork_rect") is Rect2)
	assert(share_ids==["greenhouse","puku_members","jurejure_gang","all_characters"] and not share_ids.has("collection_complete"))
	assert(str(share_catalog[0].texture_path)=="res://assets/greenhouse-master-horizontal.png" and str(share_catalog[0].crop_mode)=="cover")
	for background in share_catalog.slice(1):
		var background_image:Image=(load(str(background.texture_path)) as Texture2D).get_image();assert(background_image.get_size()==Vector2i(720,1280) and str(background.crop_mode)=="native_9_16")
	var initial_share_unlocks:Dictionary=game._share_background_unlock_states();assert(bool(initial_share_unlocks.greenhouse) and bool(initial_share_unlocks.puku_members) and not bool(initial_share_unlocks.jurejure_gang) and not bool(initial_share_unlocks.all_characters))
	assert(game.pot_catalog.size()==44 and int(game.owned_pots.get("shallow_terracotta",0))==1 and typeof(game.owned_pots.get("shallow_terracotta"))==TYPE_INT)
	for pot_value in game.pot_catalog:
		for required_key in ["pot_id","display_name","image_path","price_puku","sales_group","sales_stage","unlock_type","unlock_condition","iap_product_id","placement_area","sort_order"]:assert(pot_value.has(required_key))
		assert(int(pot_value.price_puku)>=1)
	assert(str(game.pot_catalog[16].pot_id)=="g1_rock_bowl" and int(game.pot_catalog[16].price_puku)==2)
	assert(str(game.pot_catalog[17].pot_id)=="g1_rose_gold_glass" and int(game.pot_catalog[17].price_puku)==3)
	assert(str(game.pot_catalog[18].pot_id)=="g1_gold_jackpot" and int(game.pot_catalog[18].price_puku)==30)
	assert(str(game.pot_catalog[22].pot_id)=="g2_shell_coral" and int(game.pot_catalog[22].price_puku)==5)
	assert(str(game.pot_catalog[31].pot_id)=="g2_neon_crystal" and int(game.pot_catalog[31].price_puku)==10)
	assert(str(game.pot_catalog[43].pot_id)=="g2_ramen_bowl" and int(game.pot_catalog[43].price_puku)==100)
	for source_path in ["res://scripts/arrangement_ui.gd","res://scripts/game_localizer.gd"]:
		var source_text:=FileAccess.get_file_as_string(source_path);assert(not "all_pots_one_puku" in source_text)
	assert(game._current_pot_sales_stage()==0 and not game._pot_unlocked({"sales_stage":1,"unlock_condition":{"type":"default"}}))
	game.forest_gacha_unlocked=true;assert(game._current_pot_sales_stage()==1 and game._pot_unlocked({"sales_stage":1,"unlock_condition":{"type":"default"}}));game.forest_gacha_unlocked=false
	game.act3_unlocked=true;assert(game._current_pot_sales_stage()==2 and game._pot_unlocked({"sales_stage":2,"unlock_condition":{"type":"default"}}));game.act3_unlocked=false
	for added_pot_id in ["shallow_terracotta","classic_terracotta","black_ceramic","white_ceramic","clear_crystal","amethyst_crystal","glass_bowl","tin_bucket"]:
		var added_pot:Dictionary=game._pot_entry(added_pot_id);assert(not added_pot.is_empty() and ResourceLoader.exists(str(added_pot.image_path)))
		var pot_image:Image=(load(str(added_pot.image_path)) as Texture2D).get_image();assert(pot_image.get_pixel(0,0).a<.05 and pot_image.get_pixel(pot_image.get_width()-1,pot_image.get_height()-1).a<.05)
	assert(game.arrangement_button == null)
	var available:Array=ui._available_species_entries("all");assert(available.size()==1 and str(available[0].species_id)=="colorata")
	game.discovered["gummy_peach_milk"]=true;game.discovered["hyb_gummy_metal"]=true;game._sync_arrangement_ui()
	ui._refresh_picker_filters(true)
	var gummy_filter_index:=-1
	for item_index in range(ui.picker_filter.item_count):
		if str(ui.picker_filter.get_item_metadata(item_index))=="gummy":gummy_filter_index=item_index
	assert(ui.picker_filter.item_count==3 and gummy_filter_index>0)
	ui.picker_filter.select(gummy_filter_index);ui._on_picker_filter_changed(gummy_filter_index)
	var gummy_entries:Array=ui._available_species_entries("gummy");assert(gummy_entries.size()==2 and gummy_entries.all(func(entry:Dictionary)->bool:return str(entry.get("species_id","")) in ["gummy_peach_milk","hyb_gummy_metal"]))
	assert(ui.picker_grid.get_child_count()==2)
	for card_value in ui.picker_grid.get_children():
		var card:=card_value as Button;assert(card!=null and card.find_child("SpeciesImage",true,false)!=null and card.find_child("SpeciesName",true,false)!=null and card.find_child("SpeciesName",true,false).text.count("\n")==0 and not _has_label_text_containing(card,"記録"))
	game.discovered.erase("gummy_peach_milk");game.discovered.erase("hyb_gummy_metal");game._sync_arrangement_ui()
	ui.open_home();assert(ui.home_page.visible and ui.pot_select_grid.get_child_count()==1 and not (ui.pot_select_grid.get_child(0) as Button).disabled and _has_label_text_containing(ui.pot_select_grid.get_child(0),"使用可能 ×1"))
	assert(_has_label_text_containing(ui.pot_select_grid,"浅型素焼き鉢") and not _has_label_text_containing(ui.pot_select_grid,"未所持") and not _has_label_text_containing(ui.pot_select_grid,"デザイン未アンロック"))
	assert(_has_label_text_containing(ui.home_page,"好きな鉢を選んで作ってみよう") and _has_button_text(ui.home_page,"作った作品を見る") and not _has_button_text(ui.home_page,"＋ 新しく作る"))
	ui._select_editor_pot("shallow_terracotta");assert(ui.editor_page.visible and str(ui.current_arrangement.pot_id)=="shallow_terracotta" and ui.editor_message.text.is_empty())
	assert(not _has_button_text(ui.editor_page,"共有背景") and not _has_button_text(ui.editor_page,"共有") and not ui.share_background_panel.visible)
	assert(not _has_label_text_containing(ui.editor_page,"タップで選択・ドラッグで移動"))
	assert(game._pot_available_count("shallow_terracotta")==1 and ui._pot_available_count("shallow_terracotta")==1)
	assert(not _has_button_text(ui.editor_page,"鉢を変更") and not ui.has_method("_change_editor_pot"))
	ui._add_species_to_editor("laui");assert(ui.editor_plants.is_empty())
	ui._add_species_to_editor("colorata");assert(ui.editor_plants.size()==1 and ui.selected_plant_index==0)
	assert(ui._placement_rect({},ui.editor_canvas.size)==Rect2(Vector2.ZERO,ui.editor_canvas.size) and ui.editor_pot_layer.get_child_count()==1 and ui.editor_plant_layer.z_index==ui.PLANT_LAYER_Z)
	assert(ui.editor_plant_layer.find_child("SelectionBorder",true,false)==null and ui.editor_plant_layer.find_child("SelectionMark",true,false)==null and ui.editor_selection_label.text.is_empty())
	var selected_image:TextureRect=ui.editor_plant_nodes[0].get_node("PlantImage");assert(selected_image.material is ShaderMaterial and is_equal_approx(float((selected_image.material as ShaderMaterial).get_shader_parameter("selected")),1.0))
	var original_position:=Vector2(float(ui.editor_plants[0].x),float(ui.editor_plants[0].y))
	var down:=_mouse_button(original_position,true);ui._on_editor_canvas_gui_input(down)
	var drag:=_mouse_motion(original_position+Vector2(38,24));ui._on_editor_canvas_gui_input(drag)
	var up:=_mouse_button(drag.position,false);ui._on_editor_canvas_gui_input(up)
	var moved_position:=Vector2(float(ui.editor_plants[0].x),float(ui.editor_plants[0].y));assert(moved_position.distance_to(original_position)>10.0 and not ui.drag_active and ui.selected_plant_index==0)
	# No long press is needed: pressing the real plant selects it and dragging moves it immediately.
	var direct_down:=_mouse_button(moved_position,true);ui._on_editor_canvas_gui_input(direct_down);assert(ui.drag_active and ui.selected_plant_index==0)
	ui._on_editor_canvas_gui_input(_mouse_motion(moved_position+Vector2(-31,19)));ui._on_editor_canvas_gui_input(_mouse_button(moved_position+Vector2(-31,19),false));var direct_move_position:=Vector2(float(ui.editor_plants[0].x),float(ui.editor_plants[0].y));assert(direct_move_position.distance_to(moved_position)>10.0 and not ui.drag_active)
	# A two-finger gesture started on empty canvas space scales and rotates the
	# currently selected plant at the same time.
	var pinch_origin:=Vector2(30,40);_send_editor_touch(ui,_screen_touch(0,pinch_origin,true))
	_send_editor_touch(ui,_screen_touch(1,pinch_origin+Vector2(30,0),true));assert(ui.pinch_active and ui.selected_plant_index==0)
	_send_editor_touch(ui,_screen_drag(1,pinch_origin+Vector2(41.1,0)));assert(is_equal_approx(float(ui.editor_plants[0].scale),1.37) and is_equal_approx(float(ui.editor_plants[0].rotation),0.0))
	_send_editor_touch(ui,_screen_drag(1,pinch_origin+Vector2(0,41.1)));assert(is_equal_approx(float(ui.editor_plants[0].scale),1.37) and is_equal_approx(float(ui.editor_plants[0].rotation),90.0))
	_send_editor_touch(ui,_screen_touch(1,pinch_origin+Vector2(0,41.1),false));_send_editor_touch(ui,_screen_touch(0,pinch_origin,false));assert(not ui.pinch_active and is_equal_approx(float(ui.editor_plants[0].scale),1.37) and is_equal_approx(float(ui.editor_plants[0].rotation),90.0))
	# A Control-level delivery path is also accepted when a mobile port bypasses
	# viewport _input for one of the fingers.
	ui._on_editor_canvas_gui_input(_screen_touch(4,pinch_origin,true));ui._on_editor_canvas_gui_input(_screen_touch(5,pinch_origin+Vector2(40,0),true));assert(ui.pinch_active)
	ui._on_editor_canvas_gui_input(_screen_drag(5,pinch_origin+Vector2(0,60)));assert(float(ui.editor_plants[0].scale)>1.9 and absf(float(ui.editor_plants[0].rotation)-180.0)<.1)
	ui._on_editor_canvas_gui_input(_screen_touch(5,pinch_origin+Vector2(0,60),false));ui._on_editor_canvas_gui_input(_screen_touch(4,pinch_origin,false));assert(not ui.pinch_active)
	# The Web DOM fallback consumes complete touch snapshots and suppresses the
	# mirrored Godot events, applying scale and rotation only once.
	ui._handle_web_multitouch_snapshot({21:pinch_origin,22:pinch_origin+Vector2(50,0)});assert(ui.web_multitouch_active and ui.web_multitouch_suppress_native and ui.pinch_active)
	var web_start_scale:=float(ui.editor_plants[0].scale)
	ui._handle_web_multitouch_snapshot({21:pinch_origin,22:pinch_origin+Vector2(0,75)});assert(is_equal_approx(float(ui.editor_plants[0].scale),web_start_scale*1.5) and absf(float(ui.editor_plants[0].rotation)-270.0)<.1)
	ui._handle_web_multitouch_snapshot({21:pinch_origin});ui._handle_web_multitouch_snapshot({});assert(not ui.web_multitouch_active and ui.web_multitouch_suppress_native and not ui.pinch_active)
	# Suppression intentionally survives the mirrored native touchend and is
	# released when the next Web touchstart begins.
	ui._reset_web_multitouch_state();assert(not ui.web_multitouch_suppress_native)
	# Browser canvases include the black pillar/letterbox region. Equal physical
	# X/Y finger travel must remain equal after mapping into the game viewport.
	var mapped_origin:Vector2=ui._web_touch_viewport_position(Vector2(590,390),Vector2.ZERO,Vector2(1262,624),Vector2(576,1024))
	var mapped_x:Vector2=ui._web_touch_viewport_position(Vector2(660,390),Vector2.ZERO,Vector2(1262,624),Vector2(576,1024))
	var mapped_y:Vector2=ui._web_touch_viewport_position(Vector2(590,460),Vector2.ZERO,Vector2(1262,624),Vector2(576,1024))
	assert(is_equal_approx(mapped_origin.distance_to(mapped_x),mapped_origin.distance_to(mapped_y)))
	var tracked_before:int=ui.touch_positions.size();_send_editor_touch(ui,_screen_touch(3,Vector2(-12,-12),true));assert(ui.touch_positions.size()==tracked_before)
	var rotation_before_buttons:=float(ui.editor_plants[0].rotation)
	for rotation_step in range(18):ui._adjust_selected_rotation(15.0)
	assert(is_equal_approx(float(ui.editor_plants[0].rotation),fposmod(rotation_before_buttons+270.0,360.0)))
	ui._add_species_to_editor("colorata");assert(ui.editor_plants.size()==2)
	# Empty space only clears the selection; it never jumps a plant to the tap position.
	var second_position:=Vector2(float(ui.editor_plants[1].x),float(ui.editor_plants[1].y))
	ui._on_editor_canvas_gui_input(_mouse_button(second_position,true));ui._on_editor_canvas_gui_input(_mouse_button(second_position,false));assert(ui.selected_plant_index==1)
	var tap_position:=Vector2(72,88);ui._on_editor_canvas_gui_input(_mouse_button(tap_position,true));ui._on_editor_canvas_gui_input(_mouse_button(tap_position,false))
	assert(Vector2(float(ui.editor_plants[1].x),float(ui.editor_plants[1].y)).is_equal_approx(second_position) and ui.selected_plant_index==-1)
	ui._select_plant(0);ui._change_selected_depth(1);assert(int(ui.editor_plants[0].z_index)>int(ui.editor_plants[1].z_index));ui._change_selected_depth(-1);assert(int(ui.editor_plants[0].z_index)<int(ui.editor_plants[1].z_index))
	assert(ui.editor_plant_layer.z_index+int(ui.editor_plants[0].z_index)>ui.editor_pot_layer.z_index and ui.editor_plant_layer.z_index+int(ui.editor_plants[1].z_index)>ui.editor_pot_layer.z_index)
	ui._select_plant(1);ui._delete_selected_plant();assert(ui.editor_plants.size()==1)
	ui._add_species_to_editor("colorata");ui._select_plant(0);ui._change_selected_depth(1);assert(ui.editor_plants.size()==2 and int(ui.editor_plants[0].z_index)>int(ui.editor_plants[1].z_index))
	var large_plant:Dictionary=ui.editor_plants[0];large_plant["scale"]=2.35;large_plant["rotation"]=123.0;large_plant["x"]=214.0;large_plant["y"]=268.0;ui.editor_plants[0]=large_plant;ui._apply_plant_transform(0)
	var rear_plant:Dictionary=ui.editor_plants[1];rear_plant["scale"]=.78;rear_plant["rotation"]=27.0;rear_plant["x"]=356.0;rear_plant["y"]=310.0;ui.editor_plants[1]=rear_plant;ui._apply_plant_transform(1)
	var get_before:Dictionary=game.species_get_counts.duplicate(true);var best_before:Dictionary=game.bests.duplicate(true);var discovered_before:Dictionary=game.discovered.duplicate(true)
	var edit_snapshots:Array=[];var editor_pot:Control=ui.editor_pot_layer.get_child(0);var edit_pot_position:=editor_pot.position
	assert(editor_pot.size.is_equal_approx(ui.POT_HOLDER_SIZE) and is_equal_approx(editor_pot.position.y+editor_pot.size.y,ui.POT_LOCAL_BASELINE_Y))
	assert(editor_pot.size.x>=432.0*1.19 and editor_pot.size.x<=432.0*1.25)
	for editor_node in ui.editor_plant_nodes:edit_snapshots.append({"position":editor_node.position,"scale":editor_node.scale,"rotation":editor_node.rotation_degrees,"z":editor_node.z_index})
	ui.editor_name.text="春の寄せ植え";ui._save_current_arrangement();assert(game.saved_arrangements.size()==1 and game._owned_pot_total("shallow_terracotta")==1 and game._pot_usage_count("shallow_terracotta")==1 and game._pot_available_count("shallow_terracotta")==0 and ui.editor_page.visible and ui.completion_overlay.visible and ui.completion_label.text=="寄せ植え完成！" and ui.completion_confetti_layer.get_child_count()==40)
	await get_tree().create_timer(ui.COMPLETION_DISPLAY_SECONDS+.08).timeout
	assert(ui.viewer_page.visible and not ui.share_editor_page.visible and ui.viewer_plant_layer.get_child_count()==2 and ui.viewer_plant_layer.find_child("SelectionBorder",true,false)==null and not ui.completion_overlay.visible)
	assert(ui.is_viewer_active() and not ui.is_share_editor_active() and ui.viewer_pot_layer.get_parent()==ui.viewer_artwork_root and ui.viewer_plant_layer.get_parent()==ui.viewer_artwork_root and ui.viewer_artwork_root.get_parent()==ui.viewer_artwork_canvas and ui.viewer_artwork_root.position.is_zero_approx() and ui.viewer_artwork_root.scale.is_equal_approx(Vector2.ONE))
	assert(ui.viewer_canvas.position==ui.ARRANGEMENT_CANVAS_POSITION and ui.viewer_canvas.size.is_equal_approx(ui.ShareRendererClass.VIEWER_CANVAS_SIZE) and not ui.viewer_canvas.clip_contents and ui.viewer_canvas.get_theme_stylebox("panel") is StyleBoxEmpty)
	assert(ui.viewer_canvas.find_children("*","Sprite2D",true,false).is_empty() and ui.last_share_preview_debug.is_empty())
	assert(_has_button_text(ui.viewer_page,"共有") and not _has_button_text(ui.viewer_page,"共有背景") and str(game.saved_arrangements[0].share_background_id)=="greenhouse")
	assert(ui.viewer_share_button.get_parent()==ui.viewer_page and ui.viewer_share_background_button.get_parent()==ui.share_editor_page and ui.viewer_share_button.position==Vector2(154,790) and ui.viewer_share_button.size==Vector2(268,58) and ui.viewer_share_button.position.x==ui.viewer_dismantle_button.position.x and ui.viewer_share_button.size==ui.viewer_dismantle_button.size and ui.viewer_dismantle_button.position.y>ui.viewer_share_button.position.y)
	var share_pot_usage_before:int=int(game._pot_usage_count("shallow_terracotta"));var share_available_before:int=int(game._pot_available_count("shallow_terracotta"));var share_plants_before:=JSON.stringify(game.saved_arrangements[0].plants);var share_created_at_before:=str(game.saved_arrangements[0].created_at);assert(not game.saved_arrangements[0].has("viewer_transform"))
	var viewed_pot:Control=ui.viewer_pot_layer.get_child(0);assert(viewed_pot.position.is_equal_approx(edit_pot_position) and viewed_pot.size.is_equal_approx(editor_pot.size))
	for index in range(ui.viewer_plant_layer.get_child_count()):
		var viewed_plant:Control=ui.viewer_plant_layer.get_child(index);var edit_snapshot:Dictionary=edit_snapshots[index]
		assert(viewed_plant.position.is_equal_approx(edit_snapshot.position) and viewed_plant.scale.is_equal_approx(edit_snapshot.scale) and is_equal_approx(viewed_plant.rotation_degrees,float(edit_snapshot.rotation)) and viewed_plant.z_index==int(edit_snapshot.z))
	assert(ui.viewer_plant_layer.z_index==ui.PLANT_LAYER_Z and ui.viewer_dismantle_button.z_index>ui.viewer_canvas.z_index)
	assert(game.species_get_counts==get_before and game.bests==best_before and game.discovered==discovered_before)
	var pot_global_before:=viewed_pot.get_global_transform_with_canvas().origin;var plant_global_before:=(ui.viewer_plant_layer.get_child(0) as Control).get_global_transform_with_canvas().origin
	var expected_source_drag:=Vector2(42,36)
	ui._on_viewer_canvas_gui_input(_mouse_button(Vector2(220,280),true));ui._on_viewer_canvas_gui_input(_mouse_motion(Vector2(262,316)))
	# Viewer framing is transient and is never added to the saved arrangement.
	assert(not game.saved_arrangements[0].has("viewer_transform"))
	ui._on_viewer_canvas_gui_input(_mouse_button(Vector2(262,316),false))
	assert(ui.viewer_artwork_root.position.is_equal_approx(expected_source_drag))
	var pot_drag_delta:=viewed_pot.get_global_transform_with_canvas().origin-pot_global_before;var plant_drag_delta:=(ui.viewer_plant_layer.get_child(0) as Control).get_global_transform_with_canvas().origin-plant_global_before
	assert(pot_drag_delta.is_equal_approx(Vector2(42,36)) and plant_drag_delta.is_equal_approx(pot_drag_delta))
	var plant_local_scale_before:=(ui.viewer_plant_layer.get_child(0) as Control).scale
	_send_viewer_touch(ui,_screen_touch(10,Vector2(170,270),true));_send_viewer_touch(ui,_screen_touch(11,Vector2(350,270),true));_send_viewer_touch(ui,_screen_drag(11,Vector2(440,270)))
	assert(ui.viewer_artwork_root.scale.x>1.0 and ui.viewer_artwork_root.scale.x<=ui.VIEWER_SCALE_MAX and is_zero_approx(ui.viewer_artwork_root.rotation) and (ui.viewer_plant_layer.get_child(0) as Control).scale.is_equal_approx(plant_local_scale_before))
	_send_viewer_touch(ui,_screen_touch(11,Vector2(440,270),false));_send_viewer_touch(ui,_screen_touch(10,Vector2(170,270),false))
	# The iPhone/Web capture-phase bridge receives complete two-finger snapshots.
	# It scales the same share artwork once and suppresses mirrored native events.
	ui._restore_viewer_transform();ui._handle_viewer_web_multitouch_snapshot({31:Vector2(170,270),32:Vector2(350,270)});assert(ui.viewer_web_multitouch_active and ui.viewer_web_multitouch_suppress_native and ui.viewer_pinch_active)
	var web_viewer_start_scale:float=ui.viewer_artwork_root.scale.x;ui._handle_viewer_web_multitouch_snapshot({31:Vector2(125,270),32:Vector2(395,270)});assert(is_equal_approx(ui.viewer_artwork_root.scale.x,web_viewer_start_scale*1.5))
	ui._handle_viewer_web_multitouch_snapshot({31:Vector2(125,270)});ui._handle_viewer_web_multitouch_snapshot({});assert(not ui.viewer_web_multitouch_active and ui.viewer_web_multitouch_suppress_native and not ui.viewer_pinch_active)
	ui._reset_viewer_web_multitouch_state(false);assert(not ui.viewer_web_multitouch_suppress_native)
	var transient_viewer_transform:Dictionary=ui._viewer_transform_state();assert(float(transient_viewer_transform.scale)>1.0 and not game.saved_arrangements[0].has("viewer_transform"))
	ui._set_viewer_artwork_transform(Vector2(100000,100000),99.0,false);assert(is_equal_approx(ui.viewer_artwork_root.scale.x,ui.VIEWER_SCALE_MAX) and ui.viewer_artwork_root.position.x<=ui.viewer_canvas.size.x-ui.VIEWER_MIN_VISIBLE_PIXELS and ui.viewer_artwork_root.position.y<=ui.viewer_canvas.size.y-ui.VIEWER_MIN_VISIBLE_PIXELS)
	ui._set_viewer_artwork_transform(Vector2(-100000,-100000),.01,false);assert(is_equal_approx(ui.viewer_artwork_root.scale.x,ui.VIEWER_SCALE_MIN) and ui.viewer_artwork_root.position.x+0.01>=ui.VIEWER_MIN_VISIBLE_PIXELS-ui.ShareRendererClass.VIEWER_CANVAS_SIZE.x*ui.VIEWER_SCALE_MIN and ui.viewer_artwork_root.position.y+0.01>=ui.VIEWER_MIN_VISIBLE_PIXELS-ui.ShareRendererClass.VIEWER_CANVAS_SIZE.y*ui.VIEWER_SCALE_MIN)
	ui._set_viewer_artwork_transform(Vector2(31,-17),1.2,false)
	var normal_viewer_transform:Dictionary=ui._viewer_transform_state().duplicate(true)
	ui.viewer_share_button.pressed.emit();assert(ui.share_editor_page.visible and not ui.viewer_page.visible and ui.is_share_editor_active())
	assert(ui.share_editor_canvas.position==ui.SHARE_PREVIEW_POSITION and ui.share_editor_canvas.size.is_equal_approx(ui.SHARE_PREVIEW_SIZE) and ui.share_editor_canvas.clip_contents and is_equal_approx(ui.share_editor_canvas.size.x/ui.share_editor_canvas.size.y,9.0/16.0))
	assert(ui.share_editor_background.texture!=null and str(ui.last_share_preview_debug.background_id)=="greenhouse" and ui.share_editor_artwork_root.position.is_zero_approx() and ui.share_editor_artwork_root.scale.is_equal_approx(Vector2.ONE))
	assert(_has_button_text(ui.share_editor_page,"共有背景") and _has_button_text(ui.share_editor_page,"共有する") and not _has_button_text(ui.share_editor_page,"解体する"))
	ui._open_share_background_panel();assert(ui.share_background_panel.visible and ui.share_background_cards.get_child_count()==4 and ui.share_background_scroll.horizontal_scroll_mode==ScrollContainer.SCROLL_MODE_AUTO and _has_label_text_containing(ui.share_background_panel,"✓ 選択中"))
	var artwork_position_before_panel:Vector2=ui.share_editor_artwork_root.position;ui._on_viewer_canvas_gui_input(_mouse_button(Vector2(220,280),true));ui._on_viewer_canvas_gui_input(_mouse_motion(Vector2(300,340)));ui._on_viewer_canvas_gui_input(_mouse_button(Vector2(300,340),false));assert(ui.share_editor_artwork_root.position.is_equal_approx(artwork_position_before_panel))
	ui._select_share_background("puku_members");assert(str(ui.current_arrangement.share_background_id)=="puku_members" and str(game.saved_arrangements[0].share_background_id)=="puku_members" and not ui.share_background_panel.visible and str(ui.last_share_preview_debug.background_id)=="puku_members")
	ui._open_share_background_panel();ui._select_share_background("jurejure_gang");assert(ui.share_background_panel.visible and str(ui.current_arrangement.share_background_id)=="puku_members" and str(game.saved_arrangements[0].share_background_id)=="puku_members")
	assert(game._pot_usage_count("shallow_terracotta")==share_pot_usage_before and game._pot_available_count("shallow_terracotta")==share_available_before and JSON.stringify(game.saved_arrangements[0].plants)==share_plants_before and str(game.saved_arrangements[0].created_at)==share_created_at_before and not game.saved_arrangements[0].has("viewer_transform"))
	game.story_progression_state["exploitation_started"]=true;game._sync_arrangement_ui();assert(ui._share_background_unlocked("jurejure_gang") and not ui._share_background_unlocked("all_characters"));ui._select_share_background("jurejure_gang");assert(str(game.saved_arrangements[0].share_background_id)=="jurejure_gang")
	var legacy_restoration:Dictionary=game._restoration_state();legacy_restoration["ending_seen"]=true;assert(bool(game._share_background_unlock_states().all_characters));legacy_restoration["ending_seen"]=false
	game.finale_complete=true;game._sync_arrangement_ui();assert(ui._share_background_unlocked("all_characters"));ui._select_share_background("all_characters");assert(str(game.saved_arrangements[0].share_background_id)=="all_characters" and not game.saved_arrangements[0].has("viewer_transform"))
	var share_pot:Control=ui.share_editor_pot_layer.get_child(0);var share_plant:Control=ui.share_editor_plant_layer.get_child(0);var share_pot_global_before:=share_pot.get_global_transform_with_canvas().origin;var share_plant_global_before:=share_plant.get_global_transform_with_canvas().origin
	var share_preview_scale:float=ui.share_editor_artwork_canvas.scale.x;ui._on_viewer_canvas_gui_input(_mouse_button(Vector2(180,250),true));ui._on_viewer_canvas_gui_input(_mouse_motion(Vector2(222,286)));ui._on_viewer_canvas_gui_input(_mouse_button(Vector2(222,286),false))
	assert(ui.share_editor_artwork_root.position.is_equal_approx(Vector2(42,36)/share_preview_scale))
	assert((share_pot.get_global_transform_with_canvas().origin-share_pot_global_before).is_equal_approx(Vector2(42,36)) and (share_plant.get_global_transform_with_canvas().origin-share_plant_global_before).is_equal_approx(Vector2(42,36)))
	_send_viewer_touch(ui,_screen_touch(41,Vector2(120,260),true));_send_viewer_touch(ui,_screen_touch(42,Vector2(260,260),true));_send_viewer_touch(ui,_screen_drag(42,Vector2(330,260)));assert(ui.share_editor_artwork_root.scale.x>1.0);_send_viewer_touch(ui,_screen_touch(42,Vector2(330,260),false));_send_viewer_touch(ui,_screen_touch(41,Vector2(120,260),false))
	assert(not game.saved_arrangements[0].has("viewer_transform"))
	ui._return_from_share_editor();assert(ui.viewer_page.visible and not ui.share_editor_page.visible and ui.viewer_artwork_root.position.is_equal_approx(Vector2(float(normal_viewer_transform.x),float(normal_viewer_transform.y))) and is_equal_approx(ui.viewer_artwork_root.scale.x,float(normal_viewer_transform.scale)))
	assert(game._pot_usage_count("shallow_terracotta")==share_pot_usage_before and game._pot_available_count("shallow_terracotta")==share_available_before and JSON.stringify(game.saved_arrangements[0].plants)==share_plants_before and str(game.saved_arrangements[0].created_at)==share_created_at_before and not game.saved_arrangements[0].has("viewer_transform"))
	ui._restore_viewer_transform(game.saved_arrangements[0]);assert(ui.viewer_artwork_root.position.is_zero_approx() and is_equal_approx(ui.viewer_artwork_root.scale.x,1.0))
	var saved:Dictionary=game.saved_arrangements[0];assert(saved.has("arrangement_id") and saved.has("name") and saved.has("pot_id") and saved.has("created_at") and saved.has("plants") and not saved.has("viewer_transform") and bool(saved.completed));assert(saved.plants.size()==2 and int(saved.plants[0].z_index)>int(saved.plants[1].z_index) and is_equal_approx(float(saved.plants[0].scale),2.35))
	for plant_key in ["species_id","x","y","scale","rotation","z_index"]:assert(saved.plants[0].has(plant_key))
	var saved_id:=str(saved.arrangement_id);var saved_position:=Vector2(float(saved.plants[0].x),float(saved.plants[0].y));var saved_scale:=float(saved.plants[0].scale)
	game._save();game.saved_arrangements.clear();game._load_save();assert(game.saved_arrangements.size()==1 and str(game.saved_arrangements[0].arrangement_id)==saved_id and str(game.saved_arrangements[0].share_background_id)=="all_characters")
	assert(Vector2(float(game.saved_arrangements[0].plants[0].x),float(game.saved_arrangements[0].plants[0].y)).is_equal_approx(saved_position) and is_equal_approx(float(game.saved_arrangements[0].plants[0].scale),saved_scale) and not game.saved_arrangements[0].has("viewer_transform"))
	game._on_arrangement_save_requested({"arrangement_id":"blocked_no_pot","name":"保存不可","pot_id":"shallow_terracotta","created_at":"test","completed":true,"plants":[]});assert(game.saved_arrangements.size()==1 and not ui.save_request_accepted)
	game._sync_arrangement_ui();ui.selected_plant_index=0;var locked_scale:=float(ui.editor_plants[0].scale);ui._adjust_selected_scale(.1);assert(is_equal_approx(float(ui.editor_plants[0].scale),locked_scale))
	# Completion returns directly to the viewer; its back button returns to the
	# creation-first pot grid. Saved-work viewing retains its own return route.
	ui._return_from_viewer();assert(ui.home_page.visible)
	ui._open_saved_arrangements();assert(ui.saved_arrangements_page.visible and ui.viewer_gallery_mode and _has_label_text_containing(ui.saved_arrangements_page,"作った作品") and ui.saved_arrangements_tabs.get_child_count()==1 and ui.viewer_canvas.visible and ui.viewer_artwork_root.position.is_zero_approx() and is_equal_approx(ui.viewer_artwork_root.scale.x,1.0))
	assert(not _has_button_text(ui.saved_arrangements_page,"見る") and ui.saved_arrangements_tab_scroll.horizontal_scroll_mode==ScrollContainer.SCROLL_MODE_AUTO and ui.saved_arrangements_tab_scroll.vertical_scroll_mode==ScrollContainer.SCROLL_MODE_DISABLED and "✓" in (ui.saved_arrangements_tabs.get_child(0) as Button).text)
	ui._return_from_viewer();assert(ui.home_page.visible and ui.pot_select_grid.get_child_count()==0 and ui.home_status.visible and ui.home_status.text==localizer.text("ja","arrangement_no_available_pots") and _has_button_text(ui.home_page,"作った作品を見る") and not _has_button_text(ui.home_page,"編集"))
	# The grid remains visible at capacity, but even an otherwise available pot
	# cannot bypass the guard and enter the editor.
	var capacity_arrangements:Array=[]
	for capacity_index in range(3):capacity_arrangements.append({"arrangement_id":"capacity_%d"%capacity_index,"name":"上限","pot_id":"unused","completed":true,"plants":[]})
	var capacity_owned:Dictionary=game.owned_pots.duplicate(true);capacity_owned["shallow_terracotta"]=2
	ui.sync_state(capacity_owned,capacity_arrangements,3);ui.open_home();assert(ui.pot_select_grid.get_child_count()==1 and (ui.pot_select_grid.get_child(0) as Button).disabled and "作品の保存上限" in ui.home_status.text)
	ui._select_editor_pot("shallow_terracotta");assert(ui.home_page.visible and not ui.editor_page.visible and ui.current_arrangement.is_empty())
	game._sync_arrangement_ui();ui.open_home()
	ui._open_saved_arrangements()
	ui._show_dismantle_confirmation();assert(ui.dismantle_confirmation_overlay.visible);ui._hide_dismantle_confirmation();assert(game.saved_arrangements.size()==1)
	ui._show_dismantle_confirmation();ui._confirm_dismantle();assert(game.saved_arrangements.is_empty() and ui.saved_arrangements_page.visible and not ui.dismantle_confirmation_overlay.visible and game._owned_pot_total("shallow_terracotta")==1 and game._pot_usage_count("shallow_terracotta")==0 and game._pot_available_count("shallow_terracotta")==1)
	ui._return_from_saved_arrangements();assert(ui.home_page.visible and ui.pot_select_grid.get_child_count()==1 and not (ui.pot_select_grid.get_child(0) as Button).disabled and _has_label_text_containing(ui.pot_select_grid.get_child(0),"使用可能 ×1"))
	assert(game.species_get_counts==get_before and game.bests==best_before and game.discovered==discovered_before)
	game.audio_manager.prepare_se("purchase");ui.open_pot_shop();game.audio_manager.se_enabled=true;game.audio_manager.last_se_key=""
	var puku_before:int=game.puku_points;var classic_shop_card:Node=_pot_shop_card(ui,"classic_terracotta");var classic_card_instance_id:=classic_shop_card.get_instance_id();var initial_classic_buttons:=classic_shop_card.find_children("*","Button",true,false);var prepared_classic_feedback:=classic_shop_card.find_child("PotPurchaseFeedback",true,false) as Control;assert(initial_classic_buttons.size()==1 and prepared_classic_feedback!=null and not prepared_classic_feedback.visible)
	var purchase_started_usec:=Time.get_ticks_usec();(initial_classic_buttons[0] as Button).pressed.emit();var success_ready_usec:=Time.get_ticks_usec()
	classic_shop_card=_pot_shop_card(ui,"classic_terracotta");var classic_feedback:=classic_shop_card.find_child("PotPurchaseFeedback",true,false) as Control
	assert(int(game.owned_pots.get("classic_terracotta",0))==1 and game.puku_points==puku_before-1 and game.audio_manager.last_se_key=="purchase")
	assert(classic_shop_card.get_instance_id()==classic_card_instance_id and classic_feedback!=null and classic_feedback.visible and classic_feedback.mouse_filter==Control.MOUSE_FILTER_IGNORE and classic_feedback.position.x>=0.0 and classic_feedback.position.y>=0.0 and classic_feedback.position.x+classic_feedback.size.x<=(classic_feedback.get_parent() as Control).size.x and classic_feedback.position.y+classic_feedback.size.y<=(classic_feedback.get_parent() as Control).size.y)
	assert(_has_label_text_containing(classic_feedback,"素焼き鉢を購入しました！") and _has_label_text_containing(classic_feedback,"所持 ×0 →") and _has_label_text_containing(classic_feedback,"×1") and classic_feedback.find_children("PotPurchaseSparkle*","Label",true,false).size()==4)
	assert(ui.shop_message.text.is_empty() and "購入しました" not in ui.shop_message.text and ui.shop_wallet.text==localizer.text("ja","wallet",[puku_before-1]))
	assert(float(success_ready_usec-purchase_started_usec)/1000.0<50.0 and ui.last_pot_purchase_ui_ready_latency_msec<50.0)
	await get_tree().process_frame
	assert(ui.last_pot_purchase_first_frame_latency_msec>=0.0 and ui.last_pot_purchase_first_frame_latency_msec<50.0)
	print("POT_PURCHASE_PROFILE smoke ui_ready_ms=",snappedf(float(success_ready_usec-purchase_started_usec)/1000.0,.001)," first_frame_ms=",snappedf(ui.last_pot_purchase_first_frame_latency_msec,.001))
	await get_tree().create_timer(.75).timeout
	classic_shop_card=_pot_shop_card(ui,"classic_terracotta");var repeat_classic_buttons:=classic_shop_card.find_children("*","Button",true,false);var initial_black_card:Node=_pot_shop_card(ui,"black_ceramic");var black_card_instance_id:=initial_black_card.get_instance_id();var initial_black_buttons:=initial_black_card.find_children("*","Button",true,false);assert(repeat_classic_buttons.size()==1 and initial_black_buttons.size()==1);(repeat_classic_buttons[0] as Button).pressed.emit();(initial_black_buttons[0] as Button).pressed.emit();await get_tree().process_frame
	classic_shop_card=_pot_shop_card(ui,"classic_terracotta");classic_feedback=classic_shop_card.find_child("PotPurchaseFeedback",true,false) as Control
	var black_shop_card:Node=_pot_shop_card(ui,"black_ceramic");var black_feedback:=black_shop_card.find_child("PotPurchaseFeedback",true,false) as Control
	assert(int(game.owned_pots.get("classic_terracotta",0))==2 and int(game.owned_pots.get("black_ceramic",0))==1 and game.puku_points==puku_before-4)
	assert(classic_shop_card.get_instance_id()==classic_card_instance_id and black_shop_card.get_instance_id()==black_card_instance_id and ui.pot_purchase_feedback.has("classic_terracotta") and ui.pot_purchase_feedback.has("black_ceramic") and classic_feedback.visible and black_feedback.visible and _has_label_text_containing(classic_feedback,"所持 ×1 →") and _has_label_text_containing(classic_feedback,"×2") and _has_label_text_containing(black_feedback,"黒陶器鉢を購入しました！"))
	await get_tree().create_timer(.80).timeout
	assert((_pot_shop_card(ui,"classic_terracotta").find_child("PotPurchaseFeedback",true,false) as Control).visible and (_pot_shop_card(ui,"black_ceramic").find_child("PotPurchaseFeedback",true,false) as Control).visible)
	await get_tree().create_timer(.80).timeout
	assert(not ui.pot_purchase_feedback.has("classic_terracotta") and not ui.pot_purchase_feedback.has("black_ceramic") and not (_pot_shop_card(ui,"classic_terracotta").find_child("PotPurchaseFeedback",true,false) as Control).visible and not (_pot_shop_card(ui,"black_ceramic").find_child("PotPurchaseFeedback",true,false) as Control).visible and _has_label_text_containing(_pot_shop_card(ui,"classic_terracotta"),"所持 ×2"))
	var puku_after_success:int=game.puku_points;var white_before:int=game._owned_pot_total("white_ceramic");game.puku_points=0;game._sync_arrangement_ui();game.audio_manager.last_se_key="";game._on_pot_purchase_requested("white_ceramic")
	assert(game._owned_pot_total("white_ceramic")==white_before and game.puku_points==0 and game.audio_manager.last_se_key.is_empty() and not ui.pot_purchase_feedback.has("white_ceramic") and ui.shop_message.text==localizer.text("ja","not_enough_puku"))
	game.puku_points=puku_after_success;game._sync_arrangement_ui()
	var paid_pot:Dictionary=game._pot_entry("g1_crystal_goblet");var paid_product_id:=str(paid_pot.iap_product_id);game.forest_gacha_unlocked=true;game.pot_design_unlocks.erase(paid_product_id);game.owned_pots.erase("g1_crystal_goblet")
	var paid_puku_before:int=game.puku_points;game._on_pot_purchase_requested("g1_crystal_goblet");assert(game._owned_pot_total("g1_crystal_goblet")==0 and game.puku_points==paid_puku_before)
	game.pot_design_unlocks[paid_product_id]=true;game._on_pot_purchase_requested("g1_crystal_goblet");assert(game._owned_pot_total("g1_crystal_goblet")==1 and game.puku_points==paid_puku_before-2)
	var jackpot_pot:Dictionary=game._pot_entry("g1_gold_jackpot");var jackpot_product_id:=str(jackpot_pot.iap_product_id)
	var ramen_pot:Dictionary=game._pot_entry("g2_ramen_bowl");var ramen_product_id:=str(ramen_pot.iap_product_id)
	game.act3_unlocked=true;game.puku_points=200;game.pot_design_unlocks[jackpot_product_id]=true;game.pot_design_unlocks[ramen_product_id]=true
	game._on_pot_purchase_requested("g1_gold_jackpot");assert(game._owned_pot_total("g1_gold_jackpot")==1 and game.puku_points==170)
	game._on_pot_purchase_requested("g2_ramen_bowl");assert(game._owned_pot_total("g2_ramen_bowl")==1 and game.puku_points==70)
	game._save();game.pot_design_unlocks.clear();game.owned_pots.erase("g1_crystal_goblet");game.owned_pots.erase("g1_gold_jackpot");game.owned_pots.erase("g2_ramen_bowl");game.puku_points=0;game._load_save()
	assert(bool(game.pot_design_unlocks.get(paid_product_id,false)) and bool(game.pot_design_unlocks.get(jackpot_product_id,false)) and bool(game.pot_design_unlocks.get(ramen_product_id,false)))
	assert(game._owned_pot_total("g1_crystal_goblet")==1 and game._owned_pot_total("g1_gold_jackpot")==1 and game._owned_pot_total("g2_ramen_bowl")==1 and game.puku_points==70)
	game.owned_pots.erase("g1_crystal_goblet");game.owned_pots.erase("g1_gold_jackpot");game.owned_pots.erase("g2_ramen_bowl");game.pot_design_unlocks.erase(paid_product_id);game.pot_design_unlocks.erase(jackpot_product_id);game.pot_design_unlocks.erase(ramen_product_id);game.forest_gacha_unlocked=false;game.act3_unlocked=false
	ui.open_pot_shop();classic_shop_card=_pot_shop_card(ui,"classic_terracotta");var classic_buy_buttons:=classic_shop_card.find_children("*","Button",true,false);assert(_has_label_text_containing(classic_shop_card,"所持 ×2") and classic_buy_buttons.size()==1 and not (classic_buy_buttons[0] as Button).disabled and "1ぷくコイン" in (classic_buy_buttons[0] as Button).text)
	game._save();game.owned_pots.erase("classic_terracotta");game._load_save();assert(int(game.owned_pots.get("classic_terracotta",0))==2 and typeof(game.owned_pots.get("classic_terracotta"))==TYPE_INT)
	game._sync_arrangement_ui();ui.open_home();assert(ui.pot_select_grid.get_child_count()==3 and _has_label_text_containing(ui.pot_select_grid.get_child(0),"浅型素焼き鉢") and _has_label_text_containing(ui.pot_select_grid.get_child(1),"素焼き鉢") and _has_label_text_containing(ui.pot_select_grid.get_child(2),"黒陶器鉢"));ui._select_editor_pot("classic_terracotta");assert(ui.editor_page.visible and str(ui.current_arrangement.pot_id)=="classic_terracotta")
	assert(game.species_get_counts==get_before and game.bests==best_before and game.discovered==discovered_before)
	var migrated:Dictionary=game._normalize_arrangement({"arrangement_id":"legacy","name":"旧作品","pot_id":"starter_terracotta","plants":[],"viewer_transform":{"x":91.0,"y":-42.0,"scale":2.0}});assert(str(migrated.pot_id)=="shallow_terracotta" and not migrated.has("viewer_transform") and str(migrated.share_background_id)=="greenhouse")
	ui._open_viewer(migrated);assert(ui.viewer_plant_layer.get_child_count()==0 and ui.viewer_artwork_root.position.is_zero_approx() and ui.viewer_artwork_root.scale.is_equal_approx(Vector2.ONE));ui._return_from_viewer();ui._select_editor_pot("classic_terracotta")
	var free_scale:Dictionary=game._normalize_arrangement({"arrangement_id":"free_scale","name":"自由拡大","pot_id":"shallow_terracotta","plants":[{"species_id":"colorata","x":211.0,"y":287.0,"scale":2.75,"rotation":73.0,"z_index":4}]})
	assert(is_equal_approx(float(free_scale.plants[0].scale),2.75) and is_equal_approx(float(free_scale.plants[0].rotation),73.0) and int(free_scale.plants[0].z_index)==4)
	for species_entry in game.catalog_species:game.discovered[str(species_entry.get("species_id",""))]=true
	game._sync_arrangement_ui();ui._open_species_picker();await get_tree().process_frame;await get_tree().process_frame
	assert(ui.picker_page.visible and ui.picker_scroll.vertical_scroll_mode==ScrollContainer.SCROLL_MODE_AUTO and ui.picker_scroll.get_v_scroll_bar().max_value>ui.picker_scroll.size.y)
	for picker_card in ui.picker_grid.get_children():
		if picker_card is Button:assert(picker_card.action_mode==BaseButton.ACTION_MODE_BUTTON_RELEASE and picker_card.mouse_filter==Control.MOUSE_FILTER_PASS and picker_card.mouse_force_pass_scroll_events)
	ui.picker_scroll.scroll_vertical=100000;await get_tree().process_frame;assert(ui.picker_scroll.scroll_vertical>0)
	ui._return_to_editor()
	ui.current_arrangement={"arrangement_id":"limit_test","name":"上限テスト","pot_id":"shallow_terracotta","created_at":"test","plants":[]};ui._load_editor_from_current()
	for plant_index in range(ui.MAX_PLANTS_PER_ARRANGEMENT+3):ui._add_species_to_editor("colorata")
	assert(ui.editor_plants.size()==ui.MAX_PLANTS_PER_ARRANGEMENT and ui.add_plant_button.disabled)
	for classic_index in range(2):game._on_arrangement_save_requested({"arrangement_id":"classic_%d"%classic_index,"name":"鉢在庫テスト","pot_id":"classic_terracotta","created_at":"test","completed":true,"plants":[]})
	assert(game._owned_pot_total("classic_terracotta")==2 and game._pot_usage_count("classic_terracotta")==2 and game._pot_available_count("classic_terracotta")==0)
	game._on_arrangement_save_requested({"arrangement_id":"classic_blocked","name":"保存不可","pot_id":"classic_terracotta","created_at":"test","completed":true,"plants":[]});assert(game.saved_arrangements.size()==2 and not ui.save_request_accepted)
	game._sync_arrangement_ui();ui.open_home();assert(_pot_select_card(ui,"classic_terracotta")==null)
	game.puku_points+=1;game._on_pot_purchase_requested("classic_terracotta");await get_tree().process_frame;ui.open_home()
	var available_classic_card:=_pot_select_card(ui,"classic_terracotta");assert(game._owned_pot_total("classic_terracotta")==3 and game._pot_available_count("classic_terracotta")==1 and available_classic_card!=null and _has_label_text_containing(available_classic_card,"使用可能 ×1"))
	# Loading a legacy bool inventory preserves every existing arrangement by
	# raising each total to at least that pot's completed-work usage count.
	game.owned_pots={"shallow_terracotta":true,"black_ceramic":true,"white_ceramic":true}
	game.saved_arrangements=[]
	for legacy_index in range(3):game.saved_arrangements.append({"arrangement_id":"legacy_black_%d"%legacy_index,"name":"旧作品","pot_id":"black_ceramic","created_at":"test","completed":true,"plants":[]})
	game.saved_arrangements.append({"arrangement_id":"legacy_retired","name":"旧鉢作品","pot_id":"starter_terracotta","created_at":"test","completed":true,"plants":[]})
	game._save();game.owned_pots={};game.saved_arrangements=[];game._load_save()
	assert(game.saved_arrangements.size()==4 and int(game.owned_pots.get("black_ceramic",0))==3 and int(game.owned_pots.get("white_ceramic",0))==1 and int(game.owned_pots.get("shallow_terracotta",0))==1)
	assert(game._pot_usage_count("black_ceramic")==3 and game._pot_available_count("black_ceramic")==0 and game._pot_usage_count("shallow_terracotta")==1 and typeof(game.owned_pots.get("black_ceramic"))==TYPE_INT)
	for arrangement_value in game.saved_arrangements:assert(str(arrangement_value.pot_id)!="starter_terracotta")
	game._save();var migrated_save=JSON.parse_string(FileAccess.get_file_as_string(game._active_save_path()));assert(migrated_save is Dictionary and typeof(migrated_save.owned_pots.black_ceramic)==TYPE_FLOAT and int(migrated_save.owned_pots.black_ceramic)==3)
	# A legacy save's stored 20-work limit is upgraded without dropping any of
	# its existing works, then persisted as the new 50-work limit.
	game.owned_pots={"shallow_terracotta":51};game.saved_arrangements=[];game.arrangement_save_capacity=50
	for legacy_capacity_index in range(20):game.saved_arrangements.append(game._normalize_arrangement({"arrangement_id":"legacy_capacity_%02d"%legacy_capacity_index,"name":"旧作品","pot_id":"shallow_terracotta","created_at":"test","completed":true,"plants":[]}))
	game._save();var legacy_capacity_save=JSON.parse_string(FileAccess.get_file_as_string(game._active_save_path()));legacy_capacity_save["arrangement_save_capacity"]=20
	var legacy_capacity_file:=FileAccess.open(game._active_save_path(),FileAccess.WRITE);legacy_capacity_file.store_string(JSON.stringify(legacy_capacity_save));legacy_capacity_file.close()
	game.saved_arrangements=[];game.arrangement_save_capacity=1;game._load_save()
	assert(game.arrangement_save_capacity==50 and game.saved_arrangements.size()==20 and game.arrangement_capacity_migration_dirty)
	game._save();var upgraded_capacity_save=JSON.parse_string(FileAccess.get_file_as_string(game._active_save_path()));assert(int(upgraded_capacity_save.arrangement_save_capacity)==50 and upgraded_capacity_save.saved_arrangements.size()==20)
	# The 50th work is accepted and only the 51st is rejected.
	for capacity_index in range(game.saved_arrangements.size(),49):game.saved_arrangements.append(game._normalize_arrangement({"arrangement_id":"capacity_%02d"%capacity_index,"name":"上限確認","pot_id":"shallow_terracotta","created_at":"test","completed":true,"plants":[]}))
	game._sync_arrangement_ui();game._on_arrangement_save_requested({"arrangement_id":"capacity_49","name":"50作品目","pot_id":"shallow_terracotta","created_at":"test","completed":true,"plants":[]})
	assert(game.saved_arrangements.size()==50 and ui.save_request_accepted)
	game._on_arrangement_save_requested({"arrangement_id":"capacity_50","name":"51作品目","pot_id":"shallow_terracotta","created_at":"test","completed":true,"plants":[]})
	assert(game.saved_arrangements.size()==50 and not ui.save_request_accepted)
	print("ARRANGEMENT_SMOKE_OK pots=",game.pot_catalog.size()," saved=",game.saved_arrangements.size()," capacity=",game.arrangement_save_capacity," max_plants=",ui.MAX_PLANTS_PER_ARRANGEMENT)
	get_tree().quit()

func _mouse_button(position:Vector2,pressed:bool)->InputEventMouseButton:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=position;return event

func _mouse_motion(position:Vector2)->InputEventMouseMotion:
	var event:=InputEventMouseMotion.new();event.position=position;return event

func _screen_touch(index:int,position:Vector2,pressed:bool)->InputEventScreenTouch:
	var event:=InputEventScreenTouch.new();event.index=index;event.position=position;event.pressed=pressed;return event

func _screen_drag(index:int,position:Vector2)->InputEventScreenDrag:
	var event:=InputEventScreenDrag.new();event.index=index;event.position=position;return event

func _send_editor_touch(ui,event:InputEvent)->void:
	var screen_event:=event.duplicate()
	screen_event.position=ui.editor_canvas.get_global_transform_with_canvas()*event.position
	ui._input(screen_event)

func _send_viewer_touch(ui,event:InputEvent)->void:
	var screen_event:=event.duplicate()
	screen_event.position=ui._active_viewer_canvas().get_global_transform_with_canvas()*event.position
	ui._input(screen_event)

func _has_button_text(root:Node,text:String)->bool:
	for node in root.find_children("*","Button",true,false):
		if node is Button and (node as Button).text==text:return true
	return false

func _has_label_text_containing(root:Node,text:String)->bool:
	for node in root.find_children("*","Label",true,false):
		if node is Label and text in (node as Label).text:return true
	return false

func _pot_shop_card(ui,pot_id:String)->Node:
	for card in ui.shop_grid.get_children():
		if card.has_meta("pot_id") and str(card.get_meta("pot_id"))==pot_id:return card
	return null

func _pot_select_card(ui,pot_id:String)->Button:
	for card in ui.pot_select_grid.get_children():
		if card is Button and card.has_meta("pot_id") and str(card.get_meta("pot_id"))==pot_id:return card
	return null
