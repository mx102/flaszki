# Research: Solvable level generation for fluid-sort puzzles

Issue: [#3](https://github.com/mx102/flaszki/issues/3). Feeds decision issue [#5](https://github.com/mx102/flaszki/issues/5). Facts only; no recommendation.

Notation: `n` = filled Flasks, `h` = Flask capacity (Layers), `k` = empty Flasks, `C` = Colors. Flaszki target: `C <= 12`, `h = 4`.

## 1. Theory (primary: Ito et al., FUN 2022)

Source: T. Ito, J. Kawahara, S. Minato, Y. Otachi, T. Saitoh, A. Suzuki, R. Uehara, T. Uno, K. Yamanaka, R. Yoshinaka, "Sorting Balls and Water: Equivalence and Computational Complexity", FUN 2022, LIPIcs 226:16. [arXiv:2202.09495](https://arxiv.org/abs/2202.09495), [LIPIcs](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.FUN.2022.16).

- Model matches our Pour rule: "If the target bin has enough margin, all the water of the same color moves ... a part ... moves up to the limit of the target bin" (sec. 1). Model allows a Color to fill several bins ("each color c occurs exactly hj times") — i.e. **repeated Colors are covered by all results below**.
- Ball-sort and water-sort have identical solvability (Corollary 4).
- Both in NP; solvable in `O(h^n)` time (Cor. 5, 6). Any solvable water instance has a solution of `<= 2(h-1)·n·min(h,n)` Pours (Cor. 8). For `h=4, n=12`: `<= 288`.
- **NP-complete even with 2 Colors** (Thm 9). Finding a shortest solution is NP-complete even when the instance is known solvable (Cor. 12).
- `h=2`: always solvable with `k>=2` (Thm 13); `k=1` decidable in `O(n)` (Thm 14).
- Empty bins needed so that **every** instance is solvable, `k(n,h)`: `ceil(19/64·min(n,h)) <= k(n,h) <= ceil((h-1)/h · n)` (Thms 16, 17). For `h=4, n=12`: upper bound 9.
- Explicit **unsolvable instances: `h=3,k=2,n=9` and `h=4,k=3,n=12`** (sec. 6, Fig. 10), found by hand, verified by program. So for our exact size (12 Colors, capacity 4) even 3 empty Flasks do not guarantee solvability of an arbitrary deal.

Consequence (direct from the above): a random deal is not solvable by construction; either verify with a solver or generate by construction.

## 2. Solver techniques (primary: Kociemba)

Source: H. Kociemba, [Color Sort Puzzles](http://kociemba.org/themen/waterball/colorsort.html), [Algorithm description 1](http://kociemba.org/themen/waterball/algorithm.html), [Algorithm description 2](http://kociemba.org/themen/waterball/algorithm2.html), code [hkociemba/WaterBallSortPuzzleOptimalSolver](https://github.com/hkociemba/WaterBallSortPuzzleOptimalSolver).

- **Block invariant** (water rule): a Pour never increases the number of same-Color contiguous blocks `B`; only a Pour whose whole run fits onto a non-empty target decreases it, by exactly 1. Solved state has `C` blocks (one per Flask), so **every solution has exactly `B - C` merging Pours**, and `B - C` is a lower bound on solution length.
- Optimal search: 2-D layered BFS `states[x][y]` (x = merging Pours, y = non-merging Pours); "resembles both A* and breadth first search". Finds optimal solutions; returns "no solution" when frontier empties.
- Pruning: forbid pouring a single-Color Flask into an empty Flask (useless).
- **Canonicalisation**: Flasks within a state are sorted lexicographically, so empty-Flask position and Flask order don't create duplicate states.
- Dedup: 2^32-bit array keyed by 32-bit random (Zobrist-style) hash; collisions ignored.
- Performance claim: standard cases optimal "within less than a second"; 14 Colors × 6 Layers "within seconds" (desktop, Pascal).
- Ball rule (one unit per move) can increase blocks; algorithm then only near-optimal.

Other repos ([cemasma/water-sort-puzzle-solver](https://github.com/cemasma/water-sort-puzzle-solver), [ashraftryfie/colored_ball_sort_puzzle_game](https://awesome.ecosyste.ms/projects/github.com%2Fashraftryfie%2Fcolored_ball_sort_puzzle_game)) use plain DFS/BFS/A*; nothing beyond the above.

Size facts (computed): branching factor `<= (n+k)(n+k-1)` Pours. Distinct initial full deals of `n` Colors × `h=4`: `(4n)!/(4!)^n` — n=8: 2.4e24, n=10: 1.3e34, n=12: 3.4e44 (÷ n! for Flask-order symmetry: 7.1e35). Full enumeration impossible; per-instance search is what's feasible (see 4).

## 3. Generation approaches found

- **Reverse play (scramble from solved)**: solvable by construction because the scramble replayed backwards is a solution. Claimed for ball-sort game SortStack ([blog](https://puzzlevault.pages.dev/blog/posts/the-math-behind-sortstack.html) — on fetch, page did not actually describe its generator; treat as unconfirmed). General argument + pitfall (buggy inverse moves yielded unsolvable levels) documented for Sokoban ([dev.to](https://dev.to/yurukusa/i-built-a-procedural-sokoban-generator-in-one-day-heres-why-it-kept-making-unsolvable-levels-5191)). No primary water-sort reverse-play implementation found.
- **Random deal + solver verify**: e.g. itch.io Water Sort dev discards levels its solver can't finish within 20,000 moves ([itch.io](https://beytullahkalay1.itch.io/water-sort)).
- No paper on water/ball-sort level generation found.

Inverse-Pour constraints (derived from the Pour rule, not from a source). Forward Pour `s -> d` of `m` units of Color `c` is legal and moves exactly `m` iff: `d` empty or top `c`; and either `m` = whole top run of `s` or `d` becomes full. So an "unpour" (take `m` top `c` units from `d`, put on `s`) is a valid inverse only if:
1. `d`'s top `m` units are `c`, and after removal `d` is empty or its top is `c`;
2. `s` has room for `m`;
3. after placing, `s`'s top `c`-run equals `m` (i.e. `s` was empty or its top was not `c`), **or** `d` had been full before un-pouring (capacity-limited Pour, then `s` run may exceed `m`).
Naive "move top unit anywhere" reverse moves violate these and break the solvability guarantee.

## 4. Empirical numbers (our own experiment, this repo)

Script: [`levelgen_exp.py`](levelgen_exp.py), [`levelgen_paired.py`](levelgen_paired.py). Uniform random deals, water rule, `h=4`, DFS with sorted-Flask canonicalisation + visited set (exact: reports unsolvable only after exhausting reachable space). CPython on a desktop Mac; seeds fixed in script.

| Colors | Flasks filled | k | solvable / trials | max nodes expanded | avg ms/instance (CPython) |
|---|---|---|---|---|---|
| 4–10 | = Colors | 2 | 100% (100 each; 1000 for 10) | 1,119 | <= 1 |
| 12 | 12 | 1 | **0 / 300** | 754 | 1 |
| 12 | 12 | 2 | 994 / 1000 (99.4%); paired run 2994 / 3000 | 6,605 | 4 |
| 12 | 12 | 3 | 300 / 300 | 392 | 1 |
| 6 (each ×2) | 12 | 2 | 1000 / 1000 | 2,702 | 1 |

Takeaways (facts from the data):
- With `k=2` (genre-standard "n+2"), ~0.2–0.6% of uniform random 12-Color deals are unsolvable; all sampled smaller sizes were solvable.
- `k=1` at 12 Colors: no sampled deal solvable.
- Repeated Colors (6 Colors × 2 Flasks) were easier: all solvable, fewer nodes.
- Verifying a random deal is cheap: worst case ~6.6k nodes in CPython. Low-end phone timing not measured.

## 5. Our twist: Goal Queue + sealed removal + repeated Colors

Prior art: none found with a Goal Queue order. Closest: "Sort Resort" removes a Flask once completed ([1001games](https://www.1001games.com/think/sort-resort)); SortStack adds a new empty tube on completion ([blog](https://puzzlevault.pages.dev/blog/posts/the-math-behind-sortstack.html)). Ito et al. (sec. 6) list commercial extensions (mixed capacities, numbered balls, transparent balls) — no queue.

Facts / derived observations:
- Sealed removal removes only a full single-Color Flask, so free space is unchanged; it only removes options (pouring out of a Completed Flask). Hence queue-solvable ⇒ standard-solvable (derived).
- Converse is not proven. Empirically (paired, same deals, random queue order with repeats): **0 deals** solvable in standard rules but not in queue order — 12 Colors k=2: 2994 both / 6 neither of 3000; 6 Colors ×2 k=2: 2000/2000 both; 10 Colors k=2: 2000/2000 both.
- Repeated Colors: queue lists Color `c` once per Flask of `c`; each Completed Flask of the head Color is removed in turn. Theory of sec. 1 already covers multiple bins per Color.
- Effect on reverse play (derived): forward end state = only empty Flasks. Reverse step for each queue entry (last first) = re-insert a full Flask of that Color, then scramble with valid inverse Pours (sec. 3). A re-inserted Flask did not exist earlier in reverse time, matching forward rule that a sealed Flask is never touched again. Extra case: a Flask completed earlier and waiting off-queue means in reverse it may sit full for several steps before being un-poured.

## 6. Difficulty metrics found

- Solution length; lower bound `B - C` merging Pours (Kociemba). Shortest length NP-hard in general (Ito Cor. 12) but optimal BFS practical at our sizes (Kociemba).
- Search effort (nodes expanded) as difficulty proxy: domain-agnostic A*-expansion metric, [Beukman et al., arXiv:2201.10334](https://arxiv.org/abs/2201.10334) (not tested on sort puzzles).
- Knobs used by shipping games: Colors, tube count, move limits (SortStack modes: 3/5, 5/7, 7/9, 10/12 Colors/tubes).
- `k` strongly affects solvability (sec. 4).

## 7. Cross-platform deterministic seeded PRNG

- JS `Math.random()`: "implementation-defined algorithm or strategy" ([ECMA-262 §21.3.2.28](https://tc39.es/ecma262/#sec-math.random)); seed "cannot be chosen or reset by the user" ([MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/random)). Unusable for seeded Levels.
- Dart `Random(seed)`: "The implementation of the random stream can change between releases of the library" ([api.dart.dev](https://api.dart.dev/stable/dart-math/Random/Random.html)). Not stable across versions.
- **xoshiro128\*\*** / **xoshiro128++** (Blackman & Vigna, [prng.di.unimi.it](https://prng.di.unimi.it/), [C source](https://prng.di.unimi.it/xoshiro128starstar.c)): 32-bit ops only, 128-bit state; recommended 32-bit all-purpose generators; state must not be all zero; seed via **SplitMix** from a 64-bit seed. 32-bit-only ops map to JS via `Math.imul` + `>>> 0` (`Math.imul` = exact `(a·b) mod 2^32`, [ECMA-262 §21.3.2.20](https://tc39.es/ecma262/#sec-math.imul)).
- **PCG** family ([pcg-random.org](https://www.pcg-random.org/)) is an alternative; PCG32 needs 64-bit multiply (BigInt or split arithmetic in JS).
- Avoid floats for determinism; bounded ints: rejection or Lemire's multiply-shift method ([Lemire, "Fast Random Integer Generation in an Interval", ACM TOMACS 2019, arXiv:1805.10941](https://arxiv.org/abs/1805.10941)). Shuffle with Fisher–Yates driven by those ints.
- Determinism also requires the generator *algorithm* to be deterministic (fixed iteration order, no hash-map iteration order, no time limits that cut search differently per device).

## Open gaps

- No primary source on reverse-play water-sort generators or their difficulty distribution.
- No low-end-phone timings; CPython desktop numbers only.
- Queue-solvable ⇔ standard-solvable unproven (only sampled).
