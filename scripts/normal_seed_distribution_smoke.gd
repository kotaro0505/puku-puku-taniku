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
	_test_jurejure_collection_new_selection(game)
	_test_jurejure_story_phase_acquisition_gate(game)
	game.free();await get_tree().process_frame
	print("NORMAL_SEED_DISTRIBUTION_SMOKE_OK normal=uniform_0+1 fusion=0.5+0.1+0.03 five_star=0 guarantees=3+1 jure_new_share=50 unlocks=2+3+4")
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

func _test_jurejure_collection_new_selection(game:Node)->void:
	var jure_entries:Array[Dictionary]=game._series_species_entries("jurejure")
	assert(jure_entries.size()==10 and is_equal_approx(game.JUREJURE_COLLECTION_NORMAL_NEW_SHARE,.5))
	for entry in jure_entries:
		var species_id:=str(entry.get("species_id",""))
		game.discovered.erase(species_id);game.species_get_counts.erase(species_id)
		game.greenhouse_available.erase(species_id);game.unlocked_species.erase(species_id)
	game.jurejure_pool_unlocked=false;game.jurejure_species_unlocked.clear();game.unlocked_series.erase("jurejure")
	game.forest_gacha_encountered.clear()
	game.story_progression_state["exploitation_started"]=false;game.habitat_crisis_pending=false;game.habitat_crisis_started=false
	assert(not game._jurejure_collection_draw_active() and game._jurejure_collection_new_candidates().is_empty())
	game.story_progression_state["exploitation_started"]=true
	assert(game._jurejure_collection_draw_active() and game._jurejure_collection_new_candidates().size()==10)
	game.habitat_crisis_pending=true;assert(not game._jurejure_collection_draw_active());game.habitat_crisis_pending=false
	game.habitat_crisis_started=true;assert(not game._jurejure_collection_draw_active());game.habitat_crisis_started=false
	# Both legacy normal-NEW windows use the same post-NEW 50% selector while
	# their original absolute 3% and 1% windows remain untouched.
	var featured_unlocked:Dictionary=game._select_normal_seed_species(.0063,true,.1)
	assert(game._is_jurejure_species(featured_unlocked) and not bool(featured_unlocked.get("_deferred_series_get",false)))
	var ordinary_unlocked:Dictionary=game._select_normal_seed_species(.0063,true,.9)
	assert(str(ordinary_unlocked.get("species_id",""))=="shaviana")
	var featured_locked:Dictionary=game._select_normal_seed_species(.0363,true,.1)
	assert(game._is_jurejure_species(featured_locked) and not bool(featured_locked.get("_deferred_series_get",false)))
	var ordinary_locked:Dictionary=game._select_normal_seed_species(.0363,true,.9)
	assert(str(ordinary_locked.get("species_id",""))=="gummy_peach_milk" and bool(ordinary_locked.get("_deferred_series_get",false)))
	assert(game._select_collection_phase_new_candidate([],false,.9).is_empty())
	assert(game._is_jurejure_species(game._select_collection_phase_new_candidate([],false,.1)))
	# Fixed RNG verifies that a successful carryover NEW is split 50/50 after,
	# rather than before, its existing chance roll.
	var probability_rng:=RandomNumberGenerator.new();probability_rng.seed=2026101803;var probability_featured_count:=0
	for sample_index in range(NORMAL_SAMPLE_COUNT):
		if game._jurejure_collection_roll_selects_feature(probability_rng.randf()):probability_featured_count+=1
	var probability_ratio:=float(probability_featured_count)/NORMAL_SAMPLE_COUNT
	assert(probability_ratio>.499 and probability_ratio<.501,"normal NEW feature threshold ratio=%f"%probability_ratio)
	print("JUREJURE_NORMAL_NEW_DISTRIBUTION samples=%d featured=%.4f"%[NORMAL_SAMPLE_COUNT,probability_ratio])
	var sample_count:=5000;var featured_count:=0;var ordinary_count:=0;var featured_ids:Dictionary={};game.rng.seed=2026101804
	for entry in jure_entries:featured_ids[str(entry.get("species_id",""))]=true
	var jure_counts:Dictionary={}
	for sample_index in range(sample_count):
		var selected:Dictionary=game._select_endless_forced_new_candidate(game.rng.randf())
		var species_id:=str(selected.get("species_id",""))
		if featured_ids.has(species_id):
			featured_count+=1;jure_counts[species_id]=int(jure_counts.get(species_id,0))+1
		else:ordinary_count+=1
	var featured_ratio:=float(featured_count)/sample_count
	assert(featured_ratio>.48 and featured_ratio<.52,"normal NEW JureJure ratio=%f"%featured_ratio)
	assert(featured_count+ordinary_count==sample_count)
	for species_id in featured_ids:
		var candidate_ratio:=float(jure_counts.get(species_id,0))/featured_count
		assert(candidate_ratio>.075 and candidate_ratio<.125,"normal JureJure candidates not uniform: %s=%f"%[species_id,candidate_ratio])
	# A harvested-but-unconfirmed result and a live NEW plant are both excluded,
	# preventing duplicate NEW labels inside one round.
	var pending_id:=str(jure_entries[0].get("species_id",""));game.pending_round_new_species_ids.append(pending_id)
	assert(game._jurejure_collection_new_candidates().all(func(entry:Dictionary)->bool:return str(entry.get("species_id",""))!=pending_id))
	game.pending_round_new_species_ids.erase(pending_id)
	var active_id:=str(jure_entries[1].get("species_id",""));var active_plant=load("res://scripts/succulent.gd").new()
	active_plant.data=game._catalog_entry(active_id);active_plant.set_meta("new_species_candidate",true);game.plants.append(active_plant)
	assert(game._jurejure_collection_new_candidates().all(func(entry:Dictionary)->bool:return str(entry.get("species_id",""))!=active_id))
	game.plants.erase(active_plant);active_plant.free()
	# The eighth owned species, crisis transition, or a pre-Act-III save disables
	# the route immediately without a separate UI refresh.
	for index in range(8):game.species_get_counts[str(jure_entries[index].get("species_id",""))]=1
	assert(not game._jurejure_collection_draw_active() and game._jurejure_collection_new_candidates().is_empty())

func _test_jurejure_story_phase_acquisition_gate(game:Node)->void:
	game.discovered.clear();game.species_get_counts.clear();game.greenhouse_available.clear();game.unlocked_species.clear()
	game.unlocked_series={"base":true,"jurejure":true}
	game.pending_round_new_species_ids.clear();game.forest_gacha_encountered.clear()
	game.act2_unlocked=true;game.act3_unlocked=false;game.act3_intro_seen=false;game.act3_intro_pending=false
	game.story_progression_state=game.StoryProgressionClass.default_runtime_state()
	game.story_progression_state["fantasy_unlocked"]=true
	game.story_progression_state["fusion_lab_unlocked"]=true
	game.story_progression_state["exploitation_started"]=false
	game.habitat_crisis_pending=false;game.habitat_crisis_started=false

	var act2_ids:Array[String]=[]
	var jurejure_page_ids:Array[String]=[]
	var direct_jurejure_ids:Array[String]=[]
	for entry_value in game.catalog_species:
		if not entry_value is Dictionary:continue
		var entry:Dictionary=entry_value;var species_id:=str(entry.get("species_id",""))
		if game._is_jurejure_collection_species(entry):jurejure_page_ids.append(species_id)
		if game._is_jurejure_species(entry):direct_jurejure_ids.append(species_id)
		if not game._is_jurejure_collection_species(entry) and (bool(entry.get("main_story_original",false)) or game._is_fantasy_species(entry)):
			act2_ids.append(species_id)
	assert(jurejure_page_ids.size()==20 and direct_jurejure_ids.size()==10 and act2_ids.size()>=24)

	# Reproduce a fresh Act II 5/24 save while also injecting the stale unlock
	# flags seen in older formats. The flags must not become acquisition proof.
	for index in range(5):
		var species_id:=act2_ids[index]
		game.discovered[species_id]=true;game.species_get_counts[species_id]=1
		game.greenhouse_available[species_id]=true;game.unlocked_species[species_id]=true
	assert(game._unique_act2_species_get_count()==5)
	game.jurejure_pool_unlocked=true
	for species_id in direct_jurejure_ids:game.jurejure_species_unlocked[species_id]=true
	assert(not game._jurejure_acquisition_is_allowed())
	assert(not game._is_jurejure_species_unlocked(direct_jurejure_ids[0]))
	_assert_pre_exploitation_random_pools_exclude_jurejure(game,jurejure_page_ids)
	# The early one-time Armadillo series gift is another random grant route.
	# If every ordinary series is already open, it must not fall through to the
	# still-locked JureJure catalog page.
	for rule_value in game.catalog_progression.get("normal_series",[]):
		if rule_value is Dictionary and str(rule_value.get("series_id",""))!="jurejure":game.unlocked_series[str(rule_value.get("series_id",""))]=true
	game.unlocked_series.erase("jurejure")
	game.armadillo_gift_series_id="jurejure";game.armadillo_gift_species_id=direct_jurejure_ids[0]
	game._prepare_armadillo_series_gift()
	assert(game.armadillo_gift_series_id.is_empty() and game.armadillo_gift_species_id.is_empty())
	game.unlocked_series["jurejure"]=true
	var direct_id:=direct_jurejure_ids[0];var fusion_id:="hyb_sweets_jure"
	assert(not game._register_species_discovery(direct_id,true) and game._species_get_count(direct_id)==0)
	assert(not game._register_species_discovery(fusion_id,true) and game._species_get_count(fusion_id)==0)

	# A corrupt/old save can own a Jure parent, but the Lab must reject its Jure
	# result before charging currency or changing ownership.
	var sweets_parent:="sweets_strawberry_shortcake"
	game.species_get_counts[sweets_parent]=1;game.species_get_counts[direct_id]=1
	game.discovered[sweets_parent]=true;game.discovered[direct_id]=true
	game.greenhouse_available[sweets_parent]=true;game.greenhouse_available[direct_id]=true
	game.puku_points=20;var balance_before:int=game.puku_balance_units
	var blocked_resolution:Dictionary=game.fusion_system.resolve(sweets_parent,direct_id)
	assert(str(blocked_resolution.get("result_species_id",""))==fusion_id)
	game._perform_fusion(sweets_parent,direct_id)
	assert(game.puku_balance_units==balance_before and game._species_get_count(fusion_id)==0 and not game.fusion_in_progress)
	game.species_get_counts.erase(sweets_parent);game.discovered.erase(sweets_parent)
	game.greenhouse_available.erase(sweets_parent);game.unlocked_species.erase(sweets_parent)

	# Even 24/24 only queues Act III. Until the intro actually begins
	# exploitation, every acquisition path remains closed and crisis cannot start.
	for index in range(5,24):
		var species_id:=act2_ids[index]
		game.discovered[species_id]=true;game.species_get_counts[species_id]=1
		game.greenhouse_available[species_id]=true;game.unlocked_species[species_id]=true
	assert(game._unique_act2_species_get_count()==24)
	game._refresh_narrative_species_progress()
	assert(game.act3_unlocked and game.act3_intro_pending and not game._jurejure_acquisition_is_allowed())
	assert(not game.habitat_crisis_pending and not game.habitat_crisis_started)
	_assert_pre_exploitation_random_pools_exclude_jurejure(game,jurejure_page_ids)

	# Reload migration clears stale pool flags but preserves the already-owned
	# leaked card instead of corrupting or deleting player data.
	game.habitat_crisis_pending=true
	game.armadillo_gift_series_id="jurejure";game.armadillo_gift_species_id=direct_id
	game.StoryProgressionClass.queue_habitat_crisis_transition(game.story_progression_state,false)
	game._migrate_three_act_progress(game.PROGRESSION_VERSION)
	assert(not game.jurejure_pool_unlocked and game.jurejure_species_unlocked.is_empty())
	assert(game.armadillo_gift_series_id.is_empty() and game.armadillo_gift_species_id.is_empty())
	assert(game._species_get_count(direct_id)==1 and bool(game.discovered.get(direct_id,false)))
	assert(not game.habitat_crisis_pending and not game.jurejure_species_first_seen)
	_assert_pre_exploitation_random_pools_exclude_jurejure(game,jurejure_page_ids)

	# The same entries become eligible at the durable exploitation phase. A
	# legitimate Lab result then contributes to the shared eight-species count.
	game.story_progression_state["exploitation_started"]=true;game.act3_intro_seen=true;game.act3_intro_pending=false
	assert(game._unlock_jurejure_pool() and game._is_jurejure_species_unlocked(direct_jurejure_ids[1]))
	var no_featured:Array[String]=[]
	var gacha_post:Dictionary=game.forest_gacha_system._eligible_candidates_by_rank(true,game.jurejure_species_unlocked,{2:true,3:true,4:true},no_featured,true)
	for species_id in jurejure_page_ids:
		var entry:Dictionary=game._catalog_entry(species_id);var stars:int=SpeciesStarRarityClass.stars_for(entry)
		if stars>=2 and stars<=4:assert((gacha_post.get(stars,[]) as Array).any(func(candidate:Dictionary)->bool:return str(candidate.get("species_id",""))==species_id))
	var before_fusion_count:int=game._unique_jurejure_species_get_count()
	assert(game._register_species_discovery(fusion_id,true))
	assert(game._unique_jurejure_species_get_count()==before_fusion_count+1)
	game.habitat_crisis_pending=false;game.habitat_crisis_started=false
	for index in range(8):
		var species_id:=jurejure_page_ids[index]
		game.discovered[species_id]=true;game.species_get_counts[species_id]=maxi(1,game._species_get_count(species_id))
	game._refresh_narrative_species_progress()
	assert(game._unique_jurejure_species_get_count()>=8 and game.habitat_crisis_pending)
	var restoration:Dictionary=game._restoration_state();restoration["ending_seen"]=true;restoration["ending_phase"]="complete";game.story_progression_state["restoration"]=restoration
	assert(game._jurejure_acquisition_is_allowed() and not game._post_ending_normal_reward_candidates().is_empty())

func _assert_pre_exploitation_random_pools_exclude_jurejure(game:Node,jurejure_page_ids:Array[String])->void:
	var blocked_ids:Dictionary={}
	for species_id in jurejure_page_ids:blocked_ids[species_id]=true
	var normal_pools:Dictionary=game._normal_seed_selection_pools()
	for group_name in ["unlocked_new","locked_new","normal_known","all_known"]:
		for entry_value in normal_pools.get(group_name,[]):
			assert(entry_value is Dictionary and not blocked_ids.has(str(entry_value.get("species_id",""))),"normal seed leaked %s through %s"%[entry_value.get("species_id",""),group_name])
	for stars in [2,3,4]:
		for entry_value in (normal_pools.get("fusion_by_stars",{}).get(stars,[]) as Array):
			assert(entry_value is Dictionary and not blocked_ids.has(str(entry_value.get("species_id",""))),"normal seed rank %d leaked %s"%[stars,entry_value.get("species_id","")])
	var no_featured:Array[String]=[]
	var gacha_pools:Dictionary=game.forest_gacha_system._eligible_candidates_by_rank(true,game.jurejure_species_unlocked,{2:true,3:true,4:true},no_featured,false)
	for stars in [0,2,3,4]:
		for entry_value in (gacha_pools.get(stars,[]) as Array):
			assert(entry_value is Dictionary and not blocked_ids.has(str(entry_value.get("species_id",""))),"gacha rank %d leaked %s"%[stars,entry_value.get("species_id","")])
	for stars in [2,3,4]:
		for entry_value in game._battle_fusion_reward_candidates(stars):
			assert(not blocked_ids.has(str(entry_value.get("species_id",""))),"battle rank %d leaked %s"%[stars,entry_value.get("species_id","")])
	for entry_value in game._series_seed_draw_candidates("jurejure"):
		assert(not blocked_ids.has(str(entry_value.get("species_id",""))),"series seed leaked %s"%entry_value.get("species_id",""))
	for entry_value in game._jurejure_reward_candidates():
		assert(not blocked_ids.has(str(entry_value.get("species_id",""))),"battle reward leaked %s"%entry_value.get("species_id",""))
