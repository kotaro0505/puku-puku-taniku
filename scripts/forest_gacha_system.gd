class_name ForestGachaSystem
extends RefCounted

const SpeciesStarRarityClass=preload("res://scripts/species_star_rarity.gd")
const NEW_DRAW_RATE := 0.60
const NORMAL_RANK_RATE := 0.95
const TWO_STAR_RATE := 0.04
const THREE_STAR_RATE := 0.008
const FOUR_STAR_RATE := 0.002

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

func draw(unlocked_series:Dictionary,discovered:Dictionary,encountered:Dictionary,draw_rng:RandomNumberGenerator,creative_allowed:=true,jurejure_species_unlocked:Dictionary={},random_source_unlocks:Dictionary={},forced_rank_roll:float=-1.0)->Dictionary:
	var candidates_by_rank:=_eligible_candidates_by_rank(creative_allowed,jurejure_species_unlocked,random_source_unlocks)
	var selected_rank:=_roll_star_rank(draw_rng.randf() if forced_rank_roll<0.0 else forced_rank_roll)
	var rank_candidates:Array=candidates_by_rank.get(selected_rank,[])
	# A locked or empty fusion rank falls back only to the ordinary 95% pool.
	# It is never reassigned to another fusion rank, so completing a rank cannot
	# inflate any rarer result.
	if rank_candidates.is_empty():
		selected_rank=0
		rank_candidates=candidates_by_rank.get(0,[])
	if rank_candidates.is_empty():return {}
	var new_species:Array[Dictionary]=[]
	var duplicate_species:Array[Dictionary]=[]
	for candidate_species in rank_candidates:
		var candidate_species_id:=str(candidate_species.get("species_id",""))
		if bool(discovered.get(candidate_species_id,false)):duplicate_species.append(candidate_species)
		else:new_species.append(candidate_species)
	var target_pool:Array[Dictionary]
	if new_species.is_empty():target_pool=duplicate_species
	elif duplicate_species.is_empty():target_pool=new_species
	else:target_pool=new_species if draw_rng.randf()<NEW_DRAW_RATE else duplicate_species
	if target_pool.is_empty():return {}
	var species_entry:Dictionary=target_pool[draw_rng.randi_range(0,target_pool.size()-1)]
	var series_id:=str(species_entry.get("series_id",""))
	var series_entry:Dictionary=series_by_id.get(series_id,{})
	var series_was_unlocked:=str(series_entry.get("unlock_type","future"))=="default" or bool(unlocked_series.get(series_id,false))
	return {
		"source":"unlocked" if series_was_unlocked else "locked",
		"series_id":series_id,
		"series_name":str(series_entry.get("display_name","シリーズ")),
		"series_entry":series_entry.duplicate(true),
		"species_id":str(species_entry.get("species_id","")),
		"species_entry":species_entry.duplicate(true),
		"was_discovered":bool(discovered.get(str(species_entry.get("species_id","")),false)),
		"was_encountered":bool(encountered.get(str(species_entry.get("species_id","")),false)),
		"star_rating":SpeciesStarRarityClass.stars_for(species_entry),
	}

func _roll_star_rank(roll:float)->int:
	var normalized:=clampf(roll,0.0,.999999)
	if normalized<.950:return 0
	if normalized<.990:return 2
	if normalized<.998:return 3
	return 4

func _eligible_candidates_by_rank(creative_allowed:bool,jurejure_species_unlocked:Dictionary,random_source_unlocks:Dictionary)->Dictionary:
	var result:Dictionary={0:[],2:[],3:[],4:[]}
	# Preserve the established normal-series and route gates, but flatten the
	# resulting pool so every eligible zero/one-star species is equally likely.
	for series_entry in eligible_series(creative_allowed,jurejure_species_unlocked):
		var series_id:=str(series_entry.get("series_id",""))
		for entry in eligible_species(series_id,creative_allowed,jurejure_species_unlocked):
			if SpeciesStarRarityClass.stars_for(entry)<=1:(result[0] as Array).append(entry)
	if not creative_allowed:return result
	var effective_unlocks:=random_source_unlocks
	if effective_unlocks.is_empty():effective_unlocks={2:true,3:false,4:false}
	for species_value in species_by_id.values():
		if not species_value is Dictionary:continue
		var entry:Dictionary=species_value
		var stars:=SpeciesStarRarityClass.stars_for(entry)
		if stars<2 or stars>4 or not SpeciesStarRarityClass.random_source_unlocked(stars,effective_unlocks):continue
		(result[stars] as Array).append(entry)
	return result

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
