# Senior review — continuation, 2026-10-07

The original fac61d1 history is retained. The canonical public repository is
`jankendo/-gem-survivor-crystal-field-v3`; the leading hyphen is intentional and
confirmed by the owner. Human/device quality gates remain unverified.

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
| Release Engineer | Resolved | Repository identity clarified by owner. Authenticated jankendo, PUBLIC/main/ADMIN confirmed; existing history pushed without force; v2 not written. |
| Release Engineer | Resolved High | Fast, balance, performance and release workflows actually execute. Windows runner exports EXE with embedded PCK, launches bundled-pack smoke, validates ZIP/PE/PCK/README and SHA. macOS builds actual unsigned IPA and uploads SHA plus bilingual signing README. |
| Rights | Medium | Upstream has no license; inherited code/assets do not gain a new license here. LICENSE is a rights-status notice. |
| Presentation | Low | Friendly deployable decoration is simplified; real crowded-combat visibility still needs human review. Silence is intentional. |

No known Critical or fixable High remains after current regressions. Human/device
quality gates remain unverified and are not marked PASS. An alpha prerelease may
be published only after all four required workflows succeed on its immutable
main commit; this does not declare human/device acceptance complete.

Additional review fixes: deploy pull now changes authoritative enemy impulses; periodic poison/reset is owned by StatusSystem and status deaths drain before AI, so a lethally poisoned boss cannot attack. Legacy desktop saves are read-only imported from the original product directory. Boss contact/telegraph death causes are distinct.473 assertions in10 suites cover these regressions.

## UI/UX follow-up review — runtime744e994

Full audit/state matrix/performance evidence: UI_UX_AUDIT.md, UI_STATE_MATRIX.md,
UI_PERFORMANCE.md. All42 tracked implementation findings repaired (2Critical,
18High,21Medium,1Low at discovery). Fixable **UI code** Critical/High remaining0;
this does not close the human playtest gates.

UX: explicit start goal, selection differences, disabled conditions and results;
UI: cached Containers, native focus, width-first Japanese layout, modal single owner;
Mobile: point-based Safe Area,48pt actions, keyboard-aware seed entry and neutral
joystick; Accessibility: contrast/name/focus/shape/type scaling; QA:1,510 assertions,
16 viewport entries,63 actual Linux render fixtures, normal-HP clear/endless/result
flow; Performance:30Hz critical/5Hz contextual and lifecycle boss lookup.
No known fixable Critical/High emerged in the final engineering walkthrough.

## alpha.2 final engineering review

| View | Status / evidence | Remaining limitation |
|---|---|---|
| Game Designer / UX | Full loop and normal-HP UI commands exercised; evolution timer and corridor pursuit repaired; no EXP/count/HP-only nerf | Bot success is not human comprehension/fun; long melee/utility TTK needs human comparison |
| Godot / UI | Cached searchable collection,8 reusable rows, shared read-only details; no duplicated simulation state; growth descriptions deduplicated | Phone cards/details can require scroll; human navigation efficiency unmeasured |
| Mobile / Accessibility |48pt actions, logical Safe Area, keyboard compact mode and125% typography regressions; critical shape/outline above FX | Physical IME/gesture dismissal/VoiceOver/touch/thermal NOT YET VERIFIED ON REAL DEVICE |
| Performance | Same600/500/1000 fixture, component profiles and full process RSS; stable301 UI nodes and six-run exact node cleanup | Native cumulative allocation, GPU/effects frame time and thermal remain unmeasured; isolated worst ticks retained |
| QA | Prior1510 checks retained, new character/search/detail/route/cleanup/geometry checks; seeded timeline/input/local JSON isolated from shipped runtime | v2 references are not all executable v3 tests; autoplay has identity/route bias |
| Release | Versioned same-SHA manifests, binary validation, complete-draft publication and independent public re-download tool | Publication requires actual same-final-SHA4 green workflows; document alone is not proof |

Code issue count for this follow-up: Critical0; fixable High0 after repairs. Human
fun remains an **unverified High acceptance gate**, not a demonstrated code defect.
Medium: device/accessibility, representative combat tuning and upstream rights;
Low: art placeholders and minimum-phone detail scrolling are deliberate limits.
Never present unexecuted human/device items as PASS or move alpha.1.
Physical iOS keyboard/VoiceOver/gesture feel, Narrator, novice understanding/fun and
sustained GPU/thermal measurements remain NOT YET VERIFIED ON REAL DEVICE.

## alpha.3 release recovery

Actual main3cae956 had all four required workflows green;tag build37703164950
produced validated Windows and unsigned arm64 IPA. Publication stopped at draft
lookup: GitHub's published-only `GET /releases/tags/:tag` returns404 for a draft.
No incomplete public Release was created. Empty draft406253234 was removed;
alpha.2 tag still points to3cae956 and is not moved. Source now uses authenticated
paginated release listing and stable Release ID for draft validation/publication.
First-creation regression reproduces that API contract;12 Python checks PASS.
App build metadata is read from actual export presets instead of hardcoded values.
New alpha.3 /iOS30003 /Windows3.0.0.3 is rebuilt on its new final source SHA;
alpha.2 artifacts are never substituted. Gameplay source/1766 assertions are
unchanged by this release-only repair. Final required CI/public verification must
be executed again at the new SHA; evidence is reported at delivery/manifest.

## alpha.4 authoritative creation/transport recovery

Actual alpha.3 tag37705013424 again built/validated both platforms, but the
new draft was absent from the immediate authenticated list. It stopped before
upload/publication; draft406260273 remains private for the controlled live probe.
Tagsalpha.1/2/3 are never moved. The final publisher no longer re-queries an index
after creation: REST POST returns the authoritative ID/upload URL, files stream
directly to that ID, and ID-based metadata/asset hashes guard publication.
Partial retries skip matching assets; public releases cannot be overwritten.
15 Python checks include an index that never updates, tag/source mismatch,
partial resume and upload-host/public-release protection. Workspace direct upload
received401 (not successful); the same small, automatically cleaned probe runs
under actual Actions token against an unpublished draft via release-protocol.yml.
Probe success must be read from the actual run, never assumed. New alpha.4 builds
with iOS30004/Windows3.0.0.4 and new final SHA; prior binaries are not substituted.
