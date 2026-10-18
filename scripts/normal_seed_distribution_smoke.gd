extends Node

const SpeciesStarRarityClass=preload("res://scripts/species_star_rarity.gd")
const NORMAL_SAMPLE_COUNT:=1000000

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game.opening_story_complete=true;game._finish_opening();game.audio_manager.apply_settings({"bgm_enabled":false,"se_enabled":false})
	_prepare_full_random_unlocks(game)
	_test_exact_windows(game)
	_test_unlock_gates(game)
	_test_fixed_rng_distribution(game)
	_test_uniform_normal_species(game)
	_test_fusion_acquisition_does_not_leak(game)
	_test_route_exclusions_and_spawn_weight(game)
	game.free();await get_tree().process_frame
	print("NORMAL_SEED_DISTRIBUTION_SMOKE_OK normal=uniform_0+1 fusion=0.5+0.1+0.03 five_star=0 guarantees=3+1 unlocks=2+3+4")
	get_tree().quit()

func _prepare_full_random_unlocks(game:Node)->void:
	game.act2_unlocked=true
	game.act3_unlocked=true
	game.story_progression_state["fantasy_unlocked"]=true
	game.story_progression_state["fusion_lab_unlocked"]=true
	game.fantasy_realization_seen=true
	game.pending_round_new_species_ids.clear()
	game.discovered.clear();game.species_get_counts.clear();game.greenhouse_available.clear();game.unlocked_species.clear()
	game.unlocked_series={"base":true}
	# Keep exactly one unlocked and one locked ordinary NEW candidate so the old
	# 3% + 1% windows can be checked independently of the fusion windows.
	for entry_value in game.catalog_species:
		if not entry_value is Dictionary:continue
		var entry:Dictionary=entry_value;var species_id:=str(entry.get("species_id",""))
		if SpeciesStarRarityClass.stars_for(entry)>1:continue
		if species_id in ["shaviana","gummy_peach_milk"]:continue
		game.discovered[species_id]=true;game.species_get_counts[species_id]=1
		game.greenhouse_available[species_id]=true;game.unlocked_species[species_id]=true
	game.forest_gacha_encountered.clear();game.rng.seed=20261018

func _test_exact_windows(game:Node)->void:
	assert(is_equal_approx(game.NORMAL_SEED_TWO_STAR_RATE,.005))
	assert(is_equal_approx(game.NORMAL_SEED_THREE_STAR_RATE,.001))
	assert(is_equal_approx(game.NORMAL_SEED_FOUR_STAR_RATE,.0003))
	assert(is_equal_approx(game.NORMAL_SEED_FUSION_TOTAL_RATE,.0063))
	assert(game._normal_seed_fusion_rank_for_roll(0.0)==2)
	assert(game._normal_seed_fusion_rank_for_roll(.004999)==2)
	assert(game._normal_seed_fusion_rank_for_roll(.005)==3)
	assert(game._normal_seed_fusion_rank_for_roll(.005999)==3)
	assert(game._normal_seed_fusion_rank_for_roll(.006)==4)
	assert(game._normal_seed_fusion_rank_for_roll(.006299)==4)
	assert(game._normal_seed_fusion_rank_for_roll(.0063)==0)
	assert(SpeciesStarRarityClass.stars_for(game._select_normal_seed_species(.004,false))==2)
	assert(SpeciesStarRarityClass.stars_for(game._select_normal_seed_species(.0055,false))==3)
	assert(SpeciesStarRarityClass.stars_for(game._select_normal_seed_species(.0061,false))==4)
	assert(str(game._select_normal_seed_species(.0063,true).get("species_id",""))=="shaviana")
	assert(str(game._select_normal_seed_species(.036299,true).get("species_id",""))=="shaviana")
	var locked:Dictionary=game._select_normal_seed_species(.0363,true)
	assert(str(locked.get("species_id",""))=="gummy_peach_milk" and bool(locked.get("_deferred_series_get",false)))
	assert(game._register_deferred_seed_get("gummy_peach_milk"))
	assert(not bool(game.discovered.get("gummy_peach_milk",false)) and not bool(game.unlocked_series.get("gummy",false)))
	assert(SpeciesStarRarityClass.stars_for(game._select_normal_seed_species(.0463,true))<=1)

func _test_unlock_gates(game:Node)->void:
	game.story_progression_state["fantasy_unlocked"]=false
	game.story_progression_state["fusion_lab_unlocked"]=false
	game.act3_unlocked=false
	for roll in [.001,.0055,.0061]:assert(SpeciesStarRarityClass.stars_for(game._select_normal_seed_species(roll,false))<=1)
	game.story_progression_state["fantasy_unlocked"]=true
	assert(SpeciesStarRarityClass.stars_for(game._select_normal_seed_species(.001,false))==2)
	assert(SpeciesStarRarityClass.stars_for(game._select_normal_seed_species(.0055,false))<=1)
	game.story_progression_state["fusion_lab_unlocked"]=true
	assert(SpeciesStarRarityClass.stars_for(game._select_normal_seed_species(.0055,false))==3)
	assert(SpeciesStarRarityClass.stars_for(game._select_normal_seed_species(.0061,false))<=1)
	game.act3_unlocked=true
	assert(SpeciesStarRarityClass.stars_for(game._select_normal_seed_species(.0061,false))==4)

func _test_fixed_rng_distribution(game:Node)->void:
	var test_rng:=RandomNumberGenerator.new();test_rng.seed=20261018
	var counts:Dictionary={0:0,2:0,3:0,4:0}
	for sample_index in range(NORMAL_SAMPLE_COUNT):
		var stars:int=int(game._normal_seed_fusion_rank_for_roll(test_rng.randf()))
		counts[stars]=int(counts.get(stars,0))+1
	var two_ratio:=float(counts[2])/NORMAL_SAMPLE_COUNT
	var three_ratio:=float(counts[3])/NORMAL_SAMPLE_COUNT
	var four_ratio:=float(counts[4])/NORMAL_SAMPLE_COUNT
	assert(two_ratio>.00475 and two_ratio<.00525,"two-star ratio=%f"%two_ratio)
	assert(three_ratio>.00087 and three_ratio<.00113,"three-star ratio=%f"%three_ratio)
	assert(four_ratio>.00024 and four_ratio<.00036,"four-star ratio=%f"%four_ratio)
	assert(int(counts.get(5,0))==0 and counts.values().reduce(func(sum,value):return int(sum)+int(value),0)==NORMAL_SAMPLE_COUNT)

func _test_uniform_normal_species(game:Node)->void:
	var ids:=["colorata","shaviana","lutea","purpusorum"]
	var pool:Array=[]
	for species_id in ids:
		var entry:Dictionary=game._catalog_entry(species_id)
		assert(not entry.is_empty() and SpeciesStarRarityClass.stars_for(entry)<=1)
		pool.append(entry)
	var counts:Dictionary={}
	game.rng.seed=20261019
	for sample_index in range(40000):
		var species_id:=str(game._uniform_normal_seed_fallback(pool).get("species_id",""))
		counts[species_id]=int(counts.get(species_id,0))+1
	for species_id in ids:
		var ratio:=float(counts.get(species_id,0))/40000.0
		assert(ratio>.24 and ratio<.26,"normal species must be uniform: %s=%f"%[species_id,ratio])
	var zero_total:=int(counts.get("colorata",0))+int(counts.get("shaviana",0))
	var one_total:=int(counts.get("lutea",0))+int(counts.get("purpusorum",0))
	assert(absf(float(zero_total-one_total)/40000.0)<.015)

func _test_fusion_acquisition_does_not_leak(game:Node)->void:
	var fusion_entry:Dictionary=game._series_species_entries("hybrid")[0]
	var fusion_id:=str(fusion_entry.get("species_id",""))
	game.discovered[fusion_id]=true;game.species_get_counts[fusion_id]=1;game.greenhouse_available[fusion_id]=true
	if not game.species.any(func(entry:Dictionary)->bool:return str(entry.get("species_id",""))==fusion_id):game.species.append(fusion_entry)
	game.rng.seed=20261020
	for sample_index in range(1000):
		assert(SpeciesStarRarityClass.stars_for(game._select_normal_seed_species(.5,false))<=1)
		assert(SpeciesStarRarityClass.stars_for(game._select_species_for_seed("volume",.5))<=1)
		assert(SpeciesStarRarityClass.stars_for(game._select_species_for_seed("premium",.5))<=1)
	assert(SpeciesStarRarityClass.stars_for(game._select_normal_seed_species(.001,false))==2)
	for entry_value in game.catalog_species:
		if entry_value is Dictionary and SpeciesStarRarityClass.stars_for(entry_value)==5:
			assert(str(entry_value.get("series_id",""))=="fusion_tier3")

func _test_route_exclusions_and_spawn_weight(game:Node)->void:
	var pool_ids:Array[String]=[]
	for entry_value in game._normal_seed_selection_pools().get("all_known",[]):
		if entry_value is Dictionary:pool_ids.append(str(entry_value.get("species_id","")))
	assert("transparent_succulent" not in pool_ids)
	assert("jurejure_pure_gold" not in pool_ids)
	var entry:Dictionary=game._catalog_entry("colorata").duplicate(true)
	entry["catalog_only"]=true;entry["spawn_weight"]=.35;entry["unlocked_spawn_weight"]=99.0
	game.discovered.erase("colorata")
	var before_get:float=game._normal_spawn_weight(entry)
	game.discovered["colorata"]=true
	var after_get:float=game._normal_spawn_weight(entry)
	assert(is_equal_approx(before_get,.35) and is_equal_approx(after_get,before_get))
