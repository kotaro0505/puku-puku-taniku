extends Node

const CaptureClass = preload("res://scripts/iap_review_capture.gd")


func _ready()->void:
	assert(CaptureClass.PRODUCT_ID=="pot_unlock_001")
	assert(CaptureClass.PRODUCT_ID==preload("res://scripts/build_profile.gd").IAP_REVIEW_CAPTURE_PRODUCT_ID)
	assert(CaptureClass.POT_ID=="g1_crystal_goblet")
	assert(CaptureClass.EXPECTED_PUKU_PRICE==2)
	assert(CaptureClass.is_supported_apple_portrait_size(Vector2i(1320,2868)))
	assert(CaptureClass.is_supported_apple_portrait_size(Vector2i(1179,2556)))
	assert(not CaptureClass.is_supported_apple_portrait_size(Vector2i(576,1024)))
	# Display formatting is presentation only. StoreKit's numeric value and ISO
	# currency code are the authoritative 100-yen gate.
	for display in ["¥100","￥100","¥100.00","100円"]:
		assert(CaptureClass.is_expected_jpy_100_price({"currency_code":"JPY","currency_value":100.0,"localized_price":display}))
	assert(CaptureClass.is_expected_jpy_100_price({"currency_code":"jpy","currency_value":100,"localized_price":"JP¥ 100"}))
	assert(not CaptureClass.is_expected_jpy_100_price({"currency_code":"USD","currency_value":100.0,"localized_price":"$100.00"}))
	assert(not CaptureClass.is_expected_jpy_100_price({"currency_code":"JPY","currency_value":99.0,"localized_price":"¥99"}))
	assert(not CaptureClass.is_expected_jpy_100_price({"currency_code":"JPY","currency_value":100.01,"localized_price":"¥100.01"}))
	assert(not CaptureClass.is_expected_jpy_100_price({"currency_code":"JPY","localized_price":"¥100"}))
	var usd_diagnostic:=CaptureClass._storekit_price_diagnostic({"currency_code":"USD","currency_value":0.49,"storefront_country_code":"USA","localized_price":"$0.49"})
	assert(not CaptureClass.is_expected_jpy_100_price({"currency_code":"USD","currency_value":0.49,"storefront_country_code":"USA","localized_price":"$0.49"}))
	assert(usd_diagnostic.contains("currency_code=USD"))
	assert(usd_diagnostic.contains("currency_value=0.49"))
	assert(usd_diagnostic.contains("storefront_country_code=USA"))
	var price_diagnostic:=CaptureClass._storekit_price_diagnostic({"currency_code":"JPY","currency_value":100.0,"storefront_country_code":"JPN","localized_price":"¥100.00"})
	assert(price_diagnostic.contains("currency_code=JPY"))
	assert(price_diagnostic.contains("currency_value=100"))
	assert(price_diagnostic.contains("storefront_country_code=JPN"))
	assert(price_diagnostic.contains('localized_price="¥100.00"'))

	var rgb_header:=_png_header(Vector2i(1320,2868),2)
	assert(CaptureClass._is_rgb_png_without_alpha(rgb_header,Vector2i(1320,2868)))
	var rgba_header:=_png_header(Vector2i(1320,2868),6)
	assert(not CaptureClass._is_rgb_png_without_alpha(rgba_header,Vector2i(1320,2868)))
	assert(not CaptureClass._is_rgb_png_without_alpha(rgb_header,Vector2i(1290,2796)))

	var capture_source:=FileAccess.get_file_as_string("res://scripts/iap_review_capture.gd")
	assert(capture_source.contains("BuildProfileClass.IAP_REVIEW_CAPTURE_PRODUCT_ID"))
	assert(not capture_source.contains("pot_unlock_002"))
	assert(capture_source.contains("image.convert(Image.FORMAT_RGB8)"))
	assert(capture_source.contains("buy_button.mouse_filter=Control.MOUSE_FILTER_IGNORE"))
	assert(capture_source.contains('"storekit_price_is_jpy_100"'))
	assert(capture_source.contains('"storekit_price_response_timeout"'))
	assert(capture_source.contains("IAP_REVIEW_CAPTURE_STOREKIT_PRICE"))
	assert(capture_source.contains("storefront_country_code=%s"))
	assert(not capture_source.contains("_is_jpy_100_display"))
	var main_source:=FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(main_source.contains("price_only_product_id"))
	assert(main_source.contains("BuildProfileClass.IAP_REVIEW_CAPTURE_PRODUCT_ID"))

	var presets:=FileAccess.get_file_as_string("res://export_presets.cfg")
	var production_header:=presets.get_slice('[preset.1]',1).get_slice('[preset.1.options]',0)
	assert(production_header.contains('custom_features="puku_app_store_release"'))
	assert(not production_header.contains("puku_iap_review_capture"))
	assert(presets.contains('custom_features="puku_app_store_release,puku_iap_review_capture"'))

	print("IAP_REVIEW_CAPTURE_SMOKE_OK target=pot_unlock_001 native_size_gate=true rgb_png_gate=true production_isolated=true")
	get_tree().quit()


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
