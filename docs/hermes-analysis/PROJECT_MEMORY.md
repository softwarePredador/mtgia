# Hermes Analysis: Project Memory

> Memoria operacional do agente residente para o projeto ManaLoom.
> Versionada neste diretorio — atualizar sempre que houver mudanca estrutural.

## Identidade

- Nome: **ManaLoom** (tambem referido como mtgia)
- Repositorio: `softwarePredador/mtgia` (GitHub)
- Produto: Plataforma Commander-first para Magic: The Gathering
- Stack: Flutter (`app/`) + Dart Frog (`server/`) + PostgreSQL
- Backend publicado: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Estado em 2026-05-25: **PASS_WITH_RISKS** para release interno non-scanner

## Branch de analise

A memoria versionada do agente vive em `codex/hermes-analysis-docs`.
Nunca commitar diretamente na `master`. Fluxo:

1. `git fetch --all --prune`
2. `git checkout codex/hermes-analysis-docs`
3. `git pull --ff-only origin codex/hermes-analysis-docs`
4. Editar `docs/hermes-analysis/*`
5. `git add docs/hermes-analysis && git commit -m "Update Hermes project analysis docs"`
6. `git push origin codex/hermes-analysis-docs`

## Fontes canonicas (ordem de precedencia)

1. `docs/CONTEXTO_PRODUTO_ATUAL.md` — fonte de verdade operacional
2. `server/manual-de-instrucao.md` — diario tecnico com ultimas decisoes
3. `docs/README.md` — indice documental
4. `server/doc/API_CONTRACTS_AND_DATA_MAP.md` — contratos app/backend
5. `app/doc/APP_AUDIT_2026-04-29.md` — status consolidado do app
6. `app/doc/UI_TEST_SURFACE_MAP.md` — keys de teste para runtime
7. `docs/hermes-analysis/*` — analise do agente (este diretorio)
8. `git log --oneline --decorate -40` — estado atual dos commits

## Regra de escopo

- `CONTEXTO_PRODUTO_ATUAL.md` prevalece sobre roadmaps antigos e handoffs congelados antes de 2026-03-23.
- Nenhuma melhoria visual ou operacional fora do core de decks deve furar a fila da Sprint 1/2.
- Toda tela do fluxo core precisa preservar: `formato`, `deckId`, feedback de erro e estado de carregamento.
- Toda melhoria de UX precisa de validacao tecnica repetivel.

## Estado do agente neste servidor

Hermes consegue ler, auditar e analisar o repositorio. O container NAO possui Dart ou Flutter SDK — `dart test`, `flutter analyze` e `flutter test` nao podem ser executados aqui. Recomendacoes de codigo sem validacao local devem ser marcadas explicitamente.

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
- `scripts/quality_gate.sh` (validacao automatizada)
- `CHECKLIST_GO_LIVE_FINAL.md` (gates de release)

## Conta QA para validacao

- Email: `rafa@rafarafa.com`
- Senha: `12341234`
- Username: `dsadasdsa`
- User ID: `840e108c-b2fc-4d10-b13e-83f52184f3d4`
- Plano: Free (120 requests IA/mes)
- Decks: `teste` (0 cartas), `lorehold` (2 cartas)
- Obs: JWT expira rapido (~30s) — fazer login fresco antes de usar