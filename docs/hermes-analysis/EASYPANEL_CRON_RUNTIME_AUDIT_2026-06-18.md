# EasyPanel Cron Runtime Audit — 2026-06-18

## Objetivo

Fechar a validacao operacional da frota migrada para EasyPanel e provar, com
evidencia live, quais jobs sao deterministicas, quais dependem de provider e
qual runtime hoje usa `OPENAI_API_KEY`.

## Estado validado

- `manaloom-ops`
  - runtime deterministico
  - `OPENAI_API_KEY` ausente por design
  - `MANALOOM_GIT_SHA=41d751f7f3c9dd9e89751edac855a2021f43b085`
  - `MANALOOM_KNOWLEDGE_DB=/data/manaloom-ops/knowledge.db`
  - jobs ativos:
    - `pull_learning_events`
    - `auto_sync_learned_decks`
    - `auto_promote_learned_decks`
    - `master_optimizer_preflight`
    - `manaloom_knowledge_import`
    - `hermes_mana_base_validator`
    - `hermes_cron_governor_report`

- `hermes-lab`
  - runtime provider-backed
  - `HERMES_PROVIDER=openai-api`
  - `HERMES_MODEL=gpt-4o-mini`
  - `OPENAI_API_KEY` presente
  - `MANALOOM_GIT_SHA=41d751f7f3c9dd9e89751edac855a2021f43b085`
  - `MANALOOM_KNOWLEDGE_DB=/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
  - jobs ativos:
    - `manaloom-docs-branch-sync`
    - `manaloom-commander-knowledge-deep`
    - `manaloom-gamechanger-research`
    - `manaloom-knowledge-synthesis`
    - `mtg-rules-auditor`

## Evidencia live

Artefato principal:

- `server/test/artifacts/easypanel_cron_runtime_2026-06-18_live/summary.json`
- `server/test/artifacts/easypanel_cron_runtime_2026-06-18_live/report.md`

Revalidacao direta do `jobs.json` no container `hermes-lab` confirmou `last_status=ok`
para os jobs provider-backed:

- `manaloom-commander-knowledge-deep` -> `2026-06-18T04:35:14.308545+00:00`
- `mtg-rules-auditor` -> `2026-06-18T04:35:14.396159+00:00`
- `manaloom-gamechanger-research` -> `2026-06-18T04:42:36.265235+00:00`
- `manaloom-knowledge-synthesis` -> `2026-06-18T04:42:36.403394+00:00`

Isso fecha a prova minima de que:

1. a topologia `manaloom-ops` vs `hermes-lab` esta coerente;
2. o runtime provider-backed realmente executa jobs no EasyPanel;
3. a OpenAI key esta sendo consumida apenas onde deveria.

## Achado operacional

Os logs do `hermes-lab` mostraram warnings de `read_file` para paths de
diretorio como:

- `docs/hermes-analysis/manaloom-knowledge/decks`
- `server/test/artifacts`

Isso nao quebrou a execucao final dos jobs, mas gera ruido e pode alongar
rodadas provider-backed desnecessariamente.

## Correcao aplicada

`server/bin/hermes_lab_cron_bootstrap.py` foi endurecido para que todos os
prompts provider-backed:

- priorizem `latest_files` do contexto da cron;
- tratem `watch_root_hints` apenas como escopo;
- nunca tentem `read_file` em diretorio;
- enumerem arquivos com `rg --files`, `find`, `ls` ou `git diff --name-only`
  antes de abrir evidencias concretas.

## Proxima regra operacional

- `manaloom-ops` continua dono de:
  - sync PG -> SQLite operacional
  - learned deck sync/promote
  - preflight deterministico
  - validacoes de mana/cron

- `hermes-lab` continua dono de:
  - auditorias report-only
  - regras/strategy delta review
  - knowledge synthesis
  - pesquisas provider-backed pequenas e delta-gated

Qualquer cron nova deve entrar primeiro como:

1. escopo pequeno;
2. delta-gated;
3. prova de `last_status=ok` no EasyPanel;
4. consumo restrito de provider.
