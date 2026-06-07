# MTG Rules Auditor v7.0 — Full Cron Pipeline Audit

**Run:** 2026-06-07 18:45Z | **Job ID:** c0591cb18024 | **Execution #7** (v3.7→v3.8→v3.9→v4.0→v5.0→v6.0→v7.0)

## ⚠️ PROMPT STALE — 7ª Execução Consecutiva

**Este cron está na sua 7ª execução consecutiva com prompt desatualizado.** O prompt referencia 5 IDs de crons descomissionados (`f20ac299992b`, `712579b15767`, `08468451a06a`, `94f8590b1beb`, `a50bef4c2a59`) cujos diretórios de output foram removidos em 2026-06-04. Esta execução ignora essas referências e audita os **24 crons ativos** no `jobs.json`.

**Ação imediata necessária:** Atualizar o prompt do `mtg-rules-auditor` no `jobs.json` para remover as referências obsoletas.

## Pipeline Score

| Cron | Nota | Confiabilidade | MTG Rules OK? | Gaps |
|:-----|:----:|:--------------|:--------------|:-----|
| Commander Knowledge Deep | 3.0/10 | 🔴 BAIXA | ❌ Battle Simulator citado como validação | Tasks P0 geradas com dados inválidos |
| Gamechanger Research | 3.0/10 | 🟡 MÉDIA | ⚠️ 53/53 identificado mas bracket_detection falho | 29/53 GCs não detectados por código |
| Mana Base Validator | 6.0/10 | 🟡 MÉDIA | ✅ Validação EDHREC correta | CMC corruption distorce métricas |
| Knowledge Synthesis | 0.0/10 | 🔴 QUEBRADO | N/A — não executa | HTTP 404 no provider desde Exec #9 |
| Tag Accuracy Reporter | 5.0/10 | 🟡 MÉDIA | ⚠️ Classificador tem 29 heurísticas mas 10%+ double-null | CMC=0 distorce precisão |
| Master Optimizer Preflight | 7.5/10 | 🟢 OK | ✅ Script-only, sem regras MTG | SQLite read-only RESOLVIDO |
| KC Validator | 7.0/10 | 🟢 OK | ✅ Classificação de cartas | Lock file stale RESOLVIDO |
| Knowncards Generator | 0.0/10 | 🔴 QUEBRADO | N/A — não executa | Script path errado, root-owned output |
| Universal Optimizer | 0.0/10 | 🔴 PAUSADO | ❌ Corta staples Commander | Battle Simulator inválido |
| Logic Coherence Auditor | 7.0/10 | 🟢 OK | ✅ Auditoria de código | — |
| Code Structure Auditor | 8.0/10 | 🟢 OK | ✅ Auditoria de estrutura | — |
| Normal Audit | 7.5/10 | 🟢 OK | ✅ Auditoria de projeto | HTTP 429 ocasional |
| Cron Governor | 8.0/10 | 🟢 OK | ✅ Report-only | — |
| **PIPELINE** | **3.0/10** | 🔴 **BAIXA** | | **0/11 correções aplicadas em 48h+** |

## Sumário Executivo

A pipeline de conhecimento Commander está em **3.0/10** — queda de 0.0 vs v6.0. Nenhum dos 11 itens do plano de correções do v4.0 foi aplicado. **Três novas falhas** detectadas no v6.0 foram parcialmente resolvidas (Master Optimizer Preflight e KC Validator voltaram a funcionar), mas a **regressão Tergrid**, **CMC corruption (142/543, 26.2%)**, **Battle Simulator em tasks P0**, e **Knowledge Synthesis quebrado** permanecem sem correção.

### 🔴 Crítico (P0 — quebra regras MTG)
1. **Commander Knowledge Deep gera tasks P0 com dados inválidos** (Exec #9-12 — 4 execuções consecutivas)
2. **CMC corrompido em 142 cartas (26.2%)** — 48h+ sem correção
3. **Knowledge Synthesis quebrado** — HTTP 404 no provider `opencode-go`
4. **Tergrid oracle_text vazio** — regressão confirmada (skill diz "RESOLVIDO", DB mostra `''`)

### 🟡 Alto (P1 — distorce resultados)
5. **Gamechanger bracket detection incompleta** — 29/53 GCs (54.7%) não detectados
6. **Knowncards Generator quebrado** — script path errado + root-owned output
7. **Universal Optimizer propõe cortar staples Commander** — bloqueado por PermissionError



## Commander Knowledge Deep — Auditoria Detalhada

**Job ID:** 75eed994c103 | **Score:** 3.0/10 🔴 BAIXA

### O que faz certo
- Analisa 1 commander/deck por ciclo com evidência real (Lorehold, Krenko, etc.)
- Gera COMMANDER_DEEP_REPORT.md com padrões de ramp/draw/removal/wincon
- Identifica gaps estruturais (apenas 4 removal/wipe no Lorehold)

### O que faz errado — VIOLAÇÕES DE REGRAS MTG
1. **Cita Battle Simulator como "BATTLE-VALIDATED" — 4 execuções consecutivas (#9-12):**
   - Exec #9 (02:02Z): "84.5% aggregate win rate, BATTLE-VALIDATED"
   - Exec #10 (05:10Z): "6 swaps battle-validados" com WR 89.5%
   - Exec #11 (15:29Z): **Gera tasks P0** ("Apply Slot Optimizer Phase 3 Findings", "Integrate Master Optimizer as Cron Pipeline")
   - Exec #12 (18:34Z): "Wheel of Misfortune replaced Reforge the Soul — WR 85.3% → 89.3% (+4.0pp)"
   - O `battle_simulator.dart` (linha 9) declara "Sem stack complexo (resolução imediata)"
   - **NÃO implementa:** stack/priority (CR 117.3-117.4), Commander damage (CR 903.10a), Commander tax (CR 903.8), multiplayer (CR 802.1a), ETB triggers
   - **Tasks P0 têm precedência** sobre o backlog — sistema instruído a priorizar ações baseadas em dados inválidos

2. **Git push falha consistentemente** — commits locais (`03e09d30`, `6a828c6a`, `47518102`, `db6eb67a`) não pushados. Credenciais GitHub ausentes no ambiente cron.

### Verificações Scryfall (2026-06-07 18:45Z)
- Worldfire: CMC=9, Commander=**legal** ✅
- Mana Crypt: CMC=0, Commander=**banned** ✅

### Recomendações
1. 🔴 Adicionar disclaimer obrigatório em toda análise que citar Battle Simulator
2. 🔴 Remover "BATTLE-VALIDATED" do léxico; usar "SIMULATION-INDICATED"
3. 🔴 Não gerar tasks P0 baseadas exclusivamente em dados do Battle Simulator
4. 🟡 Configurar GitHub PAT no ambiente cron para destravar git push




## Gamechanger Research — Auditoria Detalhada

**Job ID:** 7915cc2377a0 | **Score:** 3.0/10 🟡 MÉDIA (piorou: v6.0 era 4.0)

### O que faz certo
- 53/53 Game Changers identificados e catalogados com `why_game_changer`
- Pesquisa contínua de GCs via Scryfall + EDHREC
- Gera `GAMECHANGER_RESEARCH_REPORT.md` com tabela de lacunas

### O que faz errado — VIOLAÇÕES DE REGRAS MTG
1. **Bracket detection incompleta (Gap 3):** `edh_bracket_policy.dart` cobre apenas 5/12 categorias. 29/53 GCs (54.7%) não são detectados pelo código Dart. 7 categorias faltam: `card_advantage` (5 GCs), `board_wipe` (2), `stax` (7), `value_engine` (9), `protection` (1), `free_interaction_flex` (1), `fast_mana_land` (3).

2. **5 erros de categorização no SQLite** — Force of Will como `value_engine`, Field of the Dead com `manaloom_detected=1` (falso positivo).

3. **Tergrid regressão CONFIRMADA (Scryfall, 2026-06-07 18:45Z):**
   - Scryfall API: `oracle_text` é NULL no objeto raiz (DFC). Dados estão em `card_faces[0].oracle_text` e `card_faces[1].oracle_text`
   - DB: `oracle_text = ''` (string vazia, não NULL)
   - A "resolução" (v3.9) apenas converteu NULL → `''` sem popular o oracle real
   - Tergrid permanece **invisível para heurísticas** baseadas em oracle_text

4. **8 cartas Reserved List com `price_usd=NULL`** — Lion's Eye Diamond, Mishra's Workshop, etc. Scryfall retorna null para RL prices.

### Recomendações
1. 🔴 Reimportar Tergrid via Scryfall buscando por face frontal ("Tergrid, God of Fright"), ler `card_faces[0].oracle_text`
2. 🟡 Implementar 7 categorias faltantes no `edh_bracket_policy.dart`
3. 🟡 Marcar cartas RL como `RESERVED_LIST` ao invés de NULL no price




## Mana Base Validator — Auditoria Detalhada

**Job ID:** 444aa9510c2c | **Score:** 6.0/10 🟡 MÉDIA

### O que faz certo
- Valida lands/ramp/draw contra perfis EDHREC reais (32 commander profiles)
- Detecta INCOMPLETE decks (Kinnan #1 13 cartas, Korvold #3 11 cartas)
- Git push tenta 2x com pull --rebase antes de desistir

### O que faz errado — VIOLAÇÕES DE REGRAS MTG
1. **CMC systemic corruption:** `decks.avg_cmc` diverge de `AVG(cmc) WHERE cmc>0` em 6/7 decks. Lorehold (#6): stored 1.79 vs computed 3.14 (delta +1.35). 36% de cartas com CMC NULL no deck 6. Curva de mana reportada é inválida.

2. **Tags NULL:** Yuriko (#2) com 25% de cartas sem `functional_tag` — pior caso.

3. **Role de ramp não mapeado:** `role_targets` do perfil EDHREC (ex: `ramp_extra_lands`) não mapeiam 1:1 para `functional_tag` no `deck_cards`. Apenas `lands` é diretamente comparável.

4. **Sem verificação de legalidade Commander:** O validator não checa se cartas no deck são banned em Commander (usa `knowledge.db` local, que pode estar desatualizado).

### Recomendações
1. 🔴 Corrigir CMC via `fix_cmc_batch.py` (pendente desde 2026-06-05)
2. 🟡 Rodar sync de legalidades antes de validar: `manaloom-sync-legalities.sh`
3. 🟡 Mapear `PROFILE_ROLE_TO_TAG` para comparar ramp/draw além de lands




## Knowledge Synthesis — Auditoria Detalhada

**Job ID:** 10a59b3bdf4d | **Score:** 0.0/10 🔴 QUEBRADO

### Status
- **Exec #9 (12:23Z):** `RuntimeError: HTTP 404 — Not Found | opencode`. Provider `opencode-go` ou modelo não encontrado.
- **Exec #10 (16:29Z):** Voltou a funcionar — gerou output de 74KB com IMPLEMENTATION_TASKS.md e análise de código.
- Porém: **a falha 404 é recorrente** (2 das últimas 10 execuções) e o provider `opencode-go` é diferente dos demais crons que usam `deepseek-pro`.

### O que faz certo (quando funciona)
- Cruza conhecimento MTG (game changers, tags, perfis) com código Dart real
- Lê `functional_card_tags.dart`, `optimize_runtime_support.dart`, `optimization_quality_gate.dart`
- Gera tasks de implementação específicas com arquivo/linha

### Problemas
1. Provider `opencode-go` diferente do resto da frota (`deepseek-pro`) — inconsistência
2. Sem fallback quando o provider falha — fica sem IMPLEMENTATION_TASKS.md por horas

### Recomendações
1. 🔴 Migrar para provider `deepseek-pro` como o resto da frota
2. 🟡 Adicionar retry com backoff para erros 404
3. 🟡 Verificar se `opencode-go` está corretamente configurado no `jobs.json`




## Master Optimizer Preflight — Auditoria Detalhada

**Job ID:** mmo-preflight01 | **Score:** 7.5/10 🟢 OK (RESOLVIDO do v6.0)

### Status
- **v6.0:** 43 falhas consecutivas — `sqlite3.OperationalError: attempt to write a readonly database`
- **v7.0:** ✅ RESOLVIDO. Exec #51 (18:35Z) passou com `status: approved`. Todos os checks OK (knowledge_db, battle, slot_optimizer, metadata_sync, oracle_cache_coverage).
- `sync_pg_card_metadata_to_hermes.py` voltou a funcionar: 3377 nomes únicos, 3573 matches PG, 3464 cache rows, apenas 10 unresolved.

### O que faz
- Script-only (no_agent=true), sem regras MTG — verifica arquivos, compila, e sincroniza metadados PG→SQLite
- Preflight para Master Optimizer — checa se todos os scripts e dados estão prontos

### Pontos de atenção
1. **Battle Simulator usado para validação:** `battle_regression: ok` — o script testa `battle_analyst_v8.py`, que é o simulador 2-player sem regras Commander oficiais. O preflight aprova um simulador inválido.
2. **10 unresolved cards** no cache — podem incluir GCs ou staples não mapeadas.

### Recomendações
1. 🟡 Adicionar verificação de regras Commander no `battle_regression` check
2. 🟡 Reportar quais são as 10 unresolved cards




## KC Validator — Auditoria Detalhada

**Job ID:** d4e5f6a7b8c9 | **Score:** 7.0/10 🟢 OK (RESOLVIDO do v6.0)

### Status
- **v6.0:** "LOCKED (5420s). Exiting." — lock file stale por 1.5h
- **v7.0:** ✅ RESOLVIDO. Exec #69 (18:39Z): 500 cartas validadas, 0 correções, 0 conflitos.
- Expansão de pool: 2000 cartas PG, 783 Lorehold unique, 43 matches PG.
- Effect distribution: draw_cards=440, ramp_permanent=311, token_maker=208, etc.

### O que faz
- Script-only, classifica cartas por efeitos funcionais (known_cards_generated.json)
- Valida classificações existentes contra PG

### Pontos de atenção
1. **0 conflitos em 500 cartas** — suspeito. Execuções alternam entre 0-4 conflitos. Pode indicar amostragem não-determinística.
2. **Sem verificação contra Scryfall oracle_text** — depende apenas de classificação heurística local.

### Recomendações
1. 🟡 Adicionar seed determinística para reprodutibilidade
2. 🟡 Cross-check com Scryfall para cartas com oracle_text vazio




## Knowncards Generator — Auditoria Detalhada

**Job ID:** b9c8a7d6e5f4 | **Score:** 0.0/10 🔴 QUEBRADO

### Status
- Script path errado: aponta para `/root/.hermes/scripts/generate_known_cards.py` (não existe)
- Bloqueado: "script path resolves outside the scripts directory"
- Output `known_cards_generated.json` é root-owned (PermissionError)
- Última execução: 2026-06-06 04:07Z (2 completions total, nenhuma recente)

### Recomendações
1. 🔴 Corrigir script path no `jobs.json` para path real
2. 🔴 `sudo chown hermes:hermes scripts/known_cards_generated.json`

## Universal Optimizer — Auditoria Detalhada

**Job ID:** c8d9e0f1a2b3 | **Score:** 0.0/10 🔴 PAUSADO

### Status
- **PAUSADO** desde 2026-06-07 00:15Z: "superseded_by_safe_master_optimizer_slot_scan"
- Última execução falhou com PermissionError em `battle_analyst_v8.py` (root-owned)
- Propõe cortar **Smothering Tithe** (40%+ EDHREC) e **Imperial Recruiter** (staple combo) baseado em Battle Simulator 2-player sem stack

### Violações de regras MTG
1. Battle Simulator não implementa regras oficiais de Commander
2. Cortar staples baseado em simulação inválida degrada o deck contra jogo real
3. CMC corruption (26.2%) distorce seleção de candidatos

### Recomendações
1. ✅ Manter PAUSADO até Battle Simulator implementar regras Commander oficiais
2. 🟡 Se reativar: adicionar heurística — nunca cortar cartas com EDHREC ≥ 30%




## Plano de Correções (ordenado por impacto, v7.0)

### 🔴 P0 — Imediato (quebra regras MTG ou impede funcionamento)

| # | Item | Status v6.0 | Status v7.0 | Ação |
|:--|:-----|:------------|:------------|:-----|
| 1 | Atualizar prompt do mtg-rules-auditor | ❌ Stale (5ª exec) | ❌ Stale (7ª exec) | Remover 5 IDs descomissionados do prompt |
| 2 | Commander Knowledge Deep — remover "BATTLE-VALIDATED" | ❌ Exec #11 | ❌ Exec #12 | Adicionar disclaimer obrigatório |
| 3 | Corrigir CMC corruption (142/543, 26.2%) | ❌ 48h+ | ❌ 48h+ | Rodar `fix_cmc_batch.py` |
| 4 | Corrigir Tergrid oracle_text (regressão) | ❌ | ❌ Confirmado | Reimportar via Scryfall card_faces |
| 5 | Corrigir Knowledge Synthesis — HTTP 404 | ❌ Nova | 🟡 Parcial | Migrar provider para `deepseek-pro` |

### 🟡 P1 — Alto (distorce resultados)

| # | Item | Status | Ação |
|:--|:-----|:-------|:-----|
| 6 | Implementar 7 categorias GC faltantes no `edh_bracket_policy.dart` | ❌ | Adicionar heurísticas para 29 GCs não detectados |
| 7 | Corrigir Knowncards Generator script path | ❌ | Apontar para path real |
| 8 | `sudo chown` root-owned files nos scripts/ | 🔴 Bloqueia 3 crons | `sudo chown -R hermes:hermes scripts/known_cards_generated.json scripts/battle_analyst_v8.py` |
| 9 | Configurar GitHub PAT no ambiente cron | ❌ 4+ commits não pushados | Adicionar `GITHUB_TOKEN` ou SSH key |

### 🟢 P2 — Médio (imprecisões)

| # | Item | Status | Ação |
|:--|:-----|:-------|:-----|
| 10 | Sync de legalidades antes de validar decks | ❌ | `manaloom-sync-legalities.sh` antes de cada validação |
| 11 | KC Validator — seed determinística | 🟡 Parcial | Adicionar seed para reprodutibilidade |

## Conclusão

A pipeline de conhecimento Commander está em **3.0/10** — estagnada desde v6.0. Nenhum dos 11 itens do plano de correções anterior foi aplicado. Três falhas detectadas no v6.0 foram resolvidas (Master Optimizer Preflight, KC Validator LOCKED), mas as **4 falhas críticas de regras MTG** permanecem sem correção.

### Mudanças vs v6.0
- **Master Optimizer Preflight:** ✅ RESOLVIDO — SQLite read-only corrigido
- **KC Validator:** ✅ RESOLVIDO — Lock file stale resolvido
- **Knowledge Synthesis:** 🟡 PARCIAL — Exec #10 (16:29Z) funcionou, mas provider `opencode-go` é instável
- **Prompt mtg-rules-auditor:** ❌ AINDA STALE — 7ª execução consecutiva sem correção
- **Battle Simulator em tasks P0:** ❌ AINDA ATIVO — Exec #12 (18:34Z) continua citando WR do simulador
- **CMC corruption:** ❌ INALTERADO — 142/543 (26.2%), mesmo valor de 48h atrás
- **Tergrid:** ❌ REGRESSÃO CONFIRMADA — oracle_text é string vazia

### O pipeline Lorehold (descomissionado) não será ressuscitado
Os 5 crons removidos em 2026-06-04 permanecem descomissionados. O Death Loop foi resolvido por remoção. O código Dart (`battle_simulator.dart`, `functional_card_tags.dart`, `edh_bracket_policy.dart`) permanece no repo mas sem crons ativos. NÃO recriar estes crons sem antes:
1. Corrigir `battle_simulator.dart` (stack/priority, Commander damage/tax, multiplayer)
2. Corrigir `edh_bracket_policy.dart` (7 categorias faltantes)
3. Configurar GitHub credentials no ambiente cron

**Próximo passo automático:** O `mtg-rules-auditor` executará novamente em ~3h. Se o prompt NÃO for atualizado, será a 8ª execução consecutiva com prompt stale.



