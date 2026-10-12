extends Node

const TARGET_SAMPLE_COUNT := 4000
const WAIT_TIMEOUT_SECONDS := 6.0

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game.audio_manager.apply_settings({"bgm_enabled":false,"se_enabled":false})
	game._reset_progression_state()
	game._set_language("ja")
	game.endless_greenhouse.configure(true)
	game.opening_finished=true;game.opening_story_complete=true;game.intro_story_complete=true;game.opening_overlay.visible=false;game.opening_story_overlay.visible=false
	game.first_habitat_gift_claimed=true;game.initial_seed_stock_notice_complete=true;game.habitat_awakened=true;game.seed_shop_open=true
	game.habitat_tutorial_complete=true;game.mystery_items_acquired=true;game.mystery_catalog_tutorial_complete=true
	game.normal_play_tutorial_complete=true;game.puku_buyback_tutorial_complete=true;game.puku_gauge_intro_complete=true
	game.current_mode="greenhouse";game.puku_balance_units=999;game._apply_mode();game._update_play_ui()
	assert(game.play_open_button.visible and not game.play_open_button.disabled)
	assert(game.play_open_button.text=="パンダのお手伝いをする\n＋1ぷくコイン")
	game._open_play_modal();assert(not game.play_active and game.puku_balance_units==999 and game.shop_overlay.visible)
	game._close_shop()
	game.puku_balance_units=5000;game._update_play_ui()
	assert(game.play_open_button.visible and game.play_open_button.text=="たねをまく\n1ぷくコイン消費")
	_assert_uniform_concurrent_target_rolls(game)
	var target_five_seed:=_seed_for_target(game,5)
	var target_eight_seed:=_seed_for_target(game,8)
	game.rng.seed=target_five_seed
	game._open_play_modal()
	assert(game.play_active and game.puku_balance_units==4000 and game.endless_economy_seed_cost_units==1000)
	assert(game.ENDLESS_NORMAL_MIN_PLANTS==5 and game.ENDLESS_NORMAL_MAX_PLANTS==8)
	assert(game.play_concurrent_target==5)
	assert(game.play_seeds_remaining==12-game.play_concurrent_target)
	assert(await _wait_for_population(game,5),"initial population did not settle: %s"%_round_state(game,-1))
	assert(game.plants.size()==5 and game.endless_economy_seed_count==5)
	_assert_normal_plant_balance(game)
	print("NORMAL_ROUND_STAGE initial ",_round_state(game,-1))
	# This suite settles the round manually. Pause the game's frame loop and
	# disable automatic checks before each manual tick so the formal random
	# jelly system cannot race the deterministic twelve-settlement assertions.
	game.set_process(false)
	_disable_automatic_jelly(game)

	# A vacancy after an initial five-plant start may immediately re-roll to
	# eight. The refill counts queued drops and active seed animations, so the
	# scheduled population reaches eight without ever exceeding it.
	game.rng.seed=target_eight_seed
	game.plants[0].jelly()
	await get_tree().process_frame
	assert(game.play_concurrent_target==8)
	assert(_planned_population(game)==8)
	var expanded_ready:=await _wait_for_population(game,8)
	assert(expanded_ready,"target-eight refill did not settle: %s"%_round_state(game,-1))
	assert(game.plants.size()==8 and game.endless_economy_seed_count==9)
	_assert_normal_plant_balance(game)
	print("NORMAL_ROUND_STAGE expanded ",_round_state(game,-1))

	# A lower re-roll never deletes living plants. Three consecutive target-five
	# settlements naturally reduce an eight-plant population to five instead.
	for expected_population in [7,6,5]:
		game.rng.seed=target_five_seed
		game.plants[0].jelly()
		await get_tree().process_frame
		assert(game.play_concurrent_target==5)
		assert(game.play_spawn_queue==0 and game.play_seed_animations_pending==0)
		assert(game.plants.size()==expected_population and _planned_population(game)==expected_population)
	assert(game.endless_economy_jelly_count==4)
	print("NORMAL_ROUND_STAGE reduced ",_round_state(game,-1))

	var manual_settlements_remaining: int = game.NORMAL_GERMINATION_COUNT-game.endless_economy_harvest_count-game.endless_economy_jelly_count
	assert(manual_settlements_remaining==8)
	for settlement_index in range(manual_settlements_remaining):
		assert(await _wait_for_settlement_plant(game),"round ended before all 12 seeds settled: %s"%_round_state(game,settlement_index))
		_disable_automatic_jelly(game)
		game.rng.seed=target_eight_seed if settlement_index%2==0 else target_five_seed
		var plant=game.plants[0];plant.jelly()
		await get_tree().process_frame
		assert(_planned_population(game)<=game.ENDLESS_NORMAL_MAX_PLANTS)
	assert(await _wait_until(func()->bool:return not game.play_active and game.result_overlay.visible))
	assert(not game.play_active and game.result_overlay.visible)
	assert(game.endless_economy_seed_count==12 and game.endless_economy_jelly_count==12 and game.endless_economy_harvest_count==0)
	assert(game.puku_balance_units==4000 and game.endless_economy_seed_cost_units==1000 and game.endless_economy_harvest_reward_units==0)
	assert(game.result_count_label.text.contains("収穫　0株") and game.result_count_label.text.contains("ジュレ　12株"))
	assert(game.result_total_label.text.contains("-1.00ぷく") and game.result_total_label.text.contains("今回の収支　-1.00ぷく"))
	game._close_result();game._process(.2)
	assert(not game.play_active)
	print("NORMAL_ROUND_SMOKE_OK seeds=12 concurrent=5-8 dynamic=5_to_8_to_5 max_planned=8 entry_cost=1 refill_cost=0 all_jelly_net=-1 result=true no_autostart=true")
	game.queue_free()
	get_tree().quit()

func _assert_uniform_concurrent_target_rolls(game:Node)->void:
	var counts:={5:0,6:0,7:0,8:0}
	game.rng.seed=20261012
	for sample_index in range(TARGET_SAMPLE_COUNT):
		var target:int=game._roll_normal_greenhouse_concurrent_target()
		assert(target>=game.ENDLESS_NORMAL_MIN_PLANTS and target<=game.ENDLESS_NORMAL_MAX_PLANTS)
		counts[target]=int(counts[target])+1
	var expected:=TARGET_SAMPLE_COUNT/4.0
	for target in counts:
		assert(absf(float(counts[target])-expected)<=expected*.20,"concurrent target distribution was not approximately uniform: %s"%counts)
	print("NORMAL_ROUND_TARGET_DISTRIBUTION samples=",TARGET_SAMPLE_COUNT," counts=",counts)

func _seed_for_target(game:Node,target:int)->int:
	var probe:=RandomNumberGenerator.new()
	for candidate_seed in range(10000):
		probe.seed=candidate_seed
		if probe.randi_range(game.ENDLESS_NORMAL_MIN_PLANTS,game.ENDLESS_NORMAL_MAX_PLANTS)==target:return candidate_seed
	assert(false,"could not find deterministic seed for concurrent target %s"%target)
	return 0

func _planned_population(game:Node)->int:
	return game.plants.size()+game.play_spawn_queue+game.play_seed_animations_pending

func _disable_automatic_jelly(game:Node)->void:
	for plant in game.plants:
		if is_instance_valid(plant) and plant.state=="growing":plant.jelly_checks_enabled=false

func _assert_normal_plant_balance(game:Node)->void:
	for plant in game.plants:
		assert(plant.jelly_rates_per_second==[0.01,0.025,0.05,0.08])
		assert(is_equal_approx(plant.growth_speed_multiplier,1.6))
		assert(plant.kakuhen_enabled)

func _wait_for_population(game:Node,expected_population:int)->bool:
	var deadline_msec:=Time.get_ticks_msec()+int(WAIT_TIMEOUT_SECONDS*1000.0)
	while Time.get_ticks_msec()<deadline_msec:
		_disable_automatic_jelly(game)
		if _planned_population(game)>game.ENDLESS_NORMAL_MAX_PLANTS:return false
		if game.plants.size()==expected_population and game.play_spawn_queue==0 and game.play_seed_animations_pending==0:return true
		if game.play_active and game.play_spawn_queue>0 and game.play_seed_animations_pending==0:
			game.play_spawn_timer=0.0;game._process(.01)
		await get_tree().process_frame
	push_error("population wait timed out: expected=%s %s"%[expected_population,_round_state(game,-1)])
	return false

func _wait_for_settlement_plant(game:Node)->bool:
	var deadline_msec:=Time.get_ticks_msec()+int(WAIT_TIMEOUT_SECONDS*1000.0)
	while Time.get_ticks_msec()<deadline_msec:
		_disable_automatic_jelly(game)
		if not game.play_active:return false
		if not game.plants.is_empty():return true
		if game.play_spawn_queue>0 and game.play_seed_animations_pending==0:
			game.play_spawn_timer=0.0;game._process(.01)
		await get_tree().process_frame
	push_error("settlement plant wait timed out: %s"%_round_state(game,-1))
	return false

func _wait_until(predicate:Callable)->bool:
	var deadline_msec:=Time.get_ticks_msec()+int(WAIT_TIMEOUT_SECONDS*1000.0)
	while Time.get_ticks_msec()<deadline_msec and not bool(predicate.call()):await get_tree().process_frame
	return bool(predicate.call())

func _round_state(game:Node,settlement_index:int)->String:
	return "index=%s active=%s plants=%s seeds_remaining=%s queue=%s pending=%s spawned=%s harvest=%s jelly=%s target=%s planned=%s"%[settlement_index,game.play_active,game.plants.size(),game.play_seeds_remaining,game.play_spawn_queue,game.play_seed_animations_pending,game.endless_economy_seed_count,game.endless_economy_harvest_count,game.endless_economy_jelly_count,game.play_concurrent_target,_planned_population(game)]
