# Auditoria documental — Grupo: Registros de decisão de arquitetura (`docs/adr/*.md`)

- Data da auditoria: 2026-09-22. HEAD: `d15beb05b` (branch `codex/free-beta-release-candidate-2026-07-17`).
- Método: leitura integral dos 15 arquivos; cada afirmação verificável conferida no código, no registry, no git log ou no arquivo em disco. Nenhum teste, build, servidor ou emulador foi executado. Somente leitura no repositório.
- Ciclo de vida: 13 dos 15 ADRs estão em `canonical_documents` de `docs/project_logic_contracts.json` (estado padrão `current_contract`). `docs/adr/0004-xmage-human-spike-go.md` tem override `historical_evidence`. `docs/adr/README.md` **não** está na lista canônica (cai no default `supporting_reference_non_authoritative`).
- O gerador (`tools/project_logic/lib/project_logic_generator.dart:1183-1195`) falha se um documento canônico resolver para estado não-corrente, e os documentos correntes entram no `source_digest_sha256` (`:400-431`, `_currentDocumentFiles` `:2527-2540`). Ou seja: corrigir texto de ADR canônico muda o digest e exige `./scripts/manaloom_project_logic.sh --write`.

## 1. Tabela-resumo por documento

| Documento | Veredito | Afirmações | Erradas/defasadas | Ação |
| --- | --- | ---: | ---: | --- |
| `docs/adr/README.md` | MANTER | 6 | 0 | nenhuma |
| `0001-generated-project-logic.md` | MANTER | 16 | 0 | nenhuma |
| `0002-battle-lab-execution-boundaries.md` | CORRIGIR | 25 | 3 | inserir emenda de supersessão parcial pelo ADR 0013 (Live não é superfície pública; "Coach Mode" virou Jogar contra IA) e trocar a prova obrigatória que hoje é documento histórico |
| `0003-xmage-human-spike-no-go.md` | CORRIGIR | 12 | 2 | duas correções de texto: precisão da data de supersessão e referência "ADR 0004" → "ADR 0012" |
| `0004-battle-live-polling-and-durable-checkpoints.md` | CORRIGIR | 21 | 3 | inserir emenda: superfície Flutter de espectador removida pelo ADR 0013; transporte/persistência continuam como infraestrutura interna |
| `0004-xmage-human-spike-go.md` (histórico) | MANTER | 9 | 1 (defasada, já marcada histórica) | nenhuma — cabeçalho `HISTORICAL_EVIDENCE · SUPERSEDED · NO_MUTATION_AUTHORITY` já presente |
| `0005-interactive-battle-coach-alpha.md` | CORRIGIR | 20 | 4 | inserir emenda 2026-08-25 (ADR 0013 substitui nome, rota e UX); corrigir rota do item 9; trocar duas referências "ADR 0004" → "ADR 0012" |
| `0006-commander-optimizer-bracket-and-apply-safety.md` | CORRIGIR | 20 | 1 | item 9: cache contract `v19` → `v20` |
| `0007-commander-reference-generation-timeout.md` | CORRIGIR | 14 | 3 | contract `v6` → `v8`; prompt policy `v8` → `v9`; clamp 800–8.000 não é "Commander-only" |
| `0008-decklist-and-binder-physical-copy-boundary.md` | MANTER | 10 | 0 | nenhuma |
| `0009-social-trade-navigation-context-and-counterproposal.md` | MANTER | 12 | 0 | nenhuma |
| `0010-brewtact-public-brand-transition.md` | CORRIGIR | 14 | 2 | marcar item 10, a consequência de domínio e o review trigger como supersedidos pelo ADR 0011 (o 0011 declara, o 0010 não) |
| `0011-brewtact-production-domain.md` | MANTER | 12 | 0 | nenhuma |
| `0012-xmage-human-spike-go.md` | MANTER | 6 | 0 | nenhuma |
| `0013-play-vs-ai-is-the-only-interactive-battle-product.md` | MANTER | 18 | 0 | nenhuma |
| **Total** | | **215** | **19** | |

Nenhum ADR deve ser removido: todos têm valor de evidência ou de contrato. Nenhum ADR precisa ser "marcado histórico" além do que já está: o único histórico (`0004-xmage-human-spike-go.md`) já carrega o cabeçalho de lifecycle.

### Respostas ao foco do grupo

1. **Há ADR revogado por outro sem dizer?** Sim, três casos de supersessão **parcial não declarada no próprio ADR**:
   - ADR 0002 e ADR 0004 (Battle Live) decidem um "Live Spectator" com stream público e tela Flutter; o ADR 0013 (item 3) e `docs/status/CURRENT_PRODUCT_DECISION.md:64,88-89` dizem que não existe superfície pública de espectador. O código cumpre o 0013: `BattleLiveSpectatorScreen` só é importado pelo próprio arquivo (`grep -rln BattleLiveSpectatorScreen app/lib` → 1 arquivo) e `app/test/core/config/release_capability_surface_contract_test.dart:109-119` proíbe o roteador de construí-la. O `docs/CONTEXTO_PRODUTO_ATUAL.md:79-81` já registra "O ADR 0013 substitui sua direção pública", mas os ADRs 0002/0004 não.
   - ADR 0005 é substituído pelo 0013 em nome, rota e UX (declarado no cabeçalho do 0013 e no README), mas o 0005 só tem a emenda de 2026-08-13 e ainda diz que o app retoma por `/decks/:id/battle-coach/:sessionId` (item 9) — hoje é redirect (`app/lib/main.dart:704-718`).
   - ADR 0010 item 10 ("até a aquisição de domínio BrewTact, links usam a URL de deploy ou o host EasyPanel") foi substituído pelo ADR 0011 (o 0011 declara `Supersedes: ... ADR 0010, itens 10, Consequences e Review triggers`), mas o 0010 não recebeu a marca.
2. **Os dois 0004 e os dois spikes com veredito oposto** estão resolvidos e coerentes: 0003 = NO-GO em 2026-07-26 (commit `e64800eab`), reaberto em 2026-07-27 pelo arquivo que nasceu como `0004-xmage-human-spike-go.md` (commit `9b44648d5`), renumerado como ADR 0012 no commit `b2d3fc04f` (2026-08-13). O 0003 aponta para o 0012, o 0004-xmage aponta para o 0012, o 0012 aponta para o 0003 e para o histórico, e o README explica a colisão. As únicas imprecisões são textuais (ver 0003 e 0005).
3. **Há decisão que o código não cumpre?** Não, para as três decisões de produto pedidas:
   - ADR 0013 (Play vs IA único produto interativo): rota canônica `play-vs-ai` e redirects `battle-coach` em `app/lib/main.dart:675-718`; zero strings públicas com "Coach" em `app/lib` (só identificadores `BattleCoachScreen`, `battle-coach-*`, `isCoach`); espectador sem rota; preflight interativo exige `selected_engine == 'xmage'` (`app/lib/features/battle/models/battle_test_setup.dart:86-87`) e o serviço interativo não menciona Forge.
   - ADR 0011 (`brewtact.com`): `server/lib/public_site_url.dart:1` (`currentPublicSiteFallbackUrl = 'https://brewtact.com'`), `web-public/src/lib/routes.ts:2`, `scripts/manaloom_deploy_backend_image.sh:78-84,1035` (origem obrigatória, allowlist apex+www+EasyPanel, links de reset/verificação em `https://brewtact.com/app/#/...`), `server/.env.example:78,83,262`, teste `server/test/user_facing_brand_contract_test.dart:27-36`.
   - ADR 0010 (marca BrewTact): `app/lib/core/branding/product_identity.dart:8-9`, `app/web/index.html:50,57`, `app/web/manifest.json:2`, `AndroidManifest.xml:25`, `ios/Runner/Info.plist:9-18`, paleta em `app/lib/core/theme/app_theme.dart:35-54`, zero URLs `manaloom.com` no código (os únicos hits são chaves de storage `manaloom.commercial.*`, que o ADR autoriza manter). Identificadores internos seguem legados como decidido: `app/pubspec.yaml name: manaloom`, `applicationId com.mtgia.mtg_app`, `PRODUCT_BUNDLE_IDENTIFIER com.mtgia.mtgApp`.
   - Ressalva de método: o cumprimento do ADR 0013 na UI (mesa card-first, mão sempre visível, viewports 390x844/844x390/1440x900) foi conferido pela **existência** dos testes (`app/test/features/battle/screens/battle_coach_screen_test.dart:549,618,970,1016`) e pelo receipt de 2026-08-25, não por execução nesta auditoria.

## 2. Divergências por documento

Formato: linha | afirmação | classificação | evidência | verdade atual | ação | texto corrigido.

### `docs/adr/README.md` — MANTER

Sem divergências. Afirmações conferidas: (a) o manifesto valida a existência dos ADRs canônicos e os inclui no digest — `project_logic_generator.dart:1183-1195` e `:2527-2540`; o manifesto lista 14 caminhos `docs/adr/*.md`; (b) dois arquivos `0004` existem no disco; (c) `0004-xmage-human-spike-go.md` tem override `historical_evidence` em `project_logic_contracts.json` (`documentation_lifecycle.document_overrides`); (d) `0004-battle-live-polling-and-durable-checkpoints.md` está em `canonical_documents`; (e) o ADR 0013 declara substituir o 0005 só em nome/UX/superfície (`0013:6-8`).

Fato a registrar: o README **não** é documento canônico; vale como roteador de apoio. Se o dono quiser que as regras de supersessão dele tenham força de contrato, é preciso adicioná-lo a `canonical_documents`.

### `0001-generated-project-logic.md` — MANTER

Sem divergências. Conferido:

| linha | afirmação | evidência |
| --- | --- | --- |
| 16-19 | manifesto gerado inventaria rotas, migrations, deps, scripts, gates, testes e contratos | `project_logic_manifest.json` (10.345.672 bytes) com chaves `modules, app_routes, web_routes, api_routes, database, scripts_and_jobs, quality_gates, environment_variables, tests, flows, task_registry` |
| 19-21 | `package:analyzer` resolve contextos reais | `tools/project_logic/lib/project_logic_generator.dart:5-6` |
| 23-24 | `docs/generated/` é derivado | prefixo `docs/generated/` → `generated_snapshot` no contrato; 8 arquivos gerados |
| 24 | "O projeto não usa GitHub Actions" | `.github/workflows` não existe |
| 25-26 | pre-commit verifica MCP, segredos, manifesto e testes do gerador; pre-push roda o gate completo | `.githooks/pre-commit` → `scripts/manaloom_local_ci.sh quick` (`run_mcp_preflight`, `run_secret_scan`, `run_project_logic` = `--check` + `--test`, `:100-111,216-223`); `.githooks/pre-push` → `manaloom_local_ci.sh full` (`:225-234`) |
| 27 | `dart doc` valida APIs | `scripts/quality_gate.sh:333` chama `manaloom_dart_doc.sh --check` |
| 27-30 | gate `tbls`: PostgreSQL loopback descartável, DDL+migrations, Mermaid, comparação com o manifesto | `scripts/manaloom_tbls_local_gate.sh:68-77` (initdb/pg_ctl em 127.0.0.1), `:94-111` (database_setup.sql + `bin/migrate.dart`), `:154-160` (`--er-format mermaid`), `:170-202` (diff tabelas/views vs manifesto) |
| 33-34 | XMage pinado primeira referência; Forge pinado cobre gaps | `server/lib/ai/battle_engine_config.dart:10-14` (`pinnedXmageCommit`, `pinnedForgeCommit`, `pinnedXmageVersion = '1.4.60'`, `pinnedForgeVersion = '2.0.14-SNAPSHOT'`) |
| 47-50 | `manaloom_project_logic.sh --write`; `manaloom_install_local_hooks.sh --install`; sem hooks o gate falha fechado | `scripts/manaloom_project_logic.sh:13,28-31` (`--check|--write|--test`); `scripts/manaloom_install_local_hooks.sh:7-15` e `manaloom_local_ci.sh:97` (`--check`) |

Nota: "Responsáveis: ManaLoom engineering" e "Hermes/SQLite é cache/laboratório" são nomenclatura histórica; o ADR 0010 item 7 autoriza manter referências históricas. Não há SQLite em `server/lib`/`app/lib` (só em scripts Python de `server/bin`), o que não contradiz a hierarquia declarada.

### `0002-battle-lab-execution-boundaries.md` — CORRIGIR

| linha | afirmação | classificação | evidência | verdade atual | ação | texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 1, 29-31, 96-97 | Título e decisão 2: "Live Spectator será construído sobre `battle_job_v1` e um stream público sanitizado"; "Live Spectator e Coach podem permanecer desabilitados" | DEFASADO (produto) | ADR 0013 item 3 (`0013:30-32`); `docs/status/CURRENT_PRODUCT_DECISION.md:64,88-89`; `app/test/core/config/release_capability_surface_contract_test.dart:109-119`; `BattleLiveSpectatorScreen` sem rota (`grep -rln` em `app/lib` → só o próprio arquivo); supersessão registrada em `docs/CONTEXTO_PRODUTO_ATUAL.md:79-81` mas não neste ADR | O transporte (`GET /ai/battle/jobs/:id/live`, `battle_job_live_records`) existe e continua como infraestrutura interna/evidência; não há superfície pública de espectador desde o ADR 0013 (commit `f6f791098`, 2026-09-18) | corrigir | Inserir após a linha 6: `> Emenda 2026-08-25 (ADR 0013): o "Live Spectator" deixou de ser superfície de usuário. O stream público sanitizado, os checkpoints e o replay permanecem como transporte, recuperação, observabilidade e evidência internos; nenhuma rota, CTA ou modo de espectador existe no app. Os limites técnicos desta decisão continuam válidos.` |
| 32-35 | "Coach Mode usa `interactive_battle_session_v1`" | DEFASADO (nome) | ADR 0013 item 1-2 e consequência `0013:64-65` ("textos e rotas públicas deixam de usar 'Coach'"); zero strings públicas "Coach" em `app/lib` | O contrato `interactive_battle_session_v1` é o de **Jogar contra IA**; "Coach Mode" é nome técnico legado (capability `battle_coach` mantida por compatibilidade, `0013:53-55`) | corrigir | Na mesma emenda acima acrescentar: `O produto interativo chama-se Jogar contra IA; "Coach Mode" sobrevive apenas como identificador técnico (capability battle_coach, BattleCoachScreen).` |
| 115 | Prova obrigatória: `docs/MANALOOM_BATTLE_LAB_DELIVERY_PLAN.md` | DEFASADO (lifecycle) | `project_logic_contracts.json` → `document_overrides`: esse arquivo é `historical_evidence` ("prior deployed-alpha program; current public capability remains off"); guarda `historical_or_generated_may_set_priority: false` | Um documento histórico não pode ser "prova obrigatória" corrente; as provas correntes são os contratos hermes-analysis e os gates | corrigir | Substituir a linha 115 por: `- docs/MANALOOM_BATTLE_LAB_DELIVERY_PLAN.md (evidência histórica do programa BL0–BL10; não define prioridade nem autoriza mutação)` |

Afirmações confirmadas (CORRETO) que sustentam manter o ADR: `external_battle_request_v2` (`server/lib/ai/battle_engine_config.dart:6`); `battle_job_v1`, `interactive_battle_session_v1`, `battle_job_request_v1`, `server_dispatch_recorded`, `subject_deck_key` (todos presentes em `server/lib`, contagem por `grep -rl`); `client_editor_network_and_adventure` avaliado fora de escopo (`docs/hermes-analysis/EXTERNAL_ENGINE_CAPABILITY_CONTRACT.json:350-356`); cadeia `auto` XMage→Forge→native só após gap de cobertura (`server/lib/battle/battle_execution_runtime.dart:277` `auto_secondary_forge_after_coverage_gap`, `:295` `auto_native_after_external_coverage_gaps`); Live XMage-only com 409 para outro engine (`server/lib/battle/battle_live_service.dart:112,252-271`); sem TTL automático nas famílias Battle (nenhum `DELETE FROM battle_*` em `server/bin`; os únicos deletes são `user_data_privacy_service.dart` e a exclusão de anotação pelo dono em `battle_replay_annotation_service.dart:302`); exportação inclui `battle_simulations, battle_simulation_attempts, battle_jobs, battle_job_live_records, interactive_battle_sessions, interactive_battle_records, battle_replay_annotations` (`server/lib/user_data_privacy_service.dart:105-545`) e exclui `interactive_battle_request_payload`/`fingerprints` (`:584-586`); exclusão de conta remove as famílias (`:669-894`); `state_version` e idempotência (`server/lib/battle/interactive_battle_contract.dart:264-284`); gates `quality_gate.sh battle` e `engine-capabilities` (`scripts/quality_gate.sh:521,527`).

### `0003-xmage-human-spike-no-go.md` — CORRIGIR

| linha | afirmação | classificação | evidência | verdade atual | ação | texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 3-4 | "Estado: substituído pelo ADR 0012 em 2026-07-27" | ERRADO (precisão) | `git log -- docs/adr/0012-xmage-human-spike-go.md` → único commit `b2d3fc04f` 2026-08-13; o GO de 2026-07-27 entrou como `docs/adr/0004-xmage-human-spike-go.md` no commit `9b44648d5` (2026-07-27) | Substituído em 2026-07-27 pela decisão GO que nasceu com o número 0004 e foi renumerada como ADR 0012 em 2026-08-12/13 | corrigir | `- Estado: substituído em 2026-07-27 pela decisão GO registrada originalmente como 0004-xmage-human-spike-go.md e renumerada como ADR 0012 em 2026-08-12; o arquivo com o número antigo permanece somente como evidência histórica` |
| 75 | "reflete o GO do ADR 0004" | CONTRADIZ_OUTRO_DOC | `docs/adr/README.md:16-18`: "Novas referências devem usar ADR 0012; o ADR 0004 canônico continua sendo o contrato de polling ... de Battle Live" | O GO é o ADR 0012; "ADR 0004" hoje é Battle Live | corrigir | `... e reflete o GO do ADR 0012; não deve ser usado para reescrever retroativamente este registro histórico.` |

Confirmado: XMage `1.4.60` (`battle_engine_config.dart:13`); reabertura de `GAME_PLAY_MANA` em 2026-07-27 (commit `0784a42c9` "bound XMage mana prompt responses"); scripts `services/xmage-sidecar/bin/human_vs_ai_spike.sh` e `human_vs_ai_runtime_spike.sh` existem; testes `HumanVsAiSpikeTest.java`, `HumanVsAiRuntimeSpikeMain.java` existem. As métricas do harness ("sete testes") são históricas (NAO_VERIFICAVEL sem executar) e o próprio ADR as rotula como registro histórico.

### `0004-battle-live-polling-and-durable-checkpoints.md` — CORRIGIR

| linha | afirmação | classificação | evidência | verdade atual | ação | texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 10-11 | "O Live Spectator precisa mostrar progresso público enquanto o XMage executa" | DEFASADO (produto) | ADR 0013 item 3; `CURRENT_PRODUCT_DECISION.md:64,88-89` | Não há progresso **público**; o Live é infraestrutura interna e evidência | corrigir | inserir emenda (abaixo) |
| 35-36 | item 7: "Pausar no Flutter pausa somente playback/renderização local; polling e engine continuam. Reconexão retoma pelo último cursor" | DEFASADO | `app/lib/features/battle/screens/battle_live_spectator_screen.dart` existe (1.736 linhas) mas nenhuma rota a constrói; `release_capability_surface_contract_test.dart:109-119` proíbe `BattleLiveSpectatorScreen` em `main.dart`; `ReleaseRouteBuildSupport.battleLive` nunca é preenchido (`app/lib/main.dart:104-109`) | A tela Flutter é código sem porta de entrada; o comportamento descrito só vale para consumidores internos/testes | corrigir | inserir emenda |
| 80, 85 | "polling adiciona latência de poucos segundos, aceitável para espectador"; "Live continua somente leitura e não aproxima Coach Mode de um GO" | DEFASADO | ADR 0012 deu GO limitado ao spike (2026-07-27) e ADR 0013 definiu Jogar contra IA; espectador não é produto | O Live não é superfície de usuário; o GO de engenharia interativa já existe (0012) e o produto interativo é Jogar contra IA (0013) | corrigir | inserir emenda |

Texto único a inserir após a linha 6:

```
> Emenda 2026-08-25 (ADR 0013): a superfície de espectador (tela Flutter
> `BattleLiveSpectatorScreen`, rota `battle-live/:jobId`, CTA) deixou de
> existir como produto e o roteador é proibido de construí-la por teste de
> contrato. As decisões 1–6 e 8–11 (polling autenticado, cursor HMAC,
> `battle_job_live_records`, registry transitório do sidecar, allowlist dupla,
> orçamento do job, fase operacional) continuam válidas como infraestrutura
> interna, recuperação e evidência. O item 7 descreve a tela histórica e não
> uma superfície de usuário. Coach Mode recebeu GO de engenharia no ADR 0012 e
> virou Jogar contra IA no ADR 0013.
```

Confirmado (CORRETO): rota `server/routes/ai/battle/jobs/[id]/live/index.dart` com 404 antes de consultar o job quando a flag está desligada (`:24-26`); `battle_job_live_records` criada pela migration `055` (`server/bin/migrate.dart:3362-3365`); registry do sidecar 64 streams / 20.000 registros / 15 min (`services/xmage-sidecar/src/main/java/com/manaloom/xmage/BattleLiveRegistry.java:27-29`); releitura `after=-1` (`battle_live_service.dart:142`); engine ≠ XMage → 409 (`:112,252-271`); job 120 s padrão / 180 s teto (`server/lib/battle/battle_job_contract.dart:8-9`); `/ai/simulate` teto 40 s (`server/lib/ai/battle_simulation_request_support.dart:74-76`); migration `057` só amplia o CHECK (`migrate.dart:3847-3851`); flags `BATTLE_LIVE_SPECTATOR_ENABLED` (`battle_live_service.dart:12`) e `ENABLE_BATTLE_LIVE_SPECTATOR` (`app/lib/core/config/launch_features.dart:21`); readiness só quando habilitado (`server/lib/health_readiness_support.dart:914-915`); timeout 2 s e 8 MiB (`battle_live_source_client.dart:12,76`); `limit=1..100` (`battle_live_cursor_contract.dart:9`); os 7 arquivos de prova existem; capability `battle_live` `off` (`server/config/release_capabilities.json`).

### `0004-xmage-human-spike-go.md` (histórico) — MANTER

| linha | afirmação | classificação | evidência | verdade atual | ação |
| --- | --- | --- | --- | --- | --- |
| 43-44 | "servidor real pinado em XMage `1.4.60`, commit `34d81ea4995ce15d7e1a788dc6d2a3595d35bcec`" | DEFASADO | `git log -S'34d81ea4...' -- server/lib/ai/battle_engine_config.dart` → removido em `c05774e0f` (2026-07-28, "update pinned XMage and audit upstream drift"); hoje `pinnedXmageCommit = '2c43ec8cdb5cd475d47e6b555a4077151f476a3b'` (`battle_engine_config.dart:10`), versão continua `1.4.60` | O commit do pin mudou um dia depois da decisão; o documento é evidência histórica marcada como tal | nenhuma (cabeçalho `HISTORICAL_EVIDENCE · SUPERSEDED · NO_MUTATION_AUTHORITY` presente nas linhas 3-11) |

Confirmado: override `historical_evidence` no contrato; `superseded_by_adr_0012`; scripts de reprodução existem (comandos históricos valem como exemplo, guarda `historical_commands_are_examples_only: true`). As métricas de runtime (3/3 partidas, 251/251, p95) são NAO_VERIFICAVEL sem executar e são evidência da época.

### `0005-interactive-battle-coach-alpha.md` — CORRIGIR

| linha | afirmação | classificação | evidência | verdade atual | ação | texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 1, 8-11 (cabeçalho) | Título "Battle Coach alpha"; só a emenda de 2026-08-13 | DEFASADO (falta emenda) | ADR 0013 cabeçalho (`0013:6-8`) e `docs/adr/README.md:20-25` declaram a substituição de nome/UX/superfície; ADR 0005 não a registra | O 0005 é a arquitetura técnica de Jogar contra IA | corrigir | Inserir após a linha 11: `> Emenda 2026-08-25: o ADR 0013 substitui este ADR quanto ao nome ("Jogar contra IA"), à rota canônica (/decks/:id/play-vs-ai[/sessionId]) e à experiência (mesa card-first, sem espectador público). Os limites de privacidade, persistência, autenticação e resposta tipada abaixo continuam válidos. Onde este texto diz "ADR 0004", leia ADR 0012.` |
| 15 | "O GO limitado do ADR 0004 provou..." | CONTRADIZ_OUTRO_DOC | `docs/adr/README.md:16-18` | O GO é o ADR 0012 | corrigir | `O GO limitado do ADR 0012 provou...` |
| 41 | "Ela contradiz a política aprovada do ADR 0004" | CONTRADIZ_OUTRO_DOC | idem | idem | corrigir | `...a política aprovada do ADR 0012...` |
| 49-51 | item 9: "O app retoma pela URL `/decks/:id/battle-coach/:sessionId`" | DEFASADO | `app/lib/main.dart:675-703` registra `play-vs-ai/:sessionId` e `play-vs-ai`; `:704-718` registra `battle-coach/:sessionId` e `battle-coach` **apenas como redirect** (`playVsAiSessionRouteLocation`/`playVsAiRouteLocation`); helpers antigos `@Deprecated` em `battle_coach_screen.dart:28-35`; mudança no commit `f6f791098` (2026-09-18) | A URL de retomada é `/decks/:id/play-vs-ai/:sessionId`; `battle-coach` é compatibilidade temporária | corrigir | `9. O app retoma pela URL /decks/:id/play-vs-ai/:sessionId (ADR 0013); /decks/:id/battle-coach/:sessionId existe apenas como redirect de compatibilidade. shared_preferences não é fonte de sessão, prompt, ação ou replay.` |

Confirmado (CORRETO): tabelas `interactive_battle_sessions` e `interactive_battle_records` na migration `056` (`migrate.dart:3461-3464`, `CREATE TABLE` em +10 e +219); 404 único para malformado/inexistente/outro dono (`server/routes/ai/battle/sessions/[id]/index.dart:18,31,54-57`); `state_version`, `prompt_id`, `option_id|integer_value|multi_amount_values|delegate`, `idempotency_key` (`interactive_battle_contract.dart:176,264-284`); estados não terminais/terminais exatamente como listados (`:45-74`); `XMAGE_RUNTIME_MODE` batch|interactive (`services/xmage-sidecar/.../SidecarMain.java:70-75`); `INTERACTIVE_BATTLE_ENABLED` (`interactive_battle_runtime_client.dart:33`, `health_readiness_support.dart:1177`) e `ENABLE_INTERACTIVE_BATTLE` (`launch_features.dart:32`); scripts recusam `MANALOOM_RELEASE_ENABLE_INTERACTIVE_BATTLE=1` (`scripts/manaloom_deploy_flutter_web.sh:9-12`, `manaloom_build_android_release.sh:12-15`, `manaloom_deploy_backend_image.sh:9-14`); evidências BL8/BL9/BL10 existem em `docs/qa/` (prefixo `historical_evidence`); testes Dart (`server/test/interactive_battle_*` — 8 arquivos), Maven (`InteractiveBattleRegistryTest.java`) e Flutter (`app/test/features/battle/**`) existem.

### `0006-commander-optimizer-bracket-and-apply-safety.md` — CORRIGIR

| linha | afirmação | classificação | evidência | verdade atual | ação | texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 62 | "The persistent optimize cache contract advances to `v19`" | DEFASADO | `server/lib/ai/optimize_cache_support.dart:13` → `optimizeCacheContractVersion = 'v20'`; `git log -S"= 'v20'"` → `b2d3fc04f` (2026-08-13); `v19` entrou em `d8025ce9e` (2026-08-01) | O contrato é `v20` desde 2026-08-13 | corrigir | `9. The persistent optimize cache contract is at v20 (v19 in this decision; bumped to v20 on 2026-08-13 by the free-beta all-off baseline), invalidating previews produced before ...` |

Confirmado (CORRETO): rota `server/routes/ai/optimize/index.dart`; cap de Game Changers B1/B2 = 0, B3 = 3, B4/B5 = 99 (`server/lib/edh_bracket_policy.dart:33-37`); matriz de intenção turno 9/8/6/4/`null`, só B5 `competitiveLane: true` (`:96-136`); `commander_functional_role_floors_v3` (`server/lib/ai/optimize_functional_role_support.dart:6`); `OPTIMIZE_NEEDS_REPAIR` (`optimize_route_outcome_support.dart:292`), `/ai/rebuild` (`server/routes/ai/rebuild/index.dart`), `full_non_commander_rebuild` (`rebuild_guided_service.dart`, `optimize_route_response_support.dart`); `safe_no_change` é nome de caminho terminal no corpus (`server/test/fixtures/optimization_resolution_corpus.json:7`), não literal em `server/lib` — a semântica do item 11 se sustenta pelos códigos `OPTIMIZE_NO_SAFE_SWAPS`/`OPTIMIZE_NO_ACTIONABLE_SWAPS` (`:294-295`); `OPTIMIZATION_APPLY_SIGNING_SECRET` opcional com fallback `JWT_SECRET` (`optimize_swap_integrity.dart:174-186`); duas rotas de mutação com autorização e `FOR UPDATE` (`server/routes/decks/[id]/index.dart`, `decks/[id]/cards/bulk/index.dart`); fonte oficial de Game Changers `server/config/commander_game_changers.json` (`source_url` = update 2026-02-09, 53 nomes, inclui `Biorhythm`, `Farewell`, `Lion's Eye Diamond`, `Grim Monolith`, `Mox Diamond`; `Cori-Steel Cutter` ausente) com gate `sync_game_changers_to_dart.py --check` em `manaloom_local_ci.sh:114-119`. As URLs da Wizards são NAO_VERIFICAVEL offline.

### `0007-commander-reference-generation-timeout.md` — CORRIGIR

| linha | afirmação | classificação | evidência | verdade atual | ação | texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 39-40 | "with an explicit Commander-only 800–8,000 operational clamp" | ERRADO (parcial) | `server/lib/ai_generate_performance_support.dart:317-335`: `min: 800, max: 8000` aplica-se a **qualquer** formato; o que é Commander-only é o override `OPENAI_MAX_TOKENS_GENERATE_COMMANDER` (`:322-327`) e o default 6000 vs 2200/2600 | O clamp 800–8000 vale para todos os formatos; o default 6.000 e a variável de override são Commander-only | corrigir | `Reserve 6,000 output tokens by default for Commander generation (2,200/2,600 for other formats), with a Commander-only override OPENAI_MAX_TOKENS_GENERATE_COMMANDER; every generation format keeps the 800–8,000 operational clamp.` |
| 43-44 | "Invalidate old generation cache entries with contract `v6`" | DEFASADO | `ai_generate_performance_support.dart:13` → `'v8'`; `v6` em `e16d86107` (2026-08-02), `v7` em `491bb4f80` (2026-08-02), `v8` em `b2d3fc04f` (2026-08-13) | Contrato `v8` | corrigir | `... contract v8 (v6 in this decision; v7 on 2026-08-02 and v8 on 2026-08-13) and reference-prompt policy v9 (v8 in this decision; bumped in the same day by 96208fa9e).` |
| 44 | "reference-prompt policy `v8`" | DEFASADO | `server/routes/ai/generate/index.dart:45` → `'ai_generate_reference_prompt_v9'`; `96208fa9e` (2026-08-02) | Política `v9` | corrigir | idem acima |

Confirmado (CORRETO): `OPENAI_TIMEOUT_GENERATE_REFERENCE_SECONDS` default 75 s em todos os ambientes, clamp 3–90 s (`:389-396`); caminho legado sem referência mantém `OPENAI_TIMEOUT_GENERATE_SECONDS` (`:362-380`); truncamento classificado à parte com `can_save: false` (`:343-352`); só Commander/Brawl usam o orçamento de referência (`:355-357`). As falhas de produção de 24 s / 21,3 s / 3.800 tokens são contexto histórico (NAO_VERIFICAVEL).

### `0008-decklist-and-binder-physical-copy-boundary.md` — MANTER

Sem divergências. Conferido: `deck_cards` = `card_id, quantity, is_commander, condition` (com comentário "metadado legado da decklist; não aloca item do Binder", `server/database_setup.sql`); `user_binder_items` = `... condition, is_foil, ... language, list_type`; `cards.foil` comentado como "disponibilidade foil da impressão no catálogo; não é cópia física" (`:146`); nenhuma migration adiciona `language`/`is_foil` a `deck_cards`; UI usa `'Foil disponível' : 'Sem foil'` (`app/lib/features/cards/widgets/card_edition_metadata.dart:20`); snapshot de trade em migration `058 snapshot_trade_item_identity` (`migrate.dart:3865-3869`). A data 2026-08-05 antecede o commit `e6737c53b` (2026-08-10) — data de decisão, NAO_VERIFICAVEL, sem conflito.

### `0009-social-trade-navigation-context-and-counterproposal.md` — MANTER

Sem divergências. Conferido: `marketplaceRouteLocation = '/collection?tab=1'` e `quotesRouteLocation = '/community?tab=3'` (`app/lib/features/trades/trade_route_contract.dart:1,3`); `/market`, `/marketplace`, `/quotes` são redirects (`app/lib/main.dart:800-810`); `/collection/matches` com `deck` na query (`:778-780`); `trades/create/:receiverId` lê `item, type, source, deck, counter` da URI (`:877-895`; `trade_route_contract.dart:56-63`); servidor revalida `trade_visibility`, `user_blocks`, `interaction_blocked` (`server/routes/trades/index.dart:132-201`); `COALESCE(oracle_id, id)` (`server/lib/collection_availability_contract.dart` e mais 4); `users.location_visibility DEFAULT 'private'` (`database_setup.sql:58`); `[Contexto: <rótulo>] <comentário>` (`app/lib/features/community/providers/community_provider.dart:111,117`); contraproposta só `type == 'trade'` (`trades/index.dart:69`), original travada com `FOR UPDATE` e exigida `pending` (`:255-280`). "ManaLoom" no item 9 é nome histórico permitido.

### `0010-brewtact-public-brand-transition.md` — CORRIGIR

| linha | afirmação | classificação | evidência | verdade atual | ação | texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 48-50 | item 10: "Até a aquisição e configuração de domínio BrewTact, links públicos usam a URL de deploy configurada ou o host público EasyPanel aprovado" | DEFASADO (supersedido, não marcado) | ADR 0011 `:7-8` ("Supersedes: a condição provisória de domínio descrita no ADR 0010, itens 10, Consequences e Review triggers"); `server/lib/public_site_url.dart:1` fallback `https://brewtact.com` | O domínio foi adquirido e é canônico desde 2026-08-12 (`704c2c11c`) | corrigir | Após a linha 50: `   > Superseded pelo ADR 0011 em 2026-08-11: a origem pública canônica é https://brewtact.com. Permanece válida a proibição de fallback para manaloom.com.` |
| 63-64 | "Um domínio definitivo e remetente de e-mail BrewTact continuam dependentes de aquisição/verificação externa; o código não presume que isso ocorreu" | DEFASADO | idem; `scripts/manaloom_deploy_backend_image.sh:82-84` fixa `CANONICAL_PUBLIC_SITE_URL`, reset e verificação em `https://brewtact.com/app/#/...` | O domínio está resolvido (ADR 0011); o remetente de e-mail não foi auditado aqui | corrigir | `- O domínio definitivo é brewtact.com (ADR 0011). O remetente de e-mail BrewTact continua dependente de verificação externa; o código não presume que isso ocorreu.` |

Confirmado (CORRETO): marca e taglines (`app/lib/core/branding/product_identity.dart:8-9`; `web-public/src/components/site-shell.tsx:28`); títulos BrewTact em `app/web/index.html:50,57`, `app/web/manifest.json:2`, `AndroidManifest.xml:25`, `Info.plist:9-18`; master vetorial Tactical Stack (`docs/brand/brewtact/final/tactical-stack/master/brewtact-tactical-stack-mark*.svg`) e pipeline `scripts/generate_brewtact_brand_assets.py`; splash Android = cor `#0B0D12` + `launch_mark` centrado, sem texto (`app/android/app/src/main/res/drawable/launch_background.xml`, `values/colors.xml:3`); launcher monocromático (`drawable/ic_launcher_monochrome.xml`); paleta `#0B0D12/#151821/#C58B2A/#E0A93B/#6FA8DC/#F3EFE3` (`app/lib/core/theme/app_theme.dart:35-54`); identificadores internos legados (`app/pubspec.yaml name: manaloom`; `applicationId com.mtgia.mtg_app`; `com.mtgia.mtgApp`; chaves `manaloom.commercial.*`); zero URLs `manaloom.com` em `app/lib`, `server/lib`, `server/routes`, `web-public/src`; testes de contrato de marca (`server/test/user_facing_brand_contract_test.dart:7-36`, `app/test/core/branding/product_identity_contract_test.dart`).

### `0011-brewtact-production-domain.md` — MANTER

Sem divergências. Conferido: origem canônica `https://brewtact.com` (`server/lib/public_site_url.dart:1`; `web-public/src/lib/routes.ts:2,26`; `server/.env.example:83,262`); allowlist CORS `EasyPanel legado + apex + www`, apex obrigatório (`scripts/manaloom_deploy_backend_image.sh:79-81,1035 --required-origin`; `.env.example:78`); CORS rejeita userInfo/query/fragment/path (`server/lib/cors_policy.dart:84-99`) e produção exige `https` não-loopback (`:106-108`); reset/verificação em `https://brewtact.com/app/#/reset-password|verify-email` fixados no deploy (`:83-84`; o default do código é `http://localhost:8088/app/#/...`, `server/lib/password_reset_delivery_service.dart:62`, `email_verification_delivery_service.dart:24` — configuração, não contradição); API `https://evolution-cartinhas.2ta7qx.easypanel.host` (`:78`); adendo 2026-08-13: 29 capabilities `off` (`server/config/release_capabilities.json`, `policy_version brewtact_free_beta_2026-08-13`), site sem link para `/app` (nenhum `href` para `/app` em `web-public/src`; único hit é `robots.ts:10 disallow`), texto `Acesso ainda não liberado` (`web-public/src/components/ui.tsx:33-36`). Os retornos `200`, o redirect `www` e o TLS no proxy são NAO_VERIFICAVEL no repositório (o próprio adendo diz que os 200 históricos não valem como receipt).

### `0012-xmage-human-spike-go.md` — MANTER

Sem divergências. Conferido: substitui ADR 0003 (o 0003 aponta de volta); `0004-xmage-human-spike-go.md` é `historical_evidence`; restrições (default-off, sem rota pública, sem deploy) refletidas em `release_capabilities.json` (29 off) e nos scripts de deploy que recusam `MANALOOM_RELEASE_ENABLE_INTERACTIVE_BATTLE=1`; os quatro documentos citados nas linhas 40-43 existem. "Renumeração documental: 2026-08-12" vs commit `b2d3fc04f` 2026-08-13 16:35 -0300 — data de decisão anterior ao commit, NAO_VERIFICAVEL, sem conflito.

### `0013-play-vs-ai-is-the-only-interactive-battle-product.md` — MANTER

Sem divergências. Conferido: rota canônica e redirects (`app/lib/main.dart:675-718`); espectador sem rota (`release_capability_surface_contract_test.dart:109-119`); zero strings públicas "Coach" em `app/lib`; `delegate` por prompt (`interactive_battle_contract.dart:271`); bloqueio explícito sem Forge (`battle_test_setup.dart:86-87`: `canStartInteractive` exige `selected_engine == 'xmage'`; nenhum `forge` em `interactive_battle_service.dart`/`interactive_battle_runtime_client.dart`); capability `battle_coach` mantida (`release_capabilities.json`); `BT-PLAY-001/002/003` no registry (`docs/generated/TASK_REGISTRY.json`, `source_line` 472-474, status `BLOCKED_BY_P0`, dependências `BT-SCP-001, BT-BAT-004/005/007` → `BT-PLAY-001` → `BT-BAT-010` → `BT-PLAY-002` → `BT-BAT-008/009` → `BT-PLAY-003`); runner `scripts/manaloom_play_vs_ai_e2e.sh` existe; receipt `docs/qa/execution/2026-08-25/play-vs-ai-real-xmage-e2e.md` confirma 232 registros PostgreSQL (`:59`), nove capturas 1440x900 (`:74`) e cleanup sem kill forçado (`:82`). Fato de contexto: o ADR e o receipt (datados 2026-08-25) só entraram no repositório no commit `f6f791098` de 2026-09-18. Ressalva atual, não do ADR: o runner hoje trava na segunda invocação de `manaloom_server_contract_e2e_isolated.sh` ("build output has a consumer"), conforme `docs/PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md:23-28`.

## 3. Fatos confirmados (tabela de verdade)

Cada item foi verificado na fonte primária nesta auditoria.

### Lifecycle e governança dos ADRs
1. `docs/adr/` tem 15 arquivos: 13 ADRs canônicos (0001, 0002, 0003, 0004-battle-live, 0005, 0006, 0007, 0008, 0009, 0010, 0011, 0012, 0013) listados em `canonical_documents`, 1 histórico (`0004-xmage-human-spike-go.md`, override `historical_evidence`) e o `README.md`, que **não** é canônico. Fonte: `docs/project_logic_contracts.json` (`canonical_documents`, 36 entradas; `documentation_lifecycle.document_overrides`).
2. Documentos canônicos entram no `source_digest_sha256` do manifesto; o gerador rejeita canônico com lifecycle não-corrente. Fonte: `tools/project_logic/lib/project_logic_generator.dart:1183-1195,2527-2540`; manifesto com 14 caminhos `docs/adr/*.md`.
3. Cadeia dos spikes: 0003 NO-GO (2026-07-26, `e64800eab`) → GO em arquivo `0004-xmage-human-spike-go.md` (2026-07-27, `9b44648d5`) → renumerado ADR 0012 (`b2d3fc04f`, 2026-08-13). O 0003 cita o 0012; o 0004-xmage cita o 0012; o 0012 cita o 0003 e o histórico.
4. ADR 0013 substitui ADR 0005 em nome/rota/UX (declarado em `0013:6-8` e `README.md:20-25`); o 0005 não tem a emenda correspondente (divergência acima). `docs/CONTEXTO_PRODUTO_ATUAL.md:79-81` já registra a supersessão da direção pública do programa Battle Lab.
5. ADR 0011 declara superseder o item 10, Consequences e Review triggers do ADR 0010 (`0011:7-8`); o 0010 não recebeu a marca.
6. Não existe GitHub Actions (`.github/workflows` ausente). Hooks locais: `.githooks/pre-commit` → `manaloom_local_ci.sh quick`; `.githooks/pre-push` → `manaloom_local_ci.sh full`; `core.hooksPath = .githooks`.

### Battle (ADRs 0002, 0004, 0005, 0012, 0013)
7. `server/config/release_capabilities.json`: `policy_version brewtact_free_beta_2026-08-13`, 29 capabilities, nenhuma `allowed`, todas `release_capability: off`; inclui `battle_batch`, `battle_live`, `battle_coach`.
8. Rotas do app: `/decks/:id/battle-replays` incondicional (`main.dart:656-674`); `play-vs-ai/:sessionId` e `play-vs-ai` sob `LaunchFeatures.interactiveBattleSupported` (`:675-703`); `battle-coach/:sessionId` e `battle-coach` são redirects (`:704-718`). Nenhuma rota constrói `BattleLiveSpectatorScreen` (teste `release_capability_surface_contract_test.dart:109-119`).
9. Zero strings públicas "Coach" em `app/lib` (só identificadores `BattleCoachScreen`, `battle-coach-*`, `onOpenCoach`, `isCoach`).
10. Pins: `pinnedXmageVersion = '1.4.60'`, `pinnedXmageCommit = '2c43ec8cdb5cd475d47e6b555a4077151f476a3b'` (desde `c05774e0f`, 2026-07-28), `pinnedForgeVersion = '2.0.14-SNAPSHOT'` (`server/lib/ai/battle_engine_config.dart:10-14`).
11. Contratos: `external_battle_request_v2` (`battle_engine_config.dart:6`), `battle_job_v1`, `interactive_battle_session_v1`, `battle_job_request_v1`, `server_dispatch_recorded`, `subject_deck_key` presentes em `server/lib`. `client_editor_network_and_adventure` = `evaluated_out_of_scope` (`EXTERNAL_ENGINE_CAPABILITY_CONTRACT.json:350-356`).
12. Cadeia `auto`: XMage → Forge (`auto_secondary_forge_after_coverage_gap`, `battle_execution_runtime.dart:277`) → native (`auto_native_after_external_coverage_gaps`, `:295`).
13. Migrations Battle: `052` attempts (`migrate.dart:2706`), `053` annotations (`:2809`), `054` battle_jobs (`:3041`), `055` battle_job_live_records (`:3362`), `056` interactive_battle_sessions + interactive_battle_records (`:3461`), `057` só amplia CHECK de timeout (`:3847`), `058` snapshot_trade_item_identity (`:3865`).
14. Orçamentos: job 120 s padrão / 180 s teto (`battle_job_contract.dart:8-9`); `/ai/simulate` 40 s padrão e teto (`battle_simulation_request_support.dart:74-76`).
15. Live: registry do sidecar 64 streams / 20.000 registros / 15 min (`BattleLiveRegistry.java:27-29`); source timeout 2 s, 8 MiB, `limit` 1..100; engine ≠ XMage → 409 `battle_live_engine_unsupported`; flag `BATTLE_LIVE_SPECTATOR_ENABLED` desligada → 404 antes de consultar o job; flag do app `ENABLE_BATTLE_LIVE_SPECTATOR`.
16. Interativo: `XMAGE_RUNTIME_MODE` batch|interactive (`SidecarMain.java:70-75`); `INTERACTIVE_BATTLE_ENABLED` no servidor; `ENABLE_INTERACTIVE_BATTLE` no app; 13 estados de lifecycle exatamente como no ADR 0005 (`interactive_battle_contract.dart:45-74`); resposta = `option_id | integer_value | multi_amount_values | delegate` com `state_version`, `prompt_id`, `idempotency_key`; 404 único para malformado/inexistente/outro dono.
17. Os três scripts de release recusam `MANALOOM_RELEASE_ENABLE_INTERACTIVE_BATTLE=1` (`manaloom_deploy_flutter_web.sh:9-12`, `manaloom_build_android_release.sh:12-15`, `manaloom_deploy_backend_image.sh:9-14`).
18. Retenção: nenhum cron/daemon apaga `battle_*`/`interactive_battle_*`; exportação e exclusão de conta cobrem 7 relações Battle (`user_data_privacy_service.dart:105-545,669-894`) e excluem payload/fingerprint internos (`:584-586`).
19. `BT-PLAY-001/002/003` existem no registry como `P0 BATTLE BLOCKED_BY_P0` (linhas 472-474 do backlog). Registry: 220 tasks; status = TODO 86, BLOCKED_BY_P0 77, DEFERRED_BY_SCOPE 33, IN_PROGRESS_CONTAINED 10, IMPLEMENTED_LOCAL_PENDING_FULL_GATE 7, WAITING_EXTERNAL 4, PASS 3.
20. Receipt `docs/qa/execution/2026-08-25/play-vs-ai-real-xmage-e2e.md`: 232 registros PostgreSQL, nove capturas 1440x900, cleanup sem kill forçado; entrou no repositório junto com o ADR 0013 no commit `f6f791098` (2026-09-18).

### IA de deck (ADRs 0006, 0007)
21. Game Changers: fonte `server/config/commander_game_changers.json` (update 2026-02-09, 53 nomes, inclui Biorhythm e Farewell), gate `sync_game_changers_to_dart.py --check` no `quick` e no `full`. Caps: B1/B2 = 0, B3 = 3, B4/B5 = 99 (`edh_bracket_policy.dart:33-37`). Pisos de turno 9/8/6/4/null, só B5 competitivo (`:96-136`).
22. Versões vigentes: optimize cache `v20` (`optimize_cache_support.dart:13`, desde `b2d3fc04f` 2026-08-13); generate cache `v8` (`ai_generate_performance_support.dart:13`, mesmo commit); reference prompt `ai_generate_reference_prompt_v9` (`server/routes/ai/generate/index.dart:45`, desde `96208fa9e` 2026-08-02); role floors `commander_functional_role_floors_v3`.
23. Geração Commander/Brawl com referência: timeout 75 s padrão, clamp 3–90 s; tokens 6.000 (Commander) / 2.200–2.600 (outros), clamp 800–8.000 para todos, override `OPENAI_MAX_TOKENS_GENERATE_COMMANDER` (`ai_generate_performance_support.dart:317-396`); truncamento → `can_save: false`.
24. Apply do Optimize: HMAC com `OPTIMIZATION_APPLY_SIGNING_SECRET` opcional e fallback `JWT_SECRET` (`optimize_swap_integrity.dart:174-186`); rotas de mutação `PUT /decks/:id` e `POST /decks/:id/cards/bulk` validam autorização e usam `FOR UPDATE`.

### Dados e social (ADRs 0008, 0009)
25. `deck_cards` = `card_id, quantity, is_commander, condition` (legado, CHECK NM/LP/MP/HP/DMG); sem `language`/`is_foil`. `user_binder_items` tem `condition, is_foil, language, list_type`. `cards.foil` é capacidade da impressão. UI: `'Foil disponível' : 'Sem foil'`.
26. Rotas sociais: `/collection?tab=1` (marketplace), `/community?tab=3` (cotações); `/market`, `/marketplace`, `/quotes` são redirects; `/collection/matches?deck=`; `/trades/create/:receiverId?item&type&source&deck&counter`. Contraproposta só para `trade` puro, `pending`, com `FOR UPDATE` na original. `users.location_visibility` default `private`. Comentário contextual `[Contexto: <rótulo>] <comentário>`.

### Marca e domínio (ADRs 0010, 0011)
27. Marca pública BrewTact em Web/manifest/Android/iOS; taglines `Monte melhor. Jogue melhor.` / `Build smarter. Play better.`; paleta tokens em `app_theme.dart:35-54`; splash Android = `#0B0D12` + símbolo centrado; master vetorial Tactical Stack em `docs/brand/brewtact/final/tactical-stack/master/`; zero URLs `manaloom.com` no código.
28. Identificadores internos legados por decisão: `name: manaloom`, `com.mtgia.mtg_app`, `com.mtgia.mtgApp`, `MANALOOM_*`, chaves `manaloom.*`.
29. Origem canônica `https://brewtact.com` (fallback em `public_site_url.dart:1`, `routes.ts:2`, `.env.example:83,262`); CORS de produção = EasyPanel legado + apex + www com apex obrigatório (`manaloom_deploy_backend_image.sh:79-81,1035`); API `https://evolution-cartinhas.2ta7qx.easypanel.host`; links de reset/verificação fixados no deploy em `https://brewtact.com/app/#/...`; site público sem CTA para `/app`, mostrando `Acesso ainda não liberado` (`ui.tsx:33-36`).

### Gates (ADR 0001)
30. `manaloom_local_ci.sh quick` = shell contracts + Game Changer source + MCP preflight + secret scan + project logic (`--check` e `--test`) + UI live evidence; `full` = shell contracts + Game Changer + MCP + secrets + guardrail audits + release contracts + `melos run quality` + gate tbls. `full` **não** repete `run_project_logic` (`:225-234`). Gate tbls: PostgreSQL loopback descartável, `database_setup.sql` + `bin/migrate.dart`, `tbls --er-format mermaid`, comparação tabelas/views com o manifesto (`manaloom_tbls_local_gate.sh:68-202`). `dart doc --check` em `quality_gate.sh:333`.
