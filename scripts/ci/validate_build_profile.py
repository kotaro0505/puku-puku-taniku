#!/usr/bin/env python3
"""Fail CI when an iOS export profile can expose the wrong feature set."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


PRODUCTION_BUNDLE = "com.ohanayanouen.pukupukutaniku"
DEVELOPMENT_BUNDLE = "com.ohanayanouen.pukupukutaniku.dev"
PRODUCTION_DISPLAY_NAME = "ぷくぷく！たにくらいふ"
IAP_REVIEW_CAPTURE_DISPLAY_NAME = "ぷくぷく 撮影"


def fail(message: str) -> None:
    raise SystemExit(message)


def parse_presets(text: str) -> dict[str, dict[str, str]]:
    headers = list(re.finditer(r"(?m)^\[preset\.(\d+)\]\s*$", text))
    result: dict[str, dict[str, str]] = {}
    for index, header in enumerate(headers):
        number = header.group(1)
        end = headers[index + 1].start() if index + 1 < len(headers) else len(text)
        block = text[header.start() : end]
        name_match = re.search(r'(?m)^name="([^"]+)"$', block)
        if not name_match:
            continue
        values = {
            key: value
            for key, value in re.findall(r'(?m)^([^\n=]+)="([^"]*)"$', block)
        }
        values["_number"] = number
        values["_block"] = block
        result[name_match.group(1)] = values
    return result


def read_project_string(source: str, key: str) -> str | None:
    match = re.search(rf'(?m)^{re.escape(key)}="([^"]*)"$', source)
    return match.group(1) if match else None


def main() -> None:
    profiles = {
        "app_store": {
            "preset": "iOS",
            "features": "puku_app_store_release",
            "bundle": PRODUCTION_BUNDLE,
            "display_name_setting": "config/name",
            "display_name": PRODUCTION_DISPLAY_NAME,
            "forbidden": [
                "puku_iap_review_capture",
                "puku_internal_test_story_jump",
                "puku_development",
                "puku_rewarded_ad_stub",
                "puku_ios_test_ads",
            ],
        },
        "internal_test": {
            "preset": "iOS Internal Test",
            "features": "puku_app_store_release,puku_internal_test_story_jump",
            "bundle": PRODUCTION_BUNDLE,
            "display_name_setting": "config/name",
            "display_name": PRODUCTION_DISPLAY_NAME,
            "forbidden": [
                "puku_iap_review_capture",
                "puku_development",
                "puku_rewarded_ad_stub",
                "puku_ios_test_ads",
            ],
        },
        "iap_review_capture": {
            "preset": "iOS IAP Review Capture",
            "features": "puku_app_store_release,puku_iap_review_capture",
            "bundle": PRODUCTION_BUNDLE,
            "display_name_setting": "config/name.puku_iap_review_capture",
            "display_name": IAP_REVIEW_CAPTURE_DISPLAY_NAME,
            "forbidden": [
                "puku_internal_test_story_jump",
                "puku_development",
                "puku_rewarded_ad_stub",
                "puku_ios_test_ads",
            ],
        },
        "development": {
            "preset": "iOS Development",
            "features": "puku_development,puku_ios_test_ads",
            "bundle": DEVELOPMENT_BUNDLE,
            "forbidden": [
                "puku_app_store_release",
                "puku_iap_review_capture",
                "puku_internal_test_story_jump",
                "puku_rewarded_ad_stub",
            ],
        },
    }
    if len(sys.argv) != 2 or sys.argv[1] not in profiles:
        fail("usage: validate_build_profile.py app_store|internal_test|iap_review_capture|development")
    profile = sys.argv[1]
    presets = parse_presets(Path("export_presets.cfg").read_text(encoding="utf-8"))
    profile_config = profiles[profile]
    preset_name = profile_config["preset"]
    if preset_name not in presets:
        fail(f"Missing export preset: {preset_name}")
    preset = presets[preset_name]
    block = preset["_block"]

    expected_features = profile_config["features"]
    expected_bundle = profile_config["bundle"]
    forbidden = profile_config["forbidden"]
    expected_display_name = profile_config.get("display_name")

    if preset.get("custom_features") != expected_features:
        fail(f"{preset_name} custom_features must be exactly {expected_features}")
    if preset.get("application/bundle_identifier") != expected_bundle:
        fail(f"{preset_name} has an unexpected bundle identifier")
    if any(feature in preset.get("custom_features", "").split(",") for feature in forbidden):
        fail(f"{preset_name} contains a forbidden feature")
    if profile == "iap_review_capture" and "application/name" in preset:
        fail(
            "iOS IAP Review Capture must not use the unsupported export option "
            "application/name; use the project feature override"
        )
    if expected_display_name is not None:
        project_source = Path("project.godot").read_text(encoding="utf-8")
        display_name_setting = profile_config["display_name_setting"]
        configured_display_name = read_project_string(project_source, display_name_setting)
        if configured_display_name != expected_display_name:
            fail(
                f"{preset_name} display name must resolve from project setting "
                f"{display_name_setting} as {expected_display_name!r}; "
                f"found {configured_display_name!r}"
            )
    required_lines = [
        "plugins/AdmobPlugin=true",
        "plugins/godot-storekit2=true",
        "privacy/file_timestamp_access_reasons=2",
        "privacy/system_boot_time_access_reasons=1",
        "privacy/disk_space_access_reasons=1",
        "privacy/user_defaults_access_reasons=4",
        "privacy/tracking_enabled=false",
    ]
    for line in required_lines:
        if line not in block:
            fail(f"{preset_name} is missing {line}")
    included_files = {entry.strip() for entry in preset.get("include_filter", "").split(",")}
    if "data/mobile-ads.cfg" not in included_files:
        fail(f"{preset_name} must include the generated runtime mobile-ads config")
    web_preset = presets.get("Web", {})
    web_included_files = {
        entry.strip() for entry in web_preset.get("include_filter", "").split(",")
    }
    if "data/mobile-ads.cfg" in web_included_files:
        fail("Web export must not package the iOS mobile-ads config")

    main_source = Path("scripts/main.gd").read_text(encoding="utf-8")
    if "BuildProfileClass.development_tools_enabled()" not in main_source:
        fail("main.gd is not using the centralized development feature gate")
    if "BuildProfileClass.rewarded_ad_stub_enabled()" not in main_source:
        fail("main.gd is not using the centralized rewarded-ad stub gate")
    for required_capture_gate in [
        "BuildProfileClass.iap_review_capture_enabled()",
        "IAP_REVIEW_CAPTURE_SCRIPT_PATH",
        "save_namespace_migration=disabled",
    ]:
        if required_capture_gate not in main_source:
            fail(f"main.gd is missing IAP review capture gate: {required_capture_gate}")
    for required_internal_ad_diagnostic_gate in [
        "BuildProfileClass.internal_test_story_jump_enabled()",
        'internal_forced_ad_diagnostic_button.name="InternalForcedAdDiagnosticButton"',
        'internal_forced_ad_diagnostic_overlay.name="InternalForcedAdDiagnosticOverlay"',
        "if not BuildProfileClass.internal_test_story_jump_enabled():return",
    ]:
        if required_internal_ad_diagnostic_gate not in main_source:
            fail(
                "main.gd is missing the internal-TestFlight forced-ad diagnostic gate: "
                f"{required_internal_ad_diagnostic_gate}"
            )
    release_gate_source = Path("scripts/release_gate_smoke.gd").read_text(encoding="utf-8")
    for required_release_absence_check in [
        "game.internal_forced_ad_diagnostic_button == null",
        "game.internal_forced_ad_diagnostic_overlay == null",
        'game.find_child("InternalForcedAdDiagnosticButton", true, false) == null',
        'game.find_child("InternalForcedAdDiagnosticOverlay", true, false) == null',
    ]:
        if required_release_absence_check not in release_gate_source:
            fail(
                "Release gate does not prove forced-ad diagnostics are absent: "
                f"{required_release_absence_check}"
            )
    for forbidden_literal in [
        "const TRIAL_DEV_CONTROLS_ENABLED := true",
        "const REWARDED_AD_DEVELOPMENT_STUB_ENABLED := true",
    ]:
        if forbidden_literal in main_source:
            fail(f"Forbidden fixed release flag remains: {forbidden_literal}")

    for required_path in [
        "addons/AdmobPlugin/plugin.cfg",
        "addons/AdmobPlugin/LICENSE.txt",
        "ios/plugins/AdmobPlugin.gdip",
        "ios/plugins/AdmobPlugin.release.xcframework/ios-arm64/AdmobPlugin.a",
        "scripts/ci/build_admob_plugin.sh",
        "scripts/ci/patch_admob_ump_native.py",
        "scripts/ci/validate_ios_export.py",
        "scripts/ci/validate_ios_export_smoke.py",
        "scripts/ci/configure_mobile_ads_smoke.py",
        "scripts/ci/configure_att_localizations.py",
        "scripts/ci/configure_att_localizations_smoke.py",
        "scripts/ci/verify_mobile_ads_export.sh",
        "scripts/ci/verify_mobile_ads_pack.gd",
        "scripts/build_profile.gd",
        "scripts/iap_review_capture.gd",
        "scripts/rewarded_ad_service.gd",
        "scripts/interstitial_ad_service.gd",
        "scripts/forced_interstitial_policy.gd",
        "scripts/story_dev_presets.gd",
        "tools/.gdignore",
    ]:
        if not Path(required_path).exists():
            fail(f"Missing release dependency: {required_path}")

    admob_export_source = Path("addons/AdmobPlugin/AdmobPlugin.gd").read_text(encoding="utf-8")
    if "NSAllowsArbitraryLoadsForMedia" not in admob_export_source:
        fail("AdMob export is missing the scoped ATS media exception")
    if "NSAllowsArbitraryLoadsInWebContent" not in admob_export_source:
        fail("AdMob export is missing the scoped ATS web-content exception")
    if "<key>NSAllowsArbitraryLoads</key>" in admob_export_source:
        fail("AdMob export must not disable ATS globally")

    admob_build_source = Path("scripts/ci/build_admob_plugin.sh").read_text(encoding="utf-8")
    admob_patch_source = Path("scripts/ci/patch_admob_ump_native.py").read_text(encoding="utf-8")
    for required_pin in [
        "4b4ddceab0be81f0dcb12a6313038dba6cf9eacf",
        'GOOGLE_MOBILE_ADS_VERSION="${GOOGLE_MOBILE_ADS_VERSION:-12.14.0}"',
        'ADMOB_NATIVE_COMPAT_REVISION="${ADMOB_NATIVE_COMPAT_REVISION:-ump2-att2}"',
        "ADMOB_UMP_NATIVE_BUILT",
    ]:
        if required_pin not in admob_build_source:
            fail(f"AdMob native build pin is missing: {required_pin}")
    for required_build_step in [
        '(cd "$PLUGIN_SOURCE" && ./script/run_gradle_task.sh copyiOSBuildArtifacts)',
        'BUILT_FRAMEWORKS="$PLUGIN_SOURCE/ios/build/framework"',
        'BUILT_PLUGIN="$PLUGIN_SOURCE/common/build/plugin/ios/ios/plugins"',
        'validate_plugin_artifacts "$BUILT_FRAMEWORKS"',
        '["xcrun", "lipo", "-archs", str(library_path)]',
        "ADMOB_BUILD_LAYOUT_OK",
    ]:
        if required_build_step not in admob_build_source:
            fail(f"AdMob iOS artifact assembly check is missing: {required_build_step}")
    if 'BUILT_PLUGIN="$PLUGIN_SOURCE/common/build/plugin/ios/plugins"' in admob_build_source:
        fail("AdMob build still uses the pre-v7 distribution path without the nested ios directory")
    for required_native_api in [
        "UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus",
        "UMPConsentInformation.sharedInstance.canRequestAds",
        "presentPrivacyOptionsFormFromViewController",
        'D_METHOD("get_privacy_options_requirement_status")',
        'D_METHOD("can_request_ads")',
        'D_METHOD("present_privacy_options_form")',
        'D_METHOD("get_tracking_authorization_status")',
        "ATTrackingManager.trackingAuthorizationStatus",
        "allow UMP form loading before GMA initialization",
        "UMP form loading still depends on GMA initialization",
    ]:
        if required_native_api not in admob_patch_source:
            fail(f"AdMob native UMP bridge is missing: {required_native_api}")

    committed_admob_binary = Path(
        "ios/plugins/AdmobPlugin.release.xcframework/ios-arm64/AdmobPlugin.a"
    ).read_bytes()
    bridge_tokens = [
        b"privacy_options_form_dismissed",
        b"get_privacy_options_requirement_status",
        b"present_privacy_options_form",
        b"can_request_ads",
        b"get_tracking_authorization_status",
    ]
    bridge_token_count = sum(token in committed_admob_binary for token in bridge_tokens)
    if bridge_token_count not in {0, len(bridge_tokens)}:
        fail("Committed AdMob binary contains a partial UMP native bridge")

    ad_service_source = Path("scripts/rewarded_ad_service.gd").read_text(encoding="utf-8")
    for required_setting in [
        "max_ad_content_rating = AdmobConfigClass.ContentRating.G",
        "child_directed = AdmobConfigClass.TagForChildDirectedTreatment.UNSPECIFIED",
        "under_age_of_consent = AdmobConfigClass.TagForUnderAgeOfConsent.UNSPECIFIED",
        "first_party_id_enabled = false",
        "personalization_state = AdmobConfigClass.PersonalizationState.DISABLED",
        "att_enabled = _att_required",
        "remove_interstitial_ads_after_displayed = true",
        "ios_real_interstitial_id = interstitial_id",
        "ios_debug_interstitial_id = interstitial_id",
    ]:
        if required_setting not in ad_service_source:
            fail(f"Rewarded-ad privacy setting is missing: {required_setting}")
    for required_privacy_gate in [
        "is_privacy_options_supported()",
        "get_privacy_options_requirement_status()",
        "can_request_ads()",
        "privacy_options_form_dismissed.connect",
        "tracking_authorization_granted.connect",
        "tracking_authorization_denied.connect",
        "_initialize_ads_after_att()",
        "and not BuildProfileClass.iap_review_capture_enabled()",
        '"AUTHORIZED", "DENIED", "RESTRICTED"',
        "att_callback_status_mismatch",
        "CONSENT_OPERATION_TIMEOUT_SECONDS",
        "ATT_AUTHORIZATION_TIMEOUT_SECONDS",
        "consent_form_load_request_failed",
        "consent_update_timeout",
        "att_authorization_timeout",
    ]:
        if required_privacy_gate not in ad_service_source:
            fail(f"Rewarded-ad privacy-options gate is missing: {required_privacy_gate}")
    if ad_service_source.count("_admob.initialize()") != 1:
        fail("Google Mobile Ads initialization must have exactly one ATT-guarded call site")

    admob_wrapper_source = Path("addons/AdmobPlugin/Admob.gd").read_text(encoding="utf-8")
    for required_wrapper_contract in [
        "func load_consent_form() -> bool:",
        "func show_consent_form() -> bool:",
        "func update_consent_info(a_parameters: ConsentRequestParameters = null) -> bool:",
    ]:
        if required_wrapper_contract not in admob_wrapper_source:
            fail(f"AdMob UMP wrapper result contract is missing: {required_wrapper_contract}")

    config_source = Path("scripts/ci/configure_mobile_ads.py").read_text(encoding="utf-8")
    for required_att_configuration in [
        'os.environ.get("IOS_ATT_ENABLED", "")',
        'att_setting not in {"true", "false"}',
        "ATT_USAGE_DESCRIPTION",
        "ATT_USAGE_DESCRIPTION_EN",
        "ADMOB_IOS_INTERSTITIAL_AD_UNIT_ID",
        "SAMPLE_IOS_INTERSTITIAL_ID",
    ]:
        if required_att_configuration not in config_source:
            fail(f"Generated mobile-ads ATT configuration is missing: {required_att_configuration}")
    if "f'mode=\"{mode}\"'" not in config_source:
        fail("Generated runtime mobile-ads configuration must identify test or production mode")

    att_localization_source = Path("scripts/ci/configure_att_localizations.py").read_text(
        encoding="utf-8"
    )
    for required_att_localization in [
        "ATT_USAGE_DESCRIPTION_JA",
        "ATT_USAGE_DESCRIPTION_EN",
        "許可しなくても広告を利用でき、報酬は変わりません",
        "You can still use rewarded ads without allowing tracking",
        "rewards will not change",
        "ja.lproj/InfoPlist.strings",
        "verify_bundle_localizations",
    ]:
        if required_att_localization not in att_localization_source:
            fail(f"Localized ATT configuration is missing: {required_att_localization}")
    if 'const MOBILE_ADS_CONFIG_PATH := "res://data/mobile-ads.cfg"' not in ad_service_source:
        fail("Rewarded-ad runtime config path does not match the exported path")
    for required_config_diagnostic in [
        "mobile_ads_config_file_missing",
        "mobile_ads_config_load_failed",
        'return "CONFIG-MISSING"',
        'return "CONFIG-PARSE"',
        'return "CONFIG-MODE"',
        'return "CONFIG-ID"',
        'return "CONFIG-PROFILE"',
    ]:
        if required_config_diagnostic not in ad_service_source:
            fail(f"Rewarded-ad configuration diagnostic is missing: {required_config_diagnostic}")

    pack_validator_source = Path("scripts/ci/verify_mobile_ads_pack.gd").read_text(
        encoding="utf-8"
    )
    export_validator_source = Path("scripts/ci/verify_mobile_ads_export.sh").read_text(
        encoding="utf-8"
    )
    for required_pack_check in [
        'const CONFIG_PATH := "res://data/mobile-ads.cfg"',
        "ProjectSettings.load_resource_pack(pack_path, true)",
        'expected_mode not in ["test", "production"]',
        "MOBILE_ADS_PACK_OK",
        "interstitial_ad_unit_id",
    ]:
        if required_pack_check not in pack_validator_source:
            fail(f"Exported mobile-ads pack validation is missing: {required_pack_check}")
    for required_export_check in [
        'exported_pack="$3"',
        '--main-pack "$exported_pack"',
        'cd "$validation_workdir"',
        "pack_selection=explicit",
        "[REDACTED_ADMOB_ID]",
        "MOBILE_ADS_EXPORT_OK",
    ]:
        if required_export_check not in export_validator_source:
            fail(f"Mobile-ads distribution validation is missing: {required_export_check}")
    if 'mv "$runtime_config"' in export_validator_source:
        fail("Mobile-ads distribution validation must not move the source config")

    tracked = set(
        subprocess.check_output(["git", "ls-files"], text=True, encoding="utf-8").splitlines()
    )
    for secret_path in ["addons/AdmobPlugin/ios_export.cfg", "data/mobile-ads.cfg"]:
        if secret_path in tracked:
            fail(f"Generated ad configuration must not be committed: {secret_path}")

    ios_export_validator_source = Path("scripts/ci/validate_ios_export.py").read_text(
        encoding="utf-8"
    )
    for required_validation in [
        'privacy_path = project.parent / "PrivacyInfo.xcprivacy"',
        "IOS_EXPORT_VALIDATION_FAILED check=",
        '"google_mobile_ads_package": "GoogleMobileAds"',
        '"info_plist.admob_app_id_key"',
        '"info_plist.display_name_reference"',
        '"info_plist.att_prompt.fallback_en"',
        'f"info_plist.att_prompt.{locale}"',
        "GODOT_IOS_DISPLAY_NAME_OK",
    ]:
        if required_validation not in ios_export_validator_source:
            fail(f"Named iOS export validation is missing: {required_validation}")

    codemagic_source = Path("codemagic.yaml").read_text(encoding="utf-8")
    for required_diagnostic in [
        "python3 scripts/ci/validate_ios_export_smoke.py",
        "python3 scripts/ci/configure_mobile_ads_smoke.py",
        "python3 scripts/ci/configure_att_localizations_smoke.py",
        "python3 scripts/ci/configure_att_localizations.py configure",
        "python3 scripts/ci/configure_att_localizations.py verify",
        "bash scripts/ci/resolve_ipa_path_smoke.sh",
        "GODOT_IOS_EXPORT_COMMAND_FAILED",
        "python3 scripts/ci/validate_ios_export.py",
        'PRIVACY_MANIFEST="$(dirname "$CM_BUILD_DIR/$XCODE_PROJECT")/PrivacyInfo.xcprivacy"',
        "IOS_EXPORT_CHECK_OK check=privacy_manifest.plutil",
        "bash scripts/ci/verify_mobile_ads_export.sh",
        'EXPORTED_PCK="$CM_BUILD_DIR/${XCODE_PROJECT%.xcodeproj}.pck"',
        'SIGNED_PCK="$APP_PATH/$XCODE_SCHEME.pck"',
        '--ipa-directory "$CM_BUILD_DIR/$IPA_DIR"',
        'IPA_PATH="$(bash scripts/ci/resolve_ipa_path.sh "$CM_BUILD_DIR/$IPA_DIR")"',
        "[REDACTED_ADMOB_ID]",
        '--att-enabled "$IOS_ATT_ENABLED"',
    ]:
        if required_diagnostic not in codemagic_source:
            fail(f"Codemagic iOS export diagnostic is missing: {required_diagnostic}")
    if "$IOS_APP_DIR/PrivacyInfo.xcprivacy" in codemagic_source:
        fail("Codemagic still checks PrivacyInfo.xcprivacy in the generated app source directory")
    if codemagic_source.count("bash scripts/ci/verify_mobile_ads_export.sh") < 2:
        fail("Codemagic must verify mobile-ads config in both the Xcode export and signed IPA")

    testflight_block = codemagic_source.split("  ios-testflight:", 1)[1].split(
        "  ios-app-store-release:", 1
    )[0]
    release_block = codemagic_source.split("  ios-app-store-release:", 1)[1].split(
        "  ios-iap-review-capture:", 1
    )[0]
    capture_block = codemagic_source.split("  ios-iap-review-capture:", 1)[1].split(
        "  ios-development:", 1
    )[0]
    development_block = codemagic_source.split("  ios-development:", 1)[1]
    if 'MOBILE_ADS_MODE: "test"' not in testflight_block:
        fail("Internal TestFlight must use Google test ads before the iOS app is store-listed")
    if "admob_production" in testflight_block:
        fail("Internal TestFlight must not load production AdMob secrets")
    if 'INTERNAL_TESTFLIGHT_ONLY: "true"' not in testflight_block:
        fail("Test-ad TestFlight workflow must remain internal-testing-only")
    if 'IOS_ATT_ENABLED: "true"' not in testflight_block:
        fail("Internal TestFlight must enable ATT")
    for required_internal_setting in [
        'BUILD_PROFILE: "internal_test"',
        'GODOT_IOS_PRESET: "iOS Internal Test"',
    ]:
        if required_internal_setting not in testflight_block:
            fail(f"Internal TestFlight story-jump separation is missing: {required_internal_setting}")
    if 'MOBILE_ADS_MODE: "production"' not in release_block or "admob_production" not in release_block:
        fail("App Store release must load production AdMob secrets")
    if 'APP_STORE_SUBMISSION: "true"' not in release_block:
        fail("App Store release workflow lost its App Store-eligible signing gate")
    if 'IOS_ATT_ENABLED: "true"' not in release_block:
        fail("App Store release must enable ATT")
    for required_release_upload_setting in [
        "publishing:",
        "app_store_connect:",
        "auth: integration",
        "submit_to_testflight: false",
        "submit_to_app_store: false",
    ]:
        if required_release_upload_setting not in release_block:
            fail(
                "App Store release upload-only workflow is missing: "
                f"{required_release_upload_setting}"
            )
    for forbidden_release_submission_setting in [
        "submit_to_testflight: true",
        "submit_to_app_store: true",
        "beta_groups:",
        "release_type:",
        "cancel_previous_submissions:",
        "earliest_release_date:",
    ]:
        if forbidden_release_submission_setting in release_block:
            fail(
                "App Store release upload-only workflow contains an automatic "
                "submission or distribution setting: "
                f"{forbidden_release_submission_setting}"
            )
    for required_capture_setting in [
        'BUILD_PROFILE: "iap_review_capture"',
        'GODOT_IOS_PRESET: "iOS IAP Review Capture"',
        f'DISPLAY_NAME: "{IAP_REVIEW_CAPTURE_DISPLAY_NAME}"',
        'BUNDLE_ID: "com.ohanayanouen.pukupukutaniku"',
        'MOBILE_ADS_MODE: "test"',
        'IOS_ATT_ENABLED: "false"',
        'IPA_DIR: "build/ios-iap-capture/ipa"',
        '- build/ios-iap-capture/ipa/*.ipa',
        'INTERNAL_TESTFLIGHT_ONLY: "true"',
        'APP_STORE_SUBMISSION: "false"',
        'app_store_connect:',
        'auth: integration',
        'submit_to_testflight: false',
        'submit_to_app_store: false',
    ]:
        if required_capture_setting not in capture_block:
            fail(f"IAP review capture workflow is missing: {required_capture_setting}")
    for forbidden_capture_setting in [
        "publishing: {}",
        "submit_to_testflight: true",
        "submit_to_app_store: true",
        "beta_groups:",
        "release_type:",
    ]:
        if forbidden_capture_setting in capture_block:
            fail(
                "IAP review capture workflow contains a forbidden publishing setting: "
                f"{forbidden_capture_setting}"
            )
    for required_capture_build_number_guard in [
        'if [ "$BUILD_PROFILE" = "iap_review_capture" ]; then',
        "app-store-connect apps list",
        '--bundle-id-identifier "$BUNDLE_ID"',
        "--strict-match-identifier",
        "app-store-connect get-latest-build-number",
        '--version-string "$APP_VERSION"',
        'IOS_BUILD_NUMBER="$((10#$LATEST_APPLE_BUILD_NUMBER + 1))"',
    ]:
        if required_capture_build_number_guard not in codemagic_source:
            fail(
                "IAP review capture workflow is missing its Apple build-number guard: "
                f"{required_capture_build_number_guard}"
            )
    if 'IPA_DIR: "build/ios/ipa"' in capture_block:
        fail("IAP review capture workflow must keep its IPA outside the normal iOS output directory")
    if 'MOBILE_ADS_MODE: "test"' not in development_block or "admob_production" in development_block:
        fail("iPhone development workflow must use Google test ads without production secrets")
    if 'IOS_ATT_ENABLED: "false"' not in development_block:
        fail("iPhone development workflow must not enable ATT")
    for required_ads_gate in [
        'test "$MOBILE_ADS_MODE" = "production"',
        'test "$MOBILE_ADS_MODE" = "test"',
        'Signed test-ad IPA does not contain Google\'s sample app ID',
        'Signed production-ad IPA contains Google\'s sample app ID',
    ]:
        if required_ads_gate not in codemagic_source:
            fail(f"Codemagic mobile-ads separation gate is missing: {required_ads_gate}")

    print(
        f"BUILD_PROFILE_VALIDATE_OK profile={profile} preset={preset_name} "
        f"bundle={expected_bundle} features={expected_features}"
        + (f" display_name={expected_display_name!r}" if expected_display_name else "")
    )


if __name__ == "__main__":
    main()
