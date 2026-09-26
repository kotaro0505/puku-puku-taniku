extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state()
	game._update_play_ui();assert(not game.shop_button.visible)
	var visits_before:int=game.shop_visit_count;game._open_shop();assert(not game.shop_overlay.visible and game.shop_visit_count==visits_before)
	game.intro_story_complete=true;game.first_colorata_confirmed=true;game.trio_originals_confirmed=true;game.total_play_count=3
	game.habitat_unlocked=true;game.habitat_awakened=true;game.habitat_awakening_event_complete=true;game.habitat_tutorial_complete=true
	game.mystery_items_acquired=true;game.mystery_catalog_tutorial_complete=true;game.encyclopedia_unlocked=true;game.seed_shop_open=true
	game.puku_gauge_intro_complete=true
	game._update_play_ui();assert(game.shop_button.visible and game.shop_button.text=="パンダのお店")
	game._open_shop();assert(game.shop_overlay.visible and game.shop_current_page=="categories" and game.shop_category_controls[0].is_visible_in_tree())
	assert(game.find_child("ShopCategoryCatalog",true,false)==null)
	assert(game.find_child("ShopCategorySeed",true,false)==null)
	assert(game.find_child("ShopCategoryPot",true,false)!=null and game.find_child("ShopForestGachaButton",true,false)!=null)

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

	game._prepare_shop_visit(true);game._on_armadillo_tapped();assert(game.shop_chatter_sequence_kind=="pinwheel_intro" and not bool(game.discovered.get("pinwheel",false)))
	while game.shop_chatter_bubble.visible:game._dismiss_or_advance_shop_chatter()
	assert(bool(game.discovered.get("pinwheel",false)))
	await get_tree().process_frame
	if game.species_get_overlay.visible:
		game.species_get_overlay.busy=false;game.species_get_overlay.close_overlay();await get_tree().create_timer(.2).timeout
	if game.scripted_dialog_kind=="armadillo_mystery_intro":game._finish_scripted_dialog()

	game._save();game.mystery_items_acquired=false;game.encyclopedia_unlocked=false;game.seed_shop_open=false;game._load_save();game._update_play_ui()
	assert(game.mystery_items_acquired and game.encyclopedia_unlocked and game.seed_shop_open and game.shop_button.visible)
	print("SHOP_FIX_SMOKE_OK shop=panda items=pots+gacha beacon=retired normal_seed_sale=removed catalog_sale=removed")
	get_tree().quit()
