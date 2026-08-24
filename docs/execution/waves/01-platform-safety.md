# Onda 01 — segurança, dados e contenção

Objetivo: preparar PostgreSQL, autorização, privacidade, capacidade e operação
antes de mutações de deck ou providers caros.

## Baseline e operação

| Ordem | ID | A task conterá | Fechamento ponta a ponta específico |
| ---: | --- | --- | --- |
| 1 | `BT-DB-001` | auditoria fresh do baseline 058 | cluster PG loopback novo, migrations, tabelas/views/colunas/FKs/ledger, diferenças classificadas, cleanup; zero DDL live |
| 2 | `BT-DB-004` | proibição executável de DDL runtime | scan e testes de todos os entrypoints; somente migration altera schema; CLIs/backfills falham fechado |
| 3 | `BT-DB-005` | classificação das relações ML suplementares | cada consumer ganha migration/contrato ou é removido; fresh baseline não degrada silenciosamente |
| 4 | `BT-CAP-001` | medição do host e política de capacidade | CPU/RAM/swap/PG/serviços medidos, thresholds versionados e preflight reproduzível |
| 5 | `BT-DR-001` | backup off-site e restore isolado | objeto exato, checksum/version, restore fresh, validação de dados/schema e RPO/RTO medidos |
| 6 | `BT-KPI-001` | eventos, coortes, métricas e guardrails | esquema de eventos sem decklist/UGC/PII; dedupe e coorte por usuário; baseline antes de meta |
| 7 | `BT-OBS-001` | SLO, alertas e runbooks | API/PG/jobs/cache/catalog/release com receiver humano, test alert e redaction |

## Contenção antes da abertura funcional

| Ordem | ID | A task conterá | Fechamento ponta a ponta específico |
| ---: | --- | --- | --- |
| 8 | `DCK-P0-00` | replace-all OFF, novo deck privado, IA advisory | UI/deep link/API direta; add-only preservado; negação antes de mutação; deck vazio nunca público |
| 9 | `SCOPE-P0-SOC-00` | flags separadas para social/DM/push/public binder/trades | cada rota e consumer negados antes de PG; release identity registra OFF |
| 10 | `SCOPE-P0-TRD-00` | kill switch de marketplace/trade | criação/listagem/match/proposta e copy pública bloqueados; nenhuma promessa comercial |
| 11 | `BT-AI-029` | runtime obsoleto/inseguro inacessível | reachability real, registry validation-only, owner/substituto/expiry e zero órfão desconhecido |

`BT-SCN-00` permanece PARKED nesta etapa: sua dependência `BT-CAT-02` é
fechada na onda de catálogo. Ele entra logo depois dela, não por antecipação.

## Segurança e privacidade

| Ordem | ID | A task conterá | Fechamento ponta a ponta específico |
| ---: | --- | --- | --- |
| 12 | `BT-AUTH-001` | erros públicos tipados | corpus de falhas sem SQL/stack/exception e com request-id estável |
| 13 | `BT-AUTH-002` | limites globais de body/campo/URL | oversize/chunked/compressed rejeitado antes de parse, alocação e DML |
| 14 | `BT-AUTH-003` | recuperação não enumerável | conta existente/inexistente indistinguível, rate limit, token single-use e sessão invalidada |
| 15 | `BT-AUTH-004` | step-up para export/delete | sessão/token velho ou roubado falha; rate limit distribuído e auditoria |
| 16 | `BT-AUTH-006` | admissão controlada | convite single-use/expirável/revogável, race/replay cobertos, zero usuário/email na negação |
| 17 | `BT-LEGAL-ACCEPT-001` | aceite legal versionado | versões exatas, reaceite seletivo e UX acionável |
| 18 | `BT-PRIV-001` | export allowlisted | isolamento A/B, conteúdo mínimo/completo, expiração e download auditado |
| 19 | `BT-PRIV-002` | exclusão por outbox/reconciliação | retries idempotentes, sidecars/jobs/caches/arquivos e receipt por consumer |
| 20 | `BT-PRIV-003` | inventário de retenção | owner, finalidade, prazo, export/delete e exceção legal por classe |
| 21 | `BT-SEC-001` | rate limiting distribuído | limiter-down fail-closed nas mutações caras; buckets e concorrência provados |
| 22 | `BT-SEC-AI-001` | callback IA privado | allowlist, redirect/DNS rebinding, token curto audience/job/user/nonce e replay cross-replica |
| 23 | `BT-SEC-AI-002` | pseudonimização de sinks | allowlist estruturada, zero ID bruto, retenção/export/delete e scan estático |

Saída da onda: fundação apta a receber o ledger do Deckbuilder. Features
continuam OFF até os receipts próprios.
