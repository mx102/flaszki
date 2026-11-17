# Credits

Flaszki code is MIT; original assets are CC BY 4.0 (see [README](README.md)).

## Sounds

All sound effects are original work, synthesized by
[`tool/gen_sounds.py`](tool/gen_sounds.py) (numpy + ffmpeg Vorbis), by
Michał Dratkowski (Flaszki), licensed
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

| file | used for | license |
|---|---|---|
| `assets/audio/select_1.ogg` | Select: glass clink | CC BY 4.0 |
| `assets/audio/select_2.ogg` | Select: glass clink | CC BY 4.0 |
| `assets/audio/select_3.ogg` | Select: glass clink | CC BY 4.0 |
| `assets/audio/pour_1.ogg` | Pour: glug + splash | CC BY 4.0 |
| `assets/audio/pour_2.ogg` | Pour: glug + splash | CC BY 4.0 |
| `assets/audio/pour_3.ogg` | Pour: glug + splash | CC BY 4.0 |
| `assets/audio/invalid_1.ogg` | Invalid tap: muted tap | CC BY 4.0 |
| `assets/audio/seal_1.ogg` | Seal: cork pop | CC BY 4.0 |
| `assets/audio/seal_2.ogg` | Seal: cork pop | CC BY 4.0 |
| `assets/audio/seal_3.ogg` | Seal: cork pop | CC BY 4.0 |
| `assets/audio/queueAdvance_1.ogg` | Goal Queue advance: orb chime | CC BY 4.0 |
| `assets/audio/waitingCork_1.ogg` | Waiting Completed Flask: cork squeak | CC BY 4.0 |
| `assets/audio/solved_1.ogg` | Solved: chime arpeggio | CC BY 4.0 |
| `assets/audio/undo_1.ogg` | Undo: reverse swish | CC BY 4.0 |

## Third-party assets

Third-party assets must be CC0, CC BY or OFL (fonts). List each one here:
name, author, source URL, license, and what it is used for.

_None yet._

## Software

Built with [Flutter](https://flutter.dev) (BSD-3-Clause) and
[Flame](https://flame-engine.org) (MIT). Sound plays via
[flutter_soloud](https://pub.dev/packages/flutter_soloud) (MIT; SoLoud and
miniaudio are zlib / public domain; Ogg Vorbis decoders BSD-3-Clause).
Dependency licenses are checked in CI.
