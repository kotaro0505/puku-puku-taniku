class_name PotUnlockIAPService
extends Node

signal state_changed
signal entitlement_changed(product_id:String,unlocked:bool)
signal purchase_failed(product_id:String,reason:String)
signal restore_finished(success:bool)

const STOREKIT2_CLASS_NAME := "GodotStoreKit2"
const STATUS_LOADING := "loading"
const STATUS_AVAILABLE := "available"
const STATUS_UNAVAILABLE := "unavailable"
const STATUS_PURCHASING := "purchasing"

# Values exported by GodotStoreKit2.TransactionState.  Keeping the numeric
# bridge constants here avoids loading an iOS-only class on Web or desktop.
const TRANSACTION_FAILED := 0
const TRANSACTION_REFUNDED := 1
const TRANSACTION_PENDING := 2
const TRANSACTION_PURCHASED := 3
const TRANSACTION_RESTORED := 4
const TRANSACTION_EXPIRED := 5
const TRANSACTION_CANCELED := 6

var _store_kit
var _product_ids:Array[String]=[]
var _product_states:Dictionary={}
var _entitlements:Dictionary={}
var _restore_in_progress:=false
var _active_purchase_product_id:=""
var _using_test_bridge:=false
var _price_only_product_id:=""
var _request_method_available:=false
var _response_signal_available:=false
var _requests_dispatched:=0
var _responses_received:=0

func configure(pots:Array,cached_entitlements:Dictionary={},test_bridge:Variant=null,price_only_product_id:String="")->void:
	_product_ids.clear()
	_product_states.clear()
	_entitlements.clear()
	_restore_in_progress=false
	_active_purchase_product_id=""
	_store_kit=null
	_using_test_bridge=false
	_price_only_product_id=price_only_product_id.strip_edges()
	_request_method_available=false
	_response_signal_available=false
	_requests_dispatched=0
	_responses_received=0
	for pot_value in pots:
		if not pot_value is Dictionary:continue
		var pot:Dictionary=pot_value
		if str(pot.get("unlock_type","free"))!="iap_unlock":continue
		var product_id:=str(pot.get("iap_product_id","")).strip_edges()
		if product_id.is_empty() or _product_ids.has(product_id):continue
		_product_ids.append(product_id)
		_product_states[product_id]={"status":STATUS_LOADING,"localized_price":"","error":""}
		if bool(cached_entitlements.get(product_id,false)):_entitlements[product_id]=true
	if not _price_only_product_id.is_empty() and not _product_ids.has(_price_only_product_id):
		_mark_all_unavailable("capture_product_unknown")
		return
	if not _price_only_product_id.is_empty():
		for product_id in _product_ids:
			if product_id==_price_only_product_id:continue
			_product_states[product_id]={"status":STATUS_UNAVAILABLE,"localized_price":"","error":"capture_not_requested"}
	if test_bridge!=null:
		if not OS.is_debug_build():
			push_error("Pot IAP test bridge is disabled in release builds")
		else:
			_store_kit=test_bridge
			_using_test_bridge=true
	elif OS.has_feature("ios") and ClassDB.class_exists(STOREKIT2_CLASS_NAME):
		_store_kit=ClassDB.instantiate(STOREKIT2_CLASS_NAME)
	if _store_kit==null:
		_mark_all_unavailable("storekit_unavailable")
		return
	_connect_bridge_signals()
	if not _validate_product_request_api():return
	call_deferred("_request_configured_product_data")

func product_states_snapshot()->Dictionary:
	return _product_states.duplicate(true)

func entitlements_snapshot()->Dictionary:
	return _entitlements.duplicate(true)

func is_unlocked(product_id:String)->bool:
	return bool(_entitlements.get(product_id,false))

func restore_available()->bool:
	return _store_kit!=null and _store_kit.has_method("sync")

func restore_in_progress()->bool:
	return _restore_in_progress

func using_test_bridge()->bool:
	return _using_test_bridge

func diagnostic_snapshot()->Dictionary:
	return {
		"bridge_available":_store_kit!=null,
		"request_mode":"price_only" if not _price_only_product_id.is_empty() else "product_info",
		"request_method_available":_request_method_available,
		"response_signal_available":_response_signal_available,
		"configured_product_count":_product_ids.size(),
		"requested_product_count":1 if not _price_only_product_id.is_empty() else _product_ids.size(),
		"requests_dispatched":_requests_dispatched,
		"responses_received":_responses_received,
	}

func purchase(product_id:String)->bool:
	if not _product_ids.has(product_id):
		purchase_failed.emit(product_id,"unknown_product")
		return false
	if is_unlocked(product_id):return false
	var state:Dictionary=_product_states.get(product_id,{})
	if _store_kit==null or not _store_kit.has_method("purchase_product") or str(state.get("status",""))!=STATUS_AVAILABLE:
		purchase_failed.emit(product_id,"product_unavailable")
		return false
	state["status"]=STATUS_PURCHASING
	_product_states[product_id]=state
	_active_purchase_product_id=product_id
	state_changed.emit()
	_store_kit.call("purchase_product",product_id,1)
	return true

func restore_purchases()->bool:
	if not restore_available() or _restore_in_progress:
		purchase_failed.emit("","restore_unavailable")
		return false
	_restore_in_progress=true
	state_changed.emit()
	_store_kit.call("sync")
	return true

func _connect_bridge_signals()->void:
	if _store_kit.has_signal("product_info_received"):
		_store_kit.connect("product_info_received",_on_product_info_received)
	if _store_kit.has_signal("product_price_received"):
		_store_kit.connect("product_price_received",_on_product_price_received)
	if _store_kit.has_signal("transaction_state_changed"):
		_store_kit.connect("transaction_state_changed",_on_transaction_state_changed)
	if _store_kit.has_signal("synchronized"):
		_store_kit.connect("synchronized",_on_synchronized)

func _validate_product_request_api()->bool:
	var method_name:="request_product_price" if not _price_only_product_id.is_empty() else "request_product_info"
	var signal_name:="product_price_received" if not _price_only_product_id.is_empty() else "product_info_received"
	_request_method_available=_store_kit.has_method(method_name)
	_response_signal_available=_store_kit.has_signal(signal_name)
	if _request_method_available and _response_signal_available:return true
	var error:="storekit_%s_%s_missing"%[
		"price" if not _price_only_product_id.is_empty() else "product_info",
		"method" if not _request_method_available else "signal",
	]
	if not _price_only_product_id.is_empty():_set_product_unavailable(_price_only_product_id,error)
	else:_mark_loading_unavailable(error)
	return false

func _request_configured_product_data()->void:
	if _store_kit==null:return
	if not _price_only_product_id.is_empty():
		_requests_dispatched+=1
		_store_kit.call("request_product_price",_price_only_product_id)
		return
	for product_id in _product_ids:
		_requests_dispatched+=1
		_store_kit.call("request_product_info",product_id)

func _on_product_info_received(info:Dictionary)->void:
	_responses_received+=1
	var product_id:=str(info.get("product_id",""))
	if product_id.is_empty():
		# StoreKit may omit the product id on an error. Keep every unresolved item
		# safely unavailable rather than guessing which price belongs to it.
		if not str(info.get("error","")).is_empty():_mark_loading_unavailable(str(info.get("error","product_info_failed")))
		return
	if not _product_ids.has(product_id):return
	var error:=str(info.get("error",""))
	var localized_price:=str(info.get("localized_price","")).strip_edges()
	if not error.is_empty() or localized_price.is_empty():
		_product_states[product_id]={"status":STATUS_UNAVAILABLE,"localized_price":"","error":error if not error.is_empty() else "localized_price_missing"}
		state_changed.emit()
		return
	_product_states[product_id]={"status":STATUS_AVAILABLE,"localized_price":localized_price,"error":""}
	# A successful StoreKit lookup is authoritative. It restores purchases on a
	# new save/device and also removes a refunded entitlement from the local cache.
	_set_entitlement(product_id,bool(info.get("is_purchased",false)))
	state_changed.emit()

func _on_product_price_received(price:Dictionary)->void:
	_responses_received+=1
	var product_id:=str(price.get("product_id",_price_only_product_id))
	if product_id!=_price_only_product_id:return
	var error:=str(price.get("error",""))
	# Keep StoreKit's localized display byte-for-byte for the review button. The
	# numeric value and ISO currency code are retained separately so validation
	# never has to parse locale-dependent presentation text. The storefront code
	# is an in-memory diagnostic only and is never written to the game save.
	var localized_price:=str(price.get("localized_price",""))
	if not error.is_empty() or localized_price.strip_edges().is_empty():
		_set_product_unavailable(product_id,error if not error.is_empty() else "localized_price_missing")
		return
	_product_states[product_id]={
		"status":STATUS_AVAILABLE,
		"localized_price":localized_price,
		"currency_value":price.get("currency_value",null),
		"currency_code":str(price.get("currency_code","")),
		"currency_symbol":str(price.get("currency_symbol","")),
		"storefront_country_code":str(price.get("storefront_country_code","")),
		"error":"",
	}
	state_changed.emit()

func _on_transaction_state_changed(transaction:Dictionary)->void:
	var product_id:=str(transaction.get("product_id",""))
	if product_id.is_empty():product_id=_active_purchase_product_id
	var error:=str(transaction.get("error",""))
	if not error.is_empty():
		_reset_product_after_purchase(product_id,error)
		purchase_failed.emit(product_id,error)
		return
	if not _product_ids.has(product_id):return
	var transaction_state:=int(transaction.get("transaction_state",TRANSACTION_FAILED))
	match transaction_state:
		TRANSACTION_PURCHASED,TRANSACTION_RESTORED:
			_set_entitlement(product_id,true)
			_reset_product_after_purchase(product_id,"")
		TRANSACTION_REFUNDED,TRANSACTION_EXPIRED:
			_set_entitlement(product_id,false)
			_reset_product_after_purchase(product_id,"")
		TRANSACTION_PENDING:
			var state:Dictionary=_product_states.get(product_id,{})
			state["status"]=STATUS_PURCHASING
			_product_states[product_id]=state
			state_changed.emit()
		TRANSACTION_CANCELED:
			_reset_product_after_purchase(product_id,"canceled")
			purchase_failed.emit(product_id,"canceled")
		_:
			_reset_product_after_purchase(product_id,"purchase_failed")
			purchase_failed.emit(product_id,"purchase_failed")

func _on_synchronized(_error:String="")->void:
	_restore_in_progress=false
	_request_configured_product_data()
	restore_finished.emit(true)
	state_changed.emit()

func _set_entitlement(product_id:String,unlocked:bool)->void:
	var previous:=bool(_entitlements.get(product_id,false))
	if unlocked:_entitlements[product_id]=true
	else:_entitlements.erase(product_id)
	if previous!=unlocked:entitlement_changed.emit(product_id,unlocked)

func _reset_product_after_purchase(product_id:String,error:String)->void:
	if not _product_ids.has(product_id):return
	if _active_purchase_product_id==product_id:_active_purchase_product_id=""
	var state:Dictionary=_product_states.get(product_id,{})
	state["status"]=STATUS_AVAILABLE if not str(state.get("localized_price","")).is_empty() else STATUS_UNAVAILABLE
	state["error"]=error
	_product_states[product_id]=state
	state_changed.emit()

func _mark_loading_unavailable(error:String)->void:
	for product_id in _product_ids:
		var state:Dictionary=_product_states.get(product_id,{})
		if str(state.get("status",""))==STATUS_LOADING:
			state["status"]=STATUS_UNAVAILABLE
			state["error"]=error
			_product_states[product_id]=state
	state_changed.emit()

func _set_product_unavailable(product_id:String,error:String)->void:
	if not _product_ids.has(product_id):return
	_product_states[product_id]={"status":STATUS_UNAVAILABLE,"localized_price":"","error":error}
	state_changed.emit()

func _mark_all_unavailable(error:String)->void:
	for product_id in _product_ids:
		_product_states[product_id]={"status":STATUS_UNAVAILABLE,"localized_price":"","error":error}
	state_changed.emit()
