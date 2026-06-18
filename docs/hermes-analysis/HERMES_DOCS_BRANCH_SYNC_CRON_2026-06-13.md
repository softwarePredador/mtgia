# Hermes Docs Branch Sync Cron — 2026-06-13

> Status: novo guardrail operacional.
> Objetivo: impedir que auditorias Hermes em `codex/hermes-analysis-docs`
> analisem código defasado em relação a `origin/master`.

## Problema

As auditorias de documentação/estrutura do Hermes rodam historicamente na branch
`codex/hermes-analysis-docs`. Essa branch recebe merges periódicos de `master`,
mas pode ficar atrás do código vivo. Quando isso acontece, achados como
"função não chamada", "classe sem uso", "semântica por nome" ou "contrato
app/backend divergente" podem ser verdadeiros apenas para o snapshot antigo da
branch de docs, não para a `master` atual.

## Solução

Adicionar uma cron script-only que rode antes de qualquer auditoria que leia
código de produto a partir da branch `codex/hermes-analysis-docs`.

Script versionado:

```bash
server/bin/hermes_docs_branch_sync.sh
```

Comando runtime recomendado:

```bash
/opt/data/scripts/manaloom-docs-branch-sync.sh
```

## O que o script faz

1. Entra no workspace Hermes (`/opt/data/workspace/mtgia` por padrão).
2. Recusa rodar como `root`, salvo override explícito.
3. Recusa prosseguir se houver alterações tracked não commitadas.
4. Move arquivos untracked para quarentena em
   `/opt/data/artifacts/hermes_docs_branch_sync/untracked_quarantine_*`.
   Isso preserva artefatos locais gerados por replay/auditoria sem deixar que
   bloqueiem checkout/merge.
5. Faz `git fetch --prune` com refspec explícito para atualizar
   `origin/master` e `origin/codex/hermes-analysis-docs`.
6. Faz checkout de `codex/hermes-analysis-docs`.
7. Atualiza a branch docs com `git pull --ff-only origin codex/hermes-analysis-docs`.
8. Verifica se `origin/master` já está contido na branch docs.
9. Se não estiver, faz merge controlado de `origin/master` na branch docs.
10. Aborta e falha alto se houver conflito.
11. Faz push para `origin/codex/hermes-analysis-docs`.
12. Grava relatório em `/opt/data/artifacts/hermes_docs_branch_sync/`.

Ele nunca altera `master`.

## Instalação no Hermes runtime

Executar uma vez, como usuário com permissão no workspace:

```bash
cd /opt/data/workspace/mtgia
git checkout master
git pull --ff-only origin master
install -m 0755 server/bin/hermes_docs_branch_sync.sh \
  /opt/data/scripts/manaloom-docs-branch-sync.sh
chown hermes:hermes /opt/data/scripts/manaloom-docs-branch-sync.sh
```

## Cron nova

Nome recomendado:

```text
manaloom-docs-branch-sync
```

Tipo:

```text
script-only
```

Cadência recomendada:

```text
every 20m
```

Comando:

```bash
MANALOOM_WORKSPACE=/opt/data/workspace/mtgia \
HERMES_DOCS_SYNC_PUSH=1 \
/opt/data/scripts/manaloom-docs-branch-sync.sh
```

## Ordem obrigatória

Antes de qualquer uma destas crons ler `app/lib`, `server/lib`,
`server/routes`, `server/bin` ou arquivos de produto, a sync cron precisa ter
rodado com status `up_to_date` ou `merged`:

- `manaloom-commander-knowledge-deep`
- `manaloom-knowledge-synthesis`
- `manaloom-gamechanger-research`
- `mtg-rules-auditor`
- qualquer `manaloom-code-structure-auditor` reativado
- qualquer `manaloom-hermes-normal-audit` reativado
- qualquer `manaloom-hermes-weekly-parallel-audit` reativado
- qualquer `manaloom-logic-coherence-auditor` reativado

Se a sync cron retornar `blocked_merge_conflict`,
`blocked_dirty_worktree`, `blocked_push_failed` ou qualquer erro diferente de
`up_to_date`, `merged` ou `skipped_locked`, a auditoria seguinte deve retornar
`BLOCKED` e não publicar achado novo.

## Como encaixar nos prompts de auditoria

Todo prompt/cron de auditoria que opere na branch docs deve começar com:

```text
Antes de auditar código, confirme que a última execução de
manaloom-docs-branch-sync está up_to_date ou merged. Se não houver evidência
fresca, rode /opt/data/scripts/manaloom-docs-branch-sync.sh. Se a sync bloquear
por conflito/worktree sujo/push falho, pare e retorne BLOCKED.
```

## Validação manual

Dry-run seguro:

```bash
MANALOOM_WORKSPACE=/opt/data/workspace/mtgia \
HERMES_DOCS_SYNC_DRY_RUN=1 \
/opt/data/scripts/manaloom-docs-branch-sync.sh
```

Validação sintática:

```bash
bash -n server/bin/hermes_docs_branch_sync.sh
```

Checagem de divergência antes/depois:

```bash
cd /opt/data/workspace/mtgia
git fetch --all --prune
git rev-list --left-right --count origin/master...origin/codex/hermes-analysis-docs
git merge-base --is-ancestor origin/master origin/codex/hermes-analysis-docs
```

O último comando deve retornar código `0` depois da sync.

## Guardrails

- Não usar `git reset --hard` neste script.
- Não fazer merge de `codex/hermes-analysis-docs` para `master`.
- Não mascarar conflito com `|| true`.
- Rodar como usuário `hermes` para não quebrar permissões de SQLite/artifacts.
- Não executar auditoria de código se a branch docs não contém `origin/master`.
- Não apagar artefatos untracked do workspace Hermes sem rastreabilidade; usar a
  quarentena automática do docs-sync.
