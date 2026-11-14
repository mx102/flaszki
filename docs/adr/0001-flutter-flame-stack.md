---
status: accepted
---

# Flutter + Flame, with game logic in a pure-Dart package

Flaszki is built with Flutter, using Flame and fragment shaders for juicy effects (liquid wobble, splashes, particles). We chose it over Godot 4 because AI agents write most of the code, and pure Dart is text-only and easy to test headless. Logic (generator, solver, Goal Queue) outweighs juice, the maintainer debugs Dart more easily, and Flutter's web payload is smaller. Rules, generator and solver live in a pure-Dart package with no Flutter/Flame imports; the app only renders it.

Targets: Android, iOS, macOS, Windows, Linux, plus web. Web is secondary: online-only, no PWA. Saves live in browser storage, so clearing site data loses progress. Native apps are the offline-first experience.

## Considered Options

- **Godot 4.7**: stronger built-in 2D juice (nodes, Tween, particles), but editor-centric (worse for agents), no built-in test framework, no C# on web, ~5 MB+ web wasm.

## Consequences

- Splash physics and particles take more hand-written code than in Godot.
- No isolates on web: the generator runs on the main thread there. ADR 0002 rules out a web worker and requires the wasm web build, not dart2js.
- Revisit if the generator + solver performance prototype misses the ~200 ms budget by more than 2× on Dart AOT or web.
