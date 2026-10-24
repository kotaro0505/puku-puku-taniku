class_name PukuBuildProfile
extends RefCounted

const APP_STORE_RELEASE_FEATURE := "puku_app_store_release"
const DEVELOPMENT_FEATURE := "puku_development"
const REWARDED_AD_STUB_FEATURE := "puku_rewarded_ad_stub"
const IOS_TEST_ADS_FEATURE := "puku_ios_test_ads"


static func is_app_store_release() -> bool:
	return OS.has_feature(APP_STORE_RELEASE_FEATURE)


static func development_tools_enabled() -> bool:
	if is_app_store_release():
		return false
	return OS.has_feature(DEVELOPMENT_FEATURE) or OS.is_debug_build()


static func rewarded_ad_stub_enabled() -> bool:
	if is_app_store_release() or not development_tools_enabled():
		return false
	# Desktop/editor smoke tests keep the fast deterministic stub. iOS
	# development builds deliberately use Google's test ad units instead.
	return OS.has_feature(REWARDED_AD_STUB_FEATURE) or (OS.is_debug_build() and not OS.has_feature("ios"))


static func ios_test_ads_enabled() -> bool:
	return not is_app_store_release() and development_tools_enabled() and OS.has_feature(IOS_TEST_ADS_FEATURE)


static func runtime_profile_errors() -> Array[String]:
	var errors: Array[String] = []
	if is_app_store_release():
		for forbidden_feature in [DEVELOPMENT_FEATURE, REWARDED_AD_STUB_FEATURE, IOS_TEST_ADS_FEATURE]:
			if OS.has_feature(forbidden_feature):
				errors.append("App Store profile also contains forbidden feature: %s" % forbidden_feature)
	return errors


static func evaluate_feature_set(features: Dictionary, is_debug_build: bool = false, is_ios: bool = false) -> Dictionary:
	# Pure equivalent of the runtime rules for release-gate regression tests and
	# CI audits. Production always wins closed if conflicting tags are supplied.
	var app_store_release := bool(features.get(APP_STORE_RELEASE_FEATURE, false))
	var development := not app_store_release and (bool(features.get(DEVELOPMENT_FEATURE, false)) or is_debug_build)
	var rewarded_stub := development and not app_store_release and (
		bool(features.get(REWARDED_AD_STUB_FEATURE, false)) or (is_debug_build and not is_ios)
	)
	var ios_test_ads := development and not app_store_release and bool(features.get(IOS_TEST_ADS_FEATURE, false))
	var errors: Array[String] = []
	if app_store_release:
		for forbidden_feature in [DEVELOPMENT_FEATURE, REWARDED_AD_STUB_FEATURE, IOS_TEST_ADS_FEATURE]:
			if bool(features.get(forbidden_feature, false)):
				errors.append("App Store profile also contains forbidden feature: %s" % forbidden_feature)
	return {
		"app_store_release": app_store_release,
		"development_tools": development,
		"rewarded_ad_stub": rewarded_stub,
		"ios_test_ads": ios_test_ads,
		"errors": errors,
	}
