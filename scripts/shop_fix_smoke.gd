extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.intro_story_complete=true;game.total_play_count=3;game.habitat_unlocked=true;game.encyclopedia_unlocked=true;game.buyback_unlocked=true
	game.tutorial_steps["habitat_scroll_dialog"]=true;game.tutorial_steps["habitat_get_dialog"]=true;game.tutorial_steps["play1_dialog"]=true
	game.shop_overlay.visible=true;game._prepare_shop_visit(true);game._on_armadillo_tapped()
	assert(game.shop_chatter_acquired_species==["pinwheel"] and bool(game.discovered.get("pinwheel",false)))
	game._hide_shop_chatter(true);assert(game.shop_chatter_acquired_species.is_empty())
	game._show_shop_chatter("いらっしゃい！",false,"normal","panda");assert(game.shop_chatter_acquired_species.is_empty())
	game._hide_shop_chatter(true);await get_tree().process_frame;assert(game.shop_chatter_acquired_species.is_empty())
	game.mystery_seed_count=4;game.armadillo_research_total=9;game._accept_armadillo_research()
	assert(game.shop_transfer_notice.visible and game.shop_transfer_notice.text=="渡した謎のたね ×13個" and game.shop_transfer_notice.get_parent()!=game.shop_overlay and game.shop_transfer_notice.get_theme_font_size("font_size")>=19)
	game._hide_shop_chatter(true);assert(not game.shop_transfer_notice.visible)
	game.formal_play_count=3;game.volume_seed_unlocked=false;game.premium_seed_unlocked=false;game._select_shop_product("volume")
	assert(game.shop_bag_label.text=="たね袋を1袋ずつ購入できます" and "あと4回プレイで解禁" in game.shop_product_detail_label.text)
	game._select_shop_product("premium");assert("あと10回プレイで解禁" in game.shop_product_detail_label.text and game.shop_product_detail_label.get_theme_font_size("font_size")>=15)
	game.coins=500;var bags_before:int=game.normal_seed_bags;game._buy_seed_bag("normal");assert(game.coins==0 and game.normal_seed_bags==bags_before+1)
	game._buy_seed_bag("normal");assert(game.coins==0 and game.normal_seed_bags==bags_before+1)
	assert(str(game._catalog_entry("strictiflora_bustamante").name_ja)=="ストリクチフローラ　ブスタマンテ")
	print("SHOP_FIX_SMOKE_OK")
	get_tree().quit()
