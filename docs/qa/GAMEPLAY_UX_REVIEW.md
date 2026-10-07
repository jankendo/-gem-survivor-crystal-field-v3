# Gameplay UX / alpha.2 review

Start main: `1ae9eb5d98bc7effaf46c602bccf655dc7c63489`. Public source is
`jankendo/-gem-survivor-crystal-field-v3` (leading hyphen is intentional). v2 read-only.
Previous42 fixes and1510 checks are retained; the equipment description assertion
now targets the isolated DetailPanel, preserving the full-name guarantee.

## Decisions and boundaries

| Change | Player benefit / impact | Stability/performance/complexity | Regression control |
|---|---|---|---|
| Collection search/filter/sort and8 reusable rows | Find actual weapons/passives/evolutions/combos/characters/quests; distinguish owned/progress | Cold cached definitions, bounded UI tree, no rebuild on keystroke | Combined filters, zero state, scroll restoration, keyboard and layout |
| Shared BuildDetails | Full equipment name/effect/current/next/evolution/combo; accurate growth context | Cold state clone; no RNG/live-state edits; shared detail scene | Numeric previews/ownership/long Japanese/input |
| CriticalVisuals final world layer | Player and telegraphs survive cosmetic overlap | One reusable Node; read-only snapshot; Ultra preserves critical layer | Z ordering, actual three-aspect-ratio fixtures and parity |
| Evolution tick check | Time/unique conditions activate even after build maxes |60Hz authority, check once per60 ticks; refresh cache only on change |5/10-minute no-choice regression; same-render replay |
| Corridor pursuit correction | Boss/enemies can reach corridor targets instead of pressing against walls | Same existing25-room graph; no new nav service | Three seeds, room/corridor/perpendicular routes |
| Central received-damage counters | Actual hit/boss damage visible and measurable despite regen | Update only on accepted hit; no always-on telemetry | Invulnerability counts once; QA read-only |
| No new currencies/EXP nerf/HP-only boss nerf | Preserve growth and identities | Existing mechanics unchanged apart from bugs | Existing balance/normal-HP gates |
| Versioned manifest/reusable publish | Actual latest IPA accessible without artifact expiry | Bind both platforms to checkout SHA/tag; immutable old release | Source/hash/version validation and7 Python tests |

## Processing audit

Boot/database rejects malformed required data; Title/setup/selection retain guarded
commands. Physics owns movement, AI, contact, weapons, status(single owner), Gems,
EXP, evolution/combo and progression. Damage/Death retain central attribution and
terminal priority. Exploration/events/chests/Warp use seeded streams and safe floor;
main field freezes in Warp. CLEAR and Endless remain one mode. Result/Quest/shop
settlement and save rollback retain schema3 and legacy read-only migration. Settings,
render profiles and mobile keyboard affect presentation only. No online QA/audio.

## Confirmed follow-up issues

- High: evolution depended on a subsequent choice after its time condition.
- High: effects atz2 could cover player/warnings atz0.
- High: corridor targets bypassed floor-aware pursuit, producing stalled AI/Boss fights.
- Medium: initial weapons appeared unowned and were described as needing a purchase.
- Medium: collection text was not searchable/filterable and lacked structured progress.
- Low: full equipment relationships/effects were embedded in the grid's summary.
- High found during implementation: phone search toolbars left only a clipped first
  result; fixed footer, removed empty-reason minimum height and moved result count
  into title. New test requires a visible≥44pt first-result target.
- Medium: growth cards repeated the same evolution explanation. Removed the
  duplicate while retaining live requirements and numeric comparisons.
- Medium: real weapon categories only had English search aliases; added common
  Japanese category names to search, equipment and growth.
- Medium (QA harness): warning endpoint distance240 treated safe positions as
  dangerous regardless of actual circle/segment geometry, biasing boss TTK.
  Corrected the QA input policy; added actual-danger/safe-warning regressions.

Scores from the prior UI rubric are engineering estimates, not a human fun rating.
New screens follow shared18pt body,48pt actions, contrast/focus/containers and root
Safe Area. Keyboard compact mode preserves Search/Clear/Back without auto-starting.

## Executable evaluation method

`tests/gameplay_quality.gd` covers six representative identities and seeds60606,
20261007,314159; nightly expands seed set. Normal HP/spawn and actual progression.
Deaths/time limit are explicitly recorded, not converted to CLEAR. Autoplayer
samples direction every6 ticks; this conservative bot is not a human skill model.
`RunDiagnostics` is in tests only. Records timeline, input segments, selected
choices, evolution, bosses, net outcomes and exact accepted damage counters. Geometric
attack envelope is not guaranteed landed damage, and bot selection execution time
is not human reading/UI dwell time. Replay commands are tick-indexed.

Regular CI separately retains required normal-HP ranged/melee Seed60606 clears,
310 weapon scenarios, and adds three-seed representative runs. All27 characters
receive initial equipment/stat/trait/choice/save-unlock checks plus prior replay parity.

No EXP or growth count is reduced to lower interruptions. Existing invalid/max
candidate exclusion stays; queued EXP is explained and growth cards show actual
owned relationships. Human selection/dwell/comprehension/fun remains unmeasured.

Final measured outcomes and limits are appended only after execution.

## Measured flow / diagnosis

Normal-HP UI flow at runtimec9cca5d:64 selections through actual guarded UI;
Warp entry38368/return39046, field paused during Warp; three bosses/CLEAR at
966.97 field seconds, HP112; Continue Endless, settle once, Result and Title PASS.
Local wall301.81s with CPU contention versus hosted85.05s; neither is a human
15-minute session. Full16-viewport matrix and99 real Linux-rendered fixtures have
zero detected critical rectangle errors. Physical Windows/iOS UX is unverified.

Before QA geometry correction,18 normal-HP runs (6 builds ×3 seeds) recorded
10CLEAR/3 deaths/5 time limits. See gameplay-before-bot-geometry.json; no forced
HP/spawn overrides. Choices43–65, about3.27–6.74/min, no consecutive choices
within one simulation tick in those runs. Bot selection execution milliseconds
are recorded but human panel dwell/reading duration is NOT measured.

Melee314159 originally required301.25s for final Boss and then reached Endless
before dying at1290.68s. A boss-priority targeting experiment did not establish
an improvement and was not adopted. QA geometry correction, with unchanged game
HP/damage/targeting, reaches CLEAR at1044.05s, final Boss144.05s, HP97.1;
11 accepted hits/159.9 received damage. This comparison changes the input policy,
so it is evidence of bot bias, not a claimed game DPS buff. Range opportunity is
geometric, not guaranteed hit uptime. Boss TTK remains a human tuning caveat.

New nightly harness runs5 seeds per identity and can continue to108000 total
ticks. TIME_LIMIT is explicit; an Endless run may have clear=true while still
running at that limit. Default short CI retains required normal-HP Seed60606
ranged/melee CLEAR separately from measurement validity. See BALANCE.md for
executed additional outcomes; no automatic selection is presented as best for
a human. QA diagnostics stay local and are excluded from exported runtime.

Final executed Nightly atf44837d:30 runs across six identities/five seeds,27 CLEAR,
pure-deploy2/5; all seven jobs passed. TTK and interruption-frequency tables are
in BALANCE.md. Diagnostic summary retains per-choice/timeline/actual damage, while
full tick-indexed inputs remain in Actions artifacts to avoid shipping repetitive
QA traces. Local final regression count1766/17 suites, release-tool checks7, data
tables67. Three frozen native captures each33 fixtures:99 images, detected critical
rectangle errors0. Images inspected include dense player/boss telegraphs, growth
comparisons and detailed Japanese collection entries; automated geometry is not
a human judgment of every screen's readability. Logical Safe Area/focus/keyboard
checks do not certify a physical OS keyboard or installation.

High release issue discovered in actual tag workflow: published-only tag lookup did not return newly created draft. Publication safely stopped; authenticated paginated listing/Release-ID verification/publication now tested. Alpha.3 rebuild contains all these gameplay/UI fixes; previous alpha.2 tag is retained but was never a public Release.
