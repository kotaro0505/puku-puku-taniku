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
const RESTORE_RESULT_IDLE := "idle"
const RESTORE_RESULT_SUCCESS := "success"
const RESTORE_RESULT_CANCELLED := "cancelled"
const RESTORE_RESULT_NETWORK_ERROR := "network_error"
const RESTORE_RESULT_TIMEOUT := "timeout"
const RESTORE_RESULT_FAILED := "failed"
const RESTORE_STAGE_IDLE := "idle"
const RESTORE_STAGE_SYNCING := "syncing"
const RESTORE_STAGE_REFRESHING := "refreshing"
const RESTORE_SYNC_TIMEOUT_SECONDS := 120.0
const RESTORE_REFRESH_TIMEOUT_SECONDS := 60.0

# Values exported by GodotStoreKit2.TransactionState. Keeping the numeric
# bridge constants here avoids loading an iOS-only class on Web or desktop.
const TRANSACTION_FAILED := 0
const TRANSACTION_REFUNDED := 1
const TRANSACTION_PENDING := 2
const TRANSACTION_DEFERRED := 3
const TRANSACTION_PURCHASED := 4
const TRANSACTION_RESTORED := 5
const TRANSACTION_EXPIRED := 6
const TRANSACTION_CANCELED := 7

var _store_kit
var _product_ids:Array[String]=[]
var _product_states:Dictionary={}
var _entitlements:Dictionary={}
var _restore_in_progress:=false
var _active_purchase_product_id:=""
var _using_test_bridge:=false
var _price_only_product_ids:Array[String]=[]
var _request_method_available:=false
var _response_signal_available:=false
var _requests_dispatched:=0
var _responses_received:=0
var _product_info_error_count:=0
var _last_product_info_error_product_id:=""
var _restore_stage:=RESTORE_STAGE_IDLE
var _restore_result_code:=RESTORE_RESULT_IDLE
var _restore_sync_result_code:=RESTORE_RESULT_IDLE
var _restore_entitlements_result_code:=RESTORE_RESULT_IDLE
var _restore_entitlement_count:=0
var _restore_timeout_token:=0

func configure(pots:Array,cached_entitlements:Dictionary={},test_bridge:Variant=null,price_only_products:Variant=null,extra_product_ids:Variant=null)->void:
	_product_ids.clear()
	_product_states.clear()
	_entitlements.clear()
	_restore_in_progress=false
	_active_purchase_product_id=""
	_store_kit=null
	_using_test_bridge=false
	_price_only_product_ids=_normalize_price_only_product_ids(price_only_products)
	_request_method_available=false
	_response_signal_available=false
	_requests_dispatched=0
	_responses_received=0
	_product_info_error_count=0
	_last_product_info_error_product_id=""
	_restore_stage=RESTORE_STAGE_IDLE
	_restore_result_code=RESTORE_RESULT_IDLE
	_restore_sync_result_code=RESTORE_RESULT_IDLE
	_restore_entitlements_result_code=RESTORE_RESULT_IDLE
	_restore_entitlement_count=0
	_restore_timeout_token+=1
	for pot_value in pots:
		if not pot_value is Dictionary:continue
		var pot:Dictionary=pot_value
		if str(pot.get("unlock_type","free"))!="iap_unlock":continue
		var product_id:=str(pot.get("iap_product_id","")).strip_edges()
		if product_id.is_empty() or _product_ids.has(product_id):continue
		_product_ids.append(product_id)
		_product_states[product_id]={"status":STATUS_LOADING,"localized_price":"","error":""}
		if bool(cached_entitlements.get(product_id,false)):_entitlements[product_id]=true
	for extra_product_id in _normalize_product_ids(extra_product_ids):
		if _product_ids.has(extra_product_id):continue
		_product_ids.append(extra_product_id)
		_product_states[extra_product_id]={"status":STATUS_LOADING,"localized_price":"","error":""}
		if bool(cached_entitlements.get(extra_product_id,false)):_entitlements[extra_product_id]=true
	for requested_product_id in _price_only_product_ids:
		if not _product_ids.has(requested_product_id):
			_mark_all_unavailable("capture_product_unknown")
			return
	if not _price_only_product_ids.is_empty():
		for product_id in _product_ids:
			if _price_only_product_ids.has(product_id):continue
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
	return (
		_price_only_product_ids.is_empty()
		and _store_kit!=null
		and _store_kit.has_method("sync")
		and _store_kit.has_signal("synchronized")
		and _store_kit.has_method("request_current_entitlements")
		and _store_kit.has_signal("current_entitlements_received")
	)

func restore_in_progress()->bool:
	return _restore_in_progress

func restore_result_code()->String:
	return _restore_result_code

func using_test_bridge()->bool:
	return _using_test_bridge

func diagnostic_snapshot()->Dictionary:
	return {
		"bridge_available":_store_kit!=null,
		"request_mode":"price_only" if not _price_only_product_ids.is_empty() else "product_info",
		"request_method_available":_request_method_available,
		"response_signal_available":_response_signal_available,
		"configured_product_count":_product_ids.size(),
		"requested_product_count":_price_only_product_ids.size() if not _price_only_product_ids.is_empty() else _product_ids.size(),
		"requests_dispatched":_requests_dispatched,
		"responses_received":_responses_received,
		"product_info_error_count":_product_info_error_count,
		"last_product_info_error_product_id":_last_product_info_error_product_id,
		"restore_available":restore_available(),
		"restore_in_progress":_restore_in_progress,
		"restore_stage":_restore_stage,
		"restore_result_code":_restore_result_code,
		"restore_sync_result_code":_restore_sync_result_code,
		"restore_entitlements_result_code":_restore_entitlements_result_code,
		"restore_entitlement_count":_restore_entitlement_count,
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
	_restore_stage=RESTORE_STAGE_SYNCING
	_restore_result_code=RESTORE_RESULT_IDLE
	_restore_sync_result_code=RESTORE_RESULT_IDLE
	_restore_entitlements_result_code=RESTORE_RESULT_IDLE
	_restore_entitlement_count=0
	_arm_restore_timeout(RESTORE_SYNC_TIMEOUT_SECONDS)
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
	if _store_kit.has_signal("current_entitlements_received"):
		_store_kit.connect("current_entitlements_received",_on_current_entitlements_received)

func _validate_product_request_api()->bool:
	var method_name:="request_product_price" if not _price_only_product_ids.is_empty() else "request_product_info"
	var signal_name:="product_price_received" if not _price_only_product_ids.is_empty() else "product_info_received"
	_request_method_available=_store_kit.has_method(method_name)
	_response_signal_available=_store_kit.has_signal(signal_name)
	if _request_method_available and _response_signal_available:return true
	var error:="storekit_%s_%s_missing"%[
		"price" if not _price_only_product_ids.is_empty() else "product_info",
		"method" if not _request_method_available else "signal",
	]
	if not _price_only_product_ids.is_empty():
		for product_id in _price_only_product_ids:_set_product_unavailable(product_id,error)
	else:_mark_loading_unavailable(error)
	return false

func _request_configured_product_data()->void:
	if _store_kit==null:return
	if not _price_only_product_ids.is_empty():
		for product_id in _price_only_product_ids:
			_requests_dispatched+=1
			_store_kit.call("request_product_price",product_id)
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
		if not str(info.get("error","")).is_empty():
			_product_info_error_count+=1
			_last_product_info_error_product_id="unknown"
			_mark_loading_unavailable(str(info.get("error","product_info_failed")))
		return
	if not _product_ids.has(product_id):
		return
	var error:=str(info.get("error",""))
	var localized_price:=str(info.get("localized_price","")).strip_edges()
	if not error.is_empty() or localized_price.is_empty():
		_product_info_error_count+=1
		_last_product_info_error_product_id=product_id
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
	var fallback_product_id:=_price_only_product_ids[0] if _price_only_product_ids.size()==1 else ""
	var product_id:=str(price.get("product_id",fallback_product_id))
	if not _price_only_product_ids.has(product_id):return
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


func _normalize_price_only_product_ids(value:Variant)->Array[String]:
	return _normalize_product_ids(value)


func _normalize_product_ids(value:Variant)->Array[String]:
	var normalized:Array[String]=[]
	var candidates:Array=[]
	if typeof(value)==TYPE_STRING:
		candidates=[value]
	elif value is Array:
		candidates=value
	elif typeof(value)==TYPE_PACKED_STRING_ARRAY:
		for packed_value in value:candidates.append(packed_value)
	for candidate in candidates:
		var product_id:=str(candidate).strip_edges()
		if not product_id.is_empty() and not normalized.has(product_id):normalized.append(product_id)
	return normalized

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
		TRANSACTION_PENDING,TRANSACTION_DEFERRED:
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

func _on_synchronized(error:String="")->void:
	# Ignore a duplicate or late callback after failure/timeout.  The native
	# bridge emits a stable result code for failures and an empty string only
	# when AppStore.sync() completed successfully.
	if not _restore_in_progress or _restore_stage!=RESTORE_STAGE_SYNCING:return
	var result_code:=_classify_restore_error(error)
	_restore_sync_result_code=result_code
	if result_code!=RESTORE_RESULT_SUCCESS:
		_finish_restore(false,result_code)
		return
	_begin_restore_entitlement_refresh()

func _begin_restore_entitlement_refresh()->void:
	_restore_stage=RESTORE_STAGE_REFRESHING
	if _product_ids.is_empty():
		_restore_entitlements_result_code=RESTORE_RESULT_SUCCESS
		_finish_restore(true,RESTORE_RESULT_SUCCESS)
		return
	_arm_restore_timeout(RESTORE_REFRESH_TIMEOUT_SECONDS)
	_store_kit.call("request_current_entitlements")

func _on_current_entitlements_received(info:Dictionary)->void:
	if not _restore_in_progress or _restore_stage!=RESTORE_STAGE_REFRESHING:return
	var error:=str(info.get("error","")).strip_edges().to_lower()
	_restore_entitlements_result_code=error if not error.is_empty() else RESTORE_RESULT_SUCCESS
	if not error.is_empty():
		_finish_restore(false,RESTORE_RESULT_FAILED)
		return
	var product_ids_value:Variant=info.get("product_ids",null)
	if not (product_ids_value is Array) and typeof(product_ids_value)!=TYPE_PACKED_STRING_ARRAY:
		_restore_entitlements_result_code="invalid_entitlement_snapshot"
		_finish_restore(false,RESTORE_RESULT_FAILED)
		return
	var active_entitlements:Dictionary={}
	for product_id in _normalize_product_ids(product_ids_value):
		if _product_ids.has(product_id):active_entitlements[product_id]=true
	# Apply the verified snapshot only after it has been validated in full. This
	# restores purchases on a new device and removes refunded/revoked rights,
	# while a failed snapshot leaves the last known cache untouched.
	for product_id in _product_ids:
		_set_entitlement(product_id,active_entitlements.has(product_id))
	_restore_entitlement_count=active_entitlements.size()
	_finish_restore(true,RESTORE_RESULT_SUCCESS)

func _classify_restore_error(error:String)->String:
	var normalized:=error.strip_edges().to_lower()
	if normalized.is_empty():return RESTORE_RESULT_SUCCESS
	# compat6 emits these stable, locale-independent codes. The fallback
	# aliases keep a build made with an older bridge from reporting success.
	if normalized in ["cancelled","canceled","user_cancelled","user_canceled"]:return RESTORE_RESULT_CANCELLED
	if normalized in ["network_error","network","offline"]:return RESTORE_RESULT_NETWORK_ERROR
	return RESTORE_RESULT_FAILED

func _arm_restore_timeout(seconds:float)->void:
	_restore_timeout_token+=1
	_wait_for_restore_timeout(_restore_timeout_token,seconds)

func _wait_for_restore_timeout(token:int,seconds:float)->void:
	var tree:=get_tree()
	if tree==null:return
	await tree.create_timer(seconds).timeout
	_on_restore_timeout(token)

func _on_restore_timeout(token:int)->void:
	if token!=_restore_timeout_token or not _restore_in_progress:return
	_finish_restore(false,RESTORE_RESULT_TIMEOUT)

func _finish_restore(success:bool,result_code:String)->void:
	if not _restore_in_progress:return
	_restore_in_progress=false
	_restore_stage=RESTORE_STAGE_IDLE
	_restore_result_code=result_code
	_restore_timeout_token+=1
	state_changed.emit()
	restore_finished.emit(success)

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
