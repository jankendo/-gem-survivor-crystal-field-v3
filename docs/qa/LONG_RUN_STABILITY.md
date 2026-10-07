# Long-run stability — alpha.2

Evidence in `evidence/alpha2/` is actual Godot4.7 Linux headless execution.
Two-CPU cloud quota; compare isolated local runs only with this same environment.
No physical iPhone, real-time30-minute GPU, thermal or battery claim.

## Continuous test

`tests/long_run.gd -- --ticks=108000`:30 simulation minutes in472.246 wall seconds.
Controlled late-Endless stress fixture, normal fixed60Hz processing but deliberately
large HP/phase control: this is not a normal-HP CLEAR result. Every measured sample
retains600 enemies (including boss),500 projectiles,1000 gems; two combos active.
Presentation buffer is filled to512 every30 ticks and safely drops3600 overflow
requests. This exercises CPU event/snapshot preparation, not rendered GPU particles.
Six Warp entry/exit cycles verify main-field freeze, original world references and
release of suspended state. Six separate real app/run/detail/result/title/dispose
cycles additionally return Node count exactly to baseline (12 assertions).

| Isolated local continuous stress | Result |
|---|---|
| mean / p95 / p99 simulation |4.363 /5.190 /6.483 ms|
| sampled max / all-tick max |26.270 /38.336 ms|
| warm / final live objects |1583 /1583; delta0|
| packed capacities enemy/projectile/gem |600 /4096 /1024|
| engine static-memory delta |494234 bytes (monitor proxy, not native cumulative allocations)|
| actual process RSS samples |94 at5-second cadence, Godot PID discovered via process parent|
| first / last / peak RSS |111388 /111556 /111556 KiB; peak108.94 MiB, increase168 KiB|

The RSS/HWM sampler reads actual `/proc/<GodotPID>/status`; first sample at5.017s,
last470.054s. HWM is cumulative. An initial sampler relying on unsupported
`/proc/.../children` collected zero samples; that failed attempt is retained and
explicitly labelled, never counted as measured. RSS is process memory, not an
allocation counter. Static-memory growth includes retained diagnostic checkpoints.

Percentiles sample every6 ticks; all-tick maximum observes every tick.38.336ms
spikes exceed16.67ms and remain a profiling limit, even though p99 is below it.
A repeated isolated run had all-tick max59.129ms. The contended run is retained
(mean9.517 /p9540.718 /p9949.014ms) and is not used as an optimization comparison.
No enemy/projectile/gem reduction, lower simulation frequency or render-derived
state is used to obtain these results.

Actual hosted Nightly37698440750 also completed108000 ticks: mean5.465 /p956.268 /
p996.538ms, all-tick max13.422ms, live-object delta0, six Warps PASS. Different
runner timings are separate evidence. All measurements are accelerated simulation,
not sustained physical-device sessions. Native cumulative allocation, GPU frame
spikes, touch latency, thermal and Low Power Mode remain unverified.
