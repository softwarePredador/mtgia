# Auditoria Completa — Regras MTG em Todas as Crons

**Versão:** v13.0
**Data:** 2026-06-15T14:30:00+00:00
**Auditor:** MTG Rules Auditor v3 (cron `c0591cb18024`) — execução automática
**Escopo:** Pipeline Lorehold descomissionado (5 crons) + ecossistema ativo (15+ crons) + linha-a-linha de 4 arquivos-fonte: `battle_simulator.dart` (879 linhas), `goldfish_simulator.dart` (613 linhas), `functional_card_tags.dart` (1092 linhas), `edh_bracket_policy.dart` (547 linhas, **moved** de `server/lib/ai/` para `server/lib/`)

### Metodologia
- Leitura completa dos 4 arquivos-fonte ativos do pipeline de produto
- Verificação linha a linha contra MTG Comprehensive Rules (CR)
- Consulta a `jobs.json` para prompts e estado atual dos crons
- Verificação do SQLite `knowledge.db` (3217 cartas no oracle_cache)
- Comparação com a auditoria v12.0 (2026-06-15T02:30Z) para identificar mudanças
- Verificação de diretórios de output dos crons e estado de git

### Mudanças desde v12.0 (12h de intervalo)

| Item | v12.0 (2026-06-15 02:30Z) | v13.0 (2026-06-15 14:30Z) | Status |
|:-----|:--------------------------:|:--------------------------:|:-------|
| CMC corrupted (deck único) | 35/100 (35%) | 35/100 (35%) | 🔴 Inalterado |
| GCs missing (legais) | 3 (Panoptic, Serra's, Tergrid) | 3 | 🔴 Inalterado |
| battle_simulator.dart score | 2.0/10 | 2.0/10 | 🔴 Inalterado |
| goldfish_simulator.dart score | 7.0/10 | 7.0/10 | 🔴 Inalterado |
| functional_card_tags.dart | Versão 2026-06-14 | Mesma | ✅ Estável |
| edh_bracket_policy.dart | em `server/lib/ai/` | **em `server/lib/`** | 🟡 **NOVO: arquivo movido** |
| Master Optimizer Preflight | 6.0/10 | 6.0/10 | 🔴 Git index error persiste |
| Knowncards Validator | 🔴 git index error | 🔴 git index error | 🔴 Persiste |
| MTG Rules Auditor self-score | 0.0/10 | 0.0/10 | 🔴 Cron broken persiste |
| **Score geral** | **4.5/10** | **4.5/10** | **🔴 Estagnada pelo 6º dia** |

### 🆕 Novo Achado v13.0: `edh_bracket_policy.dart` Movido

O arquivo `edh_bracket_policy.dart` **não está mais em `server/lib/ai/`** como documentado em toda a base de conhecimento. Foi movido para **`server/lib/edh_bracket_policy.dart`**. O commit `7edd62ba` ("Unify strategic role tag heuristics") no master é o candidato mais recente — mas o move pode ter ocorrido em commit anterior.

**Impacto:** Documentação do domínio (`manaloom-mtg-domain` §13, Gap 27) referencia `server/lib/ai/edh_bracket_policy.dart:354-408` — caminho incorreto. O conteúdo e linha de GCs são os mesmos (53 GCs, linhas 354-408 no novo arquivo). Apenas o path mudou.

---

## Sumário Executivo

### Pipeline Lorehold (Descomissionado v3.7, código permanece)

| Cron | Nota | Confiabilidade | Gaps Críticos |
|:-----|:----:|:--------------|:---------------|
| Scout | 4.0/10 | BAIXA | Prompt "Wincon Hunter" desalinhado; 94% [SILENT] no descomissionamento |
| Validator | 7.0/10 | MÉDIA | SYNERGY_MAP incompleto; Archetype Mismatch não detectado |
| Mulligan | 6.5/10 | MÉDIA | Tapped lands ignorados; T1 ramp inflado; color screw não simulado |
| Battle | 2.0/10 | 🔴 CRÍTICA | 2-player, sem stack/priority, sem Commander damage/tax, sem multi-blocker |
| Evolution Oracle | 3.5/10 | BAIXA | Death loop autossustentável; dependia de dados inválidos |
| **PIPELINE** | **4.5/10** | **🔴 BAIXA** | **Descomissionado — código legado sem crons ativos** |

### Ecossistema Atual (Crons Ativos 2026-06-15)

| Cron | Nota | Mudança vs v12.0 | Status |
|:-----|:----:|:----------------:|:------:|
| Commander Knowledge Deep | 8.0/10 | ↔️ Estável | ✅ Ativo, 120 execuções |
| Game Changer Research | 7.0/10 | ↔️ Estável | ✅ Ativo, 117 execuções; **3 GCs ainda perdidos** 🔴 |
| Knowledge Synthesis | 7.5/10 | ↔️ Estável | ✅ Ativo, 63 execuções |
| Goldfish Simulator (prod) | 7.0/10 | ↔️ Estável | ✅ Ativo no endpoint |
| Mana Base Validator | 7.0/10 | ↔️ Estável | ✅ Ativo (no_agent), 60 execuções |
| Master Optimizer Preflight | 6.0/10 | 🔴 **PIOROU** | **exit code 128** — git index error persiste |
| Knowncards Validator | 5.0/10 | 🔴 **PIOROU** | **exit code 128** — git index error |
| **MTG Rules Auditor (auto)** | **0.0/10** | ↔️ **CRON BROKEN** | **Skill loading failure desde 2026-06-08** (7+ dias) |
| **SCORE GERAL** | **4.5/10** | ↔️ **Estagnada pelo 6º dia** | **Nenhum gap corrigido desde v11.0** |

### Crons Ativos com Problemas Conhecidos (🔴)

| Cron | ID | Problema | Desde |
|:-----|:---|:---------|:-----|
| MTG Rules Auditor | `c0591cb18024` | Skill `manaloom-commander-knowledge` não encontrado (5 versões de auditoria documentam sem correção) | 2026-06-08 |
| Master Optimizer Preflight | `mmo-preflight01` | exit code 128 — git index corrompido (todas as execuções do dia) | ~2026-06-14 |
| Knowncards Validator | `d4e5f6a7b8c9` | exit code 128 — mesmo erro do preflight (todas as execuções do dia) | 2026-06-14/15 |
| Knowledge Synthesis | `10a59b3bdf4d` | skills[] inclui `manaloom-commander-knowledge` (inexistente) | 2026-06-08 |
| Gamechanger Research | `7915cc2377a0` | `skill: manaloom-commander-knowledge` | 2026-06-08 |
| Auto Promote Learned | `104fd03a2ea2` | `deck_promotions` table missing (último erro: 2026-06-15 12:43) | 2026-06-05+ |
| Auto Sync Learned | `7fcab928efd3` | PermissionError (hermes_auto_sync/...) | ~2026-06-01 |
| Pull Learning Events | `262dc49e1be1` | UUID cast error — mas last_status="ok" (pode ser silencioso) | ~2026-06-01 |

---

## 1. Scout (f20ac299992b) — Auditoria Detalhada

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório `/opt/data/cron/output/f20ac299992b/` **não existe**. Prompt removido de `jobs.json`. Nenhuma execução nova desde v12.0.

**Confirmação v13.0:** O diretório continua ausente. O ID não está em jobs.json. Status inalterado.

**O que fazia certo:**
- **Score A+B+C: Sinergia + Custo + Evidência** — sistema conceitualmente sólido
- **Padrões de sinergia corretos:** Token+Pump, Wipe+Proteção, Recursion Chain
- **Reconhecia cartas 0% EDHREC boas:** Spiteful Banditry, Xorn

**O que fazia errado (verificado contra CR e EDHREC):**
1. **🔴 Prompt "Wincon Hunter" — função completamente diferente do original:** 94% [SILENT]
2. **🔴 Short-circuit agressivo (Gap 17):** Perpetuava erros permanentemente
3. **🔴 Sem verificação de color identity (CR 903.4c)**
4. **🟡 Sem verificação de banlist**
5. **🟡 Score A+B+C dependia de cache local stale**

**Recomendações (inalteradas):**
- Se reativado: restaurar prompt original EDHREC + coleção + sinergia A+B+C
- Adicionar verificação color_identity + card_legalities.commander != 'banned'
- Short-circuit deve verificar discrepancies_found > 0

---

## 2. Validator (712579b15767) — Auditoria Detalhada

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório removido. Prompt removido de `jobs.json`.

**Confirmação v13.0:** Status inalterado. Nenhuma reativação.

**O que fazia certo:**
1. **SYNERGY_MAP (5 eixos):** Cobre os principais padrões de Commander
2. **Níveis 1-5 de importância:** Wincon > proteção > draw > ramp > filler
3. **Detecção de double-null:** Identificava cartas sem função
4. **CMC curve analysis:** Detectava anomalias como CMC=0.0

**O que fazia errado:**
1. **🔴 SYNERGY_MAP incompleto:** Stack Interaction (CR 117), Graveyard Hate, Stax/Tax ausentes
2. **🔴 Archetype Mismatch não detectado**
3. **🟡 Wincon vs payoff confundidos**
4. **🟡 CMC corrompido (Gap 19):** 35% das cartas com CMC NULL/0.0

**Recomendações (inalteradas):**
- Expandir SYNERGY_MAP: Stack Interaction, Graveyard Hate, Stax/Tax
- Detectar Archetype Mismatch
- Separar wincon de payoff

---

## 3. Mulligan (08468451a06a) — Auditoria Detalhada vs GoldfishSimulator Ativo

**Estado do cron:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório removido.

**Estado do código ativo:** 🟢 `server/lib/ai/goldfish_simulator.dart` (613 linhas) — herdeiro funcional, endpoint ativo.

**Confirmação v13.0:** Código do goldfish_simulator.dart não foi modificado. Todas as 613 linhas idênticas à auditoria v12.0.

### O que faz certo

1. **✅ Simula draws dos turnos 1-4** (linhas 159-205)
2. **✅ Color source tracking** (linhas 268-290): Extrai {W}, {U}, {B}, {R}, {G} do `mana_cost`
3. **✅ Land color detection** (linhas 293-325)
4. **✅ N=1000 simulações** (linha 132)
5. **✅ London Mulligan tracking** (linhas 157-161)
6. **✅ CMC safety wrapper** (linhas 264-266, cmc_safety.dart)
7. **✅ Mana screw/flood análise:** screwRate, floodRate
8. **✅ Consistency Score** (linhas 36-44): 0-100 com pesos

### O que ainda faz errado (gaps confirmados)

1. **🔴 Tapped lands NÃO detectados** (linhas 352-367): `_playLandIfPossible()` não verifica oracle_text para "enters the battlefield tapped". Terrenos como Temple of Triumph, Boros Garrison, Shocklands são tratados como untapped. **Impacto: T3 superestimado em ~3-8pp.**

2. **🔴 Enters-tapped oracle parsing ausente** — nenhuma verificação de `oracle_text.contains('enters the battlefield tapped') || oracle_text.contains('tapped')` para lands.

3. **🟡 T1 ramp detection simplificado** (linhas 176-178, 334-348): Land Tax, Weathered Wayfarer tratados como T1 ramp — não produzem mana no T1.

4. **🟡 Fetchlands tratados como incolores** (linhas 293-325): `_getLandColors()` não detecta fetchlands como fonte de mana colorida.

5. **🟡 `_getCmc()` usa `safeCmcForOptimization()`** — mitiga CMC=0.0, mas 35/100 cartas ainda com CMC NULL/0.0 no SQLite.

6. **🟡 Hybrid mana tratado como genérico** (linhas 286-288): Correto para MVP, mas ignora restrições.

7. **🟡 Mana cost `{S}` não suportado** (linhas 268-290): Snow mana ignorado.

### Recomendações (inalteradas)
1. 🔴 Adicionar detecção de "enters the battlefield tapped" em lands
2. 🟡 Refinar T1 ramp filter
3. 🟡 Melhorar fetchland color tracking

---

## 4. Battle (94f8590b1beb) — Auditoria Detalhada (battle_simulator.dart 879 linhas)

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Código `battle_simulator.dart` permanece no repo. **Endpoint de produto `/ai/simulate` usa este código.**

**Confirmação v13.0:** Código inalterado desde última modificação (2026-05-27). Todos os gaps persistem.

### Matriz de Score por Componente

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

### Gaps Confirmados (inalterados)
1. 🔴 `fight` mechanic não implementado
2. 🔴 `canAttack` não considera defender (CR 502.3) nem "can't attack" effects
3. 🟡 Board wipe detection: Blasphemous Act (dano massivo), Terminus (bottom), Settle the Wreckage (exile attacking) — não detectados

### Recomendações (inalteradas)
- Reconstruir o Dart com regras Commander ou documentar fidelidade de 2/10 no endpoint `/ai/simulate`

---

## 5. Evolution Oracle (a50bef4c2a59) — Auditoria Detalhada

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório removido. Prompt removido de `jobs.json`.

**Confirmação v13.0:** Status inalterado.

**O que fazia certo:**
- Pipeline de decisão com 0-3 swaps por ciclo
- Rastreamento de hash
- Categorização de swaps por prioridade

**O que fazia errado:**
1. 🔴 Death loop autossustentável (Gap 12)
2. 🔴 Dependia de Battle Analyst (2-player, sem stack)
3. 🟡 Miracle mechanic mal interpretado
4. 🟡 Sem fallback de provider

---

## 6. functional_card_tags.dart — Auditoria de Heurísticas (1092 linhas)

**Status:** 🟢 **ATIVO EM PRODUÇÃO.** Última modificação: 2026-06-14 (20:50). **Inalterado desde v12.0.**

### Heurísticas Implementadas (29 funções)

| Heurística | Confiança | Status | Gaps |
|:-----------|:---------:|:------:|:-----|
| land | 1.0 | ✅ | |
| ramp | 0.88 | ✅ | Signets/Talismans/Sol Ring detectados |
| ritual | 0.82 | ✅ | |
| draw | 0.84 | ✅ | |
| loot | 0.80 | ✅ | |
| tutor | 0.86 | ✅ | |
| targeted_removal | 0.83 | ✅ | |
| board_wipe | 0.90 | ✅ | |
| protection | 0.82 | ✅ | |
| recursion | 0.86 | ✅ | |
| graveyard_synergy | 0.72 | ✅ | |
| token_maker | 0.82 | ✅ | |
| sacrifice_outlet | 0.80 | ✅ | |
| aristocrat_payoff | 0.84 | ✅ | |
| lifegain | 0.76 | ✅ | |
| drain | 0.82 | ✅ | |
| spellslinger | 0.84 | ✅ | |
| artifact_synergy | 0.74 | ✅ | |
| enchantment_synergy | 0.74 | ✅ | |
| etb | 0.70 | ✅ | |
| blink | 0.86 | ✅ | |
| big_spell | 0.72 | ✅ | |
| exile_value | 0.84 | ✅ | |
| wincon | 0.78 | ✅ | |
| combo_piece | 0.60 | 🟡 | Propositalmente baixo |
| engine | 0.70 | ✅ | |
| payoff | 0.72 | ✅ | |
| enabler | 0.70 | ✅ | |

### Gaps Confirmados (inalterados)
1. 🟡 `fight` não detectado como remoção
2. 🟡 `'rather than pay'` no oracle text para counterspells — Force of Will detectada como protection, não removal
3. 🟡 `goad`/`must attack` effects não capturados
4. 🟡 `_estimateManaValue()` não trata `{C}` (incolor genérica)
5. 🟡 `cmc_safety.dart` dependência — se manaCost também vazio, fallback retorna 0.0

---

## 7. edh_bracket_policy.dart — Auditoria do Sistema de Bracket (547 linhas)

**Status:** 🟢 **ATIVO EM PRODUÇÃO.** Última modificação: 2026-06-11 (03:24). **Inalterado desde v12.0.**

**🆕 NOVO v13.0: Arquivo MOVIDO** de `server/lib/ai/edh_bracket_policy.dart` para `server/lib/edh_bracket_policy.dart`. O conteúdo é idêntico. A documentação do domínio (`manaloom-mtg-domain` §13, Gap 27) referencia o caminho antigo.

### Sistema de 11 Categorias

| Categoria | Heurística | Cartas curadas | Coverage |
|:----------|:----------:|:--------------:|:--------:|
| fastMana | Nomes curados (12) | 12 | 🟡 Mínimo viável |
| fastManaLand | Nomes curados (5) | 5 | 🟡 |
| tutor | Oracle text: `search your library` NOT land | Dinâmico | ✅ |
| extraTurns | Oracle: `extra turn` | Dinâmico | ✅ |
| freeInteraction | Nomes curados (9) + oracle `without paying` | 9 + dinâmico | ✅ |
| infiniteCombo | Nomes curados (3) | 3 | 🔴 MUITO RESTRITIVO |
| boardWipe | Oracle + nomes curados (2) | 2 + dinâmico | 🟡 |
| cardAdvantage | Nomes curados (7) + oracle | 7 + dinâmico | ✅ |
| stax | Nomes curados (12) + oracle | 12 + dinâmico | ✅ |
| protection | Nomes curados (6) + oracle | 6 + dinâmico | ✅ |
| valueEngine | Nomes curados (5) | 5 | 🟡 Mínimo viável |
| **gameChanger** | **53 nomes curados** (linhas 354-408) | **53** | **✅ Definição canônica** |

### Gaps Confirmados (inalterados)
1. 🔴 Underworld Breach não está em `_knownInfiniteComboPieces` (linhas 347-351)
2. 🔴 `_knownInfiniteComboPieces` dramaticamente pequeno: apenas 3 cartas
3. 🟡 `_looksLikeGameChangerBoardWipe()` não cobre Blasphemous Act, Terminus, Settle
4. 🟡 `_looksLikeGameChangerStax()` não cobre Trinisphere, Smokestack, Tangle Wire
5. 🟡 `_looksLikeGameChangerProtection()` não cobre Boros Charm

### GC Source of Truth (reconfirmado v13.0)

Lista do produto (53 GCs, `edh_bracket_policy.dart:354-408`) — **NÃO usar lista da Wizards.**

- **47/53 (88.7%)** presentes no oracle_cache ✅
- **3/53 (5.7%)** legais perdidos: Panoptic Mirror, Serra's Sanctum, Tergrid 🔴
- **3/53 (5.7%)** banned: Biorhythm, Braids, Coalition Victory 🟡
- **🔴 NENHUMA MUDANÇA desde v12.0**

---

## 8. SQLite Health Check — knowledge.db (2026-06-15T14:00Z)

### Schema
**15 tabelas.** Deck único: `Runtime Lorehold Learned 19e93de3cca` (id=6, 100 cartas).

### Métricas de Saúde

| Métrica | v12.0 | v13.0 | Mudança |
|:--------|:-----:|:-----:|:-------:|
| CMC corrupted (NULL/0.0) | 35/100 (35%) | **35/100 (35%)** | 🔴 Inalterado |
| Decks | 1 | 1 | ↔️ |
| Deck cards | 100 | 100 | ↔️ |
| Unknown functional tags | 0 | 0 | ✅ |
| Oracle cache rows | 3217 | **3217** | ↔️ |
| GCs missing (legais) | 3 | **3** | 🔴 Inalterado |
| Slot benchmarks | 115 | 115 | ↔️ |
| Quality reviews: passed | 120 | 120 | ↔️ |
| Quality reviews: blocked | 3 | 3 | ↔️ |

### Achados Novos do SQLite (v13.0)

1. **🔴 Git index error persiste:** `mmo-preflight01` e `d4e5f6a7b8c9` ambos falham com exit code 128. Últimas execuções: preflight 13:26Z (579 bytes — output indicando erro), validator 13:57Z (578 bytes). **Nenhuma melhora.**
2. **🟡 `deck_promotions` table ainda ausente:** auto-promote falhou em 2026-06-15 12:43 com `OperationalError: no such table: deck_promotions`. 34 execuções, 22+ erros.
3. **🟡 `battle_card_rules`:** 3156 regras — estável.

---

## 9. Análise de jobs.json — Crons com Skill Loading Failure

### Crons que Referenciam `manaloom-commander-knowledge` (inexistente)

| Cron | ID | Campo | Desde | Impacto |
|:-----|:---|:------|:------|:--------|
| **mtg-rules-auditor** | `c0591cb18024` | `skill` + `skills[]` | 2026-06-08 | 🔴 **CRON BROKEN** — 13+ execuções falhadas |
| **gamechanger-research** | `7915cc2377a0` | `skill` + `skills[]` | 2026-06-08 | 🟡 Pode causar skill dump — 117 execuções |
| **knowledge-synthesis** | `10a59b3bdf4d` | `skills[]` | 2026-06-08 | 🟡 Fallback funciona — 63 execuções |
| **tag-accuracy-reporter** | `b340374bc4e7` | `skill` + `skills[]` | 2026-06-08 | 🟡 PAUSADO |

### Correção Necessária em jobs.json (idêntica à v12.0 — SEM CORREÇÃO)

| Linha | Cron | Correção |
|:-----|:-----|:---------|
| 216-219 | gamechanger-research | `skill: "manaloom-commander-knowledge"` → `"manaloom-mtg-domain"` |
| 303-306 | tag-accuracy-reporter (PAUSADO) | `skill: "manaloom-commander-knowledge"` → `"manaloom-mtg-domain"` |
| 537-539 | knowledge-synthesis | Remover `"manaloom-commander-knowledge"` de `skills[]` |
| **586-589** | **mtg-rules-auditor (ESTE CRON)** | **`skill: "manaloom-commander-knowledge"` → `"manaloom-mtg-domain"`** |

**🔴 Todos os 4 crons continuam sem correção. Documentado em 5 versões consecutivas (v8.0–v13.0).**

---

## 10. Plano de Correções (ordenado por impacto)

### 🔴 CRÍTICO (1-3)
1. **🔴 [jobs.json] Corrigir 4 crons que referenciam `manaloom-commander-knowledge`:** Trocar para `manaloom-mtg-domain`. **Incluindo este cron (mtg-rules-auditor) — 13+ execuções falhadas.**
2. **🔴 [goldfish_simulator.dart] Adicionar detecção de "enters the battlefield tapped":** ~5 linhas de código, impacto direto na precisão do T3 em ~3-8pp.
3. **🔴 [SQLite] Corrigir sync dos 3 GCs legais perdidos:** Panoptic Mirror, Serra's Sanctum, Tergrid (DFC).

### 🟡 ALTO (4-7)
4. **🟡 [Git Workspace] Limpar git index corrompido:** exit code 128 afeta 2 crons ativos (preflight + validator).
5. **🟡 [SQLite] Criar tabela `deck_promotions`:** Script `auto_promote_learned_decks.py` precisa dela — 34 execuções, 22+ falhas.
6. **🟡 [goldfish_simulator.dart] Refinar T1 ramp detection:** Land Tax, Weathered Wayfarer não produzem mana no T1.
7. **🟡 [goldfish_simulator.dart] Melhorar fetchland color tracking.**

### 🟢 MÉDIO (8-11)
8. **🟢 [functional_card_tags.dart] Adicionar `fight` como heurística de remoção.**
9. **🟢 [edh_bracket_policy.dart] Expandir `_knownInfiniteComboPieces`:** Underworld Breach, Isochron Scepter, Dramatic Reversal.
10. **🟢 [edh_bracket_policy.dart] Expandir `_looksLikeGameChangerBoardWipe()`:** Blasphemous Act, Terminus, Settle.
11. **🟢 [battle_simulator.dart] Adicionar flag `isCommander` em `GameCard`.**

### 🔵 BAIXO (12-15)
12. **🔵 [functional_card_tags.dart] Adicionar `goad`/`must attack` heurística.**
13. **🔵 [goldfish_simulator.dart] Adicionar suporte a `{C}` (incolor).**
14. **🔵 [git] Resolver ahead-26:** Branch está 26 commits ahead de origin.
15. **🔵 [docs] Atualizar `manaloom-mtg-domain` Skill:** Path do `edh_bracket_policy.dart` mudou de `server/lib/ai/` para `server/lib/`.

---

## 11. Mudanças desde v12.0

| Item | v12.0 | v13.0 | Status |
|:-----|:-----:|:-----:|:------:|
| CMC corrupted | 35/100 | 35/100 | 🔴 Inalterado |
| GCs missing (legais) | 3 | 3 | 🔴 Inalterado |
| battle_simulator.dart score | 2.0/10 | 2.0/10 | 🔴 Inalterado |
| goldfish_simulator.dart score | 7.0/10 | 7.0/10 | 🔴 Inalterado |
| MTG Rules Auditor cron | 0.0/10 | 0.0/10 | 🔴 Inalterado |
| Master Optimizer Preflight | 6.0/10 (git index) | 6.0/10 (exit 128) | 🔴 Persiste |
| Knowncards Validator | 🔴 git index | 🔴 exit 128 | 🔴 Persiste |
| edh_bracket_policy.dart path | `server/lib/ai/` | **`server/lib/`** | 🆕 **NOVO ACHADO** |
| **Score geral** | **4.5/10** | **4.5/10** | **🔴 Estagnada pelo 6º dia** |

### Único novo achado desde v12.0
1. **🆕 `edh_bracket_policy.dart` foi movido** de `server/lib/ai/` para `server/lib/`. Documentação do domínio desatualizada.

---

## 12. Conclusão

**Score geral: 4.5/10 🔴 BAIXA — ESTAGNADA PELO 6º DIA CONSECUTIVO.**

O ecossistema de crons do ManaLoom **não apresenta nenhuma melhora material** desde a v12.0 (12h atrás) e **nenhuma desde v11.0 (24h atrás)**. Os mesmos gaps críticos persistem:

- **MTG Rules Auditor cron continua broken** (13+ execuções falhadas por skill loading failure)
- **3 GCs do produto continuam perdidos do oracle_cache**
- **CMC corruption continua em 35% no deck único**
- **Git index corrompido afeta 2 crons ativos** — nenhuma melhora
- **jobs.json com 4 referências quebradas** a skill inexistente

**Pipeline score (cron mtg-rules-auditor autoavaliação): 0.0/10 🔴** — este cron não produziu auditoria real por 7+ dias. Esta execução (v13.0) é a segunda em que o cron produz conteúdo real via contorno manual do operador (a falha de skill loading foi contornada pela execução direta com o skill `manaloom-mtg-domain` disponível).

---

*Auditoria gerada em 2026-06-15T14:30:00+00:00 por Hermes Agent (cron mtg-rules-auditor c0591cb18024)*
*Branch: codex/hermes-analysis-docs | HEAD: b3008003*
