# Completion gate — alpha.2 continuation

Start main `1ae9eb5d98bc7effaf46c602bccf655dc7c63489`; original fac61d1 history
retained. Canonical PUBLIC repository is `jankendo/-gem-survivor-crystal-field-v3`
(the intentional leading hyphen is confirmed by the owner). Authentication jankendo
and ADMIN/write confirmed; v2 baselineb9b70807492b673a6836eb6beafe8823f71e6672
reference remains read-only and untouched. No force push or replacement repository.

| Gate | Executed evidence / limitation |
|---|---|
| Engine/data | Godot4.7 stable import/parser and67-table validation PASS; engine wrapper treats SCRIPT ERROR as failure |
| Architecture | Fixed60Hz, authoritative generation-checked SoA, shared spatial queries, one status owner/central damage, active weapons, cached database/schema3 remain covered |
| Local regressions |1766 assertions /17 discovered suites PASS, plus7 release-tool Python checks. Prior1510 guarantees retained; detail assertion moved to shared detail scene |
| Character coverage | All27 starting equipment/stats/traits/choices/unlock and prior deterministic replay checks |
| Simulation/save |30/60fps,1x/2x andStandard/Ultra parity; schema3/v2 read-only import, corrupt recovery, purchase/settlement rollback and duplicate-command regressions PASS |
| Gameplay loop | Normal-HP actual UI commands:64 choices, contract, Warp, three bosses/CLEAR at966.97 field seconds, Continue Endless -> finish once -> Result -> Title PASS |
| Multiple seeds | Hosted Nightly37698440750: six identities ×five seeds =30 valid measured runs,27 CLEAR; deploy2/5. Deaths/incomplete Endless outcomes are retained, not renamed CLEAR |
| Balance |310 scenario/utility/stationary-TTK checks and required normal-HP ranged/melee clear gates; actual moving-boss identity differences remain human tuning limits |
| Collection/Quest/details | Search/filter/sort/zero state/real progress/shared full names/numeric growth/evolution/combo conditions/restoration/keyboard dismissal tested |
| Layout |928 layout assertions,16 requested viewport entries/17 panels;99 actual Linux X11/OpenGL images at3 ratios; detected critical rectangle errors0. Logical Safe Area,125% type, long Japanese/keyboard covered |
| Input | Native synthetic mouse/key/touch/focus/joystick/cancellation/modal/duplicate actions PASS; physical gestures/IME/input latency unverified |
| Performance | Same local600/500/1000 open before6.128/p957.538ms -> after5.927/p956.393ms. Generatedworld6.500/p959.851; lateboss6.987/p9511.461ms; no per-device claim |
| Endurance |108000 ticks, six Warps, two combos, event capacity512, object delta0; actual peak RSS108.94MiB. Mean4.363/p955.190/p996.483ms, all-tick max38.336ms; accelerated not real-time30min |
| UI lifetime/cost |301 stable UI controls; no per-search rebuild;30Hz/60Hz UI means8.48/4.57 microseconds on isolated fixture; six-run exact Node cleanup |
| Native release | Earlier continuation Windows/macOS builds actually succeeded. New final-main exact-SHA native builds/publication must succeed before latest delivery; older IPA is never substituted |
| Release integrity | Generic same-SHA four-workflow gate, exact version/source/byte manifests, complete-draft publication and independent public re-download verifier implemented/tested; execution status belongs to actual final Actions/manifest |
| Human/device acceptance | NOT YET VERIFIED ON REAL DEVICE. No human fun, gesture feel, physical Safe Area/keyboard, sustained GPU/thermal/battery, accessibility reader or installation PASS claim |

Known code Critical0 and fixable High0 after ten follow-up repairs (High4/Medium5/
Low1); previous42 fixes retained. Human enjoyment is a separate **unverified High
acceptance gate**. Medium limits: long mobile/utility boss TTK and pure-deploy bot
bias, real devices/accessibility/native allocations/GPU, worst-tick spikes, upstream
rights and incomplete execution of v2 reference tests. Low: simplified art and
minimum-phone detail/card scrolling. See SENIOR_REVIEW, BALANCE, LONG_RUN_STABILITY,
UI_UX_AUDIT and MANUAL_PLAYTEST. This is an alpha preview, not completed human/device
acceptance. Exact final public bytes/SHA are verified by RELEASE_VERIFICATION's
executable procedure and reported at delivery, without changing source after build.

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
