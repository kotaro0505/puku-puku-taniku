extends Node

const Localizer=preload("res://scripts/game_localizer.gd")

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state()
	_test_catalog_and_collection_rarity(game)
	_test_language_and_symbol_safety(game)
	_test_one_time_gift_arrangement_and_share(game)
	_test_removed_mystery_pod()
	game._reset_progression_state();game.queue_free();await get_tree().process_frame
	print("INTEGRATED_FEATURES_SMOKE_OK rarity=1x2+2x1 localization=3 gift=once arrangement=free-scale share=record-only mystery_pod=removed")
	get_tree().quit()

func _test_catalog_and_collection_rarity(game)->void:
	assert(game._series_entry("common").is_empty() and game._series_species_entries("common").is_empty())
	assert(Localizer.series_name("ja",game._series_entry("base"))=="原種")
	assert(game._series_species_entries("base").size()==12)
	var rarity_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/collection-rarity.json"));assert(rarity_data is Dictionary)
	for series_value in game.series_catalog:
		if not series_value is Dictionary:continue
		var series:Dictionary=series_value;var ids:Array=series.get("species_ids",[]);var series_id:=str(series.get("series_id",""))
		if series_id in ["base", "hybrid", "fusion_tier1", "fusion_tier2", "fusion_tier3"]:continue
		if ids.size()<3:continue
		assert(rarity_data.has(series_id))
		var two_star:=0;var one_star:=0
		for entry in game._series_species_entries(series_id):
			var stars:=int(entry.get("gold_star_count",0));two_star+=1 if stars==2 else 0;one_star+=1 if stars==1 else 0
			assert(stars in [0,1,2])
		assert(two_star==1 and one_star==2)
	# Collection rarity is metadata only; it must not overwrite spawn rarity.
	assert(str(game._catalog_entry("golden_laui").get("rarity",""))=="スーパーレア")
	assert(int(game._catalog_entry("golden_laui").get("gold_star_count",0))==2)

func _test_language_and_symbol_safety(game)->void:
	var major_runtime_keys:=[
		"habitat_intro_1","research_reward_title","shop_rescue_offer","shop_chatter_touch",
		"shop_season_new_year","old_page_intro_1","volume_intro_1","bustamante_gift","pinwheel_intro_1",
		"armadillo_idle_1","research_intro_1","research_return_offer","restore_offer","restore_success",
		"research_status_sprouted","research_status_first","research_milestone_catalog","research_milestone_species",
		"research_transfer","audio_se_on","story_colorata_1","story_trio_1","awakening_memory","habitat_return_panda","initial_seed_stock_received","tutorial_normal_pre_sow","seed_pod_tutorial_received","forest_gacha_intro_system","fantasy_first_girl","fantasy_six_girl_2","act3_mouse_realizes","habitat_crisis_armadillo_1","jelly_float",
		"jurejure_after_encounter_panda","jurejure_after_encounter_armadillo","jurejure_exploit_mouse_treasure","habitat_exploit_start_panda","habitat_exploit_midpoint_panda","habitat_exploit_concern_girl",
		"act3_exploitation_battle_intro_panda","act3_exploitation_battle_intro_mouse_2","jurejure_species_first_girl_2","habitat_crisis_girl","jurejure_exploit_touch_mouse_more","jurejure_exploit_touch_panda_tool","jurejure_exploit_touch_mouse_battle","jurejure_exploit_touch_peccary_more","jurejure_exploit_touch_girl_overwork","jurejure_exploit_touch_peccary_fine","jurejure_exploit_touch_skunk_price","jurejure_exploit_touch_armadillo_greed","jurejure_exploit_touch_skunk_obvious",
		"habitat_exploit_visit_early_panda_1","habitat_exploit_visit_early_girl_1","habitat_exploit_visit_early_armadillo","habitat_exploit_visit_early_girl_2","habitat_exploit_visit_early_panda_2","habitat_exploit_visit_late_panda","habitat_exploit_visit_late_armadillo","habitat_exploit_visit_late_girl","habitat_exploit_midpoint_panda_1","habitat_exploit_midpoint_girl","habitat_exploit_midpoint_mouse_1","habitat_exploit_midpoint_peccary","habitat_exploit_midpoint_armadillo","habitat_exploit_midpoint_mouse_2","post_crisis_greenhouse_panda_1","post_crisis_greenhouse_armadillo","post_crisis_greenhouse_girl","post_crisis_greenhouse_panda_2"
	]
	var numeric_format_keys:=["research_status_first","research_transfer"]
	var string_format_keys:=["restore_success","research_milestone_species","story_trio_1"]
	for language in ["ja","hiragana","en"]:
		assert(Localizer.normalize_language(language)==language)
		for key in major_runtime_keys:
			var args:Array=[5] if str(key) in numeric_format_keys else (["TEST"] if str(key) in string_format_keys else [])
			assert(not Localizer.text(language,str(key),args).is_empty())
		for key in game.SHOP_CHATTER_KEYS:assert(not Localizer.text(language,str(key)).is_empty())
	game._set_language("en");assert(game.language_code=="en" and game.settings_button.text=="Settings" and game.forest_gacha_ui.language=="en" and game.opening_prompt_localized.visible and not game.opening_prompt.visible and game.opening_prompt_localized_label.text=="Tap to Start")
	assert(game.find_child("SeToggle",true,false).text==Localizer.text("en","audio_se_on"))
	game._set_language("hiragana");assert(game.language_code=="hiragana" and game.opening_prompt_localized.visible and game.opening_prompt_localized_label.text=="タップして はじめる")
	game._set_language("ja");assert(game.opening_prompt.visible and not game.opening_prompt_localized.visible)
	game._set_language("ja")
	for path in ["res://scripts/main.gd","res://scripts/arrangement_ui.gd","res://scripts/forest_gacha_ui.gd","res://scripts/species_get_overlay.gd"]:
		var source:=FileAccess.get_file_as_string(path)
		for forbidden in [String.chr(0x2B50),String.chr(0x2605),String.chr(0x2606),String.chr(0x2665),String.chr(0x2764)]:assert(not source.contains(forbidden))
	assert(FileAccess.file_exists("res://scripts/ui_symbol_icon.gd") and FileAccess.file_exists("res://scripts/star_rating.gd"))

func _test_one_time_gift_arrangement_and_share(game)->void:
	var points_before:int=game.puku_points;var bags_before:int=game.normal_seed_bags
	game._claim_first_habitat_gift_once();game._claim_first_habitat_gift_once()
	assert(game.first_habitat_gift_claimed and game.puku_points==points_before and game.normal_seed_bags==bags_before)
	assert(is_equal_approx(game.arrangement_ui._species_scale_max("laui"),game.arrangement_ui.PLANT_SCALE_SAFETY_MAX))
	game.bests["laui"]=52.6;game._sync_arrangement_ui()
	assert(is_equal_approx(game.arrangement_ui._species_scale_max("laui"),game.arrangement_ui.PLANT_SCALE_SAFETY_MAX))
	assert(game.arrangement_ui.picker_scroll.vertical_scroll_mode==ScrollContainer.SCROLL_MODE_AUTO)
	game.play_harvest_cm_total=10.0;game.play_puku_reward_units_total=0;game.play_harvest_count=1;game.play_max_size=10.0;game.play_notable_species.clear();game.result_new_species_queue.clear();game.play_updated_global_best=false
	game.play_share_record.clear();game._show_play_result();assert(not game.result_share_button.visible)
	game.play_share_record={"species_id":"colorata","size":32.1};game._show_play_result();assert(game.result_share_button.visible)
	var main_source:=FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(main_source.contains('Engine.has_singleton("SharePlugin")') and main_source.contains('has_method("share_image")') and main_source.contains("navigator.share") and main_source.contains("_create_arrangement_share_image") and main_source.contains("_queue_species_get"))
	assert(not main_source.contains("原種として図鑑に登録したよ"))

func _test_removed_mystery_pod()->void:
	for path in ["res://data/mystery-pod.json","res://scripts/mystery_pod_system.gd","res://scripts/mystery_pod_ui.gd","res://scripts/mystery_pod_smoke.gd"]:assert(not FileAccess.file_exists(path))
	var source:=FileAccess.get_file_as_string("res://scripts/main.gd").to_lower()
	assert(not source.contains("mystery_pod"))
