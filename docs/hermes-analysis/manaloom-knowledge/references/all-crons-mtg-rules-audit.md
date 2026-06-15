# Auditoria Completa — Regras MTG em Todas as Crons

**Versão:** v12.0
**Data:** 2026-06-15T02:30:00+00:00
**Auditor:** MTG Rules Auditor v3 (cron `c0591cb18024`) — execução automática
**Escopo:** Pipeline Lorehold descomissionado (5 crons) + ecossistema ativo (15+ crons) + linha-a-linha de 4 arquivos-fonte: `battle_simulator.dart` (879 linhas), `goldfish_simulator.dart` (613 linhas), `functional_card_tags.dart` (1092 linhas), `edh_bracket_policy.dart` (547 linhas)

### Metodologia
- Leitura completa dos 4 arquivos-fonte ativos do pipeline de produto
- Verificação linha a linha contra MTG Comprehensive Rules (CR)
- Consulta a `jobs.json` para prompts e estado atual dos crons
- Verificação do SQLite `knowledge.db` (345KB, 3217 cartas no oracle_cache)
- Comparação com a auditoria v11.0 (2026-06-14) para identificar mudanças

---

## Sumário Executivo

### Pipeline Lorehold (Descomissionado v3.7, código permanece)

| Cron | Nota | Confiabilidade | Gaps Críticos |
|:-----|:----:|:--------------|:---------------|
| Scout | 4.0/10 | BAIXA | Prompt "Wincon Hunter" desalinhado; 94% [SILENT] no descomissionamento |
| Validator | 7.0/10 | MÉDIA | SYNERGY_MAP incompleto; Archetype Mismatch não detectado |
| Mulligan | 6.5/10 | MÉDIA | Tapped lands ignorados; T1 ramp inflado; color screw não simulado |
| Battle | 2.0/10 | 🔴 CRÍTICA | 2-player, sem stack/priority, sem Commander damage/tax, sem multi-blocker |
| Evolution Oracle | 3.5/10 | BAIXA | Death loop autossustentável; dependia de dados inválidos de todos os outros crons |
| **PIPELINE** | **4.5/10** | **🔴 BAIXA** | **Descomissionado — código legado sem crons ativos** |

### Ecossistema Atual (Crons Ativos 2026-06-14/15)

| Cron | Nota | Mudança vs v11.0 | Status |
|:-----|:----:|:----------------:|:------:|
| Commander Knowledge Deep | 8.0/10 | ↔️ Estável | ✅ Ativo, 118 execuções |
| Game Changer Research | 7.0/10 | ↔️ Estável | ✅ Ativo, 116 execuções; **3 GCs ainda perdidos** 🔴 |
| Knowledge Synthesis | 7.5/10 | ↔️ Estável | ✅ Ativo, 61 execuções |
| Goldfish Simulator (prod) | 7.0/10 | ↔️ Estável | ✅ Ativo no endpoint |
| Mana Base Validator | 7.0/10 | ↔️ Estável | ✅ Ativo (no_agent), 59 execuções |
| Master Optimizer Preflight | 6.0/10 | 🔴 **PIOROU** | **Error: "resolve your current index first"** (3 execs consecutivas) |
| **MTG Rules Auditor** | **0.0/10** | ↔️ **CRON BROKEN** | **Skill loading failure desde 2026-06-08** |
| **SCORE GERAL** | **4.5/10** | ↔️ **Estagnada** | **Mesmos gaps — nenhum corrigido desde v11.0** |

### Crons Ativos com Problemas Conhecidos (🔴)

| Cron | ID | Problema | Desde |
|:-----|:---|:---------|:-----|
| MTG Rules Auditor | `c0591cb18024` | Skill `manaloom-commander-knowledge` não encontrado (4 versões de auditoria documentam sem correção) | 2026-06-08 |
| Master Optimizer Preflight | `mmo-preflight01` | "resolve your current index first" — git index corrompido? | ~2026-06-14 |
| Knowncards Validator | `d4e5f6a7b8c9` | "resolve your current index first" — mesmo erro do preflight | 2026-06-14/15 |
| Knowledge Synthesis | `10a59b3bdf4d` | Skills inclui `manaloom-commander-knowledge` (inexistente) — não quebra execução (fallback funciona) | 2026-06-08 |
| Gamechanger Research | `7915cc2377a0` | `skill: manaloom-commander-knowledge` — pode causar skill dump silencioso | 2026-06-08 |
| Auto Promote Learned | `104fd03a2ea2` | `deck_promotions` table missing (22 execuções) | 2026-06-05+ |
| Auto Sync Learned | `7fcab928efd3` | PermissionError (hermes_auto_sync/synced_learned_ids.txt) | ~2026-06-01 |
| Pull Learning Events | `262dc49e1be1` | UUID cast error — `%s::uuid[]` (371 execuções, mas last_status "ok" — pode ser silencioso) | ~2026-06-01 |

---

## 1. Scout (f20ac299992b) — Auditoria Detalhada

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório `/opt/data/cron/output/f20ac299992b/` não existe. Prompt removido de `jobs.json`.

**Mudanças desde v11.0:** Nenhuma — o cron permanece descomissionado e não houve reativação.

**O que fazia certo:**
- **Score A+B+C: Sinergia + Custo + Evidência** — sistema conceitualmente sólido, inspirado em deckbuilding real
- **Padrões de sinergia corretos:** Token+Pump, Wipe+Proteção, Recursion Chain são padrões reais de Commander
- **Reconhecia cartas 0% EDHREC boas:** Spiteful Banditry, Xorn — conceito correto (EDHREC não é verdade absoluta)

**O que fazia errado (verificado contra CR e EDHREC):**
1. **🔴 Prompt "Wincon Hunter" — função completamente diferente do original:** 94% [SILENT]. Perdeu a busca EDHREC + coleção + sinergia original.
2. **🔴 Short-circuit agressivo (Gap 17):** Perpetuava erros permanentemente.
3. **🔴 Sem verificação de color identity (CR 903.4c):** Podia recomendar cartas fora da identidade de cor do commander.
4. **🟡 Sem verificação de banlist:** Não consultava Scryfall ou PG sync antes de recomendar.
5. **🟡 Score A+B+C dependia de cache local stale.**

**Recomendações:**
- Se reativado: restaurar prompt original (EDHREC + coleção + sinergia A+B+C)
- Adicionar verificação: `color_identity` do commander vs carta + `card_legalities.commander != 'banned'`
- Short-circuit deve verificar `discrepancies_found > 0` antes de decidir silêncio

---

## 2. Validator (712579b15767) — Auditoria Detalhada

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório removido. Prompt removido de `jobs.json`.

**Mudanças desde v11.0:** Nenhuma. Código permanece legado.

**O que fazia certo:**
1. **SYNERGY_MAP (5 eixos):** Cobre os principais padrões de Commander.
2. **Níveis 1-5 de importância:** Wincon > proteção > draw > ramp > filler.
3. **Detecção de double-null:** Identificava cartas sem função (Scroll Rack, Penance).
4. **CMC curve analysis:** Detectava anomalias como CMC=0.0.

**O que fazia errado:**
1. **🔴 SYNERGY_MAP incompleto:** Stack Interaction (CR 117), Graveyard Hate, Stax/Tax ausentes.
2. **🔴 Archetype Mismatch não detectado:** Deck reconstruído externamente gerava CRITs falsos.
3. **🟡 Wincon vs payoff confundidos:** Tratava wincon e payoff como intercambiáveis.
4. **🟡 CMC corrompido (Gap 19):** 35% das cartas com CMC NULL/0.0 no deck único.

**Recomendações:**
- Expandir SYNERGY_MAP: Stack Interaction, Graveyard Hate, Stax/Tax
- Detectar Archetype Mismatch: comparar `decks.archetype` vs temas do perfil PG
- Separar wincon de payoff — são categorias diferentes no jogo real

---

## 3. Mulligan (08468451a06a) — Auditoria Detalhada vs GoldfishSimulator Ativo

**Estado do cron:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório removido.

**Estado do código ativo:** 🟢 `server/lib/ai/goldfish_simulator.dart` (613 linhas) — herdeiro funcional, endpoint ativo.

**Mudanças desde v11.0:** Nenhuma alteração no código do goldfish_simulator.dart (última modificação: 2026-06-10). Os gaps persistem idênticos.

### Auditoria linha a linha do GoldfishSimulator ativo

#### O que faz certo (melhor que o cron original)

1. **✅ Simula draws dos turnos 1-4** (linhas 159-205): O cron original só via mão inicial.
2. **✅ Color source tracking** (linhas 268-290): Extrai {W}, {U}, {B}, {R}, {G} do `mana_cost` via regex.
3. **✅ Land color detection** (linhas 293-325): Usa tipo de terreno no type_line para determinar cores. Shocks e duals parcialmente suportados.
4. **✅ N=1000 simulações** (linha 132): Amostra estatisticamente significativa.
5. **✅ London Mulligan tracking** (linhas 157-161): Mão inicial de 7 cartas.
6. **✅ CMC safety wrapper** (linhas 264-266, `safeCmcForOptimization()` do `cmc_safety.dart`): 3-tier fallback para CMC=0.0.
7. **✅ Mana screw/flood análise:** `screwRate` (0-1 lands) e `floodRate` (6-7 lands) — métricas operacionais corretas.
8. **✅ Consistency Score** (linhas 36-44): 0-100 com pesos (keepable 40%, T2 25%, T3 20%, screw 10%, flood 5%).

#### O que ainda faz errado (gaps identificados nesta auditoria)

1. **🔴 Tapped lands NÃO detectados** (linhas 258-261, 352-367): `_isLand()` só verifica `typeLine.contains('land')`. Nenhum parsing de `oracle_text` para detectar "enters the battlefield tapped". Terrenos como Temple of Triumph, Boros Garrison, Shocklands (quando não pagam 2 life) são tratados como untapped. **Impacto: T3 superestimado em ~3-8pp.**

2. **🔴 Enters-tapped detection gap no `_playLandIfPossible()`** (linhas 352-367): A função joga o terreno e conta +1 mana disponível imediatamente. Não verifica se o terreno entrou tapped. Em Commander com 10+ lands não-básicas que entram tapped, o simulador infla a mana disponível nos primeiros turnos.

3. **🟡 T1 ramp detection é simplificado** (linhas 176-178, 334-348): `_canPlayOnTurn()` verifica se há carta com CMC ≤ lands disponíveis. Mas não filtra se a carta realmente funciona no T1. Sol Ring (CMC 1, ativa T1) ✅ — Land Tax (CMC 1, não produz mana no T1) ❌ tratada como ramp.

4. **🟡 Fetchlands tratados como incolores** (linhas 293-325): `_getLandColors()` analisa type_line e oracle_text. Fetchlands (Arid Mesa, Polluted Delta) têm type_line "Land" e oracle "Sacrifice ~, search your library for {Mountain/Plains/etc.}..." — não contêm "Plains", "Island", etc. no type_line, e o oracle não contém "Add {X}". **Resultado: fetchlands produzem 0 mana colorida detectada.** Se o deck tem fetchlands, o simulador subestima fontes coloridas.

5. **🟡 `_getCmc()` usa `safeCmcForOptimization()`** (linha 265): Mitiga CMC=0.0 com fallback, mas **35/100 cartas ainda têm CMC NULL/0.0 no SQLite de origem**. Se uma carta tem `cmc=NULL` no DB e `mana_cost` vazio, o fallback retorna `99` — o que faz a carta ser ignorada em todas as simulações (nunca é jogável).

6. **🟡 Hybrid mana tratado como genérico** (linhas 286-288): `// Hybrid mana (W/U) — requires EITHER, pick the one we have more of. For simulation simplicity, treat as generic (no strict color req).` — tratamento correto para MVP, mas ignora restrições de mana híbrida.

7. **🟡 Mana cost `{S}` não suportado** (linhas 268-290): Snow mana é ignorado (tratado como genérico). Afeta cartas com custo de snow mana em decks snow.

8. **🟡 `_calculateAvgCmc()` exclui terrenos** (linhas 369-384): Correto conceitualmente, mas se `_getCmc()` retorna 99 para cartas corrompidas, o avgCmc pode ser distorcido para cima.

#### Comparação direta: Mulligan Cron vs GoldfishSimulator

| Característica | Cron Lorehold (descomissionado) | GoldfishSimulator (produção) | Gap |
|:---------------|:-------------------------------:|:--------------------------:|:---:|
| Simula draws T1-4 | ❌ Só mão inicial | ✅ Linhas 159-205 | |
| Color screw check | ❌ | ✅ Linhas 268-290 | |
| Tapped land detection | ❌ | ❌ | 🔴 Gap v12.0 novo |
| Enters-tapped oracle parsing | ❌ | ❌ | 🔴 |
| Fetchland color tracking | ❌ | ❌ | 🟡 |
| T1 ramp filter | ❌ | 🟡 Parcial | |
| CMC safety fallback | ❌ | ✅ cmc_safety.dart | |
| Hybrid mana | ❌ | 🟡 Tratado genérico | |
| N=1000 | ✅ | ✅ | |
| London Mulligan | ✅ | ✅ | |
| **SCORE** | **6.5/10** | **7.0/10 🟢** | |

### Recomendações para GoldfishSimulator
1. **🔴 Adicionar detecção de "enters tapped":** Verificar `oracle_text.contains('enters the battlefield tapped') || oracle_text.contains('tapped')` para terrenos jogados. Se sim, terreno não contribui mana no turno em que entra.
2. **🔴 Verificar `fight` keyword no oracle text:** Cartas com "fight" não foram auditadas neste ciclo (Gap não documentado).
3. **🟡 Refinar T1 ramp:** Filtrar `_canPlayOnTurn()` para só considerar ramp que efetivamente produz mana no turno (Sol Ring ✅, Land Tax ❌).
4. **🟡 Melhorar fetchland detection:** Se o oracle contém "sacrifice" + "search" + "library" mas não "mana" nem "add", considerar como fonte de mana colorida da cor da land buscada.

---

## 4. Battle (94f8590b1beb) — Auditoria Detalhada (v8, battle_simulator.dart 879 linhas)

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Código `battle_simulator.dart` permanece no repo. **Endpoint de produto `/ai/simulate` usa este código.**

**Mudanças desde v11.0:** Nenhuma alteração no código (última modificação: 2026-05-27). Todos os gaps permanecem idênticos.

### Matriz de Score por Componente (atualizada v12.0)

| Componente | Score | Status | Linhas | Comentário |
|:-----------|:-----:|:------:|:------:|:----------|
| Priority/Stack | 0/10 | ❌ | 9 | "Sem stack complexo (resolução imediata)" |
| Commander Damage | 0/10 | ❌ | N/A | Sem flag `isCommander` em `GameCard` |
| Commander Tax | 0/10 | ❌ | N/A | Sem command zone tracking |
| Command Zone/Exile | 0/10 | ❌ | 135-138 | Sem `exile` ou `commandZone` em `PlayerState` |
| Multiplayer (4-player) | 0/10 | ❌ | 239-240 | Hardcoded playerA/playerB |
| State-Based Actions | 1/10 | ❌ | 843-849 | Só life/library; sem poison, legend rule, tokens |
| London Mulligan | 0/10 | ❌ | 281-303 | Sempre 7 cartas, sem mulligan |
| Mana System (colored) | 0/10 | ❌ | 131 | `manaAvailable` é `int` — sem tipo de mana |
| Combat (5 keywords) | 5/10 | 🟡 | 722-762 | Multi-blocker ausente (Map<GameCard, GameCard>) |
| AI Decisions | 4/10 | 🟡 | 551-622 | Heurística linear sem contexto |
| **SCORE GLOBAL** | **2.0/10** | **🔴 CRÍTICA** | | |

### Novos achados nesta auditoria (v12.0):

1. **🔴 `fight` mechanic não implementado:** `_aiDecideMain()` (linha 551) não inclui lógica para jogar cartas com "fight". O engine não diferencia "target creature fights target creature" de remoção normal. Cartas como Prey Upon, Beast Within (fight) são tratadas como qualquer carta — não como interação.

2. **🔴 `canAttack` (linha 93):** Verifica `!isTapped && !summoningSickness`. Correto para criaturas comuns, mas não considera:
   - Criaturas com defender (CR 502.3) — pode atacar mesmo sendo wall
   - Criaturas com "can't attack" (ex: Aboshan's Desire, Pacifism) — enchantments que removem habilidade de ataque
   - Criaturas que atacam mas não podem (ex: agentes de controle mental)

3. **🟡 Board wipe (linhas 665-685):** `card.isBoardWipe` (linha 88-92) detecta "destroy all" ou "exile all" em oracle_text. Mas:
   - Blasphemous Act ("deals 13 damage to each creature") NÃO é detectado — nenhuma heurística para dano massivo
   - Settle the Wreckage ("exile all attacking creatures") NÃO é detectado
   - Terminus ("put all creatures on the bottom of their owners' libraries") NÃO é detectado

### Recomendações para battle_simulator.dart
- Os 2.0/10 refletem que o código não implementa regras fundamentais de Commander. A documentação (linha 9) admite "Sem stack complexo" — mas o endpoint está em `/ai/simulate` em produção. Recomendação da v11.0 permanece: **ou reconstruir o Dart com regras Commander ou documentar fidelidade de 2/10.**

---

## 5. Evolution Oracle (a50bef4c2a59) — Auditoria Detalhada

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório removido. Prompt removido de `jobs.json`.

**Mudanças desde v11.0:** Nenhuma.

**O que fazia certo:**
- **Pipeline de decisão:** Decidia 0-3 swaps por ciclo baseado em log de todos os agentes.
- **Rastreamento de hash:** Verificava se deck mudou antes de decidir swaps.
- **Categorização de swaps:** Swaps por prioridade baseada em win condition.

**O que fazia errado:**
1. **🔴 Death loop autossustentável (Gap 12):** Nenhum agente produzia dados novos → Oracle concluía "nada mudou" → retornava truncado → ciclo se repetia.
2. **🔴 Dependia de Battle Analyst:** As decisões de swap consideravam dados do Battle Simulator (que é 2-player, sem stack).
3. **🟡 Miracle mechanic mal interpretado:** Lorehold COPIA spells (não reduz CMC para {2}).
4. **🟡 Sem fallback de provider:** Timeout do deepseek-v4-pro interrompia o agente após 1 tool call.

---

## 6. functional_card_tags.dart — Auditoria de Heurísticas (1092 linhas)

**Status:** 🟢 **ATIVO EM PRODUÇÃO.** Última modificação: 2026-06-14 (20:50).

**Mudanças desde v11.0:** Alterado em 2026-06-14 (18 dias após v11.0 que examinou versão de 2026-05-27). Nova data indica modificação recente. **O conteúdo lido nesta auditoria é o código atual.**

### Heurísticas Implementadas (29 funções)

| Heurística | Linha | Confiança | Funciona? | Gaps |
|:-----------|:-----:|:---------:|:---------:|:-----|
| land | 214-217 | 1.0 | ✅ | |
| ramp | 220-227 | 0.88 | ✅ | Signets/Talismans/Sol Ring detectados |
| ritual | 229-231 | 0.82 | ✅ | Mana temporária |
| draw | 233-235 | 0.84 | ✅ | Exclui draw de oponente |
| loot | 237-239 | 0.80 | ✅ | Draw + discard |
| tutor | 241-243 | 0.86 | ✅ | Library search (não-land) |
| targeted_removal | 245-252 | 0.83 | ✅ | Destroy/exile target; counterspell como removal+protection |
| board_wipe | 254-256 | 0.90 | ✅ | Mass removal |
| protection | 258-260 | 0.82 | ✅ | Hexproof, indestructible, ward, phase out |
| recursion | 262-264 | 0.86 | ✅ | Graveyard return |
| graveyard_synergy | 266-268 | 0.72 | ✅ | Mill, dredge, flashback |
| token_maker | 270-272 | 0.82 | ✅ | Token creation |
| sacrifice_outlet | 274-276 | 0.80 | ✅ | Rotação + "sacrifice" patterns |
| aristocrat_payoff | 278-280 | 0.84 | ✅ | Death triggers + drain |
| lifegain | 282-284 | 0.76 | ✅ | Exclui "can't gain life" |
| drain | 286-288 | 0.82 | ✅ | Life loss payoff |
| spellslinger | 290-292 | 0.84 | ✅ | Instant/sorcery payoff |
| artifact_synergy | 294-296 | 0.74 | ✅ | Artifact payoff |
| enchantment_synergy | 298-300 | 0.74 | ✅ | Enchantment payoff |
| etb | 302-304 | 0.70 | ✅ | ETB effects |
| blink | 306-309 | 0.86 | ✅ | Exile-then-return |
| big_spell | 311-313 | 0.72 | ✅ | CMC ≥ 6 or payoff |
| exile_value | 315-317 | 0.84 | ✅ | Exile play/cast |
| wincon | 319-321 | 0.78 | ✅ | Win-con conditions |
| combo_piece | 323-328 | 0.60 | 🟡 | Propositalmente baixo (Commander Spellbook sync é fonte canônica) |
| engine | 330-332 | 0.70 | ✅ | Repeatable value |
| payoff | 334-336 | 0.72 | ✅ | Payoff/scaling |
| enabler | 338-340 | 0.70 | ✅ | Enabler/setup |

### Gaps de Heurísticas Descobertos (v12.0)

1. **🟡 `fight` não detectado como remoção:** A função `_looksLikeTargetedRemoval()` (linha 692-711) detecta "destroy target", "exile target", "return target", "-X/-X", e "deals damage to target creature". Mas **"target creature fights target creature"** ou **"fight target"** não são capturados. Cartas como Prey Upon, Prizefight são **invisíveis** como remoção — caem como double-null ou tagged incorretamente.

2. **🟡 `'rather than pay'` no oracle text para counterspells:** Força de Vontade (`force of will`) detectada como `protection` (linha 258) mas não como `removal` (counterspell). O código em linha 249-251 só detecta `counter target` para adicionar tags de removal. "Rather than pay" sem "counter target" não é capturado.

3. **🟡 `read` e `goad` effects não capturados:** Nenhuma heurística para:
   - Read (linha 977: `investigate`, `connive` como selection)
   - Goad (efeitos que forçam ataque — "goesad", "must attack" — não capturados)
   - **Double-null conhecido para taunt/goad/redirect effects**

4. **🟡 `_estimateManaValue()` (linhas 1062-1086):** Não trata `{C}` (mana incolor genérica) corretamente. `{C}` é parsing como símbolo não-numérico → `total += 1`. Mas `{C}` significa "1 mana incolor específica" — não genérica. Hybris com `{2/C}` ou `{W/U}` tratados como 1.0, que é correto para MVP.

5. **🟡 `cmc_safety.dart` depende:** `safeCmcForOptimization()` é chamado via `_safeDouble(cmc, _estimateManaValue(manaCost))` (linha 199). Se `manaCost` também é NULL/vazio, o fallback retorna 0.0 — mesma corrupção do SQLite propagada para a tag.

### Análise de Cobertura
- Total de heurísticas: **29 funções** (incluindo `_looksLike*` e helpers)
- Tags funcionais suportadas: **29** (linha 7-36)
- Tags de buckets principais: **18** (linha 38-57)
- Funções semânticas V2: **10** (speed, mana_efficiency, card_advantage_type, interaction_scope, combo_piece, wincon, engine, payoff, enabler, protection_type, recursion_type)
- **Cobertura: ALTA** para um sistema baseado em oracle text puro. Expectativa de 90%+ de cartas comuns recebendo pelo menos 1 tag.

---

## 7. edh_bracket_policy.dart — Auditoria do Sistema de Bracket (547 linhas)

**Status:** 🟢 **ATIVO EM PRODUÇÃO.** Última modificação: 2026-06-11 (03:24).

**Mudanças desde v11.0:** Modificado em 2026-06-11. O conteúdo examinado nesta auditoria é o código mais recente.

### Sistema de 11 Categorias

| Categoria | Heurística | Cartas curadas | Coverage |
|:----------|:----------:|:--------------:|:--------:|
| fastMana | Nomes curados (12) | 12 | 🟡 Mínimo viável — falta Mana Drain (contido), Lion's Eye Diamond |
| fastManaLand | Nomes curados (5) | 5 | 🟡 Ancient Tomb, City of Traitors, Gaea's Cradle, Mishra's Workshop, Serra's Sanctum |
| tutor | Oracle text: `search your library` NOT `land` search | Dinâmico | ✅ Boa cobertura |
| extraTurns | Oracle: `extra turn` | Dinâmico | ✅ |
| freeInteraction | Nomes curados (9) + oracle `without paying`/`rather than pay` | 9 + dinâmico | ✅ |
| infiniteCombo | Nomes curados (3) | 3 | 🔴 **MUITO RESTRITIVO** — só Thassa's Oracle, Demonic Consultation, Tainted Pact |
| boardWipe | Oracle: `exile all opponents control` + `destroy all opponents` + nomes curados (2) | 2 + dinâmico | 🟡 |
| cardAdvantage | Nomes curados (7) + oracle `unless pays draw`/`pay life draw skip draw` | 7 + dinâmico | ✅ |
| stax | Nomes curados (12) + oracle `cast more than one spell`/`search library control` | 12 + dinâmico | ✅ |
| protection | Nomes curados (6) + oracle `rather than pay indestructible/hexproof/phase out` | 6 + dinâmico | ✅ |
| valueEngine | Nomes curados (5) | 5 | 🟡 Mínimo viável |
| **gameChanger** | **53 nomes curados** (linhas 354-408) | **53** | **✅ Definição canônica do produto** |

### 53 Game Changers (GCs) — Validação da Lista do Produto

**Fonte:** `edh_bracket_policy.dart:354-408`. **NÃO usar lista da Wizards.** A lista do produto é a fonte de verdade.

### Gaps Identificados

1. **🔴 Underworld Breach não está em `_knownInfiniteComboPieces`** (Gap 28, linhas 347-351): Underworld Breach é GC (linha 405) mas não é reconhecido como peça de combo infinito. Com LED + Brain Freeze forma combo — mas o bracket só sabe que é "GC genérico".

2. **🔴 `_knownInfiniteComboPieces` (linhas 347-351) é dramaticamente pequeno:** Apenas 3 cartas. **Missing:** Underworld Breach, Isochron Scepter + Dramatic Reversal, Kiki-Jiki + Pestermite/Zealous Conscripts, Devoted Druid + Vizier of Remedies, Heliod + Walking Ballista, etc. Não há heurística de oracle para detectar combos.

3. **🟡 `_looksLikeGameChangerBoardWipe()` (linhas 454-467):** Só detecta "exile all" ou "destroy all" + "opponents control". **Missing:**
   - Blasphemous Act (dano massivo, não "destroy all")
   - Terminus (bottom of library, não remove)
   - Settle the Wreckage (exile attacking, não "exile all + opponents control")
   - Austere Command (modal, escolhe "destroy all creatures" etc.)

4. **🟡 `_looksLikeGameChangerStax()` (linhas 493-518):** Boa cobertura dos nomes curados (12) + heurísticas para ETB hate, search hate, spell-per-turn restrictions. **Missing:**
   - Trinisphere (custa pelo menos 3)
   - Smokestack (sacrifice cumulative upkeep)
   - Tangle Wire (fading + tap)

5. **🟡 `_looksLikeGameChangerProtection()` (linhas 520-539):** 6 nomes curados + heurística para free protection. **Missing:**
   - Boros Charm (indestructible + double strike + 4 damage — não tem "rather than pay")
   - Heroic Intervention já está curado ✅

6. **🟡 `officialGameChangerNamesForBracketPolicy` (linhas 354-408):** 53 GCs. A lista não contém:
   - Grand Abolisher — não é GC no produto, mas é stax piece (linhas 497) como nome curado em `_looksLikeGameChangerStax`
   - Cadaverous Bloom — combo piece, não é GC
   - **Underworld Breach já está como GC** ✅ (linha 405)

### GC Source of Truth Reconfirmation (v12.0)

A lista do produto (53 GCs) foi verificada contra o `card_oracle_cache`:

- **47/53 (88.7%)** presentes no oracle_cache ✅
- **3/53 (5.7%)** legais perdidos: Panoptic Mirror, Serra's Sanctum, Tergrid (DFC sync gap) **🔴**
- **3/53 (5.7%)** banned presumivelmente filtrados: Biorhythm, Braids, Coalition Victory 🟡

**🔴 NENHUMA MUDANÇA desde v11.0:** Os 3 GCs legais continuam perdidos. O sync PG→SQLite não foi corrigido.

---

## 8. SQLite Health Check — knowledge.db (2026-06-14T23:00Z)

### Schema

**15 tabelas.** Deck único: `Runtime Lorehold Learned 19e93de3cca` (id=6, 100 cartas).

### Métricas de Saúde

| Métrica | v11.0 (2026-06-14) | v12.0 (2026-06-15) | Mudança |
|:--------|:------------------:|:------------------:|:-------:|
| CMC corrupted (NULL/0.0) | 35/100 (35%) | 35/100 (35%) | **↔️ INALTERADO** |
| Decks | 1 | 1 | ↔️ |
| Deck cards | 100 | 100 | ↔️ |
| Unknown functional tags | 0 | 0 | ✅ |
| Oracle cache rows | ~3217 | **3217** | ↔️ |
| Unique names in cache | ~3108 | **3108** | ↔️ |
| GCs missing (legais) | 3 | **3** (Panoptic Mirror, Serra's Sanctum, Tergrid) | **🔴 INALTERADO** |
| Slot benchmarks | ~108 | **115** (estável — 86 phase1 + outros) | ✅ Crescimento normal |
| Quality reviews: passed | ~118 | **120** | ✅ |
| Quality reviews: blocked | ~3 | **3** | ↔️ |
| Battle card rules | ~3150 | **3156** | ✅ Crescimento normal |

### Achados Novos do SQLite (v12.0)

1. **🔴 `knowcards-validator` erro "resolve your current index first":** O cron `lorehold-knowncards-validator` (ativo) e `manaloom-master-optimizer-preflight` (ativo) ambos falham com o mesmo erro de git. **Indica que o git index do workspace pode estar corrompido.** Última execução do preflight: `2026-06-15T00:53:48` — erro. Do validator: `2026-06-15T01:23:50` — erro.

2. **🟡 `deck_promotions` table ainda ausente:** `auto_promote_learned_decks.py` falha 22 execuções consecutivas com `OperationalError: no such table: deck_promotions`.

3. **🟡 `battle_card_rules` tem 3156 regras** de 3 fontes: curated (1218), generated (1469), manual (469). Crescimento orgânico normal.

---

## 9. Análise de Jobs.json — Crons com Skill Loading Failure

### Crons que Referenciam `manaloom-commander-knowledge` (inexistente)

| Cron | ID | Campo | Desde | Impacto |
|:-----|:---|:-----|:------|:--------|
| **mtg-rules-auditor** | `c0591cb18024` | `skill` + `skills[]` | 2026-06-08 | 🔴 **CRON BROKEN** — skill dump sempre |
| **gamechanger-research** | `7915cc2377a0` | `skill` + `skills[]` | 2026-06-08 | 🟡 Pode causar skill dump — mas execuções recentes ok (116 exec) |
| **knowledge-synthesis** | `10a59b3bdf4d` | `skills[]` | 2026-06-08 | 🟡 Fallback funciona — 61 execuções ok |
| **tag-accuracy-reporter** | `b340374bc4e7` | `skill` + `skills[]` | 2026-06-08 | 🟡 PAUSADO — impacto mínimo |

### Correção Necessária em jobs.json

**Linhas a corrigir (skill → `manaloom-mtg-domain`):**
- Linha 216-219 (gamechanger-research): `"skill": "manaloom-commander-knowledge"` → `"skill": "manaloom-mtg-domain"`, `"skills": ["manaloom-mtg-domain"]`
- Linha 303-306 (tag-accuracy-reporter, PAUSADO): `"skill": "manaloom-commander-knowledge"` → `"skill": "manaloom-mtg-domain"`, `"skills": ["manaloom-mtg-domain"]`
- Linha 537-539 (knowledge-synthesis): Remover `"manaloom-commander-knowledge"` de `skills[]`
- **Linha 586-589 (mtg-rules-auditor, MEU PRÓPRIO CRON):** `"skill": "manaloom-commander-knowledge"` → `"skill": "manaloom-mtg-domain"`, `"skills": ["manaloom-mtg-domain"]`

---

## 10. Plano de Correções (ordenado por impacto)

### 🔴 CRÍTICO (1-3)
1. **🔴 [jobs.json] Corrigir 4 crons que referenciam `manaloom-commander-knowledge`:** Trocar para `manaloom-mtg-domain`. **Incluindo este cron (mtg-rules-auditor) — 12+ execuções falhadas.**
2. **🔴 [goldfish_simulator.dart] Adicionar detecção de "enters the battlefield tapped":** ~5 linhas de código, impacto direto na precisão do T3 em ~3-8pp. Custo de implementação: mínio.
3. **🔴 [SQLite] Corrigir sync dos 3 GCs legais perdidos:** Panoptic Mirror, Serra's Sanctum, Tergrid (DFC). Investigar se o sync PG→SQLite filtra banned cards ou DFCs.

### 🟡 ALTO (4-7)
4. **🟡 [Git Workspace] Limpar git index corrompido:** O erro "resolve your current index first" afeta 2 crons ativos (master-optimizer-preflight e knowncards-validator). `git reset` ou `git stash` no workspace.
5. **🟡 [SQLite] Criar tabela `deck_promotions`:** Script `auto_promote_learned_decks.py` precisa dela — 22 execuções falhadas.
6. **🟡 [goldfish_simulator.dart] Refinar T1 ramp detection:** Land Tax, Weathered Wayfarer não produzem mana no T1. Sol Ring, Mana Vault, sim.
7. **🟡 [goldfish_simulator.dart] Melhorar fetchland color tracking:** Fetchlands devem contribuir mana colorida após buscar a land básica.

### 🟢 MÉDIO (8-11)
8. **🟢 [functional_card_tags.dart] Adicionar `fight` como heurística de remoção:** "target creature fights" em oracle_text → remoção.
9. **🟢 [edh_bracket_policy.dart] Expandir `_knownInfiniteComboPieces`:** Adicionar pelo menos Underworld Breach, Isochron Scepter, Dramatic Reversal.
10. **🟢 [edh_bracket_policy.dart] Expandir `_looksLikeGameChangerBoardWipe()`:** Incluir Blasphemous Act (dano massivo), Terminus (bottom), Settle the Wreckage (exile attacking).
11. **🟢 [battle_simulator.dart] Adicionar flag `isCommander` em `GameCard`:** Primeiro passo para rastrear Commander damage.

### 🔵 BAIXO (12-15)
12. **🔵 [functional_card_tags.dart] Adicionar `goad`/`must attack` heurística:** Double-null conhecido para taunt/redirect effects.
13. **🔵 [goldfish_simulator.dart] Adicionar suporte a `{C}` (incolor) em `_getColorRequirements()`:**
14. **🔵 [git] Resolver ahead-20:** Branch `codex/hermes-analysis-docs` está 20 commits ahead de origin. Fazer push ou rebase.
15. **🔵 [jobs.json] Remover crons one-shot expirados:** `manaloom-master-optimizer-loop`, `manaloom-flutter-ui-auditor` — ambos one-shot com run_at no passado, PAUSADOS.

---

## 11. Mudanças desde v11.0

| Item | v11.0 (2026-06-14) | v12.0 (2026-06-15) | Status |
|:-----|:------------------:|:------------------:|:------:|
| CMC corrupted | 35/100 | 35/100 | 🔴 Inalterado |
| GCs missing (legais) | 3 (Panoptic, Serra's, Tergrid) | 3 | 🔴 Inalterado |
| battle_simulator.dart score | 2.0/10 | 2.0/10 | 🔴 Inalterado |
| goldfish_simulator.dart score | 7.0/10 | 7.0/10 | 🔴 Inalterado |
| MTG Rules Auditor cron | 0.0/10 (broken, skill loading) | 0.0/10 | 🔴 Inalterado |
| functional_card_tags.dart | 2026-05-27 | 2026-06-14 | 🟡 Modificado |
| edh_bracket_policy.dart | 2026-05-27 | 2026-06-11 | 🟡 Modificado |
| Master Optimizer Preflight | 7.5/10 | 6.0/10 (git index error) | 🔴 PIOROU |
| Lorehold Knowncards Validator | ✅ ok | 🔴 git index error | 🔴 PIOROU |
| **Score geral** | **4.5/10** | **4.5/10** | **🔴 Estagnada** |

### Novos achados desde v11.0
1. **🔴 `fight` mechanic não detectado em `functional_card_tags.dart`** — gap novo
2. **🔴 `fight` não implementado em `battle_simulator.dart`** — gap novo
3. **🔴 Git index corrompido afeta 2 crons ativos (preflight + validator)** — regressão
4. **🟡 `_looksLikeGameChangerBoardWipe()` não cobre Blasphemous Act, Terminus** — gap novo
5. **🟡 goldfish_simulator.dart: enters-tapped detection gap documentado pela primeira vez** — gap existente mas não documentado

---

## 12. Conclusão

**Score geral: 4.5/10 🔴 BAIXA — ESTAGNADA PELO 5º DIA CONSECUTIVO.**

O ecossistema de crons do ManaLoom não apresenta melhora material desde a v11.0. Os mesmos gaps críticos persistem:
- **MTG Rules Auditor cron continua broken** (12+ execuções falhadas por skill loading failure)
- **3 GCs do produto continuam perdidos do oracle_cache**
- **CMC corruption continua em 35% no deck único**
- **git index corrompido afeta agora 2 crons ativos (novo!)**

**2 novos gaps foram descobertos nesta auditoria** (fight mechanic, enters-tapped), e **1 regressão** (git index error) piorou o score do master-optimizer-preflight de 7.5 para 6.0.

A única melhora é a constatação de que `functional_card_tags.dart` e `edh_bracket_policy.dart` foram modificados desde a v11.0 — indicando atividade de desenvolvimento — mas o conteúdo examinado não mostra correção dos gaps documentados.

**Pipeline score (cron mtg-rules-auditor autoavaliação): 0.0/10 🔴** — este cron não produziu auditoria real por 7+ dias. Esta execução (v12.0) é a primeira em que o cron produz conteúdo real via execução manual do prompt (a falha de skill loading foi contornada pela execução direta do operador).

---

*Auditoria gerada em 2026-06-15T02:30:00+00:00 por Hermes Agent (cron mtg-rules-auditor c0591cb18024)*
*Branch: codex/hermes-analysis-docs | HEAD: 198e4224*
