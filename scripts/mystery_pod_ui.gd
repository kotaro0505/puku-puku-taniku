class_name MysteryPodUI
extends Control

signal close_requested
signal open_pod_requested
signal series_seed_play_requested(series_id:String)
signal iap_purchase_requested(product_id:String)

const UI_CREAM:=Color("#fff1d2")
const UI_BROWN:=Color("#4a2618")

var pod_count_label:Label
var open_button:Button
var message_label:Label
var results_box:VBoxContainer
var seed_inventory_box:VBoxContainer
var purchase_box:VBoxContainer
var rates_label:Label
var opening_animation_active:=false

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP;visible=false
	_build_ui()

func open()->void:
	visible=true

func close()->void:
	if opening_animation_active:return
	visible=false;close_requested.emit()

func configure(pod_count:int,seed_inventory:Dictionary,series_catalog:Array,unlocked_series:Dictionary,products:Array,localized_prices:Dictionary,rates_text:String,iap_available:bool)->void:
	pod_count_label.text="未開封の不思議なさや　%d個"%maxi(0,pod_count)
	open_button.disabled=pod_count<=0 or opening_animation_active
	_rebuild_seed_inventory(seed_inventory,series_catalog,unlocked_series)
	_rebuild_purchase_products(products,localized_prices,iap_available)
	rates_label.text=rates_text

func set_message(text_value:String)->void:
	message_label.text=text_value

func show_open_results(results:Array[Dictionary])->void:
	opening_animation_active=true;open_button.disabled=true
	_clear_children(results_box)
	var title:=_label("さやがひらいた！",22,Color("#7c4b2a"));title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;results_box.add_child(title)
	for slot_index in range(results.size()):
		var placeholder:=_result_panel("？　？　？",Color("#d9c49d"));placeholder.modulate.a=0.0;placeholder.scale=Vector2(.72,.72);placeholder.pivot_offset=Vector2(220,35);results_box.add_child(placeholder)
		var tween:=create_tween().bind_node(placeholder);tween.tween_interval(.18 if slot_index==0 else .28);tween.tween_property(placeholder,"modulate:a",1.0,.10);tween.parallel().tween_property(placeholder,"scale",Vector2.ONE,.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween.finished
		var result:Dictionary=results[slot_index]
		if str(result.get("kind",""))=="series_seed":
			var result_label:=placeholder.get_child(0) as Label
			result_label.text="ポン！　%sの種"%str(result.get("display_name","シリーズ"))
			placeholder.add_theme_stylebox_override("panel",_box(Color("#e6d5a4"),Color("#b77c3e"),18,3))
		else:
			var result_label:=placeholder.get_child(0) as Label
			result_label.text="ポン！　%sゲーム円"%_comma(int(result.get("amount",1000)))
			placeholder.add_theme_stylebox_override("panel",_box(Color("#efd78c"),Color("#c28a2c"),18,3))
	opening_animation_active=false
	message_label.text="3つの中身を受け取りました"

func _build_ui()->void:
	var background:=ColorRect.new();background.color=Color("#3d2419");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(background)
	var title:=_label("不思議なさや",31,UI_CREAM);title.position=Vector2(30,25);title.size=Vector2(390,58);add_child(title)
	var back:=_button("もどる",Vector2(447,27),Vector2(105,55),Color("#fff0cf"),17);back.pressed.connect(close);add_child(back)
	pod_count_label=_label("未開封の不思議なさや　0個",20,Color("#f3cf8a"));pod_count_label.position=Vector2(30,88);pod_count_label.size=Vector2(516,36);pod_count_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;add_child(pod_count_label)
	open_button=_button("1個開ける",Vector2(128,132),Vector2(320,64),Color("#dca85e"),22);open_button.pressed.connect(func():open_pod_requested.emit());add_child(open_button)
	message_label=_label("さやを開けると、3つの中身が出てきます",15,UI_CREAM);message_label.position=Vector2(32,198);message_label.size=Vector2(512,34);message_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;add_child(message_label)
	var scroll:=ScrollContainer.new();scroll.position=Vector2(20,238);scroll.size=Vector2(536,760);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(scroll)
	var content:=VBoxContainer.new();content.custom_minimum_size=Vector2(516,0);content.add_theme_constant_override("separation",12);scroll.add_child(content)
	results_box=VBoxContainer.new();results_box.add_theme_constant_override("separation",8);content.add_child(results_box)
	var result_hint:=_label("まだ開封していません",17,Color("#76513b"));result_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;results_box.add_child(result_hint)
	content.add_child(_section_title("所持しているシリーズ種"))
	seed_inventory_box=VBoxContainer.new();seed_inventory_box.add_theme_constant_override("separation",7);content.add_child(seed_inventory_box)
	content.add_child(_section_title("不思議なさやを購入（iOS）"))
	purchase_box=VBoxContainer.new();purchase_box.add_theme_constant_override("separation",7);content.add_child(purchase_box)
	content.add_child(_section_title("提供割合"))
	rates_label=_label("",14,Color("#60402e"));rates_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;rates_label.add_theme_stylebox_override("normal",_box(Color("#f2dfba"),Color("#b98b58"),16,2));content.add_child(rates_label)
	var spacer:=Control.new();spacer.custom_minimum_size=Vector2(1,36);content.add_child(spacer)

func _rebuild_seed_inventory(seed_inventory:Dictionary,series_catalog:Array,unlocked_series:Dictionary)->void:
	_clear_children(seed_inventory_box);var found_any:=false
	for raw_series in series_catalog:
		if not raw_series is Dictionary:continue
		var series_id:=str(raw_series.get("series_id",""));var count:=maxi(0,int(seed_inventory.get(series_id,0)))
		if count<=0 or not bool(unlocked_series.get(series_id,false)):continue
		found_any=true
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);seed_inventory_box.add_child(row)
		var label:=_label("%sの種　%d個"%[str(raw_series.get("display_name",series_id)),count],17,UI_BROWN);label.custom_minimum_size=Vector2(320,52);label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(label)
		var play:=_button("1個まく",Vector2.ZERO,Vector2(150,52),Color("#d8b56b"),17);play.pressed.connect(func():series_seed_play_requested.emit(series_id));row.add_child(play)
	if not found_any:
		var empty:=_label("シリーズ種はまだありません",16,Color("#806047"));empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;seed_inventory_box.add_child(empty)

func _rebuild_purchase_products(products:Array,localized_prices:Dictionary,iap_available:bool)->void:
	_clear_children(purchase_box)
	for raw_product in products:
		if not raw_product is Dictionary:continue
		var product_id:=str(raw_product.get("product_id",""));var pod_count:=int(raw_product.get("pod_count",0));var price:=str(localized_prices.get(product_id,raw_product.get("display_price","")))
		var button:=_button("さや%d個　%s"%[pod_count,price],Vector2.ZERO,Vector2(490,52),Color("#d5a85d"),17);button.disabled=not iap_available;button.pressed.connect(func():iap_purchase_requested.emit(product_id));purchase_box.add_child(button)
	var note:=_label("App Storeの消費型商品です。購入の復元対象にはなりません。" if iap_available else "購入はApp Store Connect設定済みのiOS版で利用できます。",13,Color("#806047"));note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;purchase_box.add_child(note)

func _result_panel(text_value:String,color:Color)->PanelContainer:
	var panel:=PanelContainer.new();panel.custom_minimum_size=Vector2(490,70);panel.add_theme_stylebox_override("panel",_box(color,color.darkened(.22),18,3))
	var label:=_label(text_value,19,UI_BROWN);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;panel.add_child(label);return panel

func _section_title(text_value:String)->Label:
	var label:=_label(text_value,19,UI_CREAM);label.custom_minimum_size=Vector2(500,42);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.add_theme_stylebox_override("normal",_box(Color("#68452f"),Color("#b98b58"),14,2));return label

func _label(text_value:String,font_size:int,color:Color)->Label:
	var label:=Label.new();label.text=text_value;label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",color);return label

func _button(text_value:String,position_value:Vector2,size_value:Vector2,bg:Color,font_size:int)->Button:
	var button:=Button.new();button.text=text_value;button.position=position_value;button.custom_minimum_size=size_value;button.size=size_value;button.add_theme_font_size_override("font_size",font_size);button.add_theme_color_override("font_color",UI_BROWN);button.add_theme_stylebox_override("normal",_box(bg,bg.lightened(.18),18,2));button.add_theme_stylebox_override("hover",_box(bg.lightened(.08),Color.WHITE,18,2));button.add_theme_stylebox_override("pressed",_box(bg.darkened(.08),bg.lightened(.18),18,2));button.add_theme_stylebox_override("disabled",_box(Color("#947c64"),Color("#b9a58e"),18,2));return button

func _box(bg:Color,border:Color,radius:int,width:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius);style.content_margin_left=12;style.content_margin_right=12;style.content_margin_top=8;style.content_margin_bottom=8;return style

func _clear_children(parent:Node)->void:
	for child in parent.get_children():child.queue_free()

func _comma(value:int)->String:
	var source:=str(value);var output:=""
	for index in range(source.length()):
		if index>0 and (source.length()-index)%3==0:output+=","
		output+=source[index]
	return output
