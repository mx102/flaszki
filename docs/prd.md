# Flaszki PRD

Status: **accepted**, reviewed in [Assemble the PRD](https://github.com/mx102/flaszki/issues/18).
Vocabulary: [`GLOSSARY.md`](../GLOSSARY.md). Decisions: [`docs/adr/`](adr/), map [Map: Flaszki game spec](https://github.com/mx102/flaszki/issues/1).

## 1. Summary

Flaszki is a free, open-source fluid-sorting puzzle game. The player Pours Layers of Color between Flasks to build Completed Flasks, in the order set by a **Goal Queue**. Levels are endless, numbered, generated on-device and always solvable in queue order.

Targets: Android, iOS, macOS, Windows, Linux (native, offline) and web (secondary, online-only). Launch on Google Play only (ADR 0007).

### Goals

- A calm, juicy puzzle with one twist over the genre: the Goal Queue.
- Every Level solvable; no lose screen; unlimited Undo.
- Fully free: no ads, no IAP, no accounts, no data collection.
- Codebase easy for AI agents and one maintainer: pure-Dart logic, headless tests.

### Non-goals

See [§13 Out of scope](#13-out-of-scope).

## 2. Game rules

- A Level is a set of Flasks (uniform capacity 4) and a Goal Queue. At most 12 Colors.
- **Pour**: player picks a source and a target Flask. Moves all contiguous same-Color top Layers of the source that fit into the target. Legal only if the target is empty, or its top Layer has the same Color and it has free space.
- **Completed Flask**: full Flask of one Color.
  - If its Color is the Goal Queue head: it is **sealed and removed**, the queue advances. The board shrinks; no replacement Flask.
  - Otherwise it **waits** on the board. It can still be poured out of.
  - After every advance, if the new head's Color already has a waiting Completed Flask, that one seals too (cascade).
- Colors may repeat in the Goal Queue (one entry per Flask of that Color).
- **Solved**: Goal Queue empty.
- **Dead End**: no way to Solve from the current state. Not a loss.
- **Undo**: unlimited, back to the Level start. Reverts the last Pour including any seals it caused (sealed Flasks return to the board, Goal Queue steps back).
- **Restart**: back to the Level's initial state; Undo history is cleared.

## 3. Levels

### 3.1 Generator (ADR 0002)

- `generate(N)` is a pure, synchronous, deterministic function in the logic package.
- `curve(N)` → `LevelParams { colorCount ≤ 12, flasksPerColor, emptyFlasks, capacity = 4 }`.
- Up to 10 attempts; seed = SplitMix(`generatorVersion`, N, attempt) → xoshiro128**. Lemire bounded ints, 32-bit integer ops only, no floats.
  - Deal: Fisher–Yates over all Layers into full Flasks, plus empty Flasks.
  - Goal Queue: Fisher–Yates over the Color multiset, same stream.
  - Reject any deal starting with a Completed Flask.
  - Verify with the queue-order solver, `nodeCap = 50 000` nodes; cap hit = reject.
- All attempts fail → deterministic fallback with one extra empty Flask, also verified.
- Solver: DFS with move ordering and pruning; visited set = order-independent 52-bit hash in `Set<int>`.
- Returns Level + metrics (B − C, nodes, solution length) for offline tuning only.
- `generatorVersion` bumps on any change to generator, curve, PRNG, caps. Independent of app version.
- Level N+1 is pre-generated as soon as Level N starts: isolate on native, main thread on web (no web worker). Web build is `--wasm`; browsers without the required Wasm features run the bundled dart2js fallback.

### 3.2 Difficulty curve (ADR 0004)

- Always 2 empty Flasks (3 only via fallback). Board ≤ 16 Flasks (17 only via fallback: 7×2 + 3 empty).
- Levels 1–40, ×1: 3 Colors L1–3, +1 Color every 4 Levels, 12 Colors L36–40.
- Breather when `N % 5 == 0`: `ramp(max(1, N − 8))` up to L40, then 8×1.
- From L41: `[12×1, 10×1, 7×2, 11×1, 12×1, 6×2][(N − 41) mod 6]`; Breathers take priority.
- No tutorial; Level 1 (3×1) teaches by play.
- Dev script reports metrics for Levels 1–500. Not run in CI.

## 4. Screen and interaction

### 4.0 Launch

- The app opens straight into the current Level (resumed from the save). No title screen or menu.

### 4.1 Layout (ADR 0006)

- Portrait only on every target. Phones/tablets locked to portrait; desktop/web show a centred portrait column with background at the sides.
- Top: Goal Queue strip (~64 px). Middle: board. Bottom bar (~60 px), see [§4.6](#46-bottom-bar-and-settings).
- **Auto grid**: for the Level's starting Flask count, pick the column count giving the largest Layer height (ties → fewer rows). Rows fill top to bottom; short last row centred. Flask size fixed for the whole Level.
- Min Layer height 15 logical px. Tap target = whole grid cell.

### 4.2 Pour input

- Tap-tap only, no drag. Tap a Flask → it lifts (selected). Tap a target → Pour.
- Tap the selected Flask again or empty board → deselect.
- Invalid target → it shakes; selection moves to it (if not empty).
- Input is **never** blocked by animations: they finish early or play alongside.
- **Undo** across a seal: quick reverse reflow (sealed Flask reappears in its cell, Goal Queue steps back) + Undo swish. No reverse fly-in.
- **Back / Esc**: closes the Settings sheet, else deselects a selected Flask; otherwise Android Back leaves the app (system default) and Esc does nothing.

### 4.3 Goal Queue

- Head shown as a large NEXT orb; next 3 as small orbs; `+N` for the rest.
- Seal: cork drops in, Flask flies on an arc into the NEXT orb (shrinks, fades), orb pops, queue advances; remaining Flasks reflow (animated) into a tighter grid at the same Flask size.
- Waiting Completed Flask: hovering cork + badge with its queue position (`#2`..`#4`, `…` if further).

### 4.4 Dead End hint

- After every Pour, run the queue-order solver on the current state. Show only on a **proven** Dead End; cap hit = unknown = no hint. Uses an exact visited key (or verifies hash hits), so no false positives.
- Native: isolate. Web: main thread, after 1 s without input. Stale results (state changed) are dropped. Shown after the Pour/seal animation ends.
- Non-modal banner "No way to finish from here" with inline Undo + Restart (this Restart needs no confirm). Board stays playable. Disappears when the state is no longer a Dead End.
- Always on; silent; no penalty or stats.

### 4.5 Solved

- Solved chime (~1.5 s); Solved overlay with "Solved" in serif italic. Level Number++ and save immediately.
- Overlay advances to Level N+1 on a tap anywhere, or by itself after ~2 s. N+1 is pre-generated, so the swap is instant.

### 4.6 Bottom bar and Settings

- Bottom bar: **Undo**, **Restart**, "Level N" label (serif italic), **gear**.
- **Restart** needs a second tap: first tap arms the button (~2 s, visibly), second tap restarts. No modal.
- Gear opens a Settings sheet:
  - Colorblind patterns (default off)
  - Sound (default on)
  - Credits and licenses (`CREDITS.md` + Flutter license page)
  - Privacy (link to `PRIVACY.md` on the Pages site)
  - App version

### 4.7 Localization

- English + Polish at launch, via Flutter `intl`, following the system locale (fallback English). More languages later via community PRs.

## 5. Visual style (Prototype visual style and pour feel)

- **Style A, apothecary glass**. Night-blue vertical gradient `#1a2f4d` → `#0a1220`, radial vignette, faint shelf line under each board row.
- **Flask**: tall glass tube (~3:1), flared lip, round bottom, thin pale-blue outline, faint glass fill, two vertical specular streaks over the fluid.
- **Fluid**: per-Layer horizontal gradient (darker edges), meniscus highlight on top, same-Color neighbours merge into one band, surface stays level when tilted.
- **Goal Queue**: glass orbs with radial gradient + highlight; small-caps serif "NEXT".
- **Pour juice** (always on, no setting): source lifts, moves beside target, tilts (more as it empties); curved stream with light core; splash droplets; target surface wobble (decaying sine); bubbles. Timing ≈ 0.26 s move + (0.14 + 0.11 × Layers) s pour + 0.24 s return.
- **Type**: serif italic for Level label and "Solved".
- **Icon**: one tilted glass tube with 3–4 Layers on the night-blue gradient, rounded square; readable at 40 px.
- Must not copy any specific title's tube art, background or UI chrome.
- Canvas drawing, gradients, simple particles; fragment shaders optional.

### 5.1 Palette and colorblind patterns (Prototype 12-color palette with colorblind symbols)

Color ids are stable across versions (ADR 0005).

| id | Color | hex | pattern |
|---|---|---|---|
| 0 | red | `#e6194b` | none |
| 1 | green | `#3cb44b` | horizontal stripes |
| 2 | yellow | `#ffe119` | vertical stripes |
| 3 | blue | `#4363d8` | diagonal |
| 4 | orange | `#f58231` | dots |
| 5 | purple | `#911eb4` | checks |
| 6 | cyan | `#42d4f4` | zigzag |
| 7 | magenta | `#f032e6` | grid |
| 8 | lime | `#9ad61e` | crosshatch |
| 9 | pink | `#fabed4` | rings |
| 10 | brown | `#9a6324` | back-diagonal |
| 11 | white | `#f4f4f4` | big dot |

- Pattern drawn in black or white, whichever contrasts. Applied to every Layer and the Goal Queue orbs when the colorblind option is on.
- Hue alone fails for color-vision deficiency, so the option is required, not cosmetic.

## 6. Audio (Decide audio)

| event | sound |
|---|---|
| Select | soft glass clink |
| Pour | liquid glug + splash; length scales with Layers; pitch rises as target fills |
| Invalid tap | dull muted tap |
| Seal | cork pop |
| Goal Queue advance | orb chime |
| Waiting Completed Flask appears | quiet cork squeak |
| Solved | chime arpeggio ~1.5 s |
| Undo | soft reverse swish |
| Dead End hint, Restart | silent |

- ±5% pitch/volume jitter; 2–3 variants for clink, glug, cork.
- No music at launch. No haptics.
- Single Sound toggle, default on; system volume.
- Mix with other apps, never duck (iOS `ambient`, respects silent switch). Web unlocks on first tap. Mute when backgrounded.
- OGG on every target via `flutter_soloud`, behind a small audio interface.
- Assets CC0 first, else own recordings CC BY 4.0; no NC licenses; all credited in `CREDITS.md`.

## 7. Save (ADR 0005)

- `shared_preferences` on all targets (web: localStorage). Three JSON keys, each with `schemaVersion`:
  - `progress` {levelNumber}
  - `level` {levelNumber, snapshot (initial Flasks + Goal Queue), pours}; discarded if levelNumber ≠ `progress`.
  - `settings` {colorblindPatterns, sound, music (reserved), haptics (reserved)}
- Written after every Pour, Undo, Restart and on Solved. Not reliant on pause/close events. Pre-generated N+1 not saved.
- Resume: rebuild by replaying pours over the snapshot; exact board, queue position and Undo history.
- After a `generatorVersion` bump: keep Level Number; in-progress Level finishes from its snapshot; next Level from the new generator.
- Missing → new player. Corrupt (or newer `schemaVersion`) → per-key fallback, logged only, no crash or modal. Forward-only migrations.
- Web storage wipes accepted silently.

## 8. Architecture (ADR 0001)

- Flutter + Flame; fragment shaders optional.
- **Logic package** (pure Dart, no Flutter/Flame imports): rules, Pour, Goal Queue, generator, curve, solver, Dead End check, save model/serialisation.
- **App**: rendering, input, animation, audio, persistence I/O, threading.
- Web: `flutter build web --wasm` (wasm + bundled dart2js fallback), cross-origin isolated via COOP/COEP. `wasmAllowList: { gecko: true, webkit: true }` so Firefox and Safari use wasm when supported; otherwise dart2js.

## 9. Platforms and distribution (ADR 0007)

- App ID `com.mx102.flaszki` on every store.
- Minimum OS versions: Flutter defaults (stricter only where a dependency requires it).

- Launch: Google Play only (personal account; closed test 12 testers × 14 days first).
- Then, one at a time: web announce → iOS + Mac App Store → Microsoft Store → Flathub → F-Droid.
- Web on Cloudflare Pages (`flaszki.pages.dev`), deployed on every push to `main` from day 1.
- No Snap, no direct Windows/macOS downloads.

## 10. Privacy and licensing (ADR 0003, 0007)

- Nothing collected: no analytics, no crash SDK. `PRIVACY.md` served on the Pages site.
- Code MIT (`Copyright (c) 2026 Michał Dratkowski`). Original assets CC BY 4.0. Third-party assets CC0 / CC BY / OFL, credited in `CREDITS.md`.
- Name "Flaszki" and the icon reserved (README trademark note).
- Dependencies permissive only (MIT, BSD, Apache-2.0, zlib, ISC); CI enforces.
- Contributions inbound=outbound; no CLA/DCO.

## 11. CI and release (ADR 0007)

- **PR checks** (Linux): `dart format --set-exit-if-changed`, `flutter analyze`, logic unit tests, generator golden tests (VM, wasm and dart2js; AOT nightly or at release), license check (`very_good packages check licenses`), smoke builds web (wasm) + Android APK.
- **Weekly**: unsigned build matrix for all 6 targets.
- **Release**: `vX.Y.Z` tag matching `pubspec.yaml`; build number = run number; `release` environment with manual approval holds signing secrets; uploads to Play internal track + signed APK on GitHub Release. Production promotion manual.

## 12. Acceptance criteria

- Golden tests pin Levels 1–100 identical on VM, AOT, wasm, dart2js.
- Every generated Level is solvable in queue order (solver-verified).
- Generation for any Level < ~200 ms on a low-end phone; hidden by pre-generation.
- 16 Flasks fit on 320×568 with Layers ≥ 15 px.
- Kill app mid-Level → relaunch restores exact board and Undo history.
- Corrupt any save key → app starts, falls back per key.
- No input blocked by animation.
- Dead End banner never shown on a solvable state.

## 13. Out of scope

- Ads, IAP, accounts/cloud sync, leaderboards, extra-Flask helper, level editor, multiplayer, daily challenge, level select/replay.
- Snap, direct Windows/macOS downloads.
- Offline web (PWA / service worker).
- Haptics, music.
- Accessibility beyond colorblind patterns (screen reader etc.).
- Telemetry/analytics.
