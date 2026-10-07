# UI performance evidence

Baseline main `9dcae358a8aa5c9fe5ce2d60e599d89c4c212a6f` versus repaired
runtime `0de06945182dd38674438680ad170f83ad93e753`. Same local Linux
machine/Godot4.7, sequential measurements, fixed600 enemies/500 projectiles/1000
Gems, six max weapons/passives. Simulation frozen to isolate presentation CPU.
Harness: `tests/ui_performance.gd`; immutable JSON in `evidence/`.

| Rendering cadence | CPU scope | Before mean / p95 / p99 (µs) | After mean / p95 / p99 (µs) |
|---|---|---:|---:|
|30fps|UI process|2.90 /11 /29|11.21 /30 /102|
|60fps|UI process|2.39 /11 /14|5.15 /20 /27|
|30fps|Renderer preparation + UI process|1078.34 /1333 /1688|1155.15 /1446 /1735|
|60fps|Renderer preparation + UI process|1111.42 /1399 /1935|1109.67 /1355 /1734|

The repaired UI does more useful work: real boss HP, contextual field actions,
critical30Hz updates at both frame rates,5Hz objective/equipment/notification checks
and save/error feedback. It is **not faster than the sparse baseline UI**. Mean UI
process remains below0.012ms, p99 below0.103ms, within the1ms CPU process gate.
Combined differences are within measurement noise; no statistical speedup is claimed.

During repairs, the expanded UI's repeated600-enemy boss lookup measured28.79µs
mean at30fps /14.26µs at60fps. Lifecycle-maintained boss ID reduced that stage to
8.09 /4.66µs with replay/generation/world-switch checks, before adding contextual
feedback. Authoritative enemy population and collision results were unchanged.

Cold node count grows119 →272 because previously absent screens/controls now exist.
It remains272 before/after all120 simulated presentation seconds. No Controls,
Themes or resources are created per frame. Formatted HUD changes249; critical calls
3721 and slow calls620 include warmup/setup across four measurement modes.

## Limits and simulation stress

These are explicit `_process` CPU calls and actual renderer preparation, **not**
GPU frame time. Deferred Control sorting, native cumulative allocations, physical
screen latency, thermal state and battery are outside this harness. Pixel/native
geometry QA and CI are separate gates; stable nodes is only an allocation proxy.

Hosted CI at runtime0df959d additionally executed full simulation stress, before
these cold UI-only refinements: initial/replenished600 enemies/500 projectiles/1000
Gems, heavy effects/combos. Open-field mean7.470ms /p957.855 /p998.555;
generated-world8.459 /12.900 /13.104; late-large-boss8.790 /14.749 /15.088.
Packed enemy/spatial/query capacity growth0 and live-object delta0; Gem capacity
can grow once as legitimate drops exceed1024. Static-memory deltas are proxies,
not cumulative allocation counts. Collision-consumed projectile totals may differ
at final snapshot; the fixture replenishes before each measured tick.

Hosted and local hardware differ. These values neither replace a same-machine
simulation comparison nor certify sustained60fps on iPhone. See latest Actions
Performance artifact and `IOS_REAL_DEVICE_CHECKLIST.md`; no device metrics invented.

## alpha.2 follow-up (same local machine, isolated CPU measurement)

`evidence/alpha2/ui-performance.json`:600 enemies/500 projectiles/1000 Gems,
six max weapons/passives; simulation frozen.301 nodes remain301 over all four
measurement modes. New collection rows/detail controls are cold persistent nodes;
search changes cached filtering and row text, not scene creation.

| Cadence | CPU scope | Mean / p95 / p99 µs |
|---|---|---:|
|30fps|UI process|8.48 /24 /30|
|60fps|UI process|4.57 /20 /21|
|30fps|Renderer preparation + UI|1031.67 /1106 /1194|
|60fps|Renderer preparation + UI|1024.43 /1104 /1250|

Critical calls3721, slow620, actual formatted HUD changes249 including setup.
No per-frame Control/Theme creation. This is below the1ms UI CPU gate. GPU drawing,
native layout scheduling, keyboard animation and device latency are outside scope.
CriticalVisuals adds one read-only final world layer; UI point size is unchanged
in Ultra. Native99 image fixtures are separate visual evidence, not timing proof.

Open stress at start1ae9eb5 versus final code, same60606 seed and replenished
600/500/1000 fixture: simulation mean6.128 →5.927ms, p957.538 →6.393,
p998.781 →6.883. This short comparison shows no measured major regression;
it is not a statistically established optimization. Enemy/spatial/query capacity
growth0, live-object delta0; one legitimate Gem pool growth remains. Generated
world mean6.500/p959.851/p9910.660; late70-radius Boss6.987/11.461/11.899.
One generated-world tick reached20.721ms; do not describe every tick as under16.67.
JSONs in alpha2/ retain maxima and preparation/component timings.

Long-duration and process RSS evidence are in LONG_RUN_STABILITY.md. CPU quota
and concurrent workers matter: contended long timing is retained separately from
isolated measurement, never silently discarded to improve a result.
