# Direct update protocol

Syncy's sideloaded Android and portable Windows builds use GitHub Releases as
the release authority. Store-installed Android builds defer to their store.

Every tagged release must include `syncy-update-v1.json`:

```json
{
  "protocol": 1,
  "version": "1.2.0",
  "platforms": {
    "android": {
      "asset": "app-universal.apk",
      "sha256": "<64 lowercase hex characters>",
      "size": 123
    },
    "windows": {
      "asset": "syncy-windows-release.zip",
      "sha256": "<64 lowercase hex characters>",
      "size": 456
    }
  }
}
```

The release workflow generates this file from the final artifacts. It also
rejects tags that do not exactly match the version in `pubspec.yaml`.

The client accepts a direct update only when the release version is newer, the
expected platform asset exists, and the manifest's asset name and byte length
match GitHub's metadata. After download, Syncy recalculates SHA-256 from the
file before any installer or updater is launched. Historical releases without
a compatible manifest remain available through the browser but are never
treated as safe for unattended installation.

On Android, Syncy shares the verified APK through a private `FileProvider` and
opens Android's package installer. Android enforces the existing application's
signing identity. If install-source permission is disabled, Syncy opens the
per-app permission screen and resumes the installer when the user returns.

On Windows, Syncy validates and extracts the portable ZIP into a temporary
staging directory. A detached helper waits for the running process to exit,
moves the current installation to a backup, moves the staged build into place,
and relaunches Syncy. If the new process exits during its startup window, the
helper restores and relaunches the previous build.
