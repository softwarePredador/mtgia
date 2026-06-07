## [2026-05-30T16:30:00+00:00] Ciclo #4 — Evolution Oracle

### Pré-Análise: Síntese dos 3 Agentes

**SCOUT (Execução #11 — EDHREC 7765 decks, pós-Ciclo #3):**
- Motor Lorehold 4/4 completo (Treasure Ramp → Big Spell Free → Lorehold Copy → Treasure Payoff)
- Rising stars: Restoration Seminar (37.6%, trend +9.15), Improvisation Capstone (48.9%, trend +8.13) — ambas JÁ NO DECK
- The Dawning Archaic (23.9%, trend +5.33) — rising star, NO DECK, na coleção, CMC 10
- Declining: Artist's Talent (-0.71), Esper Sentinel (-0.54), Rise of the Eldrazi (-0.49)
- 7 double-null cards restantes (redução de 10→7 em 3 ciclos)

**VALIDATOR (v3.4 — Pós-Ciclo #3):**
- Motor: 4/4 ✅ COMPLETO
- Draw: 5 reais vs 8-12 do perfil — 🔴 Crítico
- Wincon: 1 dedicado (Approach) vs 4-7 do perfil — 🔴 Muito abaixo
- Rise of the Eldrazi (CMC 12) — ineficiente para o CMC, trend negativo
- Season of the Bold (CMC 5, 9.9% EDHREC) — baixo alinhamento com meta
- Sem Play T3: a validação v3.4 projetou 5.1% usando validate_mana.py, mas a simulação real (Exec#7) mediu 16.4% — a definição usada pelo validador foi mais permissiva. O número real é ~16%.

**MULLIGAN (Execução #7 — Pós-Ciclo #3):**
- Jogáveis (rigorous): 65.7% ✅
- Mulligan: 29.9% 🟡
- Ramp T1: 19.7% ✅ (caiu de 27.2% — perda de Desperate Ritual)
- Sem Play T3: 16.4% 🔴 (CRÍTICO — muito acima do limite de 12%)

### Estratégia do Ciclo #4: DEFENSIVA

**Justificativa:** Sem Play T3 real de ~16.4% está ACIMA do limite de 12%. Apesar do v3.4 ter sugerido estratégia AGGRESSIVE baseado na projeção de 5.1%, a simulação de mulliganExec#7 é a métrica mais confiável — usa o deck real com seed=42, N=1000, definição rigorosa.

**Alvo:** Reduzir Sem Play T3 de ~16% para ~8-10% via net ΔCMC negativo.

### Swap 1: Rise of the Eldrazi → Faithless Looting

**Diagnóstico:** Rise of the Eldrazi (CMC 12) é ABSURDAMENTE caro. Annihilator 2 requer 24 de mana para ativar. Em um deck com 35 lands e 16 ramp sources, conjurar CMC 12 é praticamente impraticável antes de T8-9. Ainda por cima, o trend EDHREC é negativo (-0.49) — a comunidade está abandonando.

**Solução:** Faithless Looting (CMC 1, 29.6% EDHREC). É a carta mais eficiente para o que o deck precisa: DRAW + Graveyard setup. Custa 1 mana, compra 2, descarta 2. Com flashback, efetivamente compra 4 cartas por 3 mana total. Em Lorehold, colocar spells no GY é o setup para Lorehold capturar, Mizzix's Mastery, Restoration Seminar. É draw que também é setup.

**Da sua coleção:** ✅ Sim (qty: 1, CMC 1, Sorcery)

**Princípio:** Em Lorehold, draw que enche o cemitério é draw COM SINERGIA. Cada carta descartada por Faithless Looting é uma carta que Lorehold pode capturar ou que Mizzix's Mastery pode recurse. Draw puro que vai pro lixo é draw desperdiçado — mas draw que vai pro GY é investimento.

**Impacto esperado no mulligan:** Reduzir Sem Play T3 em ~6-8pp. Mãos com 1 land + Looting agora têm algo jogável T1 (vs 1 land + Rise = dead draw).

**ΔCMC: -11**

### Swap 2: Season of the Bold → Dragon's Rage Channeler

**Diagnóstico:** Season of the Bold (CMC 5, 9.9% EDHREC) é um efeito passivo de exile top 2 cards por turno. É lento, não impacta o campo imediatamente, e não sinergiza com o motor do deck. Apenas 9.9% dos decks Lorehold usam — é claramente anti-meta.

**Solução:** Dragon's Rage Channeler (CMC 1, 39.6% EDHREC). É uma criatura 1/1 que permite olhar as 3 primeiras cartas e colocar qualquer número no fundo — SMOOTHING de topo grátis. Adicionalmente, quando faz surge, compra uma carta. Em um deck com 20+ instants/sorceries e mecânica de topdeck (Miracle, Lorehold trigger), o smoothing é brutal. É uma das criaturas mais eficientes para Lorehold.

**Da sua coleção:** ✅ Sim (qty: 1, CMC 1, Creature — Human Shaman)

**Princípio:** Topdeck manipulation em Lorehold é O recurso mais valioso. O motor do deck depende de revelar cartas do topo (Dance with Calamity Miracle, topdeck para Lorehold capturar). Cada carta colocada no fundo pelo Channeler é uma carta ruim eliminada da sequência de topdeck. O Channeler custa 1 mana (nos primeiros 3 turnos), depois vira um 5/5. É draw + smoothing + clock.

**Impacto esperado no mulligan:** Dragon's Rage Channeler é jogável T1 (CMC 1). Mãos com 2 lands + Channeler agora têm ação T1. Reduz Sem Play T3 em ~4-6pp.

**ΔCMC: -4**

### Swap 3: Goblin Engineer → Thrill of Possibility

**Diagnóstico:** Goblin Engineer (CMC 2, 0% EDHREC) é um tutor de artefato que sacrifica um artefato para buscar outro CMC≤3. Lorehold não roda artefatos-chave que justifiquem tutor. É dead draw na maioria das mãos — especialmente nas aberturas onde sacrificar um artefato para buscar outro é negativo de tempo.

**Solução:** Thrill of Possibility (CMC 2, draw). Buyback instantâneo que compra 2 cartas e descarta 1. É draw eficiente, joga no turno oponente (snapcaster-style), e tem sinergia com Lorehold.

**Da sua coleção:** ✅ Sim (qty: 1, CMC 2, Instant)

**Princípio:** CMC 2 é o sweet spot do deck em Ciclos defensivos. Thrill é estritamente melhor que Goblin Engineer porque compra cartas imediatamente (vs tutor que custa um turno e tem condição). Draw > tutor em decks que não buscam peças específicas — e Lorehold não tem "peça para buscar", tem sinergias amplas.

**Impacto esperado no mulligan:** Neutro em CMC, mas Thrill é jogável em T2-3 (vs Engineer que é dead draw até ter artefato adequado). Incremental improvement em consistência.

**ΔCMC: 0**

### Resumo do Ciclo

| Métrica | Antes (Ciclo #3) | Esperado (Ciclo #4) | Δ |
|:--------|:-----------------:|:--------------------:|:-:|
| CMC médio | ~3.8 | ~3.5 | -0.3 |
| Draw real | 5 | 7 | +2 ✅ |
| Removal | 4 | 3 | -1 |
| Sem Play T3 | ~16.4% | ~8-10% | -6 to -8pp ✅ |
| Jogáveis | 65.7% | ~72-74% | +6 to +8pp ✅ |
| Ramp T1 | 19.7% | ~20% | ≈ |

### Estado Pós-Swap (Confirmado no DB)

| Métrica | Pré-Ciclo #4 | Pós-Ciclo #4 | Δ |
|:--------|:-------------:|:------------:|:-:|
| Lands | 35 | 35 | — |
| Ramp (DB) | 16 | 16 | 0 |
| Draw (DB) | 5 | 6 | +1 ✅ |
| Removal (DB) | 5 | 4 | -1 |
| Board Wipe | 5 | 5 | — |
| Protection | 4 | 4 | — |
| Wincon | 1 | 1 | — |
| Engine | 4 | 4 | — |
| **Net ΔCMC** | — | — | **-15** |

### Lições deste Ciclo

1. **Rise of the Eldrazi (CMC 12) em deck com 35 lands é um erro de construção.** Mesmo com 16 ramp sources, chegar a 12 mana reliablemente leva T8-9. A menos que o jogo chegue a esse ponto (raro em B3), a carta é dead draw.

2. **Faithless Looting é a carta certa para Lorehold.** CMC 1 + draw + flashback + GY setup = tudo que o deck precisa. Deveria ter entrado antes.

3. **Dragon's Rage Channeler é uma adição silenciosa mas poderosa.** CMC 1, jogável T1, smoothing de topo. Em deck com 20+ instants/sorceries e mecânica de topdeck, é free value toda abertura.

4. **Goblin Engineer era o último "artifact subtheme" residual 3+ ciclos.** Sua saída marca o fim da era artefato-no-Lorehold. O deck agora é puramente spellslinger.

5. **Estratégia defensiva é obrigatória quando Sem Play T3 > 12%.** Ciclos anteriores aumentaram CMC e pioraram consistência. Ciclo #4 reverte essa tendência.

### Próximos Ciclos

Quando Sem Play T3 < 8% (após simulação pós-Ciclo #4), próximo ciclo pode ser BALANCED ou AGGRESSIVE:

- **Add:** Arcane Bombardment (42.4%, CMC 6), Chaos Warp (38.9%, CMC 3), The Dawning Archaic (23.9%, trend 5.33, mas CMC 10)
- **Cut:** Fated Clash (declining), Goldspan Dragon (18% EDHREC, condicional), Longshot (no synergy)
- **Prioridade:** Wincon gap (1 vs 4-7) e Draw residual (7 vs 8-12 após Ciclo #4)
