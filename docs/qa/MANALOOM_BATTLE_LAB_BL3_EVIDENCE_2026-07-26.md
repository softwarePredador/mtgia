# Evidência BL3 — Relatório, anotações e comparação

- Data: 2026-07-26
- Resultado: `PASS_LOCAL_WITH_RUNTIME_RESIDUALS`
- Storage: PostgreSQL (`battle_replay_annotations`), nunca
  `shared_preferences`

| Task | Estado | Evidência |
|---|---|---|
| BL3-01 | `PASS_LOCAL` | relatório mostra outcome/status, turnos, duração, engine/commit, confiabilidade, vida e atividades observadas |
| BL3-02 | `PASS_LOCAL` | observáveis ausentes são listados como desconhecidos |
| BL3-03 | `PASS_LOCAL` | migration 053, API owner-scoped e Flutter persistem notas/bookmarks com replay, tentativa, revisão e referência |
| BL3-04 | `PASS_LOCAL` | `Eu faria diferente` é anotação privada e não altera replay |
| BL3-05 | `PASS_LOCAL_CONDITIONAL_SNAPSHOT` | mão inicial legítima do deck em análise exige Keep/Mulligan antes da timeline/heurística; escolha é anotação PostgreSQL e não altera o motor |
| BL3-06 | `PASS_LOCAL` | comparação falha fechada em revisão, oponente, engine/commit ou timeout incompatível |
| BL3-07 | `PASS_LOCAL` | amostra declara `n` e separa concluída/censurada/timeout |
| BL3-08 | `PASS_LOCAL_CLIENT_SERIES` | Live cria 3/5/10 jobs canônicos sequenciais, cada um com seed e idempotência próprios, progresso e cancelamento; nunca escolhe vencedor nem promove swap |
| BL3-09 | `PASS_LOCAL` | feedback útil/não útil e event report são anotações governadas |

## Provas

Serviço/rotas/migration/privacy do backend e modelos/gateway/painel Flutter
possuem casos positivos, idempotência, conflito, owner/IDOR, referência
inválida, export e exclusão. Replays permanecem imutáveis.

O gate de mão só aparece quando o replay contém snapshot de mão inicial e
identidade inequívoca do deck em análise. Como o replay já terminou, a escolha
ocorre antes da leitura detalhada, mas pode não ser cega ao outcome. Engines
que não emitem esse snapshot continuam sem exercício; a UI não fabrica a mão.

A série é coordenação cliente sequencial sobre jobs PostgreSQL autoritativos.
Se o cliente fechar, jobs já criados continuam no histórico, mas não existe
uma entidade de série durável capaz de retomar e criar automaticamente as
tentativas restantes. Esses dois limites são resíduos explícitos de runtime,
não itens de UI ainda adiados.

## Provas focadas

- setup/runner: 7/7;
- mão inicial: 7/7;
- tela Battle/replay: 24/24;
- homologação local Battle: 3/3.
