class_name MysteryPodSystem
extends RefCounted

const CONFIG_PATH := "res://data/mystery-pod.json"

var formal_settings:Dictionary={}
var settings:Dictionary={}
var iap_products:Array=[]
var series_catalog:Array=[]
var species_catalog:Array=[]

func load_config()->void:
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:parsed={}
	formal_settings=parsed.get("formal",{}).duplicate(true)
	iap_products=parsed.get("iap_products",[]).duplicate(true)
	reset_formal()

func configure_catalog(series_data:Array,species_data:Array)->void:
	series_catalog=series_data
	species_catalog=species_data

func reset_formal()->void:
	settings=formal_settings.duplicate(true)

func set_setting(key:String,value:Variant)->void:
	if not formal_settings.has(key):return
	settings[key]=value

func setting_float(key:String)->float:
	return float(settings.get(key,formal_settings.get(key,0.0)))

func setting_int(key:String)->int:
	return int(settings.get(key,formal_settings.get(key,0)))

func catalog_price_yen(series_entry:Dictionary)->int:
	return maxi(0,int(series_entry.get("unlock_price_yen",setting_int("default_catalog_price_yen"))))

func catalog_price_pods(series_entry:Dictionary)->int:
	return maxi(0,int(series_entry.get("unlock_price_pods",setting_int("default_catalog_price_pods"))))

func product_definition(product_id:String)->Dictionary:
	for raw_product in iap_products:
		if raw_product is Dictionary and str(raw_product.get("product_id",""))==product_id:return raw_product
	return {}

func product_ids()->Array[String]:
	var result:Array[String]=[]
	for raw_product in iap_products:
		if raw_product is Dictionary:
			var product_id:=str(raw_product.get("product_id",""))
			if not product_id.is_empty():result.append(product_id)
	return result

func open_pod(unlocked_series:Dictionary,discovered:Dictionary,pod_rng:RandomNumberGenerator)->Array[Dictionary]:
	var results:Array[Dictionary]=[]
	for slot_index in range(maxi(1,setting_int("slots_per_pod"))):
		var seed_weight:=maxf(0.0,setting_float("series_seed_weight"))
		var yen_weight:=maxf(0.0,setting_float("yen_weight"))
		var eligible:=eligible_series(unlocked_series,discovered)
		var choose_seed:=not eligible.is_empty() and seed_weight>0.0 and (yen_weight<=0.0 or pod_rng.randf()*(seed_weight+yen_weight)<seed_weight)
		if choose_seed:
			var series_entry:=choose_series(unlocked_series,discovered,pod_rng)
			results.append({"kind":"series_seed","series_id":str(series_entry.get("series_id","")),"display_name":str(series_entry.get("display_name","シリーズ"))})
		else:
			results.append({"kind":"yen","amount":choose_yen_amount(pod_rng)})
	return results

func eligible_series(unlocked_series:Dictionary,discovered:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for raw_series in series_catalog:
		if not raw_series is Dictionary:continue
		var series_id:=str(raw_series.get("series_id",""))
		if not bool(unlocked_series.get(series_id,false)):continue
		var entries:=eligible_species_for_series(series_id)
		if entries.is_empty():continue
		var complete:=true
		for entry in entries:
			if not bool(discovered.get(str(entry.get("species_id","")),false)):complete=false;break
		var weight:=maxf(0.0,float(raw_series.get("pod_seed_weight",1.0)))
		if complete:weight*=maxf(0.0,setting_float("completed_series_weight_multiplier"))
		if weight>0.0:
			var copy:Dictionary=raw_series.duplicate(true);copy["_pod_weight"]=weight;copy["_pod_complete"]=complete;result.append(copy)
	return result

func choose_series(unlocked_series:Dictionary,discovered:Dictionary,pod_rng:RandomNumberGenerator)->Dictionary:
	var candidates:=eligible_series(unlocked_series,discovered)
	return _weighted_dictionary(candidates,"_pod_weight",pod_rng)

func eligible_species_for_series(series_id:String)->Array[Dictionary]:
	var series_entry:=_series_entry(series_id)
	var result:Array[Dictionary]=[]
	for species_id_value in series_entry.get("species_ids",[]):
		var entry:=_species_entry(str(species_id_value))
		if entry.is_empty() or not _series_seed_eligible(entry):continue
		result.append(entry)
	return result

func choose_species_for_series(series_id:String,discovered:Dictionary,pod_rng:RandomNumberGenerator)->Dictionary:
	var weighted:Array[Dictionary]=[]
	for entry in eligible_species_for_series(series_id):
		var base_weight:=float(entry.get("series_seed_weight",entry.get("spawn_weight",0.0)))
		if base_weight<=0.0:continue
		var final_weight:=base_weight
		if bool(discovered.get(str(entry.get("species_id","")),false)):
			final_weight*=maxf(0.0,setting_float("discovered_species_weight_multiplier"))
		if final_weight>0.0:
			var copy:Dictionary=entry.duplicate(true);copy["_series_seed_weight"]=final_weight;weighted.append(copy)
	return _weighted_dictionary(weighted,"_series_seed_weight",pod_rng)

func species_weight_for_series(species_id:String,discovered:Dictionary)->float:
	var entry:=_species_entry(species_id)
	if entry.is_empty() or not _series_seed_eligible(entry):return 0.0
	var weight:=float(entry.get("series_seed_weight",entry.get("spawn_weight",0.0)))
	if bool(discovered.get(species_id,false)):weight*=maxf(0.0,setting_float("discovered_species_weight_multiplier"))
	return maxf(0.0,weight)

func choose_yen_amount(pod_rng:RandomNumberGenerator)->int:
	var rewards=settings.get("yen_rewards",[])
	if not rewards is Array or rewards.is_empty():return 1000
	var chosen:=_weighted_dictionary(rewards,"weight",pod_rng)
	return maxi(1000,int(chosen.get("amount",1000)))

func probability_text(unlocked_series:Dictionary,discovered:Dictionary)->String:
	var seed_weight:=maxf(0.0,setting_float("series_seed_weight"));var yen_weight:=maxf(0.0,setting_float("yen_weight"));var total:=seed_weight+yen_weight
	var eligible:=eligible_series(unlocked_series,discovered)
	var seed_rate:=0.0 if eligible.is_empty() or total<=0.0 else seed_weight/total*100.0
	var yen_rate:=100.0-seed_rate
	var lines:Array[String]=["1枠ごとの提供割合","シリーズ種　%.1f%%"%seed_rate,"ゲーム円　%.1f%%"%yen_rate]
	if not eligible.is_empty():lines.append("シリーズは開放済み図鑑から抽選（コンプ済みは重み×%.2f）"%setting_float("completed_series_weight_multiplier"))
	else:lines.append("対象シリーズがない時はゲーム円になります")
	lines.append("ゲーム円枠の内訳")
	var rewards=settings.get("yen_rewards",[]);var reward_total:=0.0
	for reward in rewards:reward_total+=maxf(0.0,float(reward.get("weight",0.0)))
	for reward in rewards:
		var rate:=0.0 if reward_total<=0.0 else maxf(0.0,float(reward.get("weight",0.0)))/reward_total*100.0
		lines.append("%s円　%.1f%%"%[_comma(int(reward.get("amount",1000))),rate])
	lines.append("シリーズ種は品種未確定。発芽時に品種を抽選します。")
	return "\n".join(lines)

func _series_seed_eligible(entry:Dictionary)->bool:
	if entry.has("series_seed_eligible"):return bool(entry.get("series_seed_eligible",false))
	if bool(entry.get("special_route_only",false)):return false
	if str(entry.get("rarity","")) in ["隠し原種","謎品種"]:return false
	return float(entry.get("series_seed_weight",entry.get("spawn_weight",0.0)))>0.0

func _series_entry(series_id:String)->Dictionary:
	for raw_series in series_catalog:
		if raw_series is Dictionary and str(raw_series.get("series_id",""))==series_id:return raw_series
	return {}

func _species_entry(species_id:String)->Dictionary:
	for raw_species in species_catalog:
		if raw_species is Dictionary and str(raw_species.get("species_id",""))==species_id:return raw_species
	return {}

func _weighted_dictionary(entries:Array,weight_key:String,pod_rng:RandomNumberGenerator)->Dictionary:
	if entries.is_empty():return {}
	var total:=0.0
	for entry in entries:total+=maxf(0.0,float(entry.get(weight_key,0.0)))
	if total<=0.0:return entries[0]
	var roll:=pod_rng.randf()*total
	for entry in entries:
		roll-=maxf(0.0,float(entry.get(weight_key,0.0)))
		if roll<=0.0:return entry
	return entries.back()

func _comma(value:int)->String:
	var source:=str(value);var output:=""
	for i in range(source.length()):
		if i>0 and (source.length()-i)%3==0:output+=","
		output+=source[i]
	return output
