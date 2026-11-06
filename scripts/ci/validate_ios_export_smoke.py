#!/usr/bin/env python3
"""Regression checks for named iOS export validation and manifest placement."""

from __future__ import annotations

import plistlib
import tempfile
from pathlib import Path

from validate_ios_export import ExportExpectations, ValidationError, validate


BUNDLE_ID = "com.example.release"
TEAM_ID = "ABCDE12345"
APP_VERSION = "1.2.3"
BUILD_NUMBER = "62"
DISPLAY_NAME = "ぷくぷく 撮影"
PREVIOUS_GENERATED_DISPLAY_NAME = "ぷくぷく！たにくらいふ"
IOS_MIN_VERSION = "15.6"


def write_fixture(root: Path) -> ExportExpectations:
    project = root / "build" / "ios" / "ExportValidation.xcodeproj"
    app_dir = root / "build" / "ios" / "ExportValidation"
    info_plist = app_dir / "ExportValidation-Info.plist"
    project.mkdir(parents=True)
    (app_dir / "Images.xcassets" / "AppIcon.appiconset").mkdir(parents=True)
    (app_dir / "Images.xcassets" / "AppIcon.appiconset" / "Icon-1024.png").write_bytes(b"png")
    (project / "project.pbxproj").write_text(
        "\n".join(
            [
                f"PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};",
                f"DEVELOPMENT_TEAM = {TEAM_ID};",
                f"MARKETING_VERSION = {APP_VERSION};",
                f"CURRENT_PROJECT_VERSION = {BUILD_NUMBER};",
                f'INFOPLIST_KEY_CFBundleDisplayName = "{DISPLAY_NAME}";',
                f'INFOPLIST_KEY_CFBundleDisplayName = "{DISPLAY_NAME}";',
                "SharePlugin NotificationSchedulerPlugin godot-storekit2 StoreKit.framework",
                "AdmobPlugin GoogleMobileAds PrivacyInfo.xcprivacy",
                f"IPHONEOS_DEPLOYMENT_TARGET = {IOS_MIN_VERSION};",
            ]
        ),
        encoding="utf-8",
    )
    with info_plist.open("wb") as stream:
        plistlib.dump(
            {
                "CFBundleDisplayName": "$(INFOPLIST_KEY_CFBundleDisplayName)",
                "ITSAppUsesNonExemptEncryption": False,
                "GADApplicationIdentifier": "redacted",
                "NSAppTransportSecurity": {
                    "NSAllowsArbitraryLoadsForMedia": True,
                    "NSAllowsArbitraryLoadsInWebContent": True,
                },
            },
            stream,
        )
    privacy_path = project.parent / "PrivacyInfo.xcprivacy"
    with privacy_path.open("wb") as stream:
        plistlib.dump(
            {
                "NSPrivacyAccessedAPITypes": [
                    {
                        "NSPrivacyAccessedAPIType": category,
                        "NSPrivacyAccessedAPITypeReasons": [reason],
                    }
                    for category, reason in {
                        "NSPrivacyAccessedAPICategoryFileTimestamp": "C617.1",
                        "NSPrivacyAccessedAPICategorySystemBootTime": "35F9.1",
                        "NSPrivacyAccessedAPICategoryDiskSpace": "E174.1",
                        "NSPrivacyAccessedAPICategoryUserDefaults": "CA92.1",
                    }.items()
                ]
            },
            stream,
        )
    return ExportExpectations(
        xcode_project=project,
        app_dir=app_dir,
        info_plist=info_plist,
        bundle_id=BUNDLE_ID,
        team_id=TEAM_ID,
        app_version=APP_VERSION,
        build_number=BUILD_NUMBER,
        display_name=DISPLAY_NAME,
        ios_min_version=IOS_MIN_VERSION,
    )


def main() -> None:
    with tempfile.TemporaryDirectory() as temporary_directory:
        expectations = write_fixture(Path(temporary_directory))
        privacy_path = validate(expectations)
        assert privacy_path == expectations.xcode_project.parent / "PrivacyInfo.xcprivacy"

        pbxproj = expectations.xcode_project / "project.pbxproj"
        valid_project = pbxproj.read_text(encoding="utf-8")
        pbxproj.write_text(
            valid_project.replace(
                f'INFOPLIST_KEY_CFBundleDisplayName = "{DISPLAY_NAME}";',
                f'INFOPLIST_KEY_CFBundleDisplayName = "{PREVIOUS_GENERATED_DISPLAY_NAME}";',
            ),
            encoding="utf-8",
        )
        try:
            validate(expectations)
        except ValidationError as error:
            assert error.check == "xcode_project.display_name"
            assert repr(DISPLAY_NAME) in error.detail
            assert repr(PREVIOUS_GENERATED_DISPLAY_NAME) in error.detail
        else:
            raise AssertionError("validator accepted an unexpected generated display name")
        pbxproj.write_text(valid_project, encoding="utf-8")

        misplaced_path = expectations.app_dir / "PrivacyInfo.xcprivacy"
        misplaced_path.write_bytes(privacy_path.read_bytes())
        privacy_path.unlink()
        try:
            validate(expectations)
        except ValidationError as error:
            assert error.check == "privacy_manifest.file"
        else:
            raise AssertionError(
                "validator accepted a Privacy Manifest in the old incorrect directory"
            )

    print(
        "IOS_EXPORT_VALIDATOR_SMOKE_OK root_manifest=true "
        "display_name_mismatch=true named_failure=true"
    )


if __name__ == "__main__":
    main()
