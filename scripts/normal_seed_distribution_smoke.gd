extends Node

const KNOWN_ZERO := ["momotaro","lola"]
const KNOWN_ONE := "black_prince"
const KNOWN_TWO := "nijinotama"
const UNLOCKED_NEW := "shirobotan"
const LOCKED_NEW := "gummy_peach_milk"
const EXCLUDED := ["pinwheel","glow_colorata","metal_laui"]

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._finish_opening();game.audio_manager.apply_settings({"bgm_enabled":false,"se_enabled":false})
	_configure_probe_catalog(game)
	_test_exact_routes(game)
	_test_uniform_known_category(game)
	_test_distribution(game)
	_test_known_fallback_and_exclusions(game)
	game.free();await get_tree().process_frame
	print("NORMAL_SEED_DISTRIBUTION_SMOKE_OK new=3+1 stars=81/10/5 uniform=true legacy_rarity=false spawn_weight=false excluded=true")
	get_tree().quit()

func _configure_probe_catalog(game:Node)->void:
	var ids:=KNOWN_ZERO+[KNOWN_ONE,KNOWN_TWO,UNLOCKED_NEW,LOCKED_NEW]+EXCLUDED
	var probes:Array[Dictionary]=[]
	for species_id in ids:
		var entry:Dictionary=game._catalog_entry(species_id).duplicate(true)
		assert(not entry.is_empty())
		probes.append(entry)
	game.catalog_species=probes
	var heavy:Dictionary=game._catalog_entry(KNOWN_ZERO[0]);heavy["gold_star_count"]=0;heavy["rarity"]="スーパーレア";heavy["spawn_weight"]=20.0
	var light:Dictionary=game._catalog_entry(KNOWN_ZERO[1]);light["gold_star_count"]=0;light["rarity"]="通常";light["spawn_weight"]=1.0
	var one:Dictionary=game._catalog_entry(KNOWN_ONE);one["gold_star_count"]=1;one["rarity"]="通常";one["spawn_weight"]=1.0
	var two:Dictionary=game._catalog_entry(KNOWN_TWO);two["gold_star_count"]=2;two["rarity"]="レア";two["spawn_weight"]=1.0
	# Keep one route-only probe and make a separate mystery-rarity probe so the
	# two exclusion paths are exercised independently.
	var mystery:Dictionary=game._catalog_entry("metal_laui");mystery["special_route_only"]=false
	game.discovered={KNOWN_ZERO[0]:true,KNOWN_ZERO[1]:true,KNOWN_ONE:true,KNOWN_TWO:true,EXCLUDED[0]:true,EXCLUDED[1]:true}
	game.greenhouse_available=game.discovered.duplicate(true)
	game.unlocked_series={"common":true}
	game.forest_gacha_encountered.clear()
	game.rng.seed=20260912

func _test_exact_routes(game:Node)->void:
	assert(is_equal_approx(game.NORMAL_SEED_UNLOCKED_NEW_RATE,.03))
	assert(is_equal_approx(game.NORMAL_SEED_LOCKED_NEW_RATE,.01))
	assert(is_equal_approx(game.NORMAL_SEED_NO_STAR_RATE,.81))
	assert(is_equal_approx(game.NORMAL_SEED_ONE_STAR_RATE,.10))
	assert(is_equal_approx(game.NORMAL_SEED_TWO_STAR_RATE,.05))
	assert(str(game._select_species_for_seed("normal",.029999).species_id)==UNLOCKED_NEW)
	var locked:Dictionary=game._select_species_for_seed("normal",.03)
	assert(str(locked.species_id)==LOCKED_NEW and bool(locked.get("_deferred_series_get",false)))
	assert(not bool(game.unlocked_series.get("gummy",false)))
	assert(str(game._select_species_for_seed("normal",.04).species_id) in KNOWN_ZERO)
	assert(str(game._select_species_for_seed("normal",.849999).species_id) in KNOWN_ZERO)
	assert(str(game._select_species_for_seed("normal",.85).species_id)==KNOWN_ONE)
	assert(str(game._select_species_for_seed("normal",.949999).species_id)==KNOWN_ONE)
	assert(str(game._select_species_for_seed("normal",.95).species_id)==KNOWN_TWO)
	assert(game._register_deferred_seed_get(LOCKED_NEW))
	assert(not bool(game.discovered.get(LOCKED_NEW,false)) and not bool(game.unlocked_series.get("gummy",false)))

func _test_uniform_known_category(game:Node)->void:
	var counts:={KNOWN_ZERO[0]:0,KNOWN_ZERO[1]:0}
	for draw in range(12000):
		var species_id:=str(game._select_species_for_seed("normal",.50).species_id)
		assert(species_id in KNOWN_ZERO)
		counts[species_id]=int(counts[species_id])+1
	var heavy_ratio:=float(counts[KNOWN_ZERO[0]])/12000.0
	assert(heavy_ratio>.47 and heavy_ratio<.53)

func _test_distribution(game:Node)->void:
	game.forest_gacha_encountered.clear()
	var counts:={"unlocked":0,"locked":0,"zero":0,"one":0,"two":0}
	for draw in range(50000):
		var choice:Dictionary=game._select_species_for_seed("normal")
		var species_id:=str(choice.species_id)
		if species_id==UNLOCKED_NEW:counts.unlocked+=1
		elif bool(choice.get("_deferred_series_get",false)):counts.locked+=1
		elif species_id in KNOWN_ZERO:counts.zero+=1
		elif species_id==KNOWN_ONE:counts.one+=1
		elif species_id==KNOWN_TWO:counts.two+=1
		else:assert(false,"unexpected normal-seed species: %s"%species_id)
	assert(_ratio(counts.unlocked)>.025 and _ratio(counts.unlocked)<.035)
	assert(_ratio(counts.locked)>.007 and _ratio(counts.locked)<.013)
	assert(_ratio(counts.zero)>.80 and _ratio(counts.zero)<.82)
	assert(_ratio(counts.one)>.09 and _ratio(counts.one)<.11)
	assert(_ratio(counts.two)>.045 and _ratio(counts.two)<.055)

func _test_known_fallback_and_exclusions(game:Node)->void:
	game.greenhouse_available.erase(KNOWN_ONE)
	for draw in range(400):
		var fallback:Dictionary=game._select_species_for_seed("normal",.90)
		assert(bool(game.discovered.get(str(fallback.species_id),false)))
		assert(str(fallback.species_id) not in EXCLUDED)
	for draw in range(400):assert(str(game._select_species_for_seed("normal",.50).species_id) not in EXCLUDED)

func _ratio(count:int)->float:
	return float(count)/50000.0
