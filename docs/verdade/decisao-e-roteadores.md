# Auditoria documental — grupo "Decisão de produto, contexto e roteadores de entrada"

- Data da auditoria: 2026-09-22
- HEAD auditado: `d15beb05b` (branch `codex/free-beta-release-candidate-2026-07-17`), árvore com
  `docs/generated/*`, `project_logic_manifest.json` e `server/routes/community/marketplace/index.dart`
  modificados e não commitados (`git status` de abertura).
- Método: leitura integral dos 10 documentos pedidos; cada afirmação verificável conferida em
  código, registry gerado, `git log/show`, disco ou documento de autoridade maior. Nenhum teste,
  build ou servidor foi executado. Nada foi escrito no repositório.

## 0. Documento inexistente

`CLAUDE.md` **não existe** no repositório nem nunca existiu:
`find . -maxdepth 3 -iname CLAUDE.md` vazio; `git ls-files | grep -i claude.md` vazio;
`git log --all --name-only | grep -i claude.md` vazio; não há diretório `.claude/`.
A única instrução com esse nome é a memória do usuário fora do repo
(`~/.claude/projects/.../memory/MEMORY.md`), que não é documento do projeto.
Veredito: nada a corrigir; o índice do grupo deve parar de listá-lo.

## 1. Tabela-resumo

| Documento | Lifecycle (contrato) | Veredito | Afirmações | Erradas/defasadas | Ação |
| --- | --- | --- | ---: | ---: | --- |
| `docs/status/CURRENT_PRODUCT_DECISION.md` | `current_decision` (override) | **CORRIGIR** | 34 | 3 | 3 correções pontuais de texto (abaixo); matriz e destinos batem com o código |
| `docs/CONTEXTO_PRODUTO_ATUAL.md` | `current_context` (canônico + override) | **CORRIGIR** | 61 | 14 | manter só o cabeçalho + "Decisão vigente 2026-08-25" + "Atualização 2026-08-12" como corrente; mover tudo de 2026-07-30 para trás para `docs/archive/` com cabeçalho histórico |
| `README.md` | `current_context` (override) | **CORRIGIR** | 14 | 1 | acrescentar `server/config/release_capabilities.json` à tabela de fontes; resolver o estado de `AGENTS.md` |
| `docs/README.md` | `current_context` (override) | **CORRIGIR** | 33 | 1 (+4 omissões) | indexar os 4 canônicos ausentes, `docs/flows/` e `docs/design/` como apoio, e o registry de tasks |
| `AGENTS.md` | **nenhum** → default `supporting_reference_non_authoritative` | **CORRIGIR** (no contrato, não no texto) | 13 | 1 | dar override `current_contract` em `docs/project_logic_contracts.json` ou rebaixar o texto de "contrato obrigatório" |
| `.github/AGENT_POLICY.md` | `current_contract` (canônico) | **MANTER** | 12 | 0 | — |
| `.github/instructions/guia.instructions.md` | `current_context` (override + prefixo) | **MANTER** | 8 | 0 | — |
| `.github/instructions/roadmap.instructions.md` | `current_context` (override + prefixo) | **MANTER** | 5 | 0 | — |
| `ROADMAP.md` | `historical_evidence` (override) | **MANTER** (já marcado) | 10 | 0 no cabeçalho; corpo é histórico declarado | opcional: trocar "contexto operacional" por "roteador de contexto" no link para CONTEXTO |
| `CLAUDE.md` | — | **NÃO EXISTE** | 0 | 0 | remover da lista de documentos do grupo |

Total: 190 afirmações verificadas; 20 divergências (10,5 %).

## 2. Divergências por documento

Formato: linha | afirmação | classificação | evidência | verdade atual | ação | texto corrigido.

### 2.1 `docs/status/CURRENT_PRODUCT_DECISION.md`

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 23-25 | "App Web: rota reservada `/app` … permanece **inacessível** enquanto a matriz … estiver totalmente `OFF`" | **CONTRADIZ_OUTRO_DOC** (contradiz a própria linha 59 e o mapa) | `server/lib/release_capability_policy.dart:596-620` lista o plano de controle sem capability (`POST /auth/login`, `/auth/forgot-password`, `/auth/reset-password`, `/auth/verify-email`, `GET/PATCH/DELETE /users/me`, `GET /users/me/export`, `GET /users/me/plan`); `docs/MAPA_OPERACIONAL_DO_PROJETO.md:77` mede **10 rotas alcançáveis** no app (`/`, `/login`, `/forgot-password`, `/reset-password`, `/verify-email`, `/legal`, `/home`, `/onboarding/core-flow`, `/plans`, `/profile`); `docs/flows/auth_session.md:13` "única jornada alcançável". A própria linha 59 diz que login/recuperação/exportação/exclusão estão "Disponível". | O shell Flutter em `/app` carrega e o plano de controle de conta responde para contas pré-existentes; **nenhuma capability de produto** responde (29/29 `off`, `server/config/release_capabilities.json`). "Inacessível" é falso para o shell e verdadeiro para o produto. | corrigir | "App Web: rota reservada `/app` na origem canônica. Enquanto a matriz server-authoritative estiver totalmente `OFF`, nenhuma superfície pública aponta para `/app`, nenhuma capability de produto responde e `/app` só serve o plano de controle de conta (login, recuperação, verificação, perfil, exportação e exclusão) para contas pré-existentes; auto-cadastro continua `OFF`." |
| 93 | "A rota **planejada** é `/decks/:id/play-vs-ai[/sessionId]`" | **DEFASADO** (redação) | `app/lib/main.dart:677` (`path: 'play-vs-ai/:sessionId'`) e `:692` (`path: 'play-vs-ai'`) existem desde `f6f791098` (2026-09-18), o mesmo commit que escreveu a frase; `/decks/:id/battle-coach[/:sessionId]` são redirects em `main.dart:706,715`; compilada só com `ENABLE_INTERACTIVE_BATTLE` (`app/lib/core/config/launch_features.dart:32`) e guardada por `battle_coach` (`app/lib/core/config/release_capabilities.dart:403-407`). | A rota está implementada e guardada, não "planejada". | corrigir | "A rota é `/decks/:id/play-vs-ai[/:sessionId]` (`app/lib/main.dart:677,692`), compilada apenas com `ENABLE_INTERACTIVE_BATTLE=true` e guardada por `battle_coach`; `/decks/:id/battle-coach[/:sessionId]` sobrevive apenas como redirect de compatibilidade (`main.dart:706,715`)." |
| 56-69 | Matriz com 12 linhas cobre as capabilities do servidor | **DEFASADO** (omissão) | `server/config/release_capabilities.json` tem **29** chaves; a matriz não representa `legacy_ai_routes` (`contained_legacy`, off) nem `deck_replace_all` (`implemented_guarded`, off). Os vocábulos `OFF_UNTIL_P0_RECEIPT` e `Disponível` não existem no JSON, que só conhece `release_capability: "off"|"on"` + `implementation_status` (`release_capability_policy.dart:318-322` invalida qualquer outra combinação). | 27 de 29 capabilities têm linha; duas não. O rótulo `OFF_UNTIL_P0_RECEIPT` é semântica da decisão, o valor executável é `off` + `implemented_p0_open`/`experimental_p0_open`. | corrigir | Acrescentar duas linhas: "\| Rotas de IA legadas (`/ai/ml-status`, `/ai/simulate-matchup`, `/ai/weakness-analysis`, `/ai/optimize/telemetry`, recommendations/simulate de deck) \| Contenção legada, sem chamador no app \| `OFF` \| `null` \|" e "\| Substituição integral de deck (`PUT /decks/:id`) \| Implementado e guardado \| `OFF` \| `null` \|". Acrescentar nota sob a tabela: "`OFF_UNTIL_P0_RECEIPT` e `Disponível` são rótulos desta decisão; no artefato executável (`server/config/release_capabilities.json`) o valor é sempre `off` ou `on`, e `allowed` tem de ser igual a `release_capability == 'on'`." |

Afirmações **CORRETAS** que sustentam o restante do documento (31): ver §3.

### 2.2 `docs/CONTEXTO_PRODUTO_ATUAL.md` (816 linhas)

Estrutura real: linhas 1-33 (cabeçalho + "Decisão vigente 2026-08-25") e 34-42 ("Atualização de prioridade 2026-08-12") são correntes e batem com a decisão. Linhas 44-218 são cinco registros datados (2026-07-30, 07-26, 07-23 ×2 e a "sequência oficial daquela rodada"), já autodescritos como históricos. Linhas 220-816 são um `<details>` "Histórico acumulado" de março a junho de 2026. **Só 42 de 816 linhas (5 %) descrevem o estado corrente.**

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 31 | "migration `058`, com `58` migrations" | CORRETO | `project_logic_manifest.json` → `database.migration_count=58`, `latest_migration="058"`; `docs/generated/CURRENT_SYSTEM.md:33` | — | nenhuma | — |
| 54 | "contrato atual `v20`" | CORRETO | `server/lib/ai/optimize_cache_support.dart:13` `optimizeCacheContractVersion = 'v20'` | — | nenhuma | — |
| 58 | "`commander_functional_role_floors_v3`" | CORRETO | `server/lib/ai/optimize_functional_role_support.dart` contém o identificador | — | nenhuma | — |
| 101 | "site público com 13 rotas" | **DEFASADO** | `docs/generated/CURRENT_SYSTEM.md:30` `web_routes = 11`; `find web-public/src/app` = 9 `page.tsx` + `healthz/route.ts` + `robots.ts` + `sitemap.ts` | 11 rotas geradas | marcar_historico | Já está sob "Registro histórico de implementação"; basta o cabeçalho de lifecycle proposto abaixo |
| 101 | "1.252 testes Flutter + 1 skip" | NAO_VERIFICAVEL (não rodar testes); `CURRENT_SYSTEM.md:36` conta 1221 arquivos de teste no total, não casos | — | marcar_historico | — |
| 120-121 | "Scanner/câmera ficam desabilitados e inacessíveis no artefato de release" | CORRETO | `app/lib/core/config/launch_features.dart:8-9` (`ENABLE_SCANNER_RELEASE`, default off) + `main.dart:607` (`if (LaunchFeatures.scannerSupported)`) + `scanner` off no JSON | — | nenhuma | — |
| 113-118 | commits `2139ec9f6`, `bf035b7f1`, `b84302e1e` "validados e publicados" | CORRETO (existem) | `git cat-file -t` = commit para os três | — | nenhuma | — |
| 152 | "os 25 contratos de release" | NAO_VERIFICAVEL | `scripts/manaloom_release_ops_contract_test.sh` não expõe contagem estática | — | marcar_historico | — |
| 152 | "Flutter 3.44.6/Dart 3.12.2 pinados" | CORRETO (pin existe) | `scripts/manaloom_binder_import_visual_qa.sh:5-6` `flutter-3.44.6` | — | nenhuma | — |
| 195 | "migrations 038–055 compõem o schema exigido por este checkout" | **DEFASADO** | manifesto: versões até `058` (`056 expand_battle_job_async_timeout`, `057`, `058 snapshot_trade_item_identity`) | 058 | marcar_historico | A linha 31 já corrige; a seção é histórica |
| 246 | "`25` telas Flutter em `app/lib/features/**/screens`" | **DEFASADO** | `find app/lib/features -path '*/screens/*' -name '*_screen.dart' \| wc -l` = **39** | 39 arquivos `*_screen.dart` | marcar_historico | — |
| 261 | `CHECKLIST_GO_LIVE_FINAL.md` | **ERRADO** (arquivo não existe) | removido em `23cfc0611` (2026-05-31, "archive 9 historical .md files to archive_docs/root/") | não existe no HEAD | marcar_historico | — |
| 262 | `RELATORIO_VALIDACAO_2026-03-16.md` | **ERRADO** (arquivo não existe) | idem `23cfc0611` | não existe | marcar_historico | — |
| 287, 309 | `server/routes/ai/optimize/index.dart` "2745"/"2721" linhas | **DEFASADO** | `wc -l` = **3337** | 3337 | marcar_historico | — |
| 288 | `optimize_runtime_support.dart` "2842" linhas (e 593: "2.718") | **DEFASADO** | `wc -l` = **578** | 578 | marcar_historico | — |
| 315-348, 356, 666, 782 | `deck_details_screen.dart` "3587 → … → 1445" e "1.705 no último audit" | **DEFASADO** | `wc -l` = **2697** | 2697 | marcar_historico | — |
| 337-401, 667, 783 | `deck_provider.dart` "1560 → … → 899" e "899→1.226" | **DEFASADO** | `wc -l` = **1650** | 1650 | marcar_historico | — |
| 359, 370 | `deck_provider_support.dart` "883"/"1098" linhas | **DEFASADO** | `wc -l` = **6** (virou barrel; os seis módulos `deck_provider_support_{common,fetch,mutation,ai,import,generation}.dart` existem — linha 784-790 já diz isso) | barrel de 6 linhas | marcar_historico | — |
| 490-491, 451-503 | `app/lib/features/home/life_counter_screen.dart` e `life_counter_screen_test.dart` | **ERRADO** (caminho não existe) | removidos em `d08985bca` (2026-07-01, "Audit and remove dead app surfaces"); o contador é `app/lib/features/home/lotus_life_counter_screen.dart` (5084 linhas, desde `96105406f` 2026-03-29) e `app/test/features/home/lotus_life_counter_screen_test.dart` | Lotus Life Counter | marcar_historico | — |
| 584 | "Hermes Agent operacional com 14 crons ativos" | NAO_VERIFICAVEL (runtime externo) | — | — | marcar_historico | — |
| 622-624 | "dart test 613/613", "flutter test 589/592" | NAO_VERIFICAVEL (não rodar) e já rotulado `HISTORICAL_SNAPSHOT` | — | — | marcar_historico | — |
| 630-634 | `server/routes/ai/generate`, `optimize`, `rebuild` | CORRETO | `ls server/routes/ai` | — | nenhuma | — |
| 640-651 | superfícies `cards … life_counter` como diretórios | **DEFASADO** parcial | `ls app/lib/features`: existem `auth battle binder cards collection commercial community decks growth home market messages notifications profile retention scanner social trades`; **não existe** `life_counter/` (vive em `home/`), e `battle`, `commercial`, `growth`, `retention` não estão listadas | lista atual acima | marcar_historico | — |
| 670 | "25 telas, ~592 testes widget/unit, 103 smoke integration tests" | **DEFASADO** | 39 telas; 1221 arquivos de teste no manifesto | — | marcar_historico | — |
| 758-760 | `server/test/ai_optimize_flow_test.dart`, `ai_generate_create_optimize_flow_test.dart`, `server/run_optimize_validation.ps1` | CORRETO (existem) | `ls` | — | nenhuma | — |
| 506-527 | `server/lib/observability.dart`, `server/lib/request_trace.dart`, `app/lib/core/observability/app_observability.dart`, `server/routes/ready/index.dart`, `scripts/validate_*` | CORRETO (existem) | `ls` | — | nenhuma | — |

Cabeçalho de lifecycle a inserir no bloco que vai para `docs/archive/CONTEXTO_PRODUTO_ATUAL_HISTORICO_2026-03-23_a_2026-07-30.md` (linhas 44-816 atuais):

```
Lifecycle: `HISTORICAL_EVIDENCE · SUPERSEDED · NO_PRIORITY_AUTHORITY · NO_MUTATION_AUTHORITY`
Origem: corpo de `docs/CONTEXTO_PRODUTO_ATUAL.md` até o HEAD `d15beb05b` (2026-09-22).
Contagens de linhas, telas, testes e rotas refletem as datas de cada seção e não o checkout atual.
Caminhos que deixaram de existir: `CHECKLIST_GO_LIVE_FINAL.md`, `RELATORIO_VALIDACAO_2026-03-16.md`
(removidos em 23cfc0611), `app/lib/features/home/life_counter_screen.dart` (removido em d08985bca).
```

O arquivo `docs/CONTEXTO_PRODUTO_ATUAL.md` fica com as linhas 1-42 mais um ponteiro para o
arquivo histórico. O prefixo `docs/archive/` já recebe `historical_evidence` pela
`prefix_rules` do contrato, então nenhuma mudança em `project_logic_contracts.json` é necessária
além de rodar `manaloom_project_logic.sh --write/--check`.

### 2.3 `README.md`

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 13 | "`AGENTS.md` — contrato obrigatório para qualquer agente" | **CONTRADIZ_OUTRO_DOC** | `docs/project_logic_contracts.json` → `documentation_lifecycle`: `AGENTS.md` não está em `canonical_documents` (36 entradas) nem em `document_overrides`; `TASK_REGISTRY.json.documentation_lifecycle` resolve-o ao `default_state = supporting_reference_non_authoritative`. Enquanto isso `.github/AGENT_POLICY.md:13` manda "ler `AGENTS.md`" primeiro e `AGENTS.md:3-5` se declara contrato acima dos perfis. | O registry gerado classifica `AGENTS.md` como apoio não autoritativo. | corrigir (no contrato) | Em `docs/project_logic_contracts.json.documentation_lifecycle.document_overrides` inserir `{"path": "AGENTS.md", "state": "current_contract", "reason": "mandatory agent contract that routes to the current decision and task index; no priority authority"}` e regenerar. Alternativa (pior): rebaixar o texto do README para "roteador de agente". |
| 26-34 | Tabela "Fontes de verdade" sem linha para a matriz de capabilities | DEFASADO (omissão) | A verdade executável de capability é `server/config/release_capabilities.json` (29 chaves, `policy_version brewtact_free_beta_2026-08-13`), carregada por `server/lib/release_capability_policy.dart` e espelhada em `app/lib/core/config/release_capabilities.dart`. | — | corrigir | Acrescentar linha: "\| Capabilities de release \| `server/config/release_capabilities.json` (server-authoritative, default-deny) e a matriz em `docs/status/CURRENT_PRODUCT_DECISION.md` \|" |

Correto: `ManaLoom` como nome técnico interno (ADR 0010); ausência de GitHub Actions (`.github/` só tem `AGENT_POLICY.md`, `agents/`, `instructions/`); os três comandos de hooks (`scripts/manaloom_install_local_hooks.sh:22-38` instala `pre-commit`→`quick` e `pre-push`→`full`, `.githooks/pre-commit`, `.githooks/pre-push`); `manaloom_project_logic.sh --write|--check` (`:28-31`); modos `schema|e2e|release` (`manaloom_local_ci.sh:237-253`); manifesto tem `semantic_analysis` e `lineage` (chaves do JSON); todos os 6 links de "Comece por aqui" existem.

### 2.4 `docs/README.md`

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 9-52 | Índice "separa decisão, execução, estrutura, contratos" — mas **não lista 4 documentos canônicos** | **DEFASADO** (omissão) | `grep -c` de `MAPA_OPERACIONAL`, `DECK_QUALITY_MODEL`, `APP_AI_KNOWLEDGE_BRIDGE`, `UI_TEST_SURFACE_MAP` em `docs/README.md` = 0 para os quatro; todos estão em `canonical_documents` (`docs/MAPA_OPERACIONAL_DO_PROJETO.md` e `docs/DECK_QUALITY_MODEL.md` adicionados em `38d985f92`/`eb531386f`, 2026-09-18). Também não menciona `docs/generated/TASK_REGISTRY.json`, `docs/flows/`, `docs/design/` nem `docs/PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md`. | Índice está 4 canônicos e 3 conjuntos de apoio atrás. | corrigir | Na seção 2 acrescentar "- [Registry de tasks](generated/TASK_REGISTRY.json)". Na seção 3 acrescentar "- [Mapa operacional](MAPA_OPERACIONAL_DO_PROJETO.md) — medições estáticas de 2026-09-18, sem autoridade de prioridade" e "- [Mapa de superfícies de teste de UI](../app/doc/UI_TEST_SURFACE_MAP.md)". Na seção 4 acrescentar "- [Modelo de qualidade de deck](DECK_QUALITY_MODEL.md)" e "- [Ponte app↔IA](hermes-analysis/APP_AI_KNOWLEDGE_BRIDGE_CONTRACT_2026-07-06.md)". Nova seção "6b. Apoio não canônico (2026-09-21)": "`flows/` — 11 fluxos com verificação adversarial estática; `design/visual-audit-2026-09-21/` — auditoria visual; `PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md` — ponto de retomada. Nenhum define prioridade." |

Correto: precedência e lifecycle mínimo (7 estados = `documentation_lifecycle.states`); "registry de lifecycle é gerado a partir de `docs/project_logic_contracts.json`" (`TASK_REGISTRY.json.documentation_lifecycle` existe e é derivado); todos os 33 caminhos linkados existem (verificação por `ls`, ver §3).

### 2.5 `AGENTS.md`

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 3-5 | "este contrato" prevalece sobre perfis `.github/` | **CONTRADIZ_OUTRO_DOC** | mesma evidência de §2.3 linha 13: sem lifecycle, o documento é `supporting_reference_non_authoritative` pelo registry gerado | — | corrigir (no contrato) | idem §2.3 |

Correto: os 11 perfis em `.github/agents/` citam `AGENT_POLICY` (`grep -l` = 11/11); sem GitHub Actions; hooks e modos; o gate de schema é exatamente o descrito (`scripts/manaloom_tbls_local_gate.sh:12-115`: `mktemp -d` em `/tmp`, `initdb`, `pg_ctl … -h 127.0.0.1`, `dart run bin/migrate.dart`, `tbls`, `trap cleanup` com `pg_ctl stop`; `:25` "BLOCKED: o gate cria somente um PostgreSQL local descartável em /tmp"); três níveis `PASS_AUTOMATED/PASS_RUNTIME/PASS_VISUAL_REVIEWED` (`docs/MANALOOM_UI_LIVE_EVIDENCE_CONTRACT.md:12-18`); `./scripts/quality_gate.sh ui-proof` (`quality_gate.sh:374,434`). "Dart/Flutter MCP" é instrução, não fato.

### 2.6 `.github/AGENT_POLICY.md` — sem divergência

Verificado: lifecycle `current_contract` (canônico + override); WIP 1 = `TASK_REGISTRY.execution_ledger.wip_limit=1`, `active_slot_count=1`; caminhos das linhas 13-19 existem; "XMage é a fonte executável primária pinada; Forge cobre gaps estruturados" = `docs/hermes-analysis/EXTERNAL_ENGINE_CAPABILITY_CONTRACT.json:30` (`runtime_role: primary_external_rules_executor`) e `:231` ("Forge is attempted only for structured XMage coverage gaps"); default-deny = 29/29 `allowed:false`; "semantic_analysis e lineage" são chaves do manifesto.

### 2.7 `.github/instructions/guia.instructions.md` — sem divergência

Os 7 caminhos existem; estado `current_context` bate com override e prefixo; ordem de leitura coincide com `AGENT_POLICY.md:11-20`.

### 2.8 `.github/instructions/roadmap.instructions.md` — sem divergência

Backlog e fila existem; "CURRENT_QUEUE é derivada" = `TASK_REGISTRY.execution_ledger.authority` todos `false`; "até receber lifecycle corrente no registry gerado" descreve exatamente `documentation_lifecycle`.

### 2.9 `ROADMAP.md` — já histórico

Cabeçalho `HISTORICAL_EVIDENCE · SUPERSEDED · NO_PRIORITY_AUTHORITY · NO_MUTATION_AUTHORITY` bate com o override e com `guards.historical_header_markers`. Os 4 links de topo e os 6 de apoio existem. O corpo (`Commander-first`, `generate -> analyze -> optimize -> rebuild -> validate` como entrega) contradiz a decisão corrente (Generate/Rebuild `OFF`, `ai_generate_rebuild experimental_guarded`), mas o documento avisa isso nas linhas 3-15. Nit opcional na linha 79: "contexto operacional" → "roteador de contexto (corpo histórico)". Não remover: está referenciado pelo contrato com razão explícita.

## 3. Fatos confirmados (tabela de verdade)

Cada linha foi conferida na fonte primária nesta rodada.

### Decisão, oferta e destinos

1. Estado de release `NO_GO_PUBLIC_RELEASE`, candidato `CONTROLLED_FREE_BETA`, Web + Android, iOS/VoiceOver `DEFERRED_BY_SCOPE` — `docs/status/CURRENT_PRODUCT_DECISION.md:5-9`; coerente com 29/29 capabilities `off` (`server/config/release_capabilities.json`).
2. A decisão foi datada `2026-08-25` e o arquivo foi editado pela última vez em `f6f791098` (2026-09-18), que trocou a data de `2026-08-13` para `2026-08-25`, renomeou a linha Battle e acrescentou a seção "Direção de produto para Battle" (`git show f6f791098 -- docs/status/CURRENT_PRODUCT_DECISION.md`). ADR 0013 tem `Data: 2026-08-25` (`docs/adr/0013-…:4`).
3. Origem pública canônica `https://brewtact.com`: `docs/adr/0011-brewtact-production-domain.md:21`, `web-public/src/lib/routes.ts:1-2` (`currentPublicSiteFallbackUrl`), `server/lib/public_site_url.dart:1`.
4. Host técnico Web `evolution-manaloom-web-public.2ta7qx.easypanel.host`: `scripts/lib/manaloom_release_runtime_contract.sh:5`, `scripts/manaloom_deploy_flutter_web.sh:65`, `scripts/manaloom_deploy_backend_image.sh:79` (`LEGACY_WEB_ORIGIN`).
5. API `https://evolution-cartinhas.2ta7qx.easypanel.host`: `app/lib/core/api/api_client.dart:43-44` (`_serverFallbackUrl`), ADR 0011 item 7.
6. App Web publicado sob `/app/`: `scripts/manaloom_deploy_flutter_web.sh:317` (`--base-href /app/`), `:154,166` (smoke em `$PUBLIC_BASE_URL/app/release.json` e `/app/flutter_bootstrap.js`).
7. Site público não linka `/app`, não oferece CTA e mostra "Acesso ainda não liberado": `web-public/src/components/ui.tsx:23-39` (`AccessPending`, `role="status"`, sem `href`); `grep -rn -- '/app' web-public/src` só encontra `/branding/app_logo.png` e `robots.ts:10` (`disallow: /app/private`); o contrato `web-public/tests/free-beta-offer-contract.mjs:35-52` proíbe `href="/app"`, `routes.app`, "Abrir app/BrewTact" e exige `<AccessPending` em `site-shell.tsx`, `page.tsx`, `pricing/page.tsx`, `reports/[id]/page.tsx`.
8. Oferta única "Beta gratuita", "Sem cobrança durante a beta", sem Pro/preço/upgrade/marketplace/social/trade no site: `web-public/src/lib/product-data.ts:39-41`, `web-public/src/app/pricing/page.tsx:26-28`; o teste `free-beta-offer-contract.mjs:20-33` proíbe `\bpro\b`, `price|preç`, `upgrade`, `mercado`, `marketplace`, `social`, `trades?|trocas?`. O caminho `/pricing` existe, mas é informativo (`routes.ts:33`).
9. Teto de 120 ações de IA por mês UTC no backend: `server/lib/plan_service.dart:94` (`freeBetaAiMonthlyOperationalLimit = 120`), `:261`, `:276-286` (`date_trunc('month', NOW() AT TIME ZONE 'UTC')`); exposto em `plan_middleware.dart:107` (`ai_monthly_limit`). A landing só diz "Os limites operacionais vigentes aparecem no ambiente autenticado" (`product-data.ts:54`).
10. Billing fail-closed: `POST /users/me/plan/checkout` e `POST /billing/webhook` são classificados como `billing_checkout` (`server/lib/release_capability_policy.dart:519-523`) e essa capability está `off` → 404 `capability_unavailable` antes do handler; nenhum chamador no app (`docs/flows/commercial_plans.md:18,46,103`).

### Matriz de capabilities (executável)

11. `server/config/release_capabilities.json`: `policy_version brewtact_free_beta_2026-08-13`, `offer_mode free_beta_no_commerce`, **29 capabilities, 29 com `release_capability: "off"` e `allowed: false`, 29 com `live_verified_as_of: null`** (contagem por `python3`). Distribuição de `implementation_status`: 18 `implemented_guarded`, 4 `implemented_p0_open` (`catalog_private`, `decks_private`, `collection_private`, `life_counter_local`), 3 `contained_legacy` (`learning_reads`, `learning_writes`, `legacy_ai_routes`), 2 `not_implemented` (`ads`, `art_paywall`), 1 `experimental_p0_open` (`ai_analyze_optimize_advisory`), 1 `experimental_guarded` (`ai_generate_rebuild`).
12. Mapeamento linha-a-linha da matriz da decisão para o JSON: cadastro→`account_registration` ✓; catálogo/coleção/deck manual→`catalog_private`,`collection_private`,`decks_private` (`implemented_p0_open`) ✓; Analyze/Optimize→`ai_analyze_optimize_advisory` (`experimental_p0_open`) ✓; Generate/Rebuild→`ai_generate_rebuild` (`experimental_guarded`) ✓; Life Counter→`life_counter_local` ✓; Battle→`battle_batch`,`battle_live`,`battle_coach` ✓; Scanner→`scanner` ✓; social→`gallery_public`,`profiles_public`,`user_search`,`comments`,`follows`,`direct_messages`,`social_push` ✓; binder/marketplace/trades→`binder_public`,`marketplace`,`trades` ✓; comércio→`billing_checkout`,`subscriptions`,`ads`,`art_paywall` ✓; aprendizado→`learning_reads`,`learning_writes` ✓. Fora da matriz: `legacy_ai_routes`, `deck_replace_all`.
13. Política fail-closed no carregamento: qualquer entrada com `allowed != (release_capability == 'on')` invalida o arquivo inteiro (`release_capability_policy.dart:318-322` → `_invalidPolicy`, `configuration_status: invalid_fail_closed`).
14. Plano de controle sem capability (`release_capability_policy.dart:596-620`): `/health*`, `POST /auth/login|forgot-password|reset-password|change-password|resend-verification|revoke-sessions|verify-email`, `GET /auth/me`, `GET|PATCH|DELETE /users/me`, `GET /users/me/export`, `GET /users/me/plan`, `GET /users/me/blocks`, activation-events, `DELETE /users/me/fcm-token`, `POST /content-reports`, `GET /moderation/reports`. `POST /auth/register` exige `account_registration` (`:385-387`).
15. Scanner só entra no artefato com `--dart-define=ENABLE_SCANNER_RELEASE=true` (`app/lib/core/config/launch_features.dart:8-9`, `main.dart:607`); Jogar contra IA só com `ENABLE_INTERACTIVE_BATTLE=true` (`launch_features.dart:32`, `main.dart:107,675,690`).

### Battle

16. Rotas `/decks/:id/play-vs-ai` e `/decks/:id/play-vs-ai/:sessionId` existem (`app/lib/main.dart:692,677`); `/decks/:id/battle-coach[/:sessionId]` são redirects (`:715,706`). Landed em `f6f791098` (2026-09-18).
17. Não existe `GoRoute` de espectador: `battleLiveRouteLocation` gera `/decks/{id}/battle-live/{jobId}` sem rota correspondente e `app/test/core/config/release_capability_surface_contract_test.dart:109-119` proíbe o roteador de construir `BattleLiveSpectatorScreen` (`docs/flows/battle_replay.md:22,79,95`).
18. Cobertura XMage interativa é checada no preflight (`server/lib/battle/battle_preflight_service.dart:110-128,540-581` via `InteractiveBattleCoverageClient`); `server/lib/battle/interactive_battle_service.dart` e `interactive_battle_runtime_client.dart` não contêm "forge" (`grep`); Forge só aparece no caminho batch (`battle_execution_runtime.dart:220`).
19. Receipt focal `docs/qa/execution/2026-08-25/play-vs-ai-real-xmage-e2e.md`: `PASS` do runner (`:12`), nove checkpoints/capturas (`:18,72-74`), `release_ready=false`, `strategy_superiority_proven=false` (`:19-20`), HEAD `406d7dd53` (existe: "Harden server release capability boundary", 2026-08-25), lifecycle `FOCAL_PASS · NOT_TASK_CLOSURE · NOT_RELEASE` (`:3`); o `report.json` bruto está fora do repo (`~/Library/Application Support/ManaLoom/e2e/…`). O receipt foi commitado só em `f6f791098` (2026-09-18).

### Trabalho corrente

20. `docs/generated/TASK_REGISTRY.json`: 220 tasks; status = 86 `TODO`, 77 `BLOCKED_BY_P0`, 33 `DEFERRED_BY_SCOPE`, 10 `IN_PROGRESS_CONTAINED`, 7 `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`, 4 `WAITING_EXTERNAL`, **3 `PASS`** (`BT-GOV-001`, `BT-DOC-001`, `BT-DOC-004`, todos do Épico A).
21. Slot `NOW` = `BT-SCP-001` (`IN_PROGRESS_CONTAINED`, dep `BT-GOV-001` PASS) — `docs/execution/CURRENT_QUEUE.md:26` (atualizada 2026-09-09) e `TASK_REGISTRY.execution_ledger.active_slot`. `BT-SCP-001` pertence à "Onda 0 — verdade executável" (`docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:660-662`), logo "O trabalho atual é a Onda 0" (decisão :111) é verdadeiro.
22. Onda 0 = `BT-GOV-001` PASS, `BT-SCP-001` IN_PROGRESS_CONTAINED, `BT-OFFER-001` IMPLEMENTED_LOCAL_PENDING_FULL_GATE, `BT-DOC-001` PASS, `BT-DOC-004` PASS, `BT-GATE-001` e `BT-GATE-002` IMPLEMENTED_LOCAL_PENDING_FULL_GATE.
23. `BT-UIEV-001`, usado como Task ID em três commits recentes (`d08c18717`, `9a9ba66de`, `b397f477b`), **não existe** no backlog (`grep -c` = 0) nem no registry; só aparece em `docs/execution/PROPOSED_TASKS_DECK_QUALITY_2026-09-18.md`. (Fato fora do grupo, relevante para a divergência de dados.)
24. `BT-PLAY-001`/`BT-PLAY-002` estão `BLOCKED_BY_P0` (registry, linhas 472-473 do backlog).

### Estrutura e gates

25. Migrations: 58, última `058 snapshot_trade_item_identity` (`project_logic_manifest.json.database`, fonte `server/bin/migrate.dart`); `056 expand_battle_job_async_timeout`, `055 create_interactive_battle_sessions`.
26. `docs/generated/CURRENT_SYSTEM.md:28-36`: `app_routes 46`, `web_routes 11`, `api_routes 121`, `database_tables 79`, `views 6`, `tests 1221`, `flows 8`, `tasks 220`. `grep -c 'GoRoute(' app/lib/main.dart` = 46 (bate com o mapa).
27. Não há GitHub Actions (`.github/` = `AGENT_POLICY.md`, `agents/`, `instructions/`); hooks versionados `.githooks/pre-commit` → `manaloom_local_ci.sh quick`, `.githooks/pre-push` → `full`; modos `quick|schema|full|e2e|release` (`manaloom_local_ci.sh:237-259`).
28. `docs/project_logic_contracts.json`: 36 `canonical_documents`, todos existem no disco; `documentation_lifecycle` com 7 estados, 17 `document_overrides`, 9 `prefix_rules`, `default_state = supporting_reference_non_authoritative`; `guards.current_priority_precedence = [current_decision, current_task_index]`.
29. `AGENTS.md` não tem entrada de lifecycle (nem canônico, nem override, nem prefixo) → estado default não autoritativo, apesar de ser o primeiro documento exigido por `AGENT_POLICY.md:13`.
30. `docs/MAPA_OPERACIONAL_DO_PROJETO.md` é canônico `current_contract` no contrato, mas seu próprio cabeçalho diz `NO_AUTHORITY · NOT_RATIFIED` (`:3`) — contradição a resolver no grupo do mapa.
31. `docs/generated/CURRENT_SYSTEM.md`, `TASK_REGISTRY.json`, `openapi.generated.json` e `project_logic_manifest.json` estão modificados e não commitados no checkout (`git status`), portanto os números acima são do regenerado local, não do HEAD.
32. Arquivos removidos que ainda são citados: `CHECKLIST_GO_LIVE_FINAL.md` e `RELATORIO_VALIDACAO_2026-03-16.md` (removidos em `23cfc0611`, 2026-05-31); `app/lib/features/home/life_counter_screen.dart` (removido em `d08985bca`, 2026-07-01; substituto `lotus_life_counter_screen.dart`).
33. Todos os outros 70+ caminhos citados pelos documentos do grupo existem (verificação por `ls` em lote; lista completa no log desta auditoria).

## 4. Ordem sugerida de correção (menor risco primeiro)

1. Contrato: override `current_contract` para `AGENTS.md`; regenerar project logic.
2. `docs/status/CURRENT_PRODUCT_DECISION.md`: três correções de texto de §2.1.
3. `README.md` e `docs/README.md`: linhas/links de §2.3 e §2.4.
4. `docs/CONTEXTO_PRODUTO_ATUAL.md`: cortar em 42 linhas e mover o resto para `docs/archive/` com o cabeçalho de §2.2.
5. Retirar `CLAUDE.md` de qualquer índice ou lista de grupo.
