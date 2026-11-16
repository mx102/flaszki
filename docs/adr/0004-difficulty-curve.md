---
status: accepted
---

# Difficulty curve: hand-written table, fixed 2 empty Flasks, 16-Flask cap

`curve(N)` (see ADR 0002) is a hand-written table plus rules that depend only on N, with no PRNG. The curve is part of the versioned algorithm, so any change bumps `generatorVersion` and changes Level N for players already past it. That is why its shape is recorded here.

- **Empty Flasks: always 2.** Difficulty comes only from `colorCount` and `flasksPerColor`. With 1 empty Flask, 12 Colors × 1 is essentially never solvable in queue order (#6). 3 empty Flasks appear only through the generator's fallback.
- **`flasksPerColor` is the same for every Color in a Level**, and the board holds **at most 16 Flasks** (17 only when the generator's fallback adds a 3rd empty Flask to 7×2; ADR 0006 fits ~20), so ×2 only goes up to 7 Colors. At 12 Colors × 2 there would be 26 Flasks, too small on a phone in portrait. ×2 makes a Level longer but more forgiving (random play rarely hits a Dead End), so it is used for variety, not as a harder tier.
- **Ramp, Levels 1–40** (×1, 2 empty Flasks): 3 Colors for Levels 1–3, then +1 Color every 4 Levels (4 → L4–7, 5 → L8–11, …, 11 → L32–35), and 12 Colors for Levels 36–40. Level 1 is 3×1 and there is no separate tutorial.
- **Breather** when `N % 5 == 0`: through Level 40 it uses `ramp(max(1, N − 8))`. From Level 41 on, a breather is always 8×1, because "8 Levels earlier" there would be another hard config.
- **Endless play, from Level 41**: cycles through `[12×1, 10×1, 7×2, 11×1, 12×1, 6×2]` at position `(N − 41) mod 6`. Breather slots take priority.
- **Metrics** (B − C, solver nodes, solution length) are used only offline: a dev script in the logic package reports them for Levels 1–500, with no CI checks. They are never filters in `generate()`, because filters would add attempts and runtime variance on low-end devices.

## Considered Options

- **Formula instead of a table**: harder to read and tune by hand. A table is just as easy to pin with golden tests.
- **Difficulty filters in `generate()`** (reject deals that are too easy): more attempts, more variance, and no measured need.
- **12 Colors × 2 as the top tier**: too many Flasks for a phone screen, and in practice it's longer but not harder.

## Consequences

- The 16-Flask cap is an assumption. It must be checked when the board layout is built. If it moves, the endless-play cycle changes and `generatorVersion` is bumped.
