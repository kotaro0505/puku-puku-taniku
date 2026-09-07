extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.buyback_unlocked=true;game.total_play_count=3;game.formal_play_count=3
	game.discovered={"colorata":true,"laui":false};game.species_get_counts={"colorata":4};game.bests={"colorata":62.5};game.coins=2000;game._sync_arrangement_ui();game._update_play_ui()
	var ui=game.arrangement_ui
	assert(game.pot_catalog.size()>=3 and bool(game.owned_pots.get("starter_terracotta",false)))
	for pot_value in game.pot_catalog:
		for required_key in ["pot_id","display_name","image_path","price","unlock_condition","iap_product_id","placement_area","sort_order"]:assert(pot_value.has(required_key))
	assert(game.arrangement_button.visible)
	var available:Array=ui._available_species_entries("all");assert(available.size()==1 and str(available[0].species_id)=="colorata")
	ui.open_home();ui._start_new_arrangement();assert(ui.pot_select_page.visible)
	ui._select_editor_pot("starter_terracotta");assert(ui.editor_page.visible and str(ui.current_arrangement.pot_id)=="starter_terracotta")
	ui._add_species_to_editor("laui");assert(ui.editor_plants.is_empty())
	ui._add_species_to_editor("colorata");assert(ui.editor_plants.size()==1 and ui.selected_plant_index==0)
	var original_position:=Vector2(float(ui.editor_plants[0].x),float(ui.editor_plants[0].y));var plant_node:Control=ui.editor_plant_nodes[0]
	var down:=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=ui.PLANT_CONTROL_SIZE*.5;ui._on_plant_gui_input(down,0,plant_node)
	var drag:=InputEventMouseMotion.new();drag.position=ui.PLANT_CONTROL_SIZE*.5+Vector2(38,24);ui._on_plant_gui_input(drag,0,plant_node)
	var up:=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;up.position=drag.position;ui._on_plant_gui_input(up,0,plant_node)
	var moved_position:=Vector2(float(ui.editor_plants[0].x),float(ui.editor_plants[0].y));assert(moved_position.distance_to(original_position)>10.0 and not ui.drag_active)
	ui._adjust_selected_scale(.1);assert(is_equal_approx(float(ui.editor_plants[0].scale),1.1))
	for rotation_step in range(24):ui._adjust_selected_rotation(15.0)
	assert(is_equal_approx(float(ui.editor_plants[0].rotation),0.0))
	ui._add_species_to_editor("colorata");assert(ui.editor_plants.size()==2)
	ui._select_plant(0);ui._change_selected_depth(1);assert(int(ui.editor_plants[0].z_index)>int(ui.editor_plants[1].z_index));ui._change_selected_depth(-1);assert(int(ui.editor_plants[0].z_index)<int(ui.editor_plants[1].z_index))
	ui._select_plant(1);ui._delete_selected_plant();assert(ui.editor_plants.size()==1)
	var get_before:Dictionary=game.species_get_counts.duplicate(true);var best_before:Dictionary=game.bests.duplicate(true);var discovered_before:Dictionary=game.discovered.duplicate(true)
	ui.editor_name.text="春の寄せ植え";ui._save_current_arrangement();assert(game.saved_arrangements.size()==1 and ui.viewer_page.visible and ui.viewer_plant_layer.get_child_count()==1 and ui.viewer_plant_layer.find_child("SelectionBorder",true,false)==null)
	assert(game.species_get_counts==get_before and game.bests==best_before and game.discovered==discovered_before)
	var saved:Dictionary=game.saved_arrangements[0];assert(saved.has("arrangement_id") and saved.has("name") and saved.has("pot_id") and saved.has("created_at") and saved.has("plants"));assert(saved.plants.size()==1)
	for plant_key in ["species_id","x","y","scale","rotation","z_index"]:assert(saved.plants[0].has(plant_key))
	var saved_id:=str(saved.arrangement_id);game._save();game.saved_arrangements.clear();game._load_save();assert(game.saved_arrangements.size()==1 and str(game.saved_arrangements[0].arrangement_id)==saved_id)
	game._sync_arrangement_ui();ui._edit_arrangement(game.saved_arrangements[0]);ui.editor_name.text="春の寄せ植え・改";ui._save_current_arrangement();assert(game.saved_arrangements.size()==1 and str(game.saved_arrangements[0].name)=="春の寄せ植え・改")
	var coins_before:int=game.coins;game._on_pot_purchase_requested("cream_ceramic");assert(bool(game.owned_pots.get("cream_ceramic",false)) and game.coins==coins_before-900);game._on_pot_purchase_requested("cream_ceramic");assert(game.coins==coins_before-900)
	assert(game.species_get_counts==get_before and game.bests==best_before and game.discovered==discovered_before)
	ui.current_arrangement={"arrangement_id":"limit_test","name":"上限テスト","pot_id":"starter_terracotta","created_at":"test","plants":[]};ui._load_editor_from_current()
	for plant_index in range(ui.MAX_PLANTS_PER_ARRANGEMENT+3):ui._add_species_to_editor("colorata")
	assert(ui.editor_plants.size()==ui.MAX_PLANTS_PER_ARRANGEMENT and ui.add_plant_button.disabled)
	print("ARRANGEMENT_SMOKE_OK pots=",game.pot_catalog.size()," saved=",game.saved_arrangements.size()," max_plants=",ui.MAX_PLANTS_PER_ARRANGEMENT)
	get_tree().quit()
