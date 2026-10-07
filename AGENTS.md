# v3 engineering rules

- Keep exploration × crystals × risk/reward × survivor builds and Japanese UI. No external copyrighted assets, network gameplay or unlicensed audio.
- `app` composes; `state` stores; `combat` simulates; `progression` changes loadout; `exploration` owns map/warp; `presentation` reads snapshots; `ui` presents choices; `persistence` owns disk I/O.
- Never resurrect v2 GameScreen, SurvivorState, WeaponSystem, Main, ArenaView or SaveSystem. Migration reference is not runtime code.
- Simulation runs exactly 60Hz. Input is tick-indexed. Speed executes additional fixed ticks. Rendering FPS/profile must never affect RNG, collision, spawns, damage or rewards.
- EnemyWorld packed arrays and dense/sparse membership are authoritative. Keep generation checks and deterministic iteration. No enemy objects or allocating active-list helpers.
- StatusSystem exclusively decrements enemy status/contact/action timers. DamageSystem exclusively attributes actual HP loss; DeathSystem resolves each death once.
- SpatialWorld rebuilds once per tick and uses caller-owned query buffers. No query-triggered rebuilds or all-enemy player-contact scans.
- Register equipped weapon definitions only; archetype/modifier data adds content. Tuning numbers live in data, logic in code. Cache final stats on loadout events.
- Presentation event loss is cosmetic. Boss telegraphs remain critical. Never feed transforms, LOD or interpolated positions into simulation.
- UI components are scenes in root canvas; world alone uses SubViewport scaling. Stable nodes, dirty labels, safe area, scrollable dialogs, dynamic touch joystick and minimum 44pt on iOS.
- Save schema is 3. Import legacy saves read-only; retain legacy file and legacy archive. Validate temp file, atomically replace and keep a valid backup. Never log credentials.
- Run `tools/validate_data.py`, engine import, `tests/test_runner.gd`, relevant benchmark and exported-pack smoke. Treat any SCRIPT ERROR as failure even if Godot exits zero.
- Required regression categories: smoke/unit/gameplay/deterministic/balance/performance/UI/iOS/release. Changes to timers, RNG, spatial or pools require behavioral tests.
- Optimize only after profiling; retain fixture population and deterministic results. No worker SceneTree access or speculative native extensions.
- Release requires successful CI, validated Windows ZIP and actual unsigned arm64 IPA. Workflow files are not build evidence. No tag/release before those gates pass.
- Human gameplay and physical iPhone checks are NOT YET VERIFIED ON REAL DEVICE until actually executed; never infer them from headless tests.
