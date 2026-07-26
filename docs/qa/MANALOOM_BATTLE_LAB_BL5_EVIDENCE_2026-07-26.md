# Evidência BL5 — Jobs assíncronos

- Data: 2026-07-26
- Resultado: `PASS_LOCAL_FEATURE_OFF`
- Rollout live: não executado

| Task | Estado | Evidência |
|---|---|---|
| BL5-01 | `PASS_LOCAL` | `battle_job_v1` fecha owner, hashes, engine, status/stage, progresso, timeout, tentativa e replay |
| BL5-02 | `PASS_LOCAL` | create/list/get/cancel autenticados; idempotency key e máquina de estados fechada |
| BL5-03 | `PASS_LOCAL` | daemon faz claim com lease/heartbeat/fencing, retry limitado e recuperação sem replay duplicado |
| BL5-04 | `PASS_LOCAL` | falha operacional é terminal; `auto` só avança XMage→Forge→native por gap estruturado |
| BL5-05 | `PASS_LOCAL` | quota por usuário/global e locks de admissão por lane; `auto` conflita com todas as lanes |
| BL5-06 | `PASS_LOCAL` | `BattleJobMetricsService` expõe no dashboard ops somente agregados redigidos de tentativas, duração, fila, payload, truncamento, fallback e persistência |
| BL5-07 | `PASS_LOCAL` | cancelamento imediato na fila e cooperativo após claim; chamada HTTP já enviada não é falsamente declarada abortada |

## Correlação

`battle_job_request_v1` possui hash próprio. Cada dispatch usa o schema/hash do
engine e vincula job → engine request → tentativa → replay. XMage/Forge
aceitos exigem echo validado; native e falha sem resposta aceita ficam
explicitamente `server_dispatch_recorded`.

## Validação

- 86/86 testes Dart focados/integrados;
- runner final: 8/8, incluindo censura;
- PostgreSQL descartável migrations 001–055 e executor real: 1/1;
- concorrência de dois workers, cancelamento, fencing, retry ceiling,
  soft-delete e owner scope aprovados;
- engine capabilities 95/95; estratégia XMage 29/29;
- contrato de métricas BL5: 3/3 e query exercitada pelo gate oficial de schema
  no PostgreSQL descartável;
- worker compilado AOT; scripts shell e `git diff --check` verdes.

Todos os clusters/diretórios PostgreSQL de teste foram removidos. A migration
054 não foi aplicada live. O recurso permanece sujeito à flag e ao gate de
deploy/readiness da mesma SHA.
