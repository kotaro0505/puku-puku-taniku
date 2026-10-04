extends Node

const Localizer=preload("res://scripts/game_localizer.gd")
const ForestGachaSystemClass=preload("res://scripts/forest_gacha_system.gd")

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.opening_story_complete=true;game.intro_story_complete=true;game.first_colorata_confirmed=true;game.trio_originals_confirmed=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.habitat_arrival_started=true;game.habitat_awakened=true;game.habitat_awakening_event_complete=true;game.habitat_tutorial_started=true;game.habitat_tutorial_complete=true;game.seed_shop_open=true;game.panda_beacon_unlocked=true;game.panda_beacon_count=1;game.puku_gauge_intro_complete=true;game.total_play_count=3;game.puku_points=20;game.current_mode="greenhouse";game._update_play_ui()
	_test_assets_and_routes(game)
	_test_draw_rules(game)
	_test_jurejure_species_gate(game)
	await _test_spin_capsule_and_reveal(game)
	_test_encounter_save_and_unlock(game)
	game._reset_progression_state();game.queue_free()
	print("FOREST_GACHA_SMOKE_OK routes=2 series=uniform first_draw=all_eligible jurejure=pool_all_10 cards=species_then_catalog encounter=save+autoregister checker=backed")
	get_tree().quit()

func _test_assets_and_routes(game)->void:
	assert(game.forest_gacha_button!=null and game.forest_gacha_button.position.y<game.secret_gacha_button.position.y and game.forest_gacha_button.size==game.secret_gacha_button.size)
	assert(is_equal_approx(game.forest_gacha_button.position.y,326.0))
	assert(is_equal_approx(game.forest_gacha_button.position.y-(game.shop_button.position.y+game.shop_button.size.y),9.0))
	assert(game.forest_gacha_button.text=="森のガチャ" and "ぷく" not in game.forest_gacha_button.text)
	assert(Localizer.text("ja","main_forest_gacha")=="森のガチャ")
	assert(game.FOREST_GACHA_SPIN_COST==1 and game.forest_gacha_ui.SPIN_COST_PUKU==1 and Localizer.text("ja","gacha_spin")=="1ぷくコインで回す")
	assert(Localizer.text("hiragana","main_forest_gacha")=="もりの がちゃ")
	assert(Localizer.text("en","main_forest_gacha")=="Forest Gacha")
	var shop_route:=game.shop_overlay.find_child("ShopForestGachaButton",true,false) as Button;assert(shop_route!=null and shop_route.text.contains("ガチャ"))
	var background:=game.forest_gacha_ui.find_child("Background",true,false) as TextureRect;assert(background!=null and background.texture.resource_path=="res://assets/forest_gacha/forest-gacha-background.jpg")
	assert(background.material is ShaderMaterial and (background.material as ShaderMaterial).shader.code.contains("dial_backing_color"))
	var dial:=game.forest_gacha_ui.find_child("TemporaryDial",true,false) as TextureRect;assert(dial!=null and dial.texture.resource_path=="res://assets/forest_gacha/temporary-dial.png")
	assert(dial.size==game.forest_gacha_ui.DIAL_SIZE and (dial.position+dial.size*.5).is_equal_approx(game.forest_gacha_ui.DIAL_CENTER))
	var dial_image:=dial.texture.get_image();assert(dial_image!=null and dial_image.detect_alpha()!=Image.ALPHA_NONE and dial_image.get_pixel(0,0).a<.01)
	game.act2_unlocked=false;game.forest_gacha_unlocked=false;game.forest_gacha_intro_seen=false;game._update_play_ui()
	assert(not game.forest_gacha_button.visible and not shop_route.visible)
	game._open_forest_gacha();assert(not game.forest_gacha_ui.visible)
	game.act2_unlocked=true;game.forest_gacha_unlocked=true;game._update_play_ui()
	assert(not game.forest_gacha_button.visible and not shop_route.visible)
	game._start_forest_gacha_intro_event()
	assert(game.scripted_dialog_kind=="forest_gacha_intro" and game.intro_dialogue_label.text=="そういえば……森の方で変な機械を見つけたんだ。")
	game._advance_scripted_dialog();assert(game.intro_dialogue_label.text=="森のガチャが使えるようになった！")
	game._advance_scripted_dialog();game._update_play_ui()
	assert(game.forest_gacha_intro_seen and game.forest_gacha_button.visible and shop_route.visible)
	game._open_shop();assert(game.shop_overlay.visible);shop_route.pressed.emit();assert(game.forest_gacha_ui.visible and not game.shop_overlay.visible);game._close_forest_gacha()
	game._open_forest_gacha();assert(game.forest_gacha_ui.visible);game._close_forest_gacha()

func _test_draw_rules(game)->void:
	var test_rng:=RandomNumberGenerator.new();test_rng.seed=20260909
	var unlocked:Dictionary={"base":true};var encountered:Dictionary={};var known:Dictionary={"colorata":true}
	var pre_act_two_series:Array[Dictionary]=game.forest_gacha_system.eligible_series(false)
	assert(pre_act_two_series.size()==1 and str(pre_act_two_series[0].get("series_id",""))=="base")
	for original_entry in game.forest_gacha_system.eligible_species("base",false):
		assert(bool(original_entry.get("main_story_original",false)) and str(original_entry.get("story_group",""))!="jurejure")
	var all_eligible:Array[Dictionary]=game.forest_gacha_system.eligible_series()
	assert(all_eligible.size()>1)
	for series_entry in all_eligible:assert(not game._is_hidden_series(str(series_entry.get("series_id",""))))
	var first_five_include_locked:=false
	for draw_index in range(5):
		var early_result:Dictionary=game.forest_gacha_system.draw(unlocked,known,encountered,test_rng)
		if str(early_result.get("source",""))=="locked":first_five_include_locked=true
	assert(first_five_include_locked)
	var locked_available_on_first_draw:=false
	for seed_value in range(1,100):
		var probe:=RandomNumberGenerator.new();probe.seed=seed_value
		if str(game.forest_gacha_system.draw(unlocked,known,encountered,probe).get("source",""))=="locked":locked_available_on_first_draw=true;break
	assert(locked_available_on_first_draw)
	var all_known:Dictionary={};for species_entry in game.forest_gacha_system.eligible_species("base"):all_known[str(species_entry.species_id)]=true
	all_known.erase("lutea");var preferred:Dictionary=game.forest_gacha_system.draw(unlocked,all_known,{},test_rng,false);assert(str(preferred.species_id)=="lutea")
	_test_uniform_ten_series_weights()

func _test_uniform_ten_series_weights()->void:
	var system=ForestGachaSystemClass.new();var series_catalog:Array=[];var species_catalog:Array=[];var normal_series:Array=[]
	for index in range(10):
		var series_id:="uniform_%02d"%index;var species_id:="uniform_species_%02d"%index
		series_catalog.append({"series_id":series_id,"display_name":series_id,"unlock_type":"future","species_ids":[species_id]})
		species_catalog.append({"species_id":species_id,"rarity":"common"})
		normal_series.append({"series_id":series_id})
	system.configure(series_catalog,species_catalog,{"normal_series":normal_series})
	var pool:Array[Dictionary]=system.eligible_series();assert(pool.size()==10)
	var unlocked:Dictionary={"uniform_00":true,"uniform_01":true,"uniform_02":true};var counts:Dictionary={}
	var test_rng:=RandomNumberGenerator.new();test_rng.seed=20261001
	for sample_index in range(30000):
		var result:Dictionary=system.draw(unlocked,{}, {},test_rng);var series_id:=str(result.get("series_id",""));counts[series_id]=int(counts.get(series_id,0))+1
	assert(counts.size()==10)
	for series_entry in pool:
		var ratio:=float(counts.get(str(series_entry.get("series_id","")),0))/30000.0
		assert(ratio>.085 and ratio<.115)

func _test_jurejure_species_gate(game)->void:
	var jurejure_entries:Array[Dictionary]=game._series_species_entries("jurejure")
	assert(jurejure_entries.size()==10)
	assert(game.forest_gacha_system.eligible_species("jurejure",true,{}).is_empty())
	var pool_unlocks:Dictionary={}
	for entry in jurejure_entries:pool_unlocks[str(entry.get("species_id",""))]=true
	var eligible:Array[Dictionary]=game.forest_gacha_system.eligible_species("jurejure",true,pool_unlocks)
	assert(eligible.size()==10)
	assert(game.forest_gacha_system.eligible_species("jurejure",false,pool_unlocks).is_empty())
	var known:Dictionary={}
	for base_entry in game.forest_gacha_system.eligible_species("base",true):known[str(base_entry.get("species_id",""))]=true
	var test_rng:=RandomNumberGenerator.new();test_rng.seed=20260927
	var seen_jurejure:Dictionary={}
	for sample_index in range(200):
		var result:Dictionary=game.forest_gacha_system.draw({"base":true,"jurejure":true},known,{},test_rng,true,pool_unlocks)
		if str(result.get("series_id",""))=="jurejure":
			seen_jurejure[str(result.get("species_id",""))]=true
	assert(seen_jurejure.size()>1)

func _test_spin_capsule_and_reveal(game)->void:
	game.puku_points=5;game.forest_gacha_draw_count=0;game.forest_gacha_encountered.clear();game.discovered={"colorata":true};game.greenhouse_available={"colorata":true};game.unlocked_species=game.greenhouse_available.duplicate(true);game.unlocked_series={"base":true};game.story_progression_state["fantasy_unlocked"]=true;game._apply_saved_unlocks();game.forest_gacha_ui.animation_time_scale=.02
	var locked_seed:=-1
	for seed_value in range(1,100):
		var probe:=RandomNumberGenerator.new();probe.seed=seed_value
		var candidate:Dictionary=game.forest_gacha_system.draw(game.unlocked_series,game.discovered,game.forest_gacha_encountered,probe,true,game.jurejure_species_unlocked)
		if str(candidate.get("source",""))=="locked":locked_seed=seed_value;break
	assert(locked_seed>0);game.forest_gacha_rng.seed=locked_seed;game._open_forest_gacha()
	game._spin_forest_gacha();await get_tree().create_timer(.45).timeout
	assert(game.puku_points==4 and game.forest_gacha_draw_count==1 and game.forest_gacha_ui.capsule_ready and game.forest_gacha_ui.capsule.visible and absf(game.forest_gacha_ui.dial_texture.rotation)>1.0)
	var species_id:=str(game.forest_gacha_ui.pending_result.get("species_id",""));var series_id:=str(game.forest_gacha_ui.pending_result.get("series_id",""));assert(not species_id.is_empty() and series_id!="base" and bool(game.discovered.get(species_id,false)) and bool(game.greenhouse_available.get(species_id,false)))
	assert(series_id in game.catalog_series_unlock_notice_queue and not game.catalog_series_unlock_overlay.visible)
	game.forest_gacha_ui._reveal_result();await get_tree().process_frame;assert(game.species_get_overlay.visible and not game.catalog_series_unlock_overlay.visible and game.species_get_overlay.result_image.texture!=null and game.species_get_overlay.name_label.text==str(game._catalog_entry(species_id).get("name_ja","")))
	game.species_get_overlay.busy=false;await game.species_get_overlay.close_overlay();await get_tree().process_frame
	assert(not game.species_get_overlay.visible and game.catalog_series_unlock_overlay.visible and game.scripted_dialog_kind.is_empty())
	assert(game.catalog_series_unlock_overlay.title_label.text=="図鑑ページ解放！" and game.catalog_series_unlock_overlay.message_label.text.contains(game._catalog_series_notice_name(game._series_entry(series_id))))
	assert(str(game.catalog_cover_species.get(series_id,""))==species_id)
	assert(game.catalog_series_unlock_overlay.cover_image.texture!=null and game.catalog_series_unlock_overlay.cover_image.texture.resource_path==str(game._catalog_entry(species_id).get("image_path","")))
	game.catalog_series_unlock_overlay.busy=false;await game.catalog_series_unlock_overlay.close_overlay();await get_tree().process_frame
	assert(not game.catalog_series_unlock_overlay.visible and not game.forest_gacha_ui.busy);game._close_forest_gacha()
	game.puku_balance_units=999;var previous_count:int=game.forest_gacha_draw_count;game._open_forest_gacha();game._spin_forest_gacha();assert(game.forest_gacha_draw_count==previous_count and game.puku_balance_units==999);game._close_forest_gacha()

func _test_encounter_save_and_unlock(game)->void:
	var target_id:="gummy_peach_milk";game.unlocked_series.erase("gummy");game.discovered.erase(target_id);game.greenhouse_available.erase(target_id);game.unlocked_species.erase(target_id);game.forest_gacha_encountered={target_id:true};game.forest_gacha_draw_count=9;game.act2_unlocked=true;game.forest_gacha_unlocked=true;game.forest_gacha_intro_seen=true;game._save();game.forest_gacha_encountered.clear();game.forest_gacha_draw_count=0;game.act2_unlocked=false;game.forest_gacha_unlocked=false;game.forest_gacha_intro_seen=false;game._load_save();assert(game.forest_gacha_draw_count==9 and bool(game.forest_gacha_encountered.get(target_id,false)) and not bool(game.discovered.get(target_id,false)))
	assert(game.act2_unlocked and game.forest_gacha_unlocked and game.forest_gacha_intro_seen)
	var registered:Array[String]=game._unlock_series_and_register_encounters("gummy");assert(target_id in registered and bool(game.discovered.get(target_id,false)) and bool(game.greenhouse_available.get(target_id,false)))
	game.unlocked_series.erase("gummy");game.discovered.erase(target_id);game.greenhouse_available.erase(target_id);game.unlocked_species.erase(target_id);game.forest_gacha_encountered={target_id:true};game.puku_points=5;game.forest_gacha_ui.open_gacha(game.puku_points,game.forest_gacha_draw_count);game._unlock_forest_gacha_series("gummy",target_id);assert(game.puku_points==5 and bool(game.unlocked_series.get("gummy",false)) and bool(game.discovered.get(target_id,false)) and game.forest_gacha_ui.result_badge.text=="NEW!")
	game.unlocked_series.erase("gummy");game.discovered.erase(target_id);game.greenhouse_available.erase(target_id);game.unlocked_species.erase(target_id);game.forest_gacha_encountered={target_id:true};game._unlock_series_and_register_encounters("gummy");assert(bool(game.discovered.get(target_id,false)))
	game.forest_gacha_ui.show_later_message("この品種は不思議な図鑑へ自動で記録されます。",0,10);assert("自動で記録" in game.forest_gacha_ui.result_message.text)
