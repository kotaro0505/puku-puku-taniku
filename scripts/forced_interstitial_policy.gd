class_name ForcedInterstitialPolicy
extends RefCounted

const SOURCE_FOREST_GACHA := "forest_gacha"
const SOURCE_FUSION_LAB := "fusion_lab"
const DISPLAY_INTERVAL := 5

var _success_counts: Dictionary = {
	SOURCE_FOREST_GACHA: 0,
	SOURCE_FUSION_LAB: 0,
}
var _transition_pending: Dictionary = {}
var _separation_required := false


func restore_counts(forest_gacha_count: int, fusion_count: int) -> void:
	_success_counts[SOURCE_FOREST_GACHA] = _normalize_count(forest_gacha_count)
	_success_counts[SOURCE_FUSION_LAB] = _normalize_count(fusion_count)
	# A pending presentation is deliberately session-only. Restoring a save must
	# never make an interstitial appear at launch or during a later story scene.
	_transition_pending.clear()
	_separation_required = false


func success_count(source: String) -> int:
	return int(_success_counts.get(source, 0))


func record_success(source: String, forced_ads_removed: bool = false) -> bool:
	if not _valid_source(source):
		return false
	var next_count := (success_count(source) + 1) % DISPLAY_INTERVAL
	_success_counts[source] = next_count
	var reached_interval := next_count == 0
	if not reached_interval:
		# One completed gacha/fusion action is a meaningful separation between two
		# full-screen ads, without introducing a time-based cooldown.
		_separation_required = false
	if reached_interval and not forced_ads_removed:
		_transition_pending[source] = true
	else:
		_transition_pending.erase(source)
	return reached_interval


func has_pending_transition(source: String) -> bool:
	return bool(_transition_pending.get(source, false))


func consume_transition_candidate(source: String, forced_ads_removed: bool = false) -> bool:
	if not has_pending_transition(source):
		return false
	# A due event is consumed exactly once. If the ad is not ready, the caller
	# skips it instead of remembering it for a surprising later presentation.
	_transition_pending.erase(source)
	if forced_ads_removed:
		return false
	if _separation_required:
		_separation_required = false
		return false
	return true


func mark_presented() -> void:
	_separation_required = true


func clear_session_pending() -> void:
	_transition_pending.clear()
	_separation_required = false


func _normalize_count(value: int) -> int:
	return posmod(maxi(0, value), DISPLAY_INTERVAL)


func _valid_source(source: String) -> bool:
	return source in [SOURCE_FOREST_GACHA, SOURCE_FUSION_LAB]
