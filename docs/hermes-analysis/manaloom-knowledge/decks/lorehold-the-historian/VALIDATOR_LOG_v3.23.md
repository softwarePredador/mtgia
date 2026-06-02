# Purpose Analyzer v3.23 — 🚨 PIPELINE INTEGRITY CRISIS: Deck Completamente Reconstruido

> **Data:** 2026-06-02T18:42:51+00:00
> **Fonte:** knowledge.db deck_id=6 — ESTADO REAL DO DB
> **Card hash:** `f2241d994743e8142396c0f846917fde` — 🚨 DIVERGENTE do v3.22 (`30d00347...`)
> **Hash intermediario detectado:** `0b4913e79ec97b3ce05e0fe26531cd44` (76 rows, 98 cards)
> **Deck:** Lorehold — 100 cards, 100 rows, 33 lands, CMC medio ~2.15 (dados parciais)
> **Status:** 🚨 **PIPELINE INTEGRITY CRISIS** — Deck foi completamente reconstruido DUAS VEZES durante a janela de analise (2026-06-02 17:00-18:00 UTC)
> **EDHREC:** 7934 decks (+41 desde v3.22)
> **PostgreSQL:** Indisponivel (authentication failure). Perfil PG usado do prompt inline.
> **⚠️ Dados corrompidos:** 20 cartas com `functional_tag='unknown'`, 6 cartas com CMC=NULL, varias com CMC=0.0 incorreto. Classificador nao processou a importacao.

---

## Secao 0: PIPELINE INTEGRITY — CRISE SEM PRECEDENTES

### Timeline da Crise

| Timestamp (UTC) | Hash | Rows | Cards | Evento |
|:----------------|:-----|:----:|:-----:|:-------|
| 2026-06-01T20:52 | `30d00347...` | 86 | 100 | Estado v3.22 — spellslinger deck |
| 2026-06-02T17:XX | `0b4913e7...` | 76 | 98 | 🚨 BUILD cEDH — 25+ swaps revertidos, motor removido |
| 2026-06-02T18:XX | `f2241d99...` | 100 | 100 | 🚨 BUILD HIBRIDA — 38 cartas adicionadas, 14 removidas |

**Conclusao:** O deck foi alterado por forca externa (usuario ou outro agente) PELO MENOS DUAS VEZES nas ultimas horas. Nenhum agente do pipeline (Evolution Oracle, Scout) documentou ou aplicou estas mudancas — foi uma reconstrucao manual.

### O Que Mudou da Build Spellslinger (v3.22) para a Atual

**REMOVIDOS (todos os 25+ swaps dos ciclos #1-#11):**
- Double Vision, Arcane Bombardment, The Dawning Archaic, Improvisation Capstone, Restoration Seminar
- Dance with Calamity, Big Score, Brass's Bounty, Hit the Mother Lode
- Penance, Hexing Squelcher, Primal Amulet, Volcanic Vision, Call Forth the Tempest
- Boros Charm (removido, depois re-adicionado)
- Demand Answers, Thrill of Possibility
- E muitas outras cartas do spellslinger engine

**ADICIONADOS (nova build):**
- Fast mana: Mana Crypt, Mana Vault, Lotus Petal, Mox Amber, Chrome Mox, Mox Diamond, Rite of Flame, Seething Song, Simian Spirit Guide
- Tutores extras: Imperial Recruiter, Recruiter of the Guard, Ranger-Captain of Eos, Land Tax, Urza's Saga, Mystical Tutor
- Protection suite: Orim's Chant, Silence, Pyroblast, Red Elemental Blast, Flawless Maneuver, Deflecting Swat, Giver of Runes, Boros Charm, Lightning Greaves
- cEDH staples: Drannith Magistrate, Aetherflux Reservoir, Birgi God of Storytelling, The One Ring
- Copy/Combo: Heat Shimmer, Electroduplicate, Molten Duplication, Reiterate, Reverberate, Past in Flames
- Wincons readicionados: Approach of the Second Sun, Mizzix's Mastery, Worldfire, Guttersnipe, Rite of the Dragoncaller, Fiery Emancipation
- Mana/Value: Mana Geyser, Unexpected Windfall, Victory Chimes, Ruby Medallion, Monument to Endurance
- Lands extras: Ancient Den, Great Furnace, Mana Confluence, Inspiring Vantage, Needleverge Pathway, Prismatic Vista, Sunbillow Verge, War Room, Hall of Heliod's Generosity, Inventors' Fair

### ⚠️ Corrupcao de Dados Detectada na Importacao

A importacao em massa do deck produziu dados inconsistentes:

| Problema | Afetados | Impacto |
|:---------|:--------:|:--------|
| `functional_tag='unknown'` | 20 cartas | Classificador cego para estas cartas |
| `CMC=NULL` | 6 cartas | Curva de mana subestimada |
| `CMC=0.0` incorreto | 14+ cartas | Boros Signet, Mana Vault, Sol Ring etc com CMC 0 |
| `type_line=NULL` | 5 cartas | Aetherflux, Electroduplicate, Fiery Emancipation, Heat Shimmer, Past in Flames |

**Cartas com CMC real conhecido mas registrado como 0.0 no DB:**

| Carta | CMC Real | CMC DB |
|:------|:--------:|:------:|
| Sol Ring | 1 | 0.0 |
| Mana Vault | 1 | 0.0 |
| Boros Signet | 2 | 0.0 |
| Talisman of Conviction | 2 | 0.0 |
| Ruby Medallion | 2 | 0.0 |
| Scroll Rack | 2 | 0.0 |
| Lightning Greaves | 2 | 0.0 |
| Orim's Chant | 1 | 0.0 |
| Pyroblast | 1 | 0.0 |
| Birgi, God of Storytelling | 3 | 0.0 |
| Boros Charm | 2 | 0.0 |
| Flawless Maneuver | 3 | 0.0 |
| Reforge the Soul | 5 | 0.0 |
| Reverberate | 2 | 0.0 |
| Valakut Awakening | 3 | 0.0 |
| Victory Chimes | 3 | 0.0 |

**Cartas com CMC=None (mais grave):**
- Aetherflux Reservoir (CMC real: 4)
- Electroduplicate (CMC real: 3)
- Fiery Emancipation (CMC real: 6)
- Heat Shimmer (CMC real: 3)
- Past in Flames (CMC real: 4)
- Reiterate (CMC real: 3)

**Impacto na analise:** A CMC media reportada (2.15) e SUBESTIMADA. Com CMCs corrigidos, a CMC real do deck deve estar proxima de ~2.8-3.0. O "Sem Play T3" calculado com dados corrompidos sera artificialmente baixo.

---

## Secao 1: COMPARACAO PG — Deck vs Perfil Ideal

> **Fonte:** PG `commander_reference_deck_analysis` para Lorehold, the Historian.
> **Nota:** PostgreSQL indisponivel. Perfil PG usado do prompt do cron.
> **⚠️ AVISO:** Esta build e um ARQUETIPO DIFERENTE (turbo-combo cEDH) do perfil PG (spellslinger big-spells). A comparacao PG e util para entender o desvio, mas NAO deve ser usada como validacao.

### PG Ideal Profile vs Deck Atual (com correcoes manuais de CMC)

| Metrica PG | PG Ideal | Deck Atual (estimado) | Diff | Status |
|:-----------|:--------:|:---------------------:|:----:|:------:|
| lands | 32 | 33 | +1 | ✅ OK |
| ramp | 3.67 | ~12 (rocks + fast mana + rituals) | +8.33 | 🔴 FAR ABOVE — cEDH fast mana package |
| ritual_treasure | 10 | ~6 (Jeska's, Seething Song, Rite of Flame, Mana Geyser, Smothering Tithe, Unexpected Windfall) | -4 | 🔵 ABAIXO |
| big_spell_payoff | 7.67 | ~10 (Rise, Storm Herd, Worldfire, Mizzix, Approach, Fiery, Rite of Dragoncaller, Aetherflux, Guttersnipe, Mana Geyser) | +2.33 | 🟡 ACIMA |
| miracle_topdeck | 4.33 | ~3 (Scroll Rack, Top, Valakut Awakening) | -1.33 | 🔵 ABAIXO |
| interaction (removal) | 5.33 | 3 (Path, Swords, Generous Gift) | -2.33 | 🔵 ABAIXO — apenas 3 remocoes! |
| protection | 3.67 | ~10 (Mom, Giver, Teferi, Orim, Silence, Abolisher, Swat, Flawless, Greaves, Pyro/REB) | +6.33 | 🔴 FAR ABOVE |
| draw_value | 2.67 | ~8 (Esper, Faithless, Wheel, One Ring, Top, Scroll Rack, Monument, Unexpected Windfall) | +5.33 | 🔴 FAR ABOVE |
| tutor | 3.67 | 6 (Enlightened, Gamble, Imperial, Recruiter, Ranger-Captain, Land Tax) | +2.33 | 🟡 ACIMA |
| win_condition | 1.33 | 11 | +9.67 | 🔴 FAR ABOVE — excesso de wincons |

### Analise de Desvios

**🔴 Protecao (+6.33):** 10 slots de protecao. Inclui Silence e Orim's Chant (protecao de turno), Pyroblast/REB (anti-blue), Mother + Giver of Runes (protecao pontual), Teferi's Protection (mass protection), Deflecting Swat (redirect), Flawless Maneuver (indestructible), Lightning Greaves (haste + shroud), Grand Abolisher (protecao passiva). Em build cEDH, protecao para o combo e essencial — mas 10 slots ainda e alto.

**🔵 Remocao (-2.33):** Apenas Path to Exile, Swords to Plowshares, e Generous Gift. 3 remocoes e MUITO POUCO para Commander. Chaos Warp foi removido na transicao da build intermedia para a final. **GAP CRITICO:** O deck nao consegue responder a permanentes problematicas consistentemente.

**🔴 Wincons (+9.67):** 11 wincons e excessivo. O deck tem:
- Combo deterministico: Dualcaster + Twinflame (ou Heat Shimmer, Molten Duplication)
- Wincons standalone: Approach, Worldfire, Rise, Storm Herd, Fiery Emancipation
- Wincons value: Guttersnipe, Aetherflux, Rite of the Dragoncaller
- Enablers: Mizzix's Mastery, Past in Flames, Reiterate, Reverberate
Com 6 tutores, 3-4 wincons seriam suficientes. 11 e overkill e ocupa slots que poderiam ser remocao ou ramp.

---

## Secao 2: CLASSIFICACAO ESTRATEGICA (Nivel 1-5)

> **Nota:** 20 cartas com `functional_tag='unknown'` foram classificadas manualmente.
> CMCs foram corrigidos manualmente onde o DB tem valores incorretos (0.0 ou NULL).
> Cartas marcadas com `†` tem CMC corrigido na tabela.

### Nivel 5 — Essenciais (deck nao funciona sem)

| Carta | CMC (real) | Funcao Real | EDHREC | Trend | Nota |
|:------|:----------:|:------------|:------:|:-----:|:-----|
| Lorehold, the Historian | 5 | Commander, copy engine | N/A | N/A | Unico copy engine no deck |
| Dualcaster Mage | 3 | Combo piece | 21.1% | — | Combo com Twinflame/Heat Shimmer |
| Twinflame | 2† | Combo piece | 8.0% | -0.66 | Combo deterministico |

### Nivel 4 — Core Engine

| Carta | CMC (real) | Funcao Real | EDHREC | Trend | Nota |
|:------|:----------:|:------------|:------:|:-----:|:-----|
| Approach of the Second Sun | 7 | Wincon primario | 53.8% | — | Re-adicionado; arqui-inimigo |
| Mizzix's Mastery | 4 | Mass flashback | 56.1% | — | Re-adicionado; wincon-enabler |
| Worldfire | 9 | Wincon reset total | 35.0% | — | Re-adicionado; combo com Teferi |
| Past in Flames | 4† | Flashback engine | 18.0% | — | Re-adicionado; recursion |
| Storm-Kiln Artist | 4 | Treasure payoff | 55.4% | — | Re-adicionado; fecha motor |
| Scroll Rack | 2† | Topdeck engine | 59.4% | +0.41 | Core; double-null corrigido |
| Sensei's Divining Top | 1 | Topdeck engine | 66.6% | +0.57 | Core |
| Esper Sentinel | 1 | Draw condicional | 32.3% | **-0.67** | Declinio 7+ ciclos |

### Nivel 3 — Suporte Forte

| Carta | CMC (real) | Funcao Real | EDHREC | Trend | Nota |
|:------|:----------:|:------------|:------:|:-----:|:-----|
| Enlightened Tutor | 1 | Tutor | 30.0% | — | Busca artifact/enchantment |
| Gamble | 1 | Tutor | 25.0% | — | Busca qualquer; risco descarte |
| Imperial Recruiter | 3 | Tutor (power≤2) | 0% | — | Busca Dualcaster, DRC, Mom |
| Ranger-Captain of Eos | 3 | Tutor + Silence | 0% | — | Busca CMC≤1 + fog de spell |
| Recruiter of the Guard | 3 | Tutor (toughness≤2) | 0% | — | Busca Giver, Mom, Magistrate |
| Drannith Magistrate | 2 | Stax | 15.0% | — | Lock de commander |
| Smothering Tithe | 4 | Treasure ramp | 29.4% | +0.04 | Motor de mana |
| Jeska's Will | 3 | Ritual + impulsedraw | 30.4% | +0.40 | Ritual explosivo |
| Teferi's Protection | 3 | Mass protection | 21.1% | 0.00 | Fog + phase out |
| Grand Abolisher | 2† | Protecao passiva | 11.7% | **-0.33** | Declinio 3+ ciclos |

### Nivel 2 — Suporte Situacional

| Carta | CMC (real) | Funcao Real | EDHREC | Trend | Nota |
|:------|:----------:|:------------|:------:|:-----:|:-----|
| Guttersnipe | 3 | Wincon invisivel | 19.0% | — | 2 dano/spell; fragil |
| Rite of the Dragoncaller | 6 | Wincon dragons | 25.0% | — | Dragons por spell |
| Aetherflux Reservoir | 4† | Wincon storm | 15.0% | — | Storm payoff |
| Fiery Emancipation | 6† | Damage tripler | 18.0% | — | Amplifica Storm Herd/Guttersnipe |
| Rise of the Eldrazi | 10 | Wincon aniquilador | 54.4% | **-0.77** | Declinio detectado |
| Storm Herd | 10 | Wincon pegasus | 75.0% | +1.19 | Alta inclusao, trend positivo |
| Boros Charm | 2† | Protecao + pump | 30.0% | — | Double strike + indestructible |
| Mana Geyser | 5 | Ritual massivo | 20.0% | — | Escala com oponentes |
| Unexpected Windfall | 4 | Treasure + draw | 18.0% | — | Instant-speed value |
| Victory Chimes | 3† | Mana + draw | 53.6% | 0.00 | Untap cada turno |
| Ruby Medallion | 2† | Cost reduction | 25.1% | **-0.61** | Declinio persistente |
| Monument to Endurance | 3 | Draw + loot | 15.0% | — | Value engine |
| Birgi, God of Storytelling | 3† | Mana + impulsedraw | 15.0% | — | Ritual engine |
| Reforge the Soul | 5† | Wheel massivo | 10.0% | — | Miracle cost |
| Valakut Awakening | 3† | Wheel seletivo | 10.0% | — | MDFC land |
| Land Tax | 1 | Land tutor | 10.0% | — | Land advantage |

### Nivel 1 — Substitutivel

| Carta | CMC (real) | Funcao Real | EDHREC | Trend | Nota |
|:------|:----------:|:------------|:------:|:-----:|:-----|
| Reiterate | 3† | Copy spell | 17.8% | -0.66 | Reverberate clone; custo buyback alto |
| Reverberate | 2† | Copy spell | 17.8% | -0.66 | Declinio; Fork effect |
| Heat Shimmer | 3† | Copy creature | 5.0% | — | Combo com Dualcaster |
| Electroduplicate | 3† | Copy creature | 5.0% | — | Flashback copy |
| Molten Duplication | 2 | Copy artifact/creature | 5.0% | — | Versatil mas niche |
| Seething Song | 3 | Ritual | 15.0% | — | RRRRR por 2R |
| Rite of Flame | 1 | Ritual | 10.0% | — | R por R; escala mal |
| Lotus Petal | 0 | Fast mana | 0% | — | One-shot |
| Mana Crypt | 0† | Fast mana | 0% | — | Game Changer; cEDH staple |
| Mana Vault | 1† | Fast mana | 5.8% | 0.00 | Game Changer |
| Mox Amber | 0 | Fast mana | 0% | — | Legendary-dependente |
| Simian Spirit Guide | 0† | Fast mana | 0% | — | One-shot R |
| Orim's Chant | 1† | Protecao turno | 0% | — | Silence clone |
| Silence | 1† | Protecao turno | 6.5% | -0.66 | Declinio |
| Pyroblast | 1† | Anti-blue | 0% | — | Meta-specifico |
| Giver of Runes | 1 | Protecao pontual | 5.0% | — | Mother of Runes #2 |

---

## Secao 3: SYNERGY_MAP — 7 Eixos (Nova Build)

> **Nota:** O SYNERGY_MAP foi completamente reescrito para refletir a nova build hibrida.
> O motor spellslinger anterior (Treasure → Big Spell → Copy → Payoff) NAO EXISTE MAIS.
> A nova build opera em dois modos: (1) turbo-combo via tutor, (2) big spell via mana ritual.

### A) Token Makers + Pump — Score: 5/10
- **Token makers:** Storm Herd (pegasus X vida), Rite of the Dragoncaller (dragons por spell), Smothering Tithe (treasures), Unexpected Windfall (treasures), Monastery Mentor removido
- **Pump:** Boros Charm (double strike), Akroma's Will removido!
- **Forca:** Storm Herd com Fiery Emancipation = dano massivo
- **Fraqueza:** **Sem Akroma's Will** — os tokens nao tem haste. Storm Herd sem Akroma's Will precisa esperar um turno. Rite of the Dragoncaller tambem.
- **GAP:** Akroma's Will foi removido na build final! Estava presente na build intermedia mas foi cortado na importacao final.

### B) Board Wipes + Protection — Score: 7/10
- **Wipes:** Blasphemous Act (CMC 9, convoke → CMC ~1-3), Worldfire (reset total)
- **Protection:** 10 cartas (Mom, Giver, Teferi, Grand Abolisher, Orim, Silence, Swat, Flawless, Greaves, Boros Charm)
- **Assimetria:** Worldfire + Teferi's Protection = vitoria assimetrica. Blasphemous Act + Teferi = wipe unilateral.
- **Ratio:** 2 wipes : 10 protection = 1:5. Extremamente protegido.
- **Fraqueza:** Apenas 2 board wipes. Em meta com muitos creatures, pode ser insuficiente.

### C) Recursion Chains — Score: 8/10
- **Mizzix's Mastery:** Overload flashback de TODAS instants/sorceries do cemiterio. Com Past in Flames = double recursion.
- **Past in Flames:** Flashback para todas instants/sorceries. Com Mizzix = casta tudo 2x.
- **Recursion loop:** Faithless Looting (draw + discard) → Mizzix's Mastery overload → tudo do grave. Wheel of Fortune → Past in Flames → Wheel again.
- **Unexpected Windfall:** Instant-speed, gera treasures + draw. Com Mizzix/Past, gera treasures repetidos.
- **Forca:** Recursion massiva em vermelho e raro. Este eixo e forte.

### D) Explosive Mana — Score: 8/10
- **Fast mana (one-shot):** Lotus Petal, Mana Crypt, Mana Vault, Mox Amber, Simian Spirit Guide, Rite of Flame, Seething Song
- **Rituals:** Jeska's Will, Mana Geyser, Seething Song, Rite of Flame
- **Sustained:** Smothering Tithe, Storm-Kiln Artist, Birgi, Ruby Medallion, Victory Chimes
- **Mana sinks:** Combo pieces, Approach (14 mana total), Rise of the Eldrazi (10), Storm Herd (10), Fiery Emancipation (6)
- **Sequencia ideal T1:** Land → Mana Crypt → Sol Ring → Arcane Signet → 5 mana T1. Turn 2: Commander (Lorehold) ja em jogo.
- **Forca:** Fast mana package de nivel cEDH.
- **Fraqueza:** Muitos one-shots. Se o combo falhar, a mana acaba.

### E) Combo Pieces — Score: 9/10
- **Combo A (deterministico):** Dualcaster Mage + Twinflame → criaturas infinitas com haste
- **Combo B (deterministico):** Dualcaster Mage + Heat Shimmer → criaturas infinitas com haste
- **Combo C (semi-deterministico):** Approach of the Second Sun + Mystical Tutor/Enlightened Tutor → 2 casts para vitoria
- **Combo D (reset):** Worldfire + Teferi's Protection (ou Boros Charm) → todos com 1 vida exceto voce
- **Combo E (storm):** Reiterate + Jeska's Will/Seething Song → mana infinita com buyback → Aetherflux Reservoir
- **Tutores para combo:** Enlightened Tutor (Twinflame, Reservoir), Mystical Tutor (Heat Shimmer, Seething Song), Gamble (qualquer), Imperial Recruiter (Dualcaster), Recruiter of the Guard (Dualcaster)
- **Forca:** Multiplos combos deterministicos. Dificil de parar todos.
- **Fraqueza:** Dualcaster e fragil (2 toughness, morre pra qualquer coisa). Precisa de protecao para resolver o combo.

### F) Stack Interaction — Score: 5/10
- **Counterspells:** Nenhum! Boros nao tem counterspell tradicional.
- **Stack protection:** Silence, Orim's Chant (fog de spell), Grand Abolisher (passivo), Pyroblast/REB (anti-blue), Deflecting Swat (redirect), Flawless Maneuver (protecao de remocao)
- **Stack tricks:** Reiterate (copy na stack), Reverberate (copy na stack), Boros Charm (indestructible na stack)
- **Forca:** Tem protecao para o proprio combo na stack.
- **Fraqueza:** Nao pode interagir com spells dos oponentes (sem counters). Depende de Silence/Orim para "fog" de spell no proprio turno.

### G) Resilience — Score: 6/10
- **Recursion:** Past in Flames, Mizzix's Mastery, Valakut Awakening, Faithless Looting
- **Protection de board:** Teferi's Protection, Boros Charm, Flawless Maneuver
- **Recovery de wipe:** Mizzix's Mastery overload = recupera TUDO do grave. Melhor recovery do deck.
- **Fraqueza:** Se o combo falhar e as pecas forem exiladas (nao destruidas), nao ha recovery. Sem Riftsweeper ou Pull from Eternity.

---

## Secao 4: DOUBLE-NULL AUDIT

> **Estado:** 20 cartas com `functional_tag='unknown'` e zero multi-tags. Todas importadas sem classificacao.

| Carta | CMC Real | Funcao Real | Risco | Nota |
|:------|:--------:|:------------|:-----:|:-----|
| Sol Ring | 1 | Ramp | 🔴 | Game Changer. Classificador deveria detectar. |
| Mana Vault | 1 | Ramp | 🔴 | Game Changer. CMC incorreto no DB (0.0). |
| Boros Signet | 2 | Ramp | 🟡 | Classificador deveria detectar. |
| Talisman of Conviction | 2 | Ramp | 🟡 | Classificador deveria detectar. |
| Scroll Rack | 2 | Draw/Engine | 🔴 | Core engine. Classificador cego cronico. |
| Lightning Greaves | 2 | Protection | 🟡 | Equipamento classico. |
| Ruby Medallion | 2 | Cost reduction | 🟡 | Declinio em Lorehold. |
| Orim's Chant | 1 | Protection | 🟡 | Silence clone. |
| Silence | 1 | Protection | 🟡 | Protecao de turno. |
| Pyroblast | 1 | Protection | 🟡 | Anti-blue. |
| Boros Charm | 2 | Protection | 🟡 | Double strike + indestructible. |
| Flawless Maneuver | 3 | Protection | 🟡 | Indestructible gratuito. |
| Birgi, God of Storytelling | 3 | Ramp/Engine | 🟡 | Ritual engine. |
| Victory Chimes | 3 | Ramp/Draw | 🟡 | 53.6% EDHREC! |
| Valakut Awakening | 3 | Draw | 🟡 | MDFC wheel. |
| Reforge the Soul | 5 | Draw/Wheel | 🟡 | Miracle. |
| Reverberate | 2 | Copy/Combo | 🟢 | Fork effect. |
| Heat Shimmer | 3 | Copy/Combo | 🟢 | Combo com Dualcaster. |
| Electroduplicate | 3 | Copy/Combo | 🟢 | Flashback copy. |
| Past in Flames | 4 | Recursion/Engine | 🔴 | Core recursion! Classificador deveria detectar. |

**Acoes recomendadas:** Re-executar o classificador (`scryfall_classifier.infer_functional_card_tags()`) em TODAS as 20 cartas. A importacao em massa nao processou a classificacao.

---

## Secao 5: COMPARACAO EDHREC — Alinhamento com o Meta

> **Fonte:** EDHREC JSON API (7934 decks, 2026-06-02)

### Cartas do Deck com Alta Inclusao EDHREC (>50%) — Bem Alinhadas

| Carta | EDHREC | Trend |
|:------|:------:|:-----:|
| Sol Ring | 90.5% | 0.00 |
| Command Tower | 88.2% | 0.00 |
| Arcane Signet | 88.1% | 0.00 |
| Library of Leng | 77.7% | +1.54 |
| Clifftop Retreat | 75.5% | 0.00 |
| Storm Herd | 75.0% | +1.19 |
| Swords to Plowshares | 69.1% | +1.28 |
| Sacred Foundry | 66.9% | 0.00 |
| Sensei's Divining Top | 66.6% | +0.57 |
| Scroll Rack | 59.4% | +0.41 |
| Path to Exile | 57.5% | +0.98 |
| Victory Chimes | 53.6% | 0.00 |

### Cartas do Deck com Baixa Inclusao EDHREC (<10%) — cEDH Staples (Nao Alinhadas com o Meta Casual)

| Carta | EDHREC | Trend | Por Que Esta Aqui |
|:------|:------:|:-----:|:------------------|
| Lotus Petal | 0% | — | cEDH fast mana |
| Mana Crypt | 0% | — | cEDH fast mana; Game Changer |
| Simian Spirit Guide | 0% | — | cEDH fast mana |
| Mox Amber | 0% | — | cEDH fast mana |
| Orim's Chant | 0% | — | cEDH protection |
| Pyroblast | 0% | — | cEDH anti-blue |
| Imperial Recruiter | 0% | — | cEDH tutor |
| Recruiter of the Guard | 0% | — | cEDH tutor |
| Ranger-Captain of Eos | 0% | — | cEDH tutor + Silence |
| Mana Vault | 5.8% | 0.00 | cEDH fast mana; Game Changer |
| Silence | 6.5% | -0.66 | cEDH protection |
| Heat Shimmer | 5.0% | — | Combo com Dualcaster |
| Electroduplicate | 5.0% | — | Combo com Dualcaster |
| Molten Duplication | 5.0% | — | Copy versatil |
| Ragavan | 7.2% | -0.51 | cEDH value (removido na build final) |

**Conclusao:** 15+ cartas tem <10% EDHREC porque sao staples cEDH que a comunidade casual do Lorehold nao joga. O EDHREC medio do Lorehold e ~2.0 (casual), enquanto esta build e cEDH (~4.0-5.0). O desalinhamento e esperado e NAO e um problema — e intencional.

### Rising Stars (EDHREC >15%, trend >3.0) — Nao Presentes no Deck

| Carta | EDHREC | Trend | Esta na Colecao? |
|:------|:------:|:-----:|:----------------:|
| Restoration Seminar | 38.1% | **+9.30** | ✅ Sim |
| Improvisation Capstone | 49.3% | **+7.88** | ✅ Sim |
| The Dawning Archaic | 24.2% | **+5.31** | ✅ Sim |

**Nota:** Estas cartas sao do motor spellslinger que foi removido. Na build atual (turbo-combo), estas cartas nao se encaixam.

### Declining Cards no Deck (EDHREC >15%, trend < -0.3)

| Carta | EDHREC | Trend | Risco |
|:------|:------:|:-----:|:-----:|
| Esper Sentinel | 32.3% | **-0.67** | 🟡 Monitorar — 7+ ciclos de declinio |
| Grand Abolisher | 11.7% | **-0.33** | 🟡 Monitorar — ja e marginal |
| Ruby Medallion | 25.1% | **-0.61** | 🟡 5+ ciclos de declinio |
| Reverberate | 17.8% | **-0.66** | 🟢 Nivel 1 — substituivel |
| Rise of the Eldrazi | 54.4% | **-0.77** | 🟡 54% ainda e alto, mas trend negativo |

---

## Secao 6: GAPS & RECOMENDACOES

### 🔴 GAP CRITICO: Apenas 3 Remocoes

O deck tem Path to Exile, Swords to Plowshares, e Generous Gift. 3 remocoes em 99 cartas e EXTREMAMENTE POUCO. Em Commander, precisa-se de 5-8 remocoes para responder a ameacas.

**Solucao na colecao (verificar):** Chaos Warp (estava na build intermedia, removido na final), Abrade, Wear // Tear.

### 🟡 GAP: Akroma's Will Ausente

A build intermedia (hash `0b4913e7...`) tinha Akroma's Will, mas foi removido na build final. Sem Akroma's Will:
- Storm Herd gera pegasus sem haste (precisa esperar 1 turno)
- Rite of the Dragoncaller gera dragons sem haste
- Unico pump e Boros Charm (double strike apenas)

**Solucao:** Re-adicionar Akroma's Will. Esta na colecao e e critical para o plano de tokens.

### 🟡 GAP: Faltam Lands Basicas

Apenas 2 basic lands (1 Mountain + 1 Plains). Com 33 lands totais, isso significa 31 nonbasics. Em meta com Blood Moon ou Back to Basics, o deck e completamente anulado. Alem disso, path to exile e field of ruin dos oponentes nao te dao fetch de basic.

**Recomendacao:** Aumentar para 5-6 basics. Trocar algumas nonbasics redundantes (Ex: Needleverge Pathway por 1 Mountain, Sunbillow Verge por 1 Plains).

### 🟡 GAP: Excesso de Copy Spells

O deck tem 5 copy spells (Twinflame, Heat Shimmer, Electroduplicate, Molten Duplication, Reiterate, Reverberate) + o commander que copia. 6 fontes de copy e excessivo — 3-4 seriam suficientes.

**Candidatos para corte:** Electroduplicate (CMC 3, flashback util mas lento), Reverberate (CMC 2, Fork effect simples).

### 🟢 RECOMENDACAO: Corrigir Dados do DB

20 cartas com `functional_tag='unknown'` e CMCs incorretos. Re-executar:
```python
from scryfall_classifier import infer_functional_card_tags
# Para cada carta com tag='unknown', buscar oracle_text e re-classificar
```

---

## Secao 7: O PLANO DE JOGO — Turn by Turn (Build Atual)

### Mao Ideal (T1-T4)
- **T1:** Land → Mana Crypt → Sol Ring → Arcane Signet → (5 mana T1)
- **T2:** Land → Commander (Lorehold, 5 mana) → ativa T3
- **T3:** Silence/Orim's Chant (protecao) → Enlightened Tutor (Twinflame) → Dualcaster → Twinflame → **VITORIA**
- **T4:** N/A (jogo acabou T3)

### Mao Media (T1-T6)
- **T1:** Land → Sol Ring → pass
- **T2:** Land → Arcane Signet → pass
- **T3:** Land → Commander (Lorehold)
- **T4:** Land → Storm-Kiln Artist → Wheel of Fortune (draw 7, gera treasure)
- **T5:** Land → Guttersnipe → Faithless Looting (2 dano) → Past in Flames flashback
- **T6:** Ritual massivo (Jeska's + Seething Song) → Approach → Mystical Tutor → Approach → **VITORIA**

### Mao Pobre (T1-T8+)
- **T1-T3:** Land drops, sem ramp
- **T4:** Smothering Tithe → oponentes draw → treasures
- **T5:** Commander (Lorehold)
- **T6-T7:** Acumular treasures + controlar board com Path/Swords
- **T8+:** Worldfire + Teferi's Protection → **VITORIA**

---

## Secao 8: RESUMO EXECUTIVO

### Metricas Corrigidas (Estimadas)

| Metrica | Valor DB | Valor Corrigido | PG Ideal |
|:--------|:--------:|:---------------:|:--------:|
| Lands | 33 | 33 | 32 |
| Ramp | 6 | ~12 | 3.67 |
| Draw | 6 | ~8 | 2.67 |
| Removal | 3 | 3 | 5.33 |
| Tutor | 6 | 6 | 3.67 |
| Board Wipe | 1 | 2 | — |
| Protection | 4 | ~10 | 3.67 |
| Wincon | 11 | 11 | 1.33 |
| Avg CMC | 2.15 | ~2.9 | — |

### Status do Deck

| Componente | Status | Nota |
|:-----------|:------:|:-----|
| Pipeline Integrity | 🔴 CRISE | Deck mudou 2x em 1h |
| Motor spellslinger | ⚫ DESTRUIDO | 0/4 componentes |
| Motor turbo-combo | ✅ COMPLETO | Tutor + combo + protecao |
| Remocao | 🔴 3 apenas | MUITO POUCO |
| Protecao | ✅ Robusta | 10 slots = seguro para combo |
| Wincons | 🟡 Excesso | 11 wincons; reduzir para 5-7 |
| Fast mana | ✅ cEDH nivel | Crypt, Vault, Mox, Petal, Rituals |
| Dados DB | 🔴 CORROMPIDOS | 20 cartas sem tag; CMCs errados |
| Basics | 🔴 2 apenas | Vulneravel a Blood Moon |

### Recomendacoes Prioritarias

1. **CORRIGIR DADOS DO DB** — Re-classificar 20 cartas com `infer_functional_card_tags()`. Corrigir CMCs (6 NULL, 14+ incorretos).
2. **ADICIONAR REMOCAO** — Chaos Warp + 1-2 remocoes adicionais. O deck tem apenas 3.
3. **RE-ADICIONAR AKROMA'S WILL** — Foi removido na build final. Essencial para tokens.
4. **AUMENTAR BASICS** — 2 → 5-6 basics. Trocar nonbasics redundantes.
5. **REDUZIR COPY SPELLS** — 6 copy effects e excessivo. Cortar Electroduplicate e Reverberate.
6. **EXECUTAR MULLIGAN SIMULATION** — Com dados corrigidos, rodar N=1000 para medir T3 real.
7. **EXECUTAR BATTLE ANALYST** — Testar matchup contra meta atual.

### Nota para o Evolution Oracle

Esta build e uma RECONSTRUCAO TOTAL. Todos os logs anteriores (EVOLUTION_LOG C#1-C#23, VALIDATOR_LOG v3.0-v3.22, MULLIGAN_LOG Exec#1-#13) referem-se a um deck que NAO EXISTE MAIS.

O Evolution Oracle deve:
1. Resetar o contador de ciclos (C#24 = Ciclo #1 da nova build)
2. Reconstruir EVOLUTION_LOG do zero para esta build
3. Re-executar Mulligan Tester com deck corrigido (CMCs certos, tags corrigidas)
4. Nao tentar aplicar swaps do pipeline antigo

---

> **Hash final:** `f2241d994743e8142396c0f846917fde`
> **Hash anterior (v3.22):** `30d00347764fc2a215edb4e668994871` — DIVERGENTE
> **Hash intermedio:** `0b4913e79ec97b3ce05e0fe26531cd44` — descartado
> **Versao:** v3.23 — Pipeline Integrity Crisis
> **Proxima versao:** v3.24 — Apos correcao de dados do DB e mulligan simulation
