extends Node

const Localizer=preload("res://scripts/game_localizer.gd")
const ForestGachaSystemClass=preload("res://scripts/forest_gacha_system.gd")

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.opening_story_complete=true;game.intro_story_complete=true;game.first_colorata_confirmed=true;game.trio_originals_confirmed=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.habitat_arrival_started=true;game.habitat_awakened=true;game.habitat_awakening_event_complete=true;game.habitat_tutorial_started=true;game.habitat_tutorial_complete=true;game.seed_shop_open=true;game.panda_beacon_unlocked=true;game.panda_beacon_count=1;game.puku_gauge_intro_complete=true;game.total_play_count=3;game.puku_points=20;game.current_mode="greenhouse";game.story_progression_state["arrangement_unlocked"]=true;game.story_progression_state["arrangement_intro_seen"]=true;game._update_play_ui()
	_test_assets_and_routes(game)
	_test_price_and_localization(game)
	await _test_get_card_decoration(game)
	_test_removed_status_text(game)
	_test_draw_rules(game)
	_test_star_rank_draw_distribution()
	_test_jurejure_collection_distribution()
	_test_jurejure_species_gate(game)
	await _test_spin_capsule_and_reveal(game)
	_test_repeated_price_debit(game)
	_test_encounter_save_and_unlock(game)
	game._reset_progression_state();game.queue_free()
	print("FOREST_GACHA_SMOKE_OK price=3 ranks=95+4+0.8+0.2+0 five_star=never normal_species=uniform rank_new=60 duplicate=40 jure_mission=25+35+40 empty_rank=no_upper_transfer wallet=2_blocked+3_allowed+115_to_1 card=new_gold+duplicate_ivory_no_glow+stars")
	get_tree().quit()

func _test_assets_and_routes(game)->void:
	assert(game.forest_gacha_button!=null and game.forest_gacha_button.size==Vector2(153,55))
	assert(is_equal_approx(game.forest_gacha_button.position.y,326.0))
	assert(is_equal_approx(game.forest_gacha_button.position.y-(game.shop_button.position.y+game.shop_button.size.y),9.0))
	assert(is_equal_approx(game.fusion_lab_button.position.y-(game.forest_gacha_button.position.y+game.forest_gacha_button.size.y),9.0))
	assert(game.forest_gacha_button.text=="ガチャ" and "ぷく" not in game.forest_gacha_button.text)
	assert(Localizer.text("ja","main_forest_gacha")=="ガチャ")
	assert(Localizer.text("hiragana","main_forest_gacha")=="がちゃ")
	assert(Localizer.text("en","main_forest_gacha")=="Gacha")
	assert(Localizer.text("ja","forest_gacha")=="ガチャ" and Localizer.text("ja","shop_category_gacha")=="ガチャ")
	assert(game.forest_gacha_ui.title_label.text=="ガチャ")
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
	assert(game.scripted_dialog_kind=="forest_gacha_intro" and game.intro_dialogue_label.text=="僕が見つけた品種をガチャにしてみたんだ！良かったらやってみてよ！")
	game._advance_scripted_dialog();assert(game.intro_dialogue_label.text=="ガチャが使えるようになった！")
	game._advance_scripted_dialog();game._update_play_ui()
	assert(game.forest_gacha_intro_seen and game.forest_gacha_button.visible and shop_route.visible)
	game._open_shop();assert(game.shop_overlay.visible);shop_route.pressed.emit();assert(game.forest_gacha_ui.visible and not game.shop_overlay.visible);game._close_forest_gacha()
	game._open_forest_gacha();assert(game.forest_gacha_ui.visible);game._close_forest_gacha()

func _test_price_and_localization(game)->void:
	var ui=game.forest_gacha_ui
	assert(game.FOREST_GACHA_SPIN_COST==3)
	assert(ui.SPIN_COST_PUKU==3)
	var expected_text:={
		"ja":"3ぷくコインで回す",
		"hiragana":"3ぷくこいんでまわす",
		"en":"Spin for 3 Puku Coins",
	}
	for test_language in expected_text:
		ui.set_language(str(test_language))
		assert(Localizer.text(str(test_language),"gacha_spin")==str(expected_text[test_language]))
		assert(ui.spin_button.text==str(expected_text[test_language]))
		assert(ui.spin_button.position==Vector2(148,910) and ui.spin_button.size==Vector2(280,72))
		var font:Font=ui.spin_button.get_theme_font("font")
		var font_size:int=ui.spin_button.get_theme_font_size("font_size")
		var text_width:float=font.get_string_size(ui.spin_button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		assert(text_width<=ui.spin_button.size.x-24.0,"gacha spin label clips in %s width=%.2f available=%.2f"%[test_language,text_width,ui.spin_button.size.x-24.0])
	ui.set_language("ja")
	ui.set_wallet(2,0);assert(ui.spin_button.disabled and ui.dial_hit_area.disabled)
	ui.set_wallet(3,0);assert(not ui.spin_button.disabled and not ui.dial_hit_area.disabled)
	ui.set_wallet(115,0);assert(not ui.spin_button.disabled and not ui.dial_hit_area.disabled)
	ui.set_wallet(20,0)

func _test_get_card_decoration(game)->void:
	var overlay=game.species_get_overlay
	var entry:Dictionary=game._catalog_entry("colorata")
	var texture:=game._species_texture(entry) as Texture2D
	assert(texture!=null)
	var cases:=[
		{"context":"forest_gacha","is_new":false,"duplicate":true},
		{"context":"forest_gacha","is_new":true,"duplicate":false},
		{"context":"forest_gacha","is_new":false,"duplicate":true},
		{"context":"round_result_new","is_new":false,"duplicate":false},
	]
	for case_value in cases:
		var case:Dictionary=case_value
		overlay.show_species(entry,texture,bool(case.is_new),str(case.context),"ja","原種")
		var duplicate:=bool(case.duplicate)
		var card_style:=overlay.card.get_theme_stylebox("panel") as StyleBoxFlat
		var frame_style:=overlay.image_frame.get_theme_stylebox("panel") as StyleBoxFlat
		assert(overlay.duplicate_gacha_decoration_active==duplicate)
		if duplicate:
			assert(card_style.border_color.is_equal_approx(overlay.DUPLICATE_GACHA_IVORY))
			assert(frame_style.border_color.is_equal_approx(Color(overlay.DUPLICATE_GACHA_IVORY,.82)))
			assert(card_style.shadow_size==0 and frame_style.shadow_size==0)
			assert(is_zero_approx(overlay.flash.color.a) and not overlay.badge_label.visible)
		else:
			assert(card_style.border_color.is_equal_approx(overlay.GOLD_BORDER))
			assert(card_style.shadow_size==24 and frame_style.shadow_size==22)
			assert(overlay.flash.color.a>.9)
			assert(overlay.badge_label.visible==bool(case.is_new))
		assert(await _wait_until(func()->bool:return not overlay.busy,1000))
		overlay.visible=false;overlay.result_image.texture=null

func _test_removed_status_text(game)->void:
	var ui=game.forest_gacha_ui
	for test_language in ["ja","hiragana","en"]:
		ui.set_language(test_language);ui.open_gacha(20,37)
		assert(ui.current_draw_count==37)
		var visible_text:=_visible_control_text(ui)
		assert(Localizer.text(test_language,"gacha_draw_count",[37]) not in visible_text)
	ui.close_gacha();ui.set_language("ja")

func _visible_control_text(root:Node)->String:
	var texts:Array[String]=[]
	for node in root.find_children("*","Control",true,false):
		if node is Control and not (node as Control).is_visible_in_tree():continue
		if node is Label or node is Button:texts.append(str(node.text))
	return "\n".join(texts)

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
	_test_new_duplicate_draw_rate()
	_test_uniform_ten_series_weights()

func _test_new_duplicate_draw_rate()->void:
	var system=ForestGachaSystemClass.new()
	var series_catalog:Array=[{"series_id":"mix","display_name":"mix","unlock_type":"future","species_ids":["new_a","new_b","owned_a","owned_b"]}]
	var species_catalog:Array=[{"species_id":"new_a","series_id":"mix"},{"species_id":"new_b","series_id":"mix"},{"species_id":"owned_a","series_id":"mix"},{"species_id":"owned_b","series_id":"mix"}]
	system.configure(series_catalog,species_catalog,{"normal_series":[{"series_id":"mix"}]})
	var discovered:Dictionary={"owned_a":true,"owned_b":true};var test_rng:=RandomNumberGenerator.new();test_rng.seed=20261016
	var new_count:=0;var duplicate_count:=0
	for sample_index in range(20000):
		var result:Dictionary=system.draw({"mix":true},discovered,{},test_rng)
		if bool(result.get("was_discovered",false)):duplicate_count+=1
		else:new_count+=1
	var new_ratio:=float(new_count)/20000.0
	assert(new_ratio>.58 and new_ratio<.62 and new_count+duplicate_count==20000)
	for sample_index in range(100):assert(not bool(system.draw({"mix":true},{},{},test_rng).get("was_discovered",true)))
	var all_discovered:Dictionary={"new_a":true,"new_b":true,"owned_a":true,"owned_b":true}
	for sample_index in range(100):assert(bool(system.draw({"mix":true},all_discovered,{},test_rng).get("was_discovered",false)))

func _test_uniform_ten_series_weights()->void:
	var system=ForestGachaSystemClass.new();var series_catalog:Array=[];var species_catalog:Array=[];var normal_series:Array=[]
	for index in range(10):
		var series_id:="uniform_%02d"%index;var species_id:="uniform_species_%02d"%index
		series_catalog.append({"series_id":series_id,"display_name":series_id,"unlock_type":"future","species_ids":[species_id]})
		species_catalog.append({"species_id":species_id,"series_id":series_id,"rarity":"common"})
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

func _test_star_rank_draw_distribution()->void:
	var system=ForestGachaSystemClass.new()
	assert(system._roll_star_rank(.0)==0)
	assert(system._roll_star_rank(.949999)==0)
	assert(system._roll_star_rank(.950)==2)
	assert(system._roll_star_rank(.989999)==2)
	assert(system._roll_star_rank(.990)==3)
	assert(system._roll_star_rank(.997999)==3)
	assert(system._roll_star_rank(.998)==4)
	assert(system._roll_star_rank(.999999)==4)
	var series_catalog:Array=[
		{"series_id":"normal","display_name":"normal","unlock_type":"default","species_ids":["n0a","n0b","n1a","n1b"]},
		{"series_id":"hybrid","display_name":"hybrid","unlock_type":"future","species_ids":["r2n","r2d"]},
		{"series_id":"fusion_tier1","display_name":"tier1","unlock_type":"future","species_ids":["r3n","r3d"]},
		{"series_id":"fusion_tier2","display_name":"tier2","unlock_type":"future","species_ids":["r4n","r4d"]},
		{"series_id":"fusion_tier3","display_name":"tier3","unlock_type":"future","species_ids":["r5n"]},
	]
	var species_catalog:Array=[
		{"species_id":"n0a","series_id":"normal","star_rating":0},{"species_id":"n0b","series_id":"normal","star_rating":0},
		{"species_id":"n1a","series_id":"normal","star_rating":1},{"species_id":"n1b","series_id":"normal","star_rating":1},
		{"species_id":"r2n","series_id":"hybrid","star_rating":2},{"species_id":"r2d","series_id":"hybrid","star_rating":2},
		{"species_id":"r3n","series_id":"fusion_tier1","star_rating":3},{"species_id":"r3d","series_id":"fusion_tier1","star_rating":3},
		{"species_id":"r4n","series_id":"fusion_tier2","star_rating":4},{"species_id":"r4d","series_id":"fusion_tier2","star_rating":4},
		{"species_id":"r5n","series_id":"fusion_tier3","star_rating":5},
	]
	system.configure(series_catalog,species_catalog,{"normal_series":[{"series_id":"normal"}]})
	var unlocks:Dictionary={2:true,3:true,4:true};var unlocked_series:Dictionary={"normal":true}
	var test_rng:=RandomNumberGenerator.new();test_rng.seed=20261018
	var counts:Dictionary={0:0,2:0,3:0,4:0,5:0}
	for sample_index in range(1000000):
		var stars:int=system._roll_star_rank(test_rng.randf());counts[stars]=int(counts.get(stars,0))+1
	assert(_ratio(int(counts[0]),1000000)>.948 and _ratio(int(counts[0]),1000000)<.952)
	assert(_ratio(int(counts[2]),1000000)>.039 and _ratio(int(counts[2]),1000000)<.041)
	assert(_ratio(int(counts[3]),1000000)>.0075 and _ratio(int(counts[3]),1000000)<.0085)
	assert(_ratio(int(counts[4]),1000000)>.0017 and _ratio(int(counts[4]),1000000)<.0023)
	assert(int(counts[5])==0)
	# All four ordinary species share the same 95% pool. Star 1 never changes an
	# individual species' chance.
	var species_counts:Dictionary={};test_rng.seed=202610181
	for sample_index in range(40000):
		var result:Dictionary=system.draw(unlocked_series,{}, {},test_rng,true,{},unlocks,.5)
		var species_id:=str(result.get("species_id",""));species_counts[species_id]=int(species_counts.get(species_id,0))+1
	for species_id in ["n0a","n0b","n1a","n1b"]:
		var ratio:=_ratio(int(species_counts.get(species_id,0)),40000)
		assert(ratio>.24 and ratio<.26,"ordinary gacha species not uniform: %s=%f"%[species_id,ratio])
	assert(not species_counts.has("r5n"))
	# NEW 60/duplicate 40 is applied after the rank roll, independently inside
	# every populated rank.
	var discovered:Dictionary={"n0b":true,"n1b":true,"r2d":true,"r3d":true,"r4d":true,"r5n":true}
	var forced_rolls:Dictionary={0:.5,2:.96,3:.995,4:.999};test_rng.seed=20261019
	for stars_value in [0,2,3,4]:
		var new_count:=0
		for sample_index in range(20000):
			var result:Dictionary=system.draw(unlocked_series,discovered,{},test_rng,true,{},unlocks,float(forced_rolls[stars_value]))
			var result_stars:=int(result.get("star_rating",-1))
			assert(result_stars<=1 if stars_value==0 else result_stars==stars_value)
			if not bool(result.get("was_discovered",false)):new_count+=1
		var new_ratio:=_ratio(new_count,20000)
		assert(new_ratio>.54 and new_ratio<.66,"rank-local NEW ratio stars=%d ratio=%f"%[stars_value,new_ratio])
	# Completing every ordinary and fusion candidate changes only NEW/duplicate
	# selection; it never raises a higher rank.
	var all_discovered:Dictionary={}
	for entry in species_catalog:all_discovered[str(entry.get("species_id",""))]=true
	for stars_value in [0,2,3,4]:
		for sample_index in range(100):
			var result:Dictionary=system.draw(unlocked_series,all_discovered,{},test_rng,true,{},unlocks,float(forced_rolls[stars_value]))
			var result_stars:=int(result.get("star_rating",-1))
			assert(bool(result.get("was_discovered",false)) and (result_stars<=1 if stars_value==0 else result_stars==stars_value))
	# If rank 3 has no eligible candidate, its 0.8% falls back to normal. It does
	# not get transferred to rank 4.
	var missing_rank3_unlocks:Dictionary={2:true,3:false,4:true};test_rng.seed=20261021
	for sample_index in range(1000):
		var missing_result:Dictionary=system.draw(unlocked_series,{}, {},test_rng,true,{},missing_rank3_unlocks,.995)
		assert(int(missing_result.get("star_rating",-1))<=1)
		var four_result:Dictionary=system.draw(unlocked_series,{}, {},test_rng,true,{},missing_rank3_unlocks,.999)
		assert(int(four_result.get("star_rating",-1))==4)

func _ratio(count:int,total:int)->float:
	return float(count)/float(total)

func _test_jurejure_collection_distribution()->void:
	var system=ForestGachaSystemClass.new()
	var series_catalog:Array=[
		{"series_id":"normal","display_name":"normal","unlock_type":"default","species_ids":["other_new_a","other_new_b","owned_a","owned_b"]},
		{"series_id":"jurejure","display_name":"jurejure","unlock_type":"future","species_ids":["jure_a","jure_b","jure_c","jure_d"]},
		{"series_id":"hybrid","display_name":"hybrid","unlock_type":"future","species_ids":["r2n","r2d"]},
		{"series_id":"fusion_tier1","display_name":"tier1","unlock_type":"future","species_ids":["r3n","r3d"]},
		{"series_id":"fusion_tier2","display_name":"tier2","unlock_type":"future","species_ids":["r4n","r4d"]},
	]
	var species_catalog:Array=[
		{"species_id":"other_new_a","series_id":"normal","star_rating":0},{"species_id":"other_new_b","series_id":"normal","star_rating":1},
		{"species_id":"owned_a","series_id":"normal","star_rating":0},{"species_id":"owned_b","series_id":"normal","star_rating":1},
		{"species_id":"jure_a","series_id":"jurejure","story_group":"jurejure","star_rating":0},
		{"species_id":"jure_b","series_id":"jurejure","story_group":"jurejure","star_rating":0},
		{"species_id":"jure_c","series_id":"jurejure","story_group":"jurejure","star_rating":1},
		{"species_id":"jure_d","series_id":"jurejure","story_group":"jurejure","star_rating":1},
		{"species_id":"r2n","series_id":"hybrid","star_rating":2},{"species_id":"r2d","series_id":"hybrid","star_rating":2},
		{"species_id":"r3n","series_id":"fusion_tier1","star_rating":3},{"species_id":"r3d","series_id":"fusion_tier1","star_rating":3},
		{"species_id":"r4n","series_id":"fusion_tier2","star_rating":4},{"species_id":"r4d","series_id":"fusion_tier2","star_rating":4},
	]
	system.configure(series_catalog,species_catalog,{"normal_series":[{"series_id":"normal"}]})
	assert(is_equal_approx(system.JUREJURE_NEW_TOTAL_RATE,.25))
	assert(is_equal_approx(system.JUREJURE_NEW_RATE_WITHIN_NORMAL_RANK,.25/.95))
	var featured:Array[String]=["jure_a","jure_b","jure_c","jure_d"]
	var discovered:Dictionary={"owned_a":true,"owned_b":true,"r2d":true,"r3d":true,"r4d":true}
	var unlocks:Dictionary={2:true,3:true,4:true};var test_rng:=RandomNumberGenerator.new();test_rng.seed=2026101801
	var sample_count:=200000;var jure_new_count:=0;var other_new_count:=0;var duplicate_count:=0
	var ranks:Dictionary={0:0,2:0,3:0,4:0};var jure_counts:Dictionary={}
	for sample_index in range(sample_count):
		var result:Dictionary=system.draw({"normal":true},discovered,{},test_rng,true,{},unlocks,-1.0,featured,true)
		var species_id:=str(result.get("species_id",""));var stars:=int(result.get("star_rating",-1))
		var rank_key:=0 if stars<=1 else stars;ranks[rank_key]=int(ranks.get(rank_key,0))+1
		if species_id in featured:
			jure_new_count+=1;jure_counts[species_id]=int(jure_counts.get(species_id,0))+1
		elif bool(result.get("was_discovered",false)):duplicate_count+=1
		else:other_new_count+=1
	var jure_ratio:=_ratio(jure_new_count,sample_count);var other_new_ratio:=_ratio(other_new_count,sample_count);var duplicate_ratio:=_ratio(duplicate_count,sample_count)
	assert(jure_ratio>.245 and jure_ratio<.255,"mission JureJure ratio=%f"%jure_ratio)
	assert(other_new_ratio>.345 and other_new_ratio<.355,"mission other NEW ratio=%f"%other_new_ratio)
	assert(duplicate_ratio>.395 and duplicate_ratio<.405,"mission duplicate ratio=%f"%duplicate_ratio)
	assert(absf(jure_ratio+other_new_ratio-.60)<.006)
	assert(_ratio(int(ranks[0]),sample_count)>.947 and _ratio(int(ranks[0]),sample_count)<.953)
	assert(_ratio(int(ranks[2]),sample_count)>.038 and _ratio(int(ranks[2]),sample_count)<.042)
	assert(_ratio(int(ranks[3]),sample_count)>.0068 and _ratio(int(ranks[3]),sample_count)<.0092)
	assert(_ratio(int(ranks[4]),sample_count)>.0014 and _ratio(int(ranks[4]),sample_count)<.0026)
	print("JUREJURE_GACHA_DISTRIBUTION samples=%d jure_new=%.4f other_new=%.4f duplicate=%.4f ranks=%.4f/%.4f/%.4f/%.4f"%[sample_count,jure_ratio,other_new_ratio,duplicate_ratio,_ratio(int(ranks[0]),sample_count),_ratio(int(ranks[2]),sample_count),_ratio(int(ranks[3]),sample_count),_ratio(int(ranks[4]),sample_count)])
	for species_id in featured:
		var individual_ratio:=_ratio(int(jure_counts.get(species_id,0)),jure_new_count)
		assert(individual_ratio>.24 and individual_ratio<.26,"featured candidates must be uniform: %s=%f"%[species_id,individual_ratio])
	# Boundary rolls prove the 25% feature is an inner slice of rank 0, not an
	# extra NEW chance, and can never consume a fusion-rank roll.
	var boundary_rng:=RandomNumberGenerator.new();boundary_rng.seed=42
	assert(str(system.draw({"normal":true},discovered,{},boundary_rng,true,{},unlocks,.5,featured,false,.0).get("species_id","")) not in featured)
	assert(str(system.draw({"normal":true},discovered,{},boundary_rng,true,{},unlocks,.5,featured,true,.0).get("species_id","")) in featured)
	assert(str(system.draw({"normal":true},discovered,{},boundary_rng,true,{},unlocks,.5,featured,true,.3).get("species_id","")).begins_with("other_new"))
	assert(bool(system.draw({"normal":true},discovered,{},boundary_rng,true,{},unlocks,.5,featured,true,.9).get("was_discovered",false)))
	assert(int(system.draw({"normal":true},discovered,{},boundary_rng,true,{},unlocks,.96,featured,true,.0).get("star_rating",-1))==2)
	var unlocked_jurejure:Dictionary={};for species_id in featured:unlocked_jurejure[species_id]=true
	assert(str(system.draw({"normal":true,"jurejure":true},discovered,{},boundary_rng,true,unlocked_jurejure,unlocks,.5,[],true,.0).get("species_id","")) not in featured)
	var inactive_a:=RandomNumberGenerator.new();var inactive_b:=RandomNumberGenerator.new();inactive_a.seed=301;inactive_b.seed=301
	var inactive_with_ids:Dictionary=system.draw({"normal":true,"jurejure":true},discovered,{},inactive_a,true,unlocked_jurejure,unlocks,.5,featured,false,.0)
	var inactive_without_ids:Dictionary=system.draw({"normal":true,"jurejure":true},discovered,{},inactive_b,true,unlocked_jurejure,unlocks,.5,[],false,.0)
	assert(str(inactive_with_ids.get("species_id",""))==str(inactive_without_ids.get("species_id","")))
	var remaining_featured:Array[String]=["jure_b","jure_c","jure_d"]
	for sample_index in range(100):
		var pending_safe:Dictionary=system.draw({"normal":true,"jurejure":true},discovered,{},boundary_rng,true,unlocked_jurejure,unlocks,.5,remaining_featured,true,.3)
		assert(str(pending_safe.get("species_id",""))!="jure_a")
	# With no mission candidates, the established rank-local 60/40 draw is used.
	var no_feature_new:=0;test_rng.seed=2026101802
	for sample_index in range(30000):
		if not bool(system.draw({"normal":true},discovered,{},test_rng,true,{},unlocks,.5,[]).get("was_discovered",false)):no_feature_new+=1
	assert(_ratio(no_feature_new,30000)>.59 and _ratio(no_feature_new,30000)<.61)

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
	game.puku_points=9;game.forest_gacha_draw_count=0;game.forest_gacha_encountered.clear();game.discovered={"colorata":true};game.greenhouse_available={"colorata":true};game.unlocked_species=game.greenhouse_available.duplicate(true);game.unlocked_series={"base":true};game.story_progression_state["fantasy_unlocked"]=true;game.story_progression_state["pending_story_events"]=[];game.fantasy_first_discovery_seen=true;game.fantasy_realization_seen=true;game._apply_saved_unlocks();game.forest_gacha_ui.animation_time_scale=1.0
	var locked_seed:=-1
	for seed_value in range(1,100):
		var probe:=RandomNumberGenerator.new();probe.seed=seed_value
		var candidate:Dictionary=game.forest_gacha_system.draw(game.unlocked_series,game.discovered,game.forest_gacha_encountered,probe,true,game.jurejure_species_unlocked)
		if str(candidate.get("source",""))=="locked":locked_seed=seed_value;break
	assert(locked_seed>0);game.forest_gacha_rng.seed=locked_seed;game._open_forest_gacha()
	var dial_rotation_before:float=game.forest_gacha_ui.dial_texture.rotation
	game.forest_gacha_ui._request_spin()
	assert(not game.forest_gacha_ui.busy and game.forest_gacha_ui._spin_feedback_active and game.forest_gacha_ui.hint_label.text.is_empty())
	assert(game.forest_gacha_ui._spin_turn_tween!=null and game.forest_gacha_ui._spin_turn_tween.is_valid())
	assert(await _wait_until(func()->bool:return game.forest_gacha_ui.busy and not game.forest_gacha_ui._spin_feedback_active,900))
	assert(game.forest_gacha_ui.dial_texture.rotation>dial_rotation_before)
	assert(game.forest_gacha_ui.last_spin_start_latency_msec>=0 and game.forest_gacha_ui.last_spin_start_latency_msec<100)
	assert(game.forest_gacha_ui.last_spin_visual_latency_msec>=0 and game.forest_gacha_ui.last_spin_visual_latency_msec<100)
	for test_language in ["ja","hiragana","en"]:assert(Localizer.text(test_language,"gacha_selecting") not in game.forest_gacha_ui.hint_label.text)
	assert(await _wait_until(func()->bool:return game.forest_gacha_ui.capsule_ready,2500))
	assert(game.puku_balance_units==6000 and game.puku_points==6 and game.forest_gacha_draw_count==1 and game.forest_gacha_ui.capsule_ready and game.forest_gacha_ui.capsule.visible and absf(game.forest_gacha_ui.dial_texture.rotation)>1.0)
	var first_balance_after_spin_units:int=game.puku_balance_units
	var first_was_discovered:=bool(game.forest_gacha_ui.pending_result.get("was_discovered",false))
	var species_id:=str(game.forest_gacha_ui.pending_result.get("species_id",""));var series_id:=str(game.forest_gacha_ui.pending_result.get("series_id",""));assert(not species_id.is_empty() and series_id!="base" and bool(game.discovered.get(species_id,false)) and bool(game.greenhouse_available.get(species_id,false)))
	assert(series_id in game.catalog_series_unlock_notice_queue and not game.catalog_series_unlock_overlay.visible)
	game.gacha_capsule_profile_enabled=true;game.gacha_capsule_profile_total_msec=-1
	game.forest_gacha_ui._reveal_result()
	assert(game.forest_gacha_ui.busy and game.forest_gacha_ui.capsule.visible and game.forest_gacha_ui.capsule_open_burst.visible and not game.species_get_overlay.visible)
	assert(await _wait_until(func()->bool:return game.species_get_overlay.visible,900));assert(not game.catalog_series_unlock_overlay.visible and game.species_get_overlay.result_image.texture!=null and game.species_get_overlay.name_label.text==str(game._catalog_entry(species_id).get("name_ja","")))
	assert(game.species_get_overlay.duplicate_gacha_decoration_active==first_was_discovered and game.species_get_overlay.badge_label.visible!=first_was_discovered)
	assert(await _wait_until(func()->bool:return game.gacha_capsule_profile_total_msec>=0,900))
	assert(game.forest_gacha_ui.last_capsule_first_visual_latency_msec>=0 and game.forest_gacha_ui.last_capsule_first_visual_latency_msec<100 and game.gacha_capsule_profile_total_msec<200)
	assert(game.gacha_capsule_profile_started_with_placeholder and not game.forest_gacha_ui.capsule.visible and not game.forest_gacha_ui.capsule_open_burst.visible)
	for event_name in ["capsule_tap","first_visual_response","handler_entry","get_card_show_start","first_display_frame"]:assert(game.gacha_capsule_profile_events.has(event_name))
	var profile_totals:Array[int]=[];profile_totals.append(game.gacha_capsule_profile_total_msec)
	assert(await _wait_until(func()->bool:return not game.species_get_overlay.busy,900));await game.species_get_overlay.close_overlay();await get_tree().process_frame
	assert(not game.species_get_overlay.visible and game.catalog_series_unlock_overlay.visible and game.scripted_dialog_kind.is_empty())
	assert(game.catalog_series_unlock_overlay.title_label.text=="図鑑ページ解放！" and game.catalog_series_unlock_overlay.message_label.text.contains(game._catalog_series_notice_name(game._series_entry(series_id))))
	assert(str(game.catalog_cover_species.get(series_id,""))==species_id)
	assert(game.catalog_series_unlock_overlay.cover_image.texture!=null and game.catalog_series_unlock_overlay.cover_image.texture.resource_path==str(game._catalog_entry(species_id).get("image_path","")))
	game.catalog_series_unlock_overlay.busy=false;await game.catalog_series_unlock_overlay.close_overlay();await get_tree().process_frame
	assert(not game.catalog_series_unlock_overlay.visible and not game.forest_gacha_ui.busy and game.puku_balance_units==first_balance_after_spin_units)
	# Measure all three consecutive openings at production animation speed. Each
	# second call verifies that duplicate spin/reveal input still cannot charge or
	# open twice.
	for run_index in range(1,3):
		game.forest_gacha_ui._request_spin();game.forest_gacha_ui._request_spin()
		assert(await _wait_until(func()->bool:return game.forest_gacha_ui.capsule_ready,2500))
		var expected_balance_units:int=(6-run_index*3)*int(game.PUKU_UNITS_PER_PUKU)
		assert(game.puku_balance_units==expected_balance_units and game.puku_points==6-run_index*3 and game.forest_gacha_draw_count==run_index+1)
		var was_discovered:=bool(game.forest_gacha_ui.pending_result.get("was_discovered",false))
		game.gacha_capsule_profile_total_msec=-1
		game.forest_gacha_ui._reveal_result();game.forest_gacha_ui._reveal_result()
		assert(await _wait_until(func()->bool:return game.species_get_overlay.visible,900))
		assert(game.species_get_overlay.duplicate_gacha_decoration_active==was_discovered and game.species_get_overlay.badge_label.visible!=was_discovered)
		assert(await _wait_until(func()->bool:return game.gacha_capsule_profile_total_msec>=0,900))
		assert(game.forest_gacha_ui.last_capsule_first_visual_latency_msec>=0 and game.forest_gacha_ui.last_capsule_first_visual_latency_msec<100 and game.gacha_capsule_profile_total_msec<200)
		assert(game.gacha_capsule_profile_started_with_placeholder)
		for event_name in ["capsule_tap","first_visual_response","handler_entry","get_card_show_start","first_display_frame"]:assert(game.gacha_capsule_profile_events.has(event_name))
		profile_totals.append(game.gacha_capsule_profile_total_msec)
		assert(await _wait_until(func()->bool:return not game.species_get_overlay.busy,900));await game.species_get_overlay.close_overlay();await get_tree().process_frame
		if game.catalog_series_unlock_overlay.visible:
			game.catalog_series_unlock_overlay.busy=false;await game.catalog_series_unlock_overlay.close_overlay();await get_tree().process_frame
		assert(not game.species_get_overlay.visible and not game.forest_gacha_ui.busy and game.puku_balance_units==expected_balance_units)
	assert(profile_totals.size()==3)
	assert(game.puku_points==0 and game.forest_gacha_ui.spin_button.disabled and game.forest_gacha_ui.dial_hit_area.disabled)
	print("GACHA_CAPSULE_SMOKE normal_speed run1_ms=",profile_totals[0]," run2_ms=",profile_totals[1]," run3_ms=",profile_totals[2])
	game._close_forest_gacha()
	game.puku_balance_units=2000;var previous_count:int=game.forest_gacha_draw_count;game._open_forest_gacha();assert(game.forest_gacha_ui.spin_button.disabled);game._spin_forest_gacha();assert(game.forest_gacha_draw_count==previous_count and game.puku_balance_units==2000 and game.forest_gacha_pending_commit.is_empty());game._close_forest_gacha()

func _test_repeated_price_debit(game)->void:
	game.forest_gacha_pending_commit.clear();game.puku_points=115;game.forest_gacha_draw_count=0
	game.forest_gacha_ui.open_gacha(game.puku_points,game.forest_gacha_draw_count)
	for draw_index in range(38):
		var before_units:int=game.puku_balance_units
		game.forest_gacha_pending_commit={"mode":"live","result":{"species_id":"colorata"},"unlocked_series_id":"","next_draw":draw_index+1}
		game._on_forest_gacha_spin_animation_completed()
		assert(game.puku_balance_units==before_units-3*game.PUKU_UNITS_PER_PUKU)
		assert(game.forest_gacha_draw_count==draw_index+1 and game.forest_gacha_pending_commit.is_empty())
	assert(game.puku_balance_units==game.PUKU_UNITS_PER_PUKU and game.puku_points==1 and game.forest_gacha_draw_count==38)
	assert(game.forest_gacha_ui.spin_button.disabled and game.forest_gacha_ui.dial_hit_area.disabled)
	var count_before_blocked:int=game.forest_gacha_draw_count
	game._spin_forest_gacha()
	assert(game.puku_balance_units==game.PUKU_UNITS_PER_PUKU and game.forest_gacha_draw_count==count_before_blocked and game.forest_gacha_pending_commit.is_empty())
	game.forest_gacha_ui.close_gacha()
	game.forest_gacha_preview_puku_points=10;game.forest_gacha_preview_draw_count=0
	game.forest_gacha_ui.open_gacha(game.forest_gacha_preview_puku_points,game.forest_gacha_preview_draw_count)
	game.forest_gacha_pending_commit={"mode":"preview","result":{"species_id":"colorata"},"unlocked_series_id":"","next_draw":1}
	game._on_forest_gacha_spin_animation_completed()
	assert(game.forest_gacha_preview_puku_points==7 and game.forest_gacha_preview_draw_count==1 and game.forest_gacha_ui.current_puku_points==7)
	game.forest_gacha_ui.close_gacha()

func _test_encounter_save_and_unlock(game)->void:
	var target_id:="gummy_peach_milk";game.unlocked_series.erase("gummy");game.discovered.erase(target_id);game.greenhouse_available.erase(target_id);game.unlocked_species.erase(target_id);game.forest_gacha_encountered={target_id:true};game.forest_gacha_draw_count=9;game.act2_unlocked=true;game.forest_gacha_unlocked=true;game.forest_gacha_intro_seen=true;game._save();game.forest_gacha_encountered.clear();game.forest_gacha_draw_count=0;game.act2_unlocked=false;game.forest_gacha_unlocked=false;game.forest_gacha_intro_seen=false;game._load_save();assert(game.forest_gacha_draw_count==9 and bool(game.forest_gacha_encountered.get(target_id,false)) and not bool(game.discovered.get(target_id,false)))
	assert(game.act2_unlocked and game.forest_gacha_unlocked and game.forest_gacha_intro_seen)
	var registered:Array[String]=game._unlock_series_and_register_encounters("gummy");assert(target_id in registered and bool(game.discovered.get(target_id,false)) and bool(game.greenhouse_available.get(target_id,false)))
	game.unlocked_series.erase("gummy");game.discovered.erase(target_id);game.greenhouse_available.erase(target_id);game.unlocked_species.erase(target_id);game.forest_gacha_encountered={target_id:true};game.puku_points=5;game.forest_gacha_ui.open_gacha(game.puku_points,game.forest_gacha_draw_count);game._unlock_forest_gacha_series("gummy",target_id);assert(game.puku_points==5 and bool(game.unlocked_series.get("gummy",false)) and bool(game.discovered.get(target_id,false)) and game.forest_gacha_ui.result_badge.text=="NEW!")
	game.unlocked_series.erase("gummy");game.discovered.erase(target_id);game.greenhouse_available.erase(target_id);game.unlocked_species.erase(target_id);game.forest_gacha_encountered={target_id:true};game._unlock_series_and_register_encounters("gummy");assert(bool(game.discovered.get(target_id,false)))
	game.forest_gacha_ui.show_later_message("この品種は不思議な図鑑へ自動で記録されます。",0,10);assert("自動で記録" in game.forest_gacha_ui.result_message.text)

func _wait_until(predicate:Callable,timeout_msec:int)->bool:
	var deadline:=Time.get_ticks_msec()+timeout_msec
	while Time.get_ticks_msec()<deadline:
		if bool(predicate.call()):return true
		await get_tree().process_frame
	return bool(predicate.call())
