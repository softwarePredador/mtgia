# Plano de Ajustes — Crons e Geracao de Decks com IA

> Data: 2026-05-27
> Baseado em: ANALISE_CRONS_E_IA.md + validacao contra codigo atual
> Escopo: docs/hermes-analysis/** apenas (sem alteracao de codigo de produto)

---

## Estado Atual dos Crons (2026-05-27 18:00Z)

| # | Cron | Schedule | Status | Nota |
|:--|:-----|:---------|:-------|:-----|
| 1 | manaloom-master-watchdog | 30min | ok | Script bash, sem agent |
| 2 | manaloom-hermes-normal-audit | 16h/21h | ok | Skill: manaloom-project-auditor |
| 3 | manaloom-hermes-weekly-parallel | Dom 12:30 | ok | Skill: manaloom-project-auditor |
| 4 | manaloom-commander-knowledge-deep | 20min | **error** | ultimo run 17:46Z falhou |
| 5 | manaloom-gamechanger-research | 20min | ok | deepseek-v4-flash |
| 6 | manaloom-manager-watchdog | 30min | ok | Skill: manaloom-project-auditor |
| 7 | manaloom-tag-accuracy-reporter | 360min | ok | Proximo: 19:05Z |
| 8 | manaloom-mana-base-validator | 60min | **error** | ultimo run 17:24Z falhou |
| 9 | lorehold-deck-scout | 30min | ok | deepseek-v4-flash |
| 10 | lorehold-deck-validator | 60min | ok | deepseek-v4-flash |
| 11 | lorehold-mulligan-analyst | 120min | ok | deepseek-v4-flash |
| 12 | lorehold-evolution-oracle | 360min | ok | deepseek-v4-flash, **prompt diz "Auto-Pilot"** |

**Erros atuais: 2/12** (commander-knowledge-deep + mana-base-validator)

---

## P0 — Ajustes Criticos (impacto imediato)

### P0.1 — Corrigir nome do cron: "Auto-Pilot" → "Co-Pilot"

**Arquivo afetado:** Prompt do cron `lorehold-evolution-oracle` (job_id: `a50bef4c2a59`)

**Problema:** O prompt atual diz "Agente 4: Lorehold Evolution Auto-Pilot — Aprenda e Evolua". O usuario quer CO-PILOT (analise + recomendacao com justificativa), nao auto-pilot (aplica swaps automaticamente).

**Por que e critico:** O comportamento atual contradiz explicitamente o desejo do usuario. A cada 6h o evolution-oracle pode aplicar swaps no DB sem revisao humana.

**Mudanca necessaria:** O prompt do cron deve:
1. Ler SCOUT_LOG.md, VALIDATOR_LOG.md, MULLIGAN_LOG.md
2. Gerar recomendacoes de swap (max 3) com justificativa baseada em dados
3. Escrever recomendacoes em EVOLVE_RECOMMENDATIONS.md (novo arquivo)
4. **NAO aplicar swaps no DB** — apenas recomendar
5. Incluir secao "Como aplicar" com comandos SQL/Dart que o usuario pode executar

**Nota:** Como o cron roda no Hermes e o Hermes so permite escrita em `docs/hermes-analysis/**`, a restricao de escrita ja impede alteracao no DB do produto (knowledge.db esta fora do scope). Entao na pratica o cron JA nao consegue aplicar swaps no DB de produto. O risco e que o Hermes tente alterar o knowledge.db em `/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` (que e uma copia/analise separada). Mas o prompt deve deixar explicito que e so recomendacao.

### P0.2 — Corrigir erros dos 2 crons em estado error

**commander-knowledge-deep** (job_id: `75eed994c103`):
- Ultimo run: 17:46Z com `last_status=error`
- Prompt precisa de revisao para incluir no-change short-circuit (igual aos crons de auditoria)
- Workdir correto: `/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge` (ja corrigido pelo manager-watchdog)

**mana-base-validator** (job_id: `444aa9510c2c`):
- Ultimo run: 17:24Z com `last_status=error`
- Provavel causa: formato de output ou permissao no SQLite
- Prompt precisa de melhor tratamento de erro + fallback

---

## P1 — Alta Impacto (qualidade da geracao de IA)

### P1.1 — Otimizador usa single-tag quando deveria usar multi-tag

**Arquivo de codigo:** `server/lib/ai/optimization_quality_gate.dart` linha 52-53 (FORA DO SCOPE — documentar apenas)

**Estado atual:** `filterUnsafeOptimizeSwapsByCardData()` usa `classifyOptimizationFunctionalRole()` (single-tag) para determinar se um swap e seguro. Multi-tag (`inferFunctionalCardTags()`) existe mas nao e usado pelo gate.

**Impacto:** Cartas dual-function sao classificadas por apenas 1 tag. Smothering Tithe = `draw` (perde `ramp`). Boros Charm = `removal` (perde `protection`). O gate pode bloquear swaps que na verdade preservam funcoes.

**Recomendacao (documentacao):** Criar engajamento com o time de produto para:
1. Mudar `optimization_quality_gate.dart` para usar `inferFunctionalCardTags()` 
2. Comparar ambas as tags (removed e added) verificando se TODAS as funcoes sao preservadas ou melhoradas
3. Aceitar swap se o added_card tem todas as funcoes do removed_card + possiveis melhorias

### P1.2 — Semantic V2 em shadow mode (sem poder de veto)

**Arquivo de codigo:** `server/lib/ai/optimization_functional_roles.dart` linha 348: `enforcement: 'disabled'`

**Estado atual:** A camada semantica V2 calcula `role_delta` (quantas funções de cada tipo foram perdidas/ganhas) mas nao bloqueia nenhum swap. O `OptimizationSemanticV2EnforcementDecision` existe mas `blockedBySemanticV2` nunca e true porque `mode = disabled`.

**Recomendacao (documentacao):** Promover para `partial`:
1. Mudar `enforcement` para `'partial'` no builder
2. Quando `criticalLossRoles` contiver `draw`, `removal`, `ramp` ou `wipe` com delta negativo, bloquear o swap
3. Adicionar log de diagnostico no output da otimizacao

### P1.1.3 — EDHREC inclusion rate nao e usado como sinal de qualidade

**Arquivo de codigo:** `server/lib/ai/candidate_quality_data_support.dart` (FORA DO SCOPE)

**Estado atual:** O `CandidateQualityData` usa `meta_deck_count` (EDHTop16) mas nao `edhrec_inclusion_pct`. Cartas com alta inclusao em decks casuais mas baixa em torneios sao penalizadas.

**Recomendacao (documentacao):** Adicionar campo `edhrecInclusionPct` no schema e usar como sinal secundario. Cartas com >50% EDHREC inclusion devem ter bonus no score.

---

## P2 — Medio Impacto (robustez e completude)

### P2.1 — Bracket Policy: categorias faltantes

**Arquivo de codigo:** `server/lib/edh_bracket_policy.dart` (FORA DO SCOPE — documentar para time de produto)

**Categorias que faltam:**

| Categoria | Cartas que cobre | GCs afetados |
|:----------|:-----------------|:-------------|
| board_wipe (GC) | Cyclonic Rift, Farewell | 2 GCs |
| card_advantage (GC) | Rhystic Study, The One Ring, Necropotence, Consecrated Sphinx, Ad Nauseam | 5 GCs |
| stax (GC) | Drannith Magistrate, Opposition Agent, Notion Thief, Orcish Bowmasters, Narset | 5 GCs |
| value_engine (GC) | Seedborn Muse, Tergrid | 2 GCs |
| combo_piece (expandido) | Alem dos 3 atuais, adicionar: Underworld Breach loops, Bomba+Dockside | varios |

**Total: ~14 GCs a mais detectados com essas categorias**

### P2.2 — Metrics por tema nao sao usadas na validacao

**Estado atual:** `optimization_quality_gate.dart` usa `_criticalRolesForArchetype()` com apenas 3 archetypes: aggro, control, midrange. Os 42 temas do THEMES.md (Goblins, Vampires, Dragons, etc.) nao tem ranges especificos.

**Recomendacao (documentacao):** Expandir `_criticalRolesForArchetype()` para incluir temas tribais, usando os ranges do THEMES.md. Exemplo: Goblins precisa de `creature` density >= 25, `haste` enablers >= 6.

### P2.3 — Reconstruction do deck apos swaps

**Estado atual:** Depois que swaps sao aplicados, o `functional_tag` das cartas trocadas nao e recalculado. Se o deck evolui de cycle para cycle, as tags ficam stale.

**Recomendacao (documentacao):** Apos aplicar swaps, executar `inferFunctionalCardTags()` nas cartas adicionadas e recalcular metricas antes de escrever o EVOLUTION_LOG.

### P2.4 — Prompt do commander-knowledge-deep (em error)

O cron `commander-knowledge-deep` esta em error. O prompt precisa de:
1. No-change short-circuit (se nao ha nada novo desde ultima execucao, sair)
2. Melhor tratamento de erro HTTP 429 (retry com backoff)
3. Workdir correto (ja corrigido para `docs/hermes-analysis/manaloom-knowledge`)

### P2.5 — Prompt do mana-base-validator (em error)

O cron `manaloma-base-validator` esta em error. O prompt precisa de:
1. Validar se o SQLite e acessivel antes de tentar query
2. Fallback: se knowledge.db nao existir, criar schema antes
3. Tratamento de erro com mensagem acionavel

---

## P3 — Melhorias Continuas (backlog)

### P3.1 — Expandir perfis de referencia
- 11 perfis existem, faltam ~20 comandantes populares
- Proximos: Spellslinger (Prosper/Niv-Mizzet), Graveyard (Muldrotha/Meren), Tokens, Counters, Voltron

### P3.2 — Triangular EDHREC + Moxfield
- EDHREC ja e fonte primaria
- Moxfield primers sao mais detalhados mas requerem parsing HTML
- Usar como fonte secundaria para validacao

### P3.3 — Tag accuracy reporter expandido
- Quantificar multi-tag vs single-tag
- Medir taxa de falsos positivos/negativos por tema
- Reportar por comandante, nao so global

### P3.4 — GC research completar os 53
- 4/53 com analise completa
- Remaining: 49
- Priorizar GCs que o ManaLoom nao detecta (P2.1)

---

## Resumo de Prioridades

| Prioridade | Ajustes | Impacto | Esforço |
|:-----------|:--------|:--------|:--------|
| **P0** | 3 ajustes (co-pilot, 2 erros) | Critico | Baixo (mudanca de prompt) |
| **P1** | 3 ajustes (multi-tag, semantic v2, EDHREC pct) | Alto | Medio (mudanca de codigo) |
| **P2** | 5 ajustes (bracket, temas, reconstruction, 2 prompts) | Medio | Medio |
| **P3** | 4 melhorias (perfis, Moxfield, tag accuracy, GC research) | Baixo | Alto |

**Total: 15 ajustes documentados.**
