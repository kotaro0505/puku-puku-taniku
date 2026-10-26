#!/usr/bin/env python3
"""Validate a Godot-generated iOS Xcode project with named CI diagnostics."""

from __future__ import annotations

import argparse
import plistlib
import re
import sys
from dataclasses import dataclass
from pathlib import Path


class ValidationError(RuntimeError):
    def __init__(self, check: str, detail: str) -> None:
        super().__init__(detail)
        self.check = check
        self.detail = detail


@dataclass(frozen=True)
class ExportExpectations:
    xcode_project: Path
    app_dir: Path
    info_plist: Path
    bundle_id: str
    team_id: str
    app_version: str
    build_number: str
    display_name: str
    ios_min_version: str


def require(condition: bool, check: str, detail: str) -> None:
    if not condition:
        raise ValidationError(check, detail)
    print(f"IOS_EXPORT_CHECK_OK check={check}")


def require_contains(source: str, value: str, check: str, detail: str) -> None:
    require(value in source, check, detail)


def load_plist(path: Path, check: str) -> dict:
    require(path.is_file(), f"{check}.file", f"missing file: {path}")
    try:
        with path.open("rb") as stream:
            value = plistlib.load(stream)
    except (OSError, plistlib.InvalidFileException) as error:
        raise ValidationError(f"{check}.syntax", f"invalid plist: {path}: {error}") from error
    require(isinstance(value, dict), f"{check}.root", f"plist root is not a dictionary: {path}")
    return value


def validate(expectations: ExportExpectations) -> Path:
    project = expectations.xcode_project
    pbxproj = project / "project.pbxproj"
    require(project.is_dir(), "xcode_project.directory", f"missing directory: {project}")
    require(pbxproj.is_file(), "xcode_project.pbxproj", f"missing file: {pbxproj}")
    source = pbxproj.read_text(encoding="utf-8")

    metadata = {
        "bundle_id": f"PRODUCT_BUNDLE_IDENTIFIER = {expectations.bundle_id};",
        "team_id": f"DEVELOPMENT_TEAM = {expectations.team_id};",
        "marketing_version": f"MARKETING_VERSION = {expectations.app_version};",
        "build_number": f"CURRENT_PROJECT_VERSION = {expectations.build_number};",
        "display_name": f'INFOPLIST_KEY_CFBundleDisplayName = "{expectations.display_name}";',
    }
    for name, marker in metadata.items():
        require_contains(
            source,
            marker,
            f"xcode_project.{name}",
            f"generated project does not contain the expected {name}",
        )

    dependencies = {
        "share_plugin": "SharePlugin",
        "notification_plugin": "NotificationSchedulerPlugin",
        "storekit2_plugin": "godot-storekit2",
        "storekit_framework": "StoreKit.framework",
        "admob_plugin": "AdmobPlugin",
        "google_mobile_ads_package": "GoogleMobileAds",
    }
    for name, marker in dependencies.items():
        require_contains(
            source,
            marker,
            f"xcode_project.{name}",
            f"generated project is missing {marker}",
        )

    deployment_targets = sorted(
        set(re.findall(r"IPHONEOS_DEPLOYMENT_TARGET\s*=\s*([^;]+);", source))
    )
    require(
        deployment_targets == [expectations.ios_min_version],
        "xcode_project.deployment_target",
        "expected iOS deployment target "
        f"{expectations.ios_min_version}, found {', '.join(deployment_targets) or 'missing'}",
    )
    print(
        "GODOT_IOS_DEPLOYMENT_TARGET_OK "
        f"target={expectations.ios_min_version} project={pbxproj}"
    )

    icon = expectations.app_dir / "Images.xcassets" / "AppIcon.appiconset" / "Icon-1024.png"
    require(icon.is_file(), "app_icon.1024", f"missing file: {icon}")

    info_source = (
        expectations.info_plist.read_text(encoding="utf-8")
        if expectations.info_plist.is_file()
        else ""
    )
    info = load_plist(expectations.info_plist, "info_plist")
    require(
        info_source.count("<key>ITSAppUsesNonExemptEncryption</key>") == 1,
        "info_plist.export_compliance_key",
        "ITSAppUsesNonExemptEncryption must occur exactly once",
    )
    require(
        info_source.count("<key>GADApplicationIdentifier</key>") == 1,
        "info_plist.admob_app_id_key",
        "GADApplicationIdentifier must occur exactly once",
    )
    ats = info.get("NSAppTransportSecurity", {})
    require(
        isinstance(ats, dict) and not ats.get("NSAllowsArbitraryLoads", False),
        "info_plist.ats_global",
        "NSAllowsArbitraryLoads must be absent or false",
    )
    require(
        bool(ats.get("NSAllowsArbitraryLoadsForMedia"))
        and bool(ats.get("NSAllowsArbitraryLoadsInWebContent")),
        "info_plist.ats_scoped",
        "scoped media and web-content ATS exceptions are required for Google Mobile Ads",
    )
    require(
        "NSUserTrackingUsageDescription" not in info,
        "info_plist.att_prompt",
        "ATT is disabled but NSUserTrackingUsageDescription is present",
    )
    print("IOS_ATS_OK global=false media=true web_content=true att_prompt=false")

    # Godot 4.7.2 writes PrivacyInfo.xcprivacy beside the .xcodeproj, not in the
    # generated application source directory. The Xcode resources phase then
    # copies it into the final .app bundle.
    privacy_path = project.parent / "PrivacyInfo.xcprivacy"
    privacy = load_plist(privacy_path, "privacy_manifest")
    require_contains(
        source,
        "PrivacyInfo.xcprivacy",
        "xcode_project.privacy_manifest_reference",
        "generated project does not reference PrivacyInfo.xcprivacy",
    )
    declared_reasons = {
        item.get("NSPrivacyAccessedAPIType"): set(item.get("NSPrivacyAccessedAPITypeReasons", []))
        for item in privacy.get("NSPrivacyAccessedAPITypes", [])
        if isinstance(item, dict)
    }
    required_reasons = {
        "NSPrivacyAccessedAPICategoryFileTimestamp": "C617.1",
        "NSPrivacyAccessedAPICategorySystemBootTime": "35F9.1",
        "NSPrivacyAccessedAPICategoryDiskSpace": "E174.1",
        "NSPrivacyAccessedAPICategoryUserDefaults": "CA92.1",
    }
    for category, reason in required_reasons.items():
        require(
            reason in declared_reasons.get(category, set()),
            f"privacy_manifest.reason.{reason}",
            f"missing required-reason declaration {category}/{reason}",
        )

    return privacy_path


def parse_args() -> ExportExpectations:
    parser = argparse.ArgumentParser()
    parser.add_argument("--xcode-project", required=True, type=Path)
    parser.add_argument("--app-dir", required=True, type=Path)
    parser.add_argument("--info-plist", required=True, type=Path)
    parser.add_argument("--bundle-id", required=True)
    parser.add_argument("--team-id", required=True)
    parser.add_argument("--app-version", required=True)
    parser.add_argument("--build-number", required=True)
    parser.add_argument("--display-name", required=True)
    parser.add_argument("--ios-min-version", required=True)
    args = parser.parse_args()
    return ExportExpectations(
        xcode_project=args.xcode_project,
        app_dir=args.app_dir,
        info_plist=args.info_plist,
        bundle_id=args.bundle_id,
        team_id=args.team_id,
        app_version=args.app_version,
        build_number=args.build_number,
        display_name=args.display_name,
        ios_min_version=args.ios_min_version,
    )


def main() -> int:
    try:
        privacy_path = validate(parse_args())
    except ValidationError as error:
        print(
            f"IOS_EXPORT_VALIDATION_FAILED check={error.check} detail={error.detail}",
            file=sys.stderr,
        )
        return 1
    except (OSError, UnicodeError) as error:
        print(
            f"IOS_EXPORT_VALIDATION_FAILED check=unexpected_io detail={error}",
            file=sys.stderr,
        )
        return 1
    print(f"IOS_EXPORT_VALIDATION_OK privacy_manifest={privacy_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
