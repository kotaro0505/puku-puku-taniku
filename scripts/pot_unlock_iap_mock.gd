class_name PotUnlockIAPMock
extends RefCounted

signal transaction_state_changed(transaction:Dictionary)
signal product_info_received(product_info:Dictionary)
signal synchronized

const TRANSACTION_PURCHASED := 3
const TRANSACTION_RESTORED := 4

var localized_prices:Dictionary={}
var purchased:Dictionary={}
var restore_entitlements:Dictionary={}
var next_purchase_error:=""
var purchase_calls:Array[String]=[]
var requested_products:Array[String]=[]
var sync_calls:=0

func request_product_info(product_id:String)->Signal:
	requested_products.append(product_id)
	if not localized_prices.has(product_id):
		product_info_received.emit({"product_id":product_id,"error":"not_configured"})
	else:
		product_info_received.emit({
			"error":"",
			"product_id":product_id,
			"display_name":product_id,
			"description":"mock non-consumable",
			"is_purchased":bool(purchased.get(product_id,false)),
			"currency_value":0.0,
			"currency_code":"TEST",
			"currency_symbol":"",
			"localized_price":str(localized_prices[product_id]),
		})
	return product_info_received

func purchase_product(product_id:String,_quantity:int=1)->Signal:
	purchase_calls.append(product_id)
	if not next_purchase_error.is_empty():
		var error:=next_purchase_error
		next_purchase_error=""
		# StoreKit error dictionaries may contain only the error key.
		transaction_state_changed.emit({"error":error})
	elif not localized_prices.has(product_id):
		transaction_state_changed.emit({"product_id":product_id,"error":"not_configured"})
	else:
		purchased[product_id]=true
		transaction_state_changed.emit({"error":"","product_id":product_id,"transaction_state":TRANSACTION_PURCHASED})
	return transaction_state_changed

func sync()->Signal:
	sync_calls+=1
	for product_id_value in restore_entitlements:
		var product_id:=str(product_id_value)
		if not bool(restore_entitlements[product_id_value]):continue
		purchased[product_id]=true
		transaction_state_changed.emit({"error":"","product_id":product_id,"transaction_state":TRANSACTION_RESTORED})
	synchronized.emit()
	return synchronized
