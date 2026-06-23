# Purpose Analyzer v3.20 — Lorehold Spellslinger: RE-CONFIRMACAO + PG REFERENCE + SYNERGY_MAP

> **Data:** 2026-06-01T09:03:00+00:00
> **Fonte:** knowledge.db deck_id=6 — ESTADO REAL DO DB (card_hash = `30d00347764fc2a215edb4e668994871`)
> **Deck:** Lorehold Spellslinger — 100 cards (99 fisicos, ver Valakut duplicado), 86 rows, 35 lands, CMC medio 3.63
> **Ciclo atual:** Pos-Ciclo #22 — **Hash identico ao v3.19. Nenhuma mudanca detectada.**
> **v3.19 → v3.20:** RE-CONFIRMACAO. Card hash `30d00347764fc2a215edb4e668994871` mantido. Deck nao mudou.
> **Correcao critica:** VALIDATOR_LOG.md e VALIDATOR_SUMMARY.md estavam STALE (v3.13 de 31/05). Sincronizados para v3.20.

---

## Secao 0: INTEGRIDADE DO PIPELINE — CONFIRMADA

| Verificacao | v3.19 (08:00) | v3.20 (09:03) | Status |
|:------------|:-------------:|:-------------:|:------:|
| Card hash | `30d00347764fc2a215edb4e668994871` | `30d00347764fc2a215edb4e668994871` | ✅ **IDENTICO** |
| Deck cards | 86 rows, 100 total | 86 rows, 100 total | ✅ Same |
| Lands | 35 | 35 | ✅ Same |
| Commander | 1 (Lorehold) | 1 (Lorehold) | ✅ OK |
| Double-nulls | 4 | 4 | ✅ Same |

### ⚠️ DATA ISSUE: Valakut Awakening Duplicado

O DB tem **duas linhas** para o mesmo card MDFC:

| id | card_name | tag | cmc |
|:---|:----------|:---|:---:|
| 653 | `Valakut Awakening` | draw | 3.0 |
| 350 | `Valakut Awakening // Valakut Stoneforge` | land | 3.0 |

**Impacto:** `SUM(quantity)=100` conta a MESMA carta fisica duas vezes. Deck real tem **99 cartas fisicas**.
**Recomendacao:** Remover linha id=653 (front face duplicada). A linha id=350 (MDFC completa) ja cobre o card.
**Severidade:** 🟡 MODERADA — nao quebra metrica nenhuma, mas infla contagem de draw em +1.

---

## Secao 1: PG REFERENCE PROFILE COMPARISON

Fonte: PostgreSQL `commander_reference_deck_analysis` (3 decks analisados, perfil estatistico otimo).

| PG Role | Ideal | Actual | Diff | Status | Interpretacao |
|:--------|:-----:|:------:|:----:|:------:|:--------------|
| **lands** | 32.00 | **35.0** | +3.0 | 🟡 ACIMA | Boros sem fast mana precisa de 35. **Justificado.** |
| **ramp** | 3.67 | **7.0** | +3.3 | 🟡 ACIMA | 7 rocks (Sol Ring, 3 Signets, Talisman, Fellwar, Map). Excelente. |
| **ritual_treasure** | 10.00 | **10.0** | 0.0 | ✅ IDEAL | 10 geradores (Jeska's Will, Tithe, Storm-Kiln, Big Score, etc.) |
| **big_spell_payoff** | 7.67 | **17.0** | +9.3 | 🟡 ACIMA | 17 payoffs. Deck de Big Spells — **intencional.** |
| **miracle_topdeck** | 4.33 | **7.0** | +2.7 | 🟡 ACIMA | 7 manipuladores. Deck Miracle-focused. **Saudavel.** |
| **interaction** | 5.33 | **11.0** | +5.7 | 🟡 ACIMA | 5 removal + 5 wipes + 1 goad. **Robusto.** |
| **protection** | 3.67 | **8.0** | +4.3 | 🟡 ACIMA | 8 protecoes (3 fogs massivos: Teferi's, Flawless, Boros Charm). |
| **draw_value** | 2.67 | **9.0** | +6.3 | 🟡 ACIMA | 9 fontes (One Ring, Chimes, Monument, Sentinel, Top, etc.) |
| **tutor** | 3.67 | **2.0** | -1.7 | 🔴 **ABAIXO** | **UNICO GAP REAL.** Enlightened + Gamble = 2. PG quer 3.67. |
| **win_condition** | 1.33 | **5.0** | +3.7 | 🟡 ACIMA | 5 wincons (Approach, Akroma's, Worldfire, Apex, Storm Herd). |
| **board_wipe** | 2.00 | **5.0** | +3.0 | 🟡 ACIMA | 5 wipes. Bom mix de assimetricas. |
| **recursion** | 3.33 | **2.0** | -1.3 | 🟡 ABAIXO | Mizzix's Mastery + Restoration Seminar. **Aceitavel** (Mizzix's overload = recursao massiva). |
| **exile_value** | 3.67 | **2.0** | -1.7 | 🟡 ABAIXO | Capstone + Dance with Calamity. **Monitorar.** |
| **spellslinger** | 3.67 | **7.0** | +3.3 | 🟡 ACIMA | 7 cartas. Deck E spellslinger por definicao. |

### Resumo PG: O deck esta ACIMA do perfil ideal em 11/14 roles. Apenas **tutor (-1.7)** e um gap real. Recursion (-1.3) e exile_value (-1.7) sao aceitaveis no contexto.

---

## Secao 2: PG CARD RULINGS — Interacoes Chave

> Fonte: PostgreSQL `card_rulings.ruling_text` (76.991 rulings).

### Lorehold + Miracle
- **Revelacao obrigatoria:** Card com Miracle DEVE ser revelado antes de entrar na mao.
- **Draw vs tutor:** Efeitos que colocam cartas na mao sem usar 'draw' NAO ativam Miracle.
- **Scroll Rack + Miracle:** Colocar carta no topo via Scroll Rack + draw = Miracle ativado.

### Copy Engines (Dualcaster, Double Vision, Bombardment, Primal Amulet)
- **Dualcaster Mage:** Copia na stack. NAO e 'conjurada' — nao ativa Lorehold nem Bombardment.
- **Double Vision:** Copia resolve ANTES do original. Mesmo X. Copia criada mesmo se original counterado.
- **Arcane Bombardment:** Se sair do campo, cartas exiladas PERMANECEM. Nova copia nao acessa exilio anterior.
- **Primal Amulet:** So spells CONJURADOS contam para transformar. Copias de Wellspring NAO contam.

### Topdeck Engine (Scroll Rack, Top, Penance)
- **Scroll Rack:** NAO e draw. Com grimorio <N cartas, pega quantas existirem. NAO causa perda por deck vazio.
- **Sensei's Divining Top:** Ativar 2a habilidade em resposta a 1a = 'draw 1, scry 3' por 1 mana.
- **Penance:** Revela topo, se for da cor escolhida → fundo. Setup de Miracle. Sem rulings no PG (carta antiga).

### Free Protection (Flawless Maneuver, Teferi's, One Ring)
- **Flawless Maneuver:** GRATIS se controla commander. Lorehold sempre commander → sempre gratis.
- **Teferi's Protection:** Phase out — permanentes nao existem ate proximo turno. Vida congelada.
- **The One Ring:** Protecao contra tudo no turno de entrada. Nao previne discard nem ataques diretos.

### Win Conditions (Approach, Mizzix's Mastery)
- **Approach:** Apenas o CONJURADO conta. Copias NAO contam. Se primeiro counterado, segundo AINDA vence.
- **Mizzix's Mastery (Overload):** Exila TODOS instant/sorcery. X = 0 nas copias. Copias nao sao conjuradas.
- **Dance with Calamity:** X = 0 no cast gratuito. Cartas nao conjuradas ficam no exilio permanente.

### Uncounterable (Boseiju, Cavern of Souls)
- **Boseiju:** 2 vidas. Mana gasta em QUALQUER custo torna spell incounteravel (inclui kicker, splice).
- **Cavern of Souls:** Spells do tipo escolhido sao incounteraveis mesmo com custo alternativo (Dash, etc.).

---

## Secao 3: SYNERGY_MAP — 7 Eixos Estrategicos

### A) TOKEN MAKERS + PUMP — Score: 7/10
**Token Makers (5):** Rite of the Dragoncaller (5/5 Dragon por spell), Storm Herd (X Pegasus), Brass's Bounty (X Treasure), Smothering Tithe (Treasure), Storm-Kiln Artist (Treasure).
**Pump (2):** Akroma's Will (double strike + keywords para TODAS), Boros Charm (double strike para 1).
**Melhor par:** Storm-Kiln Artist + Rite of the Dragoncaller → Treasure + 5/5 Dragon por spell. Akroma's Will no turno seguinte = dano massivo.
**PG:** ritual_treasure = IDEAL, win_condition ACIMA.

### B) BOARD WIPES + PROTECTION — Score: 8/10
**Wipes (5):** Blasphemous Act (CMC 1 com board), Call Forth the Tempest (dano dinamico em criaturas dos oponentes; cascade ainda anotada no runtime), Volcanic Vision (dano + recursion), Olorin's Searing Light (exila GY), Worldfire (reset total).
**Protection (8):** Teferi's Protection, Flawless Maneuver (gratis!), Boros Charm, Mother of Runes, Lightning Greaves, Grand Abolisher, Hexing Squelcher, Akroma's Will.
**Ratio:** 5 wipes / 8 protecoes = 0.625. Cada wipe tem 1.6 protecoes de cobertura.
**PG:** board_wipe +3.0, protection +4.3. Ambos robustos.

### C) RECURSION CHAINS — Score: 7/10
**Recursion (2):** Mizzix's Mastery (overload — todo GY), Restoration Seminar (paradigm — copia a cada main phase).
**GY Enablers (3):** Faithless Looting (draw+discard), Dragon's Rage Channeler (surveil), Olorin's Searing Light.
**Chain principal:** Faithless Looting (T1-2) → enche GY → Mizzix's Mastery overload (T5-6) → conjura TUDO.
**PG:** recursion -1.3 (aceitavel — Mizzix's overload compensa quantidade com qualidade).

### D) EXPLOSIVE MANA — Score: 9/10
**Treasure (8):** Smothering Tithe, Storm-Kiln Artist, Big Score, Unexpected Windfall, Brass's Bounty, Hit the Mother Lode, Jeska's Will, Ragavan.
**Rituals (2):** Simian Spirit Guide (R instantaneo), Jeska's Will (RRR + exile top 3).
**Rocks (5):** Sol Ring, Arcane Signet, Boros Signet, Talisman, Fellwar Stone.
**Mana Sinks (4):** Dance with Calamity, Improvisation Capstone, Call Forth the Tempest, Storm Herd.
**Ideal sequence:** T1 Land + Sol Ring → T2 Land + Signet → T3 Land + Tithe → T4 Land + Storm-Kiln → T5 8+ manas.
**PG:** ritual_treasure = IDEAL, ramp +3.3. Motor de mana e a forca do deck.

### E) COMBO PIECES — Score: 7/10
**Deterministico (1):** Approach → Top/Scroll Rack → Approach = VITORIA. Requer 14 manas totais.
**Semi-deterministico (2):** Worldfire + qualquer fonte de dano. Dualcaster Mage + spell alvo na stack.
**⚠️ Perda em C#17-C#22:** Flare of Duplication e Twinflame foram removidos. Combo Approach+Flare (mesmo turno) PERDIDO.
**PG:** win_condition +3.7. Redundancia saudavel, mas combo instant-speed era diferencial.

### F) STACK INTERACTION — Score: 5/10
**Counterspell proxy (2):** Hexing Squelcher (taxa), Grand Abolisher (silencia no seu turno).
**Redirect (1):** Deflecting Swat.
**Uncounterable (2):** Boseiju, Cavern of Souls.
**Spell Copy (1):** Dualcaster Mage (pode copiar counterspell oponente).
**Nota:** Stack interaction e fraqueza classica de Boros. Flare of Duplication foi cortada.

### G) RESILIENCE — Score: 8/10
**Fogs massivos (3):** Teferi's Protection, Flawless Maneuver, Boros Charm.
**Protecao pontual (2):** Mother of Runes, Lightning Greaves.
**Anti-target (1):** The One Ring.
**Recuperacao (2):** Mizzix's Mastery, Restoration Seminar.
**PG:** protection +4.3. 3 fogs = sobrevive a 3 wipes/alpha strikes.

### SYNERGY_MAP Summary

| Eixo | Score | PG Alignment | Destaque |
|:-----|:-----:|:-------------|:---------|
| A) TOKEN MAKERS + PUMP | 7/10 | ritual_treasure = IDEAL | — |
| B) BOARD WIPES + PROTECTION | 8/10 | protection +4.3 | Flawless Maneuver gratis |
| C) RECURSION CHAINS | 7/10 | recursion -1.3 (aceitavel) | Mizzix's overload compensa |
| D) EXPLOSIVE MANA | 9/10 | ritual_treasure = IDEAL | Motor excepcional |
| E) COMBO PIECES | 7/10 | win_condition +3.7 | Flare/Twinflame perdidos |
| F) STACK INTERACTION | 5/10 | N/A (Boros) | — |
| G) RESILIENCE | 8/10 | protection +4.3 | 3 fogs massivos |

**SYNERGY_MAP Score Medio: 7.3/10** — Deck solido com motor de mana excepcional. Stack interaction e a fraqueza classica de Boros. Perda de Flare of Duplication reduziu combo potential.

---

## Secao 4: DOUBLE-NULL AUDIT

| Card | CMC | Real Function | Risk | EDHREC % | Nota |
|:-----|:---:|:--------------|:-----|:--------:|:-----|
| Scroll Rack | 2 | Topdeck engine | 🔴 CRITICAL | 51.3 | NUNCA cortar. Essencial para Miracle + Approach. |
| Penance | 3 | Miracle enabler | 🔴 CRITICAL | N/A | NUNCA cortar. Unico enabler de Miracle deterministico. |
| Grand Abolisher | 2 | Protection | 🟡 HIGH | 11.7 | Trend -0.27. Monitorar — util mas declinante. |
| Taunt from the Rampart | 5 | Mass goad | 🟢 LOW | 35.2 | Seguro. 35.2% EDHREC. Manter. |

**4 double-nulls — estavel desde v3.13.** Scroll Rack e Penance sao core engines (Nivel 4). Grand Abolisher em declinio lento. Taunt seguro.

---

## Secao 5: MUDANCAS DESDE v3.13 (canonical file fix)

O VALIDATOR_LOG.md estava congelado em v3.13 (31/05) enquanto o deck passou por mudancas significativas detectadas em v3.19:

| Tipo | Cartas | Net DCMC | Nota |
|:-----|:-------|:--------:|:-----|
| **OUT (8)** | Ashling(4), Austere(6), Demand(2), Flare(3), Surge(6), Thrill(2), Twinflame(2), Weathered Wayfarer(1) | -26 | 8 cartas removidas |
| **IN nonland (5)** | Dualcaster Mage(3), Fellwar Stone(2), Flawless Maneuver(3), Primal Amulet(4), Valakut Awakening(3) | +15 | 5 cartas adicionadas |
| **IN lands** | Fetch/dual upgrades (8 fetches) + utility lands (Ancient Tomb, Boseiju, Cavern, Kor Haven, Exotic Orchard, Dormant Volcano) | 0 | Manabase refeita |
| **NET** | -3 cartas | **-11 DCMC** | **~+6pp melhora T3 estimada** |

### Cartas que o v3.13 mencionava mas NAO estao mais no deck:
- ❌ Insurrection (Nivel 4 no v3.13, ausente do DB)
- ❌ Surge to Victory (Nivel 4 no v3.13, ausente do DB)
- ❌ Wedding Ring (Nivel 3 no v3.13, ausente do DB)
- ❌ Flare of Duplication (Nivel 4 no v3.13, removida)
- ❌ Twinflame (Nivel 4 no v3.13, removida)
- ❌ Ashling, Flame Dancer (removida)
- ❌ Austere Command (removida)
- ❌ Demand Answers (removida)
- ❌ Thrill of Possibility (removida)
- ❌ Weathered Wayfarer (removida)

### Cartas NOVAS (nao mencionadas no v3.13):
- ✅ Dualcaster Mage (Nivel 3 — copy, stack interaction)
- ✅ Fellwar Stone (Nivel 3 — ramp rock)
- ✅ Flawless Maneuver (Nivel 3 — free fog massivo)
- ✅ Primal Amulet (Nivel 3 — engine que transforma em Wellspring)
- ✅ Valakut Awakening (Nivel 3 — draw_loot)
- ✅ 5 fetch lands (Arid Mesa, Bloodstained Mire, Flooded Strand, Scalding Tarn, Windswept Heath)
- ✅ 4 new duals/utility (Sacred Foundry, Inspiring Vantage, Clifftop Retreat, Sundown Pass, Ancient Tomb, Boseiju, Cavern of Souls, Kor Haven, Exotic Orchard, Dormant Volcano)

---

## Secao 6: RECOMENDACOES

### Gaps Detectados

| # | Gap | PG Baseline | Actual | Severidade | Acao |
|:-:|:-----|:-----------:|:------:|:----------:|:-----|
| 1 | **tutor** | 3.67 | 2 | 🟡 MODERADO | **Aquisicao: Idyllic Tutor ($15-20).** Unico gap > 1.0. |
| 2 | **Valakut duplicado** | — | 2 rows | 🟡 MODERADO | Corrigir DB: remover id=653 (front face duplicada). |
| 3 | **exile_value** | 3.67 | 2 | 🟡 MODERADO | Capstone + Dance cobrem. Monitorar. |
| 4 | **stack interaction** | N/A | 5/10 | 🟡 MODERADO | Flare/Twinflame cortadas. Se readquiridas, reavaliar. |
| 5 | **T3 nao medido** | — | ❓ | 🔴 ALTA | **Necessario executar Mulligan Tester** com novo deck (pos-C#17 manabase). |

### Aquisicoes Recomendadas

| # | Carta | CMC | Funcao | PG Role | Custo | Fecha Gap? |
|:-:|:------|:---:|:-------|:--------|:-----:|:-----------|
| 1 | **Idyllic Tutor** | 3 | Tutor de enchantment | tutor | $15-20 | **SIM — fecha tutor gap.** |
| 2 | **Flare of Duplication** | 3 | Free stack copy | big_spell_payoff | $2-3 | Parcial — combo Approach+Flare. |
| 3 | **Twinflame** | 2 | Creature copy + Surge | combo_piece | $2-3 | Parcial — combo Storm-Kiln. |
| 4 | **Skullclamp** | 1 | Draw engine | draw_value | $5-8 | Utilidade geral (draw ja ACIMA). |

---

## Secao 7: CHECKLIST p/ Evolution Oracle

| Check | Status | Nota |
|:------|:------:|:-----|
| 100 cartas? | ⚠️ | 100 no DB, 99 fisicas (Valakut duplicado). Corrigir. |
| Commander = 1? | ✅ | Lorehold |
| Lands = 35? | ✅ | 35 |
| Singleton? | ⚠️ | Valakut duplicado (MDFC front + full). Corrigir. |
| Motor 4/4? | ✅ | Treasure, Free Spell, Copy, Payoff — completo |
| Copy engines? | ✅ | 5 ativas (Lorehold, Double Vision, Bombardment, Archaic, Primal Amulet) + Dualcaster |
| Tutor PG gap? | 🔴 | 2 vs 3.67. Unico gap real. Aquisicao: Idyllic Tutor. |
| Double-nulls? | ⚠️ | 4 (Scroll Rack, Penance, Grand Abolisher, Taunt) |
| T3 Sem Play? | ❓ | **NAO MEDIDO.** Necessario Mulligan Tester com novo deck. |
| **Estrategia** | **BALANCED** | Deck saudavel. Aguardar T3 para confirmar. Nenhum swap necessario. |

---

## Secao 8: NOVIDADES v3.20

### O que mudou desde v3.19:
- **Nenhuma mudanca no deck.** Card hash identico (`30d00347...`).
- VALIDATOR_LOG.md e VALIDATOR_SUMMARY.md estavam STALE (v3.13 de 31/05). **Sincronizados para v3.20.**
- Documentado o gap entre v3.13 e estado real: 10 cartas OUT, 5+ nonland IN, manabase refeita.
- Valakut duplicado documentado como data issue com recomendacao de correcao.

### Confirmacoes:
- PG comparison identica a v3.19 — deck ACIMA do perfil em 11/14 roles.
- SYNERGY_MAP estavel (7.3/10 medio, mesmo de v3.19 com ajuste de -0.1 pela perda de Flare/Twinflame).
- Tutor gap (-1.7) permanece o unico gap real.
- Double-nulls estaveis em 4.
- T3 continua NAO MEDIDO — gap critico que o Mulligan Tester precisa preencher.

### O que NAO mudou:
- Motor continua 4/4.
- Copy engines: 5 + Dualcaster.
- Wincons: 5 (Approach, Akroma's, Worldfire, Apex, Storm Herd).
- Nivel 1 continua vazio (sem filler).
- Colecao permanece esgotada de CMC <= 3.

---

*Fim do VALIDATOR_LOG v3.20 — 2026-06-01T09:03:00+00:00*
*Proxima analise: v3.21 — re-confirmacao (salvo mudancas no deck ou apos Mulligan Tester)*
