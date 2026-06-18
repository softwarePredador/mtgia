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

## Ajuste de runtime aplicado no `hermes-lab`

Na tentativa de redeploy da revisao `ab490778`, o build do `hermes-lab`
falhou por `No space left on device` ao extrair o Flutter completo dentro da
imagem.

Correcao aplicada:

- `server/Dockerfile.hermes-lab` passou a instalar apenas Dart SDK standalone
  + `dart_frog_cli`;
- `server/bin/hermes_lab_entrypoint.sh` passou a exportar apenas o path do Dart
  SDK;
- o corte e coerente com a frota atual, porque nenhuma das 5 crons ativas do
  laboratorio depende de `flutter`.

Consequencia operacional:

- `hermes-lab` continua apto para chat/auditoria/docs/provider-backed;
- validacao mobile/UI continua fora do laboratorio Linux e segue no ambiente
  local do Codex.

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

## Follow-up live — 2026-06-18 08:51 UTC

Nova rodada validada em:

- `server/test/artifacts/easypanel_cron_runtime_2026-06-18_post_manual_knowledge_import/summary.json`
- `server/test/artifacts/easypanel_cron_runtime_2026-06-18_post_manual_knowledge_import/report.md`

Essa rodada fechou dois pontos que ainda pareciam ambíguos no snapshot das
06:23 UTC:

1. `manaloom_knowledge_import` no `manaloom-ops`
   - o erro antigo de `DATABASE_URL is not set` ficou para trás;
   - a evidência atual do cron aponta output real com import concluído e
     `manaloom_knowledge_import=ok`;
   - uma execução manual dentro do container confirmou import efetivo em
     PostgreSQL, com `card_deck_profiles` alterando e log final em
     `/app/server/test/artifacts/knowledge_import/knowledge_import_20260618_084640.log`.

2. Jobs provider-backed do `hermes-lab`
   - `manaloom-commander-knowledge-deep` já executou no container após a janela
     de agenda (`last_run_at=2026-06-18T08:50:58.445151+00:00`, `last_status=ok`);
   - `manaloom-gamechanger-research` e `manaloom-knowledge-synthesis` também
     rodaram e provaram o fluxo de gate, retornando `wakeAgent=false` quando não
     havia delta real;
   - isso confirma que a topologia final `gate script -> decisão wake/skip ->
     output em /opt/data/cron/output/<job_id>/...` está funcional no EasyPanel.

## Correção de observabilidade aplicada

O `manaloom-ops` ainda podia reaparecer com `last_status=None` após restart de
container mesmo quando um job já tinha output `ok`, porque o daemon zerava o
estado em memória e sobrescrevia `jobs.json` no boot.

Correção aplicada em `server/bin/manaloom_ops_daemon.py`:

- o daemon agora carrega o `jobs.json` existente antes de reescrever o
  manifesto;
- isso preserva `last_status`, `last_started_at`, `last_finished_at`,
  `last_exit_code` e `latest_output` de jobs já executados;
- quando o manifesto já tiver sido zerado por uma versão antiga do daemon, ele
  também reconstrói o estado básico a partir do log mais recente em
  `/data/manaloom-ops/cron/output/<job>/`;
- isso evita falsos negativos operacionais em auditorias logo após redeploy.

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

## Follow-up live — 2026-06-18 10:23 UTC

Rodada manual adicional validada em:

- `server/test/artifacts/easypanel_manual_provider_cron_run_2026-06-18_env_fix/summary.json`

O objetivo desta rodada foi provar o fluxo provider-backed sem esperar a
próxima janela do cron:

1. `hermes-lab` não pode ser testado com `hermes cron run/tick` em shell cru de
   inspeção sem forçar o mesmo ambiente do gateway (`HOME=/opt/data`,
   `HERMES_HOME=/opt/data`, `HERMES_STATE_ROOT=/opt/data`,
   `HERMES_CRON_JOBS_JSON=/opt/data/cron/jobs.json`).
2. Com esse ambiente aplicado, `hermes cron run 6f791f1baad5` seguido de
   `hermes cron tick` executou de fato o job
   `manaloom-commander-knowledge-deep`.
3. Evidência objetiva:
   - `last_run_at=2026-06-18T10:23:01.675572+00:00`;
   - `last_status=ok`;
   - output real em `/opt/data/cron/output/6f791f1baad5/2026-06-18_10-23-01.md`.

Essa prova fechou o ponto pendente "provider configurado, mas não executado
manualmente" no EasyPanel.

## Correcao de contrato aplicada

A mesma rodada manual encontrou um defeito menor, mas real, no contrato de
saída provider-backed:

- o job retornou relatório textual e também anexou `[SILENT]` no fim;
- isso não quebrou a execução, mas viola o contrato correto de delivery do
  Hermes (`ou [SILENT] puro, ou relatório normal`).

Correção aplicada em `server/bin/hermes_lab_cron_bootstrap.py`:

- todos os prompts provider-backed agora instruem explicitamente:
  - se não houver delta acionável, responder exatamente `[SILENT]`;
  - não emitir seções, bullets, headings ou texto extra nesse caso;
  - só produzir a estrutura `1/2/3` quando realmente houver delta material.

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

## Fechamento adicional — branch stale e escopo fora do produto

Depois da primeira prova manual de provider, a rodada seguinte mostrou um drift
mais sutil, mas mais perigoso:

- os jobs provider-backed estavam rodando com `repo_head=88fa4a1e...`, isto e,
  a HEAD da `codex/hermes-analysis-docs`;
- ao mesmo tempo, o deploy vivo do produto ja estava em `b6500c7a...` na
  `master`.

Diagnostico:

- `manaloom-docs-branch-sync.sh` estava correto em mergear `origin/master` na
  branch de docs, mas errado em deixar o workspace principal parado nessa
  branch ao final;
- como os jobs provider-backed usam o workspace do container, isso fazia o
  Hermes auditar codigo stale por design operacional, nao por bug do provider.

Correcao aplicada nesta mesma trilha:

- `server/bin/hermes_docs_branch_sync.sh` agora restaura o workspace para
  `master`/`HERMES_REPO_REF` no final do fluxo;
- o comportamento foi coberto por teste real de Git em
  `server/test/hermes_docs_branch_sync_test.py`;
- `server/bin/hermes_lab_cron_bootstrap.py` endureceu tambem o escopo dos
  prompts provider-backed para ignorar `optional-mcps/` e manifests alheios ao
  runtime ManaLoom, porque um smoke do `manaloom-knowledge-synthesis`
  retornou tarefas falsas sobre `optional-mcps/*`.

Prova objetiva do ruido fora de escopo:

- `manaloom-knowledge-synthesis` executou com `status=ok`, mas o output da
  rodada anterior sugeriu tasks para `optional-mcps/linear/manifest.yaml` e
  `optional-mcps/n8n/manifest.yaml`, sem relacao com o runtime do produto;
- isso confirmou que o problema nao era "falta de key OpenAI", e sim falta de
  delimitacao do workspace auditavel.

Estado correto apos o ajuste:

- `hermes-lab` continua sendo o runtime provider-backed;
- `manaloom-ops` continua sendo o runtime deterministico/operacional;
- `master` volta a ser a arvore viva auditada pelo Hermes;
- `codex/hermes-analysis-docs` continua como memoria derivada e branch de
  documentacao, nao como worktree persistente do produto.
