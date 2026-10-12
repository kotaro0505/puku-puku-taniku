class_name KakuhenSystem
extends RefCounted

# Every roll is exclusive.  The thresholds intentionally encode the product
# requirements directly so a visible acceleration is real 80% of the time and
# fake 20% of the time, while the total real entry chance remains 0.5%.
const REAL_ACCELERATED_CHANCE := 0.0035
const REAL_HIDDEN_CHANCE := 0.0015
const FAKE_ACCELERATED_CHANCE := 0.000875
const REAL_ENTRY_CHANCE := REAL_ACCELERATED_CHANCE + REAL_HIDDEN_CHANCE
const ANY_EVENT_CHANCE := REAL_ENTRY_CHANCE + FAKE_ACCELERATED_CHANCE
const CONTINUE_CHANCE := 0.91
const INTERVAL_SECONDS := 10.0
const ACCELERATION_MULTIPLIER := 1.4

const STATE_NONE := "none"
const STATE_REAL_ACCELERATED := "real_accelerated"
const STATE_REAL_HIDDEN := "real_hidden"
const STATE_FAKE_ACCELERATED := "fake_accelerated"


static func entry_outcome(draw: float) -> String:
	var roll := clampf(draw, 0.0, 1.0)
	if roll < REAL_ACCELERATED_CHANCE:
		return STATE_REAL_ACCELERATED
	if roll < REAL_ENTRY_CHANCE:
		return STATE_REAL_HIDDEN
	if roll < ANY_EVENT_CHANCE:
		return STATE_FAKE_ACCELERATED
	return STATE_NONE


static func is_real(state: String) -> bool:
	return state in [STATE_REAL_ACCELERATED, STATE_REAL_HIDDEN]


static func is_accelerated(state: String) -> bool:
	return state in [STATE_REAL_ACCELERATED, STATE_FAKE_ACCELERATED]
