class_name JellyBalance
extends RefCounted

const FORMAL := {
	"final_chance":0.06,"cooldown":0.0,"safe_min":3.8,"safe_max":6.2,
	"short_weight":45.0,"short_min":4.5,"short_max":8.5,
	"normal_weight":35.0,"normal_min":7.5,"normal_max":13.5,
	"long_weight":16.0,"long_min":12.0,"long_max":22.0,
	"ultra_weight":4.0,"ultra_min":22.0,"ultra_max":38.0,
	"slow_short_rate":0.0,"slow_growth_min":0.65,"slow_growth_max":0.80,
	"slow_ramp_min":12.0,"slow_ramp_max":22.0,
	"slow_resilient_rate":0.0,"regular_short_resilient_rate":0.0,
	"resilient_final_chance":0.03,
	"growth_speed":1.0,"rhythm_amplitude":0.10
}

# At 0% conversion rates the formal RNG draw sequence remains unchanged.
# Opening the developer panel applies these candidate rates as an override only.
const SLOW_STICKY_TEST_RATE := 70.0
const SLOW_RESILIENT_TEST_RATE := 30.0
const REGULAR_SHORT_RESILIENT_TEST_RATE := 5.0
const RESILIENT_FINAL_CHANCE_TEST := 0.03

static var override_enabled := false
static var values:Dictionary = FORMAL.duplicate(true)
static var initialized := false

static func begin_test_defaults()->void:
	if initialized:return
	values=FORMAL.duplicate(true);values["cooldown"]=1.0;apply_prediction_v1_test_values();initialized=true

static func apply_prediction_v1_test_values()->void:
	values["slow_short_rate"]=SLOW_STICKY_TEST_RATE
	values["slow_resilient_rate"]=SLOW_RESILIENT_TEST_RATE
	values["regular_short_resilient_rate"]=REGULAR_SHORT_RESILIENT_TEST_RATE
	values["resilient_final_chance"]=RESILIENT_FINAL_CHANCE_TEST
	values["slow_growth_min"]=0.65;values["slow_growth_max"]=0.80
	values["slow_ramp_min"]=12.0;values["slow_ramp_max"]=22.0
	override_enabled=true;initialized=true

static func effective()->Dictionary:
	return values if override_enabled else FORMAL

static func reset_formal()->void:
	values=FORMAL.duplicate(true);override_enabled=false;initialized=true

static func set_value(key:String,value:float)->void:
	begin_test_defaults();values[key]=value;override_enabled=true

static func weight_total(source:Dictionary={})->float:
	var balance:=values if source.is_empty() else source
	return float(balance.short_weight)+float(balance.normal_weight)+float(balance.long_weight)+float(balance.ultra_weight)

static func resistance_for_roll(roll:float,source:Dictionary={})->String:
	var balance:=values if source.is_empty() else source
	var total:=maxf(.001,weight_total(balance));var cursor:=0.0
	for key in ["short","normal","long","ultra"]:
		cursor+=float(balance[key+"_weight"])/total
		if roll<=cursor:return key
	return "ultra"

static func slow_sticky_for_roll(base_type:String,roll:float,source:Dictionary={})->bool:
	if base_type!="short":return false
	var balance:=values if source.is_empty() else source
	return roll<clampf(float(balance.slow_short_rate)/100.0,0.0,1.0)

static func resilient_for_roll(base_type:String,is_slow_sticky:bool,roll:float,source:Dictionary={})->bool:
	if base_type!="short":return false
	var balance:=values if source.is_empty() else source
	var key:="slow_resilient_rate" if is_slow_sticky else "regular_short_resilient_rate"
	return roll<clampf(float(balance[key])/100.0,0.0,1.0)
