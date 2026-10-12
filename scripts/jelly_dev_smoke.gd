extends Node

const JellyBalanceClass = preload("res://scripts/jelly_balance.gd")
const SucculentClass = preload("res://scripts/succulent.gd")
const KakuhenSystemClass = preload("res://scripts/kakuhen_system.gd")

const SAMPLE_COUNT := 30000
const KAKUHEN_ENTRY_SAMPLES := 400000
const KAKUHEN_CONTINUATION_SAMPLES := 200000
const FORMAL_RATES:Array[float] = [0.01, 0.025, 0.05, 0.08]
const NON_NORMAL_RATES:Array[float] = [0.01, 0.02, 0.03, 0.04]

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

func _kakuhen_balance(rates:Array[float]=FORMAL_RATES)->Dictionary:
	var balance:=JellyBalanceClass.FORMAL.duplicate(true)
	for index in range(JellyBalanceClass.RATE_KEYS.size()):balance[JellyBalanceClass.RATE_KEYS[index]]=rates[index]
	balance["kakuhen_enabled"]=true
	return balance

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
	_approx(SucculentClass.jelly_chance_per_second(7.0,FORMAL_RATES),0.025)
	_approx(SucculentClass.jelly_chance_per_second(12.0,FORMAL_RATES),0.05)
	_approx(SucculentClass.jelly_chance_per_second(20.0,FORMAL_RATES),0.08)
	_approx(SucculentClass.jelly_probability_for_interval(0.0,5.0,FORMAL_RATES),1.0-pow(.99,5.0))
	_approx(SucculentClass.jelly_probability_for_interval(4.0,2.0,FORMAL_RATES),1.0-.99*.975)
	_approx(SucculentClass.jelly_probability_for_interval(9.0,7.0,FORMAL_RATES),1.0-.975*pow(.95,5.0)*.92)
	_approx(SucculentClass.jelly_probability_for_interval(0.0,20.0,FORMAL_RATES),1.0-pow(.99,5.0)*pow(.975,5.0)*pow(.95,5.0)*pow(.92,5.0))
	_approx(float(JellyBalanceClass.FORMAL.growth_speed),1.6)
	assert(JellyBalanceClass.rate_values(JellyBalanceClass.NON_NORMAL)==NON_NORMAL_RATES)
	_approx(float(JellyBalanceClass.NON_NORMAL.growth_speed),1.0)

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

func _verify_non_normal_modes_keep_previous_balance()->void:
	var plant:=_make_plant(4001)
	assert(plant.jelly_rates_per_second==NON_NORMAL_RATES)
	_approx(plant.growth_speed_multiplier,1.0)
	assert(not plant.kakuhen_enabled and plant.kakuhen_state==KakuhenSystemClass.STATE_NONE)
	plant.free()

func _verify_kakuhen_entry_statistics()->void:
	var probe:=RandomNumberGenerator.new();probe.seed=20261013
	var counts:={
		KakuhenSystemClass.STATE_REAL_ACCELERATED:0,
		KakuhenSystemClass.STATE_REAL_HIDDEN:0,
		KakuhenSystemClass.STATE_FAKE_ACCELERATED:0,
		KakuhenSystemClass.STATE_NONE:0,
	}
	for _sample in range(KAKUHEN_ENTRY_SAMPLES):
		var outcome:=KakuhenSystemClass.entry_outcome(probe.randf())
		counts[outcome]=int(counts[outcome])+1
	var real_count:=int(counts[KakuhenSystemClass.STATE_REAL_ACCELERATED])+int(counts[KakuhenSystemClass.STATE_REAL_HIDDEN])
	var visible_acceleration_count:=int(counts[KakuhenSystemClass.STATE_REAL_ACCELERATED])+int(counts[KakuhenSystemClass.STATE_FAKE_ACCELERATED])
	var observed_real:=float(real_count)/KAKUHEN_ENTRY_SAMPLES
	var observed_real_accelerated_share:=float(counts[KakuhenSystemClass.STATE_REAL_ACCELERATED])/real_count
	var observed_fake_visible_share:=float(counts[KakuhenSystemClass.STATE_FAKE_ACCELERATED])/visible_acceleration_count
	assert(absf(observed_real-KakuhenSystemClass.REAL_ENTRY_CHANCE)<.00035)
	assert(absf(observed_real_accelerated_share-.70)<.035)
	assert(absf(observed_fake_visible_share-.20)<.035)
	var continued:=0;probe.seed=20261014
	for _sample in range(KAKUHEN_CONTINUATION_SAMPLES):
		if probe.randf()<KakuhenSystemClass.CONTINUE_CHANCE:continued+=1
	var observed_continue:=float(continued)/KAKUHEN_CONTINUATION_SAMPLES
	assert(absf(observed_continue-KakuhenSystemClass.CONTINUE_CHANCE)<.003)
	print("KAKUHEN_ENTRY_STAT_PROFILE samples=",KAKUHEN_ENTRY_SAMPLES," counts=",counts," real_rate=",observed_real," real_accelerated_share=",observed_real_accelerated_share," fake_visible_share=",observed_fake_visible_share," continuation_samples=",KAKUHEN_CONTINUATION_SAMPLES," continuation_rate=",observed_continue)

func _seed_for_continuations(draw_count:int)->int:
	var probe:=RandomNumberGenerator.new()
	for candidate_seed in range(200000):
		probe.seed=candidate_seed
		var matches:=true
		for _index in range(draw_count):
			if probe.randf()>=KakuhenSystemClass.CONTINUE_CHANCE:
				matches=false;break
		if matches:return candidate_seed
	assert(false,"could not find continuation seed")
	return 0

func _seed_for_exit_then_real_entry()->int:
	var probe:=RandomNumberGenerator.new()
	for candidate_seed in range(500000):
		probe.seed=candidate_seed
		if probe.randf()>=KakuhenSystemClass.CONTINUE_CHANCE and probe.randf()<KakuhenSystemClass.REAL_ENTRY_CHANCE:return candidate_seed
	assert(false,"could not find exit/re-entry seed")
	return 0

func _prepare_forced_kakuhen_state(plant:Succulent,state_name:String)->void:
	plant.age=0.0;plant.growth_time=0.0;plant.diameter_cm=1.6;plant.visual_scale=.18
	plant.kakuhen_state=state_name;plant.kakuhen_next_boundary_age=KakuhenSystemClass.INTERVAL_SECONDS
	plant.kakuhen_entry_roll_count=0;plant.kakuhen_continuation_roll_count=0;plant.kakuhen_boundary_count=0

func _verify_kakuhen_protection_continuation_and_reentry()->void:
	var forced_rates:Array[float]=[1.0,1.0,1.0,1.0]
	var real_hidden:=_make_plant(5101,_kakuhen_balance(forced_rates))
	_prepare_forced_kakuhen_state(real_hidden,KakuhenSystemClass.STATE_REAL_HIDDEN)
	real_hidden.simulate(.1)
	assert(real_hidden.state=="growing")
	_approx(real_hidden.effective_growth_speed_multiplier(),1.6)
	real_hidden.free()

	var fake:=_make_plant(5102,_kakuhen_balance(forced_rates))
	_prepare_forced_kakuhen_state(fake,KakuhenSystemClass.STATE_FAKE_ACCELERATED)
	_approx(fake.effective_growth_speed_multiplier(),2.24)
	fake.simulate(.1)
	assert(fake.state=="jelly")
	fake.free()

	var long_chain:=_make_plant(5103,_kakuhen_balance())
	_prepare_forced_kakuhen_state(long_chain,KakuhenSystemClass.STATE_REAL_HIDDEN)
	long_chain.jelly_checks_enabled=false
	long_chain.kakuhen_rng.seed=_seed_for_continuations(30)
	long_chain.simulate(300.0)
	assert(long_chain.state=="growing" and long_chain.kakuhen_state==KakuhenSystemClass.STATE_REAL_HIDDEN)
	assert(long_chain.kakuhen_boundary_count==30 and long_chain.kakuhen_continuation_roll_count==30)
	long_chain.free()

	var reentry:=_make_plant(5104,_kakuhen_balance())
	_prepare_forced_kakuhen_state(reentry,KakuhenSystemClass.STATE_REAL_HIDDEN)
	reentry.jelly_checks_enabled=false
	reentry.kakuhen_rng.seed=_seed_for_exit_then_real_entry()
	reentry.simulate(10.0)
	assert(reentry.kakuhen_state==KakuhenSystemClass.STATE_NONE and reentry.kakuhen_entry_roll_count==0)
	reentry.simulate(9.999)
	assert(reentry.kakuhen_state==KakuhenSystemClass.STATE_NONE and reentry.kakuhen_entry_roll_count==0)
	reentry.simulate(.001)
	assert(KakuhenSystemClass.is_real(reentry.kakuhen_state) and reentry.kakuhen_entry_roll_count==1)
	reentry.free()

func _verify_growth_speed_changes_are_continuous()->void:
	var normal:=_make_plant(6201,JellyBalanceClass.FORMAL)
	var accelerated:=_make_plant(6201,JellyBalanceClass.FORMAL)
	normal.jelly_checks_enabled=false;accelerated.jelly_checks_enabled=false
	normal.simulate(3.0);accelerated.simulate(3.0)
	var normal_before:=normal.diameter_cm;var accelerated_before:=accelerated.diameter_cm
	accelerated.kakuhen_state=KakuhenSystemClass.STATE_REAL_ACCELERATED
	_approx(accelerated.diameter_cm,accelerated_before)
	normal.simulate(1.0);accelerated.simulate(1.0)
	var normal_increment:=normal.diameter_cm-normal_before
	var accelerated_increment:=accelerated.diameter_cm-accelerated_before
	_approx(accelerated_increment/normal_increment,KakuhenSystemClass.ACCELERATION_MULTIPLIER,.00001)
	var before_exit:=accelerated.diameter_cm
	accelerated.kakuhen_state=KakuhenSystemClass.STATE_NONE
	_approx(accelerated.diameter_cm,before_exit)
	var growth_before:=accelerated.growth_time
	accelerated.simulate(1.0)
	var expected_growth:=accelerated._integrated_growth_multiplier(4.0,5.0)*accelerated.growth_speed_multiplier
	_approx(accelerated.growth_time-growth_before,expected_growth,.00001)
	var teleported:=_make_plant(6202,JellyBalanceClass.FORMAL)
	teleported.fast_forward_to_diameter(500.0)
	_approx(teleported.diameter_cm,500.0,.00001)
	var teleport_before:=teleported.diameter_cm
	teleported.simulate(.01)
	assert(teleported.diameter_cm>teleport_before and teleported.diameter_cm-teleport_before<.1)
	normal.free();accelerated.free();teleported.free()

func _verify_kakuhen_boundaries_are_fps_independent()->void:
	var one_frame:=_make_plant(7301,_kakuhen_balance())
	one_frame.jelly_checks_enabled=false
	one_frame.simulate(35.0)
	for fps in [30,60,120]:
		var stepped:=_make_plant(7301,_kakuhen_balance())
		stepped.jelly_checks_enabled=false
		var step:=1.0/float(fps)
		for _frame in range(35*fps):stepped.simulate(step)
		_approx(stepped.age,one_frame.age,.0001)
		_approx(stepped.diameter_cm,one_frame.diameter_cm,.001)
		assert(stepped.kakuhen_state==one_frame.kakuhen_state)
		assert(stepped.kakuhen_boundary_count==3 and stepped.kakuhen_boundary_count==one_frame.kakuhen_boundary_count)
		assert(stepped.kakuhen_entry_roll_count==one_frame.kakuhen_entry_roll_count)
		assert(stepped.kakuhen_continuation_roll_count==one_frame.kakuhen_continuation_roll_count)
		stepped.free()
	one_frame.free()

func _verify_development_ui(game)->void:
	game._open_jelly_dev()
	assert(game.jelly_dev_overlay.visible and JellyBalanceClass.override_enabled)
	assert(game.jelly_dev_labels.size()==5)
	for key in JellyBalanceClass.RATE_KEYS:
		assert(key in game.jelly_dev_labels)
	assert("growth_speed" in game.jelly_dev_labels)
	assert(game.jelly_dev_labels.rate_0_5.text=="0〜5秒 ジュレ率：1.0%")
	assert(game.jelly_dev_labels.rate_5_10.text=="5〜10秒 ジュレ率：2.5%")
	assert(game.jelly_dev_labels.rate_10_15.text=="10〜15秒 ジュレ率：5.0%")
	assert(game.jelly_dev_labels.rate_15_plus.text=="15秒以降 ジュレ率：8.0%")
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
	_approx(float(JellyBalanceClass.values.growth_speed),1.8)

	JellyBalanceClass.set_value("rate_5_10",.125)
	game._dev_spawn_50cm()
	assert(game.dev_jelly_test_active and game.plants.size()==4 and not game.play_active)
	for plant in game.plants:
		_approx(plant.jelly_rates_per_second[1],.125)
		_approx(plant.effective_growth_speed_multiplier(),1.8)
		assert(not plant.kakuhen_enabled)
		assert(absf(plant.diameter_cm-50.0)<.01)

	game._dev_reset_jelly()
	assert(not JellyBalanceClass.override_enabled and not game.dev_jelly_test_active)
	assert(JellyBalanceClass.rate_values(JellyBalanceClass.values)==FORMAL_RATES)
	_approx(float(JellyBalanceClass.values.growth_speed),1.6)

func _ready()->void:
	_verify_formal_rates_and_boundaries()
	_verify_fps_independence()
	_verify_independent_random_and_statistics()
	_verify_simultaneous_results_are_not_limited()
	_verify_new_plant_snapshot()
	_verify_non_normal_modes_keep_previous_balance()
	_verify_kakuhen_entry_statistics()
	_verify_kakuhen_protection_continuation_and_reentry()
	_verify_growth_speed_changes_are_continuous()
	_verify_kakuhen_boundaries_are_fps_independent()
	var game=load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	_verify_development_ui(game)
	print("JELLY_DEV_SMOKE_OK normal_rates=1/2.5/5/8 normal_growth=1.6 non_normal_rates=1/2/3/4 non_normal_growth=1.0 kakuhen_entry=.5 real_mix=70/30 fake_visible=20 continuation=91 interval=10 fps=30/60/120 continuity=true independent=true reset=true")
	get_tree().quit()
