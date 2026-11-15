---
status: accepted
---

# MIT code, CC BY 4.0 assets, name and icon reserved

Code is MIT, `Copyright (c) 2026 Michał Dratkowski`. We picked MIT over GPL-3.0 because GPL conflicts with App Store terms for forks and outside contributions. Making GPL work would need a CLA. MIT also matches Flutter (BSD-3) and Flame (MIT). The cost is that anyone may ship a closed fork with ads. We guard against that with the name, not the license: the "Flaszki" name and the app icon are not licensed for forks. The icon is all rights reserved, and the README carries a trademark note. The name is not registered.

- Original art, sounds and other assets: CC BY 4.0. Third-party assets must be CC0, CC BY or OFL (fonts), and each is credited in `CREDITS.md`.
- Dependencies must use permissive licenses only (MIT, BSD, Apache-2.0, zlib, ISC). No GPL or LGPL, because static linking on iOS makes LGPL compliance messy. A CI license check enforces this.
- Contributions are inbound=outbound under the project licenses. There is no CLA or DCO.

## Considered Options

- **GPL-3.0**: blocks closed clones, but forks can't ship on the App Store and it needs a CLA.
- **Apache-2.0**: adds a patent grant at the cost of NOTICE boilerplate. Not worth it for a game.
- **MPL-2.0**: file-level copyleft. More complex for little gain.
