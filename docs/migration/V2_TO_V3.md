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

The continuation adds equipped-runtime utilities for all 31 weapons and restores all 20 named overclock choices. Homing, wall reflection, split shots, gem charge/pull, knockback, mining, lifesteal and kill currency have executable behavior. Mines arm then consume once; magma leaves a persistent floor; shrine beam is a stationary pulsing deployable; guardian wall deploys forward. Six original event IDs use actual objectives with deadlines and rewards. Quest/shop conditions share one fail-closed evaluator; discovery and paid ownership are distinct. Original license costs are enforced inside the save purchase API.

Intentional v3 redesigns: Collector starts with Coin Orbit: the source empty starting-weapon ID was unusable in active runtime and could leave the gem-build unable to begin. All 27 character starting IDs are now validated and replayed.  Ghost trades wall phasing for 15% movement because walkable-floor reachability and branch risk are world invariants. Secret Ghost unlock uses cumulative relic-vault time 300s and low-HP time 60s; extreme boss_25 death unlocks Reaper. Map-reveal character utility widens the unexplored-room compass. Void's unexplored damage becomes the unified new-room Resonance window. Echo corridor resonance is a corridor damage multiplier. Some overclock descriptions map to archetype-level effects rather than identical v2 trajectories. Timings and values are tuned for v3; bitwise v2 gameplay equivalence is not claimed.

Character HP, tag damage/area/cooldown, slow duration, bounce/chain count, incoming damage, healing, mining/reward, contracts, terrain defense, exploration, rare cores, kill heal, boss damage and gem utility are connected to their owners. New tests exercise previously ignored trait routes. Preserved source tests are references; unported implementation-specific assertions are not counted as executed.

Legacy save import retains the complete parsed source in `legacy_archive` and never modifies `user://chrono_merge_tactics.save`. New schema root is profile/progression/settings. Some old progression keys are preserved for future normalization rather than silently discarded.

Bundle identifier remains `com.jankendo14.gemsurvivor`; there is no reason to make this a separate coinstalled app. Version is 3.0.0. Windows and iOS artifacts use v3 names. A dummy Team ID is export-only and is not a credential.

Desktop read-only legacy import additionally checks the original sibling Godot product directory (`Gem Survivor Crystal Field`) when the new product directory contains no v3 save. iOS first checks the retained bundle container. No source save is overwritten; invalid imports produce an explicit parse error. Optional legacy-directory injection is used only for isolated tests.
