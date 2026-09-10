class_name SecretGachaUI
extends Control

signal close_requested
signal spin_requested
signal species_reveal_requested(result:Dictionary)

const CapsuleClass=preload("res://scripts/forest_gacha_capsule.gd")
const Localizer=preload("res://scripts/game_localizer.gd")
const BACKGROUND_TEXTURE=preload("res://assets/secret_gacha/secret-gacha-background.png")
const DIAL_TEXTURE=preload("res://assets/secret_gacha/temporary-dial.png")
const UI_CREAM:=Color("#fff1d2")
const UI_BROWN:=Color("#3a1d12")

var language:="ja"
var wallet_label:Label
var remaining_label:Label
var close_button:Button
var spin_button:Button
var hint_label:Label
var machine_stage:Control
var dial_texture:TextureRect
var dial_hit_area:Button
var capsule:Control
var capsule_hit_area:Button
var result_overlay:Control
var result_flash:ColorRect
var result_card:PanelContainer
var result_image:TextureRect
var result_badge:Label
var result_name:Label
var result_close_button:Button
var pending_result:Dictionary={}
var pending_texture:Texture2D
var current_puku_points:=0
var current_remaining:=0
var busy:=false
var capsule_ready:=false
var animation_time_scale:=1.0
var dial_duration_seconds:=2.0
var shake_duration_seconds:=1.4
var _dial_dragging:=false

func _ready()->void:
	name="SecretGachaUI";set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP;visible=false;z_index=500
	_build_background();_build_header();_build_dial();_build_capsule();_build_result();set_language(language)

func _build_background()->void:
	machine_stage=Control.new();machine_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);machine_stage.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(machine_stage)
	var background:=TextureRect.new();background.name="SecretGachaBackground";background.texture=BACKGROUND_TEXTURE;background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;background.stretch_mode=TextureRect.STRETCH_SCALE;background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.mouse_filter=Control.MOUSE_FILTER_IGNORE;machine_stage.add_child(background)
	var shade:=ColorRect.new();shade.color=Color(.055,.025,.008,.10);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;machine_stage.add_child(shade)

func _build_header()->void:
	var title:=Label.new();title.name="Title";title.position=Vector2(132,20);title.size=Vector2(312,66);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",30);title.add_theme_color_override("font_color",Color("#fff1c2"));title.add_theme_color_override("font_outline_color",Color("#32160b"));title.add_theme_constant_override("outline_size",8);add_child(title)
	wallet_label=Label.new();wallet_label.position=Vector2(22,92);wallet_label.size=Vector2(250,48);wallet_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;wallet_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;wallet_label.add_theme_font_size_override("font_size",18);wallet_label.add_theme_color_override("font_color",Color("#ffe99b"));wallet_label.add_theme_stylebox_override("normal",_box(Color(.14,.065,.025,.88),Color("#d7a64c"),18,2));add_child(wallet_label)
	remaining_label=Label.new();remaining_label.position=Vector2(286,96);remaining_label.size=Vector2(148,40);remaining_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;remaining_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;remaining_label.add_theme_font_size_override("font_size",16);remaining_label.add_theme_color_override("font_color",UI_CREAM);remaining_label.add_theme_color_override("font_outline_color",Color("#32160b"));remaining_label.add_theme_constant_override("outline_size",5);add_child(remaining_label)
	close_button=Button.new();close_button.position=Vector2(448,28);close_button.size=Vector2(106,54);_skin_button(close_button,Color("#f4deb3"),17);close_button.pressed.connect(_request_close);add_child(close_button)

func _build_dial()->void:
	dial_texture=TextureRect.new();dial_texture.name="ReplaceableTemporaryDial";dial_texture.texture=DIAL_TEXTURE;dial_texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;dial_texture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;dial_texture.position=Vector2(240,524);dial_texture.size=Vector2(112,112);dial_texture.pivot_offset=dial_texture.size*.5;dial_texture.mouse_filter=Control.MOUSE_FILTER_IGNORE;machine_stage.add_child(dial_texture)
	dial_hit_area=Button.new();dial_hit_area.flat=true;dial_hit_area.position=Vector2(224,508);dial_hit_area.size=Vector2(144,144);dial_hit_area.focus_mode=Control.FOCUS_NONE;dial_hit_area.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;dial_hit_area.gui_input.connect(_on_dial_input);add_child(dial_hit_area)
	hint_label=Label.new();hint_label.position=Vector2(108,856);hint_label.size=Vector2(360,44);hint_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;hint_label.add_theme_font_size_override("font_size",18);hint_label.add_theme_color_override("font_color",Color("#fff0bd"));hint_label.add_theme_color_override("font_outline_color",Color("#32160b"));hint_label.add_theme_constant_override("outline_size",7);add_child(hint_label)
	spin_button=Button.new();spin_button.position=Vector2(148,908);spin_button.size=Vector2(280,72);_skin_button(spin_button,Color("#b97d2d"),20);spin_button.pressed.connect(_request_spin);add_child(spin_button)

func _build_capsule()->void:
	capsule=CapsuleClass.new();capsule.position=Vector2(244,705);capsule.size=Vector2(88,88);capsule.pivot_offset=capsule.size*.5;capsule.mouse_filter=Control.MOUSE_FILTER_IGNORE;capsule.visible=false;add_child(capsule)
	capsule_hit_area=Button.new();capsule_hit_area.flat=true;capsule_hit_area.position=Vector2(224,688);capsule_hit_area.size=Vector2(136,144);capsule_hit_area.focus_mode=Control.FOCUS_NONE;capsule_hit_area.visible=false;capsule_hit_area.pressed.connect(_reveal_result);add_child(capsule_hit_area)

func _build_result()->void:
	result_overlay=Control.new();result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);result_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;result_overlay.visible=false;result_overlay.z_index=20;add_child(result_overlay)
	var dim:=ColorRect.new();dim.color=Color(.02,.012,.006,.86);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);dim.mouse_filter=Control.MOUSE_FILTER_STOP;result_overlay.add_child(dim)
	result_flash=ColorRect.new();result_flash.color=Color(1,.80,.37,0);result_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);result_flash.mouse_filter=Control.MOUSE_FILTER_IGNORE;result_overlay.add_child(result_flash)
	result_card=PanelContainer.new();result_card.position=Vector2(42,154);result_card.size=Vector2(492,680);result_card.pivot_offset=result_card.size*.5;result_card.add_theme_stylebox_override("panel",_box(Color(.105,.052,.022,.98),Color("#e2ad4e"),30,4));result_overlay.add_child(result_card)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",12);content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);content.offset_left=26;content.offset_top=28;content.offset_right=-26;content.offset_bottom=-26;result_card.add_child(content)
	result_badge=Label.new();result_badge.custom_minimum_size=Vector2(420,56);result_badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;result_badge.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;result_badge.add_theme_font_size_override("font_size",34);result_badge.add_theme_color_override("font_color",Color("#ffe36b"));result_badge.add_theme_color_override("font_outline_color",Color("#6e3111"));result_badge.add_theme_constant_override("outline_size",7);content.add_child(result_badge)
	var frame:=PanelContainer.new();frame.custom_minimum_size=Vector2(408,400);frame.add_theme_stylebox_override("panel",_box(Color(.98,.79,.34,.08),Color(1,.83,.39,.62),26,3));content.add_child(frame)
	result_image=TextureRect.new();result_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;result_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;result_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);result_image.offset_left=18;result_image.offset_top=18;result_image.offset_right=-18;result_image.offset_bottom=-18;result_image.mouse_filter=Control.MOUSE_FILTER_IGNORE;frame.add_child(result_image)
	result_name=Label.new();result_name.custom_minimum_size=Vector2(420,66);result_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;result_name.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;result_name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;result_name.add_theme_font_size_override("font_size",26);result_name.add_theme_color_override("font_color",Color("#fff1d0"));content.add_child(result_name)
	result_close_button=Button.new();result_close_button.custom_minimum_size=Vector2(258,62);_skin_button(result_close_button,Color("#ca913a"),18);result_close_button.pressed.connect(_close_result);content.add_child(result_close_button)

func set_language(value:String)->void:
	language=Localizer.normalize_language(value)
	if not is_node_ready():return
	(get_node_or_null("Title") as Label).text=Localizer.text(language,"secret_gacha")
	close_button.text=Localizer.text(language,"back");spin_button.text=Localizer.text(language,"gacha_spin");result_close_button.text=Localizer.text(language,"close")
	hint_label.text=Localizer.text(language,"secret_gacha_dial_hint");set_wallet(current_puku_points,current_remaining)

func configure_timings(dial_seconds:float,shake_seconds:float)->void:
	dial_duration_seconds=clampf(dial_seconds,1.8,2.2);shake_duration_seconds=clampf(shake_seconds,1.2,1.6)

func open_gacha(puku_points:int,remaining:int)->void:
	visible=true;pending_result.clear();pending_texture=null;busy=false;capsule_ready=false;capsule.visible=false;capsule_hit_area.visible=false;result_overlay.visible=false;close_button.disabled=false;hint_label.text=Localizer.text(language,"secret_gacha_dial_hint");set_wallet(puku_points,remaining)

func close_gacha()->void:
	visible=false;pending_result.clear();pending_texture=null;busy=false;capsule_ready=false

func set_wallet(puku_points:int,remaining:int)->void:
	current_puku_points=maxi(0,puku_points);current_remaining=maxi(0,remaining)
	if wallet_label:wallet_label.text=Localizer.text(language,"wallet",[current_puku_points])
	if remaining_label:remaining_label.text=Localizer.text(language,"secret_remaining",[current_remaining])
	if spin_button:
		spin_button.disabled=busy or capsule_ready or result_overlay.visible or current_puku_points<1 or current_remaining<=0
		dial_hit_area.disabled=spin_button.disabled

func play_spin(result:Dictionary,texture:Texture2D)->void:
	if busy:return
	pending_result=result.duplicate(true);pending_texture=texture;busy=true;capsule_ready=false;close_button.disabled=true;spin_button.disabled=true;dial_hit_area.disabled=true;hint_label.text=Localizer.text(language,"secret_turning")
	dial_texture.rotation=0.0;machine_stage.position=Vector2.ZERO
	var turn:=create_tween();turn.tween_property(dial_texture,"rotation",TAU*2.35,dial_duration_seconds*animation_time_scale).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	await turn.finished
	var unit:=shake_duration_seconds/10.0*animation_time_scale;var shake:=create_tween()
	for offset in [-7.0,6.0,-5.0,5.0,-3.5,3.0,-2.0,1.5,0.0]:shake.tween_property(machine_stage,"position:x",offset,unit).set_trans(Tween.TRANS_SINE)
	await shake.finished
	capsule.set_seed(str(result.get("species_id",result.get("pot_id",result.get("series_id","secret")))).hash());capsule.position=Vector2(244,700);capsule.scale=Vector2(.32,.32);capsule.rotation=-.28;capsule.modulate=Color(1,1,1,0);capsule.visible=true
	var drop:=create_tween().set_parallel(true);drop.tween_property(capsule,"position",Vector2(244,770),.54*animation_time_scale).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT);drop.tween_property(capsule,"scale",Vector2.ONE,.38*animation_time_scale).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);drop.tween_property(capsule,"rotation",.16,.52*animation_time_scale);drop.tween_property(capsule,"modulate:a",1.0,.18*animation_time_scale)
	await drop.finished
	busy=false;capsule_ready=true;capsule_hit_area.visible=true;hint_label.text=Localizer.text(language,"gacha_capsule_hint")

func _reveal_result()->void:
	if not capsule_ready or pending_result.is_empty():return
	capsule_ready=false;busy=true;capsule.visible=false;capsule_hit_area.visible=false
	if str(pending_result.get("category",""))=="species":species_reveal_requested.emit(pending_result.duplicate(true));return
	result_image.texture=pending_texture;result_badge.text=Localizer.text(language,"get")
	var category:=str(pending_result.get("category",""))
	if category=="pot":result_name.text=Localizer.pot_name(language,pending_result.get("pot_entry",{}))
	elif category=="catalog_page":result_name.text=Localizer.text(language,"secret_catalog_page_prize",[Localizer.series_name(language,pending_result.get("series_entry",{}))])
	else:result_name.text=Localizer.text(language,"secret_prize")
	result_overlay.visible=true;result_card.scale=Vector2(.66,.66);result_flash.color.a=.92
	var reveal:=create_tween().set_parallel(true);reveal.tween_property(result_card,"scale",Vector2.ONE,.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);reveal.tween_property(result_flash,"color:a",0.0,.48)
	await reveal.finished
	busy=false

func resume_after_species_reveal()->void:
	pending_result.clear();pending_texture=null;busy=false;close_button.disabled=false;hint_label.text=Localizer.text(language,"secret_gacha_dial_hint");set_wallet(current_puku_points,current_remaining)

func _close_result()->void:
	if busy:return
	result_overlay.visible=false;result_image.texture=null;pending_result.clear();pending_texture=null;close_button.disabled=false;hint_label.text=Localizer.text(language,"secret_gacha_dial_hint");set_wallet(current_puku_points,current_remaining)

func _on_dial_input(event:InputEvent)->void:
	if event is InputEventScreenTouch:
		if event.pressed:_dial_dragging=true
		elif _dial_dragging:_dial_dragging=false;_request_spin()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:_dial_dragging=true
		elif _dial_dragging:_dial_dragging=false;_request_spin()
	elif event is InputEventScreenDrag and _dial_dragging:dial_texture.rotation+=event.relative.x*.018
	elif event is InputEventMouseMotion and _dial_dragging:dial_texture.rotation+=event.relative.x*.018

func _request_spin()->void:
	if busy or capsule_ready or result_overlay.visible or spin_button.disabled:return
	spin_requested.emit()

func _request_close()->void:
	if busy or capsule_ready or result_overlay.visible:return
	close_requested.emit()

func is_busy()->bool:return busy or capsule_ready or result_overlay.visible

func _skin_button(button:Button,background:Color,font_size:int)->void:
	button.add_theme_font_size_override("font_size",font_size);button.add_theme_color_override("font_color",UI_BROWN if background.get_luminance()>.55 else Color.WHITE);button.add_theme_stylebox_override("normal",_box(background,background.lightened(.22),20,3));button.add_theme_stylebox_override("hover",_box(background.lightened(.08),Color.WHITE,20,3));button.add_theme_stylebox_override("pressed",_box(background.darkened(.08),background.lightened(.2),20,3));button.add_theme_stylebox_override("disabled",_box(background.darkened(.28),Color(.55,.48,.36,.65),20,2))

func _box(background:Color,border:Color,radius:int,width:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=background;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius);style.shadow_color=Color(.10,.04,.01,.36);style.shadow_size=7;style.shadow_offset=Vector2(0,3);style.content_margin_left=10;style.content_margin_right=10;style.content_margin_top=6;style.content_margin_bottom=6;return style
