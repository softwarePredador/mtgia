# Battle Rule Derived Tag Review - 2026-06-11

Status: report-only. No PostgreSQL apply is allowed from this review.

Scope: evaluate whether trusted `card_battle_rules` can safely propose missing
`card_function_tags` without flattening multi-function cards, multiplying deck
rows or letting Hermes become the product source of truth.

Owner constraints:

- release stability first;
- no global Mox ban;
- learned decks only for single commander until partner corpus exists;
- duplicate Commander singleton identity blocks save/import;
- Hermes metadata hidden from normal users;
- Hermes proposes, backend owns;
- `needs_review` battle rules do not execute hard behavior;
- `card_battle_rules` can derive tags only when trusted and traceable;
- first coding slice limited to aggregation + Hermes snapshot + tests.

## Executive result

The first derivation runner was useful but too broad for direct apply. The
review found one concrete taxonomy issue before it could become data: battle
effects such as `recursion`, `land_recursion` and `land_recursion_creature`
were grouped as `engine` by the battle registry, which is useful for simulator
strategy but too coarse for `card_function_tags`.

The report-only derivation now prefers a traceable concrete effect when it maps
to a more specific function tag. This keeps battle classification and
deckbuilding function classification separate.

## Current report-only numbers

Command:

```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 derive_functional_tags_from_battle_rules.py \
  --output /tmp/manaloom_battle_rule_derivation_full_v3.json
```

Result:

| Metric | Count |
|---|---:|
| battle rules seen | 3156 |
| new candidates | 89 |
| already present | 261 |
| rejected by gate | 2806 |
| low-risk review candidates | 30 |
| manual-review candidates | 59 |

The reduced candidate count is expected: recursion-like effects now match
existing `recursion` tags instead of creating broad `engine` candidates.

## Candidate count by tag

| Tag | Count |
|---|---:|
| board_wipe | 2 |
| draw | 16 |
| engine | 10 |
| protection | 17 |
| ramp | 19 |
| recursion | 1 |
| removal | 8 |
| tutor | 7 |
| wincon | 9 |

## Review flags

| Flag | Count | Meaning |
|---|---:|---|
| protection_scope_review | 17 | Protection is context-sensitive: counter, silence, hate, phasing, redirect and lifegain are not interchangeable. |
| lower_confidence_review | 16 | Battle rule confidence is below 1.0. It can be useful evidence but not direct canonical data. |
| conditional_ramp_review | 16 | Ramp engine/permanent effects may depend on board state, combo pieces or deck context. |
| wincon_scope_review | 7 | Extra turns, pump, token makers, mass theft and overload recursion are possible wincons, not universal wincons. |
| tutor_scope_review | 7 | Tutor scope matters: land tutor, artifact tutor, exile tutor and all-card tutor should not collapse blindly. |
| topdeck_not_direct_draw_review | 3 | Topdeck manipulation/cast-from-top is not direct card draw. |
| multi_face_review | 2 | Split/MDFC cards need face-aware semantics before automatic apply. |
| effect_overrode_broad_role | 1 | Concrete effect produced a more precise tag than broad deck role. |

## Low-risk candidates

These are still review-only, but they are the safest group for a future
controlled apply after stale-cleanup semantics exist.

| Tag | Card | Effect | Confidence |
|---|---|---|---:|
| wincon | Aetherflux Reservoir | finisher | 1.0 |
| removal | Amphibian Downpour | remove_creature | 1.0 |
| engine | Arcane Bombardment | copy_spell | 1.0 |
| wincon | Brain Freeze | finisher | 1.0 |
| ramp | Burnt Offering | ramp_ritual | 1.0 |
| removal | Chaos Warp | remove_permanent | 1.0 |
| engine | Double Vision | copy_spell | 1.0 |
| ramp | Dramatic Reversal | ramp_ritual | 1.0 |
| engine | Dualcaster Mage | copy_spell | 1.0 |
| engine | Echoes of Eternity | copy_spell | 1.0 |
| engine | Flare of Duplication | copy_spell | 1.0 |
| removal | Force of Vigor | remove_permanent | 1.0 |
| engine | Isochron Scepter | copy_spell | 1.0 |
| engine | Jin-Gitaxias, Progress Tyrant | copy_spell | 1.0 |
| board_wipe | Living Death | board_wipe | 1.0 |
| ramp | Manamorphose | treasure_maker | 1.0 |
| draw | Peer into the Abyss | draw_cards | 1.0 |
| removal | Pest Infestation | remove_permanent | 1.0 |
| draw | Reforge the Soul | draw_cards | 1.0 |
| engine | Reiterate | copy_spell | 1.0 |
| engine | Reverberate | copy_spell | 1.0 |
| removal | Run Away Together | remove_creature | 1.0 |
| removal | Step Through | remove_creature | 1.0 |
| draw | Timetwister | draw_cards | 1.0 |
| removal | Ugin, Eye of the Storms | remove_permanent | 1.0 |
| board_wipe | Ugin, the Spirit Dragon | board_wipe | 1.0 |
| draw | Victory Chimes | draw_engine | 1.0 |
| draw | Wheel of Fortune | draw_cards | 1.0 |
| draw | Wheel of Misfortune | draw_cards | 1.0 |
| draw | Windfall | draw_cards | 1.0 |

## Manual-review candidates

These candidates should not be applied automatically. They need either a more
specific tag taxonomy, face-aware support, or card-by-card review.

| Tag | Card | Effect | Review flags |
|---|---|---|---|
| wincon | Akroma's Will | pump_all | wincon_scope_review |
| tutor | Analyze the Pollen | tutor | tutor_scope_review |
| draw | Bolas's Citadel | topdeck_manipulation | topdeck_not_direct_draw_review |
| draw | Bridgeworks Battle // Tanglespan Bridgeworks | draw_cards | lower_confidence_review, multi_face_review |
| protection | Commandeer | counter | protection_scope_review |
| protection | Deflecting Swat | redirect_removal | protection_scope_review |
| draw | Delayed Blast Fireball | draw_cards | lower_confidence_review |
| tutor | Demonic Consultation | tutor | tutor_scope_review |
| protection | Displace | phase_creatures | protection_scope_review |
| tutor | Expedition Map | tutor | tutor_scope_review |
| wincon | Final Fortune | extra_turn | wincon_scope_review |
| recursion | Flashback | recursion | effect_overrode_broad_role |
| wincon | Forsaken Monument | pump_all | wincon_scope_review |
| ramp | Freed from the Real | ramp_engine | conditional_ramp_review |
| protection | Galadriel's Dismissal | phase_creatures | protection_scope_review |
| protection | Grand Abolisher | silence_opponents | protection_scope_review |
| ramp | Grinding Station | ramp_permanent | conditional_ramp_review, lower_confidence_review |
| ramp | Helm of Awakening | ramp_engine | conditional_ramp_review |
| protection | Hullbreaker Horror | counter | protection_scope_review |
| ramp | Inspiring Statuary | ramp_engine | conditional_ramp_review |
| wincon | Insurrection | steal_all_creatures | wincon_scope_review |
| wincon | Last Chance | extra_turn | wincon_scope_review |
| ramp | Magda, the Hoardmaster | ramp_engine | conditional_ramp_review, lower_confidence_review |
| ramp | Manifold Key | ramp_engine | conditional_ramp_review |
| protection | Mindbreak Trap | counter | protection_scope_review |
| ramp | Mirage Mirror | ramp_engine | conditional_ramp_review |
| protection | Misdirection | redirect_removal | protection_scope_review |
| wincon | Mizzix's Mastery | overload_recursion | wincon_scope_review |
| tutor | Moonsilver Key | tutor | lower_confidence_review, tutor_scope_review |
| draw | Necropotence | draw_engine | lower_confidence_review |
| protection | Orim's Chant | silence_spell | protection_scope_review |
| removal | Pinnacle Monk // Mystic Peak | remove_permanent | lower_confidence_review, multi_face_review |
| draw | Powerbalance | draw_engine | lower_confidence_review |
| tutor | Praetor's Grasp | tutor | tutor_scope_review |
| draw | Pyrokinesis | draw_cards | lower_confidence_review |
| draw | Redirect Lightning | draw_cards | lower_confidence_review |
| ramp | Relic of Sauron | ramp_permanent | conditional_ramp_review |
| protection | Reprieve | counter | protection_scope_review |
| engine | Return the Favor | copy_spell | lower_confidence_review |
| ramp | Rings of Brighthearth | ramp_permanent | conditional_ramp_review, lower_confidence_review |
| ramp | Ruby Medallion | ramp_engine | conditional_ramp_review |
| draw | Scroll Rack | topdeck_manipulation | topdeck_not_direct_draw_review |
| ramp | Sculpting Steel | ramp_permanent | conditional_ramp_review, lower_confidence_review |
| protection | Silence | silence_spell | protection_scope_review |
| protection | Sink into Stupor | counter | protection_scope_review |
| protection | Soul-Guide Lantern | hate_artifact | protection_scope_review |
| tutor | Sylvan Scrying | tutor | tutor_scope_review |
| tutor | Tainted Pact | tutor | tutor_scope_review |
| ramp | Tataru Taru | ramp_engine | conditional_ramp_review, lower_confidence_review |
| protection | Thalia, Guardian of Thraben | silence_opponents | lower_confidence_review, protection_scope_review |
| draw | The Reality Chip | topdeck_manipulation | topdeck_not_direct_draw_review |
| wincon | They Came from the Pipes | token_maker | wincon_scope_review |
| ramp | Training Grounds | ramp_engine | conditional_ramp_review |
| ramp | Unwinding Clock | ramp_engine | conditional_ramp_review |
| protection | Vexing Bauble | hate_artifact | protection_scope_review |
| protection | Voice of Victory | silence_opponents | protection_scope_review |
| ramp | Wild Growth | ramp_permanent | conditional_ramp_review |
| ramp | Xorn | ramp_engine | conditional_ramp_review, lower_confidence_review |
| protection | Zuran Orb | life_artifact | protection_scope_review |

## Policy for future apply

Do not build an apply path until all of these are true:

1. The runner keeps `apply=false` by default and requires an explicit allowlist.
2. A future apply can write only low-risk reviewed candidates first.
3. Stale cleanup exists for tags with `source='card_battle_rules_v1'` when the
   originating logical battle rule disappears, is downgraded, or loses trust.
4. `logical_rule_key` is stored in evidence for every derived tag.
5. `needs_review`, `generated`, `heuristic`, low-confidence or non-traceable
   rules never create canonical tags.
6. Face-aware cards stay manual until card identity/faces are formalized.
7. Derived tags remain additive; they cannot remove existing manual/curated
   tags without a separate review flow.

## Next steps

1. Keep the current Slice 4 as report-only.
2. Review the 30 low-risk candidates manually before any apply implementation.
3. Extend taxonomy before applying the 59 manual-review candidates:
   scoped tutor, conditional ramp, protection subtype, topdeck/cast-from-top,
   broad wincon, and face-aware semantics.
4. If apply is approved later, start with an allowlist-backed dry-run and a
   small PostgreSQL transaction test, not a bulk write.
