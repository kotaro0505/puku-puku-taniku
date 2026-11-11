#!/usr/bin/env python3
"""Regression checks for locale-specific ATT purpose-string configuration."""

from __future__ import annotations

import tempfile
from pathlib import Path

from configure_att_localizations import (
    ATT_KEY,
    ATT_USAGE_DESCRIPTION_EN,
    ATT_USAGE_DESCRIPTION_JA,
    configure_localizations,
    read_info_plist_string,
    verify_bundle_localizations,
)


PBX_FIXTURE = """// !$*UTF8*$!
{
objects = {
/* Begin PBXFileReference section */
\t\tD0BCFE4518AEBDA2004A7AAE /* en */ = {isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = en; path = en.lproj/InfoPlist.strings; sourceTree = "<group>"; };
/* End PBXFileReference section */
\t\tknownRegions = (
\t\t\ten,
\t\t\tBase,
\t\t);
/* Begin PBXVariantGroup section */
\t\tD0BCFE4418AEBDA2004A7AAE /* InfoPlist.strings */ = {
\t\t\tisa = PBXVariantGroup;
\t\t\tchildren = (
\t\t\t\tD0BCFE4518AEBDA2004A7AAE /* en */,
\t\t\t);
\t\t\tname = InfoPlist.strings;
\t\t\tsourceTree = "<group>";
\t\t};
/* End PBXVariantGroup section */
};
}
"""


def write_fixture(root: Path) -> tuple[Path, Path]:
    project = root / "Example.xcodeproj"
    app_dir = root / "Example"
    project.mkdir()
    (app_dir / "en.lproj").mkdir(parents=True)
    (project / "project.pbxproj").write_text(PBX_FIXTURE, encoding="utf-8")
    (app_dir / "en.lproj" / "InfoPlist.strings").write_text(
        "/* Localized versions of Info.plist keys */\n",
        encoding="utf-8",
    )
    return project, app_dir


def main() -> None:
    with tempfile.TemporaryDirectory() as temporary_directory:
        project, app_dir = write_fixture(Path(temporary_directory))
        configure_localizations(project, app_dir, True)
        # Applying the configuration twice must not duplicate references or keys.
        configure_localizations(project, app_dir, True)
        source = (project / "project.pbxproj").read_text(encoding="utf-8")
        assert source.count("path = ja.lproj/InfoPlist.strings;") == 1
        assert source.count("/* ja */,") == 1
        assert source.count("\n\t\t\tja,\n") == 1
        assert read_info_plist_string(app_dir / "en.lproj/InfoPlist.strings") == ATT_USAGE_DESCRIPTION_EN
        assert read_info_plist_string(app_dir / "ja.lproj/InfoPlist.strings") == ATT_USAGE_DESCRIPTION_JA
        assert "personalized" not in ATT_USAGE_DESCRIPTION_EN.lower()
        assert "あなたに合った" not in ATT_USAGE_DESCRIPTION_JA

    with tempfile.TemporaryDirectory() as temporary_directory:
        project, app_dir = write_fixture(Path(temporary_directory))
        configure_localizations(project, app_dir, False)
        assert ATT_KEY not in (app_dir / "en.lproj" / "InfoPlist.strings").read_text(encoding="utf-8")

    with tempfile.TemporaryDirectory() as temporary_directory:
        root = Path(temporary_directory)
        (root / "en.lproj").mkdir()
        (root / "en.lproj" / "InfoPlist.strings").write_text(
            f'{ATT_KEY} = "Unexpected";\n', encoding="utf-8"
        )
        try:
            verify_bundle_localizations(root, False)
        except SystemExit as error:
            assert "ATT-disabled bundle" in str(error)
        else:
            raise AssertionError("ATT-disabled validation accepted localized tracking text")

    print(
        "ATT_LOCALIZATION_SMOKE_OK locales=en,ja exact_text=true "
        "idempotent=true disabled_absent=true personalized_claim=false"
    )


if __name__ == "__main__":
    main()
