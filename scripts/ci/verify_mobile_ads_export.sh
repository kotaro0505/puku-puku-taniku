#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: verify_mobile_ads_export.sh GODOT_BIN PROJECT_ROOT DISTRIBUTION_ROOT test|production" >&2
  exit 2
fi

godot_bin="$1"
project_root="$2"
distribution_root="$3"
expected_mode="$4"
runtime_config="$project_root/data/mobile-ads.cfg"

if [ "$expected_mode" != "test" ] && [ "$expected_mode" != "production" ]; then
  echo "MOBILE_ADS_EXPORT_FAILED check=expected_mode detail=expected test or production" >&2
  exit 1
fi
if [ ! -x "$godot_bin" ]; then
  echo "MOBILE_ADS_EXPORT_FAILED check=godot.file_exists detail=Godot executable was not found" >&2
  exit 1
fi
if [ ! -d "$distribution_root" ]; then
  echo "MOBILE_ADS_EXPORT_FAILED check=distribution.file_exists detail=distribution directory was not found" >&2
  exit 1
fi
if [ ! -f "$runtime_config" ]; then
  echo "MOBILE_ADS_EXPORT_FAILED check=source_config.file_exists detail=generated runtime config was not found" >&2
  exit 1
fi

pack_files=()
while IFS= read -r pack_path; do
  pack_files+=("$pack_path")
done < <(find "$distribution_root" -type f -name '*.pck' -print)
if [ "${#pack_files[@]}" -ne 1 ]; then
  echo "MOBILE_ADS_EXPORT_FAILED check=pack.count detail=expected exactly one exported PCK, found ${#pack_files[@]}" >&2
  exit 1
fi

backup_dir="$(mktemp -d)"
backup_config="$backup_dir/mobile-ads.cfg"
restore_source_config() {
  if [ -f "$backup_config" ]; then
    mv "$backup_config" "$runtime_config"
  fi
  rmdir "$backup_dir" 2>/dev/null || true
}
trap restore_source_config EXIT

# Remove the source copy while checking so res:// can only resolve the file
# from the exported PCK. This prevents a false pass on the CI checkout.
mv "$runtime_config" "$backup_config"
set +e
"$godot_bin" --headless --path "$project_root" \
  --script res://scripts/ci/verify_mobile_ads_pack.gd -- \
  "${pack_files[0]}" "$expected_mode" 2>&1 \
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

restore_source_config
trap - EXIT
echo "MOBILE_ADS_EXPORT_OK mode=$expected_mode path=res://data/mobile-ads.cfg"
