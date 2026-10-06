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

func configure(pots:Array,cached_entitlements:Dictionary={},test_bridge:Variant=null)->void:
	_product_ids.clear()
	_product_states.clear()
	_entitlements.clear()
	_restore_in_progress=false
	_active_purchase_product_id=""
	_store_kit=null
	_using_test_bridge=false
	for pot_value in pots:
		if not pot_value is Dictionary:continue
		var pot:Dictionary=pot_value
		if str(pot.get("unlock_type","free"))!="iap_unlock":continue
		var product_id:=str(pot.get("iap_product_id","")).strip_edges()
		if product_id.is_empty() or _product_ids.has(product_id):continue
		_product_ids.append(product_id)
		_product_states[product_id]={"status":STATUS_LOADING,"localized_price":"","error":""}
		if bool(cached_entitlements.get(product_id,false)):_entitlements[product_id]=true
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
	call_deferred("_request_all_product_info")

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
	if _store_kit.has_signal("transaction_state_changed"):
		_store_kit.connect("transaction_state_changed",_on_transaction_state_changed)
	if _store_kit.has_signal("synchronized"):
		_store_kit.connect("synchronized",_on_synchronized)

func _request_all_product_info()->void:
	if _store_kit==null:return
	for product_id in _product_ids:
		if _store_kit.has_method("request_product_info"):
			_store_kit.call("request_product_info",product_id)

func _on_product_info_received(info:Dictionary)->void:
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

func _on_synchronized()->void:
	_restore_in_progress=false
	_request_all_product_info()
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

func _mark_all_unavailable(error:String)->void:
	for product_id in _product_ids:
		_product_states[product_id]={"status":STATUS_UNAVAILABLE,"localized_price":"","error":error}
	state_changed.emit()
