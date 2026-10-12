class_name JellyBalance
extends RefCounted

const FORMAL := {
	"rate_0_5":0.01,
	"rate_5_10":0.025,
	"rate_10_15":0.05,
	"rate_15_plus":0.08,
	"growth_speed":1.6,"rhythm_amplitude":0.10
}

# Non-normal modes deliberately retain the balance they had before the formal
# normal-round adjustment.  Battle, old seeds, premium/volume/series seeds and
# catalog previews all use this snapshot unless a caller explicitly overrides it.
const NON_NORMAL := {
	"rate_0_5":0.01,
	"rate_5_10":0.02,
	"rate_10_15":0.03,
	"rate_15_plus":0.04,
	"growth_speed":1.0,"rhythm_amplitude":0.10
}

const RATE_KEYS := ["rate_0_5","rate_5_10","rate_10_15","rate_15_plus"]

static var override_enabled := false
static var values:Dictionary = FORMAL.duplicate(true)
static var initialized := false

static func begin_test_defaults()->void:
	if initialized:return
	values=FORMAL.duplicate(true);initialized=true

static func effective()->Dictionary:
	return values if override_enabled else FORMAL

static func reset_formal()->void:
	values=FORMAL.duplicate(true);override_enabled=false;initialized=true

static func set_value(key:String,value:float)->void:
	if not FORMAL.has(key):return
	begin_test_defaults()
	if key in RATE_KEYS:value=clampf(value,0.0,1.0)
	elif key=="growth_speed":value=clampf(value,0.1,10.0)
	values[key]=value;override_enabled=true

static func rate_values(source:Dictionary={}) -> Array[float]:
	var balance:=effective() if source.is_empty() else source
	var result:Array[float]=[]
	for key in RATE_KEYS:result.append(clampf(float(balance.get(key,FORMAL[key])),0.0,1.0))
	return result
