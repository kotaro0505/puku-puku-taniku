class_name IAPReviewCapture
extends Node

const BuildProfileClass = preload("res://scripts/build_profile.gd")
const GameLocalizer = preload("res://scripts/game_localizer.gd")

const PRODUCT_COUNT := BuildProfileClass.IAP_REVIEW_CAPTURE_PRODUCT_COUNT
const OUTPUT_DIRECTORY := "user://iap-review-capture"
const BATCH_MANIFEST_FILENAME := "iap-review-capture-manifest.json"
const BUNDLE_FILENAME := "puku-iap-review-captures.zip"
const STOREKIT_TIMEOUT_MSEC := 60000

# App Store Connect accepts an IAP review screenshot at any screenshot size the
# iPhone app supports. Keep this list aligned with Apple's published portrait
# dimensions. The 9:16 Godot viewport can be shorter than a modern iPhone's
# native screen, so capture-only code composes it over the real black letterbox
# area without resizing either axis.
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
var _status_visual: Control
var _status_label: Label
var _share_button: Button
var _output_path := ""
var _active_product_id := ""


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

	var catalog_result:=_capture_catalog_entries()
	if not bool(catalog_result.get("ok",false)):
		_fail(str(catalog_result.get("error","capture_catalog_invalid")))
		return
	var entries:Array=catalog_result.get("entries",[])
	var product_ids:=BuildProfileClass.iap_review_capture_product_ids()
	_show_status("StoreKitから36商品の実価格を取得しています… 0 / %d"%PRODUCT_COUNT,false)
	var states:Dictionary=await _wait_for_storekit_products(product_ids)
	if states.is_empty():return

	var price_context:=validate_storekit_price_batch(product_ids,states)
	if not bool(price_context.get("ok",false)):
		_fail(str(price_context.get("error","storekit_price_context_invalid")),str(price_context.get("diagnostic","")))
		return
	print(
		"IAP_REVIEW_CAPTURE_PRICE_CONTEXT products=",PRODUCT_COUNT,
		" storefront_country_code=",str(price_context.get("storefront_country_code","")),
		" currency_code=",str(price_context.get("currency_code",""))
	)

	if not await _prepare_real_pot_shop(states):return
	var output_directory_absolute:=ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	if DirAccess.make_dir_recursive_absolute(output_directory_absolute)!=OK:
		_fail("capture_directory_create_failed")
		return

	var captures:Array=[]
	var image_size:=Vector2i.ZERO
	var viewport_content_size:=Vector2i.ZERO
	for index in entries.size():
		var pot:Dictionary=entries[index]
		_active_product_id=str(pot.get("iap_product_id",""))
		_show_status("審査画像を撮影・検証しています… %d / %d"%[index,PRODUCT_COUNT],false)
		var product_state:Dictionary=states.get(_active_product_id,{})
		print("IAP_REVIEW_CAPTURE_STOREKIT_PRICE product_id=",_active_product_id," ",_storekit_price_diagnostic(product_state))
		var capture_result:Dictionary=await _capture_product(pot,product_state)
		if not bool(capture_result.get("ok",false)):
			_fail(str(capture_result.get("error","product_capture_failed")),str(capture_result.get("diagnostic","")))
			return
		var current_size:Vector2i=capture_result.get("image_size",Vector2i.ZERO)
		var current_content_size:Vector2i=capture_result.get("viewport_content_size",Vector2i.ZERO)
		if image_size==Vector2i.ZERO:image_size=current_size
		elif current_size!=image_size:
			_fail("capture_dimensions_changed_between_products")
			return
		if viewport_content_size==Vector2i.ZERO:viewport_content_size=current_content_size
		elif current_content_size!=viewport_content_size:
			_fail("capture_viewport_dimensions_changed_between_products")
			return
		captures.append(capture_result.get("manifest",{}))

	if captures.size()!=PRODUCT_COUNT:
		_fail("capture_count_mismatch")
		return
	var manifest_path:=OUTPUT_DIRECTORY.path_join(BATCH_MANIFEST_FILENAME)
	var batch_manifest:={
		"schema_version":2,
		"capture_mode":"iap_review_capture_batch",
		"product_count":PRODUCT_COUNT,
		"expected_product_ids":product_ids,
		"storefront_country_code":str(price_context.get("storefront_country_code","")),
		"currency_code":str(price_context.get("currency_code","")),
		"width":image_size.x,
		"height":image_size.y,
		"viewport_content_width":viewport_content_size.x,
		"viewport_content_height":viewport_content_size.y,
		"capture_composition":"native_screen_with_unscaled_viewport_and_black_letterbox",
		"content_scaled":false,
		"format":"PNG",
		"pixel_format":"RGB8",
		"png_color_type":2,
		"has_alpha":false,
		"captures":captures,
		"source":"live Godot iOS viewport centered unscaled on the native iOS screen",
		"completed_at_utc":Time.get_datetime_string_from_system(true,true),
	}
	if not _write_json_file(manifest_path,batch_manifest):
		_fail("batch_manifest_write_failed")
		return

	_output_path=OUTPUT_DIRECTORY.path_join(BUNDLE_FILENAME)
	var bundle_result:=_create_and_validate_bundle(_output_path,manifest_path,captures,image_size)
	if not bool(bundle_result.get("ok",false)):
		_fail(str(bundle_result.get("error","capture_bundle_invalid")))
		return

	_active_product_id=""
	_show_status(
		"36商品の撮影・検証が完了しました。\n共有シートからZIPを「ファイルに保存」してください。\n%d × %d / PNG / RGB / アルファなし"%[image_size.x,image_size.y],
		true
	)
	print(
		"IAP_REVIEW_CAPTURE_BATCH_OK products=",captures.size(),
		" size=",image_size.x,"x",image_size.y,
		" format=PNG pixel_format=RGB8 alpha=false bundle=",BUNDLE_FILENAME
	)
	_share_bundle()


func _capture_catalog_entries()->Dictionary:
	var by_product_id:Dictionary={}
	var pot_ids:Dictionary={}
	for pot_value in _main.pot_catalog:
		if not pot_value is Dictionary:continue
		var pot:Dictionary=pot_value
		if str(pot.get("unlock_type","free"))!="iap_unlock":continue
		var product_id:=str(pot.get("iap_product_id","")).strip_edges()
		var pot_id:=str(pot.get("pot_id","")).strip_edges()
		if product_id.is_empty():return {"ok":false,"error":"catalog_product_id_missing"}
		if pot_id.is_empty():return {"ok":false,"error":"catalog_pot_id_missing_%s"%product_id}
		if by_product_id.has(product_id):return {"ok":false,"error":"catalog_product_duplicate_%s"%product_id}
		if pot_ids.has(pot_id):return {"ok":false,"error":"catalog_pot_duplicate_%s"%pot_id}
		var image_path:=str(pot.get("image_path","")).strip_edges()
		if not image_path.ends_with(".png") or not ResourceLoader.exists(image_path):
			return {"ok":false,"error":"catalog_image_missing_%s"%product_id}
		if GameLocalizer.pot_name("ja",pot).strip_edges().is_empty():
			return {"ok":false,"error":"catalog_name_missing_%s"%product_id}
		if not pot.has("price_puku") or int(pot.get("price_puku",-1))<0:
			return {"ok":false,"error":"catalog_puku_price_invalid_%s"%product_id}
		by_product_id[product_id]=pot.duplicate(true)
		pot_ids[pot_id]=true
	var entries:Array=[]
	var expected_ids:=BuildProfileClass.iap_review_capture_product_ids()
	if by_product_id.size()!=expected_ids.size():return {"ok":false,"error":"catalog_product_count_mismatch"}
	for expected_id in expected_ids:
		if not by_product_id.has(expected_id):return {"ok":false,"error":"catalog_product_missing_%s"%expected_id}
		entries.append(by_product_id[expected_id])
	return {"ok":true,"entries":entries}


func _wait_for_storekit_products(product_ids:Array[String])->Dictionary:
	var deadline:=Time.get_ticks_msec()+STOREKIT_TIMEOUT_MSEC
	var last_available_count:=-1
	while Time.get_ticks_msec()<deadline:
		var states:Dictionary=_main.pot_unlock_iap_service.product_states_snapshot()
		var available_count:=0
		for product_id in product_ids:
			var state_value=states.get(product_id,{})
			if not state_value is Dictionary:continue
			var state:Dictionary=state_value
			var status:=str(state.get("status","loading"))
			if status=="unavailable":
				_active_product_id=product_id
				_fail("storekit_product_unavailable",str(state.get("error","")))
				return {}
			if status=="available" and not str(state.get("localized_price","")).strip_edges().is_empty():available_count+=1
		if available_count!=last_available_count:
			last_available_count=available_count
			_show_status("StoreKitから36商品の実価格を取得しています… %d / %d"%[available_count,product_ids.size()],false)
		if available_count==product_ids.size():return states
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
		" responses=",int(diagnostic.get("responses_received",0)),
		" expected=",product_ids.size()
	)
	if int(diagnostic.get("requests_dispatched",0))!=product_ids.size():
		_fail("storekit_request_count_mismatch")
	elif int(diagnostic.get("responses_received",0))<=0:
		_fail("storekit_price_response_timeout")
	else:
		_fail("storekit_product_batch_timeout")
	return {}


static func validate_storekit_price_tuple(product_state:Dictionary,expected_storefront:String="",expected_currency:String="")->Dictionary:
	var localized_price:=str(product_state.get("localized_price","")).strip_edges()
	if localized_price.is_empty():return {"ok":false,"error":"localized_price_missing"}
	var currency_value=product_state.get("currency_value",null)
	if typeof(currency_value) not in [TYPE_INT,TYPE_FLOAT]:return {"ok":false,"error":"currency_value_not_numeric"}
	var numeric_value:=float(currency_value)
	if not is_finite(numeric_value) or numeric_value<=0.0:return {"ok":false,"error":"currency_value_invalid"}
	var currency_code:=str(product_state.get("currency_code","")).strip_edges().to_upper()
	if not _is_ascii_alpha3(currency_code):return {"ok":false,"error":"currency_code_invalid"}
	var storefront_country_code:=str(product_state.get("storefront_country_code","")).strip_edges().to_upper()
	if not _is_ascii_alpha3(storefront_country_code):return {"ok":false,"error":"storefront_country_code_invalid"}
	if storefront_country_code=="USA" and currency_code!="USD":return {"ok":false,"error":"usa_storefront_currency_mismatch"}
	if storefront_country_code=="JPN" and currency_code!="JPY":return {"ok":false,"error":"japan_storefront_currency_mismatch"}
	if not expected_storefront.is_empty() and storefront_country_code!=expected_storefront:
		return {"ok":false,"error":"storefront_changed_during_batch"}
	if not expected_currency.is_empty() and currency_code!=expected_currency:
		return {"ok":false,"error":"currency_changed_during_batch"}
	return {
		"ok":true,
		"storefront_country_code":storefront_country_code,
		"currency_code":currency_code,
		"currency_value":numeric_value,
		"localized_price":localized_price,
	}


static func validate_storekit_price_batch(product_ids:Array[String],states:Dictionary)->Dictionary:
	var expected_storefront:=""
	var expected_currency:=""
	for product_id in product_ids:
		var state_value=states.get(product_id,{})
		if not state_value is Dictionary:
			return {"ok":false,"error":"product_state_missing_%s"%product_id}
		var validation:=validate_storekit_price_tuple(state_value,expected_storefront,expected_currency)
		if not bool(validation.get("ok",false)):
			return {
				"ok":false,
				"error":"%s_%s"%[str(validation.get("error","price_invalid")),product_id],
				"diagnostic":_storekit_price_diagnostic(state_value),
			}
		if expected_storefront.is_empty():
			expected_storefront=str(validation.get("storefront_country_code",""))
			expected_currency=str(validation.get("currency_code",""))
	return {"ok":true,"storefront_country_code":expected_storefront,"currency_code":expected_currency}


static func _is_ascii_alpha3(value:String)->bool:
	if value.length()!=3:return false
	for character_index in 3:
		var code:=value.unicode_at(character_index)
		if code<65 or code>90:return false
	return true


func _prepare_real_pot_shop(states:Dictionary)->bool:
	var ui:Control=_main.arrangement_ui as Control
	ui.move_to_front()
	ui.set("language_code","ja")
	ui.set("pot_sales_stage",2)
	ui.set("pot_design_unlocks",{})
	ui.set("pot_iap_products",states.duplicate(true))
	ui.call("open_pot_shop")
	ui.call("show_pot_shop_message","")
	await get_tree().process_frame
	await get_tree().process_frame
	for product_id in BuildProfileClass.iap_review_capture_product_ids():
		var pot:=_pot_entry(product_id)
		if pot.is_empty():
			_active_product_id=product_id
			_fail("pot_catalog_entry_missing")
			return false
		var card:Control=ui.call("_pot_shop_card_node",str(pot.get("pot_id",""))) as Control
		if card==null:
			_active_product_id=product_id
			_fail("pot_card_missing")
			return false
		var buy_button:=card.find_child("PotBuyButton",true,false) as Button
		if buy_button==null:
			_active_product_id=product_id
			_fail("pot_buy_button_missing")
			return false
		# Keep the normal enabled appearance and StoreKit display price while making
		# every transaction entry point inert for the entire batch capture.
		buy_button.mouse_filter=Control.MOUSE_FILTER_IGNORE
		buy_button.focus_mode=Control.FOCUS_NONE
	return true


func _capture_product(pot:Dictionary,product_state:Dictionary)->Dictionary:
	var pot_id:=str(pot.get("pot_id",""))
	var card:Control=_main.arrangement_ui.call("_pot_shop_card_node",pot_id) as Control
	if card==null:return {"ok":false,"error":"pot_card_missing"}
	var scroll:=_ancestor_scroll_container(card)
	if scroll==null:return {"ok":false,"error":"pot_scroll_container_missing"}
	var target_scroll:=roundi(card.position.y+card.size.y*.5-scroll.size.y*.5)
	scroll.scroll_vertical=maxi(0,target_scroll)
	await get_tree().process_frame
	scroll.ensure_control_visible(card)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var card_rect:=card.get_global_rect()
	var scroll_rect:=scroll.get_global_rect()
	var visible_rect:=card_rect.intersection(scroll_rect)
	if visible_rect.size.x+1.0<card_rect.size.x or visible_rect.size.y+1.0<card_rect.size.y:
		return {"ok":false,"error":"pot_card_not_fully_visible"}
	var content_result:=_validate_card_content(card,pot,product_state)
	if not bool(content_result.get("ok",false)):
		return {"ok":false,"error":str(content_result.get("error","card_content_invalid"))}

	_status_visual.visible=false
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var viewport_image:=get_viewport().get_texture().get_image()
	if viewport_image==null or viewport_image.is_empty():return {"ok":false,"error":"viewport_capture_empty"}
	viewport_image.convert(Image.FORMAT_RGB8)
	var viewport_content_size:=Vector2i(viewport_image.get_width(),viewport_image.get_height())
	var native_screen_size:=DisplayServer.screen_get_size(DisplayServer.SCREEN_OF_MAIN_WINDOW)
	var native_window_size:=DisplayServer.window_get_size(DisplayServer.MAIN_WINDOW_ID)
	if native_screen_size!=native_window_size:
		return {
			"ok":false,
			"error":"native_screen_window_dimensions_mismatch",
			"diagnostic":"screen=%dx%d window=%dx%d"%[native_screen_size.x,native_screen_size.y,native_window_size.x,native_window_size.y],
		}
	var composition:=compose_native_screen_capture(viewport_image,native_screen_size)
	if not bool(composition.get("ok",false)):
		return {
			"ok":false,
			"error":str(composition.get("error","native_screen_capture_composition_failed")),
			"diagnostic":"viewport=%dx%d screen=%dx%d"%[viewport_content_size.x,viewport_content_size.y,native_screen_size.x,native_screen_size.y],
		}
	var image:Image=composition.get("image") as Image
	var image_size:=Vector2i(image.get_width(),image.get_height())
	var viewport_offset:Vector2i=composition.get("viewport_offset",Vector2i.ZERO)
	var letterbox_top:=int(composition.get("letterbox_top",0))
	var letterbox_bottom:=int(composition.get("letterbox_bottom",0))
	if image.get_format()!=Image.FORMAT_RGB8:return {"ok":false,"error":"capture_is_not_rgb8"}

	var product_id:=str(pot.get("iap_product_id",""))
	var filename:="%s-app-review.png"%product_id
	var output_path:=OUTPUT_DIRECTORY.path_join(filename)
	if image.save_png(output_path)!=OK:return {"ok":false,"error":"png_save_failed"}
	var png_bytes:=FileAccess.get_file_as_bytes(output_path)
	if not _is_rgb_png_without_alpha(png_bytes,image_size):return {"ok":false,"error":"png_structure_or_alpha_invalid"}
	var saved_image:=Image.new()
	if saved_image.load_png_from_buffer(png_bytes)!=OK:return {"ok":false,"error":"png_reload_failed"}
	if not _has_black_letterbox(saved_image,viewport_offset,viewport_content_size):
		return {"ok":false,"error":"png_letterbox_validation_failed"}
	var digest:=_sha256_hex(png_bytes)
	if digest.is_empty():return {"ok":false,"error":"png_sha256_failed"}
	_status_visual.visible=true
	var manifest:={
		"product_id":product_id,
		"pot_id":pot_id,
		"pot_name":GameLocalizer.pot_name("ja",pot),
		"catalog_image_path":str(pot.get("image_path","")),
		"iap_type":"NON_CONSUMABLE",
		"storekit_localized_price":str(product_state.get("localized_price","")),
		"storekit_currency_value":product_state.get("currency_value",null),
		"storekit_currency_code":str(product_state.get("currency_code","")),
		"storekit_currency_symbol":str(product_state.get("currency_symbol","")),
		"storefront_country_code":str(product_state.get("storefront_country_code","")),
		"puku_price":int(pot.get("price_puku",-1)),
		"filename":filename,
		"width":image_size.x,
		"height":image_size.y,
		"viewport_content_width":viewport_content_size.x,
		"viewport_content_height":viewport_content_size.y,
		"viewport_offset_x":viewport_offset.x,
		"viewport_offset_y":viewport_offset.y,
		"letterbox_top":letterbox_top,
		"letterbox_bottom":letterbox_bottom,
		"capture_composition":"native_screen_with_unscaled_viewport_and_black_letterbox",
		"content_scaled":false,
		"format":"PNG",
		"pixel_format":"RGB8",
		"png_color_type":2,
		"has_alpha":false,
		"sha256":digest,
		"content_checks":content_result.get("checks",{}),
		"captured_at_utc":Time.get_datetime_string_from_system(true,true),
	}
	print(
		"IAP_REVIEW_CAPTURE_PRODUCT_OK product_id=",product_id,
		" filename=",filename,
		" size=",image_size.x,"x",image_size.y,
		" viewport=",viewport_content_size.x,"x",viewport_content_size.y,
		" offset=",viewport_offset.x,",",viewport_offset.y,
		" content_scaled=false"
	)
	return {
		"ok":true,
		"image_size":image_size,
		"viewport_content_size":viewport_content_size,
		"manifest":manifest,
	}


func _pot_entry(product_id:String)->Dictionary:
	for value in _main.pot_catalog:
		if value is Dictionary and str(value.get("iap_product_id",""))==product_id:
			return (value as Dictionary).duplicate(true)
	return {}


func _validate_card_content(card:Control,pot:Dictionary,product_state:Dictionary)->Dictionary:
	var localized_price:=str(product_state.get("localized_price",""))
	var puku_price:=int(pot.get("price_puku",-1))
	var expected_name:=GameLocalizer.pot_name("ja",pot)
	var expected_image_path:=str(pot.get("image_path",""))
	var expected_unlock:=GameLocalizer.text("ja","pot_permanent_unlock")
	var expected_puku:=GameLocalizer.text("ja","pot_locked_puku_price",[puku_price])
	var expected_button:=GameLocalizer.text("ja","iap_unlock_for_price",[localized_price])
	var owned_label:=card.find_child("PotOwnedTotal",true,false) as Label
	var puku_label:=card.find_child("PotLockedPukuPrice",true,false) as Label
	var buy_button:=card.find_child("PotBuyButton",true,false) as Button
	var name_label:Label=null
	var image_rect:TextureRect=null
	for label_value in card.find_children("*","Label",true,false):
		if label_value is Label and (label_value as Label).text==expected_name and (label_value as Label).is_visible_in_tree():
			name_label=label_value as Label
	for texture_value in card.find_children("*","TextureRect",true,false):
		if not texture_value is TextureRect:continue
		var texture_rect:=texture_value as TextureRect
		if texture_rect.texture!=null and texture_rect.texture.resource_path==expected_image_path and texture_rect.is_visible_in_tree():
			image_rect=texture_rect
	var name_fully_inside:=name_label!=null and _rect_fully_inside(name_label.get_global_rect(),card.get_global_rect())
	var image_fully_inside:=image_rect!=null and _rect_fully_inside(image_rect.get_global_rect(),card.get_global_rect())
	var checks:={
		"product_id_matches_card":str(card.get_meta("pot_id",""))==str(pot.get("pot_id","")),
		"card_fully_visible":card.is_visible_in_tree(),
		"pot_image_visible":image_rect!=null,
		"pot_image_fully_inside":image_fully_inside,
		"japanese_name_visible":name_label!=null,
		"japanese_name_fully_inside":name_fully_inside,
		"permanent_unlock_visible":owned_label!=null and owned_label.is_visible_in_tree() and owned_label.text==expected_unlock,
		"puku_price_visible":puku_label!=null and puku_label.is_visible_in_tree() and puku_label.text==expected_puku,
		"storekit_button_visible":buy_button!=null and buy_button.is_visible_in_tree() and not buy_button.disabled and buy_button.text==expected_button,
		"storekit_price_valid":bool(validate_storekit_price_tuple(product_state).get("ok",false)),
	}
	for key in checks:
		if not bool(checks[key]):return {"ok":false,"error":"card_check_failed_%s"%str(key),"checks":checks}
	return {"ok":true,"checks":checks}


static func _rect_fully_inside(inner:Rect2,outer:Rect2)->bool:
	var intersection:=inner.intersection(outer)
	return intersection.size.x+1.0>=inner.size.x and intersection.size.y+1.0>=inner.size.y


func _ancestor_scroll_container(control:Control)->ScrollContainer:
	var current:Node=control.get_parent()
	while current!=null:
		if current is ScrollContainer:return current as ScrollContainer
		current=current.get_parent()
	return null


static func _storekit_price_diagnostic(product_state:Dictionary)->String:
	var currency_code:=str(product_state.get("currency_code","<missing>")).strip_edges().to_upper()
	if currency_code.is_empty():currency_code="<missing>"
	var currency_value:="<missing>" if not product_state.has("currency_value") or product_state.get("currency_value")==null else str(product_state.get("currency_value"))
	var storefront_country_code:=str(product_state.get("storefront_country_code","<missing>")).strip_edges().to_upper()
	if storefront_country_code.is_empty():storefront_country_code="<missing>"
	var localized_price:=str(product_state.get("localized_price",""))
	return "currency_code=%s currency_value=%s storefront_country_code=%s localized_price=%s"%[currency_code,currency_value,storefront_country_code,JSON.stringify(localized_price)]


static func is_supported_apple_portrait_size(size:Vector2i)->bool:
	return size in APPLE_IPHONE_PORTRAIT_SIZES


static func compose_native_screen_capture(viewport_image:Image,native_screen_size:Vector2i)->Dictionary:
	if viewport_image==null or viewport_image.is_empty():return {"ok":false,"error":"viewport_capture_empty"}
	if viewport_image.get_format()!=Image.FORMAT_RGB8:return {"ok":false,"error":"viewport_capture_is_not_rgb8"}
	if not is_supported_apple_portrait_size(native_screen_size):
		return {"ok":false,"error":"unsupported_native_capture_dimensions_%dx%d"%[native_screen_size.x,native_screen_size.y]}
	var content_size:=Vector2i(viewport_image.get_width(),viewport_image.get_height())
	# The app's keep-aspect presentation fills the physical width on portrait
	# iPhone screens. Reject any other geometry instead of cropping or scaling.
	if content_size.x!=native_screen_size.x:
		return {"ok":false,"error":"viewport_native_width_mismatch_%d_%d"%[content_size.x,native_screen_size.x]}
	if content_size.y>native_screen_size.y:
		return {"ok":false,"error":"viewport_exceeds_native_screen_height_%d_%d"%[content_size.y,native_screen_size.y]}
	var remaining_height:=native_screen_size.y-content_size.y
	var viewport_offset:=Vector2i(0,floori(remaining_height*.5))
	var letterbox_bottom:=remaining_height-viewport_offset.y
	var full_screen_image:=Image.create(native_screen_size.x,native_screen_size.y,false,Image.FORMAT_RGB8)
	if full_screen_image==null or full_screen_image.is_empty():
		return {"ok":false,"error":"native_screen_image_create_failed"}
	full_screen_image.fill(Color.BLACK)
	full_screen_image.blit_rect(viewport_image,Rect2i(Vector2i.ZERO,content_size),viewport_offset)
	return {
		"ok":true,
		"image":full_screen_image,
		"image_size":native_screen_size,
		"viewport_content_size":content_size,
		"viewport_offset":viewport_offset,
		"letterbox_top":viewport_offset.y,
		"letterbox_bottom":letterbox_bottom,
		"content_scaled":false,
	}


static func _has_black_letterbox(image:Image,viewport_offset:Vector2i,content_size:Vector2i)->bool:
	if image==null or image.is_empty():return false
	var image_size:=Vector2i(image.get_width(),image.get_height())
	if viewport_offset.x<0 or viewport_offset.y<0:return false
	if viewport_offset.x+content_size.x>image_size.x or viewport_offset.y+content_size.y>image_size.y:return false
	var top_height:=viewport_offset.y
	var bottom_start:=viewport_offset.y+content_size.y
	var probe_x_values:Array[int]=[0,floori(image_size.x*.5),image_size.x-1]
	for probe_x in probe_x_values:
		if top_height>0:
			for probe_y in [0,floori(top_height*.5),top_height-1]:
				if image.get_pixel(probe_x,probe_y)!=Color.BLACK:return false
		if bottom_start<image_size.y:
			for probe_y in [bottom_start,floori((bottom_start+image_size.y-1)*.5),image_size.y-1]:
				if image.get_pixel(probe_x,probe_y)!=Color.BLACK:return false
	return true


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


func _write_json_file(path:String,value:Variant)->bool:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify(value,"\t",false)+"\n")
	file.close()
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed is Dictionary


func _create_and_validate_bundle(bundle_path:String,manifest_path:String,captures:Array,image_size:Vector2i)->Dictionary:
	var packer:=ZIPPacker.new()
	packer.compression_level=ZIPPacker.COMPRESSION_NONE
	if packer.open(bundle_path)!=OK:return {"ok":false,"error":"bundle_open_failed"}
	for capture_value in captures:
		if not capture_value is Dictionary:
			packer.close()
			return {"ok":false,"error":"bundle_capture_manifest_invalid"}
		var capture:Dictionary=capture_value
		var filename:=str(capture.get("filename",""))
		var source_path:=OUTPUT_DIRECTORY.path_join(filename)
		if filename.get_file()!=filename or not FileAccess.file_exists(source_path):
			packer.close()
			return {"ok":false,"error":"bundle_source_missing_%s"%str(capture.get("product_id","unknown"))}
		if packer.start_file(filename)!=OK or packer.write_file(FileAccess.get_file_as_bytes(source_path))!=OK or packer.close_file()!=OK:
			packer.close()
			return {"ok":false,"error":"bundle_png_write_failed_%s"%str(capture.get("product_id","unknown"))}
	if packer.start_file(BATCH_MANIFEST_FILENAME)!=OK or packer.write_file(FileAccess.get_file_as_bytes(manifest_path))!=OK or packer.close_file()!=OK:
		packer.close()
		return {"ok":false,"error":"bundle_manifest_write_failed"}
	if packer.close()!=OK:return {"ok":false,"error":"bundle_close_failed"}
	return _validate_bundle_archive(bundle_path,captures,image_size)


func _validate_bundle_archive(bundle_path:String,captures:Array,image_size:Vector2i)->Dictionary:
	var reader:=ZIPReader.new()
	if reader.open(bundle_path)!=OK:return {"ok":false,"error":"bundle_reopen_failed"}
	var archive_files:Array[String]=[]
	for file_value in reader.get_files():archive_files.append(str(file_value))
	var expected_files:Array[String]=[BATCH_MANIFEST_FILENAME]
	var expected_ids:=BuildProfileClass.iap_review_capture_product_ids()
	var seen_ids:Dictionary={}
	for capture_value in captures:
		if not capture_value is Dictionary:
			reader.close()
			return {"ok":false,"error":"bundle_manifest_entry_invalid"}
		var capture:Dictionary=capture_value
		var product_id:=str(capture.get("product_id",""))
		var filename:=str(capture.get("filename",""))
		if seen_ids.has(product_id):
			reader.close()
			return {"ok":false,"error":"bundle_product_duplicate_%s"%product_id}
		seen_ids[product_id]=true
		if filename!="%s-app-review.png"%product_id:
			reader.close()
			return {"ok":false,"error":"bundle_filename_mismatch_%s"%product_id}
		expected_files.append(filename)
		var bytes:=reader.read_file(filename)
		if not _is_rgb_png_without_alpha(bytes,image_size):
			reader.close()
			return {"ok":false,"error":"bundle_png_invalid_%s"%product_id}
		if _sha256_hex(bytes)!=str(capture.get("sha256","")):
			reader.close()
			return {"ok":false,"error":"bundle_sha256_mismatch_%s"%product_id}
	for expected_id in expected_ids:
		if not seen_ids.has(expected_id):
			reader.close()
			return {"ok":false,"error":"bundle_product_missing_%s"%expected_id}
	archive_files.sort();expected_files.sort()
	if archive_files!=expected_files:
		reader.close()
		return {"ok":false,"error":"bundle_file_set_mismatch"}
	var bundled_manifest=JSON.parse_string(reader.read_file(BATCH_MANIFEST_FILENAME).get_string_from_utf8())
	reader.close()
	if not bundled_manifest is Dictionary:return {"ok":false,"error":"bundle_manifest_json_invalid"}
	if int(bundled_manifest.get("product_count",0))!=PRODUCT_COUNT:return {"ok":false,"error":"bundle_manifest_count_mismatch"}
	return {"ok":true}


func _build_status_ui()->void:
	_status_layer=CanvasLayer.new()
	_status_layer.name="IAPReviewCaptureStatusLayer"
	_status_layer.layer=1000
	add_child(_status_layer)
	var input_blocker:=Control.new()
	input_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	input_blocker.mouse_filter=Control.MOUSE_FILTER_STOP
	_status_layer.add_child(input_blocker)
	_status_visual=Control.new()
	_status_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_status_visual.mouse_filter=Control.MOUSE_FILTER_IGNORE
	input_blocker.add_child(_status_visual)
	var shade:=ColorRect.new()
	shade.color=Color(0.08,0.05,0.03,.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_status_visual.add_child(shade)
	var panel:=PanelContainer.new()
	panel.position=Vector2(48,330)
	panel.size=Vector2(480,360)
	_status_visual.add_child(panel)
	var column:=VBoxContainer.new()
	column.alignment=BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation",18)
	panel.add_child(column)
	var title:=Label.new()
	title.text="IAP審査画像 36商品一括撮影"
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
	_share_button.text="36枚のZIPを共有"
	_share_button.custom_minimum_size=Vector2(280,58)
	_share_button.visible=false
	_share_button.pressed.connect(_share_bundle)
	column.add_child(_share_button)


func _show_status(message:String,can_share:bool)->void:
	if _status_layer==null:return
	_status_layer.visible=true
	_status_visual.visible=true
	_status_label.text=message
	_share_button.visible=can_share


func _share_bundle()->void:
	if _output_path.is_empty() or not FileAccess.file_exists(_output_path):
		_fail("capture_bundle_missing")
		return
	_main.call("_open_native_share_or_fallback",_output_path,BUNDLE_FILENAME,"iap_review_capture","application/zip")


func _fail(reason:String,diagnostic:String="")->void:
	var message:="撮影を停止しました。\n理由コード: %s"%reason
	if not _active_product_id.is_empty():message+="\n商品ID: %s"%_active_product_id
	if not diagnostic.is_empty():message+="\n診断: %s"%diagnostic
	message+="\n商品作成・購入・送信は行っていません。"
	_show_status(message,false)
	push_error("IAP_REVIEW_CAPTURE_FAILED product_id=%s reason=%s%s"%[_active_product_id if not _active_product_id.is_empty() else "batch",reason," diagnostic="+diagnostic if not diagnostic.is_empty() else ""])
