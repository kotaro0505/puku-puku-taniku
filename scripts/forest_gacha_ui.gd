class_name ForestGachaUI
extends Control

signal close_requested
signal spin_requested
signal unlock_requested(series_id:String,species_id:String)
signal later_requested(series_id:String,species_id:String)
signal species_reveal_requested(result:Dictionary)

const CapsuleClass=preload("res://scripts/forest_gacha_capsule.gd")
const BACKGROUND_TEXTURE=preload("res://assets/forest_gacha/forest-gacha-background.jpg")
const DIAL_TEXTURE=preload("res://assets/forest_gacha/temporary-dial.png")
const BACKGROUND_SHADER=preload("res://shaders/forest_gacha_background.gdshader")
const Localizer=preload("res://scripts/game_localizer.gd")
const UI_CREAM:=Color("#fff1d2")
const UI_BROWN:=Color("#4a2618")

var wallet_label:Label
var title_label:Label
var draw_count_label:Label
var close_button:Button
var spin_button:Button
var hint_label:Label
var background_stage:Control
var dial_texture:TextureRect
var dial_hit_area:Button
var capsule:Control
var capsule_hit_area:Button
var result_overlay:Control
var result_flash:ColorRect
var result_panel:PanelContainer
var result_image:TextureRect
var result_badge:Label
var result_name:Label
var result_series:Label
var result_message:Label
var offer_panel:PanelContainer
var unlock_button:Button
var later_button:Button
var result_close_button:Button
var pending_result:Dictionary={}
var busy:=false
var capsule_ready:=false
var animation_time_scale:=1.0
var current_puku_points:=0
var current_draw_count:=0
var _dial_dragging:=false
var _dial_drag_origin:=Vector2.ZERO
var language:="ja"

func _ready()->void:
	name="ForestGachaUI";set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP;visible=false
	_build_background();_build_header();_build_dial();_build_capsule();_build_result_overlay()

func _build_background()->void:
	background_stage=Control.new();background_stage.name="MachineStage";background_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background_stage.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(background_stage)
	var background:=TextureRect.new();background.name="Background";background.texture=BACKGROUND_TEXTURE;background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;background.stretch_mode=TextureRect.STRETCH_SCALE;background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material:=ShaderMaterial.new();material.shader=BACKGROUND_SHADER;background.material=material;background_stage.add_child(background)
	var warm_shade:=ColorRect.new();warm_shade.color=Color(0.12,.06,.01,.07);warm_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);warm_shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;background_stage.add_child(warm_shade)

func _build_header()->void:
	title_label=Label.new();title_label.text="森のガチャ";title_label.position=Vector2(138,24);title_label.size=Vector2(300,66);title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;title_label.add_theme_font_size_override("font_size",31);title_label.add_theme_color_override("font_color",Color("#fff5d6"));title_label.add_theme_color_override("font_outline_color",Color("#45220f"));title_label.add_theme_constant_override("outline_size",8);add_child(title_label)
	wallet_label=Label.new();wallet_label.name="WalletLabel";wallet_label.position=Vector2(22,92);wallet_label.size=Vector2(238,48);wallet_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;wallet_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;wallet_label.add_theme_font_size_override("font_size",18);wallet_label.add_theme_color_override("font_color",Color("#fff4ba"));wallet_label.add_theme_stylebox_override("normal",_box(Color(0.18,.09,.035,.82),Color("#d7ad63"),18,2));add_child(wallet_label)
	draw_count_label=Label.new();draw_count_label.position=Vector2(276,96);draw_count_label.size=Vector2(136,40);draw_count_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;draw_count_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;draw_count_label.add_theme_font_size_override("font_size",14);draw_count_label.add_theme_color_override("font_color",UI_CREAM);draw_count_label.add_theme_color_override("font_outline_color",Color("#45220f"));draw_count_label.add_theme_constant_override("outline_size",5);add_child(draw_count_label)
	close_button=Button.new();close_button.name="CloseButton";close_button.text="もどる";close_button.position=Vector2(448,28);close_button.size=Vector2(106,54);_skin_button(close_button,Color("#fff0cf"),17);close_button.pressed.connect(_request_close);add_child(close_button)

func _build_dial()->void:
	dial_texture=TextureRect.new();dial_texture.name="TemporaryDial";dial_texture.texture=DIAL_TEXTURE;dial_texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;dial_texture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;dial_texture.position=Vector2(340,578);dial_texture.size=Vector2(100,100);dial_texture.pivot_offset=dial_texture.size*.5;dial_texture.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(dial_texture)
	dial_hit_area=Button.new();dial_hit_area.name="DialHitArea";dial_hit_area.flat=true;dial_hit_area.position=Vector2(326,562);dial_hit_area.size=Vector2(128,132);dial_hit_area.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;dial_hit_area.focus_mode=Control.FOCUS_NONE;dial_hit_area.gui_input.connect(_on_dial_input);add_child(dial_hit_area)
	hint_label=Label.new();hint_label.position=Vector2(118,862);hint_label.size=Vector2(340,44);hint_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;hint_label.text="ダイヤルをタップして回そう";hint_label.add_theme_font_size_override("font_size",18);hint_label.add_theme_color_override("font_color",Color("#fff4cf"));hint_label.add_theme_color_override("font_outline_color",Color("#3e1d0d"));hint_label.add_theme_constant_override("outline_size",7);add_child(hint_label)
	spin_button=Button.new();spin_button.name="SpinButton";spin_button.text="1ぷくコインで回す";spin_button.position=Vector2(148,910);spin_button.size=Vector2(280,72);_skin_button(spin_button,Color("#c7923d"),21);spin_button.pressed.connect(_request_spin);add_child(spin_button)

func _build_capsule()->void:
	capsule=CapsuleClass.new();capsule.name="Capsule";capsule.position=Vector2(244,742);capsule.size=Vector2(88,88);capsule.pivot_offset=capsule.size*.5;capsule.mouse_filter=Control.MOUSE_FILTER_IGNORE;capsule.visible=false;add_child(capsule)
	capsule_hit_area=Button.new();capsule_hit_area.name="CapsuleHitArea";capsule_hit_area.flat=true;capsule_hit_area.position=Vector2(226,728);capsule_hit_area.size=Vector2(124,132);capsule_hit_area.focus_mode=Control.FOCUS_NONE;capsule_hit_area.visible=false;capsule_hit_area.pressed.connect(_reveal_result);add_child(capsule_hit_area)

func _build_result_overlay()->void:
	result_overlay=Control.new();result_overlay.name="ResultOverlay";result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);result_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;result_overlay.visible=false;add_child(result_overlay)
	var dim:=ColorRect.new();dim.color=Color(0.025,.018,.012,.82);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);dim.mouse_filter=Control.MOUSE_FILTER_STOP;result_overlay.add_child(dim)
	result_flash=ColorRect.new();result_flash.color=Color(1.0,.95,.68,0.0);result_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);result_flash.mouse_filter=Control.MOUSE_FILTER_IGNORE;result_overlay.add_child(result_flash)
	result_panel=PanelContainer.new();result_panel.position=Vector2(38,104);result_panel.size=Vector2(500,810);result_panel.pivot_offset=result_panel.size*.5;result_panel.add_theme_stylebox_override("panel",_box(Color(.12,.075,.035,.96),Color("#e8bd67"),30,4));result_overlay.add_child(result_panel)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",8);content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);content.offset_left=28;content.offset_top=24;content.offset_right=-28;content.offset_bottom=-24;result_panel.add_child(content)
	result_badge=Label.new();result_badge.custom_minimum_size=Vector2(380,48);result_badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;result_badge.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;result_badge.add_theme_font_size_override("font_size",30);result_badge.add_theme_color_override("font_color",Color("#fff06f"));result_badge.add_theme_color_override("font_outline_color",Color("#8b3c16"));result_badge.add_theme_constant_override("outline_size",7);content.add_child(result_badge)
	var image_glow:=PanelContainer.new();image_glow.custom_minimum_size=Vector2(410,354);var glow_style:=_box(Color(.96,.88,.62,.09),Color(1.0,.88,.47,.72),28,3);glow_style.shadow_color=Color(1.0,.70,.24,.42);glow_style.shadow_size=18;image_glow.add_theme_stylebox_override("panel",glow_style);content.add_child(image_glow)
	result_image=TextureRect.new();result_image.name="SpeciesImage";result_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;result_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;result_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);result_image.offset_left=18;result_image.offset_top=18;result_image.offset_right=-18;result_image.offset_bottom=-18;result_image.mouse_filter=Control.MOUSE_FILTER_IGNORE;image_glow.add_child(result_image)
	result_name=Label.new();result_name.custom_minimum_size=Vector2(420,56);result_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;result_name.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;result_name.add_theme_font_size_override("font_size",27);result_name.add_theme_color_override("font_color",Color("#fff4d2"));result_name.add_theme_color_override("font_outline_color",Color("#3c1b0d"));result_name.add_theme_constant_override("outline_size",6);content.add_child(result_name)
	result_series=Label.new();result_series.custom_minimum_size=Vector2(420,30);result_series.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;result_series.add_theme_font_size_override("font_size",16);result_series.add_theme_color_override("font_color",Color("#dfbc7c"));content.add_child(result_series)
	result_message=Label.new();result_message.custom_minimum_size=Vector2(420,78);result_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;result_message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;result_message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;result_message.add_theme_font_size_override("font_size",17);result_message.add_theme_color_override("font_color",UI_CREAM);content.add_child(result_message)
	offer_panel=PanelContainer.new();offer_panel.custom_minimum_size=Vector2(430,132);offer_panel.add_theme_stylebox_override("panel",_box(Color(.28,.16,.07,.92),Color("#ba8c4e"),20,2));content.add_child(offer_panel)
	var offer_content:=VBoxContainer.new();offer_content.alignment=BoxContainer.ALIGNMENT_CENTER;offer_content.add_theme_constant_override("separation",8);offer_panel.add_child(offer_content)
	var choice_row:=HBoxContainer.new();choice_row.alignment=BoxContainer.ALIGNMENT_CENTER;choice_row.add_theme_constant_override("separation",16);offer_content.add_child(choice_row)
	unlock_button=Button.new();unlock_button.name="UnlockButton";unlock_button.text="解放する\n5ぷく";unlock_button.custom_minimum_size=Vector2(184,76);_skin_button(unlock_button,Color("#d2a046"),18);unlock_button.pressed.connect(_request_unlock);choice_row.add_child(unlock_button)
	later_button=Button.new();later_button.name="LaterButton";later_button.text="あとで";later_button.custom_minimum_size=Vector2(154,76);_skin_button(later_button,Color("#d8c59a"),18);later_button.pressed.connect(_request_later);choice_row.add_child(later_button)
	result_close_button=Button.new();result_close_button.name="ResultCloseButton";result_close_button.text="ガチャへ戻る";result_close_button.custom_minimum_size=Vector2(260,62);_skin_button(result_close_button,Color("#d5aa58"),18);result_close_button.pressed.connect(_close_result);content.add_child(result_close_button)

func open_gacha(puku_points:int,draw_count:int)->void:
	visible=true;pending_result.clear();busy=false;capsule_ready=false;capsule.visible=false;capsule_hit_area.visible=false;result_overlay.visible=false;set_wallet(puku_points,draw_count);hint_label.text="ダイヤルをタップして回そう";close_button.disabled=false
	set_language(language)

func set_language(value:String)->void:
	language=Localizer.normalize_language(value)
	if not is_node_ready():return
	title_label.text=Localizer.text(language,"forest_gacha");close_button.text=Localizer.text(language,"back");spin_button.text=Localizer.text(language,"gacha_spin");hint_label.text=Localizer.text(language,"gacha_dial_hint")
	wallet_label.text=Localizer.text(language,"wallet",[current_puku_points]);result_close_button.text=Localizer.text(language,"gacha_return");unlock_button.text=Localizer.text(language,"unlock_action");later_button.text=Localizer.text(language,"later")

func close_gacha()->void:
	visible=false;pending_result.clear();busy=false;capsule_ready=false

func set_wallet(puku_points:int,draw_count:int)->void:
	current_puku_points=puku_points;current_draw_count=draw_count
	wallet_label.text=Localizer.text(language,"wallet",[puku_points]);draw_count_label.text=Localizer.text(language,"gacha_draw_count",[draw_count]);spin_button.disabled=busy or capsule_ready or result_overlay.visible or puku_points<1;dial_hit_area.disabled=spin_button.disabled

func play_spin(result:Dictionary,texture:Texture2D)->void:
	if busy:return
	pending_result=result.duplicate(true);busy=true;capsule_ready=false;close_button.disabled=true;spin_button.disabled=true;dial_hit_area.disabled=true;hint_label.text=Localizer.text(language,"gacha_selecting");result_image.texture=texture
	dial_texture.rotation=0.0;background_stage.position=Vector2.ZERO
	var turn:=create_tween().set_parallel(true)
	turn.tween_property(dial_texture,"rotation",TAU*3.4,.92*animation_time_scale).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var shake:=create_tween();shake.tween_property(background_stage,"position:x",-5.0,.10*animation_time_scale);shake.tween_property(background_stage,"position:x",6.0,.12*animation_time_scale);shake.tween_property(background_stage,"position:x",-3.0,.12*animation_time_scale);shake.tween_property(background_stage,"position:x",0.0,.18*animation_time_scale)
	await turn.finished
	capsule.set_seed(str(result.get("species_id","")).hash());capsule.position=Vector2(244,726);capsule.scale=Vector2(.35,.35);capsule.rotation=-.35;capsule.modulate=Color(1,1,1,0);capsule.visible=true
	var drop:=create_tween().set_parallel(true);drop.tween_property(capsule,"position",Vector2(244,784),.46*animation_time_scale).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT);drop.tween_property(capsule,"scale",Vector2.ONE,.34*animation_time_scale).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);drop.tween_property(capsule,"rotation",.14,.46*animation_time_scale).set_trans(Tween.TRANS_CUBIC);drop.tween_property(capsule,"modulate:a",1.0,.16*animation_time_scale)
	await drop.finished
	busy=false;capsule_ready=true;capsule_hit_area.visible=true;hint_label.text=Localizer.text(language,"gacha_capsule_hint");close_button.disabled=true

func show_unlock_complete(message:String,puku_points:int,draw_count:int)->void:
	offer_panel.visible=false;result_message.text=message;result_badge.text=Localizer.text(language,"new");result_close_button.visible=true;set_wallet(puku_points,draw_count)

func show_unlock_error(message:String)->void:
	result_message.text=message;unlock_button.disabled=false;later_button.disabled=false

func show_later_message(message:String,puku_points:int,draw_count:int)->void:
	offer_panel.visible=false;result_message.text=message;result_badge.text=Localizer.text(language,"encountered");result_close_button.visible=true;set_wallet(puku_points,draw_count)

func _on_dial_input(event:InputEvent)->void:
	if event is InputEventScreenTouch:
		if event.pressed:_dial_dragging=true;_dial_drag_origin=event.position
		elif _dial_dragging:_dial_dragging=false;_request_spin()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:_dial_dragging=true;_dial_drag_origin=event.position
		elif _dial_dragging:_dial_dragging=false;_request_spin()
	elif event is InputEventScreenDrag and _dial_dragging:
		dial_texture.rotation+=event.relative.x*.025
	elif event is InputEventMouseMotion and _dial_dragging:
		dial_texture.rotation+=event.relative.x*.025

func _request_spin()->void:
	if busy or capsule_ready or result_overlay.visible or spin_button.disabled:return
	spin_requested.emit()

func _reveal_result()->void:
	if not capsule_ready or pending_result.is_empty():return
	capsule_ready=false;capsule.visible=false;capsule_hit_area.visible=false;busy=true;species_reveal_requested.emit(pending_result.duplicate(true))

func resume_after_species_reveal()->void:
	busy=false
	if pending_result.is_empty():return
	var is_locked:=str(pending_result.get("source",""))=="locked"
	if not is_locked:_close_result();return
	result_overlay.visible=true;result_panel.scale=Vector2(.86,.86);result_flash.color.a=.72;result_image.get_parent().visible=false
	var entry:Dictionary=pending_result.get("species_entry",{});var series_entry:Dictionary=pending_result.get("series_entry",{});var series_name:=Localizer.series_name(language,series_entry) if not series_entry.is_empty() else str(pending_result.get("series_name","Catalog"))
	result_name.text=Localizer.species_name(language,entry);result_series.text="『%s』"%series_name;result_badge.text=Localizer.text(language,"locked_series")
	result_message.text=Localizer.text(language,"locked_offer",[series_name])
	offer_panel.visible=true;result_close_button.visible=false;unlock_button.disabled=false;later_button.disabled=false
	var reveal:=create_tween().set_parallel(true);reveal.tween_property(result_flash,"color:a",0.0,.36*animation_time_scale);reveal.tween_property(result_panel,"scale",Vector2.ONE,.30*animation_time_scale).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _request_unlock()->void:
	if pending_result.is_empty():return
	unlock_button.disabled=true;later_button.disabled=true;unlock_requested.emit(str(pending_result.get("series_id","")),str(pending_result.get("species_id","")))

func _request_later()->void:
	if pending_result.is_empty():return
	unlock_button.disabled=true;later_button.disabled=true;later_requested.emit(str(pending_result.get("series_id","")),str(pending_result.get("species_id","")))

func _close_result()->void:
	result_overlay.visible=false;pending_result.clear();result_image.texture=null;result_image.get_parent().visible=true;close_button.disabled=false;hint_label.text=Localizer.text(language,"gacha_dial_hint");capsule_ready=false;busy=false;set_wallet(current_puku_points,current_draw_count)

func _request_close()->void:
	if busy or capsule_ready or result_overlay.visible:return
	close_requested.emit()

func is_open()->bool:return visible
func is_busy()->bool:return busy or capsule_ready or result_overlay.visible

func _skin_button(button:Button,background:Color,font_size:int)->void:
	button.add_theme_font_size_override("font_size",font_size);button.add_theme_color_override("font_color",UI_BROWN if background.get_luminance()>.55 else Color.WHITE);button.add_theme_color_override("font_hover_color",UI_BROWN);button.add_theme_stylebox_override("normal",_box(background,background.lightened(.22),20,3));button.add_theme_stylebox_override("hover",_box(background.lightened(.08),Color.WHITE,20,3));button.add_theme_stylebox_override("pressed",_box(background.darkened(.08),background.lightened(.2),20,3));button.add_theme_stylebox_override("disabled",_box(background.darkened(.28),Color(.55,.48,.36,.65),20,2))

func _box(background:Color,border:Color,radius:int,width:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=background;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius);style.shadow_color=Color(.12,.05,.01,.34);style.shadow_size=6;style.shadow_offset=Vector2(0,3);style.content_margin_left=10;style.content_margin_right=10;style.content_margin_top=6;style.content_margin_bottom=6;return style
