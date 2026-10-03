extends Node

const SucculentClass=preload("res://scripts/succulent.gd")
const JellyBalanceClass=preload("res://scripts/jelly_balance.gd")
const MainScript=preload("res://scripts/main.gd")
const SAMPLE_SEEDS:=50000
const ROUND_SEEDS:=12
const TARGETS:=[20.0,30.0,40.0,50.0,60.0,70.0,80.0,90.0,100.0,110.0,120.0]

func _combination(n:int,k:int)->float:
	var result:=1.0
	var smaller:=mini(k,n-k)
	for index in range(1,smaller+1):result=result*float(n-smaller+index)/float(index)
	return result

func _binomial_probability(n:int,k:int,p:float)->float:
	return _combination(n,k)*pow(p,k)*pow(1.0-p,n-k)

func _ready()->void:
	var balance:Dictionary=JellyBalanceClass.endless_normal_trial_balance()
	var economy=MainScript.new()
	var survival_sums:Dictionary={}
	for target in TARGETS:survival_sums[target]=0.0
	for sample_index in range(SAMPLE_SEEDS):
		var plant=SucculentClass.new()
		plant.setup({"species_id":"economy_probe"},170000+sample_index,null,null,true,balance)
		for target in TARGETS:
			plant.fast_forward_to_diameter(float(target))
			var jelly_probability:float=SucculentClass.jelly_probability_for_interval(0.0,plant.age,plant.jelly_safe_end_seconds,plant.jelly_ramp_end_seconds,plant.jelly_final_chance)
			survival_sums[target]=float(survival_sums[target])+(1.0-jelly_probability)
		plant.free()
	var rows:Array=[]
	var net_by_target:Dictionary={}
	for target in TARGETS:
		var survival:float=float(survival_sums[target])/SAMPLE_SEEDS
		var reward_puku:float=float(economy._harvest_puku_reward_units(float(target),false))/economy.PUKU_UNITS_PER_PUKU
		var reached_plants:float=ROUND_SEEDS*survival
		var average_gross:float=reached_plants*reward_puku
		var average_net:float=average_gross-float(economy.NORMAL_ROUND_COST_UNITS)/float(economy.PUKU_UNITS_PER_PUKU)
		var net_variance:float=ROUND_SEEDS*survival*(1.0-survival)*reward_puku*reward_puku
		var red_rate:float=0.0;var black_rate:float=0.0;var break_even_rate:float=0.0;var big_win_rate:float=0.0
		for successes in range(ROUND_SEEDS+1):
			var probability:float=_binomial_probability(ROUND_SEEDS,successes,survival)
			var round_net:float=successes*reward_puku-1.0
			if round_net<-0.000001:red_rate+=probability
			elif round_net>0.000001:black_rate+=probability
			else:break_even_rate+=probability
			if round_net>=5.0:big_win_rate+=probability
		rows.append({
			"target_cm":target,
			"survival_percent":snappedf(survival*100.0,.01),
			"expected_reached_plants":snappedf(reached_plants,.01),
			"expected_jellied_plants":snappedf(ROUND_SEEDS-reached_plants,.01),
			"reward_puku":reward_puku,
			"average_harvest_reward_puku":snappedf(average_gross,.01),
			"average_net_puku":snappedf(average_net,.01),
			"net_variance":snappedf(net_variance,.01),
			"red_game_percent":snappedf(red_rate*100.0,.01),
			"break_even_percent":snappedf(break_even_rate*100.0,.01),
			"black_game_percent":snappedf(black_rate*100.0,.01),
			"big_win_net_5plus_percent":snappedf(big_win_rate*100.0,.01),
		})
		net_by_target[target]=average_net
	assert(float(net_by_target[20.0])<0.0 and float(net_by_target[30.0])<float(net_by_target[50.0]))
	print("PUKU_ECONOMY_BALANCE_REPORT settings=35/35/22/8 safe=3.8-6.2 final=6% round_seeds=12 entry_cost=1.00 samples=",SAMPLE_SEEDS," rows=",JSON.stringify(rows))
	print("PUKU_ECONOMY_BALANCE_SMOKE_OK targets=20-120 round_model=true")
	economy.free()
	get_tree().quit()
