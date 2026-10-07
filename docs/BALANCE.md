# Balance

Tuning is in `v3_balance.json`, `v3_weapons.json` and `v3_passives.json`. Definitions preserve original names/icons/recipes. Spawn uses target alive, refill tokens and threat cost; rate multiplier is applied once. Population is not balanced around the 600 safety ceiling.

`tests/benchmark.gd -- --mode=balance` runs every weapon against single boss, 30/100/300/600 targets, narrow corridor, open field, moving swarm, elite mix and high-mobility boss. Recorded metrics include actual DPS, damage, kills/sec, boss DPS, damage/target, active-damage coverage, overkill, status coverage, utility descriptors and proximity risk. Five-second fixtures are deliberately short CI samples, not sustained build tests.

Initial analysis found excessive close-range target counts and weak single Projectile growth. Tuning added data-driven Projectile count/pierce progression, corrected Beam classification, reduced aura/orbit base damage, lowered melee target caps and raised deploy damage. These choices retain coverage/risk identities; no claim of final human-approved balance is made.

Boss TTK derives from measured representative stationary build DPS. Strong/median/weak variants are reported separately. Mechanics, mobility, upgrade luck and human dodging remain outside this stationary estimate. Seeded autoplay is a separate gate rather than treating this proxy as a full run.

Final evidence: 310 scenarios executed; stationary final-boss TTK weak 52.92s / median 29.49s / strong 14.65s. Seed60606 normal-HP autoplay defeated two bosses in each build, then died at 912.63s / 919.98s. No successful full-run CLEAR is claimed for the final tuning. Mean scenario DPS remains spread from sonic_wave 40.23 to magic_bolt 328.77; coverage/utility differences do not excuse missing unique behavior. Balance completion is blocked pending outlier/identity review and human tests.
