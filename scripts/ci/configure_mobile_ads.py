#!/usr/bin/env python3
"""Generate ignored AdMob configuration from CI environment variables."""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path


SAMPLE_IOS_APP_ID = "ca-app-pub-3940256099942544~1458002511"
SAMPLE_IOS_REWARDED_ID = "ca-app-pub-3940256099942544/1712485313"
APP_ID_PATTERN = re.compile(r"^ca-app-pub-[0-9]{16}~[0-9]{10}$")
AD_UNIT_PATTERN = re.compile(r"^ca-app-pub-[0-9]{16}/[0-9]{10}$")
ATT_USAGE_DESCRIPTION = (
    "リワード広告の表示回数調整と効果測定のため、端末の広告識別子を利用する許可を求めます。"
    "許可しなくてもゲームを続けられます。 / "
    "We request permission to use the device advertising identifier for rewarded-ad "
    "frequency control and measurement. You can continue playing without allowing tracking."
)


def fail(message: str) -> None:
    raise SystemExit(message)


def main() -> None:
    if len(sys.argv) != 2 or sys.argv[1] not in {"production", "test"}:
        fail("usage: configure_mobile_ads.py production|test")

    mode = sys.argv[1]
    att_setting = os.environ.get("IOS_ATT_ENABLED", "").strip().lower()
    if att_setting not in {"true", "false"}:
        fail("IOS_ATT_ENABLED must be exactly true or false")
    att_enabled = att_setting == "true"
    att_text = ATT_USAGE_DESCRIPTION if att_enabled else ""
    if mode == "production":
        app_id = os.environ.get("ADMOB_IOS_APP_ID", "").strip()
        rewarded_id = os.environ.get("ADMOB_IOS_REWARDED_AD_UNIT_ID", "").strip()
        if not APP_ID_PATTERN.fullmatch(app_id):
            fail("ADMOB_IOS_APP_ID is missing or malformed")
        if not AD_UNIT_PATTERN.fullmatch(rewarded_id):
            fail("ADMOB_IOS_REWARDED_AD_UNIT_ID is missing or malformed")
        if app_id == SAMPLE_IOS_APP_ID or rewarded_id == SAMPLE_IOS_REWARDED_ID:
            fail("Production builds must not use Google's sample AdMob IDs")
        is_real = "true"
    else:
        app_id = SAMPLE_IOS_APP_ID
        rewarded_id = SAMPLE_IOS_REWARDED_ID
        is_real = "false"

    export_config = Path("addons/AdmobPlugin/ios_export.cfg")
    runtime_config = Path("data/mobile-ads.cfg")
    export_config.parent.mkdir(parents=True, exist_ok=True)
    runtime_config.parent.mkdir(parents=True, exist_ok=True)
    export_config.write_text(
        "\n".join(
            [
                "[General]",
                f"is_real={is_real}",
                "",
                "[Debug]",
                f'app_id="{SAMPLE_IOS_APP_ID}"',
                "",
                "[Release]",
                f'app_id="{app_id}"',
                "",
                "[ATT]",
                f"att_enabled={'true' if att_enabled else 'false'}",
                f'att_text="{att_text}"',
                "",
            ]
        ),
        encoding="utf-8",
        newline="\n",
    )
    runtime_config.write_text(
        "\n".join(
            [
                "[ios]",
                f'mode="{mode}"',
                f'rewarded_ad_unit_id="{rewarded_id}"',
                "",
            ]
        ),
        encoding="utf-8",
        newline="\n",
    )
    print(
        f"MOBILE_ADS_CONFIG_OK mode={mode} "
        f"att={'true' if att_enabled else 'false'} personalized=false"
    )


if __name__ == "__main__":
    main()
