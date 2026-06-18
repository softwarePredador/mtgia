# EasyPanel Cron Migration Slice 1 — 2026-06-17

## Objetivo

Fechar o primeiro slice de migração Hermes -> ManaLoom server/EasyPanel sem
reescrever a arquitetura. Este slice só trata entrypoints operacionais e
portabilidade de runtime.

Princípios:

- PostgreSQL/backend continuam sendo a fonte de verdade.
- Hermes continua sendo laboratório e auditoria.
- SQLite Hermes continua sendo cache operacional.
- Nenhum contrato app-facing muda neste slice.
- Não existe `git checkout`/`git pull` embutido no job do produto.

## O que entrou neste slice

### 1. `pull_learning_events`

Arquivo:

- `server/bin/pull_learning_events.py`
- `server/bin/pull_learning_events.sh`

Mudança:

- remove default hardcoded de `/opt/data/workspace/...`;
- passa a derivar o repositório a partir de `server/bin`;
- aceita overrides por ambiente:
  - `HERMES_KNOWLEDGE_DB`
  - `MTGIA_SYNC_HOME`
  - `MTGIA_SYNC_SERVER_DIR`
  - `MTGIA_ENV_FILE`
- wrapper shell agora executa o script local do repositório.

Resultado:

- o job fica executável tanto no Hermes AWS quanto em um container EasyPanel do
  servidor ManaLoom;
- a dependência de path absoluto de laboratório some do entrypoint.

### 2. `auto_sync_learned_decks`

Arquivo:

- `server/bin/auto_sync_learned_decks.py`
- `server/bin/auto_sync_learned_decks.sh`

Mudança:

- remove defaults fixos de `/opt/data/workspace/mtgia`,
  `/opt/data/workspace/mtgia-sync` e `/opt/data/artifacts/...`;
- usa `server/bin` como âncora do repo;
- `dart` deixa de depender de `/opt/data/tools/flutter/bin/dart` e passa a
  aceitar:
  - `MANALOOM_DART_BIN`
  - `DART_BIN`
  - `dart` encontrado no `PATH`;
- `.env` passa a ser resolvido via:
  - `MTGIA_ENV_FILE`
  - `server/.env` do repo sincronizado
  - `MANALOOM_POSTGRES_ENV` quando existir;
- artefatos passam a ir por default para
  `server/test/artifacts/hermes_auto_sync`.

Resultado:

- o sync de learned decks deixa de depender da topologia exata do host Hermes;
- o job fica pronto para rodar como cron de aplicação no servidor.

### 3. `master_optimizer_preflight`

Arquivo novo:

- `server/bin/master_optimizer_preflight.sh`

Mudança:

- cria um entrypoint server-owned para o preflight do optimizer;
- preserva a sequência atual de sync/preflight:
  - `sync_pg_meta_decks_to_hermes.py`
  - `sync_pg_target_deck_to_hermes.py`
  - `lorehold_canonical_deck_snapshot.py` quando `deck_id=6`
  - `sync_pg_card_metadata_to_hermes.py`
  - `sync_battle_card_rules_pg.py --apply-pg`
  - `sync_battle_card_rules_pg.py --apply-sqlite-from-pg`
  - `master_optimizer_loop.py --preflight --report`
- remove o acoplamento com:
  - `git fetch`
  - `git checkout master`
  - `git pull --ff-only origin master`
- usa env/config do container atual, não branch switching interno.

Resultado:

- o preflight pode migrar para um job isolado do EasyPanel sem alterar o estado
  Git do workspace em produção;
- a responsabilidade de deploy/pinning de commit fica no processo de release,
  não no cron runtime.

## Matriz operacional

### Migrar agora

| Job | Motivo |
|---|---|
| `manaloom-pull-learning-events` | alimenta o loop app -> backend -> Hermes com dados reais |
| `manaloom-auto-sync-learned-decks` | move learned decks elegíveis para o fluxo do produto |
| `manaloom-master-optimizer-preflight` | protege geração/optimize contra dados stale |

### Migrar depois do Slice 1

| Job | Condição |
|---|---|
| `manaloom-auto-promote-learned` | precisa rodar com auditoria e gates claros no backend |
| `manaloom-mana-base-validator` | pode virar rotina determinística de qualidade server-side |
| `lorehold-knowncards-validator` | deve deixar de depender do laboratório Hermes para checks básicos |
| `mtg-rules-auditor` | deve evoluir para suite/golden scenarios e não cron isolada |
| `manaloom-cron-governor-report` | deve virar health interno do runtime final |

### Manter como laboratório Hermes

| Job | Motivo |
|---|---|
| `manaloom-commander-knowledge-deep` | extração exploratória, provider-dependent |
| `manaloom-knowledge-synthesis` | produz tarefas/hipóteses, não verdade do produto |
| `manaloom-gamechanger-research` | pesquisa de corpus e gaps, sem efeito operacional imediato |

### Descontinuar quando a migração fechar

| Job | Substituto esperado |
|---|---|
| `manaloom-master-watchdog` | webhook/CI/release pipeline |
| wrappers `/opt/data/scripts/...` hardcoded | entrypoints versionados em `server/bin` |
| `git checkout/pull` dentro de cron operacional | deploy pinado por imagem/commit no EasyPanel |

## Próximos passos

1. Instalar os três jobs migrados no runtime EasyPanel usando os entrypoints
   versionados em `server/bin`.
2. Validar cada job com ambiente explícito:
   - `MTGIA_ENV_FILE`
   - `HERMES_KNOWLEDGE_DB`
   - `MANALOOM_DART_BIN` quando `dart` não estiver no `PATH`
3. Confirmar que os artefatos ficam em diretórios previsíveis do projeto ou em
   volume dedicado do container.
4. Depois disso, mover o próximo slice:
   - `auto-promote-learned`
   - `mana-base-validator`
   - `cron-governor-report`

## Fora do escopo deste slice

- remover SQLite Hermes;
- reescrever scripts Python para Dart;
- mexer em contratos do app;
- alterar battle logic;
- mudar learned deck policy;
- substituir Hermes como laboratório.
