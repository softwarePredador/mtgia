# Evidência BL3 — Relatório, anotações e comparação

- Data: 2026-07-26
- Resultado: `PASS_LOCAL_WITH_P1_DEFERRED`
- Storage: PostgreSQL (`battle_replay_annotations`), nunca
  `shared_preferences`

| Task | Estado | Evidência |
|---|---|---|
| BL3-01 | `PASS_LOCAL` | relatório mostra outcome/status, turnos, duração, engine/commit, confiabilidade, vida e atividades observadas |
| BL3-02 | `PASS_LOCAL` | observáveis ausentes são listados como desconhecidos |
| BL3-03 | `PASS_LOCAL` | migration 053, API owner-scoped e Flutter persistem notas/bookmarks com replay, tentativa, revisão e referência |
| BL3-04 | `PASS_LOCAL` | `Eu faria diferente` é anotação privada e não altera replay |
| BL3-05 | `DEFERRED_P1` | contrato/backend aceitam escolha de mulligan, mas esta rodada não cria o gatilho humano antes da heurística |
| BL3-06 | `PASS_LOCAL` | comparação falha fechada em revisão, oponente, engine/commit ou timeout incompatível |
| BL3-07 | `PASS_LOCAL` | amostra declara `n` e separa concluída/censurada/timeout |
| BL3-08 | `DEFERRED_P1` | séries 3/5/10 não foram implementadas; cada job atual é amostra independente |
| BL3-09 | `PASS_LOCAL` | feedback útil/não útil e event report são anotações governadas |

## Provas

Serviço/rotas/migration/privacy do backend e modelos/gateway/painel Flutter
possuem casos positivos, idempotência, conflito, owner/IDOR, referência
inválida, export e exclusão. Replays permanecem imutáveis.

Os dois itens P1 não são blockers de M1 nesta rodada e não são apresentados
como concluídos.
