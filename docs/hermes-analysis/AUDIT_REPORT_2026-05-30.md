# Audit Report — 2026-05-30

> Auditoria profunda: 20 commits desde `3f7d784f` até `21768cca`.
> Atualizado em: 2026-05-30T21:00Z.
> Validacao: 599 dart test PASSED, 1 flutter analyze issue (pre-existing).

## Resumo Executivo

20 avancos significativos desde a ultima auditoria. O foco principal foi:

1. **F0-F3: Modularizacao dos gargalhos do optimize** — 3 arquivos novos, -1824 linhas nos gargalhos
2. **F1: Adapter unificado de roles funcionais** — `resolveCardFunctionalRoles()` substitui heuristicas espalhadas
3. **F2: Limpeza de tabelas write-only** — Migration criada (ainda nao aplicada em prod)
4. **Bracket Policy expandida** — 5 novas categorias, 53/53 Game Changers detectados
5. **card_deck_profiles integrado ao gate de swaps** — Proteção de cartas core
6. **Suite de layout tests expandida** — 4 novos arquivos de overflow
7. **CONTEXTO atualizado** — Reflete novo estado do produto

## Validacao Ambiental

| Check | Resultado | Detalhes |
|-------|-----------|----------|
| `dart test` (backend) | **599 PASSED** | 0 falhas, 0 skipped |
| `flutter analyze` | **1 issue** | Pre-existing: `local_test_server.dart` → `.dart_frog/server.dart` nao existe |
| `flutter pub get` | OK | 2 deps atualizadas |

## Mudancas Estruturais

### F0-F3: Modularizacao de Gargalhos

| Arquivo | Antes | Depois | Delta |
|---------|-------|--------|--------|
| `optimize_runtime_support.dart` | 4.028 linhas | 2.718 linhas | **-1.310** |
| `routes/ai/optimize/index.dart` | 3.589 linhas | 3.075 linhas | **-514** |
| `optimize_filler_loader_support.dart` | — | 1.310 linhas | **NOVO** |
| `optimize_route_internal.dart` | — | 430 linhas | **NOVO** |
| `optimize_response_support.dart` | — | 144 linhas | **NOVO** |
| **Total gargalhos** | **~7.617 linhas** | **~5.677 linhas** | **-1.940** |

### F1: Card Roles Adapter

- Arquivo: `server/lib/ai/optimization_functional_roles.dart` (683→398 linhas, reescrito)
- Nova classe `CardRoles` com `Set<String> roles`, `primaryRole`, `source`
- Fonte unificada: `resolveCardFunctionalRoles()` com prioridade: `persistida > semantic_v2 > heuristica`
- `classifyOptimizationFunctionalRole()` agora delega ao adapter
- Rastreio de origem (`source: 'persisted'|'semantic_v2'|'heuristic'`) para diagnósticos

### Bracket Policy Expandida

- `BracketCategory` enum: 6 → 11 valores (adicionados: `boardWipe`, `cardAdvantage`, `stax`, `protection`, `valueEngine`)
- **ATENCAO**: `gameChanger` foi REMOVIDO do enum e substituido pelas 5 novas categorias
- Heuristicas de deteccao para cada nova categoria (oracle text patterns)
- Limites por bracket (1-4) definidos para todas as 11 categorias
- `BracketPolicy.forBracket()` e `countBracketCategories()` atualizados para 11 categorias

### card_deck_profiles no Gate de Swaps

- `filterUnsafeOptimizeSwapsByCardData` agora aceita `cardDeckProfiles` opcional
- Protege cartas core (do perfil do deck) de serem removidas em swaps

### F2: Migration Write-Only Tables

- `server/bin/migrate_drop_unused_tables.sql`
- Remove: `deck_matchups`, `deck_weakness_reports`, `ml_prompt_feedback`
- Mantem: `commander_reference_decks`, `commander_reference_deck_cards`
- **Pendente**: Nenhum controle de migrations

### Layout Tests Expandidos

| Arquivo | Tela | Viewports |
|---------|------|-----------|
| `deck_card_overflow_test.dart` | DeckCard | +820px (tablet) |
| `trade_detail_screen_overflow_test.dart` | TradeDetailScreen | 320, 375px |
| `binder_screen_overflow_test.dart` | BinderTabContent | 320, 375px |
| `lotus_life_counter_overflow_test.dart` | LotusLifeCounterScreen | 280, 320, 375px + text scaler |
| `docs/LAYOUT_TEST_MAP.md` | Mapeamento completo | — |

### Semantic Layer V2

- `_criticalRolesForArchetype` agora inclui `wipe` para TODOS os arquetipos
- `SEMANTIC_LAYER_V2_EXPANDED_CRITICAL_ROLES` flag documentada com valores validos
- Strict validation: Commander imports sem `commander` no name/type rejeitados

### Payoff Detection Expandida

- `_looksLikePayoff` agora detecta payoffs de dano direto: `Impact Tremors`, `Guttersnipe`, `Purphoros`

## Novos Riscos Identificados

### NR.1 — `BracketCategory.gameChanger` removido sem deprecacao (P2)
**Arquivo:** `server/lib/edh_bracket_policy.dart` (commit `ae886b11`)
O valor `gameChanger` foi removido do enum e substituido por 5 categorias detalhadas. Codigo externo que referenciava `BracketCategory.gameChanger` quebrara. Mitigacao: heuristicas cobrem 53/53 Game Changers. Acao: verificar referencias residuais.

### NR.2 — Migration F2 nao tem mecanismo de controle (P2)
**Arquivo:** `server/bin/migrate_drop_unused_tables.sql` (commit `a751fa5c`)
Sem framework de migrations, sem rollback, sem versionamento. Acao: documentar em `manual-de-instrucao.md`.

### NR.3 — Remocao write-only tables pode afetar analise historica (P3)
Antes de dropar, verificar dados valiosos. Backup antes de aplicar.

## Commit Hygiene
Todos os 20 commits tem mensagens descritivas com tipo prefixado. Nenhum commit viola regras de segredo.
