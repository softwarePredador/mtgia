# Auditoria — Grupo "Mapas técnicos: API, superfície de UI, sistema gerado"

Data: 2026-09-22 · Repo: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia` · HEAD `d15beb05b`
(branch `codex/free-beta-release-candidate-2026-07-17`). Somente leitura no repositório; nada foi
executado além de `git`, `grep`, `find`, `python3` sobre JSON e o script de digest de UI
(`scripts/manaloom_ui_source_digest.sh`, que só escreve em um `mktemp -d` apontado para o scratchpad).

Árvore de trabalho no momento da auditoria: `M docs/generated/CURRENT_SYSTEM.md`,
`M docs/generated/TASK_REGISTRY.json`, `M docs/generated/openapi.generated.json`,
`M project_logic_manifest.json`, `M server/routes/community/marketplace/index.dart`,
`?? server/test/community_marketplace_privacy_contract_test.dart`, `?? docs/flows/`, `?? docs/design/`,
`?? docs/PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md`.

Estado de ciclo de vida de cada documento (fonte: `docs/project_logic_contracts.json`,
chaves `canonical_documents` e `documentation_lifecycle`):

| Documento | Canônico? | Estado de lifecycle |
|---|---|---|
| `server/doc/API_CONTRACTS_AND_DATA_MAP.md` | sim (36 canônicos) | `current_contract` (default canônico) |
| `app/doc/UI_TEST_SURFACE_MAP.md` | sim | `current_contract` |
| `docs/generated/CURRENT_SYSTEM.md` | não | `generated_snapshot` (regra de prefixo `docs/generated/`) |
| `docs/LAYOUT_TEST_MAP.md` | não | `supporting_reference_non_authoritative` (default; sem override) |
| `app/integration_test/README.md` | não | `supporting_reference_non_authoritative` (default) |

---

## 1. Tabela-resumo

| Documento | Veredito | Afirmações verificadas | Erradas / defasadas | Ação |
|---|---|---:|---:|---|
| `server/doc/API_CONTRACTS_AND_DATA_MAP.md` | **CORRIGIR** | 78 | 6 (3 DEFASADAS, 1 ERRADA por omissão estrutural, 2 CONTRADIZ) | Acrescentar 8 rotas ausentes (6 `/auth/*`, `GET /capabilities`, `GET /`); acrescentar coluna `Capability` e marcação explícita "anônimo"; normalizar a coluna Status ao vocabulário fechado que o próprio doc declara; corrigir 3 linhas defasadas (timeouts de job ×2, readiness "até migração 056"). |
| `app/doc/UI_TEST_SURFACE_MAP.md` | **CORRIGIR** | 61 | 11 (8 DEFASADAS, 1 ERRADA, 2 incompletas) | Corrigir 7 keys que não existem no código, matriz de viewports 16→18, plataforma Android física→emulador, contagem de PNGs, digest hard-coded; completar a lista de rotas não ativas. |
| `docs/generated/CURRENT_SYSTEM.md` | **MANTER** (com 2 ajustes no gerador, não no arquivo) | 26 | 0 falsas; 2 números enganosos sem quebra (`tests`, `scripts_and_jobs`) | Não editar à mão. Corrigir o gerador para imprimir a quebra por lane e para rotular "Estado declarado" como escopo de contrato, não estado de capability. Commitar a regeneração junto com o fix do marketplace. |
| `docs/generated/openapi.generated.json` (irmão, citado no FOCO) | **CORRIGIR (gerador)** | 14 paths conferidos | 9 paths com `bearerAuth` falso | Corrigir `tools/project_logic/lib/project_logic_generator.dart:3642-3680` para derivar `security` da presença de `authMiddleware` na cadeia de `_middleware.dart`, não da omissão em `public_api_paths`. |
| `docs/LAYOUT_TEST_MAP.md` | **MARCAR_HISTORICO** | 24 | 13 DEFASADAS (54%) | Inserir banner de lifecycle; não corrigir o corpo (é fotografia de 2026-05-30 referenciada por `docs/hermes-analysis/AUDIT_REPORT_2026-05-30.md` e por `docs/design/visual-audit-2026-09-21/`). |
| `app/integration_test/README.md` | **MANTER** (1 correção pontual) | 19 | 1 ERRADA (referência incompleta a `test/README.md`) | Listar as 5 variáveis `MANALOOM_RUN_*_E2E` ou apontar para `scripts/manaloom_e2e_suite.sh:85-91`. |

Divergências já conhecidas que este grupo **confirma** (não redescobre): (2) 46 `GoRoute` — confirmado por
contagem (`grep -c 'GoRoute(' app/lib/main.dart` = 46) e pela reexecução dos regex do guard
`app/test/ui/ui_surface_inventory_test.dart:153-172` sobre `app/lib` (266 superfícies, batendo
com `expected_totals`); (6) 29 capabilities, 0 `allowed` (`server/config/release_capabilities.json`);
(5) `/import`, `/decks/generate` etc. como entrypoints do contrato — fora do meu grupo, não reaudito.
O OpenAPI mentir sobre `bearerAuth` (achado A20 de `docs/flows/card_catalog.md`) foi **reconferido
por mim** e ampliado: além de `/cards*`, `/rules`, também `/market/movers`, `/market/card/{cardId}` e
`/capabilities` estão marcados `bearerAuth` sem nenhum `authMiddleware` na cadeia.

---

## 2. `server/doc/API_CONTRACTS_AND_DATA_MAP.md` — veredito CORRIGIR

**O que está certo e foi conferido** (resumo; detalhe na §7): 141/141 arquivos de teste citados
existem; 227/228 caminhos de repositório citados existem (o único ausente,
`server/bin/backfill_missing_scryfall_cards.dart`, é declarado pelo próprio doc como removido em
`8cab6400b` — commit confirmado); 8/8 SHAs de deploy citados existem no repositório; limites de
paginação, TTLs de cache, códigos de status de billing, timeouts de `/ai/simulate` e Battle jobs,
política de senha, constantes de otimização (`v20`, `floors_v3`, `decision_contract_v2`, pisos de
terreno 34/55 e 24/36, token de apply 24 h), migrações citadas (022, 023, 038, 039, 040, 045–049,
053–058) — todos batem com o código.

**Cobertura de rotas:** o doc tem 137 linhas de contrato que cobrem **112 dos 120 arquivos de rota**
de `server/routes` mais o alias `/community/decks/following`. O guard
`server/test/api_contracts_data_map_guard_test.dart` só protege 17 rotas nomeadas (linhas 14-27,
44-49); **não há gate de completude** contra `server/routes`.

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
|---|---|---|---|---|---|---|
| 3, 15 (e ausência em todo o doc) | O doc é o mapa dos contratos app-facing e "when adding a route, add a contract row here" | **ERRADO (omissão estrutural)** | `grep -c` de `change-password`, `forgot-password`, `resend-verification`, `reset-password`, `revoke-sessions`, `verify-email`, `/capabilities`, `routes/index.dart` no doc = **0** para todos. Os 8 arquivos existem: `server/routes/auth/{change-password,forgot-password,resend-verification,reset-password,revoke-sessions,verify-email}.dart`, `server/routes/capabilities/index.dart`, `server/routes/index.dart`. Todos os 8 estão no allowlist do plano de controle (`server/lib/release_capability_policy.dart:586-622`) e são consumidos: `app/lib/features/auth/providers/auth_provider.dart:348,355` (change-password, revoke-sessions), `app/lib/core/config/release_capabilities.dart:251,281` (`/capabilities`). | 8 rotas nunca tiveram linha. Entre elas está **`GET /capabilities`, o endpoint que decide toda a Free Beta** no app, e as 6 rotas de auth que, junto com `/auth/login` e `/auth/me`, são **a única jornada alcançável hoje** (`docs/flows/README.md:57-59`). | **corrigir** | Inserir na seção "Auth and Current User": ver bloco "Linhas prontas" abaixo desta tabela. |
| 25 | "Route status vocabulary: `stable` / `experimental` / `internal` / `deprecated` / `not proven`" (vocabulário fechado) | **CONTRADIZ (interno)** | `awk` sobre a coluna Status das 137 linhas: **26 valores distintos** (`stable` 65, `stable/beta` 14, `experimental` 13, `internal` 6, `additive/experimental` 5, `stable/experimental` 3, `stable/additive sync` 3, `beta/stable phase 1` 2, `beta-disabled` 2, `active/beta` 2, `implemented_guarded` 1, `experimental/capability-default-off` 1, …). | O vocabulário declarado não é seguido; `capability OFF na Free Beta` aparece embutido no Status de 4 linhas, misturando eixos que a linha 26-30 manda separar. | **corrigir** | Normalizar Status aos 5 valores e mover o eixo de release para uma coluna nova `Capability (server)` preenchida a partir de `requiredCapabilityForRequest` em `server/lib/release_capability_policy.dart` (distribuição já levantada em `docs/flows/_coerencia_transversal.md` §3.2). |
| 19 + 137 linhas | "protected routes are behind middleware" e, por linha, "Auth required" em 78 linhas; **nenhuma linha diz "anônimo"** | **CONTRADIZ_OUTRO_DOC** (com `docs/generated/openapi.generated.json`) e omissão material | Rotas **sem** `authMiddleware` em nenhum `_middleware.dart` da cadeia (calculado subindo diretórios a partir de cada handler): `/cards`, `/cards/printings`, `/cards/resolve`, `/cards/resolve/batch`, `/cards/:id/rulings`, `/sets`, `/rules`, `/market/movers`, `/market/card/:cardId`, `/capabilities`, `/reports/:id`, `/community/**` (auth opcional no handler — `server/routes/community/_middleware.dart:5-9`). O doc **não marca** nenhuma dessas como anônima; para `GET /cards/printings?sync=true` (linha 127) diz "write-capable", mas não que é **anônima e escreve em `cards`/`sets`** — achado nº 1 de `docs/flows/README.md:129`. Enquanto isso o OpenAPI gerado diz `bearerAuth` para `/cards*`, `/rules`, `/market/*`, `/capabilities` (conferido com `python3` sobre `docs/generated/openapi.generated.json`). | O eixo "auth" existe no doc só por presença/ausência da palavra "Auth" na coluna de request — não é verificável mecanicamente e deixa invisível a superfície anônima que escreve no banco. | **corrigir** | Acrescentar coluna `Auth` com valores fechados `bearer` / `anonymous` / `anonymous+optional-bearer` / `ops-key-or-admin`; na linha 127 escrever: "**Anônima.** `sync=true` executa até 30 `INSERT … ON CONFLICT DO UPDATE` em `cards` e `INSERT … ON CONFLICT DO NOTHING` em `sets` sem `Authorization` (`server/routes/cards/printings/index.dart:309-484`; não existe `server/routes/cards/_middleware.dart`). Enquanto `catalog_private=OFF` a rota responde 404 antes do handler." |
| 222 | `GET /ai/optimize/jobs/:id`: "a nonterminal job without progress for **six minutes** is failed explicitly" (timer de inatividade) | **DEFASADO** | `server/lib/ai/optimize_job.dart:25` `executionTimeout = Duration(minutes: 6)` medido de `created_at`; o próprio doc, linhas 305-307, diz "total deadlines measured from `created_at` … not inactivity/stall timers" e "supersedes the narrower status descriptions in the table rows above". | Prazo **total** de 6 min desde `created_at`, não "sem progresso por 6 min". | **corrigir** | "The job has a total deadline of six minutes measured from `created_at` (`OptimizeJobStore.executionTimeout`); a nonterminal job past that deadline is failed explicitly so a process restart does not leave endless polling." |
| 225 | `GET /ai/generate/jobs/:id`: "A nonterminal job without progress for **four minutes** is failed explicitly" | **ERRADO** (nunca 4 min; hoje 3 min totais) | `server/lib/ai_generate_job.dart:14` `executionTimeout = Duration(minutes: 3)`; `grep -rn 'minutes: 4'` em `server/lib` e `server/routes` = 0; linhas 305-306 do próprio doc dizem "three minutes for Generate". | Prazo total de 3 min desde `created_at`. | **corrigir** | "The job has a total deadline of three minutes measured from `created_at` (`AiGenerateJobStore.executionTimeout`); a nonterminal job past that deadline is failed explicitly." |
| 461 | `GET /health/ready`: "release/deck/AI-job/collection schema checks **through migration 056**" | **DEFASADO** desde `e6737c53b` (2026-08-10) | `server/lib/health_readiness_support.dart:133-134` lista `'057': 'expand_battle_job_async_timeout'`, `'058': 'snapshot_trade_item_identity'`; `:173` `= '058' AS latest_migration_ready`; `:648,661` `'latest_migration': '058'`. A linha 461 foi reescrita em `f6f791098` (2026-09-18) já defasada. | Readiness verifica até a migração **058** (a última registrada em `server/bin/migrate.dart`, 58 migrações). | **corrigir** | "…release/deck/AI-job/collection/battle/trade schema checks through migration **058** (`latest_migration_ready`), …" |

**Linhas prontas para as 8 rotas ausentes** (todas plano de controle; nenhuma exige capability;
formato da tabela "Auth and Current User"):

```
| `POST /auth/forgot-password` | stable | `auth_provider.dart`, `ForgotPasswordScreen` | `server/routes/auth/forgot-password.dart`, `server/lib/password_reset_delivery_service.dart`, `server/lib/account_email_delivery_transport.dart` | Body: `email`. Anônima; rate-limit de credencial em `server/routes/auth/_middleware.dart`. | Resposta neutra (não revela existência da conta); envio por Resend ou webhook configurado. | Nenhum. | `users`, tokens de reset. | DB + egress de e-mail transacional. | `auth_runtime_policy_test.dart`, `account_email_delivery_transport_test.dart`. | Plano de controle (`release_capability_policy.dart:586-622`). Nunca ecoar token. |
| `POST /auth/reset-password` | stable | `ResetPasswordScreen` via deep link `/reset-password?token=` | `server/routes/auth/reset-password.dart` | Body: `token`, `new_password` (política 12–256, `password_policy.dart:4-5`). Anônima. | Sessão/`auth_version` rotacionados; JWTs anteriores invalidados. | Nenhum. | `users`. | DB. | `password_policy_test.dart`, `auth_token_rotation_live_test.dart`. | Plano de controle. Não existe deep link de SO (AndroidManifest sem scheme); o link só resolve dentro do roteador. |
| `POST /auth/verify-email` | stable | `VerifyEmailScreen` | `server/routes/auth/verify-email.dart` | Body: `token`. Anônima. | `email_verified=true`. | Nenhum. | `users`. | DB. | `email_verification_contract_test.dart`, `email_verification_live_test.dart`. | Plano de controle. Mutação social/binder/trade exige e-mail verificado (`verified_email_middleware.dart:38-47`). |
| `POST /auth/resend-verification` | stable | `VerifyEmailScreen` / perfil | `server/routes/auth/resend-verification.dart`, `server/lib/email_verification_delivery_service.dart` | `Authorization: Bearer` lido no handler (`:18`); sem body. | Resposta neutra; reenvio por transporte de e-mail. | Nenhum. | `users`. | DB + egress de e-mail. | `email_verification_contract_test.dart`. | Plano de controle. |
| `POST /auth/change-password` | stable | `auth_provider.dart:348` (`_rotateAuthenticatedSession`) | `server/routes/auth/change-password.dart`, `server/lib/auth_service.dart` | Bearer no handler (`:38`); body `current_password`, `new_password`. | `token` novo + `user{id,username,email}` (só 3 campos — `auth_service.dart:778-781`; o app sobrescreve o usuário completo, achado `auth_session.md` A1). | Nenhum. | `users.auth_version`. | DB. | `account_security_live_test.dart`, `auth_token_rotation_live_test.dart`. | Plano de controle. 401 `invalid_password` **não** encerra a sessão no app (`api_client.dart:103-105`). |
| `POST /auth/revoke-sessions` | stable | `auth_provider.dart:355` | `server/routes/auth/revoke-sessions.dart` | Bearer no handler (`:43`); body `current_password`. | `token` novo + `user{id,username,email}`. | Nenhum. | `users.auth_version`. | DB. | idem. | Plano de controle. Mesmo truncamento de `user` da linha anterior. |
| `GET /capabilities` | stable | `app/lib/core/config/release_capabilities.dart:251,281` (`ReleaseCapabilitiesProvider.refresh`) | `server/routes/capabilities/index.dart`, `server/lib/release_capability_policy.dart` | Anônima; só GET (outros métodos 405). | 200 `{schema_version,policy_version,product,release_channel,offer_mode,implementation_status,live_verified_as_of,policy_digest_sha256,configuration_status,capabilities{29 chaves}}` (`toPublicJson`, `release_capability_policy.dart:198-211`); 503 quando a política é inválida. `Cache-Control: no-store`. | Nenhum. | `server/config/release_capabilities.json` (ou arquivo isolado sob dupla confirmação, `:7-13,205-230`). | Arquivo de política em memória. | `release_capability_policy_test.dart`, `root_liveness_contract_test.dart`, app `release_capabilities_test.dart`. | Plano de controle. O app exige **exatamente** as 29 chaves; sobra ou falta derruba o snapshot para `denied()` (`release_capabilities.dart:119-125`). |
| `GET /` | internal | ops/smoke | `server/routes/index.dart` | Anônima. | Identidade do produto/liveness raiz. | Nenhum. | Nenhum. | Processo. | `root_product_identity_test.dart`, `root_liveness_contract_test.dart`. | Plano de controle. |
```

---

## 3. `app/doc/UI_TEST_SURFACE_MAP.md` — veredito CORRIGIR

**O que está certo e foi conferido:** contagem do inventário (linhas 33-42) reproduzida com os
regex do guard sobre `app/lib`: `go_route` 46, `shell_route` 1, `material_page_route` 7, `dialog` 51,
`bottom_sheet` 24, `menu` 9, `tabs` 10, `navigation` 2, `transient` 116 = **266** — idêntico a
`expected_totals` de `app/test/ui/fixtures/ui_surface_inventory.json`; 18 domínios e 15 estados
(`ui_state_matrix.json`); 7 cenários (`ui_navigation_resume_matrix.json`); 54 checkpoints e 4
plataformas (`ui_authenticated_visual_matrix.json`); as 22 linhas UX-PACK-08 batem anchor/teste
com `ui_live_evidence_policy.json` (`required_checkpoints: 22`, `required_profiles: 3` → 66 PNGs);
`overall_ui_proof_claimed: false` (`docs/qa/ui-live/current/play-vs-ai-web-real/visual-review.json:84`);
as 13 keys de Battle/Jogar contra IA existem em `app/lib`; as 8 funções do helper existem em
`app/integration_test/runtime_test_helpers.dart:31-187`; os 13 harnesses e 7 scripts/arquivos
citados existem; toolchain `flutter-3.44.6` existe; subcomandos `ui-audit`, `ui-proof`,
`patrol-smoke`, `performance`, `web-image-memory`, `e2e`, `battle`, `battle-lab` existem em
`scripts/quality_gate.sh:460-539`. Dos 311 tokens de key citados, **304 resolvem** para uma key
literal ou dinâmica em `app/lib`; os 7 que não resolvem estão abaixo.

**Cobertura de telas:** o mapa de keys por tela nomeia 23 dos 43 `*_screen.dart`. Os 20 sem
nenhuma linha de key (classe ou arquivo ausentes do doc): `forgot_password`, `reset_password`,
`splash`, `verify_email`, `battle_coach`, `battle_live_spectator`, `battle_replays`,
`binder_import`, `latest_set_collection`, `checkout`, `legal`, `plan`, `upgrade`,
`community_deck_detail`, `home`, `lotus_life_counter`, `post_game_notes`, `card_scanner`,
`user_profile`, `trade_matches`. O doc não afirma cobrir todas (delega ao JSON, linha 23-27), então
não é afirmação falsa — mas é a lacuna que impede "100% de noção" a partir deste arquivo.

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
|---|---|---|---|---|---|---|
| 55-57 | "O Scanner permanece explicitamente deferido e `/market` é apenas compatibilidade … nenhum deles é contabilizado como tela ativa própria" | **DEFASADO** (incompleto desde `f6f791098`, 2026-09-18) | `ui_surface_inventory.json` `route_surfaces`: 38 `active`, **3** `deferred_by_scope` (`/decks/:id/scan`, `/decks/:id/play-vs-ai`, `/decks/:id/play-vs-ai/:sessionId`), **5** `compatibility_redirect` (`/decks/:id/battle-coach`, `/decks/:id/battle-coach/:sessionId`, `/market`, `/marketplace`, `/quotes`). `git log -S'route.deck_play_vs_ai'` → `f6f791098`. | Jogar contra IA (2 rotas) também está `deferred_by_scope`; há 5 redirects, não 1. | **corrigir** | "38 rotas são `active`; 3 são `deferred_by_scope` (Scanner `/decks/:id/scan` e as duas rotas de Jogar contra IA `/decks/:id/play-vs-ai[/:sessionId]`, enquanto `battle_coach` estiver OFF); 5 são `compatibility_redirect` (`/market`, `/marketplace`, `/quotes` e os dois aliases `battle-coach`). Nenhuma das 8 conta como tela ativa própria." |
| 224-228 | "`ui_viewport_matrix.json` declara **16 casos** canônicos: mobile 320×568, 390×844 e 412×915; tablet …" | **DEFASADO** desde `6baab7bdb` (2026-07-28) | `python3` sobre o fixture: **18** viewports; os dois a mais são `mobile-reference-landscape` 844×390 e `mobile-large-landscape` 915×412. Linha escrita em `776b9e25d` (2026-07-23). | 18 casos, incluindo mobile landscape. | **corrigir** | "declara 18 casos canônicos: mobile 320×568, 390×844 e 412×915 e seus landscapes 844×390 e 915×412; tablet 768×1024 e 1024×768; boundaries 599/600, 839/840, 1199/1200 e 1599/1600; desktop 1280×900, 1440×900 e 1920×1080." |
| 333-338 | Tabela de plataformas: 4ª linha "**Android físico Samsung SM-A135M** \| 1080×2408; Life Counter 2408×1080 \| 54" | **DEFASADO** desde `35370ed89` (2026-07-31) | `ui_authenticated_visual_matrix.json` `platforms`: `web_mobile` 390×844, `web_desktop` 1440×900, `web_wide` 1920×1080, **`android_emulator` 411×914**; `grep -c A135M` no fixture = 0; `visual_gate.required_profile_counts = {web_mobile:54, web_desktop:53, web_wide:53, android_emulator:54}`; `docs/qa/ui-live/latest.json` `release_checks.android_physical_p0_matrix = "stale_not_claimed"`. | O 4º perfil exigido é o **emulador** Android API 34 (411×914). Android físico é evidência separada, hoje `stale_not_claimed`. | **corrigir** | "\| Android emulador `ManaLoom_API34` \| 411×914 \| 54 \|" e nota: "Android físico (SM-A135M) não faz parte do gate de baseline; é item de release separado, hoje `stale_not_claimed` em `docs/qa/ui-live/latest.json`." |
| 340 | "Os **214 PNGs aprovados** vivem em `app/test/ui/goldens/runtime`" | **DEFASADO / impreciso** | `find … -name '*.png' \| wc -l` = **322** em 6 diretórios: `web_mobile` 54, `web_desktop` 53, `web_wide` 53, `android_emulator` 54 (= 214 exigidos) **+ `android/` 54 (último commit `61583ccc6`, 2026-07-30) + `android_physical/` 54 (`fd0397a5a`, 2026-08-24)**, ambos rastreados pelo git e fora de `required_profile_counts`. | 214 são os PNGs que o gate compara; 108 são baselines órfãos versionados. | **corrigir** (+ decisão de limpeza, fora deste doc) | "O gate compara 214 PNGs (54+53+53+54) em quatro perfis. Os diretórios `android/` e `android_physical/` (54 cada) são baselines históricos fora do gate; remover ou mover para `docs/archive/` exige decisão registrada." |
| 363-367 | "A execução vinculada ao digest `c78b0b12…` é histórica … `docs/qa/ui-live/latest.json` só volta a aprovar após nova captura" | **DEFASADO** | `grep -rl c78b0b12` em `docs`/`app/test` = **0** (o digest não aparece em lugar nenhum). A linha foi escrita em `f6f791098` (2026-09-18), o **mesmo commit** que gravou `latest.json` com `status: PASS`, `source_digest: 865e6041…`. Hoje `scripts/manaloom_ui_source_digest.sh` devolve **`8bba809c…`**; entre `f6f791098` e HEAD mudaram 10 arquivos do escopo do digest (`ui_surface_inventory.json`, `scripts/lib/manaloom_chromedriver.sh`, 7 scripts `manaloom_*_visual_qa.sh`, `manaloom_p0_runtime_capture.sh`, `manaloom_ui_live_evidence_gate.sh`). `docs/PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md:19`: "22 dos 23 manifests … verdes no digest `8bba809c`". | O `latest.json` **está** em PASS, mas para um digest (`865e6041`) que já não é o das fontes (`8bba809c`); o gate `stale_evidence_fails_closed: true` o invalida. Hard-codar um digest no doc canônico o torna falso a cada commit. | **corrigir** | "A aprovação em `docs/qa/ui-live/latest.json` vale apenas para o `source_digest` que ela registra. Qualquer alteração nos caminhos listados em `scripts/manaloom_ui_source_digest.sh` muda o digest e invalida o PASS (fail-closed). Confira com `./scripts/manaloom_ui_source_digest.sh` e compare com `latest.json.source_digest`; não copie o digest para este documento." |
| 381 | Keys `onboarding-storage-notice` e `onboarding-storage-retry` | **ERRADO** (nunca existiram) | `git log -S'onboarding-storage-notice' -- app` = vazio; a única key com esse prefixo que já existiu foi `onboarding-storage-recovery` (placeholder, `e6737c53b`). Keys reais: `onboarding-persistence-error` (`app/lib/features/home/onboarding_core_flow_screen.dart:1374`) e `onboarding-persistence-retry` (`:1404`); é o que `test/features/home/onboarding_core_flow_screen_test.dart` usa. | As keys de falha/retry de persistência chamam-se `onboarding-persistence-error` / `onboarding-persistence-retry`. | **corrigir** | "- `onboarding-persistence-error` e `onboarding-persistence-retry`;" |
| 425 | `deck-details-optimize-button` | **DEFASADO** desde `e9f55a1d6` (2026-07-16) | `grep -rn deck-details-optimize-button app/lib` = 0. Keys atuais: `deck-optimize-button` (`app/lib/features/decks/widgets/deck_details_overview_tab.dart:1466`) e `deck-workshop-optimize-button` (`deck_workshop_tab.dart:222`). | O CTA de optimize vive na aba Visão Geral (`deck-optimize-button`) e na Oficina (`deck-workshop-optimize-button`). | **corrigir** | "\| Ações do deck \| `DeckDetailsScreen` \| `deck-optimize-button` (Visão Geral), `deck-workshop-optimize-button` (Oficina), `deck-details-menu`, `deck-details-menu-import-list` \| …" |
| 488-489 | `collection-open-sets-catalog`, `collection-open-latest-set` | **DEFASADO** desde `918851942` (2026-05-26) | `git log -S'collection-open-sets-catalog' -- app/lib` → adicionada `5059b5bb7` (2026-05-08), removida `918851942`. Hoje `collection_screen.dart:42-73` expõe `collection-tabs-*`, `collection-tab-binder/market/trades/sets`. `/collection/latest-set` continua rota sem entrada na UI (`_coerencia_transversal.md` §5.1). | Não há atalhos; o catálogo é a aba `collection-tab-sets`; latest-set só por URL. | **corrigir** | Substituir as duas linhas por: "\| Aba catálogo \| `CollectionScreen` \| `collection-tab-sets` \| Abre o catálogo de coleções embutido. \| Tap por key. \|" e remover a linha de "última edição" (sem superfície). |
| 495 | Retry `binder-list-retry-<have\|want>` | **DEFASADO** desde `f3c502db0` (2026-05-21) | `binder_screen.dart:558` `Key('binder-list-error-…')` com `onAction: _retryFetch` **sem `actionKey`**; única key de retry é `binder-pagination-retry-${listType}` (`:709`, paginação, não erro inicial). | O retry do erro inicial não tem key própria; só a paginação tem. | **corrigir** | "Falha de `/binder` não deve aparecer como lista vazia. \| `find.byKey` + ação de retry do `AppStatePanel` (sem key própria; `binder-pagination-retry-<have\|want>` cobre só paginação)." |
| 510 | Retry `marketplace-list-retry` | **DEFASADO** desde `f3c502db0` (2026-05-21) | `marketplace_screen.dart:256` `marketplace-list-error` com `onAction: _doSearch` sem `actionKey`; `:277` só `marketplace-empty-action`. | Não existe key de retry do erro; existe `marketplace-empty-action` no estado vazio. | **corrigir** | "\| `find.byKey` + ação de retry do `AppStatePanel` (sem key própria); vazio expõe `marketplace-empty-action`." |
| 29 | "Inventário corrente da beta Web + Android em **2026-08-25**" | CORRETO (números) / data envelhecida | Contagens conferem hoje; o fixture mudou em `f6f791098` (2026-09-18) sem alterar totais. | — | **corrigir** (só a data) | "Inventário corrente (guard verde em 2026-09-22; fixture alterado por último em `f6f791098`)". |

---

## 4. `docs/generated/CURRENT_SYSTEM.md` — veredito MANTER (ajustes no gerador)

Arquivo gerado (`> Gerado por scripts/manaloom_project_logic.sh --write. Não editar manualmente.`).
A versão na árvore de trabalho (digest `9d37547f…`, `tests` 1221, call edges 42731) reflete o fix não
commitado de `server/routes/community/marketplace/index.dart` + o teste não rastreado; a versão em HEAD
tem digest `556ba631…`, `tests` 1220. **Ambas são internamente coerentes com o manifesto de sua época**;
a da árvore deve ser commitada **junto** com o fix do marketplace, senão `--check` falha no próximo.

Todos os 25 números do "Inventário" batem com `project_logic_manifest.json.statistics` (mesmo digest).
Reconferidos de forma independente: `app_routes` 46 (grep em `main.dart`), `api_routes` 121 (120
arquivos + alias), `web_routes` 11 (`web-public/`: 8 páginas + `healthz`/`robots`/`sitemap`),
`migrations` 58 (`migrate.dart` 001–058), `tasks` 220, `flows` 8, `database_views` 6 (nomes
conferem com os citados no API map), 1221 caminhos de `tests` existem no disco.

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
|---|---|---|---|---|---|---|
| 36 | `tests` \| 1221 | **CORRETO mas enganoso** (sem quebra por lane) | Manifesto `tests[]`: `docs/hermes-analysis/manaloom-knowledge/scripts/test_*.py` **424**, `server/test` 401, `app/test` 237, `app/integration_test` 147, sidecar 4, `server/bin` 2, `tools/*` 4. O gerador inclui o diretório Hermes de propósito (`tools/project_logic/lib/project_logic_generator.dart:2385-2406`). O mesmo arquivo diz (linha 10) que Hermes é "never product source of truth". | 35% do número são scripts de laboratório Hermes, não testes do produto. Testes do produto ≈ 797. | **corrigir o gerador** (não o arquivo) | Imprimir `tests` com quebra: "1221 (server 401 · app 237 · integration 147 · hermes-lab 424 · outros 12)". |
| 34 | `scripts_and_jobs` \| 687 | **CORRETO mas enganoso** | Manifesto: `docs/hermes-analysis` **427**, `server/bin` 140, `app/tool` 9, `scripts/lib` 9, sidecar 8, `scripts/*` 94. | 62% do número são scripts Hermes sob `docs/`. | **corrigir o gerador** | Mesma quebra por raiz. |
| 46-55 | Tabela "Fluxos canônicos — Estado declarado": `active_release_scope` para Auth, Cartas, Deck, Life Counter | **NAO_VERIFICAVEL** como estado de release; correto como cópia do contrato | Copiado 1:1 de `docs/project_logic_contracts.json` `flows[].status`. Mas `docs/status/CURRENT_PRODUCT_DECISION.md:56-70` dá `release_capability = OFF/OFF_UNTIL_P0_RECEIPT` para todas essas áreas e as 29 capabilities estão `off`. Os valores `active_release_scope`, `active_guarded`, `active_requires_release_e2e`, `guarded_no_implicit_live_write` **não pertencem** ao vocabulário fechado de `implementation_status` (`release_capability_policy.dart:72-77`). | "Estado declarado" é o escopo que o contrato pretende para o fluxo, não o que está ligado. Lido sem o CURRENT_PRODUCT_DECISION, "active" induz erro. | **corrigir o gerador** | Renomear a coluna para "Escopo declarado no contrato (não é capability)" e acrescentar linha de rodapé: "Capabilities ligadas hoje: 0/29 (`server/config/release_capabilities.json`, `policy_version brewtact_free_beta_2026-08-13`). Fonte de prioridade: `docs/status/CURRENT_PRODUCT_DECISION.md`." |

**Irmão gerado citado no FOCO — `docs/generated/openapi.generated.json`:**

| Path | Afirmação do OpenAPI | Classificação | Evidência | Verdade | Ação |
|---|---|---|---|---|---|
| `/cards`, `/cards/printings`, `/cards/resolve`, `/cards/resolve/batch`, `/cards/{id}/rulings`, `/rules`, `/market/movers`, `/market/card/{cardId}`, `/capabilities` | `security: [bearerAuth]` | **ERRADO** | Não existe `server/routes/{cards,rules,market,capabilities}/_middleware.dart` (`find server/routes -name _middleware.dart` lista 16, nenhum desses); `server/routes/_middleware.dart:335-353` só lê o header para telemetria, não recusa. Regra do gerador: `if (!publicPaths.contains(apiPath)) 'security': […]` (`project_logic_generator.dart:3642-3645, 3677-3680`) — omissão em `public_api_paths` (`docs/project_logic_contracts.json`: só `/`, `/ready`, `/health*`, 6 `/auth/*`, `/sets`, `/reports/{id}`, `/billing/webhook`) vira "autenticada". | 9 paths anônimos aparecem como autenticados; `/sets` e `/reports/{id}` aparecem corretos só porque estão na lista. | **corrigir o gerador**: derivar `security` da cadeia real de `_middleware.dart` (presença de `authMiddleware`) e tratar `public_api_paths` como asserção a ser **verificada**, não como fonte. Enquanto isso, o artefato não pode ser usado por auditoria ou SDK. |

---

## 5. `docs/LAYOUT_TEST_MAP.md` — veredito MARCAR_HISTORICO

Fotografia datada ("Data: 2026-05-30", único commit `49b6b1e1d` do mesmo dia; nunca atualizada).
Referenciada por `docs/hermes-analysis/AUDIT_REPORT_2026-05-30.md` e por
`docs/design/visual-audit-2026-09-21/{README.md,audit.json}` (que a critica). Não é canônica. 13 de
24 afirmações verificáveis estão defasadas — inclusive 6 das 9 "lacunas conhecidas", três delas
fechadas **no mesmo dia** do documento. Marcar como histórico preserva o valor de evidência para o
relatório de auditoria de 2026-05-30; remover quebraria dois links de entrada. As seções S3-01…S3-08
de `app/doc/UI_TEST_SURFACE_MAP.md` e os fixtures `app/test/ui/fixtures/*.json` são a versão viva.

Banner a inserir logo abaixo do título:

```
> Lifecycle: `HISTORICAL_EVIDENCE · NO_MUTATION_AUTHORITY`.
> **Fotografia de 2026-05-30. Não descreve a suíte atual.** Três dos arquivos listados
> (`deck_card_overflow_test.dart`, `life_counter_clone_proof_test.dart`,
> `life_counter_screen_test.dart`) foram removidos em `d08985bca` (2026-07-01); seis das nove
> "lacunas conhecidas" já foram fechadas (`community_screen_responsive_test.dart`,
> `trade_detail_screen_overflow_test.dart`, `binder_screen_overflow_test.dart`,
> `lotus_life_counter_overflow_test.dart`, `chat_screen_test.dart`, matriz de viewports com 18
> casos e evidência autenticada em 4 plataformas). Para o mapa vivo use
> `app/doc/UI_TEST_SURFACE_MAP.md` (S3-01…S3-08) e `app/test/ui/fixtures/*.json`.
```

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação |
|---|---|---|---|---|---|
| 24, 32, 55, 59 | `deck_card_overflow_test.dart` (`DeckCard`, 5 viewports, 10 testes) | **DEFASADO** desde `d08985bca` (2026-07-01, "Audit and remove dead app surfaces") | `find app/test -name deck_card_overflow_test.dart` = vazio; `git log --diff-filter=D` → `d08985bca`. | Arquivo removido; a cobertura multi-viewport migrou para `deck_list_responsive_test.dart` e `ui_viewport_matrix_test.dart`. | marcar_historico |
| 43, 45, 70 | `life_counter_clone_proof_test.dart` com 5 goldens 590×1280 | **DEFASADO** desde `d08985bca` | idem. | Removido. | marcar_historico |
| 45 | "Total: 6 goldens em 2 arquivos" | **DEFASADO** | Hoje `matchesGoldenFile` em 2 arquivos (`home_screen_test.dart:903,1037,1080`; `deck_list_responsive_test.dart:462`) + `goldenTest` (alchemist) em `app/test/ui/manaloom_commercial_ui_audit_test.dart`; 12 PNGs de golden fora de `runtime` (4 `home_hero_*`, `deck_gallery_card_1880`, 7 em `ui/goldens/ci/`). | ≥12 goldens em ≥3 arquivos. | marcar_historico |
| 69 | `life_counter_screen_test.dart` (legacy) com ~28 keys | **DEFASADO** desde `d08985bca` | `find` vazio; `git log --diff-filter=D` → `d08985bca`. | Removido; o shell atual é testado por `lotus_life_counter_screen_test.dart` e `life_counter_route_test.dart`. | marcar_historico |
| 76 | "12+ native sheet tests" | CORRETO | `ls app/test/features/home \| grep -c life_counter_native_.*_sheet_test` = 13 (falta só `commander_damage`, conforme `_nao_coberto.md` §3.1a). | — | — |
| 126 | "DeckCard é o único widget com teste responsivo multi-viewport" | **DEFASADO** | 14 arquivos `*responsive*`/`*overflow*`/`*viewport*` em `app/test` (`binder_screen_overflow`, `card_detail_screen_responsive`, `collection_screen_responsive`, `commercial_screens_responsive`, `community_screen_responsive`, `deck_list_responsive`, `lotus_life_counter_overflow`, `post_game_notes_screen_responsive`, `user_profile_screen_responsive`, `trade_detail_screen_overflow`, `create_trade_screen_overflow`, `marketplace_screen_overflow`, `responsive_page_frame`, `ui_viewport_matrix`). | Cobertura responsiva é sistêmica (matriz de 18 viewports × 18 domínios). | marcar_historico |
| 127 | "Nenhum golden test para telas funcionais atuais" | **DEFASADO** | `app/test/ui/goldens/ci/`: `manaloom_auth_login`, `manaloom_auth_register`, `manaloom_commercial_beta_{plans,upgrade,checkout}`, `manaloom_commercial_ai_usage_states`, `manaloom_deck_analysis_summary` (último commit `fd0397a5a`, 2026-08-24). | Há goldens de auth, comercial e análise de deck. | marcar_historico |
| 128 | "Integration tests só usam 390x844" | **DEFASADO** | `ui_authenticated_visual_matrix.json` `platforms`: 390×844, 1440×900, 1920×1080, 411×914; `grep Size(` em `app/integration_test`: 21× `Size(390, 844)`, 1× `Size(412, 915)`; goldens `web_desktop`/`web_wide` versionados. | Web mobile/desktop/wide + Android emulador. | marcar_historico |
| 130 | "Life Counter Flutter shell sem teste de overflow" | **DEFASADO** desde `e113215f3` (2026-05-30, mesmo dia do doc) | `app/test/features/home/lotus_life_counter_overflow_test.dart`. | Existe. | marcar_historico |
| 131 | "community_screen (1729 linhas) sem teste de widget unitário" | **DEFASADO** desde `e9f55a1d6` (2026-07-16) | `app/test/features/community/screens/community_screen_responsive_test.dart`; arquivo hoje tem 1953 linhas. | Existe. | marcar_historico |
| 132 | "trade_detail_screen (1479 linhas) sem teste de layout dedicado" | **DEFASADO** desde `8ef05d99e` (2026-05-30) | `trade_detail_screen_overflow_test.dart`; 1769 linhas hoje. | Existe. | marcar_historico |
| 133 | "binder_screen (1628 linhas) sem teste de widget dedicado" | **DEFASADO** desde `df889a38f` (2026-05-30) | `binder_screen_overflow_test.dart` + `binder_screen_resilience_test.dart`; 2097 linhas hoje. | Existe. | marcar_historico |
| 134 | "chat_screen sem teste de widget; 3 falhas pré-existentes" | **DEFASADO** (teste) / **NAO_VERIFICAVEL** (falhas) | `app/test/features/messages/screens/chat_screen_test.dart` existe; não rodei `flutter test`. | Existe teste; estado verde/vermelho não verificado nesta auditoria. | marcar_historico |

---

## 6. `app/integration_test/README.md` — veredito MANTER

Último commit `075916b49` (2026-07-23). Conferido: `test_driver/integration_test.dart`,
`image_memory_runtime_test.dart`, `patrol_test/manaloom_patrol_smoke_test.dart`,
`ios/RunnerUITests/`, `test/README.md` existem; `MANALOOM_CHROMEDRIVER_BIN` continua sendo o
override (`scripts/lib/manaloom_chromedriver.sh:28-33`, após o pin de `b397f477b`);
`MANALOOM_RUN_PATROL_DEVICE_TESTS`/`MANALOOM_PATROL_DEVICE`/`MANALOOM_PATROL_WEB_HEADLESS` em
`scripts/manaloom_patrol_smoke.sh:33-51`; artefato `app/build/manaloom_web_image_memory.json`
(`scripts/manaloom_web_image_memory_profile.sh:14`); `app/ios/Podfile:34` `target 'RunnerUITests'`,
Pods `Pods-Runner-RunnerUITests` e `patrol` presentes; `app/test/**/failures/` ignorado
(`.gitignore:68`); subcomandos `ui-audit`, `performance`, `web-image-memory`, `patrol-smoke`, `e2e`
existem. "four distinct test lanes" com 5 cabeçalhos é imprecisão de redação (Web image memory é
sub-lane de runtime), não erro de fato.

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
|---|---|---|---|---|---|---|
| 93-94 | "live … layers are opt-in via the `MANALOOM_RUN_*_E2E` variables documented in `test/README.md`" | **ERRADO** (referência incompleta) | `app/test/README.md` cita só `MANALOOM_RUN_FLUTTER_RUNTIME_E2E` (`:95`); `scripts/manaloom_e2e_suite.sh:85-91` lê cinco: `MANALOOM_RUN_FLUTTER_RUNTIME_E2E`, `MANALOOM_RUN_SERVER_LIVE_E2E`, `MANALOOM_RUN_LIVE_PRODUCT_E2E`, `MANALOOM_RUN_MUTATING_RESOLUTION_E2E`, `MANALOOM_RUN_MUTATING_BATTLE_PRODUCT_E2E`. | Quatro das cinco variáveis não estão documentadas onde o README manda olhar. | **corrigir** | "…opt-in via `MANALOOM_RUN_FLUTTER_RUNTIME_E2E`, `MANALOOM_RUN_SERVER_LIVE_E2E`, `MANALOOM_RUN_LIVE_PRODUCT_E2E`, `MANALOOM_RUN_MUTATING_RESOLUTION_E2E` and `MANALOOM_RUN_MUTATING_BATTLE_PRODUCT_E2E` (read in `scripts/manaloom_e2e_suite.sh`); the guarded profile additionally requires the `MANALOOM_CONFIRM_*` phrases shown in `test/README.md`." |

---

## 7. Fatos confirmados (tabela de verdade — verificados na fonte primária hoje)

**Repositório e árvore**
1. HEAD `d15beb05b`; a árvore tem 5 arquivos modificados e 4 não rastreados (listados no cabeçalho). Nenhum arquivo de `app/lib`, `server/lib`, `server/config` mudou desde `d26f23a16`; o único código de produção alterado e não commitado é `server/routes/community/marketplace/index.dart` (`git status`).

**Servidor / API**
2. `server/routes` tem **120 arquivos de handler** e **16 `_middleware.dart`** (`find`). `docs/generated/openapi.generated.json` tem **121 paths** = 120 + alias `/community/decks/following` (`docs/project_logic_contracts.json` `api_route_aliases`, resolvido em `server/routes/community/decks/[id]/index.dart:17`).
3. `server/config/release_capabilities.json`: `policy_version brewtact_free_beta_2026-08-13`, **29 capabilities, 0 `allowed`, todas `release_capability: "off"`** (python3).
4. Negação de capability: `404 {"error":"capability_unavailable", capability, release_capability, policy_version, policy_digest_sha256, offer_mode}` com `Cache-Control: no-store` antes de PostgreSQL (`server/routes/_middleware.dart:105-144`); política inválida → 503 `capability_policy_invalid`; rota não classificada → 404 `capability_route_unclassified` (`server/lib/release_capability_policy.dart:172-193`).
5. Plano de controle: 29 pares exatos método+path (`release_capability_policy.dart:586-622`: `GET /`, `GET /capabilities`, `GET /ready`, `GET /health*` ×7, `POST /auth/{login,forgot-password,reset-password,change-password,resend-verification,revoke-sessions,verify-email}`, `GET /auth/me`, `GET/PATCH/DELETE /users/me`, `GET /users/me/{export,plan,blocks,activation-events}`, `POST /users/me/activation-events`, `DELETE /users/me/fcm-token`, `POST /content-reports`, `GET /moderation/reports`) mais regex para `/users/:id/follow`, `/community/decks/:id/reports`, `/content-reports/:id/appeals`, `/moderation/reports/:id`, `/reports/:id`.
6. Rotas **sem `authMiddleware` em nenhum ponto da cadeia** (calculado subindo diretórios): `/auth/*` (3 delas leem o bearer no handler: `change-password.dart:38`, `revoke-sessions.dart:43`, `resend-verification.dart:18`), `/billing/webhook`, `/capabilities`, `/cards/**` (5), `/sets`, `/rules`, `/market/**` (2), `/reports/:id`, `/health/**` e `/ready` (ops key/admin para metrics/dashboard/commercial/ai-history), `/moderation/**` (ops key), `/community/**` (auth opcional no handler, `community/_middleware.dart:5-9`, com `verifiedEmailForMutations()`).
7. `GET /capabilities` responde `toPublicJson()` (`release_capability_policy.dart:198-211`) com 200 ou 503 (`server/routes/capabilities/index.dart:16-22`); só GET (405 caso contrário).
8. `EndpointCache`: `/cards` 45 s (`server/routes/cards/index.dart:127`), `/sets` 60 s (`sets/index.dart:162`), `/ai/archetypes` e `/ai/generate` via `ai_generate_performance_support.dart`.
9. Limites: `/cards` default 50 max 200 (`cards/index.dart:44-46`); `/community/users` 20/50 (`:22`); `/community/decks` 20/50 (`:28`); comments 50/100; `/community/trade-matches` 40, clamp 1..100 (`community_engagement_service.dart:179-181`); `/community/marketplace` 20/100 (`:21`); `/rules` 20/100; `/trades` 20/50 (`trades/index.dart:815`); `/trades/:id/messages` 50/200; `/conversations` 20/50; battle-replays 30, clamp 1..100 (`:76-78`); annotations 50, clamp 1..100 (`:160`); `/ai/commander-reference` 40, clamp 5..200 (`:41`); `/binder/availability` ≤100 ids (`binder/[id]/index.dart:45`).
10. Senha: mínimo 12, máximo 256 (`server/lib/password_policy.dart:4-5`).
11. Billing: checkout 403 `beta_free_only`, webhook 410 `beta_free_only`, estáticos (`server/lib/billing/payment_provider.dart:8,22,39,53`).
12. `/ai/simulate` `timeout_ms` default e máximo 40000 (`server/lib/ai/battle_simulation_request_support.dart:74-76`); Battle jobs `timeout_ms` 1000/120000/180000 (`server/lib/battle/battle_job_contract.dart:7-9`).
13. Jobs de IA: deadline **total** Generate 3 min (`server/lib/ai_generate_job.dart:14`), Optimize 6 min (`server/lib/ai/optimize_job.dart:25`), TTL 30 min; polling limitado a 120 req/min (`server/lib/rate_limit_middleware.dart:167`).
14. Optimize: cache `v20` (`server/lib/ai/optimize_cache_support.dart:13`), `commander_functional_role_floors_v3` (`optimize_functional_role_support.dart:6`), `optimize_decision_contract_v2_2026-07-28` (`optimize_payload_support.dart:572`), pisos 34 (mín.)/42 (piso automático máx.)/55 (excesso severo) Commander e 24/30/36 Brawl (`server/lib/commander_mana_floor.dart:10-13,91-98`), token de apply com validade 24 h (`server/lib/ai/optimize_swap_integrity.dart:25`).
15. Migrações: **58** registradas em `server/bin/migrate.dart` (001–058; não há diretório `server/migrations`); nomes conferem com as citadas no API map (022 `create_card_identity_and_intelligence_views`, 023, 038 `add_privacy_and_post_game_sync_contracts`, 039, 040, 045, 046, 047, 048 `close_ai_job_lifecycle`, 049, 053, 054, 055, 056, 057, 058 `snapshot_trade_item_identity`). `/health/ready` exige `latest_migration = '058'` (`health_readiness_support.dart:173`).
16. `learning_reads` OFF → 404 no middleware raiz; ligada sem `MANALOOM_ENABLE_PROMOTED_LEARNED_DECK_READS=1` → 503 no handler (`server/routes/ai/commander-learning/index.dart:104`).
17. O guard `server/test/api_contracts_data_map_guard_test.dart` só assegura que 17 rotas nomeadas continuem no doc; não compara o doc com `server/routes`.

**App / superfície de UI**
18. `app/lib/main.dart`: **46 `GoRoute` + 1 `ShellRoute`**, 47 `path:` (o `/` aparece duas vezes: checagem boot-safe `:373` e rota `:441`). Reexecutando os regex do guard sobre `app/lib`: 7 `MaterialPageRoute`, 51 dialogs, 24 bottom sheets, 9 menus, 10 `TabBar`, 2 navegação, 116 `SnackBar` → **266**, idêntico a `expected_totals` (`ui_surface_inventory.json`), em 58 arquivos.
19. Escopo das 46 rotas no inventário: 38 `active`, 3 `deferred_by_scope` (`/decks/:id/scan`, `/decks/:id/play-vs-ai`, `/decks/:id/play-vs-ai/:sessionId`), 5 `compatibility_redirect` (`/market`, `/marketplace`, `/quotes`, `/decks/:id/battle-coach`, `/decks/:id/battle-coach/:sessionId`).
20. **43 arquivos `*_screen.dart`** em `app/lib` (1 é `lotus_life_counter_screen.dart`); `BattleLiveSpectatorScreen` não tem rota. O mapa de keys de `UI_TEST_SURFACE_MAP.md` nomeia 23 deles.
21. Fixtures em `app/test/ui/fixtures/`: `ui_state_matrix.json` 15 estados × 18 domínios; `ui_viewport_matrix.json` **18** viewports; `ui_navigation_resume_matrix.json` 7 cenários; `ui_authenticated_visual_matrix.json` 54 checkpoints × 4 plataformas (`web_mobile` 390×844, `web_desktop` 1440×900, `web_wide` 1920×1080, `android_emulator` 411×914), `baseline_files 214`, `maximum_changed_pixel_ratio 0.001`; `ui_live_evidence_policy.json` 10 superfícies, `critical_overlays_states` 22 checkpoints × 3 perfis; `ui_accessibility_matrix.json` 18 domínios, TalkBack `pending_physical`; `ui_keyboard_focus_matrix.json` `manual_web.status = pending` com 2 itens `remaining` (teclado Web nas rotas Battle; vincular manifesto Jogar contra IA ao digest corrente).
22. `app/test/ui/goldens/runtime`: **322 PNG** em 6 diretórios (`web_mobile` 54, `web_desktop` 53, `web_wide` 53, `android_emulator` 54, `android` 54, `android_physical` 54); o gate usa 214 (4 perfis); `android/` e `android_physical/` são baselines versionados fora do gate.
23. Digest de fontes de UI hoje: **`8bba809cb7617445ea8bde807643515ac716a08ef28a554164c3c17d0b090ba4`** (`scripts/manaloom_ui_source_digest.sh`). `docs/qa/ui-live/latest.json` (último commit `f6f791098`, 2026-09-18): `status: PASS`, `source_digest: 865e6041…`, `release_checks.overall_release: NO_GO_CAPABILITIES_OFF`, `android_physical_p0_matrix: stale_not_claimed`, `android_talkback_human`/`android_hardware_smoke`/`web_hardware_keyboard`: `pending`. **O PASS está vinculado a um digest que não é mais o das fontes** (fail-closed por `stale_evidence_fails_closed: true`); 10 arquivos do escopo mudaram depois (`ui_surface_inventory.json`, `scripts/lib/manaloom_chromedriver.sh`, 8 scripts de captura/gate).
24. `docs/qa/ui-live/current/play-vs-ai-web-real/visual-review.json:84` `overall_ui_proof_claimed: false`; o receipt `docs/qa/execution/2026-08-25/play-vs-ai-real-xmage-e2e.md` existe.
25. Keys de UI: 304 dos 311 tokens de key citados em `UI_TEST_SURFACE_MAP.md` resolvem em `app/lib` (literal ou dinâmica: `'create-trade-type-$…'` `:1404`, `'create-trade-add-item-$…'` `:1540`, `'optimize-intensity-$…'` `deck_optimize_sections.dart:447`, `'optimize-suggestion-$keyPrefix-$index'` `deck_optimize_sheet_widgets.dart:542,2137`); os 7 que não resolvem estão na §3. As 22 âncoras UX-PACK-08 batem com o fixture.
26. Toolchain `/Users/desenvolvimentomobile/.manaloom/toolchains/flutter-3.44.6/bin/flutter` existe. `scripts/quality_gate.sh` tem `quick`, `full`, `performance`, `web-image-memory`, `ui-audit`, `ui-proof`, `patrol-smoke`, `battle`, `battle-lab`, `e2e` (`:460-539`). `quality_gate.sh e2e` chama `scripts/manaloom_e2e_suite.sh --strict` (`:336-339`), que lê 5 variáveis `MANALOOM_RUN_*_E2E` (`:85-91`).
27. Testes de layout hoje: 14 arquivos responsive/overflow/viewport em `app/test`; 13 testes de folha nativa do contador; goldens `matchesGoldenFile` em `home_screen_test.dart` e `deck_list_responsive_test.dart` + `goldenTest` alchemist em `manaloom_commercial_ui_audit_test.dart`; 12 PNG de golden fora de `runtime` (7 em `ui/goldens/ci`). Removidos em `d08985bca` (2026-07-01): `deck_card_overflow_test.dart`, `life_counter_clone_proof_test.dart`, `life_counter_screen_test.dart`.

**Sistema gerado**
28. `project_logic_manifest.json` (árvore): digest `9d37547f…`; `statistics` = exatamente a tabela de `CURRENT_SYSTEM.md`; `tests` 1221 caminhos, **todos existem no disco**, dos quais 424 são `docs/hermes-analysis/manaloom-knowledge/scripts/test_*.py`; `scripts_and_jobs` 687, dos quais 427 sob `docs/hermes-analysis`; `web_routes` 11 (`/`, `/blog`, `/blog/{slug}`, `/healthz`, `/legal/{disclaimer,privacy,terms}`, `/pricing`, `/reports/{id}`, `/robots.txt`, `/sitemap.xml`); `database` 79 tabelas + 6 views (`binder_item_availability`, `card_identity_bridge`, `card_intelligence_snapshot`, `collection_availability_snapshot`, `commander_learning_snapshot`, `optimize_candidate_quality_summary`), `migration_count 58`, `latest_migration 058`; `api_routes[]` **não tem campo de auth** (121 entradas, `auth/security/public` = `None`).
29. `flows[].status` no contrato (`active_release_scope` ×4, `experimental_guarded`, `active_guarded`, `active_requires_release_e2e`, `guarded_no_implicit_live_write`) é copiado 1:1 para a coluna "Estado declarado"; esse vocabulário é distinto do `implementation_status` fechado (`contained_legacy`, `experimental_guarded`, `experimental_p0_open`, `implemented_guarded`, `implemented_p0_open`, `not_implemented` — `release_capability_policy.dart:72-77`).
30. `TASK_REGISTRY.json` (árvore): 220 tasks; status `TODO` 86, `BLOCKED_BY_P0` 77, `DEFERRED_BY_SCOPE` 33, `IN_PROGRESS_CONTAINED` 10, `IMPLEMENTED_LOCAL_PENDING_FULL_GATE` 7, `WAITING_EXTERNAL` 4, **`PASS` 3**. `BT-UX-PROOF-001` = `BLOCKED_BY_P0`; `BT-SCP-001` = `IN_PROGRESS_CONTAINED`.
31. `docs/generated/openapi.generated.json` marca `bearerAuth` em `/cards`, `/cards/printings`, `/cards/resolve`, `/cards/resolve/batch`, `/cards/{id}/rulings`, `/rules`, `/market/movers`, `/market/card/{cardId}`, `/capabilities` — todos anônimos no código; `/sets`, `/reports/{id}`, `/health`, `/`, `/auth/login` aparecem anônimos (estão em `public_api_paths`).

**Precedente de marcação histórica no projeto**
32. Formato de banner já usado em `d93867b68` (2026-09-18, "mark the six documents that assert things no longer true"): `> Lifecycle: \`HISTORICAL_EVIDENCE · NO_MUTATION_AUTHORITY\`.` seguido de blockquote com a data da fotografia e o ponteiro para a fonte viva (ex.: `server/doc/MANALOOM_CRONS_E_PENDENCIAS.md:3-13`). Os marcadores `HISTORICAL_EVIDENCE` e `NO_MUTATION_AUTHORITY` são os `historical_header_markers` do lifecycle (`docs/project_logic_contracts.json`).

---

## 8. Limites desta auditoria

- Nada de Flutter/Dart/servidor/emulador foi executado; "existe teste" nunca significa "passou".
- O API map tem 137 linhas de contrato com centenas de campos de resposta; conferi caminhos,
  testes, SHAs, limites, TTLs, códigos de status, constantes e migrações (78 afirmações), **não**
  cada campo de payload. As linhas de `/ai/optimize` e `/ai/generate` (linhas 221 e 224, ~1.500
  palavras cada) foram conferidas só nos pontos estruturais listados na §7.
- O estado all-OFF descreve o repositório, não o que está implantado
  (`docs/status/CURRENT_PRODUCT_DECISION.md:30-31`).
