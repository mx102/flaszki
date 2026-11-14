---
status: accepted
---

# Level generator: seeded random deal + queue-order solver verify

Each Level must be solvable in Goal Queue order, identical on every device, and generated on-device in < ~200 ms. We generate by **random deal + solver verification with deterministic retries**, not by reverse play. Research (#3) showed 99.4% of random 12-Color deals (capacity 4, 2 empty Flasks) are solvable and verification costs milliseconds; reverse play needs exact inverse-Pour rules, has no prior art for the Goal Queue twist, and biases the distribution.

## Algorithm

`generate(N)`:

1. `params = curve(N)` → `LevelParams { colorCount (≤ 12), flasksPerColor, emptyFlasks, capacity (= 4) }`. The difficulty curve is a separate component.
2. For attempt `i = 0..maxAttempts-1`: seed = SplitMix(`generatorVersion`, `N`, `i`) → xoshiro128**.
   - **Deal**: Fisher–Yates over all Layers into the filled Flasks (all full), plus `emptyFlasks` empty Flasks.
   - **Goal Queue**: Fisher–Yates over the multiset of Colors, one entry per Flask of that Color, from the same stream.
   - **Reject** if any Flask starts as a Completed Flask.
   - **Verify** with the solver under queue rules (only the head Color's Completed Flask is sealed and removed). The solver is capped by **node count**, never wall-clock time; hitting the cap counts as rejection.
3. If every attempt fails: deterministic fallback (one extra empty Flask), which must also verify.

Returns the Level plus difficulty metrics: `B − C` merging Pours, solver nodes expanded, solution length. These are for tuning the curve, not filters.

## Determinism

- Own PRNG: xoshiro128** seeded via SplitMix, Lemire bounded ints, 32-bit integer ops only, no floats (Dart `Random` and JS `Math.random` aren't stable across versions or platforms).
- Fixed iteration order, no hash-map iteration order dependence.
- `generatorVersion` is part of the seed. Golden tests pin Levels 1–100 on Dart VM, AOT and web; any intentional change to generator, curve, PRNG, node cap or retry cap bumps the version.

## Threading

`generate()` is a pure synchronous function in the logic package. Native runs it in an isolate (`compute`); web runs it on the main thread. Add a web worker only if the performance prototype shows a visible hitch.

## Considered Options

- **Reverse play** (scramble from solved via inverse Pours): solvable by construction, but inverse rules are subtle (buggy inverses yield unsolvable levels), no water-sort/queue prior art, distribution skewed toward short scrambles.

## Consequences

- Node cap, retry cap and timings are tuned by the performance prototype; they're part of the versioned algorithm.
- Changing the generator changes Level N; how saved progress handles a version bump is a persistence question.
- The solver is reusable for a Dead End hint if its cost permits.
