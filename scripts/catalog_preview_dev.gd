class_name CatalogPreviewDev
extends Control

signal close_requested
signal preview_species_requested(species_id:String)
signal preview_batch_requested(species_ids:Array,series_name:String)
signal clear_requested

const MAX_PLANTS_PER_BATCH := 24
const UI_CREAM := Color("#fff1d2")
const UI_BROWN := Color("#4a2618")

var catalog_species:Array=[]
var series_catalog:Array=[]
var series_groups:Array=[]
var selected_group_index:=0
var group_batch_offsets:Dictionary={}
var all_group_cursor:=0
var session_active:=false

var overlay:Control
var launcher_button:Button
var series_picker:OptionButton
var species_grid:GridContainer
var status_label:Label
var series_batch_button:Button

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	_build_ui()

func configure(species_data:Array,series_data:Array)->void:
	catalog_species=species_data
	series_catalog=series_data
	_rebuild_groups()
	_refresh_series_picker()
	_refresh_species_grid()

func open()->void:
	overlay.visible=true
	launcher_button.visible=false
	_refresh_species_grid()

func is_overlay_open()->bool:
	return overlay!=null and overlay.visible

func set_session_active(active:bool)->void:
	session_active=active
	launcher_button.visible=active and not overlay.visible
	if not active and status_label:status_label.text="プレビュー株はありません"

func group_count()->int:
	return series_groups.size()

func species_ids_for_series(series_id:String)->Array:
	for group_value in series_groups:
		var group:Dictionary=group_value
		if str(group.get("series_id",""))==series_id:return group.get("species_ids",[]).duplicate()
	return []

func _build_ui()->void:
	launcher_button=_button("品種プレビュー中\n操作画面へ",Vector2(360,918),Vector2(196,82),Color("#c7b4d9"),15)
	launcher_button.visible=false
	launcher_button.pressed.connect(open)
	add_child(launcher_button)

	overlay=Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	overlay.visible=false
	add_child(overlay)
	var shade:=ColorRect.new()
	shade.color=Color(0.08,0.04,0.03,.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter=Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)
	var panel:=PanelContainer.new()
	panel.position=Vector2(18,22)
	panel.size=Vector2(540,980)
	panel.add_theme_stylebox_override("panel",_box(Color("#f7e8c7"),Color("#8f633b"),24,4))
	overlay.add_child(panel)
	var outer:=VBoxContainer.new()
	outer.add_theme_constant_override("separation",8)
	panel.add_child(outer)
	var title_row:=HBoxContainer.new()
	title_row.alignment=BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation",8)
	outer.add_child(title_row)
	var title:=Label.new()
	title.text="開発用：品種プレビュー"
	title.custom_minimum_size=Vector2(350,48)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",23)
	title.add_theme_color_override("font_color",UI_BROWN)
	title_row.add_child(title)
	var close_button:=_button("温室を見る",Vector2.ZERO,Vector2(128,46),Color("#ead8b1"),14)
	close_button.pressed.connect(_close_overlay)
	title_row.add_child(close_button)
	var note:=Label.new()
	note.text="図鑑登録・GET数・自己ベスト・コイン・セーブには反映されません"
	note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size",13)
	note.add_theme_color_override("font_color",Color("#76513b"))
	outer.add_child(note)
	series_picker=OptionButton.new()
	series_picker.custom_minimum_size=Vector2(490,48)
	series_picker.add_theme_font_size_override("font_size",17)
	series_picker.item_selected.connect(_on_series_selected)
	outer.add_child(series_picker)
	var actions:=HBoxContainer.new()
	actions.alignment=BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation",7)
	outer.add_child(actions)
	series_batch_button=_button("このシリーズを\n全部出す",Vector2.ZERO,Vector2(158,58),Color("#d8b56b"),14)
	series_batch_button.pressed.connect(_preview_selected_series_batch)
	actions.add_child(series_batch_button)
	var all_button:=_button("全シリーズ確認\n（順送り）",Vector2.ZERO,Vector2(158,58),Color("#c7b4d9"),14)
	all_button.pressed.connect(_preview_next_series_batch)
	actions.add_child(all_button)
	var clear_button:=_button("プレビュー株を\n全部消す",Vector2.ZERO,Vector2(158,58),Color("#d9c49d"),14)
	clear_button.pressed.connect(_clear_preview)
	actions.add_child(clear_button)
	status_label=Label.new()
	status_label.text="品種を選ぶと、温室へ1株だけ出します"
	status_label.custom_minimum_size=Vector2(500,44)
	status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size",14)
	status_label.add_theme_color_override("font_color",Color("#6f472f"))
	outer.add_child(status_label)
	var scroll:=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(500,700)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	species_grid=GridContainer.new()
	species_grid.columns=2
	species_grid.custom_minimum_size=Vector2(490,0)
	species_grid.add_theme_constant_override("h_separation",8)
	species_grid.add_theme_constant_override("v_separation",8)
	scroll.add_child(species_grid)

func _rebuild_groups()->void:
	series_groups.clear()
	group_batch_offsets.clear()
	var species_lookup:Dictionary={}
	for raw_species in catalog_species:
		if raw_species is Dictionary:
			var species_id:=str(raw_species.get("species_id",""))
			if not species_id.is_empty():species_lookup[species_id]=raw_species
	var assigned:Dictionary={}
	for raw_series in series_catalog:
		if not raw_series is Dictionary:continue
		var series_id:=str(raw_series.get("series_id",""))
		if series_id.is_empty():continue
		var ids:Array=[]
		var configured_ids=raw_series.get("species_ids",[])
		if configured_ids is Array:
			for configured_id_value in configured_ids:
				var configured_id:=str(configured_id_value)
				if species_lookup.has(configured_id) and configured_id not in ids:ids.append(configured_id)
		for raw_species in catalog_species:
			if not raw_species is Dictionary:continue
			var species_id:=str(raw_species.get("species_id",""))
			if str(raw_species.get("series_id",""))==series_id and species_lookup.has(species_id) and species_id not in ids:ids.append(species_id)
		for species_id in ids:assigned[species_id]=true
		series_groups.append({"series_id":series_id,"display_name":str(raw_series.get("display_name",series_id)),"species_ids":ids})
	var unassigned:Array=[]
	for raw_species in catalog_species:
		if not raw_species is Dictionary:continue
		var species_id:=str(raw_species.get("species_id",""))
		if not species_id.is_empty() and not assigned.has(species_id):unassigned.append(species_id)
	if not unassigned.is_empty():series_groups.append({"series_id":"__unassigned__","display_name":"未分類","species_ids":unassigned})
	selected_group_index=clampi(selected_group_index,0,maxi(0,series_groups.size()-1))
	all_group_cursor=0

func _refresh_series_picker()->void:
	if series_picker==null:return
	series_picker.clear()
	for group_value in series_groups:
		var group:Dictionary=group_value
		series_picker.add_item("%s（%d種）"%[str(group.get("display_name","シリーズ")),_group_ids(group).size()])
	if not series_groups.is_empty():series_picker.select(selected_group_index)

func _refresh_species_grid()->void:
	if species_grid==null:return
	_clear_children(species_grid)
	if series_groups.is_empty():
		series_batch_button.disabled=true
		_add_empty_label("登録済みシリーズがありません")
		return
	var group:Dictionary=series_groups[selected_group_index]
	var ids:=_group_ids(group)
	series_batch_button.disabled=ids.is_empty()
	if ids.is_empty():
		_add_empty_label("このシリーズには、まだ品種が登録されていません")
		return
	var lookup:=_species_lookup()
	for species_id_value in ids:
		var species_id:=str(species_id_value)
		var entry:Dictionary=lookup.get(species_id,{})
		var button:=_button("%s\n%s\n［1株だけ確認］"%[str(entry.get("name_ja",species_id)),species_id],Vector2.ZERO,Vector2(240,82),Color("#f1ddb8"),13)
		button.pressed.connect(_preview_one.bind(species_id))
		species_grid.add_child(button)

func _on_series_selected(index:int)->void:
	selected_group_index=clampi(index,0,maxi(0,series_groups.size()-1))
	_refresh_species_grid()
	if not series_groups.is_empty():status_label.text="%sの品種を選択中"%str(series_groups[selected_group_index].get("display_name","シリーズ"))

func _preview_one(species_id:String)->void:
	var entry:Dictionary=_species_lookup().get(species_id,{})
	status_label.text="%sを1株プレビュー"%str(entry.get("name_ja",species_id))
	_show_workspace()
	preview_species_requested.emit(species_id)

func _preview_selected_series_batch()->void:
	if series_groups.is_empty():return
	_emit_group_batch(selected_group_index,false)

func _preview_next_series_batch()->void:
	if series_groups.is_empty():return
	for ignored in range(series_groups.size()):
		var index:=all_group_cursor%series_groups.size()
		all_group_cursor=(index+1)%series_groups.size()
		if not _group_ids(series_groups[index]).is_empty():
			selected_group_index=index
			series_picker.select(index)
			_refresh_species_grid()
			_emit_group_batch(index,true)
			return

func _emit_group_batch(group_index:int,from_all_series:bool)->void:
	var group:Dictionary=series_groups[group_index]
	var ids:=_group_ids(group)
	if ids.is_empty():return
	var series_id:=str(group.get("series_id",""))
	var offset:=int(group_batch_offsets.get(series_id,0))
	var end:=mini(offset+MAX_PLANTS_PER_BATCH,ids.size())
	var batch:Array=ids.slice(offset,end)
	group_batch_offsets[series_id]=0 if end>=ids.size() else end
	var series_name:=str(group.get("display_name",series_id))
	var range_text:="全%d種"%ids.size() if ids.size()<=MAX_PLANTS_PER_BATCH else "%d〜%d / %d種"%[offset+1,end,ids.size()]
	status_label.text="%s：%s%s"%[series_name,range_text,"（全シリーズ順送り）" if from_all_series else ""]
	_show_workspace()
	preview_batch_requested.emit(batch,series_name)

func _clear_preview()->void:
	set_session_active(false)
	clear_requested.emit()

func _show_workspace()->void:
	session_active=true
	overlay.visible=false
	launcher_button.visible=true
	close_requested.emit()

func _close_overlay()->void:
	overlay.visible=false
	launcher_button.visible=session_active
	close_requested.emit()

func _group_ids(group:Dictionary)->Array:
	var ids=group.get("species_ids",[])
	return ids if ids is Array else []

func _species_lookup()->Dictionary:
	var lookup:Dictionary={}
	for raw_species in catalog_species:
		if raw_species is Dictionary:lookup[str(raw_species.get("species_id",""))]=raw_species
	return lookup

func _add_empty_label(text_value:String)->void:
	var label:=Label.new()
	label.text=text_value
	label.custom_minimum_size=Vector2(490,120)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",16)
	label.add_theme_color_override("font_color",Color("#76513b"))
	species_grid.add_child(label)

func _button(text_value:String,position_value:Vector2,size_value:Vector2,bg:Color,font_size:int)->Button:
	var button:=Button.new()
	button.text=text_value
	button.position=position_value
	button.custom_minimum_size=size_value
	button.size=size_value
	button.add_theme_font_size_override("font_size",font_size)
	button.add_theme_color_override("font_color",UI_BROWN if bg.get_luminance()>.55 else Color.WHITE)
	button.add_theme_color_override("font_hover_color",UI_BROWN)
	button.add_theme_stylebox_override("normal",_box(bg,bg.lightened(.20),16,2))
	button.add_theme_stylebox_override("hover",_box(bg.lightened(.08),Color.WHITE,16,2))
	button.add_theme_stylebox_override("pressed",_box(bg.darkened(.08),bg.lightened(.18),16,2))
	return button

func _box(bg:Color,border:Color,radius:int,width:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=bg
	style.border_color=border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left=10
	style.content_margin_right=10
	style.content_margin_top=7
	style.content_margin_bottom=7
	return style

func _clear_children(parent:Node)->void:
	for child in parent.get_children():child.queue_free()
