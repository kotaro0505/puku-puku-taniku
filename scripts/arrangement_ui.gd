class_name ArrangementUI
extends Control

signal close_requested(context:String)
signal save_requested(arrangement:Dictionary)
signal share_background_save_requested(arrangement_id:String,share_background_id:String)
signal share_requested(arrangement:Dictionary)
signal dismantle_requested(arrangement_id:String)
signal pot_purchase_requested(pot_id:String)
signal pot_unlock_requested(product_id:String)
signal pot_restore_requested
signal catalog_purchase_requested(series_id:String)
signal seed_purchase_requested(seed_type:String)
signal world_scroll_input(event:InputEvent)
signal completion_confetti_requested(layer:Control)

const PotPlaceholderClass = preload("res://scripts/arrangement_pot_placeholder.gd")
const ShareBackgroundsClass = preload("res://scripts/arrangement_share_backgrounds.gd")
const ShareRendererClass = preload("res://scripts/arrangement_share_renderer.gd")
const MAX_PLANTS_PER_ARRANGEMENT := 24
const PLANT_CONTROL_SIZE := Vector2(150,150)
const PLANT_SCALE_MIN := 0.45
# This is only a technical guard against accidental infinite transforms.  It
# is deliberately unrelated to harvest records and sits well beyond ordinary
# editor gestures.
const PLANT_SCALE_SAFETY_MAX := 12.0
const PLANT_SCALE_STEP := 0.10
const PLANT_ROTATION_STEP := 15.0
const PLANT_GESTURE_MOVE_THRESHOLD := 12.0
const ARRANGEMENT_CANVAS_POSITION := Vector2(20,150)
const POT_VERTICAL_OFFSET := 62.0
const POT_HOLDER_SIZE := Vector2(516,292)
const POT_LOCAL_BASELINE_Y := 538.0
const PLANT_LAYER_Z := 200
const VIEWER_SCALE_DEFAULT := 1.0
const VIEWER_SCALE_MIN := 0.6
const VIEWER_SCALE_MAX := 2.25
const VIEWER_MIN_VISIBLE_PIXELS := 96.0
const COMPLETION_DISPLAY_SECONDS := 1.65
const DEFAULT_POT_ID := "shallow_terracotta"
const UI_CREAM := Color("#fff1d2")
const UI_BROWN := Color("#4a2618")

var catalog_species:Array=[]
var series_catalog:Array=[]
var pot_catalog:Array=[]
var discovered:Dictionary={}
var species_bests:Dictionary={}
var language_code:="ja"
var owned_pots:Dictionary={}
var owned_catalogs:Dictionary={"base":true}
var wallet_puku_points:=0
var seed_shop_products:Array=[]
var saved_arrangements:Array=[]
var save_capacity:=20
var pot_sales_stage:=0
var pot_design_unlocks:Dictionary={}
var pot_iap_products:Dictionary={}
var pot_restore_available:=false
var pot_restore_in_progress:=false
var share_background_catalog:Array=[]
var share_background_unlocks:Dictionary={}
var texture_resolver:Callable
var texture_requester:Callable
var return_context:="greenhouse"
var world_backdrop_enabled:=false
var world_pot_anchor_screen:=Vector2(288,630)

var backdrop_shade:ColorRect
var home_page:Control
var home_status:Label
var home_saved_button:Button
var home_pot_scroll:ScrollContainer
var pot_select_grid:GridContainer
var saved_arrangements_page:Control
var saved_arrangements_summary:Label
var saved_arrangements_tab_scroll:ScrollContainer
var saved_arrangements_tabs:HBoxContainer
var saved_arrangements_empty:Label
var selected_saved_tab_button:Button
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
var viewer_header_title:Label
var viewer_name:Label
var viewer_canvas:Panel
var viewer_artwork_root:Control
var viewer_pot_layer:Control
var viewer_plant_layer:Control
var viewer_dismantle_button:Button
var viewer_share_button:Button
var viewer_share_background_button:Button
var viewer_share_status:Label
var share_background_panel:Panel
var share_background_scroll:ScrollContainer
var share_background_cards:HBoxContainer
var viewer_return_context:="home"
var dismantle_confirmation_overlay:Control
var dismantle_confirmation_label:Label
var completion_overlay:Control
var completion_confetti_layer:Control
var completion_label:Label
var shop_page:Control
var shop_wallet:Label
var shop_message:Label
var shop_grid:VBoxContainer
var shop_restore_button:Button
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
var web_touch_canvas
var web_touch_callback
var web_touch_listener_options
var web_multitouch_active:=false
var web_multitouch_suppress_native:=false
var viewer_touch_positions:Dictionary={}
var viewer_drag_active:=false
var viewer_drag_pointer_id:=-999
var viewer_drag_last_position:=Vector2.ZERO
var viewer_pinch_active:=false
var viewer_pinch_touch_ids:Array[int]=[]
var viewer_pinch_start_distance:=1.0
var viewer_pinch_start_scale:=VIEWER_SCALE_DEFAULT
var viewer_pinch_start_position:=Vector2.ZERO
var viewer_pinch_start_midpoint:=Vector2.ZERO
var viewer_web_multitouch_active:=false
var viewer_web_multitouch_suppress_native:=false
var viewer_share_in_progress:=false
var last_share_render_debug:Dictionary={}
var viewer_gallery_mode:=false
var selected_saved_arrangement_id:=""
var selected_saved_arrangement_index:=-1
var save_request_accepted:=false
var dismantle_request_accepted:=false

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
	_install_web_multitouch_fallback()

func _exit_tree()->void:
	_remove_web_multitouch_fallback()

func configure(species_data:Array,series_data:Array,pots_data:Array,discovery:Dictionary,purchased_pots:Dictionary,arrangements:Array,capacity:int,puku_points:int,resolver:Callable,requester:Callable=Callable(),best_records:Dictionary={},locale:String="ja",sales_stage:int=0,design_unlocks:Dictionary={},iap_products:Dictionary={},restore_available:bool=false,restore_in_progress:bool=false,share_backgrounds:Array=[],background_unlocks:Dictionary={})->void:
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
	species_bests=best_records
	language_code=GameLocalizer.normalize_language(locale)
	pot_sales_stage=clampi(sales_stage,0,2)
	pot_design_unlocks=design_unlocks
	pot_iap_products=iap_products
	pot_restore_available=restore_available
	pot_restore_in_progress=restore_in_progress
	share_background_catalog=share_backgrounds.duplicate(true)
	share_background_unlocks=background_unlocks.duplicate(true)
	if visible and viewer_page!=null and viewer_page.visible and _share_background_panel_is_open():_refresh_share_background_panel()

func set_language(locale:String)->void:
	language_code=GameLocalizer.normalize_language(locale)
	_apply_static_language()
	if not visible:return
	if home_page.visible:_refresh_home()
	elif viewer_page.visible and viewer_gallery_mode:_refresh_saved_arrangements()
	elif editor_page.visible:_rebuild_editor_scene()
	elif picker_page.visible:_refresh_picker_filters();_refresh_species_picker()
	elif viewer_page.visible and not current_arrangement.is_empty():
		_apply_viewer_page_mode()
		if _share_background_panel_is_open():_refresh_share_background_panel()
	elif shop_page.visible:_refresh_pot_shop()
	elif catalog_shop_page.visible:_refresh_catalog_shop()
	elif seed_shop_page.visible:_refresh_seed_shop()

func sync_species_bests(best_records:Dictionary)->void:
	species_bests=best_records
	if visible and editor_page.visible and not current_arrangement.is_empty():_rebuild_editor_scene()

func _species_scale_max(_species_id:String)->float:
	# Harvest bests remain display-only metadata.  Arrangement composition is a
	# creative tool and must never be capped by a species' historical best cm.
	return PLANT_SCALE_SAFETY_MAX

func _plant_scale_max(plant:Dictionary)->float:
	return _species_scale_max(str(plant.get("species_id","")))

func sync_state(purchased_pots:Dictionary,arrangements:Array,capacity:int)->void:
	owned_pots=purchased_pots;saved_arrangements=arrangements;save_capacity=maxi(1,capacity)
	if visible and shop_page.visible:_refresh_pot_shop()
	if visible and home_page.visible:_refresh_home()
	if visible and viewer_page.visible and viewer_gallery_mode:_refresh_saved_arrangements()

func sync_catalog_state(purchased_catalogs:Dictionary,puku_points:int)->void:
	owned_catalogs=purchased_catalogs;wallet_puku_points=maxi(0,puku_points)
	if visible and shop_page.visible:_refresh_pot_shop()
	if visible and catalog_shop_page.visible:_refresh_catalog_shop()

func sync_pot_iap_state(design_unlocks:Dictionary,iap_products:Dictionary,restore_available:bool,restore_in_progress:bool)->void:
	pot_design_unlocks=design_unlocks;pot_iap_products=iap_products;pot_restore_available=restore_available;pot_restore_in_progress=restore_in_progress
	if visible and shop_page.visible:_refresh_pot_shop()
	if visible and home_page.visible:_refresh_home()

func sync_share_background_state(backgrounds:Array,background_unlocks:Dictionary)->void:
	share_background_catalog=backgrounds.duplicate(true);share_background_unlocks=background_unlocks.duplicate(true)
	if visible and viewer_page.visible and _share_background_panel_is_open():_refresh_share_background_panel()

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
	_cancel_editor_gesture();_cancel_viewer_gesture(false);_close_share_background_panel();_clear_completion_overlay();_hide_dismantle_confirmation();visible=false;close_requested.emit(return_context)

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
	if changed and visible and viewer_page and viewer_page.visible and not current_arrangement.is_empty():_render_readonly_arrangement(current_arrangement,_viewer_transform_state())

func _build_ui()->void:
	backdrop_shade=ColorRect.new();backdrop_shade.color=Color("#43281f");backdrop_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop_shade.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(backdrop_shade)
	home_page=_page();home_page.gui_input.connect(_on_home_world_scroll_input);_build_home_page()
	editor_page=_page();_build_editor_page()
	picker_page=_page();_build_picker_page()
	viewer_page=_page();saved_arrangements_page=viewer_page;_build_viewer_page()
	shop_page=_page();_build_shop_page()
	catalog_shop_page=_page();_build_catalog_shop_page()
	seed_shop_page=_page();_build_seed_shop_page()
	_build_completion_overlay()
	_build_dismantle_confirmation()
	_apply_static_language()

func _build_completion_overlay()->void:
	completion_overlay=Control.new();completion_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);completion_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;completion_overlay.visible=false;add_child(completion_overlay)
	completion_confetti_layer=Control.new();completion_confetti_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);completion_confetti_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;completion_overlay.add_child(completion_confetti_layer)
	completion_label=Label.new();_mark_localized(completion_label,"arrangement_complete");completion_label.position=Vector2(48,326);completion_label.size=Vector2(480,92);completion_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;completion_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;completion_label.add_theme_font_size_override("font_size",38);completion_label.add_theme_color_override("font_color",Color("#fff1c8"));completion_label.add_theme_color_override("font_outline_color",Color("#61351f"));completion_label.add_theme_constant_override("outline_size",8);completion_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;completion_overlay.add_child(completion_label)

func _clear_completion_overlay()->void:
	if completion_overlay:completion_overlay.visible=false
	if completion_confetti_layer:
		for child in completion_confetti_layer.get_children():child.queue_free()

func _build_dismantle_confirmation()->void:
	dismantle_confirmation_overlay=Control.new();dismantle_confirmation_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);dismantle_confirmation_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;dismantle_confirmation_overlay.visible=false;add_child(dismantle_confirmation_overlay)
	var shade:=ColorRect.new();shade.color=Color(0.08,0.04,0.025,.76);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;dismantle_confirmation_overlay.add_child(shade)
	var card:=Panel.new();card.position=Vector2(42,320);card.size=Vector2(492,300);card.add_theme_stylebox_override("panel",_box(Color("#f7e8c7"),Color("#b87962"),26,4));dismantle_confirmation_overlay.add_child(card)
	dismantle_confirmation_label=Label.new();_mark_localized(dismantle_confirmation_label,"arrangement_dismantle_confirm");dismantle_confirmation_label.position=Vector2(66,354);dismantle_confirmation_label.size=Vector2(444,116);dismantle_confirmation_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;dismantle_confirmation_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;dismantle_confirmation_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;dismantle_confirmation_label.add_theme_font_size_override("font_size",20);dismantle_confirmation_label.add_theme_color_override("font_color",UI_BROWN);dismantle_confirmation_overlay.add_child(dismantle_confirmation_label)
	var cancel:=_button(GameLocalizer.text(language_code,"arrangement_dismantle_cancel"),Vector2(66,514),Vector2(204,62),Color("#ead4a5"),18);_mark_localized(cancel,"arrangement_dismantle_cancel");cancel.pressed.connect(_hide_dismantle_confirmation);dismantle_confirmation_overlay.add_child(cancel)
	var confirm:=_button(GameLocalizer.text(language_code,"arrangement_dismantle_confirm_button"),Vector2(306,514),Vector2(204,62),Color("#b87962"),18);_mark_localized(confirm,"arrangement_dismantle_confirm_button");confirm.pressed.connect(_confirm_dismantle);dismantle_confirmation_overlay.add_child(confirm)

func _show_dismantle_confirmation()->void:
	if current_arrangement.is_empty() or not bool(current_arrangement.get("completed",false)):return
	_close_share_background_panel();dismantle_request_accepted=false;dismantle_confirmation_overlay.visible=true;dismantle_confirmation_overlay.move_to_front()

func _hide_dismantle_confirmation()->void:
	if dismantle_confirmation_overlay:dismantle_confirmation_overlay.visible=false

func _confirm_dismantle()->void:
	if current_arrangement.is_empty():_hide_dismantle_confirmation();return
	var was_gallery:=viewer_gallery_mode
	dismantle_request_accepted=false
	dismantle_requested.emit(str(current_arrangement.get("arrangement_id","")))
	if not dismantle_request_accepted:return
	_close_share_background_panel();_hide_dismantle_confirmation()
	if was_gallery:
		_refresh_saved_arrangements()
	else:
		current_arrangement={};_show_page(home_page);_refresh_home()

func set_dismantle_request_result(accepted:bool)->void:
	dismantle_request_accepted=accepted

func set_save_request_result(accepted:bool,message:String="")->void:
	save_request_accepted=accepted
	if not accepted and not message.is_empty():editor_message.text=message

func _page()->Control:
	var page:=Control.new();page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);page.mouse_filter=Control.MOUSE_FILTER_STOP;page.visible=false;add_child(page);return page

func _show_page(page:Control)->void:
	if editor_page and editor_page.visible and page!=editor_page:_cancel_editor_gesture()
	if viewer_page and viewer_page.visible and page!=viewer_page:_cancel_viewer_gesture(false)
	if page!=viewer_page:_hide_dismantle_confirmation();_close_share_background_panel()
	for candidate in [home_page,editor_page,picker_page,viewer_page,shop_page,catalog_shop_page,seed_shop_page]:
		if candidate:candidate.visible=candidate==page

func is_editor_active()->bool:
	return visible and editor_page!=null and editor_page.visible

func is_viewer_active()->bool:
	return visible and viewer_page!=null and viewer_page.visible

func is_navigation_hint_safe()->bool:
	# Viewer gestures are exclusively owned by the finished artwork. Keep the
	# greenhouse return hint on the pot-selection home only.
	return visible and not completion_overlay.visible and not dismantle_confirmation_overlay.visible and home_page!=null and home_page.visible

func _input(event:InputEvent)->void:
	# Web/mobile browsers do not reliably route the second finger of a
	# multi-touch gesture through a Control's gui_input signal. Track touch
	# events at viewport level while an interactive canvas is active so both
	# fingers use the same path. Mouse input remains owned by each canvas.
	if is_viewer_active() and viewer_canvas!=null:
		if event is InputEventScreenTouch or event is InputEventScreenDrag:
			if _share_background_panel_is_open():
				_cancel_viewer_gesture(true)
				return
			if viewer_web_multitouch_suppress_native:
				# The capture-phase DOM bridge already applied this exact Web gesture.
				get_viewport().set_input_as_handled()
				return
			if _route_viewer_touch_event(event,false):get_viewport().set_input_as_handled()
		return
	if not is_editor_active() or editor_canvas==null:return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if web_multitouch_suppress_native:
			# The capture-phase DOM bridge already applied this exact Web gesture.
			# Claim the Godot mirror event without applying the transform twice.
			get_viewport().set_input_as_handled()
			return
		if _route_editor_touch_event(event,false):get_viewport().set_input_as_handled()

func _route_editor_touch_event(event:InputEvent,position_is_editor_local:bool)->bool:
	if not is_editor_active() or editor_canvas==null:return false
	if event is InputEventScreenTouch:
		var touch:=event as InputEventScreenTouch
		var local_position:=touch.position if position_is_editor_local else _editor_local_touch_position(touch.position)
		if touch.pressed and not _editor_canvas_has_point(local_position):return false
		if not touch.pressed and not touch_positions.has(touch.index):return false
		var local_touch:=touch.duplicate() as InputEventScreenTouch;local_touch.position=local_position;_handle_editor_touch(local_touch)
		return true
	if event is InputEventScreenDrag:
		var drag:=event as InputEventScreenDrag
		var local_position:=drag.position if position_is_editor_local else _editor_local_touch_position(drag.position)
		if not touch_positions.has(drag.index) and not _editor_canvas_has_point(local_position):return false
		var local_drag:=drag.duplicate() as InputEventScreenDrag;local_drag.position=local_position;_handle_editor_touch(local_drag)
		return true
	return false

func _route_viewer_touch_event(event:InputEvent,position_is_viewer_local:bool)->bool:
	if not is_viewer_active() or viewer_canvas==null or _share_background_panel_is_open():return false
	if event is InputEventScreenTouch:
		var touch:=event as InputEventScreenTouch
		var local_position:=touch.position if position_is_viewer_local else _viewer_local_touch_position(touch.position)
		if touch.pressed and not _viewer_canvas_has_point(local_position):return false
		if not touch.pressed and not viewer_touch_positions.has(touch.index):return false
		var local_touch:=touch.duplicate() as InputEventScreenTouch;local_touch.position=local_position;_handle_viewer_touch(local_touch)
		return true
	if event is InputEventScreenDrag:
		var drag:=event as InputEventScreenDrag
		var local_position:=drag.position if position_is_viewer_local else _viewer_local_touch_position(drag.position)
		if not viewer_touch_positions.has(drag.index) and not _viewer_canvas_has_point(local_position):return false
		var local_drag:=drag.duplicate() as InputEventScreenDrag;local_drag.position=local_position;_handle_viewer_touch(local_drag)
		return true
	return false

func _editor_local_touch_position(screen_position:Vector2)->Vector2:
	return editor_canvas.get_global_transform_with_canvas().affine_inverse()*screen_position

func _editor_canvas_has_point(local_position:Vector2)->bool:
	return Rect2(Vector2.ZERO,editor_canvas.size).has_point(local_position)

func _viewer_local_touch_position(screen_position:Vector2)->Vector2:
	return viewer_canvas.get_global_transform_with_canvas().affine_inverse()*screen_position

func _viewer_canvas_has_point(local_position:Vector2)->bool:
	return Rect2(Vector2.ZERO,viewer_canvas.size).has_point(local_position)

func _on_home_world_scroll_input(event:InputEvent)->void:
	if world_backdrop_enabled and visible and home_page.visible:world_scroll_input.emit(event)

func _build_header(page:Control,title_key:String,back_callable:Callable,back_key:="back")->Label:
	var header_panel:=Panel.new();header_panel.position=Vector2(8,10);header_panel.size=Vector2(560,72);header_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;header_panel.add_theme_stylebox_override("panel",_box(Color(0.18,0.09,0.045,.72),Color(1.0,.82,.53,.32),22,1));page.add_child(header_panel)
	var back:=_button(GameLocalizer.text(language_code,back_key),Vector2(20,24),Vector2(108,54),Color("#f4dfb8"),16);_mark_localized(back,back_key);back.pressed.connect(back_callable);page.add_child(back)
	var title:=Label.new();_mark_localized(title,title_key);title.position=Vector2(132,25);title.size=Vector2(312,52);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",27);_style_overlay_label(title);page.add_child(title)
	return title

func _build_home_page()->void:
	_build_header(home_page,"arrangement_title",close)
	var hint:=Label.new();_mark_localized(hint,"arrangement_choose_pot_hint");hint.position=Vector2(30,91);hint.size=Vector2(516,36);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_font_size_override("font_size",18);_style_overlay_label(hint,Color("#ffe0a0"),4);home_page.add_child(hint)
	home_saved_button=_button(GameLocalizer.text(language_code,"arrangement_view_saved"),Vector2(118,136),Vector2(340,58),Color("#d7aa64"),19);_mark_localized(home_saved_button,"arrangement_view_saved");home_saved_button.pressed.connect(_open_saved_arrangements);home_page.add_child(home_saved_button)
	home_status=Label.new();home_status.position=Vector2(34,198);home_status.size=Vector2(508,64);home_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;home_status.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;home_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;home_status.add_theme_font_size_override("font_size",14);_style_overlay_label(home_status,Color("#ffd58a"),4);home_page.add_child(home_status)
	home_pot_scroll=ScrollContainer.new();home_pot_scroll.position=Vector2(24,208);home_pot_scroll.size=Vector2(528,738);home_pot_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;home_pot_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;home_pot_scroll.scroll_deadzone=12;home_pot_scroll.mouse_filter=Control.MOUSE_FILTER_STOP;home_page.add_child(home_pot_scroll)
	pot_select_grid=GridContainer.new();pot_select_grid.columns=2;pot_select_grid.custom_minimum_size=Vector2(510,0);pot_select_grid.mouse_filter=Control.MOUSE_FILTER_PASS;pot_select_grid.add_theme_constant_override("h_separation",10);pot_select_grid.add_theme_constant_override("v_separation",12);home_pot_scroll.add_child(pot_select_grid)

func _refresh_home()->void:
	var capacity_full:=_at_save_capacity()
	home_status.visible=capacity_full;home_status.text=GameLocalizer.text(language_code,"arrangement_save_limit_help") if capacity_full else ""
	home_pot_scroll.position.y=268.0 if capacity_full else 208.0;home_pot_scroll.size.y=678.0 if capacity_full else 738.0
	_refresh_pot_selection()

func _open_saved_arrangements()->void:
	viewer_gallery_mode=true;viewer_return_context="saved";selected_saved_arrangement_id="";selected_saved_arrangement_index=-1
	_cancel_viewer_gesture(false);_close_share_background_panel();_hide_dismantle_confirmation();set_share_state("",false);_show_page(viewer_page);_refresh_saved_arrangements(true)

func _return_from_saved_arrangements()->void:
	_show_page(home_page);_refresh_home()

func _refresh_saved_arrangements(select_newest:bool=false)->void:
	saved_arrangements_summary.text=GameLocalizer.text(language_code,"arrangement_summary",[saved_arrangements.size(),save_capacity,_owned_pot_count()])
	if saved_arrangements.is_empty():
		selected_saved_arrangement_id="";selected_saved_arrangement_index=-1;current_arrangement={};_clear_saved_arrangement_tabs();_clear_children(viewer_pot_layer);_clear_children(viewer_plant_layer);_apply_viewer_page_mode();return
	var target_index:=-1
	if select_newest:target_index=saved_arrangements.size()-1
	else:
		target_index=_saved_arrangement_index(selected_saved_arrangement_id)
		if target_index<0:target_index=clampi(selected_saved_arrangement_index,0,saved_arrangements.size()-1)
	var target:Dictionary=saved_arrangements[target_index]
	var target_id:=str(target.get("arrangement_id",""))
	var must_display:=select_newest or current_arrangement.is_empty() or str(current_arrangement.get("arrangement_id",""))!=target_id
	selected_saved_arrangement_index=target_index;selected_saved_arrangement_id=target_id;_rebuild_saved_arrangement_tabs()
	if must_display:_display_saved_arrangement(target)
	else:
		# State syncs caused by a background choice must not reset the live pan/zoom.
		current_arrangement["share_background_id"]=ShareBackgroundsClass.normalize_id(target.get("share_background_id",ShareBackgroundsClass.DEFAULT_ID));_apply_viewer_page_mode()

func _open_saved_arrangement(arrangement:Dictionary)->void:
	if not viewer_gallery_mode:_open_saved_arrangements()
	_select_saved_arrangement(str(arrangement.get("arrangement_id","")))

func _saved_arrangement_index(arrangement_id:String)->int:
	if arrangement_id.is_empty():return -1
	for index in range(saved_arrangements.size()):
		var value=saved_arrangements[index]
		if value is Dictionary and str(value.get("arrangement_id",""))==arrangement_id:return index
	return -1

func _select_saved_arrangement(arrangement_id:String)->void:
	var target_index:=_saved_arrangement_index(arrangement_id)
	if target_index<0 or arrangement_id==selected_saved_arrangement_id:return
	_cancel_viewer_gesture(false);_close_share_background_panel();_hide_dismantle_confirmation();set_share_state("",false)
	selected_saved_arrangement_id=arrangement_id;selected_saved_arrangement_index=target_index;_rebuild_saved_arrangement_tabs();_display_saved_arrangement(saved_arrangements[target_index])

func _display_saved_arrangement(arrangement:Dictionary)->void:
	current_arrangement=arrangement.duplicate(true);current_arrangement.erase("viewer_transform");current_arrangement["completed"]=true;current_arrangement["share_background_id"]=ShareBackgroundsClass.normalize_id(current_arrangement.get("share_background_id",ShareBackgroundsClass.DEFAULT_ID));viewer_name.text=str(current_arrangement.get("name",GameLocalizer.text(language_code,"arrangement_title")));_render_readonly_arrangement(current_arrangement);_apply_viewer_page_mode()

func _rebuild_saved_arrangement_tabs()->void:
	_clear_saved_arrangement_tabs()
	for arrangement_value in saved_arrangements:
		if not arrangement_value is Dictionary:continue
		var arrangement:Dictionary=arrangement_value;var arrangement_id:=str(arrangement.get("arrangement_id",""));var selected:=arrangement_id==selected_saved_arrangement_id
		var tab:=Button.new();tab.text=("✓ " if selected else "")+str(arrangement.get("name",GameLocalizer.text(language_code,"arrangement_title")));tab.custom_minimum_size=Vector2(164,30);tab.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;tab.tooltip_text=str(arrangement.get("name",""));_skin_button(tab,Color("#f6d993") if selected else Color("#ead4a5"),13);_prepare_scroll_button(tab);tab.pressed.connect(_select_saved_arrangement.bind(arrangement_id));saved_arrangements_tabs.add_child(tab)
		if selected:selected_saved_tab_button=tab
	if selected_saved_tab_button:call_deferred("_scroll_selected_saved_tab_into_view")

func _clear_saved_arrangement_tabs()->void:
	selected_saved_tab_button=null
	if saved_arrangements_tabs==null:return
	# Detach old tabs immediately so the ScrollContainer does not calculate its
	# deferred scroll target against old and new rows at the same time.
	for child in saved_arrangements_tabs.get_children():
		saved_arrangements_tabs.remove_child(child);child.queue_free()

func _scroll_selected_saved_tab_into_view()->void:
	# Containers resolve their new minimum width on the next frame. Waiting here
	# keeps the latest-work tab from being clamped against the previous width.
	await get_tree().process_frame
	if not is_instance_valid(selected_saved_tab_button) or not saved_arrangements_tab_scroll.is_ancestor_of(selected_saved_tab_button):return
	saved_arrangements_tab_scroll.ensure_control_visible(selected_saved_tab_button)
	var left:=selected_saved_tab_button.position.x;var right:=left+selected_saved_tab_button.size.x;var viewport_width:=saved_arrangements_tab_scroll.size.x
	var current:=float(saved_arrangements_tab_scroll.scroll_horizontal)
	if left<current:saved_arrangements_tab_scroll.scroll_horizontal=int(floor(left))
	elif right>current+viewport_width:saved_arrangements_tab_scroll.scroll_horizontal=int(ceil(right-viewport_width))

func _apply_viewer_page_mode()->void:
	if viewer_header_title:viewer_header_title.text=GameLocalizer.text(language_code,"arrangement_saved_title" if viewer_gallery_mode else "viewer_title")
	var has_work:=not current_arrangement.is_empty()
	if saved_arrangements_summary:saved_arrangements_summary.visible=viewer_gallery_mode
	if saved_arrangements_tab_scroll:saved_arrangements_tab_scroll.visible=viewer_gallery_mode and has_work
	if saved_arrangements_empty:
		saved_arrangements_empty.text=GameLocalizer.text(language_code,"arrangement_empty");saved_arrangements_empty.visible=viewer_gallery_mode and not has_work
	if viewer_name:viewer_name.visible=not viewer_gallery_mode and has_work
	for control in [viewer_canvas,viewer_share_button,viewer_share_background_button,viewer_dismantle_button]:
		if control:control.visible=has_work
	if not has_work:
		_close_share_background_panel()
		if viewer_share_status:viewer_share_status.visible=false

func _refresh_pot_selection()->void:
	_clear_children(pot_select_grid)
	var capacity_full:=_at_save_capacity()
	for pot_value in pot_catalog:
		if not pot_value is Dictionary:continue
		var pot:Dictionary=pot_value
		if not _pot_sales_stage_unlocked(pot):continue
		var pot_id:=str(pot.get("pot_id",""));var total:=_pot_total_count(pot_id);var available:=_pot_available_count(pot_id);var design_unlocked:=_pot_design_unlocked(pot);var selectable:=not capacity_full and design_unlocked and available>0
		var card:=Button.new();card.custom_minimum_size=Vector2(248,230);_skin_button(card,Color("#f4e1bc") if selectable else Color("#c9b8a2"),15);_prepare_scroll_button(card);card.disabled=not selectable;pot_select_grid.add_child(card)
		var preview:=Control.new();preview.position=Vector2(14,10);preview.size=Vector2(220,150);preview.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(preview);_render_pot(preview,pot,true)
		var availability_text:=GameLocalizer.text(language_code,"pot_iap_locked_short") if not design_unlocked else (GameLocalizer.text(language_code,"pot_not_owned") if total<=0 else (GameLocalizer.text(language_code,"pot_available_count",[available]) if available>0 else GameLocalizer.text(language_code,"pot_all_in_use")))
		var label:=Label.new();label.text=GameLocalizer.pot_name(language_code,pot)+"\n"+availability_text;label.position=Vector2(10,164);label.size=Vector2(228,56);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",16);label.add_theme_color_override("font_color",UI_BROWN);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(label)
		card.pressed.connect(_select_editor_pot.bind(pot_id))

func _select_editor_pot(pot_id:String)->void:
	if _at_save_capacity():
		current_arrangement={};editor_plants.clear();selected_plant_index=-1;_show_page(home_page);_refresh_home();return
	var pot:=_pot_entry(pot_id)
	if pot.is_empty() or not _pot_sales_stage_unlocked(pot) or not _pot_design_unlocked(pot) or _pot_available_count(pot_id)<=0:return
	current_arrangement={"arrangement_id":_new_arrangement_id(),"name":_default_arrangement_name(),"pot_id":pot_id,"created_at":Time.get_datetime_string_from_system(false,true),"completed":false,"plants":[],"share_background_id":ShareBackgroundsClass.DEFAULT_ID}
	_show_page(editor_page);_load_editor_from_current()

func _build_editor_page()->void:
	var header_panel:=Panel.new();header_panel.position=Vector2(8,10);header_panel.size=Vector2(560,72);header_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;header_panel.add_theme_stylebox_override("panel",_box(Color(0.18,0.09,0.045,.72),Color(1.0,.82,.53,.32),22,1));editor_page.add_child(header_panel)
	var back:=_button(GameLocalizer.text(language_code,"back"),Vector2(18,20),Vector2(98,50),Color("#f4dfb8"),15);_mark_localized(back,"back");back.pressed.connect(_return_home_from_editor);editor_page.add_child(back)
	editor_name=LineEdit.new();_mark_localized(editor_name,"arrangement_name",true);editor_name.position=Vector2(124,20);editor_name.size=Vector2(286,50);editor_name.add_theme_font_size_override("font_size",18);editor_name.add_theme_color_override("font_color",UI_BROWN);editor_name.add_theme_stylebox_override("normal",_box(Color("#fff3d8"),Color("#b47d49"),16,2));editor_page.add_child(editor_name)
	var save:=_button(GameLocalizer.text(language_code,"complete"),Vector2(418,20),Vector2(140,50),Color("#d7aa64"),15);_mark_localized(save,"complete");save.pressed.connect(_save_current_arrangement);editor_page.add_child(save)
	editor_canvas=Panel.new();editor_canvas.position=ARRANGEMENT_CANVAS_POSITION;editor_canvas.size=Vector2(536,552);editor_canvas.clip_contents=false;editor_canvas.mouse_filter=Control.MOUSE_FILTER_STOP;editor_canvas.add_theme_stylebox_override("panel",StyleBoxEmpty.new());editor_canvas.gui_input.connect(_on_editor_canvas_gui_input);editor_page.add_child(editor_canvas)
	editor_pot_layer=Control.new();editor_pot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);editor_pot_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;editor_canvas.add_child(editor_pot_layer)
	editor_plant_layer=Control.new();editor_plant_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);editor_plant_layer.z_index=PLANT_LAYER_Z;editor_plant_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;editor_canvas.add_child(editor_plant_layer)
	var message_panel:=Panel.new();message_panel.position=Vector2(20,700);message_panel.size=Vector2(536,43);message_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;message_panel.add_theme_stylebox_override("panel",_box(Color(0.18,0.09,0.045,.66),Color(1.0,.82,.53,.24),15,1));editor_page.add_child(message_panel)
	editor_message=Label.new();editor_message.position=Vector2(28,705);editor_message.size=Vector2(520,33);editor_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;editor_message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;editor_message.add_theme_font_size_override("font_size",15);_style_overlay_label(editor_message,Color("#ffe2a5"),4);editor_page.add_child(editor_message)
	add_plant_button=_button("＋ "+GameLocalizer.text(language_code,"add_succulent"),Vector2(154,746),Vector2(268,58),Color("#d7aa64"),20);add_plant_button.set_meta("locale_prefix","＋ ");_mark_localized(add_plant_button,"add_succulent");add_plant_button.pressed.connect(_open_species_picker);editor_page.add_child(add_plant_button)
	editor_selection_label=Label.new();editor_selection_label.visible=false;editor_page.add_child(editor_selection_label)
	var scale_minus:=_button("－",Vector2(28,812),Vector2(70,56),Color("#ead4a5"),22);scale_minus.pressed.connect(_adjust_selected_scale.bind(-PLANT_SCALE_STEP));editor_page.add_child(scale_minus);selected_controls.append(scale_minus)
	var scale_title:=Label.new();_mark_localized(scale_title,"size");scale_title.position=Vector2(100,812);scale_title.size=Vector2(84,56);scale_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;scale_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;scale_title.add_theme_font_size_override("font_size",16);_style_overlay_label(scale_title);editor_page.add_child(scale_title)
	var scale_plus:=_button("＋",Vector2(186,812),Vector2(70,56),Color("#ead4a5"),22);scale_plus.pressed.connect(_adjust_selected_scale.bind(PLANT_SCALE_STEP));editor_page.add_child(scale_plus);selected_controls.append(scale_plus)
	var rotate_left:=_button(GameLocalizer.text(language_code,"rotate_left"),Vector2(272,812),Vector2(70,56),Color("#ead4a5"),13);_mark_localized(rotate_left,"rotate_left");rotate_left.pressed.connect(_adjust_selected_rotation.bind(-PLANT_ROTATION_STEP));editor_page.add_child(rotate_left);selected_controls.append(rotate_left)
	var rotate_title:=Label.new();_mark_localized(rotate_title,"rotate");rotate_title.position=Vector2(344,812);rotate_title.size=Vector2(84,56);rotate_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;rotate_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;rotate_title.add_theme_font_size_override("font_size",16);_style_overlay_label(rotate_title);editor_page.add_child(rotate_title)
	var rotate_right:=_button(GameLocalizer.text(language_code,"rotate_right"),Vector2(430,812),Vector2(70,56),Color("#ead4a5"),13);_mark_localized(rotate_right,"rotate_right");rotate_right.pressed.connect(_adjust_selected_rotation.bind(PLANT_ROTATION_STEP));editor_page.add_child(rotate_right);selected_controls.append(rotate_right)
	var back_depth:=_button(GameLocalizer.text(language_code,"send_back"),Vector2(42,876),Vector2(140,58),Color("#c8ae88"),17);_mark_localized(back_depth,"send_back");back_depth.pressed.connect(_change_selected_depth.bind(-1));editor_page.add_child(back_depth);selected_controls.append(back_depth)
	var front_depth:=_button(GameLocalizer.text(language_code,"bring_front"),Vector2(218,876),Vector2(140,58),Color("#d7aa64"),17);_mark_localized(front_depth,"bring_front");front_depth.pressed.connect(_change_selected_depth.bind(1));editor_page.add_child(front_depth);selected_controls.append(front_depth)
	var delete:=_button(GameLocalizer.text(language_code,"delete"),Vector2(394,876),Vector2(140,58),Color("#b87962"),17);_mark_localized(delete,"delete");delete.pressed.connect(_delete_selected_plant);editor_page.add_child(delete);selected_controls.append(delete)

func _load_editor_from_current()->void:
	if bool(current_arrangement.get("completed",false)):_open_viewer(current_arrangement);return
	editor_name.text=str(current_arrangement.get("name",_default_arrangement_name()))
	editor_plants=_plant_array(current_arrangement).duplicate(true)
	_cancel_editor_gesture();selected_plant_index=-1;editor_message.text="";_rebuild_editor_scene()

func _rebuild_editor_scene()->void:
	_clear_children(editor_pot_layer);_clear_children(editor_plant_layer);editor_plant_nodes.clear()
	var pot:=_pot_entry(str(current_arrangement.get("pot_id","")));_render_editor_pot(pot)
	for index in range(editor_plants.size()):_create_editor_plant(index)
	_update_editor_selection();add_plant_button.disabled=editor_plants.size()>=MAX_PLANTS_PER_ARRANGEMENT

func _render_editor_pot(pot:Dictionary)->void:
	if pot.is_empty():return
	var holder:=Control.new();holder.size=POT_HOLDER_SIZE;holder.position=_pot_holder_position(editor_canvas,holder.size);holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;editor_pot_layer.add_child(holder);_render_pot(holder,pot,false)

func _create_editor_plant(index:int)->void:
	var plant:Dictionary=editor_plants[index];var entry:=_species_entry(str(plant.get("species_id","")));var texture:=_resolve_texture(entry)
	if texture==null:editor_plant_nodes.append(null);return
	var root:=Control.new();root.size=PLANT_CONTROL_SIZE;root.pivot_offset=PLANT_CONTROL_SIZE*.5;root.position=Vector2(float(plant.get("x",editor_canvas.size.x*.5)),float(plant.get("y",editor_canvas.size.y*.42)))-PLANT_CONTROL_SIZE*.5;root.scale=Vector2.ONE*clampf(float(plant.get("scale",PLANT_SCALE_MIN)),PLANT_SCALE_MIN,_plant_scale_max(plant));root.rotation_degrees=fposmod(float(plant.get("rotation",0.0)),360.0);root.z_index=int(plant.get("z_index",index));root.mouse_filter=Control.MOUSE_FILTER_IGNORE;editor_plant_layer.add_child(root)
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
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		# Fallback for mobile ports which deliver a finger only to the Control. The
		# viewport path marks handled events, so the same event cannot run twice.
		if _route_editor_touch_event(event,true):accept_event()

func _on_viewer_canvas_gui_input(event:InputEvent)->void:
	if _share_background_panel_is_open():return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:_begin_viewer_drag(-1,event.position)
		else:_finish_viewer_pointer(-1)
		accept_event()
	elif event is InputEventMouseMotion:
		if viewer_drag_active and viewer_drag_pointer_id==-1:_update_viewer_drag(event.position)
		accept_event()
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		# Fallback for ports which deliver a finger only to the Control. Viewport
		# input marks handled events, so a touch cannot transform the work twice.
		if _route_viewer_touch_event(event,true):accept_event()

func _install_web_multitouch_fallback()->void:
	if not OS.has_feature("web"):return
	var document=JavaScriptBridge.get_interface("document")
	if document==null:return
	web_touch_canvas=document.getElementById("canvas")
	if web_touch_canvas==null:return
	web_touch_canvas.style.touchAction="none";web_touch_canvas.style.overscrollBehavior="none"
	web_touch_callback=JavaScriptBridge.create_callback(_on_web_touch_event)
	web_touch_listener_options=JavaScriptBridge.eval("({capture:true,passive:false})",true)
	for event_name in ["touchstart","touchmove","touchend","touchcancel"]:
		web_touch_canvas.addEventListener(event_name,web_touch_callback,web_touch_listener_options)

func _remove_web_multitouch_fallback()->void:
	if web_touch_canvas!=null and web_touch_callback!=null:
		for event_name in ["touchstart","touchmove","touchend","touchcancel"]:
			web_touch_canvas.removeEventListener(event_name,web_touch_callback,web_touch_listener_options)
	web_touch_canvas=null;web_touch_callback=null;web_touch_listener_options=null

func _on_web_touch_event(arguments:Array)->void:
	if arguments.is_empty() or web_touch_canvas==null:return
	var event=arguments[0]
	if event==null:return
	var touches=event.touches
	if touches==null:return
	var touch_count:=int(touches.length)
	var event_type:=str(event.type)
	if is_viewer_active():
		if web_multitouch_active or web_multitouch_suppress_native:_reset_web_multitouch_state()
		if _share_background_panel_is_open():
			if viewer_web_multitouch_active or viewer_web_multitouch_suppress_native:_reset_viewer_web_multitouch_state(true)
			return
		if touch_count<2 and not viewer_web_multitouch_active:
			if viewer_web_multitouch_suppress_native and event_type=="touchstart":
				# Keep suppression through the trailing Godot touchend mirror, then
				# return the next one-finger gesture to the native path.
				viewer_web_multitouch_suppress_native=false
				return
			if not viewer_web_multitouch_suppress_native:return
		if bool(event.cancelable):event.preventDefault()
		var viewer_rect=web_touch_canvas.getBoundingClientRect();var viewer_rect_size:=Vector2(maxf(1.0,float(viewer_rect.width)),maxf(1.0,float(viewer_rect.height)));var viewer_viewport_size:=get_viewport().get_visible_rect().size
		var viewer_positions:Dictionary={}
		for index in range(touch_count):
			var viewer_touch=touches.item(index)
			if viewer_touch==null:continue
			var viewer_screen_position:=_web_touch_viewport_position(Vector2(float(viewer_touch.clientX),float(viewer_touch.clientY)),Vector2(float(viewer_rect.left),float(viewer_rect.top)),viewer_rect_size,viewer_viewport_size)
			viewer_positions[int(viewer_touch.identifier)]=_viewer_local_touch_position(viewer_screen_position)
		_handle_viewer_web_multitouch_snapshot(viewer_positions)
		return
	if viewer_web_multitouch_active or viewer_web_multitouch_suppress_native:_reset_viewer_web_multitouch_state(false)
	if not is_editor_active():
		if web_multitouch_active or web_multitouch_suppress_native:_reset_web_multitouch_state()
		return
	if touch_count<2 and not web_multitouch_active:
		if web_multitouch_suppress_native and event_type=="touchstart":
			# Keep suppression through the trailing native touchend mirror, then let
			# the first finger of the next gesture resume the normal Godot path.
			web_multitouch_suppress_native=false
			return
		if not web_multitouch_suppress_native:return
	if bool(event.cancelable):event.preventDefault()
	var rect=web_touch_canvas.getBoundingClientRect();var rect_size:=Vector2(maxf(1.0,float(rect.width)),maxf(1.0,float(rect.height)));var viewport_size:=get_viewport().get_visible_rect().size
	var positions:Dictionary={}
	for index in range(touch_count):
		var touch=touches.item(index)
		if touch==null:continue
		var screen_position:=_web_touch_viewport_position(Vector2(float(touch.clientX),float(touch.clientY)),Vector2(float(rect.left),float(rect.top)),rect_size,viewport_size)
		positions[int(touch.identifier)]=_editor_local_touch_position(screen_position)
	_handle_web_multitouch_snapshot(positions)

func _web_touch_viewport_position(client_position:Vector2,canvas_position:Vector2,canvas_size:Vector2,viewport_size:Vector2)->Vector2:
	# Godot keeps the 576x1024 game aspect inside the browser canvas. The canvas
	# itself includes any pillar/letterbox area, so independently scaling X/Y
	# distorts pinch distance and rotation on phones and wide desktop windows.
	var content_scale:=minf(canvas_size.x/maxf(1.0,viewport_size.x),canvas_size.y/maxf(1.0,viewport_size.y))
	content_scale=maxf(content_scale,0.0001)
	var content_offset:=(canvas_size-viewport_size*content_scale)*0.5
	return (client_position-canvas_position-content_offset)/content_scale

func _handle_web_multitouch_snapshot(positions:Dictionary)->void:
	if positions.size()>=2:
		if not web_multitouch_active:
			var inside_count:=0
			for point_value in positions.values():
				if _editor_canvas_has_point(point_value as Vector2):inside_count+=1
			if inside_count<2:return
			if selected_plant_index<0:
				for point_value in positions.values():
					var hit_index:=_plant_index_at(point_value as Vector2)
					if hit_index>=0:_select_plant(hit_index);break
			if selected_plant_index<0:return
			web_multitouch_active=true;web_multitouch_suppress_native=true;touch_positions=positions.duplicate(true);pinch_target_index=selected_plant_index;_cancel_background_for_pinch();_begin_pinch()
		else:
			touch_positions=positions.duplicate(true);_update_pinch_transform()
		return
	if web_multitouch_active:
		web_multitouch_active=false
		if pinch_active:_finish_selected_gesture(GameLocalizer.text(language_code,"arrangement_gesture_transform"))
		touch_positions.clear();pinch_target_index=-1

func _reset_web_multitouch_state()->void:
	web_multitouch_active=false;web_multitouch_suppress_native=false;touch_positions.clear();pinch_target_index=-1
	if pinch_active:_finish_selected_gesture(GameLocalizer.text(language_code,"arrangement_gesture_transform"))

func _handle_viewer_web_multitouch_snapshot(positions:Dictionary)->void:
	if positions.size()>=2:
		if not viewer_web_multitouch_active:
			var inside_count:=0
			for point_value in positions.values():
				if _viewer_canvas_has_point(point_value as Vector2):inside_count+=1
			if inside_count<2:return
			viewer_web_multitouch_active=true;viewer_web_multitouch_suppress_native=true;viewer_drag_active=false;viewer_drag_pointer_id=-999;viewer_touch_positions=positions.duplicate(true);_begin_viewer_pinch()
		else:
			viewer_touch_positions=positions.duplicate(true);_update_viewer_pinch()
		return
	if viewer_web_multitouch_active:
		viewer_web_multitouch_active=false
		_finish_viewer_gesture(true)
		viewer_touch_positions.clear()

func _reset_viewer_web_multitouch_state(commit_changes:bool)->void:
	viewer_web_multitouch_active=false;viewer_web_multitouch_suppress_native=false
	if viewer_pinch_active:_finish_viewer_gesture(commit_changes)
	viewer_touch_positions.clear()

func _handle_editor_touch(event:InputEvent)->void:
	if event is InputEventScreenTouch:
		var touch:=event as InputEventScreenTouch
		if touch.pressed:
			var is_first_touch:=touch_positions.is_empty()
			touch_positions[touch.index]=touch.position;_begin_canvas_pointer(touch.index,touch.position,touch)
			if is_first_touch:pinch_target_index=selected_plant_index
		else:
			_end_canvas_pointer(touch.index,touch.position,touch);touch_positions.erase(touch.index)
			if touch_positions.is_empty():pinch_target_index=-1
	elif event is InputEventScreenDrag:
		var drag:=event as InputEventScreenDrag
		touch_positions[drag.index]=drag.position;_update_canvas_pointer(drag.index,drag.position,drag)

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
		pinch_active=false;pinch_touch_ids.clear();_finish_selected_gesture(GameLocalizer.text(language_code,"arrangement_gesture_transform"))
	elif drag_active and drag_pointer_id==pointer_id:_finish_selected_gesture(GameLocalizer.text(language_code,"arrangement_gesture_move"))
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
	pinch_start_distance=maxf(gesture_vector.length(),1.0);pinch_start_angle=gesture_vector.angle();pinch_start_scale=float(editor_plants[selected_plant_index].get("scale",1.0));pinch_start_rotation=float(editor_plants[selected_plant_index].get("rotation",0.0));editor_message.text=GameLocalizer.text(language_code,"arrangement_pinch_hint")

func _update_pinch_transform()->void:
	if not pinch_active or pinch_touch_ids.size()<2 or selected_plant_index<0:return
	if not touch_positions.has(pinch_touch_ids[0]) or not touch_positions.has(pinch_touch_ids[1]):return
	var first:Vector2=touch_positions[pinch_touch_ids[0]];var second:Vector2=touch_positions[pinch_touch_ids[1]];var gesture_vector:=second-first;var distance:=maxf(gesture_vector.length(),1.0)
	var angle_delta:=wrapf(gesture_vector.angle()-pinch_start_angle,-PI,PI)
	var plant:Dictionary=editor_plants[selected_plant_index];plant["scale"]=clampf(pinch_start_scale*distance/pinch_start_distance,PLANT_SCALE_MIN,_plant_scale_max(plant));plant["rotation"]=fposmod(pinch_start_rotation+rad_to_deg(angle_delta),360.0);editor_plants[selected_plant_index]=plant;_apply_plant_transform(selected_plant_index)

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
	drag_active=false;drag_pointer_id=-999;pinch_active=false;pinch_touch_ids.clear();touch_positions.clear();pinch_target_index=-1;pinch_start_angle=0.0;pinch_start_rotation=0.0;web_multitouch_active=false;web_multitouch_suppress_native=false;_clear_background_pointer()

static func normalize_viewer_transform(value:Variant)->Dictionary:
	var source:Dictionary={}
	if value is Dictionary:source=value
	var position_x:=float(source.get("x",0.0))
	var position_y:=float(source.get("y",0.0))
	var scale_value:=float(source.get("scale",VIEWER_SCALE_DEFAULT))
	if is_nan(position_x) or is_inf(position_x):position_x=0.0
	if is_nan(position_y) or is_inf(position_y):position_y=0.0
	if is_nan(scale_value) or is_inf(scale_value):scale_value=VIEWER_SCALE_DEFAULT
	return {"x":position_x,"y":position_y,"scale":clampf(scale_value,VIEWER_SCALE_MIN,VIEWER_SCALE_MAX)}

func _handle_viewer_touch(event:InputEvent)->void:
	if event is InputEventScreenTouch:
		var touch:=event as InputEventScreenTouch
		if touch.pressed:
			viewer_touch_positions[touch.index]=touch.position
			if viewer_touch_positions.size()>=2:_begin_viewer_pinch()
			else:_begin_viewer_drag(touch.index,touch.position)
		else:
			viewer_touch_positions.erase(touch.index)
			if viewer_pinch_active and touch.index in viewer_pinch_touch_ids:_finish_viewer_gesture(true)
			elif viewer_drag_active and viewer_drag_pointer_id==touch.index:_finish_viewer_gesture(true)
	elif event is InputEventScreenDrag:
		var drag:=event as InputEventScreenDrag
		viewer_touch_positions[drag.index]=drag.position
		if viewer_pinch_active:_update_viewer_pinch()
		elif viewer_touch_positions.size()>=2:_begin_viewer_pinch()
		elif viewer_drag_active and viewer_drag_pointer_id==drag.index:_update_viewer_drag(drag.position)

func _begin_viewer_drag(pointer_id:int,pointer_position:Vector2)->void:
	if not is_viewer_active() or viewer_artwork_root==null:return
	viewer_drag_active=true;viewer_drag_pointer_id=pointer_id;viewer_drag_last_position=pointer_position

func _update_viewer_drag(pointer_position:Vector2)->void:
	if not viewer_drag_active or viewer_artwork_root==null:return
	var delta:=pointer_position-viewer_drag_last_position
	viewer_drag_last_position=pointer_position
	if delta.is_zero_approx():return
	_set_viewer_artwork_transform(viewer_artwork_root.position+delta,viewer_artwork_root.scale.x,true)

func _finish_viewer_pointer(pointer_id:int)->void:
	if viewer_drag_active and viewer_drag_pointer_id==pointer_id:_finish_viewer_gesture(true)

func _begin_viewer_pinch()->void:
	if viewer_artwork_root==null or viewer_touch_positions.size()<2:return
	viewer_drag_active=false;viewer_drag_pointer_id=-999;viewer_pinch_active=true;viewer_pinch_touch_ids.clear()
	var pointer_ids:Array=[]
	for pointer_value in viewer_touch_positions.keys():pointer_ids.append(int(pointer_value))
	pointer_ids.sort()
	for pointer_value in pointer_ids:
		viewer_pinch_touch_ids.append(int(pointer_value))
		if viewer_pinch_touch_ids.size()>=2:break
	var first:Vector2=viewer_touch_positions.get(viewer_pinch_touch_ids[0],Vector2.ZERO);var second:Vector2=viewer_touch_positions.get(viewer_pinch_touch_ids[1],Vector2.ZERO)
	viewer_pinch_start_distance=maxf(first.distance_to(second),1.0);viewer_pinch_start_scale=viewer_artwork_root.scale.x;viewer_pinch_start_position=viewer_artwork_root.position;viewer_pinch_start_midpoint=(first+second)*.5

func _update_viewer_pinch()->void:
	if not viewer_pinch_active or viewer_pinch_touch_ids.size()<2 or viewer_artwork_root==null:return
	if not viewer_touch_positions.has(viewer_pinch_touch_ids[0]) or not viewer_touch_positions.has(viewer_pinch_touch_ids[1]):return
	var first:Vector2=viewer_touch_positions[viewer_pinch_touch_ids[0]];var second:Vector2=viewer_touch_positions[viewer_pinch_touch_ids[1]];var midpoint:=(first+second)*.5
	var scale_value:=clampf(viewer_pinch_start_scale*maxf(first.distance_to(second),1.0)/viewer_pinch_start_distance,VIEWER_SCALE_MIN,VIEWER_SCALE_MAX)
	var artwork_point:=(viewer_pinch_start_midpoint-viewer_pinch_start_position)/maxf(viewer_pinch_start_scale,0.001)
	_set_viewer_artwork_transform(midpoint-artwork_point*scale_value,scale_value,true)

func _set_viewer_artwork_transform(position_value:Vector2,scale_value:float,_mark_dirty:bool=false)->void:
	if viewer_artwork_root==null:return
	var safe_scale:=clampf(scale_value,VIEWER_SCALE_MIN,VIEWER_SCALE_MAX)
	var safe_position:=_clamp_viewer_position(position_value,safe_scale)
	viewer_artwork_root.position=safe_position;viewer_artwork_root.scale=Vector2.ONE*safe_scale;viewer_artwork_root.rotation=0.0

func _clamp_viewer_position(position_value:Vector2,scale_value:float)->Vector2:
	if viewer_canvas==null:return position_value
	var scaled_size:=viewer_canvas.size*scale_value
	var minimum:=Vector2(VIEWER_MIN_VISIBLE_PIXELS,VIEWER_MIN_VISIBLE_PIXELS)-scaled_size
	var maximum:=viewer_canvas.size-Vector2(VIEWER_MIN_VISIBLE_PIXELS,VIEWER_MIN_VISIBLE_PIXELS)
	return Vector2(clampf(position_value.x,minimum.x,maximum.x),clampf(position_value.y,minimum.y,maximum.y))

func _viewer_transform_state()->Dictionary:
	if viewer_artwork_root==null:return normalize_viewer_transform({})
	return {"x":viewer_artwork_root.position.x,"y":viewer_artwork_root.position.y,"scale":viewer_artwork_root.scale.x}

func _restore_viewer_transform(_arrangement:Dictionary={})->void:
	# Finished-work framing is deliberately session-only. Legacy save metadata is
	# ignored whenever a work is newly displayed.
	_set_viewer_artwork_transform(Vector2.ZERO,VIEWER_SCALE_DEFAULT,false)

func _finish_viewer_gesture(_commit_changes:bool=false)->void:
	viewer_drag_active=false;viewer_drag_pointer_id=-999;viewer_pinch_active=false;viewer_pinch_touch_ids.clear()

func _cancel_viewer_gesture(commit_changes:bool)->void:
	_finish_viewer_gesture(commit_changes);viewer_touch_positions.clear();viewer_web_multitouch_active=false;viewer_web_multitouch_suppress_native=false

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
	var plant:Dictionary=editor_plants[index];node.position=Vector2(float(plant.get("x",0.0)),float(plant.get("y",0.0)))-PLANT_CONTROL_SIZE*.5;node.scale=Vector2.ONE*clampf(float(plant.get("scale",PLANT_SCALE_MIN)),PLANT_SCALE_MIN,_plant_scale_max(plant));node.rotation_degrees=fposmod(float(plant.get("rotation",0.0)),360.0);node.z_index=int(plant.get("z_index",index));_update_editor_selection()

func _adjust_selected_scale(amount:float)->void:
	if bool(current_arrangement.get("completed",false)) or selected_plant_index<0:return
	var plant:Dictionary=editor_plants[selected_plant_index];plant["scale"]=snappedf(clampf(float(plant.get("scale",PLANT_SCALE_MIN))+amount,PLANT_SCALE_MIN,_plant_scale_max(plant)),.01);editor_plants[selected_plant_index]=plant;_apply_plant_transform(selected_plant_index)

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
	editor_plants.remove_at(selected_plant_index);selected_plant_index=-1;editor_message.text=GameLocalizer.text(language_code,"arrangement_deleted");_rebuild_editor_scene()

func _return_home_from_editor()->void:
	drag_active=false;_show_page(home_page);_refresh_home()

func _build_picker_page()->void:
	_build_header(picker_page,"picker_title",_return_to_editor,"edit_back")
	picker_filter=OptionButton.new();picker_filter.position=Vector2(145,91);picker_filter.size=Vector2(286,52);picker_filter.add_theme_font_size_override("font_size",17);picker_filter.item_selected.connect(_on_picker_filter_changed);picker_page.add_child(picker_filter)
	var hint:=Label.new();_mark_localized(hint,"picker_hint");hint.position=Vector2(26,151);hint.size=Vector2(524,32);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_font_size_override("font_size",15);_style_overlay_label(hint,Color("#ffe0a0"),4);picker_page.add_child(hint)
	picker_scroll=ScrollContainer.new();picker_scroll.position=Vector2(24,194);picker_scroll.size=Vector2(528,790);picker_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;picker_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;picker_scroll.scroll_deadzone=12;picker_scroll.mouse_filter=Control.MOUSE_FILTER_STOP;picker_page.add_child(picker_scroll)
	picker_grid=GridContainer.new();picker_grid.columns=2;picker_grid.custom_minimum_size=Vector2(510,0);picker_grid.mouse_filter=Control.MOUSE_FILTER_PASS;picker_grid.add_theme_constant_override("h_separation",10);picker_grid.add_theme_constant_override("v_separation",10);picker_scroll.add_child(picker_grid)

func _open_species_picker()->void:
	if bool(current_arrangement.get("completed",false)):return
	if editor_plants.size()>=MAX_PLANTS_PER_ARRANGEMENT:editor_message.text=GameLocalizer.text(language_code,"arrangement_max_plants",[MAX_PLANTS_PER_ARRANGEMENT]);return
	_show_page(picker_page);_refresh_picker_filters();_refresh_species_picker();picker_scroll.scroll_vertical=0

func _refresh_picker_filters()->void:
	picker_filter.clear();picker_filter.add_item(GameLocalizer.text(language_code,"all"));picker_filter.set_item_metadata(0,"all")
	for series_value in series_catalog:
		if not series_value is Dictionary:continue
		var series:Dictionary=series_value;var series_id:=str(series.get("series_id",""))
		if _available_species_entries(series_id).is_empty():continue
		picker_filter.add_item(GameLocalizer.series_name(language_code,series));picker_filter.set_item_metadata(picker_filter.item_count-1,series_id)
	picker_filter.select(0)

func _on_picker_filter_changed(_index:int)->void:
	_refresh_species_picker()

func _refresh_species_picker()->void:
	_clear_children(picker_grid)
	var filter_id:="all"
	if picker_filter.item_count>0:filter_id=str(picker_filter.get_item_metadata(picker_filter.selected))
	var available:=_available_species_entries(filter_id)
	if available.is_empty():
		var empty:=Label.new();empty.text=GameLocalizer.text(language_code,"picker_empty");empty.custom_minimum_size=Vector2(500,100);empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;empty.add_theme_color_override("font_color",UI_CREAM);picker_grid.add_child(empty);return
	for entry in available:
		var species_id:=str(entry.get("species_id",""));var texture:=_resolve_texture(entry)
		var card:=Button.new();card.custom_minimum_size=Vector2(248,150);_skin_button(card,Color("#f4e1bc"),15);_prepare_scroll_button(card);card.disabled=texture==null;picker_grid.add_child(card)
		var image_frame:=Control.new();image_frame.position=Vector2(8,12);image_frame.size=Vector2(112,112);image_frame.clip_contents=true;image_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(image_frame)
		var image:=TextureRect.new();image.texture=texture;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;image_frame.add_child(image);_request_texture(entry,image,false)
		var max_cm:=float(species_bests.get(species_id,0.0));var size_line:=GameLocalizer.text(language_code,"no_record_min") if max_cm<=0.0 else GameLocalizer.text(language_code,"max_cm",[max_cm])
		var label:=Label.new();label.text=GameLocalizer.species_name(language_code,entry)+("\n"+GameLocalizer.text(language_code,"image_preparing") if texture==null else "\n"+size_line);label.position=Vector2(121,12);label.size=Vector2(117,126);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",13);label.add_theme_color_override("font_color",UI_BROWN);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(label)
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
	var initial_scale:=minf(1.0,_species_scale_max(species_id))
	editor_plants.append({"species_id":species_id,"x":center.x,"y":center.y,"scale":initial_scale,"rotation":0.0,"z_index":index})
	_show_page(editor_page);_rebuild_editor_scene();_select_plant(editor_plants.size()-1);editor_message.text=GameLocalizer.text(language_code,"arrangement_added",[GameLocalizer.species_name(language_code,entry)])

func _return_to_editor()->void:
	_show_page(editor_page);_rebuild_editor_scene()

func _save_current_arrangement()->void:
	if current_arrangement.is_empty() or bool(current_arrangement.get("completed",false)):return
	var current_pot_id:=str(current_arrangement.get("pot_id",DEFAULT_POT_ID))
	var current_pot:=_pot_entry(current_pot_id)
	if current_pot.is_empty() or not _pot_sales_stage_unlocked(current_pot) or not _pot_design_unlocked(current_pot):
		editor_message.text=GameLocalizer.text(language_code,"pot_unlock_required")
		return
	if _pot_available_count(current_pot_id)<=0:
		editor_message.text=GameLocalizer.text(language_code,"pot_save_unavailable")
		return
	var name:=editor_name.text.strip_edges()
	if name.is_empty():name=_default_arrangement_name();editor_name.text=name
	_cancel_editor_gesture();selected_plant_index=-1;_update_editor_selection()
	var saved:={"arrangement_id":str(current_arrangement.get("arrangement_id",_new_arrangement_id())),"name":name,"pot_id":str(current_arrangement.get("pot_id",DEFAULT_POT_ID)),"created_at":str(current_arrangement.get("created_at",Time.get_datetime_string_from_system(false,true))),"completed":true,"plants":editor_plants.duplicate(true),"share_background_id":ShareBackgroundsClass.normalize_id(current_arrangement.get("share_background_id",ShareBackgroundsClass.DEFAULT_ID))}
	save_request_accepted=false;save_requested.emit(saved.duplicate(true))
	if not save_request_accepted:return
	current_arrangement=saved.duplicate(true)
	completion_overlay.visible=true;completion_confetti_requested.emit(completion_confetti_layer)
	await get_tree().create_timer(COMPLETION_DISPLAY_SECONDS).timeout
	_clear_completion_overlay()
	if visible:_open_viewer(saved)

func _build_viewer_page()->void:
	viewer_header_title=_build_header(viewer_page,"viewer_title",_return_from_viewer)
	for header_control in viewer_page.get_children():
		if header_control is Control:(header_control as Control).z_index=500
	saved_arrangements_summary=Label.new();saved_arrangements_summary.position=Vector2(32,82);saved_arrangements_summary.size=Vector2(512,24);saved_arrangements_summary.z_index=500;saved_arrangements_summary.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;saved_arrangements_summary.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;saved_arrangements_summary.add_theme_font_size_override("font_size",13);_style_overlay_label(saved_arrangements_summary,Color("#ffe0a0"),4);saved_arrangements_summary.visible=false;viewer_page.add_child(saved_arrangements_summary)
	saved_arrangements_tab_scroll=ScrollContainer.new();saved_arrangements_tab_scroll.position=Vector2(24,106);saved_arrangements_tab_scroll.size=Vector2(528,44);saved_arrangements_tab_scroll.z_index=500;saved_arrangements_tab_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;saved_arrangements_tab_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;saved_arrangements_tab_scroll.scroll_deadzone=10;saved_arrangements_tab_scroll.mouse_filter=Control.MOUSE_FILTER_STOP;saved_arrangements_tab_scroll.visible=false;viewer_page.add_child(saved_arrangements_tab_scroll)
	saved_arrangements_tabs=HBoxContainer.new();saved_arrangements_tabs.custom_minimum_size=Vector2(0,30);saved_arrangements_tabs.mouse_filter=Control.MOUSE_FILTER_PASS;saved_arrangements_tabs.add_theme_constant_override("separation",8);saved_arrangements_tab_scroll.add_child(saved_arrangements_tabs)
	saved_arrangements_empty=Label.new();saved_arrangements_empty.position=Vector2(48,300);saved_arrangements_empty.size=Vector2(480,150);saved_arrangements_empty.z_index=500;saved_arrangements_empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;saved_arrangements_empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;saved_arrangements_empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;saved_arrangements_empty.add_theme_font_size_override("font_size",18);_style_overlay_label(saved_arrangements_empty,Color("#f8deb5"),4);saved_arrangements_empty.visible=false;viewer_page.add_child(saved_arrangements_empty)
	viewer_name=Label.new();viewer_name.position=Vector2(30,90);viewer_name.size=Vector2(516,48);viewer_name.z_index=500;viewer_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;viewer_name.add_theme_font_size_override("font_size",24);_style_overlay_label(viewer_name,Color("#ffe0a0"),5);viewer_page.add_child(viewer_name)
	viewer_canvas=Panel.new();viewer_canvas.position=ARRANGEMENT_CANVAS_POSITION;viewer_canvas.size=Vector2(536,552);viewer_canvas.clip_contents=false;viewer_canvas.mouse_filter=Control.MOUSE_FILTER_STOP;viewer_canvas.gui_input.connect(_on_viewer_canvas_gui_input);viewer_canvas.add_theme_stylebox_override("panel",StyleBoxEmpty.new());viewer_page.add_child(viewer_canvas)
	viewer_artwork_root=Control.new();viewer_artwork_root.name="ViewerArtworkRoot";viewer_artwork_root.size=viewer_canvas.size;viewer_artwork_root.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewer_canvas.add_child(viewer_artwork_root)
	viewer_pot_layer=Control.new();viewer_pot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);viewer_pot_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewer_artwork_root.add_child(viewer_pot_layer)
	viewer_plant_layer=Control.new();viewer_plant_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);viewer_plant_layer.z_index=PLANT_LAYER_Z;viewer_plant_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewer_artwork_root.add_child(viewer_plant_layer)
	viewer_share_button=_button(GameLocalizer.text(language_code,"share_action"),Vector2(28,790),Vector2(248,58),Color("#d7aa64"),18);viewer_share_button.z_index=500;_mark_localized(viewer_share_button,"share_action");viewer_share_button.pressed.connect(_request_current_arrangement_share);viewer_page.add_child(viewer_share_button)
	viewer_share_background_button=_button(GameLocalizer.text(language_code,"share_background"),Vector2(300,790),Vector2(248,58),Color("#d7aa64"),18);viewer_share_background_button.z_index=500;_mark_localized(viewer_share_background_button,"share_background");viewer_share_background_button.pressed.connect(_toggle_share_background_panel);viewer_page.add_child(viewer_share_background_button)
	viewer_share_status=Label.new();viewer_share_status.position=Vector2(28,852);viewer_share_status.size=Vector2(520,34);viewer_share_status.z_index=500;viewer_share_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;viewer_share_status.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;viewer_share_status.add_theme_font_size_override("font_size",14);_style_overlay_label(viewer_share_status,Color("#ffe0a0"),4);viewer_share_status.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewer_share_status.visible=false;viewer_page.add_child(viewer_share_status)
	viewer_dismantle_button=_button(GameLocalizer.text(language_code,"arrangement_dismantle"),Vector2(154,892),Vector2(268,58),Color("#b87962"),18);viewer_dismantle_button.z_index=500;_mark_localized(viewer_dismantle_button,"arrangement_dismantle");viewer_dismantle_button.pressed.connect(_show_dismantle_confirmation);viewer_page.add_child(viewer_dismantle_button)
	_build_share_background_panel()
	_apply_viewer_page_mode()

func _build_share_background_panel()->void:
	share_background_panel=Panel.new();share_background_panel.position=Vector2(12,430);share_background_panel.size=Vector2(552,552);share_background_panel.z_index=700;share_background_panel.clip_contents=true;share_background_panel.mouse_filter=Control.MOUSE_FILTER_STOP;share_background_panel.visible=false;share_background_panel.add_theme_stylebox_override("panel",_box(Color("#f6e6c7"),Color("#b77c48"),26,4));viewer_page.add_child(share_background_panel)
	var title:=Label.new();_mark_localized(title,"share_background");title.position=Vector2(24,16);title.size=Vector2(394,52);title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",24);title.add_theme_color_override("font_color",UI_BROWN);title.mouse_filter=Control.MOUSE_FILTER_IGNORE;share_background_panel.add_child(title)
	var close_button:=_button(GameLocalizer.text(language_code,"close"),Vector2(444,14),Vector2(88,52),Color("#ead4a5"),15);_mark_localized(close_button,"close");close_button.pressed.connect(_close_share_background_panel);share_background_panel.add_child(close_button)
	share_background_scroll=ScrollContainer.new();share_background_scroll.position=Vector2(18,80);share_background_scroll.size=Vector2(516,446);share_background_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;share_background_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;share_background_scroll.scroll_deadzone=12;share_background_scroll.mouse_filter=Control.MOUSE_FILTER_STOP;share_background_panel.add_child(share_background_scroll)
	share_background_cards=HBoxContainer.new();share_background_cards.custom_minimum_size=Vector2(0,426);share_background_cards.mouse_filter=Control.MOUSE_FILTER_PASS;share_background_cards.add_theme_constant_override("separation",12);share_background_scroll.add_child(share_background_cards)

func _share_background_panel_is_open()->bool:
	return share_background_panel!=null and share_background_panel.visible

func _toggle_share_background_panel()->void:
	if _share_background_panel_is_open():_close_share_background_panel()
	else:_open_share_background_panel()

func _open_share_background_panel()->void:
	if not is_viewer_active() or current_arrangement.is_empty() or viewer_share_in_progress:return
	_cancel_viewer_gesture(false);_hide_dismantle_confirmation();_refresh_share_background_panel();share_background_panel.visible=true;viewer_share_button.disabled=true;share_background_panel.move_to_front()

func _close_share_background_panel()->void:
	if share_background_panel:share_background_panel.visible=false
	if viewer_share_button:viewer_share_button.disabled=viewer_share_in_progress

func _current_share_background_id()->String:
	return ShareBackgroundsClass.normalize_id(current_arrangement.get("share_background_id",ShareBackgroundsClass.DEFAULT_ID))

func _share_background_unlocked(background_id:String)->bool:
	return bool(share_background_unlocks.get(background_id,false))

func _refresh_share_background_panel()->void:
	if share_background_cards==null:return
	_clear_children(share_background_cards)
	var selected_id:=_current_share_background_id()
	for value in share_background_catalog:
		if not value is Dictionary:continue
		var entry:Dictionary=value
		var background_id:=str(entry.get("id",""));var texture_path:=str(entry.get("texture_path",""))
		if background_id.is_empty() or texture_path.is_empty() or not ResourceLoader.exists(texture_path):continue
		var unlocked:=_share_background_unlocked(background_id);var selected:=background_id==selected_id
		var card:=Button.new();card.custom_minimum_size=Vector2(184,426);card.action_mode=BaseButton.ACTION_MODE_BUTTON_RELEASE;card.focus_mode=Control.FOCUS_NONE;card.mouse_filter=Control.MOUSE_FILTER_PASS;card.mouse_force_pass_scroll_events=true
		_skin_button(card,Color("#e9cf9e") if selected else Color("#f4e1bc") if unlocked else Color("#a99d90"),14);share_background_cards.add_child(card)
		var thumbnail:=TextureRect.new();thumbnail.position=Vector2(10,10);thumbnail.size=Vector2(164,292);thumbnail.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;thumbnail.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;thumbnail.clip_contents=true;thumbnail.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var texture_value=load(texture_path)
		if texture_value is Texture2D:thumbnail.texture=texture_value
		if not unlocked:thumbnail.modulate=Color(.42,.39,.36,.82)
		card.add_child(thumbnail)
		if not unlocked:
			var lock_label:=Label.new();lock_label.text="🔒";lock_label.position=Vector2(10,112);lock_label.size=Vector2(164,74);lock_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;lock_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;lock_label.add_theme_font_size_override("font_size",38);lock_label.add_theme_color_override("font_color",Color.WHITE);lock_label.add_theme_color_override("font_outline_color",Color(0.12,.06,.03,.9));lock_label.add_theme_constant_override("outline_size",7);lock_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(lock_label)
		var name_label:=Label.new();name_label.text=GameLocalizer.text(language_code,str(entry.get("name_key","")));name_label.position=Vector2(8,306);name_label.size=Vector2(168,42);name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;name_label.add_theme_font_size_override("font_size",17);name_label.add_theme_color_override("font_color",UI_BROWN);name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(name_label)
		var status_key:=str(entry.get("unlock_text_key","share_background_available_now"))
		if selected:status_key="share_background_selected"
		elif unlocked and str(entry.get("unlock_condition",""))!="always":status_key="share_background_available_now"
		var status_label:=Label.new();status_label.text=GameLocalizer.text(language_code,status_key);status_label.position=Vector2(8,350);status_label.size=Vector2(168,66);status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;status_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status_label.add_theme_font_size_override("font_size",13);status_label.add_theme_color_override("font_color",Color("#6f4027") if unlocked else Color("#f7ead4"));status_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(status_label)
		card.pressed.connect(_select_share_background.bind(background_id))

func _select_share_background(background_id:String)->void:
	var normalized_id:=ShareBackgroundsClass.normalize_id(background_id)
	if normalized_id!=background_id or not _share_background_unlocked(normalized_id):return
	if normalized_id!=_current_share_background_id():
		current_arrangement["share_background_id"]=normalized_id
		var arrangement_id:=str(current_arrangement.get("arrangement_id",""))
		if not arrangement_id.is_empty():share_background_save_requested.emit(arrangement_id,normalized_id)
	_refresh_share_background_panel()

func _request_current_arrangement_share()->void:
	if viewer_share_in_progress or not is_viewer_active() or current_arrangement.is_empty():return
	_close_share_background_panel();_cancel_viewer_gesture(false);_hide_dismantle_confirmation()
	var share_snapshot:=current_arrangement.duplicate(true);share_snapshot["viewer_transform"]=_viewer_transform_state().duplicate(true)
	set_share_state(GameLocalizer.text(language_code,"share_creating"),true)
	share_requested.emit(share_snapshot)

func set_share_state(message:String,in_progress:bool)->void:
	viewer_share_in_progress=in_progress
	if viewer_share_button:viewer_share_button.disabled=in_progress or _share_background_panel_is_open()
	if viewer_share_background_button:viewer_share_background_button.disabled=in_progress
	if viewer_share_status:
		viewer_share_status.text=message
		viewer_share_status.visible=not message.is_empty()

func create_share_image(arrangement:Dictionary,background_entry:Dictionary,output_path:String)->String:
	last_share_render_debug={}
	if not is_viewer_active() or arrangement.is_empty() or background_entry.is_empty() or output_path.is_empty():return ""
	var texture_path:=str(background_entry.get("texture_path",""));var crop_mode:=str(background_entry.get("crop_mode",""))
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path) or crop_mode not in ["cover","native_9_16"]:return ""
	var background_texture:=load(texture_path) as Texture2D
	if background_texture==null:return ""
	# Rebuild once after async catalog textures have completed, then duplicate
	# only the artwork root. Viewer labels and buttons never enter the viewport.
	_render_readonly_arrangement(arrangement,arrangement.get("viewer_transform",{}))
	await get_tree().process_frame
	if viewer_artwork_root==null:return ""
	var artwork_clone:=viewer_artwork_root.duplicate() as Control
	if artwork_clone==null:return ""
	artwork_clone.name="ShareArtworkRoot";artwork_clone.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var viewport:=SubViewport.new();viewport.name="ArrangementShareViewport";viewport.size=ShareRendererClass.OUTPUT_SIZE;viewport.transparent_bg=false;viewport.disable_3d=true;viewport.render_target_clear_mode=SubViewport.CLEAR_MODE_ALWAYS;viewport.render_target_update_mode=SubViewport.UPDATE_ONCE;add_child(viewport)
	var composition:=Control.new();composition.name="ShareCompositionRoot";composition.size=Vector2(ShareRendererClass.OUTPUT_SIZE);composition.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewport.add_child(composition)
	var background_layout:Dictionary=ShareRendererClass.background_layout(background_texture.get_size(),background_entry.get("focus",Vector2(.5,.5)))
	if background_layout.is_empty():viewport.queue_free();return ""
	var background:=Sprite2D.new();background.name="ShareBackground";background.texture=background_texture;background.centered=false;background.position=background_layout.position;background.scale=Vector2.ONE*float(background_layout.scale);composition.add_child(background)
	var artwork_layout:Dictionary=ShareRendererClass.artwork_layout(background_entry)
	var artwork_canvas:=Control.new();artwork_canvas.name="ShareArtworkCanvas";artwork_canvas.position=artwork_layout.position;artwork_canvas.size=ShareRendererClass.ARTWORK_VIRTUAL_SIZE;artwork_canvas.scale=Vector2.ONE*float(artwork_layout.scale);artwork_canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;composition.add_child(artwork_canvas);artwork_canvas.add_child(artwork_clone)
	var z_indexes:Array=[];var rotations:Array=[];var plant_scales:Array=[]
	for plant_node in viewer_plant_layer.get_children():
		if plant_node is Control:z_indexes.append((plant_node as Control).z_index);rotations.append((plant_node as Control).rotation_degrees);plant_scales.append((plant_node as Control).scale.x)
	last_share_render_debug={
		"background_id":str(background_entry.get("id","")),"crop_mode":crop_mode,"output_size":ShareRendererClass.OUTPUT_SIZE,
		"root_children":[str(background.name),str(artwork_canvas.name)],"pot_count":viewer_pot_layer.get_child_count(),"plant_count":viewer_plant_layer.get_child_count(),
		"viewer_transform":normalize_viewer_transform(arrangement.get("viewer_transform",{})),"background_layout":background_layout.duplicate(true),"artwork_layout":artwork_layout.duplicate(true),
		"mapped_viewer_transform":ShareRendererClass.mapped_viewer_transform(normalize_viewer_transform(arrangement.get("viewer_transform",{})),background_entry),
		"z_indexes":z_indexes,"rotations":rotations,"plant_scales":plant_scales,
	}
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var rendered:=viewport.get_texture().get_image()
	var directory_path:=ProjectSettings.globalize_path(output_path.get_base_dir())
	var directory_error:=DirAccess.make_dir_recursive_absolute(directory_path)
	var save_error:=ERR_CANT_CREATE if directory_error!=OK else rendered.save_png(output_path)
	viewport.queue_free()
	if rendered.is_empty() or rendered.get_size()!=ShareRendererClass.OUTPUT_SIZE or save_error!=OK:return ""
	return output_path

func _open_viewer(arrangement:Dictionary,return_target:String="home")->void:
	if return_target=="saved":
		_open_saved_arrangements();_select_saved_arrangement(str(arrangement.get("arrangement_id","")));return
	viewer_gallery_mode=false;viewer_return_context="home";selected_saved_arrangement_id=str(arrangement.get("arrangement_id",""));selected_saved_arrangement_index=_saved_arrangement_index(selected_saved_arrangement_id)
	_cancel_viewer_gesture(false);_close_share_background_panel();_hide_dismantle_confirmation();set_share_state("",false);current_arrangement=arrangement.duplicate(true);current_arrangement.erase("viewer_transform");current_arrangement["completed"]=true;current_arrangement["share_background_id"]=ShareBackgroundsClass.normalize_id(current_arrangement.get("share_background_id",ShareBackgroundsClass.DEFAULT_ID));viewer_name.text=str(arrangement.get("name",GameLocalizer.text(language_code,"arrangement_title")));_show_page(viewer_page);_render_readonly_arrangement(current_arrangement);_apply_viewer_page_mode()

func _render_readonly_arrangement(arrangement:Dictionary,transient_transform:Variant=null)->void:
	_clear_children(viewer_pot_layer);_clear_children(viewer_plant_layer)
	var pot:=_pot_entry(str(arrangement.get("pot_id","")));var holder:=Control.new();holder.size=POT_HOLDER_SIZE;holder.position=_pot_holder_position(viewer_canvas,holder.size);holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewer_pot_layer.add_child(holder);_render_pot(holder,pot,false)
	for plant_value in _plant_array(arrangement):
		if not plant_value is Dictionary:continue
		var plant:Dictionary=plant_value;var texture:=_resolve_texture(_species_entry(str(plant.get("species_id",""))))
		if texture==null:continue
		var root:=Control.new();root.size=PLANT_CONTROL_SIZE;root.pivot_offset=PLANT_CONTROL_SIZE*.5;root.position=Vector2(float(plant.get("x",0.0)),float(plant.get("y",0.0)))-PLANT_CONTROL_SIZE*.5;root.scale=Vector2.ONE*clampf(float(plant.get("scale",PLANT_SCALE_MIN)),PLANT_SCALE_MIN,_plant_scale_max(plant));root.rotation_degrees=fposmod(float(plant.get("rotation",0.0)),360.0);root.z_index=int(plant.get("z_index",0));root.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewer_plant_layer.add_child(root)
		var image:=TextureRect.new();image.texture=texture;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(image);_request_texture(_species_entry(str(plant.get("species_id",""))),image,true)
	var state:=normalize_viewer_transform(transient_transform if transient_transform is Dictionary else {})
	_set_viewer_artwork_transform(Vector2(float(state.x),float(state.y)),float(state.scale),false)

func _pot_holder_position(canvas:Control,holder_size:Vector2)->Vector2:
	if not world_backdrop_enabled:return Vector2((canvas.size.x-holder_size.x)*.5,POT_LOCAL_BASELINE_Y-holder_size.y)
	return Vector2(world_pot_anchor_screen.x-canvas.position.x-holder_size.x*.5,world_pot_anchor_screen.y+POT_VERTICAL_OFFSET-canvas.position.y-holder_size.y*.94)

func _return_from_viewer()->void:
	_cancel_viewer_gesture(false);_close_share_background_panel();_show_page(home_page);_refresh_home()

func _on_viewer_world_scroll_input(_event:InputEvent)->void:
	# Compatibility hook for older tooling. Finished-viewer gestures are never
	# forwarded to greenhouse/arrangement world navigation.
	pass

func _build_shop_page()->void:
	_build_header(shop_page,"pot_shop_title",close)
	shop_wallet=Label.new();shop_wallet.position=Vector2(30,92);shop_wallet.size=Vector2(516,38);shop_wallet.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_wallet.add_theme_font_size_override("font_size",20);shop_wallet.add_theme_color_override("font_color",Color("#f5d36d"));shop_page.add_child(shop_wallet)
	shop_message=Label.new();shop_message.position=Vector2(30,132);shop_message.size=Vector2(516,52);shop_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;shop_message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;shop_message.add_theme_font_size_override("font_size",16);shop_message.add_theme_color_override("font_color",UI_CREAM);shop_page.add_child(shop_message)
	shop_restore_button=_button(GameLocalizer.text(language_code,"iap_restore_purchases"),Vector2(168,190),Vector2(240,50),Color("#c29c72"),15);_prepare_scroll_button(shop_restore_button);shop_restore_button.pressed.connect(_request_pot_restore);shop_page.add_child(shop_restore_button)
	var scroll:=_shop_scroll(Vector2(26,252),Vector2(524,732));shop_page.add_child(scroll)
	shop_grid=VBoxContainer.new();shop_grid.custom_minimum_size=Vector2(504,0);shop_grid.mouse_filter=Control.MOUSE_FILTER_PASS;shop_grid.add_theme_constant_override("separation",14);scroll.add_child(shop_grid)

func _refresh_pot_shop()->void:
	shop_wallet.text=GameLocalizer.text(language_code,"wallet",[wallet_puku_points])
	if shop_message.text.is_empty():shop_message.text=GameLocalizer.text(language_code,"all_pots_one_puku")
	shop_restore_button.visible=_has_visible_iap_pots()
	shop_restore_button.text=GameLocalizer.text(language_code,"iap_restore_processing" if pot_restore_in_progress else "iap_restore_purchases")
	shop_restore_button.disabled=not pot_restore_available or pot_restore_in_progress
	_refresh_pot_shop_cards()

func _refresh_pot_shop_cards()->void:
	_clear_children(shop_grid)
	for pot_value in pot_catalog:
		if not pot_value is Dictionary:continue
		var pot:Dictionary=pot_value
		if not _pot_sales_stage_unlocked(pot):continue
		var pot_id:=str(pot.get("pot_id",""));var total:=_pot_total_count(pot_id);var design_unlocked:=_pot_design_unlocked(pot);var price_value=pot.get("price_puku");var priced:=price_value is int or price_value is float;var price:=maxi(0,int(price_value)) if priced else 0
		var card:=PanelContainer.new();card.custom_minimum_size=Vector2(504,204);card.mouse_filter=Control.MOUSE_FILTER_PASS;card.add_theme_stylebox_override("panel",_box(Color("#f4e1bc"),Color("#b77c48"),20,3));shop_grid.add_child(card)
		var content:=Control.new();content.custom_minimum_size=Vector2(484,184);content.mouse_filter=Control.MOUSE_FILTER_PASS;card.add_child(content)
		var preview:=Control.new();preview.position=Vector2(2,2);preview.size=Vector2(214,176);preview.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(preview);_render_pot(preview,pot,true)
		var name:=Label.new();name.text=GameLocalizer.pot_name(language_code,pot);name.position=Vector2(220,12);name.size=Vector2(258,45);name.mouse_filter=Control.MOUSE_FILTER_IGNORE;name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name.add_theme_font_size_override("font_size",19);name.add_theme_color_override("font_color",UI_BROWN);content.add_child(name)
		var condition:=Label.new();condition.text=GameLocalizer.text(language_code,"pot_owned_total",[total]) if design_unlocked else GameLocalizer.text(language_code,"pot_permanent_unlock");condition.position=Vector2(220,55);condition.size=Vector2(258,34);condition.mouse_filter=Control.MOUSE_FILTER_IGNORE;condition.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;condition.add_theme_font_size_override("font_size",13);condition.add_theme_color_override("font_color",Color("#79543a"));content.add_child(condition)
		var buy_text:="";var buy_enabled:=false;var product_id:=str(pot.get("iap_product_id",""));var buy_action:=Callable()
		if design_unlocked:
			buy_text=GameLocalizer.text(language_code,"buy_puku",[price]) if priced else GameLocalizer.text(language_code,"price_tbd")
			buy_enabled=priced and wallet_puku_points>=price
			buy_action=_request_pot_purchase.bind(pot_id)
		else:
			var product_state:Dictionary=pot_iap_products.get(product_id,{"status":"loading","localized_price":""})
			var status:=str(product_state.get("status","loading"));var localized_price:=str(product_state.get("localized_price","")).strip_edges()
			match status:
				"available":buy_text=GameLocalizer.text(language_code,"iap_unlock_for_price",[localized_price]);buy_enabled=not localized_price.is_empty()
				"purchasing":buy_text=GameLocalizer.text(language_code,"iap_purchase_processing")
				"loading":buy_text=GameLocalizer.text(language_code,"iap_price_loading")
				_:buy_text=GameLocalizer.text(language_code,"iap_purchase_unavailable")
			buy_action=_request_pot_unlock.bind(product_id)
		var buy:=_button(buy_text,Vector2(232,102),Vector2(236,58),Color("#d7aa64") if buy_enabled else Color("#b9a17d"),15)
		_prepare_scroll_button(buy);buy.disabled=not buy_enabled
		if buy_action.is_valid():buy.pressed.connect(buy_action)
		content.add_child(buy)

func _request_pot_purchase(pot_id:String)->void:
	pot_purchase_requested.emit(pot_id)

func _request_pot_unlock(product_id:String)->void:
	pot_unlock_requested.emit(product_id)

func _request_pot_restore()->void:
	pot_restore_requested.emit()

func _has_visible_iap_pots()->bool:
	for pot_value in pot_catalog:
		if pot_value is Dictionary and _pot_sales_stage_unlocked(pot_value) and str(pot_value.get("unlock_type","free"))=="iap_unlock":return true
	return false

func _build_catalog_shop_page()->void:
	_build_header(catalog_shop_page,"catalog_shop_title",close)
	catalog_shop_wallet=Label.new();catalog_shop_wallet.position=Vector2(30,92);catalog_shop_wallet.size=Vector2(516,38);catalog_shop_wallet.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;catalog_shop_wallet.add_theme_font_size_override("font_size",20);catalog_shop_wallet.add_theme_color_override("font_color",Color("#f5d36d"));catalog_shop_page.add_child(catalog_shop_wallet)
	catalog_shop_message=Label.new();catalog_shop_message.position=Vector2(30,132);catalog_shop_message.size=Vector2(516,52);catalog_shop_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;catalog_shop_message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;catalog_shop_message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;catalog_shop_message.add_theme_font_size_override("font_size",16);catalog_shop_message.add_theme_color_override("font_color",UI_CREAM);catalog_shop_page.add_child(catalog_shop_message)
	var scroll:=_shop_scroll(Vector2(26,194),Vector2(524,790));catalog_shop_page.add_child(scroll)
	catalog_shop_grid=VBoxContainer.new();catalog_shop_grid.custom_minimum_size=Vector2(504,0);catalog_shop_grid.mouse_filter=Control.MOUSE_FILTER_PASS;catalog_shop_grid.add_theme_constant_override("separation",14);scroll.add_child(catalog_shop_grid)

func _refresh_catalog_shop()->void:
	catalog_shop_wallet.text=GameLocalizer.text(language_code,"wallet",[wallet_puku_points])
	if catalog_shop_message.text.is_empty():catalog_shop_message.text=GameLocalizer.text(language_code,"catalog_shop_hint")
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
			var placeholder:=Label.new();placeholder.text=GameLocalizer.text(language_code,"product_image_preparing");placeholder.position=preview.position;placeholder.size=preview.size;placeholder.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;placeholder.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;placeholder.add_theme_font_size_override("font_size",18);placeholder.add_theme_color_override("font_color",Color("#79543a"));content.add_child(placeholder)
		var name:=Label.new();name.text=GameLocalizer.series_name(language_code,series);name.position=Vector2(220,12);name.size=Vector2(258,45);name.mouse_filter=Control.MOUSE_FILTER_IGNORE;name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name.add_theme_font_size_override("font_size",19);name.add_theme_color_override("font_color",UI_BROWN);content.add_child(name)
		var condition:=Label.new();condition.text=GameLocalizer.text(language_code,"catalog_page_product");condition.position=Vector2(220,55);condition.size=Vector2(258,34);condition.mouse_filter=Control.MOUSE_FILTER_IGNORE;condition.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;condition.add_theme_font_size_override("font_size",13);condition.add_theme_color_override("font_color",Color("#79543a"));content.add_child(condition)
		var buy:=_button(GameLocalizer.text(language_code,"bought") if owned else GameLocalizer.text(language_code,"buy_puku",[price]),Vector2(248,102),Vector2(204,58),Color("#b9a17d") if owned else Color("#d7aa64"),17);_prepare_scroll_button(buy);buy.disabled=owned or wallet_puku_points<price;buy.pressed.connect(_request_catalog_purchase.bind(series_id));content.add_child(buy)

func _request_catalog_purchase(series_id:String)->void:
	catalog_purchase_requested.emit(series_id)

func _build_seed_shop_page()->void:
	_build_header(seed_shop_page,"seed_shop_title",close)
	seed_shop_wallet=Label.new();seed_shop_wallet.position=Vector2(30,92);seed_shop_wallet.size=Vector2(516,38);seed_shop_wallet.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;seed_shop_wallet.add_theme_font_size_override("font_size",20);seed_shop_wallet.add_theme_color_override("font_color",Color("#f5d36d"));seed_shop_page.add_child(seed_shop_wallet)
	seed_shop_message=Label.new();seed_shop_message.position=Vector2(30,132);seed_shop_message.size=Vector2(516,52);seed_shop_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;seed_shop_message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;seed_shop_message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;seed_shop_message.add_theme_font_size_override("font_size",16);seed_shop_message.add_theme_color_override("font_color",UI_CREAM);seed_shop_page.add_child(seed_shop_message)
	var scroll:=_shop_scroll(Vector2(26,194),Vector2(524,790));seed_shop_page.add_child(scroll)
	seed_shop_grid=VBoxContainer.new();seed_shop_grid.custom_minimum_size=Vector2(504,0);seed_shop_grid.mouse_filter=Control.MOUSE_FILTER_PASS;seed_shop_grid.add_theme_constant_override("separation",14);scroll.add_child(seed_shop_grid)

func _refresh_seed_shop()->void:
	seed_shop_wallet.text=GameLocalizer.text(language_code,"wallet",[wallet_puku_points])
	if seed_shop_message.text.is_empty():seed_shop_message.text=GameLocalizer.text(language_code,"normal_seed_price")
	_clear_children(seed_shop_grid)
	for product_value in seed_shop_products:
		if not product_value is Dictionary:continue
		var product:Dictionary=product_value;var seed_type:=str(product.get("seed_type","normal"));var price_value=product.get("price_puku");var priced:=price_value is int or price_value is float;var price:=maxi(0,int(price_value)) if priced else 0;var unlocked:=bool(product.get("unlocked",false));var purchasable:=bool(product.get("purchasable",priced));var accent:=Color(str(product.get("accent","#d8b56b")))
		var card:=PanelContainer.new();card.custom_minimum_size=Vector2(504,204);card.mouse_filter=Control.MOUSE_FILTER_PASS;card.add_theme_stylebox_override("panel",_box(Color("#f4e1bc"),Color("#b77c48"),20,3));seed_shop_grid.add_child(card)
		var content:=Control.new();content.custom_minimum_size=Vector2(484,184);content.mouse_filter=Control.MOUSE_FILTER_PASS;card.add_child(content)
		var preview:=PanelContainer.new();preview.position=Vector2(2,2);preview.size=Vector2(214,176);preview.mouse_filter=Control.MOUSE_FILTER_IGNORE;preview.add_theme_stylebox_override("panel",_box(accent.lightened(.16),accent.darkened(.18),24,3));content.add_child(preview)
		var preview_label:=Label.new();preview_label.text=str(product.get("preview_text",GameLocalizer.text(language_code,"seed_bag_count",[int(product.get("count",0))])));preview_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;preview_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;preview_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;preview_label.add_theme_font_size_override("font_size",24);preview_label.add_theme_color_override("font_color",UI_BROWN);preview.add_child(preview_label)
		var name:=Label.new();name.text=GameLocalizer.seed_name(language_code,seed_type,str(product.get("display_name","たね")));name.position=Vector2(220,7);name.size=Vector2(258,40);name.mouse_filter=Control.MOUSE_FILTER_IGNORE;name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name.add_theme_font_size_override("font_size",19);name.add_theme_color_override("font_color",UI_BROWN);content.add_child(name)
		var detail:=Label.new();detail.text=str(product.get("description",""));detail.position=Vector2(220,45);detail.size=Vector2(258,66);detail.mouse_filter=Control.MOUSE_FILTER_IGNORE;detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;detail.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.add_theme_font_size_override("font_size",13);detail.add_theme_color_override("font_color",Color("#79543a"));content.add_child(detail)
		var buy_text:=GameLocalizer.text(language_code,"locked") if not unlocked else (GameLocalizer.text(language_code,"buy_puku",[price]) if purchasable and priced else GameLocalizer.text(language_code,"price_tbd"))
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
		var placeholder:=PotPlaceholderClass.new();placeholder.display_name=GameLocalizer.pot_name(language_code,pot) if not compact else GameLocalizer.text(language_code,"pot_image_preparing");placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);placeholder.mouse_filter=Control.MOUSE_FILTER_IGNORE;container.add_child(placeholder)

func _placement_rect(_pot:Dictionary,canvas_size:Vector2)->Rect2:
	return Rect2(Vector2.ZERO,canvas_size)

func _pot_entry(pot_id:String)->Dictionary:
	for value in pot_catalog:
		if value is Dictionary and str(value.get("pot_id",""))==pot_id:return value
	return {}

func _pot_name(pot_id:String)->String:
	return GameLocalizer.pot_name(language_code,_pot_entry(pot_id))

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

func _pot_total_count(pot_id:String)->int:
	var value=owned_pots.get(pot_id,0)
	if value is bool:return 1 if bool(value) else 0
	if value is int or value is float:return maxi(0,int(value))
	return 0

func _pot_used_count(pot_id:String)->int:
	var count:=0
	for arrangement_value in saved_arrangements:
		if arrangement_value is Dictionary and str(arrangement_value.get("pot_id",""))==pot_id:count+=1
	return count

func _pot_available_count(pot_id:String)->int:
	return maxi(0,_pot_total_count(pot_id)-_pot_used_count(pot_id))

func _at_save_capacity()->bool:
	return saved_arrangements.size()>=save_capacity

func _pot_sales_stage_unlocked(pot:Dictionary)->bool:
	return int(pot.get("sales_stage",0))<=pot_sales_stage

func _pot_design_unlocked(pot:Dictionary)->bool:
	if str(pot.get("unlock_type","free"))!="iap_unlock":return true
	var product_id:=str(pot.get("iap_product_id",""))
	return not product_id.is_empty() and bool(pot_design_unlocks.get(product_id,false))

func _owned_pot_count()->int:
	var count:=0
	for pot_value in pot_catalog:
		if pot_value is Dictionary:count+=_pot_total_count(str(pot_value.get("pot_id","")))
	return count

func _default_arrangement_name()->String:
	return "%s %d"%[GameLocalizer.text(language_code,"arrangement_title"),saved_arrangements.size()+1]

func _new_arrangement_id()->String:
	return "arrangement_%d_%d"%[Time.get_unix_time_from_system(),Time.get_ticks_msec()%100000]

func _clear_children(node:Node)->void:
	for child in node.get_children():child.free()

func _mark_localized(control:Control,key:String,placeholder:=false)->void:
	control.set_meta("locale_key",key);control.set_meta("locale_placeholder",placeholder);_apply_localized_control(control)

func _apply_localized_control(node:Node)->void:
	if not node.has_meta("locale_key"):return
	var translated:=str(node.get_meta("locale_prefix",""))+GameLocalizer.text(language_code,str(node.get_meta("locale_key","")))
	if bool(node.get_meta("locale_placeholder",false)) and node is LineEdit:(node as LineEdit).placeholder_text=translated
	elif node is Label or node is Button:(node as Control).set("text",translated)

func _apply_static_language()->void:
	for child in find_children("*","",true,false):_apply_localized_control(child)

func _button(text_value:String,position_value:Vector2,size_value:Vector2,color:Color,font_size:int)->Button:
	var button:=Button.new();button.text=text_value;button.position=position_value;button.size=size_value;button.custom_minimum_size=size_value;button.focus_mode=Control.FOCUS_NONE;_skin_button(button,color,font_size);return button

func _skin_button(button:Button,bg:Color,font_size:int)->void:
	button.add_theme_font_size_override("font_size",font_size);button.add_theme_color_override("font_color",UI_BROWN if bg.get_luminance()>.55 else Color.WHITE);button.add_theme_color_override("font_disabled_color",Color("#c9b7a3"));button.add_theme_stylebox_override("normal",_box(bg,bg.lightened(.18),18,3));button.add_theme_stylebox_override("hover",_box(bg.lightened(.07),Color.WHITE,18,3));button.add_theme_stylebox_override("pressed",_box(bg.darkened(.08),bg.lightened(.18),18,3));button.add_theme_stylebox_override("disabled",_box(bg.darkened(.32),bg.darkened(.18),18,2))

func _style_overlay_label(label:Label,color:=UI_CREAM,outline_size:=5)->void:
	label.add_theme_color_override("font_color",color);label.add_theme_color_override("font_outline_color",Color(0.12,.055,.025,.92));label.add_theme_constant_override("outline_size",outline_size);label.add_theme_color_override("font_shadow_color",Color(0.0,0.0,0.0,.52));label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",2)

func _box(bg:Color,border:Color,radius:int,width:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius);style.content_margin_left=10;style.content_margin_right=10;style.content_margin_top=7;style.content_margin_bottom=7;style.shadow_color=Color(0.15,.07,.03,.28);style.shadow_size=5;style.shadow_offset=Vector2(0,3);return style
