extends Node

const SucculentClass=preload("res://scripts/succulent.gd")
const JellyBalanceClass=preload("res://scripts/jelly_balance.gd")
const KakuhenSystemClass=preload("res://scripts/kakuhen_system.gd")
const MainScript=preload("res://scripts/main.gd")

const ROUND_SEEDS:=12
const MONTE_CARLO_SAMPLES:=500000
const TARGETS:Array[float]=[50.0,70.0,100.0,150.0,200.0,300.0,500.0,1000.0]
const CURRENT_TRIAL_RATES:Array[float]=[0.01,0.02,0.045,0.075]
const EXPECTED_NEW_PERCENT:Array[float]=[36.311272,17.485572,6.276349,1.727118,.933624,.590064,.300930,.059000]


func _combination(n:int,k:int)->float:
	var result:=1.0
	var smaller:=mini(k,n-k)
	for index in range(1,smaller+1):result=result*float(n-smaller+index)/float(index)
	return result


func _binomial_probability(n:int,k:int,p:float)->float:
	return _combination(n,k)*pow(p,k)*pow(1.0-p,n-k)


func _survival_probability(start_age:float,duration:float,rates:Array[float])->float:
	return 1.0-SucculentClass.jelly_probability_for_interval(start_age,duration,rates)


func _entry_distribution()->Array:
	return [
		[KakuhenSystemClass.STATE_NONE,1.0-KakuhenSystemClass.ANY_EVENT_CHANCE],
		[KakuhenSystemClass.STATE_REAL_ACCELERATED,KakuhenSystemClass.REAL_ACCELERATED_CHANCE],
		[KakuhenSystemClass.STATE_REAL_HIDDEN,KakuhenSystemClass.REAL_HIDDEN_CHANCE],
		[KakuhenSystemClass.STATE_FAKE_ACCELERATED,KakuhenSystemClass.FAKE_ACCELERATED_CHANCE],
	]


func _add_probability_mass(target:Dictionary,state_name:String,growth_units:float,probability:float)->void:
	if probability<=0.0:return
	var key:="%s:%s"%[state_name,roundi(growth_units*1000000.0)]
	if target.has(key):
		var existing:Dictionary=target[key]
		existing["probability"]=float(existing["probability"])+probability
		target[key]=existing
	else:target[key]={"state":state_name,"growth_units":growth_units,"probability":probability}


func _exact_kakuhen_reach_probability(target_cm:float)->float:
	# Exact discrete-state calculation for the documented approximation: growth
	# rhythm is omitted, while every normal hazard and ten-second state transition
	# is retained. Growth units are seconds at the formal x1.6 base speed.
	var base_cm_per_second:=SucculentClass.GROWTH_CM_PER_SECOND*float(JellyBalanceClass.FORMAL.growth_speed)
	var target_growth_units:=(target_cm-1.6)/base_cm_per_second
	var masses:Dictionary={}
	for outcome in _entry_distribution():_add_probability_mass(masses,str(outcome[0]),0.0,float(outcome[1]))
	var interval_start_age:=0.0
	var reached_probability:=0.0
	for _interval in range(10000):
		var survivors:Array=[]
		for raw_mass in masses.values():
			var mass:Dictionary=raw_mass
			var state_name:=str(mass["state"]);var growth_units:=float(mass["growth_units"]);var probability:=float(mass["probability"])
			var speed_factor:=KakuhenSystemClass.ACCELERATION_MULTIPLIER if KakuhenSystemClass.is_accelerated(state_name) else 1.0
			var seconds_needed:=(target_growth_units-growth_units)/speed_factor
			if seconds_needed<=KakuhenSystemClass.INTERVAL_SECONDS+.000000001:
				var survival:=1.0 if KakuhenSystemClass.is_real(state_name) else _survival_probability(interval_start_age,maxf(0.0,seconds_needed),JellyBalanceClass.rate_values(JellyBalanceClass.FORMAL))
				reached_probability+=probability*survival
			else:
				var interval_survival:=1.0 if KakuhenSystemClass.is_real(state_name) else _survival_probability(interval_start_age,KakuhenSystemClass.INTERVAL_SECONDS,JellyBalanceClass.rate_values(JellyBalanceClass.FORMAL))
				survivors.append([state_name,growth_units+KakuhenSystemClass.INTERVAL_SECONDS*speed_factor,probability*interval_survival])
		if survivors.is_empty():break
		interval_start_age+=KakuhenSystemClass.INTERVAL_SECONDS
		masses={}
		for survivor in survivors:
			var state_name:=str(survivor[0]);var growth_units:=float(survivor[1]);var probability:=float(survivor[2])
			if state_name==KakuhenSystemClass.STATE_REAL_ACCELERATED:
				_add_probability_mass(masses,state_name,growth_units,probability*KakuhenSystemClass.CONTINUE_CHANCE)
				_add_probability_mass(masses,KakuhenSystemClass.STATE_NONE,growth_units,probability*(1.0-KakuhenSystemClass.CONTINUE_CHANCE))
			elif state_name==KakuhenSystemClass.STATE_REAL_HIDDEN:
				_add_probability_mass(masses,state_name,growth_units,probability*KakuhenSystemClass.CONTINUE_CHANCE)
				_add_probability_mass(masses,KakuhenSystemClass.STATE_NONE,growth_units,probability*(1.0-KakuhenSystemClass.CONTINUE_CHANCE))
			else:
				for outcome in _entry_distribution():_add_probability_mass(masses,str(outcome[0]),growth_units,probability*float(outcome[1]))
	return reached_probability


func _next_stage_boundary(age:float)->float:
	if age<5.0:return 5.0
	if age<10.0:return 10.0
	if age<15.0:return 15.0
	return (floorf(age/KakuhenSystemClass.INTERVAL_SECONDS)+1.0)*KakuhenSystemClass.INTERVAL_SECONDS


func _integrated_growth_rhythm(start_age:float,end_age:float,period:float,phase:float)->float:
	var duration:=maxf(0.0,end_age-start_age)
	var amplitude:=float(JellyBalanceClass.FORMAL.rhythm_amplitude)
	if duration<=0.0 or amplitude<=0.0:return duration
	var omega:=TAU/maxf(.001,period)
	return duration+(amplitude/omega)*(cos(omega*start_age+phase)-cos(omega*end_age+phase))


func _monte_carlo_reach_counts()->Array[int]:
	var counts:Array[int]=[]
	for _target in TARGETS:counts.append(0)
	var random:=RandomNumberGenerator.new();random.seed=20261015
	var growth_random:=RandomNumberGenerator.new();growth_random.seed=20261016
	var rates:=JellyBalanceClass.rate_values(JellyBalanceClass.FORMAL)
	var base_cm_per_second:=SucculentClass.GROWTH_CM_PER_SECOND*float(JellyBalanceClass.FORMAL.growth_speed)
	for _sample in range(MONTE_CARLO_SAMPLES):
		var state_name:=KakuhenSystemClass.entry_outcome(random.randf())
		var rhythm_period:=growth_random.randf_range(16.0,28.0)
		var rhythm_phase:=growth_random.randf_range(0.0,TAU)
		var age:=0.0;var diameter:=1.6;var target_index:=0
		while target_index<TARGETS.size():
			var kakuhen_boundary:=(floorf(age/KakuhenSystemClass.INTERVAL_SECONDS)+1.0)*KakuhenSystemClass.INTERVAL_SECONDS
			var segment_end:=minf(kakuhen_boundary,_next_stage_boundary(age))
			var duration:=segment_end-age
			var failure_after:=INF
			if not KakuhenSystemClass.is_real(state_name):
				var chance_per_second:=SucculentClass.jelly_chance_per_second(age,rates)
				if chance_per_second>=1.0:failure_after=0.0
				elif chance_per_second>0.0:failure_after=log(maxf(random.randf(),.000000000001))/log(1.0-chance_per_second)
			var lived_duration:=minf(duration,failure_after)
			var speed_factor:=KakuhenSystemClass.ACCELERATION_MULTIPLIER if KakuhenSystemClass.is_accelerated(state_name) else 1.0
			diameter+=_integrated_growth_rhythm(age,age+lived_duration,rhythm_period,rhythm_phase)*base_cm_per_second*speed_factor
			while target_index<TARGETS.size() and diameter>=TARGETS[target_index]:
				counts[target_index]+=1;target_index+=1
			if failure_after<duration-.000000001:break
			age=segment_end
			if is_equal_approx(age,kakuhen_boundary):
				if KakuhenSystemClass.is_real(state_name):
					if random.randf()>=KakuhenSystemClass.CONTINUE_CHANCE:state_name=KakuhenSystemClass.STATE_NONE
				else:state_name=KakuhenSystemClass.entry_outcome(random.randf())
	return counts


func _ready()->void:
	var economy=MainScript.new()
	var monte_carlo_counts:=_monte_carlo_reach_counts()
	var rows:Array=[]
	for target_index in range(TARGETS.size()):
		var target:=TARGETS[target_index]
		var target_age:=(target-1.6)/(SucculentClass.GROWTH_CM_PER_SECOND*1.6)
		var current_trial_survival:=_survival_probability(0.0,target_age,CURRENT_TRIAL_RATES)
		var exact_survival:=_exact_kakuhen_reach_probability(target)
		var observed_survival:=float(monte_carlo_counts[target_index])/MONTE_CARLO_SAMPLES
		assert(absf(exact_survival*100.0-EXPECTED_NEW_PERCENT[target_index])<.00002,"target=%s actual=%s expected=%s"%[target,exact_survival*100.0,EXPECTED_NEW_PERCENT[target_index]])
		var monte_carlo_tolerance:=.003 if target<=100.0 else .001 if target<=300.0 else .0006 if target<=500.0 else .00035
		assert(absf(observed_survival-exact_survival)<monte_carlo_tolerance,"target=%s observed=%s exact=%s"%[target,observed_survival,exact_survival])
		var reward_puku:float=float(economy._harvest_puku_reward_units(target,false))/float(economy.PUKU_UNITS_PER_PUKU)
		var reached_plants:float=ROUND_SEEDS*exact_survival
		var average_gross:float=reached_plants*reward_puku
		var average_net:float=average_gross-float(economy.NORMAL_ROUND_COST_UNITS)/float(economy.PUKU_UNITS_PER_PUKU)
		var red_rate:=0.0;var black_rate:=0.0;var break_even_rate:=0.0;var big_win_rate:=0.0
		for successes in range(ROUND_SEEDS+1):
			var probability:=_binomial_probability(ROUND_SEEDS,successes,exact_survival)
			var round_net:float=successes*reward_puku-1.0
			if round_net<-.000001:red_rate+=probability
			elif round_net>.000001:black_rate+=probability
			else:break_even_rate+=probability
			if round_net>=5.0:big_win_rate+=probability
		rows.append({
			"target_cm":target,
			"current_trial_percent":snappedf(current_trial_survival*100.0,.000001),
			"new_exact_percent":snappedf(exact_survival*100.0,.000001),
			"new_observed_percent":snappedf(observed_survival*100.0,.000001),
			"reward_puku":reward_puku,
			"expected_reached_plants":snappedf(reached_plants,.0001),
			"average_harvest_reward_puku":snappedf(average_gross,.0001),
			"average_net_puku":snappedf(average_net,.0001),
			"red_game_percent":snappedf(red_rate*100.0,.0001),
			"break_even_percent":snappedf(break_even_rate*100.0,.0001),
			"black_game_percent":snappedf(black_rate*100.0,.0001),
			"big_win_net_5plus_percent":snappedf(big_win_rate*100.0,.0001),
		})
	assert(absf(float(rows[2].new_exact_percent)-float(rows[2].current_trial_percent))<.5)
	assert(is_equal_approx(float(rows[5].reward_puku),62.0))
	assert(is_equal_approx(float(rows[6].reward_puku),122.0))
	assert(is_equal_approx(float(rows[7].reward_puku),272.0))
	print("PUKU_ECONOMY_BALANCE_REPORT current_trial_rates=1/2/4.5/7.5 normal_rates=1/2.5/5/8 growth=1.6 rhythm=+-10% kakuhen=.5 continuation=91 samples=",MONTE_CARLO_SAMPLES," rows=",JSON.stringify(rows))
	print("PUKU_ECONOMY_BALANCE_SMOKE_OK targets=50-1000 exact=true monte_carlo=true reward_curve=unchanged")
	economy.free()
	get_tree().quit()
