extends Node

const ServiceClass = preload("res://scripts/pot_unlock_iap_service.gd")
const MockClass = preload("res://scripts/pot_unlock_iap_mock.gd")
const ArrangementUIClass = preload("res://scripts/arrangement_ui.gd")
const Localizer = preload("res://scripts/game_localizer.gd")

const EXPECTED_PRICE_GROUPS := {
	1: ["shallow_terracotta", "classic_terracotta"],
	2: ["black_ceramic", "white_ceramic", "clear_crystal", "amethyst_crystal", "glass_bowl", "tin_bucket", "g1_crystal_goblet", "g1_green_glass", "g1_silver_metal", "g1_white_bowl", "g1_terracotta_tall", "g1_pearl_pink", "g1_wood_barrel", "g1_blue_diamond", "g1_rock_bowl"],
	3: ["g1_rose_gold_glass"],
	30: ["g1_gold_jackpot", "g1_flamingo_resort", "g1_crown_watch", "g1_magenta_supercar"],
	5: ["g2_shell_coral", "g2_weathered_stump", "g2_concrete_round", "g2_rough_rock", "g2_stardust_moon", "g2_amber_crystal", "g2_antique_fleur", "g2_rusty_bucket", "g2_aurora_pearl"],
	10: ["g2_neon_crystal", "g2_king_money", "g2_retro_arcade", "g2_royal_jewel", "g2_jellyfish_aqua", "g2_red_jackpot", "g2_sleepy_moon", "g2_disco_mirror", "g2_ufo", "g2_forest_stump", "g2_flower_meadow", "g2_mossy_forest"],
	100: ["g2_ramen_bowl"],
}

func _ready()->void:
	assert(ServiceClass.TRANSACTION_PURCHASED==3 and ServiceClass.TRANSACTION_RESTORED==4 and ServiceClass.TRANSACTION_CANCELED==6)
	var initial:=_read_array("res://data/pots.json")
	var paid:=_read_array("res://data/pot-iap-catalog.json")
	assert(initial.size()==8)
	assert(paid.size()==36)
	var all_pots:Array=initial+paid
	var expected_prices:Dictionary={}
	for expected_price_value in EXPECTED_PRICE_GROUPS:
		for expected_pot_id_value in EXPECTED_PRICE_GROUPS[expected_price_value]:
			var expected_pot_id:=str(expected_pot_id_value)
			assert(not expected_prices.has(expected_pot_id))
			expected_prices[expected_pot_id]=int(expected_price_value)
	assert(expected_prices.size()==44)
	var pot_ids:Dictionary={}
	var product_ids:Dictionary={}
	var group_1_count:=0
	var group_2_count:=0
	for pot_value in all_pots:
		assert(pot_value is Dictionary)
		var pot:Dictionary=pot_value
		for key in ["pot_id","display_name","image_path","sales_group","unlock_type","iap_product_id","price_puku"]:assert(pot.has(key))
		var pot_id:=str(pot.pot_id);assert(not pot_id.is_empty() and not pot_ids.has(pot_id));pot_ids[pot_id]=true
		assert(expected_prices.has(pot_id) and int(pot.price_puku)==int(expected_prices[pot_id]))
		if str(pot.unlock_type)=="iap_unlock":
			var product_id:=str(pot.iap_product_id);assert(not product_id.is_empty() and not product_ids.has(product_id));product_ids[product_id]=true
			assert(product_id=="pot_unlock_%03d"%(product_ids.size()))
			assert(int(pot.sales_stage) in [1,2])
			if str(pot.sales_group)=="group_1":group_1_count+=1
			elif str(pot.sales_group)=="group_2":group_2_count+=1
			else:assert(false)
			var texture:=load(str(pot.image_path)) as Texture2D;assert(texture!=null)
			# Source PNGs stay at full resolution; the runtime texture is capped to
			# 512 px so the root Web PCK remains publishable on GitHub Pages.
			var image:=texture.get_image();assert(image.get_width()==512 and image.get_height()==512)
			assert(image.get_pixel(0,0).a<.05 and image.get_pixel(image.get_width()-1,image.get_height()-1).a<.05)
		else:
			assert(str(pot.unlock_type)=="free" and str(pot.sales_group)=="initial" and str(pot.iap_product_id).is_empty())
	assert(group_1_count==14 and group_2_count==22 and product_ids.size()==36)
	var sorted_pots:Array=all_pots.duplicate(true);sorted_pots.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.sort_order)<int(b.sort_order))
	assert(sorted_pots.size()==44)
	assert(str(sorted_pots[16].pot_id)=="g1_rock_bowl" and int(sorted_pots[16].price_puku)==2)
	assert(str(sorted_pots[17].pot_id)=="g1_rose_gold_glass" and int(sorted_pots[17].price_puku)==3)
	assert(str(sorted_pots[18].pot_id)=="g1_gold_jackpot" and str(sorted_pots[21].pot_id)=="g1_magenta_supercar" and int(sorted_pots[18].price_puku)==30 and int(sorted_pots[21].price_puku)==30)
	assert(str(sorted_pots[22].pot_id)=="g2_shell_coral" and int(sorted_pots[22].price_puku)==5)
	assert(str(sorted_pots[30].pot_id)=="g2_aurora_pearl" and int(sorted_pots[30].price_puku)==5)
	assert(str(sorted_pots[31].pot_id)=="g2_neon_crystal" and int(sorted_pots[31].price_puku)==10)
	assert(str(sorted_pots[42].pot_id)=="g2_mossy_forest" and int(sorted_pots[42].price_puku)==10)
	assert(str(sorted_pots[43].pot_id)=="g2_ramen_bowl" and int(sorted_pots[43].price_puku)==100)

	var prices:Dictionary={}
	for product_id in product_ids:prices[product_id]="€0,99"
	var first_product:="pot_unlock_001"
	var last_product:="pot_unlock_036"
	var mock:=MockClass.new();mock.localized_prices=prices.duplicate(true)
	var service:=ServiceClass.new();add_child(service);service.configure(all_pots,{},mock)
	await get_tree().process_frame
	assert(service.restore_available() and service.using_test_bridge())
	assert(str(service.product_states_snapshot()[first_product].localized_price)=="€0,99")
	assert(str(service.product_states_snapshot()[first_product].status)==service.STATUS_AVAILABLE)
	assert(service.purchase(first_product));assert(service.is_unlocked(first_product) and mock.purchase_calls.size()==1)
	assert(not service.purchase(first_product) and mock.purchase_calls.size()==1)
	var failure_mock:=MockClass.new();failure_mock.localized_prices=prices.duplicate(true);failure_mock.next_purchase_error="declined"
	var failure_service:=ServiceClass.new();add_child(failure_service);failure_service.configure(all_pots,{},failure_mock)
	await get_tree().process_frame
	assert(failure_service.purchase(first_product));assert(not failure_service.is_unlocked(first_product))
	assert(str(failure_service.product_states_snapshot()[first_product].status)==failure_service.STATUS_AVAILABLE)

	var restore_mock:=MockClass.new();restore_mock.localized_prices=prices.duplicate(true);restore_mock.restore_entitlements={first_product:true,last_product:true}
	var restore_service:=ServiceClass.new();add_child(restore_service);restore_service.configure(all_pots,{},restore_mock)
	await get_tree().process_frame
	assert(not restore_service.is_unlocked(first_product));assert(restore_service.restore_purchases())
	assert(restore_mock.sync_calls==1 and restore_service.is_unlocked(first_product) and restore_service.is_unlocked(last_product) and not restore_service.restore_in_progress())

	# Production desktop/Web has no StoreKit bridge. It must never simulate a
	# charge or invent a price; only the isolated test bridge above can do that.
	var safe_service:=ServiceClass.new();add_child(safe_service);safe_service.configure(all_pots,{})
	assert(not safe_service.restore_available() and not safe_service.purchase(first_product))
	assert(str(safe_service.product_states_snapshot()[first_product].status)==safe_service.STATUS_UNAVAILABLE)
	assert(str(safe_service.product_states_snapshot()[first_product].localized_price).is_empty())

	var ui:=ArrangementUIClass.new();add_child(ui);await get_tree().process_frame
	var owned:Dictionary={"shallow_terracotta":1}
	ui.configure([],[],all_pots,{},owned,[],20,5,Callable(),Callable(),{},"ja",0,{},service.product_states_snapshot(),false,false)
	ui.open_pot_shop();assert(ui.shop_grid.get_child_count()==8 and not ui.shop_restore_button.visible)
	ui.configure([],[],all_pots,{},owned,[],20,5,Callable(),Callable(),{},"ja",1,{},service.product_states_snapshot(),false,false)
	ui.open_pot_shop();assert(ui.shop_grid.get_child_count()==22 and ui.shop_restore_button.visible and ui.shop_restore_button.disabled)
	var first_paid_card:Node=ui.shop_grid.get_child(8);var unlock_buttons:=first_paid_card.find_children("*","Button",true,false)
	var first_locked_price:=first_paid_card.find_child("PotLockedPukuPrice",true,false) as Label
	assert(unlock_buttons.size()==1 and "€0,99" in (unlock_buttons[0] as Button).text and not (unlock_buttons[0] as Button).disabled and not bool((unlock_buttons[0] as Button).get_meta("puku_purchase",true)))
	assert(first_locked_price!=null and first_locked_price.visible and first_locked_price.text=="価格：2ぷくコイン" and first_locked_price.get_theme_font_size("font_size")==18)
	assert((unlock_buttons[0] as Button).get_theme_font_size("font_size")==19)
	ui.open_home();assert(ui.home_page.visible and ui.pot_select_grid.get_child_count()==22)
	var first_paid_select:=ui.pot_select_grid.get_child(8) as Button;assert(first_paid_select.disabled and _has_label_text_containing(first_paid_select,"デザイン未アンロック"))
	var unlocks:Dictionary={first_product:true}
	ui.configure([],[],all_pots,{},owned,[],20,5,Callable(),Callable(),{},"ja",1,unlocks,service.product_states_snapshot(),false,false)
	ui._refresh_pot_selection();first_paid_select=ui.pot_select_grid.get_child(8) as Button;assert(first_paid_select.disabled and _has_label_text_containing(first_paid_select,"未所持"))
	owned["g1_crystal_goblet"]=1;ui.sync_state(owned,[],20);first_paid_select=ui.pot_select_grid.get_child(8) as Button;assert(not first_paid_select.disabled and _has_label_text_containing(first_paid_select,"使用可能 ×1"))
	ui.open_pot_shop();first_paid_card=ui.shop_grid.get_child(8);var puku_buttons:=first_paid_card.find_children("*","Button",true,false);var owned_label:=first_paid_card.find_child("PotOwnedTotal",true,false) as Label
	assert(puku_buttons.size()==1 and "2ぷくコイン" in (puku_buttons[0] as Button).text and (puku_buttons[0] as Button).get_theme_font_size("font_size")==19 and bool((puku_buttons[0] as Button).get_meta("puku_purchase",false)))
	assert(owned_label!=null and owned_label.get_theme_font_size("font_size")==17 and not (first_paid_card.find_child("PotLockedPukuPrice",true,false) as Label).visible)
	ui.configure([],[],all_pots,{},owned,[],20,5,Callable(),Callable(),{},"ja",2,unlocks,service.product_states_snapshot(),false,false);ui.open_pot_shop();assert(ui.shop_grid.get_child_count()==44)

	for locale in ["ja","hiragana","en"]:
		for key in ["pot_not_owned","pot_iap_locked_short","pot_unlock_required","pot_permanent_unlock","pot_locked_puku_price","pot_unlock_success","iap_unlock_for_price","iap_price_loading","iap_purchase_unavailable","iap_restore_purchases","iap_restore_complete"]:assert(Localizer.text(locale,key)!=key)
		ui.configure([],[],all_pots,{},owned,[],200,5,Callable(),Callable(),{},locale,2,{},service.product_states_snapshot(),false,false);ui.open_pot_shop();await get_tree().process_frame
		var locked_ramen_card:=_pot_shop_card(ui,"g2_ramen_bowl");var locked_ramen_price:=locked_ramen_card.find_child("PotLockedPukuPrice",true,false) as Label
		assert(locked_ramen_price.visible and locked_ramen_price.text==Localizer.text(locale,"pot_locked_puku_price",[100]) and locked_ramen_price.get_theme_font_size("font_size")==18)
		ui.configure([],[],all_pots,{},owned,[],200,5,Callable(),Callable(),{},locale,2,{last_product:true},service.product_states_snapshot(),false,false);ui.open_pot_shop();await get_tree().process_frame
		var ramen_card:=_pot_shop_card(ui,"g2_ramen_bowl");var ramen_buy:=ramen_card.find_child("PotBuyButton",true,false) as Button;var ramen_owned:=ramen_card.find_child("PotOwnedTotal",true,false) as Label
		assert(ramen_buy.text==Localizer.text(locale,"buy_puku",[100]) and ramen_buy.get_theme_font_size("font_size")==19 and ramen_buy.get_minimum_size().x<=ramen_buy.size.x)
		assert(ramen_owned.get_theme_font_size("font_size")==17 and ramen_owned.get_minimum_size().x<=ramen_owned.size.x)
	for source_path in ["res://data/pot-iap-catalog.json","res://scripts/pot_unlock_iap_service.gd","res://scripts/arrangement_ui.gd","res://scripts/main.gd"]:
		var source:=FileAccess.get_file_as_string(source_path);assert(not "100円" in source and not "¥100" in source)
	assert(not FileAccess.file_exists("res://scripts/secret_gacha_system.gd"))
	print("POT_UNLOCK_IAP_SMOKE_OK initial=",initial.size()," group_1=",group_1_count," group_2=",group_2_count," localized_price=€0,99 restore=true safe_preview=true")
	get_tree().quit()

func _read_array(path:String)->Array:
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Array)
	return parsed

func _has_label_text_containing(root:Node,text:String)->bool:
	for node in root.find_children("*","Label",true,false):
		if node is Label and text in (node as Label).text:return true
	return false

func _pot_shop_card(ui:Node,pot_id:String)->Node:
	for card in ui.shop_grid.get_children():
		if card.has_meta("pot_id") and str(card.get_meta("pot_id"))==pot_id:return card
	return null
