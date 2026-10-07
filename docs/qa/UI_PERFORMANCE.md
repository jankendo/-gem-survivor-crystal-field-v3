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
|60fps|Renderer preparation + UI process|1111.42 /1396 /1935|1109.67 /1355 /1734|

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
