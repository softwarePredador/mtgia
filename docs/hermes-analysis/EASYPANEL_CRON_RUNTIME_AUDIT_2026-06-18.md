# EasyPanel Cron Runtime Audit — 2026-06-18

## Objetivo

Fechar a validacao operacional da frota migrada para EasyPanel e provar, com
evidencia live, quais jobs sao deterministicas, quais dependem de provider e
qual runtime hoje usa `OPENAI_API_KEY`.

## Estado validado

- `manaloom-ops`
  - runtime deterministico
  - `OPENAI_API_KEY` ausente por design
  - health publico em `215af0c719e4d5c4b20f157569024dbf4637e64d`
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
  - health publico em `215af0c719e4d5c4b20f157569024dbf4637e64d`
  - `MANALOOM_KNOWLEDGE_DB=/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
  - jobs ativos:
    - `manaloom-docs-branch-sync`
    - `manaloom-commander-knowledge-deep`
    - `manaloom-gamechanger-research`
    - `manaloom-knowledge-synthesis`
    - `mtg-rules-auditor`

## Evidencia live

Artefatos principais:

- `server/test/artifacts/easypanel_cron_runtime_2026-06-18_live/summary.json`
- `server/test/artifacts/easypanel_cron_runtime_2026-06-18_live/report.md`
- `server/test/artifacts/easypanel_cron_runtime_2026-06-18_goal_live_proved/summary.json`
- `server/test/artifacts/easypanel_cron_runtime_2026-06-18_goal_live_proved/report.md`

No fechamento desta rodada o auditor passou a provar mais do que `jobs.json`.
Agora cada servico registra:

- probe de shell dentro do container (`user`, `uid`, `hostname`, `pwd`,
  `repo_exists`);
- caminho real de output por job;
- preview do tail desse output.

Isso confirmou execucao real por arquivo para:

- `manaloom-ops`
  - `pull_learning_events`
  - `auto_sync_learned_decks`
  - `master_optimizer_preflight`
  - e tambem evidencia historica acessivel para
    `auto_promote_learned_decks`,
    `manaloom_knowledge_import`,
    `hermes_mana_base_validator`,
    `hermes_cron_governor_report`

- `hermes-lab`
  - `manaloom-docs-branch-sync`
  - `mtg-rules-auditor`

Revalidacao direta do `jobs.json` no container `hermes-lab` tambem confirmou
`last_status=ok` para os jobs provider-backed que ja tinham rodado antes do
ultimo bootstrap:

- `manaloom-commander-knowledge-deep` -> `2026-06-18T04:35:14.308545+00:00`
- `mtg-rules-auditor` -> `2026-06-18T04:35:14.396159+00:00`
- `manaloom-gamechanger-research` -> `2026-06-18T04:42:36.265235+00:00`
- `manaloom-knowledge-synthesis` -> `2026-06-18T04:42:36.403394+00:00`

Isso fecha a prova operacional forte de que:

1. a topologia `manaloom-ops` vs `hermes-lab` esta coerente;
2. o runtime provider-backed realmente executa jobs no EasyPanel;
3. os jobs deterministcos tambem escrevem output real no volume esperado;
4. a OpenAI key esta sendo consumida apenas onde deveria.

## Probe de runtime

O auditor agora prova shell real dentro dos containers:

- `manaloom-ops`
  - `user=root`
  - `pwd=/app/server`
  - `repo_exists=no`
  - leitura de outputs em `/data/manaloom-ops/cron/output/...`

- `hermes-lab`
  - `user=root`
  - `pwd=/opt/hermes`
  - `repo_exists=yes`
  - leitura de outputs em `/opt/data/cron/output/<job_id>/...`

Essa diferenca e coerente com a arquitetura final:

- `manaloom-ops` nao precisa do repo checked-out para jobs deterministcos;
- `hermes-lab` precisa do repo montado porque os jobs gated auditam codigo/docs.

## Achado operacional

Os logs amostrados ainda mostraram warnings antigos de `read_file` para paths
de diretorio como:

- `docs/hermes-analysis/manaloom-knowledge/decks`
- `server/test/artifacts`

Isso nao quebrou a execucao final dos jobs, mas ainda gera ruido em rodadas
mais antigas e pode alongar execucoes provider-backed desnecessariamente.

## Correcao aplicada

`server/bin/hermes_lab_cron_bootstrap.py` foi endurecido para que todos os
prompts provider-backed:

- priorizem `latest_files` do contexto da cron;
- nao recebam mais os diretorios observados como contexto bruto;
- recebam apenas `scope_summary`, `watch_root_count` e `latest_files`;
- nunca tentem `read_file` em diretorio;
- enumerem arquivos com `rg --files`, `find`, `ls` ou `git diff --name-only`
  antes de abrir evidencias concretas.

## Estado residual correto

- `manaloom-commander-knowledge-deep`,
  `manaloom-gamechanger-research` e
  `manaloom-knowledge-synthesis`
  ainda nao tinham output novo neste snapshot porque o bootstrap atual recriou
  os jobs e a proxima janela de agenda ainda nao havia disparado;
- isso nao e falha: o auditor encontrou `jobs.json` coerente, schedule valida e
  bootstrap report consistente;
- o que faltava provar neste slice era acesso real ao output por job, e isso
  ficou fechado.

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
3. prova de output acessivel dentro do container, nao so `last_status=ok`;
4. consumo restrito de provider.
