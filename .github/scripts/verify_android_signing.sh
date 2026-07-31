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

if command -v apksigner >/dev/null 2>&1; then
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

  verification_output="$("${apksigner_path}" verify --verbose --print-certs "${apk_path}")"
  mapfile -t reported_signer_fingerprints < <(
    printf '%s\n' "${verification_output}" |
      sed -nE \
        's/^[[:space:]]*Signer (#[0-9]+|\([^)]*\)) certificate SHA-256 digest:[[:space:]]*//p'
  )

  if (( ${#reported_signer_fingerprints[@]} == 0 )); then
    echo "Could not parse a signing certificate SHA-256 digest for ${apk_path}." >&2
    exit 1
  fi

  declare -A unique_signer_fingerprints=()
  for reported_fingerprint in "${reported_signer_fingerprints[@]}"; do
    normalized_fingerprint="$(normalize_fingerprint "${reported_fingerprint}")"
    if [[ ! "${normalized_fingerprint}" =~ ^[[:xdigit:]]{64}$ ]]; then
      echo "apksigner reported an invalid SHA-256 certificate digest for ${apk_path}." >&2
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
