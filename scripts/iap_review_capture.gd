class_name IAPReviewCapture
extends Node

const BuildProfileClass = preload("res://scripts/build_profile.gd")
const GameLocalizer = preload("res://scripts/game_localizer.gd")

const PRODUCT_ID := BuildProfileClass.IAP_REVIEW_CAPTURE_PRODUCT_ID
const POT_ID := "g1_crystal_goblet"
const EXPECTED_NAME_JA := "クリスタルゴブレット鉢"
const EXPECTED_IMAGE_PATH := "res://assets/arrangement/pots/pot-g1-001-crystal-goblet.png"
const EXPECTED_PUKU_PRICE := 2
const OUTPUT_DIRECTORY := "user://iap-review-capture"
const OUTPUT_FILENAME := "pot_unlock_001-app-review.png"
const MANIFEST_FILENAME := "pot_unlock_001-app-review.json"
const STOREKIT_TIMEOUT_MSEC := 30000

# App Store Connect accepts an IAP review screenshot at any screenshot size the
# iPhone app supports. Keep this list aligned with Apple's published portrait
# dimensions; an unexpected logical 576x1024 capture must fail closed.
const APPLE_IPHONE_PORTRAIT_SIZES: Array[Vector2i] = [
	Vector2i(1398,2034), # iPhone Duo outer display
	Vector2i(2007,2853), # iPhone Duo inner display
	Vector2i(1260,2736),
	Vector2i(1290,2796),
	Vector2i(1320,2868),
	Vector2i(1284,2778),
	Vector2i(1242,2688),
	Vector2i(1179,2556),
	Vector2i(1206,2622),
	Vector2i(1170,2532),
	Vector2i(1125,2436),
	Vector2i(1080,2340),
	Vector2i(1242,2208),
	Vector2i(750,1334),
	Vector2i(640,1096),
	Vector2i(640,1136),
	Vector2i(640,920),
	Vector2i(640,960),
]

var _main: Node
var _status_layer: CanvasLayer
var _status_label: Label
var _share_button: Button
var _output_path := ""


func begin(main_node:Node)->void:
	_main=main_node
	_build_status_ui()
	call_deferred("_run_capture")


func _run_capture()->void:
	if not BuildProfileClass.iap_review_capture_enabled():
		_fail("capture_feature_gate_closed")
		return
	if not OS.has_feature("ios"):
		_fail("ios_device_required")
		return
	if not Engine.has_singleton("SharePlugin"):
		_fail("share_plugin_unavailable")
		return
	var share_plugin=Engine.get_singleton("SharePlugin")
	if share_plugin==null or not share_plugin.has_method("share"):
		_fail("share_plugin_method_unavailable")
		return
	if _main==null or _main.arrangement_ui==null or _main.pot_unlock_iap_service==null:
		_fail("game_ui_or_storekit_unavailable")
		return

	_show_status("StoreKitから pot_unlock_001 の100円表示を取得しています…",false)
	var product_state:Dictionary=await _wait_for_storekit_product()
	if product_state.is_empty():return
	var localized_price:=str(product_state.get("localized_price",""))
	var price_diagnostic:=_storekit_price_diagnostic(product_state)
	print("IAP_REVIEW_CAPTURE_STOREKIT_PRICE product_id=",PRODUCT_ID," ",price_diagnostic)
	if not is_expected_jpy_100_price(product_state):
		_fail("unexpected_storekit_price",price_diagnostic)
		return

	var pot:Dictionary=_pot_entry()
	if not _validate_catalog_entry(pot):return
	var card:Control=await _prepare_real_pot_shop(product_state)
	if card==null:return
	var content_result:=_validate_card_content(card,product_state)
	if not bool(content_result.get("ok",false)):
		_fail(str(content_result.get("error","card_content_invalid")))
		return

	# The review build is intentionally view-only. Preserve the normal enabled
	# appearance while making an accidental tap unable to start a transaction.
	var buy_button:=card.find_child("PotBuyButton",true,false) as Button
	buy_button.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_status_layer.visible=false
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var image:=get_viewport().get_texture().get_image()
	if image==null or image.is_empty():
		_fail("viewport_capture_empty")
		return
	image.convert(Image.FORMAT_RGB8)
	var image_size:=Vector2i(image.get_width(),image.get_height())
	if not is_supported_apple_portrait_size(image_size):
		_fail("unsupported_capture_dimensions_%dx%d"%[image_size.x,image_size.y])
		return
	if image.get_format()!=Image.FORMAT_RGB8:
		_fail("capture_is_not_rgb8")
		return

	var output_directory_absolute:=ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	var mkdir_error:=DirAccess.make_dir_recursive_absolute(output_directory_absolute)
	if mkdir_error!=OK:
		_fail("capture_directory_create_failed")
		return
	_output_path=OUTPUT_DIRECTORY.path_join(OUTPUT_FILENAME)
	var save_error:=image.save_png(_output_path)
	if save_error!=OK:
		_fail("png_save_failed")
		return
	var png_bytes:=FileAccess.get_file_as_bytes(_output_path)
	if not _is_rgb_png_without_alpha(png_bytes,image_size):
		_fail("png_structure_or_alpha_invalid")
		return

	var digest:=_sha256_hex(png_bytes)
	var manifest:={
		"schema_version":1,
		"capture_mode":"iap_review_capture",
		"product_id":PRODUCT_ID,
		"pot_id":POT_ID,
		"locale":"ja",
		"pot_name":EXPECTED_NAME_JA,
		"iap_type":"NON_CONSUMABLE",
		"storekit_localized_price":localized_price,
		"storekit_currency_value":product_state.get("currency_value",null),
		"storekit_currency_code":str(product_state.get("currency_code","")),
		"storekit_currency_symbol":str(product_state.get("currency_symbol","")),
		"expected_japan_price_yen":100,
		"puku_price":EXPECTED_PUKU_PRICE,
		"width":image_size.x,
		"height":image_size.y,
		"format":"PNG",
		"pixel_format":"RGB8",
		"png_color_type":2,
		"has_alpha":false,
		"sha256":digest,
		"content_checks":content_result.get("checks",{}),
		"source":"live Godot iOS viewport",
		"captured_at_utc":Time.get_datetime_string_from_system(true,true),
	}
	var manifest_path:=OUTPUT_DIRECTORY.path_join(MANIFEST_FILENAME)
	var manifest_file:=FileAccess.open(manifest_path,FileAccess.WRITE)
	if manifest_file==null:
		_fail("manifest_write_failed")
		return
	manifest_file.store_string(JSON.stringify(manifest,"\t",false)+"\n")
	manifest_file.close()

	_show_status("撮影・検証が完了しました。共有シートから「ファイルに保存」を選んでください。\n%d × %d / PNG / RGB / アルファなし"%[image_size.x,image_size.y],true)
	print("IAP_REVIEW_CAPTURE_OK product_id=",PRODUCT_ID," size=",image_size.x,"x",image_size.y," format=PNG pixel_format=RGB8 alpha=false")
	_share_png()


func _wait_for_storekit_product()->Dictionary:
	var deadline:=Time.get_ticks_msec()+STOREKIT_TIMEOUT_MSEC
	while Time.get_ticks_msec()<deadline:
		var states:Dictionary=_main.pot_unlock_iap_service.product_states_snapshot()
		var state_value=states.get(PRODUCT_ID,{})
		if state_value is Dictionary:
			var state:Dictionary=state_value
			var status:=str(state.get("status","loading"))
			var localized_price:=str(state.get("localized_price","")).strip_edges()
			if status=="available" and not localized_price.is_empty():return state.duplicate(true)
			if status=="unavailable":
				_fail("storekit_product_unavailable")
				return {}
		await get_tree().create_timer(.1).timeout
	var diagnostic:Dictionary={}
	if _main.pot_unlock_iap_service.has_method("diagnostic_snapshot"):
		diagnostic=_main.pot_unlock_iap_service.diagnostic_snapshot()
	print(
		"IAP_REVIEW_CAPTURE_STOREKIT_TIMEOUT mode=",str(diagnostic.get("request_mode","unknown")),
		" bridge=",bool(diagnostic.get("bridge_available",false)),
		" method=",bool(diagnostic.get("request_method_available",false)),
		" signal=",bool(diagnostic.get("response_signal_available",false)),
		" dispatched=",int(diagnostic.get("requests_dispatched",0)),
		" responses=",int(diagnostic.get("responses_received",0))
	)
	if int(diagnostic.get("requests_dispatched",0))<=0:
		_fail("storekit_request_not_dispatched")
	elif int(diagnostic.get("responses_received",0))<=0:
		_fail("storekit_price_response_timeout")
	else:
		_fail("storekit_product_timeout")
	return {}


func _pot_entry()->Dictionary:
	for value in _main.pot_catalog:
		if value is Dictionary and str(value.get("iap_product_id",""))==PRODUCT_ID:
			return (value as Dictionary).duplicate(true)
	return {}


func _validate_catalog_entry(pot:Dictionary)->bool:
	if pot.is_empty():
		_fail("catalog_product_missing")
		return false
	if str(pot.get("pot_id",""))!=POT_ID:
		_fail("catalog_pot_id_mismatch")
		return false
	if str(pot.get("unlock_type",""))!="iap_unlock":
		_fail("catalog_unlock_type_mismatch")
		return false
	if int(pot.get("price_puku",-1))!=EXPECTED_PUKU_PRICE:
		_fail("catalog_puku_price_mismatch")
		return false
	if str(pot.get("image_path",""))!=EXPECTED_IMAGE_PATH or not ResourceLoader.exists(EXPECTED_IMAGE_PATH):
		_fail("catalog_pot_image_mismatch")
		return false
	if GameLocalizer.pot_name("ja",pot)!=EXPECTED_NAME_JA:
		_fail("catalog_japanese_name_mismatch")
		return false
	return true


func _prepare_real_pot_shop(product_state:Dictionary)->Control:
	var ui:Control=_main.arrangement_ui as Control
	ui.move_to_front()
	ui.set("language_code","ja")
	ui.set("pot_sales_stage",2)
	ui.set("pot_design_unlocks",{})
	var states:Dictionary=_main.pot_unlock_iap_service.product_states_snapshot()
	states[PRODUCT_ID]=product_state.duplicate(true)
	ui.set("pot_iap_products",states)
	ui.call("open_pot_shop")
	ui.call("show_pot_shop_message","")
	await get_tree().process_frame
	await get_tree().process_frame

	var card:Control=ui.call("_pot_shop_card_node",POT_ID) as Control
	if card==null:
		_fail("pot_card_missing")
		return null
	var scroll:=_ancestor_scroll_container(card)
	if scroll==null:
		_fail("pot_scroll_container_missing")
		return null
	scroll.ensure_control_visible(card)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var card_rect:=card.get_global_rect()
	var scroll_rect:=scroll.get_global_rect()
	var visible_rect:=card_rect.intersection(scroll_rect)
	if visible_rect.size.x+1.0<card_rect.size.x or visible_rect.size.y+1.0<card_rect.size.y:
		_fail("pot_card_not_fully_visible")
		return null
	return card


func _validate_card_content(card:Control,product_state:Dictionary)->Dictionary:
	var localized_price:=str(product_state.get("localized_price",""))
	var expected_unlock:=GameLocalizer.text("ja","pot_permanent_unlock")
	var expected_puku:=GameLocalizer.text("ja","pot_locked_puku_price",[EXPECTED_PUKU_PRICE])
	var expected_button:=GameLocalizer.text("ja","iap_unlock_for_price",[localized_price])
	var owned_label:=card.find_child("PotOwnedTotal",true,false) as Label
	var puku_label:=card.find_child("PotLockedPukuPrice",true,false) as Label
	var buy_button:=card.find_child("PotBuyButton",true,false) as Button
	var name_visible:=false
	var image_visible:=false
	for label_value in card.find_children("*","Label",true,false):
		if label_value is Label and (label_value as Label).text==EXPECTED_NAME_JA and (label_value as Label).is_visible_in_tree():
			name_visible=true
	for texture_value in card.find_children("*","TextureRect",true,false):
		if not texture_value is TextureRect:continue
		var texture_rect:=texture_value as TextureRect
		if texture_rect.texture!=null and texture_rect.texture.resource_path==EXPECTED_IMAGE_PATH and texture_rect.is_visible_in_tree():
			image_visible=true
	var checks:={
		"card_fully_visible":card.is_visible_in_tree(),
		"pot_image_visible":image_visible,
		"japanese_name_visible":name_visible,
		"permanent_unlock_visible":owned_label!=null and owned_label.is_visible_in_tree() and owned_label.text==expected_unlock,
		"puku_price_visible":puku_label!=null and puku_label.is_visible_in_tree() and puku_label.text==expected_puku,
		"storekit_button_visible":buy_button!=null and buy_button.is_visible_in_tree() and not buy_button.disabled and buy_button.text==expected_button,
		"storekit_price_is_jpy_100":is_expected_jpy_100_price(product_state),
	}
	for key in checks:
		if not bool(checks[key]):return {"ok":false,"error":"card_check_failed_%s"%str(key),"checks":checks}
	return {"ok":true,"checks":checks}


func _ancestor_scroll_container(control:Control)->ScrollContainer:
	var current:Node=control.get_parent()
	while current!=null:
		if current is ScrollContainer:return current as ScrollContainer
		current=current.get_parent()
	return null


static func is_expected_jpy_100_price(product_state:Dictionary)->bool:
	if str(product_state.get("currency_code","")).strip_edges().to_upper()!="JPY":return false
	if not product_state.has("currency_value") or product_state.get("currency_value")==null:return false
	var numeric_text:=str(product_state.get("currency_value")).strip_edges()
	if not numeric_text.is_valid_float():return false
	return absf(float(numeric_text)-100.0)<=0.0001


static func _storekit_price_diagnostic(product_state:Dictionary)->String:
	var currency_code:=str(product_state.get("currency_code","<missing>")).strip_edges().to_upper()
	if currency_code.is_empty():currency_code="<missing>"
	var currency_value:="<missing>" if not product_state.has("currency_value") or product_state.get("currency_value")==null else str(product_state.get("currency_value"))
	var localized_price:=str(product_state.get("localized_price",""))
	return "currency_code=%s currency_value=%s localized_price=%s"%[currency_code,currency_value,JSON.stringify(localized_price)]


static func is_supported_apple_portrait_size(size:Vector2i)->bool:
	return size in APPLE_IPHONE_PORTRAIT_SIZES


static func _is_rgb_png_without_alpha(bytes:PackedByteArray,expected_size:Vector2i)->bool:
	if bytes.size()<33:return false
	var signature:=PackedByteArray([137,80,78,71,13,10,26,10])
	if bytes.slice(0,8)!=signature:return false
	if bytes.slice(12,16).get_string_from_ascii()!="IHDR":return false
	var width:=(int(bytes[16])<<24)|(int(bytes[17])<<16)|(int(bytes[18])<<8)|int(bytes[19])
	var height:=(int(bytes[20])<<24)|(int(bytes[21])<<16)|(int(bytes[22])<<8)|int(bytes[23])
	var bit_depth:=int(bytes[24])
	var color_type:=int(bytes[25])
	return width==expected_size.x and height==expected_size.y and bit_depth==8 and color_type==2


func _sha256_hex(bytes:PackedByteArray)->String:
	var hashing:=HashingContext.new()
	if hashing.start(HashingContext.HASH_SHA256)!=OK:return ""
	hashing.update(bytes)
	return hashing.finish().hex_encode()


func _build_status_ui()->void:
	_status_layer=CanvasLayer.new()
	_status_layer.name="IAPReviewCaptureStatusLayer"
	_status_layer.layer=1000
	add_child(_status_layer)
	var root:=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_STOP
	_status_layer.add_child(root)
	var shade:=ColorRect.new()
	shade.color=Color(0.08,0.05,0.03,.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter=Control.MOUSE_FILTER_STOP
	root.add_child(shade)
	var panel:=PanelContainer.new()
	panel.position=Vector2(48,330)
	panel.size=Vector2(480,360)
	root.add_child(panel)
	var column:=VBoxContainer.new()
	column.alignment=BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation",18)
	panel.add_child(column)
	var title:=Label.new()
	title.text="IAP審査画像 撮影専用ビルド"
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",22)
	column.add_child(title)
	_status_label=Label.new()
	_status_label.custom_minimum_size=Vector2(430,170)
	_status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size",17)
	column.add_child(_status_label)
	_share_button=Button.new()
	_share_button.text="PNGを共有"
	_share_button.custom_minimum_size=Vector2(280,58)
	_share_button.visible=false
	_share_button.pressed.connect(_share_png)
	column.add_child(_share_button)


func _show_status(message:String,can_share:bool)->void:
	if _status_layer==null:return
	_status_layer.visible=true
	_status_label.text=message
	_share_button.visible=can_share


func _share_png()->void:
	if _output_path.is_empty() or not FileAccess.file_exists(_output_path):
		_fail("capture_file_missing")
		return
	_main.call("_open_native_share_or_fallback",_output_path,OUTPUT_FILENAME,"iap_review_capture")


func _fail(reason:String,diagnostic:String="")->void:
	var message:="撮影を停止しました。\n理由コード: %s"%reason
	if not diagnostic.is_empty():message+="\n診断: %s"%diagnostic
	message+="\n商品作成・購入・送信は行っていません。"
	_show_status(message,false)
	push_error("IAP_REVIEW_CAPTURE_FAILED product_id=%s reason=%s%s"%[PRODUCT_ID,reason," diagnostic="+diagnostic if not diagnostic.is_empty() else ""])
