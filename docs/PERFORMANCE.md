# Performance

Evidence is under `docs/qa/evidence`. Measurements are Linux x86_64 headless CPU or llvmpipe screenshot captures, never iPhone/Windows GPU/thermal/battery proof. The source's Phase12 render harness and v3 simulation harness measure different paths and cannot justify a direct speedup percentage.

The stress fixture starts/replenishes 600 enemies and at least 500 projectiles, carries 1000 initial gems, equips four weapons and an active combo. Simulation, enemy, weapon, spatial and render-snapshot preparation have separate mean/p95/p99 timing. Capacity-growth counters are allocation proxies, not a native allocation profiler. Sampled gem count can decrease through legitimate pickup; gems are never reduced to improve performance.

Before-profile evidence preceded packed shared-grid and active-cache optimization. Projectile collision/query work is the main CPU cost. Enemy SoA capacity is fixed in the measured fixture. No worker threads or GDExtension were added.

World rendering can shrink 2x under Ultra; effects reduce cosmetically. UI size and gameplay state do not shrink. Desktop headless timing does not establish sustained 15/30-minute iPhone performance. Follow `qa/IOS_REAL_DEVICE_CHECKLIST.md` before any mobile performance claim.

The archived v2 simulation baseline was captured with other jobs running and a different object/runtime workload. It is contextual evidence only; a controlled comparative speedup claim is not supported. Final v3 evidence was measured separately.

Final isolated 220 measured samples: simulation mean 13.44 ms, p95 16.80 ms, p99 18.97 ms; CPU fixture (simulation + snapshot) p95 17.05 ms. Enemy/spatial capacity-growth proxy = 0.

The final p95 exceeds the 16.67ms 60Hz tick budget slightly. This fixture does not certify that the performance target is achieved; projectile collision/query profiling needs further work.
