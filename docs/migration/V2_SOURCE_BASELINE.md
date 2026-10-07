# v2 source baseline

Source: https://github.com/jankendo/gem-survivor-crystal-field-v2
Commit: b9b70807492b673a6836eb6beafe8823f71e6672 (main)
Godot: 4.7.stable.official.5b4e0cb0f; renderer: gl_compatibility.

All source text, JSON, scenes and asset metadata were read by the inventory audit; SHA-256 inventories preserve exact provenance. This is not a claim of human visual approval of every image.

## Counts

{'.github': 4, '.gitignore': 1, 'AGENTS.md': 1, 'IOS_UNSIGNED_README.md': 1, 'README.md': 1, 'assets': 1047, 'balance_report.md': 1, 'data': 63, 'docs': 109, 'export_presets.cfg': 1, 'project.godot': 1, 'scenes': 4, 'scripts': 454, 'test-output': 34, 'tests': 1092, 'tools': 45}

## Runtime call flow and dependencies

Main creates GameScreen; GameScreen._process derives sim_delta from rendering delta and speed multiplier. CrystalField/Event/Drop/Synergy/Status helpers run before player movement. Warp entry switches EnemySpawner to existing-only processing. EnemySpawner moves SurvivorEnemy objects, WeaponSystem rebuilds its own grid and processes every weapon function, Pickup/CharacterEvolution/Drop/Chest follow, then Combo, Player survival, Exploration/Momentum and UI refresh. SurvivorState owns definitions, runtime arrays, stats, RNG and progression. ArenaView mixes static cache, environment art, enemy batching and effect presentation. SaveSystem repeatedly loads and writes a legacy JSON profile.

EnemySpawner.process_enemies and WeaponSystem.process both call tick_cooldowns(delta): shock, poison, contact and hit cooldowns decrement twice. SurvivorPlayer contact code also decrements contact timers. Spawn interval is divided by multiplier while count is multiplied by it: throughput approximately squares the multiplier. iOS AI cadence varies by profile and GameScreen uses render delta, so deterministic cross-profile fixed-tick parity is not established by that runtime.

RNG uses seeded streams (FNV-derived stream seed) and snapshot/restore. Warp has a separate stream and suspended main field. Evolution requires weapon/passive levels; combos retain component weapons and use dedicated attribution. Drops must remain on reachable safe floor; uncollected gems persist. v2 progression includes shop-only permanent unlocks, collection, quests, mastery, character evolution, blessings and contracts.

## Tests and CI

Legacy tests cover seeded RNG, gameplay, asset integrity, safe area, touch, save, unlock, warp isolation, combo attribution, effect budgets, UI dirty updates and SoA foundations. Fast manifest contains phase-specific contracts; long autoplay and stress scripts are separate. Existing workflows: ci-fast, ci-ios-perf, nightly-full, build-release. Release exports Windows and uses macos-26 Godot export then unsigned xcodebuild arm64, Payload packaging and partial IPA validation.

## Retain / redesign

Retain original Japanese definitions, character/weapon/passive/evolution/combo/warp/environment assets, manifest provenance, silence, Compatibility, safe-area touch, seeded streams, pool/spatial/batched rendering principles. Redesign all six large runtime classes, timer ownership, active weapon execution, shared spatial index, budget spawn, boss TTK, saves, UI component tree and test discovery. No obsolete phase runtime is copied. Original test source is retained as migration reference with explicit port mapping, not falsely reported as passing v3.

## Constraints

No LICENSE exists upstream: no new open-source permission is inferred. Asset manifests contain human review status which must remain unchanged. Headless measurements do not prove iPhone performance. Real-device and human gameplay gates remain unverified until actually performed.
