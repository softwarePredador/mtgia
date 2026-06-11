# Hermes Runtime Cron Alignment — 2026-06-11

> Status: runtime AWS revisado e alinhado ao modelo de duas branches.
> Escopo: Hermes Agent em `/opt/data/workspace/mtgia`, crons em
> `/opt/data/cron/jobs.json` e scripts em `/opt/data/scripts`.

## Estado Git no Hermes

Comandos executados no container Hermes:

```bash
cd /opt/data/workspace/mtgia
git fetch --all --prune
git checkout master
git pull --ff-only origin master
git status --short --branch
git branch -r
```

Resultado esperado confirmado:

- `master` alinhada com `origin/master`.
- Remotes reais restantes:
  - `origin/master`
  - `origin/codex/hermes-analysis-docs`
- Branches antigas `copilot/*`, `codex/hermes-dev` e
  `codex/hermes-fixes-f0-f3` foram removidas do checkout remoto via prune.

## Estado das crons

Resumo após alinhamento:

| Métrica | Valor |
|---|---:|
| Jobs cadastrados | 25 |
| Jobs habilitados | 17 |
| Jobs pausados | 8 |

Jobs one-shot vencidos pausados:

| Job | Motivo |
|---|---|
| `manaloom-master-optimizer-loop` | `run_at` passado; não deve ficar enabled como fila fantasma |
| `manaloom-flutter-ui-auditor` | `run_at` passado; não deve ficar enabled como fila fantasma |

## Ajustes aplicados no runtime Hermes

Arquivos runtime ajustados no servidor:

- `/opt/data/cron/jobs.json`
- `/opt/data/scripts/manaloom-hermes-report-only.sh`
- `/opt/data/scripts/manaloom-post-push-audit.sh`
- `/opt/data/scripts/manaloom-master-watchdog.sh`

Backups criados:

- `/opt/data/cron/jobs.json.bak_codex_hermes_branch_protocol_20260611_122430`
- `/opt/data/scripts/*.bak_branch_protocol_20260611_122430`

Mudanças:

- Todos os prompts cron com texto receberam guardrail de branches.
- `manaloom-hermes-report-only.sh` agora usa `git fetch --all --prune`.
- `manaloom-post-push-audit.sh` reforça que `master` é canônica e a branch docs
  é staging/memory.
- `manaloom-master-watchdog.sh` agora usa fetch com `--prune`.
- Jobs one-shot vencidos foram desabilitados.

## Guardrail operacional

Crons Hermes podem:

- ler `origin/master`;
- gerar relatórios/memória em `docs/hermes-analysis/**`;
- escrever na branch `codex/hermes-analysis-docs`;
- sincronizar conhecimento runtime quando o script for explicitamente de sync.

Crons Hermes não podem:

- alterar código de produto em `master`;
- mergear/copiar relatório bruto da branch docs para `master`;
- criar tarefa sem evidência concreta;
- criar novas branches sem pedido humano.

## Fluxo Codex + Hermes validado

1. Codex trabalha e faz push em `master`.
2. Codex chama Hermes report-only contra o SHA pushado.
3. Hermes retorna `PASS`, `FINDINGS` ou `BLOCKED`.
4. Achados do Hermes viram tarefa real somente após triagem contra o código vivo.
5. Se a branch docs acumular relatório contraditório, Codex triage primeiro; não
   faz merge bruto.

## Validações executadas

```bash
python3 -m json.tool /opt/data/cron/jobs.json
bash -n /opt/data/scripts/manaloom-hermes-report-only.sh \
  /opt/data/scripts/manaloom-post-push-audit.sh \
  /opt/data/scripts/manaloom-master-watchdog.sh
```

Resultado: `validation=ok`.

## Correção pós-primeira rodada

Após o scheduler voltar a executar, dois problemas reais apareceram:

- permissões `root` em caminhos que o usuário `hermes` precisa escrever;
- `sync_pg_target_deck_to_hermes.py` quebrando em duplicatas de `card_name`
  contra a constraint `UNIQUE(deck_id, card_name)`.

Correções:

- ownership de `/opt/data/workspace/mtgia`, `/opt/data/cron`,
  `/opt/data/artifacts` e `/opt/data/scripts` restaurado para `hermes:hermes`;
- sync do target deck ajustado no repo para agregar duplicatas antes do insert.
- crons operacionais versionadas (`preflight`, `knowncards`, `slot-scan`,
  `auto-cycle`) ajustadas para executar código de `master`, não da branch
  `codex/hermes-analysis-docs`.

Regra operacional nova: pulls do checkout Hermes devem ser feitos como usuário
`hermes`, ou então seguidos de `chown -R hermes:hermes` nos caminhos acima. Isso
evita que as crons voltem a falhar por banco SQLite readonly.

Regra de branch nova: scripts operacionais que executam optimizer/sync devem
fazer checkout de `master`; apenas crons de memória, documentação e report-only
podem trabalhar em `codex/hermes-analysis-docs`.
