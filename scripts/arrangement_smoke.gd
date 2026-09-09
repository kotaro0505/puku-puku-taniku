extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.buyback_unlocked=true;game.total_play_count=3;game.formal_play_count=3
	game.discovered={"colorata":true,"laui":false};game.species_get_counts={"colorata":4};game.bests={"colorata":62.5};game.coins=2000;game._sync_arrangement_ui();game._update_play_ui()
	var ui=game.arrangement_ui
	assert(game.pot_catalog.size()==11 and bool(game.owned_pots.get("starter_terracotta",false)))
	for pot_value in game.pot_catalog:
		for required_key in ["pot_id","display_name","image_path","price","unlock_condition","iap_product_id","placement_area","sort_order"]:assert(pot_value.has(required_key))
		if str(pot_value.pot_id)!="starter_terracotta":assert(int(pot_value.price)==1000)
	for added_pot_id in ["shallow_terracotta","classic_terracotta","black_ceramic","white_ceramic","clear_crystal","amethyst_crystal","glass_bowl","tin_bucket"]:
		var added_pot:Dictionary=game._pot_entry(added_pot_id);assert(not added_pot.is_empty() and ResourceLoader.exists(str(added_pot.image_path)))
		var pot_image:Image=(load(str(added_pot.image_path)) as Texture2D).get_image();assert(pot_image.get_pixel(0,0).a<.05 and pot_image.get_pixel(pot_image.get_width()-1,pot_image.get_height()-1).a<.05)
	assert(game.arrangement_button.visible)
	var available:Array=ui._available_species_entries("all");assert(available.size()==1 and str(available[0].species_id)=="colorata")
	ui.open_home();ui._start_new_arrangement();assert(ui.pot_select_page.visible and ui.pot_select_grid.get_child_count()==1)
	ui._select_editor_pot("starter_terracotta");assert(ui.editor_page.visible and str(ui.current_arrangement.pot_id)=="starter_terracotta")
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
	var pinch_origin:=Vector2(30,40);ui._on_editor_canvas_gui_input(_screen_touch(0,pinch_origin,true))
	ui._on_editor_canvas_gui_input(_screen_touch(1,pinch_origin+Vector2(30,0),true));assert(ui.pinch_active and ui.selected_plant_index==0)
	ui._on_editor_canvas_gui_input(_screen_drag(1,pinch_origin+Vector2(41.1,0)));assert(is_equal_approx(float(ui.editor_plants[0].scale),1.37) and is_equal_approx(float(ui.editor_plants[0].rotation),0.0))
	ui._on_editor_canvas_gui_input(_screen_drag(1,pinch_origin+Vector2(0,41.1)));assert(is_equal_approx(float(ui.editor_plants[0].scale),1.37) and is_equal_approx(float(ui.editor_plants[0].rotation),90.0))
	ui._on_editor_canvas_gui_input(_screen_touch(1,pinch_origin+Vector2(0,41.1),false));ui._on_editor_canvas_gui_input(_screen_touch(0,pinch_origin,false));assert(not ui.pinch_active and is_equal_approx(float(ui.editor_plants[0].scale),1.37) and is_equal_approx(float(ui.editor_plants[0].rotation),90.0))
	for rotation_step in range(18):ui._adjust_selected_rotation(15.0)
	assert(is_equal_approx(float(ui.editor_plants[0].rotation),0.0))
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
	var rear_plant:Dictionary=ui.editor_plants[1];rear_plant["scale"]=.78;rear_plant["rotation"]=27.0;rear_plant["x"]=356.0;rear_plant["y"]=310.0;ui.editor_plants[1]=rear_plant;ui._apply_plant_transform(1)
	var get_before:Dictionary=game.species_get_counts.duplicate(true);var best_before:Dictionary=game.bests.duplicate(true);var discovered_before:Dictionary=game.discovered.duplicate(true)
	var edit_snapshots:Array=[];var editor_pot:Control=ui.editor_pot_layer.get_child(0);var edit_pot_position:=editor_pot.position
	for editor_node in ui.editor_plant_nodes:edit_snapshots.append({"position":editor_node.position,"scale":editor_node.scale,"rotation":editor_node.rotation_degrees,"z":editor_node.z_index})
	ui.editor_name.text="春の寄せ植え";ui._save_current_arrangement();assert(game.saved_arrangements.size()==1 and ui.editor_page.visible and ui.completion_overlay.visible and ui.completion_label.text=="寄せ植え完成！" and ui.completion_confetti_layer.get_child_count()==40)
	await get_tree().create_timer(ui.COMPLETION_DISPLAY_SECONDS+.08).timeout
	assert(ui.viewer_page.visible and ui.viewer_plant_layer.get_child_count()==2 and ui.viewer_plant_layer.find_child("SelectionBorder",true,false)==null and not ui.completion_overlay.visible)
	var viewed_pot:Control=ui.viewer_pot_layer.get_child(0);assert(viewed_pot.position.is_equal_approx(edit_pot_position))
	for index in range(ui.viewer_plant_layer.get_child_count()):
		var viewed_plant:Control=ui.viewer_plant_layer.get_child(index);var edit_snapshot:Dictionary=edit_snapshots[index]
		assert(viewed_plant.position.is_equal_approx(edit_snapshot.position) and viewed_plant.scale.is_equal_approx(edit_snapshot.scale) and is_equal_approx(viewed_plant.rotation_degrees,float(edit_snapshot.rotation)) and viewed_plant.z_index==int(edit_snapshot.z))
	assert(ui.editor_canvas.position==ui.viewer_canvas.position and ui.viewer_plant_layer.z_index==ui.PLANT_LAYER_Z and ui.viewer_canvas.get_theme_stylebox("panel") is StyleBoxEmpty)
	assert(game.species_get_counts==get_before and game.bests==best_before and game.discovered==discovered_before)
	var saved:Dictionary=game.saved_arrangements[0];assert(saved.has("arrangement_id") and saved.has("name") and saved.has("pot_id") and saved.has("created_at") and saved.has("plants") and bool(saved.completed));assert(saved.plants.size()==2 and int(saved.plants[0].z_index)>int(saved.plants[1].z_index))
	for plant_key in ["species_id","x","y","scale","rotation","z_index"]:assert(saved.plants[0].has(plant_key))
	var saved_id:=str(saved.arrangement_id);var saved_position:=Vector2(float(saved.plants[0].x),float(saved.plants[0].y));var saved_scale:=float(saved.plants[0].scale)
	game._save();game.saved_arrangements.clear();game._load_save();assert(game.saved_arrangements.size()==1 and str(game.saved_arrangements[0].arrangement_id)==saved_id)
	assert(Vector2(float(game.saved_arrangements[0].plants[0].x),float(game.saved_arrangements[0].plants[0].y)).is_equal_approx(saved_position) and is_equal_approx(float(game.saved_arrangements[0].plants[0].scale),saved_scale))
	game._sync_arrangement_ui();ui.open_home();assert(not _has_button_text(ui.home_page,"編集"));ui._open_viewer(game.saved_arrangements[0]);assert(not _has_button_text(ui.viewer_page,"編集") and not ui.has_method("_edit_arrangement"))
	ui.selected_plant_index=0;var locked_scale:=float(ui.editor_plants[0].scale);ui._adjust_selected_scale(.1);assert(is_equal_approx(float(ui.editor_plants[0].scale),locked_scale))
	var coins_before:int=game.coins;game._on_pot_purchase_requested("shallow_terracotta");assert(bool(game.owned_pots.get("shallow_terracotta",false)) and game.coins==coins_before-1000);game._on_pot_purchase_requested("shallow_terracotta");assert(game.coins==coins_before-1000)
	game._save();game.owned_pots.erase("shallow_terracotta");game._load_save();assert(bool(game.owned_pots.get("shallow_terracotta",false)))
	game._sync_arrangement_ui();ui.open_home();ui._start_new_arrangement();assert(ui.pot_select_grid.get_child_count()==2);ui._select_editor_pot("shallow_terracotta");assert(ui.editor_page.visible and str(ui.current_arrangement.pot_id)=="shallow_terracotta")
	assert(game.species_get_counts==get_before and game.bests==best_before and game.discovered==discovered_before)
	ui.current_arrangement={"arrangement_id":"limit_test","name":"上限テスト","pot_id":"starter_terracotta","created_at":"test","plants":[]};ui._load_editor_from_current()
	for plant_index in range(ui.MAX_PLANTS_PER_ARRANGEMENT+3):ui._add_species_to_editor("colorata")
	assert(ui.editor_plants.size()==ui.MAX_PLANTS_PER_ARRANGEMENT and ui.add_plant_button.disabled)
	print("ARRANGEMENT_SMOKE_OK pots=",game.pot_catalog.size()," saved=",game.saved_arrangements.size()," max_plants=",ui.MAX_PLANTS_PER_ARRANGEMENT)
	get_tree().quit()

func _mouse_button(position:Vector2,pressed:bool)->InputEventMouseButton:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=position;return event

func _mouse_motion(position:Vector2)->InputEventMouseMotion:
	var event:=InputEventMouseMotion.new();event.position=position;return event

func _screen_touch(index:int,position:Vector2,pressed:bool)->InputEventScreenTouch:
	var event:=InputEventScreenTouch.new();event.index=index;event.position=position;event.pressed=pressed;return event

func _screen_drag(index:int,position:Vector2)->InputEventScreenDrag:
	var event:=InputEventScreenDrag.new();event.index=index;event.position=position;return event

func _has_button_text(root:Node,text:String)->bool:
	for node in root.find_children("*","Button",true,false):
		if node is Button and (node as Button).text==text:return true
	return false
