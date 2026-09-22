# PLANO DE CORREÇÃO DOCUMENTAL — BrewTact — 2026-09-22

Base: `d15beb05b`. Fonte de verdade para cada correção: `FATOS.md` (mesma pasta). Nada aqui foi aplicado — o repositório é somente leitura nesta rodada.

## 0. Regras que governam a aplicação

1. **Ordem**: canônicos (§A) → contexto corrente (§B) → apoio (§C) → marcar histórico (§D) → remover (§E) → geradores (§F). Dentro de §A, `docs/project_logic_contracts.json` primeiro, porque registry, `CURRENT_SYSTEM.md` e OpenAPI derivam dele.
2. **Qualquer edição em documento canônico muda o `source_digest_sha256`** (`tools/project_logic/lib/project_logic_generator.dart:2527-2540`). Depois de cada lote: `./scripts/manaloom_project_logic.sh --write` e `--check`. Commitar os 4 gerados junto (`docs/generated/CURRENT_SYSTEM.md`, `TASK_REGISTRY.json`, `openapi.generated.json`, `project_logic_manifest.json`). A árvore já tem uma regeneração pendente (fix do marketplace) — commitar aquela primeiro ou junto, nunca deixar o `--check` falhar.
3. **Padrão de banner histórico** (o que o repositório já usa — `docs/MANALOOM_PRODUCT_COMPLETION_TRACKER.md:1-6`, `server/doc/MANALOOM_CRONS_E_PENDENCIAS.md:1-6`): linha 1 = `# Título`, linha 2 vazia, linha 3 em diante = blockquote começando por `> Lifecycle: \`HISTORICAL_EVIDENCE · SUPERSEDED · NO_MUTATION_AUTHORITY\`.` O gerador exige os dois marcadores `HISTORICAL_EVIDENCE` e `NO_MUTATION_AUTHORITY` nas **16 primeiras linhas** de qualquer arquivo registrado como override `historical_evidence` (`project_logic_generator.dart:1226-1262`); senão falha fechado.
4. **Marcar histórico = banner + override**. Só o banner deixa o registry dizendo `supporting_reference_non_authoritative` (é o que acontece hoje com 5 docs bannerizados). Cada MARCAR_HISTORICO abaixo inclui a entrada JSON a acrescentar em `documentation_lifecycle.document_overrides`.
5. **Prioridade só vem da decisão e do backlog** (`guards.current_priority_precedence`). Nenhuma correção abaixo muda prioridade; onde há decisão pendente do dono (próximo NOW, ratificação de DECK_QUALITY_MODEL, bump de `next`), o plano diz "aguarda decisão" e não escolhe.
6. Mudança de estado de task no backlog exige link para receipt/commit na própria linha (regra do backlog l.732). Onde não há receipt, o estado correto é `EVIDENCE_REQUIRED` (definido em l.170, nunca usado), não `PASS`.

Vereditos consolidados (66 documentos existentes auditados pelos sete grupos + 5 de apoio novos revisados de passagem; `CLAUDE.md` não existe; `docs/LAYOUT_TEST_MAP.md` foi auditado por dois grupos com vereditos opostos — resolvido em FATOS 10.9):

| Veredito | Qtde | Documentos |
| --- | ---: | --- |
| MANTER | 17 | `.github/AGENT_POLICY.md`, `.github/instructions/guia.instructions.md`, `.github/instructions/roadmap.instructions.md`, `ROADMAP.md`, `docs/execution/TASK_PACKET_TEMPLATE.md`, `docs/generated/TASK_REGISTRY.json`, `docs/generated/CURRENT_SYSTEM.md` (ajustes só no gerador, §F), `docs/MANALOOM_CARD_ART_SOURCE_CACHE_AND_RIGHTS_CONTRACT.md`, `docs/MANALOOM_EXTERNAL_ENGINE_DELTA_SCHEDULE.md`, `docs/adr/README.md`, `docs/adr/0001`, `0004-xmage-human-spike-go.md`, `0008`, `0009`, `0011`, `0012`, `0013` |
| CORRIGIR | 32 | §A: `project_logic_contracts.json`, `CURRENT_PRODUCT_DECISION.md`, `CONTEXTO_PRODUTO_ATUAL.md`, backlog, `docs/execution/README.md`, MAPA, E2E contract, UI_LIVE_EVIDENCE contract, DECK_QUALITY_MODEL, COLLECTION_INGESTION, DECKBUILDER_AI_CURRENT_FLOW, ADRs 0002/0003/0004-battle-live/0005/0006/0007/0010, `API_CONTRACTS_AND_DATA_MAP.md`, `UI_TEST_SURFACE_MAP.md` (18) · §B: `README.md`, `docs/README.md`, `AGENTS.md` (via contrato), `CURRENT_QUEUE.md` (4) · §C: ficha `BT-SCP-001.md`, `PROPOSED_TASKS_DECK_QUALITY`, `VISUAL_EXECUTION_BASE`, `.hermes.md`, `app/integration_test/README.md`, `docs/flows/{platform_release_ops,life_counter_post_game,_nao_coberto}.md`, `PONTO_DE_RETOMADA_COORDENACAO`, `docs/design/visual-audit-2026-09-21/README.md` (10) |
| MARCAR_HISTORICO | 19 | §D (D1–D18; D18 são 2 arquivos): `PROPOSED_QUEUE_REORDER`, fichas `BT-GOV-001`/`BT-DOC-001`/`BT-DOC-004`, 9 docs de março (`AUDITORIA_RUIDO`, `AUDITORIA_UX`, `MATRIZ_TESTES`, `PLANO_SPRINTS`, `SENTRY_SETUP`, `SPRINT_AUDITORIA`, `BENCHMARK_CLONE`, `TABLETOP`, `TASK_PERFEICAO`), `LAYOUT_TEST_MAP`, `EASYPANEL_RUNBOOK` (1 palavra), `PROJECT_LOGIC_FULL_REPORT` (2 linhas), `READINESS_RUNBOOK` (só override), `server/doc/COMMANDER_LEARNING_API_2026-06-03.md` e `server/doc/MANALOOM_CRONS_E_PENDENCIAS.md` (só override) |
| REMOVER | 2 | `docs/HERMES_SQLITE_EASYPANEL_BRIDGE_AUDIT_2026-06-06.md` (mover para `docs/archive/2026-06/`); `CLAUDE.md` (inexistente — retirar das listas) |

---

## A. Documentos canônicos (`canonical_documents` / `current_decision` / `current_task_index` / `current_contract`)

### A1. `docs/project_logic_contracts.json` — CORRIGIR (maior alavancagem)

Todos os 312 caminhos declarados existem; as correções são de conteúdo declarado.

| Chave | Hoje | Novo valor (colar) | Fato |
| --- | --- | --- | --- |
| `flows[deck_lifecycle].entrypoints` | `["/decks","/import","/decks/generate",…]` | `["/decks", "/decks/import", "/decks/{id}", "/decks/{id}/search", "/decks/{id}/scan", "POST /import/to-deck"]` | 9.7 |
| `flows[card_collection].entrypoints` | `"/cards"`, `"/sets"` | `["/collection", "/collection/sets", "/cards/{cardId}", "GET /cards", "GET /sets"]` | 9.7 |
| `flows[battle_replay].entrypoints` | inclui `/decks/{id}/battle-coach`, `/decks/{id}/battle-coach/{sessionId}` | remover as duas; acrescentar `"deprecated_redirects": ["/decks/{id}/battle-coach", "/decks/{id}/battle-coach/{sessionId}"]` | 3.4 |
| `flows[deck_ai].entrypoints` | inclui `/ai/commander-reference` | retirar (fica só em `implementation`) | 9.7 |
| `flows[deck_ai].implementation` | 18 arquivos | acrescentar `"server/routes/decks/[id]/index.dart"` (apply do Optimize passa por `PUT /decks/{id}`, `deck_replace_all`) | 2.9 |
| `flows[deck_ai].status` | `"experimental_guarded"` | `{"analyze_optimize": "experimental_p0_open", "generate_rebuild": "experimental_guarded"}` (ou dividir o fluxo) | 2.2 |
| `flows[release_operations].entrypoints` | `"quality gates"`, `"release scripts"`, `/health`, `/ready` | `["GET /", "GET /capabilities", "GET /health", "GET /health/live", "GET /health/ready", "GET /ready", "scripts/quality_gate.sh", "scripts/manaloom_local_ci.sh", "scripts/manaloom_build_beta_release.sh"]` | 2.5, 2.6 |
| `flows[release_operations].implementation` | sem o portão de capability | acrescentar `"server/routes/_middleware.dart"`, `"server/lib/release_capability_policy.dart"`, `"server/routes/capabilities/index.dart"`, `"app/lib/core/config/release_capabilities.dart"`, `"server/bin/manaloom_ops_daemon.py"` | 2.4 |
| `flows[release_operations].tests` | 5, nenhum do portão | acrescentar `"server/test/release_capability_policy_test.dart"`, `"app/test/core/config/release_capabilities_test.dart"`, `"app/test/core/config/release_capability_surface_contract_test.dart"`, `"server/test/manaloom_ops_daemon_test.py"` | 2.4 |
| `flows[release_operations].gates` | `[manaloom_release_ops_contract_test.sh, manaloom_e2e_suite.sh]` | `["scripts/quality_gate.sh full", "scripts/manaloom_release_ops_contract_test.sh", "scripts/manaloom_e2e_suite.sh"]` | 9.8 |
| `flows[release_operations].storage` | `["schema_migrations","sync_log"]` | `["schema_migrations"]`; `sync_log`, `sync_state`, `data_source_snapshots` vão para o fluxo novo `ops_scheduler` | 9.8 |
| `flows[social_trade].tests[0]` / `.gates` | `e2e_trade_tests.py`; `[manaloom_e2e_suite.sh]` | anotar `e2e_trade_tests.py` como `"live_only": true`; `"gates": ["scripts/quality_gate.sh full", "scripts/manaloom_e2e_suite.sh"]` | 9.8 |
| `flows` (conjunto) | 8 | acrescentar `home_onboarding_notifications` (`/home`, `/onboarding/core-flow`, `/notifications`, FCM), `commercial_plans` (`/plans`, `/upgrade`, `/checkout`, `POST /billing/webhook`, `scripts/manaloom_commercial_quality_gate.sh`), `public_web` (`web-public/`, 11 rotas, `GET /reports/{id}`, `scripts/manaloom_deploy_public_web.sh`), `ops_scheduler` (`server/bin/manaloom_ops_daemon.py`, 16 jobs, `scripts/manaloom_deploy_ops_image.sh`); separar `binder_collection_scanner` de `card_collection` | 9.6 |
| `public_api_paths` | 14, com `/sets`, `/billing/webhook`, `/auth/register`; sem `/capabilities` | acrescentar `"/capabilities"`; mover `/sets`, `/billing/webhook`, `/auth/register` para `"public_when_capability_on": {"/sets": "catalog_private", "/billing/webhook": "billing_checkout", "/auth/register": "account_registration"}` | 2.5 |
| `receipt_contracts[deck_ai_learning_gate_v2].consumers` | inclui `scripts/manaloom_local_ci.sh` | `["scripts/quality_gate.sh deck-ai-learning"]` | 9.8 |
| `traceability[3].canonical_source`, `[4]` | `docs/hermes-analysis/DATA_MODEL_FINAL_VALIDATION_2026-06-15.md` (não canônico) | trocar por `docs/hermes-analysis/DATA_FIELD_ALIAS_CONTRACT_2026-06-30.md` ou adicionar o arquivo a `canonical_documents` | — |
| `documentation_lifecycle.document_overrides` | 17 | **+1**: `{"path": "AGENTS.md", "state": "current_contract", "reason": "mandatory agent contract that routes to the current decision and task index; no priority authority"}`; **+15** `historical_evidence` (lista em §D); **+1** `{"path": "docs/MANALOOM_VISUAL_EXECUTION_BASE_2026-04-19.md", "state": "supporting_reference_non_authoritative", "reason": "visual baseline consumed by app_theme.dart and premium_visual_qa_surfaces.json; not a priority source"}` | 9.3, 9.10 |
| `canonical_documents[6]` (`docs/DECK_QUALITY_MODEL.md`) | canônico, mas o doc diz `NOT_RATIFIED` | **aguarda decisão do dono**: ratificar (então corrigir o doc, A9) ou remover a linha 16 do JSON | 9.2 |
| `flows[release_operations].id` | `release_operations` | manter; o doc de apoio é que cede (renomear `docs/flows/platform_release_ops.md` → `release_operations.md`, §C) | 9.5 |

### A2. `docs/status/CURRENT_PRODUCT_DECISION.md` — CORRIGIR (3 trechos)

| Linhas | Texto novo (colar) | Fato |
| --- | --- | --- |
| 23-25 | `- App Web: rota reservada \`/app\` na origem canônica. Enquanto a matriz server-authoritative estiver totalmente \`OFF\`, nenhuma superfície pública aponta para \`/app\`, nenhuma capability de produto responde, e \`/app\` serve apenas o plano de controle de conta (login, recuperação, verificação, perfil, exportação e exclusão) para contas pré-existentes; auto-cadastro continua \`OFF\`.` | 1.7, 3.3 |
| 93 | `- A rota é \`/decks/:id/play-vs-ai[/:sessionId]\` (\`app/lib/main.dart:677,692\`), compilada apenas com \`ENABLE_INTERACTIVE_BATTLE=true\` e guardada por \`battle_coach\`; \`/decks/:id/battle-coach[/:sessionId]\` sobrevive apenas como redirect de compatibilidade (\`main.dart:706,715\`).` | 3.4 |
| após 69 (tabela) | Duas linhas novas: `\| Rotas de IA legadas (\`/ai/ml-status\`, \`/ai/simulate-matchup\`, \`/ai/weakness-analysis\`, \`/ai/optimize/telemetry\`, recommendations/simulate de deck) \| Contenção legada, sem chamador no app \| \`OFF\` \| \`null\` \|` e `\| Substituição integral de deck (\`PUT /decks/:id\`, \`POST /decks/:id/cards/replace\`, \`POST /import/to-deck\`) \| Implementado e guardado \| \`OFF\` \| \`null\` \|`. Nota sob a tabela: `\`OFF_UNTIL_P0_RECEIPT\` e \`Disponível\` são rótulos desta decisão; no artefato executável (\`server/config/release_capabilities.json\`) o valor é sempre \`off\` ou \`on\`, e \`allowed\` tem de ser igual a \`release_capability == 'on'\`.` | 2.2, 2.3 |

### A3. `docs/CONTEXTO_PRODUTO_ATUAL.md` — CORRIGIR (cortar em 42 linhas)

- Manter linhas 1-42 (cabeçalho, "Decisão vigente — 2026-08-25", "Atualização de prioridade 2026-08-12"). Acrescentar, após a l.42: `> O corpo histórico (2026-03-23 a 2026-07-30) foi movido para \`docs/archive/2026-09/CONTEXTO_PRODUTO_ATUAL_HISTORICO_2026-03-23_a_2026-07-30.md\`.`
- Mover linhas 44-816 para esse arquivo com o cabeçalho (§0.3):
  ```
  # Contexto Produto Atual — corpo histórico (2026-03-23 a 2026-07-30)

  > Lifecycle: `HISTORICAL_EVIDENCE · SUPERSEDED · NO_PRIORITY_AUTHORITY · NO_MUTATION_AUTHORITY`.
  > Origem: corpo de `docs/CONTEXTO_PRODUTO_ATUAL.md` até o HEAD `d15beb05b` (2026-09-22).
  > Contagens de linhas, telas, testes e rotas refletem as datas de cada seção, não o checkout atual
  > (hoje: 39 telas, 46 GoRoute, 11 rotas web, 58 migrations, `optimize/index.dart` 3337 linhas,
  > `deck_details_screen.dart` 2697, `deck_provider.dart` 1650).
  > Caminhos que deixaram de existir: `CHECKLIST_GO_LIVE_FINAL.md` e `RELATORIO_VALIDACAO_2026-03-16.md`
  > (→ `archive_docs/root/`, 23cfc0611), `app/lib/features/home/life_counter_screen.dart` (removido em d08985bca).
  ```
- O prefixo `docs/archive/` já classifica como `historical_evidence`; não precisa de override.
- Fatos: 9.11, 3.6, 3.7, 3.10, 5.14, 8.8.

### A4. `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md` — CORRIGIR

| Linha | Texto novo (colar) | Fato |
| --- | --- | --- |
| após 6 | `Última revisão do índice: 2026-09-18 (commit f6f791098: +BT-PLAY-001/002/003; aceite de BT-SCP-001 ampliado; matriz "Battle interativo / Jogar contra IA").` | 9.17 |
| 392 | `\| \`BT-NAV-01\` \| P1 \| IMPLEMENTED_LOCAL_PENDING_FULL_GATE \| Corrigir "Abrir Fichário" para tab do Fichário, não Ofertas. \| — \| Deep link/reload/back e tracking corretos. Correção: b2d3fc04f (\`home_screen.dart:442\` → \`/collection?tab=0\`); falta receipt de deep link/reload/back. \|` | 3.12 |
| 546 | estado `TODO` → `EVIDENCE_REQUIRED`; anexar ao aceite: `Implementado em b2d3fc04f (política 29/29 OFF; \`server/routes/_middleware.dart:105-144\`; guards do app); receipt próprio pendente.` | 4.6 |
| 547 | idem: `EVIDENCE_REQUIRED`; `Implementado em b2d3fc04f/fd0397a5a (marketplace/trades OFF; copy limpa em BT-GOV-001); receipt de negação por rota (listagem/match/proposta) pendente.` | 4.6 |
| 222 (BT-SCP-001) | anexar: `Evidência parcial: receipts docs/qa/execution/2026-09-21/btscp001-gate-amplo.md e btuiev001-chromedriver-e-recaptura.md; commits d83e9b1e1, 07014b431, d26f23a16. Aceite ampliado em f6f791098 durante a execução.` | 4.10 |
| 223, 225, 417, 429, 435, 610, 611 (IMPLEMENTED ×7) e 279, 427, 428, 430-433, 436, 598 (IN_PROGRESS ×10) | para cada: `Evidência: <commit/arquivo:linha>` ou rebaixar para `EVIDENCE_REQUIRED`. Mínimo imediato: BT-OFFER-001 → `fd0397a5a` + receipt BT-GOV-001; BT-DOC-002 → `c6e2725af`; BT-AI-013 → `optimize_cache_support.dart:65`; BT-DB-004 → `server/bin/update_schema.dart` tombstone | 4.5 |
| Épico J (novas) | `\| BT-CI-001 \| P0 CORE \| IMPLEMENTED_LOCAL_PENDING_FULL_GATE \| Suíte de project logic roda dentro do bootstrap frio; bootstrap e validação usam a mesma lista de pacotes. \| — \| \`manaloom_project_logic.sh --test\` passa; divergência bootstrap↔validação falha por mutação. Commits d83e9b1e1, 07014b431; receipt formal pendente. \|` e `\| BT-UIEV-001 \| P0 CORE \| IN_PROGRESS_CONTAINED \| Restabelecer a prova de UI viva após mudança de fonte, com pin único de ChromeDriver. \| BT-SCP-001 \| \`manaloom_local_ci.sh quick\` passa sem --no-verify; os 23 manifests de docs/qa/ui-live/latest.json no digest corrente e latest.json reescrito. Evidência: b397f477b, 9a9ba66de, d08c18717; receipt docs/qa/execution/2026-09-21/btuiev001-chromedriver-e-recaptura.md (22/23 em 8bba809c). \|` | 4.8 |
| Épico D (nova) | `\| BT-UX-KIT-001 \| P0 CORE \| TODO \| Kit de primitivas visuais em app/lib (régua do contador: azulejos, miniaturas, numerais). \| BT-UIEV-001 \| Packet docs/design/execution/BT-UX-KIT-001-proposto.md; aceite conforme packet. \|` — **posição no horizonte aguarda ratificação do dono** | 4.12 |
| Épicos J/K/E (novas, decisões do dono de 2026-09-21) | linhas para: bump `next` 15.5.25 / `sharp` 0.35.4; gate rodar `app/integration_test/` (147 arquivos); retenção de jobs de IA; documentar o 3º portão (`manaloom_ops_daemon.py`) | 4.16 |
| após tabela de ondas (§6, l.189-211) | `Situação em 2026-09-22: Onda 0 aberta (3/7 PASS: BT-GOV-001, BT-DOC-001, BT-DOC-004; BT-SCP-001 NOW desde 2026-08-24; BT-OFFER-001/BT-GATE-001/BT-GATE-002 sem receipt). Onda 1: nenhum ID iniciado. Fora das ondas: Jogar contra IA (f6f791098, sem mover BT-PLAY-*), BT-CI-001 e BT-UIEV-001 (infra de gate).` | 4.13 |
| 730 (regras) | `- alterar o aceite de um ID em NOW exige nota datada na própria linha e na ficha (ocorreu em f6f791098 para BT-SCP-001).` | 4.10 |
| 757 | `- docs/MANALOOM_PRODUCT_COMPLETION_TRACKER.md — histórico (S0–S10); não prevalece sobre este backlog.` | 9.1 |
| §10 (739-759) | acrescentar `- docs/MAPA_OPERACIONAL_DO_PROJETO.md`, `- docs/DECK_QUALITY_MODEL.md`, `- docs/adr/0013-play-vs-ai-is-the-only-interactive-battle-product.md`, `- docs/flows/README.md — apoio não autoritativo (verificação estática de 2026-09-21)` | 9.2 |

Depois: `./scripts/manaloom_project_logic.sh --write` (o registry muda: 220 → 223+ tasks).

### A5. `docs/execution/README.md` — CORRIGIR (3 trechos)

| Linha | Texto novo | Fato |
| --- | --- | --- |
| 29-45 (árvore) | acrescentar `├── PROPOSED_*.md   (propostas datadas, NOT_MERGED, sem autoridade; arquivar quando decididas)` | — |
| 49 | `…assim, não surgem 220 cópias que envelhecem fora do backlog.` | 4.1 |
| 199 | `MANALOOM_NODE_BIN=/opt/homebrew/opt/node@22/bin/node ./scripts/manaloom_local_ci.sh full` | 5.9 |

### A6. `docs/MAPA_OPERACIONAL_DO_PROJETO.md` — CORRIGIR (17 trechos; manter canônico)

| Linha | Texto novo (colar) | Fato |
| --- | --- | --- |
| 1 | `# BrewTact — mapa operacional do projeto — 2026-09-18, atualizado em 2026-09-21 e 2026-09-22` | — |
| 3 | `Status: \`MAP · STATIC_ANALYSIS · NO_PRIORITY_AUTHORITY · NO_MUTATION_AUTHORITY · CANONICAL_CURRENT_CONTRACT (desde 8e6a7e0ed)\`` | 9.2 |
| 9-11 | `As seções 1-6, 8 (C1-C15), 9 e 10 foram medidas por análise estática em 2026-09-18 sobre \`0677762d7\`; a seção 7 e C16-C17 em 2026-09-21 sobre \`b397f477b\`; a seção 4.3 foi remedida em 2026-09-22 sobre \`d15beb05b\`. Ele **não observa runtime nem produção**.` | — |
| 60 + novo item após 70 | `### Os três portões, todos fail-closed` e item **Scheduler**: `\`server/bin/manaloom_ops_daemon.py:145-205\` carrega o mesmo \`server/config/release_capabilities.json\` (envelope inválido ⇒ política vazia) e \`_jobs_for_release_policy\` (\`:736-745\`) só agenda um job se todas as capabilities de \`JOB_REQUIRED_CAPABILITIES\` (\`:711-734\`, 16 jobs) estiverem \`allowed\`. Com 29/29 \`off\` roda 1 de 16 (\`hermes_cron_governor_report\`) e o daemon sobe em \`safe_housekeeping_only\` com \`/health\` próprio na porta \`MANALOOM_NATIVE_BATTLE_PORT\` (\`:396-465\`); o deploy reasserta isso (\`scripts/manaloom_deploy_ops_image.sh:366,369\`).` | 2.4 |
| 93 | `\| card_collection \| sim \| não \| \`catalog_private\` (catálogo, edições, \`/market/*\`) + \`collection_private\` (fichário/import) · \`scanner\` no scan · \`trades\` em \`/collection/matches\` \|` | 2.9 |
| 94 | `\| deck_lifecycle \| sim \| não \| \`decks_private\` (base) + \`deck_replace_all\` (PUT /decks/:id, replace, import/to-deck) + \`catalog_private\` (busca) + \`scanner\` (scan) + \`gallery_public\` (/decks/:id/reports) \|` | 2.9 |
| 99 | desdobrar: `\| battle — Battle Lab / replays \| sim, compilado \| não \| \`battle_batch\` \|` e `\| battle — Jogar contra IA \| **não compilado no artefato** (\`ENABLE_INTERACTIVE_BATTLE\` default \`false\`) \| não \| \`battle_coach\` + trava de compilação \|` | 3.4 |
| 100 | `\| life_counter \| client-only (bundle web + 14 folhas nativas) \| não — rota \`/life-counter\` existe (\`main.dart:491-501\`) e o guard a devolve a \`/home\` \| \`life_counter_local\` \|` | 2.11, 3.7 |
| 149, 153 | retirar contadores de dias: `\| Atualizado em \| 2026-07-28 (\`c05774e0f\`) \| 2026-07-14 (\`0c9a4075c\`) \|`; `\`XMAGE_PATCH_COMMIT = 991948742…\`, 2026-08-03 (\`a6ee09c8f\`)` | 7.1 |
| 176 | `### 4.3 Detecção de drift — funciona quando a árvore está limpa` | 7.4 |
| 178-180 | `Cadência declarada (\`docs/MANALOOM_EXTERNAL_ENGINE_DELTA_SCHEDULE.md:43-48\`): domingo, 09:17, por automação cron local do Codex ("ManaLoom • Deltas XMage/Forge"), porque o checkout está sob \`~/Documents\` e o instalador de LaunchAgent recusa pastas protegidas por TCC (\`scripts/manaloom_install_external_engine_delta_schedule.sh:58-64\`). O LaunchAgent não está instalado e não é o caminho para este checkout.` | 7.5 |
| 182-197 | tabela: `2026-07-28, 2026-08-25, 2026-09-20 → consultou upstream (review_required)`; `08-02, 08-10, 08-17, 08-24, 08-31, 09-13 → skipped · dirty_worktree`; `latest.json = 2026-09-20, review_required`. Texto: `**Seis das nove auditorias foram puladas por árvore suja.** A de 2026-09-20 mediu: XMage master **775 commits** à frente do pin, Forge **780**; 211 cartas e 212 fixtures candidatos; \`pin_contract_failures: 0\`. O projeto sabe o delta desde 2026-09-20; o que não existe é a revisão nominal das 211 cartas nem decisão de avançar pin. A árvore voltou a ficar suja em 2026-09-21; a auditoria de 2026-09-27 será pulada se não for limpa antes.` | 7.4 |
| 203-209 | cabeçalho: `\| Fonte \| Consome \| Última checagem (backup PG 2026-08-03; Game Changers via git) \| Checagem automática \|` — retirar a coluna "Dias" | 5.18 |
| 240 | `\| \`hermes-lab\` \| \`server/Dockerfile.hermes-lab\` \| nenhum \| **desconhecido** — último commit no Dockerfile 2026-06-18 (\`637f22193\`); estado do container só com o comando da §9 \|` | 8.4 |
| 279 | `\| **\`ui_live_evidence\`** \| quick **e full** \| **falha** — 22 de 23 manifests exigidos estão no digest atual \`8bba809c\`; falta \`play-vs-ai-web-real\` e o \`source_digest\` de \`docs/qa/ui-live/latest.json\` (ambos em \`865e6041\`); 0 casam digest+hash até latest.json ser reescrito \|` | 6.3 |
| 304 | `Com aquele contrato corrigido, o \`full\` passou a chegar ao **segundo de seis** estágios do \`melos run quality\` (\`quality_gate.sh full\`, arm \`run_public_web_full\`) e revelou o bloqueio seguinte:` | 5.4 |
| 332-334 | `A trava de versão do ChromeDriver foi resolvida em \`b397f477b\`: pin único (\`scripts/lib/manaloom_chromedriver.sh:14\`, 153.0.8010.52) com bootstrap que baixa e confere SHA-256; o pin entra no digest de UI (\`manaloom_ui_source_digest.sh:75\`). O que trava a recaptura hoje é o E2E de Jogar contra IA (\`manaloom_play_vs_ai_e2e.sh\` invoca \`manaloom_server_contract_e2e_isolated.sh\` duas vezes e a segunda para em \`BLOCKED: build output has a consumer\`), registrado em \`docs/PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md:23-28\`.` | 6.5, 6.6 |
| 336-337 | `\`git log --grep=no-verify -i\` devolve **16 commits** (medido em 2026-09-22): 9 em 2026-09-18 e 7 em 2026-09-21; são 19 commits desde \`354983a1e\` (último que passou pelo hook) e 3 não declaram o bypass na mensagem. O número cresce enquanto \`ui_live_evidence\` não fechar.` | 5.7 |
| 365 (C7) | `\| C7 \| O agendamento semanal existe e roda (9 relatórios, último 2026-09-20 com upstream consultado), mas 6 de 9 execuções foram puladas por árvore suja; a árvore voltou a ficar suja em 2026-09-21 \| \`~/Library/Application Support/ManaLoom/external-engine-delta/\` vs \`git status\` \|` | 7.4 |
| 386 | `e quando 23 de 27 continuam passando a deriva não grita.` | — |
| 451 | `Sob \`docs/hermes-analysis/\`, oito arquivos são contratos canônicos (\`canonical_documents\`); \`archive/\`, \`deduplicated-report-content/\` e \`master_optimizer_reports/\` são \`historical_evidence\`; o resto é referência de apoio sem autoridade.` | 8.4, 9.2 |
| 457-460 | `Análise estática em três camadas: 2026-09-18 sobre \`0677762d7\` (seções 1-6, 8, 9, 10), 2026-09-21 sobre \`b397f477b\` (seção 7, C16, C17) e 2026-09-22 sobre \`d15beb05b\` (seção 4.3, seção 7 revalidada). Números de banco vêm do backup local de 2026-08-03.` e `Este documento está em \`canonical_documents\` desde \`8e6a7e0ed\` (2026-09-18), com estado \`current_contract\`: é referência, não autoridade de prioridade.` | 9.2 |

### A7. `docs/MANALOOM_E2E_RELEASE_CONTRACT.md` — CORRIGIR (2 trechos)

| Linha | Texto novo | Fato |
| --- | --- | --- |
| após 41 | `O runner grava em \`summary.json\` \`requested_profile\` ∈ {\`deterministic-read-only\`, \`isolated-mutating\`, \`live-smoke\`, \`live-smoke+isolated-mutating\`} e \`execution_policy\` ∈ {\`strict-gate\`, \`diagnostic-allow-partial\`}. As linhas \`isolated-play-vs-ai\` e \`release-target\` são etapas desta página, executadas por \`scripts/manaloom_play_vs_ai_e2e.sh\` e pelo checklist de release, e não aparecem como perfil no summary.` | 5.10 |
| 81-82 | `…a partir do SHA de \`XMAGE_COMMIT\`; \`scripts/manaloom_local_ci.sh release\` e \`scripts/manaloom_battle_product_gate.sh\` executam esse bootstrap antes do gate. Não há CI remoto.` | 5.1 |

### A8. `docs/MANALOOM_UI_LIVE_EVIDENCE_CONTRACT.md` — CORRIGIR (3 omissões)

| Onde | Texto novo | Fato |
| --- | --- | --- |
| "Fluxo canônico", antes dos `*_visual_qa.sh` | `Toda captura Web resolve o ChromeDriver por \`scripts/lib/manaloom_chromedriver.sh\`: \`MANALOOM_CHROMEDRIVER_BIN\` (override explícito, precisa ser executável) → pin \`153.0.8010.52\` em \`~/Library/Caches/manaloom/chromedriver/\` → \`BLOCKED\` apontando para \`scripts/manaloom_chromedriver_bootstrap.sh\`. O PATH nunca é consultado. O major do driver precisa ser igual ao do Chrome instalado; divergência falha fechada.` | 6.6 |
| lista "Arquivos executáveis" (283-312) | acrescentar: ChromeDriver pinado/bootstrap; `binder_import_visual_runtime_proof_test.dart` + `manaloom_binder_import_visual_qa.sh`; `deck_workshop_visual_runtime_proof_test.dart` + `manaloom_deck_workshop_visual_qa.sh`; `app_existing_user_visual_audit_test.dart` + `manaloom_p0_runtime_capture.sh` + `--index-p0-matrix` (manifests em `docs/qa/ui-live/current/p0-matrix/`); `core_product_acceptance_runtime_test.dart` + `--capture-core-product`; `app/test_driver/runtime_screenshot_crop.dart` | 6.7 |
| 226-231 | acrescentar: `Os perfis P0 são \`web_mobile_390x844\`, \`web_desktop_1440x900\`, \`web_wide_1920x1080\` e \`android_emulator_manaloom_api34\` (54/53/53/54 checkpoints); Binder Import usa \`web_binder_import_*\` (7 × 3) e Deck Workshop \`web_deck_workshop_*\` (12 × 3).` | 6.8 |

### A9. `docs/DECK_QUALITY_MODEL.md` — CORRIGIR (aguarda ratificação)

| Linha | Texto novo | Fato |
| --- | --- | --- |
| 3 | se ratificado: trocar `NOT_RATIFIED` por `CANONICAL_CURRENT_CONTRACT_2026-09-18`; se não, remover a linha 16 do JSON e manter | 9.2 |
| 355-357 | `Este documento está em \`canonical_documents\` de \`docs/project_logic_contracts.json\` desde \`8e6a7e0ed\` (2026-09-18) e herda o estado \`current_contract\`. Ele descreve mecanismo; não define prioridade nem autoriza mutação.` | 9.2 |
| 12-14 | `…têm zero ocorrências em \`docs/generated/CURRENT_SYSTEM.md\`, \`docs/generated/openapi.generated.json\` e \`docs/project_logic_contracts.json\`; \`docs/generated/DATABASE_ERD.md\` lista a tabela e a coluna como schema, sem explicar o que decidem.` | — |
| 119 | `\`commander_reference_profile_support.dart:6,10\` (nomes) e \`:47,53\` (candidatos)` | — |
| 121 | trocar `:224` por `:372-395` | — |

### A10. `docs/MANALOOM_COLLECTION_INGESTION_CONTRACT.md` — CORRIGIR (2 trechos)

| Linha | Texto novo | Fato |
| --- | --- | --- |
| 17 | acrescentar: `A rota e os endpoints \`/binder/import/*\` ficam sob a capability \`collection_private\`; com ela \`off\` (política \`brewtact_free_beta_2026-08-13\`) o app redireciona para \`/home\` e o servidor responde 404 \`capability_unavailable\`.` | 2.9 |
| 113-114 | `Quando o artefato foi compilado com \`ENABLE_SCANNER_RELEASE=true\` **e** a capability \`scanner\` de \`server/config/release_capabilities.json\` está \`allowed\`, o workspace pode abrir \`CardScannerScreen\` em \`continuousBinderSession\`. O flag de build nunca é autorização por si só (\`app/lib/core/config/launch_features.dart:4-11\`). Hoje a capability está \`off\`.` | 2.10 |

### A11. `docs/BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md` — CORRIGIR (6 trechos)

| Linha | Texto novo | Fato |
| --- | --- | --- |
| 5 | `SECOND_AUDIT_MAPPED · CONTAINMENT_PARTIAL · IMPLEMENTATION_PACKAGE_STARTED_GOVERNANCE_ONLY` + `Estado por task: ver docs/generated/TASK_REGISTRY.json (3 PASS, 10 IN_PROGRESS_CONTAINED, 7 IMPLEMENTED_LOCAL_PENDING_FULL_GATE em 2026-09-22).` | 4.2 |
| 298-299 | `A rota \`/ai/commander-learning\` responde 404 \`capability_unavailable\` enquanto \`learning_reads\` estiver \`off\`; com a capability ligada e as duas variáveis ausentes ela responde \`503\` antes de tocar o banco.` | 2.8 |
| 352-368 | coluna nova "Capability (hoje `off`)": `/ai/archetypes`, `/ai/explain`, `/decks/{id}/(ai-)analysis` → `ai_analyze_optimize_advisory`; `/ai/ml-status`, `/ai/simulate-matchup`, `/ai/weakness-analysis`, `/ai/optimize/telemetry`, `/decks/{id}/(recommendations\|simulate)` → `legacy_ai_routes`; trocar "entra no registry/capability de BT-AI-029" por "já classificada; BT-AI-029 decide adapter/410/remover" | 2.8 |
| 374-384 | renomear coluna para "Implementado" e acrescentar "Alcançável hoje (capability)": criar/importar/editar → `não · decks_private`; Analyze/Analyze IA/Optimize/Complete → `não · ai_analyze_optimize_advisory`; Generate/Rebuild → `não · ai_generate_rebuild`; Learning → `não · learning_*`; Battle → `não · battle_batch` **e** não compilado | 2.1, 2.8 |
| 434-436 | `\`optimize_feedback_support.dart\`: removido da árvore em \`b2d3fc04f\`; …` | — |
| 498-499, 579 | `1. verdade/capabilities/DAG/gates: ~~BT-GOV-001~~ (PASS), BT-SCP-001 (NOW), ~~BT-DOC-004~~ (PASS), BT-GATE-001, BT-GATE-002;` e `BT-DOC-004 (PASS) provou IDs/dependências/lifecycle;` | 4.2 |

### A12. ADRs canônicos — CORRIGIR (7 arquivos)

| ADR | Linha | Texto novo (colar) | Fato |
| --- | --- | --- | --- |
| `0002-battle-lab-execution-boundaries.md` | após 6 | `> Emenda 2026-08-25 (ADR 0013): o "Live Spectator" deixou de ser superfície de usuário. O stream público sanitizado, os checkpoints e o replay permanecem como transporte, recuperação, observabilidade e evidência internos; nenhuma rota, CTA ou modo de espectador existe no app. O produto interativo chama-se Jogar contra IA; "Coach Mode" sobrevive apenas como identificador técnico (capability \`battle_coach\`, \`BattleCoachScreen\`). Os limites técnicos desta decisão continuam válidos.` | 1.9, 3.5 |
| idem | 115 | `- docs/MANALOOM_BATTLE_LAB_DELIVERY_PLAN.md (evidência histórica do programa BL0–BL10; não define prioridade nem autoriza mutação)` | — |
| `0003-xmage-human-spike-no-go.md` | 3-4 | `- Estado: substituído em 2026-07-27 pela decisão GO registrada originalmente como 0004-xmage-human-spike-go.md e renumerada como ADR 0012 em 2026-08-12; o arquivo com o número antigo permanece somente como evidência histórica` | — |
| idem | 75 | `... e reflete o GO do ADR 0012; não deve ser usado para reescrever retroativamente este registro histórico.` | — |
| `0004-battle-live-polling-and-durable-checkpoints.md` | após 6 | `> Emenda 2026-08-25 (ADR 0013): a superfície de espectador (tela Flutter \`BattleLiveSpectatorScreen\`, rota \`battle-live/:jobId\`, CTA) deixou de existir como produto e o roteador é proibido de construí-la por teste de contrato. As decisões 1–6 e 8–11 continuam válidas como infraestrutura interna, recuperação e evidência. O item 7 descreve a tela histórica. Coach Mode recebeu GO de engenharia no ADR 0012 e virou Jogar contra IA no ADR 0013.` | 1.9, 3.5 |
| `0005-interactive-battle-coach-alpha.md` | após 11 | `> Emenda 2026-08-25: o ADR 0013 substitui este ADR quanto ao nome ("Jogar contra IA"), à rota canônica (/decks/:id/play-vs-ai[/sessionId]) e à experiência (mesa card-first, sem espectador público). Os limites de privacidade, persistência, autenticação e resposta tipada abaixo continuam válidos. Onde este texto diz "ADR 0004", leia ADR 0012.` | 3.4 |
| idem | 15, 41 | `ADR 0004` → `ADR 0012` (duas ocorrências) | — |
| idem | 49-51 | `9. O app retoma pela URL /decks/:id/play-vs-ai/:sessionId (ADR 0013); /decks/:id/battle-coach/:sessionId existe apenas como redirect de compatibilidade. shared_preferences não é fonte de sessão, prompt, ação ou replay.` | 3.4 |
| `0006-commander-optimizer-bracket-and-apply-safety.md` | 62 | `9. The persistent optimize cache contract is at v20 (v19 in this decision; bumped to v20 on 2026-08-13 by the free-beta all-off baseline), invalidating previews produced before …` | 5.16 |
| `0007-commander-reference-generation-timeout.md` | 39-40 | `Reserve 6,000 output tokens by default for Commander generation (2,200/2,600 for other formats), with a Commander-only override OPENAI_MAX_TOKENS_GENERATE_COMMANDER; every generation format keeps the 800–8,000 operational clamp.` | 5.16 |
| idem | 43-44 | `… contract v8 (v6 in this decision; v7 on 2026-08-02 and v8 on 2026-08-13) and reference-prompt policy v9 (v8 in this decision; bumped the same day by 96208fa9e).` | 5.16 |
| `0010-brewtact-public-brand-transition.md` | após 50 | `   > Superseded pelo ADR 0011 em 2026-08-11: a origem pública canônica é https://brewtact.com. Permanece válida a proibição de fallback para manaloom.com.` | 1.6 |
| idem | 63-64 | `- O domínio definitivo é brewtact.com (ADR 0011). O remetente de e-mail BrewTact continua dependente de verificação externa; o código não presume que isso ocorreu.` | 1.6 |

### A13. `server/doc/API_CONTRACTS_AND_DATA_MAP.md` — CORRIGIR

| Linha | Texto novo | Fato |
| --- | --- | --- |
| seção "Auth and Current User" | inserir as 8 linhas prontas do relatório `mapas-tecnicos.md` §2 (`POST /auth/forgot-password`, `reset-password`, `verify-email`, `resend-verification`, `change-password`, `revoke-sessions`, `GET /capabilities`, `GET /`) | 2.5, 2.6 |
| 25 + coluna Status | normalizar aos 5 valores declarados; mover o eixo de release para coluna nova `Capability (server)` preenchida a partir de `requiredCapabilityForRequest` (`release_capability_policy.dart`) | 2.8, 2.9 |
| todas as linhas | coluna nova `Auth` ∈ {`bearer`, `anonymous`, `anonymous+optional-bearer`, `ops-key-or-admin`}; na l.127 (`GET /cards/printings`): `**Anônima.** \`sync=true\` executa até 30 \`INSERT … ON CONFLICT DO UPDATE\` em \`cards\` e \`INSERT … ON CONFLICT DO NOTHING\` em \`sets\` sem \`Authorization\` (\`server/routes/cards/printings/index.dart:309-484\`). Enquanto \`catalog_private=OFF\` responde 404 antes do handler.` | 2.7 |
| 222 | `The job has a total deadline of six minutes measured from \`created_at\` (\`OptimizeJobStore.executionTimeout\`); a nonterminal job past that deadline is failed explicitly.` | 5.15 |
| 225 | `The job has a total deadline of three minutes measured from \`created_at\` (\`AiGenerateJobStore.executionTimeout\`); a nonterminal job past that deadline is failed explicitly.` | 5.15 |
| 461 | `…release/deck/AI-job/collection/battle/trade schema checks through migration **058** (\`latest_migration_ready\`), …` | 5.14 |

### A14. `app/doc/UI_TEST_SURFACE_MAP.md` — CORRIGIR

| Linha | Texto novo | Fato |
| --- | --- | --- |
| 29 | `Inventário corrente (guard verde em 2026-09-22; fixture alterado por último em f6f791098)` | — |
| 55-57 | `38 rotas são \`active\`; 3 são \`deferred_by_scope\` (Scanner \`/decks/:id/scan\` e as duas rotas de Jogar contra IA \`/decks/:id/play-vs-ai[/:sessionId]\`, enquanto \`battle_coach\` estiver OFF); 5 são \`compatibility_redirect\` (\`/market\`, \`/marketplace\`, \`/quotes\` e os dois aliases \`battle-coach\`). Nenhuma das 8 conta como tela ativa própria.` | 3.2 |
| 224-228 | `declara 18 casos canônicos: mobile 320×568, 390×844 e 412×915 e seus landscapes 844×390 e 915×412; tablet 768×1024 e 1024×768; boundaries 599/600, 839/840, 1199/1200 e 1599/1600; desktop 1280×900, 1440×900 e 1920×1080.` | 6.9 |
| 333-338 | 4ª linha: `\| Android emulador \`ManaLoom_API34\` \| 411×914 \| 54 \|` + nota `Android físico (SM-A135M) não faz parte do gate de baseline; é item de release separado, hoje \`stale_not_claimed\` em \`docs/qa/ui-live/latest.json\`.` | 6.8 |
| 340 | `O gate compara 214 PNGs (54+53+53+54) em quatro perfis. Os diretórios \`android/\` e \`android_physical/\` (54 cada) são baselines históricos fora do gate; remover ou mover para \`docs/archive/\` exige decisão registrada.` | 6.8 |
| 363-367 | `A aprovação em \`docs/qa/ui-live/latest.json\` vale apenas para o \`source_digest\` que ela registra. Qualquer alteração nos caminhos listados em \`scripts/manaloom_ui_source_digest.sh\` muda o digest e invalida o PASS (fail-closed). Confira com \`./scripts/manaloom_ui_source_digest.sh\`; não copie o digest para este documento.` | 6.1 |
| 381 | `- \`onboarding-persistence-error\` e \`onboarding-persistence-retry\`;` | 6.10 |
| 425 | `\| Ações do deck \| \`DeckDetailsScreen\` \| \`deck-optimize-button\` (Visão Geral), \`deck-workshop-optimize-button\` (Oficina), \`deck-details-menu\`, \`deck-details-menu-import-list\` \| …` | 6.10 |
| 488-489 | `\| Aba catálogo \| \`CollectionScreen\` \| \`collection-tab-sets\` \| Abre o catálogo de coleções embutido. \| Tap por key. \|` (remover a linha de "última edição") | 6.10 |
| 495 | `Falha de \`/binder\` não deve aparecer como lista vazia. \| \`find.byKey\` + ação de retry do \`AppStatePanel\` (sem key própria; \`binder-pagination-retry-<have\|want>\` cobre só paginação).` | 6.10 |
| 510 | `\| \`find.byKey\` + ação de retry do \`AppStatePanel\` (sem key própria); vazio expõe \`marketplace-empty-action\`.` | 6.10 |

### A15. `docs/generated/CURRENT_SYSTEM.md`, `openapi.generated.json`, `TASK_REGISTRY.json` — MANTER (não editar à mão)

Regenerar após A1/A4. Correções vão no gerador (§F). Commitar a versão da árvore (digest `9d37547f…`, tests 1221) junto com o fix do marketplace.

---

## B. Contexto corrente (`current_context`) e roteadores

### B1. `README.md` — CORRIGIR (2 trechos)

| Linha | Texto novo | Fato |
| --- | --- | --- |
| 13 | manter o texto; a correção é no contrato (A1: override `current_contract` para `AGENTS.md`). Alternativa pior: `1. [AGENTS.md](AGENTS.md) — roteador obrigatório para agentes (referência de apoio no registry);` | 9.3 |
| tabela "Fontes de verdade" (26-34) | `\| Capabilities de release \| \`server/config/release_capabilities.json\` (server-authoritative, default-deny) e a matriz em \`docs/status/CURRENT_PRODUCT_DECISION.md\` \|` | 2.1 |

### B2. `docs/README.md` — CORRIGIR (índice)

- Seção 2: `- [Registry de tasks](generated/TASK_REGISTRY.json)`.
- Seção 3: `- [Mapa operacional](MAPA_OPERACIONAL_DO_PROJETO.md) — medições estáticas, sem autoridade de prioridade`; `- [Mapa de superfícies de teste de UI](../app/doc/UI_TEST_SURFACE_MAP.md)`.
- Seção 4: `- [Modelo de qualidade de deck](DECK_QUALITY_MODEL.md)`; `- [Ponte app↔IA](hermes-analysis/APP_AI_KNOWLEDGE_BRIDGE_CONTRACT_2026-07-06.md)`.
- Nova seção "6b. Apoio não canônico (2026-09-21)": `\`flows/\` — 11 fluxos com verificação adversarial estática; \`design/visual-audit-2026-09-21/\` — auditoria visual; \`PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md\` — ponto de retomada. Nenhum define prioridade.`
- Fato 9.2.

### B3. `AGENTS.md` — CORRIGIR (no contrato, não no texto)

Só a entrada de override em A1. Conteúdo técnico confirmado (hooks, gate de schema, três níveis de prova viva, 11/11 perfis herdam `AGENT_POLICY`).

### B4. `docs/execution/CURRENT_QUEUE.md` — CORRIGIR (reescrever "Estado operacional conhecido")

| Linha | Texto novo | Fato |
| --- | --- | --- |
| 5 | `- Atualizada em: 2026-09-22 (estado observado após d15beb05b)` | — |
| 10 | `- Divergência observada em 2026-09-22: ahead_by=0, behind_by=0, PUSHED (todos os commits até d15beb05b estão no origin)` | 4.4 |
| 12-15 | acrescentar `- Backlog/registry SHA-256 corrente (2026-09-22): 333b6c0ba8262783ee2f457e65b0dfbc4a86696cf76eeee18d0b6557bc6458d1 (220 tasks, 402 arestas; mudou em f6f791098)` e `- Project logic digest corrente em HEAD: 556ba631… (árvore: 9d37547f… com o fix do marketplace)` | 4.1 |
| 18-19 | `- Writers em 2026-09-21: quatro sessões paralelas (ver docs/PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md). Só a frente A serviu ao slot NOW; as demais produziram docs/design, docs/flows e a correção não commitada do marketplace, fora de qualquer ID. Exceção ao WIP-1 registrada aqui, não autorizada por este documento.` | 4.13 |
| 30-31 | manter a regra e acrescentar `Exceções ocorridas (não retroativamente autorizadas): a2d044618 (gate deck-quality, sem ID), f6f791098 (Jogar contra IA, BT-PLAY-* não movidos), BT-CI-001 (d83e9b1e1) e BT-UIEV-001 (b397f477b, 9a9ba66de, d08c18717) — os dois últimos ganharam linha no backlog em <commit da correção A4>.` | 4.13 |
| 35-47 (horizonte) | **aguarda ratificação do dono** entre BT-OFFER-001 (atual), BT-DB-001 (proposta) e BT-UX-KIT-001 (PONTO:183). Se a decisão do dono vale: `\| 1b \| BT-UIEV-001 \| fechar latest.json (23/23) \|` e `\| 2 \| BT-UX-KIT-001 \| kit de primitivas visuais (Épico D); exige BT-UIEV-001 fechado \|` | 4.12 |
| 70-80 | `- A consolidação planejada em 2026-09-09 landou em 2026-09-18 como f6f791098 (313 arquivos, --no-verify). Em 2026-09-21: 22/23 manifests de latest.json no digest 8bba809c (430/439 PNGs); falta play-vs-ai-web-real (corrida de handoff em manaloom_play_vs_ai_e2e.sh) e reescrever latest.json. Gate amplo: full termina EXIT=1 em npm audit (next 15.5.21 → 15.5.25; sharp) e nunca chega a ui-audit/custom-lint/patrol-smoke/dependency-audit. 16 dos 19 commits desde 2026-09-18 declaram --no-verify.` | 4.10, 5.7, 6.3 |
| 98-101 | `- BT-DOC-004 … implementação d9f7a59cd já está no upstream; nenhum deploy ocorreu.` | 4.4 |
| 112-120 | manter os passos; acrescentar `Estado em 2026-09-22: passos 5 (hashes) e 6 (arquivar fichas fechadas) pendentes desde f6f791098.` | — |

---

## C. Apoio (`supporting_reference_non_authoritative`) — CORRIGIR

### C1. `docs/execution/tasks/BT-SCP-001.md` (ficha NOW)

| Linha | Texto novo | Fato |
| --- | --- | --- |
| 12-14 | `- Registry generated_from.sha256 corrente: 333b6c0b… (o aceite desta task foi ampliado em f6f791098)` | 4.1 |
| 48 | `- Base atual: d15beb05b (2026-09-21). Consolidação herdada landou em f6f791098 (313 arquivos).` | 4.10 |
| 103-106 | `- Próximo marco: play-vs-ai-web-real recapturado e latest.json reescrito (hoje 22/23 manifests em 8bba809c; 0 casam digest+hash).` | 6.3 |
| 107-110 | `- Veredito corrente (2026-09-21): GATE_AMPLO_NAO_ALCANCADO — full EXIT=1 em npm audit; ui-audit (BT-UIEV-001), custom-lint, patrol-smoke e dependency_audit não exercitados. Provado: bootstrap frio + suíte project-logic + guard por mutação (d83e9b1e1, 07014b431, d26f23a16).` | 4.10 |
| 164-165 | `- O runner isolado (scripts/manaloom_play_vs_ai_e2e.sh) provou o fluxo em 2026-08-25 (receipt); a versão de 2026-09-18 tinha asserção impossível (corrigida em d08c18717) e ainda não voltou a passar no HEAD.` | 6.11 |
| 269-280 (gates) | `\| Full 2026-09-21 \| ./scripts/manaloom_local_ci.sh full \| PARCIAL \| EXIT=1 em npm audit (next critical, sharp high); zero falha de teste nos estágios que rodaram \| 1 \| b4473a98a→07014b431 \| docs/qa/execution/2026-09-21/btscp001-gate-amplo.md \|` | 4.10 |
| 282-288 (receipts) | três linhas `PARCIAL` para `2026-09-21/{btscp001-gate-amplo, btuiev001-chromedriver-e-recaptura, PONTO_DE_RETOMADA}.md` | 4.11 |
| 308-309 | `- Bloqueios (2026-09-21): (1) npm audit do web público — decisão do dono sobre next 15.5.25/sharp 0.35.4; (2) BT-UIEV-001 — latest.json com 23 manifests; (3) custom-lint, patrol-smoke, dependency_audit nunca exercitados; (4) clean-SHA com hooks (16 commits --no-verify); (5) auditoria independente e receipt final.` | 5.8 |
| 318 | aguarda ratificação (B4) | 4.12 |

### C2. `docs/execution/PROPOSED_TASKS_DECK_QUALITY_2026-09-18.md`

| Linha | Texto novo | Fato |
| --- | --- | --- |
| 6-12 | `Este documento não é autoridade. As linhas da Parte 2 aguardam decisão do dono para entrar no backlog mestre (a edição que bloqueava, f6f791098, já landou).` | — |
| 77 | linha BT-UIEV-001 conforme A4 (dependência `BT-SCP-001`, não `BT-PLAY-001`; alvo = 23 manifests de `latest.json`, não "35 packs") | 4.8, 6.3 |
| 86-87 | substituir "não precisa entrar no backlog" pela linha BT-CI-001 de A4 | 4.8 |
| 138-149 | `Resolvido em b397f477b: pin único 153.0.8010.52 em scripts/lib/manaloom_chromedriver.sh, bootstrap com SHA-256, contrato "every ChromeDriver consumer resolves through the shared pin". Ver receipt 2026-09-21/btuiev001-chromedriver-e-recaptura.md.` | 6.6 |
| 151-156 | `Estado em 2026-09-21: recapturado (22/23). Falta: (1) o estágio esperar a liberação de server/build; (2) recapturar play-vs-ai-web-real; (3) reescrever latest.json com 23 manifests.` | 6.5 |
| 185-186 | `1. BT-SCP-001 (NOW) só destrava commit/push sem bypass depois de BT-UIEV-001 fechar latest.json e do dono decidir o bump next 15.5.25 / sharp 0.35.4.` | 5.8 |

Depois que BT-META-001/002, BT-FRESH-001, BT-HERMES-RET-001 forem decididos (colar no backlog ou descartar), este arquivo vai para §D.

### C3. `docs/MANALOOM_VISUAL_EXECUTION_BASE_2026-04-19.md` (consumido por código — não marcar histórico)

| Linha | Texto novo | Fato |
| --- | --- | --- |
| 5 | `> Lifecycle: \`SUPPORTING_REFERENCE_NON_AUTHORITATIVE · CONSUMED_BY_CODE\`.` + `> Base visual citada por \`app/lib/core/theme/app_theme.dart:12\` e \`server/config/premium_visual_qa_surfaces.json:4\`. Não define prioridade. A direção corrente de qualidade visual (régua do contador, azulejos, numerais) está em \`docs/design/visual-audit-2026-09-21/README.md\` e no backlog; onde este documento e o tema divergirem, vale \`app_theme.dart\`.` | 6.14 |
| 99-102 | `- \`obsidian-950\`: \`#0B0D12\`` / `- \`obsidian-900\`: \`#151821\`` / `- \`slate-850\` (surfaceElevated): \`#1D222C\`` / `- \`slate-750\` (outlineMuted): \`#293041\`` | 6.14 |
| 386-411 | substituir "ManaLoom App Visual QA", "App Release Engineer", "Release Coordinator" por `### manaloom-ux-design-auditor` e `### mobile-runtime-device-qa` (perfis reais em `.github/agents/`); remover "Release Coordinator" | — |
| contrato | override em A1 (`supporting_reference_non_authoritative` explícito, com `reason`) | — |

### C4. `.hermes.md` (manter só regras de git; marcar Hermes como histórico)

| Linha | Texto novo | Fato |
| --- | --- | --- |
| 1 (novo) | `> Lifecycle: \`SUPPORTING_REFERENCE_NON_AUTHORITATIVE · GIT_HYGIENE_ONLY\`. As seções sobre Hermes são históricas.` | — |
| 37-39 | `1. Branch canônica: \`master\`. A branch de release candidate corrente é a indicada em \`docs/execution/CURRENT_QUEUE.md\`; \`codex/hermes-analysis-docs\` é memória Hermes histórica, não fonte de verdade.` | 8.6 |
| 48-53, 75-87 | substituir por `> Seção histórica (Hermes dormente; \`docs/MAPA_OPERACIONAL_DO_PROJETO.md:240\`). Não há cron nem chamada report-only ativa; \`battle_analyst_v8.py\` foi apagado (f53e32868); o executor de regras é o XMage pinado.` | 8.4, 8.8 |
| 57-62 | `1. Leia, nesta ordem: \`AGENTS.md\`, \`.github/AGENT_POLICY.md\`, \`docs/status/CURRENT_PRODUCT_DECISION.md\`, \`docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md\`, \`docs/execution/CURRENT_QUEUE.md\`, \`docs/generated/CURRENT_SYSTEM.md\`, o contrato da área e \`server/doc/API_CONTRACTS_AND_DATA_MAP.md\`. \`server/manual-de-instrucao.md\` é histórico e não deve ser usado nem atualizado.` | 9.15 |
| 68-70 | `4. Para mudança de contrato app-facing, atualize \`server/doc/API_CONTRACTS_AND_DATA_MAP.md\` e rode \`./scripts/manaloom_project_logic.sh --write && --check\`.` | 9.15 |
| após 103 | `Depois de alterar código, rota, migration, script, gate ou contrato: \`./scripts/manaloom_project_logic.sh --write\` e \`--check\`. O pre-commit roda \`./scripts/manaloom_local_ci.sh quick\`; nunca use \`--no-verify\`.` | 5.6 |

### C5. `app/integration_test/README.md` (1 linha)

| 93-94 | `…opt-in via \`MANALOOM_RUN_FLUTTER_RUNTIME_E2E\`, \`MANALOOM_RUN_SERVER_LIVE_E2E\`, \`MANALOOM_RUN_LIVE_PRODUCT_E2E\`, \`MANALOOM_RUN_MUTATING_RESOLUTION_E2E\` and \`MANALOOM_RUN_MUTATING_BATTLE_PRODUCT_E2E\` (read in \`scripts/manaloom_e2e_suite.sh:85-91\`); the guarded profile additionally requires the \`MANALOOM_CONFIRM_*\` phrases shown in \`test/README.md\`.` | 5.10 |

### C6. `docs/flows/` (untracked; apoio novo)

| Arquivo | Linha | Texto novo | Fato |
| --- | --- | --- | --- |
| `platform_release_ops.md` | nome | `git mv` (após commit) para `docs/flows/release_operations.md`; atualizar `README.md:10,59,89` | 9.5 |
| `platform_release_ops.md` | 21 | `**Os três portões são coerentes entre si.** …` + parágrafo sobre `server/bin/manaloom_ops_daemon.py:145-205,711-746` (16 jobs; 1 roda) | 2.4 |
| `life_counter_post_game.md` | 69, 89 | `16 folhas` → `14 folhas` (a lista já está certa: card_search, commander_damage, day_night, dice, game_modes, game_timer, history, player_appearance, player_counter, player_state, set_life, table_state, turn_tracker, settings); `_nao_coberto.md:157-159,607` já registra a errata | 3.7 |
| `_nao_coberto.md` | 148 | `**Capability:** \`life_counter_local\` — rota \`/life-counter\` negada em \`release_capabilities.dart:363-364\`; entrada da Home condicionada em \`home_screen.dart:114,123,160\`.` | 2.11 |

### C7. `docs/PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md` (untracked)

| Linha | Texto novo | Fato |
| --- | --- | --- |
| 129 | `Saída em docs/flows/_p0/: auth-conta.md (312 l.), catalogo-arte.md e medir-p0.js.` | — |
| 163 | `(política própria, 16 jobs, /health separado na porta MANALOOM_NATIVE_BATTLE_PORT)` | 2.4 |
| 183 | manter como decisão do dono, mas acrescentar `— não ratificada no backlog/fila até <commit>` | 4.12 |

### C8. `docs/design/visual-audit-2026-09-21/README.md` (untracked)

| Linha | Texto novo | Fato |
| --- | --- | --- |
| 145 (trecho final) | `Observação adicional: hoje nem esse gate está verde — latest.json está no digest 865e6041…, 22 dos 23 manifests que ele referencia foram recapturados em 8bba809c… (hash novo, ainda não registrado) e falta play-vs-ai-web-real.` (idem em `audit.json:4595`) | 6.1, 6.3 |

---

## D. MARCAR_HISTORICO (banner §0.3 + override em `document_overrides`)

Para cada arquivo: inserir o banner após o `# Título` (linha 3), adaptando "Fotografia de" e "Superado por"; nos três com `Status: ACTIVE`/`IN_PROGRESS` o banner **substitui** essas linhas. Depois acrescentar a entrada JSON e regenerar.

Banner modelo:
```
> Lifecycle: `HISTORICAL_EVIDENCE · SUPERSEDED · NO_MUTATION_AUTHORITY`.
> Fotografia de `<DATA>`. Não define prioridade, status nem aceite.
> Comandos, caminhos e números abaixo são exemplo histórico; vários já não
> existem ou mudaram (ver "Superado por").
> Superado por: `docs/status/CURRENT_PRODUCT_DECISION.md` (decisão),
> `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md` (tasks),
> `<DOC ATUAL DA ÁREA>`.
```

| # | Documento | Fotografia | "Superado por" | Linhas a substituir | Override JSON (`reason`) | Por que marcar e não remover |
| --- | --- | --- | --- | --- | --- | --- |
| D1 | `docs/execution/PROPOSED_QUEUE_REORDER_2026-09-18.md` | 2026-09-18 | `docs/execution/CURRENT_QUEUE.md`; nota `Procedência: alcance transitivo sem excluir DEFERRED_BY_SCOPE (com exclusão: 95/73/51/40/32); BT-PRIV-002 tem 1 dep aberta` | — | `"dated queue-reorder proposal, NOT_MERGED; fan-out table kept as evidence"` | tabela de fan-out continua útil; §4-6 defasadas; sugestão de fechar BT-PLAY-001/002 contradiz backlog l.485-489 |
| D2 | `docs/execution/tasks/BT-GOV-001.md` | 2026-08-14 | `docs/qa/execution/2026-08-14/BT-GOV-001.md` | — | `"closed packet; canonical PASS recorded in backlog"` | ledger fechado e correto; ou mover para `docs/execution/tasks/closed/` (o gerador só valida a ficha do NOW) |
| D3 | `docs/execution/tasks/BT-DOC-001.md` | 2026-08-24 | receipt 2026-08-24; trocar l.96 `NOT_PUSHED` → `PUSHED (c6e2725af no origin)` | 96 | idem | idem |
| D4 | `docs/execution/tasks/BT-DOC-004.md` | 2026-08-24 | receipt 2026-08-24 | — | idem | idem |
| D5 | `docs/AUDITORIA_RUIDO_VISUAL_CORES_2026-03-25.md` | 2026-03-25 | `docs/MANALOOM_VISUAL_EXECUTION_BASE_2026-04-19.md`, `app/lib/core/theme/app_theme.dart`, `docs/design/visual-audit-2026-09-21/README.md` | — | `"March 2026 colour audit; rule adopted (no Color(0x) outside theme), targets since deleted"` | citado por `CONTEXTO:810`; a regra que propôs vigora |
| D6 | `docs/AUDITORIA_UX_LOGICA_PERFORMANCE_2026-03-23.md` | 2026-03-23 | `docs/BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md`, `docs/DECK_QUALITY_MODEL.md`, `docs/flows/deck_ai.md` | — | `"March 2026 UX/perf audit; counts superseded"` | citado por `CONTEXTO:254` |
| D7 | `docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md` | 2026-03-23 | `docs/flows/deck_ai.md`, `docs/DECK_QUALITY_MODEL.md`, `scripts/quality_gate_resolution_corpus.sh` | — | `"March 2026 test matrix (206 tests then; 270 now)"` | citado por `CONTEXTO:255`, `ROADMAP.md:83` |
| D8 | `docs/PLANO_SPRINTS_EXECUCAO_MTGIA_2026-03-23.md` | 2026-03-23 | backlog 2026-08-12 e `docs/execution/CURRENT_QUEUE.md` | 3 ("Ordem oficial…") | `"March 2026 sprint plan; must not be read as execution order"` | maior risco de ser lido como fila; citado por `CONTEXTO:561` |
| D9 | `docs/SENTRY_SETUP_MTGIA_2026-03-24.md` | 2026-03-24 | `docs/flows/release_operations.md` §observabilidade, `server/test/observability_test.dart` | — | `"March 2026 Sentry setup; implementation still live, pending items not tracked"` | citado por `CONTEXTO:508`; implementação continua |
| D10 | `docs/SPRINT_AUDITORIA_PRODUTO_UX_2026-03-25.md` | 2026-03-25 | `docs/design/visual-audit-2026-09-21/README.md`, `docs/MANALOOM_UI_LIVE_EVIDENCE_CONTRACT.md` | 659-667 ("Ordem oficial") | `"March 2026 UX sprint; 5 IN_PROGRESS screens frozen"` | citado por `CONTEXTO:811` |
| D11 | `docs/SPRINT_LIFE_COUNTER_BENCHMARK_CLONE_2026-03-25.md` | 2026-03-25 | `app/lib/features/home/lotus_life_counter_screen.dart`, `docs/flows/life_counter_post_game.md`, backlog Épico H; `código-alvo removido em d08985bca (2026-07-01)` | 3-6 (`Status: ACTIVE`) | `"clone sprint whose target screen was deleted in d08985bca"` | única narrativa da fase clone; citado por `CONTEXTO:257,461` |
| D12 | `docs/SPRINT_LIFE_COUNTER_TABLETOP_2026-03-25.md` | 2026-03-25 | idem D11 | 3-5 e 285 (`IN_PROGRESS`) | idem | citado por `CONTEXTO:256,460` |
| D13 | `docs/TASK_LIFE_COUNTER_PERFEICAO_2026-03-26.md` | 2026-03-26 | idem D11 | 3-5 (`Status: ACTIVE`), 286-297 ("Proxima task") | idem | citado por `CONTEXTO:258,355,480` |
| D14 | `docs/LAYOUT_TEST_MAP.md` | 2026-05-30 | `app/doc/UI_TEST_SURFACE_MAP.md` (S3-01…S3-08), `app/test/ui/fixtures/*.json`; banner deve nomear os 3 testes removidos em `d08985bca` e as 6 lacunas fechadas | — | `"2026-05-30 layout test photo; 3 files deleted, 6 of 9 gaps closed"` | 6 citações em 5 arquivos (`docs/flows/`, `docs/design/`, `hermes-analysis`) — ver FATOS 10.9 |
| D15 | `docs/EASYPANEL_RUNBOOK_MTGIA_2026-03-24.md` | (já bannerizado) | — | 3: `> Lifecycle: \`HISTORICAL_EVIDENCE · NO_MUTATION_AUTHORITY · NO_DEPLOY_AUTHORITY\`.` | `"server cutover record 2026-06/07; commands not executable"` | único registro do cutover; citado por `CONTEXTO:512` |
| D16 | `docs/PROJECT_LOGIC_FULL_REPORT_2026-06-11.md` | (já bannerizado) | — | 3: `> Lifecycle: \`HISTORICAL_EVIDENCE · SUPERSEDED · NO_MUTATION_AUTHORITY\`.`; 13: `> Relatório histórico de arquitetura… no checkout de 2026-06-11.` | `"2026-06-11 full report; superseded by generated CURRENT_SYSTEM"` | corpo já coberto pelo banner |
| D17 | `docs/MANALOOM_PRODUCT_READINESS_RUNBOOK_2026-07-06.md` | (banner correto) | — | nenhuma | `"pre-free-beta readiness runbook; checkout/Pro/webhook no longer exist"` | zero inbound; mover para `docs/archive/2026-07/` é opcional e seguro |
| D18 | `server/doc/COMMANDER_LEARNING_API_2026-06-03.md`, `server/doc/MANALOOM_CRONS_E_PENDENCIAS.md` | (já bannerizados) | — | nenhuma | `"historical; banner present since d93867b68"` | fora do escopo dos grupos, mas mesmo problema: banner sem override |

Total de entradas novas em `document_overrides`: 17 (D1, D5-D18) + `AGENTS.md` + `VISUAL_EXECUTION_BASE` = 19 (as fichas D2-D4 ficam cobertas pelo prefixo `docs/execution/tasks/` se permanecerem lá; se forem movidas para `closed/`, o prefixo ainda cobre).

---

## E. REMOVER

| # | Documento | Ação | Justificativa | Confirmação de que nenhum canônico o cita |
| --- | --- | --- | --- | --- |
| E1 | `docs/HERMES_SQLITE_EASYPANEL_BRIDGE_AUDIT_2026-06-06.md` | `git mv` → `docs/archive/2026-06/HERMES_SQLITE_EASYPANEL_BRIDGE_AUDIT_2026-06-06.md` (prefixo `docs/archive/` classifica como `historical_evidence` sem banner nem override) | zero referências inbound em todo o repo (inclusive untracked); único valor de evidência (migration 018 + backfill) já está em `server/bin/migrate.dart:483-490` e no receipt `server/doc/BACKFILL_CARD_COMBAT_METADATA_2026-06-06.json` com os mesmos números; o resto (contagens live, `knowledge.db` nunca versionado, `battle_analyst_v8` apagado, Hermes dormente) só confunde | `git grep -n HERMES_SQLITE_EASYPANEL -- . ':!docs/HERMES_SQLITE…md'` = vazio; `grep -rn HERMES_SQLITE docs/design docs/flows docs/PONTO_…md` = vazio |
| E2 | `CLAUDE.md` | retirar de qualquer índice ou lista de grupo | nunca existiu (`find`, `git ls-files`, `git log --all --name-only` vazios; sem `.claude/`) | n/a |

---

## F. Geradores (correções em código, não em documento)

| # | Arquivo | Correção | Fato |
| --- | --- | --- | --- |
| F1 | `tools/project_logic/lib/project_logic_generator.dart:3642-3645,3677-3680` | derivar `security: [bearerAuth]` da presença de `authMiddleware` na cadeia de `_middleware.dart` do handler, não da ausência em `public_api_paths`; tratar `public_api_paths` como asserção verificada | 2.7 |
| F2 | idem (bloco que imprime `statistics` em `CURRENT_SYSTEM.md`) | imprimir `tests` e `scripts_and_jobs` com quebra por raiz (`server 401 · app 237 · integration 147 · hermes-lab 424 · outros 12`; `docs/hermes-analysis 427 · server/bin 140 · scripts 94 · …`) | 5.11 |
| F3 | idem (tabela "Fluxos canônicos") | renomear coluna para "Escopo declarado no contrato (não é capability)" e rodapé `Capabilities ligadas hoje: 0/29 (server/config/release_capabilities.json, policy_version brewtact_free_beta_2026-08-13). Fonte de prioridade: docs/status/CURRENT_PRODUCT_DECISION.md.` | 1.1, 2.3 |
| F4 | `docs/project_logic_contracts.json > documentation_lifecycle.prefix_rules` | follow-up de `d93867b68` ainda não feito: avaliar regra para `archive_docs/` (14 docs sem lifecycle) | 9.16 |

---

## G. Ordem de execução sugerida (menor risco primeiro)

1. Commitar o fix do marketplace + 4 gerados (árvore volta a ficar limpa; o `--check` volta a passar; a auditoria de drift de 2026-09-27 não é pulada).
2. A1 (`project_logic_contracts.json`: overrides, `public_api_paths`, entrypoints, gates) → `--write` → `--check`.
3. A2, A5, A7, A8, A10, A12, A13, A14 (correções pontuais em canônicos) → `--write` → `--check`.
4. A4 (backlog: 3 estados, 17 evidências, linhas novas BT-CI-001/BT-UIEV-001/BT-UX-KIT-001 + decisões do dono) → `--write`; B4 (fila) só depois que o dono ratificar o próximo NOW.
5. A6 (MAPA), A11 (CURRENT_FLOW), A9 (DECK_QUALITY — após ratificação).
6. A3 (CONTEXTO: cortar e arquivar).
7. B1, B2 (roteadores).
8. §D (banners + overrides) e §E (mover HERMES) → `--write` → `--check`.
9. §C (apoio: ficha NOW, PROPOSED, VISUAL_BASE, `.hermes.md`, `docs/flows`, PONTO, design).
10. §F (geradores) — pode ser uma task própria no Épico J.
11. Cada lote commitado **com hook** só depois de BT-UIEV-001 fechar `latest.json`; até lá, qualquer commit continua exigindo `--no-verify` declarado na mensagem.
