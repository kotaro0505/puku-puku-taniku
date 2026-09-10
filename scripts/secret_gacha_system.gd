class_name SecretGachaSystem
extends RefCounted

var config:Dictionary={}
var species_by_id:Dictionary={}
var series_by_id:Dictionary={}
var series_for_species:Dictionary={}
var pots:Array=[]
var hidden_series_ids:Array[String]=[]

func load_config()->void:
	var parsed=JSON.parse_string(FileAccess.get_file_as_string("res://data/secret-gacha.json"))
	config=parsed if parsed is Dictionary else {}

func configure(series_catalog:Array,species_catalog:Array,pot_catalog:Array,catalog_progression:Dictionary)->void:
	species_by_id.clear();series_by_id.clear();series_for_species.clear();pots=pot_catalog.duplicate(true);hidden_series_ids.clear()
	for raw_series in series_catalog:
		if not raw_series is Dictionary:continue
		var series_id:=str(raw_series.get("series_id",""));series_by_id[series_id]=raw_series
		for species_id_value in raw_series.get("species_ids",[]):series_for_species[str(species_id_value)]=series_id
	for raw_species in species_catalog:
		if raw_species is Dictionary:species_by_id[str(raw_species.get("species_id",""))]=raw_species
	for rule in catalog_progression.get("hidden_series",[]):
		if rule is Dictionary:hidden_series_ids.append(str(rule.get("series_id","")))

func should_activate(formal_play_count:int,habitat_tutorial_complete:bool,draw_rng:RandomNumberGenerator,forced_roll:float=-1.0)->bool:
	if not habitat_tutorial_complete or formal_play_count<int(config.get("minimum_formal_play_count",5)):return false
	var roll:=forced_roll if forced_roll>=0.0 else draw_rng.randf()
	return roll<float(config.get("activation_chance_per_formal_play",.012))

func draw(unlocked_series:Dictionary,discovered:Dictionary,owned_pots:Dictionary,draw_rng:RandomNumberGenerator,forced_category:String="")->Dictionary:
	var category:=forced_category if forced_category in ["species","pot","catalog_page"] else _weighted_category(draw_rng)
	var result:=_draw_category(category,unlocked_series,discovered,owned_pots,draw_rng)
	if not result.is_empty():return result
	for fallback in ["species","pot","catalog_page"]:
		result=_draw_category(fallback,unlocked_series,discovered,owned_pots,draw_rng)
		if not result.is_empty():return result
	return {}

func _weighted_category(draw_rng:RandomNumberGenerator)->String:
	var weights:Dictionary=config.get("category_weights",{})
	var roll:=draw_rng.randf()*maxf(.0001,float(weights.get("species",.55))+float(weights.get("pot",.25))+float(weights.get("catalog_page",.20)))
	for category in ["species","pot","catalog_page"]:
		roll-=float(weights.get(category,0.0))
		if roll<=0.0:return category
	return "species"

func _draw_category(category:String,unlocked_series:Dictionary,discovered:Dictionary,owned_pots:Dictionary,draw_rng:RandomNumberGenerator)->Dictionary:
	match category:
		"species":
			var candidates:Array[Dictionary]=[];var preferred:Array[Dictionary]=[]
			for species_id_value in species_by_id:
				var entry:Dictionary=species_by_id[species_id_value];var species_id:=str(species_id_value)
				if int(entry.get("gold_star_count",0))<=0 or bool(entry.get("special_route_only",false)):continue
				candidates.append(entry)
				if not bool(discovered.get(species_id,false)):preferred.append(entry)
			if not preferred.is_empty():candidates=preferred
			if candidates.is_empty():return {}
			var chosen:Dictionary=candidates[draw_rng.randi_range(0,candidates.size()-1)]
			return {"category":"species","species_id":str(chosen.get("species_id","")),"species_entry":chosen.duplicate(true),"was_discovered":bool(discovered.get(str(chosen.get("species_id","")),false))}
		"pot":
			var candidates:Array[Dictionary]=[]
			for raw_pot in pots:
				if raw_pot is Dictionary and not bool(owned_pots.get(str(raw_pot.get("pot_id","")),false)):candidates.append(raw_pot)
			if candidates.is_empty():return {}
			var chosen:Dictionary=candidates[draw_rng.randi_range(0,candidates.size()-1)]
			return {"category":"pot","pot_id":str(chosen.get("pot_id","")),"pot_entry":chosen.duplicate(true),"image_path":str(chosen.get("image_path",""))}
		"catalog_page":
			var candidates:Array[String]=[]
			for series_id in hidden_series_ids:
				if not bool(unlocked_series.get(series_id,false)):candidates.append(series_id)
			if candidates.is_empty():return {}
			var chosen:=candidates[draw_rng.randi_range(0,candidates.size()-1)];var series:Dictionary=series_by_id.get(chosen,{})
			return {"category":"catalog_page","series_id":chosen,"series_entry":series.duplicate(true),"image_path":str(series.get("cover_image_path",""))}
	return {}

func setting_int(key:String,fallback:int)->int:return int(config.get(key,fallback))
func setting_float(key:String,fallback:float)->float:return float(config.get(key,fallback))
