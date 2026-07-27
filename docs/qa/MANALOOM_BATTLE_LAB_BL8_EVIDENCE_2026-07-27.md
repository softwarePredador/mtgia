# Evidência BL8 — Sessão interativa versionada

- Data: 2026-07-27
- Branch: `codex/free-beta-release-candidate-2026-07-17`
- Estado: `PASS_LOCAL_FEATURE_OFF`
- Release/migration live/deploy: `NOT_AUTHORIZED / NOT_EXECUTED`
- Commit exato: registrado no handoff final da rodada

## Resultado por task

| Task | Estado | Evidência |
|---|---|---|
| BL8-01 | `PASS_LOCAL` | migration 056 cria sessão owner-scoped e log append-only; store PostgreSQL valida FK, quota, idempotência e proibição de update do log |
| BL8-02 | `PASS_LOCAL` | `POST/GET /ai/battle/sessions`, item, actions e concede; auth herdada do middleware, corpo limitado e respostas fechadas |
| BL8-03 | `PASS_LOCAL` | resposta privada é owner-only; replay terminal usa persistência Battle sanitizada e oponentes têm somente contagens de zonas ocultas |
| BL8-04 | `PASS_LOCAL` | `XMAGE_RUNTIME_MODE=batch|interactive` é exclusivo; modo interativo publica apenas capacidade bounded e rejeita batch |
| BL8-05 | `PASS_LOCAL` | `state_version`, prompt/opção opacos, request hash e idempotência rejeitam replay, conflito e escolha obsoleta |
| BL8-06 | `PASS_LOCAL` | TTL/prompt timeout bounded, concede, timeout, expiração, abandono, engine error, process lost e persistence error são explícitos |
| BL8-07 | `PASS_LOCAL` | conclusão persiste tentativa/replay existente e anexa somente `replay_id` ao contrato privado |

## Runtime XMage real

Uma sessão interativa isolada concluiu em XMage pinado:

- runtime: `ibsrt_ecccf246eba84642b83f6c3d00cc1`;
- processo: `21a95831-a940-41e3-a095-38b74d3e567f`;
- 83 ações delegadas aceitas;
- terminal: `engine_game_over`;
- 273 eventos e 196 snapshots bounded;
- zero identidade da mão adversária no payload inspecionado.

Testes adicionais provaram limite de capacidade, concessão terminal/idempotente
e rejeição cruzada entre modos batch/interativo. O username enviado ao XMage
usa prefixo `ml_` mais SHA de 10 caracteres para respeitar o máximo de 14.

## Validação local

Os gates da rodada incluem:

```bash
cd services/xmage-sidecar && mvn test
cd server && dart test \
  test/interactive_battle_contract_test.dart \
  test/interactive_battle_route_contract_test.dart \
  test/interactive_battle_service_test.dart \
  test/interactive_battle_runtime_client_test.dart \
  test/interactive_battle_migration_test.dart
./scripts/manaloom_tbls_local_gate.sh
./scripts/manaloom_project_logic.sh --write
./scripts/manaloom_project_logic.sh --check
```

O gate de schema usa cluster PostgreSQL descartável em loopback, valida as 56
migrations, tabelas/colunas/FKs e remove o cluster. Nada aponta para o banco
live.

## Riscos residuais

- nenhuma migration foi aplicada em ambiente live;
- nenhuma sessão foi publicada;
- retomada depois da perda do processo XMage não é prometida;
- carga integrada e observabilidade de alpha pertencem a BL10.
