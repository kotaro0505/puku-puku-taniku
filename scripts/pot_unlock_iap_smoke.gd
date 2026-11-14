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
	assert(mock.requested_products.size()==36 and mock.requested_prices.is_empty())
	assert(str(service.product_states_snapshot()[first_product].localized_price)=="€0,99")
	assert(str(service.product_states_snapshot()[first_product].status)==service.STATUS_AVAILABLE)
	assert(service.purchase(first_product));assert(service.is_unlocked(first_product) and mock.purchase_calls.size()==1)
	assert(not service.purchase(first_product) and mock.purchase_calls.size()==1)
	# The forced-ad removal is the 37th independent non-consumable. It shares the
	# StoreKit purchase/entitlement/restore bridge without changing any pot ID.
	var forced_ads_product_id:="forced_ads_removal"
	var all_product_prices:=prices.duplicate(true);all_product_prices[forced_ads_product_id]="€0,99"
	var extra_mock:=MockClass.new();extra_mock.localized_prices=all_product_prices.duplicate(true)
	var extra_service:=ServiceClass.new();add_child(extra_service);extra_service.configure(all_pots,{},extra_mock,null,[forced_ads_product_id])
	await get_tree().process_frame
	assert(extra_mock.requested_products.size()==37)
	assert(str(extra_service.product_states_snapshot()[forced_ads_product_id].localized_price)=="€0,99")
	assert(extra_service.purchase(forced_ads_product_id))
	assert(extra_service.is_unlocked(forced_ads_product_id))
	assert(extra_mock.purchase_calls==[forced_ads_product_id])
	var extra_restore_mock:=MockClass.new();extra_restore_mock.localized_prices=all_product_prices.duplicate(true);extra_restore_mock.restore_entitlements={forced_ads_product_id:true}
	var extra_restore_service:=ServiceClass.new();add_child(extra_restore_service);extra_restore_service.configure(all_pots,{},extra_restore_mock,null,[forced_ads_product_id])
	await get_tree().process_frame
	assert(extra_restore_service.restore_purchases())
	assert(extra_restore_service.is_unlocked(forced_ads_product_id))
	var failure_mock:=MockClass.new();failure_mock.localized_prices=prices.duplicate(true);failure_mock.next_purchase_error="declined"
	var failure_service:=ServiceClass.new();add_child(failure_service);failure_service.configure(all_pots,{},failure_mock)
	await get_tree().process_frame
	assert(failure_service.purchase(first_product));assert(not failure_service.is_unlocked(first_product))
	assert(str(failure_service.product_states_snapshot()[first_product].status)==failure_service.STATUS_AVAILABLE)

	# The review-capture profile needs only visible StoreKit prices. It requests
	# all 36 products through the price-only bridge without entitlement lookups.
	var capture_product_ids:Array[String]=[]
	var capture_mock:=MockClass.new()
	for product_number in range(1,37):
		var product_id:="pot_unlock_%03d"%product_number
		capture_product_ids.append(product_id)
		capture_mock.localized_prices[product_id]="$0.49"
		capture_mock.currency_values[product_id]=0.49
		capture_mock.currency_codes[product_id]="USD"
		capture_mock.currency_symbols[product_id]="$"
		capture_mock.storefront_country_codes[product_id]="USA"
	var capture_service:=ServiceClass.new();add_child(capture_service);capture_service.configure(all_pots,{},capture_mock,capture_product_ids)
	await get_tree().process_frame
	var capture_diagnostic:Dictionary=capture_service.diagnostic_snapshot()
	var capture_state:Dictionary=capture_service.product_states_snapshot()[first_product]
	assert(capture_mock.requested_prices==capture_product_ids and capture_mock.requested_products.is_empty())
	assert(str(capture_state.status)==capture_service.STATUS_AVAILABLE)
	assert(str(capture_state.localized_price)=="$0.49")
	assert(is_equal_approx(float(capture_state.currency_value),0.49))
	assert(str(capture_state.currency_code)=="USD" and str(capture_state.currency_symbol)=="$")
	assert(str(capture_state.storefront_country_code)=="USA")
	assert(capture_mock.purchase_calls.is_empty())
	assert(str(capture_service.product_states_snapshot()[last_product].status)==capture_service.STATUS_AVAILABLE)
	assert(str(capture_diagnostic.request_mode)=="price_only")
	assert(int(capture_diagnostic.requested_product_count)==36 and int(capture_diagnostic.requests_dispatched)==36 and int(capture_diagnostic.responses_received)==36)
	assert(bool(capture_diagnostic.request_method_available) and bool(capture_diagnostic.response_signal_available))

	# A native request that never returns remains distinguishable from a missing
	# bridge API without weakening the capture timeout gate.
	var timeout_mock:=MockClass.new();timeout_mock.localized_prices=prices.duplicate(true);timeout_mock.suppress_price_response=true
	var timeout_service:=ServiceClass.new();add_child(timeout_service);timeout_service.configure(all_pots,{},timeout_mock,first_product)
	await get_tree().process_frame
	var timeout_diagnostic:Dictionary=timeout_service.diagnostic_snapshot()
	assert(str(timeout_service.product_states_snapshot()[first_product].status)==timeout_service.STATUS_LOADING)
	assert(timeout_mock.requested_prices==[first_product] and timeout_mock.requested_products.is_empty())
	assert(int(timeout_diagnostic.requests_dispatched)==1 and int(timeout_diagnostic.responses_received)==0)

	var restore_mock:=MockClass.new();restore_mock.localized_prices=prices.duplicate(true);restore_mock.restore_entitlements={first_product:true,last_product:true}
	var restore_service:=ServiceClass.new();add_child(restore_service);restore_service.configure(all_pots,{},restore_mock)
	await get_tree().process_frame
	var restore_results:Array[bool]=[]
	restore_service.restore_finished.connect(func(success:bool)->void:restore_results.append(success))
	assert(not restore_service.is_unlocked(first_product));assert(restore_service.restore_purchases())
	assert(restore_mock.sync_calls==1 and restore_service.is_unlocked(first_product) and restore_service.is_unlocked(last_product) and not restore_service.restore_in_progress())
	assert(restore_results==[true] and restore_service.restore_result_code()==restore_service.RESTORE_RESULT_SUCCESS)
	# Duplicate native completion callbacks must not complete or refresh twice.
	restore_mock.emit_sync_result("");assert(restore_results==[true])

	# A successful sync with no purchases is still a completed history check.
	var empty_restore_mock:=MockClass.new();empty_restore_mock.localized_prices=prices.duplicate(true)
	var empty_restore_service:=ServiceClass.new();add_child(empty_restore_service);empty_restore_service.configure(all_pots,{},empty_restore_mock)
	await get_tree().process_frame
	var empty_restore_results:Array[bool]=[]
	empty_restore_service.restore_finished.connect(func(success:bool)->void:empty_restore_results.append(success))
	assert(empty_restore_service.restore_purchases())
	assert(empty_restore_results==[true] and empty_restore_service.entitlements_snapshot().is_empty())

	# StoreKit sync failures never become a success message. Stable native result
	# codes keep cancellation and network errors independent of the device locale.
	for failure_case in [
		{"native_code":"cancelled","expected":ServiceClass.RESTORE_RESULT_CANCELLED},
		{"native_code":"network_error","expected":ServiceClass.RESTORE_RESULT_NETWORK_ERROR},
		{"native_code":"unexpected_storekit_error","expected":ServiceClass.RESTORE_RESULT_FAILED},
	]:
		var restore_failure_mock:=MockClass.new();restore_failure_mock.localized_prices=prices.duplicate(true);restore_failure_mock.sync_error=str(failure_case.native_code)
		var restore_failure_service:=ServiceClass.new();add_child(restore_failure_service);restore_failure_service.configure(all_pots,{},restore_failure_mock)
		await get_tree().process_frame
		var failure_results:Array[bool]=[]
		restore_failure_service.restore_finished.connect(func(success:bool)->void:failure_results.append(success))
		assert(restore_failure_service.restore_purchases())
		assert(failure_results==[false] and not restore_failure_service.restore_in_progress())
		assert(restore_failure_service.restore_result_code()==str(failure_case.expected))

	# A missing native callback and an incomplete entitlement refresh both time
	# out, re-enable the restore action, and ignore a later stale callback.
	var sync_timeout_mock:=MockClass.new();sync_timeout_mock.localized_prices=prices.duplicate(true);sync_timeout_mock.suppress_sync_response=true
	var sync_timeout_service:=ServiceClass.new();add_child(sync_timeout_service);sync_timeout_service.configure(all_pots,{},sync_timeout_mock)
	await get_tree().process_frame
	var sync_timeout_results:Array[bool]=[]
	sync_timeout_service.restore_finished.connect(func(success:bool)->void:sync_timeout_results.append(success))
	assert(sync_timeout_service.restore_purchases() and sync_timeout_service.restore_in_progress())
	assert(not sync_timeout_service.restore_purchases())
	sync_timeout_service._on_restore_timeout(sync_timeout_service._restore_timeout_token)
	assert(sync_timeout_results==[false] and not sync_timeout_service.restore_in_progress())
	assert(sync_timeout_service.restore_result_code()==sync_timeout_service.RESTORE_RESULT_TIMEOUT)
	sync_timeout_mock.emit_sync_result("");assert(sync_timeout_results==[false])

	var refresh_timeout_mock:=MockClass.new();refresh_timeout_mock.localized_prices=prices.duplicate(true)
	var refresh_timeout_service:=ServiceClass.new();add_child(refresh_timeout_service);refresh_timeout_service.configure(all_pots,{},refresh_timeout_mock)
	await get_tree().process_frame
	refresh_timeout_mock.suppress_product_info_response=true
	var refresh_timeout_results:Array[bool]=[]
	refresh_timeout_service.restore_finished.connect(func(success:bool)->void:refresh_timeout_results.append(success))
	assert(refresh_timeout_service.restore_purchases() and refresh_timeout_service.restore_in_progress())
	refresh_timeout_service._on_restore_timeout(refresh_timeout_service._restore_timeout_token)
	assert(refresh_timeout_results==[false] and refresh_timeout_service.restore_result_code()==refresh_timeout_service.RESTORE_RESULT_TIMEOUT)

	# A product lookup error after AppStore.sync() is not reported as a fully
	# verified restore. Existing cached entitlements are not erased on the error.
	var refresh_failure_mock:=MockClass.new();refresh_failure_mock.localized_prices=prices.duplicate(true);refresh_failure_mock.purchased[first_product]=true
	var refresh_failure_service:=ServiceClass.new();add_child(refresh_failure_service);refresh_failure_service.configure(all_pots,{first_product:true},refresh_failure_mock)
	await get_tree().process_frame
	refresh_failure_mock.localized_prices.erase(last_product)
	var refresh_failure_results:Array[bool]=[]
	refresh_failure_service.restore_finished.connect(func(success:bool)->void:refresh_failure_results.append(success))
	assert(refresh_failure_service.restore_purchases())
	assert(refresh_failure_results==[false] and refresh_failure_service.is_unlocked(first_product))
	assert(refresh_failure_service.restore_result_code()==refresh_failure_service.RESTORE_RESULT_FAILED)

	# Production desktop/Web has no StoreKit bridge. It must never simulate a
	# charge or invent a price; only the isolated test bridge above can do that.
	var safe_service:=ServiceClass.new();add_child(safe_service);safe_service.configure(all_pots,{})
	assert(not safe_service.restore_available() and not safe_service.purchase(first_product))
	assert(str(safe_service.product_states_snapshot()[first_product].status)==safe_service.STATUS_UNAVAILABLE)
	assert(str(safe_service.product_states_snapshot()[first_product].localized_price).is_empty())

	var ui:=ArrangementUIClass.new();add_child(ui);await get_tree().process_frame
	var owned:Dictionary={"shallow_terracotta":1}
	ui.configure([],[],all_pots,{},owned,[],20,5,Callable(),Callable(),{},"ja",2,{},capture_service.product_states_snapshot(),false,false)
	ui.open_pot_shop()
	var capture_card:=_pot_shop_card(ui,"g1_crystal_goblet")
	var capture_buy_button:=capture_card.find_child("PotBuyButton",true,false) as Button
	assert(capture_buy_button.text==Localizer.text("ja","iap_unlock_for_price",["$0.49"]))
	ui.configure([],[],all_pots,{},owned,[],20,5,Callable(),Callable(),{},"ja",2,{},extra_service.product_states_snapshot(),true,false,[],{},[],true,forced_ads_product_id)
	ui.open_pot_shop();await get_tree().process_frame
	var forced_ads_card:=ui.find_child("ForcedAdsRemovalCard",true,false)
	var forced_ads_buy:=ui.find_child("ForcedAdsRemovalBuyButton",true,false) as Button
	assert(forced_ads_card!=null and forced_ads_buy!=null)
	assert(forced_ads_buy.text==Localizer.text("ja","forced_ads_removal_owned") and forced_ads_buy.disabled)
	ui.configure([],[],all_pots,{},owned,[],20,5,Callable(),Callable(),{},"ja",0,{},service.product_states_snapshot(),false,false)
	ui.open_pot_shop();assert(ui.shop_grid.get_child_count()==8 and not ui.shop_restore_button.visible)
	ui.configure([],[],all_pots,{},owned,[],20,5,Callable(),Callable(),{},"ja",1,{},service.product_states_snapshot(),false,false)
	ui.open_pot_shop();assert(ui.shop_grid.get_child_count()==22 and ui.shop_restore_button.visible and ui.shop_restore_button.disabled)
	var first_paid_card:Node=ui.shop_grid.get_child(8);var unlock_buttons:=first_paid_card.find_children("*","Button",true,false)
	var first_locked_price:=first_paid_card.find_child("PotLockedPukuPrice",true,false) as Label
	assert(unlock_buttons.size()==1 and "€0,99" in (unlock_buttons[0] as Button).text and not (unlock_buttons[0] as Button).disabled and not bool((unlock_buttons[0] as Button).get_meta("puku_purchase",true)))
	assert(first_locked_price!=null and first_locked_price.visible and first_locked_price.text=="価格：2ぷくコイン" and first_locked_price.get_theme_font_size("font_size")==18)
	assert((unlock_buttons[0] as Button).get_theme_font_size("font_size")==19)
	ui.open_home();assert(ui.home_page.visible and ui.pot_select_grid.get_child_count()==1 and _has_label_text_containing(ui.pot_select_grid.get_child(0),"浅型素焼き鉢") and not _has_label_text_containing(ui.pot_select_grid,"未所持") and not _has_label_text_containing(ui.pot_select_grid,"デザイン未アンロック"))
	var unlocks:Dictionary={first_product:true}
	ui.configure([],[],all_pots,{},owned,[],20,5,Callable(),Callable(),{},"ja",1,unlocks,service.product_states_snapshot(),false,false)
	ui._refresh_pot_selection();assert(ui.pot_select_grid.get_child_count()==1 and not _has_label_text_containing(ui.pot_select_grid,"クリスタルゴブレット鉢"))
	owned["g1_crystal_goblet"]=1;ui.sync_state(owned,[],20);var first_paid_select:=ui.pot_select_grid.get_child(1) as Button;assert(ui.pot_select_grid.get_child_count()==2 and not first_paid_select.disabled and _has_label_text_containing(first_paid_select,"クリスタルゴブレット鉢") and _has_label_text_containing(first_paid_select,"使用可能 ×1"))
	ui.open_pot_shop();first_paid_card=ui.shop_grid.get_child(8);var puku_buttons:=first_paid_card.find_children("*","Button",true,false);var owned_label:=first_paid_card.find_child("PotOwnedTotal",true,false) as Label
	assert(puku_buttons.size()==1 and "2ぷくコイン" in (puku_buttons[0] as Button).text and (puku_buttons[0] as Button).get_theme_font_size("font_size")==19 and bool((puku_buttons[0] as Button).get_meta("puku_purchase",false)))
	assert(owned_label!=null and owned_label.get_theme_font_size("font_size")==17 and not (first_paid_card.find_child("PotLockedPukuPrice",true,false) as Label).visible)
	ui.configure([],[],all_pots,{},owned,[],20,5,Callable(),Callable(),{},"ja",2,unlocks,service.product_states_snapshot(),false,false);ui.open_pot_shop();assert(ui.shop_grid.get_child_count()==44)

	var all_paid_unlocks:Dictionary={}
	for pot_value in paid:all_paid_unlocks[str((pot_value as Dictionary).iap_product_id)]=true
	var expected_ads_copy:Dictionary={
		"ja":{"name":"広告を削除","description":"森のガチャとラボで自動表示される広告を削除します。パンダのお手伝い広告は残ります。","banned":"強制広告"},
		"hiragana":{"name":"こうこくを けす","description":"もりの がちゃと らぼで じどうで でる こうこくを けします。ぱんだの おてつだいこうこくは のこります。","banned":"きょうせいこうこく"},
		"en":{"name":"Remove Ads","description":"Removes ads that appear automatically in Forest Gacha and Hybrid Lab. Panda Help ads will remain available.","banned":"forced ads"},
	}
	for locale in ["ja","hiragana","en"]:
		for key in ["pot_not_owned","pot_iap_locked_short","pot_unlock_required","pot_permanent_unlock","pot_locked_puku_price","pot_unlock_success","iap_unlock_for_price","iap_price_loading","iap_purchase_unavailable","iap_restore_purchases","iap_restore_complete","iap_restore_failed","iap_restore_cancelled","iap_restore_network_failed","iap_restore_timeout","forced_ads_removal_name","forced_ads_removal_description","forced_ads_removal_owned","forced_ads_removal_success"]:assert(Localizer.text(locale,key)!=key)
		var expected_copy:Dictionary=expected_ads_copy[locale]
		assert(Localizer.text(locale,"forced_ads_removal_name")==str(expected_copy.name))
		assert(Localizer.text(locale,"forced_ads_removal_description")==str(expected_copy.description))
		var player_purchase_copy:=("%s %s %s %s %s"%[Localizer.text(locale,"forced_ads_removal_name"),Localizer.text(locale,"forced_ads_removal_description"),Localizer.text(locale,"forced_ads_removal_buy",["€0,99"]),Localizer.text(locale,"forced_ads_removal_owned"),Localizer.text(locale,"forced_ads_removal_success")]).to_lower()
		assert(not str(expected_copy.banned).to_lower() in player_purchase_copy)
		ui.configure([],[],all_pots,{},owned,[],200,1000,Callable(),Callable(),{},locale,2,{},extra_service.product_states_snapshot(),true,false,[],{},[],false,forced_ads_product_id);ui.open_pot_shop();await get_tree().process_frame;await get_tree().process_frame
		var forced_card:=ui.find_child("ForcedAdsRemovalCard",true,false) as PanelContainer
		var forced_title:=ui.find_child("ForcedAdsRemovalTitle",true,false) as Label
		var forced_description:=ui.find_child("ForcedAdsRemovalDescription",true,false) as Label
		var forced_buy:=ui.find_child("ForcedAdsRemovalBuyButton",true,false) as Button
		assert(forced_card!=null and forced_title!=null and forced_description!=null and forced_buy!=null)
		assert(forced_title.text==str(expected_copy.name) and forced_description.text==str(expected_copy.description))
		assert(forced_description.autowrap_mode==TextServer.AUTOWRAP_WORD_SMART and forced_description.custom_minimum_size.y==96.0)
		assert(forced_description.get_visible_line_count()==forced_description.get_line_count())
		assert(forced_description.get_combined_minimum_size().y<=forced_description.size.y+.5)
		assert(forced_description.position.y+forced_description.size.y<=forced_buy.position.y+.5)
		assert(forced_card.get_combined_minimum_size().y<=forced_card.size.y+.5)
		ui.configure([],[],all_pots,{},owned,[],200,1000,Callable(),Callable(),{},locale,2,{},service.product_states_snapshot(),false,false);ui.open_pot_shop();await get_tree().process_frame
		for pot_value in paid:
			var pot:Dictionary=pot_value;var pot_id:=str(pot.pot_id);var expected_price:=int(expected_prices[pot_id]);var locked_card:=_pot_shop_card(ui,pot_id);var locked_price:=locked_card.find_child("PotLockedPukuPrice",true,false) as Label
			assert(locked_price.visible and locked_price.text==Localizer.text(locale,"pot_locked_puku_price",[expected_price]) and locked_price.get_theme_font_size("font_size")==18)
		ui.configure([],[],all_pots,{},owned,[],200,1000,Callable(),Callable(),{},locale,2,all_paid_unlocks,service.product_states_snapshot(),false,false);ui.open_pot_shop();await get_tree().process_frame
		for pot_value in paid:
			var pot:Dictionary=pot_value;var pot_id:=str(pot.pot_id);var expected_price:=int(expected_prices[pot_id]);var card:=_pot_shop_card(ui,pot_id);var buy:=card.find_child("PotBuyButton",true,false) as Button;var owned_total:=card.find_child("PotOwnedTotal",true,false) as Label
			assert(buy.text==Localizer.text(locale,"buy_puku",[expected_price]) and not buy.disabled and buy.get_theme_font_size("font_size")==19 and buy.get_minimum_size().x<=buy.size.x and bool(buy.get_meta("puku_purchase",false)))
			assert(owned_total.get_theme_font_size("font_size")==17 and owned_total.get_minimum_size().x<=owned_total.size.x)
	for source_path in ["res://data/pot-iap-catalog.json","res://scripts/pot_unlock_iap_service.gd","res://scripts/arrangement_ui.gd","res://scripts/main.gd"]:
		var source:=FileAccess.get_file_as_string(source_path);assert(not "100円" in source and not "¥100" in source)
	assert(not FileAccess.file_exists("res://scripts/secret_gacha_system.gd"))
	print("POT_UNLOCK_IAP_SMOKE_OK initial=",initial.size()," group_1=",group_1_count," group_2=",group_2_count," official_pot_prices=36 non_consumables=37 localized_display=ja-hiragana-en localized_price=€0,99 restore=true safe_preview=true")
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
