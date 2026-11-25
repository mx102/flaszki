# Google Play listing

Listing for `com.mx102.flaszki` (#32, PRD §9–10, ADR 0007). Source of truth is
[`fastlane/metadata/android/`](../fastlane/metadata/android/) (fastlane
`supply` layout; F-Droid reads the same layout later). Paste or upload it into
Play Console → Grow → Store presence → Main store listing; add **Polish
(pl-PL)** as a translation next to the default **English (en-US)**.

| File | Play field | Limit |
|---|---|---|
| `title.txt` | App name | 30 |
| `short_description.txt` | Short description | 80 |
| `full_description.txt` | Full description | 4000 |
| `images/icon.png` | App icon | 512×512 |
| `images/featureGraphic.png` | Feature graphic | 1024×500 |
| `images/phoneScreenshots/*.png` | Phone screenshots | 2–8, 1080×1920 |
| `changelogs/default.txt` | Release notes | 500 |

`test/tool/store_listing_test.dart` checks the limits and sizes.
Regenerate the graphics (real app, fixed levels and states, both locales):

```sh
flutter test tool/render_store.dart
```

## App content (Play Console → Policy → App content)

- **Privacy policy**: `https://flaszki.pages.dev/PRIVACY.md` (also
  `/privacy`, a redirect). Same URL as Settings → Privacy.
- **Ads**: No.
- **App access**: All functionality available without special access.
- **Data safety**:
  - Does your app collect or share any of the required user data types? **No.**
  - That ends the form: no data types, so no encryption/deletion questions.
  - Play's own Android vitals (crash/ANR stats) are Google's, not declared by
    the developer.
- **Content rating** (IARC questionnaire): category **Game → Puzzle**; answer
  No to violence, fear, sexuality, language, controlled substances, gambling,
  user interaction/chat, sharing location, digital purchases. Expected result:
  PEGI 3 / ESRB Everyone.
- **Target audience**: 13+ age groups. Choosing under-13 is possible (no ads,
  no data) but enrolls the app in the Families policy review; decide before
  the first production release.
- **News app**: No. **Government app**: No. **Financial features**: None.
  **Health**: None.

## Store settings

- **Category**: Game → Puzzle. **Tags**: up to 5 from Play's list (e.g.
  Puzzle, Casual, Offline, Logic).
- **Contact details**: maintainer email (required); website
  `https://github.com/mx102/flaszki`.
- **Pricing**: Free; all countries.
