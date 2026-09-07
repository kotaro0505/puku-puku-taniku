class_name ConsumableIAPService
extends Node

signal product_info_updated(product_info:Dictionary)
signal purchase_started(product_id:String)
signal purchase_verified(product_id:String,transaction_id:String)
signal purchase_cancelled(product_id:String)
signal purchase_failed(product_id:String,message:String)
signal purchase_unavailable(message:String)
signal restore_event_ignored(product_id:String)

var product_definitions:Array=[]
var product_info:Dictionary={}
var store_bridge:Variant=null
var native_available:=false
var request_in_progress:=false

func configure(products:Array)->void:
	product_definitions=products.duplicate(true)
	_connect_native_store()
	if native_available:request_product_info()

func _connect_native_store()->void:
	native_available=false;store_bridge=null
	if OS.has_feature("ios") and Engine.has_singleton("InAppStore"):
		store_bridge=Engine.get_singleton("InAppStore")
		store_bridge.set_auto_finish_transaction(false)
		native_available=true

func set_store_bridge_for_test(bridge:Variant)->void:
	store_bridge=bridge;native_available=bridge!=null
	if native_available and store_bridge.has_method("set_auto_finish_transaction"):store_bridge.set_auto_finish_transaction(false)

func request_product_info()->bool:
	if not native_available or store_bridge==null:return false
	var ids:Array[String]=[]
	for raw_product in product_definitions:
		if raw_product is Dictionary:
			var product_id:=str(raw_product.get("product_id",""))
			if not product_id.is_empty():ids.append(product_id)
	if ids.is_empty():return false
	var error_code=int(store_bridge.request_product_info({"product_ids":ids}))
	request_in_progress=error_code==OK
	if error_code!=OK:purchase_unavailable.emit("商品情報を取得できませんでした")
	return error_code==OK

func purchase(product_id:String)->bool:
	if _product_definition(product_id).is_empty():
		purchase_failed.emit(product_id,"未登録の商品です")
		return false
	if not native_available or store_bridge==null:
		purchase_unavailable.emit("App Store購入はiOS版で利用できます")
		return false
	var error_code=int(store_bridge.purchase({"product_id":product_id}))
	if error_code!=OK:
		purchase_failed.emit(product_id,"購入を開始できませんでした")
		return false
	purchase_started.emit(product_id)
	return true

func finish_transaction(product_id:String)->void:
	if native_available and store_bridge!=null and store_bridge.has_method("finish_transaction"):
		store_bridge.finish_transaction(product_id)

func _process(_delta:float)->void:
	if not native_available or store_bridge==null:return
	while int(store_bridge.get_pending_event_count())>0:
		process_store_event(store_bridge.pop_pending_event())

func process_store_event(raw_event:Variant)->void:
	if not raw_event is Dictionary:return
	var event:Dictionary=raw_event
	var event_type:=str(event.get("type",""));var result:=str(event.get("result",""));var product_id:=str(event.get("product_id",""))
	match event_type:
		"product_info":
			request_in_progress=false
			if result=="ok":_store_product_info(event)
			else:purchase_unavailable.emit(str(event.get("error","商品情報を取得できませんでした")))
		"purchase":
			if result=="ok":
				var transaction_id:=str(event.get("transaction_id",""))
				if transaction_id.is_empty():
					purchase_failed.emit(product_id,"取引IDを確認できませんでした")
				else:purchase_verified.emit(product_id,transaction_id)
			elif result=="error":
				var message:=str(event.get("error","購入に失敗しました"))
				if _looks_cancelled(message):purchase_cancelled.emit(product_id)
				else:purchase_failed.emit(product_id,message)
		"restore":
			# These products are consumables. Restore callbacks must never grant pods.
			if result=="ok":restore_event_ignored.emit(product_id)

func localized_price(product_id:String)->String:
	var info:Dictionary=product_info.get(product_id,{})
	if not info.is_empty():return str(info.get("localized_price",""))
	return str(_product_definition(product_id).get("display_price",""))

func _store_product_info(event:Dictionary)->void:
	product_info.clear()
	var ids=event.get("ids",[]);var titles=event.get("titles",[]);var descriptions=event.get("descriptions",[]);var localized_prices=event.get("localized_prices",[]);var currency_codes=event.get("currency_codes",[])
	for index in range(ids.size()):
		var product_id:=str(ids[index])
		product_info[product_id]={
			"title":str(titles[index]) if index<titles.size() else "",
			"description":str(descriptions[index]) if index<descriptions.size() else "",
			"localized_price":str(localized_prices[index]) if index<localized_prices.size() else "",
			"currency_code":str(currency_codes[index]) if index<currency_codes.size() else ""
		}
	product_info_updated.emit(product_info.duplicate(true))

func _product_definition(product_id:String)->Dictionary:
	for raw_product in product_definitions:
		if raw_product is Dictionary and str(raw_product.get("product_id",""))==product_id:return raw_product
	return {}

func _looks_cancelled(message:String)->bool:
	var lower:=message.to_lower()
	return "cancel" in lower or "キャンセル" in message
