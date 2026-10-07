# v2 → v3 migration

Source is pinned by `V2_SOURCE_BASELINE.md` and SHA/file/call inventories. Original remote remains untouched; generated local import sidecars were restored after baseline execution. v3 has a new Git history. Legacy test source is reference-only and excluded from exports.

| Area | v3 decision | Verification |
|---|---|---|
| Enemy object runtime | packed authoritative SoA + dense/sparse + generations | reuse/stale ID tests |
| Render delta gameplay | fixed60Hz physics + replay accumulator | 30/60 + 1x/2x replay |
| Repeated cooldown decrement | StatusSystem only | exact integer timer test + reproduced v2 evidence |
| Private enemy/gem grids | five-layer packed SpatialWorld | circle/aabb/segment/nearest + reuse |
| Every weapon function each frame | active archetype definitions | equipped-process counter + all-weapon scenarios |
| Dictionary death events | packed death IDs + separate cosmetic buffer | no-double-attribution |
| Spawn multiplier squared | refill tokens + alive target + threat cost | linear bound/population test |
| Boss exponential scaling | measured reference DPS × TTK | benchmark evidence |
| Save path / destructive write | schema3 new path + read-only import, backup/temp/atomic | recovery and original preservation |
| Dynamic Control trees | retained scene panels + dirty HUD | scene/navigation/profile tests |
| Phase-specific old scripts | absent from runtime | dependency inventory |
| Original assets/names/recipes | retained with provenance | JSON and asset-path validation |

Weapon-specific special behaviors, advanced event/gimmick variants, full quest/shop prerequisite parity and every v2 utility are not yet complete equivalents. Do not count preservation of a JSON definition as proof of implemented gameplay. Content-completeness gate requires additional verification recorded in the final review.

Legacy save import retains the complete parsed source in `legacy_archive` and never modifies `user://chrono_merge_tactics.save`. New schema root is profile/progression/settings. Some old progression keys are preserved for future normalization rather than silently discarded.

Bundle identifier remains `com.jankendo14.gemsurvivor`; there is no reason to make this a separate coinstalled app. Version is 3.0.0. Windows and iOS artifacts use v3 names. A dummy Team ID is export-only and is not a credential.
