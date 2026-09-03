class_name ArrangementUI
extends Control

signal close_requested(context:String)
signal save_requested(arrangement:Dictionary)
signal pot_purchase_requested(pot_id:String)

const PotPlaceholderClass = preload("res://scripts/arrangement_pot_placeholder.gd")
const WorkbenchPlaceholderClass = preload("res://scripts/arrangement_workbench_placeholder.gd")
const MAX_PLANTS_PER_ARRANGEMENT := 24
const PLANT_CONTROL_SIZE := Vector2(150,150)
const PLANT_SCALE_MIN := 0.45
const PLANT_SCALE_MAX := 1.80
const PLANT_SCALE_STEP := 0.10
const PLANT_ROTATION_STEP := 15.0
const UI_CREAM := Color("#fff1d2")
const UI_BROWN := Color("#4a2618")

var catalog_species:Array=[]
var series_catalog:Array=[]
var pot_catalog:Array=[]
var discovered:Dictionary={}
var owned_pots:Dictionary={}
var saved_arrangements:Array=[]
var save_capacity:=20
var wallet_coins:=0
var texture_resolver:Callable
var return_context:="greenhouse"

var home_page:Control
var home_summary:Label
var home_list:VBoxContainer
var home_new_button:Button
var pot_select_page:Control
var pot_select_grid:GridContainer
var pot_select_mode:="new"
var editor_page:Control
var editor_name:LineEdit
var editor_canvas:Panel
var editor_pot_layer:Control
var editor_plant_layer:Control
var editor_message:Label
var editor_selection_label:Label
var add_plant_button:Button
var selected_controls:Array[Button]=[]
var layer_panel:PanelContainer
var layer_list:VBoxContainer
var picker_page:Control
var picker_filter:OptionButton
var picker_grid:GridContainer
var viewer_page:Control
var viewer_name:Label
var viewer_canvas:Panel
var viewer_pot_layer:Control
var viewer_plant_layer:Control
var shop_page:Control
var shop_wallet:Label
var shop_message:Label
var shop_grid:VBoxContainer

var current_arrangement:Dictionary={}
var editor_plants:Array=[]
var editor_plant_nodes:Array=[]
var selected_plant_index:=-1
var drag_active:=false
var drag_pointer_offset:=Vector2.ZERO
var active_touches:Dictionary={}
var touch_travel:Dictionary={}
var gesture_active:=false
var gesture_start_distance:=1.0
var gesture_start_angle:=0.0
var gesture_start_scale:=1.0
var gesture_start_rotation:=0.0
var gesture_start_midpoint:=Vector2.ZERO
var gesture_start_position:=Vector2.ZERO
var last_overlap_tap_position:=Vector2(-1000,-1000)
var last_overlap_tap_msec:=0
var overlap_cycle_candidates:Array[int]=[]

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	visible=false
	_build_ui()

func configure(species_data:Array,series_data:Array,pots_data:Array,discovery:Dictionary,purchased_pots:Dictionary,arrangements:Array,capacity:int,coins:int,resolver:Callable)->void:
	catalog_species=species_data
	series_catalog=series_data
	pot_catalog=pots_data
	discovered=discovery
	owned_pots=purchased_pots
	saved_arrangements=arrangements
	save_capacity=maxi(1,capacity)
	wallet_coins=maxi(0,coins)
	texture_resolver=resolver

func sync_state(purchased_pots:Dictionary,arrangements:Array,capacity:int,coins:int)->void:
	owned_pots=purchased_pots;saved_arrangements=arrangements;save_capacity=maxi(1,capacity);wallet_coins=maxi(0,coins)
	if visible and shop_page.visible:_refresh_pot_shop()
	if visible and home_page.visible:_refresh_home()

func open_home()->void:
	return_context="greenhouse";visible=true;_show_page(home_page);_refresh_home()

func open_pot_shop()->void:
	return_context="shop";visible=true;_show_page(shop_page);_refresh_pot_shop()

func close()->void:
	_reset_editor_gesture();visible=false;close_requested.emit(return_context)

func show_pot_shop_message(message:String)->void:
	shop_message.text=message;_refresh_pot_shop_cards()

func _build_ui()->void:
	var workbench:=WorkbenchPlaceholderClass.new();workbench.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);workbench.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(workbench)
	var shade:=ColorRect.new();shade.color=Color(0.20,0.105,0.07,.32);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(shade)
	home_page=_page();_build_home_page()
	pot_select_page=_page();_build_pot_select_page()
	editor_page=_page();_build_editor_page()
	picker_page=_page();_build_picker_page()
	viewer_page=_page();_build_viewer_page()
	shop_page=_page();_build_shop_page()

func _page()->Control:
	var page:=Control.new();page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);page.mouse_filter=Control.MOUSE_FILTER_STOP;page.visible=false;add_child(page);return page

func _show_page(page:Control)->void:
	for candidate in [home_page,pot_select_page,editor_page,picker_page,viewer_page,shop_page]:
		if candidate:candidate.visible=candidate==page

func _build_header(page:Control,title_text:String,back_callable:Callable,back_text:="もどる")->Label:
	var back:=_button(back_text,Vector2(20,24),Vector2(108,54),Color("#f4dfb8"),16);back.pressed.connect(back_callable);page.add_child(back)
	var title:=Label.new();title.text=title_text;title.position=Vector2(132,25);title.size=Vector2(312,52);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",27);title.add_theme_color_override("font_color",UI_CREAM);page.add_child(title)
	return title

func _build_home_page()->void:
	_build_header(home_page,"寄せ植え",close)
	home_summary=Label.new();home_summary.position=Vector2(32,93);home_summary.size=Vector2(512,42);home_summary.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;home_summary.add_theme_font_size_override("font_size",18);home_summary.add_theme_color_override("font_color",Color("#f4d68f"));home_page.add_child(home_summary)
	home_new_button=_button("＋ 新しく作る",Vector2(118,146),Vector2(340,64),Color("#d7aa64"),22);home_new_button.pressed.connect(_start_new_arrangement);home_page.add_child(home_new_button)
	var saved_title:=Label.new();saved_title.text="保存した寄せ植え";saved_title.position=Vector2(32,232);saved_title.size=Vector2(512,36);saved_title.add_theme_font_size_override("font_size",21);saved_title.add_theme_color_override("font_color",UI_CREAM);home_page.add_child(saved_title)
	var scroll:=ScrollContainer.new();scroll.position=Vector2(28,278);scroll.size=Vector2(520,706);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;home_page.add_child(scroll)
	home_list=VBoxContainer.new();home_list.custom_minimum_size=Vector2(500,0);home_list.add_theme_constant_override("separation",12);scroll.add_child(home_list)

func _refresh_home()->void:
	_clear_children(home_list)
	home_summary.text="%d / %d作品　・　購入済みの鉢 %d個"%[saved_arrangements.size(),save_capacity,_owned_pot_count()]
	home_new_button.disabled=saved_arrangements.size()>=save_capacity
	if saved_arrangements.is_empty():
		var empty:=Label.new();empty.text="まだ作品はありません。\n図鑑登録した多肉で、最初の寄せ植えを作ってみよう。";empty.custom_minimum_size=Vector2(500,140);empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;empty.add_theme_font_size_override("font_size",18);empty.add_theme_color_override("font_color",Color("#e5cba5"));home_list.add_child(empty);return
	for arrangement_value in saved_arrangements:
		if not arrangement_value is Dictionary:continue
		var arrangement:Dictionary=arrangement_value
		var card:=PanelContainer.new();card.custom_minimum_size=Vector2(500,104);card.add_theme_stylebox_override("panel",_box(Color("#f4e1bc"),Color("#b77c48"),20,3));home_list.add_child(card)
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);card.add_child(row)
		var info:=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(info)
		var name_label:=Label.new();name_label.text=str(arrangement.get("name","寄せ植え"));name_label.add_theme_font_size_override("font_size",20);name_label.add_theme_color_override("font_color",UI_BROWN);info.add_child(name_label)
		var pot_label:=Label.new();pot_label.text="%s　・　%d株"%[_pot_name(str(arrangement.get("pot_id",""))),_plant_array(arrangement).size()];pot_label.add_theme_font_size_override("font_size",14);pot_label.add_theme_color_override("font_color",Color("#79543a"));info.add_child(pot_label)
		var view:=_button("見る",Vector2.ZERO,Vector2(78,56),Color("#ead4a5"),15);view.pressed.connect(_open_viewer.bind(arrangement));row.add_child(view)
		var edit:=_button("編集",Vector2.ZERO,Vector2(78,56),Color("#d7aa64"),15);edit.pressed.connect(_edit_arrangement.bind(arrangement));row.add_child(edit)

func _build_pot_select_page()->void:
	_build_header(pot_select_page,"鉢を選ぶ",_return_from_pot_selection)
	var hint:=Label.new();hint.text="購入済みの鉢から選んでください";hint.position=Vector2(30,91);hint.size=Vector2(516,38);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_font_size_override("font_size",17);hint.add_theme_color_override("font_color",Color("#efd49d"));pot_select_page.add_child(hint)
	var scroll:=ScrollContainer.new();scroll.position=Vector2(24,140);scroll.size=Vector2(528,840);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;pot_select_page.add_child(scroll)
	pot_select_grid=GridContainer.new();pot_select_grid.columns=2;pot_select_grid.custom_minimum_size=Vector2(510,0);pot_select_grid.add_theme_constant_override("h_separation",10);pot_select_grid.add_theme_constant_override("v_separation",12);scroll.add_child(pot_select_grid)

func _refresh_pot_selection()->void:
	_clear_children(pot_select_grid)
	for pot_value in pot_catalog:
		if not pot_value is Dictionary:continue
		var pot:Dictionary=pot_value;var pot_id:=str(pot.get("pot_id",""));var owned:=bool(owned_pots.get(pot_id,false))
		var card:=Button.new();card.custom_minimum_size=Vector2(248,230);card.disabled=not owned;_skin_button(card,Color("#f4e1bc") if owned else Color("#705142"),15);pot_select_grid.add_child(card)
		var preview:=Control.new();preview.position=Vector2(14,10);preview.size=Vector2(220,150);preview.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(preview);_render_pot(preview,pot,true)
		var label:=Label.new();label.text=str(pot.get("display_name","鉢"))+("\n選ぶ" if owned else "\n🔒 たねやで購入");label.position=Vector2(10,164);label.size=Vector2(228,56);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",16);label.add_theme_color_override("font_color",UI_BROWN if owned else UI_CREAM);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(label)
		if owned:card.pressed.connect(_select_editor_pot.bind(pot_id))

func _start_new_arrangement()->void:
	if saved_arrangements.size()>=save_capacity:return
	pot_select_mode="new";current_arrangement={};editor_plants.clear();selected_plant_index=-1;_show_page(pot_select_page);_refresh_pot_selection()

func _return_from_pot_selection()->void:
	if pot_select_mode=="edit" and not current_arrangement.is_empty():_show_page(editor_page);_rebuild_editor_scene()
	else:_show_page(home_page);_refresh_home()

func _select_editor_pot(pot_id:String)->void:
	if not bool(owned_pots.get(pot_id,false)):return
	if pot_select_mode=="new":
		current_arrangement={"arrangement_id":_new_arrangement_id(),"name":_default_arrangement_name(),"pot_id":pot_id,"created_at":Time.get_datetime_string_from_system(false,true),"plants":[]}
	else:current_arrangement["pot_id"]=pot_id
	_show_page(editor_page);_load_editor_from_current()

func _build_editor_page()->void:
	var back:=_button("もどる",Vector2(18,20),Vector2(98,50),Color("#f4dfb8"),15);back.pressed.connect(_return_home_from_editor);editor_page.add_child(back)
	editor_name=LineEdit.new();editor_name.placeholder_text="寄せ植えの名前";editor_name.position=Vector2(124,20);editor_name.size=Vector2(286,50);editor_name.add_theme_font_size_override("font_size",18);editor_name.add_theme_color_override("font_color",UI_BROWN);editor_name.add_theme_stylebox_override("normal",_box(Color("#fff3d8"),Color("#b47d49"),16,2));editor_page.add_child(editor_name)
	var save:=_button("完成 / 保存",Vector2(418,20),Vector2(140,50),Color("#d7aa64"),15);save.pressed.connect(_save_current_arrangement);editor_page.add_child(save)
	editor_canvas=Panel.new();editor_canvas.position=Vector2(20,88);editor_canvas.size=Vector2(536,552);editor_canvas.clip_contents=false;editor_canvas.mouse_filter=Control.MOUSE_FILTER_STOP;editor_canvas.gui_input.connect(_on_editor_canvas_input);editor_canvas.add_theme_stylebox_override("panel",_box(Color(0.97,.90,.77,.88),Color("#c58b50"),24,4));editor_page.add_child(editor_canvas)
	editor_pot_layer=Control.new();editor_pot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);editor_pot_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;editor_canvas.add_child(editor_pot_layer)
	editor_plant_layer=Control.new();editor_plant_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);editor_plant_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;editor_canvas.add_child(editor_plant_layer)
	editor_message=Label.new();editor_message.position=Vector2(28,648);editor_message.size=Vector2(520,31);editor_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;editor_message.add_theme_font_size_override("font_size",15);editor_message.add_theme_color_override("font_color",Color("#f5d48c"));editor_page.add_child(editor_message)
	add_plant_button=_button("＋ 多肉を追加",Vector2(24,687),Vector2(240,58),Color("#d7aa64"),19);add_plant_button.pressed.connect(_open_species_picker);editor_page.add_child(add_plant_button)
	var flip:=_button("左右反転",Vector2(276,687),Vector2(126,58),Color("#ead4a5"),16);flip.pressed.connect(_flip_selected_plant);editor_page.add_child(flip);selected_controls.append(flip)
	var layer_button:=_button("株一覧",Vector2(414,687),Vector2(138,58),Color("#c8ae88"),16);layer_button.pressed.connect(_toggle_layer_panel);editor_page.add_child(layer_button)
	editor_selection_label=Label.new();editor_selection_label.position=Vector2(24,750);editor_selection_label.size=Vector2(528,32);editor_selection_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;editor_selection_label.add_theme_font_size_override("font_size",16);editor_selection_label.add_theme_color_override("font_color",UI_CREAM);editor_page.add_child(editor_selection_label)
	var scale_minus:=_button("－",Vector2(28,793),Vector2(70,56),Color("#ead4a5"),22);scale_minus.pressed.connect(_adjust_selected_scale.bind(-PLANT_SCALE_STEP));editor_page.add_child(scale_minus);selected_controls.append(scale_minus)
	var scale_title:=Label.new();scale_title.text="大きさ";scale_title.position=Vector2(100,793);scale_title.size=Vector2(84,56);scale_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;scale_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;scale_title.add_theme_font_size_override("font_size",16);scale_title.add_theme_color_override("font_color",UI_CREAM);editor_page.add_child(scale_title)
	var scale_plus:=_button("＋",Vector2(186,793),Vector2(70,56),Color("#ead4a5"),22);scale_plus.pressed.connect(_adjust_selected_scale.bind(PLANT_SCALE_STEP));editor_page.add_child(scale_plus);selected_controls.append(scale_plus)
	var rotate_left:=_button("↶",Vector2(272,793),Vector2(70,56),Color("#ead4a5"),23);rotate_left.pressed.connect(_adjust_selected_rotation.bind(-PLANT_ROTATION_STEP));editor_page.add_child(rotate_left);selected_controls.append(rotate_left)
	var rotate_title:=Label.new();rotate_title.text="回転";rotate_title.position=Vector2(344,793);rotate_title.size=Vector2(84,56);rotate_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;rotate_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;rotate_title.add_theme_font_size_override("font_size",16);rotate_title.add_theme_color_override("font_color",UI_CREAM);editor_page.add_child(rotate_title)
	var rotate_right:=_button("↷",Vector2(430,793),Vector2(70,56),Color("#ead4a5"),23);rotate_right.pressed.connect(_adjust_selected_rotation.bind(PLANT_ROTATION_STEP));editor_page.add_child(rotate_right);selected_controls.append(rotate_right)
	var back_depth:=_button("奥へ",Vector2(42,871),Vector2(140,58),Color("#c8ae88"),17);back_depth.pressed.connect(_change_selected_depth.bind(-1));editor_page.add_child(back_depth);selected_controls.append(back_depth)
	var front_depth:=_button("手前へ",Vector2(218,871),Vector2(140,58),Color("#d7aa64"),17);front_depth.pressed.connect(_change_selected_depth.bind(1));editor_page.add_child(front_depth);selected_controls.append(front_depth)
	var delete:=_button("削除",Vector2(394,871),Vector2(140,58),Color("#b87962"),17);delete.pressed.connect(_delete_selected_plant);editor_page.add_child(delete);selected_controls.append(delete)
	var change_pot:=_button("鉢を変更",Vector2(188,944),Vector2(200,48),Color("#8a6752"),15);change_pot.pressed.connect(_change_editor_pot);editor_page.add_child(change_pot)
	_build_layer_panel()

func _build_layer_panel()->void:
	layer_panel=PanelContainer.new();layer_panel.position=Vector2(62,126);layer_panel.size=Vector2(452,680);layer_panel.z_index=200;layer_panel.mouse_filter=Control.MOUSE_FILTER_STOP;layer_panel.add_theme_stylebox_override("panel",_box(Color(0.25,.12,.075,.98),Color("#e1b66f"),24,4));layer_panel.visible=false;editor_page.add_child(layer_panel)
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",10);layer_panel.add_child(content)
	var title_row:=HBoxContainer.new();content.add_child(title_row)
	var title:=Label.new();title.text="配置中の株";title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.add_theme_font_size_override("font_size",23);title.add_theme_color_override("font_color",UI_CREAM);title_row.add_child(title)
	var close_button:=_button("閉じる",Vector2.ZERO,Vector2(96,48),Color("#ead4a5"),15);close_button.pressed.connect(_close_layer_panel);title_row.add_child(close_button)
	var hint:=Label.new();hint.text="重なっていても、ここから確実に選べます";hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_font_size_override("font_size",14);hint.add_theme_color_override("font_color",Color("#e8c995"));content.add_child(hint)
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;content.add_child(scroll)
	layer_list=VBoxContainer.new();layer_list.custom_minimum_size=Vector2(414,0);layer_list.add_theme_constant_override("separation",8);scroll.add_child(layer_list)

func _load_editor_from_current()->void:
	editor_name.text=str(current_arrangement.get("name",_default_arrangement_name()))
	editor_plants=_plant_array(current_arrangement).duplicate(true)
	selected_plant_index=-1;_reset_editor_gesture();layer_panel.visible=false;editor_message.text="1本指で移動・2本指で大きさと回転を調整できます";_rebuild_editor_scene()

func _rebuild_editor_scene()->void:
	_clear_children(editor_pot_layer);_clear_children(editor_plant_layer);editor_plant_nodes.clear()
	var pot:=_pot_entry(str(current_arrangement.get("pot_id","")));_render_editor_pot(pot)
	for index in range(editor_plants.size()):_create_editor_plant(index)
	_update_editor_selection();add_plant_button.disabled=editor_plants.size()>=MAX_PLANTS_PER_ARRANGEMENT

func _render_editor_pot(pot:Dictionary)->void:
	if pot.is_empty():return
	var placement:=Panel.new();var placement_rect:=_placement_rect(pot,editor_canvas.size);placement.position=placement_rect.position;placement.size=placement_rect.size;placement.mouse_filter=Control.MOUSE_FILTER_IGNORE;placement.add_theme_stylebox_override("panel",_box(Color(1,.92,.68,.08),Color(0.58,.36,.20,.34),20,2));editor_pot_layer.add_child(placement)
	var holder:=Control.new();holder.position=Vector2(52,294);holder.size=Vector2(432,244);holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;editor_pot_layer.add_child(holder);_render_pot(holder,pot,false)

func _create_editor_plant(index:int)->void:
	var plant:Dictionary=editor_plants[index];var entry:=_species_entry(str(plant.get("species_id","")));var texture:=_resolve_texture(entry)
	if texture==null:editor_plant_nodes.append(null);return
	var root:=Control.new();root.size=PLANT_CONTROL_SIZE;root.pivot_offset=PLANT_CONTROL_SIZE*.5;root.position=Vector2(float(plant.get("x",editor_canvas.size.x*.5)),float(plant.get("y",editor_canvas.size.y*.42)))-PLANT_CONTROL_SIZE*.5;root.scale=Vector2.ONE*clampf(float(plant.get("scale",1.0)),PLANT_SCALE_MIN,PLANT_SCALE_MAX);root.rotation_degrees=fposmod(float(plant.get("rotation",0.0)),360.0);root.z_index=int(plant.get("z_index",index));root.mouse_filter=Control.MOUSE_FILTER_IGNORE;editor_plant_layer.add_child(root)
	var image:=TextureRect.new();image.name="PlantImage";image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);image.texture=texture;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.pivot_offset=PLANT_CONTROL_SIZE*.5;image.scale=Vector2(-1,1) if bool(plant.get("flipped",false)) else Vector2.ONE;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(image)
	var border:=Panel.new();border.name="SelectionBorder";border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);border.mouse_filter=Control.MOUSE_FILTER_IGNORE;border.add_theme_stylebox_override("panel",_box(Color(1,1,1,.02),Color("#f1b942"),18,3));root.add_child(border)
	editor_plant_nodes.append(root)

func _on_plant_gui_input(event:InputEvent,index:int,node:Control)->void:
	# Kept as a compatibility entry point for automated tests and desktop input.
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:_begin_plant_drag(index,_event_canvas_position(node,event.position))
		else:drag_active=false
		accept_event()
	elif event is InputEventMouseMotion and drag_active and selected_plant_index==index:
		_drag_selected_to(_event_canvas_position(node,event.position));accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:_begin_plant_drag(index,_event_canvas_position(node,event.position))
		else:drag_active=false
		accept_event()
	elif event is InputEventScreenDrag and drag_active and selected_plant_index==index:
		_drag_selected_to(_event_canvas_position(node,event.position));accept_event()

func _on_editor_canvas_input(event:InputEvent)->void:
	if event is InputEventScreenTouch:
		if event.pressed:_begin_editor_touch(event.index,event.position)
		else:_end_editor_touch(event.index,event.position)
		accept_event()
	elif event is InputEventScreenDrag:
		_update_editor_touch(event.index,event.position,event.relative);accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:_begin_editor_touch(-1,event.position)
		else:_end_editor_touch(-1,event.position)
		accept_event()
	elif event is InputEventMouseMotion and active_touches.has(-1) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_editor_touch(-1,event.position,event.relative);accept_event()

func _begin_editor_touch(pointer_id:int,point:Vector2)->void:
	active_touches[pointer_id]=point;touch_travel[pointer_id]=0.0
	if active_touches.size()==1:
		var candidates:=_plant_candidates_at(point)
		if not candidates.is_empty():
			if not candidates.has(selected_plant_index):_select_plant(candidates[0])
			drag_active=selected_plant_index>=0
			if drag_active:
				var selected:Dictionary=editor_plants[selected_plant_index]
				drag_pointer_offset=Vector2(float(selected.get("x",0.0)),float(selected.get("y",0.0)))-point
		else:
			drag_active=false
	elif active_touches.size()==2 and selected_plant_index>=0:
		drag_active=false;_start_two_finger_gesture()

func _update_editor_touch(pointer_id:int,point:Vector2,relative:Vector2)->void:
	if not active_touches.has(pointer_id):return
	active_touches[pointer_id]=point;touch_travel[pointer_id]=float(touch_travel.get(pointer_id,0.0))+relative.length()
	if active_touches.size()>=2:
		_update_two_finger_gesture()
	elif drag_active and selected_plant_index>=0:
		_drag_selected_to(point)

func _end_editor_touch(pointer_id:int,point:Vector2)->void:
	if not active_touches.has(pointer_id):return
	var travel:=float(touch_travel.get(pointer_id,0.0));var was_gesture:=gesture_active
	active_touches.erase(pointer_id);touch_travel.erase(pointer_id)
	if was_gesture:
		gesture_active=false;drag_active=false
		if active_touches.size()==1:
			var remaining_id=active_touches.keys()[0];var remaining_point:Vector2=active_touches[remaining_id]
			touch_travel[remaining_id]=0.0
			if selected_plant_index>=0:
				var selected:Dictionary=editor_plants[selected_plant_index]
				drag_pointer_offset=Vector2(float(selected.get("x",0.0)),float(selected.get("y",0.0)))-remaining_point;drag_active=true
		return
	drag_active=false
	if travel<10.0:_cycle_overlap_selection(point)

func _start_two_finger_gesture()->void:
	if active_touches.size()<2 or selected_plant_index<0:return
	var ids:=active_touches.keys();var first:Vector2=active_touches[ids[0]];var second:Vector2=active_touches[ids[1]]
	gesture_active=true;gesture_start_distance=maxf(8.0,first.distance_to(second));gesture_start_angle=(second-first).angle();gesture_start_midpoint=(first+second)*.5
	var plant:Dictionary=editor_plants[selected_plant_index];gesture_start_scale=float(plant.get("scale",1.0));gesture_start_rotation=float(plant.get("rotation",0.0));gesture_start_position=Vector2(float(plant.get("x",0.0)),float(plant.get("y",0.0)))

func _update_two_finger_gesture()->void:
	if not gesture_active or active_touches.size()<2 or selected_plant_index<0:return
	var ids:=active_touches.keys();var first:Vector2=active_touches[ids[0]];var second:Vector2=active_touches[ids[1]]
	var plant:Dictionary=editor_plants[selected_plant_index]
	plant["scale"]=snappedf(clampf(gesture_start_scale*first.distance_to(second)/gesture_start_distance,PLANT_SCALE_MIN,PLANT_SCALE_MAX),.01)
	plant["rotation"]=fposmod(gesture_start_rotation+rad_to_deg((second-first).angle()-gesture_start_angle),360.0)
	var midpoint:=(first+second)*.5;var translated_center:=gesture_start_position+(midpoint-gesture_start_midpoint)
	var allowed:=_placement_rect(_pot_entry(str(current_arrangement.get("pot_id",""))),editor_canvas.size)
	translated_center.x=clampf(translated_center.x,allowed.position.x,allowed.end.x);translated_center.y=clampf(translated_center.y,allowed.position.y,allowed.end.y)
	plant["x"]=translated_center.x;plant["y"]=translated_center.y;editor_plants[selected_plant_index]=plant;_apply_plant_transform(selected_plant_index)

func _plant_candidates_at(point:Vector2)->Array[int]:
	var candidates:Array[int]=[]
	for index in range(editor_plant_nodes.size()):
		var node=editor_plant_nodes[index]
		if not is_instance_valid(node):continue
		var local_point:Vector2=node.get_transform().affine_inverse()*point
		if Rect2(Vector2.ZERO,node.size).has_point(local_point):candidates.append(index)
	candidates.sort_custom(func(left:int,right:int)->bool:
		var left_z:=int(editor_plants[left].get("z_index",left));var right_z:=int(editor_plants[right].get("z_index",right))
		return left>right if left_z==right_z else left_z>right_z)
	return candidates

func _cycle_overlap_selection(point:Vector2)->void:
	var candidates:=_plant_candidates_at(point)
	if candidates.is_empty():return
	var now:=Time.get_ticks_msec();var same_tap:=point.distance_to(last_overlap_tap_position)<28.0 and now-last_overlap_tap_msec<900 and candidates==overlap_cycle_candidates
	if same_tap and candidates.size()>1:
		var current_position:=candidates.find(selected_plant_index);_select_plant(candidates[(current_position+1)%candidates.size()])
		editor_message.text="重なった株を切り替えました"
	else:
		_select_plant(candidates[0])
	last_overlap_tap_position=point;last_overlap_tap_msec=now;overlap_cycle_candidates=candidates.duplicate()

func _reset_editor_gesture()->void:
	drag_active=false;gesture_active=false;active_touches.clear();touch_travel.clear()

func _event_canvas_position(node:Control,local_position:Vector2)->Vector2:
	var global_position:=node.get_global_transform_with_canvas()*local_position
	return editor_canvas.get_global_transform_with_canvas().affine_inverse()*global_position

func _begin_plant_drag(index:int,pointer_position:Vector2)->void:
	_select_plant(index);drag_active=true
	var plant:Dictionary=editor_plants[index];drag_pointer_offset=Vector2(float(plant.get("x",0.0)),float(plant.get("y",0.0)))-pointer_position

func _drag_selected_to(pointer_position:Vector2)->void:
	if selected_plant_index<0 or selected_plant_index>=editor_plants.size():return
	_move_selected_center(pointer_position+drag_pointer_offset)

func _move_selected_center(center:Vector2)->void:
	if selected_plant_index<0 or selected_plant_index>=editor_plants.size():return
	var pot:=_pot_entry(str(current_arrangement.get("pot_id","")));var allowed:=_placement_rect(pot,editor_canvas.size)
	center.x=clampf(center.x,allowed.position.x,allowed.end.x);center.y=clampf(center.y,allowed.position.y,allowed.end.y)
	var plant:Dictionary=editor_plants[selected_plant_index];plant["x"]=center.x;plant["y"]=center.y;editor_plants[selected_plant_index]=plant;_apply_plant_transform(selected_plant_index)

func _select_plant(index:int)->void:
	if index<0 or index>=editor_plants.size():return
	selected_plant_index=index;_update_editor_selection()
	if layer_panel and layer_panel.visible:_refresh_layer_list()

func _update_editor_selection()->void:
	for index in range(editor_plant_nodes.size()):
		var node=editor_plant_nodes[index]
		if is_instance_valid(node):node.get_node("SelectionBorder").visible=index==selected_plant_index
	var has_selection:=selected_plant_index>=0 and selected_plant_index<editor_plants.size()
	for control in selected_controls:control.disabled=not has_selection
	if not has_selection:editor_selection_label.text="株を選ぶと、ピンチ・2本指回転・反転・前後を調整できます";return
	var plant:Dictionary=editor_plants[selected_plant_index];var entry:=_species_entry(str(plant.get("species_id","")))
	editor_selection_label.text="%s　×%.2f　%d°　%s"%[str(entry.get("name_ja","多肉")),float(plant.get("scale",1.0)),roundi(float(plant.get("rotation",0.0))),"左右反転" if bool(plant.get("flipped",false)) else "通常"]

func _apply_plant_transform(index:int)->void:
	if index<0 or index>=editor_plant_nodes.size():return
	var node=editor_plant_nodes[index]
	if not is_instance_valid(node):return
	var plant:Dictionary=editor_plants[index];node.position=Vector2(float(plant.get("x",0.0)),float(plant.get("y",0.0)))-PLANT_CONTROL_SIZE*.5;node.scale=Vector2.ONE*clampf(float(plant.get("scale",1.0)),PLANT_SCALE_MIN,PLANT_SCALE_MAX);node.rotation_degrees=fposmod(float(plant.get("rotation",0.0)),360.0);node.z_index=int(plant.get("z_index",index))
	var image:=node.get_node_or_null("PlantImage") as TextureRect
	if image:image.scale=Vector2(-1,1) if bool(plant.get("flipped",false)) else Vector2.ONE
	_update_editor_selection()

func _adjust_selected_scale(amount:float)->void:
	if selected_plant_index<0:return
	var plant:Dictionary=editor_plants[selected_plant_index];plant["scale"]=snappedf(clampf(float(plant.get("scale",1.0))+amount,PLANT_SCALE_MIN,PLANT_SCALE_MAX),.01);editor_plants[selected_plant_index]=plant;_apply_plant_transform(selected_plant_index)

func _adjust_selected_rotation(amount:float)->void:
	if selected_plant_index<0:return
	var plant:Dictionary=editor_plants[selected_plant_index];plant["rotation"]=fposmod(float(plant.get("rotation",0.0))+amount,360.0);editor_plants[selected_plant_index]=plant;_apply_plant_transform(selected_plant_index)

func _flip_selected_plant()->void:
	if selected_plant_index<0:return
	var plant:Dictionary=editor_plants[selected_plant_index];plant["flipped"]=not bool(plant.get("flipped",false));editor_plants[selected_plant_index]=plant;_apply_plant_transform(selected_plant_index)

func _change_selected_depth(direction:int)->void:
	if selected_plant_index<0:return
	var edge:=0
	if not editor_plants.is_empty():
		edge=int(editor_plants[0].get("z_index",0))
		for plant_value in editor_plants:
			var z:=int(plant_value.get("z_index",0));edge=maxi(edge,z) if direction>0 else mini(edge,z)
	var plant:Dictionary=editor_plants[selected_plant_index];plant["z_index"]=clampi(edge+direction,-100,100);editor_plants[selected_plant_index]=plant;_apply_plant_transform(selected_plant_index)
	if layer_panel and layer_panel.visible:_refresh_layer_list()

func _toggle_layer_panel()->void:
	if layer_panel.visible:_close_layer_panel()
	else:layer_panel.visible=true;_refresh_layer_list()

func _close_layer_panel()->void:
	layer_panel.visible=false

func _refresh_layer_list()->void:
	_clear_children(layer_list)
	if editor_plants.is_empty():
		var empty:=Label.new();empty.text="まだ株がありません";empty.custom_minimum_size=Vector2(414,72);empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;empty.add_theme_color_override("font_color",UI_CREAM);layer_list.add_child(empty);return
	var order:Array[int]=[]
	for index in range(editor_plants.size()):order.append(index)
	order.sort_custom(func(left:int,right:int)->bool:
		var left_z:=int(editor_plants[left].get("z_index",left));var right_z:=int(editor_plants[right].get("z_index",right))
		return left>right if left_z==right_z else left_z>right_z)
	for index in order:
		var plant:Dictionary=editor_plants[index];var entry:=_species_entry(str(plant.get("species_id","")))
		var label:="株%d　%s　（重なり %d）"%[index+1,str(entry.get("name_ja","多肉")),int(plant.get("z_index",index))]
		var button:=_button(label,Vector2.ZERO,Vector2(414,54),Color("#f0d7aa") if index==selected_plant_index else Color("#b99369"),15);button.pressed.connect(_select_from_layer_list.bind(index));layer_list.add_child(button)

func _select_from_layer_list(index:int)->void:
	layer_panel.visible=false;_select_plant(index);editor_message.text="株一覧から選択しました"

func _delete_selected_plant()->void:
	if selected_plant_index<0 or selected_plant_index>=editor_plants.size():return
	editor_plants.remove_at(selected_plant_index);selected_plant_index=-1;editor_message.text="株を削除しました";_rebuild_editor_scene()

func _change_editor_pot()->void:
	_reset_editor_gesture();pot_select_mode="edit";_show_page(pot_select_page);_refresh_pot_selection()

func _return_home_from_editor()->void:
	_reset_editor_gesture();_show_page(home_page);_refresh_home()

func _build_picker_page()->void:
	_build_header(picker_page,"多肉を選ぶ",_return_to_editor,"編集へ")
	picker_filter=OptionButton.new();picker_filter.position=Vector2(145,91);picker_filter.size=Vector2(286,52);picker_filter.add_theme_font_size_override("font_size",17);picker_filter.item_selected.connect(_on_picker_filter_changed);picker_page.add_child(picker_filter)
	var hint:=Label.new();hint.text="図鑑登録済みの品種は何度でも使えます";hint.position=Vector2(26,151);hint.size=Vector2(524,32);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_font_size_override("font_size",15);hint.add_theme_color_override("font_color",Color("#efd49d"));picker_page.add_child(hint)
	var scroll:=ScrollContainer.new();scroll.position=Vector2(24,194);scroll.size=Vector2(528,790);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;picker_page.add_child(scroll)
	picker_grid=GridContainer.new();picker_grid.columns=2;picker_grid.custom_minimum_size=Vector2(510,0);picker_grid.add_theme_constant_override("h_separation",10);picker_grid.add_theme_constant_override("v_separation",10);scroll.add_child(picker_grid)

func _open_species_picker()->void:
	if editor_plants.size()>=MAX_PLANTS_PER_ARRANGEMENT:editor_message.text="1作品には最大%d株まで置けます"%MAX_PLANTS_PER_ARRANGEMENT;return
	_reset_editor_gesture();_show_page(picker_page);_refresh_picker_filters();_refresh_species_picker()

func _refresh_picker_filters()->void:
	picker_filter.clear();picker_filter.add_item("すべて");picker_filter.set_item_metadata(0,"all")
	for series_value in series_catalog:
		if not series_value is Dictionary:continue
		var series:Dictionary=series_value;var series_id:=str(series.get("series_id",""))
		if _available_species_entries(series_id).is_empty():continue
		picker_filter.add_item(str(series.get("display_name",series_id)));picker_filter.set_item_metadata(picker_filter.item_count-1,series_id)
	picker_filter.select(0)

func _on_picker_filter_changed(_index:int)->void:
	_refresh_species_picker()

func _refresh_species_picker()->void:
	_clear_children(picker_grid)
	var filter_id:="all"
	if picker_filter.item_count>0:filter_id=str(picker_filter.get_item_metadata(picker_filter.selected))
	var available:=_available_species_entries(filter_id)
	if available.is_empty():
		var empty:=Label.new();empty.text="このシリーズには、まだ使える多肉がありません";empty.custom_minimum_size=Vector2(500,100);empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;empty.add_theme_color_override("font_color",UI_CREAM);picker_grid.add_child(empty);return
	for entry in available:
		var species_id:=str(entry.get("species_id",""));var texture:=_resolve_texture(entry)
		var card:=Button.new();card.custom_minimum_size=Vector2(248,150);_skin_button(card,Color("#f4e1bc"),15);card.disabled=texture==null;picker_grid.add_child(card)
		var image_frame:=Control.new();image_frame.position=Vector2(8,12);image_frame.size=Vector2(112,112);image_frame.clip_contents=true;image_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(image_frame)
		var image:=TextureRect.new();image.texture=texture;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;image_frame.add_child(image)
		var label:=Label.new();label.text=str(entry.get("name_ja","多肉"))+("\n画像準備中" if texture==null else "\n追加する");label.position=Vector2(121,18);label.size=Vector2(117,112);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",14);label.add_theme_color_override("font_color",UI_BROWN);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(label)
		if texture!=null:card.pressed.connect(_add_species_to_editor.bind(species_id))

func _available_species_entries(series_id:String="all")->Array[Dictionary]:
	var allowed_ids:Dictionary={}
	if series_id!="all":
		for series_value in series_catalog:
			if series_value is Dictionary and str(series_value.get("series_id",""))==series_id:
				for species_id_value in series_value.get("species_ids",[]):allowed_ids[str(species_id_value)]=true
				break
	var entries:Array[Dictionary]=[]
	for entry_value in catalog_species:
		if not entry_value is Dictionary:continue
		var entry:Dictionary=entry_value;var species_id:=str(entry.get("species_id",""))
		if not bool(discovered.get(species_id,false)):continue
		if series_id!="all" and not allowed_ids.has(species_id):continue
		entries.append(entry)
	return entries

func _add_species_to_editor(species_id:String)->void:
	if editor_plants.size()>=MAX_PLANTS_PER_ARRANGEMENT or not bool(discovered.get(species_id,false)):return
	var entry:=_species_entry(species_id)
	if entry.is_empty() or _resolve_texture(entry)==null:return
	var pot:=_pot_entry(str(current_arrangement.get("pot_id","")));var allowed:=_placement_rect(pot,editor_canvas.size);var index:=editor_plants.size();var column:=(index%5)-2;var row:=int(index/5)%4
	var center:=Vector2(allowed.get_center().x+column*34.0,allowed.end.y-48.0-row*27.0)
	center.x=clampf(center.x,allowed.position.x,allowed.end.x);center.y=clampf(center.y,allowed.position.y,allowed.end.y)
	editor_plants.append({"species_id":species_id,"x":center.x,"y":center.y,"scale":1.0,"rotation":0.0,"flipped":false,"z_index":index})
	_show_page(editor_page);_rebuild_editor_scene();_select_plant(editor_plants.size()-1);editor_message.text="%sを追加しました"%str(entry.get("name_ja","多肉"))

func _return_to_editor()->void:
	_show_page(editor_page);_rebuild_editor_scene()

func _save_current_arrangement()->void:
	if current_arrangement.is_empty():return
	_reset_editor_gesture()
	var name:=editor_name.text.strip_edges()
	if name.is_empty():name=_default_arrangement_name();editor_name.text=name
	var saved:={"arrangement_id":str(current_arrangement.get("arrangement_id",_new_arrangement_id())),"name":name,"pot_id":str(current_arrangement.get("pot_id","starter_terracotta")),"created_at":str(current_arrangement.get("created_at",Time.get_datetime_string_from_system(false,true))),"plants":editor_plants.duplicate(true)}
	current_arrangement=saved.duplicate(true);save_requested.emit(saved.duplicate(true));_open_viewer(saved)

func _edit_arrangement(arrangement:Dictionary)->void:
	current_arrangement=arrangement.duplicate(true);_show_page(editor_page);_load_editor_from_current()

func _build_viewer_page()->void:
	_build_header(viewer_page,"完成した寄せ植え",_return_from_viewer)
	var edit:=_button("編集",Vector2(458,24),Vector2(98,54),Color("#d7aa64"),16);edit.pressed.connect(_edit_viewed_arrangement);viewer_page.add_child(edit)
	viewer_name=Label.new();viewer_name.position=Vector2(30,90);viewer_name.size=Vector2(516,48);viewer_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;viewer_name.add_theme_font_size_override("font_size",24);viewer_name.add_theme_color_override("font_color",Color("#f5d48c"));viewer_page.add_child(viewer_name)
	viewer_canvas=Panel.new();viewer_canvas.position=Vector2(20,150);viewer_canvas.size=Vector2(536,552);viewer_canvas.clip_contents=false;viewer_canvas.add_theme_stylebox_override("panel",_box(Color("#f8e9c9"),Color("#c58b50"),24,4));viewer_page.add_child(viewer_canvas)
	viewer_pot_layer=Control.new();viewer_pot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);viewer_pot_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewer_canvas.add_child(viewer_pot_layer)
	viewer_plant_layer=Control.new();viewer_plant_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);viewer_plant_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewer_canvas.add_child(viewer_plant_layer)
	var note:=Label.new();note.text="完成作品では編集用の枠を表示しません";note.position=Vector2(30,728);note.size=Vector2(516,34);note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;note.add_theme_font_size_override("font_size",16);note.add_theme_color_override("font_color",Color("#e8cfaa"));viewer_page.add_child(note)

func _open_viewer(arrangement:Dictionary)->void:
	current_arrangement=arrangement.duplicate(true);viewer_name.text=str(arrangement.get("name","寄せ植え"));_show_page(viewer_page);_render_readonly_arrangement(arrangement)

func _render_readonly_arrangement(arrangement:Dictionary)->void:
	_clear_children(viewer_pot_layer);_clear_children(viewer_plant_layer)
	var pot:=_pot_entry(str(arrangement.get("pot_id","")));var holder:=Control.new();holder.position=Vector2(52,294);holder.size=Vector2(432,244);holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewer_pot_layer.add_child(holder);_render_pot(holder,pot,false)
	for plant_value in _plant_array(arrangement):
		if not plant_value is Dictionary:continue
		var plant:Dictionary=plant_value;var texture:=_resolve_texture(_species_entry(str(plant.get("species_id",""))))
		if texture==null:continue
		var root:=Control.new();root.size=PLANT_CONTROL_SIZE;root.pivot_offset=PLANT_CONTROL_SIZE*.5;root.position=Vector2(float(plant.get("x",0.0)),float(plant.get("y",0.0)))-PLANT_CONTROL_SIZE*.5;root.scale=Vector2.ONE*clampf(float(plant.get("scale",1.0)),PLANT_SCALE_MIN,PLANT_SCALE_MAX);root.rotation_degrees=fposmod(float(plant.get("rotation",0.0)),360.0);root.z_index=int(plant.get("z_index",0));root.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewer_plant_layer.add_child(root)
		var image:=TextureRect.new();image.texture=texture;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.pivot_offset=PLANT_CONTROL_SIZE*.5;image.scale=Vector2(-1,1) if bool(plant.get("flipped",false)) else Vector2.ONE;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(image)

func _return_from_viewer()->void:
	_show_page(home_page);_refresh_home()

func _edit_viewed_arrangement()->void:
	_edit_arrangement(current_arrangement)

func _build_shop_page()->void:
	_build_header(shop_page,"寄せ植え用の鉢",close)
	shop_wallet=Label.new();shop_wallet.position=Vector2(30,92);shop_wallet.size=Vector2(516,38);shop_wallet.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_wallet.add_theme_font_size_override("font_size",20);shop_wallet.add_theme_color_override("font_color",Color("#f5d36d"));shop_page.add_child(shop_wallet)
	shop_message=Label.new();shop_message.position=Vector2(30,132);shop_message.size=Vector2(516,52);shop_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;shop_message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;shop_message.add_theme_font_size_override("font_size",16);shop_message.add_theme_color_override("font_color",UI_CREAM);shop_page.add_child(shop_message)
	var scroll:=ScrollContainer.new();scroll.position=Vector2(26,194);scroll.size=Vector2(524,790);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;shop_page.add_child(scroll)
	shop_grid=VBoxContainer.new();shop_grid.custom_minimum_size=Vector2(504,0);shop_grid.add_theme_constant_override("separation",14);scroll.add_child(shop_grid)

func _refresh_pot_shop()->void:
	shop_wallet.text="所持金　¥%s"%_comma(wallet_coins)
	if shop_message.text.is_empty():shop_message.text="鉢は一度購入すると、何作品でも使えます"
	_refresh_pot_shop_cards()

func _refresh_pot_shop_cards()->void:
	_clear_children(shop_grid)
	for pot_value in pot_catalog:
		if not pot_value is Dictionary:continue
		var pot:Dictionary=pot_value;var pot_id:=str(pot.get("pot_id",""));var owned:=bool(owned_pots.get(pot_id,false));var price:=maxi(0,int(pot.get("price",0)))
		var card:=PanelContainer.new();card.custom_minimum_size=Vector2(504,204);card.add_theme_stylebox_override("panel",_box(Color("#f4e1bc"),Color("#b77c48"),20,3));shop_grid.add_child(card)
		var content:=Control.new();content.custom_minimum_size=Vector2(484,184);card.add_child(content)
		var preview:=Control.new();preview.position=Vector2(2,2);preview.size=Vector2(214,176);preview.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(preview);_render_pot(preview,pot,true)
		var name:=Label.new();name.text=str(pot.get("display_name","鉢"));name.position=Vector2(220,12);name.size=Vector2(258,45);name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name.add_theme_font_size_override("font_size",19);name.add_theme_color_override("font_color",UI_BROWN);content.add_child(name)
		var condition:=Label.new();condition.text=str(pot.get("unlock_condition",{}).get("display_text",""));condition.position=Vector2(220,55);condition.size=Vector2(258,34);condition.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;condition.add_theme_font_size_override("font_size",13);condition.add_theme_color_override("font_color",Color("#79543a"));content.add_child(condition)
		var buy:=_button("購入済み" if owned else ("買う　¥%s"%_comma(price)),Vector2(248,102),Vector2(204,58),Color("#b9a17d") if owned else Color("#d7aa64"),17);buy.disabled=owned or wallet_coins<price;buy.pressed.connect(_request_pot_purchase.bind(pot_id));content.add_child(buy)

func _request_pot_purchase(pot_id:String)->void:
	pot_purchase_requested.emit(pot_id)

func _render_pot(container:Control,pot:Dictionary,compact:bool)->void:
	_clear_children(container)
	var path:=str(pot.get("image_path",""))
	if not path.is_empty() and ResourceLoader.exists(path):
		var image:=TextureRect.new();image.texture=load(path) as Texture2D;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;container.add_child(image)
	else:
		var placeholder:=PotPlaceholderClass.new();placeholder.display_name=str(pot.get("display_name","鉢")) if not compact else "鉢画像 準備中";placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);placeholder.mouse_filter=Control.MOUSE_FILTER_IGNORE;container.add_child(placeholder)

func _placement_rect(pot:Dictionary,canvas_size:Vector2)->Rect2:
	var area=pot.get("placement_area",{})
	if not area is Dictionary:return Rect2(canvas_size*Vector2(.08,.12),canvas_size*Vector2(.84,.60))
	return Rect2(Vector2(float(area.get("x",.08))*canvas_size.x,float(area.get("y",.12))*canvas_size.y),Vector2(float(area.get("width",.84))*canvas_size.x,float(area.get("height",.60))*canvas_size.y))

func _pot_entry(pot_id:String)->Dictionary:
	for value in pot_catalog:
		if value is Dictionary and str(value.get("pot_id",""))==pot_id:return value
	return {}

func _pot_name(pot_id:String)->String:
	return str(_pot_entry(pot_id).get("display_name","鉢"))

func _species_entry(species_id:String)->Dictionary:
	for value in catalog_species:
		if value is Dictionary and str(value.get("species_id",""))==species_id:return value
	return {}

func _resolve_texture(entry:Dictionary)->Texture2D:
	if entry.is_empty() or not texture_resolver.is_valid():return null
	return texture_resolver.call(entry) as Texture2D

func _plant_array(arrangement:Dictionary)->Array:
	var value=arrangement.get("plants",[])
	return value if value is Array else []

func _owned_pot_count()->int:
	var count:=0
	for pot_value in pot_catalog:
		if pot_value is Dictionary and bool(owned_pots.get(str(pot_value.get("pot_id","")),false)):count+=1
	return count

func _default_arrangement_name()->String:
	return "寄せ植え %d"%(saved_arrangements.size()+1)

func _new_arrangement_id()->String:
	return "arrangement_%d_%d"%[Time.get_unix_time_from_system(),Time.get_ticks_msec()%100000]

func _clear_children(node:Node)->void:
	for child in node.get_children():child.free()

func _button(text_value:String,position_value:Vector2,size_value:Vector2,color:Color,font_size:int)->Button:
	var button:=Button.new();button.text=text_value;button.position=position_value;button.size=size_value;button.custom_minimum_size=size_value;button.focus_mode=Control.FOCUS_NONE;_skin_button(button,color,font_size);return button

func _skin_button(button:Button,bg:Color,font_size:int)->void:
	button.add_theme_font_size_override("font_size",font_size);button.add_theme_color_override("font_color",UI_BROWN if bg.get_luminance()>.55 else Color.WHITE);button.add_theme_color_override("font_disabled_color",Color("#c9b7a3"));button.add_theme_stylebox_override("normal",_box(bg,bg.lightened(.18),18,3));button.add_theme_stylebox_override("hover",_box(bg.lightened(.07),Color.WHITE,18,3));button.add_theme_stylebox_override("pressed",_box(bg.darkened(.08),bg.lightened(.18),18,3));button.add_theme_stylebox_override("disabled",_box(bg.darkened(.32),bg.darkened(.18),18,2))

func _box(bg:Color,border:Color,radius:int,width:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius);style.content_margin_left=10;style.content_margin_right=10;style.content_margin_top=7;style.content_margin_bottom=7;style.shadow_color=Color(0.15,.07,.03,.28);style.shadow_size=5;style.shadow_offset=Vector2(0,3);return style

func _comma(value:int)->String:
	var source:=str(value);var result:="";var count:=0
	for index in range(source.length()-1,-1,-1):
		if count>0 and count%3==0:result=","+result
		result=source[index]+result;count+=1
	return result
