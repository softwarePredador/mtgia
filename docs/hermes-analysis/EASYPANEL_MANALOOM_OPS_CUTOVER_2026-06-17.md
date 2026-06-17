# EasyPanel Cutover — ManaLoom Ops — 2026-06-17

## Objetivo

Absorver os jobs Hermes que agregam valor direto ao produto sem migrar o
Hermes inteiro para produção.

Escopo deste cutover:

- `pull_learning_events`
- `auto_sync_learned_decks`
- `master_optimizer_preflight`

Fora do escopo:

- chat/residência Hermes;
- branch docs/memória;
- jobs exploratórios com provider;
- research crons;
- qualquer job que altere documentação de análise em produção.

## Serviço alvo

Projeto EasyPanel:

- `evolution`

Novo serviço recomendado:

- `manaloom-ops`

Tipo:

- app/worker sem porta pública

Imagem/source:

- mesmo repositório `mtgia`
- Dockerfile dedicado: `server/Dockerfile.manaloom-ops`

## Por que não subir o Hermes inteiro

Porque o que o produto precisa não é o laboratório completo, e sim um runtime
operacional mínimo.

O Hermes completo mistura:

- scheduler;
- SQLite/cache;
- docs branch;
- agentes provider-heavy;
- research loops;
- auditorias exploratórias;
- memória operacional.

Isso não deve virar serviço de produção.

## Artefatos versionados deste slice

- `server/Dockerfile.manaloom-ops`
- `server/bin/manaloom_ops_entrypoint.sh`
- `server/bin/pull_learning_events.sh`
- `server/bin/auto_sync_learned_decks.sh`
- `server/bin/master_optimizer_preflight.sh`

## Runtime esperado

### Volume

Montar um volume persistente exclusivo:

- `/data/manaloom-ops`

Estrutura usada:

- `/data/manaloom-ops/knowledge.db`
- `/data/manaloom-ops/logs/`
- `/data/manaloom-ops/locks/`
- `/data/manaloom-ops/artifacts/`

### Variáveis mínimas

Usar o mesmo `server/.env` do ManaLoom como base e acrescentar no serviço:

- `MANALOOM_OPS_DATA_DIR=/data/manaloom-ops`
- `HERMES_KNOWLEDGE_DB=/data/manaloom-ops/knowledge.db`
- `MTGIA_ENV_FILE=/app/server/.env`
- `MANALOOM_DART_BIN=dart`
- `PULL_LEARNING_EVENTS_CRON=*/30 * * * *`
- `AUTO_SYNC_LEARNED_DECKS_CRON=0 */2 * * *`
- `MASTER_OPTIMIZER_PREFLIGHT_CRON=15 * * * *`
- `MANALOOM_RUN_PREFLIGHT_ON_BOOT=0`

Opcional:

- `MANALOOM_OPS_LOG_DIR=/data/manaloom-ops/logs`
- `MANALOOM_OPS_LOCK_DIR=/data/manaloom-ops/locks`
- `MANALOOM_OPS_ARTIFACT_DIR=/data/manaloom-ops/artifacts`

## Limites recomendados

Como o host já roda vários serviços e quase todos estão sem limites, o cutover
seguro exige limites explícitos neste novo serviço.

Começo recomendado:

- CPU reservation: `0.50`
- CPU limit: `1.00`
- Memory reservation: `512 MB`
- Memory limit: `1024 MB`

Se o preflight ficar pesado:

- manter `manaloom-ops` com `512 MB`
- criar depois um serviço separado `manaloom-preflight` com:
  - CPU limit: `1.00`
  - Memory limit: `1536 MB`

## Schedules usados

O entrypoint gera o crontab em runtime:

- `pull_learning_events`: `*/30 * * * *`
- `auto_sync_learned_decks`: `0 */2 * * *`
- `master_optimizer_preflight`: `15 * * * *`

Todos os jobs usam `flock` para evitar overlap.

Todos os jobs rodam sem `git pull`, `git checkout` ou mutação de branch em
runtime.

## Ordem de cutover

### Fase 1 — preparar

1. Confirmar que `server/.env` do deploy contém credenciais válidas do backend.
2. Criar o serviço `manaloom-ops` no projeto `evolution`.
3. Apontar para `server/Dockerfile.manaloom-ops`.
4. Montar volume persistente em `/data/manaloom-ops`.
5. Configurar limites explícitos de CPU/RAM.

### Fase 2 — smoke sem AWS desligada

Rodar no serviço novo:

1. `./server/bin/pull_learning_events.sh`
2. `./server/bin/auto_sync_learned_decks.sh`
3. `./server/bin/master_optimizer_preflight.sh`

Esperado:

- `pull_learning_events` importa ou responde sem erro estrutural;
- `auto_sync_learned_decks` faz dry-run/apply controlado sem `git pull`;
- `master_optimizer_preflight` gera artifacts e fecha sem depender de branch
  switching.

### Fase 3 — dupla execução controlada

Por 24h a 48h:

- manter AWS Hermes ainda ligada;
- manter `manaloom-ops` rodando;
- comparar:
  - artifacts de preflight;
  - progresso do `knowledge.db`;
  - sync de learned decks;
  - ausência de conflitos no PG.

### Fase 4 — corte

Se a dupla execução estiver estável:

1. pausar no Hermes AWS:
   - `manaloom-pull-learning-events`
   - `manaloom-auto-sync-learned-decks`
   - `manaloom-master-optimizer-preflight`
2. manter no EasyPanel apenas o `manaloom-ops`.

### Fase 5 — pós-corte

1. validar artifacts por 48h;
2. validar que nenhum job depende mais de `/opt/data`;
3. só então planejar a migração do próximo bloco:
   - `auto-promote-learned`
   - `mana-base-validator`
   - `cron-governor-report`

## Guardrails

- SQLite continua cache/laboratório, não fonte final;
- PostgreSQL continua fonte de verdade;
- nenhum metadata Hermes vai para o app normal;
- nenhum job de produção deve tocar `codex/hermes-analysis-docs`;
- nenhum job de produção deve fazer `git pull` em runtime;
- jobs exploratórios/provider-heavy continuam fora do runtime principal.

## Critério de sucesso

O cutover deste slice é considerado pronto quando:

1. `manaloom-ops` roda no EasyPanel com volume persistente;
2. os 3 jobs executam sem paths `/opt/data` hardcoded;
3. não há `git checkout/pull` no runtime;
4. os artifacts e logs ficam persistidos fora do container efêmero;
5. o Hermes AWS pode ser desligado para esses três jobs sem perda de função.
