#!/usr/bin/env bash
set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
verifier="${script_directory}/verify_android_signing.sh"
apk_path="$(mktemp)"
trap 'rm -f "${apk_path}"' EXIT

expected_fingerprint="E46125B876099E019B84095CB634AE65C7457F61D1BE26D2FD65BDE5BA50CDD6"
encoded_certificate="c3luY3ktY2VydGlmaWNhdGU="
other_encoded_certificate="ZGlmZmVyZW50LWNlcnRpZmljYXRl"

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
  "Verifies
Signer #1 certificate PEM:
-----BEGIN CERTIFICATE-----
${encoded_certificate}
-----END CERTIFICATE-----"

run_verifier \
  "Signer #1 certificate PEM:
-----BEGIN CERTIFICATE-----
${encoded_certificate}
-----END CERTIFICATE-----
Signer (minSdkVersion=24, maxSdkVersion=35) certificate PEM:
-----BEGIN CERTIFICATE-----
${encoded_certificate}
-----END CERTIFICATE-----"

if run_verifier \
  "Signer #1 certificate PEM:
-----BEGIN CERTIFICATE-----
${encoded_certificate}
-----END CERTIFICATE-----
Signer #2 certificate PEM:
-----BEGIN CERTIFICATE-----
${other_encoded_certificate}
-----END CERTIFICATE-----" \
  >/dev/null 2>&1; then
  echo "Verifier accepted multiple signing certificates." >&2
  exit 1
fi

echo "Android signing verifier tests passed."
