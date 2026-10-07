# Senior review — continuation, 2026-10-07

The original fac61d1 history is retained. This is a published working alpha; the requested completion gate still includes the exact repository name and human/device quality gates.

| Role | Severity | Review / evidence |
|---|---|---|
| Game Designer | High, unverified | Human 3/5/10/15-minute enjoyment, readable crowded combat and meaningful weapon/exploration choices have no human playtest evidence. Do not substitute autoplay for this gate. |
| Game Designer | Medium | Special-weapon utility, 20 named overclocks, all six event objectives, 17 quests and source shop conditions now have runtime paths. Short benchmark fixtures and two seeded builds do not certify all combinations. Intentional v3 substitutions are documented in migration. |
| Godot Engineer | Resolved High | Collector's source empty starting weapon caused initialization errors, discovered by all-character replay. v3 starts Collector with Coin Orbit; validators now reject invalid starting weapons. Late-game overclock reroll/banish now retain valid choices or resume the run. |
| Performance Engineer | Medium | Projectile broadphase bottleneck reduced without changing replay collision results. Full 600/500/1000 fixture remains; generated-world and late-boss cases added. Late-boss per-entity radius filtering reduces p95 from16.356 to11.429ms with replay parity. Native cumulative allocation and sustained GPU/thermal performance remain unverified; live-object/static-memory monitors are limited proxies. |
| iOS Engineer | Resolved High | Actual macOS Xcode Release/iphoneos/arm64 app built with signing disabled, then packaged. IPA ZIP, Payload, unique app, plist bundle/name/version, arm64, PCK, Assets.car, launch assets/icons and signature/provisioning absence validated. IPA additionally downloaded/reassembled and independently validated on Linux. |
| iOS Engineer | Medium | Physical iPhone/iPad install, touch latency, notch/orientation, 15/30-minute thermal behavior and Low Power Mode are NOT YET VERIFIED ON REAL DEVICE. |
| QA Engineer | Resolved High | Timer ownership, SoA reuse, stale IDs, spatial reuse, rendering/speed parity, all-character replay, damage accounting, save/purchase recovery, objective failures and seeded clear flow have executable checks. Windows/macOS run the same suites. |
| QA Engineer | Medium | Original v2 test sources remain migration references; they are not all ported/executed and are never counted as passing v3 tests. |
| Release Engineer | High, blocked externally | Accessible PUBLIC repo is `jankendo/-gem-survivor-crystal-field-v3` (leading hyphen). Requested exact-name repo returns404. Rename/create API returns403 despite repository push permission. Existing history was pushed without force; v2 was not written. |
| Release Engineer | Resolved High | Fast, balance, performance and release workflows actually execute. Windows runner exports EXE with embedded PCK, launches bundled-pack smoke, validates ZIP/PE/PCK/README and SHA. macOS builds actual unsigned IPA and uploads SHA plus bilingual signing README. |
| Rights | Medium | Upstream has no license; inherited code/assets do not gain a new license here. LICENSE is a rights-status notice. |
| Presentation | Low | Friendly deployable decoration is simplified; real crowded-combat visibility still needs human review. Silence is intentional. |

No known Critical or fixable High remains after current regressions. External repository-name and human/device High gates remain unverified and are not marked PASS. Per the continuation instruction, a clearly labeled alpha prerelease may be published only after all four required workflows succeed on its immutable main commit; this does not declare the full completion gate met.

Additional review fixes: deploy pull now changes authoritative enemy impulses; periodic poison/reset is owned by StatusSystem and status deaths drain before AI, so a lethally poisoned boss cannot attack. Legacy desktop saves are read-only imported from the original product directory. Boss contact/telegraph death causes are distinct.473 assertions in10 suites cover these regressions.
