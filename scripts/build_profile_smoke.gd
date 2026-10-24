extends Node

const BuildProfileClass = preload("res://scripts/build_profile.gd")


func _ready() -> void:
	var production := BuildProfileClass.evaluate_feature_set({
		BuildProfileClass.APP_STORE_RELEASE_FEATURE: true,
	})
	assert(production.app_store_release)
	assert(not production.development_tools)
	assert(not production.rewarded_ad_stub)
	assert(not production.ios_test_ads)
	assert(production.errors.is_empty())

	var conflicting := BuildProfileClass.evaluate_feature_set({
		BuildProfileClass.APP_STORE_RELEASE_FEATURE: true,
		BuildProfileClass.DEVELOPMENT_FEATURE: true,
		BuildProfileClass.REWARDED_AD_STUB_FEATURE: true,
		BuildProfileClass.IOS_TEST_ADS_FEATURE: true,
	})
	assert(conflicting.app_store_release)
	assert(not conflicting.development_tools)
	assert(not conflicting.rewarded_ad_stub)
	assert(not conflicting.ios_test_ads)
	assert(conflicting.errors.size() == 3)

	var web_development := BuildProfileClass.evaluate_feature_set({
		BuildProfileClass.DEVELOPMENT_FEATURE: true,
		BuildProfileClass.REWARDED_AD_STUB_FEATURE: true,
	})
	assert(not web_development.app_store_release)
	assert(web_development.development_tools)
	assert(web_development.rewarded_ad_stub)
	assert(not web_development.ios_test_ads)

	var ios_development := BuildProfileClass.evaluate_feature_set({
		BuildProfileClass.DEVELOPMENT_FEATURE: true,
		BuildProfileClass.IOS_TEST_ADS_FEATURE: true,
	}, false, true)
	assert(ios_development.development_tools)
	assert(not ios_development.rewarded_ad_stub)
	assert(ios_development.ios_test_ads)

	var untagged_release := BuildProfileClass.evaluate_feature_set({})
	assert(not untagged_release.app_store_release)
	assert(not untagged_release.development_tools)
	assert(not untagged_release.rewarded_ad_stub)

	var editor_debug := BuildProfileClass.evaluate_feature_set({}, true, false)
	assert(editor_debug.development_tools)
	assert(editor_debug.rewarded_ad_stub)

	print("BUILD_PROFILE_SMOKE_OK production_closed=true conflict_closed=true web_dev=true ios_dev_test_ads=true untagged_release_closed=true")
	get_tree().quit()
