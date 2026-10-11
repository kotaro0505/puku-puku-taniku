extends Node

const JellyBalanceClass = preload("res://scripts/jelly_balance.gd")
const SucculentClass = preload("res://scripts/succulent.gd")

const SAMPLE_COUNT := 20000
const FORMAL_RATES:Array[float] = [0.01, 0.02, 0.03, 0.04]

var sample_species := {
	"species_id":"colorata", "name_ja":"コロラータ",
	"visual_variant":"colorata", "colors":["7f9f91", "d35f6f"]
}

func _approx(actual:float, expected:float, tolerance:=0.000001)->void:
	assert(absf(actual-expected)<=tolerance, "actual=%s expected=%s tolerance=%s"%[actual,expected,tolerance])

func _make_plant(seed_value:int, balance:Dictionary={})->Succulent:
	var plant:=SucculentClass.new()
	plant.setup(sample_species,seed_value,null,null,true,balance)
	return plant

func _theoretical_survival(seconds:float)->float:
	return 1.0-SucculentClass.jelly_probability_for_interval(0.0,seconds,FORMAL_RATES)

func _survival_accumulated_at_fps(seconds:float,fps:int)->float:
	var survival:=1.0
	var age:=0.0
	var step:=1.0/float(fps)
	for _frame in range(int(round(seconds*fps))):
		var probability:=SucculentClass.jelly_probability_for_interval(age,step,FORMAL_RATES)
		survival*=1.0-probability
		age+=step
	return survival

func _verify_formal_rates_and_boundaries()->void:
	JellyBalanceClass.reset_formal()
	assert(JellyBalanceClass.rate_values(JellyBalanceClass.FORMAL)==FORMAL_RATES)
	assert(SucculentClass.jelly_stage_index(0.0)==0)
	assert(SucculentClass.jelly_stage_index(4.999999)==0)
	assert(SucculentClass.jelly_stage_index(5.0)==1)
	assert(SucculentClass.jelly_stage_index(9.999999)==1)
	assert(SucculentClass.jelly_stage_index(10.0)==2)
	assert(SucculentClass.jelly_stage_index(14.999999)==2)
	assert(SucculentClass.jelly_stage_index(15.0)==3)
	_approx(SucculentClass.jelly_chance_per_second(2.0,FORMAL_RATES),0.01)
	_approx(SucculentClass.jelly_chance_per_second(7.0,FORMAL_RATES),0.02)
	_approx(SucculentClass.jelly_chance_per_second(12.0,FORMAL_RATES),0.03)
	_approx(SucculentClass.jelly_chance_per_second(20.0,FORMAL_RATES),0.04)
	_approx(SucculentClass.jelly_probability_for_interval(0.0,5.0,FORMAL_RATES),1.0-pow(.99,5.0))
	_approx(SucculentClass.jelly_probability_for_interval(4.0,2.0,FORMAL_RATES),1.0-.99*.98)
	_approx(SucculentClass.jelly_probability_for_interval(9.0,7.0,FORMAL_RATES),1.0-.98*pow(.97,5.0)*.96)
	_approx(SucculentClass.jelly_probability_for_interval(0.0,20.0,FORMAL_RATES),1.0-pow(.99,5.0)*pow(.98,5.0)*pow(.97,5.0)*pow(.96,5.0))

func _verify_fps_independence()->void:
	var expected:=_theoretical_survival(20.0)
	for fps in [30,60,120]:
		_approx(_survival_accumulated_at_fps(20.0,fps),expected,0.00001)

func _verify_independent_random_and_statistics()->void:
	var observed_jellied:=0
	var first_draws:Dictionary={}
	for sample in range(SAMPLE_COUNT):
		var plant:=_make_plant(700000+sample,JellyBalanceClass.FORMAL)
		if sample<64:first_draws[plant.jelly_rng.randf()]=true
		plant.simulate(20.0)
		if plant.state=="jelly":observed_jellied+=1
		plant.free()
	assert(first_draws.size()==64)
	var expected_jellied:=1.0-_theoretical_survival(20.0)
	var observed_rate:=float(observed_jellied)/float(SAMPLE_COUNT)
	assert(absf(observed_rate-expected_jellied)<0.012,"observed=%s expected=%s"%[observed_rate,expected_jellied])
	print("JELLY_STAT_PROFILE samples=",SAMPLE_COUNT," expected_jellied=",expected_jellied," observed_jellied=",observed_rate)

func _verify_simultaneous_results_are_not_limited()->void:
	var forced_balance:=JellyBalanceClass.FORMAL.duplicate(true)
	for key in JellyBalanceClass.RATE_KEYS:forced_balance[key]=1.0
	var plants:Array=[]
	for index in range(12):
		var plant:=_make_plant(900000+index,forced_balance)
		plant.simulate(0.01)
		assert(plant.state=="jelly")
		plants.append(plant)
	for plant in plants:plant.free()

func _verify_new_plant_snapshot()->void:
	var first_balance:=JellyBalanceClass.FORMAL.duplicate(true)
	first_balance.rate_0_5=0.25
	var first:=_make_plant(101,first_balance)
	first_balance.rate_0_5=0.75
	var second:=_make_plant(102,first_balance)
	_approx(first.jelly_rates_per_second[0],0.25)
	_approx(second.jelly_rates_per_second[0],0.75)
	first.free();second.free()

func _verify_development_ui(game)->void:
	game._open_jelly_dev()
	assert(game.jelly_dev_overlay.visible and JellyBalanceClass.override_enabled)
	assert(game.jelly_dev_labels.size()==5)
	for key in JellyBalanceClass.RATE_KEYS:
		assert(key in game.jelly_dev_labels)
	assert("growth_speed" in game.jelly_dev_labels)
	assert(game.jelly_dev_labels.rate_0_5.text=="0〜5秒 ジュレ率：1.0%")
	assert(game.jelly_dev_labels.rate_5_10.text=="5〜10秒 ジュレ率：2.0%")
	assert(game.jelly_dev_labels.rate_10_15.text=="10〜15秒 ジュレ率：3.0%")
	assert(game.jelly_dev_labels.rate_15_plus.text=="15秒以降 ジュレ率：4.0%")
	assert(game.jelly_dev_overlay.find_child("JellyDevRow_short_weight",true,false)==null)
	assert(game.jelly_dev_overlay.find_child("JellyDevRow_safe_min",true,false)==null)
	for key in JellyBalanceClass.RATE_KEYS:
		var before:=float(JellyBalanceClass.values[key])
		game._change_jelly_dev_value(str(key),.005)
		_approx(float(JellyBalanceClass.values[key]),before+.005)
	game._change_jelly_dev_value("rate_0_5",-2.0)
	_approx(float(JellyBalanceClass.values.rate_0_5),0.0)
	game._change_jelly_dev_value("rate_0_5",2.0)
	_approx(float(JellyBalanceClass.values.rate_0_5),1.0)
	game._change_jelly_dev_value("growth_speed",.2)
	_approx(float(JellyBalanceClass.values.growth_speed),1.2)

	JellyBalanceClass.set_value("rate_5_10",.125)
	game._dev_spawn_50cm()
	assert(game.dev_jelly_test_active and game.plants.size()==4 and not game.play_active)
	for plant in game.plants:
		_approx(plant.jelly_rates_per_second[1],.125)
		_approx(plant.effective_growth_speed_multiplier(),1.2)
		assert(absf(plant.diameter_cm-50.0)<.01)

	game._dev_reset_jelly()
	assert(not JellyBalanceClass.override_enabled and not game.dev_jelly_test_active)
	assert(JellyBalanceClass.rate_values(JellyBalanceClass.values)==FORMAL_RATES)
	_approx(float(JellyBalanceClass.values.growth_speed),1.0)

func _ready()->void:
	_verify_formal_rates_and_boundaries()
	_verify_fps_independence()
	_verify_independent_random_and_statistics()
	_verify_simultaneous_results_are_not_limited()
	_verify_new_plant_snapshot()
	var game=load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	_verify_development_ui(game)
	print("JELLY_DEV_SMOKE_OK rates=1/2/3/4 boundaries=5/10/15 fps=30/60/120 independent=true cooldown=none reset=true")
	get_tree().quit()
