extends Node

const SucculentClass=preload("res://scripts/succulent.gd")
const JellyBalanceClass=preload("res://scripts/jelly_balance.gd")
const MainScript=preload("res://scripts/main.gd")
const SAMPLE_SEEDS:=50000
const TARGETS:=[50.0,60.0,70.0,80.0,90.0,100.0]

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
	var best_mid_net:float=-INF
	var net_100:float=-INF
	for target in TARGETS:
		var survival:float=float(survival_sums[target])/SAMPLE_SEEDS
		var reward_puku:float=float(economy._harvest_puku_reward_units(float(target),false))/economy.PUKU_UNITS_PER_PUKU
		var harvested_per_100:float=100.0*survival
		var jellied_per_100:float=100.0-harvested_per_100
		var gross_per_100:float=harvested_per_100*reward_puku
		var net_per_100:float=gross_per_100-100.0*float(economy.ENDLESS_NORMAL_SEED_COST_UNITS)/economy.PUKU_UNITS_PER_PUKU
		var seeds_per_success:float=1.0/maxf(survival,.000001)
		rows.append({
			"target_cm":target,
			"survival_percent":snappedf(survival*100.0,.01),
			"seeds_used":100,
			"harvested":snappedf(harvested_per_100,.01),
			"jellied":snappedf(jellied_per_100,.01),
			"reward_puku":reward_puku,
			"net_puku_per_100_seeds":snappedf(net_per_100,.01),
			"seeds_per_success":snappedf(seeds_per_success,.01),
			"jellies_per_success":snappedf(seeds_per_success-1.0,.01),
			"net_puku_per_success_cycle":snappedf(reward_puku-float(economy.ENDLESS_NORMAL_SEED_COST_UNITS)/economy.PUKU_UNITS_PER_PUKU/maxf(survival,.000001),.01),
		})
		if target>=70.0 and target<=90.0:best_mid_net=maxf(best_mid_net,net_per_100)
		if is_equal_approx(float(target),100.0):net_100=net_per_100
	assert(net_100<best_mid_net)
	print("PUKU_ECONOMY_BALANCE_REPORT settings=35/35/22/8 safe=3.8-6.2 final=6% seed_cost=.20 samples=",SAMPLE_SEEDS," rows=",JSON.stringify(rows))
	print("PUKU_ECONOMY_BALANCE_SMOKE_OK hundred_not_best=true")
	economy.free()
	get_tree().quit()
