#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: verify_mobile_ads_export.sh GODOT_BIN PROJECT_ROOT EXPORTED_PCK test|production" >&2
  exit 2
fi

godot_bin="$1"
project_root="$2"
exported_pack="$3"
expected_mode="$4"
runtime_config="$project_root/data/mobile-ads.cfg"
verifier_script="$project_root/scripts/ci/verify_mobile_ads_pack.gd"

if [ "$expected_mode" != "test" ] && [ "$expected_mode" != "production" ]; then
  echo "MOBILE_ADS_EXPORT_FAILED check=expected_mode detail=expected test or production" >&2
  exit 1
fi
if [ ! -x "$godot_bin" ]; then
  echo "MOBILE_ADS_EXPORT_FAILED check=godot.file_exists detail=Godot executable was not found" >&2
  exit 1
fi
if [ ! -d "$project_root" ]; then
  echo "MOBILE_ADS_EXPORT_FAILED check=project.file_exists detail=project directory was not found" >&2
  exit 1
fi
if [ ! -f "$runtime_config" ]; then
  echo "MOBILE_ADS_EXPORT_FAILED check=source_config.file_exists detail=generated runtime config was not found" >&2
  exit 1
fi
if [ ! -f "$verifier_script" ]; then
  echo "MOBILE_ADS_EXPORT_FAILED check=verifier.file_exists detail=pack verifier script was not found" >&2
  exit 1
fi
if [[ "$exported_pack" != *.pck ]]; then
  echo "MOBILE_ADS_EXPORT_FAILED check=pack.extension detail=expected export target does not use the .pck extension" >&2
  exit 1
fi

pack_parent="$(dirname "$exported_pack")"
discovered_pack_count=0
if [ -d "$pack_parent" ]; then
  while IFS= read -r _pack_path; do
    discovered_pack_count=$((discovered_pack_count + 1))
  done < <(find "$pack_parent" -maxdepth 1 -type f -name '*.pck' -print)
fi
if [ ! -f "$exported_pack" ]; then
  echo "MOBILE_ADS_EXPORT_FAILED check=pack.file_exists detail=expected exported PCK was not found; sibling_pck_count=$discovered_pack_count" >&2
  exit 1
fi

validation_workdir="$(mktemp -d)"
cleanup_validation_workdir() {
  rmdir "$validation_workdir" 2>/dev/null || true
}
trap cleanup_validation_workdir EXIT

# Start Godot from an empty working directory with the exported pack as its
# main pack. This makes res:// resolve only from the distribution artifact,
# without temporarily removing the source config or changing import caches.
set +e
(
  cd "$validation_workdir"
  "$godot_bin" --headless --main-pack "$exported_pack" \
    --script "$verifier_script" -- \
    "$exported_pack" "$expected_mode"
) 2>&1 \
  | sed -E 's|ca-app-pub-[0-9]{16}[~/][0-9]{10}|[REDACTED_ADMOB_ID]|g'
pipeline_status=("${PIPESTATUS[@]}")
set -e
if [ "${pipeline_status[0]}" -ne 0 ]; then
  echo "MOBILE_ADS_EXPORT_FAILED check=pack.runtime_config detail=exported PCK config validation failed" >&2
  exit "${pipeline_status[0]}"
fi
if [ "${pipeline_status[1]}" -ne 0 ]; then
  echo "MOBILE_ADS_EXPORT_FAILED check=log.redaction detail=diagnostic log redaction failed" >&2
  exit "${pipeline_status[1]}"
fi

cleanup_validation_workdir
trap - EXIT
echo "MOBILE_ADS_EXPORT_OK mode=$expected_mode path=res://data/mobile-ads.cfg pack_selection=explicit sibling_pck_count=$discovered_pack_count"
