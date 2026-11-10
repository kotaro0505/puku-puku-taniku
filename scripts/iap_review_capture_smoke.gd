extends Node

const CaptureClass = preload("res://scripts/iap_review_capture.gd")
const BuildProfileClass = preload("res://scripts/build_profile.gd")


func _ready()->void:
	var product_ids:=BuildProfileClass.iap_review_capture_product_ids()
	assert(CaptureClass.PRODUCT_COUNT==36)
	assert(product_ids.size()==36)
	assert(product_ids[0]=="pot_unlock_001" and product_ids[35]=="pot_unlock_036")
	var unique_ids:Dictionary={}
	for product_id in product_ids:
		assert(not unique_ids.has(product_id))
		unique_ids[product_id]=true
	assert(CaptureClass.is_supported_apple_portrait_size(Vector2i(1320,2868)))
	assert(CaptureClass.is_supported_apple_portrait_size(Vector2i(1179,2556)))
	assert(CaptureClass.is_supported_apple_portrait_size(Vector2i(1125,2436)))
	assert(not CaptureClass.is_supported_apple_portrait_size(Vector2i(576,1024)))
	assert(int(ProjectSettings.get_setting("display/window/size/viewport_width",0))==576)
	assert(int(ProjectSettings.get_setting("display/window/size/viewport_height",0))==1024)
	assert(1125*1024==2000*576)

	# iPhone 11 Pro renders this project's 9:16 viewport at 1125x2000.
	# Reconstruct the native 1125x2436 app screen by adding the real 218 px
	# letterbox areas above and below. The source pixels must remain unscaled.
	var viewport_image:=Image.create(1125,2000,false,Image.FORMAT_RGB8)
	viewport_image.fill(Color(0.2,0.4,0.6))
	viewport_image.set_pixel(0,0,Color.RED)
	viewport_image.set_pixel(1124,1999,Color.GREEN)
	var composition:=CaptureClass.compose_native_screen_capture(viewport_image,Vector2i(1125,2436))
	assert(bool(composition.ok))
	assert(composition.image_size==Vector2i(1125,2436))
	assert(composition.viewport_content_size==Vector2i(1125,2000))
	assert(composition.viewport_offset==Vector2i(0,218))
	assert(int(composition.letterbox_top)==218 and int(composition.letterbox_bottom)==218)
	assert(composition.content_scaled==false)
	var native_image:Image=composition.image
	assert(native_image.get_pixel(0,0)==Color.BLACK)
	assert(native_image.get_pixel(0,217)==Color.BLACK)
	assert(native_image.get_pixel(0,218)==Color.RED)
	assert(native_image.get_pixel(1124,2217)==Color.GREEN)
	assert(native_image.get_pixel(1124,2218)==Color.BLACK)
	assert(native_image.get_pixel(1124,2435)==Color.BLACK)
	assert(CaptureClass._has_black_letterbox(native_image,Vector2i(0,218),Vector2i(1125,2000)))
	var composed_png_path:=CaptureClass.OUTPUT_DIRECTORY.path_join("smoke-native-screen.png")
	assert(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CaptureClass.OUTPUT_DIRECTORY))==OK)
	assert(native_image.save_png(composed_png_path)==OK)
	var composed_png_bytes:=FileAccess.get_file_as_bytes(composed_png_path)
	assert(CaptureClass._is_rgb_png_without_alpha(composed_png_bytes,Vector2i(1125,2436)))
	var reloaded_native_image:=Image.new()
	assert(reloaded_native_image.load_png_from_buffer(composed_png_bytes)==OK)
	assert(CaptureClass._has_black_letterbox(reloaded_native_image,Vector2i(0,218),Vector2i(1125,2000)))
	var wrong_width_image:=Image.create(1124,1,false,Image.FORMAT_RGB8)
	assert(not bool(CaptureClass.compose_native_screen_capture(wrong_width_image,Vector2i(1125,2436)).ok))
	assert(not bool(CaptureClass.compose_native_screen_capture(viewport_image,Vector2i(1125,2000)).ok))

	# StoreKit's numeric value, ISO currency code, localized display, and current
	# storefront must all be present. No particular display string or JPY value is
	# invented by the capture feature.
	var usa_price:={"currency_code":"USD","currency_value":0.49,"storefront_country_code":"USA","localized_price":"$0.49"}
	var japan_price:={"currency_code":"JPY","currency_value":100.0,"storefront_country_code":"JPN","localized_price":"¥100"}
	assert(bool(CaptureClass.validate_storekit_price_tuple(usa_price).ok))
	assert(bool(CaptureClass.validate_storekit_price_tuple(japan_price).ok))
	assert(not bool(CaptureClass.validate_storekit_price_tuple({"currency_code":"USD","currency_value":true,"storefront_country_code":"USA","localized_price":"$0.49"}).ok))
	assert(not bool(CaptureClass.validate_storekit_price_tuple({"currency_code":"JPY","currency_value":100.0,"storefront_country_code":"USA","localized_price":"¥100"}).ok))
	assert(not bool(CaptureClass.validate_storekit_price_tuple({"currency_code":"USD","currency_value":0.0,"storefront_country_code":"USA","localized_price":"$0.00"}).ok))
	assert(not bool(CaptureClass.validate_storekit_price_tuple({"currency_code":"USD","currency_value":0.49,"storefront_country_code":"","localized_price":"$0.49"}).ok))
	assert(not bool(CaptureClass.validate_storekit_price_tuple(usa_price,"JPN","JPY").ok))
	var states:Dictionary={}
	for product_id in product_ids:states[product_id]=usa_price.duplicate(true)
	var batch_result:=CaptureClass.validate_storekit_price_batch(product_ids,states)
	assert(bool(batch_result.ok) and str(batch_result.storefront_country_code)=="USA" and str(batch_result.currency_code)=="USD")
	states["pot_unlock_036"]=japan_price.duplicate(true)
	var mixed_batch:=CaptureClass.validate_storekit_price_batch(product_ids,states)
	assert(not bool(mixed_batch.ok) and str(mixed_batch.error).contains("storefront_changed_during_batch"))
	var usd_diagnostic:=CaptureClass._storekit_price_diagnostic(usa_price)
	assert(usd_diagnostic.contains("currency_code=USD"))
	assert(usd_diagnostic.contains("currency_value=0.49"))
	assert(usd_diagnostic.contains("storefront_country_code=USA"))
	assert(usd_diagnostic.contains('localized_price="$0.49"'))

	var rgb_header:=_png_header(Vector2i(1320,2868),2)
	assert(CaptureClass._is_rgb_png_without_alpha(rgb_header,Vector2i(1320,2868)))
	var rgba_header:=_png_header(Vector2i(1320,2868),6)
	assert(not CaptureClass._is_rgb_png_without_alpha(rgba_header,Vector2i(1320,2868)))
	assert(not CaptureClass._is_rgb_png_without_alpha(rgb_header,Vector2i(1290,2796)))
	_test_zip_bundle_round_trip(product_ids,rgb_header)

	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/pot-iap-catalog.json"))
	assert(catalog is Array and catalog.size()==36)
	for index in catalog.size():
		var pot:Dictionary=catalog[index]
		assert(str(pot.iap_product_id)==product_ids[index])
		assert(str(pot.unlock_type)=="iap_unlock")
		assert(str(pot.image_path).ends_with(".png") and ResourceLoader.exists(str(pot.image_path)))
		assert(not str(pot.display_name).strip_edges().is_empty())

	var capture_source:=FileAccess.get_file_as_string("res://scripts/iap_review_capture.gd")
	assert(capture_source.contains("iap_review_capture_product_ids"))
	assert(capture_source.contains("validate_storekit_price_batch"))
	assert(capture_source.contains("ZIPPacker.new()") and capture_source.contains("ZIPReader.new()"))
	assert(capture_source.contains('"application/zip"'))
	assert(capture_source.contains("viewport_image.convert(Image.FORMAT_RGB8)"))
	assert(capture_source.contains("DisplayServer.screen_get_size(DisplayServer.SCREEN_OF_MAIN_WINDOW)"))
	assert(capture_source.contains("native_screen_with_unscaled_viewport_and_black_letterbox"))
	assert(capture_source.contains('"content_scaled":false'))
	assert(capture_source.contains("buy_button.mouse_filter=Control.MOUSE_FILTER_IGNORE"))
	assert(capture_source.contains('"storekit_price_valid"'))
	assert(capture_source.contains("storekit_product_batch_timeout"))
	assert(capture_source.contains("IAP_REVIEW_CAPTURE_BATCH_OK"))
	assert(not capture_source.contains("is_expected_jpy_100_price"))
	assert(not capture_source.contains("expected_japan_price_yen"))
	var main_source:=FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(main_source.contains("price_only_product_ids"))
	assert(main_source.contains("BuildProfileClass.iap_review_capture_product_ids()"))
	assert(main_source.contains('mime_type:String="image/png"'))

	var presets:=FileAccess.get_file_as_string("res://export_presets.cfg")
	var production_header:=presets.get_slice('[preset.1]',1).get_slice('[preset.1.options]',0)
	assert(production_header.contains('custom_features="puku_app_store_release"'))
	assert(not production_header.contains("puku_iap_review_capture"))
	assert(presets.contains('custom_features="puku_app_store_release,puku_iap_review_capture"'))

	print("IAP_REVIEW_CAPTURE_SMOKE_OK products=36 storefront_price_gate=true native_screen_letterbox=true content_scaled=false rgb_png_gate=true zip_bundle=true production_isolated=true")
	get_tree().quit()


func _test_zip_bundle_round_trip(product_ids:Array[String],png_bytes:PackedByteArray)->void:
	var capture_controller:=CaptureClass.new()
	add_child(capture_controller)
	var output_directory_absolute:=ProjectSettings.globalize_path(CaptureClass.OUTPUT_DIRECTORY)
	assert(DirAccess.make_dir_recursive_absolute(output_directory_absolute)==OK)
	var captures:Array=[]
	for product_id in product_ids:
		var filename:="%s-app-review.png"%product_id
		var path:=CaptureClass.OUTPUT_DIRECTORY.path_join(filename)
		var file:=FileAccess.open(path,FileAccess.WRITE)
		assert(file!=null)
		file.store_buffer(png_bytes)
		file.close()
		captures.append({"product_id":product_id,"filename":filename,"sha256":capture_controller._sha256_hex(png_bytes)})
	var manifest_path:=CaptureClass.OUTPUT_DIRECTORY.path_join(CaptureClass.BATCH_MANIFEST_FILENAME)
	assert(capture_controller._write_json_file(manifest_path,{"product_count":36}))
	var bundle_path:=CaptureClass.OUTPUT_DIRECTORY.path_join("smoke-iap-review-captures.zip")
	var result:Dictionary=capture_controller._create_and_validate_bundle(bundle_path,manifest_path,captures,Vector2i(1320,2868))
	assert(bool(result.get("ok",false)))
	var reader:=ZIPReader.new()
	assert(reader.open(bundle_path)==OK)
	assert(reader.get_files().size()==37)
	reader.close()


func _png_header(size:Vector2i,color_type:int)->PackedByteArray:
	var bytes:=PackedByteArray()
	bytes.resize(33)
	var signature:=PackedByteArray([137,80,78,71,13,10,26,10])
	for index in signature.size():bytes[index]=signature[index]
	bytes[8]=0;bytes[9]=0;bytes[10]=0;bytes[11]=13
	bytes[12]=73;bytes[13]=72;bytes[14]=68;bytes[15]=82
	_write_u32_be(bytes,16,size.x)
	_write_u32_be(bytes,20,size.y)
	bytes[24]=8
	bytes[25]=color_type
	return bytes


func _write_u32_be(bytes:PackedByteArray,offset:int,value:int)->void:
	bytes[offset]=(value>>24)&0xff
	bytes[offset+1]=(value>>16)&0xff
	bytes[offset+2]=(value>>8)&0xff
	bytes[offset+3]=value&0xff
