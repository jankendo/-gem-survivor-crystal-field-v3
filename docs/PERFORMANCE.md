# Performance

Evidence is under `docs/qa/evidence`. Measurements are Linux x86_64 headless CPU or llvmpipe screenshot captures, never iPhone/Windows GPU/thermal/battery proof. The source's Phase12 render harness and v3 simulation harness measure different paths and cannot justify a direct speedup percentage.

The stress fixture starts/replenishes 600 enemies and at least 500 projectiles, carries 1000 initial gems, equips four weapons and an active combo. Simulation, enemy, weapon, spatial and render-snapshot preparation have separate mean/p95/p99 timing. Capacity-growth counters are allocation proxies, not a native allocation profiler. Sampled gem count can decrease through legitimate pickup; gems are never reduced to improve performance.

Before-profile evidence preceded packed shared-grid and active-cache optimization. Projectile collision/query work is the main CPU cost. Enemy SoA capacity is fixed in the measured fixture. No worker threads or GDExtension were added.

World rendering can shrink 2x under Ultra; effects reduce cosmetically. UI size and gameplay state do not shrink. Desktop headless timing does not establish sustained 15/30-minute iPhone performance. Follow `qa/IOS_REAL_DEVICE_CHECKLIST.md` before any mobile performance claim.

The archived v2 simulation baseline was captured with other jobs running and a different object/runtime workload. It is contextual evidence only; a controlled comparative speedup claim is not supported. Final v3 evidence was measured separately.

## Continuation measurements

The prior handoff measured 13.44ms mean / 16.80ms p95. Repeating that same baseline in this session measured 14.171ms / 18.065ms. Profiling identified the projectile segment broadphase: every projectile queried an 85-unit half width even when all target radii were 18.

The bound is now `min(85, lifetime maximum enemy radius + 5.01)`. The maximum is conservative across removal/reuse; precise collision and candidate ordering are preserved. A regression replay compares against the original 85-unit query and tests boss-sized radius retention. No enemy, projectile, gem, damage or RNG was reduced for this optimization.

| Isolated Linux CPU fixture | Mean simulation | p95 | p99 |
|---|---:|---:|---:|
| Same baseline, before query change | 14.171ms | 18.065ms | 22.728ms |
| Same runtime, after query change | 5.976ms | 6.782ms | 8.033ms |
| Later content runtime, open-field stress | 6.137ms | 7.565ms | 9.987ms |
| Generated 25-room / 40-corridor moving-enemy stress | 6.808ms | 10.003ms | 10.664ms |

The late-game fixture adds the real 70-unit boss radius at the 30-minute schedule while retaining 600 total enemies, 500 projectiles and 1000 gems. It exposed p95 16.356ms before per-entity radius filtering. The spatial index now copies collision radii once per tick and applies the same conservative bound before returning projectile candidates, preserving true-hit ordering. Reference replay against the original 85-unit query includes a mixed boss/small-enemy population. After this additional change, identical late fixture mean = 7.098ms, p95 = 11.429ms, p99 = 12.050ms.

Only the first two rows isolate the optimization; later rows include content/balance changes and are not an identical-game speedup comparison. Every stress fixture starts each tick with 600 enemies, at least 500 projectiles and 1000 gems; deaths, projectile expiry and collected gems are replenished between samples. Four weapons and a combo remain active. The generated-world fixture is now also executed by Performance CI.

Engine live-object/static-memory monitors supplement capacity counters. The later open-field run measured object delta 0 and static-memory growth 91,512 bytes; the gem pool legitimately grew from 1024 to 2048 slots as enemies dropped gems. Reusable query buffers measured zero capacity growth after warmup; initial reservations are counted separately. These figures do not mean zero heap allocations. Cumulative native heap profiling remains unverified.

Linux CPU p95 is within a 16.67ms tick in these samples. Rendering heavy effects, sustained Windows GPU and actual iPhone thermal/Low Power Mode behavior remain **NOT YET VERIFIED ON REAL DEVICE**. See the real-device checklist.

Latest status-owner runtime: late fixture mean7.247ms / p9511.486ms / p9912.091ms. Open/generated/late sample minima were actually observed at600 enemies,500 projectiles and1000 gems before each tick, not inferred from requested counts. Expired/hit projectiles can legitimately reduce post-tick counts. Shared GitHub Ubuntu runner timings differ from this local CPU and must not be mixed into a controlled before/after claim.
