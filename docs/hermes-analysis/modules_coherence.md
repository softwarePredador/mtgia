# Análise de Coerência entre Módulos (server/lib ↔ server/routes ↔ app)

> Status atual: auditoria historica de modulos.
> Use apenas como contexto. Revalide contra codigo vivo antes de agir.

> Gerado: 2026-05-27 21:28 UTC (Execução #6 — Foco: COERÊNCIA)

## Arquitetura Esperada

```
app/lib/          ← Flutter frontend (features/, core/)
    ↓ HTTP API
server/routes/    ← Endpoints Shelf (shelder)
    ↓ imports
server/lib/       ← Lógica de negócio, serviços, dados
    ↓ SQL
PostgreSQL
```

## Achados de Coerência

### [C1] CLASSES DUPLICADAS ENTRE lib/ E routes/ — ALTA PRIORIDADE

Duas classes são definidas **tanto** em `server/lib/` quanto em `server/routes/ai/optimize/index.dart`:

| Classe | Em lib/ | Em routes/ | Problema |
|---|---|---|---|
| `DeckArchetypeAnalyzer` | `server/lib/ai/deck_state_analysis.dart` | `server/routes/ai/optimize/index.dart` | Definição duplicada — a versão em routes/ provavelmente sobrescreve/completa a de lib/, mas não está claro qual é a canônica |
| `DeckOptimizationState` | `server/lib/ai/deck_state_analysis.dart` | `server/routes/ai/optimize/index.dart` | Mesmo problema — duas definições da mesma classe em módulos diferentes |

**Recomendação:** Consolidar em um único local. Se a versão em routes/ estende a de lib/, refatorar para composição explícita ou herança.

### [C2] 7 CLASSES PACKAGE-PRIVADAS EM routes/ — MÉDIA PRIORIDADE

Classes com prefixo `_` definidas em routes/ (uso interno aceitável, mas indicam acoplamento):

| Classe | Arquivo |
|---|---|
| `_TelemetryQuery` | `server/routes/ai/optimize/telemetry/index.dart` |
| `_QueryBuilder` | `server/routes/cards/index.dart` |
| `_DeckMetrics` | `server/routes/decks/[id]/ai-analysis/index.dart` |
| `_SimCard` | `server/routes/decks/[id]/simulate/index.dart` |
| `_ParsedTradeItems` | `server/routes/trades/index.dart` |

Estas são classes de suporte privadas, aceitável para lógica que **nunca** será reutilizada. Porém, se crescerem, considerar mover para `lib/`.

### [C3] CLASSE PÚBLICA `ManaAnalysis` EM routes/ — MÉDIA PRIORIDADE

`ManaAnalysis` é definida em `server/routes/decks/[id]/analysis/index.dart`. Sendo pública, deveria estar em `server/lib/` para:

- Permitir reuso por outros endpoints
- Facilitar testes unitários isolados
- Manter a separação routes (HTTP) vs lib (lógica)

### [C4] ROTAS COM MAIS DE 300 LINHAS — ALTA PRIORIDADE

22 arquivos em `routes/` têm >300 linhas de código real. Os maiores:

| Arquivo | Linhas de Código | Problema |
|---|---|---|
| `routes/ai/optimize/index.dart` | 3089 | Monolítico — deveria delegar para lib/ |
| `routes/ai/generate/index.dart` | 1508 | Lógica de geração diretamente no endpoint |
| `routes/trades/index.dart` | 590 | Negócio de trades sem service dedicado |
| `routes/ai/commander-reference/index.dart` | |572 | Referência de commander sem service |
| `routes/cards/resolve/index.dart` | 539 | Resolução de cartas sem service dedicado |

**Recomendação:** Extrair lógica de negócio para classes em `server/lib/` e manter routes/ como thin controllers.

### [C5] FUNÇÃO DUPLICADA ENTRE lib/ E routes/ — BAIXA PRIORIDADE

`assessDeckOptimizationState` é definida em:
- `server/lib/ai/deck_state_analysis.dart`
- `server/routes/ai/optimize/index.dart`

Indica que a rota está implementando lógica que já existe em lib/.

### [C6] 11 ARQUIVOS _middleware.dart — ESTRUTURAL

Cada submódulo de rotas tem seu próprio `_middleware.dart` importando de `lib/`:

- `routes/_middleware.dart` — raiz (importa auth_middleware, observability, etc.)
- `routes/ai/_middleware.dart` — AI routes (3 lib imports)
- `routes/auth/_middleware.dart` — Auth routes (1 lib import)
- `routes/binder/_middleware.dart` — Binder routes (1 lib import)
- `routes/community/_middleware.dart` — Community routes (0 lib imports)
- `routes/conversations/_middleware.dart` — Conversations routes (1 lib import)
- `routes/decks/_middleware.dart` — Decks routes (1 lib import)
- `routes/import/_middleware.dart` — Import routes (1 lib import)
- `routes/notifications/_middleware.dart` — Notifications routes (1 lib import)
- `routes/trades/_middleware.dart` — Trades routes (1 lib import)
- `routes/users/_middleware.dart` — Users routes (1 lib import)

Nota: `routes/community/_middleware.dart` não importa nada de `lib/` — pode estar incompleto ou apenas repassar request.

### [C7] MÓDULOS lib/ COMPARTILHADOS ENTRE GRUPOS DE ROTAS — OK (esperado)

18 módulos de `server/lib/` são usados por múltiplos grupos de rotas. Os mais compartilhados:

| Módulo lib/ | Grupos de Rotas |
|---|---|
| `auth_middleware.dart` | ai, binder, conversations, decks, import, notifications, trades, users (8) |
| `logger.dart` | root, ai, binder, community, conversations, decks, notifications, trades, users (9) |
| `observability.dart` | root, ai, auth, binder, community, conversations, decks, notifications, trades, users (10) |
| `database.dart` | root, ai (2) |
| `rate_limit_middleware.dart` | ai, auth (2) |
| `deck_rules_service.dart` | ai, decks, import (3) |
| `http_responses.dart` | ai, decks, health, import, users (5) |

Isto é **esperado** e correto — estes são serviços cross-cutting.

### [C8] server/bin/ — 106 SCRIPTS DE OPERAÇÃO

Há 106 scripts em `server/bin/` (e subdirs) que importam diretamente de `server/lib/`. Notas:

- Migrações diretamente em bin/ em vez de framework ORM
- Scripts de sincronização (sync_cards, sync_prices, etc.) tratados como binários one-off
- QA scripts em `server/bin/qa/`

**Estes scripts acessam lib/ diretamente (sem passar por routes/), o que é correto para operações batch**, mas cria um "bypass" na arquitetura.

### [C9] APP/ (Flutter) UTILIZA HTTP — SEM ACESSO DIRETO A server/lib/

O app Flutter (`app/lib/`) não importa `server/lib/` diretamente. A comunicação é via API HTTP. ✅ Correto.

O app possui seus próprios models em `app/lib/features/*/models/` que são independents dos models do server. ✅ Correto.

### [C10] AUSÊNCIA DE ENTRY POINT VISÍVEL

Não foi encontrado um `server/bin/server.dart` ou `server/bin/main.dart` como entry point do servidor Shelf. O servidor provavelmente é iniciado via `dart run` em um dos binários ou via script de deployment.

### [C11] IMPORTS QUEBRADOS NÃO AFETAM COERÊNCIA

Os 178 "imports quebrados" reportados na auditoria base são **falsos positivos** causados pelo analisador estático não resolver imports relativos corretamente. Estes não representam problemas reais de coerência.

## Resumo de Prioridades

| Prioridade | Achados | Ação Sugerida |
|---|---|---|
| ALTA | [C1] Classes duplicadas lib ↔ routes | Consolidar em local canônico |
| ALTA | [C4] Routes com >300 linhas | Extrair lógica para lib/ |
| MÉDIA | [C3] Classe pública ManaAnalysis em routes | Mover para lib/ |
| MÉDIA | [C2] Classes privadas em routes | Monitorar crescimento |
| BAIXA | [C5] Função duplicada assessDeckOptimizationState | Consolidar |
| BAIXA | [C6] 11 middlewares com imports variados | Padronizar padrão |
| INFO | [C7] Lib modules compartilhados | ✅ Correto, sem ação |
| INFO | [C8] 106 bin scripts bypass routes | ✅ Aceitável para ops |
| INFO | [C9] App isolado via HTTP | ✅ Correto |
| INFO | [C11] Imports quebrados são falsos positivos | ✅ Sem ação |

## Histórico de Análises de Coerência

| Data | Execução | Foco | Arquivos Analizados | Achados |
|---|---|---|---|---|
| 2026-05-27 | #6 (20:00) | COERÊNCIA entre módulos | 167 (server/) + ~215 (app/) | 5 problemas identificados (2 alta, 2 média, 1 baixa) |
