# EasyPanel Cron Migration Slice 2 — 2026-06-17

## Objetivo

Expandir o `manaloom-ops` com o segundo bloco de jobs determinísticos que ainda
estavam presos à topologia do Hermes AWS.

Jobs adicionados neste slice:

- `auto_promote_learned_decks`
- `hermes_mana_base_validator`
- `hermes_cron_governor_report`

## Mudanças técnicas

### 1. Defaults portáveis

Os scripts deixaram de depender de:

- `/opt/data/workspace/mtgia/...`
- `/opt/data/cron/...`
- `/opt/data/scripts/...`

e passaram a aceitar:

- `MANALOOM_REPO`
- `MANALOOM_OPS_DATA_DIR`
- `HERMES_KNOWLEDGE_DB`
- `HERMES_PROFILE_ARTIFACTS_DIR`
- `HERMES_CRON_JOBS_JSON`
- `HERMES_CRON_OUTPUT_DIR`
- `HERMES_SCRIPTS_DIR`

### 2. Shell wrappers versionados

Foram adicionados entrypoints estáveis em `server/bin`:

- `auto_promote_learned_decks.sh`
- `hermes_mana_base_validator.sh`
- `hermes_cron_governor_report.sh`

### 3. Estado do scheduler no volume do serviço

O `manaloom_ops_daemon.py` agora escreve:

- manifesto de jobs em `cron/jobs.json`;
- logs por job em `cron/output/<job>/timestamp.log`;
- `last_status`, `last_exit_code`, timestamps e caminho do último output.

Isso permite health/report local sem depender do estado do Hermes AWS.

## Validação mínima deste slice

- `python3 -m py_compile` dos scripts alterados;
- `python3 server/test/auto_promote_learned_decks_test.py`
- `python3 server/test/hermes_mana_base_validator_test.py`
- `python3 server/test/hermes_cron_governor_report_test.py`
- smoke do daemon com schedules impossíveis para provar bootstrap e geração de
  `jobs.json`.

## Fora do escopo

- mover research/provider jobs para produção;
- substituir o Hermes chat/dashboard por este worker;
- expor metadata Hermes ao app;
- mexer em contratos mobile.
