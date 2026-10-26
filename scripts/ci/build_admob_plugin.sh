#!/bin/bash
set -euo pipefail

: "${GODOT_VERSION:?GODOT_VERSION is required}"
IOS_MIN_VERSION="${IOS_MIN_VERSION:-15.6}"
ADMOB_PLUGIN_VERSION="${ADMOB_PLUGIN_VERSION:-v7.0}"
ADMOB_PLUGIN_UPSTREAM_COMMIT="${ADMOB_PLUGIN_UPSTREAM_COMMIT:-4b4ddceab0be81f0dcb12a6313038dba6cf9eacf}"
ADMOB_NATIVE_COMPAT_REVISION="${ADMOB_NATIVE_COMPAT_REVISION:-ump1}"
GOOGLE_MOBILE_ADS_VERSION="${GOOGLE_MOBILE_ADS_VERSION:-12.14.0}"
PROJECT_DIR="${CM_BUILD_DIR:-$(pwd)}"
PATCH_SCRIPT="$PROJECT_DIR/scripts/ci/patch_admob_ump_native.py"
SOURCE_HEAD="$(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null || true)"
[ -n "$SOURCE_HEAD" ] || SOURCE_HEAD="unavailable"

EXPECTED_UPSTREAM_COMMIT="4b4ddceab0be81f0dcb12a6313038dba6cf9eacf"
EXPECTED_UPSTREAM_REPOSITORY="https://github.com/godot-sdk-integrations/godot-admob.git"
CACHE_ROOT="$HOME/.cache/puku-puku-taniku/admob-${ADMOB_PLUGIN_VERSION}-${ADMOB_NATIVE_COMPAT_REVISION}-godot-${GODOT_VERSION}-gma-${GOOGLE_MOBILE_ADS_VERSION}-ios${IOS_MIN_VERSION}"
CACHE_PLUGIN="$CACHE_ROOT/plugin"
CACHE_METADATA="$CACHE_ROOT/metadata.txt"
OUTPUT_DEBUG="$PROJECT_DIR/ios/plugins/AdmobPlugin.debug.xcframework"
OUTPUT_RELEASE="$PROJECT_DIR/ios/plugins/AdmobPlugin.release.xcframework"
PATCH_SHA="$(shasum -a 256 "$PATCH_SCRIPT" | awk '{print $1}')"
EXPECTED_METADATA="upstream=$ADMOB_PLUGIN_UPSTREAM_COMMIT
compat=$ADMOB_NATIVE_COMPAT_REVISION
godot=$GODOT_VERSION
gma=$GOOGLE_MOBILE_ADS_VERSION
ios=$IOS_MIN_VERSION
patch_sha256=$PATCH_SHA"

if [ "$GODOT_VERSION" != "4.7.2" ]; then
  echo "AdMob native compatibility build requires Godot 4.7.2, got $GODOT_VERSION" >&2
  exit 1
fi
if [ "$IOS_MIN_VERSION" != "15.6" ]; then
  echo "AdMob native compatibility build requires iOS 15.6, got $IOS_MIN_VERSION" >&2
  exit 1
fi
if [ "$ADMOB_PLUGIN_VERSION" != "v7.0" ]; then
  echo "Unexpected AdMob plugin version: $ADMOB_PLUGIN_VERSION" >&2
  exit 1
fi
if [ "$ADMOB_PLUGIN_UPSTREAM_COMMIT" != "$EXPECTED_UPSTREAM_COMMIT" ]; then
  echo "Unexpected AdMob upstream commit: $ADMOB_PLUGIN_UPSTREAM_COMMIT" >&2
  exit 1
fi
if [ "$ADMOB_NATIVE_COMPAT_REVISION" != "ump1" ]; then
  echo "Unexpected AdMob native compatibility revision: $ADMOB_NATIVE_COMPAT_REVISION" >&2
  exit 1
fi
if [ "$GOOGLE_MOBILE_ADS_VERSION" != "12.14.0" ]; then
  echo "Unreviewed Google Mobile Ads SDK version: $GOOGLE_MOBILE_ADS_VERSION" >&2
  exit 1
fi
test -f "$PATCH_SCRIPT"

validate_plugin_artifacts() {
  local plugin_dir="$1"
  python3 - \
    "$plugin_dir/AdmobPlugin.debug.xcframework" \
    "$plugin_dir/AdmobPlugin.release.xcframework" <<'PY'
import plistlib
import sys
from pathlib import Path

required_tokens = [
    b"privacy_options_form_dismissed",
    b"get_privacy_options_requirement_status",
    b"present_privacy_options_form",
    b"can_request_ads",
]

for framework_arg in sys.argv[1:]:
    framework = Path(framework_arg)
    info_path = framework / "Info.plist"
    with info_path.open("rb") as stream:
        info = plistlib.load(stream)
    candidates = [
        library
        for library in info.get("AvailableLibraries", [])
        if library.get("SupportedPlatform") == "ios"
        and not library.get("SupportedPlatformVariant")
        and "arm64" in library.get("SupportedArchitectures", [])
    ]
    if len(candidates) != 1:
        raise SystemExit(f"Expected one iOS arm64 slice in {framework}, found {len(candidates)}")
    library = candidates[0]
    library_path = framework / library["LibraryIdentifier"] / library["LibraryPath"]
    data = library_path.read_bytes()
    for token in required_tokens:
        if token not in data:
            raise SystemExit(f"Missing native UMP bridge token {token!r} in {library_path}")
    print(f"ADMOB_UMP_XCFRAMEWORK_OK path={framework} ios_arm64=true bridge=complete")
PY
}

copy_plugin_artifacts() {
  local plugin_dir="$1"
  case "$OUTPUT_DEBUG" in
    "$PROJECT_DIR/ios/plugins/"*) ;;
    *) echo "Unsafe AdMob output path: $OUTPUT_DEBUG" >&2; exit 1 ;;
  esac
  rm -rf "$OUTPUT_DEBUG" "$OUTPUT_RELEASE"
  cp -R "$plugin_dir/AdmobPlugin.debug.xcframework" "$OUTPUT_DEBUG"
  cp -R "$plugin_dir/AdmobPlugin.release.xcframework" "$OUTPUT_RELEASE"
}

if [ -f "$CACHE_METADATA" ] \
  && [ "$(cat "$CACHE_METADATA")" = "$EXPECTED_METADATA" ] \
  && validate_plugin_artifacts "$CACHE_PLUGIN"; then
  copy_plugin_artifacts "$CACHE_PLUGIN"
  echo "ADMOB_UMP_NATIVE_CACHE_HIT version=$ADMOB_PLUGIN_VERSION compat=$ADMOB_NATIVE_COMPAT_REVISION godot=$GODOT_VERSION"
  exit 0
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
PLUGIN_SOURCE="$WORK_DIR/godot-admob"

git clone --quiet --depth 1 --branch "$ADMOB_PLUGIN_VERSION" "$EXPECTED_UPSTREAM_REPOSITORY" "$PLUGIN_SOURCE"
ACTUAL_UPSTREAM_COMMIT="$(git -C "$PLUGIN_SOURCE" rev-parse HEAD)"
if [ "$ACTUAL_UPSTREAM_COMMIT" != "$ADMOB_PLUGIN_UPSTREAM_COMMIT" ]; then
  echo "AdMob v7.0 source mismatch: expected $ADMOB_PLUGIN_UPSTREAM_COMMIT, got $ACTUAL_UPSTREAM_COMMIT" >&2
  exit 1
fi

python3 "$PATCH_SCRIPT" "$PLUGIN_SOURCE" \
  --godot-version "$GODOT_VERSION" \
  --godot-release-type stable \
  --ios-min-version "$IOS_MIN_VERSION"
git -C "$PLUGIN_SOURCE" diff --check

chmod +x "$PLUGIN_SOURCE/common/gradlew" "$PLUGIN_SOURCE"/script/*.sh
(cd "$PLUGIN_SOURCE" && ./script/build_ios.sh -A)

python3 - "$PLUGIN_SOURCE/ios/plugin.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" <<'PY'
import json
import sys
from pathlib import Path

resolved_path = Path(sys.argv[1])
resolved = json.loads(resolved_path.read_text(encoding="utf-8"))
pins = {pin.get("identity"): pin.get("state", {}) for pin in resolved.get("pins", [])}
expected = {
    "swift-package-manager-google-mobile-ads": (
        "12.14.0",
        "1239c23464503053c17d37ee5daa70de3455e9c8",
    ),
    "swift-package-manager-google-user-messaging-platform": (
        "3.1.0",
        "13b248eaa73b7826f0efb1bcf455e251d65ecb1b",
    ),
}
for identity, (version, revision) in expected.items():
    state = pins.get(identity, {})
    if state.get("version") != version or state.get("revision") != revision:
        raise SystemExit(
            f"Resolved Swift package drift for {identity}: "
            f"expected {version}/{revision}, got {state.get('version')}/{state.get('revision')}"
        )
print("ADMOB_SPM_DEPENDENCIES_OK gma=12.14.0 ump=3.1.0")
PY

BUILT_PLUGIN="$PLUGIN_SOURCE/common/build/plugin/ios/plugins"
validate_plugin_artifacts "$BUILT_PLUGIN"

case "$CACHE_ROOT" in
  "$HOME/.cache/puku-puku-taniku/"*) ;;
  *) echo "Unsafe AdMob cache path: $CACHE_ROOT" >&2; exit 1 ;;
esac
rm -rf "$CACHE_ROOT"
mkdir -p "$CACHE_PLUGIN"
cp -R "$BUILT_PLUGIN/AdmobPlugin.debug.xcframework" "$CACHE_PLUGIN/AdmobPlugin.debug.xcframework"
cp -R "$BUILT_PLUGIN/AdmobPlugin.release.xcframework" "$CACHE_PLUGIN/AdmobPlugin.release.xcframework"
printf '%s\n' "$EXPECTED_METADATA" > "$CACHE_METADATA"
copy_plugin_artifacts "$CACHE_PLUGIN"

echo "ADMOB_UMP_NATIVE_BUILT version=$ADMOB_PLUGIN_VERSION upstream=$ACTUAL_UPSTREAM_COMMIT compat=$ADMOB_NATIVE_COMPAT_REVISION"
echo "ADMOB_UMP_NATIVE_SOURCE_HEAD=$SOURCE_HEAD"
