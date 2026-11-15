---
status: accepted
---

# Portrait only everywhere; auto-grid board layout

Flaszki is drawn in portrait on every target. Phones and tablets are locked to portrait. On desktop and web, the game is a portrait-shaped column centred in the window, with background filling the sides. The board uses an **auto grid**: for the Level's starting Flask count, try every column count and pick the one that gives the largest Layer height (ties go to fewer rows). Rows are filled top to bottom and a short last row is centred. Flask size is then fixed for the whole Level (see the pour UI prototype, #7).

Checked in the board-layout prototype (#13), with a 64 px Goal Queue strip, a 60 px Undo/Restart bar and glass width ≈ 2.2 × Layer height. At 16 Flasks (the ADR 0004 cap) the board is a 6×3 grid with Layer height 18.8 px on 320×568 and 21.2 px on 360×640, above the 15 px minimum (#8). The tap target is the whole grid cell (≥ 51×114 px), not just the glass. **The 16-Flask cap in ADR 0004 holds.**

## Considered Options

- **Landscape on phones**: 16 Flasks on 568×320 give 14.8 px Layers and 40 px-wide tap cells, below both limits.
- **Phones-only portrait** (free shape on tablet/desktop/web): a second layout to build and test, for little gain in a puzzle that fits a column.
- **At most two rows**: Flasks get thin at high counts.
- **Fixed size as if 16 Flasks**: the look is the same everywhere, but early Levels get needlessly small Flasks.

## Consequences

- The layout still fits about 20 Flasks in portrait on 320×568 (5×4, 16.7 px), so the cap has some room if the curve ever needs it.
- Desktop and web windows show unused space at the sides; the visual style fills it with background.
