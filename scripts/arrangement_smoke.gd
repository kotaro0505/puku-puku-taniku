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
	ui._add_species_to_editor("laui");assert(ui.editor_plants.is_empty())
	ui._add_species_to_editor("colorata");assert(ui.editor_plants.size()==1 and ui.selected_plant_index==0 and ui.selection_move_ready)
	assert(ui._placement_rect({},ui.editor_canvas.size)==Rect2(Vector2.ZERO,ui.editor_canvas.size) and ui.editor_pot_layer.get_child_count()==1 and ui.editor_plant_layer.find_child("SelectionBorder",true,false)==null)
	var original_position:=Vector2(float(ui.editor_plants[0].x),float(ui.editor_plants[0].y))
	var down:=_mouse_button(original_position,true);ui._on_editor_canvas_gui_input(down)
	var drag:=_mouse_motion(original_position+Vector2(38,24));ui._on_editor_canvas_gui_input(drag)
	var up:=_mouse_button(drag.position,false);ui._on_editor_canvas_gui_input(up)
	var moved_position:=Vector2(float(ui.editor_plants[0].x),float(ui.editor_plants[0].y));assert(moved_position.distance_to(original_position)>10.0 and not ui.drag_active and not ui.selection_move_ready)
	# A fixed plant does not move on a short touch. Long-pressing grabs the same real plant.
	var short_down:=_mouse_button(moved_position,true);ui._on_editor_canvas_gui_input(short_down);ui._on_editor_canvas_gui_input(_mouse_button(moved_position,false));assert(Vector2(float(ui.editor_plants[0].x),float(ui.editor_plants[0].y)).is_equal_approx(moved_position))
	var hold_down:=_mouse_button(moved_position,true);ui._on_editor_canvas_gui_input(hold_down);ui.hold_started_msec-=500;ui._process(0.0);assert(ui.drag_active and ui.selected_plant_index==0)
	ui._on_editor_canvas_gui_input(_mouse_motion(moved_position+Vector2(-31,19)));ui._on_editor_canvas_gui_input(_mouse_button(moved_position+Vector2(-31,19),false));var held_move_position:=Vector2(float(ui.editor_plants[0].x),float(ui.editor_plants[0].y));assert(held_move_position.distance_to(moved_position)>10.0 and not ui.drag_active)
	# Two-finger distance maps directly to scale without step snapping.
	var first_touch:=_screen_touch(0,held_move_position,true);ui._on_editor_canvas_gui_input(first_touch);ui.hold_started_msec-=500;ui._process(0.0)
	var second_touch:=_screen_touch(1,held_move_position+Vector2(30,0),true);ui._on_editor_canvas_gui_input(second_touch);assert(ui.pinch_active)
	ui._on_editor_canvas_gui_input(_screen_drag(1,held_move_position+Vector2(41.1,0)));assert(is_equal_approx(float(ui.editor_plants[0].scale),1.37))
	ui._on_editor_canvas_gui_input(_screen_touch(1,held_move_position+Vector2(41.1,0),false));ui._on_editor_canvas_gui_input(_screen_touch(0,held_move_position,false));assert(not ui.pinch_active and is_equal_approx(float(ui.editor_plants[0].scale),1.37))
	for rotation_step in range(24):ui._adjust_selected_rotation(15.0)
	assert(is_equal_approx(float(ui.editor_plants[0].rotation),0.0))
	ui._add_species_to_editor("colorata");assert(ui.editor_plants.size()==2)
	# A background tap places the newly selected plant at that point and fixes it.
	var tap_position:=Vector2(72,88);ui._on_editor_canvas_gui_input(_mouse_button(tap_position,true));ui._on_editor_canvas_gui_input(_mouse_button(tap_position,false))
	assert(Vector2(float(ui.editor_plants[1].x),float(ui.editor_plants[1].y)).is_equal_approx(tap_position) and not ui.selection_move_ready)
	ui._select_plant(0);ui._change_selected_depth(1);assert(int(ui.editor_plants[0].z_index)>int(ui.editor_plants[1].z_index));ui._change_selected_depth(-1);assert(int(ui.editor_plants[0].z_index)<int(ui.editor_plants[1].z_index))
	ui._select_plant(1);ui._delete_selected_plant();assert(ui.editor_plants.size()==1)
	var get_before:Dictionary=game.species_get_counts.duplicate(true);var best_before:Dictionary=game.bests.duplicate(true);var discovered_before:Dictionary=game.discovered.duplicate(true)
	ui.editor_name.text="春の寄せ植え";ui._save_current_arrangement();assert(game.saved_arrangements.size()==1 and ui.viewer_page.visible and ui.viewer_plant_layer.get_child_count()==1 and ui.viewer_plant_layer.find_child("SelectionBorder",true,false)==null)
	assert(game.species_get_counts==get_before and game.bests==best_before and game.discovered==discovered_before)
	var saved:Dictionary=game.saved_arrangements[0];assert(saved.has("arrangement_id") and saved.has("name") and saved.has("pot_id") and saved.has("created_at") and saved.has("plants"));assert(saved.plants.size()==1)
	for plant_key in ["species_id","x","y","scale","rotation","z_index"]:assert(saved.plants[0].has(plant_key))
	var saved_id:=str(saved.arrangement_id);var saved_position:=Vector2(float(saved.plants[0].x),float(saved.plants[0].y));var saved_scale:=float(saved.plants[0].scale)
	game._save();game.saved_arrangements.clear();game._load_save();assert(game.saved_arrangements.size()==1 and str(game.saved_arrangements[0].arrangement_id)==saved_id)
	assert(Vector2(float(game.saved_arrangements[0].plants[0].x),float(game.saved_arrangements[0].plants[0].y)).is_equal_approx(saved_position) and is_equal_approx(float(game.saved_arrangements[0].plants[0].scale),saved_scale))
	game._sync_arrangement_ui();ui._edit_arrangement(game.saved_arrangements[0]);ui.editor_name.text="春の寄せ植え・改";ui._save_current_arrangement();assert(game.saved_arrangements.size()==1 and str(game.saved_arrangements[0].name)=="春の寄せ植え・改")
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
