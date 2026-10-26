#!/usr/bin/env python3
"""Apply the minimal UMP privacy-options bridge to Godot AdMob Plugin v7.0.

The script only accepts the exact upstream v7.0 source shape. Every replacement
is count-checked so an upstream change fails the build instead of producing an
unreviewed native plugin.
"""

from __future__ import annotations

import argparse
from pathlib import Path


EXPECTED_GODOT_VERSION = "4.7"
EXPECTED_GODOT_RELEASE_TYPE = "beta1"
EXPECTED_IOS_VERSION = "14.3"
EXPECTED_GMA_VERSION = '"version": "12.14.0"'
EXPECTED_GMA_RESOLVED_VERSION = '"version" : "12.14.0"'
EXPECTED_GMA_REVISION = '"revision" : "1239c23464503053c17d37ee5daa70de3455e9c8"'
EXPECTED_UMP_VERSION = '"version" : "3.1.0"'
EXPECTED_UMP_REVISION = '"revision" : "13b248eaa73b7826f0efb1bcf455e251d65ecb1b"'


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one patch anchor, found {count}")
    return source.replace(old, new, 1)


def patch_text(path: Path, replacements: list[tuple[str, str, str]]) -> None:
    source = path.read_text(encoding="utf-8")
    for old, new, label in replacements:
        source = replace_once(source, old, new, f"{path}: {label}")
    path.write_text(source, encoding="utf-8", newline="\n")


def require_text(path: Path, expected: str, label: str) -> None:
    source = path.read_text(encoding="utf-8")
    if expected not in source:
        raise SystemExit(f"{path}: missing {label}: {expected!r}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("--godot-version", required=True)
    parser.add_argument("--godot-release-type", required=True)
    parser.add_argument("--ios-min-version", required=True)
    args = parser.parse_args()

    root = args.source.resolve()
    header = root / "ios/src/admob_plugin.h"
    implementation = root / "ios/src/admob_plugin.mm"
    godot_config = root / "common/config/godot.properties"
    ios_config = root / "ios/config/ios.properties"
    spm_config = root / "ios/config/spm_dependencies.json"
    package_resolved = root / "ios/plugin.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    for path in [header, implementation, godot_config, ios_config, spm_config, package_resolved]:
        if not path.is_file():
            raise SystemExit(f"Missing upstream v7.0 source file: {path}")

    require_text(spm_config, EXPECTED_GMA_VERSION, "pinned Google Mobile Ads 12.14.0 dependency")
    require_text(package_resolved, EXPECTED_GMA_RESOLVED_VERSION, "resolved Google Mobile Ads 12.14.0 dependency")
    require_text(package_resolved, EXPECTED_GMA_REVISION, "resolved Google Mobile Ads 12.14.0 revision")
    require_text(package_resolved, EXPECTED_UMP_VERSION, "resolved UMP 3.1.0 dependency")
    require_text(package_resolved, EXPECTED_UMP_REVISION, "resolved UMP 3.1.0 revision")

    patch_text(
        godot_config,
        [
            (
                f"godotVersion={EXPECTED_GODOT_VERSION}\ngodotReleaseType={EXPECTED_GODOT_RELEASE_TYPE}",
                f"godotVersion={args.godot_version}\ngodotReleaseType={args.godot_release_type}",
                "Godot header version",
            )
        ],
    )
    patch_text(
        ios_config,
        [
            (
                f"platform_version={EXPECTED_IOS_VERSION}",
                f"platform_version={args.ios_min_version}",
                "iOS deployment target",
            )
        ],
    )

    patch_text(
        header,
        [
            (
                "extern const String CONSENT_INFO_UPDATE_FAILED_SIGNAL;\n"
                "extern const String TRACKING_AUTHORIZATION_GRANTED;",
                "extern const String CONSENT_INFO_UPDATE_FAILED_SIGNAL;\n"
                "extern const String PRIVACY_OPTIONS_FORM_DISMISSED_SIGNAL;\n"
                "extern const String TRACKING_AUTHORIZATION_GRANTED;",
                "privacy-options signal declaration",
            ),
            (
                "\tvoid update_consent_info(Dictionary consentRequestParameters);\n"
                "\tvoid reset_consent_info();\n\n"
                "\tvoid set_mediation_privacy_settings(Dictionary settings);",
                "\tvoid update_consent_info(Dictionary consentRequestParameters);\n"
                "\tvoid reset_consent_info();\n"
                "\tint get_privacy_options_requirement_status();\n"
                "\tbool can_request_ads();\n"
                "\tError present_privacy_options_form();\n\n"
                "\tvoid set_mediation_privacy_settings(Dictionary settings);",
                "privacy-options method declarations",
            ),
        ],
    )

    patch_text(
        implementation,
        [
            (
                'const String CONSENT_INFO_UPDATE_FAILED_SIGNAL = "consent_info_update_failed";\n'
                'const String TRACKING_AUTHORIZATION_GRANTED = "tracking_authorization_granted";',
                'const String CONSENT_INFO_UPDATE_FAILED_SIGNAL = "consent_info_update_failed";\n'
                'const String PRIVACY_OPTIONS_FORM_DISMISSED_SIGNAL = "privacy_options_form_dismissed";\n'
                'const String TRACKING_AUTHORIZATION_GRANTED = "tracking_authorization_granted";',
                "privacy-options signal name",
            ),
            (
                '\tClassDB::bind_method(D_METHOD("update_consent_info"), &AdmobPlugin::update_consent_info);\n'
                '\tClassDB::bind_method(D_METHOD("reset_consent_info"), &AdmobPlugin::reset_consent_info);',
                '\tClassDB::bind_method(D_METHOD("update_consent_info"), &AdmobPlugin::update_consent_info);\n'
                '\tClassDB::bind_method(D_METHOD("reset_consent_info"), &AdmobPlugin::reset_consent_info);\n'
                '\tClassDB::bind_method(D_METHOD("get_privacy_options_requirement_status"),\n'
                '\t\t\t&AdmobPlugin::get_privacy_options_requirement_status);\n'
                '\tClassDB::bind_method(D_METHOD("can_request_ads"), &AdmobPlugin::can_request_ads);\n'
                '\tClassDB::bind_method(D_METHOD("present_privacy_options_form"), '
                '&AdmobPlugin::present_privacy_options_form);',
                "privacy-options method bindings",
            ),
            (
                '\tADD_SIGNAL(MethodInfo(CONSENT_INFO_UPDATE_FAILED_SIGNAL, '
                'PropertyInfo(Variant::DICTIONARY, "form_error_data")));',
                '\tADD_SIGNAL(MethodInfo(CONSENT_INFO_UPDATE_FAILED_SIGNAL, '
                'PropertyInfo(Variant::DICTIONARY, "form_error_data")));\n'
                '\tADD_SIGNAL(MethodInfo(\n'
                '\t\t\tPRIVACY_OPTIONS_FORM_DISMISSED_SIGNAL, '
                'PropertyInfo(Variant::DICTIONARY, "form_error_data")));',
                "privacy-options signal binding",
            ),
            (
                'void AdmobPlugin::reset_consent_info() {\n'
                '\tos_log_debug(admob_log, "AdmobPlugin reset_consent_info");\n'
                '\t[consentManager reset];\n'
                '}\n\n'
                'void AdmobPlugin::set_mediation_privacy_settings(Dictionary settings) {',
                'void AdmobPlugin::reset_consent_info() {\n'
                '\tos_log_debug(admob_log, "AdmobPlugin reset_consent_info");\n'
                '\t[consentManager reset];\n'
                '}\n\n'
                'int AdmobPlugin::get_privacy_options_requirement_status() {\n'
                '\t__block UMPPrivacyOptionsRequirementStatus status = UMPPrivacyOptionsRequirementStatusUnknown;\n'
                '\tvoid (^readStatus)(void) = ^{\n'
                '\t\tstatus = UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus;\n'
                '\t};\n\n'
                '\tif ([NSThread isMainThread]) {\n'
                '\t\treadStatus();\n'
                '\t} else {\n'
                '\t\tdispatch_sync(dispatch_get_main_queue(), readStatus);\n'
                '\t}\n\n'
                '\treturn (int)status;\n'
                '}\n\n'
                'bool AdmobPlugin::can_request_ads() {\n'
                '\t__block BOOL canRequestAds = NO;\n'
                '\tvoid (^readStatus)(void) = ^{\n'
                '\t\tcanRequestAds = UMPConsentInformation.sharedInstance.canRequestAds;\n'
                '\t};\n\n'
                '\tif ([NSThread isMainThread]) {\n'
                '\t\treadStatus();\n'
                '\t} else {\n'
                '\t\tdispatch_sync(dispatch_get_main_queue(), readStatus);\n'
                '\t}\n\n'
                '\treturn canRequestAds;\n'
                '}\n\n'
                'Error AdmobPlugin::present_privacy_options_form() {\n'
                '\tos_log_debug(admob_log, "AdmobPlugin present_privacy_options_form");\n\n'
                '\tvoid (^presentForm)(void) = ^{\n'
                '\t\tUIViewController *rootVC = GDTAppDelegateService.viewController;\n'
                '\t\t[UMPConsentForm presentPrivacyOptionsFormFromViewController:rootVC\n'
                '\t\t\t\t\t\t\t\t\tcompletionHandler:^(NSError *_Nullable error) {\n'
                '\t\t\t\t\t\t\t\t\t\tDictionary formErrorDictionary;\n'
                '\t\t\t\t\t\t\t\t\t\tif (error) {\n'
                '\t\t\t\t\t\t\t\t\t\t\tos_log_error(admob_log,\n'
                '\t\t\t\t\t\t\t\t\t\t\t\t\t"AdmobPlugin present_privacy_options_form: Error presenting form. "\n'
                '\t\t\t\t\t\t\t\t\t\t\t\t\t"Error code: %ld",\n'
                '\t\t\t\t\t\t\t\t\t\t\t\t\t(long)error.code);\n'
                '\t\t\t\t\t\t\t\t\t\t\tformErrorDictionary = '
                '[GAPConverter nsFormErrorToGodotDictionary:error];\n'
                '\t\t\t\t\t\t\t\t\t\t}\n'
                '\t\t\t\t\t\t\t\t\t\tAdmobPlugin::get_singleton()->call_deferred(\n'
                '\t\t\t\t\t\t\t\t\t\t\t\t"emit_signal", '
                'PRIVACY_OPTIONS_FORM_DISMISSED_SIGNAL, formErrorDictionary);\n'
                '\t\t\t\t\t\t\t\t\t}];\n'
                '\t};\n\n'
                '\tif ([NSThread isMainThread]) {\n'
                '\t\tpresentForm();\n'
                '\t} else {\n'
                '\t\tdispatch_async(dispatch_get_main_queue(), presentForm);\n'
                '\t}\n\n'
                '\treturn OK;\n'
                '}\n\n'
                'void AdmobPlugin::set_mediation_privacy_settings(Dictionary settings) {',
                "privacy-options implementations",
            ),
        ],
    )

    implementation_source = implementation.read_text(encoding="utf-8")
    required_native_tokens = [
        'D_METHOD("get_privacy_options_requirement_status")',
        'D_METHOD("can_request_ads")',
        'D_METHOD("present_privacy_options_form")',
        '"privacy_options_form_dismissed"',
        "UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus",
        "UMPConsentInformation.sharedInstance.canRequestAds",
        "presentPrivacyOptionsFormFromViewController",
    ]
    for token in required_native_tokens:
        if implementation_source.count(token) != 1:
            raise SystemExit(
                f"{implementation}: expected one native bridge token {token!r}, "
                f"found {implementation_source.count(token)}"
            )
    if "dispatch_get_main_queue()" not in implementation_source:
        raise SystemExit(f"{implementation}: native bridge does not dispatch UMP access to the main queue")

    print(
        "ADMOB_UMP_NATIVE_PATCH_OK "
        f"godot={args.godot_version}-{args.godot_release_type} "
        f"ios={args.ios_min_version} gma=12.14.0 ump=3.1.0"
    )


if __name__ == "__main__":
    main()
