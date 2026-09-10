class_name ForestGachaSystem
extends RefCounted

const LOCKED_SERIES_CHANCE := 0.18
const GUARANTEED_UNLOCKED_DRAWS := 5

var series_by_id:Dictionary={}
var species_by_id:Dictionary={}
var normal_series_ids:Dictionary={"base":true}

func configure(series_catalog:Array,species_catalog:Array,catalog_progression:Dictionary)->void:
	series_by_id.clear();species_by_id.clear();normal_series_ids={"base":true}
	for raw_series in series_catalog:
		if raw_series is Dictionary:
			var series_id:=str(raw_series.get("series_id",""))
			if not series_id.is_empty():
				series_by_id[series_id]=raw_series
				if str(raw_series.get("unlock_type","future"))=="default":normal_series_ids[series_id]=true
	for raw_species in species_catalog:
		if raw_species is Dictionary:
			var species_id:=str(raw_species.get("species_id",""))
			if not species_id.is_empty():species_by_id[species_id]=raw_species
	for raw_rule in catalog_progression.get("normal_series",[]):
		if raw_rule is Dictionary:
			var series_id:=str(raw_rule.get("series_id",""))
			if not series_id.is_empty():normal_series_ids[series_id]=true

func draw(draw_number:int,unlocked_series:Dictionary,discovered:Dictionary,encountered:Dictionary,draw_rng:RandomNumberGenerator,forced_locked_roll:float=-1.0)->Dictionary:
	var unlocked_candidates:=eligible_series(true,unlocked_series)
	var locked_candidates:=eligible_series(false,unlocked_series)
	if unlocked_candidates.is_empty() and locked_candidates.is_empty():return {}
	var locked_roll:=forced_locked_roll if forced_locked_roll>=0.0 else draw_rng.randf()
	var use_locked:=draw_number>GUARANTEED_UNLOCKED_DRAWS and not locked_candidates.is_empty() and (unlocked_candidates.is_empty() or locked_roll<LOCKED_SERIES_CHANCE)
	var series_candidates:=locked_candidates if use_locked else unlocked_candidates
	if series_candidates.is_empty():series_candidates=locked_candidates
	var series_entry:Dictionary=series_candidates[draw_rng.randi_range(0,series_candidates.size()-1)]
	var series_id:=str(series_entry.get("series_id",""))
	var species_candidates:=eligible_species(series_id)
	var preferred:Array[Dictionary]=[]
	for species_entry in species_candidates:
		var species_id:=str(species_entry.get("species_id",""))
		var already_seen:=bool(encountered.get(species_id,false)) if use_locked else bool(discovered.get(species_id,false))
		if not already_seen:preferred.append(species_entry)
	if not preferred.is_empty():species_candidates=preferred
	if species_candidates.is_empty():return {}
	var species_entry:Dictionary=species_candidates[draw_rng.randi_range(0,species_candidates.size()-1)]
	return {
		"source":"locked" if use_locked else "unlocked",
		"series_id":series_id,
		"series_name":str(series_entry.get("display_name","シリーズ")),
		"series_entry":series_entry.duplicate(true),
		"species_id":str(species_entry.get("species_id","")),
		"species_entry":species_entry.duplicate(true),
		"was_discovered":bool(discovered.get(str(species_entry.get("species_id","")),false)),
		"was_encountered":bool(encountered.get(str(species_entry.get("species_id","")),false))
	}

func eligible_series(want_unlocked:bool,unlocked_series:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for series_id_value in normal_series_ids:
		var series_id:=str(series_id_value)
		var entry:Dictionary=series_by_id.get(series_id,{})
		if entry.is_empty() or eligible_species(series_id).is_empty():continue
		var is_unlocked:=str(entry.get("unlock_type","future"))=="default" or bool(unlocked_series.get(series_id,false))
		if is_unlocked==want_unlocked:result.append(entry)
	return result

func eligible_species(series_id:String)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var series_entry:Dictionary=series_by_id.get(series_id,{})
	for species_id_value in series_entry.get("species_ids",[]):
		var entry:Dictionary=species_by_id.get(str(species_id_value),{})
		if entry.is_empty() or bool(entry.get("special_route_only",false)):continue
		if str(entry.get("rarity","")) in ["隠し原種","謎品種"]:continue
		result.append(entry)
	return result
