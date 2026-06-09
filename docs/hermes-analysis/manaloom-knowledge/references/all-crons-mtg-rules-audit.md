# Auditoria Completa — Regras MTG em Todas as Crons

**Versão:** v9.0
**Data:** 2026-06-09T13:30:00+00:00
**Commit:** `312c44c3` (HEAD codex/hermes-analysis-docs)
**Auditor:** MTG Rules Auditor v3 (cron `c0591cb18024`)
**Escopo:** Auditoria completa dos 24 crons ativos + delta desde v8.0 (2026-06-07 22:00Z)
**Status:** v8.0 → v9.0 (~36h desde última auditoria). **9ª execução consecutiva com prompt stale.**

---

## ⚠️ AVISO CRÍTICO: MTG Rules Auditor CRON BROKEN (v9.0)

**O cron `mtg-rules-auditor` (`c0591cb18024`) está quebrado desde 2026-06-08 ~16:54Z.**

Desde então, **7+ execuções consecutivas** produzem outputs IDÊNTICOS de 60047 bytes contendo o dump do skill `manaloom-mtg-domain` como se fosse o prompt. O status de todas é `FAILED`:

| Execução | Data | Tamanho | Status | Conteúdo |
|:---------|:-----|:-------:|:-------|:---------|
| 2026-06-08 13:50 | 60047 | FAILED | Skill dump |
| 2026-06-08 16:54 | 60047 | FAILED | Skill dump |
| 2026-06-08 19:59 | 60047 | FAILED | Skill dump |
| 2026-06-08 23:04 | 60047 | FAILED | Skill dump |
| 2026-06-09 02:09 | 60047 | FAILED | Skill dump |
| 2026-06-09 05:17 | 60047 | FAILED | Skill dump |
| 2026-06-09 08:22 | 60047 | FAILED | Skill dump |
| 2026-06-09 11:27 | 60047 | FAILED | Skill dump |

**Causa raiz:** O skill `manaloom-commander-knowledge` não é encontrado (`⚠️ Skill(s) not found and skipped: manaloom-commander-knowledge`). O agente então despeja o `manaloom-mtg-domain` inteiro como output e termina — nunca produz uma auditoria real.

**Este relatório v9.0 foi gerado MANUALMENTE, não pelo cron.** O prompt do cron (`c0591cb18024`) no `jobs.json` nunca foi atualizado desde v3.7 (2026-06-04) e ainda referencia 5 IDs de crons descomissionados.

---

## Sumário Executivo (v9.0)

| Cron | ID | Status | Nota MTG | Mudança vs v8.0 |
|:-----|:--|:-------|:--------:|:----------------|
| **Pipeline Lorehold** | — | 🔴 DESCOMISSIONADO | N/A | — |
| Master Watchdog | `757eefb8738b` | ✅ script-only | N/A | — |
| Normal Audit | `660397bb97e1` | ✅ Ativo | 8.0/10 | — |
| Weekly Parallel Audit | `aeaeb666d377` | 🔴 HTTP 429 | N/A | 🔴 (persiste) |
| **Commander Knowledge Deep** | `75eed994c103` | 🟡 MELHOROU | 5.0/10 | — (Exec #14+ sem regressão "BATTLE-VALIDATED") |
| Game Changer Research | `7915cc2377a0` | 🟡 Regressão | 3.0/10 | — (3 bracket categories vazias) |
| Tag Accuracy Reporter | `b340374bc4e7` | ⏳ Pendente | 5.0/10 | — (último run 2026-06-08) |
| Mana Base Validator | `444aa9510c2c` | ✅ Ativo | 6.0/10 | — |
| Knowledge Import | `b2f5c21ce2d7` | ✅ script-only | N/A | — |
| **Knowledge Synthesis** | `10a59b3bdf4d` | ✅ Funcionando | 6.0/10 | — |
| Logic Coherence Auditor | `de6fb777f5d1` | ✅ Ativo | 8.0/10 | — |
| Code Structure Auditor | `577a0a669714` | ✅ Ativo | N/A | — |
| Cron Governor Report | `21fa86eb0d84` | ✅ Ativo | N/A | — |
| Auto-sync-learned-decks | `7fcab928efd3` | 🔴 script-only | 0/10 | — (PermissionError persiste) |
| Pull-learning-events | `262dc49e1be1` | ✅ script-only | N/A | — (UUID cast persiste) |
| Auto-promote-learned | `104fd03a2ea2` | ✅ script-only | N/A | — |
| Knowncards Generator | `b9c8a7d6e5f4` | 🔴 QUEBRADO | 0/10 | — (script path + root-owned) |
| Universal Optimizer | `c8d9e0f1a2b3` | ⛔ PAUSADO | 1.0/10 | — (corta staples) |
| Knowncards Validator | `d4e5f6a7b8c9` | ✅ OK | 7.0/10 | — |
| Master Optimizer Preflight | `mmo-preflight01` | ✅ OK | 7.5/10 | — (estável) |
| Master Optimizer Auto-Cycle | `mmo-auto-cycle01` | 🟡 Estabilizando | N/A | ↑ Resolvido (Exec #2+ funcionando) |
| Manager Watchdog | `2d436c71bbf7` | ⛔ PAUSADO | N/A | — |
| **MTG Rules Auditor** | `c0591cb18024` | 🔴 QUEBRADO | 0.0/10 | **↓ -2.0 (7+ execs FAILED)** |
| **PIPELINE SCORE** | | | **3.5/10** 🟡 | **±0.0 vs v8.0** |

**Pipeline score permanece 3.5/10.** O MTG Rules Auditor (cron responsável por esta auditoria) caiu para 0.0/10 — não produz auditoria real há 7+ execuções. Commander Knowledge Deep manteve a melhora (sem "BATTLE-VALIDATED"). Nenhum dos 11 itens do plano v4.0 foi aplicado.

---

## 🔴 NOVO: Battle Simulator Dart vs Python — Divergência Crítica

### Dois simulares coexistem com níveis de fidelidade drasticamente diferentes

| Característica | Dart `battle_simulator.dart` (879 linhas) | Python `battle_analyst_v8.py` (5263 linhas) |
|:---------------|:------------------------------------------:|:------------------------------------------:|
| **Em produção?** | ✅ Sim — `/ai/simulate` route | ❌ Não — `docs/hermes-analysis/scripts/` |
| **Usado por cron?** | ❌ Não | ❌ Não (script não é cron) |
| **Priority/Stack** | ❌ Ausente | ✅ CR 117 implementado |
| **Commander Damage** | ❌ Ausente | ✅ 21 damage tracked (linhas 2538-2550) |
| **Commander Tax** | ❌ Ausente | ✅ +2 por cast (linhas 2253, 3532, 3550) |
| **Multiplayer (4+)** | ❌ 2-player | ✅ N oponentes |
| **State-Based Actions** | ❌ Ausente | ✅ CR 704 (linhas 2524-2556) |
| **First Turn Draw** | ❌ Pula T1 no multiplayer | ✅ Correto (Commander) |
| **London Mulligan** | ❌ Ausente | ✅ Free first, bottom N (linhas 2501-2518) |
| **Mana Colors** | ❌ Só CMC numérico | ✅ ManaPool com cores (linhas 2206-2232) |
| **Miracle Mechanic** | ❌ Ausente | ✅ CR 702.94 (linhas 4647-4673) |
| **Tapped Lands** | ❌ Não modelado | ⚠️ Não verificado |
| **Indestructible** | ❌ Ausente | ✅ Suportado |
| **Lifelink** | ✅ Simples | ✅ Tracking completo |

**Conclusão:** O Python `battle_analyst_v8.py` implementa regras MTG de Commander COM SUBSTANCIALMENTE MAIOR FIDELIDADE que o Dart `battle_simulator.dart`. Porém, o Python está em `docs/hermes-analysis/manaloom-knowledge/scripts/` — NÃO é usado por nenhum cron ativo nem pelo endpoint de produto. O Dart continua sendo o código de produção.

**Risco:** Se o Universal Optimizer ou qualquer outro componente for reativado usando o `battle_analyst_v8.py`, os resultados serão mais confiáveis que o Dart. Se for reativado com o Dart, os mesmos problemas do v3.0-v3.6 persistem.

---

## 🔴 Auditoria Detalhada: Battle Simulator Dart (PRODUÇÃO)

**Arquivo:** `/opt/data/workspace/mtgia/server/lib/ai/battle_simulator.dart` (879 linhas)

### O que faz certo
| Item | CR | Status |
|:-----|:---|:-------|
| Untap step | CR 502 | ✅ Corrige `resetForNewTurn()` para todas as permanentes |
| Draw step | CR 504 | ✅ 1 card por turno |
| Main phase land drop | CR 305 | ✅ Joga 1 land por turno (se disponível) |
| Combat damage reduz vida | CR 119.3 | ✅ `opponent.life -= damageToOpponent` |
| Trample implementado | CR 702.19 | ✅ Excesso de dano passa (linha 497-498) |
| First Strike | CR 702.7 | ✅ Resolve antes do dano normal (linha 474) |
| Lifelink | CR 702.15 | ✅ Ganha vida igual ao dano |
| Vigilance | CR 702.20 | ✅ Criatura não vira ao atacar |
| Deathtouch | CR 702.2 | ✅ Qualquer dano = destruição (linha 476) |
| Cleanup/discard | CR 514.1 | ✅ Descarta para 7 (linha 532) |

### O que faz errado — VIOLAÇÕES DE REGRAS MTG

| Item | CR | Problema | Severidade |
|:-----|:---|:---------|:-----------|
| **Sem Priority System** | CR 117.3-117.4 | Nenhum jogador recebe prioridade. Spells resolvem imediatamente. Counterspells impossíveis. | 🔴 CRÍTICA |
| **Sem Stack** | CR 405, 117.7 | Spells não podem ser respondidas. "resolução imediata" (linha 9). | 🔴 CRÍTICA |
| **Sem Commander Damage** | CR 903.10a | 21 dano de commander = morte não existe. Commanders são criaturas normais. | 🔴 CRÍTICA |
| **Sem Commander Tax** | CR 903.8 | Commander sempre custa o CMC base, nunca +2 por cast anterior. | 🔴 CRÍTICA |
| **2-player apenas** | CR 802.1a | Simula 1v1. Commander é multiplayer (4 jogadores). Split de ataque, diplomacia, archenemy inexistentes. | 🔴 CRÍTICA |
| **Draw skip no T1** | CR 800.7 | `!_currentTurn == 1 && active == playerA` (linha 364): pula draw do primeiro turno para o primeiro jogador. **Isso é correto em 1v1 mas errado para Commander multiplayer** — onde o primeiro jogador compra normalmente no T1. | 🟡 ALTA |
| **Summoning Sickness** | CR 302.6 | Criaturas podem atacar no turno que entram (sem haste). A propriedade `summoningSickness = true` é setada mas NUNCA verificada antes de atacar: `canAttack` (linha 93) só verifica `isTapped` e `summoningSickness`, mas `_aiDecideAttackers` (linha 722-761) usa `canAttack` **corretamente**. ✅ Na verdade, olhando melhor, `canAttack` verifica `summoningSickness`. | ✅ Correto (reavaliado) |
| **Mana Colors ignorados** | CR 601.2f | Só checa `cmc <= manaAvailable`. Não há colored mana. Um {U}{U}{U} pode ser pago com {R}{R}{R}. | 🟡 ALTA |
| **Tapped Lands** | CR 302.6 | Lands não entram tapped. Temples, shocklands, etc. que entram tapped são tratadas como untapped. | 🟡 ALTA |
| **Board Wipe é simétrico** | — | `_executeDecision` (linha 665-685) destrói criaturas **de ambos os jogadores**, inclusive as do próprio atacante. Sem indestructible tracking. | 🟡 ALTA |
| **Sorcery timing** | CR 117.1a | Todas as spells são jogadas no mesmo loop, sem diferenciar sorcery (main phase, stack vazio) de instant (qualquer priority). | 🟡 ALTA |
| **End Step sem triggers** | CR 513.1 | Só faz discard. Nenhum trigger "at the beginning of your end step" é processado. | 🟢 MÉDIO |
| **Upkeep step ignorado** | CR 503.1 | Fase de upkeep existe (linha 361) mas não processa triggers de upkeep. | 🟢 MÉDIO |
| **Cleanup step** | CR 514.1 | Descarte para 7, mas não limpa dano (should be end of turn). `damage = 0` no endPhase (linha 541). Correto. | ✅ Correto |
| **Multiple blockers** | CR 509.1b | 1 blocker por attacker apenas. | 🟢 MÉDIO |

**Score estimado Dart:** 2.0/10 🔴 (similar ao v6 da Python battle_analyst_v6)

---

## 🟢 Auditoria Detalhada: Battle Analyst Python v8 (5263 linhas)

**Arquivo:** `/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py`

### O que faz certo — MELHORIAS SIGNIFICATIVAS vs Dart

| Item | CR | Status | Detalhes |
|:-----|:---|:-------|:---------|
| Priority System | CR 117.3-117.4 | ✅ | `priority_round()` (linha 2563): todos os jogadores recebem prioridade, podem responder |
| Stack LIFO | CR 405 | ✅ | `Stack` class (linha 2477): push/pop com resolução LIFO |
| Commander Damage | CR 903.10a | ✅ | `commander_damage[player_name]` (linha 2261), SBA verifica ≥21 (linha 2538-2550) |
| Commander Tax | CR 903.8 | ✅ | `commander_tax` (linha 2253), incremento +2 após cast (linha 3550) |
| Multiplayer | CR 802.1a | ✅ | `all_players = [lorehold] + opponents` (linha 4897) — N oponentes |
| London Mulligan | CR 103.4a | ✅ | Free first (linha 2512), bottom N cards (linha 2513-2516) |
| State-Based Actions | CR 704 | ✅ | `check_sbas()` (linha 2524): life ≤ 0, deck out, commander damage |
| Miracle | CR 702.94 | ✅ | `miracle_cost = 2` (linha 4651-4673), Lorehold-specific |
| Colored Mana | CR 601.2f | ✅ | `ManaPool` (linha 2206): 8 color pools + payment plan |
| Instant-speed removal | CR 117.1a | ✅ | `combat_phase_v8` (linha 4336): oponentes podem removal antes do dano |
| Indestructible tracking | CR 702.12b | ✅ | `player.indestructible = False` (linha 4620), reset por turno |
| First turn draw | CR 800.7 | ✅ | **Commander multiplayer: primeiro jogador compra no T1** (correto) |
| Extra turns | CR 500.7 | ✅ | `play_turn_sequence_v8` (linha 4789) com max 5 extra turns |
| Smothering Tithe trigger | — | ✅ | Dispara em draws de oponentes (linha 4702-4709) |
| End step draw engines | CR 513.1 | ✅ | Processa draw engines no end step (linha 4727-4730) |

### Limitações conhecidas — gaps que persistem

| Item | CR | Problema | Severidade |
|:-----|:---|:---------|:-----------|
| **Tapped lands não modelados** | CR 302.6 | Terrenos como Temple of Triumph que entram tapped são tratados como untapped. Isso infla a mana disponível nos primeiros turnos. | 🟡 ALTA |
| **Mulligan capped em 3** | CR 103.4c | O London Mulligan oficial permite mulligan até 7. O código limita em 3 (linha 2506). | 🟢 MÉDIO |
| **AI simplificada** | — | Decisões de AI são heurísticas. O oponente não joga "como humano". WR é comparativo, não absoluto. | 🟢 MÉDIO |
| **Sem stack interaction total** | — | Nem todas as interações de stack são simuladas (efeitos contínuos, triggers aninhados). | 🟢 MÉDIO |

**Score estimado Python v8:** 7.0/10 🟡 MÉDIA-ALTA (substancialmente melhor que o Dart)

---

## 🔴 Pipeline Lorehold — Status de Descomissionamento

**5/5 crons removidos do `jobs.json` desde 2026-06-04.** Confirmado nesta execução:

| Cron | ID | Último output | Status |
|:-----|:---|:-------------|:-------|
| lorehold-deck-scout | `f20ac299992b` | Não encontrado | 🔴 DESCOMISSIONADO |
| lorehold-deck-validator | `712579b15767` | Não encontrado | 🔴 DESCOMISSIONADO |
| lorehold-mulligan-analyst | `08468451a06a` | Não encontrado | 🔴 DESCOMISSIONADO |
| lorehold-battle-analyst | `94f8590b1beb` | Não encontrado | 🔴 DESCOMISSIONADO |
| lorehold-evolution-oracle | `a50bef4c2a59` | Não encontrado | 🔴 DESCOMISSIONADO |

**Código Dart remanescente:** `battle_simulator.dart` (879 linhas) ainda importado por `server/routes/ai/simulate/index.dart` — usado pelo endpoint de produto `/ai/simulate`. Este código é severamente deficiente em regras MTG.

**Código Python:** `battle_analyst_v8.py` (5263 linhas) em `docs/hermes-analysis/manaloom-knowledge/scripts/` — significativamente melhor, mas sem uso por nenhum cron ativo.

**Regra:** NÃO recriar estes crons sem antes:
1. Migrar para o Python `battle_analyst_v8.py` ou equivalente
2. Adicionar tapped land modeling
3. Configurar git credentials para push

---

## 🟢 Commander Knowledge Deep — Auditoria Detalhada

**Job ID:** `75eed994c103` | **Score:** 5.0/10 🟡 (estável desde v8.0)

### Melhoria mantida: sem "BATTLE-VALIDATED"
Desde v8.0 (2026-06-07 21:38Z), o CKCD não usa mais o termo "BATTLE-VALIDATED". Commits recentes:
- `312c44c3` (Jun 9): "docs: update commander deep knowledge report — **Lorehold WR collapse crisis**"
- `f48fcac3` (Jun 8): "battle_analyst_v8 regression + KC validator settling"

### Commits recentes (codex/hermes-analysis-docs)
```
312c44c3 docs: update commander deep knowledge report — Lorehold WR collapse crisis (Jun 9, 2026)
c55e0638 Explode learned decks: JSON parse fix, 65 new commanders, 60 active in PG
0b4b0c69 Update Hermes project analysis docs — 2026-06-09 audit
```

**Produto (master):** avanços significativos: `c55e0638` (65 novos commanders), `6c2dd6b1` (auto-promoção de battle rules + optimizer loop). O knowledge pipeline está atrasado em relação ao produto.

---

## 🔴 Gaps Persistentes (atualizados v9.0)

| Gap | Descrição | Severidade | Status | Mudança vs v8.0 |
|:----|:----------|:-----------|:-------|:-----------------|
| 1 | EDHREC inclusion rate não usado | 🟡 P1 | Aberto | — |
| 2 | Single-tag vs multi-tag ordem | 🟢 P3 | Aberto | — |
| 3 | Bracket detection incompleta (SQLite) | 🟡 P1 | Parcialmente resolvido | Código Dart OK, SQLite desatualizado |
| 4 | Sem tema-aware validation | 🟡 P1 | Parcialmente resolvido | Theme service criado |
| 5 | Co-pilot vs auto-pilot | 🟢 P3 | Aberto | — |
| 6 | Classificador duplo-nulo | 🟡 P1 | Aberto | — |
| 7 | Cartas novas fora do deck | 🟢 P3 | Maturidade atingida | — |
| 8 | Battle Analyst não é cron | 🔴 P0 | Documentado | — |
| 9 | Mulligan tapped lands | 🟡 P1 | Aberto | — |
| 10 | Battle 2-player apenas | 🔴 P0 | Documentado | Python v8 resolve parcialmente |
| 11 | Scout 94% SILENT | N/A | Cron descomissionado | — |
| 12 | Evolution Oracle parado | N/A | Cron descomissionado | — |
| 13 | Bulk import corruption | 🟡 P1 | Aberto | — |
| 14 | Pipeline staleness | 🟡 P1 | Aberto | — |
| 15 | Ramp misclassification | 🟢 P3 | **Resolvido** | ✅ |
| 16 | Banlist blindness | 🟢 P3 | **Resolvido** | ✅ sync PG→SQLite |
| 17 | Short-circuit perpetua erros | 🟡 P1 | Aberto | — |
| 18 | CKC Deep cita Battle Analyst | 🔴 P0 | **Melhorou** | ✅ ausente desde v8.0 |
| 19 | CMC corruption (26.2%) | 🔴 P0 | Parcialmente resolvido | cmc_safety.dart no produto. DB ainda corrompido |
| 20 | Universal Optimizer corta staples | 🔴 P0 | Bloqueado (perm error) | — |
| 21 | Knowledge Synthesis HTTP 404 | 🟡 P1 | **Resolvido** | ✅ funcional |
| 22 | Master Optimizer Preflight SQLite | 🟢 P3 | **Resolvido** | ✅ |
| 23 | KC Validator LOCKED | 🟢 P3 | **Resolvido** | ✅ |
| 24 | Stored metrics não atualizam | 🔴 P0 | Aberto | — |
| 25 | Bracket categories esvaziadas | 🔴 P0 | Aberto | Force of Will, Bolas's Citadel → `other` |
| 26 | Auto-cycle timeout | 🟡 P1 | **Resolvido** | ✅ Exec #2+ funcionando |
| **27** | **🔴 MTG Rules Auditor CRON BROKEN** | **🔴 P0** | **🆕 NOVO** | 7+ execs FAILED dumpando skill |
| **28** | **🔴 Dart vs Python divergence** | **🔴 P0** | **🆕 NOVO** | Produção usa Dart (2/10), knowledge usa Python (7/10) |

---

## 🔴 Mapa de Regras MTG — Implementação vs Produto

Tabela comparativa de fidelidade das regras MTG entre os dois simuladores:

| Regra (CR) | Dart `battle_simulator.dart` | Python `battle_analyst_v8.py` | Oficial Commander |
|:-----------|:----------------------------:|:-----------------------------:|:-----------------:|
| Priority System (117.3) | ❌ | ✅ | Obrigatório |
| Stack LIFO (405) | ❌ | ✅ | Obrigatório |
| Commander Damage (903.10a) | ❌ | ✅ | 21 dano = morte |
| Commander Tax (903.8) | ❌ | ✅ | +2 por cast |
| Multiplayer (802) | ❌ (2-player) | ✅ (N players) | 4 jogadores |
| London Mulligan (103.4) | ❌ | ✅ (capped 3) | 7 mulligans |
| State-Based Actions (704) | ❌ | ✅ | Contínuo |
| Tapped Lands (302.6) | ❌ | ❌ | Sim |
| Colored Mana (601.2f) | ❌ | ✅ | Sim |
| Miracle (702.94) | ❌ | ✅ | Lorehold-specific |
| First Turn Draw (800.7) | ❌ (pula) | ✅ (não pula) | Commander ≠ 1v1 |
| Indestructible (702.12b) | ❌ | ✅ | Sim |
| Lifelink (702.15) | ✅ (básico) | ✅ (tracking) | Sim |
| Trample (702.19) | ✅ | ✅ | Sim |
| First Strike (702.7) | ✅ | ✅ | Sim |
| End Step Triggers (513.1) | ❌ | ✅ (parcial) | Sim |
| Cleanup Discard (514.1) | ✅ | ✅ | 7 cards max |
| Upkeep Triggers (503.1) | ❌ | ✅ (parcial: The One Ring) | Sim |
| Instant-speed Interaction | ❌ | ✅ (parcial) | Sim |

---

## 🔴 Verificações Scryfall (2026-06-09 13:30Z)

| Carta | Legalidade | CMC | Oracle Text | Observação |
|:------|:-----------|:---:|:------------|:-----------|
| Sol Ring | ✅ `commander=legal` | 1.0 | — | ✅ |
| Worldfire | ✅ `commander=legal` | 9.0 | — | ✅ Confirmado legal (não está na banlist) |
| Mana Crypt | ❌ `commander=banned` | 0.0 | — | ✅ Confirmado banned (2024-SEP) |
| Tergrid, God of Fright | ✅ `commander=legal` | 5.0 | `card_faces[0].oracle_text` **tem conteudo**: "Whenever an opponent sacrifices... you may put that card from a graveyard onto the battlefield under your control." | 🔴 **DB tem `oracle_text = ''`** — bug de import de DFC confirmado. Dados existem no Scryfall em `card_faces[0].oracle_text` |

**Commander Banlist (mtgcommander.net, 2026-06-09):** Inclui Jeweled Lotus, Mana Crypt, Nadu, Dockside Extortionist, Lutri, além dos clássicos (Ancestral Recall, Black Lotus, Time Walk, etc.). Atualização trimestral.

---

## Plano de Correções (ordenado por impacto, v9.0)

### 🔴 P0 — Imediato
1. **Corrigir MTG Rules Auditor cron** — O maior gap. O cron `c0591cb18024` está FAILED há 7+ execuções. Skill `manaloom-commander-knowledge` não encontrado. Atualizar prompt no `jobs.json` para remover 5 IDs descomissionados E corrigir o erro de skill loading.
2. **Corrigir CMC no DB** — 142/543 (26.2%) com CMC=NULL/0.0. `fix_cmc_batch.py` pendente desde 2026-06-05. 5º dia sem correção.
3. **Reimportar Tergrid oracle_text** — Buscar `card_faces[0].oracle_text` via Scryfall. Dados existem na API mas não no DB. 5º dia.
4. **Restaurar bracket_category no SQLite** — Force of Will → `freeInteraction`, Bolas's Citadel → `infiniteCombo`, 12 tutores → `tutor`. 3/5 categorias vazias.
5. **Configurar Git credentials** no ambiente cron para destravar push de múltiplos crons (commits locais acumulando há 5+ dias).

### 🟡 P1 — Alto
6. **Auditar divergência Dart vs Python e decidir qual manter.** O Dart (produção) tem 2.0/10 de fidelidade MTG. O Python (knowledge) tem 7.0/10. Ambos existem. Um deles deveria ser o canônico.
7. **Adicionar tapped land modeling** ao simulador escolhido — critico para mulligan accuracy.
8. Implementar stored-vs-actual metric recomputation (Gap 24)
9. Retroaplicar classificação de bracket no SQLite usando novas 11 categorias
10. Migrar Knowledge Synthesis de `opencode-go` para `deepseek-pro`

### 🟢 P2 — Médio
11. Aumentar mulligan cap (3→7) no Python battle_analyst_v8.py
12. Atualizar prompt do weekly-parallel-audit com 24 crons atuais
13. Corrigir UUID cast no `pull-learning-events`
14. Corrigir PermissionError no `auto-sync-learned-decks`
15. Corrigir script path do `knowncards-generator`

---

## Metodologia da Auditoria

Para cada cron, os seguintes passos foram executados:
1. **Prompt:** Lido do `jobs.json` (seção `prompt` do job)
2. **Output:** Lido do diretório `/opt/data/cron/output/<id>/` (último arquivo)
3. **Código (se aplicável):** Lido do `server/lib/ai/battle_simulator.dart` e `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py`
4. **Verificação Scryfall:** API `api.scryfall.com/cards/named?fuzzy=<carta>` para legalidade, oracle text, CMC
5. **Banlist:** mtgcommander.net para lista oficial de banidas
6. **CR:** Magic: The Gathering Comprehensive Rules (2024-11-08) referenciadas por número

---

## Conclusão

A pipeline de conhecimento Commander permanece em **3.5/10** — inalterada desde v8.0.

**Novos achados críticos (v9.0):**
- 🔴 **MTG Rules Auditor CRON BROKEN** — 7+ execuções consecutivas FAILED dumpando skill content. Este relatório foi gerado manualmente.
- 🔴 **Divergência Dart vs Python** — Produção usa Dart (2.0/10), knowledge usa Python (7.0/10). Ambos existem sem coordenação.

**Progresso real (inalterado desde v8.0):**
- ✅ Commander Knowledge Deep sem "BATTLE-VALIDATED"
- ✅ Knowledge Synthesis funcional
- ✅ CMC safety module no produto
- ✅ 53 GCs + 11 categorias no código Dart
- ✅ Master Optimizer e KC Validator estáveis
- ✅ Auto-cycle timeout resolvido

**Preocupações (agravadas):**
- 🔴 **MTG Rules Auditor quebrado** — ninguém produziu auditoria real desde 2026-06-08 16:54Z
- 🔴 0/11 correções do plano v4.0 aplicadas (5º dia)
- 🔴 CMC corruption 142/543 (26.2%) — 5º dia
- 🔴 Tergrid oracle_text vazio — 5º dia
- 🔴 Bracket categories vazias — 3º dia
- 🔴 Git push bloqueado — commits acumulam
- 🔴 **Prompt stale atinge 9ª execução consecutiva**

**Tendência:** 🔴 DECLÍNIO. Embora componentes individuais estejam estáveis, o MTG Rules Auditor (a ferramenta desta auditoria) quebrou e ninguém notou por 7+ execuções. O prompt stale completou 9 execuções sem correção. As correções P0 continuam sem aplicação no 5º dia.

---

*Relatório gerado MANUALMENTE pelo MTG Rules Auditor v9.0 — 2026-06-09 13:30Z*
*⚠️ O cron `c0591cb18024` não produziu este relatório — estava FAILED. Necessita correção imediata do prompt/skill loading.*
