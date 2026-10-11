# Receipt — BT-OBS-001: SLOs e alertas de API, banco, jobs, cache e catálogo (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. A tarefa não tem superfície de UI própria.
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

A política versionada traz os dois SLOs da D-47, 12 regras de alerta e o receptor humano. O avaliador `manaloom_slo_alerts` só lê, roda a cada 5 minutos no daemon de ops e manda uma mensagem por avaliação. Sem receptor configurado, ele grava a observação e termina com erro. O runbook tem uma seção por alerta.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `2d1f2cc52` | 2026-09-24 | feat(BT-OBS-001): add SLOs and owner alerts for the API, PostgreSQL, jobs, cache and catalog |

## Testes que cobrem o aceite

- `server/test/request_metrics_service_test.dart`: as janelas de 5 e 60 minutos e o template da rota como chave.
- `server/test/operational_alerts_test.dart`: os alertas operacionais.
- `server/test/slo_alerts_test.py`: o avaliador com HTTP, PostgreSQL e canal falsos.
- `server/test/slo_alerts_db_live_test.py`: PostgreSQL descartável, com `RUN_SCHEMA_DB_TESTS=1`.
- `server/test/manaloom_ops_daemon_test.py`: o job no daemon.

## Outros arquivos

- `server/config/slo_alert_policy.json`: a política.
- `docs/runbooks/SLO_E_ALERTAS.md`: o runbook.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- Configurar o ops (URL interna, chave e receptor) e o teste de alerta reconhecido pelo dono, antes da publicação do Android (lote, com a palavra do dono).
- Conferido em 2026-10-10: o deploy do ops (`scripts/manaloom_deploy_ops_image.sh`) espera exatamente 4 jobs em `enabled_jobs` e em `jobs.json`, e o daemon liga também o `manaloom_slo_alerts`, num total de 5. Sem conserto, a checagem depois do deploy do ops não converge. O conserto é da frente de operação (S-01 do plano da coordenação).
