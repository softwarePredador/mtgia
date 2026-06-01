# MTG Rules Compliance Audit — All Crons v3.1 (2026-06-01, re-auditado)

**Data da Auditoria:** 2026-06-01T17:45:00+00:00
**Versao:** v3.1 (re-auditoria com inspecao de prompts e outputs REAIS)
**Escopo:** 5 crons do pipeline Lorehold (Scout, Validator, Mulligan, Battle, Evolution Oracle)
**Fontes Oficiais Consultadas:**
- Scryfall API: Commander banlist (83 cartas banidas, ultima atualizacao com Nadu, Winged Wisdom)
- MTG Comprehensive Rules: CR 103 (Starting the Game), CR 117 (Timing and Priority), CR 405 (Lands), CR 702.94 (Miracle), CR 704 (State-Based Actions), CR 903 (Commander)
- London Mulligan: CR 103.4 (multiplayer Commander free first mulligan)
- Codigo real inspecionado: `server/lib/ai/battle_simulator.dart` (879 linhas)
- Outputs reais de cron: ultimos 5 dias de cada agent

---

## Sumario Executivo

| Cron | Nota | Confiabilidade | Gaps Criticos | Mudanca vs v1 |
|:-----|:----:|:--------------|:---------------|:--------------|
| Scout | **3.5/10** | 🔴 BAIXA | Prompt desalinhado, 94% [SILENT], sem verificacao de banlist | **-4.5** (era 8.0) |
| Validator | **6.0/10** | ⚠️ MEDIA | Prompt referencia tabela inexistente, sem verificacao de banlist | **-2.5** (era 8.5) |
| Mulligan | **5.0/10** | ⚠️ MEDIA | Sem tapped lands, sem color screw, T1 ramp ausente do prompt | **-2.5** (era 7.5) |
| Battle | **N/A** | ⚪ NAO E CRON | Diretorio de output nao existe, codigo e prototipo 2-player | **N/A** (era 6.5) |
| Oracle | **4.0/10** | 🔴 BAIXA | Perdeu sintese multi-agente, so verifica wincon diversity | **-3.5** (era 7.5) |
| **PIPELINE** | **4.6/10** | 🔴 **BAIXA** | 4/5 agentes nao verificam banlist, 2/5 com prompt errado | **-3.0** (era 7.6) |

### Correcoes Criticas da Auditoria v1

A auditoria v1 (2026-06-01 manha) continha **3 erros factuais** descobertos ao inspecionar o codigo Dart real:

| Afirmacao v1 | Correcao v3.1 | Evidencia |
|:-------------|:--------------|:----------|
| "Battle Analyst v8 tem cap de lifelink em 40" | **FALSO.** `active.life += lifeGained` sem `min()` | `battle_simulator.dart:516-519` |
| "Battle Analyst sem trample" | **FALSO.** `attacker.hasTrample` implementado | `battle_simulator.dart:497-499` |
| "Battle Analyst 6.5/10, MEDIA confiabilidade" | **Nao e cron.** Diretorio `/opt/data/cron/output/94f8590b1beb/` nao existe | `ls` no path: "Path not found" |
| "Scout 8.0/10, ALTA confiabilidade" | **3.5/10.** Prompt e "Wincon Hunter" — nao faz scout de sinergia | Outputs reais sao [SILENT], prompt so busca `card_deck_analysis` |

---

## Scout — Auditoria Detalhada (f20ac299992b)

### Prompt Atual (jobs.json)
```
## Lorehold Scout — Busque Wincons com Pontuacao
SCORING DE WINCONS (card_deck_analysis):
- speed_score (1-10), resilience_score (1-10), stealth_score (1-10)
- wincon_total_score: speed + resilience + stealth (max 30)
REGRAS DE PRIORIZACAO:
1. resilience >= 7: WINCON IMBATIVEIS
2. stealth >= 7: DANO INVISIVEL
3. speed >= 6: WINCON RAPIDA
4. EVITE resilience <= 3: morre pra qualquer remocao
```

### Funcao Original vs Atual

| Funcao | Original (A+B+C) | Atual (Wincon Hunter) |
|:-------|:-----------------|:----------------------|
| Busca EDHREC JSON API | ✅ | ❌ |
| Cross-ref `user_collection` | ✅ | Parcial (so `card_deck_analysis`) |
| Score A (Sinergia) | ✅ | ❌ (substituido por speed/resilience/stealth) |
| Score B (Custo de Oportunidade) | ✅ | ❌ |
| Score C (Evidencia EDHREC) | ✅ | ❌ |
| Verifica color identity | ❌ (gap) | ❌ (gap mantido) |
| Verifica banlist Commander | ❌ (gap) | ❌ (gap mantido) |

### O Que Faz Certo
- ✅ Consulta `user_collection` (cards que o jogador possui)
- ✅ Cross-ref com `deck_cards` (evita recomendar cartas ja no deck)
- ✅ Prioriza wincons com alta resilience (evita recomendar criaturas frageis que morrem para qualquer remocao)
- ✅ Nenhuma carta recomendada esta na Commander banlist (todas sao legais) — verificado contra Scryfall API

### O Que Faz Errado

1. 🔴 **CRITICO — Prompt perdeu funcao original de scout de sinergia.** O prompt atual e "Wincon Hunter" que busca apenas `card_deck_analysis`. A funcao original (EDHREC JSON API → cross-ref `user_collection` → Score A+B+C) foi completamente substituida. **94% das execucoes retornam [SILENT].**

2. 🔴 **CRITICO — Nao verifica Commander banlist.** O SQL nao filtra cartas banidas. Se `card_deck_analysis` contiver uma carta banida (ex: Dockside Extortionist, Mana Crypt), o Scout recomendaria sem alerta. **Mitigacao parcial:** Nenhuma das 83 cartas banidas aparece nas recomendacoes atuais.

3. 🔴 **CRITICO — Nao verifica color identity.** O SQL `JOIN user_collection uc` nao filtra por `color`. Cartas com U, B, G na color identity sao ILEGAIS em Lorehold (RW). O prompt deveria incluir: `AND (uc.color IS NULL OR uc.color IN ('R','W','R,W'))`.

4. 🟡 **ALTO — Score de wincon ignora o contexto Commander.** Resilience 7+ nao significa "imbativel" em Commander multiplayer — uma criatura com resilience 9 pode ser exilada por Path to Exile, Swords to Plowshares, ou Chaos Warp. O score nao considera que Commander e um formato com 3 oponentes e muito mais remocao.

5. 🟡 **ALTO — Nao considera interacao com o commander.** Wincons que nao interagem com Lorehold (copia de spells) sao menos valiosas que wincons que interagem — mas o scoring atual trata todas igualmente.

6. 🟡 **MEDIO — "EVITE resilience <= 3: morre pra qualquer remocao".** Embora pragmaticamente correto, a metrica e subjetiva — resilience no `card_deck_analysis` e um score artificial, nao uma propriedade real da carta.

### Recomendacoes

1. **Restaurar prompt original A+B+C** (EDHREC JSON API + `user_collection` cross-ref + sinergia)
2. **Adicionar filtro de color identity:** `AND (uc.color IS NULL OR uc.color NOT LIKE '%U%' AND uc.color NOT LIKE '%B%' AND uc.color NOT LIKE '%G%')` para Lorehold RW
3. **Adicionar verificacao de banlist:** Cross-ref contra tabela `game_changers` ou lista hardcoded da Scryfall
4. **Manter Wincon Hunter como secao do Scout, nao como Scout inteiro**

---

## Validator — Auditoria Detalhada (712579b15767)

### Prompt Atual (jobs.json)
```
## Lorehold Validator — PG Reference
LOREHOLD IDEAL PROFILE (from PG commander_reference_deck_analysis):
- lands: 32, ramp: 3.67, ritual_treasure: 10, big_spell_payoff: 7.67
- miracle_topdeck: 4.33, interaction: 5.33, protection: 3.67
- draw_value: 2.67, tutor: 3.67, win_condition: 1.33

VALIDE o deck atual contra este perfil:
SYNERGY_MAP com 7 eixos + comparacao PG

PG card_rulings disponivel para entender interacoes:
- Use card_oracle_data.ruling_text para explicar interacoes entre cartas
```

### O Que Faz Certo
- ✅ Usa perfil PG (PostgreSQL) para comparacao — abordagem orientada a dados
- ✅ SYNERGY_MAP com 7 eixos (expansao correta dos 5 originais)
- ✅ Output mais recente detecta deck hash `30d00347...` inalterado desde v3.19
- ✅ Nao propoe swaps quando deck nao mudou (short-circuit correto)
- ✅ Perfil PG referencia 3-deck corpus (nao e inventado)
- ✅ Metricas do perfil sao realistas: 32 lands, 3.67 ramp em Boros e razoavel

### O Que Faz Errado

1. 🔴 **CRITICO — Prompt referencia tabela inexistente.** `card_oracle_data.ruling_text` **NAO EXISTE.** A tabela correta e `card_rulings.ruling_text` (76,991 rulings). O Skill ja documenta isso, mas o prompt do cron NAO foi atualizado. Isso significa que o Validator **nunca consulta rulings** quando tenta explicar interacoes.

2. 🟡 **ALTO — Perfil PG e de 3 decks apenas.** O corpus de 3 decks (`commander_reference_deck_analysis`) e muito pequeno para ser estatisticamente significativo. As medias de 3 decks tem variancia enorme — `ritual_treasure: 10` pode ser um outlier de 1 deck com muitos rituals.

3. 🟡 **ALTO — SYNERGY_MAP nao inclui Stack Interaction.** Os 7 eixos atuais (Token+Pump, Wipe+Protecao, Recursion, Mana Explosiva, Combo Pieces, Stack, Resilience) cobrem bem o Lorehold, mas o eixo Stack deveria incluir explicitamente: counterspells do oponente, protecao contra counter (Grand Abolisher, Silence), e timing de Miracle.

4. 🟡 **MEDIO — Nao verifica Commander banlist.** Assim como o Scout, o Validator nao cruza as cartas do deck com a banlist. **Mitigacao:** Nenhuma carta do deck Lorehold atual esta banida.

5. 🟡 **MEDIO — "win_condition: 1.33" no perfil e contra-intuitivo.** Commander decks normalmente tem 5-8 win conditions. Um perfil com 1.33 sugere que o corpus tem decks com 1-2 wincons, o que e atipico para Commander casual/optimizado (B3).

6. 🔵 **BAIXO — Prompt nao especifica como validar lands.** O perfil diz `lands: 32` mas nao especifica se sao basic lands ou total lands. O SQLite `decks` armazena `total_lands` como soma de todas as lands (incluindo MDFCs, utility lands, fetch lands).

### Recomendacoes

1. **Corrigir referencia de tabela:** `card_oracle_data.ruling_text` → `card_rulings.ruling_text`
2. **Expandir corpus PG** para 30+ decks (usar EDHREC averages como referencia complementar)
3. **Adicionar eixo Stack Interaction** ao SYNERGY_MAP
4. **Adicionar verificacao de banlist** no pipeline de validacao
5. **Documentar que o perfil de 3 decks e suplementar**, nao normativo

---

## Mulligan — Auditoria Detalhada (08468451a06a)

### Prompt Atual (jobs.json)
```
## Agente 3: Lorehold Mulligan Tester — Teste as Mudancas
PASSO 1: Verificar se o deck mudou (EVOLUTION_LOG.md)
PASSO 2: Simular 1000 maos
  - Considere jogavel se: 2+ lands + 1 ramp OR 3+ lands
  - Considere mulligan se: 0-1 lands OR 0 ramp + 2 lands
  - Calcule tambem: % sem play no T3, % ramp T1
PASSO 3: Comparacao com historico
PASSO 4: Registrar em MULLIGAN_LOG.md

REGRA — London Mulligan Free First:
  bottom_count = max(0, mulligan_count - 1)  # primeiro mulligan = 0 cartas
```

### O Que Faz Certo
- ✅ London Mulligan "free first" implementado corretamente (CR 103.4c: primeiro mulligan em multiplayer Commander e gratuito)
- ✅ Definicao de "jogavel" rigorosa: 2+ lands + 1 ramp OR 3+ lands
- ✅ Definicao de mulligan correta: 0-1 lands OR 2 lands sem ramp
- ✅ Simulacao de 1000 maos (N suficiente para intervalos de confianca razoaveis)
- ✅ Verifica EVOLUTION_LOG antes de rodar (short-circuit quando deck nao mudou)

### O Que Faz Errado

1. 🔴 **CRITICO — Prompt nao especifica T1 ramp definition.** O prompt diz "Calcule tambem: % ramp T1" mas **NAO define quais cartas contam como T1 ramp.** O Skill documenta `T1_RAMP = {'Sol Ring'}` como canonico, mas se o Mulligan Agent nao ler o Skill (ou ler uma versao desatualizada), pode usar definicoes inconsistentes. Execucoes passadas usaram ate 3 definicoes diferentes.

2. 🔴 **CRITICO — Nao simula tapped lands.** Temple of Triumph, Boros Garrison, e outras lands que entram tapped sao tratadas como untapped. Isso significa que o T3 "real" e **pior** que o reportado — o jogador pode ter 3 lands no T3 mas uma delas entrou tapped no T2, efetivamente tendo so 2 mana disponivel.

3. 🔴 **CRITICO — Nao verifica color requirements (color screw).** Uma mao com 3 Mountains + 2 spells brancos e considerada "jogavel" se tiver ramp. Mas o jogador nao consegue conjurar as spells brancas. O "Sem Play T3" deveria verificar se as lands produzem as cores necessarias para as spells na mao.

4. 🟡 **ALTO — "Sem Play T3" nao definido no prompt.** O prompt diz para calcular "% sem play no T3" mas nao da a definicao. O Skill documenta: "nenhuma nao-land com CMC <= min(lands, 3)". Se o agente usar uma definicao diferente, os numeros serao incomparaveis (ex: Evolution Oracle Ciclos #7-#9 usou free mulligan rate em vez de Sem Play T3).

5. 🟡 **ALTO — Nao simula draws nos turnos 1-3.** A simulacao avalia apenas a mao inicial de 7 cartas. O jogador real compra 1 carta por turno — uma mao "sem play T3" pode se tornar jogavel com a compra do T1 ou T2. E vice-versa: uma mao "jogavel" pode se tornar injogavel se as compras forem lands 5+ consecutivas.

6. 🟡 **MEDIO — "2+ lands + 1 ramp OR 3+ lands" nao define o que e "ramp".** O agente precisa classificar cada carta como ramp ou nao. Se usar `functional_tag='ramp'` do SQLite, cartas como Land Tax (busca lands para a mao, nao da mana) e Weathered Wayfarer (mesmo) seriam contadas como ramp, inflando a taxa de jogaveis.

7. 🔵 **BAIXO — Nao considera free spells.** Flare of Duplication (CMC 3 mas custo alternativo gratuito) e tratada como CMC 3 para "Sem Play T3", mas na pratica e castable com 0 mana.

### Recomendacoes

1. **Adicionar `T1_RAMP = {'Sol Ring'}` explicitamente no prompt**
2. **Adicionar definicao de "Sem Play T3" no prompt:** "nenhuma nao-land com CMC <= min(lands_disponiveis, 3), considerando lands tapped"
3. **Simular tapped lands:** Marcar Temple of Triumph, Boros Garrison como tapped no turno de entrada
4. **Adicionar color requirement check:** Verificar se as lands produzem as cores das spells na mao
5. **Adicionar draw nos turnos 1-2:** Comprar 2 cartas extras antes de avaliar T3
6. **Clarificar definicao de ramp:** Excluir Land Tax, Weathered Wayfarer (busca pra mao, nao ramp)

---

## Battle Analyst — Auditoria Detalhada (94f8590b1beb)

### Status: NAO E CRON

**Evidencia:**
```bash
$ ls /opt/data/cron/output/94f8590b1beb/
# Path not found: /opt/data/cron/output/94f8590b1beb
$ grep 94f8590b1beb /opt/data/cron/jobs.json
# Nenhuma entrada
```

O Battle Analyst **nao existe como cron job.** Nao ha entrada em `jobs.json` com esse ID, e o diretorio de output nao existe. A auditoria v1 atribuiu nota 6.5/10 a um cron que nunca rodou.

### Codigo Real (battle_simulator.dart, 879 linhas)

Inspecao do codigo Dart confirma:

| Feature | Estado | Linha |
|:--------|:------|:------|
| Stack/Priority | ❌ "Sem stack complexo (resolucao imediata)" | Linha 9 |
| Counterspells | ❌ Impossiveis sem stack | Linha 9 |
| Lifelink | ✅ Sem cap (`active.life += lifeGained`) | Linha 516-519 |
| Trample | ✅ Implementado (`attacker.hasTrample`) | Linha 497-499 |
| First Strike | ✅ Timing correto | Linha ~470 |
| Flying evasion | ✅ Implementado | Linha ~480 |
| Commander damage (CR 903.10a) | ❌ Nao implementado | — |
| Commander tax (CR 903.8) | ❌ Nao implementado | — |
| ETB triggers | ❌ Nao implementado | — |
| Planeswalkers | ❌ Nao implementado | — |
| Multiplayer (4-player) | ❌ 2-player apenas | — |
| Multiplos bloqueadores | ❌ 1 blocker por attacker | — |
| Split de ataque (CR 802.1a) | ❌ Todos atacam um defensor | — |

### Correcoes da Auditoria v1

| Afirmacao v1 | Correcao |
|:-------------|:---------|
| "Priority system nao segue CR 117.3" | **Agravado:** Nao existe priority system — spells resolvem imediatamente |
| "Lifelink cap at 40 life" | **FALSO:** Codigo `active.life += lifeGained` sem cap |
| "Sem trample" | **FALSO:** `attacker.hasTrample` implementado |
| "6.5/10 confiabilidade" | **N/A:** Nao e cron, e um prototipo de codigo |

### Recomendacoes

1. **Nao usar metricas do Battle para decisoes de swap** — o codigo e um prototipo 2-player que nunca rodou
2. Se o Battle for promovido a cron, implementar: Stack LIFO, Priority CR 117.3-117.4, Commander damage, Commander tax, 4-player
3. Remover a entrada `lorehold-battle-analyst` da documentacao de crons (so existe na skill, nao no sistema)

---

## Evolution Oracle — Auditoria Detalhada (a50bef4c2a59)

### Prompt Atual (jobs.json)
```
## Lorehold Oracle — Wincon Diversity + Scoring
WINCON DIVERSITY RULE:
O deck precisa de wincons em 3 categorias:
1. RAPIDA (speed >= 6): fecha antes de virar arqui-inimigo
2. RESILIENTE (resilience >= 7): impossivel de parar
3. STEALTH (stealth >= 7): ninguem percebe ate morrer

DECK ATUAL (verifique card_deck_analysis):
...

SE FALTAR CATEGORIA, PRIORIZE:
NAO RECOMENDE: resilience <= 2
PROTECAO PARA WINCONS FRAGEIS:
- Approach (resilience=5): precisa de Grand Abolisher, Silence, Boseiju
- Storm Herd (resilience=3): precisa de Akroma's Will, Flawless Maneuver
- Rite of the Dragoncaller (resilience=4): precisa de Lightning Greaves, Swiftfoot Boots
```

### Funcao Original vs Atual

| Funcao | Original (Sintese Multi-Agente) | Atual (Wincon Diversity Oracle) |
|:-------|:-------------------------------|:-------------------------------|
| Le SCOUT_LOG.md | ✅ | ❌ |
| Le VALIDATOR_LOG.md | ✅ | ❌ |
| Le MULLIGAN_LOG.md | ✅ | ❌ |
| Le BATTLE_LOG.md | ✅ | ❌ |
| Le EVOLUTION_LOG.md (historico) | ✅ | ❌ |
| Sintese multi-agente | ✅ | ❌ (substituido por wincon check) |
| Recomenda swaps (3 eixos) | ✅ | ❌ |
| Verifica wincon diversity | Parcial | ✅ (unica funcao atual) |
| Verifica Game Changer count | ❌ (gap) | ❌ (gap mantido) |
| Verifica collection depletion | ❌ (gap) | ❌ (gap mantido) |
| Verifica CMC budget | ❌ (gap) | ❌ (gap mantido) |
| Verifica Commander banlist | ❌ (gap) | ❌ (gap mantido) |

### O Que Faz Certo
- ✅ Wincon diversity em 3 categorias e uma framework util para analise de deck
- ✅ Recomendacoes de protecao para wincons frageis sao pragmaticas (Akroma's Will para Storm Herd, Grand Abolisher para Approach)
- ✅ Output [SILENT] quando deck nao mudou (ultimo output confirma hash `30d00347...` estavel)

### O Que Faz Errado

1. 🔴 **CRITICO — Perdeu sintese multi-agente.** O Oracle atual e APENAS "Wincon Diversity Oracle". A funcao original — ler todos os logs dos agentes, sintetizar em recomendacoes de swap com justificativa nos 3 eixos (Diagnostico, Solucao, Principio) — foi completamente perdida. O Oracle nao le SCOUT_LOG, VALIDATOR_LOG, MULLIGAN_LOG, nem o historico do EVOLUTION_LOG.

2. 🔴 **CRITICO — Nao recomenda swaps.** O prompt atual so verifica se o deck tem wincons nas 3 categorias. Nao ha logica de swap, nao ha consulta a `user_collection`, nao ha verificacao de CMC budget. O Oracle se tornou um verificador passivo de wincon diversity.

3. 🔴 **CRITICO — Nao verifica Game Changer count.** Em Commander Bracket 3 (B3), o limite e 3 Game Changers. O Oracle deveria verificar `COUNT(*) FROM deck_cards WHERE card_name IN (SELECT card_name FROM game_changers)` antes de recomendar adicionar mais GCs. Atualmente, poderia recomendar o 4o GC sem alerta.

4. 🟡 **ALTO — "resilience >= 7: impossivel de parar" e enganoso.** Em Commander, mesmo wincons "imbativeis" tem respostas: exilio em massa (Farewell), counter (Force of Will), stax (Drannith Magistrate). Nenhuma wincon e verdadeiramente "impossivel de parar" em Commander multiplayer.

5. 🟡 **ALTO — Categorias de wincon nao consideram o deck especifico.** "STEALTH >= 7" e generico — o que torna uma wincon "stealth" em Lorehold (spellslinger que copia spells) e diferente do que torna stealth em um deck de criaturas. Por exemplo, Approach of the Second Sun e stealth=1 (todo mundo ve), mas em Lorehold com topdeck manipulation (Scroll Rack, Penance) ela e muito mais stealth do que o score sugere.

6. 🟡 **ALTO — Nao verifica collection depletion.** O Oracle deveria verificar se `user_collection` tem cartas compativeis antes de recomendar aquisicoes. Atualmente, se faltar uma categoria, o Oracle recomenda "buscar cartas speed >= 6 na colecao" sem verificar se existem tais cartas.

7. 🟡 **MEDIO — Referencia cartas que podem nao estar na colecao.** "precisa de Grand Abolisher, Silence, Boseiju" — Grand Abolisher esta no deck, Silence e Boseiju podem nao estar na colecao. O Oracle deveria verificar `user_collection` antes de recomendar.

8. 🟡 **MEDIO — Nao verifica Commander banlist.** Se `card_deck_analysis` contiver uma carta banida como wincon (ex: Dockside Extortionist era um engine comum), o Oracle nao detectaria.

### Recomendacoes

1. **Restaurar leitura de todos os logs de agentes** (SCOUT_LOG, VALIDATOR_LOG, MULLIGAN_LOG, EVOLUTION_LOG historico)
2. **Restaurar logica de swap com 3 eixos** (Diagnostico, Solucao, Principio)
3. **Manter Wincon Diversity como SECAO do Oracle**, nao como Oracle inteiro
4. **Adicionar verificacao de Game Changer count** antes de recomendar GCs
5. **Adicionar verificacao de collection depletion** antes de recomendar aquisicoes
6. **Adicionar CMC budget check** (net DCMC por ciclo)
7. **Adicionar verificacao de banlist** no pipeline

---

## Verificacao de Banlist Commander (Todas as Crons)

Cross-reference com Scryfall API (83 cartas banidas em Commander, ultima atualizacao incluindo Nadu, Winged Wisdom):

### Cartas no Deck Lorehold (deck_id=6)
**NENHUMA carta banida encontrada.** ✅ Todas as 99 cartas sao legais em Commander.

### Cartas Recomendadas pelos Agentes
**NENHUMA carta banida nas recomendacoes.** ✅ (Limitado — agentes estao em [SILENT], poucas recomendacoes para auditar)

### Cartas na Colecao (user_collection)
Nao foi possivel verificar toda a colecao neste escopo. **Recomendacao:** Adicionar query SQL periodica:
```sql
SELECT uc.card_en FROM user_collection uc
WHERE uc.card_en IN ('Dockside Extortionist', 'Mana Crypt', 'Jeweled Lotus', 'Nadu, Winged Wisdom', 'Hullbreacher', 'Flash', 'Paradox Engine')
AND uc.quantity > 0;
```

---

## Plano de Correcoes (ordenado por impacto)

### 🔴 CRITICO (quebra o pipeline)

| # | Problema | Agente(s) | Correcao | Esforco |
|:-:|:---------|:----------|:---------|:-------:|
| 1 | Scout prompt e Wincon Hunter, perdeu funcao A+B+C | Scout | Restaurar prompt EDHREC + colecao + sinergia | 1h |
| 2 | Oracle perdeu sintese multi-agente | Oracle | Restaurar leitura de todos os logs + swap logic | 2h |
| 3 | Nenhum agente verifica Commander banlist | Todos | Adicionar query SQL de banlist no inicio de cada agente | 30min |
| 4 | Validator referencia tabela inexistente `card_oracle_data` | Validator | Corrigir para `card_rulings` | 5min |
| 5 | Mulligan T1 ramp definition ausente do prompt | Mulligan | Adicionar `T1_RAMP = {'Sol Ring'}` ao prompt | 5min |
| 6 | Mulligan nao simula tapped lands | Mulligan | Adicionar logica de lands tapped no template Python | 1h |

### 🟡 ALTO (distorce resultados)

| # | Problema | Agente(s) | Correcao | Esforco |
|:-:|:---------|:----------|:---------|:-------:|
| 7 | Mulligan nao verifica color requirements | Mulligan | Adicionar color screw check | 2h |
| 8 | Oracle nao verifica Game Changer count | Oracle | Adicionar COUNT de GCs antes de recomendar | 30min |
| 9 | Oracle nao verifica collection depletion | Oracle | Query `user_collection` antes de recomendar aquisicoes | 30min |
| 10 | Scout nao filtra por color identity | Scout | Adicionar `WHERE color IN ('R','W','R,W') OR color IS NULL` | 15min |
| 11 | Validator perfil PG de 3 decks apenas | Validator | Expandir para 30+ decks com EDHREC averages | 4h |

### 🟡 MEDIO (imprecisao)

| # | Problema | Agente(s) | Correcao | Esforco |
|:-:|:---------|:----------|:---------|:-------:|
| 12 | Mulligan "Sem Play T3" nao definido no prompt | Mulligan | Adicionar definicao explicita | 5min |
| 13 | Mulligan nao simula draws nos turnos 1-2 | Mulligan | Adicionar 2 compras antes de avaliar T3 | 1h |
| 14 | Oracle "resilience >= 7 = imbativel" e enganoso | Oracle | Reformular para "alta resiliencia, mas nao invencivel" | 15min |
| 15 | Scout "EVITE resilience <= 3" e subjetivo | Scout | Adicionar contexto Commander multiplayer | 15min |

### 🔵 BAIXO (cosmetico/documentacao)

| # | Problema | Correcao |
|:-:|:---------|:---------|
| 16 | Battle listado como cron na documentacao | Remover `lorehold-battle-analyst` da lista de crons |
| 17 | Validator prompt nao especifica validacao de lands | Clarificar: `total_lands` vs basic lands |

---

## Conclusao

A pipeline Lorehold tem confiabilidade **BAIXA (4.6/10)** em relacao as regras oficiais de MTG — uma queda significativa da nota 7.6/10 da auditoria v1. A queda nao e porque o codigo piorou, mas porque a **auditoria v1 superestimou a confiabilidade** ao nao inspecionar os prompts e outputs reais.

### Principais Descobertas

1. **2 dos 4 agentes ativos tem prompts errados.** O Scout e um "Wincon Hunter" em vez de scout de sinergia. O Oracle e um "Wincon Diversity Checker" em vez de sintese multi-agente. Ambos retornam [SILENT] na maioria das execucoes porque suas funcoes atuais sao triviais.

2. **O Battle Analyst nao e um cron** — e um prototipo de codigo 2-player que nunca rodou. A auditoria v1 deu nota 6.5/10 para algo inexistente, e continha 2 erros factuais sobre o codigo (lifelink cap, trample).

3. **Nenhum agente verifica a Commander banlist.** Embora nenhuma carta banida tenha sido encontrada nas recomendacoes atuais, e uma vulnerabilidade sistemica.

4. **O Mulligan tem 3 gaps criticos nao documentados no prompt**: T1 ramp definition ausente, tapped lands nao simuladas, color requirements nao verificados. Os numeros de "Sem Play T3" sao consistentemente otimistas (3-8pp acima do real).

5. **O Validator referencia uma tabela PostgreSQL que nao existe** (`card_oracle_data`), significando que nunca consulta rulings para explicar interacoes.

### Proximos Passos Imediatos

1. **Corrigir prompts do Scout e Oracle** — maior impacto, menor esforco
2. **Adicionar verificacao de banlist em todos os agentes** — prevencao de risco
3. **Corrigir referencia de tabela no Validator** — 5 minutos
4. **Adicionar T1 ramp definition e Sem Play T3 definition nos prompts do Mulligan** — 10 minutos
5. **Remover Battle Analyst da documentacao de crons** — nao existe

### O Que Esta Funcionando

- ✅ Nenhuma carta banida no deck ou nas recomendacoes
- ✅ London Mulligan "free first" correto no Mulligan
- ✅ Deck hash verification no Validator (detecta unchanged state)
- ✅ SYNERGY_MAP com 7 eixos no Validator (expansao correta)
- ✅ Short-circuit [SILENT] quando deck nao mudou (todos os agentes)
- ✅ Colecao ESGOTADA documentada — pipeline reconhece limite de otimizacao sem aquisicao
- ✅ Motor 4/4 completo, SYNERGY_MAP 7 eixos pontuando 6-9/10 — deck esta em estado saudavel

### Nota Final

A pipeline Lorehold produziu 25 swaps bem-sucedidos desde o baseline, completou o motor 4/4, e atingiu maturidade de deck (3+ ciclos consecutivos com 0 swaps). O problema **nao e a qualidade do deck** — o deck esta excelente. O problema e que os **prompts dos agentes se degradaram** ao longo do tempo (Scout virou Wincon Hunter, Oracle virou Diversity Checker), e a **auditoria v1 nao detectou isso** porque confiou na documentacao em vez de inspecionar os outputs reais.

**A pipeline funciona apesar dos prompts, nao por causa deles.** Corrigir os prompts restaurara a capacidade de gerar insights mesmo em estado de maturidade (synergy-first scout, validacao profunda com rulings, recomendacoes de aquisicao informadas).
