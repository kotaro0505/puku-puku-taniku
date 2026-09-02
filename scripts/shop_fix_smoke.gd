extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state()
	game._update_play_ui();assert(not game.shop_button.visible)
	var visits_before:int=game.shop_visit_count;game._open_shop();assert(not game.shop_overlay.visible and game.shop_visit_count==visits_before)
	game.intro_story_complete=true;game.total_play_count=3;game.habitat_unlocked=true;game.encyclopedia_unlocked=true;game.buyback_unlocked=true
	game.tutorial_steps["habitat_scroll_dialog"]=true;game.tutorial_steps["habitat_get_dialog"]=true;game.tutorial_steps["play1_dialog"]=true
	game._update_play_ui();assert(game.shop_button.visible)

	game.volume_seed_unlocked=true;game.volume_seed_intro_seen=false;game.tutorial_steps["volume_intro_step"]=0
	game.shop_overlay.visible=true;game._prepare_shop_visit(false)
	assert(game.shop_chatter_sequence_kind=="volume_intro" and "新しいたねを入荷したよ！" in game.shop_chatter_label.text)
	game._dismiss_or_advance_shop_chatter();assert(game.shop_chatter_bubble.visible and "36粒入ってるから" in game.shop_chatter_label.text)
	game._dismiss_or_advance_shop_chatter();assert(not game.shop_chatter_bubble.visible and game.volume_seed_intro_seen)

	game._prepare_shop_visit(true);game._on_armadillo_tapped();assert(game.shop_chatter_sequence_kind=="pinwheel_intro" and not bool(game.discovered.get("pinwheel",false)))
	game._dismiss_or_advance_shop_chatter();assert("君も多肉" in game.shop_chatter_label.text and not bool(game.discovered.get("pinwheel",false)))
	game._dismiss_or_advance_shop_chatter();assert("ピンウィールという品種" in game.shop_chatter_label.text and not bool(game.discovered.get("pinwheel",false)))
	game._dismiss_or_advance_shop_chatter();assert(bool(game.discovered.get("pinwheel",false)) and not game.shop_chatter_bubble.visible)
	await get_tree().process_frame
	game._show_shop_chatter("いらっしゃい！",false,"normal","panda");assert(game.shop_chatter_acquired_species.is_empty())
	game._hide_shop_chatter(true);await get_tree().process_frame;assert(game.shop_chatter_acquired_species.is_empty())

	game.mystery_seed_count=3;game.armadillo_research_intro_seen=false;game._start_armadillo_research()
	assert(not game.shop_chatter_action_button.visible and "おや？" in game.shop_chatter_label.text)
	game._dismiss_or_advance_shop_chatter();assert(not game.shop_chatter_action_button.visible and "じつはぼく" in game.shop_chatter_label.text)
	game._dismiss_or_advance_shop_chatter();assert(game.shop_chatter_action_button.visible and game.shop_chatter_decline_button.visible and "研究させてもらえないかな" in game.shop_chatter_label.text)
	game._decline_armadillo_research();assert(game.mystery_seed_count==3 and not game.shop_chatter_bubble.visible)
	game._start_armadillo_research();game.armadillo_research_total=10;game._accept_armadillo_research()
	assert(game.mystery_seed_count==0 and game.armadillo_research_total==13 and game.shop_transfer_notice.visible and game.shop_transfer_notice.text=="渡した謎のたね ×13個")
	game._hide_shop_chatter(true);assert(not game.shop_transfer_notice.visible)

	game.formal_play_count=2;game.volume_seed_unlocked=false;game.premium_seed_unlocked=false;game.coins=500;game._select_shop_product("normal")
	assert(game.shop_buy_glow.visible)
	game._select_shop_product("volume");assert("あと1回プレイで解禁" in game.shop_product_detail_label.text and "お得な大容量。じっくり大物を狙えます。" in game.shop_product_detail_label.text and not "36粒入りのお得" in game.shop_product_detail_label.text and not game.shop_buy_glow.visible)
	game._select_shop_product("premium");assert("あと11回プレイで解禁" in game.shop_product_detail_label.text and "24粒 / 袋" in game.shop_product_detail_label.text)
	game._select_shop_product("normal");var bags_before:int=game.normal_seed_bags;game._buy_seed_bag("normal")
	assert(game.coins==0 and game.normal_seed_bags==bags_before+1 and not game.shop_buy_glow.visible)
	var purchase_stream=game.audio_manager._stream_for("se","purchase");var purchase_heard:=false
	for player in game.audio_manager.se_players:
		if player.playing and player.stream==purchase_stream:purchase_heard=true
	assert(purchase_heard)
	for player in game.audio_manager.se_players:player.stop()
	game._buy_seed_bag("normal");assert(game.coins==0 and game.normal_seed_bags==bags_before+1)
	for player in game.audio_manager.se_players:assert(not player.playing)
	game._save();game.intro_story_complete=false;game.habitat_unlocked=false;game.buyback_unlocked=false;game.total_play_count=0;game._load_save();game._update_play_ui();assert(game._tutorial_fully_complete() and game.shop_button.visible)
	print("SHOP_FIX_SMOKE_OK")
	get_tree().quit()
