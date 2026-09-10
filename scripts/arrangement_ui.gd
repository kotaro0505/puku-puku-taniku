class_name ArrangementUI
extends Control

signal close_requested(context:String)
signal save_requested(arrangement:Dictionary)
signal pot_purchase_requested(pot_id:String)
signal catalog_purchase_requested(series_id:String)
signal seed_purchase_requested(seed_type:String)
signal world_scroll_input(event:InputEvent)
signal completion_confetti_requested(layer:Control)

const PotPlaceholderClass = preload("res://scripts/arrangement_pot_placeholder.gd")
const MAX_PLANTS_PER_ARRANGEMENT := 24
const PLANT_CONTROL_SIZE := Vector2(150,150)
const PLANT_SCALE_MIN := 0.45
const PLANT_SCALE_MAX := 1.80
const PLANT_SCALE_STEP := 0.10
const PLANT_ROTATION_STEP := 15.0
const PLANT_GESTURE_MOVE_THRESHOLD := 12.0
const ARRANGEMENT_CANVAS_POSITION := Vector2(20,150)
const POT_VERTICAL_OFFSET := 62.0
const PLANT_LAYER_Z := 200
const COMPLETION_DISPLAY_SECONDS := 1.65
const DEFAULT_POT_ID := "shallow_terracotta"
const UI_CREAM := Color("#fff1d2")
const UI_BROWN := Color("#4a2618")

var catalog_species:Array=[]
var series_catalog:Array=[]
var pot_catalog:Array=[]
var discovered:Dictionary={}
var owned_pots:Dictionary={}
var owned_catalogs:Dictionary={"base":true}
var wallet_puku_points:=0
var seed_shop_products:Array=[]
var saved_arrangements:Array=[]
var save_capacity:=20
var texture_resolver:Callable
var texture_requester:Callable
var return_context:="greenhouse"
var world_backdrop_enabled:=false
var world_pot_anchor_screen:=Vector2(288,630)

var backdrop_shade:ColorRect
var home_page:Control
var home_summary:Label
var home_list:VBoxContainer
var home_new_button:Button
var pot_select_page:Control
var pot_select_grid:GridContainer
var editor_page:Control
var editor_name:LineEdit
var editor_canvas:Panel
var editor_pot_layer:Control
var editor_plant_layer:Control
var editor_message:Label
var editor_selection_label:Label
var add_plant_button:Button
var selected_controls:Array[Button]=[]
var picker_page:Control
var picker_filter:OptionButton
var picker_scroll:ScrollContainer
var picker_grid:GridContainer
var viewer_page:Control
var viewer_name:Label
var viewer_canvas:Panel
var viewer_pot_layer:Control
var viewer_plant_layer:Control
var completion_overlay:Control
var completion_confetti_layer:Control
var completion_label:Label
var shop_page:Control
var shop_wallet:Label
var shop_message:Label
var shop_grid:VBoxContainer
var catalog_shop_page:Control
var catalog_shop_wallet:Label
var catalog_shop_message:Label
var catalog_shop_grid:VBoxContainer
var seed_shop_page:Control
var seed_shop_wallet:Label
var seed_shop_message:Label
var seed_shop_grid:VBoxContainer

var current_arrangement:Dictionary={}
var editor_plants:Array=[]
var editor_plant_nodes:Array=[]
var selected_plant_index:=-1
var drag_active:=false
var drag_pointer_offset:=Vector2.ZERO
var drag_pointer_id:=-999
var touch_positions:Dictionary={}
var pinch_active:=false
var pinch_touch_ids:Array[int]=[]
var pinch_start_distance:=1.0
var pinch_start_scale:=1.0
var pinch_start_angle:=0.0
var pinch_start_rotation:=0.0
var pinch_target_index:=-1
var background_gesture_pointer:=-999
var background_press_event:InputEvent
var background_start_position:=Vector2.ZERO
var background_forwarded:=false
var plant_selection_shader:Shader

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	visible=false
	plant_selection_shader=Shader.new()
	plant_selection_shader.code="""
shader_type canvas_item;
uniform float selected : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * 2.0;
	float nearby = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	nearby = max(nearby, texture(TEXTURE, UV - vec2(px.x, 0.0)).a);
	nearby = max(nearby, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
	nearby = max(nearby, texture(TEXTURE, UV - vec2(0.0, px.y)).a);
	nearby = max(nearby, texture(TEXTURE, UV + px).a);
	nearby = max(nearby, texture(TEXTURE, UV - px).a);
	float halo = max(nearby - base.a, 0.0) * selected;
	vec3 cool_glow = vec3(0.70, 0.93, 1.0);
	COLOR = vec4(mix(base.rgb, cool_glow, halo * 0.48), max(base.a, halo * 0.32));
}
"""
	_build_ui()

func configure(species_data:Array,series_data:Array,pots_data:Array,discovery:Dictionary,purchased_pots:Dictionary,arrangements:Array,capacity:int,puku_points:int,resolver:Callable,requester:Callable=Callable())->void:
	catalog_species=species_data
	series_catalog=series_data
	pot_catalog=pots_data
	discovered=discovery
	owned_pots=purchased_pots
	saved_arrangements=arrangements
	save_capacity=maxi(1,capacity)
	wallet_puku_points=maxi(0,puku_points)
	texture_resolver=resolver
	texture_requester=requester

func sync_state(purchased_pots:Dictionary,arrangements:Array,capacity:int)->void:
	owned_pots=purchased_pots;saved_arrangements=arrangements;save_capacity=maxi(1,capacity)
	if visible and shop_page.visible:_refresh_pot_shop()
	if visible and home_page.visible:_refresh_home()
	if visible and pot_select_page.visible:_refresh_pot_selection()

func sync_catalog_state(purchased_catalogs:Dictionary,puku_points:int)->void:
	owned_catalogs=purchased_catalogs;wallet_puku_points=maxi(0,puku_points)
	if visible and catalog_shop_page.visible:_refresh_catalog_shop()

func sync_seed_shop_state(products:Array,puku_points:int)->void:
	seed_shop_products=products;wallet_puku_points=maxi(0,puku_points)
	if visible and seed_shop_page.visible:_refresh_seed_shop()

func open_home()->void:
	return_context="greenhouse";visible=true;_show_page(home_page);_refresh_home()

func open_pot_shop()->void:
	set_world_backdrop_mode(false,world_pot_anchor_screen);return_context="shop";visible=true;_show_page(shop_page);_refresh_pot_shop()

func open_catalog_shop()->void:
	set_world_backdrop_mode(false,world_pot_anchor_screen);return_context="shop";visible=true;_show_page(catalog_shop_page);_refresh_catalog_shop()

func open_seed_shop()->void:
	set_world_backdrop_mode(false,world_pot_anchor_screen);return_context="shop";visible=true;_show_page(seed_shop_page);_refresh_seed_shop()

func close()->void:
	_cancel_editor_gesture();_clear_completion_overlay();visible=false;close_requested.emit(return_context)

func show_pot_shop_message(message:String)->void:
	shop_message.text=message;_refresh_pot_shop_cards()

func show_catalog_shop_message(message:String)->void:
	catalog_shop_message.text=message;_refresh_catalog_shop()

func show_seed_shop_message(message:String)->void:
	seed_shop_message.text=message;_refresh_seed_shop()

func set_world_backdrop_mode(enabled:bool,pot_anchor_screen:Vector2)->void:
	var changed:=world_backdrop_enabled!=enabled or not world_pot_anchor_screen.is_equal_approx(pot_anchor_screen)
	world_backdrop_enabled=enabled;world_pot_anchor_screen=pot_anchor_screen
	if backdrop_shade==null:return
	backdrop_shade.color=Color(0.16,0.09,0.05,.22) if enabled else Color("#43281f")
	if editor_canvas:
		editor_canvas.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	if viewer_canvas:
		viewer_canvas.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	if changed and visible and editor_page and editor_page.visible and not current_arrangement.is_empty():_rebuild_editor_scene()
	if changed and visible and viewer_page and viewer_page.visible and not current_arrangement.is_empty():_render_readonly_arrangement(current_arrangement)

func _build_ui()->void:
	backdrop_shade=ColorRect.new();backdrop_shade.color=Color("#43281f");backdrop_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop_shade.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(backdrop_shade)
	home_page=_page();home_page.gui_input.connect(_on_home_world_scroll_input);_build_home_page()
	pot_select_page=_page();_build_pot_select_page()
	editor_page=_page();_build_editor_page()
	picker_page=_page();_build_picker_page()
	viewer_page=_page();_build_viewer_page()
	shop_page=_page();_build_shop_page()
	catalog_shop_page=_page();_build_catalog_shop_page()
	seed_shop_page=_page();_build_seed_shop_page()
	_build_completion_overlay()

func _build_completion_overlay()->void:
	completion_overlay=Control.new();completion_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);completion_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;completion_overlay.visible=false;add_child(completion_overlay)
	completion_confetti_layer=Control.new();completion_confetti_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);completion_confetti_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;completion_overlay.add_child(completion_confetti_layer)
	completion_label=Label.new();completion_label.text="寄せ植え完成！";completion_label.position=Vector2(48,326);completion_label.size=Vector2(480,92);completion_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;completion_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;completion_label.add_theme_font_size_override("font_size",38);completion_label.add_theme_color_override("font_color",Color("#fff1c8"));completion_label.add_theme_color_override("font_outline_color",Color("#61351f"));completion_label.add_theme_constant_override("outline_size",8);completion_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;completion_overlay.add_child(completion_label)

func _clear_completion_overlay()->void:
	if completion_overlay:completion_overlay.visible=false
	if completion_confetti_layer:
		for child in completion_confetti_layer.get_children():child.queue_free()

func _page()->Control:
	var page:=Control.new();page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);page.mouse_filter=Control.MOUSE_FILTER_STOP;page.visible=false;add_child(page);return page

func _show_page(page:Control)->void:
	if editor_page and editor_page.visible and page!=editor_page:_cancel_editor_gesture()
	for candidate in [home_page,pot_select_page,editor_page,picker_page,viewer_page,shop_page,catalog_shop_page,seed_shop_page]:
		if candidate:candidate.visible=candidate==page

func is_editor_active()->bool:
	return visible and editor_page!=null and editor_page.visible

func _on_home_world_scroll_input(event:InputEvent)->void:
	if world_backdrop_enabled and visible and home_page.visible:world_scroll_input.emit(event)

func _build_header(page:Control,title_text:String,back_callable:Callable,back_text:="もどる")->Label:
	var header_panel:=Panel.new();header_panel.position=Vector2(8,10);header_panel.size=Vector2(560,72);header_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;header_panel.add_theme_stylebox_override("panel",_box(Color(0.18,0.09,0.045,.72),Color(1.0,.82,.53,.32),22,1));page.add_child(header_panel)
	var back:=_button(back_text,Vector2(20,24),Vector2(108,54),Color("#f4dfb8"),16);back.pressed.connect(back_callable);page.add_child(back)
	var title:=Label.new();title.text=title_text;title.position=Vector2(132,25);title.size=Vector2(312,52);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",27);_style_overlay_label(title);page.add_child(title)
	return title

func _build_home_page()->void:
	_build_header(home_page,"寄せ植え",close)
	home_summary=Label.new();home_summary.position=Vector2(32,93);home_summary.size=Vector2(512,42);home_summary.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;home_summary.add_theme_font_size_override("font_size",18);_style_overlay_label(home_summary,Color("#ffe0a0"),4);home_page.add_child(home_summary)
	home_new_button=_button("＋ 新しく作る",Vector2(118,146),Vector2(340,64),Color("#d7aa64"),22);home_new_button.pressed.connect(_start_new_arrangement);home_page.add_child(home_new_button)
	var saved_title:=Label.new();saved_title.text="保存した寄せ植え";saved_title.position=Vector2(32,232);saved_title.size=Vector2(512,36);saved_title.add_theme_font_size_override("font_size",21);_style_overlay_label(saved_title);home_page.add_child(saved_title)
	var scroll:=ScrollContainer.new();scroll.position=Vector2(28,278);scroll.size=Vector2(520,706);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;home_page.add_child(scroll)
	home_list=VBoxContainer.new();home_list.custom_minimum_size=Vector2(500,0);home_list.add_theme_constant_override("separation",12);scroll.add_child(home_list)

func _refresh_home()->void:
	_clear_children(home_list)
	home_summary.text="%d / %d作品　・　購入済みの鉢 %d個"%[saved_arrangements.size(),save_capacity,_owned_pot_count()]
	home_new_button.disabled=saved_arrangements.size()>=save_capacity
	if saved_arrangements.is_empty():
		var empty:=Label.new();empty.text="まだ作品はありません。\n図鑑登録した多肉で、最初の寄せ植えを作ってみよう。";empty.custom_minimum_size=Vector2(500,140);empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;empty.add_theme_font_size_override("font_size",18);_style_overlay_label(empty,Color("#f8deb5"),4);home_list.add_child(empty);return
	for arrangement_value in saved_arrangements:
		if not arrangement_value is Dictionary:continue
		var arrangement:Dictionary=arrangement_value
		var card:=PanelContainer.new();card.custom_minimum_size=Vector2(500,104);card.add_theme_stylebox_override("panel",_box(Color("#f4e1bc"),Color("#b77c48"),20,3));home_list.add_child(card)
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);card.add_child(row)
		var info:=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(info)
		var name_label:=Label.new();name_label.text=str(arrangement.get("name","寄せ植え"));name_label.add_theme_font_size_override("font_size",20);name_label.add_theme_color_override("font_color",UI_BROWN);info.add_child(name_label)
		var pot_label:=Label.new();pot_label.text="%s　・　%d株"%[_pot_name(str(arrangement.get("pot_id",""))),_plant_array(arrangement).size()];pot_label.add_theme_font_size_override("font_size",14);pot_label.add_theme_color_override("font_color",Color("#79543a"));info.add_child(pot_label)
		var view:=_button("見る",Vector2.ZERO,Vector2(112,56),Color("#ead4a5"),15);view.pressed.connect(_open_viewer.bind(arrangement));row.add_child(view)

func _build_pot_select_page()->void:
	_build_header(pot_select_page,"鉢を選ぶ",_return_from_pot_selection)
	var hint:=Label.new();hint.text="購入済みの鉢から選んでください";hint.position=Vector2(30,91);hint.size=Vector2(516,38);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_font_size_override("font_size",17);_style_overlay_label(hint,Color("#ffe0a0"),4);pot_select_page.add_child(hint)
	var scroll:=ScrollContainer.new();scroll.position=Vector2(24,140);scroll.size=Vector2(528,840);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;pot_select_page.add_child(scroll)
	pot_select_grid=GridContainer.new();pot_select_grid.columns=2;pot_select_grid.custom_minimum_size=Vector2(510,0);pot_select_grid.add_theme_constant_override("h_separation",10);pot_select_grid.add_theme_constant_override("v_separation",12);scroll.add_child(pot_select_grid)

func _refresh_pot_selection()->void:
	_clear_children(pot_select_grid)
	for pot_value in pot_catalog:
		if not pot_value is Dictionary:continue
		var pot:Dictionary=pot_value;var pot_id:=str(pot.get("pot_id",""));var owned:=bool(owned_pots.get(pot_id,false))
		if not owned:continue
		var card:=Button.new();card.custom_minimum_size=Vector2(248,230);_skin_button(card,Color("#f4e1bc"),15);pot_select_grid.add_child(card)
		var preview:=Control.new();preview.position=Vector2(14,10);preview.size=Vector2(220,150);preview.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(preview);_render_pot(preview,pot,true)
		var label:=Label.new();label.text=str(pot.get("display_name","鉢"))+"\n選ぶ";label.position=Vector2(10,164);label.size=Vector2(228,56);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",16);label.add_theme_color_override("font_color",UI_BROWN);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(label)
		card.pressed.connect(_select_editor_pot.bind(pot_id))

func _start_new_arrangement()->void:
	if saved_arrangements.size()>=save_capacity:return
	current_arrangement={};editor_plants.clear();selected_plant_index=-1;_show_page(pot_select_page);_refresh_pot_selection()

func _return_from_pot_selection()->void:
	_show_page(home_page);_refresh_home()

func _select_editor_pot(pot_id:String)->void:
	if not bool(owned_pots.get(pot_id,false)):return
	current_arrangement={"arrangement_id":_new_arrangement_id(),"name":_default_arrangement_name(),"pot_id":pot_id,"created_at":Time.get_datetime_string_from_system(false,true),"completed":false,"plants":[]}
	_show_page(editor_page);_load_editor_from_current()

func _build_editor_page()->void:
	var header_panel:=Panel.new();header_panel.position=Vector2(8,10);header_panel.size=Vector2(560,72);header_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;header_panel.add_theme_stylebox_override("panel",_box(Color(0.18,0.09,0.045,.72),Color(1.0,.82,.53,.32),22,1));editor_page.add_child(header_panel)
	var back:=_button("もどる",Vector2(18,20),Vector2(98,50),Color("#f4dfb8"),15);back.pressed.connect(_return_home_from_editor);editor_page.add_child(back)
	editor_name=LineEdit.new();editor_name.placeholder_text="寄せ植えの名前";editor_name.position=Vector2(124,20);editor_name.size=Vector2(286,50);editor_name.add_theme_font_size_override("font_size",18);editor_name.add_theme_color_override("font_color",UI_BROWN);editor_name.add_theme_stylebox_override("normal",_box(Color("#fff3d8"),Color("#b47d49"),16,2));editor_page.add_child(editor_name)
	var save:=_button("完成",Vector2(418,20),Vector2(140,50),Color("#d7aa64"),15);save.pressed.connect(_save_current_arrangement);editor_page.add_child(save)
	editor_canvas=Panel.new();editor_canvas.position=ARRANGEMENT_CANVAS_POSITION;editor_canvas.size=Vector2(536,552);editor_canvas.clip_contents=false;editor_canvas.mouse_filter=Control.MOUSE_FILTER_STOP;editor_canvas.add_theme_stylebox_override("panel",StyleBoxEmpty.new());editor_canvas.gui_input.connect(_on_editor_canvas_gui_input);editor_page.add_child(editor_canvas)
	editor_pot_layer=Control.new();editor_pot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);editor_pot_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;editor_canvas.add_child(editor_pot_layer)
	editor_plant_layer=Control.new();editor_plant_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);editor_plant_layer.z_index=PLANT_LAYER_Z;editor_plant_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;editor_canvas.add_child(editor_plant_layer)
	var message_panel:=Panel.new();message_panel.position=Vector2(20,700);message_panel.size=Vector2(536,43);message_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;message_panel.add_theme_stylebox_override("panel",_box(Color(0.18,0.09,0.045,.66),Color(1.0,.82,.53,.24),15,1));editor_page.add_child(message_panel)
	editor_message=Label.new();editor_message.position=Vector2(28,705);editor_message.size=Vector2(520,33);editor_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;editor_message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;editor_message.add_theme_font_size_override("font_size",15);_style_overlay_label(editor_message,Color("#ffe2a5"),4);editor_page.add_child(editor_message)
	add_plant_button=_button("＋ 多肉を追加",Vector2(154,746),Vector2(268,58),Color("#d7aa64"),20);add_plant_button.pressed.connect(_open_species_picker);editor_page.add_child(add_plant_button)
	editor_selection_label=Label.new();editor_selection_label.visible=false;editor_page.add_child(editor_selection_label)
	var scale_minus:=_button("－",Vector2(28,812),Vector2(70,56),Color("#ead4a5"),22);scale_minus.pressed.connect(_adjust_selected_scale.bind(-PLANT_SCALE_STEP));editor_page.add_child(scale_minus);selected_controls.append(scale_minus)
	var scale_title:=Label.new();scale_title.text="大きさ";scale_title.position=Vector2(100,812);scale_title.size=Vector2(84,56);scale_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;scale_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;scale_title.add_theme_font_size_override("font_size",16);_style_overlay_label(scale_title);editor_page.add_child(scale_title)
	var scale_plus:=_button("＋",Vector2(186,812),Vector2(70,56),Color("#ead4a5"),22);scale_plus.pressed.connect(_adjust_selected_scale.bind(PLANT_SCALE_STEP));editor_page.add_child(scale_plus);selected_controls.append(scale_plus)
	var rotate_left:=_button("↶",Vector2(272,812),Vector2(70,56),Color("#ead4a5"),23);rotate_left.pressed.connect(_adjust_selected_rotation.bind(-PLANT_ROTATION_STEP));editor_page.add_child(rotate_left);selected_controls.append(rotate_left)
	var rotate_title:=Label.new();rotate_title.text="回転";rotate_title.position=Vector2(344,812);rotate_title.size=Vector2(84,56);rotate_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;rotate_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;rotate_title.add_theme_font_size_override("font_size",16);_style_overlay_label(rotate_title);editor_page.add_child(rotate_title)
	var rotate_right:=_button("↷",Vector2(430,812),Vector2(70,56),Color("#ead4a5"),23);rotate_right.pressed.connect(_adjust_selected_rotation.bind(PLANT_ROTATION_STEP));editor_page.add_child(rotate_right);selected_controls.append(rotate_right)
	var back_depth:=_button("奥へ",Vector2(42,876),Vector2(140,58),Color("#c8ae88"),17);back_depth.pressed.connect(_change_selected_depth.bind(-1));editor_page.add_child(back_depth);selected_controls.append(back_depth)
	var front_depth:=_button("手前へ",Vector2(218,876),Vector2(140,58),Color("#d7aa64"),17);front_depth.pressed.connect(_change_selected_depth.bind(1));editor_page.add_child(front_depth);selected_controls.append(front_depth)
	var delete:=_button("削除",Vector2(394,876),Vector2(140,58),Color("#b87962"),17);delete.pressed.connect(_delete_selected_plant);editor_page.add_child(delete);selected_controls.append(delete)

func _load_editor_from_current()->void:
	if bool(current_arrangement.get("completed",false)):_open_viewer(current_arrangement);return
	editor_name.text=str(current_arrangement.get("name",_default_arrangement_name()))
	editor_plants=_plant_array(current_arrangement).duplicate(true)
	_cancel_editor_gesture();selected_plant_index=-1;editor_message.text="タップで選択・ドラッグで移動・2本指で拡大縮小／回転";_rebuild_editor_scene()

func _rebuild_editor_scene()->void:
	_clear_children(editor_pot_layer);_clear_children(editor_plant_layer);editor_plant_nodes.clear()
	var pot:=_pot_entry(str(current_arrangement.get("pot_id","")));_render_editor_pot(pot)
	for index in range(editor_plants.size()):_create_editor_plant(index)
	_update_editor_selection();add_plant_button.disabled=editor_plants.size()>=MAX_PLANTS_PER_ARRANGEMENT

func _render_editor_pot(pot:Dictionary)->void:
	if pot.is_empty():return
	var holder:=Control.new();holder.size=Vector2(432,244);holder.position=_pot_holder_position(editor_canvas,holder.size);holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;editor_pot_layer.add_child(holder);_render_pot(holder,pot,false)

func _create_editor_plant(index:int)->void:
	var plant:Dictionary=editor_plants[index];var entry:=_species_entry(str(plant.get("species_id","")));var texture:=_resolve_texture(entry)
	if texture==null:editor_plant_nodes.append(null);return
	var root:=Control.new();root.size=PLANT_CONTROL_SIZE;root.pivot_offset=PLANT_CONTROL_SIZE*.5;root.position=Vector2(float(plant.get("x",editor_canvas.size.x*.5)),float(plant.get("y",editor_canvas.size.y*.42)))-PLANT_CONTROL_SIZE*.5;root.scale=Vector2.ONE*clampf(float(plant.get("scale",1.0)),PLANT_SCALE_MIN,PLANT_SCALE_MAX);root.rotation_degrees=fposmod(float(plant.get("rotation",0.0)),360.0);root.z_index=int(plant.get("z_index",index));root.mouse_filter=Control.MOUSE_FILTER_IGNORE;editor_plant_layer.add_child(root)
	var image:=TextureRect.new();image.name="PlantImage";image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);image.texture=texture;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var selection_material:=ShaderMaterial.new();selection_material.shader=plant_selection_shader;selection_material.set_shader_parameter("selected",0.0);image.material=selection_material;root.add_child(image);_request_texture(entry,image,true)
	editor_plant_nodes.append(root)

func _on_editor_canvas_gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:_begin_canvas_pointer(-1,event.position,event)
		else:_end_canvas_pointer(-1,event.position,event)
		accept_event()
	elif event is InputEventMouseMotion:
		_update_canvas_pointer(-1,event.position,event);accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			var is_first_touch:=touch_positions.is_empty()
			touch_positions[event.index]=event.position;_begin_canvas_pointer(event.index,event.position,event)
			if is_first_touch:pinch_target_index=selected_plant_index
		else:
			_end_canvas_pointer(event.index,event.position,event);touch_positions.erase(event.index)
			if touch_positions.is_empty():pinch_target_index=-1
		accept_event()
	elif event is InputEventScreenDrag:
		touch_positions[event.index]=event.position;_update_canvas_pointer(event.index,event.position,event);accept_event()

func _begin_canvas_pointer(pointer_id:int,pointer_position:Vector2,event:InputEvent)->void:
	if bool(current_arrangement.get("completed",false)):return
	if pointer_id>=0 and touch_positions.size()>=2 and (pinch_target_index>=0 or selected_plant_index>=0):
		if pinch_target_index>=0:_select_plant(pinch_target_index)
		_cancel_background_for_pinch()
		_begin_pinch()
		return
	var hit_index:=_plant_index_at(pointer_position)
	if hit_index>=0:
		_begin_plant_drag(hit_index,pointer_position,pointer_id)
		return
	background_gesture_pointer=pointer_id;background_press_event=event.duplicate();background_start_position=pointer_position;background_forwarded=false

func _update_canvas_pointer(pointer_id:int,pointer_position:Vector2,event:InputEvent)->void:
	if pinch_active:
		_update_pinch_transform()
		return
	if drag_active and drag_pointer_id==pointer_id:
		_drag_selected_to(pointer_position)
		return
	if background_gesture_pointer==pointer_id:
		# The editor owns every gesture inside the canvas. Empty-space drags must
		# never leak into the greenhouse horizontal navigation.
		return

func _end_canvas_pointer(pointer_id:int,_pointer_position:Vector2,event:InputEvent)->void:
	if pinch_active and pointer_id in pinch_touch_ids:
		pinch_active=false;pinch_touch_ids.clear();_finish_selected_gesture("大きさと向きを調整しました")
	elif drag_active and drag_pointer_id==pointer_id:_finish_selected_gesture("位置を調整しました")
	if background_gesture_pointer==pointer_id:
		if background_start_position.distance_to(_pointer_position)<PLANT_GESTURE_MOVE_THRESHOLD:selected_plant_index=-1;_update_editor_selection()
		_clear_background_pointer()

func _begin_plant_drag(index:int,pointer_position:Vector2,pointer_id:=-1)->void:
	_select_plant(index);drag_active=true;drag_pointer_id=pointer_id
	var plant:Dictionary=editor_plants[index];drag_pointer_offset=Vector2(float(plant.get("x",0.0)),float(plant.get("y",0.0)))-pointer_position

func _begin_pinch()->void:
	if selected_plant_index<0 or selected_plant_index>=editor_plants.size() or touch_positions.size()<2:return
	drag_active=false;drag_pointer_id=-999;pinch_active=true;pinch_touch_ids.clear()
	for pointer_value in touch_positions.keys():
		pinch_touch_ids.append(int(pointer_value))
		if pinch_touch_ids.size()>=2:break
	var first:Vector2=touch_positions.get(pinch_touch_ids[0],Vector2.ZERO);var second:Vector2=touch_positions.get(pinch_touch_ids[1],Vector2.ZERO)
	var gesture_vector:=second-first
	pinch_start_distance=maxf(gesture_vector.length(),1.0);pinch_start_angle=gesture_vector.angle();pinch_start_scale=float(editor_plants[selected_plant_index].get("scale",1.0));pinch_start_rotation=float(editor_plants[selected_plant_index].get("rotation",0.0));editor_message.text="2本指の動きに合わせて大きさと向きを調整できます"

func _update_pinch_transform()->void:
	if not pinch_active or pinch_touch_ids.size()<2 or selected_plant_index<0:return
	if not touch_positions.has(pinch_touch_ids[0]) or not touch_positions.has(pinch_touch_ids[1]):return
	var first:Vector2=touch_positions[pinch_touch_ids[0]];var second:Vector2=touch_positions[pinch_touch_ids[1]];var gesture_vector:=second-first;var distance:=maxf(gesture_vector.length(),1.0)
	var angle_delta:=wrapf(gesture_vector.angle()-pinch_start_angle,-PI,PI)
	var plant:Dictionary=editor_plants[selected_plant_index];plant["scale"]=clampf(pinch_start_scale*distance/pinch_start_distance,PLANT_SCALE_MIN,PLANT_SCALE_MAX);plant["rotation"]=fposmod(pinch_start_rotation+rad_to_deg(angle_delta),360.0);editor_plants[selected_plant_index]=plant;_apply_plant_transform(selected_plant_index)

func _update_pinch_scale()->void:
	# Kept as a compatibility hook for older smoke helpers and saved tooling.
	_update_pinch_transform()

func _finish_selected_gesture(message:String)->void:
	drag_active=false;drag_pointer_id=-999;pinch_active=false;pinch_touch_ids.clear();editor_message.text=message;_update_editor_selection()

func _clear_background_pointer()->void:
	background_gesture_pointer=-999;background_press_event=null;background_start_position=Vector2.ZERO;background_forwarded=false

func _cancel_background_for_pinch()->void:
	if background_forwarded and background_press_event:
		var release_event:=background_press_event.duplicate()
		if release_event is InputEventScreenTouch:
			(release_event as InputEventScreenTouch).pressed=false
			(release_event as InputEventScreenTouch).position=touch_positions.get(background_gesture_pointer,background_start_position)
		elif release_event is InputEventMouseButton:
			(release_event as InputEventMouseButton).pressed=false
			(release_event as InputEventMouseButton).position=background_start_position
		world_scroll_input.emit(release_event)
	_clear_background_pointer()

func _cancel_editor_gesture()->void:
	drag_active=false;drag_pointer_id=-999;pinch_active=false;pinch_touch_ids.clear();touch_positions.clear();pinch_target_index=-1;pinch_start_angle=0.0;pinch_start_rotation=0.0;_clear_background_pointer()

func _plant_index_at(canvas_position:Vector2)->int:
	var canvas_global:=editor_canvas.get_global_transform_with_canvas()*canvas_position;var selected_index:=-1;var selected_z:=-1000000
	for index in range(editor_plant_nodes.size()):
		var node=editor_plant_nodes[index]
		if not is_instance_valid(node):continue
		var local_position:Vector2=node.get_global_transform_with_canvas().affine_inverse()*canvas_global
		if Rect2(Vector2.ZERO,node.size).has_point(local_position) and node.z_index>=selected_z:selected_index=index;selected_z=node.z_index
	return selected_index

func _drag_selected_to(pointer_position:Vector2)->void:
	if selected_plant_index<0 or selected_plant_index>=editor_plants.size():return
	_move_selected_center(pointer_position+drag_pointer_offset)

func _move_selected_center(center:Vector2)->void:
	if bool(current_arrangement.get("completed",false)) or selected_plant_index<0 or selected_plant_index>=editor_plants.size():return
	var pot:=_pot_entry(str(current_arrangement.get("pot_id","")));var allowed:=_placement_rect(pot,editor_canvas.size)
	center.x=clampf(center.x,allowed.position.x,allowed.end.x);center.y=clampf(center.y,allowed.position.y,allowed.end.y)
	var plant:Dictionary=editor_plants[selected_plant_index];plant["x"]=center.x;plant["y"]=center.y;editor_plants[selected_plant_index]=plant;_apply_plant_transform(selected_plant_index)

func _select_plant(index:int,_move_ready:=false)->void:
	if index<0 or index>=editor_plants.size():return
	selected_plant_index=index;_update_editor_selection()

func _update_editor_selection()->void:
	for index in range(editor_plant_nodes.size()):
		var node=editor_plant_nodes[index]
		if is_instance_valid(node):
			var image:=node.get_node_or_null("PlantImage") as TextureRect
			if image and image.material is ShaderMaterial:(image.material as ShaderMaterial).set_shader_parameter("selected",1.0 if index==selected_plant_index else 0.0)
	var has_selection:=selected_plant_index>=0 and selected_plant_index<editor_plants.size()
	for control in selected_controls:control.disabled=not has_selection
	editor_selection_label.text=""

func _apply_plant_transform(index:int)->void:
	if index<0 or index>=editor_plant_nodes.size():return
	var node=editor_plant_nodes[index]
	if not is_instance_valid(node):return
	var plant:Dictionary=editor_plants[index];node.position=Vector2(float(plant.get("x",0.0)),float(plant.get("y",0.0)))-PLANT_CONTROL_SIZE*.5;node.scale=Vector2.ONE*clampf(float(plant.get("scale",1.0)),PLANT_SCALE_MIN,PLANT_SCALE_MAX);node.rotation_degrees=fposmod(float(plant.get("rotation",0.0)),360.0);node.z_index=int(plant.get("z_index",index));_update_editor_selection()

func _adjust_selected_scale(amount:float)->void:
	if bool(current_arrangement.get("completed",false)) or selected_plant_index<0:return
	var plant:Dictionary=editor_plants[selected_plant_index];plant["scale"]=snappedf(clampf(float(plant.get("scale",1.0))+amount,PLANT_SCALE_MIN,PLANT_SCALE_MAX),.01);editor_plants[selected_plant_index]=plant;_apply_plant_transform(selected_plant_index)

func _adjust_selected_rotation(amount:float)->void:
	if bool(current_arrangement.get("completed",false)) or selected_plant_index<0:return
	var plant:Dictionary=editor_plants[selected_plant_index];plant["rotation"]=fposmod(float(plant.get("rotation",0.0))+amount,360.0);editor_plants[selected_plant_index]=plant;_apply_plant_transform(selected_plant_index)

func _change_selected_depth(direction:int)->void:
	if bool(current_arrangement.get("completed",false)) or selected_plant_index<0 or editor_plants.size()<2:return
	var order:Array[int]=[]
	for index in range(editor_plants.size()):order.append(index)
	order.sort_custom(func(first:int,second:int)->bool:
		var first_z:=int(editor_plants[first].get("z_index",first));var second_z:=int(editor_plants[second].get("z_index",second))
		return first_z<second_z if first_z!=second_z else first<second)
	for rank in range(order.size()):
		var ranked:Dictionary=editor_plants[order[rank]];ranked["z_index"]=rank;editor_plants[order[rank]]=ranked
	var current_rank:=order.find(selected_plant_index);var target_rank:=clampi(current_rank+signi(direction),0,order.size()-1)
	if current_rank==target_rank:
		for index in range(editor_plants.size()):_apply_plant_transform(index)
		return
	var target_index:=order[target_rank];var selected:Dictionary=editor_plants[selected_plant_index];var target:Dictionary=editor_plants[target_index];var selected_z:=int(selected.get("z_index",current_rank));selected["z_index"]=int(target.get("z_index",target_rank));target["z_index"]=selected_z;editor_plants[selected_plant_index]=selected;editor_plants[target_index]=target
	_apply_plant_transform(target_index);_apply_plant_transform(selected_plant_index)

func _delete_selected_plant()->void:
	if bool(current_arrangement.get("completed",false)) or selected_plant_index<0 or selected_plant_index>=editor_plants.size():return
	editor_plants.remove_at(selected_plant_index);selected_plant_index=-1;editor_message.text="株を削除しました";_rebuild_editor_scene()

func _return_home_from_editor()->void:
	drag_active=false;_show_page(home_page);_refresh_home()

func _build_picker_page()->void:
	_build_header(picker_page,"多肉を選ぶ",_return_to_editor,"編集へ")
	picker_filter=OptionButton.new();picker_filter.position=Vector2(145,91);picker_filter.size=Vector2(286,52);picker_filter.add_theme_font_size_override("font_size",17);picker_filter.item_selected.connect(_on_picker_filter_changed);picker_page.add_child(picker_filter)
	var hint:=Label.new();hint.text="図鑑登録済みの品種は何度でも使えます";hint.position=Vector2(26,151);hint.size=Vector2(524,32);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_font_size_override("font_size",15);_style_overlay_label(hint,Color("#ffe0a0"),4);picker_page.add_child(hint)
	picker_scroll=ScrollContainer.new();picker_scroll.position=Vector2(24,194);picker_scroll.size=Vector2(528,790);picker_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;picker_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;picker_scroll.scroll_deadzone=12;picker_scroll.mouse_filter=Control.MOUSE_FILTER_STOP;picker_page.add_child(picker_scroll)
	picker_grid=GridContainer.new();picker_grid.columns=2;picker_grid.custom_minimum_size=Vector2(510,0);picker_grid.mouse_filter=Control.MOUSE_FILTER_PASS;picker_grid.add_theme_constant_override("h_separation",10);picker_grid.add_theme_constant_override("v_separation",10);picker_scroll.add_child(picker_grid)

func _open_species_picker()->void:
	if bool(current_arrangement.get("completed",false)):return
	if editor_plants.size()>=MAX_PLANTS_PER_ARRANGEMENT:editor_message.text="1作品には最大%d株まで置けます"%MAX_PLANTS_PER_ARRANGEMENT;return
	_show_page(picker_page);_refresh_picker_filters();_refresh_species_picker();picker_scroll.scroll_vertical=0

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
		var card:=Button.new();card.custom_minimum_size=Vector2(248,150);_skin_button(card,Color("#f4e1bc"),15);_prepare_scroll_button(card);card.disabled=texture==null;picker_grid.add_child(card)
		var image_frame:=Control.new();image_frame.position=Vector2(8,12);image_frame.size=Vector2(112,112);image_frame.clip_contents=true;image_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(image_frame)
		var image:=TextureRect.new();image.texture=texture;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;image_frame.add_child(image);_request_texture(entry,image,false)
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
	if bool(current_arrangement.get("completed",false)) or editor_plants.size()>=MAX_PLANTS_PER_ARRANGEMENT or not bool(discovered.get(species_id,false)):return
	var entry:=_species_entry(species_id)
	if entry.is_empty() or _resolve_texture(entry)==null:return
	var pot:=_pot_entry(str(current_arrangement.get("pot_id","")));var allowed:=_placement_rect(pot,editor_canvas.size);var index:=editor_plants.size();var column:=(index%5)-2;var row:=int(index/5)%4
	var center:=Vector2(allowed.get_center().x+column*34.0,allowed.end.y-48.0-row*27.0)
	center.x=clampf(center.x,allowed.position.x,allowed.end.x);center.y=clampf(center.y,allowed.position.y,allowed.end.y)
	editor_plants.append({"species_id":species_id,"x":center.x,"y":center.y,"scale":1.0,"rotation":0.0,"z_index":index})
	_show_page(editor_page);_rebuild_editor_scene();_select_plant(editor_plants.size()-1);editor_message.text="%sを追加しました。選択したまま直接ドラッグできます"%str(entry.get("name_ja","多肉"))

func _return_to_editor()->void:
	_show_page(editor_page);_rebuild_editor_scene()

func _save_current_arrangement()->void:
	if current_arrangement.is_empty() or bool(current_arrangement.get("completed",false)):return
	var name:=editor_name.text.strip_edges()
	if name.is_empty():name=_default_arrangement_name();editor_name.text=name
	_cancel_editor_gesture();selected_plant_index=-1;_update_editor_selection()
	var saved:={"arrangement_id":str(current_arrangement.get("arrangement_id",_new_arrangement_id())),"name":name,"pot_id":str(current_arrangement.get("pot_id",DEFAULT_POT_ID)),"created_at":str(current_arrangement.get("created_at",Time.get_datetime_string_from_system(false,true))),"completed":true,"plants":editor_plants.duplicate(true)}
	current_arrangement=saved.duplicate(true);save_requested.emit(saved.duplicate(true))
	completion_overlay.visible=true;completion_confetti_requested.emit(completion_confetti_layer)
	await get_tree().create_timer(COMPLETION_DISPLAY_SECONDS).timeout
	_clear_completion_overlay()
	if visible:_open_viewer(saved)

func _build_viewer_page()->void:
	viewer_page.gui_input.connect(_on_viewer_world_scroll_input)
	_build_header(viewer_page,"完成した寄せ植え",_return_from_viewer)
	viewer_name=Label.new();viewer_name.position=Vector2(30,90);viewer_name.size=Vector2(516,48);viewer_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;viewer_name.add_theme_font_size_override("font_size",24);_style_overlay_label(viewer_name,Color("#ffe0a0"),5);viewer_page.add_child(viewer_name)
	viewer_canvas=Panel.new();viewer_canvas.position=ARRANGEMENT_CANVAS_POSITION;viewer_canvas.size=Vector2(536,552);viewer_canvas.clip_contents=false;viewer_canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewer_canvas.add_theme_stylebox_override("panel",StyleBoxEmpty.new());viewer_page.add_child(viewer_canvas)
	viewer_pot_layer=Control.new();viewer_pot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);viewer_pot_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewer_canvas.add_child(viewer_pot_layer)
	viewer_plant_layer=Control.new();viewer_plant_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);viewer_plant_layer.z_index=PLANT_LAYER_Z;viewer_plant_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewer_canvas.add_child(viewer_plant_layer)

func _open_viewer(arrangement:Dictionary)->void:
	current_arrangement=arrangement.duplicate(true);current_arrangement["completed"]=true;viewer_name.text=str(arrangement.get("name","寄せ植え"));_show_page(viewer_page);_render_readonly_arrangement(current_arrangement)

func _render_readonly_arrangement(arrangement:Dictionary)->void:
	_clear_children(viewer_pot_layer);_clear_children(viewer_plant_layer)
	var pot:=_pot_entry(str(arrangement.get("pot_id","")));var holder:=Control.new();holder.size=Vector2(432,244);holder.position=_pot_holder_position(viewer_canvas,holder.size);holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewer_pot_layer.add_child(holder);_render_pot(holder,pot,false)
	for plant_value in _plant_array(arrangement):
		if not plant_value is Dictionary:continue
		var plant:Dictionary=plant_value;var texture:=_resolve_texture(_species_entry(str(plant.get("species_id",""))))
		if texture==null:continue
		var root:=Control.new();root.size=PLANT_CONTROL_SIZE;root.pivot_offset=PLANT_CONTROL_SIZE*.5;root.position=Vector2(float(plant.get("x",0.0)),float(plant.get("y",0.0)))-PLANT_CONTROL_SIZE*.5;root.scale=Vector2.ONE*clampf(float(plant.get("scale",1.0)),PLANT_SCALE_MIN,PLANT_SCALE_MAX);root.rotation_degrees=fposmod(float(plant.get("rotation",0.0)),360.0);root.z_index=int(plant.get("z_index",0));root.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewer_plant_layer.add_child(root)
		var image:=TextureRect.new();image.texture=texture;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(image);_request_texture(_species_entry(str(plant.get("species_id",""))),image,true)

func _pot_holder_position(canvas:Control,holder_size:Vector2)->Vector2:
	if not world_backdrop_enabled:return Vector2(52,294)
	return Vector2(world_pot_anchor_screen.x-canvas.position.x-holder_size.x*.5,world_pot_anchor_screen.y+POT_VERTICAL_OFFSET-canvas.position.y-holder_size.y*.94)

func _return_from_viewer()->void:
	_show_page(home_page);_refresh_home()

func _on_viewer_world_scroll_input(event:InputEvent)->void:
	if world_backdrop_enabled and visible and viewer_page.visible:world_scroll_input.emit(event)

func _build_shop_page()->void:
	_build_header(shop_page,"寄せ植え用の鉢",close)
	shop_wallet=Label.new();shop_wallet.position=Vector2(30,92);shop_wallet.size=Vector2(516,38);shop_wallet.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_wallet.add_theme_font_size_override("font_size",20);shop_wallet.add_theme_color_override("font_color",Color("#f5d36d"));shop_page.add_child(shop_wallet)
	shop_message=Label.new();shop_message.position=Vector2(30,132);shop_message.size=Vector2(516,52);shop_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;shop_message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;shop_message.add_theme_font_size_override("font_size",16);shop_message.add_theme_color_override("font_color",UI_CREAM);shop_page.add_child(shop_message)
	var scroll:=_shop_scroll(Vector2(26,194),Vector2(524,790));shop_page.add_child(scroll)
	shop_grid=VBoxContainer.new();shop_grid.custom_minimum_size=Vector2(504,0);shop_grid.mouse_filter=Control.MOUSE_FILTER_PASS;shop_grid.add_theme_constant_override("separation",14);scroll.add_child(shop_grid)

func _refresh_pot_shop()->void:
	shop_wallet.text="所持　%dぷくコイン"%wallet_puku_points
	if shop_message.text.is_empty():shop_message.text="鉢のぷく価格は準備中です"
	_refresh_pot_shop_cards()

func _refresh_pot_shop_cards()->void:
	_clear_children(shop_grid)
	for pot_value in pot_catalog:
		if not pot_value is Dictionary:continue
		var pot:Dictionary=pot_value;var pot_id:=str(pot.get("pot_id",""));var owned:=bool(owned_pots.get(pot_id,false));var price_value=pot.get("price_puku");var priced:=price_value is int or price_value is float;var price:=maxi(0,int(price_value)) if priced else 0
		var card:=PanelContainer.new();card.custom_minimum_size=Vector2(504,204);card.mouse_filter=Control.MOUSE_FILTER_PASS;card.add_theme_stylebox_override("panel",_box(Color("#f4e1bc"),Color("#b77c48"),20,3));shop_grid.add_child(card)
		var content:=Control.new();content.custom_minimum_size=Vector2(484,184);content.mouse_filter=Control.MOUSE_FILTER_PASS;card.add_child(content)
		var preview:=Control.new();preview.position=Vector2(2,2);preview.size=Vector2(214,176);preview.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(preview);_render_pot(preview,pot,true)
		var name:=Label.new();name.text=str(pot.get("display_name","鉢"));name.position=Vector2(220,12);name.size=Vector2(258,45);name.mouse_filter=Control.MOUSE_FILTER_IGNORE;name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name.add_theme_font_size_override("font_size",19);name.add_theme_color_override("font_color",UI_BROWN);content.add_child(name)
		var condition:=Label.new();condition.text=str(pot.get("unlock_condition",{}).get("display_text",""));condition.position=Vector2(220,55);condition.size=Vector2(258,34);condition.mouse_filter=Control.MOUSE_FILTER_IGNORE;condition.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;condition.add_theme_font_size_override("font_size",13);condition.add_theme_color_override("font_color",Color("#79543a"));content.add_child(condition)
		var buy_text:="購入済み" if owned else ("買う　%dぷくコイン"%price if priced else "価格準備中")
		var buy:=_button(buy_text,Vector2(248,102),Vector2(204,58),Color("#b9a17d") if owned or not priced else Color("#d7aa64"),17);_prepare_scroll_button(buy);buy.disabled=owned or not priced or wallet_puku_points<price;buy.pressed.connect(_request_pot_purchase.bind(pot_id));content.add_child(buy)

func _request_pot_purchase(pot_id:String)->void:
	pot_purchase_requested.emit(pot_id)

func _build_catalog_shop_page()->void:
	_build_header(catalog_shop_page,"シリーズ図鑑",close)
	catalog_shop_wallet=Label.new();catalog_shop_wallet.position=Vector2(30,92);catalog_shop_wallet.size=Vector2(516,38);catalog_shop_wallet.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;catalog_shop_wallet.add_theme_font_size_override("font_size",20);catalog_shop_wallet.add_theme_color_override("font_color",Color("#f5d36d"));catalog_shop_page.add_child(catalog_shop_wallet)
	catalog_shop_message=Label.new();catalog_shop_message.position=Vector2(30,132);catalog_shop_message.size=Vector2(516,52);catalog_shop_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;catalog_shop_message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;catalog_shop_message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;catalog_shop_message.add_theme_font_size_override("font_size",16);catalog_shop_message.add_theme_color_override("font_color",UI_CREAM);catalog_shop_page.add_child(catalog_shop_message)
	var scroll:=_shop_scroll(Vector2(26,194),Vector2(524,790));catalog_shop_page.add_child(scroll)
	catalog_shop_grid=VBoxContainer.new();catalog_shop_grid.custom_minimum_size=Vector2(504,0);catalog_shop_grid.mouse_filter=Control.MOUSE_FILTER_PASS;catalog_shop_grid.add_theme_constant_override("separation",14);scroll.add_child(catalog_shop_grid)

func _refresh_catalog_shop()->void:
	catalog_shop_wallet.text="所持　%dぷくコイン"%wallet_puku_points
	if catalog_shop_message.text.is_empty():catalog_shop_message.text="図鑑は一度購入すると、メイン画面からいつでも見られます"
	_clear_children(catalog_shop_grid)
	for series_value in series_catalog:
		if not series_value is Dictionary:continue
		var series:Dictionary=series_value;var series_id:=str(series.get("series_id",""));var owned:=bool(owned_catalogs.get(series_id,false)) or str(series.get("unlock_type","future"))=="default";var price:=maxi(0,int(series.get("unlock_price_puku",5)))
		var card:=PanelContainer.new();card.custom_minimum_size=Vector2(504,204);card.mouse_filter=Control.MOUSE_FILTER_PASS;card.add_theme_stylebox_override("panel",_box(Color("#f4e1bc"),Color("#b77c48"),20,3));catalog_shop_grid.add_child(card)
		var content:=Control.new();content.custom_minimum_size=Vector2(484,184);content.mouse_filter=Control.MOUSE_FILTER_PASS;card.add_child(content)
		var preview:=TextureRect.new();preview.position=Vector2(2,2);preview.size=Vector2(214,176);preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;preview.mouse_filter=Control.MOUSE_FILTER_IGNORE;preview.texture=_series_preview_texture(series);content.add_child(preview)
		var preview_ids=series.get("species_ids",[])
		if preview_ids is Array and not preview_ids.is_empty():_request_texture(_species_entry(str(preview_ids[0])),preview,false)
		if preview.texture==null:
			var placeholder:=Label.new();placeholder.text="商品画像\n準備中";placeholder.position=preview.position;placeholder.size=preview.size;placeholder.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;placeholder.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;placeholder.add_theme_font_size_override("font_size",18);placeholder.add_theme_color_override("font_color",Color("#79543a"));content.add_child(placeholder)
		var name:=Label.new();name.text=str(series.get("display_name","シリーズ図鑑"));name.position=Vector2(220,12);name.size=Vector2(258,45);name.mouse_filter=Control.MOUSE_FILTER_IGNORE;name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name.add_theme_font_size_override("font_size",19);name.add_theme_color_override("font_color",UI_BROWN);content.add_child(name)
		var condition:=Label.new();condition.text="シリーズ図鑑ページ";condition.position=Vector2(220,55);condition.size=Vector2(258,34);condition.mouse_filter=Control.MOUSE_FILTER_IGNORE;condition.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;condition.add_theme_font_size_override("font_size",13);condition.add_theme_color_override("font_color",Color("#79543a"));content.add_child(condition)
		var buy:=_button("購入済み" if owned else ("買う　%dぷくコイン"%price),Vector2(248,102),Vector2(204,58),Color("#b9a17d") if owned else Color("#d7aa64"),17);_prepare_scroll_button(buy);buy.disabled=owned or wallet_puku_points<price;buy.pressed.connect(_request_catalog_purchase.bind(series_id));content.add_child(buy)

func _request_catalog_purchase(series_id:String)->void:
	catalog_purchase_requested.emit(series_id)

func _build_seed_shop_page()->void:
	_build_header(seed_shop_page,"たね袋",close)
	seed_shop_wallet=Label.new();seed_shop_wallet.position=Vector2(30,92);seed_shop_wallet.size=Vector2(516,38);seed_shop_wallet.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;seed_shop_wallet.add_theme_font_size_override("font_size",20);seed_shop_wallet.add_theme_color_override("font_color",Color("#f5d36d"));seed_shop_page.add_child(seed_shop_wallet)
	seed_shop_message=Label.new();seed_shop_message.position=Vector2(30,132);seed_shop_message.size=Vector2(516,52);seed_shop_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;seed_shop_message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;seed_shop_message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;seed_shop_message.add_theme_font_size_override("font_size",16);seed_shop_message.add_theme_color_override("font_color",UI_CREAM);seed_shop_page.add_child(seed_shop_message)
	var scroll:=_shop_scroll(Vector2(26,194),Vector2(524,790));seed_shop_page.add_child(scroll)
	seed_shop_grid=VBoxContainer.new();seed_shop_grid.custom_minimum_size=Vector2(504,0);seed_shop_grid.mouse_filter=Control.MOUSE_FILTER_PASS;seed_shop_grid.add_theme_constant_override("separation",14);scroll.add_child(seed_shop_grid)

func _refresh_seed_shop()->void:
	seed_shop_wallet.text="所持　%dぷくコイン"%wallet_puku_points
	if seed_shop_message.text.is_empty():seed_shop_message.text="普通のたねは1ぷくコインで3袋です"
	_clear_children(seed_shop_grid)
	for product_value in seed_shop_products:
		if not product_value is Dictionary:continue
		var product:Dictionary=product_value;var seed_type:=str(product.get("seed_type","normal"));var price_value=product.get("price_puku");var priced:=price_value is int or price_value is float;var price:=maxi(0,int(price_value)) if priced else 0;var unlocked:=bool(product.get("unlocked",false));var purchasable:=bool(product.get("purchasable",priced));var accent:=Color(str(product.get("accent","#d8b56b")))
		var card:=PanelContainer.new();card.custom_minimum_size=Vector2(504,204);card.mouse_filter=Control.MOUSE_FILTER_PASS;card.add_theme_stylebox_override("panel",_box(Color("#f4e1bc"),Color("#b77c48"),20,3));seed_shop_grid.add_child(card)
		var content:=Control.new();content.custom_minimum_size=Vector2(484,184);content.mouse_filter=Control.MOUSE_FILTER_PASS;card.add_child(content)
		var preview:=PanelContainer.new();preview.position=Vector2(2,2);preview.size=Vector2(214,176);preview.mouse_filter=Control.MOUSE_FILTER_IGNORE;preview.add_theme_stylebox_override("panel",_box(accent.lightened(.16),accent.darkened(.18),24,3));content.add_child(preview)
		var preview_label:=Label.new();preview_label.text="たね袋\n%d粒"%int(product.get("count",0));preview_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;preview_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;preview_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;preview_label.add_theme_font_size_override("font_size",24);preview_label.add_theme_color_override("font_color",UI_BROWN);preview.add_child(preview_label)
		var name:=Label.new();name.text=str(product.get("display_name","たね袋"));name.position=Vector2(220,7);name.size=Vector2(258,40);name.mouse_filter=Control.MOUSE_FILTER_IGNORE;name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name.add_theme_font_size_override("font_size",19);name.add_theme_color_override("font_color",UI_BROWN);content.add_child(name)
		var detail:=Label.new();detail.text=str(product.get("description",""));detail.position=Vector2(220,45);detail.size=Vector2(258,66);detail.mouse_filter=Control.MOUSE_FILTER_IGNORE;detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;detail.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.add_theme_font_size_override("font_size",13);detail.add_theme_color_override("font_color",Color("#79543a"));content.add_child(detail)
		var buy_text:="未解禁" if not unlocked else ("買う　%dぷくコイン"%price if purchasable and priced else "価格準備中")
		var buy:=_button(buy_text,Vector2(248,116),Vector2(204,54),accent,17);_prepare_scroll_button(buy);buy.disabled=not unlocked or not purchasable or not priced or wallet_puku_points<price;buy.pressed.connect(_request_seed_purchase.bind(seed_type));content.add_child(buy)

func _request_seed_purchase(seed_type:String)->void:
	seed_purchase_requested.emit(seed_type)

func _series_preview_texture(series:Dictionary)->Texture2D:
	var ids=series.get("species_ids",[])
	if ids is Array and not ids.is_empty():
		var first:=_species_entry(str(ids[0]));var first_texture:=_resolve_texture(first)
		if first_texture!=null:return first_texture
	var path:=str(series.get("cover_image_path",""))
	return load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null

func _shop_scroll(position_value:Vector2,size_value:Vector2)->ScrollContainer:
	var scroll:=ScrollContainer.new();scroll.position=position_value;scroll.size=size_value;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;scroll.scroll_deadzone=12;scroll.mouse_filter=Control.MOUSE_FILTER_STOP;return scroll

func _prepare_scroll_button(button:Button)->void:
	button.action_mode=BaseButton.ACTION_MODE_BUTTON_RELEASE;button.mouse_filter=Control.MOUSE_FILTER_PASS;button.mouse_force_pass_scroll_events=true

func _render_pot(container:Control,pot:Dictionary,compact:bool)->void:
	_clear_children(container)
	var path:=str(pot.get("image_path",""))
	if not path.is_empty() and ResourceLoader.exists(path):
		var image:=TextureRect.new();image.texture=load(path) as Texture2D;image.anchor_left=.035;image.anchor_top=.035;image.anchor_right=.965;image.anchor_bottom=.965;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;container.add_child(image)
	else:
		var placeholder:=PotPlaceholderClass.new();placeholder.display_name=str(pot.get("display_name","鉢")) if not compact else "鉢画像 準備中";placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);placeholder.mouse_filter=Control.MOUSE_FILTER_IGNORE;container.add_child(placeholder)

func _placement_rect(_pot:Dictionary,canvas_size:Vector2)->Rect2:
	return Rect2(Vector2.ZERO,canvas_size)

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

func _request_texture(entry:Dictionary,target:TextureRect,high_priority:bool)->void:
	if entry.is_empty() or not is_instance_valid(target) or not texture_requester.is_valid():return
	texture_requester.call(entry,target,high_priority)

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

func _style_overlay_label(label:Label,color:=UI_CREAM,outline_size:=5)->void:
	label.add_theme_color_override("font_color",color);label.add_theme_color_override("font_outline_color",Color(0.12,.055,.025,.92));label.add_theme_constant_override("outline_size",outline_size);label.add_theme_color_override("font_shadow_color",Color(0.0,0.0,0.0,.52));label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",2)

func _box(bg:Color,border:Color,radius:int,width:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius);style.content_margin_left=10;style.content_margin_right=10;style.content_margin_top=7;style.content_margin_bottom=7;style.shadow_color=Color(0.15,.07,.03,.28);style.shadow_size=5;style.shadow_offset=Vector2(0,3);return style
