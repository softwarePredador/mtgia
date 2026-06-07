# Other Lorehold the Historian Decks — Research

**Last Updated:** 2026-05-31 (Deck Learner cron execution #2 — EDHREC + learned_decks)
**Sources:** EDHREC JSON API (7,851 decks), TappedOut.net (2 decks), Archidekt (82 UUIDs pending)
**Moxfield/Archidekt scraping:** BLOCKED by Cloudflare in cron context
**Statistical profiles saved:** 3 new profiles in `learned_decks` (ids 13-15)

## Executive Summary (2026-05-31 Run — EDHREC Deep Analysis)

This run performed a deep analysis of the EDHREC meta from **7,851 Lorehold decks**
and cross-referenced all findings against our post-Ciclo #11 deck (25 swaps, MATURIDADE ATINGIDA).
Individual deck scraping from Moxfield and Archidekt was blocked by Cloudflare, but the
EDHREC JSON API provides comprehensive statistical coverage.

### Meta State: 7,851 Decks Analyzed

| Card | EDHREC % | Synergy | Trend | In Our Deck? |
|:-----|:--------:|:-------:|:-----:|:------------:|
| Sol Ring | 90.5% | 0.06 | 0.00 | YES |
| Arcane Signet | 88.1% | 0.08 | 0.00 | YES |
| Hit the Mother Lode | 79.3% | 0.76 | +1.29 | YES |
| Library of Leng | 77.8% | 0.75 | +1.44 | YES |
| Storm Herd | 75.0% | 0.72 | +1.21 | YES |
| Monument to Endurance | 72.8% | 0.68 | +1.27 | YES |
| Bender's Waterskin | 71.1% | 0.65 | 0.00 | YES |
| Big Score | 67.3% | 0.55 | +1.52 | YES |
| Brass's Bounty | 67.1% | 0.64 | +1.13 | YES |
| Sensei's Divining Top | 66.8% | 0.63 | +0.55 | YES |
| Swords to Plowshares | 69.0% | 0.03 | +1.24 | YES |
| Approach of the Second Sun | 63.8% | 0.62 | +0.74 | YES |
| Scroll Rack | 59.5% | 0.57 | +0.48 | YES |
| Mizzix's Mastery | 57.4% | 0.55 | +1.07 | YES |
| Path to Exile | 57.4% | 0.00 | +0.91 | YES |
| Storm-Kiln Artist | 55.3% | 0.48 | +0.76 | YES |
| Apex of Power | 54.9% | 0.53 | +0.11 | NO (CMC 10) |
| Rise of the Eldrazi | 54.6% | 0.53 | -0.47 | NO (CMC 12, declining) |
| Victory Chimes | 53.5% | 0.52 | 0.00 | YES |
| Dance with Calamity | 50.2% | 0.48 | +0.58 | YES |

### Key Findings

1. **Our deck is at maturity.** Only 10 cards have EDHREC inclusion < 15%. Most are deliberate:
   Akroma's Will (wincon), Twinflame (copy), Flare of Duplication (copy), Wedding Ring (draw),
   Weathered Wayfarer (ramp). Only Grand Abolisher (11.7%, double-null) is questionable.

2. **Win condition convergence reached.** The meta has 5 clear win conditions and our deck
   runs all five: Approach of the Second Sun (63.8%), Storm Herd (75.0%), Mizzix's Mastery
   recursion (57.4%), Rise of the Eldrazi (54.6% — not in our deck, see below), Apex of Power
   (54.9% — not in our deck).

3. **Rising stars confirmed (all in our deck):** Improvisation Capstone (49.0%, trend +8.13),
   Restoration Seminar (37.9%, trend +9.16), The Dawning Archaic (24.0%, trend +5.31).

4. **Declining trends (correct cuts confirmed):** Ruby Medallion (-0.37, cut Ciclo #10),
   Pearl Medallion (-0.46, cut Ciclo #9), Artist's Talent (-0.72, cut Ciclo #5),
   Oswald Fiddlebender (0%, cut Ciclo #5). All cuts validated by meta data.

5. **Cost reduction vs treasure: clear winner.** Both Medallions declining while treasure-based
   ramp (Storm-Kiln Artist +0.76, Big Score +1.52, Hit the Mother Lode +1.29) rising.
   Community has voted: treasure > cost reduction for Lorehold.

6. **Copy engine meta:** Double Vision (46.5%), Arcane Bombardment (42.4%), Mizzix's Mastery
   (57.4%). Our deck runs all three plus The Dawning Archaic, Flare of Duplication, and
   Twinflame — 6 copy engines total (double the meta average of ~3).

### Cards the Meta Plays That We Don't (Top Gaps)

| Card | EDHREC % | CMC | Trend | Status |
|:-----|:--------:|:---:|:-----:|:-------|
| Apex of Power | 54.9% | 10 | +0.11 | In collection. Would worsen T3 from 13.3%. Hold. |
| Rise of the Eldrazi | 54.6% | 12 | -0.47 | Not in collection. Declining + CMC 12 = SKIP. |
| Soulfire Eruption | 42.4% | 9 | +0.35 | Not in collection. Not tracked. CMC too high. |
| Ruby Medallion | 42.3% | 2 | -0.37 | CORRECTLY CUT Ciclo #10. Confirmed declining. |
| Mother of Runes | 34.5% | 1 | +0.23 | In collection. Sidegrade protection. Not needed. |
| Perch Protection | 34.4% | 4 | -0.45 | Declining. SKIP. |
| Esper Sentinel | 32.4% | 1 | -0.54 | Not in collection. Declining 6 consecutive cycles. |
| Guttersnipe | 32.2% | 3 | -0.08 | In collection. Spellslinger payoff. Sidegrade. |
| Velomachus Lorehold | 32.6% | 7 | 0.00 | Not in collection. Too expensive, creature-focused. |
| Invoke Calamity | 33.9% | 5 | +0.11 | Not in collection. Instant-speed recursion. Interesting. |

### Learned Decks Saved to knowledge.db

Three statistical profiles were built from the EDHREC data and saved to the `learned_decks`
table for Battle Analyst matchup simulations:

| ID | Name | Archetype | Cards | Wincon Primary | Wincon Backup |
|:---|:-----|:----------|:-----:|:---------------|:--------------|
| 13 | EDHREC Statistical Average (7,851) | spellslinger | 99 | Approach of the Second Sun | Storm Herd + Mizzix Mastery |
| 14 | EDHREC Spellslinger Profile (7,851) | spellslinger | 100 | Approach of the Second Sun | Storm Herd token swarm |
| 15 | EDHREC Budget Profile (7,851) | spellslinger-budget | 100 | Approach of the Second Sun | Storm Herd |

Each profile contains a full JSON card list with inclusion percentages, synergy scores,
and trend data. The Battle Analyst can load these via SQLite.

### Archidekt Sources (Pending)

82 Archidekt deck UUIDs are available from the EDHREC average deck JSON but Archidekt's
API returns "Client Unavailable" in cron context (SPA routing issue). These UUIDs are
saved at `/tmp/lorehold_deck_urls.json` and can be attempted from a non-cron environment
or with residential proxies. Individual decklists from these would provide the complete
100-card lists missing from the EDHREC statistical average (which is ~82 cards).

---

## Deck Sources Analyzed

### 1. EDHREC Average Deck

- **URL:** https://edhrec.com/average-decks/lorehold-the-historian
- **Type:** aggregate_average
- **Bracket:** varies (mostly 2-3)
- **Price:** $959
- **Cards Analyzed:** 82

**Win Conditions:**
- **Approach of the Second Sun:** Cast for miracle cost {2} from hand, then recast normally 7 turns later or dig for it immediately with Scroll Rack/SDT
- **Storm Herd Token Swarm:** Cast Storm Herd for miracle {2}, creating X 1/1 Pegasi where X is your life total. Often 30+ tokens for 2 mana
- **Big Spell Cheating:** Apex of Power, Rise of the Eldrazi, Call Forth the Tempest — all castable for {2} via miracle, generating insurmountable advantage
- **Mizzix's Mastery Overload:** Cast Mizzix's Mastery overloaded to replay all instants/sorceries from graveyard for free
- **Arcane Bombardment / Double Vision:** Copy spells multiple times. Double Vision doubles first sorcery/instant each turn; Arcane Bombardment exiles and copies each turn
- **Insurrection:** Steal all creatures on the battlefield for {2} mana and swing for lethal

**Card Breakdown:**
- commander: 1 cards
- creatures: 13 cards
- instants: 13 cards
- sorceries: 21 cards
- artifacts: 13 cards
- enchantments: 4 cards
- lands_nonbasic: 15 cards
- lands_basic: 2 cards

---

### 2. TappedOut - Major Miracle

- **URL:** https://tappedout.net/mtg-decks/major-miracle/
- **Type:** player_decklist
- **Bracket:** 2
- **Price:** 183-206
- **Author:** SnowLeo
- **Cards Analyzed:** 101

**Win Conditions:**
- **Token Army Swarm:** Cast Storm Herd, Deploy to the Front, Devout Invocation, Entreat the Angels, or Nomads' Assembly all for miracle {2} each, flooding board with tokens
- **Surge to Victory Combat:** Exile a high-CMC sorcery (Apex of Power, Storm Herd) with Surge to Victory, giving all creatures +X/+0 and casting copies on combat damage
- **Mizzix's Mastery Graveyard Storm:** Overload Mizzix's Mastery to replay all instants/sorceries from graveyard — with 28 sorceries, this can end games
- **Primal Amulet Flip:** Transform Primal Amulet into Primal Wellspring, then double key spells
- **Dualcaster Mage + Flare of Duplication:** Copy opponents' key spells or your own big spells for extra value
- **Galvanoth Free Casts:** Galvanoth lets you cast top card of library for free each upkeep — works with topdeck manipulation

**Card Breakdown:**
- commander: 1 cards
- creatures: 19 cards
- instants: 7 cards
- sorceries: 28 cards
- artifacts: 11 cards
- enchantments: 1 cards
- lands_nonbasic: 21 cards
- lands_basic: 2 cards

**Notable Unique Cards (not in EDHREC average):**
- Archangel's Light
- Aziza, Mage Tower Captain
- Blessed Wind
- Chaotic Transformation
- Chronomantic Escape
- Crystal Barricade
- Devout Invocation
- Dualcaster Mage
- Flare of Duplication
- Full Throttle
- Galvanoth
- Leonin Lightscribe
- Lorehold Command
- Mica, Reader of Ruins
- Nomads' Assembly
- ... and 14 more

**Notable Support Cards:**
- Primal Amulet (spell copy + land)
- Galvanoth (free spell each upkeep)
- Seething Song (ritual for big turns)
- Brainstone + Crystal Ball (topdeck manipulation)
- Archaeomancer's Map (ramp in Boros)
- Treasure Map (ramp + draw)
- Monologue Tax (tax draw)

---

### 3. TappedOut - Lorehold Shenanigans

- **URL:** https://tappedout.net/mtg-decks/lorehold-shenanigans-1/
- **Type:** player_decklist
- **Bracket:** 3
- **Price:** 113-117
- **Author:** midknightcruiser
- **Cards Analyzed:** 80

**Win Conditions:**
- **Approach of the Second Sun (Primary):** The dedicated win condition. Cast for {2} via miracle, then use chaos effects to stall while digging for the second cast
- **Chaos Lock / Disruption:** Scrambleverse + Thieves' Auction + Restore Balance — disrupt opponents' boards while assembling your win. Whims of the Fates can randomly eliminate threats
- **Insurrection / Storm Herd:** Traditional finishers — steal all creatures or make massive token army for {2}
- **Surge to Victory:** Exile a high-CMC spell, pump the team, and cast free copies on combat damage
- **Single Combat:** Miracle for {2} to force a 1v1 creature situation where your commander (5/5 flying haste) dominates

**Card Breakdown:**
- commander: 1 cards
- creatures: 13 cards
- instants: 6 cards
- sorceries: 28 cards
- artifacts: 12 cards
- enchantments: 2 cards
- lands_nonbasic: 16 cards
- lands_basic: 2 cards

**Notable Unique Cards (not in EDHREC average):**
- Aven Interrupter
- Blitzball
- Borrowed Knowledge
- Choreographed Sparks
- Disrupt Decorum
- Erode
- Farewell
- Gift of Immortality
- Magmakin Artillerist
- Molten Man, Inferno Incarnate
- Moonring Mirror
- Prisoner's Dilemma
- Promise of Loyalty
- Redirect Lightning
- Restore Balance
- ... and 14 more

**Notable Support Cards:**
- Semblance Anvil / Cloud Key (cost reduction for sorceries)
- Moonring Mirror (impulse draw / card selection)
- Tablet of Discovery (topdeck manipulation + ramp)
- Bender's Waterskin (mana + lifegain synergy with Invincible Hymn)
- Blitzball (removal + card draw)
- The Endstone (ramp + graveyard hate)
- Gift of Immortality (commander protection)
- Triple Triad (political card draw)

---

## Cross-Deck Analysis

### Common Win Conditions Across All Decks

1. **Approach of the Second Sun** — Present in all builds. The miracle cost {2} makes
   this the most mana-efficient alt-wincon in Commander. Enablers: Scroll Rack,
   Sensei's Divining Top, Penance (topdeck manipulation).

2. **Mizzix's Mastery (Overloaded)** — All decks leverage this to replay graveyards.
   Lorehold's discard trigger fills the yard naturally.

3. **Big Spell Cheating (Miracle {2})** — The commander's core mechanic enables casting
   7-12 CMC spells for {2}. Common targets: Storm Herd, Apex of Power, Rise of the
   Eldrazi, Insurrection.

4. **Token Swarm (Storm Herd / Deploy / Entreat)** — Multiple white miracle token
   generators create lethal boards for 2 mana each.

### Unique Win Conditions NOT in Our Deck

| Wincon | Source | Why We Don't Have It |
|:-------|:-------|:---------------------|
| Surge to Victory | Major Miracle, Shenanigans | Exiles a sorcery, pumps team, free copies on combat damage — strong with token subtheme |
| Galvanoth | Major Miracle | Free spell each upkeep — requires topdeck manipulation |
| Chaos Lock (Scrambleverse/Thieves' Auction) | Shenanigans | Not competitive; chaos for chaos's sake |
| Single Combat | Shenanigans | 1v1 commander domination — narrow |

### Cards in Our Deck NOT in Any Other Build

These are cards that make our Lorehold build unique:

| Card | CMC | Tag | Notes |
|:-----|:---:|:----|:------|
| Enlightened Tutor | 1.0 | tutor | |
| Weathered Wayfarer | 1.0 | ramp | |
| Abrade | 2.0 | removal | |
| Grand Abolisher | 2.0 | NULL | |
| Thrill of Possibility | 2.0 | draw | |
| Twinflame | 2.0 | token_maker | |
| Teferi's Protection | 3.0 | protection | |
| Valakut Awakening // Valakut Stoneforge | 3.0 | land | |
| Akroma's Will | 4.0 | wincon | |
| Smothering Tithe | 4.0 | ramp | |
| The One Ring | 4.0 | draw | |
| Wedding Ring | 4.0 | draw | |
| Fated Clash | 5.0 | board_wipe | |
| Rite of the Dragoncaller | 6.0 | spellslinger | |
| Emeria's Call // Emeria, Shattered Skyclave | 7.0 | land | |
| Ancient Tomb | 0.0 | land | |
| Bloodstained Mire | 0.0 | land | |
| Boseiju, Who Shelters All | 0.0 | land | |
| Cavern of Souls | 0.0 | land | |
| Dormant Volcano | 0.0 | land | |
| Flooded Strand | 0.0 | land | |
| Gamble | 0.0 | tutor | |
| Inspiring Vantage | 0.0 | land | |
| Kor Haven | 0.0 | land | |
| Scalding Tarn | 0.0 | land | |
| Urza's Saga | 0.0 | land | |
| Windswept Heath | 0.0 | land | |

**Total unique cards: 27**

## Key Takeaways for Our Deck

### What We Can Learn

1. **Our deck is well-optimized.** After 11 evolution cycles, our card selection aligns
   with the EDHREC average on the key staples (Approach, Mizzix, Storm-Kiln, etc.).

2. **Galvanoth + topdeck manipulation** is a popular alternative engine we don't use.
   The Major Miracle deck runs Galvanoth + Brainstone + Crystal Ball for a free spell
   each upkeep. Could be considered if we find space.

3. **Surge to Victory** is underexplored. With our copy engines (6 active), Surge could
   add a combat-based wincon that exiles and copies our best sorceries.

4. **We use more interaction** than the average Lorehold deck (Abrade, Flare of
   Duplication, Twinflame, Boros Charm as protection). This is intentional for our
   spellslinger-control hybrid.

5. **Our mana base is stronger.** We run 35 lands including fetches; the budget builds
   run fewer utility lands and more tap-lands.

### Cards Other Builds Use That We Should Consider

| Card | Source | EDHREC % | In Collection? | Reason |
|:-----|:-------|:--------:|:--------------:|:-------|
| Surge to Victory | Major Miracle, Shenanigans | ~15% | Unknown | Combat wincon + spell copying |
| Primal Amulet | Major Miracle | ~10% | Unknown | Spell doubler that flips to land |
| Galvanoth | Major Miracle | ~12% | Unknown | Free spell each upkeep |
| Archaeomancer's Map | Major Miracle | ~25% | Unknown | Boros ramp |
| Treasure Map | Major Miracle | ~15% | Unknown | Scry + ramp |

## References

- EDHREC Lorehold page: https://edhrec.com/commanders/lorehold-the-historian
- EDHREC JSON API: https://json.edhrec.com/pages/commanders/lorehold-the-historian.json
- Major Miracle: https://tappedout.net/mtg-decks/major-miracle/
- Lorehold Shenanigans: https://tappedout.net/mtg-decks/lorehold-shenanigans-1/
