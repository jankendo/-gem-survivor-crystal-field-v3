# Changelog

## 3.0.0 — working alpha, unreleased

- Rebuilt simulation with fixed ticks, authoritative generation-checked enemy SoA, shared packed spatial index, central status/damage ownership and active archetype weapons.
- Retained source definitions/assets and test references with SHA inventories.
- Replaced large runtime/UI scripts with separated owners and scene components.
- Added 5/10/15 minute boss schedule, CLEAR choice and continued Endless schedule.
- Introduced schema-3 cached/debounced/atomic saves and read-only legacy import.
- Added discovered tests, seeded weapon scenarios, boss TTK and stress evidence.
- Renamed current product/export/save artifacts to v3 and strengthened release validators.
- Continued the existing fac61d1 history without rebuilding the repository; pushed to the user-created public repository with a leading hyphen in its name. The requested exact-name rename is denied HTTP403.
- Executed successful GitHub Actions on Windows/macOS, built and validated Windows EXE/PCK/ZIP and actual unsigned arm64 IPA including Assets.car, launch assets and SHA256.
- Fixed Windows UTF-8 data/test processing.
- Reduced projectile broadphase work with deterministic collision parity; retained 600/500/1000 stress load and added generated-world profiling and memory monitors.
- Connected special weapon deployables, homing/reflection, gem pull, knockback, mining, named Overclocks and character utility traits.
- Restored all six field-event objectives, quest metrics, source shop prerequisites and proven legacy purchase entitlements.
- Calibrated boss HP from measured stationary and actual-run TTK; autoplay now fails CI if the either representative build cannot CLEAR.
- No release tag is published while the exact repository-name and human/device gates remain unmet.
