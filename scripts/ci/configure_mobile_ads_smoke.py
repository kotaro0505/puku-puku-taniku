#!/usr/bin/env python3
"""Regression checks for profile-specific generated AdMob/ATT configuration."""

from __future__ import annotations

import configparser
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from configure_att_localizations import ATT_USAGE_DESCRIPTION_EN


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/ci/configure_mobile_ads.py"


def run_configuration(att_enabled: str) -> tuple[configparser.ConfigParser, str]:
    with tempfile.TemporaryDirectory() as temporary_directory:
        env = os.environ.copy()
        env["IOS_ATT_ENABLED"] = att_enabled
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "test"],
            cwd=temporary_directory,
            env=env,
            check=True,
            capture_output=True,
            text=True,
        )
        config = configparser.ConfigParser()
        path = Path(temporary_directory) / "addons/AdmobPlugin/ios_export.cfg"
        with path.open(encoding="utf-8") as stream:
            config.read_file(stream)
        return config, result.stdout


def main() -> None:
    enabled, enabled_output = run_configuration("true")
    assert enabled.getboolean("ATT", "att_enabled")
    usage = enabled.get("ATT", "att_text")
    assert usage == f'"{ATT_USAGE_DESCRIPTION_EN}"'
    assert "あなたに合った" not in usage
    assert "personalized" not in usage.lower()
    assert " / " not in usage
    assert "rewards will not change" in usage
    assert "att=true" in enabled_output

    disabled, disabled_output = run_configuration("false")
    assert not disabled.getboolean("ATT", "att_enabled")
    assert disabled.get("ATT", "att_text") == '""'
    assert "att=false" in disabled_output

    with tempfile.TemporaryDirectory() as temporary_directory:
        env = os.environ.copy()
        env["IOS_ATT_ENABLED"] = "unexpected"
        invalid = subprocess.run(
            [sys.executable, str(SCRIPT), "test"],
            cwd=temporary_directory,
            env=env,
            capture_output=True,
            text=True,
        )
        assert invalid.returncode != 0
        assert "IOS_ATT_ENABLED must be exactly true or false" in invalid.stderr

    print("MOBILE_ADS_CONFIG_SMOKE_OK att_release=true att_nonrelease=false invalid_rejected=true")


if __name__ == "__main__":
    main()
