extends Node

const SpeciesStarRarityClass=preload("res://scripts/species_star_rarity.gd")
const BattleClass=preload("res://scripts/puku_puku_battle.gd")
const BATTLE_SAMPLE_COUNT:=1000000
const DIFFICULTY_SAMPLE_COUNT:=300000

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled":false,"se_enabled":false})
	_test_complete_assignment(game)
	await _test_catalog_star_layout(game)
	await _test_get_card_star_layout(game)
	_test_battle_bonus(game)
	game.queue_free();await get_tree().process_frame
	print("SPECIES_RARITY_SMOKE_OK assignment=64+64+66+22+21+5 catalog=list+detail get_card=flat_gold battle=L1:5+1+0.3,L2:10+3+1,L3:15+6+2 main_phase_odds=70/30/0,50/50/0,40/30/30 five_star=fusion_only")
	get_tree().quit()

func _test_complete_assignment(game:Node)->void:
	assert(game.catalog_species.size()==242)
	assert(SpeciesStarRarityClass.NORMAL_ONE_STAR_IDS.size()==64)
	var counts:Dictionary={0:0,1:0,2:0,3:0,4:0,5:0};var ids:Dictionary={}
	for entry_value in game.catalog_species:
		assert(entry_value is Dictionary)
		var entry:Dictionary=entry_value;var species_id:=str(entry.get("species_id",""));var stars:=SpeciesStarRarityClass.stars_for(entry)
		assert(not species_id.is_empty() and not ids.has(species_id));ids[species_id]=true
		assert(int(entry.get("star_rating",-1))==stars and int(entry.get("gold_star_count",-1))==stars)
		counts[stars]=int(counts.get(stars,0))+1
		if stars==5:assert(str(entry.get("series_id",""))=="fusion_tier3")
	assert(counts=={0:64,1:64,2:66,3:22,4:21,5:5})

func _test_catalog_star_layout(game:Node)->void:
	var entries:Array[Dictionary]=game._series_species_entries("fusion_tier3")
	assert(entries.size()==5)
	game.discovered.clear();game.species_get_counts.clear()
	var acquired:Dictionary=entries[1];var display_series_id:String=str(game._catalog_display_series_id_for_entry(acquired))
	var discovered_only:Dictionary={}
	for candidate_value in game.catalog_species:
		if not candidate_value is Dictionary:continue
		var candidate:Dictionary=candidate_value
		if game._catalog_display_series_id_for_entry(candidate)==display_series_id and SpeciesStarRarityClass.stars_for(candidate)>0 and str(candidate.get("species_id",""))!=str(acquired.get("species_id","")):
			discovered_only=candidate;break
	assert(not discovered_only.is_empty())
	var acquired_id:=str(acquired.get("species_id",""));var discovered_only_id:=str(discovered_only.get("species_id",""))
	game.discovered[acquired_id]=true;game.species_get_counts[acquired_id]=3
	# A discovered-but-not-GET legacy state must not leak its rank.
	game.discovered[discovered_only_id]=true;game.species_get_counts.erase(discovered_only_id)
	game.encyclopedia_overlay.visible=true;game.encyclopedia_list_page.visible=true;game.encyclopedia_detail_page.visible=false
	game.current_encyclopedia_series_id=display_series_id;game._refresh_encyclopedia_cards()
	await get_tree().process_frame;await get_tree().process_frame
	var card_stars:Array[Node]=game.encyclopedia_grid.find_children("SpeciesCardStars","Label",true,false)
	assert(card_stars.size()>=2)
	var visible_star_labels:Array=[]
	for node in card_stars:
		var label:=node as Label
		if label.visible:visible_star_labels.append(label)
	assert(visible_star_labels.size()==1)
	var list_star:=visible_star_labels[0] as Label
	assert(list_star.text=="★★★★★" and list_star.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER)
	assert(list_star.get_theme_color("font_color").is_equal_approx(SpeciesStarRarityClass.STAR_COLOR))
	assert(not list_star.has_theme_constant_override("outline_size"))
	var list_get:=list_star.get_parent().find_child("SpeciesCardGetCount",false,false) as Label
	assert(list_get!=null and list_star.get_index()==list_get.get_index()+1)
	var list_card:=list_star.get_parent().get_parent() as Control
	assert(list_star.position.y>=list_get.position.y+list_get.size.y-1.0)
	assert(list_star.global_position.y+list_star.size.y<=list_card.global_position.y+list_card.size.y+1.0)
	game._open_species_detail(acquired);await get_tree().process_frame;await get_tree().process_frame
	var detail_get:=game.encyclopedia_detail_page.find_child("SpeciesGetCount",true,false) as Label
	var detail_star:=game.encyclopedia_detail_page.find_child("SpeciesDetailStars",true,false) as Label
	assert(detail_get!=null and detail_star!=null and detail_star.visible and detail_star.text=="★★★★★")
	assert(detail_star.get_parent()==detail_get.get_parent() and detail_star.get_index()==detail_get.get_index()+1)
	assert(detail_star.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER and detail_star.get_theme_color("font_color").is_equal_approx(SpeciesStarRarityClass.STAR_COLOR))
	assert(not detail_star.has_theme_constant_override("outline_size"))
	game.discovered["colorata"]=true;game.species_get_counts["colorata"]=1
	game._open_species_detail(game._catalog_entry("colorata"));await get_tree().process_frame
	detail_star=game.encyclopedia_detail_page.find_child("SpeciesDetailStars",true,false) as Label
	assert(detail_star!=null and not detail_star.visible and detail_star.text.is_empty())

func _test_get_card_star_layout(game:Node)->void:
	var overlay=game.species_get_overlay
	var five_star_entry:Dictionary=game._series_species_entries("fusion_tier3")[0]
	for language in ["ja","hiragana","en"]:
		overlay.show_species(five_star_entry,game._species_texture(five_star_entry),true,"fusion_lab",language,game._species_get_catalog_page_name(five_star_entry,language))
		await get_tree().process_frame;await get_tree().process_frame
		assert(overlay.star_label.visible and overlay.star_label.text=="★★★★★")
		assert(overlay.star_label.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER)
		assert(overlay.star_label.get_theme_color("font_color").is_equal_approx(SpeciesStarRarityClass.STAR_COLOR))
		assert(not overlay.star_label.has_theme_constant_override("outline_size"))
		assert(overlay.star_label.get_index()==overlay.series_label.get_index()+1)
		assert(overlay.hint_label.get_index()==overlay.star_label.get_index()+1)
		assert(await _wait_until(func()->bool:return not overlay.busy,1200))
		assert(overlay.star_label.global_position.y>=overlay.series_label.global_position.y+overlay.series_label.size.y-1.0)
		assert(overlay.hint_label.global_position.y>=overlay.star_label.global_position.y+overlay.star_label.size.y-1.0)
		assert(overlay.hint_label.global_position.y+overlay.hint_label.size.y<=overlay.card.global_position.y+overlay.card.size.y+1.0)
		overlay.visible=false;overlay.result_image.texture=null
	var zero_star_entry:Dictionary=game._catalog_entry("colorata")
	overlay.show_species(zero_star_entry,game._species_texture(zero_star_entry),true,"round_result_new","ja",game._species_get_catalog_page_name(zero_star_entry,"ja"))
	await get_tree().process_frame;await get_tree().process_frame
	assert(not overlay.star_label.visible and overlay.star_label.text.is_empty())
	assert(overlay.hint_label.global_position.y>overlay.series_label.global_position.y)
	assert(await _wait_until(func()->bool:return not overlay.busy,1200))
	overlay.visible=false;overlay.result_image.texture=null

func _test_battle_bonus(game:Node)->void:
	assert(is_equal_approx(game.BATTLE_TWO_STAR_REWARD_RATE,.05))
	assert(is_equal_approx(game.BATTLE_THREE_STAR_REWARD_RATE,.01))
	assert(is_equal_approx(game.BATTLE_FOUR_STAR_REWARD_RATE,.003))
	assert(game._battle_fusion_reward_rank_for_roll(.049999)==2)
	assert(game._battle_fusion_reward_rank_for_roll(.05)==3)
	assert(game._battle_fusion_reward_rank_for_roll(.059999)==3)
	assert(game._battle_fusion_reward_rank_for_roll(.06)==4)
	assert(game._battle_fusion_reward_rank_for_roll(.062999)==4)
	assert(game._battle_fusion_reward_rank_for_roll(.063)==0)
	assert(game._battle_fusion_reward_rank_for_roll(.099999,BattleClass.DIFFICULTY_STRONG)==2)
	assert(game._battle_fusion_reward_rank_for_roll(.10,BattleClass.DIFFICULTY_STRONG)==3)
	assert(game._battle_fusion_reward_rank_for_roll(.129999,BattleClass.DIFFICULTY_STRONG)==3)
	assert(game._battle_fusion_reward_rank_for_roll(.13,BattleClass.DIFFICULTY_STRONG)==4)
	assert(game._battle_fusion_reward_rank_for_roll(.139999,BattleClass.DIFFICULTY_STRONG)==4)
	assert(game._battle_fusion_reward_rank_for_roll(.14,BattleClass.DIFFICULTY_STRONG)==0)
	assert(game._battle_fusion_reward_rank_for_roll(.149999,BattleClass.DIFFICULTY_STRONGEST)==2)
	assert(game._battle_fusion_reward_rank_for_roll(.15,BattleClass.DIFFICULTY_STRONGEST)==3)
	assert(game._battle_fusion_reward_rank_for_roll(.209999,BattleClass.DIFFICULTY_STRONGEST)==3)
	assert(game._battle_fusion_reward_rank_for_roll(.21,BattleClass.DIFFICULTY_STRONGEST)==4)
	assert(game._battle_fusion_reward_rank_for_roll(.229999,BattleClass.DIFFICULTY_STRONGEST)==4)
	assert(game._battle_fusion_reward_rank_for_roll(.23,BattleClass.DIFFICULTY_STRONGEST)==0)
	var expected_rates:={
		BattleClass.DIFFICULTY_NORMAL:{2:.05,3:.01,4:.003},
		BattleClass.DIFFICULTY_STRONG:{2:.10,3:.03,4:.01},
		BattleClass.DIFFICULTY_STRONGEST:{2:.15,3:.06,4:.02}
	}
	for difficulty in expected_rates:
		var test_rng:=RandomNumberGenerator.new();test_rng.seed=20261022+int(difficulty)*100
		var counts:Dictionary={0:0,2:0,3:0,4:0,5:0}
		for sample_index in range(BATTLE_SAMPLE_COUNT):
			var stars:int=int(game._battle_fusion_reward_rank_for_roll(test_rng.randf(),int(difficulty)));counts[stars]=int(counts.get(stars,0))+1
		for stars in [2,3,4]:
			assert(absf(_ratio(int(counts[stars]))-float(expected_rates[difficulty][stars]))<.001)
		assert(int(counts[5])==0)
	game.story_progression_state["exploitation_started"]=false
	var restoration:Dictionary=game._restoration_state();restoration["ending_seen"]=false;restoration["ending_phase"]="";game.story_progression_state["restoration"]=restoration
	assert(game._jurejure_battle_difficulty_phase()==BattleClass.PHASE_EARLY)
	assert(game._draw_jurejure_battle_difficulty(.69)==BattleClass.DIFFICULTY_NORMAL)
	assert(game._draw_jurejure_battle_difficulty(.71)==BattleClass.DIFFICULTY_STRONG)
	game.story_progression_state["exploitation_started"]=true
	assert(game._jurejure_battle_difficulty_phase()==BattleClass.PHASE_EXPLOITATION)
	assert(game._draw_jurejure_battle_difficulty(.49)==BattleClass.DIFFICULTY_NORMAL)
	assert(game._draw_jurejure_battle_difficulty(.51)==BattleClass.DIFFICULTY_STRONG)
	restoration=game._restoration_state();restoration["ending_seen"]=true;restoration["ending_phase"]="complete";game.story_progression_state["restoration"]=restoration
	assert(game._jurejure_battle_difficulty_phase()==BattleClass.PHASE_POST_ENDING)
	assert(game._draw_jurejure_battle_difficulty(.39)==BattleClass.DIFFICULTY_NORMAL)
	assert(game._draw_jurejure_battle_difficulty(.41)==BattleClass.DIFFICULTY_STRONG)
	assert(game._draw_jurejure_battle_difficulty(.71)==BattleClass.DIFFICULTY_STRONGEST)
	_verify_main_difficulty_distributions(game)
	game.story_progression_state["fantasy_unlocked"]=false;game.story_progression_state["fusion_lab_unlocked"]=false;game.act3_unlocked=false
	assert(game._grant_random_fusion_battle_reward(.01).is_empty())
	game.story_progression_state["fantasy_unlocked"]=true
	var two_star_id:String=str(game._grant_random_fusion_battle_reward(.01))
	assert(not two_star_id.is_empty() and SpeciesStarRarityClass.stars_for(game._catalog_entry(two_star_id))==2)
	assert(game._species_get_count(two_star_id)==1 and bool(game.discovered.get(two_star_id,false)))
	var eligible_parent_ids:Array[String]=[]
	for parent in game.fusion_system.eligible_parents(game.species_get_counts):eligible_parent_ids.append(str(parent.get("species_id","")))
	assert(two_star_id in eligible_parent_ids)
	game.story_progression_state["fusion_lab_unlocked"]=true
	var three_star_id:String=str(game._grant_random_fusion_battle_reward(.055))
	assert(not three_star_id.is_empty() and SpeciesStarRarityClass.stars_for(game._catalog_entry(three_star_id))==3)
	game.act3_unlocked=true
	var four_star_id:String=str(game._grant_random_fusion_battle_reward(.061))
	assert(not four_star_id.is_empty() and SpeciesStarRarityClass.stars_for(game._catalog_entry(four_star_id))==4)
	assert(game._grant_random_fusion_battle_reward(.5,BattleClass.DIFFICULTY_STRONGEST).is_empty())

func _verify_main_difficulty_distributions(game:Node)->void:
	var phases:=[
		{"name":BattleClass.PHASE_EARLY,"expected":[0.0,.70,.30,0.0]},
		{"name":BattleClass.PHASE_EXPLOITATION,"expected":[0.0,.50,.50,0.0]},
		{"name":BattleClass.PHASE_POST_ENDING,"expected":[0.0,.40,.30,.30]},
	]
	for phase_value in phases:
		var phase:Dictionary=phase_value
		var phase_name:=str(phase.get("name",""))
		game.story_progression_state["exploitation_started"]=phase_name==BattleClass.PHASE_EXPLOITATION
		var restoration:Dictionary=game._restoration_state()
		restoration["ending_seen"]=phase_name==BattleClass.PHASE_POST_ENDING
		restoration["ending_phase"]="complete" if phase_name==BattleClass.PHASE_POST_ENDING else ""
		game.story_progression_state["restoration"]=restoration
		assert(game._jurejure_battle_difficulty_phase()==phase_name)
		var draw_rng:=RandomNumberGenerator.new();draw_rng.seed=20261023+phases.find(phase_value)*100
		var counts:=[0,0,0,0]
		for sample_index in range(DIFFICULTY_SAMPLE_COUNT):
			var difficulty:int=int(game._draw_jurejure_battle_difficulty(draw_rng.randf()))
			counts[difficulty]=int(counts[difficulty])+1
		var expected:Array=phase.get("expected",[])
		for difficulty in [BattleClass.DIFFICULTY_NORMAL,BattleClass.DIFFICULTY_STRONG,BattleClass.DIFFICULTY_STRONGEST]:
			assert(absf(float(counts[difficulty])/float(DIFFICULTY_SAMPLE_COUNT)-float(expected[difficulty]))<.004)

func _ratio(count:int)->float:
	return float(count)/float(BATTLE_SAMPLE_COUNT)

func _wait_until(predicate:Callable,timeout_msec:int)->bool:
	var deadline:=Time.get_ticks_msec()+timeout_msec
	while Time.get_ticks_msec()<deadline:
		if bool(predicate.call()):return true
		await get_tree().process_frame
	return bool(predicate.call())
