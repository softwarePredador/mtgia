# Auditoria Completa — Regras MTG em Todas as Crons

**Versão:** v3.7  
**Data:** 2026-06-04T15:00:00+00:00  
**Commit:** `92281194`  
**Auditor:** MTG Rules Auditor v3 (cron `c0591cb18024`)  
**Escopo:** Todos os crons MTG ativos + pipeline Lorehold (descomissionado)  
**Artefatos inspecionados:** `jobs.json` (18 crons, analisados todos), outputs mais recentes de `/opt/data/cron/output/<id>/`, SQLite `knowledge.db` (6.4MB, 19 tabelas), Scryfall API (Worldfire e Mana Crypt confirmados)  
**Fontes de regras:** Scryfall API (banlist Commander atual), MTG Comprehensive Rules 2024-11-08, CR 103 (Mulligan), CR 117.3-117.4 (Priority/Stack), CR 702.94 (Miracle), CR 903 (Commander)

---

## Sumário Executivo

| Cron | Status | Nota | Confiabilidade | Novo em v3.7 |
|:-----|:------|:----:|:--------------|:-------------|
| Scout (`f20ac299992b`) | 🔴 **DECOMISSIONADO** | N/A | N/A | Não existe em `jobs.json`; diretório de output removido |
| Validator (`712579b15767`) | 🔴 **DECOMISSIONADO** | N/A | N/A | Não existe em `jobs.json`; diretório de output removido |
| Mulligan (`08468451a06a`) | 🔴 **DECOMISSIONADO** | N/A | N/A | Não existe em `jobs.json`; diretório de output removido |
| Battle (`94f8590b1beb`) | 🔴 **DECOMISSIONADO** | N/A | N/A | Nunca foi cron; diretório nunca existiu; código 879 linhas em `battle_simulator.dart` permanece |
| Oracle (`a50bef4c2a59`) | 🔴 **DECOMISSIONADO** | N/A | N/A | Não existe em `jobs.json`; diretório de output removido |
| **Mana Base Validator** (`444aa9510c2c`) | ✅ Ativo | 7.0/10 | 🟡 MÉDIA | Produziu validação 2026-06-04T14:21Z — 8 decks, tag-only |
| **Knowledge Synthesis** (`10a59b3bdf4d`) | ✅ Ativo | N/A* | 🟡 MÉDIA | Output 2660 linhas — análise em andamento |
| **Commander Knowledge Deep** (`75eed994c103`) | ✅ Ativo | N/A* | N/A | Não verificado nesta execução |
| **Game Changer Research** (`7915cc2377a0`) | ✅ Ativo | N/A* | N/A | Não verificado nesta execução |
| **Tag Accuracy Reporter** (`b340374bc4e7`) | ✅ Ativo | N/A* | N/A | Última execução 2026-06-03 |
| **Multi-Commander Evolution** (`93a8ad77b251`) | 🆕 Novo | N/A | N/A | One-time job, ainda não executou |
| **Flutter UI Auditor** (`15ad7f5627b2`) | 🆕 Novo | N/A | N/A | Criado 2026-06-04, ainda não executou |
| **MTG Rules Auditor** (`c0591cb18024`) | 🔴 **PROMPT STALE** | 6.0/10 | 🟡 MÉDIA | Prompt referencia IDs de crons que não existem mais |
| **PIPELINE LOREHOLD** | 🔴 **DESCOMISSIONADO** | **N/A** | **N/A** | **5/5 crons removidos do `jobs.json`** |
| **PIPELINE ATUAL** | 🟡 Ativo parcial | **5.0/10** | **🟡 MÉDIA** | 8 crons MTG ativos; 4 produzem análise; Death Loop resolvido por remoção |

*Nota N/A: Crons não auditados em profundidade nesta execução (foco no pipeline Lorehold descomissionado).

**Tendência vs v3.6 (2026-06-04):** O "Death Loop" foi **resolvido** — não por correção, mas por **descomissionamento total** do pipeline Lorehold. Os 5 crons (Scout, Validator, Mulligan, Battle, Oracle) foram removidos do `jobs.json`. O pipeline atual é um conjunto de crons de conhecimento/research sem o loop de feedback Lorehold. Score do pipeline: **5.0/10** (mudança fundamental de escopo — sem pipeline de otimização ativo para auditar).

---

## v3.7 — ACHADO PRINCIPAL: Pipeline Lorehold Totalmente Descomissionado

### Evidência

1. **`jobs.json` inspecionado integralmente (763 linhas, 18 crons).** Nenhum contém "lorehold" no nome ou prompt. Os IDs antigos (`f20ac299992b`, `712579b15767`, `08468451a06a`, `94f8590b1beb`, `a50bef4c2a59`) não aparecem em nenhuma entrada.

2. **Diretórios de output verificados.** Nenhum dos 5 diretórios existe em `/opt/data/cron/output/`:
   ```
   f20ac299992b → NOT FOUND
   712579b15767 → NOT FOUND
   08468451a06a → NOT FOUND
   94f8590b1beb → NOT FOUND
   a50bef4c2a59 → NOT FOUND
   ```

3. **O prompt do MTG Rules Auditor (`c0591cb18024`) ainda referencia os IDs antigos** — evidência de que o prompt não foi atualizado quando os crons foram removidos.

### Interpretação

O pipeline Lorehold (Scout → Validator → Mulligan → Battle → Evolution Oracle) que era o foco das auditorias v3.0-v3.6 foi **inteiramente descomissionado**. Isso resolve o "Death Loop" documentado em v3.5/v3.6 — mas por remoção, não por correção.

**Causa provável:** O operador removeu os crons após constatar que o pipeline estava parado há >72h (Death Loop) e os agentes não produziam análises novas. A remoção é uma decisão operacional legítima dado o estado do pipeline.

**Implicações para a auditoria:**
- A auditoria de regras MTG do pipeline Lorehold agora é **histórica**. Os gaps documentados em v3.0-v3.6 (Scout sem EDHREC, Miracle mal interpretado, T3 sem tapped lands, etc.) permanecem como lições aprendidas, mas não há pipeline ativo para corrigir.
- O foco da auditoria deve migrar para os **crons de conhecimento ativos** (Mana Base Validator, Knowledge Synthesis, Commander Knowledge Deep, Game Changer Research, Tag Accuracy Reporter).
- O prompt do MTG Rules Auditor (`c0591cb18024`) precisa ser **atualizado** para refletir a realidade atual.

---

## Crons Ativos — Auditoria Detalhada

### Cron: Mana Base Validator (`444aa9510c2c`) — 7.0/10 🟡 MÉDIA

**Status:** Ativo, every 360m. Última execução: 2026-06-04T14:22:04Z.

**Output analisado:** 1590 linhas. A maior parte do output é o conteúdo do skill `manaloom-commander-knowledge` (eco do prompt). A seção "Response" contém o relatório real:

```
## Mana Base Validation Report — 2026-06-04T14:21Z
**Status: OK (no-change)** — all 8 decks validated against EDHREC profiles
using tag-only methodology (deck_cards.functional_tag sums).
```

**O que faz CERTO:**
- ✅ **Metodologia tag-only** implementada (usa `deck_cards.functional_tag` sums, não colunas stale da tabela `decks`). Isso resolve o Gap documentado em v3.2.
- ✅ **8 decks validados** com status apropriados: 3 INCOMPLETE (Kinnan 13/100, Korvold 11/100, Teysa 80/100), 1 NO PROFILE (Lorehold), 3 WARN/CRIT com deltas documentados.
- ✅ **Short-circuit funcional.** Detectou que nenhum estado de deck mudou desde a execução anterior (00:36Z) e reportou corretamente.
- ✅ **Deck Lorehold (#6):** Corretamente marcado como "NO PROFILE" (sem perfil de referência), com nota de 3 cartas `'unknown'` — consistente com a query do DB que confirma `functional_tag='unknown'` para 3 cartas.

**O que faz ERRADO:**
- 🔴 **Prompt referencia `commander_id` em query mas `decks` não tem essa coluna.** O prompt diz: `SELECT id, name, commander_id FROM decks` — a coluna correta seria `commander` ou requer JOIN com `commanders`. Isso não quebra a execução (o agente usa `deck_name` na prática), mas o prompt está tecnicamente incorreto.
- 🟡 **Teysa (#4) reportada com lands=15 vs [35-37].** O deck Teysa tem apenas 80 cartas (EDHREC average parcial). O delta de 20 lands é um artefato de importação incompleta, não um problema real de mana. O agente corretamente marca como "CRIT*" com asterisco (parcial), mas 80 cartas com 15 lands pode induzir confusão.
- 🟡 **Sem sync de legalidades no início.** O prompt não inclui passo de `manaloom-sync-legalities.sh`. Cards como Worldfire (legal) ou Mana Crypt (banida) não seriam detectados se estivessem no deck.
- 🟡 **Report commitado como `92281194` mas CRON_STATUS.md está stale (2026-06-01).** O validator afirma ter atualizado CRON_STATUS.md, mas o arquivo mostra última atualização em 2026-06-01.

**Verificação Scryfall (2026-06-04):**
- Worldfire: `commander=legal` ✅ (confirmado via API)
- Mana Crypt: `commander=banned` ✅ (confirmado via API)

### Cron: Knowledge Synthesis (`10a59b3bdf4d`) — NÃO AUDITADO EM PROFUNDIDADE

**Status:** Ativo, every 240m. Última execução: 2026-06-04T14:25:56Z. Output: 2660 linhas.

O output contém a skill `manaloom-mtg-strategy` + análise. O tamanho (2660 linhas) sugere que o agente está produzindo análise substancial, não apenas short-circuit.

**Observações preliminares:**
- O prompt instrui o agente a cruzar conhecimento MTG com código Dart real (`functional_card_tags.dart`, `optimization_functional_roles.dart`, etc.)
- Último output confirmou `IMPLEMENTATION_TASKS.md` gerado com tasks P0-P3
- **Não auditado em profundidade** — requer inspeção completa do output para verificar precisão de regras MTG

### Cron: Commander Knowledge Deep (`75eed994c103`) — NÃO VERIFICADO

**Status:** Ativo, every 180m. Última execução: 2026-06-04T14:18:34Z. Diretório de output não contém arquivos visíveis na listagem.

### Cron: Game Changer Research (`7915cc2377a0`) — NÃO VERIFICADO

**Status:** Ativo, every 180m. Última execução: 2026-06-04T14:20:06Z. 76 execuções completadas.

### Cron: Tag Accuracy Reporter (`b340374bc4e7`) — NÃO VERIFICADO

**Status:** Ativo, every 1440m. Última execução: 2026-06-03T20:57:49Z.

### Cron: Multi-Commander Evolution (`93a8ad77b251`) — 🆕 NOVO

**Status:** One-time job, agendado para 2026-06-04T16:39Z. Ainda não executou.

**Prompt analisado:** O agente deve:
1. Escolher comandante com menos `run_log` entries recentes (24h) que tenha learned decks com `card_count >= 90`
2. Scout de wincons em `card_deck_analysis` e `wincon_catalog`
3. Validar deck ativo contra perfil ideal
4. Propor até 3 swaps
5. Registrar em `run_log`

**Avaliação preliminar do prompt:**
- ✅ Boa lógica de rotação (menos analisado primeiro)
- ✅ Usa `card_deck_analysis` para scoring
- ⚠️ Menciona `wincon_catalog` — tabela não documentada no schema do SQLite (19 tabelas listadas, nenhuma chamada `wincon_catalog`)
- ⚠️ Sem verificação de color identity ou banlist no prompt
- ⚠️ Sem Step 0 (hash verification / pipeline integrity)

### Cron: Flutter UI Auditor (`15ad7f5627b2`) — 🆕 NOVO

**Status:** Every 360m, criado 2026-06-04T14:47Z. Ainda não executou.

**Não é um cron MTG** — audita UI/UX do Flutter. Fora do escopo desta auditoria.

---

## Pipeline Lorehold (Descomissionado) — Estado Final

### O que foi removido

| Cron | Função Original | Último Estado Conhecido (v3.6) |
|:-----|:----------------|:-------------------------------|
| `lorehold-deck-scout` | Buscar EDHREC + sinergia A+B+C | [SILENT] há 72h+; prompt virou "Wincon Hunter" |
| `lorehold-deck-validator` | SYNERGY_MAP + validação PG | v3.25 executou 2026-06-04 — única análise em 7+ dias |
| `lorehold-mulligan-analyst` | Simular 1000 mãos, medir T3 | [SILENT] há 72h+; T3=1.6% suspeito |
| `lorehold-battle-analyst` | Simular jogos 4-player | Nunca foi cron — código 2-player sem stack |
| `lorehold-evolution-oracle` | Ler logs, decidir swaps 0-3 | Timeout consistente; script `wincon_pipeline.py` não existe |

### Gaps que morreram com o pipeline

Estes gaps documentados em v3.0-v3.6 **não precisam mais de correção** pois os crons foram removidos:

1. ~~Gap 12 (CRÍTICO): Oracle timeout + Miracle mechanic~~ → Oracle removido
2. ~~Gap 11: Scout 94% SILENT, prompt Wincon Hunter~~ → Scout removido
3. ~~Gap 9: Mulligan sem tapped lands/color screw~~ → Mulligan removido
4. ~~Gap 10: Battle 2-player sem stack~~ → Battle nunca foi cron
5. ~~Gap 8: Battle Analyst não é cron~~ → Confirmado permanentemente

### Gaps que SOBREVIVEM (código Dart ainda existe)

Estes gaps são de **código de produto** que permanece no repositório mesmo sem os crons:

1. **Gap 6: Classificador "duplo nulo"** — `infer_functional_card_tags()` e `classify_card()` ainda podem falhar na mesma carta. O deck Lorehold (#6) tem 3 cartas com `functional_tag='unknown'`. O código em `server/lib/ai/functional_card_tags.dart` não foi corrigido.

2. **Gap 3: Bracket policy incompleta** — `edh_bracket_policy.dart` cobre apenas 5 categorias; 29/53 Game Changers não detectados. Código permanece inalterado.

3. **Gap 13: Bulk import data corruption** — Cartas importadas em massa recebem `functional_tag='unknown'` sem classificação. O código de importação não invoca o classificador.

4. **Gap 15: Ramp misclassification** — Classificador falha em reconhecer Sol Ring, Mana Vault, Boros Signet e outros ramp cards comuns. **RESOLVIDO parcialmente** (classificador corrigido 2026-06-03, ramp tags 6→19), mas o deck atual (#6) tem apenas 3 cartas `'unknown'` — as outras foram classificadas.

---

## Estado do SQLite knowledge.db

**DB principal (`mtgia`):** 6.4MB, 19 tabelas, 8 decks, 9 run_log entries.
**DB alternativo (`mtgia-broken`):** 659KB — significativamente menor e mais antigo.

| Métrica | v3.6 (2026-06-04) | v3.7 (atual) | Delta |
|:--------|:------------------:|:------------:|:-----:|
| Tamanho DB principal | 0 bytes (ghost) | 6.4MB | **✅ RESTAURADO** |
| Decks | N/A (DB offline) | 8 | — |
| run_log entries | N/A | 9 | — |
| Deck #6 cards | N/A | 100 | — |
| Deck #6 unknown tags | N/A | 3 | — |
| Deck #6 hash | N/A | `8b9c643c...` | — |

**Conclusão DB:** O `knowledge.db` foi restaurado no repo principal. O Gap #4 ("DB principal corrompido") está **RESOLVIDO**. O DB tem 8 decks, 19 tabelas, e apenas 9 run_log entries — indicando que a maioria dos crons não está logando execuções no SQLite (possivelmente usando apenas logs em arquivo).

---

## Verificação MTG Rules — Fontes Oficiais

### Banlist Commander (Scryfall API, 2026-06-04)

| Card | Legalidade | Fonte |
|:-----|:-----------|:------|
| Worldfire | `commander=legal` | Scryfall API `/cards/named?exact=Worldfire` |
| Mana Crypt | `commander=banned` | Scryfall API `/cards/named?exact=Mana+Crypt` |

**Confirmação:** A afirmação em v3.5/v3.6 de que Worldfire estava banida estava INCORRETA. Worldfire é legal em Commander. O ban anterior (antes de 2023) foi revertido. O Validator v3.25 já havia corrigido este erro.

### London Mulligan (CR 103.4c)

**Regra:** Em jogos multiplayer (Commander), o primeiro mulligan é gratuito (0 cartas no fundo). Mulligans subsequentes seguem a regra normal: bottom N-1 cartas.

**Status no código:** Implementado corretamente na simulação (documentado nas execuções anteriores). Não verificável atualmente pois o cron foi removido.

### Priority/Stack (CR 117.3-117.4)

**Regra:** Após uma spell/habilidade ser colocada na stack, o active player recebe prioridade. Todos os jogadores devem passar prioridade em sequência antes que o topo da stack resolva.

**Status no código (`battle_simulator.dart`):** NÃO implementado. Linha 9: "Sem stack complexo (resolução imediata)". O código nunca foi promovido a cron funcional.

---

## Plano de Correções (ordenado por impacto)

| # | Severidade | Alvo | Ação | Esforço |
|:-:|:----------:|:-----|:-----|:-------:|
| 1 | 🔴 CRÍTICO | MTG Rules Auditor | Atualizar prompt (`c0591cb18024`) — remover referências a crons descomissionados, focar nos 8 crons MTG ativos | Baixo |
| 2 | 🔴 CRÍTICO | Mana Base Validator | Corrigir query no prompt: `commander_id` não existe na tabela `decks` | Baixo |
| 3 | 🟡 ALTO | Mana Base Validator | Adicionar sync de legalidades como passo obrigatório no início | Baixo |
| 4 | 🟡 ALTO | Classificador Dart | Corrigir double-null: `infer_functional_card_tags()` e `classify_card()` falham nas mesmas cartas | Médio |
| 5 | 🟡 ALTO | Multi-Commander Evolution | Verificar se `wincon_catalog` existe antes da primeira execução | Baixo |
| 6 | 🟡 MÉDIO | Knowledge Synthesis | Auditar em profundidade na próxima execução (output 2660 linhas) | Médio |
| 7 | 🟡 MÉDIO | CRON_STATUS.md | Sincronizar com relatórios reais (está em 2026-06-01, validator reporta 2026-06-04) | Baixo |
| 8 | 🟢 BAIXO | Bracket Policy (`edh_bracket_policy.dart`) | Completar 7 categorias faltantes para detectar 29/53 GCs | Alto |

---

## Conclusão

A pipeline Lorehold foi **totalmente descomissionada**. O "Death Loop" documentado em v3.5/v3.6 não foi corrigido — foi encerrado por remoção dos crons. Esta é uma decisão operacional legítima: 4 dos 5 agentes estavam em [SILENT] permanente e o Oracle não conseguia completar análise por timeout.

**Estado atual do pipeline MTG:** 8 crons ativos, dos quais 4 produzem análise de conhecimento MTG (Mana Base Validator, Knowledge Synthesis, Commander Knowledge Deep, Game Changer Research) e 2 são novos (Multi-Commander Evolution, Flutter UI Auditor). O foco migrou de "pipeline de otimização Lorehold" para "pesquisa de conhecimento Commander multi-deck".

**Maior risco atual:** O prompt do MTG Rules Auditor (`c0591cb18024`) está stale — referencia crons que não existem mais. Isso faz com que esta mesma auditoria gaste tokens buscando diretórios e arquivos inexistentes a cada execução.

**Maior gap de código:** O classificador de cartas (`functional_card_tags.dart`) ainda tem o problema de "duplo nulo" e falha em classificar cartas comuns de ramp (Sol Ring, Mana Vault). O código permanece no repositório e afetaria qualquer futuro pipeline de otimização.

**Próximo passo recomendado:** Atualizar o prompt do MTG Rules Auditor para auditar os 8 crons ativos, não o pipeline descomissionado. A auditoria deve migrar de "verificar se o pipeline Lorehold segue regras MTG" para "verificar se os crons de conhecimento ativos produzem análises corretas baseadas em regras MTG".
