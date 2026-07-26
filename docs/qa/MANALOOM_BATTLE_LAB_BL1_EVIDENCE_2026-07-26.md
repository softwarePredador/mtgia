# Evidência BL1 — Descoberta, preflight e objetivo

- Data: 2026-07-26
- Resultado: `PASS_LOCAL`
- Fonte de verdade: PostgreSQL/backend

| Task | Estado | Evidência |
|---|---|---|
| BL1-01 | `PASS_LOCAL` | `Testar este deck` foi adicionado à aba Análise; menu e `Ver testes` mantêm a rota canônica |
| BL1-02 | `PASS_LOCAL` | preflight owner-scoped expõe legalidade/tamanho/comandante/cobertura e blockers antes do POST |
| BL1-03 | `PASS_LOCAL` | setup escolhe oponente e objetivo fechado |
| BL1-04 | `PASS_LOCAL` | até três cartas de foco entram no request; copy informa que foco não força compra/uso |
| BL1-05 | `PASS_LOCAL` | Análise consome evidência Battle compatível e distingue ausência/desconhecido |
| BL1-06 | `PASS_LOCAL` | UI separa `Consistência · Goldfish` de `Confronto · Battle` |
| BL1-07 | `PASS_LOCAL` | histórico usa cursor e filtros por revisão, adversário, engine e status |
| BL1-08 | `PASS_LOCAL` | deep link, refresh e redirect autenticado usam `/decks/:id/battle-replays`; `?replay=` abre detalhe sem depender da lista |

## Provas

Modelos, gateway, tela Battle, aba Análise, matrizes de navegação/estado e
inventário de superfície estão cobertos pelas suítes Flutter da rodada final.
O preflight e o contrato de rota estão cobertos pelos testes Dart do servidor.

Não houve criação de usuário, deck ou replay em API live.
