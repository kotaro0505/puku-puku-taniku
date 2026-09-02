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
	"growth_speed":1.0,"rhythm_amplitude":0.10
}

# The formal game remains byte-for-byte equivalent at a 0% conversion rate.
# Opening the developer panel applies this candidate rate as an override only.
const SLOW_STICKY_TEST_RATE := 70.0

static var override_enabled := false
static var values:Dictionary = FORMAL.duplicate(true)
static var initialized := false

static func begin_test_defaults()->void:
	if initialized:return
	values=FORMAL.duplicate(true);values["cooldown"]=1.0;values["slow_short_rate"]=SLOW_STICKY_TEST_RATE;initialized=true

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
