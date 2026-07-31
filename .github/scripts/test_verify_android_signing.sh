#!/usr/bin/env bash
set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
verifier="${script_directory}/verify_android_signing.sh"
apk_path="$(mktemp)"
trap 'rm -f "${apk_path}"' EXIT

expected_fingerprint="24597C73140A9C8A181486E209B3891250E5F8CC3721124FEAE9AA06D0771B59"
other_fingerprint="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

apksigner() {
  printf '%s\n' "${MOCK_APKSIGNER_OUTPUT:?MOCK_APKSIGNER_OUTPUT is not set}"
}
export -f apksigner
export ANDROID_SIGNING_CERT_SHA256="${expected_fingerprint}"

run_verifier() {
  export MOCK_APKSIGNER_OUTPUT="$1"
  bash "${verifier}" "${apk_path}"
}

run_verifier \
  "Signer #1 certificate SHA-256 digest: ${expected_fingerprint}"

run_verifier \
  "Signer (minSdkVersion=24, maxSdkVersion=35) certificate SHA-256 digest: ${expected_fingerprint}"

run_verifier \
  "Signer #1 certificate SHA-256 digest: ${expected_fingerprint}
Signer (minSdkVersion=24, maxSdkVersion=35) certificate SHA-256 digest: ${expected_fingerprint}"

if run_verifier \
  "Signer #1 certificate SHA-256 digest: ${expected_fingerprint}
Signer #2 certificate SHA-256 digest: ${other_fingerprint}" \
  >/dev/null 2>&1; then
  echo "Verifier accepted multiple signing certificates." >&2
  exit 1
fi

echo "Android signing verifier tests passed."
