# Balance

Tuning is in `v3_balance.json`, `v3_weapons.json` and `v3_passives.json`. Definitions preserve original names/icons/recipes. Spawn uses target alive, refill tokens and threat cost; rate multiplier is applied once. Population is not balanced around the 600 safety ceiling.

`tests/benchmark.gd -- --mode=balance` runs every weapon against single boss, 30/100/300/600 targets, narrow corridor, open field, moving swarm, elite mix and high-mobility boss. Recorded metrics include actual DPS, damage, kills/sec, boss DPS, damage/target, active-damage coverage, overkill, status coverage, utility descriptors and proximity risk. Five-second fixtures are deliberately short CI samples, not sustained build tests.

Initial analysis found excessive close-range target counts and weak single Projectile growth. Tuning added data-driven Projectile count/pierce progression, corrected Beam classification, reduced aura/orbit base damage, lowered melee target caps and raised deploy damage. These choices retain coverage/risk identities; no claim of final human-approved balance is made.

Boss TTK derives from measured representative stationary build DPS. Strong/median/weak variants are reported separately. Mechanics, mobility, upgrade luck and human dodging remain outside this stationary estimate. Seeded autoplay is a separate gate rather than treating this proxy as a full run.

## Continuation result

310 scenarios PASS. Stationary final-boss TTK: weak 43.45s / median 25.71s / strong 12.71s, within the stated benchmark ranges. Boss HP changed from references [30,75,630] to [30,225,435] after actual scheduled fights exposed a four-second second boss and a 59-second ranged final boss.

The initial single-weapon scenario average ranged from sonic_wave 40.23 to magic_bolt 328.77 DPS. Magic Bolt base damage was reduced from 7.74 to 5.4. Radial knockback, persistent deployables, gem utility and crowd caps were restored before comparing identities. The final averages range from Black Hole 34.58 (pull/control/collection utility) to Blade Fan 262.63 (short-range exposure); Magic Bolt averages 231.13 and Ice Orbit 167.19. These are scenario averages, not a rule that every utility weapon must have equal DPS. High-mobility boss fixtures can legitimately yield zero for an untriggered stationary mine/wall.

The first “close” replay still used Noah's starting Magic Bolt and kited outside much of its aura range. It was replaced with Mio and four actual close weapons, with normal HP. Crowd coverage of ice/poison/arc was adjusted after this build failed. The bot now prioritizes boss warnings over dash warnings and checks intermediate floor positions instead of only the escape endpoint. No health, spawn population or gameplay RNG was overridden to force a clear.

Seed60606 final replay: ranged CLEAR at 943.73s, HP112; melee CLEAR at 974.38s, HP96.8. Actual final-boss TTK43.73s / 74.38s includes conservative dodging and differs from stationary estimates. Both clears are now required by Balance CI; failed runs return nonzero rather than reporting unconditional success. The moving/dodging TTK is slightly above the target guidance and remains a playtest tuning item.

Five-second scenarios, one autoplay seed and utility descriptors are limited evidence. Human weapon-choice diversity, risk/reward and enjoyment remain **NOT YET VERIFIED ON REAL DEVICE**. Source test references are not proof of full behavioral parity.
