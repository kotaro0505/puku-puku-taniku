class_name PukuBuildProfile
extends RefCounted

const APP_STORE_RELEASE_FEATURE := "puku_app_store_release"
const IAP_REVIEW_CAPTURE_FEATURE := "puku_iap_review_capture"
const IAP_REVIEW_CAPTURE_PRODUCT_COUNT := 36
const DEVELOPMENT_FEATURE := "puku_development"
const REWARDED_AD_STUB_FEATURE := "puku_rewarded_ad_stub"
const IOS_TEST_ADS_FEATURE := "puku_ios_test_ads"


static func is_app_store_release() -> bool:
	return OS.has_feature(APP_STORE_RELEASE_FEATURE)


static func iap_review_capture_enabled() -> bool:
	return is_app_store_release() and OS.has_feature("ios") and OS.has_feature(IAP_REVIEW_CAPTURE_FEATURE)


static func iap_review_capture_product_ids() -> Array[String]:
	var product_ids: Array[String] = []
	for product_number in range(1, IAP_REVIEW_CAPTURE_PRODUCT_COUNT + 1):
		product_ids.append("pot_unlock_%03d" % product_number)
	return product_ids


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
	if OS.has_feature(IAP_REVIEW_CAPTURE_FEATURE):
		if not is_app_store_release():
			errors.append("IAP review capture requires the App Store release feature")
		if not OS.has_feature("ios"):
			errors.append("IAP review capture is only supported on iOS")
	if is_app_store_release():
		for forbidden_feature in [DEVELOPMENT_FEATURE, REWARDED_AD_STUB_FEATURE, IOS_TEST_ADS_FEATURE]:
			if OS.has_feature(forbidden_feature):
				errors.append("App Store profile also contains forbidden feature: %s" % forbidden_feature)
	return errors


static func evaluate_feature_set(features: Dictionary, is_debug_build: bool = false, is_ios: bool = false) -> Dictionary:
	# Pure equivalent of the runtime rules for release-gate regression tests and
	# CI audits. Production always wins closed if conflicting tags are supplied.
	var app_store_release := bool(features.get(APP_STORE_RELEASE_FEATURE, false))
	var iap_review_capture := app_store_release and is_ios and bool(features.get(IAP_REVIEW_CAPTURE_FEATURE, false))
	var development := not app_store_release and (bool(features.get(DEVELOPMENT_FEATURE, false)) or is_debug_build)
	var rewarded_stub := development and not app_store_release and (
		bool(features.get(REWARDED_AD_STUB_FEATURE, false)) or (is_debug_build and not is_ios)
	)
	var ios_test_ads := development and not app_store_release and bool(features.get(IOS_TEST_ADS_FEATURE, false))
	var errors: Array[String] = []
	if bool(features.get(IAP_REVIEW_CAPTURE_FEATURE, false)):
		if not app_store_release:
			errors.append("IAP review capture requires the App Store release feature")
		if not is_ios:
			errors.append("IAP review capture is only supported on iOS")
	if app_store_release:
		for forbidden_feature in [DEVELOPMENT_FEATURE, REWARDED_AD_STUB_FEATURE, IOS_TEST_ADS_FEATURE]:
			if bool(features.get(forbidden_feature, false)):
				errors.append("App Store profile also contains forbidden feature: %s" % forbidden_feature)
	return {
		"app_store_release": app_store_release,
		"iap_review_capture": iap_review_capture,
		"development_tools": development,
		"rewarded_ad_stub": rewarded_stub,
		"ios_test_ads": ios_test_ads,
		"errors": errors,
	}
