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
	print("INTEGRATED_FEATURES_SMOKE_OK star_rarity=63+62+66+22+21+5 flat_symbol_ui=true localization=3 gift=once arrangement=free-scale result_share=removed arrangement_share=preserved mystery_pod=removed")
	get_tree().quit()

func _test_catalog_and_collection_rarity(game)->void:
	assert(game._series_entry("common").is_empty() and game._series_species_entries("common").is_empty())
	assert(Localizer.series_name("ja",game._series_entry("base"))=="原種")
	assert(game._series_species_entries("base").size()==12)
	assert(not FileAccess.file_exists("res://data/collection-rarity.json"))
	assert(game.catalog_species.size()==239)
	var star_counts:Dictionary={0:0,1:0,2:0,3:0,4:0,5:0}
	for entry_value in game.catalog_species:
		assert(entry_value is Dictionary)
		var entry:Dictionary=entry_value
		var stars:=int(entry.get("star_rating",-1))
		assert(stars>=0 and stars<=5)
		assert(int(entry.get("gold_star_count",-1))==stars)
		star_counts[stars]=int(star_counts.get(stars,0))+1
	assert(star_counts=={0:63,1:62,2:66,3:22,4:21,5:5})
	assert(int(game._catalog_entry("colorata").get("star_rating",-1))==0)
	assert(int(game._catalog_entry("lutea").get("star_rating",-1))==1)
	# The former spawn-rarity field remains internal story/route data only and is
	# not overwritten by the new player-facing star rank.
	assert(str(game._catalog_entry("golden_laui").get("rarity",""))=="スーパーレア")

func _test_language_and_symbol_safety(game)->void:
	var japanese_texts:Dictionary=Localizer.TEXT.get("ja",{})
	for key_value in japanese_texts:
		var displayed_text:=str(japanese_texts[key_value])
		assert("タネ" not in displayed_text)
	assert(Localizer.text("ja","opening_story_4").contains("古いたね袋") and Localizer.text("ja","opening_story_4").contains("多肉植物のたね"))
	assert(Localizer.text("ja","awakening_sow")=="たねがまだ少し残ってる。\nここにまいてみよう。")
	assert(Localizer.text("ja","play_normal_seed_round")=="たねをまく\n1ぷくコイン消費")
	assert(Localizer.text("ja","series_seed_remaining")=="シリーズのたね\n残り %d粒")
	assert(Localizer.text("ja","post_ending_greenhouse_girl_4")=="これからも、いっぱいたねまこう！")
	assert(Localizer.text("hiragana","post_ending_greenhouse_girl_4")=="これからも、いっぱい たね まこう！")
	assert(Localizer.text("hiragana","awakening_sow").contains("まいて"))
	assert(Localizer.text("hiragana","play_normal_seed_round")=="たねを まく\n1ぷくこいん しょうひ")
	assert(Localizer.text("en","play_normal_seed_round")=="Plant seeds\nUse 1 Puku Coin")
	var major_runtime_keys:=[
		"habitat_intro_1","shop_rescue_offer","shop_chatter_touch",
		"shop_season_new_year","old_page_intro_1","volume_intro_1","bustamante_gift","pinwheel_intro_1",
		"armadillo_idle_1","restore_offer","restore_success",
		"audio_se_on","story_colorata_1","story_trio_1","awakening_memory","habitat_return_panda","initial_seed_stock_received","tutorial_normal_pre_sow","seed_pod_tutorial_received","forest_gacha_intro_system","fantasy_first_girl","fantasy_six_girl_2","act3_mouse_realizes","habitat_crisis_armadillo_1","jelly_float",
		"jurejure_after_encounter_panda","jurejure_after_encounter_armadillo","jurejure_exploit_mouse_treasure","habitat_exploit_start_panda","habitat_exploit_midpoint_panda","habitat_exploit_concern_girl",
		"act3_exploitation_battle_intro_panda","act3_exploitation_battle_intro_mouse_2","jurejure_species_first_girl_2","habitat_crisis_girl","jurejure_exploit_touch_mouse_more","jurejure_exploit_touch_panda_tool","jurejure_exploit_touch_mouse_battle","jurejure_exploit_touch_peccary_more","jurejure_exploit_touch_girl_overwork","jurejure_exploit_touch_peccary_fine","jurejure_exploit_touch_skunk_price","jurejure_exploit_touch_armadillo_greed","jurejure_exploit_touch_skunk_obvious",
		"habitat_exploit_visit_early_panda_1","habitat_exploit_visit_early_girl_1","habitat_exploit_visit_early_armadillo","habitat_exploit_visit_early_girl_2","habitat_exploit_visit_early_panda_2","habitat_exploit_visit_late_panda","habitat_exploit_visit_late_armadillo","habitat_exploit_visit_late_girl","habitat_exploit_midpoint_panda_1","habitat_exploit_midpoint_girl","habitat_exploit_midpoint_mouse_1","habitat_exploit_midpoint_peccary","habitat_exploit_midpoint_armadillo","habitat_exploit_midpoint_mouse_2","post_crisis_greenhouse_panda_1","post_crisis_greenhouse_armadillo","post_crisis_greenhouse_girl","post_crisis_greenhouse_panda_2"
	]
	var numeric_format_keys:=[]
	var string_format_keys:=["restore_success","story_trio_1"]
	for language in ["ja","hiragana","en"]:
		assert(Localizer.normalize_language(language)==language)
		for key in major_runtime_keys:
			var args:Array=[5] if str(key) in numeric_format_keys else (["TEST"] if str(key) in string_format_keys else [])
			assert(not Localizer.text(language,str(key),args).is_empty())
		for key in game.SHOP_CHATTER_KEYS:assert(not Localizer.text(language,str(key)).is_empty())
		var forbidden_rarity_terms:Dictionary={"ja":["レア","金星"],"hiragana":["れあ","きんぼし"],"en":["rare","gold star"]}
		for key in ["seed_normal_detail","seed_volume_detail","seed_premium_detail"]:
			var seed_detail:=Localizer.text(language,key).to_lower()
			for term in forbidden_rarity_terms[language]:assert(str(term).to_lower() not in seed_detail)
	game._set_language("en");assert(game.language_code=="en" and game.settings_button.text=="Settings" and game.forest_gacha_ui.language=="en" and game.opening_prompt_localized.visible and not game.opening_prompt.visible and game.opening_prompt_localized_label.text=="Tap to Start")
	assert(game.find_child("SeSettingLabel",true,false).text==Localizer.text("en","audio_se"))
	game._set_language("hiragana");assert(game.language_code=="hiragana" and game.opening_prompt_localized.visible and game.opening_prompt_localized_label.text=="タップして はじめる")
	game._set_language("ja");assert(game.opening_prompt.visible and not game.opening_prompt_localized.visible)
	game._set_language("ja")
	for path in ["res://scripts/main.gd","res://scripts/arrangement_ui.gd","res://scripts/forest_gacha_ui.gd","res://scripts/species_get_overlay.gd"]:
		var source:=FileAccess.get_file_as_string(path)
		for forbidden in [String.chr(0x2B50),String.chr(0x2606),String.chr(0x2665),String.chr(0x2764)]:assert(not source.contains(forbidden))
	assert(FileAccess.file_exists("res://scripts/ui_symbol_icon.gd") and FileAccess.file_exists("res://scripts/species_star_rarity.gd"))
	var main_source:=FileAccess.get_file_as_string("res://scripts/main.gd")
	var get_overlay_source:=FileAccess.get_file_as_string("res://scripts/species_get_overlay.gd")
	assert(main_source.contains("たねをまく") and main_source.contains("使用たね"))
	var sow_kanji:=String.chr(0x8494)
	var sow_alt_kanji:=String.chr(0x64ad)
	for locale in ["ja","hiragana"]:
		for localized_text in Localizer.TEXT[locale].values():
			assert(not str(localized_text).contains(sow_kanji) and not str(localized_text).contains(sow_alt_kanji),"Sowing text must stay in hiragana")
	assert(not main_source.contains(sow_kanji) and not main_source.contains(sow_alt_kanji))
	assert(not main_source.contains("GoldStars") and not main_source.contains('Localizer.text(language_code,"super_rare")'))
	assert(get_overlay_source.contains("SpeciesStarRarityClass") and get_overlay_source.contains('star_label.name="SpeciesStars"'))
	assert(not get_overlay_source.contains("rarity_label"))

func _test_one_time_gift_arrangement_and_share(game)->void:
	var points_before:int=game.puku_points;var bags_before:int=game.normal_seed_bags
	game.audio_manager.last_se_key="ui_tap"
	game._claim_first_habitat_gift_once();game._claim_first_habitat_gift_once()
	assert(game.first_habitat_gift_claimed and game.puku_points==points_before and game.normal_seed_bags==bags_before)
	assert(game.audio_manager.last_se_key=="ui_tap")
	assert(is_equal_approx(game.arrangement_ui._species_scale_max("laui"),game.arrangement_ui.PLANT_SCALE_SAFETY_MAX))
	game.bests["laui"]=52.6;game._sync_arrangement_ui()
	assert(is_equal_approx(game.arrangement_ui._species_scale_max("laui"),game.arrangement_ui.PLANT_SCALE_SAFETY_MAX))
	assert(game.arrangement_ui.picker_scroll.vertical_scroll_mode==ScrollContainer.SCROLL_MODE_AUTO)
	assert(not game.result_overlay.visible and game.result_overlay.get_child_count()==0)
	assert(game.result_overlay.find_child("ResultCloseButton",true,false)==null and game.result_overlay.find_child("ResultTitle",true,false)==null)
	assert(game.arrangement_ui.viewer_share_button and game.arrangement_ui.viewer_share_button.pressed.get_connections().size()>0)
	var main_source:=FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(main_source.contains('Engine.has_singleton("SharePlugin")') and main_source.contains('has_method("share")') and main_source.contains('share_plugin.call("share",{') and main_source.contains("navigator.share") and main_source.contains("_create_arrangement_share_image") and main_source.contains("_queue_species_get"))
	assert(not main_source.contains('pressed.connect(_share_personal_best)') and not main_source.contains('name="ResultCloseButton"'))
	assert(not main_source.contains("原種として図鑑に登録したよ"))

func _test_removed_mystery_pod()->void:
	for path in ["res://data/mystery-pod.json","res://scripts/mystery_pod_system.gd","res://scripts/mystery_pod_ui.gd","res://scripts/mystery_pod_smoke.gd"]:assert(not FileAccess.file_exists(path))
	var source:=FileAccess.get_file_as_string("res://scripts/main.gd").to_lower()
	assert(not source.contains("mystery_pod"))
