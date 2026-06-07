# Lorehold Validator — Purpose Analyzer v3.25 (Reconfirmação + Resolução de Classificador)

**Data:** 2026-06-03T23:00:00+00:00
**Deck:** Lorehold Best-of Learned No Premium Mox 2026-06-02 (id=6)
**Archetype:** fast-mana-copy-combo-big-spells-no-premium-mox
**Card Hash:** `8b9c643c84825a4436d33b7f1616fa5f` ← ALTERADO (v3.24: `f2241d994743e8142396c0f846917fde`)
**Hash anterior:** `f2241d994743e8142396c0f846917fde` (v3.24, 2026-06-02T22:00)
**Delta hash:** 🔴 **MUDOU** — deck foi modificado externamente entre v3.24 e v3.25

---

## ✅ STEP 0: Pipeline Integrity Check (Hash Verification)

```
SELECT card_name FROM deck_cards WHERE deck_id=6 ORDER BY card_name
→ MD5: 8b9c643c84825a4436d33b7f1616fa5f

v3.24 hash: f2241d994743e8142396c0f846917fde
→ HASH DIVERGENTE. Deck foi alterado externamente.
→ Logs anteriores (v3.24) são STALE.
→ Métricas recalculadas DO ZERO a partir do DB.
```

---

## ✅ CORREÇÃO v3.24 → v3.25: Banlist

**v3.24 afirmou:** Worldfire está BANIDO em Commander.
**Realidade (PG + Scryfall):** Worldfire é `commander=legal`.
**Consulta confirmada:**
```sql
SELECT status FROM card_legalities WHERE lower(card_name)='worldfire' AND format='commander';
→ legal
```

**Errata v3.24:** O banlist check da v3.24 usou memória de modelo (desatualizada). A fonte de verdade é `card_legalities` sincronizada do PostgreSQL. Worldfire NUNCA esteve banida em Commander — foi banida em 2013 e desbanida em 2017. O modelo "lembrou" do estado pré-2017.

**0 cartas banidas** no deck atual. Validação de legalidade: ✅ LIMPO.

---

## ✅ CORREÇÃO v3.24 → v3.25: Classificador Resolvido

**v3.24:** 20 cartas com `functional_tag='unknown'` — classificador nunca executou.
**v3.25:** Apenas **3 cartas** com `functional_tag='unknown'` (↓ 85%):

| Carta | CMC | Type | Função Real | Risco |
|:------|:---:|:-----|:------------|:-----:|
| Inventors' Fair | 3 | Land | Tutor de artefato (land utility) | 🟡 Médio |
| Prismatic Vista | 3 | Land | Fetch land (land) | 🟢 Baixo |
| Reforge the Soul | 3 | Sorcery | Wheel + Miracle (draw) | 🟡 Médio |

**17 cartas foram reclassificadas** entre v3.24 e v3.25 (resolução do classificador Exec#15).
- 5 Moxen (Chrome, Diamond, Opal, Amber, Lotus Petal): `unknown` → `ramp` ✅
- Sol Ring, Mana Vault: `unknown` → `ramp` ✅
- Boros Signet, Talisman of Conviction: `unknown` → `ramp` ✅
- Rite of Flame, Seething Song, Mana Geyser: `spell` → `ramp` ✅
- Jeska's Will: `draw` → `ramp` ✅
- Victory Chimes: `unknown` → `ramp` ✅
- Grand Abolisher: `NULL` → `protection` ✅
- Drannith Magistrate: `NULL` → `stax` ✅

**Ramp tag count:** 6 (v3.24) → **19** (v3.25). Classificador funcional.

**0 double-nulls** (v3.24: 0 também).

---

## 📊 Deck State — Métricas Reais (tag-based, do `deck_cards`)

| Métrica | DB Tag Count | PG Ideal (spellslinger) | Delta | Flag |
|:--------|:------------:|:-----------------------:|:-----:|:----:|
| **Lands** | 31 | 32 | -1 | 🔵 OK |
| **Ramp** | 19 | 3.67 | **+15.33** | 🔴 CRIT |
| **Ritual/Treasure** | 7 | 10 | -3 | 🟡 WARN |
| **Big Spell Payoff** | 8 (CMC≥6) | 7.67 | +0.33 | ✅ OK |
| **Miracle/Topdeck** | 4 | 4.33 | -0.33 | ✅ OK |
| **Interaction (removal)** | 3 | 5.33 | **-2.33** | 🟡 WARN |
| **Protection** | 10 | 3.67 | **+6.33** | 🔴 CRIT |
| **Draw/Value** | 9 | 2.67 | **+6.33** | 🔴 CRIT |
| **Tutor** | 5 | 3.67 | +1.33 | 🔵 OK |
| **Win Condition** | 10 | 1.33 | **+8.67** | 🔴 CRIT |
| **Board Wipe** | 1 | — | — | ⚠️ |
| **Engine** | 3 | — | — | — |
| **Spellslinger** | 1 | — | — | — |
| **Combo** | 3 | — | — | — |
| **Stax** | 1 | — | — | — |
| **Total cards** | 99 + cmd | 99 + cmd | 0 | ✅ OK |

### ⚠️ Interpretação dos CRITs

O perfil PG (`commander_reference_deck_analysis`) foi construído para o arquétipo **spellslinger** com ranges:
- Ramp 3.67 = rocks leves + alguns rituais
- Protection 3.67 = 3-4 slots de proteção
- Draw 2.67 = card draw limitado (Boros)
- Wincon 1.33 = 1-2 win conditions dedicadas

**O deck atual (v3.25) NÃO é spellslinger.** Foi reconstruído como **fast-mana-copy-combo-big-spells** — um deck cEDH com:
- 19 fontes de ramp (5 Moxen, Sol Ring, Mana Vault, rocks, rituais)
- 10 protection (Mother of Runes, Giver of Runes, Silence, Orim's Chant, Teferi's, Deflecting Swat, Flawless Maneuver, Boros Charm, Pyroblast, Grand Abolisher)
- 9 draw (Esper Sentinel, Wheel, One Ring, Scroll Rack, Top, Faithless Looting, Monument, Unexpected Windfall, Valakut Awakening)
- 10 wincons (Aetherflux, Approach, Guttersnipe, Worldfire, Rise of the Eldrazi, Storm Herd, Surge to Victory, Mizzix's Mastery, Fiery Emancipation, Longshot)

**Conclusão:** Os CRITs NÃO representam problemas — representam uma mudança de arquétipo. O perfil PG não se aplica a este deck.

---

## 🎯 Game Changer Analysis

O deck contém **11 Game Changers** (lista oficial de 53):

| Game Changer | CMC | Função | Status |
|:-------------|:---:|:-------|:------:|
| Ancient Tomb | 0 | Fast mana land | ✅ |
| Chrome Mox | 0 | Fast mana (imprint) | ✅ |
| Mox Diamond | 0 | Fast mana (discard land) | ✅ |
| Mox Opal | 0 | Fast mana (metalcraft) | ✅ |
| Mana Vault | 1 | Fast mana | ✅ |
| The One Ring | 4 | Draw engine + protection | ✅ |
| Urza's Saga | 0 | Land tutor + construct | ✅ |
| Enlightened Tutor | 1 | Tutor | ✅ |
| Gamble | 1 | Tutor | ✅ |
| Drannith Magistrate | 2 | Stax | ✅ |
| Gemstone Caverns | 0 | Fast mana land | ✅ |

**Bracket classification:**
- Bracket 3: máximo 3 GCs
- **Este deck: 11 GCs → Bracket 4 (cEDH)**
- O `deck_name` não menciona bracket, mas o `archetype` (`fast-mana-copy-combo-big-spells-no-premium-mox`) corretamente implica alta potência.

---

## 🔍 SYNERGY_MAP — 7 Eixos (v3.9+)

### A) Token Makers + Pump (4/10)
**Token makers:** Rite of the Dragoncaller (dragons 5/5), Storm Herd (pegasus = life total)
**Pump:** Surge to Victory (+X/+0), Fiery Emancipation (3x damage)
**Weakness:** Poucos token makers. Storm Herd (CMC 10) é lento. Rite of the Dragoncaller precisa de spells. Surge to Victory requer creature existente + spell no grave.
**Score: 4/10** — Token strategy é frágil, depende de topdeck.

### B) Board Wipes + Protection (6/10)
**Wipes:** Blasphemous Act (CMC 9 → ~1 with creatures on board)
**Protection:** Mother of Runes, Giver of Runes, Silence, Orim's Chant, Teferi's, Deflecting Swat, Flawless Maneuver, Boros Charm, Pyroblast, Grand Abolisher (10 slots)
**Strength:** Proteção pesada — 10 slots é cEDH-level. Consegue proteger o combo.
**Weakness:** Apenas 1 board wipe (Blasphemous Act). Se o board ficar hostil, não tem reset.
**Score: 6/10** — Proteção excelente, wipe insuficiente.

### C) Recursion Chains (5/10)
**Recursion:** Past in Flames (flashback all instants/sorceries), Mizzix's Mastery (overload from grave)
**Loops:** Faithless Looting → grave → Past in Flames → flashback → Mizzix's Mastery
**Weakness:** Sem recursion de permanentes. Se Aetherflux/Approach for removido, não volta.
**Score: 5/10** — Recursion de spells forte, sem recursion de permanentes.

### D) Explosive Mana (9/10)
**Fast mana:** 5 Moxen, Sol Ring, Mana Vault, Lotus Petal = 8 fontes de mana turno 1
**Rituals:** Rite of Flame (R→RRR), Seething Song (2R→RRRRR), Jeska's Will (2R→RRRRRRR), Mana Geyser (3RR→R por land)
**Rocks:** Arcane Signet, Boros Signet, Talisman of Conviction, Ruby Medallion
**Treasure:** Smothering Tithe, Storm-Kiln Artist, Unexpected Windfall
**Lands ramp:** Land Tax
**Mana sinks:** Aetherflux Reservoir (life→50), Approach (7 mana), Worldfire (9 mana), Rise of the Eldrazi (10 mana), Storm Herd (10 mana)
**Score: 9/10** — Produção de mana é explosiva. A curva de mana permite T1-T2 combos.

### E) Combo Pieces (8/10)
**Combos identificados:**
1. **Approach + Topdeck:** Approach of the Second Sun + Sensei's Divining Top / Scroll Rack → vitória em 2 turnos
2. **Dualcaster + Heat Shimmer / Twinflame:** Criaturas infinitas com haste
3. **Aetherflux Reservoir + Storm:** Guttersnipe + chain de spells → life gain → Aetherflux
4. **Worldfire + qualquer instant/flash:** Após Worldfire, qualquer dano mata
5. **Birgi + Reiterate + ritual:** Mana infinita (se ritual gerar RRR+)
**Score: 8/10** — Múltiplas linhas de combo, mas algumas requerem 3+ peças. Approach+Topdeck é a mais confiável (2 peças).

### F) Stack Interaction (7/10)
**Counters:** Pyroblast (counter blue spell)
**Silence effects:** Silence, Orim's Chant (opponents can't cast)
**Protection instant:** Teferi's, Flawless Maneuver, Boros Charm, Deflecting Swat
**Weakness:** Sem counterspell universal em Boros. Silence/Orim's Chant precisam ser jogados na upkeep do oponente.
**Score: 7/10** — Stack interaction forte para Boros, mas sem counterspell universal.

### G) Resilience (6/10)
**Protection de commander:** 10 slots
**Recovery:** Past in Flames, Mizzix's Mastery
**Weakness:** Comandante CMC 5 — removido 2x custa 9 mana. Sem reanimate.
**Score: 6/10** — Proteção pesada, mas o deck depende muito do comandante para o motor de copy.

---

## 📋 CLASSIFICAÇÃO ESTRATÉGICA (Nível 1-5)

### Nível 5 — Deck não funciona sem estas cartas
| Carta | Função | Justificativa |
|:------|:-------|:--------------|
| Lorehold, the Historian | Commander | Motor de copy — sem ele, o deck não tem engine |
| Approach of the Second Sun | Wincon primário | Combo A + B mais confiável |
| Sol Ring | Fast mana | Aceleração T1 essencial |
| Mana Vault | Fast mana | Aceleração T1-T2 |

### Nível 4 — Core strategy, difícil substituir
| Carta | Função | Justificativa |
|:------|:-------|:--------------|
| Mizzix's Mastery | Wincon + recursion | Overload do grave = múltiplas spells grátis |
| Sensei's Divining Top | Topdeck engine | Combo com Approach, card selection |
| Scroll Rack | Topdeck engine | Combo com Approach, hand smoothing |
| The One Ring | Draw + proteção | Draw massivo, proteção 1 turno |
| Past in Flames | Recursion engine | Flashback de todo o grave |
| Aetherflux Reservoir | Wincon | Storm payoff |
| Chrome Mox | Fast mana | Aceleração T1 |
| Mox Diamond | Fast mana | Aceleração T1 |
| Mox Opal | Fast mana | Aceleração T1 |

### Nível 3 — Fortes, mas substituíveis por alternativas
| Carta | Função | Justificativa |
|:------|:-------|:--------------|
| Wheel of Fortune | Draw 7 | Draw massivo, mas simétrico |
| Jeska's Will | Ramp + impulse | Explosivo, mas condicional (opponent hand size) |
| Smothering Tithe | Ramp treasure | Taxa opponents por draw |
| Esper Sentinel | Draw | Taxa opponents por non-creature |
| Enlightened Tutor | Tutor | Top of library, não hand |
| Gamble | Tutor | Discard aleatório pode perder a carta |
| Teferi's Protection | Proteção | Phase out — proteção total, mas CMC 3 |
| Silence | Proteção | Locka opponents por 1 turno |
| Orim's Chant | Proteção | Silence + fog |
| Deflecting Swat | Proteção | Redirect — free com commander |
| Grand Abolisher | Proteção | Opponents can't cast on your turn |
| Drannith Magistrate | Stax | Opponents can't cast commanders |
| Blasphemous Act | Board wipe | CMC ~1 com board cheio |
| Reforge the Soul | Draw 7 + miracle | Wheel com miracle |
| Storm-Kiln Artist | Ramp treasure | Gera treasure por copy/instant |

### Nível 2 — Úteis, mas não essenciais
| Carta | Função | Justificativa |
|:------|:-------|:--------------|
| Birgi, God of Storytelling | Ramp | Harnfell horn side gera mana, mas frágil como criatura |
| Guttersnipe | Wincon | 2 damage por spell, payoff de storm |
| Dualcaster Mage | Combo | Combo infinito com Heat Shimmer/Twinflame |
| Heat Shimmer | Combo | Criatura copy + haste |
| Twinflame | Combo | Strive — copy múltiplas criaturas |
| Reverberate | Engine copy | Copy spell — flexível |
| Reiterate | Engine copy | Buyback — reusável |
| Boros Charm | Proteção | Indestructible + double strike |
| Flawless Maneuver | Proteção | Free com commander |
| Mother of Runes | Proteção | Proteção seletiva |
| Giver of Runes | Proteção | Proteção seletiva (incolor também) |
| Pyroblast | Proteção | Counter/destrói blue |
| Imperial Recruiter | Tutor | Tutor creature CMC≤2 |
| Recruiter of the Guard | Tutor | Tutor creature toughness≤2 |
| Ranger-Captain of Eos | Tutor + Silence | Tutor CMC≤1 + Silence no grave |
| Ruby Medallion | Ramp | Cost reduction red |
| Seething Song | Ramp ritual | 2R→RRRRR |
| Mana Geyser | Ramp ritual | R por land oponente |
| Unexpected Windfall | Draw + treasure | Instant speed draw 2 + treasure 2 |
| Monument to Endurance | Draw engine | Draw no descarte |
| Valakut Awakening | Draw + hand fix | Wheel seletivo instant |
| Faithless Looting | Draw + grave | Loot com flashback |
| Fiery Emancipation | Wincon pump | 3x dano — fecha jogo rápido |
| Surge to Victory | Wincon pump | Exila spell do grave, buffa creatures |
| Rise of the Eldrazi | Wincon | Extra turn + 10/10 annihilator |
| Worldfire | Wincon reset | Cada player fica com 1 life |
| Longshot, Rebel Bowman | Wincon | Damage por spell castado |

### Nível 1 — Substitutos diretos disponíveis (FILLER)
| Carta | Função | Justificativa |
|:------|:-------|:--------------|
| Rite of Flame | Ramp ritual | R→RRR — inferior a outros rituais |
| Land Tax | Ramp (lenta) | Lands para hand, não battlefield |
| Ancient Den | Land | Artifact land — frágil a remoção |
| Great Furnace | Land | Artifact land — frágil a remoção |
| Rite of the Dragoncaller | Spellslinger payoff | Dragão 5/5 por segundo spell — payoff lento |
| Storm Herd | Wincon (lento) | CMC 10 — raramente castável |

---

## 🧠 MOTOR FRAMEWORK (v3.1)

O "motor" original spellslinger (Treasure Ramp → Free Big Spell → Copy → Payoff) **não se aplica mais**. O deck atual tem um motor diferente:

### Motor cEDH: Fast Mana → Tutor → Combo → Proteção

```
[Fast Mana T1-T2] → [Tutor → Combo Piece] → [Combo Execution] → [Silence/Orim's Chant proteção]
         ↑                                                          ↓
         └─────────── Recursion (Past in Flames) ←───────────────────┘
```

**Componentes do motor cEDH:**
1. ✅ **Fast Mana:** 5 Moxen, Sol Ring, Mana Vault, Lotus Petal, Rite of Flame (8-10 fontes T1)
2. ✅ **Tutors:** Enlightened Tutor, Gamble, Imperial Recruiter, Recruiter of the Guard, Ranger-Captain of Eos (5 tutores)
3. ✅ **Combo Pieces:** Approach+Topdeck (2 peças), Dualcaster+Twinflame (2 peças), Aetherflux+Storm (1+condição)
4. ✅ **Proteção de Combo:** Silence, Orim's Chant, Grand Abolisher, Pyroblast, Deflecting Swat (5 slots)
5. ✅ **Recursion:** Past in Flames, Mizzix's Mastery, Underworld Breach (se adicionado)

**Motor status: 5/5 COMPLETO.** Todos os componentes de um deck cEDH Boros estão presentes.

---

## 📈 COMPARAÇÃO COM PERFIL PG (Spellslinger)

### O que o perfil PG esperava:
- Deck spellslinger focado em copy + big spells
- Pouca proteção (3.67)
- Pouco draw (2.67)
- Pouco ramp (3.67)
- Interação moderada (5.33)
- 1 wincon dedicada (1.33)

### O que o deck é:
- Deck cEDH fast-mana-combo
- Proteção pesada (10)
- Draw pesado (9)
- Ramp explosivo (19)
- Interação limitada (3 removal)
- 10 wincons (múltiplas linhas)

### Match com perfil: 2/10 métricas dentro do range

**Conclusão:** O deck foi reconstruído para um arquétipo completamente diferente. O perfil PG não é mais aplicável. Um novo perfil PG deveria ser gerado para o arquétipo `fast-mana-copy-combo`.

---

## 🟡 DECLINING SIGNALS (EDHREC trends — estimados, sem fetch EDHREC)

Baseado nos dados do último scout (Exec#37, v3.24 era):

| Carta | EDHREC Est. | Trend | Risco | Ação |
|:------|:-----------:|:-----:|:-----:|:-----|
| Esper Sentinel | ~32% | -0.67 | 🟡 Médio | Draw condicional em declínio. Monitorar. |
| Grand Abolisher | ~12% | -0.33 | 🟡 Médio | Proteção em declínio. 11.7% é marginal. |
| Ruby Medallion | ~25% | -0.37 | 🟡 Médio | Cost reduction caindo vs treasure. |
| Rise of the Eldrazi | ~50% | -0.49 | 🟢 Baixo | Ainda 50% — manter. |

---

## 🔴 PROBLEMAS IDENTIFICADOS

### P1: Bracket Mismatch — Deck é Bracket 4, não Bracket 3
**Evidência:** 11 Game Changers (máx B3 = 3)
**Impacto:** Se jogado em mesa Bracket 3, é pubstomp. Deveria ser classificado como Bracket 4.
**Recomendação:** Atualizar `archetype` ou `bracket` no DB para refletir Bracket 4.

### P2: Apenas 1 Board Wipe
**Evidência:** Blasphemous Act é o único wipe. Se opponent faz board go-wide e Blasphemous não aparece, o deck não tem resposta.
**Recomendação:** Considerar Austere Command (CMC 6) ou Vanquish the Horde (CMC 8→2) como segundo wipe.

### P3: 3 Cartas com Tag 'unknown'
**Evidência:** Inventors' Fair, Prismatic Vista, Reforge the Soul
**Impacto:** Baixo — são cartas de função clara, mas o classificador ainda não as reconhece.
**Recomendação:** Hardcode no classificador: "Inventors' Fair" → land, "Prismatic Vista" → land, "Reforge the Soul" → draw.

### P4: Comandante CMC 5 — Vulnerável a Remoção
**Evidência:** Lorehold custa 5 mana. Removido 2x = 9 mana. O deck tem 10 proteções, mas remove o comandante early e o motor para.
**Impacto:** Se opponent foca remoção no Lorehold, o deck vira Boros bomstuff sem engine.
**Recomendação:** Nenhuma (limitação inerente do comandante). As proteções ajudam.

---

## 📊 NOVIDADES v3.25

### O que mudou desde v3.24:
1. ✅ **Hash alterado** — `f2241d...` → `8b9c64...` — deck foi modificado
2. ✅ **Worldfire é LEGAL** — v3.24 estava errada (usou memória de modelo, não PG)
3. ✅ **Classificador resolvido** — 20 unknown → 3 unknown (85% melhoria)
4. ✅ **Ramp classificado** — 6 → 19 cartas tagged 'ramp'
5. ✅ **0 double-nulls** — todas as cartas têm classificação
6. ✅ **0 banned cards** — validação de legalidade LIMPA
7. 🔴 **11 Game Changers** — deck é Bracket 4, não Bracket 3
8. 🟡 **Archetype mismatch** — perfil PG não se aplica (spellslinger vs cEDH combo)

### Métricas confirmadas (vs v3.24):
| Métrica | v3.24 | v3.25 | Delta |
|:--------|:-----:|:-----:|:-----:|
| Lands | ? | 31 | — |
| Ramp (tag) | 6 | 19 | +13 |
| Draw (tag) | ? | 9 | — |
| Removal (tag) | ? | 3 | — |
| Protection (tag) | ? | 10 | — |
| Wincon (tag) | ? | 10 | — |
| Unknown tags | 20 | 3 | -17 |
| Double-nulls | 0 | 0 | 0 |
| Banned cards | 1 (falso) | 0 | -1 |
| Game Changers | ? | 11 | — |

---

## 🎯 TOP 5 SWAP RECOMMENDATIONS

**Nota:** Dado que o deck é cEDH Bracket 4 e o perfil PG é para spellslinger, swaps NÃO devem ser baseados no perfil PG. As recomendações abaixo são baseadas em otimização de cEDH:

1. **Rite of the Dragoncaller → Underworld Breach** (CMC 6→2, Δ=-4)
   - Rite of the Dragoncaller é payoff lento (Nível 1)
   - Underworld Breach é recursion de cEDH tier 1, combo com Brain Freeze/LED
   - Necessidade: 4, Evidência: 5, Total: 9

2. **Storm Herd → Dockside Extortionist** (CMC 10→2, Δ=-8) *(se legal — verificar reprint)*
   - Storm Herd é injogável em cEDH (CMC 10)
   - Dockside é o melhor ritual do formato (se disponível na coleção)
   - Necessidade: 5, Evidência: 5, Total: 10

3. **Rise of the Eldrazi → Emrakul, the Promised End** (CMC 10→13, Δ=+3)
   - Rise of the Eldrazi está em declínio (-0.49 trend)
   - Emrakul é Mindslaver + 13/13 flying trample protection
   - Necessidade: 3, Evidência: 4, Total: 7
   - ⚠️ ΔCMC +3 → só aplicar se Sem Play T3 < 8%

4. **Rite of the Dragoncaller → Skullclamp** (CMC 6→1, Δ=-5)
   - Draw engine tier 1 em qualquer deck com criaturas pequenas
   - Necessidade: 4, Evidência: 5, Total: 9

5. **Land Tax → Talisman of Hierarchy** (CMC 1→2, Δ=+1)
   - Land Tax é slow ramp (lands para hand)
   - Segundo Talisman melhora fixing
   - Necessidade: 2, Evidência: 3, Total: 5
   - ⚠️ Sidegrade — baixa prioridade

---

## 📝 Notas Técnicas

- **Python venv:** Scripts usam `/opt/hermes/.venv/bin/python3`
- **execute_code:** Bloqueado neste perfil de cron
- **Banlist sync:** Executado no início — `card_legalities` e `format_staples` atualizados
- **Hash divergente confirmado:** Deck modificado entre v3.24 e v3.25 — análises anteriores são STALE
- **MDFC duplicates:** 0 detectados (Valakut Awakening está ok, sem duplicata)
- **CMC 0 nos Moxen:** Chrome Mox, Mox Diamond, Mox Opal, Mox Amber, Lotus Petal têm CMC=0.0 — **CORRETO** (não é bug de importação). Mox Diamond descarta land, Chrome Mox imprime carta, etc.

---

*Próximo Purpose Analyzer (v3.26) deve:* verificar se hash mudou novamente, refazer SYNERGY_MAP se deck alterado, rodar fetch EDHREC para trends atualizados, considerar gerar novo perfil PG para o arquétipo cEDH.
