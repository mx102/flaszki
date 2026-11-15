# Research: store accounts, fees, and CI builds for 6 targets

Issue: [#14](https://github.com/mx102/flaszki/issues/14). Researched 2026-11-15 against primary sources (official store / vendor docs). Context: free, MIT-licensed Flutter + Flame game, no ads / IAP / accounts / network / analytics; local save only. Repo `mx102/flaszki` is **public**.

Items marked **(unverified)** come from general knowledge, not a page fetched today. Check them before relying on them.

## TL;DR

| Channel | Account cost | Signing | Main hurdles |
|---|---|---|---|
| Google Play | US$25 once | Play App Signing (upload key) | New personal account: closed test with 12 testers for 14 days before production; ID check; Data safety form + privacy policy URL |
| Android outside Play (F-Droid / APK) | Free (F-Droid). Android Developer Console: US$25 full / free limited | F-Droid signs its own builds, or reproducible builds | Android developer verification: enforced in 4 countries from 2026-09-30, globally from 2027 |
| Apple App Store (iOS + macOS) | US$99 / year (individuals get no fee waiver) | Apple certs + provisioning; macOS App Store requires App Sandbox (unverified) | Privacy label + privacy policy URL required; EU DSA trader declaration (non-trader is fine for a free hobby app) |
| macOS direct download | Same US$99/yr membership | Developer ID + notarization (hardened runtime) | No way to notarize without a paid membership |
| Microsoft Store | **Free** (new individual flow, ID + selfie) | Store re-signs MSIX for free | Must start at storedeveloper.microsoft.com |
| Windows direct download | Free to host | Self-signed = SmartScreen warnings; SignPath Foundation (free for OSS, discretionary); Azure Artifact Signing (individuals: US/Canada only) | Code signing is the only real cost and friction |
| Flathub | Free | Flathub builds and signs | Must build from source offline; no prebuilt binaries; MetaInfo; `io.github.mx102.*` app ID |
| Snap Store | Free (unverified: Ubuntu One account) | Store-signed | `plugin: flutter` exists |
| AppImage | Free (GitHub Releases) | Optional | No store, no updates |
| Web | Free (GitHub Pages / Cloudflare Pages / Firebase) | n/a | GitHub Pages can't set COOP/COEP headers, so no multi-threaded Wasm |

**Minimum cash to reach all 6 targets:** US$25 (Play, once) + US$99/yr (Apple). Everything else can be free.

## Android

### Google Play
- One-time **US$25** registration fee. Applicant must be 18+. Google may ask for a government ID and a credit card in the legal name. Owner must verify access to an Android device through the Play Console app. ([Play Console help 6112435](https://support.google.com/googleplay/android-developer/answer/6112435))
- **Personal accounts created after 2023-11-13** must run a closed test with **at least 12 testers opted in for 14 consecutive days** before applying for production access. ([Play Console help 14151465](https://support.google.com/googleplay/android-developer/answer/14151465)) This is the biggest practical hurdle for a solo dev. Plan to recruit testers early.
- The **Data safety form** is required even for apps that collect no data. It needs a **privacy policy link**. The form can declare that no data is collected or shared. ([Play Console help 10787469](https://support.google.com/googleplay/android-developer/answer/10787469))
- Play enforces a yearly target-SDK minimum. (unverified: check the current level when shipping.)

### Android developer verification (affects F-Droid and sideloading too)
- Google requires developers to verify their identity and register package names + signing keys for apps installed on certified Android 7+ devices. ([developer.android.com/developer-verification](https://developer.android.com/developer-verification))
- Timeline:
  - Aug 2026: developer APIs, limited-distribution accounts and the "advanced flow" launch.
  - **2026-09-30**: enforcement for apps from participating stores in Brazil, Indonesia, Singapore and Thailand.
  - **2027+**: global.
- Apps distributed through Play with Play App Signing are **registered automatically**. The Play Console can also register apps distributed outside Play. ([FAQ](https://developer.android.com/developer-verification/guides/faq))
- Apps outside Play only: Android Developer Console. Full Distribution account costs **US$25**. Limited Distribution is free with no ID but reaches only 20 devices. Users can still install unverified apps through a one-time "advanced flow" with a 24 h wait. ADB installs are unaffected. ([FAQ](https://developer.android.com/developer-verification/guides/faq))
- There is a guide for registering open-source apps on an open-source registry. (Linked from the verification page; not read in detail.)
- **Implication:** an F-Droid build signed by F-Droid's key is a different signer from the Play build. Registering it in 2027 is the F-Droid side's concern, unless we ship reproducible builds signed with our own key. Track how this develops.

### F-Droid
- Free. Requirements: all code under a FLOSS license, built from source by F-Droid, no proprietary deps (no Play Services / Firebase), Anti-Features disclosed. ([Inclusion Policy](https://f-droid.org/en/docs/Inclusion_Policy/))
- **Flutter is explicitly allowed:** "The Android SDK, Flutter SDK and Hermes have permission to use official prebuilt binaries until Debian provides alternative solutions." ([Inclusion Policy](https://f-droid.org/en/docs/Inclusion_Policy/))
- **Flaszki is eligible:** MIT code, no network, no proprietary deps. CC BY 4.0 assets are free-culture compatible. Keep `shared_preferences` (Android impl is FLOSS) and avoid any Google-only plugins.
- The reserved name/icon (ADR 0003) does not block inclusion. (unverified: F-Droid accepts trademark-restricted names as long as the code is FLOSS.)

## Apple (iOS + macOS)
- Apple Developer Program costs **US$99/year**. Fee waivers apply only to nonprofits, accredited schools and government entities, **never to individuals or sole proprietors**. ([Fee waivers](https://developer.apple.com/help/account/membership/fee-waivers/))
- A free Apple Account gives only a Personal Team: on-device testing, 7-day profiles, 3 devices, no distribution. ([Compare memberships](https://developer.apple.com/support/compare-memberships/))
- One membership covers the iOS App Store, the Mac App Store and Developer ID (direct macOS download + notarization).
- **Notarization** for macOS outside the store needs a Developer ID Application cert, hardened runtime, `xcrun notarytool submit … --wait`, then `stapler staple`. Requires paid membership. (General Apple docs knowledge; the [notarization page](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution) didn't render for fetch. Unverified detail.)
- **Privacy details (label)** are required for every new app and update. A **privacy policy URL is required**. ([App privacy details](https://developer.apple.com/app-store/app-privacy-details/)) For Flaszki, answer "Data Not Collected". (unverified wording of the option)
- **EU DSA trader status** must be declared even if you don't target the EU. A free hobby app with no revenue can select **non-trader**: no address or phone is published, and EU users are told consumer-law rights don't apply. Declaring as a trader publishes an address (P.O. box allowed), phone and email. ([DSA trader requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements))
- Mac App Store apps must enable App Sandbox. (unverified; standard rule) `shared_preferences` on macOS (NSUserDefaults) works inside the sandbox.

## Windows

### Microsoft Store
- **No registration fee** for Individual or Company accounts via the new flow at <https://storedeveloper.microsoft.com>. Individual accounts need ID + selfie verification. Use that entry point; other paths show the legacy (paid) flow. ([Open a developer account](https://learn.microsoft.com/en-us/windows/apps/publish/partner-center/open-a-developer-account), updated 2026-10-29)
- **MSIX submissions are re-signed by Microsoft for free**, so no CA cert is needed. EXE/MSI submissions must be Authenticode-signed by you and hosted on your own CDN. ([MSIX package requirements](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/app-package-requirements)) **Use MSIX** (the `msix` pub package; unverified tool choice).

### Direct download (GitHub Releases / winget)
- An unsigned or self-signed EXE/MSIX triggers SmartScreen warnings. A sideloaded MSIX must be signed with your own cert. ([MSIX package requirements](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/app-package-requirements))
- **SignPath Foundation:** free code signing for OSS. Requirements:
  - OSI license, no proprietary components
  - project already released and actively maintained
  - MFA for all team members
  - "Code signing policy" section on the homepage
  - manual approval per release
  - verifiable reputation ("we cannot sign binaries based on source code that nobody knows")
  
  Acceptance is discretionary. ([signpath.org](https://signpath.org/), [terms](https://signpath.org/terms)) This is realistic only once Flaszki has some users.
- **Azure Artifact Signing** (formerly Trusted Signing): Public Trust for **individuals only in the US/Canada**. Organizations qualify in the EU and other listed regions. Requires an Azure subscription (paid SKU). ([Quickstart](https://learn.microsoft.com/en-us/azure/artifact-signing/quickstart)) It is not usable by an EU individual.
- **Pragmatic path:** Microsoft Store (free, signed) as the primary Windows channel. Unsigned zip on GitHub Releases as a fallback, with a SmartScreen note. Apply to SignPath later.

## Linux

### Flathub
- Free. Rules:
  - must build **entirely from source**, with no network during the build
  - every dependency declared as a manifest source
  - **no prebuilt binaries in the submission PR**
  - a valid MetaInfo file, a desktop file and a 256px+ / SVG icon
  - app ID in reverse-DNS with a code-host prefix, e.g. `io.github.mx102.flaszki`
  
  ([Flathub requirements](https://docs.flathub.org/docs/for-app-authors/requirements))
- Flutter offline builds are solved by community tools: **flatpak-flutter** (snapshots the Flutter SDK, generates pub-cache sources from `pubspec.lock`) and **flutpak** (pub.dev). ([Flathub discourse](https://discourse.flathub.org/t/to-all-publishers-of-flutter-apps-lets-build-from-source/8682), [flutpak](https://pub.dev/packages/flutpak))

### Snap Store
- Snapcraft has a first-class `plugin: flutter` (`flutter-target: lib/main.dart`). The example uses `base: core22` and `extensions: [gnome]`. ([Snapcraft: craft a Flutter app](https://ubuntu.com/docs/snapcraft/stable/how-to/integrations/craft-a-flutter-app/))
- Publishing is free with an Ubuntu One account. (unverified; the docs page did not state fees)

### AppImage
- There is no store and no fee. Attach it to GitHub Releases. (unverified: tooling such as `appimagetool` / `linuxdeploy`)

## Web
- Flutter docs list **Firebase Hosting, GitHub Pages, Google Cloud** as hosts. Release builds target Wasm with a JS fallback. **Multi-threaded Wasm needs `Cross-Origin-Opener-Policy: same-origin` + `Cross-Origin-Embedder-Policy: credentialless|require-corp`** headers. ([Flutter web deployment](https://docs.flutter.dev/deployment/web))
- **GitHub Pages:** free for public repos, 1 GB site, 100 GB/month soft bandwidth, no commercial use (Flaszki is non-commercial, fine). Needs `--base-href /flaszki/` for a project site. ([Pages limits](https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits)) GitHub Pages cannot set custom response headers, so no COOP/COEP; Wasm then runs single-threaded or falls back to JS. (unverified, widely known)
- **Cloudflare Pages:** free plan has 500 builds/month, 20,000 files, 25 MiB per file, and custom headers via a `_headers` file (100 rules). ([Pages limits](https://developers.cloudflare.com/pages/platform/limits/)) Pick this if COOP/COEP matters.
- Firebase Hosting also supports headers through `firebase.json`. Exclude `*.map` source maps. ([Flutter web deployment](https://docs.flutter.dev/deployment/web))

## CI: building and signing all 6 targets

### GitHub Actions (recommended)
- **Standard GitHub-hosted runners are free and unlimited for public repositories.** ([Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions), [runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners))
- Labels available today:
  - `ubuntu-latest` / `ubuntu-24.04-arm`: Android, Linux x64/arm64, web, Flatpak/Snap test builds
  - `windows-latest` / `windows-11-arm`: Windows x64/arm64, MSIX
  - `macos-latest` / `macos-26` (M1): iOS, macOS
  
  ([runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners))
- If the repo ever goes private, the Free plan gives US$12/month of compute. That is about 2,000 Linux minutes, but macOS costs about 10× per minute (US$0.062/min), so roughly 190 macOS minutes. ([Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions))
- Signing secrets stored in Actions secrets:
  - Android upload keystore (base64)
  - Apple: distribution cert + App Store Connect API key (iOS/Mac App Store); Developer ID cert + notarytool credentials (macOS direct)
  - Windows: none for the Store MSIX; SignPath GitHub integration later
  - Flathub / F-Droid: build and sign on their own infrastructure from our tagged source, so no secrets

  (Secret handling details unverified; standard practice.)
- Store upload automation such as fastlane or `msstore` CLI is optional. (unverified)

### Alternatives
- **Codemagic** free individual plan: 500 min/month on a Mac mini M2, 1 concurrent build, no specific OSS plan. ([Codemagic pricing](https://codemagic.io/pricing/)) It's only useful if the repo goes private or GitHub's macOS queue is slow.

## Dependency license checking (Dart/Flutter)
- **`very_good packages check licenses`** (Very Good CLI ≥ 0.17.0) supports `--allowed` / `--forbidden` lists, has a CI-friendly GitHub workflow, and reads pub.dev's PANA-declared licenses. ([VGV blog](https://verygood.ventures/blog/very-good-cli-license-checker/))
- **`legal`** (pub.dev) sets the policy in pubspec, has `check` / `generate` commands, and works offline on resolved packages. ([pub.dev/packages/legal](https://pub.dev/packages/legal))
- **`license_checker`** (YAML allow/deny config), **`dart_license_checker`** (lists direct or transitive deps). ([license_checker](https://pub.dev/packages/license_checker), [dart_license_checker](https://pub.dev/packages/dart_license_checker))
- For in-app attribution (MIT/BSD/CC BY notices): use Flutter's built-in `LicenseRegistry` / `showLicensePage`. (unverified; standard Flutter API) Alternatively, generate a file with `flutter_oss_manager` or `dart_oss_licenses`. ([flutter_oss_manager](https://pub.dev/packages/flutter_oss_manager))

## Open questions / follow-ups
- A privacy policy URL is required by both Play and Apple. Host a one-paragraph "collects no data" page on the web build's host.
- Recruiting 12 Play closed-testers for 14 days needs a plan.
- Android developer verification for the F-Droid build in 2027 (signer identity).
- Whether SignPath will accept Flaszki before it has reputation.
