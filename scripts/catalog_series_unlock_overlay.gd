class_name CatalogSeriesUnlockOverlay
extends Control

signal closed(context:String)

const Localizer=preload("res://scripts/game_localizer.gd")

var title_label:Label
var cover_image:TextureRect
var cover_placeholder:Label
var message_label:Label
var hint_label:Label
var card:PanelContainer
var flash:ColorRect
var current_context:=""
var current_language:="ja"
var busy:=false

func _ready()->void:
	name="CatalogSeriesUnlockOverlay";set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP;visible=false;z_index=910
	var dim:=ColorRect.new();dim.color=Color(0.018,.012,.03,.86);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);dim.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(dim)
	flash=ColorRect.new();flash.color=Color(1.0,.94,.62,0.0);flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);flash.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(flash)
	card=PanelContainer.new();card.position=Vector2(34,112);card.size=Vector2(508,770);card.pivot_offset=card.size*.5
	var style:=StyleBoxFlat.new();style.bg_color=Color(.10,.055,.12,.97);style.border_color=Color("#efc65e");style.set_border_width_all(4);style.set_corner_radius_all(34);style.shadow_color=Color(1.0,.63,.18,.28);style.shadow_size=24;card.add_theme_stylebox_override("panel",style);add_child(card)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",12);content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);content.offset_left=28;content.offset_top=24;content.offset_right=-28;content.offset_bottom=-24;card.add_child(content)
	title_label=Label.new();title_label.custom_minimum_size=Vector2(430,64);title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;title_label.add_theme_font_size_override("font_size",36);title_label.add_theme_color_override("font_color",Color("#fff06a"));title_label.add_theme_color_override("font_outline_color",Color("#8a2c4b"));title_label.add_theme_constant_override("outline_size",8);content.add_child(title_label)
	var glow:=PanelContainer.new();glow.custom_minimum_size=Vector2(420,410)
	var glow_style:=StyleBoxFlat.new();glow_style.bg_color=Color(1,.91,.63,.06);glow_style.border_color=Color(1,.86,.42,.68);glow_style.set_border_width_all(3);glow_style.set_corner_radius_all(34);glow_style.shadow_color=Color(1,.55,.26,.35);glow_style.shadow_size=22;glow.add_theme_stylebox_override("panel",glow_style);content.add_child(glow)
	cover_image=TextureRect.new();cover_image.name="SeriesCoverImage";cover_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;cover_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;cover_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);cover_image.offset_left=18;cover_image.offset_top=18;cover_image.offset_right=-18;cover_image.offset_bottom=-18;cover_image.mouse_filter=Control.MOUSE_FILTER_IGNORE;glow.add_child(cover_image)
	cover_placeholder=Label.new();cover_placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);cover_placeholder.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;cover_placeholder.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;cover_placeholder.add_theme_font_size_override("font_size",20);cover_placeholder.add_theme_color_override("font_color",Color("#e6ca90"));cover_placeholder.mouse_filter=Control.MOUSE_FILTER_IGNORE;glow.add_child(cover_placeholder)
	message_label=Label.new();message_label.custom_minimum_size=Vector2(430,132);message_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;message_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;message_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;message_label.add_theme_font_size_override("font_size",22);message_label.add_theme_color_override("font_color",Color("#fff4dc"));message_label.add_theme_color_override("font_outline_color",Color("#3a1724"));message_label.add_theme_constant_override("outline_size",5);content.add_child(message_label)
	hint_label=Label.new();hint_label.custom_minimum_size=Vector2(430,38);hint_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;hint_label.add_theme_font_size_override("font_size",17);hint_label.add_theme_color_override("font_color",Color("#ead8c0"));content.add_child(hint_label)

func show_series(_series_entry:Dictionary,texture:Texture2D,display_name:String,context:String,language:String="ja")->void:
	current_context=context;current_language=Localizer.normalize_language(language);visible=true;busy=true
	title_label.text=Localizer.text(current_language,"catalog_series_unlock_title")
	cover_image.set_meta("catalog_loaded_path","");cover_image.set_meta("catalog_request_path","")
	cover_image.texture=texture;cover_image.visible=texture!=null;cover_placeholder.visible=texture==null;cover_placeholder.text=Localizer.text(current_language,"catalog_cover_preparing")
	message_label.text=Localizer.text(current_language,"catalog_series_first_unlock",[display_name]);hint_label.text=Localizer.text(current_language,"tap_to_close")
	card.scale=Vector2(.56,.56);card.rotation=-.035;flash.color.a=.94
	var reveal:=create_tween().set_parallel(true);reveal.tween_property(card,"scale",Vector2.ONE,.44).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);reveal.tween_property(card,"rotation",0.0,.34).set_trans(Tween.TRANS_QUAD);reveal.tween_property(flash,"color:a",0.0,.52)
	await reveal.finished
	busy=false

func _input(event:InputEvent)->void:
	if not visible:return
	var close_press:bool=event is InputEventScreenTouch and event.pressed
	close_press=close_press or (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed)
	if not close_press:return
	get_viewport().set_input_as_handled()
	if not busy:close_overlay()

func close_overlay()->void:
	if not visible or busy:return
	busy=true
	var context:=current_context
	var hide:=create_tween().set_parallel(true);hide.tween_property(card,"scale",Vector2(.86,.86),.16).set_trans(Tween.TRANS_QUAD);hide.tween_property(self,"modulate:a",0.0,.16)
	await hide.finished
	visible=false;modulate.a=1.0;card.scale=Vector2.ONE;cover_image.texture=null;cover_image.set_meta("catalog_loaded_path","");cover_image.set_meta("catalog_request_path","");current_context="";busy=false;closed.emit(context)

func reset_overlay()->void:
	visible=false;modulate.a=1.0;busy=false;current_context=""
	if card:card.scale=Vector2.ONE;card.rotation=0.0
	if cover_image:cover_image.texture=null;cover_image.set_meta("catalog_loaded_path","");cover_image.set_meta("catalog_request_path","")

func is_open()->bool:return visible
