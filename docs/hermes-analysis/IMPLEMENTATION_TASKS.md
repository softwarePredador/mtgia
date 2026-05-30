# Implementation Tasks — ManaLoom

> Gerado por sintese: cruzamento do conhecimento MTG do Hermes × codigo atual.
> Data: 2026-05-30 | Branch: origin/master | SHA: 49b6b1e1

## Resumo de Status

| # | Prioridade | Titulo | Status |
|:--|:-----------|:-------|:-------|
| P1-a | P1 | BracketCategory enum nao detecta Game Changers | ✅ RESOLVIDO (ae886b11) |
| P1-b | P1 | card_deck_profiles nao consultado pelo optimize | ✅ RESOLVIDO (d8b7b26b) |
| P1-c | P1 | Weakness-analysis usa heuristicas legacy (sem adapter F1) | 🔴 ATIVO |
| P2-a | P2 | _looksLikePayoff nao detecta payoffs de dano direto | ✅ RESOLVIDO (3fb17356) |
| P2-b | P2 | Tags ninja/stax_disruption com 0% de acuracia no SQLite | 🔴 ATIVO |
| P3-a | P3 | CONTEXTO_PRODUTO_ATUAL.md desatualizado | ✅ RESOLVIDO (7ed5b863) |
| P3-b | P3 | Weakness-analysis wincon detection fragil (oracle text) | 🔴 ATIVO |
| P3-c | P3 | manual-de-instrucao.md nao reflete F1/F3/bracket expansion | 🔴 ATIVO |

---

### [P1] Weakness-analysis usa heuristicas legacy — sem adapter F1

**Conhecimento MTG:** O fluxo core ja usa o `resolveCardFunctionalRoles()` (adapter F1, commit eb051a80) que unifica tags funcionais com prioridade: `persistida > semantic_v2 > heuristica`. Tag `payoff` agora detecta payoffs de dano direto. Suporte multi-tag via `Set<String> roles`.

**Evidencia no codigo:**
- `server/routes/ai/weakness-analysis/index.dart:114-170` — Conta ramp/draw/removal/wipes por `oracle_text` local com patterns hardcoded
- `server/routes/ai/weakness-analysis/index.dart:380-430` — Recomendacoes sao listas fixas de nomes de carta
- `server/routes/decks/[id]/recommendations/index.dart:1-30` — Usa OpenAI como fonte primaria, sem usar tags funcionais locais

**Gap:** Duas rotas publicas operam com classificacao inferior ao adapter F1. Recomendacoes sao genericas e nao consideram colecao do usuario nem comandante.

**Impacto:**
1. Usuario recebe analise de fraquezas inferior a capacidade real do sistema
2. Recomendacoes de remocao iguais para qualquer deck
3. Qualidade inconsistente com o pipeline de otimizacao

**Acao recomendada:**
1. Refatorar weakness-analysis para usar `resolveCardFunctionalRoles()`
2. Substituir recomendacoes hardcoded por queries em `card_function_tags` + `card_semantic_tags_v2`
3. Usar `card_deck_profiles` para contextualizar recomendacoes por archetype
4. Em recommendations, usar `summarizeFunctionalTagsForDeck()` como fonte primaria

**Validacao:**
```bash
cd server
dart analyze routes/ai/weakness-analysis/index.dart routes/decks/\[id\]/recommendations/index.dart
dart test test/optimization_quality_gate_test.dart
```

---

### [P2] Tags ninja (0/17) e stax_disruption (0/3) corrompem relatorios de acuracia

**Conhecimento MTG:** O cron `manaloom-tag-accuracy-reporter` (2026-05-30T08:00Z) identificou 7 tags com acuracia 0%: `ninja`, `ramp+combo_piece`, `recursion+wincon`, `ramp+payoff`, `payoff+removal`, `payoff+token_maker`, `stax_disruption`. Tag `payoff`: 35.5% (11/31).

**Evidencia no codigo:**
- `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` → `tag_accuracy`: `ninja: 0/17`, `stax_disruption: 0/3`
- O adapter F1 nao produz tags `ninja` ou `stax_disruption`; cartas ninja recebem `creature`; cartas stax sao detectadas pela bracket policy

**Gap:** Tags fantasmas no SQLite corrompem relatorios. Tags compostas com `+` nao sao lidas pelo F1 que usa `Set<String>` simples.

**Impacto:** Relatorios de qualidade para o operador mostram tags inexistentes. Se algum modulo consulta `tag_name = ninja`, retorna resultados incorretos.

**Acao recomendada:**
1. Remover tags fantasmas do SQLite (ja executado nesta rodada)
2. Recalcular `tag_accuracy` para `payoff` apos expansao de padroes
3. Unificar tags compostas no SQLite
4. Atualizar `tag-accuracy-reporter` para pular tags que nao existem mais

**Validacao:**
```sql
DELETE FROM tag_accuracy WHERE tag_name IN (ninja, stax_disruption, ramp + combo_piece, recursion + wincon, ramp + payoff, payoff + removal, payoff + token_maker);
```

---

### [P3] Weakness-analysis wincon detection fragil

**Conhecimento MTG:** A deteccao de win conditions no weakness-analysis (linhas ~400-420) procura por patterns fixos. Mas muitas wincons nao sao detectadas: Thassa Oracle, Walking Ballista, combos de 2+ cartas.

**Evidencia no codigo:**
- `server/routes/ai/weakness-analysis/index.dart:400-420` — Patterns fixos que nao detectam combos multi-carta

**Gap:** Decks combo que vencem por mecanicas nao-obvias sao classificados como insufficient win conditions.

**Impacto:** Falso positivo na analise de fraquezas para decks combo.

**Acao recomendada:**
1. Consultar `card_meta_insights` wincon_score do PostgreSQL
2. Consultar `commander_card_synergy` para cartas marcadas como combo_piece
3. Usar tag `wincon` do adapter F1

**Validacao:**
```bash
cd server
dart analyze routes/ai/weakness-analysis/index.dart
dart test test/functional_card_tags_test.dart
```

---

### [P3] manual-de-instrucao.md nao reflete F1/F3/bracket expansion

**Evidencia no codigo:**
- `docs/CONTEXTO_PRODUTO_ATUAL.md` — Atualizado em 2026-05-30 (7ed5b863) OK
- `server/manual-de-instrucao.md` — Ultimo registro e F0. Nao menciona F1, F3, bracket expansion, card_deck_profiles, payoff expansion

**Gap:** O diario tecnico esta ~10 commits atras.

**Impacto:** Decisoes recentes nao documentadas. Risco de retrabalho.

**Acao recomendada:** Atualizar `server/manual-de-instrucao.md` com:
- Adapter F1: `resolveCardFunctionalRoles()`
- Bracket expansion: 5 novas categorias, 53/53 GCs
- card_deck_profiles integrado
- Modularizacao F3
- Payoff expansion

**Validacao:** Revisao manual.

---

## Tasks Resolvidos (referencia historica)

### ✅ [P1] BracketCategory enum — RESOLVIDO (ae886b11)
Adicionadas: boardWipe, cardAdvantage, stax, protection, valueEngine. Detecta 53/53 GCs.

### ✅ [P1] card_deck_profiles integration — RESOLVIDO (d8b7b26b)
filterUnsafeOptimizeSwapsByCardData consulta card_deck_profiles e bloqueia remocao de core cards.

### ✅ [P2] _looksLikePayoff damage payoffs — RESOLVIDO (3fb17356)
Adicionado: whenever + deals + damage + (each opponent | any target | target opponent)

### ✅ [P3] CONTEXTO_PRODUTO_ATUAL.md — RESOLVIDO (7ed5b863)
Atualizado com F0-F3, bracket expansion, card_deck_profiles, Hermes status.
