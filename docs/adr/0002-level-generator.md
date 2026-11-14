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
   - **Verify** with the solver under queue rules (only the head Color's Completed Flask is sealed and removed). The solver is capped by **node count** (`nodeCap = 50 000` states), never wall-clock time; hitting the cap counts as rejection.
3. `maxAttempts = 10`. If every attempt fails: deterministic fallback (one extra empty Flask), which must also verify.

## Solver

- Depth-first search with move ordering (completing the head Color first, then same-Color Pours, then into an empty Flask), pruning pointless Pours (out of a Completed Flask, single-Color Flask into empty, more than one empty target).
- Visited set keyed by an **order-independent 52-bit hash** of the state (sum of mixed per-Flask codes + queue position), stored as `Set<int>`: no sort, no Strings. Integer math stays below 2^53, so it's identical on VM, AOT, dart2js and wasm. A collision can only cause a false "visited", so a solvable deal may be rejected but an unsolvable Level is never accepted.

Returns the Level plus difficulty metrics: `B − C` merging Pours, solver nodes expanded, solution length. These are for tuning the curve, not filters.

## Determinism

- Own PRNG: xoshiro128** seeded via SplitMix, Lemire bounded ints, 32-bit integer ops only, no floats (Dart `Random` and JS `Math.random` aren't stable across versions or platforms).
- Fixed iteration order, no hash-map iteration order dependence.
- `generatorVersion` is part of the seed. Golden tests pin Levels 1–100 on Dart VM, AOT and web; any intentional change to generator, curve, PRNG, node cap or retry cap bumps the version.

## Threading

`generate()` is a pure synchronous function in the logic package. **Level N+1 is generated in the background as soon as Level N starts**, so its latency is hidden. Native runs it in an isolate (`compute`). Web runs it on the main thread, **no web worker**, and the web build **must be wasm** (dart2wasm), not dart2js.

Measured in the performance prototype (#6) on an Apple M4, Levels 1–200, with the hash key:

| config | AOT p95 / max | wasm p95 / max | dart2js p95 / max |
|---|---|---|---|
| 12 Colors × 1, 2 empty | 1.3 / 4.7 ms | 1.6 / 5.9 ms | 10 / 39 ms |
| 12 Colors × 2, 2 empty | 5.2 / 37 ms | 6.8 / 49 ms | 53 / 444 ms |

Low-end phones are estimated 10–20× slower (worst case ~0.4–0.75 s at 12 Colors × 2), which pre-generation in an isolate hides. dart2js is too slow on its 53-bit double math to run on the main thread. Level hashes matched across AOT, dart2js and wasm. Code and full tables: branch `prototype/generator-perf`.

## Considered Options

- **Reverse play** (scramble from solved via inverse Pours): solvable by construction, but inverse rules are subtle (buggy inverses yield unsolvable levels), no water-sort/queue prior art, distribution skewed toward short scrambles.

## Consequences

- Node cap and retry cap are part of the versioned algorithm. At `nodeCap = 50 000`, no Level failed and none needed more than 2 attempts.
- The difficulty curve must give at least 2 empty Flasks at 12 Colors × 1. With 1 empty, only 3 of ~5 950 deals are solvable in queue order.
- Changing the generator changes Level N; how saved progress handles a version bump is a persistence question.
- The solver is cheap enough for an on-device Dead End check: ≤ 2 ms max at 12 Colors × 1, ~5 ms p95 / 30 ms max at 12 Colors × 2 (AOT, M4), with no cap hits at 50 000 nodes.
