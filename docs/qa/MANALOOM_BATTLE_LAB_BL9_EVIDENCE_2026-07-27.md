# Evidência BL9 — Battle Coach alpha

- Data: 2026-07-27
- Branch: `codex/free-beta-release-candidate-2026-07-17`
- Estado: `PASS_LOCAL_FEATURE_OFF_SCOPE_REFINED`
- Release: `NO_GO`

## Resultado por task

| Task | Estado | Evidência |
|---|---|---|
| BL9-01 | `PASS_LOCAL` | mão própria, mulligan opaco, relógio e delegação do prompt atual |
| BL9-02 | `PASS_LOCAL` | ação principal apresenta exclusivamente opções emitidas pelo runtime |
| BL9-03 | `PASS_LOCAL` | alvo/cancelamento usam option IDs opacos e `state_version` atual |
| BL9-04 | `PASS_LOCAL` | atacantes/bloqueadores usam seleção de opções/múltiplos valores bounded; XMage valida legalidade |
| BL9-05 | `PASS_LOCAL` | inteiro, multi-amount, mana e X têm controles bounded coerentes com os shapes provados no spike |
| BL9-06 | `PASS_LOCAL_SCOPE_REFINED` | delegação explícita funciona por prompt; preferência automática futura foi rejeitada para não contradizer timeout terminal do ADR 0004 |
| BL9-07 | `PASS_LOCAL_FEATURE_OFF` | entrada pela Análise/menu/testes, deep link retomável, mesa responsiva, prioridade/prazo/progresso/erro/concede/replay |
| BL9-08 | `PASS_LOCAL` | somente mão própria é renderizada; oponente expõe contagens e zonas públicas |

## UX entregue

`BattleCoachScreen` usa uma mesa Obsidian/Brass coerente com ManaLoom, arte de
carta com fallback Scryfall/backend, glifos contextuais de Magic e uma ação
primária por estado. Mostra vida, biblioteca/mão, campo, cemitério, exílio,
comando, stack, combate, mana, prioridade, deadline e histórico terminal.

As rotas:

- `/decks/:id/battle-coach`;
- `/decks/:id/battle-coach/:sessionId`.

A sessão é lida do PostgreSQL/backend; `shared_preferences` não participa.

## Validação local

Testes Flutter cobrem parser/modelo, gateway HTTP, idempotência, feature flag,
CTA na Análise e mesa/decisão/replay. O widget foi exercitado em 390×844 e
1440×900 sem overflow. O bundle Web release foi gerado com
`ENABLE_INTERACTIVE_BATTLE=true` apenas para QA local em `/app/`; scripts de
release fixam a flag em `false`.

## Riscos residuais

- Android compila pelo mesmo Flutter tree, mas aparelho físico e TalkBack não
  foram executados;
- texto 200% e reduced motion exigem confirmação manual de BL10;
- habilitar a UI sem o backend/runtime interativo mantém falha fechada e não é
  configuração suportada.
