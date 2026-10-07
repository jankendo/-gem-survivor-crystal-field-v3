# Changelog

## 3.0.0-alpha.1 — published preview, 2026-10-07

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
- Alpha publishing requires successful Fast/Balance/Performance/native Release workflows on its immutable main commit. Repository rename permission and human/device gates remain explicitly unverified.
- Centralized periodic status damage before AI, fixed authoritative deploy pull, imported the original desktop save directory read-only and clarified boss death causes.
- Added measured weapon-utility gates,473 assertions and body-aware normal-HP close-build autoplay.
- Published alpha only after all four main workflows succeeded; tag rebuilt Windows and unsigned IPA, revalidated archives and attached binary assets plus checksums. Downloaded IPA SHA matches the published asset digest.

## UI/UX audit follow-up (main)

- Separate blessing/setup/equipment/collection/system/confirmation scenes; safe
  point-based responsive layouts and48pt actions; Japanese long-text/focus fixes.
- Guard transitions/purchases/selections, isolate modals and neutralize touch;
  rollback failed saves, preserve damaged originals and support validated recovery.
- Add boss HP, contextual field actions/guidance, accurate growth previews and
  combat DPS; correct Ultra camera origin and terminal death/CLEAR priority.
- Add native input,16-viewport layout,63 screenshot fixtures, normal-HP full-run
  flow and UI CPU gates. Human/device UX remains explicitly unverified.
