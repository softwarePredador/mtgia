# Tracker executável de conclusão do ManaLoom

**Plano de escopo:** `docs/MANALOOM_PRODUCT_COMPLETION_SPRINTS.md`

**Estado inicial:** nenhuma task recebeu `PASS` herdado.

Este é o registro vivo de execução. O plano define objetivo e aceite; este
arquivo define quem pode editar, em que ordem, qual gate foi executado e onde
está a evidência.

## Protocolo de atualização

1. Antes da primeira edição, preencher `Owner`, `Arquivos pretendidos` e mudar
   somente uma task de `READY` para `IN_PROGRESS`.
2. Se algum arquivo pretendido já estiver declarado por outra task ativa, as
   duas tasks não podem executar em paralelo.
3. `Arquivos pretendidos` deve listar paths ou diretórios estreitos; `repo todo`
   não é declaração válida.
4. O owner registra o teste focado durante o trabalho. O gate mínimo desta
   tabela é executado antes de pedir fechamento.
5. `PASS` exige link para evidência com SHA, comandos, exit codes, contagens,
   skips, ambiente e cleanup. Evidência verbal não é suficiente.
6. `BLOCKED` exige causa, owner da dependência e próxima condição verificável.
7. Mudança de dependência, prioridade ou aceite deve atualizar primeiro o plano
   e depois este tracker.
8. Durante S10, o tracker fica congelado junto com o checkout; somente a
   decisão e os links de evidência podem ser atualizados após os gates.

Campos iniciais `—` são obrigatoriamente preenchidos antes de `IN_PROGRESS`.

## Governança local gratuita

| ID | Estado | Owner | Gate | Evidência |
|---|---|---|---|---|
| G-01 | `PASS` | `/root` | `./scripts/manaloom_local_ci.sh full` | `docs/qa/MANALOOM_PROJECT_LOGIC_GOVERNANCE_2026-07-21.md` — manifesto/analyzer 571/571, gates/hook locais, PostgreSQL/tbls descartável e suíte completa PASS; GitHub Actions ausente |

## Sprint 0

| ID | Estado | Depende de | Owner | Arquivos pretendidos | Gate mínimo | Evidência |
|---|---|---|---|---|---|---|
| S0-01 | `PASS` | — | `/root` | caches globais regeneráveis e imagens Android sem AVD | `df -h` + inventário | `docs/qa/MANALOOM_SPRINT0_BASELINE_2026-07-21.md` — 7.6→53 GiB; caches/imagens inventariados |
| S0-02 | `PASS` | — | `/root` | worktree inteiro, somente inventário/atribuição | `git status` + diff base | `docs/qa/MANALOOM_SPRINT0_BASELINE_2026-07-21.md` — HEAD, patch hash, hashes e owners |
| S0-03 | `PASS` | S0-02 | `/root` | `docs/CONTEXTO_PRODUTO_ATUAL.md`; `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`; `docs/README.md`; `server/doc/API_CONTRACTS_AND_DATA_MAP.md`; `server/manual-de-instrucao.md`; guards focados | guards documentais focados | `docs/qa/MANALOOM_SPRINT0_BASELINE_2026-07-21.md` — Lorehold 17/17, server 22/22, auth 6/6 |
| S0-04 | `PASS` | S0-02 | `/root` | `docs/hermes-analysis/master_optimizer_reports`; manifest/guard de retenção | `quality_gate.sh report-retention` | `docs/qa/MANALOOM_SPRINT0_BASELINE_2026-07-21.md` — 18 classificados; gate 13/13 PASS |
| S0-05 | `PASS` | S0-01, S0-02 | `/root` | `scripts/manaloom_e2e_suite.sh`; `/tmp/manaloom_e2e_suite_reports`; correção estreita somente se reproduzida | Battle dentro do aggregate 2× | `docs/qa/MANALOOM_SPRINT0_BASELINE_2026-07-21.md` — 2× partial, Battle PASS, 0 FAIL/BLOCKED |
| S0-06 | `PASS` | S0-03–S0-05 | `/root` | `app/dart_dependency_validator.yaml`; `app/pubspec.yaml`; `server/dart_dependency_validator.yaml`; gates read-only do repo | gates completos S0 | `docs/qa/MANALOOM_SPRINT0_BASELINE_2026-07-21.md` — 9 gates, 0 FAIL/BLOCKED |
| S0-07 | `PASS` | S0-06 | `/root` | `docs/qa/MANALOOM_SPRINT0_BASELINE_2026-07-21.md`; tracker | manifesto de baseline | HEAD/SDK/hashes/skips congelados na evidência S0 |

## Sprint 1

| ID | Estado | Depende de | Owner | Arquivos pretendidos | Gate mínimo | Evidência |
|---|---|---|---|---|---|---|
| S1-01 | `PASS` | S0-07 | `/root` | shapes app/backend; migration 041; bootstrap social; harness PostgreSQL/API isolado | testes de shape app/server | `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md` — Flutter 119/119, Dart 54/54, HTTP 119/119 + matriz 1/1 + análise 3/3; cleanup zero |
| S1-02 | `PASS` | S0-07 | `/root` | `app/lib/features/auth/providers/auth_provider.dart`; `app/lib/features/auth/screens/login_screen.dart`; testes focados de auth; middleware/testes de rate limit já atribuídos | auth + rate-limit focados | `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md` — Flutter 14/14, backend 51/51 |
| S1-03 | `PASS` | S0-07 | `/root` | `scripts/manaloom_migrations_038_040_isolated.sh`; helper/teste isolado em `server/bin`/`server/test`; evidência Sprint 1 | fresh/upgrade/idempotência PG | `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md` — fresh/upgrade/reapply/restore/forward PASS; cleanup zero DB |
| S1-04 | `PASS` | S1-03 | `/root` | rotas/serviço/testes de post-game sync; harness API isolado; evidência Sprint 1 | E2E dois clientes/tombstone | `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md` — Flutter 12/12, Dart 5/5, E2E dois clientes 1/1; sem ressurreição |
| S1-05 | `PASS` | S1-03 | `/root` | rotas/serviço/testes de export/delete; harness API isolado; UI de privacidade | export/delete autenticados | `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md` — Flutter 5/5, Dart 13/13, E2E privacy 1/1; revogação comprovada |
| S1-06 | `PASS` | S0-07 | `/root` | auditor anti-fanout/identidade; wrapper PostgreSQL read-only allowlisted; `scripts/quality_gate.sh`; evidência Sprint 1 | `quality_gate.sh pg-contract` | `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md` — locais 36/36, wrapper 4/4, auditor 8/8 e live read-only 55/55 PASS; `mutations_performed=[]`; cleanup zero |
| S1-07 | `PASS` | S1-01, S1-06 | `/root` | `server/lib/collection_availability_contract.dart`; `server/lib/ai/optimize_swap_candidate_support.dart`; migrations 045/046 e bootstrap; rotas `binder`, `community/binders`, `community/marketplace` e `trades`; provider/tela Binder; testes app/server/E2E; mapa API; evidência Sprint 1 | testes de alocação/concorrência | `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md` — Flutter 13/13, servidor focado 42/42 + completo 698/698, E2E concorrente 1/1, migrations fresh/upgrade/restore PASS; cleanup zero |
| S1-08 | `PASS` | S1-02 | `/root` | migrations 042/044; serviço/rotas auth; recuperação/troca/revogação/verificação; gates UGC; UI; preflight e harness isolado | recuperação/revogação/verificação E2E | `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md` — Flutter 41/41, backend focado 71/71 e E2E PG 3/3; JWT antigo revogado, token single-use, UGC 403→200, entrega sanitizada |
| S1-09 | `PASS` | S1-02 | `/root` | migration 043; política/registro transacional; telas/rotas legais pré-login; testes app/server/E2E | legal pré-login + cadastro | `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md` — versões exatas, rejeição sem conta parcial, uma conta/um plano no sucesso; E2E incluído no summary `1d7d6f0a…` |

## Sprint 2

| ID | Estado | Depende de | Owner | Arquivos pretendidos | Gate mínimo | Evidência |
|---|---|---|---|---|---|---|
| S2-01 | `PASS` | S0-07 | `/root` | `app/lib/core/theme/app_theme.dart`; `app/lib/core/widgets/responsive_page_frame.dart`; manifesto/testes de tema/tokens; migração mecânica de `EdgeInsets`/`SizedBox`/`Gap`; evidência visual Sprint 2 | testes de tokens/layout | `docs/qa/MANALOOM_SPRINT2_VISUAL_EVIDENCE_2026-07-21.md` — 31 tokens, dívida crua 1355→0, focados 7/7, analyzer zero e Flutter completo 1011/1011 + 1 skip Web-only |
| S2-02 | `PASS` | S2-01 | `/root` | `app/lib/core/widgets/card_artwork.dart`; `cached_card_image.dart`; helper Scryfall; `deck_card_item.dart`; `card_provider.dart`; testes de arte/faces/provider | testes do componente de imagem | `docs/qa/MANALOOM_SPRINT2_VISUAL_EVIDENCE_2026-07-21.md` — revalidação fresca 25/25 PASS |
| S2-03 | `PASS` | S2-02 | `/root` | `app/lib/features/cards/screens/card_detail_screen.dart`; testes responsivos/faces/erro | card-detail responsivo/golden | `docs/qa/MANALOOM_SPRINT2_VISUAL_EVIDENCE_2026-07-21.md` — revalidação fresca 6/6 PASS em 390/800/1440/1920, 404, ausente, DFC e texto 200% |
| S2-04 | `PASS` | S2-02 | `/root` | `deck_list_screen.dart`; `home_screen.dart`; testes de cinco origens, URL nula/malformada/host desconhecido/DFC/padding; golden determinístico; fluxo runtime de deck | deck list/home image tests | `docs/qa/MANALOOM_SPRINT2_VISUAL_EVIDENCE_2026-07-21.md` — revalidação fresca conjunta 16/16 PASS, incluindo golden e fluxo register→verify→generate→optimize→validate |
| S2-05 | `PASS` | S2-01, S2-02 | `/root` | `home_screen.dart`; goldens Home 390/1200/1440/1920; reduced motion/texto 200% | Home goldens | `docs/qa/MANALOOM_SPRINT2_VISUAL_EVIDENCE_2026-07-21.md` — revalidação fresca 12/12 PASS |
| S2-06 | `PASS` | S2-01 | `/root` | `mana_symbols.dart`; `assets/symbols`; `mana_symbols_test.dart`; guard global de apresentação | mana symbol inventory/goldens | `docs/qa/MANALOOM_SPRINT2_VISUAL_EVIDENCE_2026-07-21.md` — 84 SVG e revalidação fresca 14/14 PASS |
| S2-07 | `PASS` | S2-02 | `/root` | `sets_catalog_screen.dart`; `set_icon_svg_cache.dart`; `server/routes/sets`; testes app/server | sets catalog/image fallback | `docs/qa/MANALOOM_SPRINT2_VISUAL_EVIDENCE_2026-07-21.md` — revalidação fresca app 11/11 + servidor 8/8 PASS |
| S2-08 | `PASS` | S2-03–S2-07, S2-09 | `/root` | build Web local; `app/tool/serve_flutter_web_app.py`; matriz browser; goldens; harness autenticado local descartável | CI pixel diff + smoke real | `docs/qa/MANALOOM_SPRINT2_VISUAL_EVIDENCE_2026-07-21.md` — browser autenticado 390/1440/1920, rede real/cache/404/1,2 s, console zero, ui-audit 13/13 e cleanup zero |
| S2-09 | `PASS` | S0-07 | `/root` | `scripts/manaloom_deploy_flutter_web.sh`; `scripts/manaloom_web_artifact_identity.sh`; contratos de identidade/release | Web artifact identity guard | `docs/qa/MANALOOM_SPRINT2_VISUAL_EVIDENCE_2026-07-21.md` — commit/patch/bundle/SDK/renderer/viewport/DPR/dataset validados; stale rejeitado |

## Sprint 3

| ID | Estado | Depende de | Owner | Arquivos pretendidos | Gate mínimo | Evidência |
|---|---|---|---|---|---|---|
| S3-01 | `PASS` | S2-08, S2-09 | `/root` | `app/doc/UI_TEST_SURFACE_MAP.md`; `app/test/ui/fixtures/ui_surface_inventory.json`; `app/test/ui/ui_surface_inventory_test.dart`; `docs/qa/MANALOOM_SPRINT3_UX_EVIDENCE_2026-07-21.md` | route/surface inventory | `docs/qa/MANALOOM_SPRINT3_UX_EVIDENCE_2026-07-21.md` — 218 superfícies classificadas, guard 4/4, analyzer zero e `ui-audit` 17/17 PASS |
| S3-02 | `PASS` | S3-01 | `/root` | `app/lib/core/widgets/app_state_panel.dart`; telas com lacuna comprovada; `app/test/ui/fixtures/ui_state_matrix.json`; `app/test/ui/ui_state_matrix_test.dart`; `app/doc/UI_TEST_SURFACE_MAP.md`; `docs/qa/MANALOOM_SPRINT3_UX_EVIDENCE_2026-07-21.md` | state-matrix tests | `docs/qa/MANALOOM_SPRINT3_UX_EVIDENCE_2026-07-21.md` — 18 domínios × 15 estados decididos, 17 loadings acessíveis, matriz 288/288 e `ui-audit` 21/21 PASS |
| S3-03 | `PASS` | S3-01 | `/root` | `app/lib/core/widgets/responsive_page_frame.dart`; telas com overflow comprovado; `app/test/ui/fixtures/ui_viewport_matrix.json`; `app/test/ui/ui_viewport_matrix_test.dart`; testes responsivos por domínio; `app/doc/UI_TEST_SURFACE_MAP.md`; `docs/qa/MANALOOM_SPRINT3_UX_EVIDENCE_2026-07-21.md` | viewport matrix | `docs/qa/MANALOOM_SPRINT3_UX_EVIDENCE_2026-07-21.md` — 16 viewports/boundaries, 18 domínios, teclado + texto 200%, matriz 125/125 e `ui-audit` 25/25 PASS |
| S3-04 | `BLOCKED` | S3-01 | `/root` | `app/test/ui/fixtures/ui_accessibility_matrix.json`; `app/test/ui/ui_accessibility_matrix_test.dart`; componentes/telas com falha comprovada; testes semantics/contraste/alvo; `app/doc/UI_TEST_SURFACE_MAP.md`; `docs/qa/MANALOOM_SPRINT3_UX_EVIDENCE_2026-07-21.md` | semantics/text 200% | automação corrente e `ui-audit` 48/48 PASS; fechamento depende somente de interação humana TalkBack no Samsung alvo. S10 fixou Web+Android, então iOS/VoiceOver está `DEFERRED_BY_SCOPE` e não bloqueia a candidata |
| S3-05 | `PASS` | S3-01 | `/root` | `app/test/ui/fixtures/ui_keyboard_focus_matrix.json`; `app/test/ui/ui_keyboard_focus_matrix_test.dart`; `app/lib/features/profile/profile_screen.dart`; `app/lib/features/auth/screens/login_screen.dart`; testes de teclado/foco Web; `app/doc/UI_TEST_SURFACE_MAP.md`; `docs/qa/MANALOOM_SPRINT3_UX_EVIDENCE_2026-07-21.md` | keyboard/focus Web | `docs/qa/MANALOOM_SPRINT3_UX_EVIDENCE_2026-07-21.md` — widget focado 25/25, `ui-audit` 35/35, rotas autenticadas Home/Decks/Collection/Community/Profile/Battle-Replays, modal real com trap/Escape/restauração, reduced-motion, DOM sem duplicação, console zero e cleanup da conta QA pelo app |
| S3-06 | `PASS` | S3-01 | `/root` | `app/lib/main.dart`; `app/lib/core/api/api_client.dart`; `app/lib/features/auth/providers/auth_provider.dart`; rotas/provedor/call sites de Card Detail; drafts de Generate/Import; `server/routes/cards/index.dart`; `app/test/ui/fixtures/ui_navigation_resume_matrix.json`; testes app/server; `app/doc/UI_TEST_SURFACE_MAP.md`; `docs/qa/MANALOOM_SPRINT3_UX_EVIDENCE_2026-07-21.md` | deep-link/reload suite | `docs/qa/MANALOOM_SPRINT3_UX_EVIDENCE_2026-07-21.md` — 38 rotas, query-tab/back-forward/reload, Battle/Card canônicos, drafts por usuário, sessão expirada automatizada, browser real e gates `full`, `ui-audit` e `project-logic` PASS; duas verificações pós-deploy explicitamente retidas |
| S3-07 | `PASS` | S3-02–S3-06 | `/root` | harness visual autenticado isolado; fixture determinística; matriz/guard; 80 goldens; comparador pixel a pixel; Web real e Android físico; evidência Sprint 3 | visual authenticated harness | `docs/qa/MANALOOM_SPRINT3_UX_EVIDENCE_2026-07-21.md` — 20 checkpoints × Web 390/1440/1920 e Samsung SM-A135M, revisão humana aprovada, console warn/error zero, pixel diff 80/80 e estado descartável removido |
| S3-08 | `PASS` | S3-06 | `/root` | onboarding/first-run; persistência por usuário; falha/offline; logout/login; deep link; teclado/texto 200%; analytics idempotente; teste runtime Android; evidência Sprint 3 | onboarding/first-run E2E | `docs/qa/MANALOOM_SPRINT3_UX_EVIDENCE_2026-07-21.md` — 22/22 focados, auth 31/31, contrato server 2/2, `ui-audit` 48/48, gate `full` com backend 1618, app 1084 + 1 skip e Web pública aprovada; E2E profile no Samsung físico com Flutter 3.44.6; primeira entrada, retomada, skip e novo login aprovados; fixture/DB/reverse removidos |

## Sprint 4

| ID | Estado | Depende de | Owner | Arquivos pretendidos | Gate mínimo | Evidência |
|---|---|---|---|---|---|---|
| S4-01 | `PASS` | S1, S3 | `/root` | criação/edição/remoção/importação de deck; formato e payload canônicos; readiness explícita; mutação de edição/quantidade atômica; testes unitários e E2E PostgreSQL/API isolado | deck mutation/import tests | `docs/qa/MANALOOM_SPRINT4_CORE_EVIDENCE_2026-07-22.md` — backend focado 23/23, provider 37/37, E2E CRUD/rollback 1/1 e gate completo backend 1626/1626 + Flutter 1086 + 1 skip + Web PASS |
| S4-02 | `PASS` | S4-01 | `/root` | migration 047 e bootstrap; contrato/rota de validação; readiness; modelos e status Flutter; testes unitários, widget e E2E PostgreSQL/API isolado | validation-state tests | `docs/qa/MANALOOM_SPRINT4_CORE_EVIDENCE_2026-07-22.md` — backend focado 57/57, Flutter focado 23/23, E2E de estados 1/1, gate completo backend 1628/1628 + Flutter 1087 + 1 skip + Web PASS |
| S4-03 | `PASS` | S4-02 | `/root` | optimize preview/apply; histórico reversível; rollback; provider/snackbar; contratos/testes/evidência | optimize/apply/rollback E2E | `docs/qa/MANALOOM_SPRINT4_CORE_EVIDENCE_2026-07-22.md` — backend focado 12/12, Flutter focado 90/90, E2E transacional/rollback 1/1, gate completo backend 1631/1631 + Flutter 1089 + 1 skip + Web PASS |
| S4-04 | `PASS` | S4-03 | `/root` | migration 048; lifecycle idempotente de generate/optimize; rotas latest/cancel; persistência e retomada Flutter; timeout recuperável; readiness, contratos e E2E isolado | async job/cancel/resume | `docs/qa/MANALOOM_SPRINT4_CORE_EVIDENCE_2026-07-22.md` — backend focado 49/49, Flutter focado 109/109, E2E lifecycle 1/1, gate completo backend 1638/1638 + Flutter 1096 + 1 skip + Web PASS |
| S4-05 | `PASS` | S1-07, S3 | `/root` | migration 049; identidade física e jogável; rota de disponibilidade; Binder/Deckbuilder; locks de trade; readiness; testes unitários, concorrentes e E2E PostgreSQL/API isolado | collection→deck E2E | `docs/qa/MANALOOM_SPRINT4_CORE_EVIDENCE_2026-07-22.md` — backend focado 57/57, Flutter focado 14/14, E2E coleção/deck/trade 1/1, gate completo backend 1647/1647 + Flutter 1099 + 1 skip + Web PASS |
| S4-06 | `PASS` | S1-04, S4-01 | `/root` | snapshot de deck; detalhe/rota/sessão/mirror Lotus; pós-jogo/fila offline; contratos/testes/evidência | deck→mesa→pós-jogo E2E | `docs/qa/MANALOOM_SPRINT4_CORE_EVIDENCE_2026-07-22.md` — backend focado 14/14, Flutter focado 64/64, E2E dois clientes/versão imutável 1/1, gate completo backend 1650/1650 + Flutter 1102 + 1 skip + Web PASS |
| S4-07 | `PASS` | S3 | `/root` | escopo por plataforma; rota/fallback; câmera/MLKit; harness físico; pipeline/identidade Android; contratos/evidência | scanner scope/build proof | `docs/qa/MANALOOM_SPRINT4_CORE_EVIDENCE_2026-07-22.md` — Flutter focado 30/30, Android físico 1/1 controlado + 2/2 câmera/MLKit, APK release instalado/aberto, contratos release 1/1 + 25/25, gate completo backend 1650/1650 + Flutter 1104 + 1 skip + Web PASS; iOS fora do alvo atual e remetido ao S10 |
| S4-08 | `PASS` | S4-01, S4-05 | `/root` | migration 050; contrato/proveniência/cache de preço; refresh Scryfall; totais de deck; Binder BRL/USD; Marketplace/Market; testes app/server e E2E PostgreSQL/API isolado | pricing/missing-data tests | `docs/qa/MANALOOM_SPRINT4_CORE_EVIDENCE_2026-07-22.md` — backend focado 42/42, backend direto 701 + 3 skips históricos, Flutter 48/48, E2E pricing 1/1 com migration 050 e cleanup |
| S4-09 | `PASS` | S3 | `/root` | Home e provider de decks; estados loading/vazio/offline/401; atalhos/rotas; onboarding/verify-email; Patrol; gate de SDK; testes/evidência | Home state/navigation E2E | `docs/qa/MANALOOM_SPRINT4_CORE_EVIDENCE_2026-07-22.md` — Flutter focado 69/69, Patrol 9/9, AI bridge + eval 3/3, gate completo backend 1657/1657 + Flutter 1113 + 1 skip + Web PASS e project-logic 9/9 |

## Sprint 5

| ID | Estado | Depende de | Owner | Arquivos pretendidos | Gate mínimo | Evidência |
|---|---|---|---|---|---|---|
| S5-01 | `PASS` | S1 | `/root` | `docs/qa/MANALOOM_SPRINT5_BATTLE_EVIDENCE_2026-07-22.md`; outputs descartáveis em `/tmp/manaloom_s501_alignment_20260722` | 3 auditorias de alinhamento | Deckbuilder 344 superfícies/0 falhas; XMage 29/29; operacional 53/53; histórico continua bloqueado |
| S5-02 | `PASS` | S5-01 | `/root` | `docs/qa/MANALOOM_SPRINT5_BATTLE_EVIDENCE_2026-07-22.md`; outputs `/tmp/manaloom_s502_lorehold_xmage_20260722.2oiiZi` | coverage/family inventory | deck 607: XMage exato 91/94; 3 Forge source candidates explícitos; 0 native imediato; 186/186 superfícies classificadas; sem promoção |
| S5-03 | `PASS` | S5-02 | `/root` | `services/forge-sidecar`; imagem local `manaloom-forge-sidecar:local-proof`; `docs/qa/MANALOOM_SPRINT5_BATTLE_EVIDENCE_2026-07-22.md` | adapter tests + package proof | Forge pinado compilado; 13/13 testes; 3/3 gaps suportados; 100/100 + 100/100 coverage; battle concluído em 13 turnos/10.574 ms/774 eventos/0 erros; negativo HTTP 422; gate Battle verde; sem promoção |
| S5-04 | `PASS` | S5-01 | `/root` | contracts/clients/sidecars/runner v2 e testes de engine | seed/timeout/censoring tests | Identidade/version/commit/processo, request/deck hashes e timeout validados; XMage e Forge declaram seed não reprodutível; timeout não aciona fallback; censura não expõe vencedor; auditoria 41/41, Forge 15/15 e runner 30/30 |
| S5-05 | `PASS` | S1-01, S5-01 | `/root` | persistência/leitura/sanitização de replay; rotas e testes PG/auth | replay PG/auth E2E | POST/lista/detalhe preservam UUID durável; persistência falha fechado; owner/IDOR e respostas sanitizadas validados; E2E descartável 1/1 |
| S5-06 | `PASS` | S5-03, S5-04 | `/root` | contrato de evidência Battle/Deckbuilder; runner e testes positivos/negativos | natural exposure/trace tests | Só `event_type`/`action` de source card conta como uso natural; log/target/type genérico permanece `unknown`; forced access é diagnóstico; nenhuma promoção automática |
| S5-07 | `PASS` | S5-02 | `/root` | fila XMage/Forge/native, ownership e auditorias operacionais | priority/owner-intent audit | Fila combina decks de produto, uso natural tipado, impacto e residual; XMage/Forge executam catálogo coberto; native só residual provado; user skeleton não é alterado e PostgreSQL permanece canônico; queue 11/11 |
| S5-08 | `PASS` | S5-01–S5-07 | `/root` | `scripts/quality_gate.sh`; gate Battle e testes/auditorias associados | `quality_gate.sh battle` 2× | Duas execuções válidas com exit 0 no mesmo HEAD/digest `cf7db6175a68171271723c00469ffa18f9b6311830764bc40c07cb5b466c0928`; em cada execução: auditorias 41/41 + 29/29, produto 45/45 e Dart 100/100 |
| S5-09 | `PASS` | S5-08 | `/root` | harness Battle E2E, PostgreSQL descartável e auditoria `/tmp/manaloom_s5_09_disposable_final.json` | guarded Battle isolated E2E | E2E 1/1; 2 usuários, 2 decks, 200 deck_cards e 2 replays; owner/intruder e IDs duráveis validados; tabelas zeradas, cluster destruído, 3 processos encerrados e listeners fechados |
| S5-10 | `PASS` | S5-01 | `/root` | evidências Sprint 5 e auditoria XMage/Forge; outputs candidatos em `/tmp` | `quality_gate.sh engine-delta` + capability gate | 95/95 checks; fonte local explícita/limpa/pinada; auditor reexecutado com 316 cartas/328 fixtures (XMage 120/131, Forge 196/197), ambos +113 commits; compare Forge truncado exige revisão antes de qualquer avanço; pins preservados e zero promoção/deploy; `docs/qa/MANALOOM_XMAGE_FORGE_CAPABILITY_AUDIT_2026-07-22.md` |

## Sprint 6

| ID | Estado | Depende de | Owner | Arquivos pretendidos | Gate mínimo | Evidência |
|---|---|---|---|---|---|---|
| S6-01 | `PASS` | S5-09 | `/root` | Commander planning contract v6/v3; server/app parsers and tests | Commander contract tests | fluxo de 12 etapas e contrato público sanitizado; `docs/qa/MANALOOM_SPRINT6_DECKBUILDER_EVIDENCE_2026-07-22.md` |
| S6-02 | `PASS` | S6-01 | `/root` | proveniência pública Optimize/Analyze; UI e testes | provenance UI/API tests | Oracle/preço/corpus/uso aprendido/IA separados; Hermes bruto censurado; evidência Sprint 6 |
| S6-03 | `PASS` | S6-01 | `/root` | auditor global Commander e wrapper PostgreSQL read-only | global Commander audit | PostgreSQL 295/295 classificados; 16 produto, 7 prontos e 9 para revisão do dono; zero mutação; evidência Sprint 6 |
| S6-04 | `PASS` | S6-01, S6-03 | `/root` | seleção de cortes/swaps, planning summary e testes | same-lane/anchor tests | mesma lane ou hipótese explícita; anchors protegidos; evidência Sprint 6 |
| S6-05 | `PASS` | S4-05, S6-01 | `/root` | constraints, apply/reanalysis/rollback e E2E isolado | collection/budget E2E | collection-only e orçamento hard; parcial/total, rollback e drift guard; evidência Sprint 6 |
| S6-06 | `PASS` | S6-01–S6-05 | `/root` | gates estatísticos pareado-rejeitado e independente; safety do probe nativo | real Lorehold engine-aware independent-sample gate | desenho histórico rejeitado; nenhuma promoção; próximo gate usa amostras independentes balanceadas; evidência Sprint 6 |
| S6-07 | `PASS` | S5-09 | `/root` | baseline policy servidor/app e testes UI | protected-baseline guards | deck 607 `experimental_blocked`, protegido e sem apply automático; evidência Sprint 6 |
| S6-08 | `PASS` | S6-01, S6-05 | `/root` | fixture held-out, scorer, runner real e gates AI | eval + latency benchmark | held-out 6/6 score 100; modelos reais 12/12, p50 2.873 ms, p95 5.041 ms, US$ 0,035058; evidência Sprint 6 |
| S6-09 | `PASS` | S6-01–S6-08 | `/root` | lifecycle real, full catalog, apply/rollback e harness PG isolado | real-provider full lifecycle E2E | 2/2, 50 migrations, 34.653 cartas, provider `prod`, cleanup; summary `a932e771…`; evidência Sprint 6 |

## Sprint 7

| ID | Estado | Depende de | Owner | Arquivos pretendidos | Gate mínimo | Evidência |
|---|---|---|---|---|---|---|
| S7-01 | `PASS` | S1 | `/root` | migration 051; `SocialSafetyService`; `/content-reports`; diálogo/ações UGC | UGC report tests | `docs/qa/MANALOOM_SPRINT7_SOCIAL_SAFETY_EVIDENCE_2026-07-23.md` — quatro superfícies, confirmação, 409 duplicado e 429 distribuído |
| S7-02 | `PASS` | S7-01 | `/root` | `user_blocks`; rotas block/list; filtros sociais e UI de unblock | two-user block E2E | evidência Sprint 7 — corte bilateral de feed, perfil, follow, mensagem, notificação e trade; desbloqueio auditado |
| S7-03 | `PASS` | S7-01, S7-02 | `/root` | fila/admin middleware; ação/SLA/auditoria/apelação; filtros de conteúdo | moderation workflow E2E | evidência Sprint 7 — ação transacional e mensagem removida ausente da lista e detalhe |
| S7-04 | `PASS` | S1, S7-02 | `/root` | visibilidades fechadas em `users`; perfil/Binder/trade/mensagem; controles Flutter | ownership/privacy negative E2E | evidência Sprint 7 — allowlists e negativos entre dois usuários no PostgreSQL descartável |
| S7-05 | `PASS` | S1, S7-02 | `/root` | `client_request_id`; `MessageDraftStore`; providers/chats; coordinator realtime | realtime/draft/push E2E | evidência Sprint 7 — Flutter 87/87, Android físico 1/1, draft/retry/unread/foreground/tap; transporte final permanece S8-06 |
| S7-06 | `PASS` | S1-01, S1-07 | `/root` | máquina de trade, locks de disponibilidade e aviso P2P | trade concurrency E2E | evidência Sprint 7 — E2E combinado 5/5 e disponibilidade concorrente atômica |
| S7-07 | `PASS` | S7-02, S7-04 | `/root` | feed canônico; follows; comentários visíveis/exclusão; estados Flutter | feed/follow/comment tests | evidência Sprint 7 — paginação, refresh, bloqueio, exclusão e erro/vazio cobertos |
| S7-08 | `PASS` | S7-01–S7-07 | `/root` | decisão de escopo social | full PASS or scope-disable proof | conjunto Community/chat/trades permanece habilitado após S7-01–S7-07 `PASS` |

## Sprint 8

| ID | Estado | Depende de | Owner | Arquivos pretendidos | Gate mínimo | Evidência |
|---|---|---|---|---|---|---|
| S8-01 | `PASS` | S4, S6, S7 | `/root` | `OfflineFlowContract`; stores locais de notas/deck/mensagem; matriz e guard; evidência Sprint 8 | offline/reconnect matrix | evidência Sprint 8 — 19 fluxos, única fila remota em pós-jogo, descrição de deck persistida e 56/56 testes focados |
| S8-02 | `IN_PROGRESS` | S4, S6 | `/root` | `PerformanceService`; harness core Web/device; budgets p50/p95; evidência Sprint 8 | p50/p95 benchmark | evidência Sprint 8 — startup Web Chrome 150 PASS em 7 amostras (cold p50/p95 490/528 ms; warm 143/146 ms); faltam startup Android e matriz autenticada das oito superfícies Web+device, dependente da fixture descartável autorizada |
| S8-03 | `IN_PROGRESS` | S2, S4 | `/root` | `CachedCardImage`; cache/eviction; `app/integration_test/image_memory_runtime_test.dart`; evidência Sprint 8 | memory/image profile | evidência Sprint 8 — 180 imagens PASS no Samsung e Chrome, cache <32 MiB, RSS/repetição Android dentro do orçamento; falta incorporar ao perfil completo e SHA limpa |
| S8-04 | `IN_PROGRESS` | S4-04, S6 | `/root` | `server/routes/ai/generate/index.dart`; lifecycle de jobs; teste de timeout do provider; contrato API; evidência Sprint 8 | AI failure injection | evidência Sprint 8 — timeout falha fechado em HTTP 504 sem mock/cache e suíte focada 26/26 PASS; faltam cancelamento físico e matriz externa completa |
| S8-05 | `BLOCKED` | S4, S5, S6 | `/root` | observabilidade app/server; request ID; redaction; health/readiness; evidência Sprint 8 | Sentry/request-id proof | bloqueado até existir SHA limpa publicada e ambiente Sentry para provar evento e correlação app→API→erro da mesma revisão |
| S8-06 | `BLOCKED` | S7-05 | `/root` | serviço/harness FCM; artefato Android final; evidência Sprint 8 | FCM device proof | bloqueado até existir APK assinado exato da SHA congelada e credenciais FCM para foreground/background/tap |
| S8-07 | `BLOCKED` | S1-03 | `/root` | scripts/contratos de backup off-site; restore isolado; evidência Sprint 8 | off-site restore proof | bloqueado por destino/chave e autorização específica; falta backup fresco, checksum, restore e RPO/RTO |
| S8-08 | `BLOCKED` | S1, S8-05 | `/root` | dependency audit; secret scan; SBOM/OSV; auth/runtime policy; evidência Sprint 8 | security/SBOM/OSV | evidência Sprint 8 — `deps` e secret scan verdes; bloqueado por S8-05, SBOM/OSV do artefato congelado e rejeição de token antigo pós-deploy |
| S8-09 | `PASS` | S8-01 | `/root` | contrato consumido por erros de rede; nomenclatura cached-only; guard de claims/exceções cruas | offline contract guard | evidência Sprint 8 — claims governados, scanner/erros centralizados e guard 6/6 |

## Sprint 9

| ID | Estado | Depende de | Owner | Arquivos pretendidos | Gate mínimo | Evidência |
|---|---|---|---|---|---|---|
| S9-01 | `IMPLEMENTED_UNPROVEN` | S8 | `/root` | manifestos/índices de retenção; 23 conteúdos canônicos; auditor e testes | consumer/retention inventory | evidência Sprint 9 — 942 fontes classificadas, 0 não governadas; falta revisão final/commit atômico e S8 continua aberta |
| S9-02 | `IMPLEMENTED_UNPROVEN` | S9-01 | `/root` | `docs/CONTEXTO_PRODUTO_ATUAL.md`; plano/tracker; referências históricas/correntes | status/link consistency | evidência Sprint 9 — contexto corrente e project logic sincronizados; falta auditoria final de links após o diff congelado |
| S9-03 | `IMPLEMENTED_UNPROVEN` | S9-01 | `/root` | contratos/índices XMage; auditor de retenção; conteúdo deduplicado | canonical-auditor regression | evidência Sprint 9 — 23/23 canônicos selados e 16 testes PASS; falta disposição final dos contratos gigantes restantes |
| S9-04 | `IMPLEMENTED_UNPROVEN` | S9-01 | `/root` | rotas/imports sem consumidor; compatibility routes; source reachability; gates | route/import consumers + gates | evidência Sprint 9 — `deps`, `server-target`, `full` e E2E determinístico sem falhas após a regeneração; falta repetir na identidade limpa congelada |
| S9-05 | `IMPLEMENTED_UNPROVEN` | S9-01 | `/root` | duplicatas/efêmeros; manifestos de recuperação; gate de retenção | `quality_gate.sh report-retention` | evidência Sprint 9 — 12/12 checks, 16/16 testes, 0 duplicatas/resíduos; falta rastrear índices+canônicos+deleções no mesmo commit |
| S9-06 | `IMPLEMENTED_UNPROVEN` | S9-02–S9-05 | `/root` | documentação operacional; links; secret scan; project logic | docs/link/secret audit | evidência Sprint 9 — secret scan, project logic e gate local completo verdes; faltam links e diff final congelado |

## Sprint 10

| ID | Estado | Depende de | Owner | Arquivos pretendidos | Gate mínimo | Evidência |
|---|---|---|---|---|---|---|
| S10-01 | `IMPLEMENTED_UNPROVEN` | S0–S9 | `/root` | plano/tracker; flags/rotas/manifesto release; matriz de acessibilidade | clean SHA/scope manifest | escopo fixado em Web+Android, scanner inacessível e iOS/VoiceOver `DEFERRED_BY_SCOPE`; checkout dirty/S9 aberta impedem congelamento |
| S10-02 | `IMPLEMENTED_UNPROVEN` | S10-01 | `/root` | scripts/gates locais; testes release/readiness; summary final | deterministic gates + summary | `full` local PASS (backend 1736, Flutter 1157 + 1 skip, Web, Patrol e schema 51); `ai-eval`, `ai-bridge`, Battle 2× e `web` PASS; E2E determinístico `PARTIAL` com 10 PASS, 9 skips guardados e 0 falha/bloqueio; faltam SHA limpa e revisão do `engine-delta` (`review_required`: 316 cartas/328 fixtures) |
| S10-03 | `BLOCKED` | S10-02 | `/root` | migrations 038–051; deploy/readiness; backup/pre/post/rollback | backup/pre/apply/post/rollback | schema PostgreSQL descartável passou 51 migrations e readiness 11/11; live bloqueado por S10-02, backup fresco e autorização específica |
| S10-04 | `TODO` | S10-03 | — | — | guarded PG/E2E + summary PASS | — |
| S10-05 | `TODO` | S10-04 | — | — | Web authenticated E2E | — |
| S10-06 | `TODO` | S10-04 | — | — | Android physical E2E | — |
| S10-07 | `TODO` | S10-05, S10-06 | — | — | visual/a11y final | — |
| S10-08 | `TODO` | S10-04 | — | — | two-client convergence | — |
| S10-09 | `TODO` | S10-05, S10-06 | — | — | failure/recovery matrix | — |
| S10-10 | `TODO` | S10-05–S10-09 | — | — | cleanup/retention/final diff | — |
| S10-11 | `TODO` | S10-10 | — | — | signed GO/NO-GO | — |
