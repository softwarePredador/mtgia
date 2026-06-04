# Implementation Tasks — MTG Knowledge ↔ Code Cross-Reference

> **Gerado:** 2026-06-04T04:00Z por ManaLoom Knowledge Synthesis (Cron)
> **Branch:** codex/hermes-analysis-docs
> **HEAD:** d2ca5234
> **Metodo:** 5 novos gaps priorizados entre conhecimento MTG (audits + SQLite) e codigo Dart
> **Base de conhecimento:** Pipeline Audit v3.4 + Structure Audit (classes-not-used) + Inspecao de codigo

---

### [P1] Battle Simulator: Implementar regras fundamentais de Commander (stack, multiplayer, commander damage, tax, ETB)

**Conhecimento MTG:** CR 117.3 (stack/priority — cada jogador deve passar prioridade em sequencia antes da resolucao), CR 802.1a (multiplayer 4-player), CR 903.10a (commander damage 21 — derrota por dano de comandante), CR 903.8 (commander tax +{2} por cada vez que foi conjurado da command zone), CR 603.4 (ETB triggers — habilidades disparadas ao entrar no campo). O Pipeline Audit v3.4 confirma: "O codigo e um prototipo de combate, nao um simulador de Commander."

**Evidencia no codigo:** `server/lib/ai/battle_simulator.dart:3-13` — A docstring admite as simplificacoes: "Sem stack complexo (resolucao imediata)". `battle_simulator.dart:233` — `class BattleSimulator` implementa apenas 2 jogadores (`active` vs `opponent`). Nao ha codigo para: stack/priority, 4-player, commander damage tracking, commander tax, ETB triggers, planeswalkers (CR 306), ou State-Based Actions alem de destroy por dano (CR 704.3). O codigo implementa keywords (flying, trample, lifelink) corretamente nas linhas 56-67 e phases (untap/draw/discard), mas sem stack e multiplayer, nao e um simulador de Commander.

**Gap:** O simulador nao consegue modelar uma partida real de Commander. Counterspells sao impossiveis (sem stack). O combate de comandante e irrelevante (sem commander damage). Politics e threat assessment nao existem (2-player). Qualquer decisao de swap baseada em simulacao de batalha seria invalida.

**Impacto:** `🔴 P1` — Se o Evolution Oracle ou qualquer agente usar `BattleSimulator` para validar swaps, as recomendacoes serao incorretas. O codigo existe (879 linhas) mas nao serve ao proposito declarado. O diretorio de cron foi removido (`/opt/data/cron/output/94f8590b1beb/` nao existe), mas o codigo permanece referenciado nos prompts de outros agentes.

**Acao recomendada:**
1. **Curto prazo:** Marcar `battle_simulator.dart` como `@deprecated` e adicionar docstring: "Prototipo 2-player — nao usar para decisoes de Commander. Migrar para `goldfish_simulator.dart` para analise de consistencia."
2. **Longo prazo:** Implementar simulador multiplayer com stack/priority (CR 117.3-117.4), 4-player support (CR 802.1a), commander damage tracking, commander tax, ETB triggers, e State-Based Actions completos.
3. Remover referencias a `BATTLE_LOG.md` dos prompts do Evolution Oracle e Mulligan.

**Validacao:**
```bash
cd server && dart analyze lib/ai/battle_simulator.dart
cd server && dart test test/ai/battle_simulator_test.dart
```

---

### [P1] Goldfish Simulator: Adicionar simulacao de tapped lands e definicao rigorosa de keepable

**Conhecimento MTG:** CR 110.5a (permanentes entram tapped a menos que o efeito diga o contrario). Cartas como Boros Garrison, Temple of Triumph, e Path of Ancestry entram tapped e NAO produzem mana no turno em que entram. O Pipeline Audit v3.4 estima que ignorar tapped lands superestima a consistencia em +2-5pp. O conhecimento do pipeline define keepable como: "2-4 lands AND (ramp >= 1 OR lands >= 3)". A definicao atual do codigo (2-5 lands, sem considerar ramp) e muito permissiva.

**Evidencia no codigo:** `server/lib/ai/goldfish_simulator.dart:340-354` — `_playLandIfPossible()` trata TODOS os terrenos como untapped. Nao ha verificacao de oracle_text para "enters tapped". `goldfish_simulator.dart:131,156` — Definicao de keepable: `if (landsInHand >= 2 && landsInHand <= 5) keepableHands++`. Esta definicao NAO considera ramp/mana rocks. `optimization_validator.dart:168-171` — O `_simulateLondonMulligan` ja melhorou com `effectiveLands` mas ainda ignora tapped lands e usa `handSize <= 5` como always-keep.

**Gap:** Dois simuladores no mesmo codebase com definicoes diferentes de keepable. O `GoldfishSimulator` superestima a jogabilidade. O `_simulateLondonMulligan` e melhor mas ainda ignora tapped lands. A diferenca de ~20pp na taxa de keepable afeta diretamente as recomendacoes de swap e o quality gate.

**Impacto:** `🔴 P1` — O quality gate (`optimization_quality_gate.dart:412-415`) usa `monteCarlo.consistencyScore` e `monteCarlo.keepableRate` para decidir se um swap e seguro. Com keepable superestimado, swaps que pioram a consistencia real podem ser aprovados.

**Acao recomendada:**
1. Unificar a definicao de keepable em ambos os simuladores: "2-4 lands AND (ramp >= 1 OR lands >= 3)"
2. Adicionar deteccao de "enters tapped" via oracle_text: `.contains('enters the battlefield tapped')`
3. No `_playLandIfPossible()`, se `entersTapped == true`, NAO adicionar mana sources ate o PROXIMO turno
4. Remover `handSize <= 5` como always-keep no `_simulateLondonMulligan`

**Validacao:**
```bash
cd server && dart analyze lib/ai/goldfish_simulator.dart
cd server && dart analyze lib/ai/optimization_validator.dart
cd server && dart test test/ai/goldfish_simulator_test.dart
```

---

### [P1] `/ai/optimize` + `/ai/archetypes`: Adicionar owner-scope nas queries de deck

**Conhecimento MTG:** N/A (seguranca de produto). O contrato mobile (`server/doc/API_CONTRACTS_AND_DATA_MAP.md`) estabelece que decks sao privados por usuario. O Structure Audit (module-coherence, 2026-06-03) identificou 3 endpoints que bypassam ownership.

**Evidencia no codigo:**
- `server/routes/ai/optimize/index.dart:401-406` — Le `userId` mas captura excecao e seta `null`
- `server/lib/ai/optimize_request_support.dart:53-62` — `loadOptimizeDeckContext()` nao aceita parametro `userId`; query linha 66 busca deck por `WHERE id = @id` sem filtro de owner
- `server/routes/ai/archetypes/index.dart:27-47` — NUNCA le `userId` do contexto; query linha 40: `WHERE id = @id` sem owner
- `server/routes/ai/optimize/jobs/[id].dart:39` — So bloqueia se `job.userId != null` (ownerless jobs sao legiveis por qualquer usuario)
- `server/lib/ai/optimize_job.dart:25-30` — `create()` aceita `String? userId` nullable

**Gap:** Qualquer usuario autenticado pode analisar/otimizar qualquer deck do sistema. O campo `user_id` existe na tabela `decks` mas nao e usado nas queries de optimize/archetypes.

**Impacto:** `🔴 P1` — Vulnerabilidade de seguranca. Um usuario malicioso pode analisar decks privados de outros usuarios, iniciar otimizacao em decks alheios, e ler resultados de otimizacao via polling.

**Acao recomendada:**
1. `optimize/index.dart`: Tornar `userId` obrigatorio (nao capturar excecao). Retornar 401 se ausente.
2. `optimize_request_support.dart:53`: Adicionar parametro `required String userId`
3. Query de deck: `WHERE id = @id AND user_id = @userId`
4. `archetypes/index.dart:27`: Ler `userId` e filtrar query
5. `optimize_job.dart:29`: Tornar `userId` obrigatorio
6. `jobs/[id].dart:39`: Simplificar para `if (job.userId != userId) return 404;`

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimize_request_support.dart
cd server && dart test test/routes/ai/optimize_test.dart
# Testar: usuario A tenta otimizar deck do usuario B → 404
```

---

### [P2] Activation Funnel: Sincronizar `_allowedEvents` entre App e Backend

**Conhecimento MTG:** N/A (sincronizacao app-backend). O Structure Audit (module-coherence, 2026-06-03) identificou que o app envia um evento que o backend rejeita silenciosamente.

**Evidencia no codigo:**
- `app/lib/features/decks/providers/deck_provider.dart:605-607` — App envia `'deck_rebuild_created'`
- `app/lib/core/services/activation_funnel_service.dart:17-26` — Envia POST com `event_name: 'deck_rebuild_created'`; erro capturado silenciosamente
- `server/routes/users/me/activation-events/index.dart:10-18` — `_allowedEvents` NAO inclui `deck_rebuild_created`; endpoint retorna 400
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md` — Evento marcado como "not proven"

**Gap:** Toda vez que um usuario cria um rebuild de deck, o app dispara um evento de telemetria que o backend rejeita com 400. O erro e silenciosamente engolido pelo app. O evento nunca e registrado no banco `activation_funnel_events`, distorcendo as metricas de funil de ativacao.

**Impacto:** `🟡 P2` — Nao quebra funcionalidade (erro e silencioso), mas a metrica de rebuilds no funil de ativacao e ZERO, subestimando o engajamento com a feature de rebuild.

**Acao recomendada:**
1. Adicionar `'deck_rebuild_created'` ao `_allowedEvents` no backend
2. Atualizar `API_CONTRACTS_AND_DATA_MAP.md` para marcar o evento como `verified`
3. Auditar outros eventos do app que possam estar na mesma situacao

**Validacao:**
```bash
cd server && dart analyze routes/users/me/activation-events/index.dart
cd server && dart test test/routes/users/activation_events_test.dart
# Enviar POST com event_name='deck_rebuild_created' → 201 created
```

---

### [P2] Candidate Quality: Adicionar `edhrec_trend_zscore` como fator de scoring

**Conhecimento MTG:** O pipeline Hermes (Scout, Validator, Evolution Oracle) usa `trend_zscore` do EDHREC para avaliar se uma carta esta subindo ou caindo no meta. Exemplos: Esper Sentinel (`trend_zscore: -0.67`, 6 ciclos de queda), Primal Amulet (`-0.40`). O `manaloom-commander-knowledge` skill recomenda: "Declining trend scan — cards with trend_zscore < -0.3 and inclusion > 15% are priority cut candidates." O EDHREC JSON API fornece `trend_zscore` para cada carta.

**Evidencia no codigo:** `server/lib/ai/candidate_quality_data_support.dart` — NENHUMA tabela ou coluna para `edhrec_trend_zscore`. O `CandidateQualityData` (definido em `optimize_runtime_support.dart`) nao tem campo `trendZscore`. O PG tem `card_meta_insights` com `usage_count` mas nao `trend_zscore`.

**Gap:** O sistema avalia qualidade de carta usando apenas dados estaticos (meta_deck_count, role scores), ignorando a DIRECAO do meta. Uma carta com 30% EDHREC mas tendencia de queda ha 6 ciclos e tratada igual a uma carta com 30% e tendencia de alta explosiva.

**Impacto:** `🟡 P2` — O optimize pode recomendar cartas em declinio no meta com a mesma prioridade que cartas em ascensao. Nao quebra o sistema, mas reduz a qualidade das recomendacoes.

**Acao recomendada:**
1. Adicionar coluna `edhrec_trend_zscore NUMERIC(5,2)` a tabela PG `card_deck_profiles`
2. Popular com dados do EDHREC JSON API (`cardview.trend_zscore`)
3. Adicionar `double? edhrecTrendZscore` ao `CandidateQualityData`
4. No scoring: `trend_zscore > 2.0` = +10%, `trend_zscore > 5.0` = +20%, `trend_zscore < -0.3 AND inclusion > 15%` = -15%

**Validacao:**
```bash
cd server && dart analyze lib/ai/candidate_quality_data_support.dart
cd server && dart analyze lib/ai/optimize_runtime_support.dart
```

---

## Resumo de Tasks Novas (2026-06-04)

| # | Prioridade | Task | Origem |
|:-:|:----------|:-----|:-------|
| 1 | 🔴 P1 | Battle Simulator: Commander multiplayer rules (stack, 4-player, commander dmg, tax, ETB) | Pipeline Audit v3.4 |
| 2 | 🔴 P1 | Goldfish Simulator: Tapped lands + rigorous keepable definition | Pipeline Audit v3.4 + Pipeline Knowledge |
| 3 | 🔴 P1 | Optimize/Archetypes: Owner-scoped deck queries | Structure Audit (module-coherence) |
| 4 | 🟡 P2 | Activation Funnel: Sync `_allowedEvents` app-backend | Structure Audit (module-coherence) |
| 5 | 🟡 P2 | Candidate Quality: Add `edhrec_trend_zscore` scoring | Pipeline Knowledge (Scout/Validator methodology) |

## Tasks Anteriores (ainda pendentes da execucao 2026-06-04 @ 498eb1a8)

| # | Prioridade | Task |
|:-:|:----------|:-----|
| 1 | 🔴 P1 | Bracket Policy: Adicionar 5 categorias mecanicas ao `BracketCategory` enum |
| 2 | 🔴 P1 | `classifyOptimizationFunctionalRole`: Usar `functional_tags` persistidas como fonte primaria |
| 3 | 🔴 P1 | Quality Gate: Integrar `theme_contextual_rules` nas decisoes de swap |
| 4 | 🟡 P2 | Candidate Quality: Adicionar `edhrec_inclusion_pct` como metrica |
| 5 | 🟡 P2 | Deck Import: Re-classificar automaticamente cartas com `functional_tag='unknown'` |

> **Nota:** Task #4 anterior (edhrec_inclusion_pct) e Task #5 nova (edhrec_trend_zscore) sao complementares — ambas populam `card_deck_profiles` com dados do EDHREC. Podem ser implementadas juntas.
