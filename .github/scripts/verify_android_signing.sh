#!/usr/bin/env bash
set -euo pipefail

if (( $# == 0 )); then
  echo "Usage: verify_android_signing.sh <apk> [<apk> ...]" >&2
  exit 2
fi

if [[ -z "${ANDROID_SIGNING_CERT_SHA256:-}" ]]; then
  echo "ANDROID_SIGNING_CERT_SHA256 is not set." >&2
  exit 1
fi

normalize_fingerprint() {
  printf '%s' "$1" | tr -cd '[:xdigit:]' | tr '[:lower:]' '[:upper:]'
}

expected_fingerprint="$(normalize_fingerprint "${ANDROID_SIGNING_CERT_SHA256}")"
if [[ ! "${expected_fingerprint}" =~ ^[[:xdigit:]]{64}$ ]]; then
  echo "ANDROID_SIGNING_CERT_SHA256 must be a 64-character SHA-256 fingerprint." >&2
  exit 1
fi

if [[ -n "${APKSIGNER_PATH:-}" ]]; then
  apksigner_path="${APKSIGNER_PATH}"
elif command -v apksigner >/dev/null 2>&1; then
  apksigner_path="$(command -v apksigner)"
else
  android_sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
  if [[ -z "${android_sdk_root}" ]]; then
    echo "Neither apksigner nor an Android SDK root is available." >&2
    exit 1
  fi

  mapfile -t apksigner_candidates < <(
    find "${android_sdk_root}/build-tools" -type f -name apksigner -print | sort -V
  )
  if (( ${#apksigner_candidates[@]} == 0 )); then
    echo "Could not find apksigner in ${android_sdk_root}/build-tools." >&2
    exit 1
  fi
  apksigner_path="${apksigner_candidates[-1]}"
fi

for apk_path in "$@"; do
  if [[ ! -f "${apk_path}" ]]; then
    echo "APK does not exist: ${apk_path}" >&2
    exit 1
  fi

  verification_output="$("${apksigner_path}" verify --verbose --print-certs-pem "${apk_path}")"
  mapfile -t encoded_signer_certificates < <(
    printf '%s\n' "${verification_output}" |
      awk '
        /^[[:space:]]*-----BEGIN CERTIFICATE-----[[:space:]]*$/ {
          reading_certificate = 1
          encoded_certificate = ""
          next
        }
        /^[[:space:]]*-----END CERTIFICATE-----[[:space:]]*$/ {
          if (reading_certificate) {
            print encoded_certificate
          }
          reading_certificate = 0
          next
        }
        reading_certificate {
          gsub(/[[:space:]]/, "")
          encoded_certificate = encoded_certificate $0
        }
      '
  )

  if (( ${#encoded_signer_certificates[@]} == 0 )); then
    echo "Could not extract a signing certificate from ${apk_path}." >&2
    exit 1
  fi

  declare -A unique_signer_fingerprints=()
  for encoded_certificate in "${encoded_signer_certificates[@]}"; do
    certificate_fingerprint="$(
      printf '%s' "${encoded_certificate}" |
        base64 --decode |
        sha256sum |
        awk '{ print $1 }'
    )"
    normalized_fingerprint="$(normalize_fingerprint "${certificate_fingerprint}")"
    if [[ ! "${normalized_fingerprint}" =~ ^[[:xdigit:]]{64}$ ]]; then
      echo "Could not calculate a certificate SHA-256 digest for ${apk_path}." >&2
      exit 1
    fi
    unique_signer_fingerprints["${normalized_fingerprint}"]=1
  done

  if (( ${#unique_signer_fingerprints[@]} != 1 )); then
    echo \
      "Expected exactly one unique signing certificate for ${apk_path}; " \
      "found ${#unique_signer_fingerprints[@]}." >&2
    exit 1
  fi

  actual_fingerprint="${!unique_signer_fingerprints[@]}"
  if [[ "${actual_fingerprint}" != "${expected_fingerprint}" ]]; then
    echo "Unexpected signing certificate for ${apk_path}." >&2
    echo "Expected: ${expected_fingerprint}" >&2
    echo "Actual:   ${actual_fingerprint}" >&2
    exit 1
  fi

  echo "Verified ${apk_path} (${actual_fingerprint})."
done
