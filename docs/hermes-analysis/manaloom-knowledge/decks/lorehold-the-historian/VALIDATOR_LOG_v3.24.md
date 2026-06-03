# Lorehold Validator — Purpose Analyzer v3.24 (Crise de Integridade)

**Data:** 2026-06-02T22:00:00+00:00
**Deck:** Lorehold Best-of Learned No Premium Mox 2026-06-02 (id=6)
**Archetype:** fast-mana-copy-combo-big-spells-no-premium-mox
**Card Hash:** `f2241d994743e8142396c0f846917fde`

---

## 🚨 ALERTA #1: BANLIST VIOLATION — Worldfire

**Worldfire** está BANIDO em Commander desde sempre. Esta carta NÃO pode estar no deck.

```
Worldfire — 6RRR (CMC 9)
Sorcery
Each player's life total becomes 1. Exile all permanents, all cards in 
all hands, and all cards in all graveyards.
```

**Ação imediata:** Remover Worldfire. O deck tem 99 cartas legais + comandante após remoção.

---

## 🚨 ALERTA #2: 20 Cartas Com `functional_tag='unknown'` — Classificador NUNCA Executou

O deck foi importado via bulk import (`import_lorehold_decks.py`). 20 cartas têm
`functional_tag='unknown'` (não é NULL — é a string 'unknown'). O classificador
(`classify_card()` / `infer_functional_card_tags()`) nunca foi invocado.

**Cartas afetadas:** Birgi, Boros Charm, Boros Signet, Electroduplicate, Flawless Maneuver,
Heat Shimmer, Lightning Greaves, Mana Vault, Orim's Chant, Past in Flames, Pyroblast,
Reforge the Soul, Reiterate, Reverberate, Ruby Medallion, Scroll Rack, Sol Ring,
Talisman of Conviction, Valakut Awakening, Victory Chimes.

Além disso, 6 cartas têm CMC=NULL (Aetherflux Reservoir, Electroduplicate, Fiery
Emancipation, Hall of Heliod's Generosity, Heat Shimmer, Past in Flames, Reiterate).

**Métricas do DB são INÚTEIS para este deck.** Toda análise abaixo usa classificação
manual baseada em conhecimento real de cartas MTG.

---

## COMPLETE DECK CLASSIFICATION (Manual — 100 cartas)

### Lands (33)

| # | Carta | CMC | Tipo | Nota |
|:--|:------|:---:|:-----|:-----|
| 1 | Ancient Den | 0 | Artifact Land | W artifact land |
| 2 | Ancient Tomb | 0 | Land | Sol land (2 mana, 2 damage) |
| 3 | Arid Mesa | 0 | Land | RW fetch |
| 4 | Battlefield Forge | 0 | Land | RW pain land |
| 5 | Bloodstained Mire | 0 | Land | BR fetch → R |
| 6 | City of Brass | 0 | Land | 5c rainbow (1 damage) |
| 7 | Clifftop Retreat | 0 | Land | RW check land |
| 8 | Command Tower | 0 | Land | 5c (commander) |
| 9 | Elegant Parlor | 0 | Land | RW surveil land |
| 10 | Flooded Strand | 0 | Land | WU fetch → W |
| 11 | Gemstone Caverns | 0 | Land | Fast mana (not starting) |
| 12 | Great Furnace | 0 | Artifact Land | R artifact land |
| 13 | Hall of Heliod's Generosity | 0 | Legendary Land | Grave→top enchantment |
| 14 | Inspiring Vantage | 0 | Land | RW fast land |
| 15 | Inventors' Fair | 0 | Legendary Land | Lifegain + artifact tutor |
| 16 | Mana Confluence | 0 | Land | 5c rainbow (1 life) |
| 17 | Marsh Flats | 0 | Land | WB fetch → W |
| 18 | Mountain | 0 | Basic | R |
| 19 | Needleverge Pathway | 0 | MDFC | R // W |
| 20 | Plains | 0 | Basic | W |
| 21 | Plateau | 0 | Land | RW dual (RL) |
| 22 | Prismatic Vista | 0 | Land | Fetch basic |
| 23 | Rugged Prairie | 0 | Land | RW filter |
| 24 | Sacred Foundry | 0 | Land | RW shock |
| 25 | Scalding Tarn | 0 | Land | UR fetch → R |
| 26 | Spectator Seating | 0 | Land | RW crowd land |
| 27 | Sunbaked Canyon | 0 | Land | RW canopy (draw) |
| 28 | Sunbillow Verge | 0 | Land | RW verge |
| 29 | Sundown Pass | 0 | Land | RW slow land |
| 30 | Urza's Saga | 0 | Enchantment Land | Constructs + tutor |
| 31 | War Room | 0 | Land | Pay 3 life: draw |
| 32 | Windswept Heath | 0 | Land | WG fetch → W |
| 33 | Wooded Foothills | 0 | Land | RG fetch → R |

**Mana base: 33 lands.** 6 fetches + 2 artifact lands + Sol land + Rainbow lands.
Excelente para cEDH.

### Fast Mana / Ramp (12)

| # | Carta | CMC | Função Real |
|:--|:------|:---:|:------------|
| 1 | Sol Ring | 1 | ramp — +2 mana |
| 2 | Mana Vault | 1 | ramp — +3 mana |
| 3 | Lotus Petal | 0 | ramp — sac for mana |
| 4 | Mox Amber | 0 | ramp — conditional (legendary) |
| 5 | Arcane Signet | 2 | ramp — mana rock |
| 6 | Boros Signet | 2 | ramp — RW rock |
| 7 | Fellwar Stone | 2 | ramp — mana rock |
| 8 | Talisman of Conviction | 2 | ramp — RW talisman |
| 9 | Ruby Medallion | 2 | ramp — red cost reducer |
| 10 | Victory Chimes | 3 | ramp — untaps each turn |
| 11 | Smothering Tithe | 4 | ramp — treasure tax |
| 12 | Storm-Kiln Artist | 4 | ramp — treasure per spell |

**DB diz 6 ramp — real são 12 (subcontagem de 50%).** Sol Ring, Mana Vault,
Boros Signet, Talisman, Ruby Medallion, e Victory Chimes estão com tag='unknown'.

### Rituals / Treasure Burst (5)

| # | Carta | CMC | Função Real |
|:--|:------|:---:|:------------|
| 1 | Rite of Flame | 1 | ritual — R (+R per copy) |
| 2 | Seething Song | 3 | ritual — RRRRR |
| 3 | Jeska's Will | 3 | ritual — RRRRRRR + impulse |
| 4 | Mana Geyser | 5 | ritual — R per tapped land |
| 5 | Unexpected Windfall | 4 | ritual — 2 treasures + loot |

Birgi (CMC 3) também gera R por spell — classificada como ramp/engine.

### Draw / Card Advantage (9)

| # | Carta | CMC | Função Real |
|:--|:------|:---:|:------------|
| 1 | Esper Sentinel | 1 | draw — tax draw |
| 2 | Faithless Looting | 1 | draw — loot + flashback |
| 3 | Sensei's Divining Top | 1 | draw — topdeck manipulation |
| 4 | Scroll Rack | 2 | draw — hand/topdeck swap |
| 5 | Monument to Endurance | 3 | draw — loot engine |
| 6 | Valakut Awakening | 3 | draw — hand refresh |
| 7 | Wheel of Fortune | 3 | draw — wheel 7 |
| 8 | The One Ring | 4 | draw — cumulative protection+draw |
| 9 | Reforge the Soul | 5 | draw — miracle wheel 7 |

### Tutores (6)

| # | Carta | CMC | Função Real |
|:--|:------|:---:|:------------|
| 1 | Enlightened Tutor | 1 | tutor — artifact/enchantment |
| 2 | Gamble | 1 | tutor — any card (random discard) |
| 3 | Land Tax | 1 | tutor — 3 basics |
| 4 | Ranger-Captain of Eos | 1 | tutor — creature CMC≤1 + silence |
| 5 | Imperial Recruiter | 3 | tutor — creature power≤2 |
| 6 | Recruiter of the Guard | 3 | tutor — creature toughness≤2 |

### Proteção (8)

| # | Carta | CMC | Função Real |
|:--|:------|:---:|:------------|
| 1 | Mother of Runes | 1 | protection — pro-color |
| 2 | Giver of Runes | 1 | protection — pro-color/colorless |
| 3 | Boros Charm | 2 | protection — indestructible / double strike |
| 4 | Grand Abolisher | 2 | protection — opponents can't cast |
| 5 | Lightning Greaves | 2 | protection — haste + shroud |
| 6 | Deflecting Swat | 3 | protection — redirect |
| 7 | Flawless Maneuver | 3 | protection — free indestructible |
| 8 | Teferi's Protection | 3 | protection — phase out |

### Stax / Silence (3)

| # | Carta | CMC | Função Real |
|:--|:------|:---:|:------------|
| 1 | Silence | 1 | stax — lock turn |
| 2 | Orim's Chant | 1 | stax — lock turn + no combat |
| 3 | Drannith Magistrate | 2 | stax — no casting from non-hand |

### Remoção / Wipe (5)

| # | Carta | CMC | Função Real |
|:--|:------|:---:|:------------|
| 1 | Path to Exile | 1 | removal — exile creature |
| 2 | Swords to Plowshares | 1 | removal — exile creature |
| 3 | Pyroblast | 1 | interaction — counter/destroy blue |
| 4 | Generous Gift | 3 | removal — destroy any permanent |
| 5 | Blasphemous Act | 9 | wipe — 13 to all (discount per creature) |

### Copy / Twin Spells (6) — MOTOR DO DECK

| # | Carta | CMC | Função Real |
|:--|:------|:---:|:------------|
| 1 | Reverberate | 2 | copy — instant/sorcery |
| 2 | Twinflame | 2 | copy — creature (Strive) |
| 3 | Molten Duplication | 2 | copy — artifact/creature |
| 4 | Electroduplicate | 3 | copy — artifact/creature (flashback) |
| 5 | Heat Shimmer | 3 | copy — creature (hasty) |
| 6 | Reiterate | 3 | copy — instant/sorcery (buyback) |

### Win Conditions (9)

| # | Carta | CMC | Função Real | Combo |
|:--|:------|:---:|:------------|:------|
| 1 | Dualcaster Mage | 3 | wincon — combo piece | Twinflame/Heat Shimmer = infinite hasty 2/2s |
| 2 | Guttersnipe | 3 | wincon — pinger | 2 dmg per spell (storm payoff) |
| 3 | Aetherflux Reservoir | 4 | wincon — storm payoff | Lifegain → 50+ = laser |
| 4 | Fiery Emancipation | 6 | wincon — multiplier | Triple all damage |
| 5 | Rite of the Dragoncaller | 6 | wincon — token engine | Dragon per spell cast |
| 6 | Approach of the Second Sun | 7 | wincon — alt win | Cast twice = win |
| 7 | 🔴 Worldfire | 9 | wincon — BANNED | Set life to 1, exile all |
| 8 | Storm Herd | 10 | wincon — token swarm | Pegasus = life total |
| 9 | Rise of the Eldrazi | 12 | wincon — bomb | Destroy all, extra turn, 7/7 annihilator 2 |

### Recursion / Engine (3)

| # | Carta | CMC | Função Real |
|:--|:------|:---:|:------------|
| 1 | Past in Flames | 4 | recursion — flashback all inst/sorc |
| 2 | Mizzix's Mastery | 4 | recursion — overload: exile→copy all |
| 3 | Birgi, God of Storytelling | 3 | engine — R per spell + backside draw |

### Commander (1)

| # | Carta | CMC |
|:--|:------|:---:|
| 1 | Lorehold, the Historian | 4 |

---

## COMPARAÇÃO COM PG IDEAL PROFILE

| PG Role | Ideal | Actual | Delta | Status |
|:--------|:-----:|:------:|:-----:|:-------|
| lands | 32.0 | 33 | +1 | ✅ Dentro |
| ramp (rocks) | 3.67 | 12 | +8.33 | 🔴 Muito acima |
| ritual_treasure | 10.0 | 5 (+2 treasure) | -3 | 🟡 Abaixo |
| big_spell_payoff | 7.67 | 5 (wincons CMC≥6) | -2.67 | 🟡 Abaixo |
| miracle_topdeck | 4.33 | 0 | -4.33 | 🔴 Ausente |
| interaction | 5.33 | 8 (removal+stax+wipe) | +2.67 | 🟡 Acima |
| protection | 3.67 | 8 | +4.33 | 🔴 Muito acima |
| draw_value | 2.67 | 9 | +6.33 | 🔴 Muito acima |
| tutor | 3.67 | 6 | +2.33 | 🟡 Acima |
| win_condition | 1.33 | 9 | +7.67 | 🔴 Muito acima |
| board_wipe | 2.0 | 1 | -1.0 | 🟡 Abaixo |

**Diagnóstico:** O deck é SIGNIFICATIVAMENTE diferente do perfil PG. O perfil PG
é para **Lorehold spellslinger big-spells** (miracle, big spell payoff, ritual_treasure).
Este deck é **cEDH turbo-combo** focado em Dualcaster Mage + copy spells. A assinatura
`ritual_treasure=10` e `miracle_topdeck=4.33` do perfil PG indica um deck que gera
tesouros e manipula o topo para milagres — este deck não faz nada disso.

**Conclusão:** O perfil PG NÃO é adequado para validar este deck. É um arquétipo diferente.

---

## SYNERGY_MAP — 7 Eixos

### A) Token Makers + Pump (3/10)

**Tokens:** Storm Herd (pegasus = vida), Rite of the Dragoncaller (dragons per spell),
Urza's Saga (constructs).

**Pump:** NENHUM. Sem Craterhoof, sem Akroma's Will, sem Moonshaker Cavalry.
O deck não tem como dar evasion/haste em massa para tokens.

**Score: 3/10** — Produz tokens mas não consegue convertê-los em vitória no mesmo turno.

### B) Board Wipes + Proteção Assimétrica (5/10)

**Wipes:** Blasphemous Act (1). Só uma wipe no deck inteiro.

**Proteção contra wipe:** Teferi's Protection, Boros Charm, Flawless Maneuver (8 cartas).

**Problema:** 8 slots de proteção para 1 wipe. A razão wipe/proteção de 1:8 é invertida.

**Score: 5/10** — Proteção excelente, pouquíssima remoção em massa.

### C) Recursion Chains (7/10)

**Cadeias:**
1. **Past in Flames → ritual chain → storm kill:** Flashback todos os rituals do grave.
2. **Mizzix's Mastery (overload) → todas as spells do grave:** Exile todas, cópia todas.
3. **Lorehold commander:** Copy spell do grave por RW com desconto de descarte.

**Fraqueza:** Sem Underworld Breach. Past in Flames é one-shot. Mizzix's Mastery custa 8
(overload) — difícil em cEDH.

**Score: 7/10** — Cadeias sólidas mas falta a peça mais broken (Underworld Breach).

### D) Explosive Mana (8/10)

**Fontes:** 6 rocks + 2 0-CMC + 5 rituals + 2 treasure engines + cost reducer + Sol land + 3 rainbow.

**Sequência ideal T1-T3:**
- T1: Land → Sol Ring/Mana Vault → Arcane Signet (4-5 mana T2)
- T2: Birgi/Storm-Kiln → ritual → Dualcaster + Twinflame = WIN
- Ou: T1 Land → Lotus Petal → Seething Song → Jeska's Will → Approach + Top (vitória T2-T3)

**Score: 8/10** — Excelente. Falta Mox Diamond, Chrome Mox (removidos pelo usuário).

### E) Combo Pieces (9/10)

**Combos determinísticos:**

1. **Dualcaster Mage + Twinflame** (3RRR): Infinitos Dualcasters 2/2 com haste. WIN.
2. **Dualcaster Mage + Heat Shimmer** (2RRR): Idem. WIN.
3. **Approach of the Second Sun + Sensei's Divining Top** (7 mana): Win em 2 turnos (ou
   mesmo turno com mana infinita).
4. **Aetherflux Reservoir + Storm turn:** Ritual chain → 10+ spells → 55+ life → laser.

**Score: 9/10** — Múltiplos combos de 2 cartas. Dualcaster é tutorável por 4 tutores diferentes.

### F) Stack Interaction (6/10)

**Counterspells:** Pyroblast (apenas blue). Nenhum universal.

**Silence effects (3):** Silence, Orim's Chant, Ranger-Captain (sac). Proteção proativa.

**Protection (8):** Teferi's, Boros Charm, Flawless Maneuver, Mom, Giver, Greaves,
Grand Abolisher, Deflecting Swat.

**Score: 6/10** — Excelente proteção para seu combo. Vulnerável a combos adversários não-blue.

### G) Resilience (7/10)

**Recuperação:** Mizzix's Mastery, Past in Flames, Hall of Heliod, Lorehold commander.

**Fraquezas:** Gy hate (Rest in Peace desliga tudo), stax de artefato (Null Rod),
Cursed Totem (desliga criaturas-chave).

**Score: 7/10** — Bom recursion mas vulnerável a hate comum no formato.

---

## SCORE CARD RESUMO

| Eixo | Score | Status |
|:-----|:-----:|:-------|
| A) Token + Pump | 3/10 | 🔴 Fraco |
| B) Wipes + Proteção | 5/10 | 🟡 Médio |
| C) Recursion Chains | 7/10 | 🟢 Bom |
| D) Explosive Mana | 8/10 | 🟢 Excelente |
| E) Combo Pieces | 9/10 | 🟢 Excelente |
| F) Stack Interaction | 6/10 | 🟡 Médio |
| G) Resilience | 7/10 | 🟢 Bom |
| **Média** | **6.4/10** | — |

---

## DIAGNÓSTICO DE ARQUÉTIPO

**Arquétipo real:** cEDH Turbo-Combo (Dualcaster Mage + copy spells)

**Plano de jogo:**
1. **T1-T2:** Land + fast mana rock → 3-4 mana disponível
2. **T2-T3:** Tutor para Dualcaster Mage ou Twinflame/Heat Shimmer
3. **T3-T4:** Silence/Orim's → combo → WIN

**Forças:** 12 fast mana, 6 tutores, 3 Silence effects, combo de 2 cartas determinístico.

**Fraquezas:** Worldfire BANNED, 9 wincons é excessivo, wincons battlecruiser
(Guttersnipe, Dragoncaller, Storm Herd, Rise) são lentos demais para cEDH.

---

## RECOMENDAÇÕES (TOP 5)

### 🔴 #1: REMOVER Worldfire IMEDIATAMENTE (BANLIST)

**Sugestão de substituição:** Underworld Breach (CMC 2).

### 🟡 #2: Consolidar Win Conditions (9→4-5)

Cortar: Guttersnipe (CMC 3), Rite of the Dragoncaller (CMC 6), Storm Herd (CMC 10),
Rise of the Eldrazi (CMC 12).

### 🟡 #3: Adicionar Underworld Breach

CMC 2, recursion infinito. Breach + ritual chain = mana infinita e storm infinito.

### 🟡 #4: Cortar Proteção Excedente (8→5 slots)

Sugestão: cortar Flawless Maneuver ou Lightning Greaves.

### 🟢 #5: Adicionar Card Advantage Barato

Mystic Remora (CMC 1) ou Archivist of Oghma (CMC 2).

---

## INTEGRIDADE DO PIPELINE

| Verificação | Resultado |
|:------------|:----------|
| Card hash | `f2241d994743e8142396c0f846917fde` |
| Banlist check | 🔴 Worldfire (BANNED) |
| Tag corruption | 🔴 20 cards 'unknown' (classifier skipped) |
| CMC corruption | 🔴 6 cards CMC=NULL, múltiplos CMC=0.0 |
| Stale decks columns | ⚠️ board_wipe_count=4 vs real=1, engine_count=4 vs real=0 |
| PG accessibility | ❌ Password auth failed — usando perfil inline |

---

**Próximo passo:** Re-classificar o deck (executar `classify_card()` e 
`infer_functional_card_tags()`). Remover Worldfire. Métricas atuais do DB são lixo.
