extends Node

const COMMON_IDS := ["momotaro","lola","black_prince","perle_von_nurnberg","shirobotan","shurei","bronze_hime","nijinotama","pink_pretty","prolidety"]
const COMMON_NAMES := ["桃太郎","ローラ","ブラックプリンス","パールフォンニュルンベルグ","白牡丹","秋麗","ブロンズ姫","虹の玉","ピンクプリティ","プロリデイティ"]

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._finish_opening();game.audio_manager.apply_settings({"bgm_enabled":false,"se_enabled":false})
	game._reset_progression_state()
	_test_common_catalog(game)
	_test_uniform_tutorial_draw(game)
	await _test_persistent_habitat(game)
	_test_main_new_species(game)
	_test_armadillo_events(game)
	game._reset_progression_state()
	print("EARLY_GAME_HABITAT_SMOKE_OK common=10 wild=variable threshold=30 offline=true armadillo=3,7")
	game.free();await get_tree().process_frame;get_tree().quit()

func _test_common_catalog(game:Node)->void:
	assert(game._owned_series_entries().map(func(entry):return str(entry.series_id))==["common"])
	assert(not game._is_series_unlocked(game._series_entry("base")))
	assert(game._series_species_entries("common").map(func(entry):return str(entry.species_id))==COMMON_IDS)
	assert(game._series_species_entries("common").map(func(entry):return str(entry.name_ja))==COMMON_NAMES)
	for species_id in COMMON_IDS:assert(bool(game.greenhouse_available.get(species_id,false)))
	for entry in game._series_species_entries("common"):
		var species_id:=str(entry.species_id);var image_path:=str(entry.get("image_path",""))
		if species_id=="nijinotama":
			assert(image_path=="res://assets/catalog/common/common-nijinotama.png" and ResourceLoader.exists(image_path))
			var image:Image=(load(image_path) as Texture2D).get_image()
			assert(image.detect_alpha()!=Image.ALPHA_NONE and image.get_pixel(0,0).a<.01 and image.get_pixel(image.get_width()-1,image.get_height()-1).a<.01)
		else:assert(image_path.is_empty())
	assert(game._series_cover_texture(game._series_entry("common")).resource_path=="res://assets/catalog/common/common-nijinotama.png")

func _test_uniform_tutorial_draw(game:Node)->void:
	var counts:Dictionary={};game.rng.seed=20260910
	for species_id in COMMON_IDS:counts[species_id]=0
	for draw in range(2000):
		game.first_tutorial_species_id=""
		var chosen:String=game._ensure_first_tutorial_species();assert(chosen in COMMON_IDS);counts[chosen]=int(counts[chosen])+1
	for species_id in COMMON_IDS:assert(int(counts[species_id])>150 and int(counts[species_id])<250)

func _test_persistent_habitat(game:Node)->void:
	game._reset_progression_state();game.intro_story_complete=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.total_play_count=3;game.current_mode="habitat";game._build_habitat_items(true)
	assert(game.habitat_wild_plants.size()>=game.HabitatWildSystemClass.INITIAL_POPULATION_MIN and game.habitat_wild_plants.size()<=game.HabitatWildSystemClass.INITIAL_POPULATION_MAX)
	assert(game.habitat_pickups.filter(func(item):return str(item.kind)=="wild_plant").size()==game.habitat_wild_plants.size())
	assert(game.habitat_pickups.filter(func(item):return str(item.kind) in ["new_species","found_species"]).is_empty())
	var tutorial_plants:Array=game.habitat_wild_plants.filter(func(plant):return bool(plant.tutorial));assert(tutorial_plants.size()==1)
	var tutorial:Dictionary=tutorial_plants[0];assert(float(tutorial.diameter_cm)>=29.76 and float(tutorial.diameter_cm)<=29.84 and bool(tutorial.jelly_immune) and not bool(tutorial.jellied))
	game.habitat_tutorial_started=true;game._save();game.habitat_tutorial_started=false;game._load_save();assert(game.habitat_tutorial_started)
	tutorial=game.HabitatWildSystemClass.tutorial_plant(game.habitat_wild_plants)
	for plant in game.habitat_wild_plants:
		for key in ["individual_id","species_id","diameter_cm","growth_state","jellied","last_updated_unix"]:assert(plant.has(key))
		if not bool(plant.tutorial):assert(float(plant.diameter_cm)<29.0)
	var small:Dictionary=game.habitat_wild_plants.filter(func(plant):return not bool(plant.tutorial))[0];var small_id:=str(small.individual_id);var small_item:Dictionary=game.habitat_pickups.filter(func(item):return str(item.get("individual_id",""))==small_id)[0]
	var population_before:int=game.habitat_wild_plants.size();game._collect_habitat_wild_plant(small_item)
	assert(game.habitat_wild_plants.size()==population_before and not game._habitat_wild_plant_by_id(small_id).is_empty())
	var now_unix:=int(Time.get_unix_time_from_system());var small_before:=float(small.diameter_cm);small.last_updated_unix=now_unix-3600;game.HabitatWildSystemClass.advance_time(game.habitat_wild_plants,now_unix);assert(float(small.diameter_cm)>small_before)
	tutorial.last_updated_unix=now_unix-3;game.HabitatWildSystemClass.advance_time(game.habitat_wild_plants,now_unix);assert(float(tutorial.diameter_cm)>=30.0 and game.HabitatWildSystemClass.can_harvest(tutorial))
	game._build_habitat_items(true);var tutorial_item:Dictionary=game.habitat_pickups.filter(func(item):return str(item.get("individual_id",""))==str(tutorial.individual_id))[0];var tutorial_species:=str(tutorial.species_id);game._collect_habitat_wild_plant(tutorial_item)
	assert(game.habitat_tutorial_complete and bool(game.discovered.get(tutorial_species,false)))
	assert(not game.original_catalog_gifted and not bool(game.unlocked_series.get("base",false)))
	game._show_next_species_get();assert(game.species_get_overlay.visible and game.species_get_active_context=="first_original")
	game.species_get_overlay.visible=false;game._on_species_get_overlay_closed("first_original");for frame in range(6):await get_tree().process_frame
	assert(game.scripted_dialog_kind=="original_catalog_gift","unexpected dialog: %s"%game.scripted_dialog_kind)
	while not game.scripted_dialog_kind.is_empty():game._advance_scripted_dialog()
	assert(game.original_catalog_gifted and bool(game.unlocked_series.get("base",false)))
	await get_tree().process_frame;await get_tree().process_frame;assert(game.scripted_dialog_kind=="puku_gauge_first_gift" and not game.first_habitat_gift_claimed)
	while game.scripted_dialog_index<3:game._advance_scripted_dialog()
	assert(not game.first_habitat_gift_claimed)
	game._advance_scripted_dialog();assert(game.first_habitat_gift_claimed and game.puku_points==10 and game.normal_seed_bags==3)
	while not game.scripted_dialog_kind.is_empty():game._advance_scripted_dialog()
	assert(game.puku_gauge_intro_complete)
	assert(game.habitat_wild_plants.size()==population_before-1 and game.HabitatWildSystemClass.tutorial_plant(game.habitat_wild_plants).is_empty())
	var saved_id:=str(game.habitat_wild_plants[0].individual_id);var saved_size:=float(game.habitat_wild_plants[0].diameter_cm);game._save();game.habitat_wild_plants.clear();game._load_save()
	var restored:Dictionary=game._habitat_wild_plant_by_id(saved_id);assert(not restored.is_empty() and float(restored.diameter_cm)>=saved_size)

func _test_main_new_species(game:Node)->void:
	game.unlocked_series={"common":true};game.discovered={"nijinotama":true};game.greenhouse_available=game._initial_greenhouse_state();game.unlocked_species=game.greenhouse_available.duplicate(true);game.species=game._series_species_entries("common");game.rng.seed=881144
	var unlocked_new_draws:=0;var locked_new_draws:=0;var samples:=3000
	for draw in range(samples):
		var chosen:Dictionary=game._select_species_for_seed("normal")
		if bool(chosen.get("_deferred_series_get",false)):locked_new_draws+=1
		else:
			assert(str(chosen.species_id) in COMMON_IDS)
			if str(chosen.species_id)!="nijinotama":unlocked_new_draws+=1
	var unlocked_ratio:=float(unlocked_new_draws)/samples;var locked_ratio:=float(locked_new_draws)/samples
	assert(unlocked_ratio>.025 and unlocked_ratio<.055 and locked_ratio>.003 and locked_ratio<.020)
	game.current_mode="greenhouse";game.active_seed_type="normal";game.opening_species=[game._catalog_entry("lola")];game._clear_greenhouse_plants();game.spawn_plant();game._update_labels();var plant=game.plants[0]
	assert(bool(plant.get_meta("new_species_candidate",false)) and "NEW！" in plant.label.text)
	plant.jelly_checks_enabled=false;plant.diameter_cm=2.0;plant.harvest();assert(bool(game.discovered.get("lola",false)))
	game._clear_greenhouse_plants()

func _test_armadillo_events(game:Node)->void:
	game.intro_story_complete=true;game.habitat_unlocked=true;game.habitat_tutorial_complete=true;game.puku_gauge_intro_complete=true;game.total_play_count=3;game.normal_play_count=2;game.armadillo_intro_event_3_completed=false;game.armadillo_series_event_7_completed=false;game.pending_armadillo_story_event="";game.hidden_species_acquired.erase("pinwheel");game.discovered.erase("pinwheel")
	game._queue_armadillo_progress_event();assert(game.pending_armadillo_story_event.is_empty())
	game.normal_play_count=3;game._queue_armadillo_progress_event();assert(game.pending_armadillo_story_event=="armadillo_3" and game._start_pending_armadillo_story())
	while not game.scripted_dialog_kind.is_empty():game._advance_intro_story()
	assert(game.armadillo_intro_event_3_completed and bool(game.discovered.get("pinwheel",false)))
	game.normal_play_count=7;game._queue_armadillo_progress_event();assert(game.pending_armadillo_story_event=="armadillo_7" and game._start_pending_armadillo_story())
	var gift_series:String=game.armadillo_gift_series_id;var gift_species:String=game.armadillo_gift_species_id
	assert(not gift_series.is_empty() and game._is_normal_series(gift_series) and not game._is_hidden_series(gift_series) and gift_series not in ["common","base"])
	while not game.scripted_dialog_kind.is_empty():game._advance_intro_story()
	assert(game.armadillo_series_event_7_completed and bool(game.unlocked_series.get(gift_series,false)) and bool(game.discovered.get(gift_species,false)))
	assert(not game._start_pending_armadillo_story())
