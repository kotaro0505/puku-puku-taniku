class_name SpeciesGetOverlay
extends Control

signal closed(context:String)

const StarRatingClass=preload("res://scripts/star_rating.gd")
const Localizer=preload("res://scripts/game_localizer.gd")

var result_image:TextureRect
var badge_label:Label
var name_label:Label
var rarity_label:Label
var star_rating:Control
var hint_label:Label
var card:PanelContainer
var flash:ColorRect
var current_context:=""
var current_language:="ja"
var busy:=false

func _ready()->void:
	name="SpeciesGetOverlay";set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP;visible=false;z_index=900
	var dim:=ColorRect.new();dim.color=Color(0.018,.012,.03,.86);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);dim.mouse_filter=Control.MOUSE_FILTER_STOP;dim.gui_input.connect(_on_background_input);add_child(dim)
	flash=ColorRect.new();flash.color=Color(1.0,.94,.62,0.0);flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);flash.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(flash)
	card=PanelContainer.new();card.position=Vector2(34,112);card.size=Vector2(508,770);card.pivot_offset=card.size*.5;var style:=StyleBoxFlat.new();style.bg_color=Color(.10,.055,.12,.97);style.border_color=Color("#efc65e");style.set_border_width_all(4);style.set_corner_radius_all(34);style.shadow_color=Color(1.0,.63,.18,.28);style.shadow_size=24;card.add_theme_stylebox_override("panel",style);add_child(card)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",10);content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);content.offset_left=28;content.offset_top=24;content.offset_right=-28;content.offset_bottom=-24;card.add_child(content)
	badge_label=Label.new();badge_label.custom_minimum_size=Vector2(430,64);badge_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;badge_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;badge_label.add_theme_font_size_override("font_size",38);badge_label.add_theme_color_override("font_color",Color("#fff06a"));badge_label.add_theme_color_override("font_outline_color",Color("#8a2c4b"));badge_label.add_theme_constant_override("outline_size",8);content.add_child(badge_label)
	var glow:=PanelContainer.new();glow.custom_minimum_size=Vector2(420,430);var glow_style:=StyleBoxFlat.new();glow_style.bg_color=Color(1,.91,.63,.06);glow_style.border_color=Color(1,.86,.42,.68);glow_style.set_border_width_all(3);glow_style.set_corner_radius_all(34);glow_style.shadow_color=Color(1,.55,.26,.35);glow_style.shadow_size=22;glow.add_theme_stylebox_override("panel",glow_style);content.add_child(glow)
	result_image=TextureRect.new();result_image.name="SpeciesImage";result_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;result_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;result_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);result_image.offset_left=18;result_image.offset_top=18;result_image.offset_right=-18;result_image.offset_bottom=-18;result_image.mouse_filter=Control.MOUSE_FILTER_IGNORE;glow.add_child(result_image)
	name_label=Label.new();name_label.custom_minimum_size=Vector2(430,64);name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;name_label.add_theme_font_size_override("font_size",30);name_label.add_theme_color_override("font_color",Color("#fff4dc"));name_label.add_theme_color_override("font_outline_color",Color("#3a1724"));name_label.add_theme_constant_override("outline_size",6);content.add_child(name_label)
	var rating_row:=HBoxContainer.new();rating_row.alignment=BoxContainer.ALIGNMENT_CENTER;rating_row.custom_minimum_size=Vector2(430,44);rating_row.add_theme_constant_override("separation",10);content.add_child(rating_row)
	rarity_label=Label.new();rarity_label.add_theme_font_size_override("font_size",18);rarity_label.add_theme_color_override("font_color",Color("#ffd76e"));rating_row.add_child(rarity_label)
	star_rating=StarRatingClass.new();rating_row.add_child(star_rating)
	hint_label=Label.new();hint_label.custom_minimum_size=Vector2(430,44);hint_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;hint_label.add_theme_font_size_override("font_size",17);hint_label.add_theme_color_override("font_color",Color("#ead8c0"));content.add_child(hint_label)

func show_species(entry:Dictionary,texture:Texture2D,is_new:bool,context:String,language:String="ja")->void:
	current_context=context;current_language=Localizer.normalize_language(language);visible=true;busy=true
	result_image.texture=texture;badge_label.text=Localizer.text(current_language,"new" if is_new else "get");name_label.text=Localizer.species_name(current_language,entry)
	var stars:=clampi(int(entry.get("gold_star_count",0)),0,2);star_rating.star_count=stars;rarity_label.text=Localizer.text(current_language,"super_rare") if stars>0 else "";star_rating.visible=stars>0;hint_label.text=Localizer.text(current_language,"tap_to_close")
	card.scale=Vector2(.56,.56);card.rotation=-.035;flash.color.a=.94
	var reveal:=create_tween().set_parallel(true);reveal.tween_property(card,"scale",Vector2.ONE,.44).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);reveal.tween_property(card,"rotation",0.0,.34).set_trans(Tween.TRANS_QUAD);reveal.tween_property(flash,"color:a",0.0,.52)
	await reveal.finished
	busy=false

func _on_background_input(event:InputEvent)->void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed):close_overlay()

func close_overlay()->void:
	if not visible or busy:return
	busy=true
	var context:=current_context
	var hide:=create_tween().set_parallel(true);hide.tween_property(card,"scale",Vector2(.86,.86),.16).set_trans(Tween.TRANS_QUAD);hide.tween_property(self,"modulate:a",0.0,.16)
	await hide.finished
	visible=false;modulate.a=1.0;card.scale=Vector2.ONE;result_image.texture=null;current_context="";busy=false;closed.emit(context)

func is_open()->bool:return visible
