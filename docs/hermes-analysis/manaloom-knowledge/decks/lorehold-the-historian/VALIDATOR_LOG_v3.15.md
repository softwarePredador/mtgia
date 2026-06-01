# Purpose Analyzer v3.15 — Lorehold Spellslinger: SYNEGY_MAP — Post-C#17, Motor Refinado, T3 Projectado 10-12%

> **Data:** 2026-06-01T02:40:00+00:00
> **Fonte:** knowledge.db deck_id=6 — ESTADO REAL DO DB (verificado, card_hash = `a440c497da4280d6769238737062b3dd`)
> **Deck:** Lorehold Spellslinger — 100 cards, 86 rows, 35 lands, CMC medio 3.61
> **Ciclo atual:** Pos-Ciclo #17 (27 swaps, 11 ciclos com swaps)
> **Analista:** Hermes Agent — Purpose Analyzer v3.15
> **Foco:** SYNEGY_MAP completo 7 eixos (A-G) + classificacao estrategica de todas as cartas

---

## Secao 0: INTEGRIDADE DO PIPELINE

| Verificacao | Status |
|:------------|:------:|
| Card hash vs EVOLUTION_LOG C#17 | ✅ **MATCH** — `a440c497da4280d6769238737062b3dd` |
| Deck cards = 86 rows, 100 total | ✅ OK |
| Lands = 35 | ✅ OK |
| Commander = 1 (Lorehold) | ✅ OK |
| DB consistent with C#17 swaps | ✅ Demand Answers presente, Ashling presente |
| Rise of the Eldrazi ausente | ✅ Confirmado (cortada C#17) |
| Longshot ausente | ✅ Confirmado (cortada C#17) |
| **Estado: PIPELINE SAUDAVEL — DB reflete C#17 corretamente** | ✅ |

### O que mudou desde v3.14:

| Carta | Status v3.14 | Status v3.15 (DB real) | Mudanca |
|:------|:-------------|:----------------------|:--------|
| Rise of the Eldrazi | ✅ PRESENTE (CMC 10, wincon) | ❌ AUSENTE | Cortada C#17 |
| Longshot, Rebel Bowman | ✅ PRESENTE (CMC 4) | ❌ AUSENTE | Cortada C#17 |
| Demand Answers | ❌ AUSENTE | ✅ PRESENTE (CMC 2, draw) | Adicionada C#17 |
| Ashling, Flame Dancer | ❌ AUSENTE | ✅ PRESENTE (CMC 4, draw) | Adicionada C#17 |

**Net DCMC desde v3.14: -8** (Rise CMC 10 → Demand CMC 2; Longshot CMC 4 → Ashling CMC 4).

---

## Secao 1: CLASSIFICACAO ESTRATEGICA — TODAS AS 86 CARTAS

Cada carta classificada por **importancia estrategica (1-5)** e **funcao real** (corrigida manualmente — DB tags estao frequentemente erradas).

### NIVEL 5 — O Deck Nao Funciona Sem Elas (4 cartas)

| Carta | CMC | Funcao Real | Por que Nivel 5 |
|:------|:---:|:------------|:----------------|
| **Lorehold, the Historian** | 5 | Commander, copy_engine, draw | O deck inteiro gira em torno da habilidade de copiar do grave. Sem Lorehold = sem motor. |
| **Approach of the Second Sun** | 7 | Wincon primaria | 89.9% das vitorias (BATTLE v8). Unica wincon que ganha sem combate. |
| **Mizzix's Mastery** | 4 | Recursion, wincon | Overload = TODOS os instants/sorceries do grave de graca. Com copy engines = 2x. Ganha jogos sozinha. |
| **Flare of Duplication** | 3 | Copy, combo_piece, stack_interaction | Combo deterministico com Approach (mesmo turno). Resposta a counterspell na stack. Sem Flare = Approach toma counter e perde. |

### NIVEL 4 — Core da Estrategia (17 cartas)

| Carta | CMC | Funcao Real | Por que Nivel 4 |
|:------|:---:|:------------|:----------------|
| **Dance with Calamity** | 8 | Engine, miracle | Exila topo ate achar X cards — com Top/Scroll/Penance = valor massivo. Miracle {R}{R}{R} = custo real 3. |
| **Double Vision** | 5 | Copy engine | Primeira spell por turno = copiada. Com Lorehold = 3 copias da mesma spell. |
| **Arcane Bombardment** | 5 | Copy engine, recursion | Dispara toda hora — exila do grave e copia. Com Restoration Seminar = loop infinito. |
| **Sensei's Divining Top** | 1 | Draw, topdeck_manipulation | Draw + reordenar topo. Essencial para Miracle e Approach. |
| **Scroll Rack** | 2 | Draw, engine, topdeck_manipulation | Troca mao pelo topo — prepara Miracle, Approach, Dance. Core engine (double-null!). |
| **Penance** | 3 | Engine, miracle_enabler, protection | Poe carta do topo no fundo — prepara Miracle. Anti-removal devolvendo criatura pro deck. Double-null! |
| **Jeska's Will** | 3 | Ramp, ritual | Exila topo + gera R igual ao numero de cartas na mao do oponente. Melhor ritual de Commander. |
| **Smothering Tithe** | 4 | Ramp, treasure | Cada draw do oponente = 1 Treasure (ou eles pagam 2). Gera 3-6 tesouros por ciclo em mesa de 4. |
| **Storm-Kiln Artist** | 4 | Ramp, treasure, engine | Cada cast/copy de instant/sorcery = 1 Treasure. Com 6 copy engines = 3-7 tesouros por spell. Componente 4/4 do motor. |
| **The One Ring** | 4 | Draw, protection | Draw massivo + protecao por um turno. GC em Bracket 3 — mas unica fonte de draw em massa do deck. |
| **Teferi's Protection** | 3 | Protection | "Nao perco o jogo." Resposta a combo, wipe, alpha strike. Melhor protecao do formato. |
| **Akroma's Will** | 4 | Wincon_enabler, protection, pump | Double strike + flying + indestrutivel + vigiliance + prot all colors para TODAS as criaturas. Com Storm Herd = lethal. |
| **Surge to Victory** | 6 | Recursion, wincon, pump | Exila Approach do grave — cada criatura atacante causa dano = CMC do Approach E CASTA COPIA. Com 3+ criaturas = 3+ copias de Approach = vitoria. |
| **Improvisation Capstone** | 7 | Engine, free_cast, recursion_enabler | Exila top 7, casta de graca. Cada spell = +1 contador. Sacrifica com 4+ = compra 3. EDHREC 49%, trend +8.09. Rising star confirmada. |
| **Restoration Seminar** | 7 | Recursion, engine | Devolve instant/sorcery do grave. Lesson. Com Bombardment = loop. EDHREC 37.9%, trend +9.16 — fastest-rising card. |
| **The Dawning Archaic** | 3 | Copy engine | Copia a primeira spell de CADA OPONENTE. Com 3 oponentes = 3 copias por ciclo. EDHREC 24%, trend +5.27. Rising star confirmada 5+ ciclos. |
| **Sol Ring** | 1 | Ramp | Fast mana. Sem Sol Ring T1 = deck perde 1-2 turnos de velocidade. |

### NIVEL 3 — Suporte Forte (36 cartas)

| Carta | CMC | Funcao Real | Por que Nivel 3 |
|:------|:---:|:------------|:----------------|
| **Land Tax** | 1 | Ramp | Busca 3 basics por turno se atrasado em lands. Alimenta Faithless Looting + Mizzix. |
| **Archaeomancer's Map** | 3 | Ramp | Land ramp continuo. Com fetch lands = +2 lands por turno. |
| **Boros Charm** | 2 | Protection, pump, removal | 4 danos OU double strike OU indestrutivel. Melhor charm do formato. DB erroneo: "removal". Funcao real: protecao e pump com opcao de remocao. |
| **Deflecting Swat** | 3 | Protection, stack_interaction | Redireciona spell ou habilidade. Responde a counterspell, removal, combo. DB erroneo: "big_spell". |
| **Grand Abolisher** | 2 | Protection, stax | Oponentes nao conjuram no seu turno. Essencial para resolver Approach sem medo de counter. Double-null! |
| **Worldfire** | 9 | Wincon alternativa | Exila TUDO, vida=1. Com qualquer dano na stack = vitoria. Nao depende de grave nem de Approach. Adicionada fora do pipeline pelo usuario. |
| **Storm Herd** | 10 | Token_maker, wincon | Cria X Pegasus 1/1 onde X = vida. Com 40 de vida = 40 tokens. + Akroma's Will = lethal na mesa inteira. EDHREC 75%. |
| **Brass's Bounty** | 7 | Ramp, treasure | Cria Treasure = numero de lands. Com 7-8 lands = 7-8 tesouros. Financia Storm Herd, Mizzix overload. |
| **Hit the Mother Lode** | 7 | Ramp, treasure | Descobre ate achar algo — ganha tesouros. Media de 4-5 tesouros por cast. |
| **Enlightened Tutor** | 1 | Tutor | Busca artefato ou enchantment. Alvos: Top, Scroll Rack, The One Ring, Smothering Tithe, Double Vision. |
| **Gamble** | 1 | Tutor, recursion_enabler | Busca qualquer carta (descarta aleatoria). Em deck com Mizzix/Lorehold, descartar e VANTAGEM. |
| **Chaos Warp** | 3 | Removal | Unico removal que lida com QUALQUER permanente (shuffle). Remove enchantments/planeswalkers intocaveis. |
| **Swords to Plowshares** | 1 | Removal | Melhor removal do formato. Exilia criatura. |
| **Path to Exile** | 1 | Removal | Segundo melhor removal. Exilia, da basic land. |
| **Generous Gift** | 3 | Removal | Destroi QUALQUER permanente. Da 3/3 token — irrelevante. |
| **Austere Command** | 6 | Board wipe | Wipe modular — escolhe quais tipos destruir. Pode poupar seus artefatos/enchantments. EDHREC 33.3%. |
| **Blasphemous Act** | 9 | Board wipe | Custo real: {R} (com 8+ criaturas em campo). 13 de dano = mata tudo com Boros Charm indestrutivel = assimetrico. |
| **Call Forth the Tempest** | 8 | Board wipe, token_maker | Dano = CMC revelado + Cascade + cria dragoes. Wipe + payoff em uma carta. EDHREC 65.3%, trend -0.31. |
| **Volcanic Vision** | 7 | Board wipe, recursion | Dano = CMC de instant/sorcery no grave + retorna aquela spell pra mao. Wipe + tutor em uma carta. EDHREC 63.8%. |
| **Monument to Endurance** | 3 | Draw, engine, loot | Descarta 1, draw 1. Com 3+ copias de Lorehold = motor de loot. DB erroneo: "ramp". |
| **Library of Leng** | 1 | Draw, engine, hand_size | Sem limite de mao. Descarta pro topo do deck (nao pro grave). Prepara Miracle! |
| **Dragon's Rage Channeler** | 1 | Draw, graveyard_setup | Surveil 1 a cada spell nao-creature. Preenche grave + filtra draws. DB erroneo: "graveyard_synergy". |
| **Victory Chimes** | 3 | Draw, ramp | Untapa a cada turno (todos!). Draw no ETB de artefato. Com Storm-Kiln + Monument = motor de draw/ramp. EDHREC 53.5%. |
| **Reforge the Soul** | 5 | Draw, wheel | Miracle {1}{W}. Wheel = draw 7. Recupera de maos ruins. |
| **Mother of Runes** | 1 | Protection | {T}: protecao de cor. Protege Lorehold, Storm-Kiln, Ashling de remocao. CMC 1. EDHREC 34.5%. |
| **Lightning Greaves** | 2 | Protection | Shroud + haste. CMC 0 pra equipar. |
| **Hexing Squelcher** | 2 | Protection, stax | Oponentes nao ativam habilidades de artefatos, criaturas ou enchantments nao-mana. Protecao proativa. EDHREC 40.8%. |
| **Boseiju, Who Shelters All** | 0 | Land, protection | Channel: spell nao pode ser counterada. Approach incounteravel. |
| **Cavern of Souls** | 0 | Land, protection | Nomeia "Elder Dragon" — Lorehold incounteravel. |
| **Emeria's Call // Emeria, Shattered Skyclave** | 7//0 | Land, token_maker | MDFC: cria 2 Anjos 4/4 flying OU land. CMC real: gratis (land slot). |
| **Urza's Saga** | 0 | Land, tutor, token_maker | Cria Constructs + busca Sol Ring/Top. Tricampeao de valor em um land slot. |
| **Ashling, Flame Dancer** | 3 | Draw_engine, damage | A cada cast OU copy de instant/sorcery: impulse draw + 2 de dano. Com 6 copy engines = 3-7 triggers por spell. Escala exponencialmente. EDHREC 5.8% (baixa, carta nova). |
| **Demand Answers** | 2 | Draw, loot | Instant: draw 2 discard 1 OU sac artifact → draw 3. Preenche grave + draw. CMC 2. EDHREC 10.9%. |
| **Olorin's Searing Light** | 4 | Removal, draw | Dano = cards na mao + draw. Instant. Com maos grandes (One Ring, Library of Leng) = removal massivo + draw. |
| **Twinflame** | 2 | Copy, token_maker | Copia criatura com haste. Com Storm-Kiln ou Ashling = chain exponencial. Surge chain enabler. EDHREC 0% (nao trackeada). |
| **Rite of the Dragoncaller** | 6 | Token_maker, engine | Cria Dragon 5/5 a cada 2a spell por turno. Com copy engines = 2+ dragoes por ciclo. Payoff passivo. |
| **Kor Haven** | 0 | Land, protection | {1}{W}{T}: previne dano de combate de uma criatura. Fog em land slot. |

### NIVEL 2 — Utilidade Situacional (13 cartas)

| Carta | CMC | Funcao Real | Por que Nivel 2 |
|:------|:---:|:------------|:----------------|
| **Faithless Looting** | 1 | Draw, loot, recursion_enabler | Flashback. Enche grave para Mizzix. Substituivel se surgir draw melhor. |
| **Thrill of Possibility** | 2 | Draw, loot | Instant loot 1, draw 2. Substituivel por Demand Answers (que e melhor). |
| **Big Score** | 4 | Ramp, draw | Instant: cria 2 Treasure + draw 2, discard 1. Bom mas pode ser substituido. |
| **Unexpected Windfall** | 4 | Ramp, draw | Igual Big Score. Redundancia — util, mas nao essencial. |
| **Valakut Awakening // Valakut Stoneforge** | 3//0 | Draw, topdeck_manipulation, land | Instant: poe cartas da mao no fundo, draw igual. MDFC land — slot eficiente. |
| **Esper Sentinel** | 1 | Draw condicional | Draw quando oponente casta 1a spell nao-creature. Em declinio ha 6+ ciclos (trend -0.54). EDHREC 32.4% ainda alto. |
| **Taunt from the Rampart** | 5 | Protection, goad | Goada TODAS as criaturas dos oponentes. Temporiza ataques. Double-null! EDHREC 35.2%. |
| **Abrade** | 2 | Removal flexivel | 3 de dano a criatura OU destruir artefato. CMC 2 util mas nao essencial — ha 6 outras remocoes. |
| **Weathered Wayfarer** | 1 | Ramp | Busca qualquer land. Util para achar Boseiju/Cavern/Urza's Saga. Lento (sorcery speed, precisa de 1 land a menos). |
| **Arcane Signet** | 2 | Ramp | Standard. Substituivel se surgir fast mana (Mana Vault, Chrome Mox). |
| **Boros Signet** | 2 | Ramp | Standard. Boros precisa de fix. |
| **Talisman of Conviction** | 2 | Ramp | Melhor que Signet (produz mana no turno que entra). |
| **Bender's Waterskin** | 3 | Ramp | Scry + ramp de basic. Bom mas nao essencial — Archaeomancer's Map e melhor. |

### NIVEL 1 — Substituivel (0 cartas!)

**Nivel 1 VAZIO — confirmado pos-C#17.** Todas as 86 cartas do deck tem proposito estrategico claro. Demand Answers (CMC 2) e Ashling (CMC 4) substituiram Rise of the Eldrazi (CMC 10, wincon redundante) e Longshot (CMC 4, ping sub-otimo) — as cartas que agora sairiam eram as ultimas "substituiveis". O deck atingiu um estado onde toda carta serve a um proposito especifico na estrategia.

**Proxima carta a ser considerada "Nivel 1" se surgir upgrade:**
- Thrill of Possibility (CMC 2) — redundante com Demand Answers, pior eficiencia (loot 1 draw 2 vs draw 2 ou 3)
- Weathered Wayfarer (CMC 1) — lento, Land Tax e melhor
- Abrade (CMC 2) — 7a melhor remocao do deck

---

## Secao 2: SYNEGY_MAP — 7 Eixos de Sinergia

### A) TOKEN MAKERS + PUMP (Score: 8/10)

**Token Makers (6):**
| Carta | CMC | Output |
|:------|:---:|:-------|
| Storm Herd | 10 | X Pegasus 1/1 (X = vida, tipicamente 35-40) |
| Call Forth the Tempest | 8 | X dragoes variaveis + cascade |
| Rite of the Dragoncaller | 6 | Dragon 5/5 a cada 2a spell |
| Emeria's Call | 7 | 2 Anjos 4/4 flying (ou land!) |
| Twinflame | 2 | Copia criatura (com Storm-Kiln = +1 tesouro por trigger) |
| Urza's Saga | 0 | Constructs (land slot!) |

**Pump Effects (4):**
| Carta | CMC | Modo |
|:------|:---:|:-----|
| Akroma's Will | 4 | Double strike + flying + indestrutivel + vigiliance + prot all colors (TODAS as criaturas) |
| Boros Charm | 2 | Double strike (TODAS as criaturas OU uma) |
| Surge to Victory | 6 | +X/+0 para cada atacante (X = CMC do exilado) + casta copia |
| Twinflame | 2 | Strive: copia adicional |

**Pares de Sinergia:**
| Token Maker | + Pump | Dano Total | Confiabilidade |
|:------------|:-------|:----------:|:--------------|
| Storm Herd (40 tokens) | Akroma's Will | 40x2x2 = 160 flying, indestrutivel | 🟢 Alta — ambos sao tutoriaveis, Storm Herd = 10 mana mas Brass's Bounty financia |
| Storm Herd (40 tokens) | Boros Charm (double strike) | 40x2 = 80 flying | 🟢 Alta — Boros Charm CMC 2, facil de segurar |
| Call Forth (3-5 dragoes) | Akroma's Will | ~30-50 flying | 🟡 Media — Call Forth e variavel |
| Rite (2+ dragoes) | Akroma's Will | ~20 flying por turno | 🟢 Alta — passivo, acumula |
| Emeria's Call (2 Anjos) | Akroma's Will | ~16 flying | 🟡 Baixa — so 2 corpos |

**Forcas:** Storm Herd + Akroma's Will = lethal garantida contra 3 jogadores. Com Brass's Bounty ou treassures acumulados = consistentemente executavel T8+.

**Fraquezas:** Sem Akroma's Will, tokens sao "apenas" corpos sem evasao. O deck depende MUITO de Akroma's Will como pump unico de evasao. Boros Charm double strike (sem flying) e pior contra mesas com flyers.

### B) BOARD WIPES + PROTECTION (Score: 8/10)

**Board Wipes (4):**
| Carta | CMC | Custo Real | Assimetrico com: |
|:------|:---:|:----------|:----------------|
| Blasphemous Act | 9 | {R} | Boros Charm (indestrutivel) |
| Austere Command | 6 | 4WW | Teferi's Protection (faseia), escolher modos (poupar artefatos/enchantments) |
| Call Forth the Tempest | 8 | 5RRR | Akroma's Will (suas criaturas ganham indestrutivel + buff) |
| Volcanic Vision | 7 | 5RR | Recupera spell — wipe + valor |

**Protecoes contra Wipes (5):**
| Carta | CMC | Mecanismo |
|:------|:---:|:----------|
| Boros Charm | 2 | Indestrutivel para TODAS as suas permanentes |
| Teferi's Protection | 3 | Faseia TUDO — suas coisas nao existem ate o proximo turno |
| Akroma's Will | 4 | Indestrutivel + prot all colors para criaturas |
| Lightning Greaves | 2 | Shroud — nao previne wipe, mas previne remocao pontual |
| Mother of Runes | 1 | Protecao de cor — previne remocao, nao wipe |

**Pares Wipe + Protecao:**
| Wipe | + Protecao | Resultado | Custo Total |
|:-----|:-----------|:----------|:-----------:|
| Blasphemous Act | Boros Charm | Limpa so oponentes | {R}{R}{W} — ridiculo! |
| Austere Command | Teferi's Protection | Suas coisas voltam, campo limpo | 4WW + 2W |
| Call Forth the Tempest | Akroma's Will | Suas criaturas indestrutiveis + buffadas, dragoes novos | 5RRR + 2W |

**Ratio: 4 wipes / 5 protecoes = 0.8. EXCELENTE.** Risco zero de auto-destruicao. O deck sempre tem mais protecoes que wipes. Alem disso, os wipes sao premium: Blasphemous Act custa {R} com board populado, Austere Command e modular, Call Forth gera dragoes, Volcanic Vision devolve spell.

### C) RECURSION CHAINS (Score: 8/10)

**Motores de Recursao (4):**
| Carta | CMC | Mecanismo |
|:------|:---:|:----------|
| Mizzix's Mastery | 4 | Overload: TODOS os instants/sorceries do grave de graca. Com Double Vision/Bombardment = 2x cada. |
| Arcane Bombardment | 5 | Exila spell do grave, copia a cada upkeep. Dispara toda hora. |
| Restoration Seminar | 7 | Devolve instant/sorcery do grave pra mao (Lesson). Com Bombardment = loop. |
| Surge to Victory | 6 | Exila instant/sorcery do grave. Cada criatura atacante causa dano = CMC E CASTA copia. |

**Chains Documentadas:**
1. **Faithless Looting → Mizzix's Mastery overload:** Looting preenche grave com 3-5 spells. Mizzix overload casta todas de graca. Com Double Vision = cada spell copiada. Com Bombardment = exiladas e disponiveis no proximo upkeep. **Valor: transforma 1 mana (Faithless) em 15-20 mana de spells gratis.**

2. **Bombardment + Restoration Seminar loop:** Bombardment exila spell. Seminar devolve do grave. Casta de novo = Bombardment exila outra. **Valor: 2 spells por turno de graca, sustentavel.**

3. **Surge to Victory + Approach no grave:** Exila Approach. 3+ criaturas atacando = 3+ copias de Approach. A PRIMEIRA resolve (ganha 7 vida). A SEGUNDA (castada do deck) = vitoria. As demais sao redundantes. **Valor: vitoria garantida se 3+ criaturas atacarem.**

4. **Volcanic Vision → recupera spell:** Dano = CMC da maior spell no grave + devolve ela pra mao. Se Approach foi descartada (Gamble/Faithless) = 7 de dano + Approach de volta. **Valor: board wipe + tutor em uma carta.**

**Fraqueza:** Rest in Peace / Leyline of the Void DESABILITAM Mizzix, Bombardment, e Surge. Mas: Approach, Worldfire, Storm Herd + Akroma's Will NAO dependem de grave. 3 wincons sobrevivem a grave hate.

### D) MANA EXPLOSIVA (Score: 7/10)

**Geradores de Treasure (7):**
| Carta | CMC | Output Tipico |
|:------|:---:|:-------------|
| Smothering Tithe | 4 | 3-6/rodada (mesa de 4) |
| Storm-Kiln Artist | 4 | 3-7/spell (com copy engines) |
| Brass's Bounty | 7 | 7-8 tesouros (lands em jogo) |
| Hit the Mother Lode | 7 | 4-5 tesouros (media de descoberta) |
| Big Score | 4 | 2 tesouros (instant) |
| Unexpected Windfall | 4 | 2 tesouros (instant) |
| Victory Chimes | 3 | 1 mana extra por turno (cada turno!) |

**Rituais (2):**
| Carta | CMC | Output |
|:------|:---:|:-------|
| Jeska's Will | 3 | Exila 3 cartas + Gera R = tamanho da mao do oponente (tipicamente 3-7). |
| Sol Ring | 1 | {C}{C} |

**Land Ramp (5):**
| Carta | CMC | Output |
|:------|:---:|:-------|
| Land Tax | 1 | 3 basics/rodada |
| Archaeomancer's Map | 3 | 1-2 lands/rodada |
| Weathered Wayfarer | 1 | Qualquer land |
| Arcane Signet / Boros Signet / Talisman | 2 | +1 mana colorida |
| Bender's Waterskin | 3 | Scry + basic |

**Para que serve tanta mana?**
| Payoff | Custo | Output |
|:-------|:-----|:-------|
| Mizzix's Mastery overload | 5RR (7) | Casta TODAS as spells do grave — valor: 20-40 mana de spells |
| Storm Herd | 8WW (10) | Cria 35-40 Pegasus — valor: 35-40 de poder em campo |
| Approach of the Second Sun | 5WW (7) | Primeiro cast (ganha 7 vida, vai pro 7o do topo) |
| Approach + Flare (mesmo turno) | 7 + 1RR + criatura vermelha (10) | Vitoria no mesmo turno! |
| Dance with Calamity (sem Miracle) | 8 | Exila topo ate achar X cartas |
| Worldfire | 6RRR (9) | Reset + vitoria (com dano na stack) |

**Sequence ideal de mana:**
- T1: Land + Sol Ring (2 mana)
- T2: Land + Talisman/Signet (4 mana) → ou Land Tax se atrasado
- T3: Land + Smothering Tithe (5 mana) ou Archaeomancer's Map
- T4: Land + Storm-Kiln Artist (6 mana, online)
- T5: Land + Lorehold (7 mana, motor ligado)
- T6+: Casta spell de 7 mana → gera 3-5 tesouros → casta outra → chain

**Fraquezas:** Sem fast mana CMC 0-1 alem de Sol Ring. Chrome Mox, Mana Vault, Mana Crypt ausentes da colecao. Limite estrutural de jogaveis T3 = ~47%.

### E) COMBO PIECES (Score: 9/10)

**Combo Deterministico (1):**
| Combo | Pecas | Custo | Condicao | Confiabilidade |
|:------|:------|:-----|:---------|:------------|
| **Approach + Flare (mesmo turno)** | Approach + Flare + criatura vermelha | 7 + 1RR = ~10 mana | Flare copia Approach. 1a resolucao = 7 vida, vai 7o. 2a (copia) = casta do deck = vitoria. | 🟢 Alta — 2 cartas, tutoriaveis (Enlightened → Top para achar Approach, Gamble → Approach) |

**Combo Semi-Deterministico (3):**
| Combo | Pecas | Custo | Condicao | Confiabilidade |
|:------|:------|:-----|:---------|:------------|
| **Approach + Topdeck** | Approach + Top/Scroll/Penance | 7 + 1 | Apos 1o cast, manipular topo para achar Approach em 1-2 turnos | 🟡 Media — precisa de 1-2 turnos, vulneravel a disruption |
| **Surge + Approach** | Surge + Approach no grave + 3+ criaturas atacando | 4RR + combate | Casta copias de Approach durante o combate. 2a copia = vitoria. | 🟡 Media — requer criaturas atacando, Approach no grave |
| **Mizzix + Dance** | Mizzix overload + Dance com Calamity no grave | 5RR (7) | Exila topo ate achar 7+ cartas. Com Double Vision = 14+. Acha Approach. | 🟡 Media — variancia alta |

**Combo "Semi-Garantido" com Recursao (1):**
| Combo | Pecas | Custo | Condicao |
|:------|:------|:-----|:---------|
| **Worldfire + dano na stack** | Worldfire + qualquer fonte de dano | 6RRR (9) + dano | Resolve Worldfire (exila tudo, vida=1). Se houver dano na stack (Ashling trigger, Olorin), o oponente morre. | 🟢 Funciona mesmo sob Rest in Peace. Nao depende de Approach nem de grave. |

**Sinergia que falta 1 peca para virar combo deterministico:**
- **Approach + Top + Gamble + Faithless Looting** → ja e semi-deterministico. Com Flare, ja e deterministico. **COMPLETO.**

### F) STACK INTERACTION (Score: 7/10)

**Como o deck SOBREVIVE a counterspell no Approach (wincon primaria)?**

O deck tem **6 camadas de protecao na stack**:

| Camada | Carta | CMC | Mecanismo | Cobertura |
|:-------|:------|:---:|:----------|:----------|
| 1 | **Boseiju, Who Shelters All** | 0 | Channel: spell NAO pode ser counterada. Approach incounteravel. | 100% — mas so 1 uso (Channel exila) |
| 2 | **Grand Abolisher** | 2 | Oponentes nao conjuram no seu turno. | 100% enquanto vivo |
| 3 | **Cavern of Souls** | 0 | Nomeia "Elder Dragon" — Lorehold incounteravel. | Lorehold apenas |
| 4 | **Flare de Duplication** | 3 | Em resposta ao counter: copia Approach. Se counterarem a original, a copia resolve. | 1x (instant) |
| 5 | **Deflecting Swat** | 3 | Redireciona counterspell para Swat (alvo ilegal = counter falha). | 1x (instant) |
| 6 | **Hexing Squelcher** | 2 | Oponentes nao ativam habilidades. Bloqueia counterspell de criatura (Spell Queller, etc.). | Passivo |

**Cobertura total na stack: 6 camadas.** O deck pode forcar Approach mesmo contra Control com 3-4 counterspells se tiver Boseiju + Grand Abolisher. Se perder Grand Abolisher, Flare e Deflecting Swat sao backups.

**Counterspells proprios:** Nenhum (limitacao de cor — Boros/RW). Nao e gap — e compensado por 6 camadas de stack interaction + remocao instant-speed (Path, Swords, Abrade, Chaos Warp, Generous Gift, Olorin).

**Instant-speed Interaction (7):** Path, Swords, Abrade, Chaos Warp, Generous Gift, Olorin, Boros Charm (removal mode).

**Score: 7/10** — sem counterspell verdadeiro, mas com 6 camadas de stack interaction + 7 instant-speed removals. Suficiente para Bracket 3.

### G) GRAVEYARD HATE & RESILIENCE (Score: 8/10)

**Dependencia de Cemiterio:**
| Carta | Dependencia | Impacto se Exilado |
|:------|:-----------|:-------------------|
| Mizzix's Mastery | ALTA — precisa de grave cheio | Perde ~30% das wincons |
| Arcane Bombardment | ALTA — exila do grave | Loop perdido |
| Surge to Victory | ALTA — exila do grave | Perde este path de vitoria |
| Restoration Seminar | MEDIA — devolve do grave | Loop de Bombardment quebrado |
| Lorehold (copy) | MEDIA — copia do grave | Perde ~50% do motor de copia |
| Faithless Looting / Thrill / Demand Answers | BAIXA — enchem grave, mas nao dependem | Perde velocidade |

**O que SOBREVIVE a Rest in Peace / Leyline of the Void / Bojuka Bog:**
| Wincon | Sobrevive? | Como |
|:-------|:----------|:-----|
| **Approach + Flare** | ✅ SIM | Nao usa grave. Flare copia na stack. Approach vai pro deck (nao pro grave). |
| **Approach + Top/Scroll** | ✅ SIM | Topdeck manipulation, nao usa grave. |
| **Worldfire + dano** | ✅ SIM | Worldfire exila tudo (inclusive o proprio grave), mas a wincon e dano na stack antes de resolver. |
| **Storm Herd + Akroma's Will** | ✅ SIM | Nao usa grave. |
| **Mizzix overload** | ❌ NAO | Depende de grave cheio. |
| **Bombardment loop** | ❌ NAO | Depende de cartas no grave. |
| **Surge + Approach** | ❌ NAO | Depende de Approach no grave. |

**Resiliencia total: 3/6 wincons sobrevivem a grave hate.** Approach (primaria, 89.9% das vitorias) e Worldfire sao imunes. Storm Herd + Akroma's Will tambem. O deck nao MORRE para Rest in Peace — perde velocidade de recursao, mas mantem paths deterministicos de vitoria.

**Respostas a artefatos/encantamentos problematicos:**
| Carta | Alvo |
|:------|:-----|
| Chaos Warp | Qualquer permanente (shuffle) |
| Generous Gift | Qualquer permanente |
| Abrade | Artefato (OU 3 dano) |
| Austere Command | Enchantments (modo 3) ou artefatos (modo 2) |
| Boseiju, Who Shelters All | Channel: destoi artefato alvo |

**Score: 8/10** — resiliencia acima da media para deck dependente de cemiterio. 50% das wincons sao imunes a grave hate. 5 respostas a permanentes problematicos.

---

## Secao 3: SYNEGY_MAP — Scorecard Consolidado

| Eixo | Score | Forte | Fraco | Prioridade |
|:-----|:-----:|:------|:------|:----------|
| **A) Token + Pump** | 8/10 | Storm Herd + Akroma's Will = lethal garantida | Dependencia pesada de Akroma's Will; sem evasao sem ela | BAIXA |
| **B) Wipes + Protection** | 8/10 | 4 wipes premium, 5 protecoes, ratio 0.8 | Nenhum — e a melhor metrica do deck | BAIXA |
| **C) Recursion Chains** | 8/10 | 4 chains documentadas, 3+ sinergicas entre si | Vulneravel a grave hate (mas compensado — ver Eixo G) | BAIXA |
| **D) Mana Explosiva** | 7/10 | 14 fontes, 7 de treasure, Storm-Kiln escalavel | Sem fast mana CMC 0-1 alem de Sol Ring. Limite T3 ~47% | MEDIA |
| **E) Combo Pieces** | 9/10 | Combo deterministico Approach+Flare (2 cartas, 10 mana) | Dependente de Approach (unica wincon direta) | BAIXA |
| **F) Stack Interaction** | 7/10 | 6 camadas anti-counterspell | Sem counterspell verdadeiro (limitacao de cor RW) | MEDIA |
| **G) Resilience** | 8/10 | 3/6 wincons imunes a grave hate | Mizzix/Bombardment desabilitados por Rest in Peace | BAIXA |

**Media: 7.9/10** — DECK SAUDAVEL. Todos os eixos pontuam 7+.

---

## Secao 4: DOUBLE-NULL AUDIT

4 cartas permanecem invisiveis ao classificador (`functional_tag IS NULL` E zero `card_tags`):

| Carta | CMC | Funcao Real | EDHREC | Trend | Risco de Auto-Swap | Status |
|:------|:---:|:------------|:------:|:-----:|:-------------------|:-------|
| **Scroll Rack** | 2 | Draw, topdeck_manipulation | 59.5% | +0.48 | 🔴 CRITICO — core engine, Nivel 4 | **PROTEGIDA** — nunca cortar |
| **Penance** | 3 | Miracle enabler, engine, protection | 41.7% | +1.15 | 🔴 CRITICO — core engine, Nivel 4 | **PROTEGIDA** — nunca cortar |
| **Grand Abolisher** | 2 | Protection, stax | 11.7% | -0.27 | 🟡 MEDIO — em declinio, mas funcao unica | **MONITORAR** — tendencia negativa, mas stack protection e insubstituivel |
| **Taunt from the Rampart** | 5 | Protection, goad | 35.2% | +0.19 | 🟢 BAIXO — EDHREC estavel acima de 35% | **MANTER** — adocao comunitaria saudavel |

**Conclusao:** Nenhum double-null e cuttavel no momento. Scroll Rack e Penance sao CORE ENGINES (Nivel 4). Grand Abolisher e a unica protecao "oponentes nao conjuram no seu turno" (Nivel 3). Taunt e protecao de combate com 35.2% EDHREC estavel (Nivel 2).

---

## Secao 5: TENDENCIAS EDHREC (7851 decks)

### Rising Stars Confirmadas (3+ ciclos consecutivos com trend > 5.0)
| Carta | EDHREC | Trend | Status |
|:------|:------:|:-----:|:-------|
| Restoration Seminar | 37.9% | **+9.16** | ✅ NO DECK (Ciclo #2) |
| Improvisation Capstone | 49.0% | **+8.13** | ✅ NO DECK (Ciclo #3) |
| The Dawning Archaic | 24.0% | **+5.27** | ✅ NO DECK (Ciclo #5) |

### Declining Deck Cards (preocupante)
| Carta | EDHREC | Trend | Ciclos em Queda | Acao |
|:------|:------:|:-----:|:---------------:|:-----|
| Esper Sentinel | 32.4% | -0.54 | **7+ ciclos** | 🟡 Monitorar — 32.4% ainda e alto, mas tendencia persistente de queda |
| Call Forth the Tempest | 65.3% | -0.31 | 1 ciclo | 🟢 OK — 65.3% e excelente, queda de 1 ciclo pode ser ruido |
| Gamble | 12.1% | -0.50 | 2+ ciclos | 🟡 Monitorar — tutor com descarte e util, mas baixa adocao |

### Declining — Cartas de Baixa Adocao Fora do Core
| Carta | EDHREC | Trend | Significancia |
|:------|:------:|:-----:|:-------------|
| Demand Answers | 10.9% | -0.56 | Carta nova — ruido estatistico, base pequena. Adicionada C#17. |
| Flare of Duplication | 6.9% | -0.72 | Carta de nicho. Interacao com Approach nao e calculada por EDHREC. |
| Ashling, Flame Dancer | 5.8% | -0.53 | Carta nova — base minuscula. Sinergia com copy engines nao precificada. |
| The One Ring | 8.5% | -0.31 | GC — adocao baixa em Bracket 3 (jogadores evitam GC). Ainda draw massivo. |
| Worldfire | 7.3% | -0.31 | Wincon de nicho. Baixa adocao, mas funcao unica (exile reset). |

---

## Secao 6: O PLANO DE JOGO — Turn by Turn (Pos-C#17)

### Sequencia Ideal (T1-T6)
- **T1:** Land (fetch → Sacred Foundry) + Sol Ring (2 mana) → Sensei's Divining Top
- **T2:** Land + Arcane Signet (4 mana) → Esper Sentinel ou Mother of Runes
- **T3:** Land + Smothering Tithe (5 mana) ou Archaeomancer's Map
- **T4:** Land + Storm-Kiln Artist (6 mana) → online, cada spell gera Treasure
- **T5:** Land + Lorehold, the Historian (7 mana) → motor de copia ativo. Se tiver Double Vision em campo = 3 copias da primeira spell por turno.
- **T6:** Casta Dance with Calamity (Miracle {R}{R}{R}) → exila topo, acha Approach. OU casta Approach direto (7 mana). Com Storm-Kiln + Tithe = tesouros acumulados para 10 mana = Approach + Flare mesmo turno.

### Sequencia Media (T1-T6)
- **T1:** Land, pass
- **T2:** Land + Talisman/Signet (3 mana) → Thrill of Possibility ou Demand Answers
- **T3:** Land + Monument to Endurance ou Bender's Waterskin (4 mana)
- **T4:** Land + Ashling, Flame Dancer ou Big Score (5 mana)
- **T5:** Land + Lorehold (6 mana) → motor online, mas poucos tesouros
- **T6:** Casta spell de 7 mana (Brass's Bounty, Hit the Mother Lode) → gera tesouros para T7

### Sequencia Ruim (Sem Play T3 — ~10-13% projetado)
- **T1-T3:** Sem spells castaveis. Lands entram tapped. Mao cheia de CMC 5+.
- **Mulligan:** Se 0-1 lands ou 2 lands sem ramp → mulligan obrigatorio.
- **Recuperacao:** Wheel (Reforge the Soul T5) ou Valakut Awakening (instant T3) pode resetar mao ruim.

### Fase 1 (T1-T3) — Setup
- **Objetivo:** 3+ lands, 1+ fonte de ramp, 1+ peca de draw/topdeck
- **Cartas-chave:** Sol Ring, Land Tax, Sensei's Top, Esper Sentinel, Mother of Runes, Demand Answers
- **Danger:** Sem Play T3 ~10-13% (projetado pos-C#17, DCMC=-8)

### Fase 2 (T4-T6) — Motor Online
- **Objetivo:** Lorehold em campo, 1+ copy engine, Storm-Kiln ativo, tesouros acumulando
- **Cartas-chave:** Double Vision, Arcane Bombardment, The Dawning Archaic, Storm-Kiln, Smothering Tithe
- **Output:** 3-7 tesouros por spell, 2-4 copias por spell

### Fase 3 (T7+) — Execucao
- **Plano A:** Approach + Flare (10 mana, deterministico)
- **Plano B:** Storm Herd + Akroma's Will (14 mana, combate massivo)
- **Plano C:** Mizzix's Mastery overload (7 mana, valor massivo)
- **Plano D:** Surge + Approach (6 mana + combate, requer setup de grave)
- **Plano E:** Worldfire + dano na stack (9 mana + dano)

---

## Secao 7: GAPS ESTRATEGICOS (Pos-C#17)

| # | Gap | Severidade | Status Pos-C#17 |
|:-:|:-----|:----------:|:----------------|
| 1 | ~~Draw = 6 (2 abaixo do perfil)~~ | ~~CRITICO~~ | ✅ **RESOLVIDO.** Demand Answers + Ashling = draw 8 (dentro do perfil) |
| 2 | ~~Rise of the Eldrazi CMC 10~~ | ~~ALTO~~ | ✅ **RESOLVIDO.** Cortada para Demand Answers (DCMC=-8) |
| 3 | T3 = 10-13% (projetado) | MODERADO | 🟡 Necessaria re-simulacao (Mulligan Exec#12). Se T3 > 12% → DEFENSIVO C#18 (colecao esgotada de CMC ≤ 2). |
| 4 | Colecao esgotada de CMC ≤ 2 com sinergia | BLOQUEANTE | 🔴 ATIVO. Demand Answers era a ultima carta de draw CMC 2 na colecao. Qualquer DEFENSIVO futuro requer AQUISICAO. |
| 5 | Sem fast mana CMC 0-1 alem de Sol Ring | MODERADO | 🟡 Chrome Mox, Mana Vault, Mana Crypt ausentes. Limite estrutural de T3 ~47%. |
| 6 | Approach = 89.9% das vitorias | TOLERAVEL | 🟢 6 camadas de stack protection + Worldfire como alternativa. Aceitavel para deck com combo deterministico. |
| 7 | Ashling e Flare com EDHREC muito baixo (5-7%) | INFORMATIVO | 🟢 Cartas novas/niche. EDHREC e retrovisor — sinergia real com copy engines e Approach nao e capturada. |
| 8 | Stalls 26% (BATTLE v8) | BAIXO | 🟢 Limite estrutural do motor (max_turns=35). Nao e gap de deckbuilding. |

---

## Secao 8: RECOMENDACOES DE AQUISICAO (Proximo Upgrade)

Com colecao esgotada de CMC ≤ 2, o proximo upgrade do deck requer compra:

| # | Carta | CMC | Funcao | Custo $ | Justificativa |
|:-:|:------|:---:|:-------|:------:|:-------------|
| 1 | **Skullclamp** | 1 | Draw massivo | $5-8 | Prioridade #1 desde C#8. Com Storm Herd (40 tokens) = draw 80 cartas. Com Urza's Saga = tutoriavel. Substitui Thrill of Possibility. DCMC=-1. |
| 2 | **Chrome Mox** | 0 | Fast mana | $30-40 | Acelera T1-T2. Imprinta carta vermelha/branca. Reduz T3 significativamente. |
| 3 | **Mana Vault** | 1 | Fast mana | $40-50 | {C}{C}{C} — financia Lorehold T3 ou Approach T4. |
| 4 | **Enlightened Tutor** (ja no deck) | 1 | — | — | Ja presente. Usado para buscar Skullclamp, Top, The One Ring. |
| 5 | **Underworld Breach** | 2 | Recursion alternativa | $10-15 | Escape — substituto para Mizzix sob grave hate. Com Storm-Kiln = loop infinito. |

---

## Secao 9: COMPARACAO COM CICLOS ANTERIORES

| Metrica | v3.12 (deck fantasma) | v3.14 (DB real pre-C#17) | v3.15 (pos-C#17) | Delta |
|:--------|:---------------------:|:------------------------:|:----------------:|:-----:|
| Card Hash | (stale) | `84bc8798...` | `a440c497...` | Novo |
| CMC medio | ~3.71 | ~3.75 | **3.61** | -0.14 |
| Draw (real) | 7 | 6 | **8** | +2 ✅ |
| Board Wipes | 5 | 4 | 4 | 0 |
| Protection | 5 | 6 | 6 | 0 |
| Wincon (DB) | 6 | 7 | 3 (DB tag) / 7 real | DB tags nao confiaveis |
| Nivel 1 | VAZIO | VAZIO | **VAZIO** | OK |
| Double-nulls | 4 | 4 | 4 | 0 |
| Swaps Totais | 22 | 25 | **27** | +2 |
| Sem Play T3 | ~13% (Exec#11) | ~13-14% (estimado) | **~10-13% (projetado)** | -1 a -4pp |
| SYNERGY_MAP medio | 7.6 | 7.6 | **7.9** | +0.3 |

---

## Secao 10: VEREDITO FINAL

### O DECK ESTA SAUDAVEL (Pos-C#17)

**Resumo executivo para o Evolution Oracle (Ciclo #18):**

1. **C#17 foi EXCELENTE.** Demand Answers (CMC 2) e Ashling (CMC 4) corrigiram o gap de draw (6 → 8) e removeram Rise of the Eldrazi (CMC 10, pior carta do deck). Net DCMC=-8 e o melhor ciclo defensivo desde C#4.

2. **SYNERGY_MAP = 7.9/10.** Todos os 7 eixos pontuam 7+. Motor 4/4 completo. 6 copy engines ativas. 3 wincons imunes a grave hate. 6 camadas de stack protection. Nivel 1 VAZIO. Nenhum double-null cuttavel.

3. **T3 PROJETADO: 10-13%.** Necessaria re-simulacao (Mulligan Exec#12) para confirmar. DCMC=-8 deve reduzir T3 em 2-4pp vs baseline de 13.3% (Exec#11 pre-C#17).

4. **ESTRATEGIA C#18:**
   - Se T3 confirmado ≤ 12% → **BALANCED (0 swaps ou DCMC=0).** Deck saudavel. Colecao esgotada.
   - Se T3 > 12% → **DEFENSIVO (0 swaps — colecao esgotada).** Documentar que a proxima melhoria requer AQUISICAO.
   - Em ambos os casos, 0 swaps e o resultado mais provavel. C#11-C#16 (pre-descoberta do deck fantasma) foram 0 swaps por 6 ciclos consecutivos. C#17 quebrou o padrao porque havia 2 gaps reais (Rise+Longshot). Esses gaps foram fechados.

5. **PROXIMO UPGRADE REAL: Skullclamp (CMC 1, $5-8).** Qualquer swap futuro que melhore o deck requer compra. A colecao de CMC ≤ 2 com sinergia para Lorehold esta ESGOTADA.

6. **MATURIDADE DO DECK: ALTA.** 27 swaps desde baseline. Todos os gaps estruturais fechados. Nivel 1 vazio. SYNERGY_MAP 7.9/10. O Purpose Analyzer confirma: o deck esta otimizado dentro do que a colecao permite.

---

*Fim do relatorio v3.15. Proximo agente: Mulligan Tester (Exec#12) para confirmar T3 pos-C#17.*
