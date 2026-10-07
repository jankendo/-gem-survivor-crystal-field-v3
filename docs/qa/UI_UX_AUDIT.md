# UI / UX audit

Baseline main: `9dcae358a8aa5c9fe5ce2d60e599d89c4c212a6f`.
Authoritative existing checkout/history retained. Accessible public repository is
`jankendo/-gem-survivor-crystal-field-v3`; the leading hyphen is intentional,
confirmed by the owner for the alpha.2 mission. No rename is required.
No v2 changes. File inventory/hashes: `evidence/ui-ux-baseline.json`.

## Baseline inventory and dependency trace

Boot has no visible failure view: GameBootstrap validates GameDatabase then silently
returns after push_error. TitleScreen routes to CharacterSelect (combined blessing
cycling), ShopScreen, shared ShopScreen-as-Collection/Quest, SettingsScreen.
Run Setup and separate Blessing Select do not exist. Gameplay HUD includes stats,
long weapon string, goal, actions and separate minimap. Equipment Grid, Boss HP,
reward feedback, save/migration status and first-use guidance are absent.
PauseMenu exposes Resume/Seed/End only. LevelUpPanel selects weapons/passives/
Overclock; evolution/combo are applied without explanations. ContractPanel pauses
for risk choice. Warp has no entry confirmation or wave/status UI. Field events
have an objective line; chest upgrades happen without reward UI. CLEAR uses
RewardPanel, followed by Endless or ResultScreen. Result omits final level/build/
progression details. No confirmation/system dialogs or debug panels exist.

GameBootstrap samples keys + TouchInput in physics; SimulationPipeline ticks only
RUNNING, producing LEVEL_UP/CONTRACT/CLEAR/RESULT. UIController independently hides
panels and directly edits phase, skip counters, choices and contract state.
RunController.select unconditionally refreshes after invalid selections. Pause
cannot preserve an existing modal. Warp directly swaps simulation worlds.
SaveRepository settles once but buy methods mutate memory before flush and do not
rollback failures. SaveMigration validates root types only. HUD cadence is every
six rendering frames, so30/60fps have different UI latency. Rendering snapshots
are read-only; gameplay remains fixed60Hz. Data loads once at GameDatabase startup.
`scripts/systems` does not exist; responsibilities are the app/combat/exploration/
progression modules, not an omitted directory.

## Confirmed findings before fixes

| ID | Severity | Reproduced code/runtime problem |
|---|---|---|
| U01 | Critical | Failed purchase flush retains deducted money/unlocked item in memory |
| U02 | High | Malformed current save silently defaults and may overwrite damaged original |
| U03 | High | TouchInput captures menu/button touches; modal/pause leaves finger movement active |
| U04 | High | UI choose hides modal even for invalid selection; phase/view disagree |
| U05 | High | No transition/double-action guard, meta purchase can repeat unexpectedly |
| U06 | High | Physical iOS canvas scaling leaves text too small;48 logical units is not reliably44pt |
| U07 | High | Long HUD equipment line and separate minimap overlap important stats |
| U08 | High | Boss HP/state missing despite gameplay depending on boss fights |
| U09 | High | Shop enables unaffordable/max upgrades, raw condition dictionary leaks into UI |
| U10 | High | Fatal DB failure leaves blank/unresponsive screen; missing required tables can crash |
| U11 | High | Modal controls have no reliable initial focus/Back behavior or focus isolation |
| U12 | High | Warp.enter mutates worlds before validating invalid portal/phase |
| U13 | Medium | Settings omit saved/effective values; fullscreen is not persisted/applied |
| U14 | Medium | Collection displays only quest text; owned/empty content unclear |
| U15 | Medium | Growth cards omit current/next level, numeric effect and evolution relevance |
| U16 | Medium | Result omits level/build/gems/evolution/meta progress and labels alive finish as death |
| U17 | Medium | No run-end confirmation, copying seed has no feedback |
| U18 | Medium | No first-use contextual guidance or bounded progression notifications |
| U19 | Medium | Buttons clip long Japanese without touch-accessible full description |
| U20 | Medium | UI styles/states lack shared contrast/spacing/selection conventions |
| U21 | Medium | Missing optional icon has no explicit fallback path |
| U22 | Medium | HUD critical updates tied to rendering FPS; strings/layout rebuilt unnecessarily |
| U24 | Critical | Ultra scales renderer but not camera origin: player shifts toward viewport edge/offscreen |
| U23 | Low | Navigation labels and collection heading reused inconsistently |

| U25 | High | Native Japanese wrapping retained old minimum height; small-screen modal footer escaped Safe Area |
| U26 | High | Same-tick final-boss death overwrote player RESULT with CLEAR; kill-heal could revive terminal death |
| U27 | Medium | Unchanged save error rebuilt/focused the system dialog every second; later same-code errors could disappear |
| U28 | High | Closing a system dialog back to HUD left the dialog active because phase sync returned early |
| U29 | Medium | Cached boss generation ID could refer to another world after Warp; repeated600-enemy HUD scan |
| U30 | Medium | Save retry could not reload repaired/backup data; recovered damaged bytes were not preserved separately |
| U31 | Medium | Passive preview displayed additive amount as a multiplier; max-level preview showed invalid next level |
| U32 | Medium | Banish did not explain that it removes the last offered candidate |
| U33 | High | Native Tab focus traversal could consume the advertised gameplay equipment shortcut |
| U34 | Medium | P paused but did not resume; rapid Escape press/release toggled pause twice |
| U35 | Medium | Focus-loss pause omitted the seed/information normally populated by manual Pause |
| U36 | Medium | Previous-run notifications and presentation references could survive into the next run |
| U37 | High | Deferred focus coroutine could resume after UIView disposal and emit an engine error |

| U38 | High | Growth preview omitted cached meta/contract stats, so displayed damage could decrease despite an upgrade |
| U39 | Medium | Result DPS silently included crystal HP; combat and mining totals needed distinct labels |

| U40 | Medium | Initial selector focus scrolled product/character identity and description away; locked Shop omitted owned currency |

| U41 | High | Mobile setup focused the optional seed automatically; keyboard could cover actions and submission had no explicit close/focus behavior |

| U42 | Medium | Single-line equipment slots ellipsized level/max status even with short Japanese names |

All42 tracked findings are addressed by executable changes. Severity at discovery:
Critical2, High18, Medium21, Low1. These counts include problems found while testing
repairs; they are not a count of unverified human/device limitations. No known
fixable Critical/High remains in the audited supported UI flow. New source-code
coverage is14 discovered suites; see committed evidence for exact assertions and CI.

## Final screen inventory and state matrix

The final tree has16 reusable modal/menu scenes plusHUD andMinimap. Separate
Blessing/Run Setup/Collection/Equipment/Confirm/System/Warp entry panels now exist.
Boot is synchronous and short, so no artificial loading spinner. Invalid required
startup data shows a fatal system dialog; optional icons/decorative floor textures
use text/procedural placeholders. Critical player/enemy/boss sprites remain required.
Evolution, Combo, automatic Chest and Field Event rewards are contextual bounded
notifications, not competing modals. Boss warning remains a critical world visual
with separateHUD HP. CLEAR andDeath/Finish use different titles. No debug UI ships.
Full inventory, applicability of all requested states and scored evidence:
[UI_STATE_MATRIX.md](UI_STATE_MATRIX.md).

## Call flow and single source of truth

- GameDatabase parses/cache-normalizes67 JSON tables once. DataValidator rejects
  malformed required definitions/references/ranges/critical assets. Strict CI also
  detects optional missing references. Startup error never enters a run.
- Bootstrap composes views andWorldRenderer; menu selections are presentation state.
  UIActionGate guards button transactions and cross-screen activations. Keyboard
  gameplay shortcuts are routed before native focus handling; menus retain native
  Tab/arrows/Enter/Space plusWASD and consistentEscape Back.
- Character + committedBlessing + validatedSeed createRunController. WorldGenerator
  builds reachable branches/portals from the seeded stream. Player/Progression/Run
  hold gameplay values; presentation snapshots never feed collision/AI/RNG.
- Godot60Hz physics → SimulationPipeline → pending deaths/status(single timer owner)
  → movement/context → spawn/boss budget → queued interaction → enemy movement
  → spatial snapshot(once/tick) → active deploy/weapons/projectiles/combos → contact
  → death → spatial Gem pickup → level offer → exploration/event/Warp. DamageSystem
  owns HP loss/attribution andDeathSystem owns removal. Terminal death outranks CLEAR.
- LevelSystem stores EXP surplus and offers one choice set. RunController validates
  selection before clearing it, then recalculates passives/evolution/runtime/combo.
  Pending contract follows the choice; no rendering-based gameplay event queue.
- UI phase synchronization maps RUNNING/HUD, LEVEL_UP/growth, CONTRACT/risk,
  PAUSED/pause, CLEAR/endless choice, RESULT/result. Settings/Equipment/Confirm/Warp
  entry are child navigation on a suspended run. Pause remembers LEVEL_UP/CONTRACT.
- Warp swaps authoritative worlds and stream, retains main field time/enemies/Gems,
  and restores walkable position. Invalid entry never mutates a world. HUD reads
  lifecycle-maintained generation-safe boss lookup from the currentEnemyWorld.
- SaveRepository caches profile, performs guarded atomic purchases with rollback,
  settles a run once, debounces disk writes, validates temp then replaces withbackup.
  Unrecoverable current data blocks start/purchase; retry can reload validated repair.
  Damaged bytes are retained as.corrupt; legacy source is read-only. Friendly UI
  messages and diagnostic codes are separate.
- HUD HP/boss≤30Hz, objective/build/minimap/feedback5Hz, menus only on state changes.
  Scene nodes/themes remain stable. Notifications deduplicate and cap at4. Full
  longJapanese content stays in scrollable containers; equipment tap reveals detail.

## Modal priority and queue policy

1. Fatal/startup or save system dialog (can suspend any active phase).
2. RESULT/terminalDeath, thenCLEAR/endless decision.
3. Pause and itsSettings/Equipment/Confirm child navigation.
4. LEVEL_UP (EXP surplus remains queued in simulation).
5. CONTRACT (pending contract ID remains queued until the growth choice resolves).
6. Warp entry confirmation (only from RUNNING; it pauses before entry).
7. Context guidance/evolution/combo/reward notifications.
8. HUD/world presentation.

One visible panel + one input-consuming scrim; no modal stacks share input. System
messages hold their view until close/retry, preventing phase sync from replacing them.
No unbounded dictionary event queue: pending gameplay is represented in authoritative
phase/EXP/contract state; cosmetic notifications are bounded and may expire safely.

## Executable/visual verification

-16 viewport entries: sevenWindows sizes, fouriPhone landscape sizes, fiveiPad
 landscape sizes. All16 panels +HUD; populated cards,12 slots,1200+ character
 Japanese descriptions and critical screens at125% type. Synthetic notch44pt each
 side/home21pt, tablet top20/home21pt. Native geometry includes clip ancestors,
 primary footer bounds,48pt targets, focus visibility and unintended button overlap.
- Actual X11/OpenGL llvmpipe images:21 states each at844×390,1280×720,1024×768.
 Dense fixture is600 enemies/500 projectiles/1000Gems/90 effects, without reducing
 population. Also capturedUltra with unchanged simulation signature. Images are
 scripted renderer fixtures, not a human or physical-device session.
- Mobile seed entry reserves the reported keyboard height in logical points; compact
 setup preserves48pt input/footer targets. Synthetic220pt keyboard + notch passes.
 Done closes editing without auto-start; initial mobile focus stays on Start. Actual
 iOS keyboard animation/autofill/height reporting is NOT YET VERIFIED ON REAL DEVICE.
- Native parse_input_event mouse click,Enter/Escape/P/Tab/touch GUI actions; repeat
 and cross-screen guard; multi-touch/outside drag/cancel/disabled movement; selected
 reward once, atomic purchase once, scene disposal, disabled reasons and clear flow.
- Normal HP/population seeded UI command autoplay:65 growth choices, contract,
 Warp enter37088/return37699ticks;3 bosses;CLEAR field933.25s, HP90;Endless → Finish
 → settledResult → Title. Shared QA input agent does not modifyHP/spawn/phase/RNG.
- UI process CPU: baseline vs controlled repaired fixture; lifecycle-maintained
 boss lookup removed the measured repeated600-enemy scan. See[UI_PERFORMANCE.md](UI_PERFORMANCE.md).

## Final expert and user-perspective review

| Perspective | Conclusion / evidence | Limit |
|---|---|---|
| SeniorGameUX | Goal/setup/disabled reason/progress/reward/result now explicit; destructive ends confirm | Human3/5/10/15-minute comprehension/fun NOT YET VERIFIED |
| GodotUI | Containers, stable scene tree, deferred width-first shaping, visible initial focus and teardown checks | Engine-native accessibility integration still needs target OS |
| Gameplay | Invalid selection/warp are non-mutating; pause retains phase; death/CLEAR priority and settlement single owner | All possible build combinations are not human-tested |
| MobileUX | Point-scaled UI, syntheticSafe Area, dynamic joystick cancellation and native GUI touch reachability | Physical notch, touch latency/multi-touch feel NOT YET VERIFIED ON REAL DEVICE |
| Accessibility | Measured panel/button contrast≥4.5:1, body≥7:1, border focus/shape status,100–125% type; named growth buttons | VoiceOver/Narrator behavior and vision-deficiency comfort require real users/devices |
| QA | Data/error/flow/layout/input/regression tests + actual screenshots; noengineERROR tolerated | Autoplay and fixtures do not certify human experience |
| Performance | Critical cadence independent of renderingFPS,5Hz cold displays, stable nodes and bounded feedback | GPU, battery/thermal/native cumulative allocation not measured here |

Beginner: title states exploration/automatic combat/Gems/15-minute goal; contextual
move/growth/Warp guidance is learned once. Experienced: seed/setup, numeric growth,
evolution conditions/equipment and sorted damage shares are reachable quickly.
Mobile:48pt actions, no equipment scrolling, single modal and cancellation; normal
choices/details can scroll without reducing text. PC: native focus/shortcuts/back,
direct selectors and purchase receipt. These are engineering walkthroughs, not four
human playtests or a claim that the game isfun.

## Remaining limitations

- MediumM1: physical iPhone/iPad/interactiveWindows sustained UX, safe-area platform
 conversion, VoiceOver/Narrator, touch latency and thermal transitions are
 NOT YET VERIFIED ON REAL DEVICE. Linux screenshots/synthetic metrics are labeled.
- Historical MediumM2 (resolved in alpha.2): Collection/Quest was a scrollable textual encyclopedia with progress;
 search/filter/sort and shared detail restoration now exist. Large-content human
 navigation speed remains unmeasured.
- LowL1: selected equipment uses shape/text placeholders and full tap detail rather
 than a bespoke art-rich grid. Deliberate clarity/performance tradeoff.
- Unlisted resolutions below the configured desktop minimum or portraitmobile are
 not certified by the landscape matrix; orientation is constrained in project/export.
- Existing rights/human release gates remain as
 documented inSeniorReview. This audit did not create/rename a repository or change
 the immutablealpha.1 binary.

## alpha.2 follow-up

Ten new tracked findings: High4, Medium5, Low1; all ten code defects/omissions
repaired. They are listed in GAMEPLAY_UX_REVIEW.md. The prior42 repaired findings
and their regression guarantees are retained. Search/filter/status/sort use157
real definitions and8 reusable rows. One common DetailPanel presents collection
and equipment data; root Safe Area/focus/Back are shared. Initial equipment is
shown as unlocked. Quest percentages come from raw conditions, not rounded text.

The extra panel joins the16-viewport automatic layout matrix. Native Linux X11
OpenGL captures cover33 fixtures ×3 ratios =99 PNGs, including100/300/600 enemies,
six weapons/combos,1000 Gems/500 projectiles,90 frozen cosmetic effects, Boss
warning/attack/low HP, Warp, Ultra, search/zero/detail/Quest/125%/synthetic keyboard.
The screenshots are renderer fixtures, not real-device or human play sessions.
Actual images were inspected: phone first-row clipping was found and fixed;
detail body scrolls while Back stays reachable; player halo and telegraph outlines
draw above decoration. No pixel-difference score is used as a fun or visibility
certificate. Native OS keyboard raster/animation remains unverified.


Release follow-up High: first-time draft lookup used published-only tag API; actual alpha.2 publication stopped safely before upload. Fixed authenticated paginated listing/Release-ID lookup and publication, with explicit creation/failure/state-change regression;12 Python checks. Empty draft removed;alpha.2 tag retained. New alpha.3 builds rerun from a new final main SHA.
