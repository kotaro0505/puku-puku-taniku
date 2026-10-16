extends Node

const Localizer=preload("res://scripts/game_localizer.gd")

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state()
	game._update_play_ui();assert(not game.shop_button.visible)
	var visits_before:int=game.shop_visit_count;game._open_shop();assert(not game.shop_overlay.visible and game.shop_visit_count==visits_before)
	game.intro_story_complete=true;game.first_colorata_confirmed=true;game.trio_originals_confirmed=true;game.total_play_count=3
	game.habitat_unlocked=true;game.habitat_awakened=true;game.habitat_awakening_event_complete=true;game.habitat_tutorial_complete=true
	game.mystery_items_acquired=true;game.mystery_catalog_tutorial_complete=true;game.encyclopedia_unlocked=true;game.seed_shop_open=true
	game.puku_gauge_intro_complete=true;game.puku_points=2;game.normal_seed_bags=1
	game._update_play_ui();assert(game.shop_button.visible and game.shop_button.text=="パンダのお店")
	game._open_shop();assert(game.shop_overlay.visible and game.shop_current_page=="categories" and not game.shop_category_controls[0].is_visible_in_tree())
	assert(game.find_child("ShopCategoryCatalog",true,false)==null)
	assert(game.find_child("ShopCategorySeed",true,false)==null)
	var pot_category:=game.find_child("ShopCategoryPot",true,false) as Button
	var gacha_category:=game.find_child("ShopForestGachaButton",true,false) as Button
	assert(pot_category!=null and gacha_category!=null and not pot_category.is_visible_in_tree() and not gacha_category.is_visible_in_tree())
	assert(game.shop_chatter_bubble.visible and game.shop_chatter_portrait.visible and game.shop_chatter_label.text=="いらっしゃい！まだ準備中なんだ！")
	for locale in ["ja","hiragana","en"]:assert(not Localizer.text(locale,"shop_preparing_arrangement").is_empty())
	game._close_shop()
	game.puku_points=0;game.normal_seed_bags=0;game.volume_seed_bags=0;game.premium_seed_bags=0;game._open_shop()
	assert(not game.shop_category_controls[0].is_visible_in_tree() and game.armadillo_dialog_mode=="rescue" and game.shop_chatter_action_button.visible)
	game._close_shop();game.puku_points=2;game.normal_seed_bags=1
	game.story_progression_state["arrangement_unlocked"]=true;game.story_progression_state["arrangement_intro_seen"]=true
	game.forest_gacha_unlocked=false;game.forest_gacha_intro_seen=false;game._open_shop()
	assert(game.shop_category_controls[0].is_visible_in_tree() and pot_category.is_visible_in_tree() and not gacha_category.is_visible_in_tree())
	assert(pot_category.text=="鉢" and is_equal_approx(pot_category.position.x,170.0))
	game.forest_gacha_unlocked=true;game.forest_gacha_intro_seen=true;game._update_play_ui()
	assert(gacha_category.is_visible_in_tree() and is_equal_approx(pot_category.position.x,82.0))

	var products:Array=game._seed_shop_products();assert(products.is_empty())
	game.puku_points=2;var bags_before:int=game.normal_seed_bags
	game._buy_seed_bag("normal")
	game._buy_seed_bag("panda_beacon")
	assert(game.puku_points==2 and game.normal_seed_bags==bags_before and game.panda_beacon_count==0)

	var points_before_catalog:int=game.puku_points;game.unlocked_series.erase("metal");game._on_catalog_purchase_requested("metal")
	assert(game.puku_points==points_before_catalog and not bool(game.unlocked_series.get("metal",false)))
	game._open_shop_pot_category();assert(game.arrangement_ui.visible and game.arrangement_ui.shop_page.visible and game.arrangement_ui.return_context=="shop")
	game.arrangement_ui.close();assert(game.shop_current_page=="categories" and game.shop_category_controls[0].is_visible_in_tree())

	game.volume_seed_unlocked=true;game.volume_seed_intro_seen=false;game.shop_overlay.visible=true;game._prepare_shop_visit(false)
	assert(game.shop_chatter_sequence_kind!="volume_intro")

	game._prepare_shop_visit(true);game._queue_armadillo_progress_event()
	assert(game.pending_armadillo_story_event.is_empty() and game.shop_chatter_sequence_kind!="pinwheel_intro")
	assert(not bool(game.discovered.get("pinwheel",false)))

	game._save();game.mystery_items_acquired=false;game.encyclopedia_unlocked=false;game.seed_shop_open=false;game._load_save();game._update_play_ui()
	assert(game.mystery_items_acquired and game.encyclopedia_unlocked and game.seed_shop_open and game.shop_button.visible)
	print("SHOP_FIX_SMOKE_OK locked=preparing unlocked=pot centered gacha=8get rescue=preserved beacon=retired")
	get_tree().quit()
