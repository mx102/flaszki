---
status: accepted
---

# Local save: Level snapshot + Pour log; Level N follows the current generator

Progress is local-only (no accounts, no cloud sync, no level select). The app saves the **Level Number**, plus the in-progress Level as a **snapshot of its initial state** (Flasks + Goal Queue) and the list of Pours made so far. It does not save a seed to regenerate from. After an app update bumps `generatorVersion` (ADR 0002, 0004), the player keeps their Level Number and gets the **new** Level N. The in-progress Level finishes from its snapshot, and the next Level comes from the new generator. Old generators are never kept.

## Details

- **Resume**: closing the app mid-Level restores the exact board, Goal Queue position and Undo history. The current state is rebuilt by replaying the Pours over the snapshot. Undo drops the last Pour and replays; Restart clears the list.
- **Storage**: `shared_preferences` on all 6 targets (web: localStorage). JSON values in three keys, each with its own `schemaVersion`:
  - `progress` {levelNumber}
  - `level` {levelNumber, snapshot, pours}, discarded if its levelNumber doesn't match `progress`
  - `settings` {colorblind patterns, sound, music, haptics}
- **When written**: after every Pour, Undo and Restart, and on Solved (Level Number++, `level` cleared). The app doesn't rely on pause or close events. The pre-generated Level N+1 is not saved; it is regenerated on launch.
- **Missing or corrupt**: missing means a new player (Level 1, default settings). Each key falls back on its own and the failure is only logged, never a crash or a modal: bad `level` → start Level N fresh; bad `settings` → defaults; bad `progress` → Level 1. A `schemaVersion` newer than the app knows (after a downgrade) counts as corrupt. Migrations run forward-only, one version at a time.
- **Web**: the browser may wipe localStorage (e.g. Safari after 7 days without a visit). This is accepted silently, since web is a secondary target (ADR 0001).

## Considered Options

- **Seed + Pour log**: smaller, but an update that changes the generator would break a Level in progress.
- **Keep old generators and store `generatorVersion` per player**: Level N would never change under a player, but code, golden tests and curves pile up forever. Without level select or replay, nobody can compare the old and new Level N anyway.

## Consequences

- "Level N is identical on every device" holds only between devices running the same `generatorVersion`.
- Color ids in a snapshot must stay stable across versions. A palette change must keep the 12 ids or migrate the `level` key.
