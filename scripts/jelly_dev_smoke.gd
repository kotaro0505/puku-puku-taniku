extends Node

const JellyBalanceClass = preload("res://scripts/jelly_balance.gd")
const SucculentClass = preload("res://scripts/succulent.gd")

var sample_species := {
	"species_id":"colorata","name_ja":"コロラータ","rarity":"通常",
	"visual_variant":"colorata","colors":["7f9f91","d35f6f"]
}

func _force_base_type(balance:Dictionary,type:String)->void:
	for key in ["short","normal","long","ultra"]:
		balance[key+"_weight"]=100.0 if key==type else 0.0

func _make_plant(balance:Dictionary,seed_value:int)->Succulent:
	JellyBalanceClass.values=balance.duplicate(true)
	JellyBalanceClass.override_enabled=true
	var plant:=SucculentClass.new()
	plant.setup(sample_species,seed_value,null,null)
	return plant

func _verify_slow_sticky_statistics()->void:
	var balance:=JellyBalanceClass.FORMAL.duplicate(true)
	balance.slow_short_rate=70.0
	var profile_rng:=RandomNumberGenerator.new();profile_rng.seed=20260904
	var short_count:=0;var slow_count:=0
	for i in range(20000):
		var base_type:=JellyBalanceClass.resistance_for_roll(profile_rng.randf(),balance)
		if base_type=="short":
			short_count+=1
			if JellyBalanceClass.slow_sticky_for_roll(base_type,profile_rng.randf(),balance):slow_count+=1
	var rate:=float(slow_count)/float(short_count)
	assert(short_count>8500 and short_count<9500)
	assert(rate>0.68 and rate<0.72)
	assert(float(slow_count)/20000.0>0.30 and float(slow_count)/20000.0<0.33)

func _verify_disabled_is_legacy()->void:
	var balance:=JellyBalanceClass.FORMAL.duplicate(true)
	_force_base_type(balance,"short");balance.slow_short_rate=0.0
	var selected_seed:=-1
	for seed_value in range(100):
		var probe:=RandomNumberGenerator.new();probe.seed=seed_value
		probe.randf_range(0.0,TAU);probe.randf();probe.randf_range(float(balance.safe_min),float(balance.safe_max))
		if JellyBalanceClass.resistance_for_roll(probe.randf(),balance)=="short":selected_seed=seed_value;break
	assert(selected_seed>=0)
	var expected:=RandomNumberGenerator.new();expected.seed=selected_seed
	expected.randf_range(0.0,TAU);expected.randf()
	var expected_safe:=expected.randf_range(float(balance.safe_min),float(balance.safe_max));expected.randf()
	var expected_ramp:=expected_safe+expected.randf_range(float(balance.short_min),float(balance.short_max))
	var expected_period:=expected.randf_range(16.0,28.0);var expected_phase:=expected.randf_range(0.0,TAU)
	var plant:=_make_plant(balance,selected_seed)
	assert(plant.base_resistance_type=="short" and plant.resistance_type=="short")
	assert(not plant.is_slow_sticky and is_equal_approx(plant.individual_growth_multiplier,1.0))
	assert(is_equal_approx(plant.jelly_safe_end_seconds,expected_safe))
	assert(is_equal_approx(plant.jelly_ramp_end_seconds,expected_ramp))
	assert(is_equal_approx(plant.growth_rhythm_period,expected_period) and is_equal_approx(plant.growth_rhythm_phase,expected_phase))
	plant.free()

func _verify_profile_bounds_and_common_hazard()->void:
	var slow_balance:=JellyBalanceClass.FORMAL.duplicate(true)
	_force_base_type(slow_balance,"short");slow_balance.slow_short_rate=100.0
	slow_balance.slow_growth_min=0.65;slow_balance.slow_growth_max=0.80;slow_balance.slow_ramp_min=12.0;slow_balance.slow_ramp_max=22.0
	var observed_min:=10.0;var observed_max:=0.0
	for seed_value in range(64):
		var plant:=_make_plant(slow_balance,seed_value+500)
		assert(plant.base_resistance_type=="short" and plant.resistance_type=="slow_sticky" and plant.is_slow_sticky)
		assert(plant.individual_growth_multiplier>=0.65 and plant.individual_growth_multiplier<=0.80)
		var ramp_duration:=plant.jelly_ramp_end_seconds-plant.jelly_safe_end_seconds
		assert(ramp_duration>=12.0 and ramp_duration<=22.0)
		assert(is_zero_approx(SucculentClass.jelly_chance_per_second(plant.jelly_safe_end_seconds,plant.jelly_safe_end_seconds,plant.jelly_ramp_end_seconds,plant.jelly_final_chance)))
		var midpoint:=(plant.jelly_safe_end_seconds+plant.jelly_ramp_end_seconds)*0.5
		var midpoint_chance:=SucculentClass.jelly_chance_per_second(midpoint,plant.jelly_safe_end_seconds,plant.jelly_ramp_end_seconds,plant.jelly_final_chance)
		assert(midpoint_chance>0.0 and midpoint_chance<plant.jelly_final_chance)
		assert(is_equal_approx(SucculentClass.jelly_chance_per_second(plant.jelly_ramp_end_seconds+10.0,plant.jelly_safe_end_seconds,plant.jelly_ramp_end_seconds,plant.jelly_final_chance),plant.jelly_final_chance))
		observed_min=minf(observed_min,plant.individual_growth_multiplier);observed_max=maxf(observed_max,plant.individual_growth_multiplier)
		plant.free()
	assert(observed_min<0.68 and observed_max>0.77)

	for type in ["normal","long","ultra"]:
		var regular_balance:=slow_balance.duplicate(true);_force_base_type(regular_balance,type)
		var regular:=_make_plant(regular_balance,900+type.length())
		assert(regular.base_resistance_type==type and regular.resistance_type==type)
		assert(not regular.is_slow_sticky and is_equal_approx(regular.individual_growth_multiplier,1.0))
		assert(regular.jelly_ramp_end_seconds-regular.jelly_safe_end_seconds>=float(regular_balance[type+"_min"]))
		assert(regular.jelly_ramp_end_seconds-regular.jelly_safe_end_seconds<=float(regular_balance[type+"_max"]))
		regular.free()

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._open_jelly_dev()
	assert(game.jelly_dev_overlay.visible and JellyBalanceClass.override_enabled)
	assert(is_equal_approx(float(JellyBalanceClass.values.final_chance),.06))
	assert(is_equal_approx(float(JellyBalanceClass.values.cooldown),1.0))
	assert(is_equal_approx(float(JellyBalanceClass.values.safe_min),3.8) and is_equal_approx(float(JellyBalanceClass.values.safe_max),6.2))
	assert(is_equal_approx(float(JellyBalanceClass.values.slow_short_rate),70.0))
	assert(is_equal_approx(float(JellyBalanceClass.values.slow_growth_min),0.65) and is_equal_approx(float(JellyBalanceClass.values.slow_growth_max),0.80))
	assert(is_equal_approx(float(JellyBalanceClass.values.slow_ramp_min),12.0) and is_equal_approx(float(JellyBalanceClass.values.slow_ramp_max),22.0))
	for key in ["slow_short_rate","slow_growth_min","slow_growth_max","slow_ramp_min","slow_ramp_max"]:assert(key in game.jelly_dev_labels)
	assert(is_equal_approx(JellyBalanceClass.weight_total(),100.0) and "100%" in game.jelly_dev_total_label.text)
	game.last_jelly_claim_msec=-1000000000;assert(game._try_claim_jelly() and not game._try_claim_jelly())
	game._change_jelly_dev_value("slow_short_rate",50.0);assert(is_equal_approx(float(JellyBalanceClass.values.slow_short_rate),100.0))
	game._change_jelly_dev_value("slow_short_rate",-200.0);assert(is_equal_approx(float(JellyBalanceClass.values.slow_short_rate),0.0))
	game._change_jelly_dev_value("slow_growth_min",1.0);game._change_jelly_dev_value("slow_growth_max",-1.0)
	assert(is_equal_approx(float(JellyBalanceClass.values.slow_growth_min),0.80) and is_equal_approx(float(JellyBalanceClass.values.slow_growth_max),0.80))
	game._change_jelly_dev_value("slow_ramp_min",20.0);game._change_jelly_dev_value("slow_ramp_max",-20.0)
	assert(is_equal_approx(float(JellyBalanceClass.values.slow_ramp_min),22.0) and is_equal_approx(float(JellyBalanceClass.values.slow_ramp_max),22.0))
	JellyBalanceClass.values.slow_short_rate=70.0;JellyBalanceClass.values.slow_growth_min=0.65;JellyBalanceClass.values.slow_growth_max=0.80;JellyBalanceClass.values.slow_ramp_min=12.0;JellyBalanceClass.values.slow_ramp_max=22.0
	_verify_disabled_is_legacy()
	_verify_slow_sticky_statistics()
	_verify_profile_bounds_and_common_hazard()

	var test_balance:=JellyBalanceClass.FORMAL.duplicate(true)
	_force_base_type(test_balance,"short");test_balance.slow_short_rate=100.0;test_balance.slow_growth_min=0.70;test_balance.slow_growth_max=0.70;test_balance.slow_ramp_min=12.0;test_balance.slow_ramp_max=22.0;test_balance.growth_speed=1.2
	JellyBalanceClass.values=test_balance;JellyBalanceClass.override_enabled=true
	game._dev_spawn_50cm();assert(game.dev_jelly_test_active and game.plants.size()==4 and not game.play_active)
	var profiles:Dictionary={}
	for plant in game.plants:
		assert(plant.is_slow_sticky and is_equal_approx(plant.individual_growth_multiplier,0.70))
		assert(is_equal_approx(plant.effective_growth_speed_multiplier(),0.84))
		assert(absf(plant.diameter_cm-50.0)<.01 and plant.age>38.0 and plant.growth_time>0.0)
		assert(is_equal_approx(plant.growth_time,plant._integrated_growth_multiplier(0.0,plant.age)))
		assert(plant.jelly_safe_end_seconds>=3.8 and plant.jelly_safe_end_seconds<=6.2)
		assert(plant.jelly_ramp_end_seconds-plant.jelly_safe_end_seconds>=12.0 and plant.jelly_ramp_end_seconds-plant.jelly_safe_end_seconds<=22.0)
		profiles["%.3f/%.3f"%[plant.jelly_safe_end_seconds,plant.jelly_ramp_end_seconds]]=true
	assert(profiles.size()>1)
	game.last_jelly_claim_msec=-1000000000;assert(game._try_claim_jelly() and game._try_claim_jelly())
	game._dev_reset_jelly()
	assert(not JellyBalanceClass.override_enabled and is_equal_approx(float(JellyBalanceClass.values.slow_short_rate),0.0))
	assert(is_equal_approx(float(JellyBalanceClass.effective().cooldown),0.0) and is_equal_approx(float(JellyBalanceClass.values.rhythm_amplitude),.10))
	print("JELLY_DEV_SMOKE_OK slow_disabled=legacy slow_full=100% slow_test_rate=70% bounds=.65-.80 ramp=12-22 fast_forward=50cm formal_reset=0%")
	get_tree().quit()
