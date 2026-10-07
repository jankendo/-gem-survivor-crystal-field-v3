# Balance

Tuning is in `v3_balance.json`, `v3_weapons.json` and `v3_passives.json`. Definitions preserve original names/icons/recipes. Spawn uses target alive, refill tokens and threat cost; rate multiplier is applied once. Population is not balanced around the 600 safety ceiling.

`tests/benchmark.gd -- --mode=balance` runs every weapon against single boss, 30/100/300/600 targets, narrow corridor, open field, moving swarm, elite mix and high-mobility boss. Recorded metrics include actual DPS, damage, kills/sec, boss DPS, damage/target, active-damage coverage, overkill, status coverage, measured utility and proximity risk. Five-second fixtures are deliberately short CI samples, not sustained build tests.

Initial analysis found excessive close-range target counts and weak single Projectile growth. Tuning added data-driven Projectile count/pierce progression, corrected Beam classification, reduced aura/orbit base damage, lowered melee target caps and raised deploy damage. These choices retain coverage/risk identities; no claim of final human-approved balance is made.

Boss TTK derives from measured representative stationary build DPS. Strong/median/weak variants are reported separately. Mechanics, mobility, upgrade luck and human dodging remain outside this stationary estimate. Seeded autoplay is a separate gate rather than treating this proxy as a full run.

## Continuation result

310 scenarios PASS. Stationary final-boss TTK: weak 43.45s / median 25.71s / strong 12.71s, within the stated benchmark ranges. Boss HP changed from references [30,75,630] to [30,225,435] after actual scheduled fights exposed a four-second second boss and a 59-second ranged final boss.

The initial single-weapon scenario average ranged from sonic_wave 40.23 to magic_bolt 328.77 DPS. Magic Bolt base damage was reduced from 7.74 to 5.4. Radial knockback, persistent deployables, gem utility and crowd caps were restored before comparing identities. The final averages range from Black Hole 34.58 (pull/control/collection utility) to Blade Fan 262.63 (short-range exposure); Magic Bolt averages 231.13 and Ice Orbit 167.19. These are scenario averages, not a rule that every utility weapon must have equal DPS. High-mobility boss fixtures can legitimately yield zero for an untriggered stationary mine/wall.

The first “close” replay still used Noah's starting Magic Bolt and kited outside much of its aura range. It was replaced with Mio and four actual close weapons, with normal HP. Crowd coverage of ice/poison/arc was adjusted after this build failed. The bot now prioritizes boss warnings over dash warnings and checks intermediate floor positions instead of only the escape endpoint. No health, spawn population or gameplay RNG was overridden to force a clear.

Seed60606 status-owner runtime: ranged CLEAR at 923.78s, HP112; body-aware melee replay CLEAR at 976.75s, HP93.25. Actual final-boss TTK23.78s / 76.75s includes conservative dodging and differs from stationary estimates. Both clears are now required by Balance CI; failed runs return nonzero rather than reporting unconditional success. The moving/dodging TTK is slightly above the target guidance and remains a playtest tuning item.

A separate five-second utility fixture measures gem/enemy displacement, pickup count, mining damage, shield uptime and bonus currency. Black Hole measured892.95 enemy displacement,5160 gem displacement and20 pickups; Gravity measured300.95 enemy displacement and20 pickups. Laser mining damage34.04 and Guardian shield uptime0.16 were measured. These fixtures isolate utility and are not the normal-HP autoplay or the600-enemy performance fixture. Definitions promising utility must produce a positive measured effect. Poison is periodic damage, not crowd control.

Five-second scenarios and one autoplay seed are limited evidence. Human weapon-choice diversity, risk/reward and enjoyment remain **NOT YET VERIFIED ON REAL DEVICE**. Source test references are not proof of full behavioral parity.

## alpha.2 multi-seed実戦評価

Actual hosted Nightly run37698440750 atf44837d780990bedb0af9299c681b85d397ba48e
completed six identities ×five seeds60606,20261007,314159,271828,9001 (30 runs).
Normal HP/spawn, tick-indexed bot, actual choices and108000-tick Endless cap.
27/30 reached CLEAR and chose Endless; three pure-deploy deaths occurred before
CLEAR. Eleven runs still running at30 simulation minutes are TIME_LIMIT after
CLEAR, never reported as finished Results. Other cleared builds eventually died
in Endless. Valid measurement PASS is separate from victory or human fun.

| Identity | CLEAR /5 | Final-boss moving TTK range (s) |
|---|---|---|
|area|5/5|82.15–150.02|
|deploy|2/5|97.67–112.47|
|hybrid|5/5|33.05–132.23|
|melee|5/5|95.63–144.05|
|ranged|5/5|14.60–45.82|
|utility|5/5|132.13–209.03|

Detailed evidence: `qa/evidence/alpha2/nightly-measured.json`; full input histories
remain in the immutable Nightly artifacts. It includes damage/hits, HP at boss
spawn/death, warning/dodging ticks, geometric attack opportunity, evolution timeline,
Warp use, choices, loadout and death source. This is not landed-attack uptime.

First3 minutes produced16–26 choices; first5 produced26–38; first10 42–64
except the early deploy death (36). Surviving builds generally select59–65
choices by15min; progression can continue without empty/max choices once no valid
offer remains. Growth counts/EXP are preserved. No same-tick consecutive choices
in these measured runs. Average human modal display/reading time is **unmeasured**:
bot decision execution is not an estimate of it. Full-run averages include long
Endless periods and must not hide early interruption frequency. Required human
playtest measures the actual dwell/tempo before any EXP/choice-count change.

Strict four-weapon/six-passive all-max selection replay, when observed, occurs
at541.60–745.60s. Null values in diagnostics mean that this strict candidate metric
was not observed, not that evolution/build formation failed. Real evolutions have
separate field-tick timeline entries; clock-only completion now refreshes once per
second without a subsequent choice. Growth cards show actual next values, full
conditions, time unmet/owned partner/max status instead of automated recommendations.

Pure-deploy bot CLEAR2/5 and utility TTK132–209s are tuning caveats. Bot movement
can leave friendly static deployables; an opportunity-envelope counter does not
represent effective mine/wall placement. No universal DPS equality, HP-only nerf,
forced invulnerability or gameplay population reduction was applied. QA warning
geometry was corrected to actual circles/segments: melee314159 final TTK301.25
->144.05s with unchanged game damage/HP but different input policy, not a claimed
weapon buff. A boss-priority targeting experiment was rejected after failing to
establish improvement. Human build/positioning comparisons remain required before
retuning these identities. Stationary310 scenarios/utility invariants and old
normal-HP ranged/melee CLEAR gates remain unchanged and continue in required CI.
