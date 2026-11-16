---
status: accepted
---

# Launch on Google Play only; GitHub Actions CI; web on Cloudflare Pages

Flaszki launches on **Google Play only**. Other channels open one at a time once the previous one is stable, with no dates: web announce → iOS + Mac App Store → Microsoft Store → Flathub → F-Droid. Snap is skipped because Flathub covers Linux. There are no direct Windows or macOS downloads, which avoids SmartScreen, SignPath and a notarization pipeline. One channel first keeps cost (US$25 once) and release work small for a solo maintainer.

- **Accounts**: personal accounts in the maintainer's name. Each is paid for and verified only when its channel opens; the Apple account (US$99/yr) waits for iOS. On Apple, declare non-trader status under the EU DSA. A personal Play account must run a closed test with 12 testers for 14 days before the first production release.
- **Web**: Cloudflare Pages at `flaszki.pages.dev`, with COOP/COEP set in `_headers`, so the wasm build from ADR 0002 runs cross-origin isolated. Every push to `main` deploys from day 1, unannounced. Web "launch" means only announcing it.
- **Privacy**: nothing is collected: no analytics and no crash-reporting SDK. We rely only on the stores' own crash stats. `PRIVACY.md` is served on the Pages site, and that URL is given to the stores.
- **PR checks** (GitHub Actions, Linux): `dart format --set-exit-if-changed`, `flutter analyze`, unit tests for the logic package, generator golden tests on VM, wasm and dart2js (AOT nightly or at release), the dependency license check (`very_good packages check licenses`, allowing MIT, BSD-2/3, Apache-2.0, Zlib and ISC; native CocoaPods and Gradle deps are not covered), and smoke builds of web (wasm) and the Android APK.
- **Weekly**: an unsigned build matrix for all 6 targets keeps channels that haven't opened yet compiling.
- **Release**: pushing a `vX.Y.Z` tag that matches `pubspec.yaml` triggers the release workflow; the build number is the GitHub run number. Its jobs run in a `release` environment that needs manual approval, and they hold the signing secrets. At launch the workflow uploads to the Play internal track and attaches a signed APK to a GitHub Release. Production promotion stays manual in the Play console. Each later channel adds its upload job when it opens: fastlane with an App Store Connect API key for TestFlight and the Mac App Store, the `msstore` CLI for the Microsoft Store, the AppImage on GitHub Releases, and a manual manifest PR for Flathub.
- `generatorVersion` (ADR 0002) is independent of the app version.

## Considered Options

- **All stores at launch**: more reach, but US$99/yr up front and five release pipelines to keep working before there are any players.
- **GitHub Pages for web**: free, but it can't set COOP/COEP, so Flutter could fall back off the wasm path.
- **Play organization account**: avoids the 12-tester closed test, but needs a D-U-N-S number.
