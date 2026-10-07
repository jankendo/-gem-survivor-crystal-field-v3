# Test plan

- smoke: instantiate main, enter gameplay and verify modal/result navigation.
- unit: pool generations, timer ownership, damage attribution, spatial query buffers, save atomic recovery.
- gameplay: loadout/evolution/combo, target population, map placement, warp freeze/resume, clear/endless.
- deterministic: tick-input replay at 30/60 rendering and 1x/2x speed; profile transitions cannot mutate state.
- balance: 31 weapons × 10 scenarios and measured build boss TTK.
- performance: fixed 600/500/1000 stress and unchanged simulation outcomes.
- UI/iOS: stable scene controls, safe-area conversion, 44pt control calculation, touch events and world-only resolution scaling.
- release: duplicate-key/data checks, exact engine parser diagnostics, bundled-pack smoke and archive structural validators.

Runner discovers `.gd` suites under `tests/suites` and filters `tags()`. No hand-maintained giant list is required. `tools/run_godot.py` treats SCRIPT ERROR/ERROR diagnostics as failure independently of engine exit code. Legacy tests in `reference/v2-tests` are migration evidence and are not counted as passing v3.

Human gameplay, sustained physical iPhone, actual Windows execution and unsigned IPA execution must have separate evidence. Unexecuted gates are never marked PASS.
