extends Node

const FIRST_FIVE:=5

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.encyclopedia_unlocked=true;game.habitat_unlocked=true;game.habitat_tutorial_complete=true;game.puku_gauge_intro_complete=true;game.total_play_count=3;game.puku_points=20;game._update_play_ui()
	_test_assets_and_routes(game)
	_test_draw_rules(game)
	await _test_spin_capsule_and_reveal(game)
	_test_encounter_save_and_unlock(game)
	game._reset_progression_state();game.queue_free()
	print("FOREST_GACHA_SMOKE_OK routes=2 first5=unlocked locked=18% capsule=reveal encounter=save+autoregister checker=masked")
	get_tree().quit()

func _test_assets_and_routes(game)->void:
	assert(game.forest_gacha_button!=null and game.forest_gacha_button.position.y<game.secret_gacha_button.position.y and game.forest_gacha_button.size==game.secret_gacha_button.size)
	var shop_route:=game.shop_overlay.find_child("ShopForestGachaButton",true,false) as Button;assert(shop_route!=null and shop_route.text.contains("ガチャ"))
	var background:=game.forest_gacha_ui.find_child("Background",true,false) as TextureRect;assert(background!=null and background.texture.resource_path=="res://assets/forest_gacha/forest-gacha-background.jpg")
	assert(background.material is ShaderMaterial and (background.material as ShaderMaterial).shader.code.contains("color.a *= opaque_mask"))
	var dial:=game.forest_gacha_ui.find_child("TemporaryDial",true,false) as TextureRect;assert(dial!=null and dial.texture.resource_path=="res://assets/forest_gacha/temporary-dial.png")
	var dial_image:=dial.texture.get_image();assert(dial_image!=null and dial_image.detect_alpha()!=Image.ALPHA_NONE and dial_image.get_pixel(0,0).a<.01)
	game._open_shop();assert(game.shop_overlay.visible);shop_route.pressed.emit();assert(game.forest_gacha_ui.visible and not game.shop_overlay.visible);game._close_forest_gacha()
	game._open_forest_gacha();assert(game.forest_gacha_ui.visible);game._close_forest_gacha()

func _test_draw_rules(game)->void:
	var test_rng:=RandomNumberGenerator.new();test_rng.seed=20260909
	var unlocked:Dictionary={"common":true};var encountered:Dictionary={};var known:Dictionary={"nijinotama":true}
	for draw_number in range(1,FIRST_FIVE+1):
		var first_result:Dictionary=game.forest_gacha_system.draw(draw_number,unlocked,known,encountered,test_rng,0.0);assert(first_result.source=="unlocked" and str(first_result.series_id)=="common")
	var locked_result:Dictionary=game.forest_gacha_system.draw(6,unlocked,known,encountered,test_rng,0.0);assert(locked_result.source=="locked" and str(locked_result.series_id)!="neon" and not game._is_hidden_series(str(locked_result.series_id)))
	var normal_result:Dictionary=game.forest_gacha_system.draw(6,unlocked,known,encountered,test_rng,.99);assert(normal_result.source=="unlocked")
	var locked_count:=0
	for sample_index in range(5000):
		if str(game.forest_gacha_system.draw(6,unlocked,known,encountered,test_rng).source)=="locked":locked_count+=1
	var locked_ratio:=float(locked_count)/5000.0;assert(locked_ratio>.15 and locked_ratio<.21)
	for locked_series in game.forest_gacha_system.eligible_series(false,unlocked):assert(not game._is_hidden_series(str(locked_series.get("series_id",""))))
	var all_known:Dictionary={};for species_entry in game.forest_gacha_system.eligible_species("common"):all_known[str(species_entry.species_id)]=true
	all_known.erase("lola");var preferred:Dictionary=game.forest_gacha_system.draw(1,unlocked,all_known,{},test_rng,.99);assert(str(preferred.species_id)=="lola")

func _test_spin_capsule_and_reveal(game)->void:
	game.puku_points=2;game.forest_gacha_draw_count=0;game.forest_gacha_encountered.clear();game.discovered={"nijinotama":true};game.greenhouse_available={"nijinotama":true};game.unlocked_species=game.greenhouse_available.duplicate(true);game.unlocked_series={"common":true};game._apply_saved_unlocks();game.forest_gacha_ui.animation_time_scale=.02;game._open_forest_gacha()
	game._spin_forest_gacha();await get_tree().create_timer(.45).timeout
	assert(game.puku_points==1 and game.forest_gacha_draw_count==1 and game.forest_gacha_ui.capsule_ready and game.forest_gacha_ui.capsule.visible and absf(game.forest_gacha_ui.dial_texture.rotation)>1.0)
	var species_id:=str(game.forest_gacha_ui.pending_result.get("species_id",""));assert(not species_id.is_empty() and bool(game.discovered.get(species_id,false)) and bool(game.greenhouse_available.get(species_id,false)))
	game.forest_gacha_ui._reveal_result();await get_tree().process_frame;assert(game.species_get_overlay.visible and game.species_get_overlay.result_image.texture!=null and game.species_get_overlay.name_label.text==str(game._catalog_entry(species_id).get("name_ja","")))
	game.species_get_overlay.busy=false;game.species_get_overlay.close_overlay();await get_tree().create_timer(.2).timeout;assert(not game.species_get_overlay.visible);game._close_forest_gacha()
	game.puku_points=0;var previous_count:int=game.forest_gacha_draw_count;game._open_forest_gacha();game._spin_forest_gacha();assert(game.forest_gacha_draw_count==previous_count and game.puku_points==0);game._close_forest_gacha()

func _test_encounter_save_and_unlock(game)->void:
	var target_id:="gummy_peach_milk";game.unlocked_series.erase("gummy");game.discovered.erase(target_id);game.greenhouse_available.erase(target_id);game.unlocked_species.erase(target_id);game.forest_gacha_encountered={target_id:true};game.forest_gacha_draw_count=9;game._save();game.forest_gacha_encountered.clear();game.forest_gacha_draw_count=0;game._load_save();assert(game.forest_gacha_draw_count==9 and bool(game.forest_gacha_encountered.get(target_id,false)) and not bool(game.discovered.get(target_id,false)))
	var registered:Array[String]=game._unlock_series_and_register_encounters("gummy");assert(target_id in registered and bool(game.discovered.get(target_id,false)) and bool(game.greenhouse_available.get(target_id,false)))
	game.unlocked_series.erase("gummy");game.discovered.erase(target_id);game.greenhouse_available.erase(target_id);game.unlocked_species.erase(target_id);game.forest_gacha_encountered={target_id:true};game.puku_points=5;game.forest_gacha_ui.open_gacha(game.puku_points,game.forest_gacha_draw_count);game._unlock_forest_gacha_series("gummy",target_id);assert(game.puku_points==0 and bool(game.unlocked_series.get("gummy",false)) and bool(game.discovered.get(target_id,false)) and game.forest_gacha_ui.result_badge.text=="NEW!")
	game.unlocked_series.erase("gummy");game.discovered.erase(target_id);game.greenhouse_available.erase(target_id);game.unlocked_species.erase(target_id);game.forest_gacha_encountered={target_id:true};game._unlock_series_and_register_encounters("gummy");assert(bool(game.discovered.get(target_id,false)))
	game.forest_gacha_ui.show_later_message("今回は登録されませんが、\nあとでこの図鑑を解放すると、\nこの品種も図鑑に登録されます。",0,10);assert("あとでこの図鑑を解放" in game.forest_gacha_ui.result_message.text)
