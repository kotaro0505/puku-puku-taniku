#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || -z "$1" ]]; then
  echo "usage: resolve_ipa_path.sh IPA_OUTPUT_DIRECTORY" >&2
  exit 2
fi

ipa_output_dir="$1"
if [[ ! -d "$ipa_output_dir" ]]; then
  echo "IOS_IPA_DIRECTORY_MISSING expected_directory=$ipa_output_dir" >&2
  exit 1
fi

ipa_paths=()
shopt -s nullglob
for ipa_path in "$ipa_output_dir"/*.ipa; do
  [[ -f "$ipa_path" ]] && ipa_paths+=("$ipa_path")
done
shopt -u nullglob

case "${#ipa_paths[@]}" in
  0)
    echo "IOS_IPA_NOT_FOUND expected_directory=$ipa_output_dir pattern=*.ipa" >&2
    exit 1
    ;;
  1)
    printf '%s\n' "${ipa_paths[0]}"
    ;;
  *)
    echo "IOS_IPA_AMBIGUOUS expected_directory=$ipa_output_dir count=${#ipa_paths[@]}" >&2
    printf 'candidate=%s\n' "${ipa_paths[@]}" >&2
    exit 1
    ;;
esac
