class_name ForestGachaSystem
extends RefCounted

const NEW_DRAW_RATE := 0.60

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

func draw(unlocked_series:Dictionary,discovered:Dictionary,encountered:Dictionary,draw_rng:RandomNumberGenerator,creative_allowed:=true,jurejure_species_unlocked:Dictionary={})->Dictionary:
	var series_candidates:=eligible_series(creative_allowed,jurejure_species_unlocked)
	if series_candidates.is_empty():return {}
	# Decide NEW versus duplicate before choosing the series/species.  Keeping a
	# per-series pool preserves the gacha's even series weighting inside the
	# selected category while making ownership -- not an encounter silhouette --
	# the only definition of NEW.
	var new_series_pools:Array[Dictionary]=[]
	var duplicate_series_pools:Array[Dictionary]=[]
	for candidate_series in series_candidates:
		var candidate_series_id:=str(candidate_series.get("series_id",""))
		var new_species:Array[Dictionary]=[]
		var duplicate_species:Array[Dictionary]=[]
		for candidate_species in eligible_species(candidate_series_id,creative_allowed,jurejure_species_unlocked):
			var candidate_species_id:=str(candidate_species.get("species_id",""))
			if bool(discovered.get(candidate_species_id,false)):duplicate_species.append(candidate_species)
			else:new_species.append(candidate_species)
		if not new_species.is_empty():new_series_pools.append({"series_entry":candidate_series,"species":new_species})
		if not duplicate_species.is_empty():duplicate_series_pools.append({"series_entry":candidate_series,"species":duplicate_species})
	var selected_pools:Array[Dictionary]
	if new_series_pools.is_empty():selected_pools=duplicate_series_pools
	elif duplicate_series_pools.is_empty():selected_pools=new_series_pools
	else:selected_pools=new_series_pools if draw_rng.randf()<NEW_DRAW_RATE else duplicate_series_pools
	if selected_pools.is_empty():return {}
	var selected_pool:Dictionary=selected_pools[draw_rng.randi_range(0,selected_pools.size()-1)]
	var series_entry:Dictionary=selected_pool.get("series_entry",{})
	var series_id:=str(series_entry.get("series_id",""))
	var series_was_unlocked:=str(series_entry.get("unlock_type","future"))=="default" or bool(unlocked_series.get(series_id,false))
	var species_candidates:Array=selected_pool.get("species",[])
	if species_candidates.is_empty():return {}
	var species_entry:Dictionary=species_candidates[draw_rng.randi_range(0,species_candidates.size()-1)]
	return {
		"source":"unlocked" if series_was_unlocked else "locked",
		"series_id":series_id,
		"series_name":str(series_entry.get("display_name","シリーズ")),
		"series_entry":series_entry.duplicate(true),
		"species_id":str(species_entry.get("species_id","")),
		"species_entry":species_entry.duplicate(true),
		"was_discovered":bool(discovered.get(str(species_entry.get("species_id","")),false)),
		"was_encountered":bool(encountered.get(str(species_entry.get("species_id","")),false))
	}

func eligible_series(creative_allowed:=true,jurejure_species_unlocked:Dictionary={})->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for series_id_value in normal_series_ids:
		var series_id:=str(series_id_value)
		var entry:Dictionary=series_by_id.get(series_id,{})
		if entry.is_empty() or eligible_species(series_id,creative_allowed,jurejure_species_unlocked).is_empty():continue
		result.append(entry)
	return result

func eligible_species(series_id:String,creative_allowed:=true,jurejure_species_unlocked:Dictionary={})->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var series_entry:Dictionary=series_by_id.get(series_id,{})
	for species_id_value in series_entry.get("species_ids",[]):
		var entry:Dictionary=species_by_id.get(str(species_id_value),{})
		if entry.is_empty():continue
		if str(entry.get("story_group","")).to_lower()=="jurejure" and not bool(jurejure_species_unlocked.get(str(entry.get("species_id","")),false)):continue
		if not creative_allowed and not bool(entry.get("main_story_original",false)):continue
		if str(entry.get("rarity","")) in ["隠し原種","謎品種"]:continue
		result.append(entry)
	return result
