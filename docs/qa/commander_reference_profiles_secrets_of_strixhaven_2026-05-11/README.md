# Commander Reference Profiles - Secrets of Strixhaven - 2026-05-11

## Verdict

**PASS WITH RISKS**

Ten Commander Reference Profile v1 JSON files were created for Secrets of
Strixhaven lot 1. They are curated aggregate references only: no runtime code was
changed, no database apply was run, no complete public decklist was copied, and
no unofficial public site is required at runtime.

The risk is that most commanders are new enough that public decklist evidence is
thin. Commander relevance is proven from the local seed plus public card /
Commander context, but cEDH relevance is **not proven** for every profile.

## Files

| Commander | Profile | Recommendation |
| --- | --- | --- |
| Lorehold, the Historian | `lorehold_the_historian.json` | PASS WITH RISKS |
| Prismari, the Inspiration | `prismari_the_inspiration.json` | PASS WITH RISKS |
| Quandrix, the Proof | `quandrix_the_proof.json` | PASS WITH RISKS |
| Silverquill, the Disputant | `silverquill_the_disputant.json` | PASS WITH RISKS |
| Witherbloom, the Balancer | `witherbloom_the_balancer.json` | PASS WITH RISKS |
| Dina, Essence Brewer | `dina_essence_brewer.json` | PASS WITH RISKS |
| Killian, Decisive Mentor | `killian_decisive_mentor.json` | PASS WITH RISKS |
| Rootha, Mastering the Moment | `rootha_mastering_the_moment.json` | PASS WITH RISKS |
| Zimone, Infinite Analyst | `zimone_infinite_analyst.json` | PASS WITH RISKS |
| Quintorius, History Chaser | `quintorius_history_chaser.json` | PASS WITH RISKS |

## Sources consulted

Low-volume public sources were used only as manual research evidence.

| Source | URLs / context | Use |
| --- | --- | --- |
| Local seed artifact | `server/test/artifacts/commander_reference_profile_secrets_of_strixhaven_2026-05-11/secrets_of_strixhaven_new_commanders_seed.json` | Exact names, color identity, type line, oracle text, and Scryfall URI. |
| Local plan | `server/doc/COMMANDER_REFERENCE_PROFILE_SECRETS_OF_STRIXHAVEN_PLAN_2026-05-11.md` | Scope, accepted JSON fields, and no-apply workflow. |
| Scryfall public card pages | `https://scryfall.com/card/sos/201/lorehold-the-historian`, `https://scryfall.com/card/sos/212/prismari-the-inspiration`, `https://scryfall.com/card/sos/218/quandrix-the-proof`, `https://scryfall.com/card/sos/226/silverquill-the-disputant`, `https://scryfall.com/card/sos/245/witherbloom-the-balancer`, `https://scryfall.com/card/soc/1/dina-essence-brewer`, `https://scryfall.com/card/soc/4/killian-decisive-mentor`, `https://scryfall.com/card/soc/8/rootha-mastering-the-moment`, `https://scryfall.com/card/soc/10/zimone-infinite-analyst`, `https://scryfall.com/card/soc/7/quintorius-history-chaser` | Public card identity / oracle context. |
| EDHREC commander pages | `https://edhrec.com/commanders/<slug>` for all ten commanders | Commander-context corroboration only; not copied as decklists and not treated as runtime data. |
| WotC announcement | `https://magic.wizards.com/en/news/announcements/secrets-of-strixhaven-commander-decklists` | Public set / Commander decklist context for SOC face commanders. |
| Playgroup set overview | `https://playgroup.gg/sets/secrets-of-strixhaven` | Supplemental set-context check only. |
| Draftsim Lorehold article | `https://draftsim.com/lorehold-the-historian-edh-deck/` | Lorehold-specific Commander strategy corroboration. |
| EDHREC Dina article | `https://edhrec.com/articles/a-new-commander-brew-with-dina-essence-brewer/` | Dina-specific Commander strategy corroboration. |

## What was proven locally

- The seed contains 36 new Secrets of Strixhaven/SOC commander candidates.
- Lot 1 contains the five school Elder Dragons plus Dina, Killian, Rootha,
  Zimone, and Quintorius.
- Local seed data proves each requested commander's exact name, set, oracle text,
  type line, and Commander color identity.
- Quintorius is explicitly represented in the seed as a planeswalker that can be
  your commander.
- No database apply was performed in this pass.

## Web-derived findings

- Public Commander context is present for all ten via Scryfall card pages plus
  EDHREC Commander pages.
- SOC face commanders also have public set/decklist context through WotC and
  Playgroup references.
- Lorehold and Dina have commander-specific article corroboration beyond generic
  aggregate pages.
- No credible cEDH source context was established for any of the ten.

## Interpretation and useful patterns to absorb

| Commander | Pattern useful to `optimize` / `generate` |
| --- | --- |
| Lorehold | RW miracle big-spells; topdeck setup before haymakers; opponent-turn first-draw support. |
| Prismari | RU storm spellslinger; cheap spell velocity, rituals/treasures, spell-count payoffs. |
| Quandrix | GU cascade spells; curve engineering and safe cascade hits before generic Simic goodstuff. |
| Silverquill | BW casualty spells; token fodder and aristocrats support copy-worthy spells. |
| Witherbloom | BG affinity for creatures; creature density, tokens, and discounted big spells. |
| Dina | BG sacrifice-once-per-turn draw; high-power sacrifice targets and recursion. |
| Killian | BW Aura politics; enchantment ETB goad and enchanted-attack draw. |
| Rootha | RU precombat big spell into flying haste Elemental token; cost reduction and token payoffs. |
| Zimone | GU X-spells plus +1/+1 counters; scalable ramp and counter acceleration. |
| Quintorius | RW graveyard-leaves Spirits; flashback/escape/recursion plus planeswalker protection. |

## Risky or not transferable

- Do not collapse these profiles into cEDH logic; cEDH relevance is not proven.
- Do not copy EDHREC, WotC, Playgroup, Draftsim, or any public decklist into the
  database. These JSONs are curated aggregate references.
- Do not let older similarly named cards contaminate Dina, Killian, Rootha, or
  Quintorius profiles.
- Do not recommend off-color packages from generic archetypes, such as blue
  miracle cards for Lorehold or UW/black Spirit packages for Quintorius.
- Do not bypass local Commander legality, banlist, or color-identity validation.

## Unresolved

- The profiles were not applied to `commander_reference_profiles` or
  `commander_reference_card_stats`.
- Card resolution/off-color checks through
  `server/bin/commander_reference_profile.dart --dry-run` remain for the
  implementation/validation agent.
- Exact package weights should be tuned after dry-run coverage, unresolved-card
  review, and at least a small generate probe sample.
- cEDH-specific packages remain blocked until credible cEDH source evidence is
  found.

## Smallest next technical actions

1. Run `server/bin/commander_reference_profile.dart --dry-run` for each JSON.
2. Review unresolved and off-color cards before any database apply.
3. Apply only profiles that resolve cleanly and keep `confidence >= medium`.
4. Probe `/ai/generate` with at least three commanders after apply, using
   sanitized outputs only.
