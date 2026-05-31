# VALIDATOR SUMMARY — Lorehold Spellslinger

> **Ultima atualizacao:** 2026-05-31T19:10:00+00:00 (Evolution Oracle C#11 + v3.10)
> **Deck:** Pos-Ciclo #11 (0 swaps), 25 swaps totais, 100 cards, 86 rows, 35 lands, CMC medio 3.71
> **Pipelines ativos:** Scout (#17) + Validator (v3.10) + Mulligan (#11 concluida) + Evolution (#11 concluido)

---

## Estado do Deck: EXCELENTE — Motor 4/4, Copy 6, Nivel 1 VAZIO

### Ciclos de Swap Completos (25 swaps em 10 ciclos)

| Ciclo | # | Saiu | Entra |
|:------:|:-:|:-----|:-------|
| #1 | 1 | Furygale Flocking | Esper Sentinel |
| #1 | 2 | Jokulhaups | Gamble |
| #1 | 3 | Karoo | Plains |
| #2 | 1 | Deflecting Palm | Big Score |
| #2 | 2 | Hellkite Tyrant | Dance with Calamity |
| #2 | 3 | Mother of Runes | The One Ring |
| #3 | 1 | Ancient Copper Dragon | Storm-Kiln Artist |
| #3 | 2 | Desperate Ritual | Boros Signet |
| #3 | 3 | Sunbird's Invocation | Improvisation Capstone |
| #3 | 4 | Victory Chimes | Generous Gift |
| #3 | 5 | Orim's Chant | Blasphemous Act |
| #4 | 1 | Rise of the Eldrazi | Faithless Looting |
| #4 | 2 | Season of the Bold | Dragon's Rage Channeler |
| #4 | 3 | Goblin Engineer | Thrill of Possibility |
| #5 | 1 | Artist's Talent | Chaos Warp |
| #5 | 2 | Oswald Fiddlebender | The Dawning Archaic |
| #5 | 3 | Perch Protection | Arcane Bombardment |
| #6 | 1 | Goldspan Dragon | Wedding Ring |
| #6 | 2 | Seething Song | Abrade |
| #7 | 1 | Galadriel's Dismissal | Victory Chimes |
| #9 | 1 | Pearl Medallion | Akroma's Will |
| #10 | 1 | Ruby Medallion | Twinflame |
| #10 | 2 | Galvanoth | Flare of Duplication |

---

## Metricas Atuais (post-C#10) vs Perfil EDHREC

| Metrica | Deck | Perfil | Status |
|:--------|:----:|:------:|:------:|
| Lands | 35 | 36-38 | OK (-1, MDFCs compensam) |
| Ramp | 14 | 10-13 | +1 (treasure-heavy) |
| Draw (real) | 7 | 8-12 | -1 (estrutural Boros) |
| Removal | 6 | 4-6 | No limite |
| Board Wipe | 5 | 3-5 | No limite |
| Protection | 3 | 3-4 | OK (+3 stack: Swat, Squelcher, Abolisher) |
| Recursion | 4 | 2-5 | No range |
| Wincon (dedicado) | 2 | 4-7 | Funcionalmente 8+ paths |
| Engine/Big Spell | 9 | 5-8 | Copy 6 + Motor 4/4 |
| Tutor | 2 | -- | Enlightened + Gamble |
| CMC medio | **3.71** | ~4.1 | OK (-0.40 do baseline) |

---

## Mulligan (pos-C#9 = ultima simulacao; #11 pendente)

| Metrica | Execucao #10 (pos-C#9) | Pos-C#10 (est.) | Target |
|:--------|:----------------------:|:---------------:|:------:|
| Jogaveis | 46.3% | ~48% | -- |
| Mulligan | 49.3% | ~47% | -- |
| Ramp T1 (estrito) | 20.1% | ~20% | -- |
| **Sem Play T3** | **13.3%** | **~13%** | **< 12%** |

> ⚠️ O T3=3.7% reportado em ciclos anteriores era a **taxa de free mulligan** (0 ou 7 lands),
> NAO o Sem Play T3 correto. Correcao aplicada nos v3.9/v3.10.
> Ciclos #7/#8/#9 usaram T3 errado para escolher AGGRESSIVE (devia ser DEFENSIVE).
> **Ciclo #10 foi o PRIMEIRO com T3 correto (16.9%) → DEFENSIVE.**

**Trajetoria T3:** C#5(15.3%) → C#6(-2CMC) → C#7(+2CMC) → C#8(0CMC) → C#9(+2CMC) → Exec#10(16.9%) → C#10(-2CMC) → Exec#11(13.3%)
**Net DCMC desde C#5:** +2 (AGGRESSIVE #7/#8/#9 causou inchaco). **Ciclo #11: 0 swaps.** Colecao esgotada.

---

## Motor: 4/4 COMPLETO

1. ✅ Treasure Ramp — Big Score, Brass's Bounty, Hit the Mother Lode
2. ✅ Free Big Spell — Dance with Calamity, Improvisation Capstone, Dawning Archaic
3. ✅ Lorehold Copy — Commander ability
4. ✅ Treasure Payoff — Storm-Kiln Artist

## Copy Engines: 6 ativas 🆕

1. Lorehold (commander)
2. Double Vision (46.6%)
3. Arcane Bombardment (42.5%)
4. The Dawning Archaic (24.0%, rising +5.31)
5. **Flare of Duplication** 🆕 (instant copy, Approach+Flare = win 1 turno)
6. **Twinflame** 🆕 (creature copy, Surge chain)

---

## SYNERGY_MAP (v3.10 — 7 Eixos)

| Eixo | Score | Mudanca (vs v3.9) | Nota |
|:-----|:-----:|:-----------------:|:-----|
| Token+Pump | 8/10 | -- | Akroma's Will + Boros Charm + Twinflame chain |
| Wipes+Protection | 8/10 | -- | 5 wipes / 4 protecoes. Balanceado. |
| Recursion | 8/10 | -- | Mizzix + Bombardment + Surge + Seminar |
| Mana Explosiva | 7/10 | -- | 6+ treasure generators. Sem fast mana. |
| **Combo Pieces** | **9/10** | **+1** | **Approach+Flare = win MESMO turno** |
| **Stack Interaction** | **7/10** | **+1** | Flare responde a counterspell |
| **Graveyard Resilience** | **6/10** | **+1** | Plano B (Approach+Flare) dispensa grave |

---

## Win Conditions (8+ paths, 2 novos no C#10)

- **Approach + Flare de Duplication** 🆕 — 7 mana + criatura vermelha = vitoria NO MESMO TURNO
- **Twinflame + Surge + Approach** 🆕 — creature copy dobra copias de Approach
- Approach of the Second Sun (hardcast ou com Sensei's Top)
- Insurrection (rouba board + haste)
- Storm Herd + Akroma's Will (overkill: 20-40 tokens flying indestructible)
- Rite of the Dragoncaller + Akroma's Will (3-5 dragons letais)
- Surge to Victory + Approach (cada criatura = 1 copia)
- Mizzix's Mastery overload (todo grave gratis)
- Arcane Bombardment chain + Double Vision (3-4 spells/turno)

---

## Double-Null Cards: 4 (eram 10 no baseline)

| Carta | CMC | EDHREC | Trend | Risco | Acao |
|:------|:---:|:------:|:-----:|:-----:|:-----|
| Scroll Rack | 2 | 59.7% | +0.15 | 🔴 | NEVER CUT — core engine |
| Penance | 3 | 41.8% | +1.15 | 🔴 | NEVER CUT — miracle enabler |
| Taunt from the Rampart | 5 | 35.2% | +0.10 | 🟢 | KEEP — util em multiplayer |
| Grand Abolisher | 2 | 11.7% | -0.27 | 🟡 | KEEP — unica protecao proativa anti-counterspell |

**Ruby Medallion removido no C#10** (declinio -0.37, 3+ ciclos). Nivel 1 agora VAZIO.

---

## GAPS Atuais

| # | Gap | Severidade | Solucao |
|:-:|:-----|:----------:|:--------|
| 1 | **Sem Play T3 ~15%** (>12%) | 🔴 DEFENSIVE | Fast mana (Chrome Mox, Mana Vault) — requer AQUISICAO |
| 2 | Colecao esgotada de CMC <= 2 | 🔴 | Aquisicao de Skullclamp ($5-8), Chrome Mox ($60-80) |
| 3 | Draw = 7 (vs perfil 8-12) | 🟡 | Skullclamp ($5-8) |
| 4 | Fated Clash 15.6% EDHREC declinio | 🟡 | Sem substituto viavel na colecao |

---

## Estrategia para Ciclo #11 — EXECUTADO (0 SWAPS) e Ciclo #12

**Ciclo #11: 0 SWAPS aplicados.** 38 cartas CMC<=2 analisadas, nenhuma atinge Necessidade >= 3.
Mulligan Execucao #11 confirmou T3 = 13.3% (-3.6pp vs C#9, -1.9pp vs projecao).
Deck saudavel, Nivel 1 vazio, colecao esgotada.

**Ciclo #12 previsto: 0 SWAPS** (a menos que Skullclamp seja adquirido).
Se Skullclamp adquirido: Fated Clash (CMC 5) -> Skullclamp (CMC 1), net DCMC = -4, T3 projetado ~10%.

**Recomendacoes de Aquisicao (sem mudanca — colecao ainda esgotada):**
1. **Skullclamp (CMC 1, draw engine, $5-8) — PRIORIDADE ABSOLUTA.** Equipa em Spirit 3/2 = draw 2. Impacto T3: -3pp a -5pp.
2. Chrome Mox (CMC 0, fast mana, $60-80) — T3: -2pp a -3pp.
3. Mana Vault (CMC 1, fast mana, $40-60) — T3: -1.5pp a -2pp.
4. Underworld Breach (CMC 2, recursion, $15-20) — Yawgmoth's Will Boros.

---

*Relatorio atualizado por Evolution Oracle C#11 em 2026-05-31T19:10:00+00:00*
*Proximo: Ciclo #12 — verificar se Skullclamp foi adquirido. Se nao, 0 swaps novamente.*
