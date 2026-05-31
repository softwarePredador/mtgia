# VALIDATOR_LOG — Lorehold Spellslinger (v3.13 — Maturidade Persistente)

**Data:** 2026-05-31
**Timestamp:** 2026-05-31T23:37:47+00:00
**Versao do Analisador:** v3.13 (SYNERGY_MAP completo com 7 eixos A-G)
**Deck ID:** 6 (knowledge.db)
**Estado:** 86 linhas, 100 cartas totais, 35 lands
**Ciclo atual:** Pos-Ciclo #11 (MATURIDADE ATINGIDA — 3 ciclos consecutivos com 0 swaps)
**Swaps acumulados desde baseline:** 22
**Ultima mudanca no deck:** Ciclo #10 (Flare of Duplication + Twinflame IN; Ruby Medallion + Galvanoth OUT)

---

## Resumo Executivo

O deck Lorehold Spellslinger atingiu MATURIDADE PERSISTENTE. Tres ciclos consecutivos (C#11, C#12, C#13) com **0 swaps** — 48+ candidatos avaliados e rejeitados em 3 ciclos. A colecao do usuario esta ESGOTADA de cartas CMC <= 3 com sinergia para Lorehold.

O deck opera com:
- **6 copy engines ativos** (Lorehold, Double Vision, Arcane Bombardment, The Dawning Archaic, Flare of Duplication, Twinflame)
- **Motor 4/4 completo** (Treasure Ramp, Free Big Spell, Lorehold Copy, Treasure Payoff)
- **SYNERGY_MAP com 7 eixos** pontuando de 6 a 9/10
- **Nivel 1 VAZIO** — nenhuma carta filler ou substituivel
- **Sem Play T3 = 13.3%** (Execucao #11, seed=42, N=1000) — estavel ha 2 ciclos
- **Combos deterministicos:** Approach + Topdeck (Scroll Rack / Sensei's Top) = vitoria em 2 turnos
- **Combo semi-deterministico:** Approach + Flare of Duplication = vitoria NO MESMO TURNO (se 7 manas disponiveis + Approach no grave)

### Prioridade de Aquisicao (para proximo upgrade)

| Carta | CMC | Funcao | Por que | Preco estimado |
|:------|:---:|:-------|:--------|:---------------|
| Skullclamp | 1 | Draw engine | Draw massivo com tokens; melhor draw engine do formato | $5-8 |
| Enlightened Tutor | 1 | Tutor | Ja no deck — redundancia com Gamble | — |
| Gamble | 1 | Tutor | Ja no deck | — |

---

## Secao 1: METRICAS ATUAIS

```
total_lands:      35
avg_cmc:          3.81
ramp_count:       14
draw_count:        7
removal_count:     6
tutor_count:       1 (DB tag — real: 3 via Enlightened + Gamble + Urza's Saga)
board_wipe_count:  5
protection_count:  3 (DB tag — real: 6+ via Boros Charm, Teferi's, Swat, Greaves, Abolisher, Hexing)
recursion_count:   4 (DB tag — real: 5+ via Mizzix's, Bombardment, Surge, Restoration Seminar, Twinflame)
wincon_count:      2 (DB tag — real: 6+ via Approach, Insurrection, Storm Herd, Surge, Akroma's, Call Forth)
engine_count:      9 (DB tag — real: 12+ via copy engines + payoff engines)
```

**Discrepancias entre DB tags e funcao real:**
- `tutor_count=1` mas o deck tem **3 tutores**: Enlightened Tutor, Gamble, Urza's Saga
- `protection_count=3` mas o deck tem **7 protecoes**: Teferi's Protection, Deflecting Swat, Boros Charm, Grand Abolisher, Lightning Greaves, Hexing Squelcher, Cavern of Souls
- `draw_count=7` subestima: Monument to Endurance, Scroll Rack, Sensei's Top, Penance, Valakut Awakening, Library of Leng sao draw engines que nao sao contados como "draw"
- `recursion_count=4` mas o deck tem **5 recursion engines**: Mizzix's Mastery, Arcane Bombardment, Surge to Victory, Restoration Seminar, Twinflame (creature copy count as recursion)
- `wincon_count=2` mas o deck tem **7 win conditions**: Approach (primaria deterministico), Insurrection, Storm Herd, Surge to Victory, Akroma's Will, Call Forth the Tempest, Mizzix's Mastery (overload como pseudo-wincon)

---

## Secao 2: CLASSIFICACAO ESTRATEGICA (86 cartas)

### Nivel 5 — O Deck Nao Funciona Sem (3 cartas)

| Carta | CMC | Funcao Real | Por que Nivel 5 |
|:------|:---:|:------------|:----------------|
| **Lorehold, the Historian** | 5 | engine, copy, commander | Copia instants/sorceries do graveyard — o coracao do deck |
| **Approach of the Second Sun** | 7 | wincon, deterministico | Unica wincon que GANHA sem combate. Cast 2x = vitoria. |
| **Mizzix's Mastery** | 4(8) | recursion, wincon, engine | Overload = 8 mana por TODOS instants/sorceries do grave. Pode ganhar sozinho. |

### Nivel 4 — Core da Estrategia (12 cartas)

| Carta | CMC | Funcao Real | Por que Nivel 4 |
|:------|:---:|:------------|:----------------|
| **Double Vision** | 5 | copy engine | Copia o primeiro instant/sorcery por turno — dobra valor de cada spell |
| **Arcane Bombardment** | 5 | copy engine, recursion | Exila instants/sorceries do grave, copia 1 por turno gratis — motor de valor infinito |
| **Dance with Calamity** | 8(Miracle 3RR) | exile_value, engine | Exila topo ate 8 cartas, casta TODAS gratis. Com topdeck manipulacao = draw 8+ e cast gratis |
| **Improvisation Capstone** | 7 | exile_value, engine | Exila topo 7, casta 1 gratis por turno (ate 7 cartas). Engine de valor continuo. |
| **Surge to Victory** | 6 | recursion_wincon, pump | Exila instant/sorcery do grave, da +N/+0 a cada criatura e faz cada uma copiar o spell ao causar dano |
| **Flare of Duplication** | 3 | copy, combo_piece | Copia instant/sorcery. Com Approach no grave: cast Flare → copy Approach do grave → VITORIA MESMO TURNO |
| **The Dawning Archaic** | 3 | copy engine, todos turnos | Copia o primeiro instant/sorcery de QUALQUER jogador — dobra valor em cada turno da mesa |
| **Twinflame** | 2 | copy, combo_piece | Copia criatura + Surge. Com Storm-Kiln: copia → 2 storm-kilns → Treasure×2 por spell |
| **Scroll Rack** | 2 | topdeck_engine, draw | Troca mao pelo topo. Com fetch = shuffle away dead cards. Essencial para Miracle + Approach. |
| **Sensei's Divining Top** | 1 | topdeck_engine, draw | Top + fetch = draw 1 por turno. Com Approach: garante draw do Approach em 1 turno. |
| **Penance** | 3 | topdeck_engine, protection | Poe carta da mao no topo. Com Miracle Dance = garante cast. Anti-removal: esconde carta no topo. |
| **Restoration Seminar** | 7 | recursion_engine, Lesson | Recupera instants/sorceries do grave para a mao. Com Bombardment = loop infinito. |

### Nivel 3 — Suporte Forte (36 cartas)

| Carta | CMC | Funcao Real | Por que Nivel 3 |
|:------|:---:|:------------|:----------------|
| **Storm-Kiln Artist** | 4 | ramp_engine, treasure | Treasure por cada instant/sorcery castado — FECHA o Motor |
| **Smothering Tithe** | 4 | ramp, treasure | Treasure por draw do oponente. Com wheels = mana explosiva. |
| **Wedding Ring** | 4 | draw, simetrico | Draw adicional por turno. Se oponente joga, voce draw tambem. |
| **The One Ring** | 4 | draw_engine, protecao | Draw massivo (1→2→3... cartas por turno). Protecao de tudo por 1 turno. |
| **Monument to Endurance** | 3 | draw_engine, loot | Draw adicional por descarte. Com Faithless Looting = draw 3 por 1 mana. |
| **Victory Chimes** | 3 | draw_engine, mana | Untap em cada turno = 4 manas por ciclo. Draw em ETB de artefato. |
| **Jeska's Will** | 3 | ramp, ritual | Adiciona RRR + exila topo 3. Em Commander = frequentemente 7+ mana por 3. |
| **Teferi's Protection** | 3 | protection, absoluta | Phase out — salva de tudo. Melhor protecao de Commander. |
| **Deflecting Swat** | 3 | protection, redirect | Redireciona spell/ability. Resposta a counterspell no Approach. |
| **Chaos Warp** | 3 | removal, universal | Remove QUALQUER permanente. Shuffle-based — unico removal desse tipo no deck. |
| **Akroma's Will** | 4 | wincon, pump, protection | Da double strike, flying, vigilance, lifelink, protection de todas as cores a TODAS criaturas |
| **Volcanic Vision** | 7 | board_wipe, recursion | Dano = CMC do instant/sorcery alvo no grave + retorna ele para a mao |
| **Austere Command** | 6 | board_wipe, modular | Escolhe 2 modos — wipe assimetrico |
| **Blasphemous Act** | 9(1) | board_wipe, barato | Custa 1 mana com board cheio. 13 de dano = mata tudo. |
| **Call Forth the Tempest** | 8 | board_wipe, wipe_wincon | Dano = mana gasta. Pode matar jogadores alem de criaturas. |
| **Insurrection** | 8 | wincon, steal | Rouba TODAS as criaturas. Com haste de Lightning Greaves = OTK. |
| **Storm Herd** | 10 | wincon, token_massivo | Cria X tokens 1/1 Pegasus onde X = vida. Com Akroma's Will = vitoria. |
| **Boros Charm** | 2 | protection, pump | Todos 4 modos relevantes: indestrutivel, double strike, 4 dano |
| **Faithless Looting** | 1(2) | draw, loot, grave_setup | Flashback — enche o grave para Mizzix's / Bombardment |
| **Dragon's Rage Channeler** | 1 | draw_engine, grave_synergy | Surveil 1 por turno. Delirium = 3/3 flying. Enche grave. |
| **Enlightened Tutor** | 1 | tutor, topdeck | Busca artefato/encantamento para o topo. Top + E-Tutor = draw imediato. |
| **Sol Ring** | 1 | ramp, fast_mana | Melhor fast mana do formato. T1 Sol Ring = 3 manas T2. |
| **Rite of the Dragoncaller** | 6 | engine, spellslinger_payoff | Cria dragon 5/5 flying por cada instant/sorcery castado no turno |
| **Reforge the Soul** | 5(Miracle R) | draw, wheel | Miracle por R = draw 7 por 1 mana. Wheel que enche grave. |
| **Olórin's Searing Light** | 4 | removal, graveyard_hate | Exila criatura + da dano = poder. Anti-reanimator. |
| **Brass's Bounty** | 7 | ramp, treasure_massivo | Cria Treasure por cada terra. Com 7+ terras = 7+ tesouros. |
| **Hit the Mother Lode** | 7 | ramp, treasure, discover | Discover 10 — pode achar Approach, Dance, etc. Cria Treasure por carta revelada. |
| **Big Score** | 4 | ramp, draw, instant | Cria 2 Treasure + draw 2. Instant speed = casta no fim do turno do oponente. |
| **Unexpected Windfall** | 4 | ramp, draw, instant | Cria 2 Treasure + draw 2. Mesma funcao que Big Score — redundancia. |
| **Ancient Tomb** | 0 | ramp, sol_land | 2 manas incolores. Acelera T2 Lorehold. |
| **Boseiju, Who Shelters All** | 0 | removal, channel | Channel — remove artefato/encantamento nao-basico incounteravel. |
| **Cavern of Souls** | 0 | protection, uncounterable | Nomeia Dragon — Lorehold incounteravel. Protege o commander. |
| **Kor Haven** | 0 | protection, fog | Previne dano de combate de 1 criatura atacante por turno. |
| **Urza's Saga** | 0 | tutor, token | Busca Sol Ring / Sensei's Top / Scroll Rack. Cria tokens Karnstruct. |
| **Valakut Awakening // Valakut Stoneforge** | 3 | draw, wheel | Poe mao no fundo, draw mesma quantidade. Reset de mao. |
| **Emeria's Call // Emeria, Shattered Skyclave** | 7 | token_maker, land | Cria 2 tokens 4/4 flying. MDFC - pode ser land ou spell. |

### Nivel 2 — Utilidade Situacional (28 cartas)

| Carta | CMC | Funcao Real |
|:------|:---:|:------------|
| **Path to Exile** | 1 | removal, exile |
| **Swords to Plowshares** | 1 | removal, exile |
| **Abrade** | 2 | removal, artifact_hate |
| **Generous Gift** | 3 | removal, universal |
| **Grand Abolisher** | 2 | protection, proactive |
| **Lightning Greaves** | 2 | protection, haste |
| **Hexing Squelcher** | 2 | protection, spellslinger_tax |
| **Fated Clash** | 5 | board_wipe, dano |
| **Taunt from the Rampart** | 5 | board_wipe, goad |
| **Thrill of Possibility** | 2 | draw, instant_loot |
| **Longshot, Rebel Bowman** | 4 | spellslinger_payoff, removal |
| **Library of Leng** | 1 | hand_smoothing, no_max_hand |
| **Land Tax** | 1 | ramp_setup, draw_lands |
| **Weathered Wayfarer** | 1 | ramp_setup, tutor_land |
| **Esper Sentinel** | 1 | draw, tax_draw |
| **Gamble** | 1 | tutor, entomb |
| **Arcane Signet** | 2 | ramp, rock |
| **Boros Signet** | 2 | ramp, rock |
| **Talisman of Conviction** | 2 | ramp, rock |
| **Archaeomancer's Map** | 3 | ramp, catchup |
| **Bender's Waterskin** | 3 | ramp, rock_untap |
| **Arid Mesa** | 0 | fetch |
| **Bloodstained Mire** | 0 | fetch |
| **Flooded Strand** | 0 | fetch |
| **Scalding Tarn** | 0 | fetch |
| **Windswept Heath** | 0 | fetch |
| **12 duals/basics** | 0 | mana_base |

### Nivel 1 — Substituivel (0 cartas)

**VAZIO.** Nao ha filler no deck. Todas as cartas tem funcao definida e contribuem para pelo menos um eixo de sinergia. Este e o indicador mais forte de maturidade.

---

## Secao 3: SYNERGY_MAP — 7 Eixos

### EIXO A — TOKEN MAKERS + PUMP (Pontuacao: 7/10)

**Token Makers no deck:**
| Carta | CMC | Tokens gerados | Condicao |
|:------|:---:|:---------------|:---------|
| Storm Herd | 10 | X tokens 1/1 Pegasus | X = vida total |
| Call Forth the Tempest | 8 | Dano a jogadores = vitoria por dano direto | X = mana gasta |
| Emeria's Call | 7 | 2 tokens 4/4 Angel | Sempre 2 |
| Rite of the Dragoncaller | 6 | 1 token 5/5 Dragon por spell castado | Acumula no turno |
| Urza's Saga | 0 | 2 tokens Karnstruct (max) | Capitulos I-II |

**Pump Effects no deck:**
| Carta | CMC | Efeito |
|:------|:---:|:-------|
| Akroma's Will | 4 | Double strike, flying, vigilance, lifelink, pro-todas-cores a TODAS criaturas |
| Surge to Victory | 6 | +N/+0 a cada criatura onde N = CMC do spell exilado. Cada criatura copia ao causar dano. |
| Boros Charm | 2 | Double strike a TODAS as criaturas |

**Pares Token+Pump (dano estimado):**
- Storm Herd (40 vida, 40 tokens) + Boros Charm (double strike) = 80 dano com 1/1s. COM Akroma's Will: 40×4/4 flying double strike = 320 dano.
- Storm Herd + Surge to Victory (exila Approach, CMC 7) = 40 tokens 8/1 double strike = 640 dano.
- Rite of the Dragoncaller (3 spells cast = 3 dragons 5/5) + Akroma's Will = 3 dragons 5/5 double strike flying = 30 dano evasivo.

**Forcas:** Multiplas combinacoes token+pump que ganham o jogo. Storm Herd e a mais explosiva (dano na casa das centenas).
**Fraquezas:** Storm Herd e CMC 10 — lento. Rite of the Dragoncaller precisa de turno de setup. Token makers sao todas sorceries — vulneraveis a counterspell.
**Nota 7/10:** Bom, mas nao e o plano A. O deck nao e um deck de tokens — tokens sao plano C (plano A = Approach, plano B = Insurrection/Surge).

### EIXO B — BOARD WIPES + PROTECTION (Pontuacao: 8/10)

**Board Wipes:**
| Carta | CMC | Tipo |
|:------|:---:|:-----|
| Austere Command | 6 | Modular — escolhe 2 modos. Pode ser assimetrico. |
| Blasphemous Act | 9(1) | 13 dano a todas as criaturas. Custa 1 mana com board cheio. |
| Call Forth the Tempest | 8 | Dano = mana gasta. Pode matar jogadores. |
| Volcanic Vision | 7 | Dano = CMC do spell alvo. Retorna spell para a mao. |
| Fated Clash | 5 | Cada jogador escolhe uma cor — destruir criaturas daquela cor. |
| Taunt from the Rampart | 5 | Goad — nao e wipe, mas redireciona ataque. |

**Protecoes:**
| Carta | CMC | Tipo |
|:------|:---:|:-----|
| Teferi's Protection | 3 | Phase out — protecao absoluta. |
| Boros Charm | 2 | Indestrutivel para TODOS os permanentes. |
| Deflecting Swat | 3 | Redirect spell/ability. Responde a counterspell. |
| Grand Abolisher | 2 | Oponentes nao podem castar no seu turno. |
| Lightning Greaves | 2 | Shroud + haste. Protege Lorehold. |
| Hexing Squelcher | 2 | Taxa 1 mana por spell nao-creature do oponente. |
| Cavern of Souls | 0 | Lorehold incounteravel. |

**Pares Wipe+Protecao:**
- Austere Command + Boros Charm = destruir todas criaturas, suas permanentes indestrutiveis
- Blasphemous Act + Teferi's Protection = 13 dano no board, voce em phase out — nada te toca
- Call Forth the Tempest + Boros Charm = dano massivo, suas criaturas sobrevivem

**Ratio:** 6 wipes / 7 protecoes = **0.86**. Excelente — mais protecoes que wipes. O deck NAO se auto-destroi.
**Nota 8/10:** Wipes sao majoritariamente assimetricos (Austere, Blasphemous, Volcanic). Protecoes sao diversas (phase out, indestrutivel, redirect, proactive). Ponto fraco: nenhum wipe e instant-speed.

### EIXO C — RECURSION CHAINS (Pontuacao: 8/10)

**Recursion Engines:**
| Carta | CMC | O que faz |
|:------|:---:|:----------|
| Mizzix's Mastery | 4(8) | Overload: casta TODOS instants/sorceries do grave de graca. 8 mana. |
| Arcane Bombardment | 5 | Exila instant/sorcery do grave: copia 1 por turno de graca. Acumula — depois de 4 turnos = 4 spells gratis por turno. |
| Surge to Victory | 6 | Exila instant/sorcery do grave: cada criatura ganha +CMC/+0 e copia o spell ao causar dano. |
| Restoration Seminar | 7 | Retorna instant/sorcery do grave para a mao. Com Bombardment: poe no grave de novo → Seminar recupera → loop. |
| Twinflame | 2 | Copia criatura. Com Storm-Kiln: copia → 2 storm-kilns → Treasure×2 por spell. Surge pode copiar criaturas com Twinflame. |
| Lorehold, the Historian | 5 | Copia instant/sorcery do grave no ataque (gratis). |

**Chains documentadas:**
1. **Faithless Looting → Mizzix's Mastery (overload):** Looting enche o grave. Mizzix's overload casta TUDO. Com 10+ instants/sorceries no grave = valor explosivo. T1-T3: loot, T4: overload = vitoria.
2. **Arcane Bombardment + Restoration Seminar:** Bombardment exila spell do grave → casta copia. Seminar recupera do grave para mao. Spell volta ao grave apos cast → Bombardment exila de novo. LOOP INFINITO de valor. 1 spell por turno garantido.
3. **Dance with Calamity + Scroll Rack:** Scroll Rack poe cartas caras no topo. Dance exila e casta TODAS gratis. Com Penance: garante Miracle cost (3 mana).
4. **Surge to Victory + Twinflame:** Twinflame copia Storm-Kiln → 2 Storm-Kilns. Surge exila Twinflame do grave → cada criatura ganha +2/+0 e ao causar dano faz copia de criatura = cadeia de copias exponencial.

**Forcas:** 5 recursion engines distintos que se sobrepoem. Bombardment+Seminar = loop garantido. Mizzix's = explosivo. Surge = transforma qualquer board em ameaca.
**Fraquezas:** TODOS dependem do cemiterio. Rest in Peace = desliga 4 dos 5 engines (so Lorehold permanece funcional). O deck tem 0 respostas a enchantment-based grave hate (exceto Chaos Warp, Generous Gift).
**Nota 8/10:** Excelente depth de recursion. 1 ponto perdido pela vulnerabilidade a grave hate sem respostas dedicadas.

### EIXO D — MANA EXPLOSIVA (Pontuacao: 9/10)

**Geradores de Treasure:**
| Carta | CMC | Producao |
|:------|:---:|:---------|
| Storm-Kiln Artist | 4 | 1 Treasure por instant/sorcery castado. Com 3 spells = 3 treasures. |
| Smothering Tithe | 4 | 1 Treasure por draw do oponente (a menos que paguem 2). |
| Brass's Bounty | 7 | Treasure = numero de terras. Com 8 terras = 8 treasures. |
| Hit the Mother Lode | 7 | Discover 10 + Treasure por carta revelada (max 10). |
| Big Score | 4 | 2 Treasure + draw 2. Instant speed. |
| Unexpected Windfall | 4 | 2 Treasure + draw 2. Instant speed. |

**Rituais One-Shot:**
| Carta | CMC | Producao |
|:------|:---:|:---------|
| Jeska's Will | 3 | RRR + exila topo 3. Com 5 cartas na mao do oponente = 8 mana total. |
| Sol Ring | 1 | 2 manas incolores. T1 = 3 manas T2. |

**Mana Rocks:**
| Carta | CMC | Produz |
|:------|:---:|:-------|
| Arcane Signet | 2 | R ou W |
| Boros Signet | 2 | RW |
| Talisman of Conviction | 2 | R ou W (paga 1 vida) |
| Bender's Waterskin | 3 | Qualquer cor, untap em cada turno |
| Victory Chimes | 3 | Qualquer cor, untap em cada turno |
| Ancient Tomb | 0 | 2 manas incolores |

**Para que serve tanta mana:**
- Mizzix's Mastery overload = 8 mana
- Storm Herd X=40 = 10 mana
- Dance with Calamity Miracle = 3 mana (casta ate 8 spells gratis — precisa de mana para os spells?)
- Call Forth the Tempest X=20 = 22 mana (mata a mesa)
- Insurrection = 8 mana

**Sequencia ideal de mana (T1-T6):**
- T1: Land + Sol Ring (3 manas T2)
- T2: Land + Arcane Signet + Faithless Looting (enche grave)
- T3: Land + Smothering Tithe (4 manas T4, tithe gera treasures)
- T4: Land + Storm-Kiln Artist + spell barato = treasure
- T5: Land + Jeska's Will (8+ manas) → Dance with Calamity (Miracle 3 mana) → casta 6+ spells gratis
- T6: Mizzix's Mastery overload OU Approach + topdeck

**Nota 9/10:** Mana explosiva e a forca #1 do deck. Entre treasures, rituais, e rocks, o deck consistentemente gera 8-15 manas nos turnos 5-6. Com Storm-Kiln + spells, a geracao e exponencial. Ponto fraco: depende de Storm-Kiln sobreviver. Sem ele, a geracao cai para 5-8 manas.

### EIXO E — COMBO PIECES (Pontuacao: 9/10)

**Combos Deterministicos:**

1. **Approach + Topdeck Manipulation = Vitoria em 2 Turnos**
   - Cast Approach (7 mana) → vai para 7a posicao do deck
   - Com Scroll Rack / Sensei's Top / Penance no campo: draw Approach imediatamente
   - Cast Approach de novo (7 mana) = VITORIA
   - **Requisito:** 14 manas em 2 turnos (7+7) + topdeck engine no campo. Com Storm-Kiln + 3 spells = 3 treasures extra por turno = consistentemente atingivel no T6-T7.
   - **Confiabilidade: 9/10.** 3 topdeck engines + 3 tutores (Enlightened, Gamble, Urza's Saga). Top + fetch = draw extra por turno.

2. **Approach + Flare of Duplication = Vitoria NO MESMO TURNO**
   - Cast Approach (7 mana) → vai para 7a posicao. Approach esta NO CEMITERIO se counterado OU se castado e resolvido (vai para o deck, mas se counterado fica no grave).
   - Flare of Duplication (3 mana): copia instant/sorcery no cemiterio → copia Approach do grave
   - Copia de Approach = "voce ganha o jogo" (porque Approach original ja foi castado este turno)
   - **Requisito:** 10 manas no mesmo turno (7+3) + Approach no cemiterio (counterado, ou discard + recursion)
   - **Confiabilidade: 7/10.** Requer que Approach va para o cemiterio (counterado, ou Faithless Looting → discard). Com 0 counterspells no deck, Approach frequentemente resolve — entao esse combo e situacional (usado quando Approach e counterado).

3. **Galvanoth + Topdeck = semi-deterministico** — REMOVIDO no Ciclo #10. Galvanoth era fragil (CMC 5, corpo 3/3, morre para qualquer remocao). Substituido por Twinflame (CMC 2, mais resiliente).

4. **Surge to Victory + board grande = Vitoria por dano massivo**
   - Exila Approach (CMC 7) do grave com Surge
   - Cada criatura ganha +7/+0 e copia Approach ao causar dano (mas Approach copiado nao ganha o jogo — precisa ser CASTADO do deck)
   - Dano bruto: 4 criaturas × 8+ poder = 32+ dano. Com double strike = 64+.
   - **Confiabilidade: 6/10.** Nao e combo deterministico — e dano massivo. Mas com Akroma's Will = unblockable + double strike = vitoria garantida contra maioria dos boards.

5. **Insurrection + Lightning Greaves = OTK**
   - Insurrection rouba todas criaturas. Lightning Greaves equipa gratuitamente (equip 0). Tudo com haste.
   - Dano = soma do poder de todas criaturas no campo. Em mesa de 4 jogadores = tipicamente 40+ dano.
   - **Confiabilidade: 8/10.** 2 cartas, 10 mana. Nao depende do cemiterio. Fraqueza: Fog effects.

**Nota 9/10:** Approach e uma wincon de uma carta so (com suporte de topdeck). Flare de Duplication adiciona redundancia no mesmo turno. Insurrection e Surge sao planos B/B+ independentes. Storm Herd e Call Forth sao planos C. O deck tem MULTIPLAS rotas para vitoria que nao dependem umas das outras — resiliencia maxima.

### EIXO F — STACK INTERACTION (Pontuacao: 6/10)

**Capacidade de interagir na stack:**
| Carta | CMC | Tipo |
|:------|:---:|:-----|
| Deflecting Swat | 3 | Redirect spell/ability. Pode responder a counterspell no Approach. |
| Boros Charm | 2 | Indestrutivel em resposta a remocao. Nao interage com counterspell. |
| Teferi's Protection | 3 | Phase out em resposta a tudo. Nao interage com counterspell (seus spells ja estao na stack). |
| Grand Abolisher | 2 | Proativo — oponentes nao podem jogar no seu turno. PREVINE counterspells. |
| Hexing Squelcher | 2 | Taxa 1 mana. Torna counterspells mais caros. |

**Como o deck SOBREVIVE a um counterspell no Approach?**
1. Grand Abolisher no campo → impossivel counterar (preventivo)
2. Deflecting Swat → redirect o counterspell para Swat
3. Se counterado: Approach vai para o cemiterio → Flare of Duplication copia do cemiterio → VITORIA MESMO TURNO
4. Se counterado e sem Flare: Mizzix's Mastery overload casta Approach do cemiterio → Approach vai para 7a posicao → draw com topdeck engine → cast de novo

**Forcas:** Grand Abolisher + Deflecting Swat dao 2 camadas de protecao na stack. Flare de Duplication transforma counterspell em vitoria (casta Approach do cemiterio no mesmo turno).
**Fraquezas:** 0 counterspells proprios. Boros nao tem acesso a counterspell. O deck NAO PODE counterar wincons dos oponentes — depende de remocao e wipe.
**Nota 6/10:** Protecao de stack e suficiente para o proprio deck (3 camadas), mas zero capacidade de interromper combos dos oponentes. E a fraqueza inerente do Boros.

### EIXO G — GRAVEYARD HATE & RESILIENCE (Pontuacao: 6/10)

**Dependencia do cemiterio:**
| Carta | Depende do cemiterio? | Impacto se exilado |
|:------|:----------------------:|:-------------------|
| Mizzix's Mastery | SIM (overload casta do grave) | Perde a wincon mais explosiva |
| Arcane Bombardment | SIM (exila do grave para copiar) | Perde engine de valor |
| Surge to Victory | SIM (exila do grave) | Perde plano B |
| Restoration Seminar | SIM (recupera do grave) | Perde recursion |
| Faithless Looting | SIM (flashback do grave) | Perde loot engine |
| Approach of the Second Sun | NAO (cast do deck) | Imune a grave hate |
| Insurrection | NAO | Imune |
| Storm Herd | NAO | Imune |
| Lorehold (commander) | SIM (copia do grave) | AINDA FUNCIONA (usa grave como COPY, nao remove) |

**Respostas a artefatos/encantamentos problemáticos (Rest in Peace, Leyline of the Void):**
| Carta | CMC | Alvo |
|:------|:---:|:-----|
| Chaos Warp | 3 | Qualquer permanente — shuffle. Unica resposta universal. |
| Generous Gift | 3 | Qualquer permanente — destroi, da token 3/3. |
| Abrade | 2 | Artefato OU 3 dano a criatura. |
| Boseiju, Who Shelters All | 0 | Channel — remove artefato/encantamento nao-basico. Incounteravel. |

**Cenario: Oponente joga Rest in Peace T2. O que o deck faz?**
1. Chaos Warp (T3, 3 mana) — shuffle, melhor resposta
2. Generous Gift (T3, 3 mana) — destroi
3. Boseiju Channel (T0-T3, 2 mana) — remove incounteravelmente
4. Se nenhuma resposta: o deck PERDE Mizzix's, Bombardment, Surge, Seminar, Looting flashback. Sobrevive com: Approach, Insurrection, Storm Herd, Lorehold (copia do grave ainda funciona com Rest in Peace? NAO — Rest in Peace exila cartas que vao para o cemiterio. Lorehold copia cartas que JA ESTAO no cemiterio. Se RIP entrou depois, as cartas no cemiterio sao exiladas. RIP impede NOVAS cartas de irem para o cemiterio. Lorehold fica inutilizavel apos RIP entrar.)

**Resiliencia real:** 3 respostas (Chaos Warp, Generous Gift, Boseiju) em 100 cartas. Chance de ter uma na mao ate T3: ~25% (considerando 3 respostas + 3 tutores). Se nao tiver resposta, o deck perde 60% da sua capacidade ofensiva.

**Nota 6/10:** Tem respostas, mas sao poucas e nao dedicadas. Um Rest in Peace T2 nao respondido = o deck vira um deck de Approach + tokens apenas. Suficiente para jogos casuais, mas vulneravel em mesas competitivas com grave hate.

---

## Secao 4: AUDITORIA DOUBLE-NULL

4 cartas permanecem como double-null (`functional_tag IS NULL` E zero `card_tags`):

| Carta | CMC | Funcao Real | Importancia | EDHREC % | Risco |
|:------|:---:|:------------|:-----------:|:--------:|:------|
| **Scroll Rack** | 2 | Topdeck engine + hand smoothing | NIVEL 4 | ~40% | 🔴 NUNCA cortar — core engine |
| **Penance** | 3 | Topdeck setup + anti-removal | NIVEL 4 | ~15% | 🔴 NUNCA cortar — miracle enabler |
| **Grand Abolisher** | 2 | Proactive protection | NIVEL 2 | ~12% | 🟡 Monitorar (declinio -0.27) |
| **Taunt from the Rampart** | 5 | Mass goad | NIVEL 2 | ~35% | 🟢 Manter — 35.2% EDHREC |

**Por que o classificador falha:**
- Scroll Rack: Efeito unico (trocar mao pelo topo) — nao se encaixa em "draw" nem "tutor"
- Penance: Efeito unico (por carta da mao no topo) — nao e "protection" classico
- Grand Abolisher: E "protection" mas o classificador perde por ser uma habilidade estatica, nao ativada
- Taunt from the Rampart: Goad em massa — classificador nao tem categoria "goad"

**Regra:** Nenhum double-null deve ser cortado sem confirmacao EDHREC. Todos os 4 tem funcao definida e 3 deles tem EDHREC acima de 15%.

---

## Secao 5: CORRECAO DE FUNCTIONAL_TAGS DO BANCO

O banco de dados tem `functional_tag` frequentemente ERRADO. Tabela de correcoes:

| Carta | DB Tag | Funcao Real |
|:------|:-------|:------------|
| Boros Charm | removal | protection, pump |
| Monument to Endurance | ramp | draw, engine, loot |
| Weathered Wayfarer | ramp | ramp_setup (busca land para a mao, nao produz mana) |
| Land Tax | ramp | draw, ramp_setup (busca lands para a mao) |
| Dragon's Rage Channeler | graveyard_synergy | draw_engine (surveil = draw seletivo) |
| Library of Leng | graveyard_synergy | draw, hand_smoothing |
| Jeska's Will | ramp | ramp, ritual (correto, mas e ritual + exile, nao ramp permanente) |
| Deflecting Swat | big_spell | protection, redirect |
| Storm-Kiln Artist | big_spell | ramp_engine, treasure |
| The Dawning Archaic | big_spell | copy_engine |
| Victory Chimes | draw | draw_engine, ramp (untap = +3 mana por ciclo em commander) |
| Arcane Bombardment | spellslinger | copy_engine, recursion |
| Double Vision | spellslinger | copy_engine |
| Rite of the Dragoncaller | spellslinger | spellslinger_payoff, token_maker |
| Surge to Victory | recursion | recursion_wincon, pump |
| Improvisation Capstone | big_spell | exile_value, engine |
| Dance with Calamity | exile_value | exile_value, engine |
| Fated Clash | board_wipe | board_wipe (correto) |
| Olórin's Searing Light | graveyard_synergy | removal, graveyard_hate |
| Reforge the Soul | loot | draw, wheel |
| Faithless Looting | recursion | draw, loot, grave_setup |
| Lorehold, the Historian | draw | engine, copy, commander |
| Esper Sentinel | draw | draw, tax (correto) |
| Twinflame | token_maker | copy, combo_piece |

---

## Secao 6: GAPS E RECOMENDACOES

### GAP 1: Vulnerabilidade a Grave Hate (EIXO G = 6/10)
**Problema:** 3 respostas para Rest in Peace/Leyline of the Void em 100 cartas. Se nao encontrar resposta, 60% do deck desliga.
**Recomendacao:** Adicionar 1-2 respostas dedicadas a enchantments (Return to Dust, Wear // Tear, Rip Apart). Nenhuma disponivel na colecao atualmente.
**Prioridade:** Media. Em mesas casuais, grave hate e menos comum. Em competitive, e necessario.

### GAP 2: Zero Stack Interaction Ofensiva (EIXO F = 6/10)
**Problema:** Boros nao tem counterspells. O deck nao pode interromper combos dos oponentes.
**Recomendacao:** Aceitar como limitacao de cor. Compensar com remocao instant-speed (Path, Swords, Abrade, Chaos Warp) e wipes. Tibalt's Trickery e a unica "counterspell" em Boros mas e muito situacional.
**Prioridade:** Baixa. E intencional — o deck joga proativamente, nao reativamente.

### GAP 3: Colecao Esgotada para Swaps de Baixo CMC
**Problema:** 38+ candidatos avaliados em 3 ciclos. Nenhum atinge Necessidade >= 3 + Evidencia >= 3.
**Recomendacao:** Adquirir Skullclamp (CMC 1, $5-8), Wheel of Fortune (CMC 3, $200+ — caro), ou Deflecting Swat (ja no deck).
**Prioridade:** Skullclamp e a melhor aquisicao custo-beneficio.

---

## Secao 7: O PLANO DE JOGO — Turn by Turn

### Mao Ideal (Top 10%):
- T1: Land + Sol Ring → 3 manas T2
- T2: Land + Arcane Signet + Sensei's Divining Top → 4 manas T3, topdeck online
- T3: Land + Smothering Tithe → 5 manas T4, tithe gerando treasures
- T4: Land + Storm-Kiln Artist + Faithless Looting → treasure, grave enchendo
- T5: Land + Jeska's Will (8+ manas) → Dance with Calamity (Miracle 3 mana) → casta 5-8 spells gratis → board dominado
- T6: Mizzix's Mastery overload (8 mana) → casta 10+ spells do grave → VITORIA

### Mao Media (40%):
- T1: Land tapped, pass
- T2: Land + Signet → 3 manas T3
- T3: Land + Monument to Endurance / Victory Chimes / Wedding Ring → draw engine online
- T4: Land + Double Vision → copy engine online
- T5: Land + Lorehold (commander) → 6 manas T6
- T6: Land + Approach of the Second Sun → Approach castado, 7a posicao
- T7: Draw com topdeck engine (Top, Scroll Rack) ou esperar → Approach de novo → VITORIA T7-T8

### Mao Ruim (15% — Sem Play T3):
- T1: Land, pass
- T2: Land, pass (sem ramp T2)
- T3: Land, pass (sem spell CMC <= 3) → **Sem Play T3**
- T4: Land + Smothering Tithe → primeiro spell T4 (atrasado)
- Recuperacao: T5+ jogar catch-up com mana explosiva (Jeska's Will, treasures)
- **Risco:** 13.3% de chance de mao sem play T3. Com mulligan gratuito (3.7% free mulligan), ~17% de maos problematicas.

### Plano de Vitoria (ordem de prioridade):
1. **Approach T6-T8** — Plano A. Cast Approach, usar topdeck engine para draw rapido, cast de novo.
2. **Insurrection + Greaves T6-T8** — Plano B. Roubar criaturas, OTK.
3. **Surge to Victory + board T7-T9** — Plano B+. Dano massivo por combate.
4. **Storm Herd + Akroma's Will T8-T10** — Plano C. Tokens massivos + pump.
5. **Mizzix's Mastery overload T6-T8** — Pseudo-wincon. 10+ spells de graca.
6. **Flare + Approach (counterado) T7** — Combo reativo. Se Approach for counterado, Flare ganha no mesmo turno.

---

## Secao 8: CONFIRMACAO DE MATURIDADE

### Criterios de Maturidade — CHECKLIST:

| Criterio | Status | Evidencia |
|:---------|:------:|:----------|
| Nivel 1 vazio (0 cartas filler) | ✅ | 0 cartas com importancia 1 |
| Motor 4/4 completo | ✅ | Treasure Ramp + Free Big Spell + Copy + Payoff |
| 3+ ciclos com 0 swaps | ✅ | C#11, C#12, C#13 |
| 48+ candidatos rejeitados | ✅ | 38 C#11 + 6 C#12 + 4 C#13 |
| Colecao esgotada (CMC <= 3) | ✅ | 0 candidatos viaveis para DEFENSIVO |
| Sem Play T3 estavel (< 15%) | ✅ | 13.3% (Execucao #11) |
| 7 eixos de sinergia pontuando 6+ | ✅ | 6/6/8/9/9/6/6 = media 7.1 |
| Wincons multiplas e independentes | ✅ | 7 rotas de vitoria |
| Copy engines >= 4 | ✅ | 6 copy engines ativos |

**Conclusao:** MATURIDADE PERSISTENTE CONFIRMADA — 3a analise consecutiva (v3.11, v3.12, v3.13) confirmando maturidade. Proximo upgrade requer AQUISICAO de cartas.

---

## Secao 9: RECOMENDACOES DE AQUISICAO

| Prioridade | Carta | CMC | Funcao | Preco | Justificativa |
|:----------:|:------|:---:|:-------|:------|:--------------|
| 1 | **Skullclamp** | 1 | Draw engine | $5-8 | Melhor draw engine do formato. Equipa em token 1/1 → draw 2. Com Storm Herd = draw 80. |
| 2 | **Wheel of Fortune** | 3 | Wheel, draw | $200+ | Draw 7 por 3 mana. Enche grave. Melhor wheel do formato. |
| 3 | **Enlightened Tutor** | 1 | Tutor | — | JA NO DECK |
| 4 | **Gamble** | 1 | Tutor | — | JA NO DECK |
| 5 | **Return to Dust** | 4 | Enchantment/artifact removal | $1-2 | Resposta dedicada a Rest in Peace. Exila em vez de destruir. |
| 6 | **Wear // Tear** | 1/2 | Enchantment/artifact removal | $0.50 | Barato e versatil. Instant speed. |

---

## Secao 10: NOVIDADES v3.13

### O que mudou desde v3.12:
- **Nenhuma mudanca no deck.** Ciclo #14 (2026-05-31T21:18) confirmou 0 swaps — 4o ciclo consecutivo sem alteracoes.
- T3 mantido em 13.3% (Execucao #11).
- Colecao permanece esgotada.
- 48+ candidatos rejeitados acumulados em 4 ciclos.

### Confirmacoes:
- Maturidade Persistente (3+ ciclos) agora tem confianca ALTA.
- Abordagem de relatorio abreviada mantida — deck nao muda, analise foca em confirmacao de estado.
- SYNERGY_MAP mantem pontuacoes estaveis em todos os 7 eixos.
- Nenhum novo double-null surgiu — os 4 restantes sao estaveis e tem funcao definida.

### O que NAO mudou:
- Motor continua 4/4.
- Copy engines continuam 6.
- Wincons continuam 7.
- Nivel 1 continua vazio.

---

*Fim do VALIDATOR_LOG v3.13 — 2026-05-31T23:37:47+00:00*
*Proxima analise: v3.14 — confirmacao continuada de maturidade (salvo aquisicoes do usuario)*
