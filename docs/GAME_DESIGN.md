# Game design

探索 → 撃破 → ジェム回収 → 装備成長 → 進化/連携 → 危険報酬 → ボス。

BUILD is Weapon / Passive / Evolution / Combo / Overclock. RISK is room choice, mining, field event, contract and Warp. META is purchased permanent equipment/characters/blessings, base upgrades, collection and mastery. Resonance presents a room-discovery burst without multiplying independent streak displays.

The seeded world has 25 connected rooms and orthogonal corridors. Safe, mining, risk, event and shortcut routes offer different rewards. Drops project onto the shared safe-floor contract. Portals are separated and visible in-world. Enemy pursuit uses room waypoints to avoid wall trapping.

Bosses appear at 5, 10 and 15 minutes. The third boss produces CLEAR; players end and settle or continue Endless, including 30-minute bosses. Bosses lock telegraph targets before attacks; movement can evade them. HP derives from reference build DPS × target TTK and linear Endless pressure rather than multiplying exponential curves.

Every original weapon ID remains available through an archetype definition. The archetypes are shared behavioral foundations; special strategies are mapped to v3 utilities and pooled deployables; exact v2 trajectory equivalence is not claimed. Projectile grows count/piercing, chain selects a group, beam covers a segment, orbit/aura defend nearby space, deploy/explosion punish clusters, melee trades reach for coverage. Evolution preserves original recipe IDs. Combos retain both weapons and use separate damage sources.

Some v2 concepts are intentionally condensed: emergency_route becomes low-HP movement; safe_pocket gives a death-settlement bonus. Original data is recoverable from the source baseline. Detailed content parity requires the migration matrix; the current build must not be advertised as full v2 content parity.

The game remains silent. No borrowed music, sound or online service is added. Human judgments about fun, enemy visibility, decision quality and desire to replay remain a formal unexecuted quality gate.

alpha.2 keeps the same loop and tuning data. The5/10-minute time conditions are
checked once per simulated second even when no growth candidate remains. Corridor
goals use the same connected-room pursuit logic as room goals. Neither fix depends
on rendering FPS. Shared build details expose actual owned requirements;
comparison cards omit duplicate explanation rather than reducing EXP or choices.
See docs/qa/GAMEPLAY_UX_REVIEW.md for tempo and explicit autoplay limitations.
