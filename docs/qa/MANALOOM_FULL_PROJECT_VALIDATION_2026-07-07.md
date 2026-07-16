# ManaLoom Full Project Validation - 2026-07-07

> Snapshot histórico da execução de 2026-07-07. A classificação antiga
> chamava o agregado local de `PASS` mesmo com camadas live fora e a primeira
> versão do retention audit contava o manifesto como referência. Ambos os
> contratos foram substituídos em 2026-07-15. Use
> `docs/MANALOOM_E2E_RELEASE_CONTRACT.md` e o fechamento corrente; não use este
> arquivo para afirmar prontidão atual ou de produção.

## Resultado

Status: PASS para a validacao local completa executada nesta rodada.

O projeto foi validado em app Flutter, backend Dart Frog, contratos de IA,
deckbuilder, battle runtime, PostgreSQL/Hermes/SQLite, gates de tooling,
auditoria visual automatizada e corpus Commander.

## Correcao aplicada

- `server/routes/decks/index.dart`: a criacao inicial de deck deixou de inserir
  `deck_cards` item a item e passou a usar um unico bulk insert parametrizado.
- `server/test/deck_create_bulk_insert_contract_test.dart`: novo teste de
  contrato impede regressao para o insert individual antigo.
- `docs/hermes-analysis/manaloom-knowledge/scripts/report_retention_audit.py`:
  o manifesto de reports retidos agora considera
  `docs/hermes-analysis/master_optimizer_reports/README.md`.
- `docs/hermes-analysis/master_optimizer_reports/README.md`: manifesto de
  evidencia bruta retida atualizado para cobrir pacotes tracked atuais.

## Performance observada

Antes da correcao, no mesmo fluxo de corpus Commander:

- Primeiro deck: `insert_cards_done=104294ms`.
- Segundo deck: `insert_cards_done=123831ms`.

Depois da correcao, com build novo:

- Corpus validado: 19 decks.
- `insert_cards_done`: minimo `5131ms`, media `8157.9ms`, maximo `8528ms`.
- `OPTIMIZE_TIMING total_ms`: minimo `17651ms`, media `18183.4ms`,
  maximo `19545ms`.

Leitura: o gargalo critico de cadastro inicial foi removido. A geracao/
otimizacao ainda fica em torno de 18s por deck no corpus local, com custo maior
em contexto do deck, consultas e shortlist deterministica.

## Gates executados

- `./scripts/quality_gate.sh e2e`: PASS.
  - Patrol product E2E local.
  - Flutter deckbuilder E2E and deck UI contracts.
  - Flutter commercial, retention, growth and trade contracts.
  - Flutter app logs and observability contracts.
  - Server AI deckbuilder battle route contracts.
  - Battle runtime pytest suite.
  - Commander resolution corpus E2E, 19 decks.
  - App AI bridge and Commander prompt eval.
  - PostgreSQL Hermes SQLite contract.
  - Deep AI alignment with deckbuilder battle logs.
- `./scripts/quality_gate.sh full`: PASS.
  - Backend full without live integration.
  - Flutter full local tests: 618 assertions passed.
- `./scripts/quality_gate.sh deps`: PASS.
- `./scripts/quality_gate.sh custom-lint`: PASS.
- `./scripts/quality_gate.sh report-retention`: PASS.
- `./scripts/quality_gate.sh ui-audit`: PASS.

## Auditorias especificas

- Deep AI alignment: PASS.
  - Dart analyze server.
  - Focused AI/data contract tests.
  - Commander AI prompt eval.
  - Old server reference audit.
  - New PostgreSQL migration status.
  - New PostgreSQL data counts.
  - Deckbuilding contract surface audit.
  - XMage strategy consistency audit.
  - Operational surface alignment audit.
  - Legacy contamination audit.
  - PG/Hermes/SQLite contract through new PostgreSQL.
- Producao mock/fallback policy: coberta por
  `server/test/production_ai_mock_fallback_policy_test.dart`.
- Busca por `8ktevp`, IP antigo e `whatsapi` em `app/lib`, `server/lib`,
  `server/routes` e `web-public/src`: nenhum hit em codigo de producao.

## Escopo nao coberto automaticamente

Estas camadas ficaram fora da rodada por dependerem de alvo vivo, device ou
configuracao externa:

- Flutter live runtime integration E2E:
  `MANALOOM_RUN_FLUTTER_RUNTIME_E2E=1`.
- Server live API E2E:
  `MANALOOM_RUN_SERVER_LIVE_E2E=1` e `TEST_API_BASE_URL`/`API_BASE_URL`.
- Live product/API E2E:
  `MANALOOM_RUN_LIVE_PRODUCT_E2E=1`.
- Dominio final: o app ainda depende de fallback publico temporario enquanto o
  dominio definitivo nao existir.
- Pagamento real, webhook real e URLs finais de checkout dependem de provedor
  externo.

## Artefatos principais

- E2E summary:
  `/tmp/manaloom_e2e_suite_reports/manaloom_e2e_suite_20260707T064302Z/summary.md`
- Deep AI summary:
  `/tmp/manaloom_deep_ai_alignment_reports/deep_ai_alignment_20260707_070231_summary.md`
- Report retention:
  `/tmp/manaloom_report_retention_audit.md`
