#!/bin/bash
set -euo pipefail

: "${GODOT_VERSION:?GODOT_VERSION is required}"
STOREKIT2_VERSION="${STOREKIT2_VERSION:-v0.2}"
IOS_MIN_VERSION="${IOS_MIN_VERSION:-15.6}"
PROJECT_DIR="${CM_BUILD_DIR:-$(pwd)}"
CACHE_ROOT="$HOME/.cache/puku-puku-taniku/storekit2-${STOREKIT2_VERSION}-godot-${GODOT_VERSION}-ios${IOS_MIN_VERSION}"
CACHE_PLUGIN="$CACHE_ROOT/godot-storekit2"
CACHE_TARGET_FILE="$CACHE_ROOT/ios-min-version.txt"
OUTPUT_DIR="$PROJECT_DIR/ios/plugins/godot-storekit2"

if [ "$IOS_MIN_VERSION" != "15.6" ]; then
  echo "godot-storekit2 $STOREKIT2_VERSION requires IOS_MIN_VERSION=15.6, got $IOS_MIN_VERSION" >&2
  exit 1
fi

validate_plugin_artifacts() {
  local plugin_dir="$1"
  test -f "$plugin_dir/godot-storekit2.gdip"
  test -d "$plugin_dir/godot-storekit2.debug.xcframework"
  test -d "$plugin_dir/godot-storekit2.release.xcframework"
  grep -Fq 'StoreKit.framework' "$plugin_dir/godot-storekit2.gdip"
  python3 - \
    "$plugin_dir/godot-storekit2.debug.xcframework" \
    "$plugin_dir/godot-storekit2.release.xcframework" <<'PY'
import plistlib
import sys
from pathlib import Path

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
    if not candidates:
        raise SystemExit(f"Missing iOS arm64 slice in {framework}")
    for library in candidates:
        library_path = framework / library["LibraryIdentifier"] / library["LibraryPath"]
        if not library_path.exists():
            raise SystemExit(f"Missing iOS arm64 library: {library_path}")
    print(f"STOREKIT2_XCFRAMEWORK_OK path={framework} ios_arm64=true")
PY
}

copy_cached_plugin() {
  rm -rf "$OUTPUT_DIR"
  mkdir -p "$(dirname "$OUTPUT_DIR")"
  cp -R "$CACHE_PLUGIN" "$OUTPUT_DIR"
}

if [ -f "$CACHE_TARGET_FILE" ] \
  && [ "$(cat "$CACHE_TARGET_FILE")" = "$IOS_MIN_VERSION" ] \
  && validate_plugin_artifacts "$CACHE_PLUGIN"; then
  copy_cached_plugin
  echo "STOREKIT2_PLUGIN_CACHE_HIT version=$STOREKIT2_VERSION godot=$GODOT_VERSION ios=$IOS_MIN_VERSION"
  exit 0
fi

if ! command -v scons >/dev/null 2>&1; then
  python3 -m pip install --user scons
  export PATH="$(python3 -m site --user-base)/bin:$PATH"
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
PLUGIN_ZIP="$WORK_DIR/storekit2.zip"
GODOT_ZIP="$WORK_DIR/godot.zip"

curl --fail --location --retry 3 \
  --output "$PLUGIN_ZIP" \
  "https://github.com/godot-sdk-integrations/godot-storekit2/archive/refs/tags/${STOREKIT2_VERSION}.zip"
unzip -q "$PLUGIN_ZIP" -d "$WORK_DIR/plugin"
PLUGIN_SOURCE="$(find "$WORK_DIR/plugin" -mindepth 1 -maxdepth 1 -type d -print -quit)"
test -n "$PLUGIN_SOURCE"

curl --fail --location --retry 3 \
  --output "$GODOT_ZIP" \
  "https://github.com/godotengine/godot/archive/refs/tags/${GODOT_VERSION}-stable.zip"
unzip -q "$GODOT_ZIP" -d "$WORK_DIR/godot-source"
GODOT_SOURCE="$(find "$WORK_DIR/godot-source" -mindepth 1 -maxdepth 1 -type d -print -quit)"
test -n "$GODOT_SOURCE"
rm -rf "$PLUGIN_SOURCE/godot"
mv "$GODOT_SOURCE" "$PLUGIN_SOURCE/godot"

PLUGIN_PROJECT="$PLUGIN_SOURCE/godot-storekit2.xcodeproj/project.pbxproj"
python3 - "$PLUGIN_PROJECT" "$IOS_MIN_VERSION" <<'PY'
import re
import sys
from pathlib import Path

project_path = Path(sys.argv[1])
expected = sys.argv[2]
targets = sorted(set(re.findall(r"IPHONEOS_DEPLOYMENT_TARGET\s*=\s*([^;]+);", project_path.read_text(encoding="utf-8"))))
if targets != [expected]:
    actual = ", ".join(targets) if targets else "missing"
    raise SystemExit(
        f"Unexpected godot-storekit2 deployment target: expected {expected}, found {actual} in {project_path}"
    )
print(f"STOREKIT2_DEPLOYMENT_TARGET_OK target={expected} project={project_path}")
PY
chmod +x "$PLUGIN_SOURCE/scripts/generate_headers.sh" "$PLUGIN_SOURCE/scripts/make_release.sh" "$PLUGIN_SOURCE/scripts/timeout"
(cd "$PLUGIN_SOURCE" && ./scripts/generate_headers.sh)
test -n "$(find "$PLUGIN_SOURCE/godot" -name '*.gen.h' -print -quit)"
(cd "$PLUGIN_SOURCE" && ./scripts/make_release.sh)

BUILT_PLUGIN="$PLUGIN_SOURCE/bin/godot-storekit2"
validate_plugin_artifacts "$BUILT_PLUGIN"
cp "$PLUGIN_SOURCE/LICENSE" "$BUILT_PLUGIN/LICENSE.txt"

rm -rf "$CACHE_ROOT"
mkdir -p "$CACHE_ROOT"
cp -R "$BUILT_PLUGIN" "$CACHE_PLUGIN"
printf '%s\n' "$IOS_MIN_VERSION" > "$CACHE_TARGET_FILE"
copy_cached_plugin
echo "STOREKIT2_PLUGIN_BUILT version=$STOREKIT2_VERSION godot=$GODOT_VERSION ios=$IOS_MIN_VERSION"
