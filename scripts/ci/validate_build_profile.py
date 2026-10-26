#!/usr/bin/env python3
"""Fail CI when an iOS export profile can expose the wrong feature set."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


PRODUCTION_BUNDLE = "com.ohanayanouen.pukupukutaniku"
DEVELOPMENT_BUNDLE = "com.ohanayanouen.pukupukutaniku.dev"


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


def main() -> None:
    if len(sys.argv) != 2 or sys.argv[1] not in {"app_store", "development"}:
        fail("usage: validate_build_profile.py app_store|development")
    profile = sys.argv[1]
    presets = parse_presets(Path("export_presets.cfg").read_text(encoding="utf-8"))
    preset_name = "iOS" if profile == "app_store" else "iOS Development"
    if preset_name not in presets:
        fail(f"Missing export preset: {preset_name}")
    preset = presets[preset_name]
    block = preset["_block"]

    if profile == "app_store":
        expected_features = "puku_app_store_release"
        expected_bundle = PRODUCTION_BUNDLE
        forbidden = ["puku_development", "puku_rewarded_ad_stub", "puku_ios_test_ads"]
    else:
        expected_features = "puku_development,puku_ios_test_ads"
        expected_bundle = DEVELOPMENT_BUNDLE
        forbidden = ["puku_app_store_release", "puku_rewarded_ad_stub"]

    if preset.get("custom_features") != expected_features:
        fail(f"{preset_name} custom_features must be exactly {expected_features}")
    if preset.get("application/bundle_identifier") != expected_bundle:
        fail(f"{preset_name} has an unexpected bundle identifier")
    if any(feature in preset.get("custom_features", "").split(",") for feature in forbidden):
        fail(f"{preset_name} contains a forbidden feature")
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

    main_source = Path("scripts/main.gd").read_text(encoding="utf-8")
    if "BuildProfileClass.development_tools_enabled()" not in main_source:
        fail("main.gd is not using the centralized development feature gate")
    if "BuildProfileClass.rewarded_ad_stub_enabled()" not in main_source:
        fail("main.gd is not using the centralized rewarded-ad stub gate")
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
        "scripts/build_profile.gd",
        "scripts/rewarded_ad_service.gd",
        "scripts/story_dev_presets.gd",
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

    ad_service_source = Path("scripts/rewarded_ad_service.gd").read_text(encoding="utf-8")
    for required_setting in [
        "max_ad_content_rating = AdmobConfigClass.ContentRating.G",
        "child_directed = AdmobConfigClass.TagForChildDirectedTreatment.UNSPECIFIED",
        "under_age_of_consent = AdmobConfigClass.TagForUnderAgeOfConsent.UNSPECIFIED",
        "first_party_id_enabled = false",
        "personalization_state = AdmobConfigClass.PersonalizationState.DISABLED",
        "att_enabled = false",
    ]:
        if required_setting not in ad_service_source:
            fail(f"Rewarded-ad privacy setting is missing: {required_setting}")
    for required_privacy_gate in [
        "is_privacy_options_supported()",
        "get_privacy_options_requirement_status()",
        "can_request_ads()",
        "privacy_options_form_dismissed.connect",
    ]:
        if required_privacy_gate not in ad_service_source:
            fail(f"Rewarded-ad privacy-options gate is missing: {required_privacy_gate}")

    config_source = Path("scripts/ci/configure_mobile_ads.py").read_text(encoding="utf-8")
    if '"att_enabled=false"' not in config_source or "'att_text=\"\"'" not in config_source:
        fail("Generated mobile-ads configuration must keep ATT disabled and omit prompt text")

    tracked = set(
        subprocess.check_output(["git", "ls-files"], text=True, encoding="utf-8").splitlines()
    )
    for secret_path in ["addons/AdmobPlugin/ios_export.cfg", "data/mobile-ads.cfg"]:
        if secret_path in tracked:
            fail(f"Generated ad configuration must not be committed: {secret_path}")

    print(
        f"BUILD_PROFILE_VALIDATE_OK profile={profile} preset={preset_name} "
        f"bundle={expected_bundle} features={expected_features}"
    )


if __name__ == "__main__":
    main()
