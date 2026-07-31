#!/usr/bin/env bash
set -euo pipefail

required_variables=(
  ANDROID_KEYSTORE_BASE64
  ANDROID_KEYSTORE_PASSWORD
  ANDROID_KEY_ALIAS
  ANDROID_KEY_PASSWORD
  ANDROID_SIGNING_CERT_SHA256
)

missing_variables=()
for variable_name in "${required_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    missing_variables+=("${variable_name}")
  fi
done

if (( ${#missing_variables[@]} > 0 )); then
  printf 'Missing Android signing secret/variable(s): %s\n' "${missing_variables[*]}" >&2
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

keystore_path="${RUNNER_TEMP:?RUNNER_TEMP is not set}/syncy-release.jks"
if ! printf '%s' "${ANDROID_KEYSTORE_BASE64}" | base64 --decode > "${keystore_path}"; then
  rm -f "${keystore_path}"
  echo "ANDROID_KEYSTORE_BASE64 is not valid base64." >&2
  exit 1
fi
chmod 600 "${keystore_path}"

certificate_output="$(
  keytool \
    -exportcert \
    -rfc \
    -keystore "${keystore_path}" \
    -alias "${ANDROID_KEY_ALIAS}" \
    -storepass "${ANDROID_KEYSTORE_PASSWORD}" |
    openssl x509 -noout -fingerprint -sha256
)"
actual_fingerprint="$(normalize_fingerprint "${certificate_output##*=}")"

if [[ "${actual_fingerprint}" != "${expected_fingerprint}" ]]; then
  rm -f "${keystore_path}"
  echo "The restored keystore does not match ANDROID_SIGNING_CERT_SHA256." >&2
  echo "Expected: ${expected_fingerprint}" >&2
  echo "Actual:   ${actual_fingerprint}" >&2
  exit 1
fi

{
  printf 'ANDROID_KEYSTORE_PATH=%s\n' "${keystore_path}"
  printf 'ANDROID_KEYSTORE_PASSWORD=%s\n' "${ANDROID_KEYSTORE_PASSWORD}"
  printf 'ANDROID_KEY_ALIAS=%s\n' "${ANDROID_KEY_ALIAS}"
  printf 'ANDROID_KEY_PASSWORD=%s\n' "${ANDROID_KEY_PASSWORD}"
  printf 'ANDROID_SIGNING_CERT_SHA256=%s\n' "${expected_fingerprint}"
} >> "${GITHUB_ENV:?GITHUB_ENV is not set}"

echo "Restored Android release keystore with certificate SHA-256 ${expected_fingerprint}."
