# Hermes Analysis: Project Memory

> Status atual: memoria historica do agente.
> Quando houver conflito, `README.md` e
> `HERMES_E2E_SYSTEM_CONTRACT_2026-06-07.md` prevalecem.

> Memoria operacional do agente residente para o projeto ManaLoom.
> Versionada neste diretorio — atualizar sempre que houver mudanca estrutural.

## Identidade

- Nome: **ManaLoom** (tambem referido como mtgia)
- Repositorio: `softwarePredador/mtgia` (GitHub)
- Produto: Plataforma Commander-first para Magic: The Gathering
- Stack: Flutter (`app/`) + Dart Frog (`server/`) + PostgreSQL
- Backend publicado: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Master HEAD observado localmente: b11456cf (2026-06-11, Record Hermes target sync validation)
- Relatorio mestre atual: `docs/PROJECT_LOGIC_FULL_REPORT_2026-06-11.md`
- Backend tests: 599 (2026-06-04 14:10Z), `dart analyze lib/` — No issues found, `flutter analyze --no-pub --no-fatal-infos` — No issues found

## Branch de analise

A memoria versionada do agente vive em `codex/hermes-analysis-docs`.
Nunca commitar diretamente na `master`. Fluxo:

1. `git fetch --all --prune`
2. `git checkout codex/hermes-analysis-docs`
3. `git pull --ff-only origin codex/hermes-analysis-docs`
4. Editar `docs/hermes-analysis/*`
5. Stage apenas arquivos intencionais em `docs/hermes-analysis/**` (evitar artefatos de crons como `knowledge.db`, decks gerados e `__pycache__`) e commitar com `Update Hermes project analysis docs`
6. `git push origin codex/hermes-analysis-docs`

## Fontes canonicas (ordem de precedencia)

1. `docs/CONTEXTO_PRODUTO_ATUAL.md` - fonte de verdade operacional
2. `docs/PROJECT_LOGIC_FULL_REPORT_2026-06-11.md` - mapa mestre de logica, dados, IA, Hermes e validacao
3. `server/manual-de-instrucao.md` - diario tecnico com ultimas decisoes
4. `docs/README.md` - indice documental
5. `server/doc/API_CONTRACTS_AND_DATA_MAP.md` - contratos app/backend
6. `app/doc/APP_AUDIT_2026-04-29.md` - status consolidado do app
7. `app/doc/UI_TEST_SURFACE_MAP.md` - keys de teste para runtime
8. `docs/hermes-analysis/*` - analise do agente (este diretorio)
9. `git log --oneline --decorate -40` - estado atual dos commits

## Regra de escopo

- `CONTEXTO_PRODUTO_ATUAL.md` prevalece sobre roadmaps antigos e handoffs congelados antes de 2026-03-23.
- Nenhuma melhoria visual ou operacional fora do core de decks deve furar a fila da Sprint 1/2.
- Toda tela do fluxo core precisa preservar: `formato`, `deckId`, feedback de erro e estado de carregamento.
- Toda melhoria de UX precisa de validacao tecnica repetivel.

## Estado do agente neste servidor

Hermes consegue ler, auditar e analisar o repositorio. O container Hermes usado para
esta memoria possui **Dart 3.12.0** e **Flutter 3.44.0** instalados em `/opt/data/tools/flutter/bin/`.

- `dart test`: 599 passed (backend, 2026-05-27)
- `flutter analyze --no-pub --no-fatal-infos`: No issues found (2026-05-27)

## Politica de resposta

Ao responder sobre o ManaLoom:
1. Consultar esta memoria
2. Checar `docs/CONTEXTO_PRODUTO_ATUAL.md` para prioridade/escopo
3. Checar commits recentes para estado atual
4. Separar fato observado de inferencia
5. Se envolver contrato app/backend, consultar `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
6. Se envolver UI runtime, consultar `app/doc/UI_TEST_SURFACE_MAP.md`

## Areas criticas

- `app/lib/features/decks/**` (core do produto)
- `server/routes/ai/**` (IA: generate, optimize, rebuild)
- `server/lib/ai/**` (logica de IA, ~30 arquivos)
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md` (contratos)
- `docs/PROJECT_LOGIC_FULL_REPORT_2026-06-11.md` (mapa mestre de arquitetura/logica)
- `docs/hermes-analysis/BATTLE_AI_DECK_LOGIC_DEEP_DIVE_2026-06-11.md` (mapa detalhado de battle, IA, Hermes e Lorehold)
- `docs/hermes-analysis/BATTLE_SEMANTIC_SYNC_IMPLEMENTATION_PLAN_2026-06-11.md` (plano de implementação para agregação multi-função e sync Hermes)
- `docs/hermes-analysis/BATTLE_SEMANTIC_SYNC_SLICE1_REPORT_2026-06-11.md` (evidência do Slice 1 de sync semântico local e bridge do optimizer para arrays)
- `docs/hermes-analysis/BATTLE_AI_PROJECT_DECISIONS_TO_VALIDATE_2026-06-11.md` (dúvidas/decisões para validação do owner)
- `docs/hermes-analysis/BATTLE_AI_OWNER_VALIDATION_QUESTIONS_2026-06-11.md` (handoff objetivo de perguntas/furos/logística antes das próximas fases)
- `docs/hermes-analysis/HERMES_FUNCTIONAL_TAG_CONSUMER_CLASSIFICATION_2026-06-11.md` (classificação dos consumidores Hermes de `functional_tag` e status de migração para arrays)
- `scripts/quality_gate.sh` (validacao automatizada)
- `CHECKLIST_GO_LIVE_FINAL.md` (gates de release)

## Conta QA para validacao

Credenciais, user IDs, tokens, emails reais e senhas de QA nao devem ficar
versionados neste diretorio. Usar cofre/local env/handoff privado quando uma
rodada de validacao precisar de conta real.

Informacoes operacionais permitidas neste arquivo:

- Plano QA: Free (120 requests IA/mes), se aplicavel
- Decks de smoke podem ser citados por nome sanitizado, sem user ID
- Obs: JWT pode expirar rapido; fazer login fresco antes de usar

## Rotina obrigatoria pos-push Codex -> Hermes

A partir de 2026-05-26, depois de todo push relevante feito no fluxo local/Codex, o Hermes deve ser chamado antes de continuar a proxima frente:

- Mudanca comum: `/opt/data/scripts/manaloom-post-push-audit.sh normal <sha>`
- Mudanca grande de app/backend/layout/runtime: `/opt/data/scripts/manaloom-post-push-audit.sh deep <sha>`
- Smoke rapido de infraestrutura: `/opt/data/scripts/manaloom-post-push-audit.sh smoke`
- Status/ultimo relatorio: `/opt/data/scripts/manaloom-hermes-status.sh`

A rotina esperada e:

1. Codex local implementa, valida e faz push.
2. Se houver backend publico, confirmar `/health.git_sha`.
3. Hermes audita a branch/commit e atualiza somente `docs/hermes-analysis/**` se houver achado real.
4. Codex local le o retorno do Hermes, valida os achados e corrige P0/P1 antes de seguir.
5. Hermes nao substitui prova viva local em iPhone Simulator, scanner/camera, push real ou validacao visual.

### Guardrails do script pos-push

Atualizado em 2026-05-26:

- `smoke` e deterministico, sem chamada LLM, para validar workspace/HEAD/status rapidamente.
- `normal` usa timeout padrao de 360s.
- `deep` usa timeout padrao de 1200s.
- O timeout pode ser sobrescrito com `HERMES_AUDIT_TIMEOUT_SECONDS=<segundos>`.
- Todo relatorio termina com `HERMES_AUDIT_STATUS: PASS|FINDINGS|BLOCKED|TIMEOUT|PASS_UNCLASSIFIED`.
- O ultimo relatorio fica apontado por `/opt/data/.hermes/data/manaloom/reports/post_push_latest.md`.
- Se o LLM travar, o script deve retornar `TIMEOUT` em vez de deixar processo pendurado.
- O script faz `git fetch --all --prune` antes de calcular `origin/master`, para o smoke nao reportar SHA antigo.
