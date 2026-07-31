# Android release signing

Every distributable APK must be signed by the same long-lived release key. The
GitHub workflows restore that key from encrypted repository secrets, compare its
public certificate with a pinned SHA-256 fingerprint, build the APKs, and verify
the signature on every output before publishing it.

Release builds intentionally fail when signing values are absent. Pull requests
build a debug APK because GitHub does not expose repository secrets to untrusted
forks.

## One-time setup

Create one keystore on a trusted machine. Do not run this command again for later
releases:

```bash
keytool -genkeypair -v \
  -keystore syncy-release.jks \
  -alias syncy \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000
```

Back up the keystore and both passwords in a password manager or other encrypted
backup. Losing the private key means existing installations cannot update to a
new APK. Never commit the keystore or passwords.

Encode the keystore as a single-line base64 value:

```bash
# Linux/macOS
base64 < syncy-release.jks | tr -d '\n'
```

```powershell
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("syncy-release.jks"))
```

In the GitHub repository, add these Actions secrets under **Settings > Secrets
and variables > Actions**:

| Type | Name | Value |
| --- | --- | --- |
| Secret | `ANDROID_KEYSTORE_BASE64` | The base64 value above |
| Secret | `ANDROID_KEYSTORE_PASSWORD` | The keystore password |
| Secret | `ANDROID_KEY_ALIAS` | The alias, `syncy` in the example |
| Secret | `ANDROID_KEY_PASSWORD` | The private-key password |

Get the certificate fingerprint:

```bash
keytool -list -v \
  -keystore syncy-release.jks \
  -alias syncy
```

Copy the certificate's `SHA256` value into an Actions **repository variable**
named `ANDROID_SIGNING_CERT_SHA256`. Colons and letter case do not matter.

After configuring these values, run the **Flutter Build** workflow manually. It
must restore the key, build the release APK, and print a successful signature
verification before the next `v*` tag is created.

## Local release builds

Set the same four Gradle environment variables before running
`flutter build apk --release`:

- `ANDROID_KEYSTORE_PATH`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Debug builds do not require them.

## Existing installs

Older GitHub releases were signed with a newly generated debug key on each
ephemeral runner. Those private keys cannot be recovered from an APK. Users with
one of those builds must uninstall it once before installing the first APK signed
with the permanent release key. Every release after that will update normally as
long as the keystore and application ID remain unchanged.
