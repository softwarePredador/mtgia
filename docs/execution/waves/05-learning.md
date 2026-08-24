# Onda 05 — Learning promocional com receipts

Objetivo: separar telemetria, contribuição, candidato e promoção. Learning é um
programa posterior; todas as reads/writes ficam OFF até o fechamento inteiro.

| Ordem | ID | A task conterá | Fechamento ponta a ponta específico |
| ---: | --- | --- | --- |
| 1 | `DCK-P0-05` | state machine e receipt de learning | opt-in por finalidade; ledger atribuível/idempotente; validação current, uso natural e decisão humana; um campeão por comandante |
| 2 | `BT-AI-001` | quarentena de `ai_generated` | zero preview/deck recém-gerado em training; reclassificação integral do cache; prova PG e Hermes separadas |
| 3 | `BT-AI-002` | ledger de aprendizado real | deck/revision/signature/consent/use/receipt; retry não duplica; agregados e AI-new não promovem |
| 4 | `BT-DB-002` | migration preservadora somente se necessária e ainda próxima | perfis de origem, preflight antes de DDL, payload preservado, postcheck/restore exatos em PG descartável |
| 5 | `BT-AI-014` | snapshot candidato Hermes/Markdown→PG | import transacional/idempotente/versionado, replace-by-snapshot, provenance, stale cleanup e rollback; cron report-only |
| 6 | `BT-AI-019` | reads históricas bloqueadas até receipt | flag ausente/inválida causa zero query; rota learned falha antes do banco; zero claim “salvo por usuários” |
| 7 | `BT-AI-030` | retração/purge por sujeito | opt-out/delete revoga leases, remove eventos/influência em PG e Hermes, emite receipt por sistema e bloqueia regravação em voo |

## Receipt de promoção

Uma promoção só é elegível quando o receipt liga:

- SHA, project logic digest, policy e schema;
- owner/consent/finalidade sem expor PII;
- deck revision/signature e validação estrita;
- origem natural, exclusão de preview/AI-new e amostra mínima;
- Battle censurado, quando usado, com subject deck e coverage;
- candidato, comparador, checks, decisão humana, rollback e expiração;
- manifests/hashes de artefatos PG e Hermes.

Hermes pode reproduzir ou cachear evidência; PostgreSQL/backend continua a
verdade de estado e promoção. Nenhuma promoção ocorre em gate local ou por
consequência de um import.

Saída da onda: Learning pode receber uma liberação separada e reversível. Se
qualquer parte falhar, toda a lane permanece OFF sem bloquear o core.
