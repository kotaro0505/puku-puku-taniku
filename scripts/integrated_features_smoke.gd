extends Node

const Localizer=preload("res://scripts/game_localizer.gd")

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state()
	_test_catalog_and_collection_rarity(game)
	await _test_secret_gacha(game)
	_test_language_and_symbol_safety(game)
	_test_one_time_gift_arrangement_and_share(game)
	_test_removed_mystery_pod()
	game._reset_progression_state();game.queue_free();await get_tree().process_frame
	print("INTEGRATED_FEATURES_SMOKE_OK rarity=1x2+2x1 secret=always-playable localization=3 gift=once arrangement=record share=record-only mystery_pod=removed")
	get_tree().quit()

func _test_catalog_and_collection_rarity(game)->void:
	assert(Localizer.series_name("ja",game._series_entry("common"))=="おなじみ多肉図鑑")
	var common:Array=game._series_species_entries("common");assert(common.size()==10)
	var first_weight:=float(common[0].get("spawn_weight",0.0))
	for entry in common:assert(is_equal_approx(float(entry.get("spawn_weight",0.0)),first_weight))
	var rarity_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/collection-rarity.json"));assert(rarity_data is Dictionary)
	for series_value in game.series_catalog:
		if not series_value is Dictionary:continue
		var series:Dictionary=series_value;var ids:Array=series.get("species_ids",[]);var series_id:=str(series.get("series_id",""))
		if ids.size()<3:continue
		assert(rarity_data.has(series_id))
		var two_star:=0;var one_star:=0
		for entry in game._series_species_entries(series_id):
			var stars:=int(entry.get("gold_star_count",0));two_star+=1 if stars==2 else 0;one_star+=1 if stars==1 else 0
			assert(stars in [0,1,2])
		assert(two_star==1 and one_star==2)
	# Collection rarity is metadata only; it must not overwrite spawn rarity.
	assert(str(game._catalog_entry("nijinotama").get("rarity",""))=="通常")
	assert(int(game._catalog_entry("nijinotama").get("gold_star_count",0))==2)

func _test_secret_gacha(game)->void:
	var config:Dictionary=game.secret_gacha_system.config
	assert(int(config.get("cost_puku",0))==1)
	assert(int(config.get("max_draws_per_event",0))==3)
	assert(is_equal_approx(float(config.get("activation_chance_per_formal_play",0.0)),.012))
	assert(int(config.get("minimum_formal_play_count",0))==5)
	var weights:Dictionary=config.get("category_weights",{});assert(is_equal_approx(float(weights.get("species",0.0))+float(weights.get("pot",0.0))+float(weights.get("catalog_page",0.0)),1.0))
	var test_rng:=RandomNumberGenerator.new();test_rng.seed=91027
	assert(not game.secret_gacha_system.should_activate(4,true,test_rng,0.0))
	assert(not game.secret_gacha_system.should_activate(5,false,test_rng,0.0))
	assert(game.secret_gacha_system.should_activate(5,true,test_rng,0.0))
	assert(not game.secret_gacha_system.should_activate(5,true,test_rng,.999))
	for sample in range(120):
		var result:Dictionary=game.secret_gacha_system.draw({"common":true},{},{"shallow_terracotta":true},test_rng,"species")
		var entry:Dictionary=result.get("species_entry",{});assert(str(result.get("category",""))=="species")
		assert(int(entry.get("gold_star_count",0)) in [1,2]);assert(not bool(entry.get("special_route_only",false)))
	var species_result:Dictionary=game.secret_gacha_system.draw({"common":true},{},{"shallow_terracotta":true},test_rng,"species")
	var reward_species_id:=str(species_result.get("species_id",""));game.discovered.erase(reward_species_id);game._apply_secret_gacha_reward(species_result)
	assert(bool(game.discovered.get(reward_species_id,false)))
	var pot_result:Dictionary=game.secret_gacha_system.draw({}, {}, {"shallow_terracotta":true},test_rng,"pot");assert(str(pot_result.get("category",""))=="pot" and not str(pot_result.get("pot_id","")).is_empty())
	var reward_pot_id:=str(pot_result.get("pot_id",""));game.owned_pots.erase(reward_pot_id);game._apply_secret_gacha_reward(pot_result);assert(bool(game.owned_pots.get(reward_pot_id,false)))
	var page_result:Dictionary=game.secret_gacha_system.draw({}, {}, {},test_rng,"catalog_page");assert(str(page_result.get("category",""))=="catalog_page" and str(page_result.get("series_id",""))=="neon")
	var page_series_id:=str(page_result.get("series_id",""));var pages_before:=int(game.old_catalog_page_inventory.get(page_series_id,0));game._apply_secret_gacha_reward(page_result)
	assert(int(game.old_catalog_page_inventory.get(page_series_id,0))==pages_before+1)
	assert(game.forest_gacha_button.position.y<game.secret_gacha_button.position.y and game.forest_gacha_button.size==game.secret_gacha_button.size)
	assert(game.shop_overlay.find_child("SecretGachaButton",true,false)==null)
	game.secret_gacha_active=false;game.secret_gacha_draws_remaining=0;game._update_secret_gacha_button_state()
	assert(game._secret_gacha_is_playable() and not game.secret_gacha_button.disabled and game.secret_gacha_button.text==Localizer.text(game.language_code,"main_secret_gacha"))
	var background:=game.secret_gacha_ui.find_child("SecretGachaBackground",true,false) as TextureRect
	var dial:=game.secret_gacha_ui.find_child("ReplaceableTemporaryDial",true,false) as TextureRect
	assert(background!=null and background.texture.resource_path=="res://assets/secret_gacha/secret-gacha-background.png")
	assert(dial!=null and dial.texture.resource_path=="res://assets/secret_gacha/temporary-dial.png" and dial.get_parent()==game.secret_gacha_ui.machine_stage)
	var dial_image:=dial.texture.get_image();assert(dial_image!=null and dial_image.detect_alpha()!=Image.ALPHA_NONE and dial_image.get_pixel(0,0).a<.02)
	var background_image:=background.texture.get_image();var neutral_bright:=0;var sampled:=0
	for y in range(int(background_image.get_height()*.54),int(background_image.get_height()*.66),4):
		for x in range(int(background_image.get_width()*.40),int(background_image.get_width()*.60),4):
			var pixel:=background_image.get_pixel(x,y);sampled+=1
			if maxf(pixel.r,maxf(pixel.g,pixel.b))-minf(pixel.r,minf(pixel.g,pixel.b))<.035 and pixel.r>.58:neutral_bright+=1
	assert(float(neutral_bright)/float(sampled)<.08)
	assert(game.secret_gacha_ui.dial_duration_seconds>=1.8 and game.secret_gacha_ui.dial_duration_seconds<=2.2)
	assert(game.secret_gacha_ui.shake_duration_seconds>=1.2 and game.secret_gacha_ui.shake_duration_seconds<=1.6)
	game.secret_gacha_ui.animation_time_scale=.01;game.secret_gacha_ui.open_gacha(5,3)
	await game.secret_gacha_ui.play_spin(pot_result,CatalogImageLoader.placeholder_texture)
	assert(game.secret_gacha_ui.capsule_ready and game.secret_gacha_ui.capsule.visible and game.secret_gacha_ui.dial_texture.rotation>TAU)
	await game.secret_gacha_ui._reveal_result();assert(game.secret_gacha_ui.result_overlay.visible and not game.secret_gacha_ui.busy)
	game.secret_gacha_ui._close_result();game.secret_gacha_ui.close_gacha();game.secret_gacha_ui.animation_time_scale=1.0
	game.intro_story_complete=true;game.habitat_unlocked=true;game.habitat_tutorial_complete=true;game.puku_gauge_intro_complete=true;game.total_play_count=3;game.current_mode="greenhouse";game.play_active=false;game.puku_points=2;game._update_play_ui()
	assert(game.secret_gacha_button.visible and not game.secret_gacha_button.disabled)
	game.secret_gacha_ui.animation_time_scale=.01;game.secret_gacha_button.pressed.emit();assert(game.secret_gacha_ui.visible and game.secret_gacha_ui.unlimited_play)
	var points_before_actual_spin:int=game.puku_points;game.secret_gacha_ui.spin_button.pressed.emit()
	var spin_guard:=0
	while not game.secret_gacha_ui.capsule_ready and spin_guard<120:await get_tree().process_frame;spin_guard+=1
	assert(game.secret_gacha_ui.capsule_ready and game.puku_points==points_before_actual_spin-1 and game.secret_gacha_draws_remaining==0 and not game.secret_gacha_active)
	game.secret_gacha_ui.close_gacha();game.secret_gacha_ui.animation_time_scale=1.0
	game.secret_gacha_active=false;game.secret_gacha_draws_remaining=0;game.secret_gacha_last_roll_play_count=-1;game.formal_play_count=5;game.habitat_tutorial_complete=true
	assert(game._maybe_activate_secret_gacha(0.0) and game.secret_gacha_draws_remaining==3)
	var saved=JSON.parse_string(FileAccess.get_file_as_string("user://records.json"));assert(saved is Dictionary and bool(saved.get("secret_gacha_active",false)) and int(saved.get("secret_gacha_draws_remaining",0))==3)

func _test_language_and_symbol_safety(game)->void:
	var major_runtime_keys:=[
		"main_secret_gacha","main_secret_gacha_unavailable","secret_unlimited","habitat_intro_1","research_reward_title","shop_rescue_offer","shop_chatter_touch",
		"shop_season_new_year","old_page_intro_1","volume_intro_1","bustamante_gift","pinwheel_intro_1",
		"armadillo_idle_1","research_intro_1","research_return_offer","restore_offer","restore_success",
		"research_status_sprouted","research_status_first","research_milestone_catalog","research_milestone_species",
		"research_transfer","audio_se_on","unlock_original_catalog","jelly_float"
	]
	var numeric_format_keys:=["restore_offer","research_status_first","research_transfer"]
	var string_format_keys:=["restore_success","research_milestone_species"]
	for language in ["ja","hiragana","en"]:
		assert(Localizer.normalize_language(language)==language)
		for key in major_runtime_keys:
			var args:Array=[5] if str(key) in numeric_format_keys else (["TEST"] if str(key) in string_format_keys else [])
			assert(not Localizer.text(language,str(key),args).is_empty())
		for key in game.SHOP_CHATTER_KEYS:assert(not Localizer.text(language,str(key)).is_empty())
	game._set_language("en");assert(game.language_code=="en" and game.settings_button.text=="Settings" and game.secret_gacha_ui.language=="en" and game.opening_prompt_localized.visible and not game.opening_prompt.visible and game.opening_prompt_localized_label.text=="Tap to Start")
	assert(game.find_child("SeToggle",true,false).text==Localizer.text("en","audio_se_on"))
	game._set_language("hiragana");assert(game.language_code=="hiragana" and "ひみつ" in game.secret_gacha_button.text and game.opening_prompt_localized.visible and game.opening_prompt_localized_label.text=="タップして はじめる")
	game._set_language("ja");assert(game.opening_prompt.visible and not game.opening_prompt_localized.visible)
	game._set_language("ja")
	for path in ["res://scripts/main.gd","res://scripts/arrangement_ui.gd","res://scripts/forest_gacha_ui.gd","res://scripts/secret_gacha_ui.gd","res://scripts/species_get_overlay.gd"]:
		var source:=FileAccess.get_file_as_string(path)
		for forbidden in [String.chr(0x2B50),String.chr(0x2605),String.chr(0x2606),String.chr(0x2665),String.chr(0x2764)]:assert(not source.contains(forbidden))
	assert(FileAccess.file_exists("res://scripts/ui_symbol_icon.gd") and FileAccess.file_exists("res://scripts/star_rating.gd"))

func _test_one_time_gift_arrangement_and_share(game)->void:
	var points_before:int=game.puku_points;var bags_before:int=game.normal_seed_bags
	game._claim_first_habitat_gift_once();game._claim_first_habitat_gift_once()
	assert(game.first_habitat_gift_claimed and game.puku_points==points_before+10 and game.normal_seed_bags==bags_before+3)
	assert(is_equal_approx(game.arrangement_ui._species_scale_max("laui"),game.arrangement_ui.PLANT_SCALE_MIN))
	game.bests["laui"]=52.6;game._sync_arrangement_ui()
	assert(is_equal_approx(game.arrangement_ui._species_scale_max("laui"),52.6/game.arrangement_ui.ARRANGEMENT_CM_AT_SCALE_ONE))
	assert(game.arrangement_ui.picker_scroll.vertical_scroll_mode==ScrollContainer.SCROLL_MODE_AUTO)
	game.play_harvest_cm_total=10.0;game.play_harvest_count=1;game.play_max_size=10.0;game.play_puku_earned_total=0;game.play_notable_species.clear();game.result_new_species_queue.clear();game.play_updated_global_best=false
	game.play_share_record.clear();game._show_play_result();assert(not game.result_share_button.visible)
	game.play_share_record={"species_id":"nijinotama","size":32.1};game._show_play_result();assert(game.result_share_button.visible)
	var main_source:=FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(main_source.contains('Engine.has_singleton("SharePlugin")') and main_source.contains('has_method("share_image")') and main_source.contains("navigator.share") and main_source.contains("_queue_species_get"))
	assert(not main_source.contains("原種として図鑑に登録したよ"))

func _test_removed_mystery_pod()->void:
	for path in ["res://data/mystery-pod.json","res://scripts/mystery_pod_system.gd","res://scripts/mystery_pod_ui.gd","res://scripts/mystery_pod_smoke.gd"]:assert(not FileAccess.file_exists(path))
	var source:=FileAccess.get_file_as_string("res://scripts/main.gd").to_lower()
	assert(not source.contains("mystery_pod"))
