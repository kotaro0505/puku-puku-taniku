class_name MysteryPodDev
extends Control

signal close_requested
signal state_changed
signal add_pods_requested(amount:int)
signal force_main_spawn_requested
signal force_habitat_spawn_requested
signal open_test_requested
signal add_all_series_seeds_requested

const UI_BROWN:=Color("#4a2618")
var pod_system:Variant
var controls:Dictionary={}
var status_label:Label

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP;visible=false
	_build_ui()

func configure(system:Variant)->void:
	pod_system=system;_sync_controls()

func open()->void:
	_sync_controls();visible=true

func close()->void:
	visible=false;close_requested.emit()

func set_status(text_value:String)->void:
	status_label.text=text_value

func _build_ui()->void:
	var shade:=ColorRect.new();shade.color=Color(0.08,0.04,0.03,.84);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(shade)
	var panel:=PanelContainer.new();panel.position=Vector2(18,18);panel.size=Vector2(540,988);panel.add_theme_stylebox_override("panel",_box(Color("#f7e8c7"),Color("#8f633b"),24,4));add_child(panel)
	var outer:=VBoxContainer.new();outer.add_theme_constant_override("separation",7);panel.add_child(outer)
	var header:=HBoxContainer.new();outer.add_child(header)
	var title:=_label("開発用：不思議なさや調整",22);title.custom_minimum_size=Vector2(380,48);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;header.add_child(title)
	var close_button:=_button("閉じる",Vector2(120,46),Color("#ead8b1"),15);close_button.pressed.connect(close);header.add_child(close_button)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(500,840);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;outer.add_child(scroll)
	var content:=VBoxContainer.new();content.custom_minimum_size=Vector2(492,0);content.add_theme_constant_override("separation",6);scroll.add_child(content)
	_add_setting(content,"slots_per_pod","1さやの枠数",1,10,1)
	_add_setting(content,"series_seed_weight","種枠率（相対値）",0,100,1)
	_add_setting(content,"normal_seed_weight","普通のたね袋枠率（相対値）",0,100,1)
	_add_setting(content,"normal_seed_bag_count","普通のたね袋数 / 枠",1,10,1)
	_add_setting(content,"main_play_pod_chance","メイン出現率",0,1,.01,true)
	_add_setting(content,"habitat_pod_chance","原生地出現率",0,1,.01,true)
	_add_setting(content,"armadillo_pod_bonus_chance","アルマジロ報酬率",0,1,.01,true)
	_add_setting(content,"armadillo_pod_bonus_count","アルマジロ付与個数",1,20,1)
	_add_setting(content,"completed_series_weight_multiplier","コンプ済み補正",0,1,.01)
	_add_setting(content,"discovered_species_weight_multiplier","既出品種補正",0,1,.01)
	_add_setting(content,"default_catalog_price_pods","図鑑さや交換数",0,100,1)
	var reset:=_button("正式値に戻す",Vector2(470,48),Color("#c7b4d9"),16);reset.pressed.connect(_reset_formal);content.add_child(reset)
	var actions:=GridContainer.new();actions.columns=2;actions.add_theme_constant_override("h_separation",7);actions.add_theme_constant_override("v_separation",7);content.add_child(actions)
	_add_action(actions,"不思議なさや +1",func():add_pods_requested.emit(1))
	_add_action(actions,"不思議なさや +10",func():add_pods_requested.emit(10))
	_add_action(actions,"さやを温室へ強制出現",func():force_main_spawn_requested.emit())
	_add_action(actions,"さやを原生地へ強制出現",func():force_habitat_spawn_requested.emit())
	_add_action(actions,"3枠開封テスト",func():open_test_requested.emit())
	_add_action(actions,"シリーズ種を各1個追加",func():add_all_series_seeds_requested.emit())
	status_label=_label("FORMAL値を使用中",14);status_label.custom_minimum_size=Vector2(490,44);status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;content.add_child(status_label)

func _add_setting(parent:VBoxContainer,key:String,title:String,min_value:float,max_value:float,step:float,as_percent:=false)->void:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);parent.add_child(row)
	var label:=_label(title,15);label.custom_minimum_size=Vector2(292,42);label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(label)
	var spin:=SpinBox.new();spin.custom_minimum_size=Vector2(180,42);spin.min_value=min_value*(100.0 if as_percent else 1.0);spin.max_value=max_value*(100.0 if as_percent else 1.0);spin.step=step*(100.0 if as_percent else 1.0);spin.suffix="%" if as_percent else "";spin.value_changed.connect(_on_setting_changed.bind(key,as_percent));row.add_child(spin);controls[key]=spin

func _on_setting_changed(value:float,key:String,as_percent:bool)->void:
	if pod_system==null:return
	pod_system.set_setting(key,value/100.0 if as_percent else value);status_label.text="テストoverrideを使用中";state_changed.emit()

func _reset_formal()->void:
	if pod_system==null:return
	pod_system.reset_formal();_sync_controls();status_label.text="正式値に戻しました";state_changed.emit()

func _sync_controls()->void:
	if pod_system==null:return
	for key in controls:
		var spin:SpinBox=controls[key];spin.set_value_no_signal(float(pod_system.settings.get(key,0.0))*(100.0 if spin.suffix=="%" else 1.0))

func _add_action(parent:GridContainer,text_value:String,callback:Callable)->void:
	var button:=_button(text_value,Vector2(238,48),Color("#d8b56b"),14);button.pressed.connect(callback);parent.add_child(button)

func _label(text_value:String,size_value:int)->Label:
	var label:=Label.new();label.text=text_value;label.add_theme_font_size_override("font_size",size_value);label.add_theme_color_override("font_color",UI_BROWN);return label

func _button(text_value:String,size_value:Vector2,bg:Color,font_size:int)->Button:
	var button:=Button.new();button.text=text_value;button.custom_minimum_size=size_value;button.add_theme_font_size_override("font_size",font_size);button.add_theme_color_override("font_color",UI_BROWN);button.add_theme_stylebox_override("normal",_box(bg,bg.lightened(.18),15,2));button.add_theme_stylebox_override("pressed",_box(bg.darkened(.08),bg.lightened(.18),15,2));return button

func _box(bg:Color,border:Color,radius:int,width:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius);style.content_margin_left=10;style.content_margin_right=10;style.content_margin_top=7;style.content_margin_bottom=7;return style
