class_name KakuhenSystem
extends RefCounted

# Germination and normal-state re-entry are deliberately separate rolls.  The
# visible acceleration pool is always 80% real / 20% fake; hidden kakuhen is an
# independent slice of the same exclusive outcome table.
const GERMINATION_REAL_ACCELERATED_CHANCE := 0.096
const GERMINATION_REAL_HIDDEN_CHANCE := 0.030
const GERMINATION_FAKE_ACCELERATED_CHANCE := 0.024
const GERMINATION_VISIBLE_ACCELERATION_CHANCE := GERMINATION_REAL_ACCELERATED_CHANCE + GERMINATION_FAKE_ACCELERATED_CHANCE
const GERMINATION_ANY_EVENT_CHANCE := GERMINATION_VISIBLE_ACCELERATION_CHANCE + GERMINATION_REAL_HIDDEN_CHANCE

const REENTRY_REAL_ACCELERATED_CHANCE := 0.032
const REENTRY_REAL_HIDDEN_CHANCE := 0.010
const REENTRY_FAKE_ACCELERATED_CHANCE := 0.008
const REENTRY_VISIBLE_ACCELERATION_CHANCE := REENTRY_REAL_ACCELERATED_CHANCE + REENTRY_FAKE_ACCELERATED_CHANCE
const REENTRY_ANY_EVENT_CHANCE := REENTRY_VISIBLE_ACCELERATION_CHANCE + REENTRY_REAL_HIDDEN_CHANCE

const CONTINUE_CHANCE := 0.70
const INTERVAL_SECONDS := 5.0
const ACCELERATION_MULTIPLIER := 2.0
const REAL_ACCELERATED_JELLY_MULTIPLIER := 0.5
const REAL_HIDDEN_JELLY_MULTIPLIER := 0.0

const STATE_NONE := "none"
const STATE_REAL_ACCELERATED := "real_accelerated"
const STATE_REAL_HIDDEN := "real_hidden"
const STATE_FAKE_ACCELERATED := "fake_accelerated"


static func _outcome(draw:float,real_accelerated_chance:float,real_hidden_chance:float,fake_accelerated_chance:float)->String:
	var roll := clampf(draw, 0.0, 1.0)
	if roll < real_accelerated_chance:
		return STATE_REAL_ACCELERATED
	if roll < real_accelerated_chance + real_hidden_chance:
		return STATE_REAL_HIDDEN
	if roll < real_accelerated_chance + real_hidden_chance + fake_accelerated_chance:
		return STATE_FAKE_ACCELERATED
	return STATE_NONE


static func germination_outcome(draw:float)->String:
	return _outcome(draw,GERMINATION_REAL_ACCELERATED_CHANCE,GERMINATION_REAL_HIDDEN_CHANCE,GERMINATION_FAKE_ACCELERATED_CHANCE)


static func reentry_outcome(draw:float)->String:
	return _outcome(draw,REENTRY_REAL_ACCELERATED_CHANCE,REENTRY_REAL_HIDDEN_CHANCE,REENTRY_FAKE_ACCELERATED_CHANCE)


static func is_real(state: String) -> bool:
	return state in [STATE_REAL_ACCELERATED, STATE_REAL_HIDDEN]


static func is_accelerated(state: String) -> bool:
	return state in [STATE_REAL_ACCELERATED, STATE_FAKE_ACCELERATED]


static func jelly_rate_multiplier(state:String)->float:
	if state==STATE_REAL_ACCELERATED:return REAL_ACCELERATED_JELLY_MULTIPLIER
	if state==STATE_REAL_HIDDEN:return REAL_HIDDEN_JELLY_MULTIPLIER
	return 1.0
