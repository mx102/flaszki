# Flaszki

A free, open-source fluid-sorting puzzle game. Pour Layers of Color between
Flasks to build Completed Flasks in the order set by the Goal Queue. Levels are
endless, generated on-device and always solvable.

Spec: [`docs/prd.md`](docs/prd.md), [`GLOSSARY.md`](GLOSSARY.md), [`docs/adr/`](docs/adr/).

## Layout

- `/` — Flutter app (Flame): rendering, input, animation, audio, persistence I/O.
- `packages/flaszki_logic/` — pure-Dart logic (no Flutter/Flame imports): rules,
  generator, solver, save model.

Pub workspace: run `flutter pub get` once at the root.

## Checks

```sh
dart format --set-exit-if-changed .
flutter analyze
(cd packages/flaszki_logic && dart test)
flutter test
very_good packages check licenses --dependency-type direct-main,transitive \
  --allowed MIT,BSD-2-Clause,BSD-3-Clause,Apache-2.0,Zlib,ISC
flutter build web --wasm
flutter build apk --debug
```

## License

- Code: [MIT](LICENSE).
- Original art, sounds and other assets: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
- Third-party assets: see [`CREDITS.md`](CREDITS.md).
- Contributions are accepted inbound=outbound under these licenses; no CLA or DCO.

## Trademark

The name "Flaszki" and the Flaszki app icon are **not** covered by the licenses
above. The icon is all rights reserved. You may fork the code, but please ship
your fork under a different name and icon.

## Privacy

Flaszki collects nothing. See [`PRIVACY.md`](PRIVACY.md).
