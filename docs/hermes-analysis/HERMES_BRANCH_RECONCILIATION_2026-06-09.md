# Hermes Branch Reconciliation — 2026-06-09

## Escopo

Reconciliacao entre `master`, `origin/codex/hermes-analysis-docs` e
`origin/codex/hermes-fixes-f0-f3` antes de continuar implementacoes oriundas dos
relatorios Hermes.

## Estado das branches

| Branch | Estado | Acao |
|---|---|---|
| `master` / `origin/master` | Fonte do produto. HEAD `9512e9a4` contem `BATTLE_SYSTEM_LOGIC.md`, `IMPLEMENTATION_GAPS.md` e `PENDING_TASKS.md`. | Continuar implementacoes aqui. |
| `origin/codex/hermes-fixes-f0-f3` | Sem commits a frente de `master` (`master...branch = 562/0`). | Nada a puxar; considerada subsumida. |
| `origin/codex/hermes-analysis-docs` | Divergencia intencional: memoria operacional do Hermes, relatorios, SQLite `knowledge.db`, scripts e artefatos. | Nao fazer merge bruto em `master`; importar apenas findings revalidados. |

## Documentos de battle engine em `master`

| Arquivo | Commit | Status |
|---|---:|---|
| `docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md` | `76ea80ed` | Canonico no `master`. |
| `docs/hermes-analysis/IMPLEMENTATION_GAPS.md` | `5c3336d8` | Canonico no `master`. |
| `docs/hermes-analysis/PENDING_TASKS.md` | `9512e9a4` | Canonico no `master`; lista 10 pendencias arquiteturais restantes. |

Esses tres arquivos nao existem em `origin/codex/hermes-analysis-docs` no mesmo
caminho. Isso nao e bug de produto; e diferenca de escopo entre branch de
memoria Hermes e branch de produto.

## Finding Hermes aplicado no produto

### P1 — Job polling com `user_id=NULL`

Status: **resolvido em `master`**.

Mudancas:

- `OptimizeJob.userId` agora e `String` obrigatoria.
- `AiGenerateJob.userId` agora e `String` obrigatoria.
- `AiGenerateJobStore.create` exige `required String userId`.
- Polling de optimize/generate retorna 404 para job sem dono (`userId.isEmpty`)
  ou dono diferente do usuario autenticado.
- Rota async de generate retorna `Authentication required` antes de criar job sem
  usuario.

Validacoes focadas:

```bash
cd server
dart analyze lib/ai/optimize_job.dart lib/ai_generate_job.dart \
  'routes/ai/optimize/jobs/[id].dart' \
  'routes/ai/generate/jobs/[id].dart' \
  routes/ai/generate/index.dart \
  test/ai_optimize_authorization_source_test.dart \
  test/ai_generate_job_authorization_source_test.dart \
  test/ai_generate_performance_support_test.dart

dart test test/ai_optimize_authorization_source_test.dart \
  test/ai_generate_job_authorization_source_test.dart \
  test/ai_generate_performance_support_test.dart -r expanded
```

## Proxima fila real

### Produto/backend imediato

1. Revalidar `origin/codex/hermes-analysis-docs:IMPLEMENTATION_TASKS.md` por
   evidencia no codigo antes de implementar.
2. Priorizar somente P1/P2 que afetam seguranca, deck generation, optimize ou
   consistencia app/backend.
3. Evitar importar `knowledge.db`, `__pycache__` e relatorios volumosos para
   `master` sem decisao explicita.

### Battle engine

Ordem recomendada conforme `PENDING_TASKS.md`:

1. APNAP trigger ordering.
2. Prioridade com pilha vazia nos main phases.
3. Passos de combate formais.
4. Casting pipeline 601.2.
5. Replacement/prevention effects.

Esses itens sao arquiteturais e devem entrar em ciclos dedicados com testes de
conformidade, nao como patch pequeno junto de hardening de API.
