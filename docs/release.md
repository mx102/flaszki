# Release

Workflows (PRD §11, ADR 0007):

- `ci.yml`: PR checks. `golden-aot.yml`: nightly AOT golden levels. `weekly.yml`: unsigned 6-target build matrix (Mon).
- `release.yml`: on `vX.Y.Z` tag. Tag must equal `version:` in `pubspec.yaml` (`dart run tool/release_version.dart vX.Y.Z`); build number = run number. Signed AAB → Play internal track; signed APK → GitHub Release. Promote to production manually in Play Console.
- Dry run: Actions → Release → Run workflow, `tag` = current `vX.Y.Z`, `dry_run` on. Builds + verifies signed AAB/APK, keeps them as workflow artifacts only.

## One-time setup (human)

1. **GitHub environment** `release` (Settings → Environments): add yourself as required reviewer. Add these environment secrets:

   | Secret | Value |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | `base64 -i upload.jks` (single line) |
   | `ANDROID_KEYSTORE_PASSWORD` | keystore password |
   | `ANDROID_KEY_ALIAS` | `upload` (alias used below) |
   | `ANDROID_KEY_PASSWORD` | key password (same as store password for PKCS12) |
   | `PLAY_SERVICE_ACCOUNT_JSON` | full JSON key of the Play service account |

2. **Upload key**: `keytool -genkeypair -v -keystore upload.jks -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias upload`. Back it up offline; never commit. Use Play App Signing (Google holds the app signing key; this is the upload key).
3. **Play service account**: Google Cloud Console → create project + service account → JSON key; enable "Google Play Android Developer API". Play Console → Users and permissions → invite the service account email, grant release rights for Flaszki.
4. **First upload is manual**: create the app `com.mx102.flaszki` in Play Console and upload the first AAB by hand (e.g. from a dry-run artifact); the API cannot create apps.
5. While the app is still a draft in Play, set repo variable `PLAY_RELEASE_STATUS=draft` (Settings → Variables); delete it once the app is published.

## Local signed build

Either export `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, or create gitignored `android/key.properties`:

```properties
storeFile=/absolute/path/upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Without either, release builds are signed with the debug key (fine for dev/weekly builds).
