# EasyPanel Cutover — ManaLoom Ops — 2026-06-17

## Objetivo

Absorver os jobs Hermes que agregam valor direto ao produto sem migrar o
Hermes inteiro para produção.

Escopo atual do cutover:

- `pull_learning_events`
- `auto_sync_learned_decks`
- `auto_promote_learned_decks`
- `master_optimizer_preflight`
- `hermes_mana_base_validator`
- `hermes_cron_governor_report`

Fora do escopo:

- chat/residência Hermes;
- branch docs/memória;
- jobs exploratórios com provider;
- research crons;
- qualquer job que altere documentação de análise em produção.

Nota operacional:

- o `hermes-lab` pode coexistir no mesmo projeto EasyPanel, mas não precisa de
  domínio público para o cutover do worker determinístico;
- o worker operacional deve permanecer separado do container Hermes completo.

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

## Artefatos versionados dos slices operacionais

- `server/Dockerfile.manaloom-ops`
- `server/bin/manaloom_ops_entrypoint.sh`
- `server/bin/manaloom_ops_daemon.py`
- `server/bin/pull_learning_events.sh`
- `server/bin/auto_sync_learned_decks.sh`
- `server/bin/auto_promote_learned_decks.sh`
- `server/bin/master_optimizer_preflight.sh`
- `server/bin/hermes_mana_base_validator.sh`
- `server/bin/hermes_cron_governor_report.sh`

## Runtime esperado

### Volume

Montar um volume persistente exclusivo:

- `/data/manaloom-ops`

Estrutura usada:

- `/data/manaloom-ops/knowledge.db`
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

- `MANALOOM_OPS_LOCK_DIR=/data/manaloom-ops/locks`
- `MANALOOM_OPS_ARTIFACT_DIR=/data/manaloom-ops/artifacts`
- `AUTO_PROMOTE_LEARNED_DECKS_CRON=30 */6 * * *`
- `HERMES_MANA_BASE_VALIDATOR_CRON=45 */6 * * *`
- `HERMES_CRON_GOVERNOR_REPORT_CRON=0 */12 * * *`

## Tokens e provider

`manaloom-ops` nao precisa de token de IA para os jobs migrados neste cutover.

Os seis jobs acima sao deterministicos e usam:

- PostgreSQL do backend;
- `knowledge.db` no volume do worker;
- scripts versionados no repositório;
- artefatos locais do projeto.

Eles nao dependem de:

- OpenAI;
- DeepSeek;
- Claude;
- Gemini;
- dashboard/chat Hermes.

Se o serviço receber um token de IA por conveniência operacional, ele deve ser
tratado como opcional e nao como pre-requisito do worker.

## Runtime final aplicado

O serviço não usa mais `cron`/`crond`. O runtime final é:

- `server/bin/manaloom_ops_entrypoint.sh`
- `server/bin/manaloom_ops_daemon.py`
- loop foreground em Python
- `flock` por job
- logs no `stdout/stderr` do container
- sem porta pública
- sem domínio atrelado ao serviço
- `deploy.command=/bin/bash /app/server/bin/manaloom_ops_entrypoint.sh`

Isso foi necessário porque o serviço criado como `app` no EasyPanel estava
concluindo o build, mas não estabilizava task em runtime com a configuração
anterior baseada em `cron` dentro do container.

## Recursos

Configuração final aplicada no serviço:

- CPU reservation: `0`
- CPU limit: `0`
- Memory reservation: `0`
- Memory limit: `0`

Motivo:

- havia indício de *placement/runtime ambiguity* no Swarm;
- o job é leve na maior parte do tempo;
- o objetivo do slice era primeiro estabilizar o worker.

Se o preflight crescer materialmente, o próximo passo é separar `manaloom-preflight`
em outro serviço, em vez de reapertar limites cedo demais.

## Schedules usados

O daemon faz polling de minuto e avalia expressões cron simples em runtime:

- `pull_learning_events`: `*/30 * * * *`
- `auto_sync_learned_decks`: `0 */2 * * *`
- `auto_promote_learned_decks`: `30 */6 * * *`
- `master_optimizer_preflight`: `15 * * * *`
- `hermes_mana_base_validator`: `45 */6 * * *`
- `hermes_cron_governor_report`: `0 */12 * * *`

Todos os jobs usam `flock` para evitar overlap e executam a partir do checkout
do repo em `/app`.

Todos os jobs rodam sem `git pull`, `git checkout` ou mutação de branch em
runtime.

## Estado operacional materializado pelo daemon

O `manaloom_ops_daemon.py` agora escreve estado local do scheduler no próprio
volume:

- `/data/manaloom-ops/cron/jobs.json`
- `/data/manaloom-ops/cron/output/<job>/*.log`

Isso permite que `hermes_cron_governor_report.py` rode no próprio worker sem
depender de `/opt/data/cron/jobs.json` do Hermes AWS.

## Ordem de cutover

### Fase 1 — preparar

1. Confirmar que `server/.env` do deploy contém credenciais válidas do backend.
2. Criar o serviço `manaloom-ops` no projeto `evolution`.
3. Apontar para `server/Dockerfile.manaloom-ops` com source path `/`.
4. Montar volume persistente em `/data/manaloom-ops`.
5. Remover domínio/porta pública do serviço.
6. Definir `deploy.command=/bin/bash /app/server/bin/manaloom_ops_entrypoint.sh`.

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
3. em caso de rollout do código, rodar `deployService` seguido de
   `restartService`/`startService` se a task não reaparecer automaticamente.

### Fase 5 — pós-corte

1. validar artifacts por 48h;
2. validar que nenhum job depende mais de `/opt/data`;
3. só então manter fora do worker principal o que ainda for laboratório:
   - chat Hermes;
   - docs branch;
   - jobs provider-heavy;
   - research loops.

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

## Estado validado em 2026-06-17

- commit do serviço no deploy: `d3e9de20`
- deploy action do EasyPanel: concluída com sucesso
- task do Swarm: `actual=1`, `desired=1`
- container observado como `running`
- comando efetivo do container:
  - `/bin/bash /app/server/bin/manaloom_ops_entrypoint.sh`
