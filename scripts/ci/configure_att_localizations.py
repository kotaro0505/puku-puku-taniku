#!/usr/bin/env python3
"""Configure and verify locale-specific ATT purpose strings for iOS exports."""

from __future__ import annotations

import argparse
import plistlib
import re
from pathlib import Path


ATT_KEY = "NSUserTrackingUsageDescription"
ATT_USAGE_DESCRIPTION_JA = (
    "リワード広告の表示回数調整と効果測定のため、端末の広告識別子の利用許可を求めます。"
    "許可しなくても広告を利用でき、報酬は変わりません。"
)
ATT_USAGE_DESCRIPTION_EN = (
    "We request permission to use the device advertising identifier for rewarded-ad "
    "frequency control and measurement. You can still use rewarded ads without allowing tracking, "
    "and rewards will not change."
)
JA_FILE_REFERENCE_ID = "A77A77000000000000000001"


def fail(message: str) -> None:
    raise SystemExit(message)


def _escape_strings_value(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def _unescape_strings_value(value: str) -> str:
    result: list[str] = []
    index = 0
    while index < len(value):
        character = value[index]
        if character != "\\" or index + 1 >= len(value):
            result.append(character)
            index += 1
            continue
        escaped = value[index + 1]
        result.append({"n": "\n", "r": "\r", "t": "\t"}.get(escaped, escaped))
        index += 2
    return "".join(result)


def read_info_plist_string(path: Path, key: str = ATT_KEY) -> str | None:
    if not path.is_file():
        return None
    data = path.read_bytes()
    try:
        plist = plistlib.loads(data)
    except (plistlib.InvalidFileException, ValueError, TypeError):
        plist = None
    if isinstance(plist, dict) and key in plist:
        return str(plist[key])

    try:
        source = data.decode("utf-8-sig")
    except UnicodeDecodeError as error:
        fail(f"ATT localization is neither a plist nor UTF-8 text: {path}: {error}")
    pattern = re.compile(
        rf'(?m)^\s*"?{re.escape(key)}"?\s*=\s*"((?:\\.|[^"\\])*)"\s*;\s*$'
    )
    matches = pattern.findall(source)
    if len(matches) > 1:
        fail(f"ATT localization contains duplicate {key} entries: {path}")
    return _unescape_strings_value(matches[0]) if matches else None


def _upsert_info_plist_string(path: Path, value: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    source = (
        path.read_text(encoding="utf-8-sig")
        if path.is_file()
        else "/* Localized versions of Info.plist keys */\n"
    )
    pattern = re.compile(
        rf'(?m)^\s*"?{re.escape(ATT_KEY)}"?\s*=\s*"(?:\\.|[^"\\])*"\s*;\s*\n?'
    )
    source, count = pattern.subn("", source)
    if count > 1:
        fail(f"ATT localization contains duplicate {ATT_KEY} entries: {path}")
    if source and not source.endswith("\n"):
        source += "\n"
    source += f'{ATT_KEY} = "{_escape_strings_value(value)}";\n'
    path.write_text(source, encoding="utf-8", newline="\n")


def _line_indices(lines: list[str], marker: str) -> list[int]:
    return [index for index, line in enumerate(lines) if marker in line]


def _patch_xcode_project(pbxproj: Path) -> None:
    if not pbxproj.is_file():
        fail(f"Missing Xcode project file: {pbxproj}")
    lines = pbxproj.read_text(encoding="utf-8").splitlines(keepends=True)

    en_reference_indices = _line_indices(lines, "path = en.lproj/InfoPlist.strings;")
    if len(en_reference_indices) != 1:
        fail(
            "Expected exactly one English InfoPlist.strings file reference, "
            f"found {len(en_reference_indices)}"
        )
    en_line = lines[en_reference_indices[0]]
    en_id_match = re.match(r"\s*([A-F0-9]{24})\s+/\*", en_line)
    if en_id_match is None:
        fail("Unable to identify the English InfoPlist.strings Xcode reference")
    en_id = en_id_match.group(1)

    ja_reference_indices = _line_indices(lines, "path = ja.lproj/InfoPlist.strings;")
    if len(ja_reference_indices) > 1:
        fail("Xcode project contains duplicate Japanese InfoPlist.strings references")
    if ja_reference_indices:
        ja_line = lines[ja_reference_indices[0]]
        ja_id_match = re.match(r"\s*([A-F0-9]{24})\s+/\*", ja_line)
        if ja_id_match is None:
            fail("Unable to identify the Japanese InfoPlist.strings Xcode reference")
        ja_id = ja_id_match.group(1)
    else:
        if any(JA_FILE_REFERENCE_ID in line for line in lines):
            fail("Reserved ATT localization Xcode reference ID is already in use")
        ja_id = JA_FILE_REFERENCE_ID
        indent = en_line[: len(en_line) - len(en_line.lstrip())]
        lines.insert(
            en_reference_indices[0] + 1,
            f"{indent}{ja_id} /* ja */ = {{isa = PBXFileReference; "
            "lastKnownFileType = text.plist.strings; name = ja; "
            'path = ja.lproj/InfoPlist.strings; sourceTree = "<group>"; };\n',
        )

    source = "".join(lines)
    variant_start = source.find("/* Begin PBXVariantGroup section */")
    variant_end = source.find("/* End PBXVariantGroup section */")
    if variant_start < 0 or variant_end <= variant_start:
        fail("Xcode project is missing its PBXVariantGroup section")
    variant = source[variant_start:variant_end]
    if "name = InfoPlist.strings;" not in variant:
        fail("Xcode project is missing the InfoPlist.strings variant group")
    if ja_id not in variant:
        en_child = re.compile(
            rf'(?m)^(\s*){re.escape(en_id)}\s+/\*\s*en\s*\*/,\s*$'
        )
        variant, count = en_child.subn(
            rf"\g<1>{en_id} /* en */,\n\g<1>{ja_id} /* ja */,",
            variant,
            count=1,
        )
        if count != 1:
            fail("Unable to add Japanese localization to the InfoPlist.strings variant group")
        source = source[:variant_start] + variant + source[variant_end:]

    known_regions = re.search(r"(?ms)(\s*knownRegions\s*=\s*\()(.*?)(\n\s*\);)", source)
    if known_regions is None:
        fail("Xcode project is missing knownRegions")
    region_body = known_regions.group(2)
    if re.search(r"(?m)^\s*ja,\s*$", region_body) is None:
        en_region = re.compile(r"(?m)^(\s*)en,\s*$")
        region_body, count = en_region.subn(r"\g<0>\n\g<1>ja,", region_body, count=1)
        if count != 1:
            fail("Unable to add Japanese to Xcode knownRegions")
        source = (
            source[: known_regions.start(2)]
            + region_body
            + source[known_regions.end(2) :]
        )

    if source.count("path = ja.lproj/InfoPlist.strings;") != 1:
        fail("Japanese InfoPlist.strings Xcode reference is incomplete")
    pbxproj.write_text(source, encoding="utf-8", newline="\n")


def verify_bundle_localizations(bundle_dir: Path, att_enabled: bool) -> None:
    localized_files = sorted(bundle_dir.glob("*.lproj/InfoPlist.strings"))
    if not att_enabled:
        unexpected = [path for path in localized_files if read_info_plist_string(path) is not None]
        if unexpected:
            fail(f"ATT-disabled bundle contains localized tracking text: {unexpected[0]}")
        print("ATT_LOCALIZATION_VERIFY_OK enabled=false localized_tracking_text=absent")
        return

    expected = {
        "en": ATT_USAGE_DESCRIPTION_EN,
        "ja": ATT_USAGE_DESCRIPTION_JA,
    }
    for locale, expected_value in expected.items():
        path = bundle_dir / f"{locale}.lproj" / "InfoPlist.strings"
        actual = read_info_plist_string(path)
        if actual != expected_value:
            fail(
                f"Unexpected {locale} ATT purpose text in {path}: "
                f"expected {expected_value!r}, found {actual!r}"
            )
    combined = " ".join(expected.values()).lower()
    if "personalized" in combined or "あなたに合った" in combined:
        fail("ATT purpose text must not claim that personalized ads are enabled")
    print("ATT_LOCALIZATION_VERIFY_OK enabled=true locales=en,ja personalized_claim=false")


def configure_localizations(xcode_project: Path, app_dir: Path, att_enabled: bool) -> None:
    if not xcode_project.is_dir():
        fail(f"Missing Xcode project directory: {xcode_project}")
    if not app_dir.is_dir():
        fail(f"Missing generated iOS application directory: {app_dir}")
    if att_enabled:
        _patch_xcode_project(xcode_project / "project.pbxproj")
        _upsert_info_plist_string(
            app_dir / "en.lproj" / "InfoPlist.strings", ATT_USAGE_DESCRIPTION_EN
        )
        _upsert_info_plist_string(
            app_dir / "ja.lproj" / "InfoPlist.strings", ATT_USAGE_DESCRIPTION_JA
        )
    verify_bundle_localizations(app_dir, att_enabled)
    print(
        "ATT_LOCALIZATION_CONFIG_OK "
        f"enabled={'true' if att_enabled else 'false'} "
        f"project={xcode_project.name}"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    configure_parser = subparsers.add_parser("configure")
    configure_parser.add_argument("--xcode-project", required=True, type=Path)
    configure_parser.add_argument("--app-dir", required=True, type=Path)
    configure_parser.add_argument("--att-enabled", required=True, choices=("true", "false"))

    verify_parser = subparsers.add_parser("verify")
    verify_parser.add_argument("--bundle-dir", required=True, type=Path)
    verify_parser.add_argument("--att-enabled", required=True, choices=("true", "false"))

    args = parser.parse_args()
    att_enabled = args.att_enabled == "true"
    if args.command == "configure":
        configure_localizations(args.xcode_project, args.app_dir, att_enabled)
    else:
        verify_bundle_localizations(args.bundle_dir, att_enabled)


if __name__ == "__main__":
    main()
