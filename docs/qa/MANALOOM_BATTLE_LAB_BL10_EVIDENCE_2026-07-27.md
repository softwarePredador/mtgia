# Evidência BL10 — Homologação do Battle Coach alpha

- Data: 2026-07-27
- Branch: `codex/free-beta-release-candidate-2026-07-17`
- Estado: `PARTIAL_LOCAL_RELEASE_NO_GO`
- Decisão: `NO_GO`

## Matriz

| Task | Estado | Prova local | Para concluir |
|---|---|---|---|
| BL10-01 | `PASS_LOCAL` | auth/owner scope, 404 uniforme, IDs opacos, body bounded, quotas, idempotência, rejeição stale e payload fechado | repetir contra ambiente homologado |
| BL10-02 | `PASS_LOCAL` | request/process correlation, runtime inválido, duplicate, timeout/concede terminal e process lost fail-closed | fault injection no deployment alvo |
| BL10-03 | `PASS_LOCAL_PRE_HOMOLOGATION` | capacidade interativa 1..32, isolamento batch/interativo e carga integrada descartável com 24 jobs e budgets de rota/PostgreSQL/batch | repetir carga com HTTP, sidecars e recursos do ambiente alvo |
| BL10-04 | `PARTIAL_LOCAL` | partida XMage real, reconexão por polling/deep link e build Web release | Android físico, background/foreground real e smoke same-SHA |
| BL10-05 | `PARTIAL_LOCAL` | semântica, teclado de widget, live state, reduced motion, texto 200% e viewports 390/1440 automatizados | teclado completo no navegador, TalkBack e texto 200% no aparelho físico |
| BL10-06 | `PARTIAL_LOCAL` | erros/correlação bounded, redaction, readiness opt-in e nenhum ID privado em health | alertas, painel e runbook de sessão travada/abandonada |
| BL10-07 | `NO_GO` | app/backend default-off e release scripts fixam flags em `false` | todos os P0 anteriores, quota/escopo/rollback e autorização explícita |

## Validação concluída

Toolchains congeladas:

- Flutter `3.44.6` / Dart `3.12.2`;
- Node `26.0.0` para o gate Web/E2E.

Resultados:

- `quality_gate.sh battle-lab`: `PASS`;
- `quality_gate.sh engine-capabilities`: `PASS`, `95/95` checks;
- `quality_gate.sh ui-audit`: `PASS`, `48` testes;
- `manaloom_local_ci.sh full`: `PASS`, incluindo `1276` testes Flutter
  (`1` skip declarado), `9` fluxos Patrol, Web público, lints, dependências e
  PostgreSQL descartável com `79` tabelas, `6` views, `98` FKs e `56`
  migrations;
- `quality_gate.sh e2e`: `PASS` no perfil determinístico/read-only; camadas
  mutantes, aparelho/API live e escrita PostgreSQL continuaram `SKIP` por
  contrato;
- `manaloom_project_logic.sh --check`: `PASS`, `8` artefatos sincronizados;
- bundle Flutter Web release para QA local: `PASS`, base `/app/`, Coach
  habilitado somente no bundle local e `main.dart.js` com SHA-256
  `62c586e953533a112758926bd25666eb200a0fb8422bde0e836369cf99695e75`.

O primeiro E2E direto selecionou Node `20.11.1` do shell e falhou antes do
build do site público. A repetição com Node `26.0.0` e Flutter `3.44.6`
explicitamente selecionados passou por completo; não foi classificada como
regressão de produto.

Complemento de 2026-07-29:

- `quality_gate.sh performance`: `PASS`, incluindo a matriz controlada de
  falha do provedor;
- `manaloom_tbls_local_gate.sh`: `PASS`, incluindo 24 jobs concorrentes,
  listagem, PostgreSQL, lane batch e cancelamento com zero job ativo ao final;
- medições, budgets e limites de crédito estão documentados em
  `docs/qa/MANALOOM_S8_BL10_RESILIENCE_FOLLOWUP_2026-07-29.md`.

## Controles de rollout

- backend: `INTERACTIVE_BATTLE_ENABLED=false`;
- app: `ENABLE_INTERACTIVE_BATTLE=false`;
- sidecar: runtime interativo separado, não selecionado pelo deployment batch;
- scripts Web/Android/backend fixam os valores acima em `false`;
- readiness só torna a dependência bloqueante quando a capacidade é
  explicitamente habilitada.

Desabilitar as flags remove entrada/rotas de produto sem apagar evidência
PostgreSQL. Rollback de migration com dados permanece manual e exige
backup/restore; nenhum cleanup automático apaga sessão para simular rollback.

## Janela restante

Com aparelho Android, ambiente homologado e autorização para migration/deploy,
estima-se 5–10 dias úteis para repetir carga na infraestrutura alvo,
alertas/runbook, acessibilidade física, smoke same-SHA, correções e decisão
final. Espera por esses recursos não é tempo de engenharia e mantém o status
bloqueado externamente.
