# Hermes Analysis: Audit Report 2026-05-27

> Status atual: historico/snapshot antigo.
> Nao use como fonte operacional atual do Hermes. Consulte `README.md` e
> `HERMES_E2E_SYSTEM_CONTRACT_2026-06-07.md` antes de agir.

> Auditoria agendada em `origin/master` 7329fbbd, com branch de memoria
> `codex/hermes-analysis-docs`. Subtarefas separadas cobriram Flutter app/UX,
> backend contratos/rotas, IA semantica/optimize, deriva documental e commits
> recentes. Hermes nao editou codigo de produto nem `master`.

## Sumario executivo

- `origin/master` nao avancou alem de `7329fbbd`; backend publicado confirmou
  `git_sha=7329fbbdd0d5ea3e88de50d3c8235e76852380f4`.
- A auditoria encontrou novos riscos acionaveis em:
  - authorization de `/ai/optimize` por ownership de deck;
  - polling de jobs async com `user_id = NULL`;
  - cobertura de rota para Semantic Layer v2 partial;
  - fillers de optimize/complete com bracket sem deck atual em alguns caminhos;
  - estados de erro do `ChatScreen`;
  - cobertura deterministica de `MarketScreen`/`MarketProvider`;
  - deriva documental em `/ready`, `docs/README.md` e `CONTEXTO_PRODUTO_ATUAL.md`.
- Achados consolidados em:
  - `docs/hermes-analysis/UI_ACTIONABLE_TASKS.md`
  - `docs/hermes-analysis/BACKEND_ACTIONABLE_TASKS.md`
  - `docs/hermes-analysis/OPEN_RISKS.md`
  - `docs/hermes-analysis/TECHNICAL_MAP.md`
  - `docs/hermes-analysis/COMMIT_DIGEST.md`

## Achados prioritarios

### P1 — `POST /ai/optimize` precisa escopar deck por owner
- **Evidencia:** `server/routes/ai/optimize/index.dart` le `userId` mas chama
  `loadOptimizeDeckContext` sem passar esse owner; `server/lib/ai/optimize_request_support.dart`
  busca deck/cartas somente por `deck_id`.
- **Impacto:** risco de usuario autenticado otimizar/inspecionar deck que nao possui.
- **Doc:** `BACKEND_ACTIONABLE_TASKS.md` BE.1.

### P1 — ChatScreen mascara falha de carregamento e pode perder rascunho
- **Evidencia:** `MessageProvider.fetchMessages` guarda erro, mas `ChatScreen`
  cai em `chat-empty-state` quando `messages.isEmpty`; `_sendMessage` limpa o
  controller antes de saber se `sendMessage` retornou sucesso.
- **Impacto:** usuario pode ver conversa vazia em outage e perder texto de negociacao.
- **Doc:** `UI_ACTIONABLE_TASKS.md` P1.5/P1.6.

### P1 — Semantic Layer v2 partial ainda precisa prova de rota
- **Evidencia:** branch 422 `OPTIMIZE_SEMANTIC_V2_REJECTED` existe na rota, mas
  testes atuais cobrem helpers em `optimization_validator_test.dart`, nao o shape
  real da rota.
- **Impacto:** nao habilitar partial fora de staging/controlado sem teste de endpoint.
- **Doc:** `BACKEND_ACTIONABLE_TASKS.md` BE.2.

## P2 relevantes

- `GET /ai/optimize/jobs/:id` permite leitura de jobs com `user_id = NULL` se o
  ID for conhecido — `BACKEND_ACTIONABLE_TASKS.md` BE.3.
- Contrato de optimize nao documenta ownership/unauthorized — BE.4.
- Fillers de optimize/complete usam `currentDeckCards: const []` ou fallback sem
  bracket em alguns caminhos — BE.5.
- `/ready` esta documentado como deprecated/not audited embora o codigo o trate
  como alias operacional de `/health/ready` — BE.6.
- `MarketScreen`/`MarketProvider` nao tem unit/widget deterministico dedicado
  para loading/erro/empty/needs-data/cache/refresh — `UI_ACTIONABLE_TASKS.md` P2.5.
- `docs/README.md` omite `docs/CONTEXTO_PRODUTO_ATUAL.md` da lista canonica,
  enquanto o proprio contexto se declara fonte de verdade.

## Commits recentes

- `7329fbbd..origin/master` vazio.
- `f57bb8d3..origin/master` contem somente `7329fbbd`, commit DOC-only que adiciona
  `docs/qa/HERMES_VALIDATION_REQUEST_SEMANTIC_FALLBACKS_2026-05-26.md`.
- `COMMIT_DIGEST.md` estava correto quanto ao HEAD; apenas ajustado texto para
  evitar ambiguidade de parser.

## Validacoes executadas

- Health publico: `git_sha=7329fbbdd0d5ea3e88de50d3c8235e76852380f4`.
- Subtarefa de IA rodou, no worktree de auditoria:
  - `dart pub get` no server;
  - `dart analyze lib/ai/optimization_functional_roles.dart lib/edh_bracket_policy.dart ...` — PASS;
  - testes focados de optimization/validator/runtime support — PASS (45 + 12 testes reportados pela subtarefa).
- Baselines Linux no worktree de auditoria:
  - `dart test` com segredo local descartavel de teste — PASS, 601 testes.
  - Primeira tentativa `flutter analyze --no-pub --no-fatal-infos` falhou por dependencias ausentes no worktree descartavel; apos `flutter pub get`, `flutter analyze --no-pub --no-fatal-infos` — PASS, No issues found. `app/pubspec.lock` do worktree descartavel foi revertido e nao foi versionado.

## Limites

- Hermes nao validou iPhone Simulator, Android emulator, camera, scanner, push ou
  prova visual real.
- A auditoria nao editou produto, testes de produto, rotas, app ou `master`.
