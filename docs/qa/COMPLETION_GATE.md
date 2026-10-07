# Completion gate — continuation

Status: **PUBLISHED WORKING ALPHA; requested final completion gate NOT FULLY MET**.

| Gate | Actual evidence / status |
|---|---|
| Source immutable | v2 main b9b70807492b673a6836eb6beafe8823f71e6672; reference checkout clean; no commit/push/settings writes |
| Existing history | fac61d1112d33c9cee9957b2c3fb9d03fcaccdaf remains an ancestor; full main history pushed without force |
| Authentication / repository | authenticated jankendo; PUBLIC, main and push permission verified at `jankendo/-gem-survivor-crystal-field-v3`; exact requested name returns404, rename/create403 |
| Godot | 4.7 stable import/parser PASS; scene/gameplay and bundled-pack launch verified |
| Architecture | fixed60Hz, generation-checked authoritative enemy SoA, five-layer spatial index, active weapons, central status/damage, GameDatabase and schema3 atomic save |
| Run goal | 5/10/15-minute bosses, CLEAR, Result and Endless schedule have executable checks; normal-HP ranged and genuine close-range seeded builds CLEAR |
| Gameplay | 31 weapon archetypes/utilities, passives/evolution/combos, 20 named Overclocks, all six event IDs, six gimmicks, Warp/exploration and quest/shop conditions connected; intentional v3 differences documented |
| QA | 473 assertions / 10 discovered suites PASS; 67 data tables PASS. Includes all27 character 30/60fps and1x/2x replay, exact cooldown owner, stale IDs, query reuse, original-query collision replay, save/purchase recovery and UI/iOS invariants |
| Source tests | v2 references preserved; not all ported/executed, not counted in v3 PASS total |
| Balance | 310 scenarios PASS; stationary boss weak43.45/median25.71/strong12.71s; seed60606 ranged/melee CLEAR at923.78/976.75s. Actual dodging TTK23.78/76.75s remains a tuning caveat |
| Performance | full600/500/1000 CPU fixture retained; final open mean6.137/p957.565ms; generated world6.808/10.003ms; late70-radius boss7.247/11.486ms. Native cumulative allocation and heavy GPU effects are not verified |
| Windows | actual Windows runner Release EXE with embedded PCK, native headless pack smoke, ZIP/PE/PCK/README and SHA validation; artifact uploaded |
| iOS | actual macOS Xcode Release/iphoneos/arm64 with signing disabled; actual IPA package/structure/plist/arm64/PCK/Assets.car/launch/icons/no provisioning/no Apple distribution signature and SHA validation; artifact uploaded with bilingual README |
| Independent IPA verification | downloaded/reassembled actual run37568720237 IPA; validator PASS, SHA aa79e26e8cf472a057dc887264b1bc45820dd79d63359fec0d9c432a69840fbf. This SHA identifies that run, not every later rebuild |
| CI | Fast37575095088 and Performance37575095063 on71b0fd0: actual473 assertions and full-load measurements downloaded and verified; Balance37575095057 and native build37575095194 successful. Current-main four immutable gates must be read from Actions; release_gate.py enforces them before any tag publication job |
| Release/tag | [v3.0.0-alpha.1](https://github.com/jankendo/-gem-survivor-crystal-field-v3/releases/tag/v3.0.0-alpha.1) created fromde85d2ad3e098170b2049d1b36e80c410f609f35 after all four main gates PASS. Tag build37575792348 native Windows/macOS and publish job PASS; both archives, SHA256SUMS.txt and bilingual signing README attached. External/human gates remain unverified |
| Human device/playtest | NOT YET VERIFIED ON REAL DEVICE; no human enjoyment, installation, touch latency or sustained thermal/battery PASS claim |

Actions and artifacts: https://github.com/jankendo/-gem-survivor-crystal-field-v3/actions . Measurements are Linux headless CPU, not real iPhone results. See SENIOR_REVIEW.md, MANUAL_PLAYTEST.md and IOS_REAL_DEVICE_CHECKLIST.md for unresolved High/Medium items.

Published IPA independently downloaded/reassembled and validated: SHA25636540c48cced830cb07bcbfa4acf01760f2fcb15e4c0d60312dd6fc5861696e2 matches the Release asset digest. The alpha tag remains immutable; later documentation commits do not alter the released runtime. Full validation provenance: `evidence/alpha-release-verified.json`.

## UI/UX audit gate (runtime744e994)

- Local parser/import and67-table validation PASS;1,510 assertions /14 suites PASS.
- Native mouse/key/touch-event and layout checks execute;16 requested viewport
  entries include all panels/HUD, long Japanese, full equipment and125% type.
- Actual Linux X11/OpenGL screenshots are scripted fixtures at844×390,1280×720,
  1024×768. They are not screenshots from Windows/iPhone or a human session.
- Normal-HP seeded UI autoplay reaches three bosses/CLEAR, continues Endless,
  finishes once, settles once and returns to Title. No HP/population overrides.
-42 tracked code/UI findings repaired; fixable UI Critical/High0. Physical-device
  Touch/SafeArea/Accessibility/human UX gates remain NOT YET VERIFIED ON REAL DEVICE.
- Immutablealpha.1 predates these UI fixes. Current main Actions binaries contain
  them; do not present the old tag as the new UI release.

See UI_UX_AUDIT.md for remaining2Medium/1Low limitations and their rationale.
Final GitHub workflow/HEAD verification is reported separately from local tests.
