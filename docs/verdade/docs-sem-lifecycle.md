# Auditoria de verdade — Grupo: documentos antigos sem cabeçalho de ciclo de vida

Data da auditoria: 2026-09-22 · Checkout: `codex/free-beta-release-candidate-2026-07-17` @ `d15beb05b` (working tree com alterações não commitadas em `docs/generated/*`, `project_logic_manifest.json`, `server/routes/community/marketplace/index.dart`).
Modo: somente leitura no repo. Evidência = `arquivo:linha`, saída de comando ou commit.

## 0. Regra que governa este grupo (fonte primária)

- `docs/project_logic_contracts.json` → `documentation_lifecycle.default_state = supporting_reference_non_authoritative`. **Nenhum dos 16 documentos deste grupo aparece em `document_overrides` (17 entradas) nem casa com `prefix_rules` (9 prefixos)**. Logo, o estado registrado de todos os 16 hoje é `supporting_reference_non_authoritative`, mesmo os três que já trazem banner "HISTORICAL" no corpo (comando: `python3` sobre o JSON; lista de overrides impressa na sessão).
- Só `current_decision` (`docs/status/CURRENT_PRODUCT_DECISION.md`) e `current_task_index` (`docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md`) definem prioridade (`guards.current_priority_precedence`).
- Para um documento entrar em `document_overrides` como `historical_evidence`, o gerador exige que as **16 primeiras linhas** contenham os dois marcadores `HISTORICAL_EVIDENCE` e `NO_MUTATION_AUTHORITY` (case-insensitive), senão falha fechado: `tools/project_logic/lib/project_logic_generator.dart:1226-1262` (`_validateHistoricalDocumentBanners`). Regra de prefixo (`docs/archive/`) **não** passa por essa validação — só overrides.
- Precedente de arquivamento: `docs/archive/2026-03/` já guarda 2 docs de março movidos em `2a727c801` (2026-05-15). `archive_docs/root/` guarda 14 docs de raiz movidos em `23cfc0611` (2026-05-31) — porém `archive_docs/` **não** tem regra de prefixo no contrato (fica em `supporting_reference_non_authoritative` por default).
- Regra dada pelo coordenador: documento citado por documento canônico não pode ser removido, só marcado. `docs/CONTEXTO_PRODUTO_ATUAL.md` é canônico (`current_context`) e cita 10 dos 16 (linhas 254, 255, 256, 257, 258, 508, 512, 561, 810, 811). Esses 10 ficam no lugar e recebem banner.

## 1. Tabela-resumo

| # | Documento | Veredito | Afirmações verificadas | Erradas/defasadas | Citado por canônico? | Ação |
| --- | --- | --- | ---: | ---: | --- | --- |
| 1 | `docs/AUDITORIA_RUIDO_VISUAL_CORES_2026-03-25.md` | MARCAR_HISTORICO | 18 | 6 | sim (`CONTEXTO_PRODUTO_ATUAL.md:810`) | inserir banner §3.1; registrar override `historical_evidence` |
| 2 | `docs/AUDITORIA_UX_LOGICA_PERFORMANCE_2026-03-23.md` | MARCAR_HISTORICO | 24 | 9 | sim (`CONTEXTO_PRODUTO_ATUAL.md:254`) | banner §3.2; override |
| 3 | `docs/HERMES_SQLITE_EASYPANEL_BRIDGE_AUDIT_2026-06-06.md` | REMOVER (mover para `docs/archive/2026-06/`) | 22 | 7 | **não** (zero inbound em todo o repo) | mover; receipt primário já existe em `server/doc/BACKFILL_CARD_COMBAT_METADATA_2026-06-06.json` |
| 4 | `docs/LAYOUT_TEST_MAP.md` | REMOVER | 21 | 13 | não (só `docs/hermes-analysis/AUDIT_REPORT_2026-05-30.md:80`, pasta histórica) | apagar; `app/test/README.md` + `app/doc/UI_TEST_SURFACE_MAP.md` (canônico) são a fonte |
| 5 | `docs/MANALOOM_VISUAL_EXECUTION_BASE_2026-04-19.md` | CORRIGIR | 17 | 6 | não por doc, **sim por código** (`app/lib/core/theme/app_theme.dart:12`, `server/config/premium_visual_qa_surfaces.json:4`) | corrigir status, tokens e papéis de agente §3.5 |
| 6 | `docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md` | MARCAR_HISTORICO | 31 | 14 | sim (`CONTEXTO_PRODUTO_ATUAL.md:255`; `ROADMAP.md:83` já a chama "histórica") | banner §3.6; override |
| 7 | `docs/PLANO_SPRINTS_EXECUCAO_MTGIA_2026-03-23.md` | MARCAR_HISTORICO | 28 | 11 | sim (`CONTEXTO_PRODUTO_ATUAL.md:561`) | banner §3.7; override |
| 8 | `docs/PROJECT_LOGIC_FULL_REPORT_2026-06-11.md` | CORRIGIR (o banner) | 21 | 7 | não por canônico; `docs/hermes-analysis/PROJECT_MEMORY.md:23,48,122` (histórico) | já tem banner desde `b2d3fc04f` (2026-08-13) mas **sem os marcadores exigidos pelo gerador**; trocar cabeçalho §3.8; override |
| 9 | `docs/SENTRY_SETUP_MTGIA_2026-03-24.md` | MARCAR_HISTORICO | 27 | 4 | sim (`CONTEXTO_PRODUTO_ATUAL.md:508`) | banner §3.9; override |
| 10 | `docs/SPRINT_AUDITORIA_PRODUTO_UX_2026-03-25.md` | MARCAR_HISTORICO | 19 | 6 | sim (`CONTEXTO_PRODUTO_ATUAL.md:811`) | banner §3.10; override |
| 11 | `docs/SPRINT_LIFE_COUNTER_BENCHMARK_CLONE_2026-03-25.md` | MARCAR_HISTORICO | 22 | 10 | sim (`CONTEXTO_PRODUTO_ATUAL.md:257,461`) | banner §3.11 (substitui "Status: ACTIVE"); override |
| 12 | `docs/SPRINT_LIFE_COUNTER_TABLETOP_2026-03-25.md` | MARCAR_HISTORICO | 12 | 4 | sim (`CONTEXTO_PRODUTO_ATUAL.md:256,460`) | já se declara superado (l.3-5) mas sem marcadores; banner §3.12; override |
| 13 | `docs/TASK_LIFE_COUNTER_PERFEICAO_2026-03-26.md` | MARCAR_HISTORICO | 11 | 5 | sim (`CONTEXTO_PRODUTO_ATUAL.md:258,355,480`) | banner §3.13 (substitui "Status: ACTIVE"); override |
| 14 | `docs/EASYPANEL_RUNBOOK_MTGIA_2026-03-24.md` | CORRIGIR (o banner) | 31 | 6 | sim (`CONTEXTO_PRODUTO_ATUAL.md:512`) | banner de `d93867b68` diz `NO_DEPLOY_AUTHORITY`, o gerador exige `NO_MUTATION_AUTHORITY`; trocar 1 palavra §3.14; override |
| 15 | `docs/MANALOOM_PRODUCT_READINESS_RUNBOOK_2026-07-06.md` | MANTER (banner já correto) | 28 | 0 novas (as 12 falsidades já estão declaradas no próprio banner) | **não** (zero inbound) | só registrar override `historical_evidence`; alternativa: mover para `docs/archive/2026-07/` |
| 16 | `.hermes.md` | CORRIGIR | 21 | 9 | não por canônico; citado como regra por receipt `docs/qa/execution/2026-09-21/btscp001-gate-amplo.md:329` | manter só as regras de git; marcar o modelo Hermes/branch como histórico; corrigir lista de leitura §3.16 |
| | **Total** | | **353** | **117** | | |

Resumo do veredito: 10 MARCAR_HISTORICO, 4 CORRIGIR (dois deles só o banner), 2 REMOVER, 1 MANTER (READINESS, já marcado). Em todos os casos a ação inclui **registrar o override no contrato** — hoje o registry gerado diz `supporting_reference_non_authoritative` para todos os 16, inclusive os três que já têm banner "histórico" no corpo (banner e registry divergem).

Verdade transversal que atravessa 7 dos 16 documentos: **`app/lib/features/home/life_counter_screen.dart` não existe.** Foi apagado (6.841 linhas) em `d08985bca` (2026-07-01, "Audit and remove dead app surfaces"), junto com `life_counter_screen_test.dart` (1.296 linhas), `life_counter_clone_proof_test.dart`, `deck_card.dart`, `deck_card_overflow_test.dart` e 15 PNGs de golden/prova do clone. O contador de vida do produto é `app/lib/features/home/lotus_life_counter_screen.dart` (criado em `96105406f`, 2026-03-29) + 14 folhas nativas em `app/lib/features/home/life_counter/life_counter_native_*_sheet.dart`. Toda a "sprint de clone" de março descreve código morto.

---

## 2. Cabeçalho padrão a inserir (cumpre `_validateHistoricalDocumentBanners`)

Inserir como primeiras linhas, **antes** do `# Título` atual (o gerador lê as 16 primeiras linhas; o banner abaixo tem 9). Adaptar o bloco "superado por".

```markdown
> Lifecycle: `HISTORICAL_EVIDENCE · SUPERSEDED · NO_MUTATION_AUTHORITY`
> Fotografia de `<DATA>`. Não define prioridade, status nem aceite.
> Comandos, caminhos e números abaixo são exemplo histórico; vários já não
> existem ou mudaram (ver "Superado por").
> Superado por: `docs/status/CURRENT_PRODUCT_DECISION.md` (decisão),
> `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md` (tasks),
> `<CONTRATO/DOC ATUAL DA ÁREA>`.
> Registrado em `docs/project_logic_contracts.json > document_overrides`
> como `historical_evidence`.
```

E a entrada correspondente em `docs/project_logic_contracts.json > documentation_lifecycle.document_overrides` (depois rodar `./scripts/manaloom_project_logic.sh --write` e `--check`, conforme `AGENTS.md:17-21`; atenção: `project_logic_manifest.json` já está modificado no working tree):

```json
{ "path": "docs/<ARQUIVO>.md", "state": "historical_evidence", "reason": "<motivo curto>" }
```

---

## 3. Divergências por documento

Formato: `linha | afirmação | classificação | evidência | verdade atual | ação | texto corrigido`.
Só listo o que **não** é CORRETO. As afirmações CORRETAS contam no total e vão para a seção 4 quando são fatos úteis.

### 3.1 `docs/AUDITORIA_RUIDO_VISUAL_CORES_2026-03-25.md` (363 linhas; único commit `b970fa66a` 2026-03-25)

Sem cabeçalho de lifecycle. Apresenta-se como auditoria com "fila executável" e status `DONE/BACKLOG`.

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 37-38 | `community_screen.dart` e `life_counter_screen.dart` em `BACKLOG` | CONTRADIZ_OUTRO_DOC | `docs/SPRINT_AUDITORIA_PRODUTO_UX_2026-03-25.md:547-617` registra ambas como `IN_PROGRESS` com mudanças aplicadas na mesma data; `docs/PLANO_SPRINTS_EXECUCAO_MTGIA_2026-03-23.md:245-254` idem | Estado de março era IN_PROGRESS; hoje `life_counter_screen.dart` nem existe | marcar_historico | — (banner resolve) |
| 38, 239, 270, 283 | `app/lib/features/home/life_counter_screen.dart` (tela existente) | DEFASADO | `ls` → No such file; apagado em `d08985bca` 2026-07-01 | Contador é `lotus_life_counter_screen.dart` + `life_counter/` (14 sheets) | marcar_historico | — |
| 278 | `app/lib/features/market/screens/market_screen.dart` no ranking | DEFASADO | apagado em `2139ec9f6` 2026-07-23 ("Harden beta release readiness and retention") | Não existe; rota `/market` ainda declarada em `app/lib/main.dart` (path list) mas a tela legada saiu | marcar_historico | — |
| 288-294 | `app/RELATORIO_CORES_TEMAS.md` "parece defasado" e Fase 4.1 "regenerar" | CORRETO (diagnóstico) / NAO feito | `git log -1 -- app/RELATORIO_CORES_TEMAS.md` → `808853d2c` 2026-03-12; nunca regenerado | Relatório de cores continua de 2026-03-12 | nenhuma (histórico) | — |
| 340 | proposta "proibição de `Color(0x...)` fora do tema" | CORRETO como proposta; **adotada** | `git grep -l "Color(0x" -- 'app/lib/*.dart' ':!app/lib/core/theme/*'` → 0 arquivos; `app/test/core/theme/app_theme_token_usage_test.dart` existe | Regra vigente e testada | nenhuma | — |
| 8, 298 | tema em `app_theme.dart` com "orçamento de cor" | CORRETO, mas a paleta mudou | `app_theme.dart:8` hoje é "Obsidian + Brass + Frost Blue", 24 tokens (`:20-22`); em março a paleta era violeta/ouro (`manaViolet`, `mythicGold` sobrevivem só como aliases em `:49-51`) | Paleta e regras são as de `docs/MANALOOM_VISUAL_EXECUTION_BASE_2026-04-19.md` + `app_theme.dart` | marcar_historico | — |
| 3-4 | "Auditoria estática em 2026-03-25, escopo `app/lib/features/**`" | CORRETO (data) | commit `b970fa66a` | — | — | — |

Veredito: **MARCAR_HISTORICO**. 18 afirmações verificáveis (caminhos de 26 arquivos existem exceto 2; regra de cor; datas), 6 defasadas/contraditórias. Não pode ser removido (`CONTEXTO_PRODUTO_ATUAL.md:810`). Banner §2 com "Superado por: `docs/MANALOOM_VISUAL_EXECUTION_BASE_2026-04-19.md`, `app/lib/core/theme/app_theme.dart`, `docs/design/visual-audit-2026-09-21/README.md`".

### 3.2 `docs/AUDITORIA_UX_LOGICA_PERFORMANCE_2026-03-23.md` (469 linhas; `1cae278e3`..`40ae8a9df`, 2026-03-23)

Sem cabeçalho. Fala em "Decisao Executiva Da Rodada", "Sprint 1", números de banco e de linhas no presente.

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 15 | "mapeamento das `25` telas do app" | DEFASADO | em `40ae8a9df`: `git ls-tree` → 25 arquivos `*/screens/*.dart`; hoje `git ls-files 'app/lib/features/*/screens/*.dart'` → **39** | 39 telas | marcar_historico | — |
| 35-37 | `flutter analyze`/`flutter test`/`dart test` "verde" | NAO_VERIFICAVEL hoje (proibido rodar) e DEFASADO como estado | `docs/qa/execution/2026-09-18/deck-quality-harness.md` registra gate pré-existente falhando (citado em `d93867b68`) | Estado de suíte é o do último receipt, não deste doc | marcar_historico | — |
| 49-59 | "Sprint 1 monotemática em otimização" é a decisão executiva | DEFASADO | `docs/status/CURRENT_PRODUCT_DECISION.md:5` = `NO_GO_PUBLIC_RELEASE`; backlog 2026-08-12 é o índice | Prioridade só vem de decisão + backlog | marcar_historico | — |
| 186 | `deck_details_screen.dart`: 4703 linhas | DEFASADO | `git show 40ae8a9df:…` → 4703 (era verdade); hoje `wc -l` → **2697** | 2697 | marcar_historico | — |
| 187 | `deck_provider.dart`: 1840 | DEFASADO | era 1840; hoje **1650** | 1650 | marcar_historico | — |
| 188 | `server/routes/ai/optimize/index.dart`: 7979 | DEFASADO (e impreciso na origem) | em `40ae8a9df` era **8008**; hoje **3337** | 3337 | marcar_historico | — |
| 189 | `rebuild_guided_service.dart`: 1747 | DEFASADO | era 1747; hoje **2218** (cresceu) | 2218 | marcar_historico | — |
| 190 | `life_counter_screen.dart`: 2669 | DEFASADO | era 2669; arquivo apagado em `d08985bca` 2026-07-01 | não existe | marcar_historico | — |
| 338-348 | contagens de banco (`meta_decks` 325, `card_legalities` 312942, `commander_reference_profiles` 7…) | NAO_VERIFICAVEL (snapshot live de 2026-03-23; nenhum receipt read-only fresco) | `CONTEXTO_PRODUTO_ATUAL.md:31-32`: "estado do PostgreSQL live continua desconhecido até receipt read-only fresco" | desconhecido | marcar_historico | — |
| 452 | `server/run_optimize_validation.ps1` verde | CORRETO (arquivo existe) / NAO_VERIFICAVEL (resultado) | `ls server/run_optimize_validation.ps1` OK | — | — | — |
| 408-423 | corpus estável cobre 16 decks; Yuriko retirada | DEFASADO | `PLANO_SPRINTS…:88` diz 19 no mesmo período; artefatos `server/test/artifacts/optimization_resolution_new_commanders_2026_03_23` apagados em `8cab6400b` 2026-05-30; hoje existem `server/test/artifacts/optimization_resolution_suite` e `…_unique_20260707` | corpus vive em `scripts/quality_gate_resolution_corpus.sh` (`quality_gate.sh resolution`, l.221-223,372) | marcar_historico | — |
| 331 | "documentação oficial dessa leitura está em `MATRIZ_TESTES…`" | DEFASADO | `ROADMAP.md:83` (histórico) chama a matriz de "histórica"; `MATRIZ` não está em `canonical_documents` | — | marcar_historico | — |

Veredito: **MARCAR_HISTORICO**. 24 afirmações, 9 defasadas. Citado por `CONTEXTO_PRODUTO_ATUAL.md:254`. Banner §2, "Superado por: `docs/BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md`, `docs/DECK_QUALITY_MODEL.md`, `docs/flows/deck_ai.md`".

### 3.3 `docs/HERMES_SQLITE_EASYPANEL_BRIDGE_AUDIT_2026-06-06.md` (317 linhas; único commit `1b97f764c` 2026-06-06)

Sem cabeçalho. Tem seções "Arquitetura recomendada", "Proximo passo tecnico" e "Regras de seguranca para agentes" que leem como plano vigente.

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 9-11 | Postgres é verdade; Hermes é laboratório; ponte parcial por scripts | CORRETO (ainda vale) | `.github/AGENT_POLICY.md:43`; `AGENTS.md:14` | — | — | — |
| 17-19 | backend público `/health` healthy, `card_count` 33795 | DEFASADO | `EASYPANEL_RUNBOOK…:148` registra 34331 em 2026-07-06; `PROJECT_LOGIC…:384` registra 34.329 em 2026-06-15 | live desconhecido (sem receipt fresco) | remover/mover | — |
| 23-36 | 12 contagens de tabelas Postgres | NAO_VERIFICAVEL (snapshot live) | sem receipt read-only atual | desconhecido | remover/mover | — |
| 54 | SQLite em `/opt/data/workspace/mtgia/...` dentro do container Hermes | NAO_VERIFICAVEL + DEFASADO | `docs/MAPA_OPERACIONAL_DO_PROJETO.md:240`: `hermes-lab` "dormente desde 2026-06-23"; `:451`: `docs/hermes-analysis/` é histórico | Hermes está desligado | remover/mover | — |
| 203-212 | "Implementacao aplicada… `knowledge.db`" como arquivo entregue | ERRADO como artefato versionado | `git ls-files …/knowledge.db` → 0; ignorado por `docs/hermes-analysis/manaloom-knowledge/scripts/.gitignore:2` (`*.db`) desde `e0143ed7e` 2026-05-26 (antes deste doc) | `knowledge.db` nunca foi versionado | remover/mover | — |
| 209-210 | `sync_pg_card_metadata_to_hermes.py`, `battle_analyst_v8.py` | metade DEFASADA | `sync_…py` existe; `battle_analyst_v8.py` apagado em `f53e32868` 2026-06-16 (existe `v9`) | v9 | remover/mover | — |
| 246-250 | validações `py_compile` + `test_battle_analyst_v10_3.py` passaram | NAO_VERIFICAVEL (resultado); arquivo existe | `ls` OK | — | — | — |
| 268-272, 277 | migration `018_add_card_combat_metadata` + backfill + receipt JSON | CORRETO | `server/bin/migrate.dart:483-490` (`version: '018'`, `add_card_combat_metadata`); `server/doc/BACKFILL_CARD_COMBAT_METADATA_2026-06-06.json` contém **exatamente** os mesmos números (34128/18892/16620/33524; before 0 → after 18537/18537/16271) | migração existe; total de migrations hoje = **58** (`migrate.dart` última `version: '058'`) | — | — |
| 280-291 | tabela do backfill | CORRETO | idem | — | — | — |
| 181-201 | "Proximo passo tecnico: implementar `sync_pg_card_metadata_to_hermes.py`" | DEFASADO (feito na mesma data, l.203) e agora Hermes dormente | `MAPA…:240` | — | remover/mover | — |

Veredito: **REMOVER da raiz `docs/` — mover para `docs/archive/2026-06/HERMES_SQLITE_EASYPANEL_BRIDGE_AUDIT_2026-06-06.md`** (o prefixo `docs/archive/` classifica automaticamente como `historical_evidence` sem exigir banner; precedente `docs/archive/2026-03/`). Motivo para remover em vez de marcar: (a) zero referências em todo o repositório (`git grep` sem hits fora do próprio arquivo); (b) o único valor de evidência — migration 018 e backfill — já está em fonte primária (`migrate.dart:483`) e em receipt dedicado (`server/doc/BACKFILL_…json`); (c) o resto (contagens live, workspace Hermes, "próximo passo") só confunde porque Hermes está dormente. 22 afirmações, 7 defasadas/erradas.

### 3.4 `docs/LAYOUT_TEST_MAP.md` (134 linhas; único commit `49b6b1e1d` 2026-05-30)

Sem cabeçalho. Título "Mapa de Testes de Layout" com totais e "Gaps Conhecidos" — leitor toma como inventário atual.

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação |
| --- | --- | --- | --- | --- | --- |
| 24, 55, 126 | `deck_card_overflow_test.dart` (DeckCard, 5 viewports, "único widget responsivo") | DEFASADO | apagado em `d08985bca` 2026-07-01 junto com `deck_card.dart` | não existe; hoje há `deck_list_responsive_test.dart` com golden | remover |
| 32 | "7 arquivos cobrindo 5 viewports (280, 320, 360, 375, 390, 411)" | ERRADO (lista 6 valores e diz 5) + DEFASADO | contagem no próprio texto | — | remover |
| 43, 45, 70 | `life_counter_clone_proof_test.dart` com 5 goldens | DEFASADO | apagado em `d08985bca` (5 PNGs `life_counter_clone_proof_*.png` removidos) | — | remover |
| 42, 45 | home tem 1 golden (`home_hero_sma135m.png`); "6 goldens em 2 arquivos" | DEFASADO | `git ls-files` → `app/test/features/home/goldens/{home_hero_1440,home_hero_1920,home_hero_sma135m,home_hero_web}.png` + `app/test/features/decks/screens/goldens/deck_gallery_card_1880.png`; `matchesGoldenFile` em `home_screen_test.dart` e `deck_list_responsive_test.dart`; além de `app/test/ui/goldens/{ci,runtime/*}` (dezenas de PNG de runtime) | 5 goldens unitários em 2 arquivos + suíte `ui/goldens` | remover |
| 69 | `life_counter_screen_test.dart` (legacy) com keys `life-counter-control-hub`… | DEFASADO | apagado em `d08985bca` | — | remover |
| 76 | "12+ native sheet tests" | DEFASADO (número) | `ls app/test/features/home/ | grep life_counter_native_.*_sheet_test` → **13**; código tem **14** folhas (`commander_damage` sem teste dedicado) | 13 testes / 14 folhas | remover |
| 118 | `app/doc/APP_AUDIT_2026-04-29.md` "auditoria visual histórica" | CORRETO (existe) | `ls` OK | — | — |
| 131 | `community_screen` (1729 linhas) sem teste unitário | DEFASADO nos dois números | hoje **1953** linhas; existe `app/test/features/community/screens/community_screen_responsive_test.dart` | coberto | remover |
| 132 | `trade_detail_screen` (1479) sem teste de layout | DEFASADO | hoje **1769**; existe `trade_detail_screen_overflow_test.dart` | coberto | remover |
| 133 | `binder_screen` (1628) sem teste | DEFASADO | hoje **2097**; existem `binder_screen_overflow_test.dart` e `binder_screen_resilience_test.dart` | coberto | remover |
| 134 | `chat_screen` sem teste; "3 falhas pré-existentes" | DEFASADO | existe `app/test/features/messages/screens/chat_screen_test.dart` | coberto | remover |
| 130 | "Life Counter Flutter shell sem teste de overflow" | DEFASADO (a shell foi apagada) | `d08985bca` | contador é Lotus WebView + sheets nativas testadas | remover |
| 116-117 | `app/test/README.md`, `app/doc/UI_TEST_SURFACE_MAP.md` | CORRETO | existem; `UI_TEST_SURFACE_MAP.md` é canônico | — | — |

Veredito: **REMOVER** (`git rm docs/LAYOUT_TEST_MAP.md`). 21 afirmações, 13 defasadas/erradas — todos os "gaps conhecidos" já fecharam e todos os totais estão errados. Não é citado por nenhum documento canônico nem por código/script/teste (`git grep` em `server/test`, `scripts`, `tools`, `.github` → 0). Sua única citação está em `docs/hermes-analysis/AUDIT_REPORT_2026-05-30.md:80`, pasta declarada histórica (`MAPA_OPERACIONAL…:451`). Fonte viva: `app/test/README.md:52-63` (goldens) e `app/doc/UI_TEST_SURFACE_MAP.md` (canônico). Não tem valor de evidência que já não esteja no histórico git do próprio `app/test/`.

### 3.5 `docs/MANALOOM_VISUAL_EXECUTION_BASE_2026-04-19.md` (457 linhas; `ab9909706` 2026-04-21 .. `94ad7a85d` 2026-07-27)

Sem cabeçalho de lifecycle; linha 5 diz "Status: Active visual source of truth for the non-Life-Counter app experience".

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 5 | "Status: Active visual source of truth" | CONTRADIZ_OUTRO_DOC | contrato: não está em `canonical_documents` (36) nem em overrides → `supporting_reference_non_authoritative`; `docs/README.md:81-92` só admite os 7 estados; `docs/design/visual-audit-2026-09-21/README.md:13` ("**Resposta: não**… nível dominante é formulário") e `:62` ("O próprio tema proíbe essa linguagem") registram que a direção mudou para a régua do contador; backlog `:58` "nova experiência visual… com imagens de cartas" | É referência de apoio consumida por código, não fonte de verdade de prioridade | corrigir | `> Lifecycle: \`SUPPORTING_REFERENCE_NON_AUTHORITATIVE · CONSUMED_BY_CODE\`` `> Base visual citada por \`app/lib/core/theme/app_theme.dart:12\` e \`server/config/premium_visual_qa_surfaces.json:4\`. Não define prioridade. A direção corrente de qualidade visual (régua do contador, azulejos, numerais) está em \`docs/design/visual-audit-2026-09-21/README.md\` e no backlog; onde este documento e o tema divergirem, vale \`app_theme.dart\`.` |
| 99-100 | `obsidian-950: #0F1115`, `obsidian-900: #171A21` | DEFASADO | `app_theme.dart:35-36` → `backgroundAbyss = 0xFF0B0D12 // obsidian-950`, `surfaceSlate = 0xFF151821 // obsidian-900`; mudança em `254aa4526` 2026-07-01; `docs/design/visual-audit-2026-09-21/README.md:75` confirma `#0B0D12`/`#151821` | `#0B0D12`, `#151821` | corrigir | `- \`obsidian-950\`: \`#0B0D12\`` / `- \`obsidian-900\`: \`#151821\`` |
| 101-102 | `slate-800: #232735`, `slate-700: #2B3142` | DEFASADO | não existem no tema; tema tem `surfaceElevated 0xFF1D222C // slate-850` (`:37`) e `outlineMuted 0xFF293041 // slate-750` (`:57`) | — | corrigir | `- \`slate-850\` (surfaceElevated): \`#1D222C\`` / `- \`slate-750\` (outlineMuted): \`#293041\`` |
| 129-131, 145-146, 115-117 | brass 500/400/700, frost 400/600, ivory/mist | CORRETO | `app_theme.dart:40-45,54-56` batem | — | — | — |
| 68-71 (regra de gradiente) | gradiente só em hero/CTA/splash | CORRETO e vigente | `app_theme.dart:18` "Gradients only for hero sections and primary buttons"; `cardGradient` "intentionally flat" (`:183-188`, per audit `:62,91`) | — | — | — |
| 386-411 | papéis "ManaLoom App Visual QA", "App Release Engineer", "Release Coordinator" | ERRADO (nunca existiram como agentes) | `git grep -i "App Visual QA\|App Release Engineer\|Release Coordinator" -- .github docs/execution docs/BREWTACT_* docs/MAPA_*` → 0; `.github/agents/` tem 11 perfis (`manaloom-ux-design-auditor`, `mobile-runtime-device-qa`…) | perfis reais herdam `.github/AGENT_POLICY.md` | corrigir | substituir os três títulos por `### manaloom-ux-design-auditor` e `### mobile-runtime-device-qa` (perfis em `.github/agents/`), mantendo os "Must"; remover a seção "Release Coordinator" |
| 417-419 | aprovação exige `MANALOOM_UI_LIVE_EVIDENCE_CONTRACT` com `PASS_AUTOMATED/RUNTIME/VISUAL_REVIEWED` | CORRETO | contrato canônico; `AGENTS.md:33-36` | — | — | — |
| 17 | comparação com "MTG Life Counter: Mythic Tools" como referência | NAO_VERIFICAVEL (capturas externas) | — | — | — | — |

Veredito: **CORRIGIR** (não marcar histórico: `app_theme.dart:12` e `premium_visual_qa_surfaces.json:4` apontam para ele como "VISUAL BASELINE"; `server/bin/premium_visual_audit.py:447` imprime esse caminho em todo relatório como "Fontes de verdade"). 17 afirmações, 6 erradas/defasadas. Correções: linha 5 (status → lifecycle), tokens 99-102, papéis de agente 386-411. Alternativa mais dura: mover os tokens para o tema (já estão) e reduzir o doc a tese + regras, mas isso extrapola "só o verdadeiro".

### 3.6 `docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md` (374 linhas; `1cae278e3`..`c64ab38a2` 2026-03-23)

Sem cabeçalho. "Este documento registra a leitura correta da malha de testes" no presente.

| Linha | Afirmação | Classificação | Evidência (contagem `grep -c "test("` hoje) | Verdade atual | Ação |
| --- | --- | --- | --- | --- | --- |
| 37 | `optimization_rules_test.dart` 52 | DEFASADO | 53 | 53 | marcar_historico |
| 38 | `optimization_quality_gate_test.dart` 8 | DEFASADO | **36** | 36 | marcar_historico |
| 41 | `optimization_validator_test.dart` 6 | DEFASADO | 18 | 18 | marcar_historico |
| 42 | `goldfish_simulator_test.dart` 14 | DEFASADO | 22 | 22 | marcar_historico |
| 43 | `generated_deck_validation_service_test.dart` 3 | DEFASADO | 11 | 11 | marcar_historico |
| 44 | `optimize_learning_pipeline_test.dart` 12 | DEFASADO | 16 | 16 | marcar_historico |
| 51 | `card_resolution_support_test.dart` 5 | DEFASADO | 8 | 8 | marcar_historico |
| 55 | "Total… `206` testes" | DEFASADO | soma dos 17 arquivos hoje = **270** | 270 | marcar_historico |
| 39,40,45-50,52,53 | demais contagens (25, 3, 3, 23, 11, 2, 4, 3, 1, 31) | CORRETO | batem | — | — |
| 64 | `deck_card_overflow_test.dart` | DEFASADO | apagado em `d08985bca` 2026-07-01 | — | marcar_historico |
| 68 | "Total Flutter… `41` testes" | NAO_VERIFICAVEL/DEFASADO | um dos 8 arquivos não existe mais | — | marcar_historico |
| 302 | `RELATORIO_RESOLUCAO_NOVOS_COMMANDERS_2026-03-23.md` | DEFASADO (caminho) | movido para `archive_docs/root/` em `23cfc0611` 2026-05-31 | `archive_docs/root/RELATORIO_RESOLUCAO_NOVOS_COMMANDERS_2026-03-23.md` | marcar_historico |
| 303 | `server/test/artifacts/optimization_resolution_new_commanders_2026_03_23` | DEFASADO | apagado em `8cab6400b` 2026-05-30 | existem `optimization_resolution_suite` e `optimization_resolution_suite_unique_20260707` | marcar_historico |
| 312 | `bootstrap_resolution_corpus_decks.dart` | DEFASADO | apagado em `8cab6400b` 2026-05-30 | gate vive em `scripts/quality_gate_resolution_corpus.sh` (1.5k linhas; checa `failed/unresolved/passed==total` `:1434-1437`) | marcar_historico |
| 351-354 | runner local: `local_test_server.dart`, `start/stop_local_test_server.ps1`, `run_optimize_validation.ps1` | CORRETO (existem) | `ls` OK | — | — |
| 291, 359 | corpus "16 decks" | CONTRADIZ_OUTRO_DOC | `PLANO_SPRINTS…:88` diz que passou de 16 para 19 (mesmo dia, doc posterior) | 19 no fim de março; hoje ver artefatos `optimization_resolution_suite*` | marcar_historico |
| 172, 207 | suites HTTP fazem skip sem `RUN_INTEGRATION_TESTS=1` | CORRETO (mecanismo) | `docs/flows/README.md:250` usa `RUN_INTEGRATION_TESTS=0` | — | — |
| 16-27, 255-277 | "malha está séria… pronta para Sprint 1" | NAO_VERIFICAVEL (juízo) + DEFASADO (Sprint 1 não é a prioridade) | decisão `NO_GO_PUBLIC_RELEASE` | — | marcar_historico |

Veredito: **MARCAR_HISTORICO**. 31 afirmações, 14 defasadas/contraditórias. Citado por `CONTEXTO_PRODUTO_ATUAL.md:255`, `ROADMAP.md:83` ("matriz histórica"), `server/doc/OPTIMIZATION_RESOLUTION_HANDOFF_2026-03-18.md:6`. Banner §2, "Superado por: `docs/flows/deck_ai.md` §testes, `docs/DECK_QUALITY_MODEL.md`, `scripts/quality_gate_resolution_corpus.sh`".

### 3.7 `docs/PLANO_SPRINTS_EXECUCAO_MTGIA_2026-03-23.md` (485 linhas; `c64ab38a2`..`b970fa66a` 2026-03-25)

Sem cabeçalho. Linha 3: "Ordem oficial recomendada de execucao" — é exatamente o tipo de documento que `roadmap.instructions.md` (guarda global) proíbe de definir prioridade.

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação |
| --- | --- | --- | --- | --- | --- |
| 3, 22-27, 424-436 | ordem oficial Sprint 1→7 | CONTRADIZ_OUTRO_DOC | `docs/project_logic_contracts.json` guards: `historical_or_generated_may_set_priority=false`; prioridade = decisão + backlog; `.github/instructions/roadmap.instructions.md` (override `current_context`: "guard that prevents non-canonical roadmaps from setting execution priority") | Backlog 2026-08-12: 220 tasks, 3 PASS, 86 TODO, 77 BLOCKED_BY_P0 | marcar_historico |
| 32-35 | caminhos absolutos `/Users/desenvolvimentomobile/...` | CORRETO (existem) mas não portáveis | — | — | — |
| 56, 81-83 | gate `scripts/quality_gate_resolution_corpus.sh` + `quality_gate.sh resolution` | CORRETO | `scripts/quality_gate.sh:221-223,372` | — | — |
| 72 | `optimize/index.dart` caiu para 2745 | DEFASADO | hoje 3337 (voltou a crescer) | 3337 | marcar_historico |
| 73-76 | `optimize_state_support.dart`, `optimize_complete_support.dart`, `optimize_request_support.dart` criados | CORRETO | existem em `server/lib/ai/` | — | — |
| 84, 88 | `bootstrap_resolution_corpus_decks.dart`; corpus 16→19 | DEFASADO (arquivo apagado `8cab6400b`) | — | — | marcar_historico |
| 99-152, 216-224 | sequência `deck_details_screen.dart` 3587→…→1445; `deck_provider.dart` 1560→…→899 | CORRETO em `b970fa66a` (899 / 1398) e DEFASADO hoje | `git show b970fa66a:` → provider 899, screen 1398; hoje **1650 / 2697** — os dois arquivos voltaram a crescer | 1650 / 2697 | marcar_historico |
| 460-467 | `deck_provider_support.dart` barrel de 6 linhas + 6 módulos | CORRETO (ainda vale) | `wc -l` → 6; `ls` → `_ai,_common,_fetch,_generation,_import,_mutation` | — | — |
| 265 | Kotlin `2.2.0` em `settings.gradle.kts` | DEFASADO | `app/android/settings.gradle.kts:22` → `2.2.20` | 2.2.20 | marcar_historico |
| 267 | Podfile com workaround `DT_TOOLCHAIN_DIR -> TOOLCHAIN_DIR` | CORRETO | `app/ios/Podfile:73,98` | — | — |
| 294 | `server/bin/load_test_core_flow.dart` | ERRADO/DEFASADO | não existe no checkout nem em `archive_docs`; `find` → 0 | — | marcar_historico |
| 479 | revisar `CHECKLIST_GO_LIVE_FINAL.md` | DEFASADO | movido para `archive_docs/root/` em `23cfc0611` 2026-05-31 | — | marcar_historico |
| 478, 269 | "próximo bloqueio dominante = Sentry mobile" | DEFASADO | decisão 2026-08-25 e backlog: bloqueios P0 são capabilities/receipts, não Sentry | — | marcar_historico |
| 168-171, 197-213 | Sentry backend/app ligados; `/ready`; `.env.example` | CORRETO | `server/lib/observability.dart` (33 menções), `app/lib/core/observability/app_observability.dart` (44), `server/routes/ready/index.dart`, `server/.env.example:228-238` | — | — |
| 4, 18 | "sem substituir a precedencia de `CONTEXTO_PRODUTO_ATUAL.md`" | DEFASADO | `CONTEXTO_PRODUTO_ATUAL.md` hoje é `current_context` sem autoridade de prioridade (`:3-8`) | — | marcar_historico |

Veredito: **MARCAR_HISTORICO**. 28 afirmações, 11 defasadas/contraditórias. Citado por `CONTEXTO_PRODUTO_ATUAL.md:561` ("toda entrega desta fila deve atualizar… `PLANO_SPRINTS…`" — instrução ela mesma histórica). Banner §2, "Superado por: backlog 2026-08-12 e `docs/execution/CURRENT_QUEUE.md`". É o documento do grupo com maior risco de ser lido como fila, por causa do título.

### 3.8 `docs/PROJECT_LOGIC_FULL_REPORT_2026-06-11.md` (886 linhas; `bd7eb5584` 2026-06-11 .. `b2d3fc04f` 2026-08-13)

**Já tem banner** (l.3-11, inserido em `b2d3fc04f`): "HISTORICAL / SUPERSEDED — NAO USE COMO ESTADO, CONTRATO OU PLANO ATUAL". Problema: o banner **não contém** `HISTORICAL_EVIDENCE` nem `NO_MUTATION_AUTHORITY` — se for registrado como override, o gerador recusa (`project_logic_generator.dart:1249-1260`). E o parágrafo seguinte (l.13-19) ainda se chama "Relatorio canonico".

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 3 | banner "HISTORICAL / SUPERSEDED" | CORRETO na intenção, **ERRADO no formato** | gerador exige os marcadores `HISTORICAL_EVIDENCE` e `NO_MUTATION_AUTHORITY` nas 16 primeiras linhas | — | corrigir | `> Lifecycle: \`HISTORICAL_EVIDENCE · SUPERSEDED · NO_MUTATION_AUTHORITY\`` (trocar a l.3) |
| 13 | "Relatorio canonico de arquitetura…" | CONTRADIZ_OUTRO_DOC | não está em `canonical_documents`; `docs/generated/CURRENT_SYSTEM.md` é o sistema gerado | — | corrigir | `> Relatório histórico de arquitetura… (era o mapa mestre em 2026-06-11).` |
| 16 | base `master@b11456cf…` | CORRETO (SHA existe, 2026-06-11) | `git cat-file -t` → commit | — | — | — |
| 42-54 | tabela "Escopo atual" com 10 áreas `Ativo` | DEFASADO (já coberto pelo banner) | `server/config/release_capabilities.json`: 29 capabilities, `allowed=false` em todas | tudo OFF por capability | nenhuma (banner) | — |
| 108 | backend público `https://evolution-cartinhas.8ktevp.easypanel.host` | DEFASADO | `grep -o` em `scripts/ server/ app/lib` → 21 ocorrências, **todas** `2ta7qx`; `EASYPANEL_RUNBOOK…:121,143-149` documenta a migração de servidor em 2026-07-06; ADR 0011: origem pública canônica é `https://brewtact.com` | host `2ta7qx` e domínio `brewtact.com` | nenhuma (banner) | — |
| 161-176 | rotas do app | CORRETO (todas existem: `/decks/generate` e `/decks/import` aninhadas `main.dart:551,569`; `/life-counter` via `lifeCounterRoutePath` `main.dart:492`) | `grep -c "GoRoute("` → **46** em `app/lib/main.dart` (único arquivo com GoRoute) | 46 GoRoute | — | — |
| 321 | telas `life_counter_screen.dart`, `lotus_life_counter_screen.dart` | metade DEFASADA | `life_counter_screen.dart` apagado `d08985bca` 2026-07-01 | só Lotus | nenhuma (banner) | — |
| 373-389 | "71 relações", `cards=34.329`, migration 022/028 | DEFASADO | `migrate.dart` tem **58** migrations; `CONTEXTO…:31` baseline `058`; live desconhecido | — | nenhuma (banner) | — |
| 678-697 | 13 crons Hermes "atuais" | DEFASADO | `MAPA_OPERACIONAL…:240-243`: `hermes-lab` dormente desde 2026-06-23; `manaloom-ops` sobe com **1 job** (`hermes_cron_governor_report`) | 1 job, sem escrita em PG | nenhuma (banner) | — |
| 725 | battle engine `battle_analyst_v9.py` + `test_battle_analyst_v10_3.py` | CORRETO (arquivos existem); DEFASADO como "ativo" | ADR 0013: Jogar vs IA é o único produto de battle; XMage pinado é a fonte executável (`AGENT_POLICY.md:45`) | — | nenhuma (banner) | — |
| 762-786 | comandos de validação `dart analyze`/`flutter test` | NAO_VERIFICAVEL (proibido rodar); incompletos vs `AGENTS.md:17-27` (project logic + hooks) | — | — | nenhuma (banner) | — |
| 58-75 | fontes consultadas | CORRETO (todas existem) | `ls` OK nos 10 caminhos | — | — | — |

Veredito: **CORRIGIR (só cabeçalho)** e registrar override `historical_evidence`. 21 afirmações, 7 defasadas (todas já cobertas pela intenção do banner). Texto pronto para as linhas 3 e 13:

```markdown
> Lifecycle: `HISTORICAL_EVIDENCE · SUPERSEDED · NO_MUTATION_AUTHORITY`
> **NÃO USE COMO ESTADO, CONTRATO OU PLANO ATUAL.**
```
```markdown
> Relatório histórico de arquitetura, lógica de produto, banco, IA, Hermes,
> crons, regras e validação do ManaLoom no checkout de 2026-06-11.
```

### 3.9 `docs/SENTRY_SETUP_MTGIA_2026-03-24.md` (210 linhas; `5f5b2d4ca` 2026-03-24 .. `c7b1b82d0` 2026-04-27)

Sem cabeçalho. Título "Setup Operacional". Comandos presentes: `dart run bin/sentry_smoke.dart`, `./scripts/validate_sentry_*.sh`, `./scripts/flutter_run_with_local_sentry.sh` — todos leem `.env` local e enviam evento ao Sentry (não mutam produto; risco baixo).

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação |
| --- | --- | --- | --- | --- | --- |
| 10-25 | Sentry backend em `observability.dart`; middleware; `captureRouteException`; `/ready`; CORS `X-Request-Id` | CORRETO | `server/lib/observability.dart` (33 refs Sentry); `server/routes/_middleware.dart:34` (CORS com `X-Request-Id`), `:75,96` (eco de `x-request-id`); `server/routes/ready/index.dart`; `captureRouteException` em 59 rotas hoje (era 6) | vale, e cresceu | — |
| 29-42 | Sentry app em `app_observability.dart`; `captureProviderException` em Auth/Deck/Notification | CORRETO | 44 refs; `captureProviderException` em 6 providers (auth, community, deck, notification, social + core) | vale, e cresceu | — |
| 50 | credenciais em `/Users/…/carMatch/backend/.env` | NAO_VERIFICAVEL (fora do repo) | — | — | marcar_historico |
| 73, 93, 108, 130, 188 | scripts existem | CORRETO | `ls scripts/` OK para os 5 + `server/bin/sentry_smoke.dart` + `app/integration_test/mobile_sentry_smoke_test.dart` | — | — |
| 140-147 | validação real de 2026-03-24 (`event_id 70168f941de24cf4923eb87bb6d38a5d`) | NAO_VERIFICAVEL (Sentry externo) | citado também em `CONTEXTO…:510` | evidência histórica | marcar_historico |
| 151-159 | "o que falta validar": ingestão real do app, smoke mobile preso, Kotlin `2.2.0`, `cocoapods 1.12.1` | DEFASADO | Kotlin hoje `2.2.20` (`settings.gradle.kts:22`); Podfile workaround existe (`:73,98`); estado de ingestão mobile não aparece em nenhum receipt atual | pendência não é rastreada no backlog: `TASK_REGISTRY.json` só cita Sentry em `BT-SEC-AI-002` e `BT-AI-012` (allowlist/pseudonimização de logs), nenhuma sobre ingestão mobile | marcar_historico |
| 168-201 | `/health`, `/health/ready`, `/ready` + `validate_request_id_ready.sh` | CORRETO (rotas e script existem) | `ls server/routes/health/ready server/routes/ready` OK | — | — |
| 203-210 | "Próximo passo natural… Redis/worker/heartbeat" | DEFASADO | prioridade só no backlog; `TASK_REGISTRY.json`: 0 tasks com "Redis"; "worker" só em Battle (`BT-BAT-*`) | — | marcar_historico |

Veredito: **MARCAR_HISTORICO**. 27 afirmações, 4 defasadas — é o documento mais "ainda verdadeiro" do grupo (a implementação descrita continua em vigor e cresceu), mas suas pendências e "próximo passo" são de março. Citado por `CONTEXTO_PRODUTO_ATUAL.md:508`. Banner §2, "Superado por: `docs/flows/platform_release_ops.md` §observabilidade (`:192,227`), `server/test/observability_test.dart`".

### 3.10 `docs/SPRINT_AUDITORIA_PRODUTO_UX_2026-03-25.md` (684 linhas; `6645f3d81`..`d7db4badd` 2026-03-25)

Sem cabeçalho. Registra 5 telas `IN_PROGRESS`, "Ordem oficial de execução", "Definição de encerramento da sprint".

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação |
| --- | --- | --- | --- | --- | --- |
| 273-402 | matriz de 31 arquivos de tela | 29 CORRETOS (existem); 2 DEFASADOS | `deck_card.dart` (l.316) apagado `d08985bca` 2026-07-01; `market_screen.dart` (l.394) apagado `2139ec9f6` 2026-07-23 | — | marcar_historico |
| 425, 482, 517, 551, 584 | 5 telas `IN_PROGRESS` | DEFASADO (estado congelado em 2026-03-25) | nenhuma task correspondente no backlog; auditoria visual 2026-09-21 reavaliou tudo com outra régua (`docs/design/visual-audit-2026-09-21/README.md:13`: 4–5/10) | estado atual = auditoria 2026-09-21 | marcar_historico |
| 580-617 | `life_counter_screen.dart` com hub, roll-off, D20 no card | DEFASADO | arquivo apagado `d08985bca`; contador atual é Lotus | — | marcar_historico |
| 440 | validação movida para `DeckProgressIndicator` | CORRETO (componente existe) | `app/lib/features/decks/widgets/deck_progress_indicator.dart` | — | — |
| 414 | "atualização em `docs/CONTEXTO_PRODUTO_ATUAL.md`" como artefato obrigatório | DEFASADO | `CONTEXTO…:3-8` é roteador; entregas hoje geram receipt em `docs/qa/execution/` (`docs/execution/README.md`) | — | marcar_historico |
| 659-667 | "Ordem oficial de execução" | CONTRADIZ_OUTRO_DOC | guards do contrato (prioridade só decisão+backlog) | — | marcar_historico |
| 123-133 | orçamento de cor (1 acento dominante etc.) | CORRETO como regra | `app_theme.dart:15-18` e `premium_visual_qa_surfaces.json` `baseline_rules` codificam o mesmo | vale | — |

Veredito: **MARCAR_HISTORICO**. 19 afirmações, 6 defasadas/contraditórias. Citado por `CONTEXTO_PRODUTO_ATUAL.md:811`. Banner §2, "Superado por: `docs/design/visual-audit-2026-09-21/README.md`, `docs/MANALOOM_UI_LIVE_EVIDENCE_CONTRACT.md`".

### 3.11 `docs/SPRINT_LIFE_COUNTER_BENCHMARK_CLONE_2026-03-25.md` (926 linhas; `d7db4badd` 2026-03-25 .. `b6e3cd2da` 2026-06-16)

Linha 4: "Status: `ACTIVE`". Linha 6: "Task complementar ativa". Não há cabeçalho de lifecycle.

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 4 | "Status: `ACTIVE`" | ERRADO hoje | o alvo (`life_counter_screen.dart`) foi apagado em `d08985bca` 2026-07-01; backlog Épico H (`LC-P0-01..04`, `LC-P1-01`) trata de namespace/lifecycle/flush do Lotus, não de clone | sprint morta | marcar_historico | substituir l.3-6 pelo banner §2 |
| 10, 684 | transformar `app/lib/features/home/life_counter_screen.dart` | DEFASADO | apagado (6.841 linhas) em `d08985bca` | contador = `lotus_life_counter_screen.dart` (164 KB) + 14 sheets nativas | marcar_historico | — |
| 10 | dump `dddddd/` removido "em 2026-06-17" | CORRETO (em UTC) | `b6e3cd2da` 2026-06-16 23:38 -0300 = 2026-06-17 02:38Z; 10 JPEG removidos | — | — | — |
| 731-780 | arquivos recomendados `widgets/life_counter_table_layout.dart`, `_control_hub`, `_player_panel`, `_overlays`, `_motion` | ERRADO (nunca existiram) | `git log --all --diff-filter=A -- 'app/lib/features/home/widgets/<cada>'` → vazio | — | marcar_historico | — |
| 784, 829-830 | `app/test/features/home/life_counter_screen_test.dart` obrigatório e verde | DEFASADO | apagado (1.296 linhas) em `d08985bca` | testes atuais: `lotus_life_counter_screen_test.dart`, `life_counter_route_test.dart`, 13 `life_counter_native_*_sheet_test.dart` (`docs/flows/README.md:287`) | marcar_historico | — |
| 722-725 | `_buildBadgesRow`, `showModalBottomSheet` de counters no arquivo | DEFASADO | arquivo apagado | — | marcar_historico | — |
| 434-461, 552-559, 639-651, 865-909 | cortes "implementados em 2026-03-25" (black-first, hub radial, overlays, takeovers, motion) | NAO_VERIFICAVEL hoje (código apagado) — eram verdade em março (`CONTEXTO…:451-465` corrobora) | `d08985bca` | evidência só no histórico git | marcar_historico | — |
| 5-6 | substitui TABLETOP; task complementar PERFEICAO | CORRETO (encadeamento) | os dois docs existem | — | — | — |
| 105 | "10 imagens" | CORRETO | `b6e3cd2da` removeu 10 JPEG | — | — | — |

Veredito: **MARCAR_HISTORICO**. 22 afirmações, 10 erradas/defasadas. Citado por `CONTEXTO_PRODUTO_ATUAL.md:257,461`. Não remover (é a única narrativa da fase "clone" cujo código sumiu). Banner §2 com "Superado por: `app/lib/features/home/lotus_life_counter_screen.dart` (Lotus, `96105406f` 2026-03-29), `docs/flows/life_counter_post_game.md`, backlog Épico H; código-alvo removido em `d08985bca` (2026-07-01)". Trocar as linhas 3-6 pelo banner (a linha "Status: ACTIVE" tem de sair).

### 3.12 `docs/SPRINT_LIFE_COUNTER_TABLETOP_2026-03-25.md` (288 linhas; `d7db4badd` 2026-03-25)

Linhas 3-5 já dizem "Documento superado… permanece como historico" — mas sem os marcadores do gerador, e a linha 285 ainda diz "status: `IN_PROGRESS`".

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação |
| --- | --- | --- | --- | --- | --- |
| 3-5 | superado por BENCHMARK_CLONE | CORRETO na intenção; **formato** incompleto | falta `HISTORICAL_EVIDENCE`/`NO_MUTATION_AUTHORITY` (gerador `:1249-1260`) | — | marcar_historico (trocar l.3-5 pelo banner §2) |
| 8 | `life_counter_screen.dart` | DEFASADO | apagado `d08985bca` | — | idem |
| 12, 26-31 | benchmark em `ddddd/` (6 JPEG) | DEFASADO | pasta versionada era `dddddd/` (6 "d"), removida em `b6e3cd2da`; `ls ddddd dddddd` → ambos inexistentes | — | idem |
| 285 | "status: `IN_PROGRESS`" | CONTRADIZ o próprio doc (l.3) | — | superado | idem |
| 159-161, 188-192, 215-218 | fases 1-3 `DONE`/`PARTIAL` | NAO_VERIFICAVEL hoje (código apagado) | — | — | idem |

Veredito: **MARCAR_HISTORICO**. 12 afirmações, 4 problemáticas. Citado por `CONTEXTO_PRODUTO_ATUAL.md:256,460`. Banner §2 no lugar das l.3-5.

### 3.13 `docs/TASK_LIFE_COUNTER_PERFEICAO_2026-03-26.md` (297 linhas; `f0ad76643` 2026-03-26)

Linha 4: "Status: `ACTIVE`". Título "Task de Perfeicao" com "Definition of done" e "Proxima task operacional".

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação |
| --- | --- | --- | --- | --- | --- |
| 4 | "Status: `ACTIVE`" | ERRADO hoje | alvo apagado `d08985bca`; não é task do backlog (`TASK_REGISTRY.json` não tem id para ela; Épico H = `LC-P0-01..04`, `LC-P1-01`) | task morta | marcar_historico (substituir l.3-5 pelo banner §2) |
| 9 | levar `app/lib/features/home/life_counter_screen.dart` a clone 1:1 | DEFASADO | apagado | — | idem |
| 43-59 | "Veredito atual… coerente… ainda nao perfeito" | NAO_VERIFICAVEL (código apagado) | — | — | idem |
| 63-77 | contrato de mesa `2p..6p`, dense mode | NAO_VERIFICAVEL hoje | `CONTEXTO…:480` corrobora que começou em março | — | idem |
| 286-297 | "Proxima task operacional" | CONTRADIZ_OUTRO_DOC | prioridade só decisão + backlog | — | idem |
| 5 | complementa BENCHMARK_CLONE | CORRETO | — | — | — |

Veredito: **MARCAR_HISTORICO**. 11 afirmações, 5 erradas/defasadas. Citado por `CONTEXTO_PRODUTO_ATUAL.md:258,355,480` e por `docs/hermes-analysis/OPEN_RISKS.md:92`, `UI_ACTIONABLE_TASKS.md:16` (históricos). Banner §2.

### 3.14 `docs/EASYPANEL_RUNBOOK_MTGIA_2026-03-24.md` (296 linhas; `5f5b2d4ca` 2026-03-24 .. `d93867b68` 2026-09-18)

**Já tem banner** (l.3-14, inserido em `d93867b68` 2026-09-18): "Lifecycle: `HISTORICAL_EVIDENCE · NO_DEPLOY_AUTHORITY`. NÃO EXECUTE OS COMANDOS". O banner está correto no conteúdo (cita `NO_GO_PUBLIC_RELEASE`, 29 capabilities `allowed=false`, e que os blocos `docker build/push/service update` contornam `manaloom_deploy_backend_image.sh`). Problema: o marcador é `NO_DEPLOY_AUTHORITY`, o contrato exige `NO_MUTATION_AUTHORITY` (`guards.historical_header_markers`), e o doc não está em `document_overrides` — o registry diz `supporting_reference_non_authoritative`.

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 3 | `HISTORICAL_EVIDENCE · NO_DEPLOY_AUTHORITY` | ERRADO no marcador | `docs/project_logic_contracts.json > guards.historical_header_markers = ["HISTORICAL_EVIDENCE","NO_MUTATION_AUTHORITY"]` | — | corrigir | `> Lifecycle: \`HISTORICAL_EVIDENCE · NO_MUTATION_AUTHORITY · NO_DEPLOY_AUTHORITY\`.` |
| 7-9 | decisão `NO_GO_PUBLIC_RELEASE`; 29 capabilities `allowed=false` | CORRETO | `CURRENT_PRODUCT_DECISION.md:5`; JSON: 29 entradas, 0 `allowed:true` | — | — | — |
| 10-13 | `manaloom_deploy_backend_image.sh` é o único caminho governado | CORRETO | `MAPA_OPERACIONAL…:233` | — | — | — |
| 44-49 | "BLOQUEADO PELA DECISÃO FREE BETA (2026-08-13)" | CORRETO (data do backlog) | backlog `2026-08-12`; decisão `2026-08-25` (`CONTEXTO…:10`) — o bloqueio existe; a data citada é a do banner interno anterior | — | — | — |
| 68-91 | comandos `MANALOOM_CONFIRM_LIVE_MUTATIONS=… ./scripts/manaloom_deploy_battle_sidecars.sh` / `…_backend_image.sh` | **comandos mutantes** com aparência operacional; scripts existem; texto já os declara históricos/não executáveis (l.64-66, 81) | `ls scripts/manaloom_deploy_battle_sidecars.sh` OK; `grep -c fail.closed` → 1 em cada script + 2 em `server/bin/manaloom_ops_daemon.py` (o **terceiro portão**, conforme divergência conhecida (1)) | — | nenhuma além do banner | — |
| 112-116, 119-154 | serviço `evolution/cartinhas`, source `image`, `localhost:5000/manaloom/cartinhas:latest`, host `2ta7qx`, primeiro deploy image-based `02270f1c…`, `card_count=34331` | CORRETO como registro de 2026-07-06 | SHA `02270f1c…` existe; 21 ocorrências de `2ta7qx` em scripts/código | live desconhecido hoje | — | — |
| 132-140 | passos `git archive` → `docker build` → `docker push` → `docker service update --update-order stop-first` | **comando mutante** que contorna o script governado | commit `d93867b68` já apontou isso; banner l.9-13 | não executar | nenhuma (banner) | — |
| 184-195 | envs "obrigatórias" incluem `BATTLE_ENGINE=auto`, `XMAGE_SIDECAR_URL`, `FORGE_SIDECAR_URL` | DEFASADO como "obrigatórias" | `.env.example:33-35` as tem, mas Battle está OFF por capability (`battle_batch`, `battle_live`, `battle_coach` `allowed=false`); `manaloom_deploy_backend_image.sh` não exige sidecar (`grep` → 0) | não obrigatórias para a Free Beta | nenhuma (banner) | — |
| 233-235 | validar com `dart test` e `./scripts/quality_gate_resolution_corpus.sh` | DEFASADO/incompleto | `AGENTS.md:23-27`: hooks `manaloom_local_ci.sh quick/full`, modos `schema/e2e/release` | — | nenhuma (banner) | — |
| 292-296 | pendências (Sentry app, `/ready` com worker "Sprint 3/4") | DEFASADO | `TASK_REGISTRY.json`: nenhuma task de ingestão Sentry mobile (Sentry só em `BT-SEC-AI-002`/`BT-AI-012`, sobre pseudonimização de logs); worker só em Battle | — | nenhuma (banner) | — |
| 17 | "baseado no padrão validado do `carMatch`" | NAO_VERIFICAVEL (projeto externo) | — | — | — | — |

Veredito: **CORRIGIR (uma palavra no banner)** + registrar override. 31 afirmações, 6 defasadas (todas neutralizadas pelo banner). Citado por `CONTEXTO_PRODUTO_ATUAL.md:512` e enumerado por `docs/hermes-analysis/manaloom-knowledge/scripts/old_server_reference_audit.py:43` (script histórico). Não remover: é o único registro do cutover de servidor (2026-06-15 e 2026-07-06) e da topologia projetada dos sidecars.

### 3.15 `docs/MANALOOM_PRODUCT_READINESS_RUNBOOK_2026-07-06.md` (187 linhas; `c7b4aabfc` 2026-07-06 .. `d93867b68` 2026-09-18)

**Já tem banner completo e correto** (l.3-24): `HISTORICAL_EVIDENCE · SUPERSEDED · NO_MUTATION_AUTHORITY`, com as 12 falsidades do corpo declaradas (checkout, Pro, webhook, envs, `manaloom.com`). Confirmei o banner na fonte:

| Linha | Afirmação (do banner) | Classificação | Evidência |
| --- | --- | --- | --- |
| 10-12 | `payment_provider.dart` retorna 403/410 estáticos sem escape hatch | CORRETO | `server/lib/billing/payment_provider.dart:18` ("no environment escape hatch"), `:37` `HttpStatus.forbidden` + `beta_free_only`, `:51` `HttpStatus.gone` |
| 13-15 | envs de checkout só como asserções negativas | CORRETO | `server/test/plan_checkout_contract_test.dart:22-24` (`isNot(contains(...))` para as 3 envs) |
| 18-21 | domínio é `brewtact.com`; `manaloom.com` não pertence ao projeto | CORRETO | `docs/adr/0011-brewtact-production-domain.md:24`; ADR 0010 |
| 22-24 | seção de rotina executa DML destrutivo via SSH; histórica | CORRETO | l.138 renomeada "(histórica, não executar)" em `d93867b68` |

Do corpo, o que continua verdadeiro: os 11 scripts de `scripts/manaloom_*.sh` existem (l.67-83, `ls` OK); as rotas `/health*`, `/ready` existem; os 4 receipts em `docs/qa/runtime/*20260706*/summary.json` existem (l.175-183); SHAs `02270f1c…`/`361c6f27…` existem, **`076ba55a6…` (l.172) não existe no clone local** (`git cat-file` → could not get object) — NAO_VERIFICAVEL. `web-public/src/app/pricing/page.tsx` existe mas hoje é página "Beta gratuita… Sem cobrança" (`:9,27`) — logo "pricing responde 200" (l.135) continua tecnicamente verdade com outro conteúdo.

Veredito: **MANTER** o texto (banner já resolve) e **registrar override** `historical_evidence` — hoje o registry o classifica como `supporting_reference_non_authoritative`. Zero referências inbound: se o dono preferir raiz limpa, mover para `docs/archive/2026-07/` é seguro (nada quebra).

### 3.16 `.hermes.md` (125 linhas; `d53e9f02e` 2026-05-26 .. `13992b990` 2026-06-11)

Sem cabeçalho. Título "ManaLoom Hermes Operating Protocol… Follow this protocol before any implementation, verification, commit, or push". Ainda é invocado por agente como regra (`docs/qa/execution/2026-09-21/btscp001-gate-amplo.md:329`: "conforme `.hermes.md` ('If git commit fails, stop…')").

| Linha | Afirmação | Classificação | Evidência | Verdade atual | Ação | Texto corrigido |
| --- | --- | --- | --- | --- | --- | --- |
| 3 | repo `softwarePredador/mtgia` | CORRETO | `git remote get-url origin` → `git@github.com:softwarePredador/mtgia.git` | — | — | — |
| 8-33 | regras de git 1-7 (status antes, sem low-level git, parar se commit falhar, não commitar DB/segredos) | NAO_VERIFICAVEL (política) — **consistente** com `AGENT_POLICY.md:40,51` e com `.gitignore` do `knowledge.db` | — | manter | — | — |
| 37-39 | "apenas duas branches ativas: `master` e `codex/hermes-analysis-docs`" | DEFASADO | `git ls-remote --heads origin` → **5** (`codex/BT-SCP-001-cleanroom`, `codex/free-beta-release-candidate-2026-07-17`, `codex/hermes-analysis-docs`, `codex/project-logic-reproducible-delivery`, `master`); local 13; a branch de trabalho `codex/free-beta-release-candidate-2026-07-17` nasceu em `e9f55a1d6` 2026-07-16 | 5 remotas; trabalho corrente em `codex/free-beta-…` | corrigir | `1. Branch canônica: \`master\`. A branch de release candidate corrente é a indicada em \`docs/execution/CURRENT_QUEUE.md\`; \`codex/hermes-analysis-docs\` é memória Hermes histórica, não fonte de verdade.` |
| 48-53 | crons Hermes atualizam `docs/hermes-analysis/**`; chamar Hermes report-only após push | DEFASADO | `MAPA_OPERACIONAL…:240` `hermes-lab` dormente desde 2026-06-23; `:451` `docs/hermes-analysis/` histórico | Hermes desligado; nenhum cron escreve docs | corrigir (marcar seção como histórica) | `> Seção histórica (Hermes dormente desde 2026-06-23, \`docs/MAPA_OPERACIONAL_DO_PROJETO.md\`). Não há cron nem chamada report-only ativa.` |
| 57-62 | leitura obrigatória: `guia.instructions.md`, `CONTEXTO_PRODUTO_ATUAL.md`, `server/manual-de-instrucao.md`, `API_CONTRACTS_AND_DATA_MAP.md`, `.github/agents/*` | CONTRADIZ_OUTRO_DOC | `guia.instructions.md:9-17` manda ler `AGENTS.md`, `.github/AGENT_POLICY.md`, decisão, backlog, `CURRENT_QUEUE.md`, `CURRENT_SYSTEM.md`, contrato da área; `server/manual-de-instrucao.md` é `historical_evidence` "explicitly excluded from operational authority" (override) e o gerador **proíbe** que arquivos de instrução em `.github` o citem (`project_logic_generator.dart:1284-1292`, fragmento `:1290`) | ordem de leitura = `guia.instructions.md:9-17` | corrigir | `1. Leia, nesta ordem: \`AGENTS.md\`, \`.github/AGENT_POLICY.md\`, \`docs/status/CURRENT_PRODUCT_DECISION.md\`, \`docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md\`, \`docs/execution/CURRENT_QUEUE.md\`, \`docs/generated/CURRENT_SYSTEM.md\`, o contrato da área e \`server/doc/API_CONTRACTS_AND_DATA_MAP.md\`. \`server/manual-de-instrucao.md\` é histórico e não deve ser usado nem atualizado.` |
| 68-70 | atualizar `server/manual-de-instrucao.md` em mudança de contrato | CONTRADIZ_OUTRO_DOC | idem (histórico, sem autoridade) | atualizar só `API_CONTRACTS_AND_DATA_MAP.md` (canônico) + regenerar project logic | corrigir | `4. Para mudança de contrato app-facing, atualize \`server/doc/API_CONTRACTS_AND_DATA_MAP.md\` e rode \`./scripts/manaloom_project_logic.sh --write && --check\`.` |
| 75-76 | "Local canonical analysis tree: `docs/hermes-analysis/**`"; workspace `/opt/data/workspace/mtgia` | DEFASADO / NAO_VERIFICAVEL | `MAPA…:451`; host externo | histórico | corrigir (seção histórica) | — |
| 81 | engine principal `battle_analyst_v8.py` | DEFASADO | apagado em `f53e32868` 2026-06-16; existe `battle_analyst_v9.py`; e o produto usa XMage pinado (`AGENT_POLICY.md:45`, ADR 0013) | v9 é laboratório; XMage é executor | corrigir (seção histórica) | — |
| 84-87 | "canonical docs for current Hermes loop" (3 arquivos) | DEFASADO | arquivos existem, mas nenhum está em `canonical_documents`; `docs/hermes-analysis` é histórico exceto os 8 contratos listados no contrato (que não são esses 3) | — | corrigir (seção histórica) | — |
| 89 | `docs/hermes-analysis/scripts/structure_auditor.py` | CORRETO (existe) | `ls` OK | — | — | — |
| 97-111 | validação mínima: `dart analyze`, `dart test <focados>` | CONTRADIZ_OUTRO_DOC (incompleto) | `AGENTS.md:17-27`: obrigatório `./scripts/manaloom_project_logic.sh --write` + `--check` após mudar código/rota/migration/script/gate/contrato; hooks `manaloom_local_ci.sh quick` (pre-commit) / `full` (pre-push) | — | corrigir | acrescentar após l.103: `Depois de alterar código, rota, migration, script, gate ou contrato: \`./scripts/manaloom_project_logic.sh --write\` e \`--check\`. O pre-commit roda \`./scripts/manaloom_local_ci.sh quick\`; nunca use \`--no-verify\`.` |
| 109-110 | testes focados de optimize existem | CORRETO | `ls server/test/optimization_validator_test.dart server/test/ai_optimize_semantic_enforcement_route_contract_test.dart` OK | — | — | — |
| 116-125 | checklist de resposta (branch, hash, arquivos, validação, untracked, "no push") | NAO_VERIFICAVEL (política); consistente com receipts em `docs/qa/execution/` | — | manter | — | — |

Veredito: **CORRIGIR** (não remover: as regras de git e o checklist final são usados na prática e não estão em `AGENT_POLICY.md`, que só tem 69 linhas e não fala de `--no-verify`, low-level git ou untracked). 21 afirmações, 9 defasadas/contraditórias. Reescrita mínima: (1) cabeçalho `> Lifecycle: SUPPORTING_REFERENCE_NON_AUTHORITATIVE · GIT_HYGIENE_ONLY`; (2) manter §"Non-Negotiable Git Rules" e §"Final Response Checklist"; (3) trocar §"Branch And Source-Of-Truth Model" e §"Hermes Analysis Context" por um bloco histórico de 3 linhas; (4) corrigir §"Implementation Rules" 1 e 4 e §"Required Validation" com os textos acima. Se o dono preferir zero Hermes na raiz, renomear para `docs/GIT_HYGIENE_RULES.md` e apagar tudo de Hermes — mas o receipt de 2026-09-21 cita o nome `.hermes.md`.

---

## 4. Fatos confirmados (tabela de verdade)

Tudo abaixo foi conferido na fonte primária nesta sessão, em 2026-09-22, no checkout `d15beb05b`.

**Ciclo de vida documental**
1. `docs/project_logic_contracts.json > documentation_lifecycle`: 7 estados; `default_state = supporting_reference_non_authoritative`; 17 `document_overrides` (8 deles `historical_evidence`); 9 `prefix_rules`; `guards.historical_header_markers = [HISTORICAL_EVIDENCE, NO_MUTATION_AUTHORITY]`; `current_priority_precedence = [current_decision, current_task_index]`.
2. Nenhum dos 16 documentos deste grupo está em overrides ou prefixos → estado registrado de todos = `supporting_reference_non_authoritative`, mesmo os 3 com banner "histórico" no corpo (`EASYPANEL_RUNBOOK`, `READINESS_RUNBOOK`, `PROJECT_LOGIC_FULL_REPORT`) e mais 2 fora do grupo (`server/doc/COMMANDER_LEARNING_API_2026-06-03.md`, `server/doc/MANALOOM_CRONS_E_PENDENCIAS.md`). Banner e registry divergem.
3. O gerador valida banner só para `document_overrides` com `state = historical_evidence`: exige os 2 marcadores nas 16 primeiras linhas, senão `ProjectLogicException` (`tools/project_logic/lib/project_logic_generator.dart:1226-1262`). `docs/archive/` (prefixo) não passa por essa validação.
4. `tools/project_logic/lib/project_logic_generator.dart:1284-1292` (`forbiddenFragments`, `:1290` = `server/manual-de-instrucao.md`): arquivos de instrução em `.github` **não podem** citar `server/manual-de-instrucao.md`, `ROADMAP_SOCIAL_TRADES.md`, `git push origin master`, `./scripts/quality_gate.sh general` — reforça que o manual é histórico.
5. `docs/CONTEXTO_PRODUTO_ATUAL.md` (816 linhas, `current_context`) cita 10 dos 16 docs do grupo em seu corpo histórico (l.254-258, 508, 512, 561, 810, 811); sua lista "Documentos Que Abrem Contexto Rapido" (l.252-262) inclui `CHECKLIST_GO_LIVE_FINAL.md` e `RELATORIO_VALIDACAO_2026-03-16.md`, que hoje estão em `archive_docs/root/` (movidos em `23cfc0611` 2026-05-31) — link quebrado em doc canônico (fora deste grupo, registrado para o auditor de roteadores).
6. Precedentes de arquivamento: `docs/archive/2026-03/` (2 docs, `2a727c801` 2026-05-15); `archive_docs/root/` (14 docs, `23cfc0611` 2026-05-31; **sem** regra de prefixo no contrato).
7. Commit `d93867b68` (2026-09-18) baniu 6 docs (2 deste grupo) e registrou: 5.501 `.md` versionados, 453 sem banner, 282 não classificados, 220 sem inbound links; decisão explícita de não bannerizar a cauda longa e sim estender `prefix_rules` — follow-up ainda não feito (prefix_rules continua com 9).

**Decisão, capabilities, tasks**
8. `docs/status/CURRENT_PRODUCT_DECISION.md:5`: `NO_GO_PUBLIC_RELEASE`. Decisão datada 2026-08-25 (`CONTEXTO…:10`).
9. `server/config/release_capabilities.json`: 29 capabilities, **0** com `allowed: true` (python sobre o JSON). Nomes: `account_registration … deck_replace_all`.
10. `docs/generated/TASK_REGISTRY.json`: 220 tasks; status: TODO 86, BLOCKED_BY_P0 77, DEFERRED_BY_SCOPE 33, IN_PROGRESS_CONTAINED 10, IMPLEMENTED_LOCAL_PENDING_FULL_GATE 7, WAITING_EXTERNAL 4, **PASS 3** (`BT-GOV-001`, `BT-DOC-001`, `BT-DOC-004`). "Sentry" aparece só em `BT-SEC-AI-002` (TODO) e `BT-AI-012` (IN_PROGRESS_CONTAINED), ambas sobre allowlist/pseudonimização de logs — **nenhuma** task cobre a pendência de março "validar ingestão real do Sentry app". "Redis": 0 tasks. "worker": só em tasks de Battle (`BT-BAT-*`, `BT-AI-025`).
11. `BT-DOC-001` (PASS, receipt `docs/qa/execution/2026-08-24/BT-DOC-001.md`, SHA `c6e2725af`): "Planos, trackers, ADR duplicado, roadmap e manual históricos receberam lifecycle inequívoco e NO_MUTATION_AUTHORITY"; gerador "falha fechado" para histórico sem marcador. Não cobriu os 16 docs deste grupo.
12. Backlog Épico H (Life Counter): `LC-P0-01..04` (namespace por usuário, lifecycle login/logout, flush fail-closed, reconciliar docs) e `LC-P1-01`; nenhuma task de "clone/benchmark".

**Código: contador de vida**
13. `app/lib/features/home/life_counter_screen.dart` **não existe**: apagado (6.841 linhas) em `d08985bca` 2026-07-01 "Audit and remove dead app surfaces", junto com `life_counter_screen_test.dart` (1.296), `life_counter_clone_proof_test.dart` (329), `deck_card.dart` (592), `deck_card_overflow_test.dart` (223), `deck_card_test.dart` e 15 PNG (benchmarks/proofs/clone). 34 arquivos, −9.367 linhas.
14. Contador vigente: `app/lib/features/home/lotus_life_counter_screen.dart` (criado `96105406f` 2026-03-29; 164.816 bytes) + `app/lib/features/home/life_counter_route.dart` (`lifeCounterRoutePath = '/life-counter'`, `:4`) + `app/lib/features/home/life_counter/` com **14** folhas nativas `life_counter_native_*_sheet.dart` (card_search, commander_damage, day_night, dice, game_modes, game_timer, history, player_appearance, player_counter, player_state, set_life, settings, table_state, turn_tracker) — confirma divergência conhecida (3): 14, não 16. Testes: **13** `life_counter_native_*_sheet_test.dart` (falta `commander_damage`).
15. Dump do benchmark `dddddd/` (10 JPEG) removido em `b6e3cd2da` (2026-06-16 23:38 -0300). Pasta `ddddd/` (5 "d", citada por TABLETOP) nunca foi o caminho versionado.
16. Os 5 módulos sugeridos por BENCHMARK_CLONE (`widgets/life_counter_table_layout.dart`, `_control_hub`, `_player_panel`, `_overlays`, `_motion`) nunca existiram em nenhuma branch (`git log --all --diff-filter=A` vazio).

**Código: rotas, telas, tamanhos**
17. `app/lib/main.dart` é o único arquivo com `GoRoute(`; contagem **46** — confirma divergência conhecida (2). `/decks/generate` e `/decks/import` são rotas aninhadas (`:551`, `:569`); `/life-counter` via constante (`:492`); `/market` ainda declarado embora `market_screen.dart` tenha sido apagado em `2139ec9f6` 2026-07-23.
18. Telas: 25 em 2026-03-23 (`40ae8a9df`) → **39** hoje (`git ls-files 'app/lib/features/*/screens/*.dart'`).
19. Linhas hoje vs março: `server/routes/ai/optimize/index.dart` 3337 (era 8008 em `40ae8a9df`, mínimo 2745 em março); `deck_details_screen.dart` 2697 (era 4703; mínimo 1398 em `b970fa66a`); `deck_provider.dart` 1650 (era 1840; mínimo 899); `rebuild_guided_service.dart` 2218 (era 1747); `community_screen.dart` 1953; `trade_detail_screen.dart` 1769; `binder_screen.dart` 2097. Os arquivos "modularizados" em março voltaram a crescer.
20. `deck_provider_support.dart` continua barrel de 6 linhas com 6 módulos `_ai/_common/_fetch/_generation/_import/_mutation`.

**Tema visual**
21. `app/lib/core/theme/app_theme.dart:8-22`: tema "Obsidian + Brass + Frost Blue", 24 tokens, "VISUAL BASELINE: docs/MANALOOM_VISUAL_EXECUTION_BASE_2026-04-19.md" (`:12`), "Gradients only for hero sections and primary buttons" (`:18`). Tokens: `backgroundAbyss #0B0D12`, `surfaceSlate #151821`, `surfaceElevated #1D222C`, `brass500 #C58B2A`, `brass400 #E0A93B`, `brass700 #8E641B`, `frost400 #6FA8DC`, `frost600 #3E5F8A`, `textPrimary #F3EFE3`, `textSecondary #B8C0CC`, `textHint #8A93A3`, `outlineMuted #293041`. Surfaces mudaram em `254aa4526` 2026-07-01; o doc-base ainda traz `#0F1115/#171A21/#232735/#2B3142`.
22. `git grep "Color(0x"` fora de `app/lib/core/theme/` → 0 arquivos; `app/test/core/theme/app_theme_token_usage_test.dart` existe. A regra proposta em março ("proibição de Color(0x) fora do tema") está em vigor.
23. `server/config/premium_visual_qa_surfaces.json:3-6` lista o VISUAL_EXECUTION_BASE como `baseline_documents`; `server/bin/premium_visual_audit.py:447-448` apenas imprime esses caminhos ("Fontes de verdade") sem validar existência; `server/test/premium_visual_audit_test.py:46` usa lista vazia.
24. Nenhum agente chamado "ManaLoom App Visual QA", "App Release Engineer" ou "Release Coordinator" existe; `.github/agents/` tem 11 perfis (`api-contracts-data-map`, `commander-ai-optimization-strategist`, `commander-meta-web-research`, `commander-optimize-flow-auditor`, `commander-reference-quality-engineer`, `manaloom-card-entry-qa`, `manaloom-ux-design-auditor`, `meta-deck-intelligence-analyst`, `mobile-runtime-device-qa`, `mobile-sets-catalog-builder`, `mtg-data-integrity-maintainer`).
25. `app/RELATORIO_CORES_TEMAS.md` último commit `808853d2c` 2026-03-12 — nunca regenerado após a auditoria de cores.

**Observabilidade / ops**
26. Sentry continua ligado: `server/lib/observability.dart` (33 refs), `app/lib/core/observability/app_observability.dart` (44), `captureRouteException` em 59 rotas, `captureProviderException` em 6 providers; `server/routes/_middleware.dart:34` CORS com `X-Request-Id`, `:75,96` eco de `x-request-id`; `server/routes/ready/index.dart` e `server/routes/health/{ready,live,metrics,dashboard,commercial,ai-history}` existem; `server/.env.example:228-238` (SENTRY_*), `:249-255` (EASYPANEL_*), `:33-35` (BATTLE_ENGINE, sidecars).
27. Scripts citados existem: `validate_request_id_ready.sh`, `validate_sentry_{backend_ingestion,mobile_local,mobile_ingestion}.sh`, `flutter_run_with_local_sentry.sh`, `quality_gate_resolution_corpus.sh` (chamado por `quality_gate.sh resolution`, `:221-223,372`), os 11 `manaloom_*.sh` do READINESS, `manaloom_deploy_battle_sidecars.sh`, `manaloom_deploy_backend_image.sh`.
28. Portões fail-closed: `grep -c` "fail.closed" → `manaloom_deploy_backend_image.sh` 1, `manaloom_deploy_battle_sidecars.sh` 1, `server/bin/manaloom_ops_daemon.py` **2** — o terceiro portão da divergência conhecida (1) existe.
29. Host EasyPanel em código/scripts: 21 ocorrências, todas `evolution-cartinhas.2ta7qx.easypanel.host`; zero `8ktevp`. Domínio público canônico `https://brewtact.com` (ADR 0011:24). `web-public/src/app/pricing/page.tsx` existe e é "Beta gratuita… Sem cobrança" (`:9,27`).
30. `server/lib/billing/payment_provider.dart`: sem escape hatch (`:18`), `HttpStatus.forbidden` + `beta_free_only` (`:37-39`), `HttpStatus.gone` (`:51-53`); `server/test/plan_checkout_contract_test.dart:22-24` assegura ausência das 3 envs de checkout. Rotas `server/routes/billing/webhook` e `server/routes/users/me/plan/checkout` ainda existem como arquivos (respondem 403/410).
31. `hermes-lab` dormente desde 2026-06-23 e sem script de deploy (`docs/MAPA_OPERACIONAL_DO_PROJETO.md:240`); `manaloom-ops` sobe com 1 job `hermes_cron_governor_report` sem escrita em PG (`:242-244`); `docs/hermes-analysis/` é histórico (`:451`) exceto os 8 contratos listados em `canonical_documents`.
32. Migrations: `server/bin/migrate.dart` tem 58 (`version: '001'..'058'`); `018_add_card_combat_metadata` em `:483-490` adiciona `power/toughness/keywords` + índice GIN. Receipt do backfill em `server/doc/BACKFILL_CARD_COMBAT_METADATA_2026-06-06.json` (34128 parsed; 33524 updated; 0→18537/18537/16271).
33. `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` **nunca foi versionado** (ignorado por `.gitignore` local `*.db` desde `e0143ed7e` 2026-05-26). `battle_analyst_v8.py` apagado em `f53e32868` 2026-06-16; `battle_analyst_v9.py` e `test_battle_analyst_v10_3.py` existem.

**Git / branches**
34. `git remote get-url origin` = `git@github.com:softwarePredador/mtgia.git`; 5 branches remotas (`codex/BT-SCP-001-cleanroom`, `codex/free-beta-release-candidate-2026-07-17`, `codex/hermes-analysis-docs`, `codex/project-logic-reproducible-delivery`, `master`); 13 locais. A branch de trabalho `codex/free-beta-release-candidate-2026-07-17` começa em `e9f55a1d6` (2026-07-16).
35. Arquivos de março movidos/apagados: `CHECKLIST_GO_LIVE_FINAL.md`, `RELATORIO_VALIDACAO_2026-03-16.md`, `RELATORIO_RESOLUCAO_NOVOS_COMMANDERS_2026-03-23.md` → `archive_docs/root/` (`23cfc0611` 2026-05-31); `server/bin/bootstrap_resolution_corpus_decks.dart` e `server/test/artifacts/optimization_resolution_new_commanders_2026_03_23/` apagados (`8cab6400b` 2026-05-30); `server/bin/load_test_core_flow.dart` não existe em lugar nenhum.
36. `app/android/settings.gradle.kts:22` Kotlin `2.2.20`; `app/ios/Podfile:73,98` workaround `DT_TOOLCHAIN_DIR → TOOLCHAIN_DIR`.

**Testes (contagem `grep -c "test("`, aproximação)**
37. Backend otimização (17 arquivos da MATRIZ): 53/36/25/3/18/22/11/16/3/23/11/2/4/3/8/1/31 = **270** (doc dizia 206). Goldens unitários: 5 PNG em `app/test/features/home/goldens/` (4) + `app/test/features/decks/screens/goldens/` (1), usados por `home_screen_test.dart` e `deck_list_responsive_test.dart`; mais `app/test/ui/goldens/{ci,runtime/*}`.
38. Cobertura das telas grandes existe: `community_screen_responsive_test.dart`, `trade_detail_screen_overflow_test.dart`, `binder_screen_{overflow,resilience}_test.dart`, `chat_screen_test.dart`.

## 5. Ordem de execução sugerida (para quem for aplicar)

1. `git rm docs/LAYOUT_TEST_MAP.md` (nada aponta para ele fora de pasta histórica).
2. `git mv docs/HERMES_SQLITE_EASYPANEL_BRIDGE_AUDIT_2026-06-06.md docs/archive/2026-06/` (opcional: mesmo para `MANALOOM_PRODUCT_READINESS_RUNBOOK_2026-07-06.md` → `docs/archive/2026-07/`).
3. Corrigir 1 palavra em `EASYPANEL_RUNBOOK…:3` e as linhas 3/13 de `PROJECT_LOGIC_FULL_REPORT…`.
4. Inserir o banner §2 nos 10 docs de março (AUDITORIA_RUIDO, AUDITORIA_UX, MATRIZ, PLANO_SPRINTS, SENTRY_SETUP, SPRINT_AUDITORIA, BENCHMARK_CLONE, TABLETOP, TASK_PERFEICAO) — em BENCHMARK_CLONE/TABLETOP/TASK_PERFEICAO o banner **substitui** as linhas "Status: ACTIVE"/"IN_PROGRESS".
5. Corrigir `MANALOOM_VISUAL_EXECUTION_BASE…` (status l.5, tokens l.99-102, agentes l.386-411) e `.hermes.md` (§3.16).
6. Adicionar 13 entradas `historical_evidence` em `document_overrides` (todos os MARCAR_HISTORICO + EASYPANEL + READINESS + PROJECT_LOGIC), rodar `./scripts/manaloom_project_logic.sh --write` e `--check`. Se o dono preferir menos entradas, a alternativa é uma `prefix_rule` nova, mas não há prefixo comum a esses arquivos de raiz.
7. Fora do grupo, mas descoberto aqui: `docs/CONTEXTO_PRODUTO_ATUAL.md:260-262` aponta para 3 arquivos que já estão em `archive_docs/root/`; `server/doc/COMMANDER_LEARNING_API_2026-06-03.md` e `server/doc/MANALOOM_CRONS_E_PENDENCIAS.md` têm banner histórico e também não estão no registry.
