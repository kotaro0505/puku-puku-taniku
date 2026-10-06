#!/bin/bash
set -euo pipefail

: "${GODOT_VERSION:?GODOT_VERSION is required}"
STOREKIT2_VERSION="${STOREKIT2_VERSION:-v0.2}"
PROJECT_DIR="${CM_BUILD_DIR:-$(pwd)}"
CACHE_ROOT="$HOME/.cache/puku-puku-taniku/storekit2-${STOREKIT2_VERSION}-godot-${GODOT_VERSION}"
CACHE_PLUGIN="$CACHE_ROOT/godot-storekit2"
OUTPUT_DIR="$PROJECT_DIR/ios/plugins/godot-storekit2"

copy_cached_plugin() {
  rm -rf "$OUTPUT_DIR"
  mkdir -p "$(dirname "$OUTPUT_DIR")"
  cp -R "$CACHE_PLUGIN" "$OUTPUT_DIR"
}

if [ -f "$CACHE_PLUGIN/godot-storekit2.gdip" ] \
  && [ -d "$CACHE_PLUGIN/godot-storekit2.debug.xcframework" ] \
  && [ -d "$CACHE_PLUGIN/godot-storekit2.release.xcframework" ]; then
  copy_cached_plugin
  echo "STOREKIT2_PLUGIN_CACHE_HIT version=$STOREKIT2_VERSION godot=$GODOT_VERSION"
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

# StoreKit 2 itself is available from iOS 15.0. Match the app deployment
# target instead of shipping a library that silently requires iOS 15.6.
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 15\.6;/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/g' \
  "$PLUGIN_SOURCE/godot-storekit2.xcodeproj/project.pbxproj"
chmod +x "$PLUGIN_SOURCE/scripts/generate_headers.sh" "$PLUGIN_SOURCE/scripts/make_release.sh" "$PLUGIN_SOURCE/scripts/timeout"
(cd "$PLUGIN_SOURCE" && ./scripts/generate_headers.sh)
test -n "$(find "$PLUGIN_SOURCE/godot" -name '*.gen.h' -print -quit)"
(cd "$PLUGIN_SOURCE" && ./scripts/make_release.sh)

BUILT_PLUGIN="$PLUGIN_SOURCE/bin/godot-storekit2"
test -f "$BUILT_PLUGIN/godot-storekit2.gdip"
test -d "$BUILT_PLUGIN/godot-storekit2.debug.xcframework"
test -d "$BUILT_PLUGIN/godot-storekit2.release.xcframework"
cp "$PLUGIN_SOURCE/LICENSE" "$BUILT_PLUGIN/LICENSE.txt"

rm -rf "$CACHE_ROOT"
mkdir -p "$CACHE_ROOT"
cp -R "$BUILT_PLUGIN" "$CACHE_PLUGIN"
copy_cached_plugin
echo "STOREKIT2_PLUGIN_BUILT version=$STOREKIT2_VERSION godot=$GODOT_VERSION"
