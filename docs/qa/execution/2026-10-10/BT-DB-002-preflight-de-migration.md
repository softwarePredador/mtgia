# Receipt — BT-DB-002: disciplina de migration: preflight, payload e pós-checagem (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. A tarefa não tem superfície de UI própria.
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

O runner classifica o banco pelo ledger antes de qualquer DDL, inclusive antes de criar `schema_migrations`. O perfil misto para o runner com código 3, sem escrever. O ensaio compara o payload tabela a tabela e o catálogo inteiro contra a lista fechada da deriva. O número "059" do título ficou obsoleto: a 059 foi a D-66, e o conteúdo da D-48 foi para o `BT-DB-005`.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `807d224cb` | 2026-09-28 | feat(BT-DB-003): rehearse upgrades and rollback by restoring the same dump, and stop mixed databases before any DDL |

## Testes que cobrem o aceite

- `server/test/migration_preflight_test.dart`: o preflight do runner.
- `server/test/migration_rehearsal_test.py`: o ensaio.
- `server/test/migration_rehearsal_db_live_test.py`: PostgreSQL descartável, ligado no gate de schema.

## Outros arquivos

- `server/lib/migration_preflight.dart`: o preflight.
- `scripts/manaloom_migration_rehearsal.py`: o ensaio.
- `docs/qa/execution/2026-09-28/BT-DB-003-ensaio-de-upgrade.md`: o receipt que a linha usava, da tarefa vizinha.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- O ensaio no modo completo com o dump novo, no lote de deploy.
