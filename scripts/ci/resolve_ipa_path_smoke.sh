#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
resolver="$repo_root/scripts/ci/resolve_ipa_path.sh"
temporary_root="$(mktemp -d)"
trap 'rm -rf "$temporary_root"' EXIT

if bash "$resolver" "$temporary_root/missing" >"$temporary_root/missing.out" 2>"$temporary_root/missing.err"; then
  echo "resolver accepted a missing IPA output directory" >&2
  exit 1
fi
grep -Fq "IOS_IPA_DIRECTORY_MISSING" "$temporary_root/missing.err"

mkdir -p "$temporary_root/empty"
if bash "$resolver" "$temporary_root/empty" >"$temporary_root/empty.out" 2>"$temporary_root/empty.err"; then
  echo "resolver accepted an empty IPA output directory" >&2
  exit 1
fi
grep -Fq "IOS_IPA_NOT_FOUND" "$temporary_root/empty.err"

mkdir -p "$temporary_root/single"
touch "$temporary_root/single/puku_puku_taniku_capture.ipa"
resolved_path="$(bash "$resolver" "$temporary_root/single")"
test "$resolved_path" = "$temporary_root/single/puku_puku_taniku_capture.ipa"

mkdir -p "$temporary_root/multiple"
touch "$temporary_root/multiple/first.ipa" "$temporary_root/multiple/second.ipa"
if bash "$resolver" "$temporary_root/multiple" >"$temporary_root/multiple.out" 2>"$temporary_root/multiple.err"; then
  echo "resolver accepted multiple IPA files" >&2
  exit 1
fi
grep -Fq "IOS_IPA_AMBIGUOUS" "$temporary_root/multiple.err"
grep -Fq "count=2" "$temporary_root/multiple.err"

echo "IOS_IPA_PATH_SMOKE_OK missing_directory=true missing_file=true single_file=true multiple_files=true"
