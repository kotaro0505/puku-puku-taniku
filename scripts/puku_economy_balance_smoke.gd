extends Node

const SucculentClass=preload("res://scripts/succulent.gd")
const JellyBalanceClass=preload("res://scripts/jelly_balance.gd")
const KakuhenSystemClass=preload("res://scripts/kakuhen_system.gd")
const MainScript=preload("res://scripts/main.gd")

const ROUND_SEEDS:=12
const MONTE_CARLO_SAMPLES:=500000
const OBSERVATION_SAMPLES:=200000
const OBSERVATION_SECONDS:=60.0
const TARGETS:Array[float]=[30.0,50.0,60.0,70.0,80.0,100.0,120.0,130.0,140.0,150.0,200.0,300.0,500.0,1000.0]
const CURRENT_TRIAL_RATES:Array[float]=[0.01,0.02,0.045,0.075]


func _combination(n:int,k:int)->float:
	var result:=1.0
	var smaller:=mini(k,n-k)
	for index in range(1,smaller+1):result=result*float(n-smaller+index)/float(index)
	return result


func _binomial_probability(n:int,k:int,p:float)->float:
	return _combination(n,k)*pow(p,k)*pow(1.0-p,n-k)


func _survival_probability(start_age:float,duration:float,rates:Array[float],rate_multiplier:=1.0)->float:
	return 1.0-SucculentClass.jelly_probability_for_interval(start_age,duration,rates,rate_multiplier)


func _entry_distribution(germination:bool)->Array:
	if germination:
		return [
			[KakuhenSystemClass.STATE_NONE,1.0-KakuhenSystemClass.GERMINATION_ANY_EVENT_CHANCE],
			[KakuhenSystemClass.STATE_REAL_ACCELERATED,KakuhenSystemClass.GERMINATION_REAL_ACCELERATED_CHANCE],
			[KakuhenSystemClass.STATE_REAL_HIDDEN,KakuhenSystemClass.GERMINATION_REAL_HIDDEN_CHANCE],
			[KakuhenSystemClass.STATE_FAKE_ACCELERATED,KakuhenSystemClass.GERMINATION_FAKE_ACCELERATED_CHANCE],
		]
	return [
		[KakuhenSystemClass.STATE_NONE,1.0-KakuhenSystemClass.REENTRY_ANY_EVENT_CHANCE],
		[KakuhenSystemClass.STATE_REAL_ACCELERATED,KakuhenSystemClass.REENTRY_REAL_ACCELERATED_CHANCE],
		[KakuhenSystemClass.STATE_REAL_HIDDEN,KakuhenSystemClass.REENTRY_REAL_HIDDEN_CHANCE],
		[KakuhenSystemClass.STATE_FAKE_ACCELERATED,KakuhenSystemClass.REENTRY_FAKE_ACCELERATED_CHANCE],
	]


func _state_survival_probability(state_name:String,start_age:float,duration:float,rates:Array[float])->float:
	return _survival_probability(start_age,duration,rates,KakuhenSystemClass.jelly_rate_multiplier(state_name))


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
	# rhythm is omitted, while every state-specific hazard and five-second transition
	# is retained. Growth units are seconds at the formal x1.6 base speed.
	var base_cm_per_second:=SucculentClass.GROWTH_CM_PER_SECOND*float(JellyBalanceClass.FORMAL.growth_speed)
	var target_growth_units:=(target_cm-1.6)/base_cm_per_second
	var masses:Dictionary={}
	for outcome in _entry_distribution(true):_add_probability_mass(masses,str(outcome[0]),0.0,float(outcome[1]))
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
				var survival:=_state_survival_probability(state_name,interval_start_age,maxf(0.0,seconds_needed),JellyBalanceClass.rate_values(JellyBalanceClass.FORMAL))
				reached_probability+=probability*survival
			else:
				var interval_survival:=_state_survival_probability(state_name,interval_start_age,KakuhenSystemClass.INTERVAL_SECONDS,JellyBalanceClass.rate_values(JellyBalanceClass.FORMAL))
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
			elif state_name==KakuhenSystemClass.STATE_FAKE_ACCELERATED:
				_add_probability_mass(masses,KakuhenSystemClass.STATE_NONE,growth_units,probability)
			else:
				for outcome in _entry_distribution(false):_add_probability_mass(masses,str(outcome[0]),growth_units,probability*float(outcome[1]))
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
		var state_name:=KakuhenSystemClass.germination_outcome(random.randf())
		var rhythm_period:=growth_random.randf_range(16.0,28.0)
		var rhythm_phase:=growth_random.randf_range(0.0,TAU)
		var age:=0.0;var diameter:=1.6;var target_index:=0
		while target_index<TARGETS.size():
			var kakuhen_boundary:=(floorf(age/KakuhenSystemClass.INTERVAL_SECONDS)+1.0)*KakuhenSystemClass.INTERVAL_SECONDS
			var segment_end:=minf(kakuhen_boundary,_next_stage_boundary(age))
			var duration:=segment_end-age
			var failure_after:=INF
			var jelly_multiplier:=KakuhenSystemClass.jelly_rate_multiplier(state_name)
			if jelly_multiplier>0.0:
				var chance_per_second:=SucculentClass.jelly_chance_per_second(age,rates,jelly_multiplier)
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
				elif state_name==KakuhenSystemClass.STATE_FAKE_ACCELERATED:state_name=KakuhenSystemClass.STATE_NONE
				else:state_name=KakuhenSystemClass.reentry_outcome(random.randf())
	return counts


func _mark_event_seen(seen:Dictionary,state_name:String)->void:
	if state_name!=KakuhenSystemClass.STATE_NONE:seen[state_name]=true


func _sixty_second_observation_report(economy)->Dictionary:
	var random:=RandomNumberGenerator.new();random.seed=20261017
	var growth_random:=RandomNumberGenerator.new();growth_random.seed=20261018
	var rates:=JellyBalanceClass.rate_values(JellyBalanceClass.FORMAL)
	var base_cm_per_second:=SucculentClass.GROWTH_CM_PER_SECOND*float(JellyBalanceClass.FORMAL.growth_speed)
	var initial_counts:={KakuhenSystemClass.STATE_REAL_ACCELERATED:0,KakuhenSystemClass.STATE_REAL_HIDDEN:0,KakuhenSystemClass.STATE_FAKE_ACCELERATED:0,KakuhenSystemClass.STATE_NONE:0}
	var ever_counts:={KakuhenSystemClass.STATE_REAL_ACCELERATED:0,KakuhenSystemClass.STATE_REAL_HIDDEN:0,KakuhenSystemClass.STATE_FAKE_ACCELERATED:0}
	var harvested:=0;var jellied:=0;var harvested_cm_total:=0.0;var harvested_reward_units_total:=0
	for _sample in range(OBSERVATION_SAMPLES):
		var state_name:=KakuhenSystemClass.germination_outcome(random.randf())
		initial_counts[state_name]=int(initial_counts[state_name])+1
		var seen:Dictionary={};_mark_event_seen(seen,state_name)
		var rhythm_period:=growth_random.randf_range(16.0,28.0);var rhythm_phase:=growth_random.randf_range(0.0,TAU)
		var age:=0.0;var diameter:=1.6;var alive:=true
		while age<OBSERVATION_SECONDS-.0000001:
			var duration:=minf(KakuhenSystemClass.INTERVAL_SECONDS,OBSERVATION_SECONDS-age)
			var failure_after:=INF
			var jelly_multiplier:=KakuhenSystemClass.jelly_rate_multiplier(state_name)
			if jelly_multiplier>0.0:
				var chance_per_second:=SucculentClass.jelly_chance_per_second(age,rates,jelly_multiplier)
				if chance_per_second>=1.0:failure_after=0.0
				elif chance_per_second>0.0:failure_after=log(maxf(random.randf(),.000000000001))/log(1.0-chance_per_second)
			var lived_duration:=minf(duration,failure_after)
			var speed_factor:=KakuhenSystemClass.ACCELERATION_MULTIPLIER if KakuhenSystemClass.is_accelerated(state_name) else 1.0
			diameter+=_integrated_growth_rhythm(age,age+lived_duration,rhythm_period,rhythm_phase)*base_cm_per_second*speed_factor
			if failure_after<duration-.000000001:
				alive=false;jellied+=1;break
			age+=duration
			if age<OBSERVATION_SECONDS-.0000001:
				if KakuhenSystemClass.is_real(state_name):
					if random.randf()>=KakuhenSystemClass.CONTINUE_CHANCE:state_name=KakuhenSystemClass.STATE_NONE
				elif state_name==KakuhenSystemClass.STATE_FAKE_ACCELERATED:state_name=KakuhenSystemClass.STATE_NONE
				else:state_name=KakuhenSystemClass.reentry_outcome(random.randf())
				_mark_event_seen(seen,state_name)
		for seen_state in seen:ever_counts[seen_state]=int(ever_counts[seen_state])+1
		if alive:
			harvested+=1;harvested_cm_total+=diameter;harvested_reward_units_total+=economy._harvest_puku_reward_units(diameter,false)
	var average_harvest_cm:=harvested_cm_total/float(harvested) if harvested>0 else 0.0
	var expected_round_gross:=float(harvested_reward_units_total)/float(OBSERVATION_SAMPLES)*ROUND_SEEDS/float(economy.PUKU_UNITS_PER_PUKU)
	return {
		"observation_seconds":OBSERVATION_SECONDS,"samples":OBSERVATION_SAMPLES,
		"initial_counts":initial_counts,"ever_counts":ever_counts,
		"jellied_percent":snappedf(float(jellied)/OBSERVATION_SAMPLES*100.0,.0001),
		"harvested_percent":snappedf(float(harvested)/OBSERVATION_SAMPLES*100.0,.0001),
		"average_harvest_cm":snappedf(average_harvest_cm,.0001),
		"expected_round_gross_puku":snappedf(expected_round_gross,.0001),
		"expected_round_net_puku":snappedf(expected_round_gross-1.0,.0001),
	}


func _append_target(targets:Array[float],target:float,count:int)->void:
	for _index in range(count):targets.append(target)


func _strategy_definitions()->Array[Dictionary]:
	var early:Array[float]=[];_append_target(early,30.0,4);_append_target(early,40.0,4);_append_target(early,50.0,4)
	var frequent:Array[float]=[];_append_target(frequent,60.0,6);_append_target(frequent,70.0,6)
	var balanced:Array[float]=[]
	for target in [70.0,80.0,90.0,100.0]:_append_target(balanced,target,3)
	var ambitious:Array[float]=[];_append_target(ambitious,100.0,6);_append_target(ambitious,120.0,4);_append_target(ambitious,150.0,2)
	var large:Array[float]=[]
	for target in [120.0,130.0,140.0,150.0]:_append_target(large,target,3)
	var legend:Array[float]=[];_append_target(legend,70.0,8);_append_target(legend,100.0,2);legend.append(300.0);legend.append(500.0)
	return [
		{"id":"early_30_50","targets":early},
		{"id":"frequent_60_70","targets":frequent},
		{"id":"balanced_70_100","targets":balanced},
		{"id":"ambitious_100_plus","targets":ambitious},
		{"id":"large_120_150","targets":large},
		{"id":"some_300_plus","targets":legend},
	]


func _strategy_report(definition:Dictionary,probability_by_target:Dictionary,economy)->Dictionary:
	var distribution:Dictionary={0:1.0}
	for target_value in definition.targets:
		var target:=float(target_value);var probability:=float(probability_by_target[target]) if probability_by_target.has(target) else _exact_kakuhen_reach_probability(target);var reward_units:int=economy._harvest_puku_reward_units(target,false);var next_distribution:Dictionary={}
		for raw_units in distribution:
			var units:=int(raw_units);var mass:=float(distribution[raw_units])
			next_distribution[units]=float(next_distribution.get(units,0.0))+mass*(1.0-probability)
			var success_units:int=units+reward_units;next_distribution[success_units]=float(next_distribution.get(success_units,0.0))+mass*probability
		distribution=next_distribution
	var average_gross:=0.0;var red_rate:=0.0;var break_even_rate:=0.0;var black_rate:=0.0
	for raw_units in distribution:
		var units:=int(raw_units);var mass:=float(distribution[raw_units]);average_gross+=mass*float(units)/float(economy.PUKU_UNITS_PER_PUKU)
		if units<economy.NORMAL_ROUND_COST_UNITS:red_rate+=mass
		elif units>economy.NORMAL_ROUND_COST_UNITS:black_rate+=mass
		else:break_even_rate+=mass
	return {"id":str(definition.id),"targets_cm":definition.targets,"average_income_puku":snappedf(average_gross,.0001),"average_net_puku":snappedf(average_gross-1.0,.0001),"red_game_percent":snappedf(red_rate*100.0,.0001),"break_even_percent":snappedf(break_even_rate*100.0,.0001),"black_game_percent":snappedf(black_rate*100.0,.0001)}


func _ready()->void:
	var economy=MainScript.new()
	var monte_carlo_counts:=_monte_carlo_reach_counts()
	var rows:Array=[];var probability_by_target:Dictionary={}
	for target_index in range(TARGETS.size()):
		var target:=TARGETS[target_index]
		var target_age:=(target-1.6)/(SucculentClass.GROWTH_CM_PER_SECOND*1.6)
		var current_trial_survival:=_survival_probability(0.0,target_age,CURRENT_TRIAL_RATES)
		var exact_survival:=_exact_kakuhen_reach_probability(target)
		var observed_survival:=float(monte_carlo_counts[target_index])/MONTE_CARLO_SAMPLES
		var monte_carlo_tolerance:=.003 if target<=100.0 else .001 if target<=300.0 else .0006 if target<=500.0 else .00035
		assert(absf(observed_survival-exact_survival)<monte_carlo_tolerance,"target=%s observed=%s exact=%s"%[target,observed_survival,exact_survival])
		probability_by_target[target]=exact_survival
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
	assert(is_equal_approx(float(rows[11].reward_puku),55.49))
	assert(is_equal_approx(float(rows[12].reward_puku),82.50))
	assert(is_equal_approx(float(rows[13].reward_puku),150.0))
	var strategies:Array=[]
	for definition in _strategy_definitions():strategies.append(_strategy_report(definition,probability_by_target,economy))
	var observation_report:=_sixty_second_observation_report(economy)
	var continuation_report:={"mean_seconds":KakuhenSystemClass.INTERVAL_SECONDS/(1.0-KakuhenSystemClass.CONTINUE_CHANCE),"two_or_more_percent":KakuhenSystemClass.CONTINUE_CHANCE*100.0,"three_or_more_percent":pow(KakuhenSystemClass.CONTINUE_CHANCE,2.0)*100.0,"five_or_more_percent":pow(KakuhenSystemClass.CONTINUE_CHANCE,4.0)*100.0}
	var initial_per_round:={"real_accelerated":ROUND_SEEDS*KakuhenSystemClass.GERMINATION_REAL_ACCELERATED_CHANCE,"real_hidden":ROUND_SEEDS*KakuhenSystemClass.GERMINATION_REAL_HIDDEN_CHANCE,"fake_accelerated":ROUND_SEEDS*KakuhenSystemClass.GERMINATION_FAKE_ACCELERATED_CHANCE,"any_event":ROUND_SEEDS*KakuhenSystemClass.GERMINATION_ANY_EVENT_CHANCE}
	print("PUKU_ECONOMY_BALANCE_REPORT current_trial_rates=1/2/4.5/7.5 normal_rates=1/2.5/5/8 growth=1.6 rhythm=+-10% germination=9.6/3.0/2.4 reentry=3.2/1.0/.8 continuation=70 interval=5 samples=",MONTE_CARLO_SAMPLES," rows=",JSON.stringify(rows))
	print("PUKU_KAKUHEN_BALANCE_IMPACT initial_per_12=",JSON.stringify(initial_per_round)," continuation=",JSON.stringify(continuation_report)," observation=",JSON.stringify(observation_report))
	print("PUKU_ECONOMY_STRATEGY_REPORT assumptions=independent_plants_no_first_get_floor strategies=",JSON.stringify(strategies))
	print("PUKU_ECONOMY_BALANCE_SMOKE_OK targets=30-1000 exact=true monte_carlo=true reward_curve=jackpot_pchip mixed_strategies=true")
	economy.free()
	get_tree().quit()
