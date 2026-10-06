#!/bin/bash
set -euo pipefail

: "${GODOT_VERSION:?GODOT_VERSION is required}"
STOREKIT2_VERSION="${STOREKIT2_VERSION:-v0.2}"
IOS_MIN_VERSION="${IOS_MIN_VERSION:-15.6}"
STOREKIT2_COMPAT_REVISION="${STOREKIT2_COMPAT_REVISION:-compat2}"
PROJECT_DIR="${CM_BUILD_DIR:-$(pwd)}"
SOURCE_HEAD="$(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null || true)"
[ -n "$SOURCE_HEAD" ] || SOURCE_HEAD="unavailable"
CACHE_ROOT="$HOME/.cache/puku-puku-taniku/storekit2-${STOREKIT2_VERSION}-godot-${GODOT_VERSION}-ios${IOS_MIN_VERSION}-${STOREKIT2_COMPAT_REVISION}"
CACHE_PLUGIN="$CACHE_ROOT/godot-storekit2"
CACHE_TARGET_FILE="$CACHE_ROOT/ios-min-version.txt"
CACHE_COMPAT_FILE="$CACHE_ROOT/compat-revision.txt"
OUTPUT_DIR="$PROJECT_DIR/ios/plugins/godot-storekit2"

if [ "$IOS_MIN_VERSION" != "15.6" ]; then
  echo "godot-storekit2 $STOREKIT2_VERSION requires IOS_MIN_VERSION=15.6, got $IOS_MIN_VERSION" >&2
  exit 1
fi

if [ "$GODOT_VERSION" != "4.7.2" ]; then
  echo "Unexpected Godot version for the StoreKit2 compatibility patch: expected 4.7.2, got $GODOT_VERSION" >&2
  exit 1
fi

if [ "$STOREKIT2_VERSION" != "v0.2" ]; then
  echo "Unexpected StoreKit2 version for the compatibility patch: expected v0.2, got $STOREKIT2_VERSION" >&2
  exit 1
fi

if [ "$STOREKIT2_COMPAT_REVISION" != "compat2" ]; then
  echo "Unexpected StoreKit2 compatibility revision: expected compat2, got $STOREKIT2_COMPAT_REVISION" >&2
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
  && [ -f "$CACHE_COMPAT_FILE" ] \
  && [ "$(cat "$CACHE_COMPAT_FILE")" = "$STOREKIT2_COMPAT_REVISION" ] \
  && validate_plugin_artifacts "$CACHE_PLUGIN"; then
  copy_cached_plugin
  echo "STOREKIT2_PLUGIN_CACHE_HIT version=$STOREKIT2_VERSION godot=$GODOT_VERSION ios=$IOS_MIN_VERSION compat=$STOREKIT2_COMPAT_REVISION"
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

PLUGIN_HEADER="$PLUGIN_SOURCE/godot-storekit2/godot-storekit2.h"
GODOT_TYPE_INFO_HEADER="$PLUGIN_SOURCE/godot/core/variant/type_info.h"
if [ ! -f "$PLUGIN_HEADER" ]; then
  echo "Missing godot-storekit2 header for the Godot 4.7.2 compatibility patch: $PLUGIN_HEADER" >&2
  exit 1
fi
if [ ! -f "$GODOT_TYPE_INFO_HEADER" ]; then
  echo "Missing Godot type_info.h required by godot-storekit2: $GODOT_TYPE_INFO_HEADER" >&2
  exit 1
fi
if ! grep -Eq '^[[:space:]]*#[[:space:]]*define[[:space:]]+VARIANT_ENUM_CAST[[:space:]]*\(' "$GODOT_TYPE_INFO_HEADER"; then
  echo "Godot $GODOT_VERSION type_info.h does not define VARIANT_ENUM_CAST: $GODOT_TYPE_INFO_HEADER" >&2
  exit 1
fi

# godot-storekit2 v0.2 relies on a transitive include that no longer exposes
# VARIANT_ENUM_CAST in Godot 4.7.2. Patch only the downloaded temporary source.
if ! grep -Fqx '#include "core/variant/type_info.h"' "$PLUGIN_HEADER"; then
  python3 - "$PLUGIN_HEADER" <<'PY'
import sys
from pathlib import Path

header_path = Path(sys.argv[1])
source = header_path.read_text(encoding="utf-8")
anchor = '#include "core/variant/dictionary.h"'
required = '#include "core/variant/type_info.h"'
if source.count(anchor) != 1:
    raise SystemExit(
        f"Cannot apply Godot 4.7.2 compatibility patch: expected one {anchor!r} in {header_path}"
    )
source = source.replace(anchor, f"{anchor}\n{required}", 1)
header_path.write_text(source, encoding="utf-8")
PY
fi

TYPE_INFO_INCLUDE_COUNT="$(awk '$0 == "#include \"core/variant/type_info.h\"" { count++ } END { print count + 0 }' "$PLUGIN_HEADER")"
if [ "$TYPE_INFO_INCLUDE_COUNT" -ne 1 ]; then
  echo "Expected exactly one core/variant/type_info.h include in $PLUGIN_HEADER, found $TYPE_INFO_INCLUDE_COUNT" >&2
  exit 1
fi
grep -Fqx '#include "core/variant/type_info.h"' "$PLUGIN_HEADER"
VARIANT_ENUM_CAST_USE_COUNT="$(awk '/^[[:space:]]*VARIANT_ENUM_CAST[[:space:]]*\(GodotStoreKit2::TransactionState\)[[:space:]]*$/ { count++ } END { print count + 0 }' "$PLUGIN_HEADER")"
if [ "$VARIANT_ENUM_CAST_USE_COUNT" -ne 1 ]; then
  echo "Expected exactly one GodotStoreKit2::TransactionState VARIANT_ENUM_CAST in $PLUGIN_HEADER, found $VARIANT_ENUM_CAST_USE_COUNT" >&2
  exit 1
fi
TYPE_INFO_INCLUDE_LINE="$(awk '$0 == "#include \"core/variant/type_info.h\"" { print NR; exit }' "$PLUGIN_HEADER")"
VARIANT_ENUM_CAST_LINE="$(awk '/^[[:space:]]*VARIANT_ENUM_CAST[[:space:]]*\(GodotStoreKit2::TransactionState\)[[:space:]]*$/ { print NR; exit }' "$PLUGIN_HEADER")"
if [ -z "$TYPE_INFO_INCLUDE_LINE" ] || [ -z "$VARIANT_ENUM_CAST_LINE" ] || [ "$TYPE_INFO_INCLUDE_LINE" -ge "$VARIANT_ENUM_CAST_LINE" ]; then
  echo "Invalid StoreKit2 macro structure: type_info include line=$TYPE_INFO_INCLUDE_LINE VARIANT_ENUM_CAST line=$VARIANT_ENUM_CAST_LINE" >&2
  exit 1
fi

echo "STOREKIT2_BUILD_DIAGNOSTICS godot=$GODOT_VERSION storekit=$STOREKIT2_VERSION ios=$IOS_MIN_VERSION compat=$STOREKIT2_COMPAT_REVISION"
echo "STOREKIT2_SOURCE_HEAD=$SOURCE_HEAD"
echo "STOREKIT2_PATCHED_HEADER=$PLUGIN_HEADER"
echo "STOREKIT2_MACRO_STRUCTURE include_line=$TYPE_INFO_INCLUDE_LINE variant_enum_cast_line=$VARIANT_ENUM_CAST_LINE"
echo "STOREKIT2_PATCHED_HEADER_BEGIN"
nl -ba "$PLUGIN_HEADER" | sed -n '1,55p'
echo "STOREKIT2_PATCHED_HEADER_END"
echo "STOREKIT2_GODOT_COMPAT_PATCH_OK godot=$GODOT_VERSION include=core/variant/type_info.h count=$TYPE_INFO_INCLUDE_COUNT"

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
printf '%s\n' "$STOREKIT2_COMPAT_REVISION" > "$CACHE_COMPAT_FILE"
copy_cached_plugin
echo "STOREKIT2_PLUGIN_BUILT version=$STOREKIT2_VERSION godot=$GODOT_VERSION ios=$IOS_MIN_VERSION compat=$STOREKIT2_COMPAT_REVISION"
