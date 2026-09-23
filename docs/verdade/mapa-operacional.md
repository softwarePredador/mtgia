# Auditoria documental — grupo "Mapa operacional do projeto"

- Documento: `docs/MAPA_OPERACIONAL_DO_PROJETO.md` (460 linhas; última alteração em `b397f477b`, 2026-09-21)
- Auditado em 2026-09-22 sobre `HEAD = d15beb05b` (árvore suja: `docs/generated/*`, `project_logic_manifest.json`, `server/routes/community/marketplace/index.dart`, `docs/flows/`, `docs/design/`, `docs/PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md`, `server/test/community_marketplace_privacy_contract_test.dart`)
- Método: cada afirmação verificável conferida contra código, registry, git log, arquivos no disco (inclusive fora do repo, somente leitura: `~/Library/LaunchAgents`, `~/Library/Application Support/ManaLoom/external-engine-delta`) e documentos de autoridade maior. Nada foi executado além de leitura, `git log/show`, `python3` sobre JSON e o script de digest de UI (`scripts/manaloom_ui_source_digest.sh`, que só lê arquivos e grava em `mktemp`).
- Estado de lifecycle do documento: está em `canonical_documents` de `docs/project_logic_contracts.json` (posição 6 de 36) desde `8e6a7e0ed` (2026-09-18 14:22), logo herda `canonical_default_state = current_contract`.

## 1. Tabela-resumo

| Documento | Veredito | Afirmações verificadas | Erradas/defasadas/contradizem | Não verificáveis | Ação |
| --- | --- | ---: | ---: | ---: | --- |
| `docs/MAPA_OPERACIONAL_DO_PROJETO.md` | **CORRIGIR** | 82 | **17** (7 DEFASADO · 9 ERRADO · 1 CONTRADIZ_OUTRO_DOC) | 2 | Corrigir no lugar: é canônico (`current_contract`), 65 de 82 afirmações continuam certas e o esqueleto (cadeia de autoridade, números de rota, política de capability, gates) é a melhor síntese que o repo tem. Não marcar como histórico nem remover. |

Proporção: 17/82 = 21% das afirmações verificáveis estão erradas ou defasadas. Concentração: §4.3 (drift das engines — inteira defasada desde 2026-09-20), §7 (estado dos gates — três itens defasados pelos commits de 2026-09-21), §2 tabela de jornadas (quatro linhas imprecisas) e a procedência/lifecycle (registrado como canônico e o texto ainda diz que não está).

## 2. Divergências — `docs/MAPA_OPERACIONAL_DO_PROJETO.md`

Formato: linha | afirmação | classificação | evidência | verdade atual | ação | texto corrigido.

### D1 — linhas 1, 9, 457 | "mapa operacional — 2026-09-18" / "Tudo aqui foi medido por análise estática deste checkout em 2026-09-18" / "Análise estática deste checkout em 2026-09-18, sobre `0677762d7`"
- Classificação: **DEFASADO**
- Evidência: `git log --follow -- docs/MAPA_OPERACIONAL_DO_PROJETO.md` → 6 commits, o último `b397f477b` (2026-09-21). A própria linha 270 diz "Medido em 2026-09-21"; a §7 inteira (linhas 264-348) e C16/C17 (374-410) foram escritas em 2026-09-21 (`446f602e0`, `b4473a98a`, `07014b431`, `d26f23a16`, `b397f477b`).
- Verdade atual: o documento mistura medições de 2026-09-18 (§1-6, 8 até C15, 9, 10) com medições de 2026-09-21 (§7, C16, C17). A base `0677762d7` vale só para a primeira camada.
- Ação: **corrigir**.
- Texto corrigido (linha 1): `# BrewTact — mapa operacional do projeto — 2026-09-18, atualizado em 2026-09-21 e 2026-09-22`
- Texto corrigido (linha 9-11): `As seções 1-6, 8 (C1-C15), 9 e 10 foram medidas por análise estática em 2026-09-18 sobre \`0677762d7\`; a seção 7 e as contradições C16-C17 foram medidas em 2026-09-21 sobre \`d26f23a16\`/\`b397f477b\`; a seção 4.3 foi remedida em 2026-09-22 sobre \`d15beb05b\`. Ele **não observa runtime nem produção**.`
- Texto corrigido (linha 457-458): `Análise estática em três camadas: 2026-09-18 sobre \`0677762d7\` (seções 1-6, 8, 9, 10), 2026-09-21 sobre \`b397f477b\` (seção 7, C16, C17) e 2026-09-22 sobre \`d15beb05b\` (seção 4.3, seção 7 revalidada). Números de banco vêm do backup local de 2026-08-03.`

### D2 — linhas 3 e 459-460 | "Status: `… NOT_RATIFIED`" / "Este documento ainda não está em `canonical_documents` de `docs/project_logic_contracts.json` — registrá-lo é decisão de governança"
- Classificação: **DEFASADO** (desde `8e6a7e0ed`, 2026-09-18 14:22)
- Evidência: `python3` sobre `docs/project_logic_contracts.json` → `canonical_documents` tem 36 entradas e a 6ª é `docs/MAPA_OPERACIONAL_DO_PROJETO.md`; `git show 8e6a7e0ed --stat` = "docs: register the operational map and deck-quality model as canonical". `documentation_lifecycle.canonical_default_state = current_contract`; não há `document_overrides` para o mapa.
- Verdade atual: o documento **é canônico** com estado `current_contract` (sem autoridade de prioridade nem de mutação, como todos os `current_contract`).
- Ação: **corrigir**.
- Texto corrigido (linha 3): `Status: \`MAP · STATIC_ANALYSIS · NO_PRIORITY_AUTHORITY · NO_MUTATION_AUTHORITY · CANONICAL_CURRENT_CONTRACT (desde 8e6a7e0ed)\``
- Texto corrigido (linha 459-460): `Este documento está em \`canonical_documents\` de \`docs/project_logic_contracts.json\` desde \`8e6a7e0ed\` (2026-09-18), com estado \`current_contract\`: é referência, não autoridade de prioridade.`

### D3 — linha 60 | "### Os dois portões, ambos fail-closed"
- Classificação: **ERRADO** e **CONTRADIZ_OUTRO_DOC** (`docs/DECK_QUALITY_MODEL.md:250-255`, canônico)
- Evidência: `server/bin/manaloom_ops_daemon.py:54` lê o mesmo `server/config/release_capabilities.json`; `:145` `_load_release_policy` (envelope inválido ⇒ política vazia, fail-closed); `:711-734` `JOB_REQUIRED_CAPABILITIES` com 16 chaves; `:736-745` `_jobs_for_release_policy` só agenda job cujas capabilities estejam todas `allowed`; `:421` `operational_mode: safe_housekeeping_only`; `:396` `_start_disabled_ops_health` sobe `/health` próprio na porta `MANALOOM_NATIVE_BATTLE_PORT`. `scripts/manaloom_deploy_ops_image.sh:366,369` reasserta no deploy `enabled_jobs == ['hermes_cron_governor_report']`. `docs/DECK_QUALITY_MODEL.md:250-255` já descreve esse filtro como "cadeado 1". O próprio mapa cita o daemon nas linhas 213 e 242-244, mas não o conta como portão.
- Verdade atual: **três** consumidores de runtime da política, cada um fail-closed: servidor (`server/routes/_middleware.dart:105-144`), app (`app/lib/core/config/release_capabilities.dart:350-534`) e scheduler (`server/bin/manaloom_ops_daemon.py:145-205,711-746`). Com 29/29 `off`, 15 dos 16 jobs não rodam.
- Ação: **corrigir**.
- Texto corrigido (linha 60 e novo item após a linha 70):
  ```
  ### Os três portões, todos fail-closed

  - **Servidor** — (mantém o texto atual)
  - **App** — (mantém o texto atual)
  - **Scheduler** — `server/bin/manaloom_ops_daemon.py:145-205` carrega o mesmo
    `server/config/release_capabilities.json` (envelope inválido ⇒ política
    vazia; caminho diferente do canônico ⇒ política inválida) e
    `_jobs_for_release_policy` (`:765-777`) só agenda um job se **todas** as
    capabilities de `JOB_REQUIRED_CAPABILITIES` (`:725-751`, 17 jobs) estiverem
    `allowed`. Com 29/29 `off`, rodam 2 de 17, os dois com tupla vazia:
    `hermes_cron_governor_report` e, desde 2026-09-23,
    `manaloom_catalog_reference_refresh`, que só grava dado de referência depois
    da ativação. O daemon sobe em `safe_housekeeping_only` com um `/health`
    próprio na porta `MANALOOM_NATIVE_BATTLE_PORT` (`:399-470`). O deploy
    reasserta isso (`scripts/manaloom_deploy_ops_image.sh:366,369`).
  ```

### D4 — linha 93 | "card_collection | sim | não | `catalog_private`"
- Classificação: **ERRADO** (incompleto ao ponto de induzir erro)
- Evidência: `server/lib/release_capability_policy.dart:534-536` → `/binder` e `/binder/*` ⇒ `collection_private`; `:525-533` → `/cards`, `/sets`, `/rules`, `/market/*` ⇒ `catalog_private`. No app, `release_capabilities.dart:460-476` manda `/collection*` para `/home` por `collection_private`, e `/collection/sets`, `/collection/latest-set` para `/collection?tab=0` por `catalog_private`. Já apontado por `docs/flows/binder_collection_scanner.md:256,279` e `docs/flows/card_catalog.md:274`.
- Verdade atual: a jornada tem duas capabilities — `catalog_private` (catálogo, edições, preço via `/market/*`) e `collection_private` (fichário, import, editor) — mais `scanner` para `/decks/:id/scan` e `trades` para `/collection/matches`.
- Ação: **corrigir**.
- Texto corrigido: `| card_collection | sim | não | \`catalog_private\` (catálogo, edições, \`/market/*\`) + \`collection_private\` (fichário/import) · \`scanner\` no scan · \`trades\` em \`/collection/matches\` |`

### D5 — linha 94 | "deck_lifecycle | sim | não | `decks_private`"
- Classificação: **ERRADO** (incompleto; o próprio documento registra `deck_replace_all` em 127-131 e C14)
- Evidência: `server/lib/release_capability_policy.dart:389-397` → `PUT /decks/:id`, `POST /decks/:id/cards/replace` e `POST /import/to-deck` ⇒ `deck_replace_all`; `:474-476` → `/decks/:id/reports` ⇒ `gallery_public`; app `release_capabilities.dart:390-400` → `/decks/:id/search` exige `catalog_private`, `/scan` exige `scanner`. `docs/flows/deck_lifecycle.md:302,330` registra "são cinco capabilities".
- Ação: **corrigir**.
- Texto corrigido: `| deck_lifecycle | sim | não | \`decks_private\` (base) + \`deck_replace_all\` (PUT /decks/:id, replace, import/to-deck) + \`catalog_private\` (busca de carta) + \`scanner\` (scan) + \`gallery_public\` (/decks/:id/reports) |`

### D6 — linha 99 | "battle / jogar contra IA | **não compilado no artefato** | não | `battle_batch` + trava de compilação"
- Classificação: **ERRADO** (meia-verdade)
- Evidência: `app/lib/main.dart:656-674` registra `battle-replays` **incondicionalmente**, guardada só por `battle_batch` (`release_capabilities.dart:407-410`); a trava de compilação `LaunchFeatures.interactiveBattleSupported` (`app/lib/core/config/launch_features.dart:31-34`, `defaultValue: false`) vale só para `play-vs-ai*` e `battle-coach*` (`main.dart:675,690,704,713`), capability `battle_coach`. Apontado por `docs/flows/battle_replay.md:266,293`.
- Ação: **corrigir** (desdobrar em duas linhas).
- Texto corrigido:
  ```
  | battle — Battle Lab / replays | sim, compilado | não | `battle_batch` |
  | battle — Jogar contra IA | **não compilado no artefato** (`ENABLE_INTERACTIVE_BATTLE` default `false`) | não | `battle_coach` + trava de compilação |
  ```

### D7 — linha 100 | "life_counter | client-only | parcial | `life_counter_local` (sem rota)"
- Classificação: **ERRADO**
- Evidência: rota existe — `app/lib/main.dart:491-501` `GoRoute(path: lifeCounterRoutePath, …)`, com `lifeCounterRoutePath = '/life-counter'` (`app/lib/features/home/life_counter_route.dart:4`); guard nega em `release_capabilities.dart:363-366` (`/life-counter*` ⇒ `/home`); a entrada da Home exige `_lifeCounterAllowed` (`app/lib/features/home/home_screen.dart:114,123,160,171,189`). Apontado por `docs/flows/platform_release_ops.md:263` (achado 12).
- Verdade atual: rota existe e está bloqueada pelo guard; com `life_counter_local` off não há caminho alcançável no app — não é "parcial".
- Ação: **corrigir**.
- Texto corrigido: `| life_counter | client-only (bundle web + folhas nativas) | não — rota \`/life-counter\` existe (\`main.dart:491-501\`) e o guard a devolve a \`/home\` | \`life_counter_local\` |`

### D8 — linhas 178-180 | "Cadência pretendida: domingo, 09:17, via LaunchAgent."
- Classificação: **ERRADO** (contradiz o contrato canônico `docs/MANALOOM_EXTERNAL_ENGINE_DELTA_SCHEDULE.md`)
- Evidência: `docs/MANALOOM_EXTERNAL_ENGINE_DELTA_SCHEDULE.md:43-48` — "Para checkouts em `Documents`, `Desktop` ou `Downloads`, a opção operacional é uma automação cron local do Codex … roda domingo às 09:17 … A automação atual se chama `ManaLoom • Deltas XMage/Forge`"; `:53-54` — o LaunchAgent é a alternativa para checkouts **fora** das pastas protegidas. Instalador: `scripts/manaloom_install_external_engine_delta_schedule.sh:58-64` bloqueia `~/Documents`.
- Verdade atual: para este checkout o mecanismo declarado é a automação Codex, não LaunchAgent; e ela roda — ver D9.
- Ação: **corrigir**.
- Texto corrigido: `Cadência declarada (\`docs/MANALOOM_EXTERNAL_ENGINE_DELTA_SCHEDULE.md:43-48\`): domingo, 09:17, por automação cron local do Codex ("ManaLoom • Deltas XMage/Forge"), porque o checkout está sob \`~/Documents\` e o instalador de LaunchAgent recusa pastas protegidas por TCC (\`scripts/manaloom_install_external_engine_delta_schedule.sh:58-64\`). O LaunchAgent \`com.manaloom.external-engine-delta-weekly\` não está instalado (\`ls ~/Library/LaunchAgents\`) e não é o caminho previsto para este checkout.`

### D9 — linhas 176, 182-197 | "Detecção de drift — e por que não está funcionando" / tabela com `latest.json = skipped · dirty_worktree` / "Seis das oito auditorias foram puladas" / "hoje o projeto não sabe o quanto os dois motores divergiram"
- Classificação: **DEFASADO** (desde 2026-09-20 12:18Z)
- Evidência: `ls ~/Library/Application Support/ManaLoom/external-engine-delta/` → **9** relatórios; `python3` sobre cada um: 07-28 `review_required`, 08-02/08-10/08-17/08-24/08-31/09-13 `skipped · dirty_worktree`, 08-25 `review_required`, **09-20 `review_required`**; `latest.json` = cópia do de 09-20 (`generated_at_utc: 2026-09-20T12:18:42+00:00`, `mode: official_upstream_compare`). Conteúdo: XMage `ahead_by: 775` commits, 300 arquivos, classificação `card_additions 579 / engine_changes 106 / rules_fixes 90`; Forge `ahead_by: 780`, 300 arquivos; `summary.candidate_cards: 211`, `candidate_fixtures: 212`, `pin_contract_failures: 0`, todos os espelhos `matches_canonical_pin`.
- Verdade atual: a auditoria rodou no domingo 2026-09-20 (árvore estava limpa naquele momento), consultou o upstream e o projeto **sabe** o delta: 775 commits XMage e 780 Forge desde os pins, 211 cartas candidatas a revisão. Seis de **nove** auditorias foram puladas por árvore suja. A árvore está suja de novo desde 2026-09-21 (git status), então a próxima (2026-09-27) será pulada se ninguém limpar.
- Ação: **corrigir**.
- Texto corrigido (linha 176): `### 4.3 Detecção de drift — funciona quando a árvore está limpa`
- Texto corrigido (linhas 182-197):
  ```
  **Estado real medido (2026-09-22):**

  | Relatório | Status |
  | --- | --- |
  | 2026-07-28, 2026-08-25, **2026-09-20** | consultou upstream (`review_required`) |
  | 08-02, 08-10, 08-17, 08-24, 08-31, 09-13 | `skipped · dirty_worktree` |
  | `latest.json` | = 2026-09-20, `review_required` |

  **Seis das nove auditorias foram puladas porque a árvore de trabalho estava
  suja.** A de 2026-09-20 rodou e mediu: XMage `master` está **775 commits**
  à frente do pin, Forge **780**; 211 cartas candidatas e 212 fixtures
  candidatos a revisão; todos os espelhos de pin coerentes
  (`pin_contract_failures: 0`). A automação Codex está operando; o LaunchAgent
  não está instalado e não é o caminho para este checkout (§4.1/§4.3 acima).

  Consequência: **o projeto sabe o delta desde 2026-09-20**; o que não existe é
  a revisão nominal das 211 cartas nem decisão de avançar pin. A árvore voltou
  a ficar suja em 2026-09-21; a auditoria de 2026-09-27 será pulada se não for
  limpa antes.
  ```

### D10 — linhas 203-209 | "Última checagem: MTGJSON 2026-06-06 (104 dias) · Scryfall legalidades 2026-06-06 · EDHREC 2026-06-02 (108) · Comprehensive Rules 2026-06-19 (91) · corpus de meta 2026-03-13 (189)"
- Classificação: **NAO_VERIFICAVEL** (fonte primária é o backup PostgreSQL de 2026-08-03, não o repo); os dias contados estão defasados em 4 desde 2026-09-18
- Evidência: nenhum arquivo versionado carrega essas datas (`git log` de `edhrec_raw.json` = 2026-05-31; de `extract_meta_insights.dart` = 2026-07-16; não há `MagicCompRules*` versionado). A linha 457-458 declara que números de banco vêm do backup de 2026-08-03. O único item confirmável no repo é Game Changers: `git log -1 -- server/config/commander_game_changers.json` = `0014f1800` 2026-07-14 ✓.
- Ação: **corrigir** a forma, não o dado: remover a coluna "Dias" (envelhece a cada dia) e marcar a coluna "Última checagem" como `(backup 2026-08-03)`.
- Texto corrigido (cabeçalho da tabela): `| Fonte | Consome | Última checagem (backup PG 2026-08-03; Game Changers via git) | Checagem automática |`

### D11 — linha 240 | "`hermes-lab` … **não** — dormente desde 2026-06-23"
- Classificação: **NAO_VERIFICAVEL** (estado de container é runtime; a §9 do próprio documento o lista como desconhecido)
- Evidência: `git log -1 -- server/Dockerfile.hermes-lab` = `637f22193` 2026-06-18; `git log -1 -- server/bin/hermes_lab_cron_bootstrap.py` = `df3d34d69` 2026-06-18; nenhuma data 2026-06-23 ligada a hermes-lab em `docs/`. Linhas 426-427 da §9 mandam rodar `audit_easypanel_cron_runtime.py --require-hermes-lab` justamente porque o estado é desconhecido (flag existe: `server/bin/audit_easypanel_cron_runtime.py:1069`).
- Ação: **corrigir** para não afirmar runtime.
- Texto corrigido: `| \`hermes-lab\` | \`server/Dockerfile.hermes-lab\` | nenhum | **desconhecido** — último commit no Dockerfile em 2026-06-18 (\`637f22193\`); estado do container só com o comando da §9 |`

### D12 — linha 279 | "`ui_live_evidence` | quick **e full** | **falha** — 23 de 35 packs com digest defasado"
- Classificação: **DEFASADO** (desde `b397f477b`/`9a9ba66de`, 2026-09-21)
- Evidência: `./scripts/manaloom_ui_source_digest.sh` = `8bba809c…`; `docs/qa/ui-live/latest.json` referencia 23 `capture_manifests`, **22** com `source_digest = 8bba809c…` e **1** defasado (`docs/qa/ui-live/current/play-vs-ai-web-real/capture-manifest.json`, `865e6041…`); o próprio `latest.json` ainda tem `source_digest = 865e6041…`, e `app/tool/ui_runtime_evidence.dart:512` exige igualdade com o digest atual. Dos 35 diretórios em `docs/qa/ui-live/current/`, 12 não são exigidos pelo `latest.json` (`stale_not_claimed`). `docs/PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md:19-28` confirma (22 de 23 verdes; bloqueio no E2E de Jogar contra IA).
- Verdade atual: o gate **continua falhando**, mas por dois itens: o pack `play-vs-ai-web-real` e o `source_digest` de `latest.json` (ambos em `865e6041…`, atual `8bba809c…`).
- Ação: **corrigir**.
- Texto corrigido: `| **\`ui_live_evidence\`** | quick **e full** | **falha** — 22 de 23 manifests exigidos estão no digest atual \`8bba809c\`; falta \`play-vs-ai-web-real\` e o \`source_digest\` de \`docs/qa/ui-live/latest.json\` (ambos ainda em \`865e6041\`) |`

### D13 — linha 304 | "Com aquele contrato corrigido, o `full` passou a chegar ao **último** estágio e revelou …"
- Classificação: **ERRADO** (o próprio documento se corrige nas linhas 319-325 e não apagou a frase)
- Evidência: `melos.yaml:98` encadeia 6 estágios e `quality_gate.sh full` é o **2º**; dentro dele, `run_public_web_full` é o 3º de 4 arms (`scripts/quality_gate.sh:464-468`), seguido de `run_runtime_performance_contract`; depois vêm `ui-audit`, `custom-lint`, `patrol-smoke`, `manaloom_dependency_audit.sh` e, em `manaloom_local_ci.sh full`, ainda `run_schema_gate` (`:225-233`). Commit `d26f23a16` registra a correção: "o full morre no segundo de seis".
- Ação: **corrigir**.
- Texto corrigido: `Com aquele contrato corrigido, o \`full\` passou a chegar ao **segundo de seis** estágios do \`melos run quality\` (\`quality_gate.sh full\`, arm \`run_public_web_full\`) e revelou o bloqueio seguinte:`

### D14 — linhas 332-334 | "a recaptura está travada por versão: o ChromeDriver pinado em 6 scripts é o 150, o Chrome instalado é o 153, e nenhum script do repositório baixa driver"
- Classificação: **DEFASADO** (desde `b397f477b`, 2026-09-21 20:29)
- Evidência: `scripts/lib/manaloom_chromedriver.sh:14` `MANALOOM_CHROMEDRIVER_VERSION="153.0.8010.52"`, `:17` URL do Chrome for Testing, `:18` cache em `~/Library/Caches/manaloom/chromedriver/`; `scripts/manaloom_chromedriver_bootstrap.sh` baixa e confere SHA-256 (mensagem de `b397f477b`); `grep -rn "CHROMEDRIVER_VERSION=" scripts/*.sh` = vazio (nenhum pin inline sobrou). O digest de UI passou a cobrir a lib (`manaloom_ui_source_digest.sh:66-71`).
- Ação: **corrigir**.
- Texto corrigido: `A trava de versão do ChromeDriver foi resolvida em \`b397f477b\`: um único pin (\`scripts/lib/manaloom_chromedriver.sh:14\`, 153.0.8010.52) com bootstrap que baixa e confere SHA-256 (\`scripts/manaloom_chromedriver_bootstrap.sh\`); o pin entra no digest de UI. O que trava a recaptura hoje é o E2E de Jogar contra IA (\`manaloom_play_vs_ai_e2e.sh\` invoca \`manaloom_server_contract_e2e_isolated.sh\` duas vezes e a segunda para em \`BLOCKED: build output has a consumer\`), registrado em \`docs/PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md:23-28\`.`

### D15 — linhas 336-337 | "`git log --grep=no-verify -i` devolve **11 commits** nesta branch, 9 deles em 2026-09-18"
- Classificação: **DEFASADO** (o número era 11 em `b4473a98a`; os 5 commits seguintes também foram `--no-verify`)
- Evidência: `git log --grep=no-verify -i --format='%h %ad' --date=short | wc -l` = **16**: 9 em 2026-09-18 e 7 em 2026-09-21 (`b4473a98a`, `07014b431`, `d26f23a16`, `b397f477b`, `9a9ba66de`, `d08c18717`, `d15beb05b`).
- Ação: **corrigir**.
- Texto corrigido: `\`git log --grep=no-verify -i\` devolve **16 commits** nesta branch (medido em 2026-09-22): 9 em 2026-09-18 e 7 em 2026-09-21, todos sob autorização explícita. Este documento registrava três, depois onze; o número cresce a cada sessão enquanto \`ui_live_evidence\` não fechar.`

### D16 — linha 365 | "C7 · Cadência semanal de drift declarada como instalada; não está, e não pode ser neste caminho | schedule vs `~/Library/LaunchAgents`"
- Classificação: **ERRADO**
- Evidência: a mesma de D8 e D9 — o contrato declara automação Codex para este checkout (`docs/MANALOOM_EXTERNAL_ENGINE_DELTA_SCHEDULE.md:43-48`), não LaunchAgent; e há 9 relatórios semanais no diretório exclusivo, o último de 2026-09-20 com consulta real ao upstream. O que continua verdadeiro: `~/Library/LaunchAgents` não tem `com.manaloom.external-engine-delta-weekly.plist` (só `card-semantics-audit`, `structure-audit`, `weekend-learning`).
- Ação: **corrigir** (reescrever C7).
- Texto corrigido: `| C7 | O agendamento semanal existe e roda (9 relatórios, último 2026-09-20 com upstream consultado), mas 6 de 9 execuções foram puladas por árvore suja; a árvore voltou a ficar suja em 2026-09-21 | \`~/Library/Application Support/ManaLoom/external-engine-delta/\` vs \`git status\` |`

### D17 — linha 386 | "quando 18 de 22 continuam passando a deriva não grita"
- Classificação: **ERRADO** (contradiz a linha 374 do mesmo documento e o commit de correção)
- Evidência: linha 374 diz "23 das 27 asserções continuavam válidas"; `git log -1 --format=%B d26f23a16` registra "27 asserções no bloco de egress (não 22)". O bloco está em `server/test/mutating_e2e_entrypoint_guard_test.dart:365-440`.
- Ação: **corrigir**.
- Texto corrigido: `e quando 23 de 27 continuam passando a deriva não grita.`

### D18 — linha 451 | "Material sob `docs/hermes-analysis/` é histórico e não tem autoridade atual."
- Classificação: **CONTRADIZ_OUTRO_DOC** (`docs/project_logic_contracts.json`, autoridade maior) e contradiz o próprio mapa (linha 161 usa `docs/hermes-analysis/EXTERNAL_ENGINE_PIN_TRANSITION_CONTRACT.json` como fonte)
- Evidência: `canonical_documents` lista 8 arquivos sob `docs/hermes-analysis/` (`EXTERNAL_BATTLE_EXECUTION_CONTRACT.md`, `EXTERNAL_ENGINE_CAPABILITY_CONTRACT.json`, `EXTERNAL_ENGINE_PIN_TRANSITION_CONTRACT.json`, `GLOBAL_BATTLE_RULES_AND_LEARNING_CLOSURE_2026-07-15.md`, `COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md`, `DATA_FIELD_ALIAS_CONTRACT_2026-06-30.md`, `APP_AI_KNOWLEDGE_BRIDGE_CONTRACT_2026-07-06.md`, `XMAGE_GOVERNED_RUNTIME_PATCH_CONTRACT.json`), estado `current_contract`. `prefix_rules` marca como `historical_evidence` apenas `docs/hermes-analysis/archive/`, `…/deduplicated-report-content/` e `…/master_optimizer_reports/`; o restante do diretório cai em `default_state = supporting_reference_non_authoritative`.
- Ação: **corrigir**.
- Texto corrigido: `Sob \`docs/hermes-analysis/\`, oito arquivos são contratos canônicos (\`canonical_documents\` de \`docs/project_logic_contracts.json\`, entre eles os dois contratos de engine citados na §4); \`archive/\`, \`deduplicated-report-content/\` e \`master_optimizer_reports/\` são \`historical_evidence\`; o resto é referência de apoio sem autoridade.`

### D19 — linhas 149 e 153 | "Atualizado em 2026-07-28 (**52 dias**) | 2026-07-14 (**66 dias**)" / "2026-08-03 (46 dias)"
- Classificação: **DEFASADO** (aritmética relativa a 2026-09-18; hoje 56/70/50)
- Evidência: `git log -1 -- services/xmage-sidecar/XMAGE_COMMIT` = `c05774e0f` 2026-07-28 ✓; `FORGE_COMMIT` = `0c9a4075c` 2026-07-14 ✓; `XMAGE_PATCH_COMMIT` = `a6ee09c8f` 2026-08-03 ✓. Os valores dos pins conferem (`2c43ec8cdb5c…`, `a62915f500c2…`, `991948742f84…`).
- Ação: **corrigir** — manter só a data absoluta e o commit; retirar o contador de dias.
- Texto corrigido: `| Atualizado em | 2026-07-28 (\`c05774e0f\`) | 2026-07-14 (\`0c9a4075c\`) |` e `\`XMAGE_PATCH_COMMIT = 991948742…\`, atualizado em 2026-08-03 (\`a6ee09c8f\`)`.

## 3. Afirmações conferidas e CORRETAS (65) — com evidência

Esta lista é a que vira tabela de verdade. Cada linha: afirmação → evidência.

### Cadeia de autoridade e decisão (§0-1)
1. Cinco camadas de autoridade (decisão → backlog → registry → fila → fichas) e receipts em `docs/qa/execution/` → `docs/execution/README.md:11-21`.
2. Nenhum documento autoriza deploy/migração/escrita live → `docs/execution/README.md:22-24`; `documentation_lifecycle.guards.document_may_authorize_live_mutation = false`.
3. Decisão de 2026-08-25: `NO_GO_PUBLIC_RELEASE`, candidato `CONTROLLED_FREE_BETA`, Web e Android, iOS/VoiceOver `DEFERRED_BY_SCOPE`, beta gratuita sem comércio, teto 120 ações de IA/mês UTC, marca BrewTact em `https://brewtact.com`, "nenhuma rota, CTA ou modo público de espectador" → `docs/status/CURRENT_PRODUCT_DECISION.md:4-9,18,37-41,88`.
4. Teto de 120 implementado em `server/lib/plan_service.dart:94` (`freeBetaAiMonthlyOperationalLimit = 120`) e inerte: `/ai/*` cai no portão de capability (`_middleware.dart:105-144`) antes de `aiPlanLimitMiddleware` (`server/routes/ai/_middleware.dart:73-75`).

### Portões e números (§2-3)
5. Portão do servidor em `server/routes/_middleware.dart:105-144`: 404 `capability_unavailable`, 404 `capability_route_unclassified`, 503 com política inválida (`release_capability_policy.dart:168-194`); nenhum `bypass`/`kDebugMode` em política ou middleware (grep vazio).
6. Portão do app: `ReleaseCapabilityRouteGuard.redirectFor` em `app/lib/core/config/release_capabilities.dart:350`, chamado em `app/lib/main.dart:426-434`; snapshot default `denied()` (`:256`) e toda falha volta a `denied()` (`:275,308,314`).
7. **46 `GoRoute`** em `app/lib/main.dart` (`grep -c 'GoRoute('` = 46; 48 `path:` = 46 rotas + 2 `Uri(...)` em `:373,:405`).
8. **10 rotas alcançáveis** com 29/29 off, derivadas rota a rota contra o guard: `/`, `/login`, `/forgot-password`, `/reset-password`, `/verify-email`, `/legal`, `/home`, `/onboarding/core-flow`, `/plans`, `/profile`. Todas as demais 36 redirecionam (`release_capabilities.dart:358-531`).
9. Destinos de navegação renderizados: 2 de 5 (Início, Perfil) → `app/lib/core/widgets/main_scaffold.dart:38-67` (Decks, Coleção e Comunidade condicionados a capability).
10. **120** arquivos de rota no servidor sem `_middleware.dart` (136 com; 16 middlewares); **99** não nomeados em `implementation/tests/gates/sequence` de nenhum fluxo declarado (21 nomeados) → `find` + `python3` sobre `docs/project_logic_contracts.json`.
11. **8 fluxos** declarados: `auth_session, card_collection, deck_lifecycle, deck_ai, battle_replay, life_counter_post_game, social_trade, release_operations`.
12. **29 capabilities**, `allowed=true` em **0**, `release_capability != 'off'` em 0, `live_verified_as_of = null` no topo e em todas; `policy_version = brewtact_free_beta_2026-08-13`; `offer_mode = free_beta_no_commerce`; `implementation_status = implemented_guarded` → `server/config/release_capabilities.json`.
13. `/register` redireciona para `/login` com `account_registration` off → `app/lib/main.dart:320-329` e `release_capabilities.dart:358-361`.
14. Só `auth_session` é alcançável (sem auto-cadastro) → itens 8, 12, 13.
15. Schema da política não tem campo `reason`; chaves por entrada são exatamente `allowed, implementation_status, live_verified_as_of, release_capability` (JSON) e `_releaseCapabilityValues = {on, off, experimental_allowlist}` (`release_capability_policy.dart:65-69`).
16. `deck_replace_all` e `legacy_ai_routes` são capabilities reais (`release_capability_policy.dart:43-44,389-397,453`) e a decisão não as menciona (grep = 0 em `CURRENT_PRODUCT_DECISION.md`).
17. `/market/*` (inclui `/market/card/:id` e `/market/movers`, arquivos em `server/routes/market/`) classificado como `catalog_private` → `release_capability_policy.dart:525-533` (C12).
18. `/reports*` é plano de controle (`null`) e `/decks/:id/reports` exige `gallery_public` → `release_capability_policy.dart:471-476` (C13).
19. Jogar contra IA não compilado por padrão: `LaunchFeatures.interactiveBattleSupported = bool.fromEnvironment('ENABLE_INTERACTIVE_BATTLE', defaultValue: false)` (`launch_features.dart:31-34`), rotas condicionadas em `main.dart:675,690,704,713` (C4).
20. `/marketplace` é `GoRoute` com `redirect` → `app/lib/main.dart:804-807`.

### Engines (§4.1-4.2)
21. XMage MIT / Forge GPL-3.0-only; papéis e fronteiras (`isolated_sidecar_api` / `isolated_process_api_only_no_backend_source_copy`) → `docs/hermes-analysis/EXTERNAL_ENGINE_CAPABILITY_CONTRACT.json` `engines[0..1]`.
22. Pins canônicos e valores: `services/xmage-sidecar/XMAGE_COMMIT = 2c43ec8cdb5c…`, `services/forge-sidecar/FORGE_COMMIT = a62915f500c2…`, `services/xmage-sidecar/XMAGE_PATCH_COMMIT = 991948742f84…` (arquivos lidos).
23. 7 espelhos obrigatórios do XMage e 2 do Forge no auditor → `docs/hermes-analysis/manaloom-knowledge/scripts/external_engine_upstream_delta_audit.py:64-131`; espelho de facto do Forge fora do auditor: `server/lib/ai/battle_engine_config.dart:12` `pinnedForgeCommit` (C8).
24. Regras de transição de pin (discovery only, diff exato, classificação nominal, resolução de catálogo não é prova semântica, reconciliação PG read-only, `deploy_requires_qualification_status: pass`) → `EXTERNAL_ENGINE_PIN_TRANSITION_CONTRACT.json.policy`.
25. Última transição `34d81ea… → 2c43ec8…`: 152 commits, 356 paths, 169 implementações de carta, 34 em escopo de produto, 133 bloqueadas por ativação → `…PIN_TRANSITION_CONTRACT.json.active_transition.expected`.
26. Gate `./scripts/quality_gate.sh engine-transition` existe → `scripts/quality_gate.sh:530`; o script tem 26 modos (`grep -c '^    [a-z][a-z0-9|_-]*)'`), compatível com "~25".
27. O LaunchAgent `com.manaloom.external-engine-delta-weekly.plist` não está instalado e o instalador recusa `~/Documents` → `ls ~/Library/LaunchAgents` (3 plists ManaLoom, nenhum de engine-delta); `scripts/manaloom_install_external_engine_delta_schedule.sh:58-64`.
28. A árvore está suja e isso pula a auditoria → `git status` (5 modificados, 4 untracked); `scripts/manaloom_external_engine_delta_weekly.sh:196-197` (`skipped dirty_worktree`).

### Upstreams de dado (§4.4)
29. `sync_cards.dart`, `sync_rulings.dart`, `cron_snapshot_edhrec.sh`, `extract_meta_insights.dart`, `sync_rules.dart` existem em `server/bin/` e nenhum é job do daemon (grep = 0 em `manaloom_ops_daemon.py`).
30. Job de legalidades Scryfall registrado (`manaloom_ops_daemon.py:598-605`, cron `30 */6 * * *`, capability `catalog_private`) e dry-run por padrão (`server/bin/sync_card_legalities_from_scryfall.sh:15` só passa `--apply` com `MANALOOM_SYNC_CARD_LEGALITIES_APPLY=1`).
31. `sync_rules.dart --check` compara fonte WotC/cache/PostgreSQL sem escrever (`server/bin/sync_rules.dart:16-52`) e não está em cron nem CI (só `sync_rules_safety_test.dart` em `manaloom_e2e_suite.sh:420`).
32. Gate de Game Changers roda a cada commit (`manaloom_local_ci.sh:114-119` → `sync_game_changers_to_dart.py --check`) e não consulta a WotC (script sem `urlopen/requests`; só valida `source_url` em `:35`). Arquivo atualizado em 2026-07-14 (`0014f1800`).
33. Oito scripts de sync vivem como receita de crontab e não estão no daemon: `server/doc/MANALOOM_CRONS_E_PENDENCIAS.md` lista 9 `cron_*.sh`; só `cron_cleanup_optimize_telemetry.sh` está registrado (`manaloom_ops_daemon.py:581`) → 8 fora. Coerente com `d93867b68`.

### O que roda onde (§5)
34. Scripts de deploy existem: `manaloom_deploy_backend_image.sh`, `manaloom_deploy_ops_image.sh`, `manaloom_deploy_battle_sidecars.sh`, `manaloom_deploy_flutter_web.sh`, `manaloom_publish_android_release.sh`, `manaloom_deploy_public_web.sh`; `server/Dockerfile.manaloom-ops` e `server/Dockerfile.hermes-lab` existem.
35. Flutter Web bloqueado sem capability aberta → `scripts/manaloom_deploy_flutter_web.sh:38-41` chama `manaloom_require_public_app_release_open`, que exige ao menos uma capability `on`+`allowed`+`live_verified_as_of` datado (`scripts/lib/manaloom_release_capabilities_contract.sh:171-189`).
36. APK fixa o snapshot de capabilities na identidade do release → `scripts/manaloom_publish_android_release.sh:57,130-140`.
37. Web público é o único deploy sem referência a capability → `grep -ci capabilit scripts/manaloom_deploy_public_web.sh` = 0; os outros cinco: 15/15/20/15/8 (C15).
38. `manaloom-ops` sobe em `safe_housekeeping_only` com 1 job (`hermes_cron_governor_report`) → `manaloom_ops_daemon.py:421,703-709,731-734`; reassertado no deploy (`manaloom_deploy_ops_image.sh:366,369`).
39. `docs/DECK_QUALITY_MODEL.md` §5 descreve três cadeados → `:248-262`.

### Etapas (§6)
40. `TASK_REGISTRY.json`: 220 tasks, 402 arestas, 3 `PASS` (`BT-GOV-001`, `BT-DOC-001`, `BT-DOC-004`) → `python3` sobre o arquivo (idêntico em `HEAD` e na cópia modificada: diff de 1 linha).
41. Slot `NOW = BT-SCP-001`, WIP 1, horizonte de 11 IDs → `docs/execution/CURRENT_QUEUE.md:16,25-42`.
42. `docs/execution/PROPOSED_TASKS_DECK_QUALITY_2026-09-18.md` existe.

### Gates (§7) — estado revalidado em 2026-09-22
43. `.githooks/pre-commit` → `manaloom_local_ci.sh quick`; `pre-push` → `full`; `core.hooksPath = .githooks`.
44. `quick` = shell contracts, Game Changers, MCP, secret scan, project logic, `ui_live_evidence` (`manaloom_local_ci.sh:216-223`); `full` = shell, Game Changers, MCP, secret, guardrail audits, release contracts, `melos run quality`, schema gate (`:225-234`).
45. Project logic passa desde `d83e9b1e1` (commit existe; diagnóstico `bootstrapWorkspacePackages` em `manaloom_local_ci.sh:108-112`).
46. Contrato de web público corrigido em 2026-09-21: alternâncias `gr(a|á)tis`/`cobran(c|ç)a` em `scripts/lib/manaloom_public_web_surface_contract.sh:86-113`, commits `07014b431`/`d26f23a16`.
47. `npm audit` continua vermelho por pin: `web-public/package.json:22` `"next": "15.5.21"` exato e `overrides.sharp = "0.35.3"` (`:19`); `manaloom_public_web_smoke.sh:199` roda `npm audit --omit=dev --audit-level=moderate`. Bump autorizado e não executado (`PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md:179`).
48. `melos.yaml:98` encadeia seis estágios; `quality_gate.sh:190-204` `run_ui_audit` chama `run_ui_live_evidence`; logo `full` também exige evidência de UI.
49. Ordem dos bloqueios: `npm audit` → `ui_live_evidence` → `custom-lint`, `patrol-smoke`, `dependency-audit` (e, no `local_ci full`, ainda `run_schema_gate`) — nunca alcançados.
50. Digest de UI é global: `scripts/manaloom_ui_source_digest.sh:25-81` cobre `app/lib`, `app/assets`, `app/web`, Android, pubspecs, **11** testes de prova visual, drivers, fixtures e, desde `b397f477b`, `scripts/lib/manaloom_chromedriver.sh`. 35 diretórios de pack em `docs/qa/ui-live/current/`.
51. **Hoje nenhum commit nem push passa sem `--no-verify`**: `quick` inclui `ui_live_evidence` e `app/tool/ui_runtime_evidence.dart:512` exige `latest.json.source_digest == 8bba809c…` (está em `865e6041…`).
52. Node do PATH `v20.11.1` (abaixo de `^20.19.0 || ^22.13.0`, `web-public/package.json:6`); `/opt/homebrew/bin/node` quebra (`dyld: Library not loaded libsimdutf.34.dylib`); `/opt/homebrew/opt/node@22/bin/node` = `v22.23.2`.
53. `grep` do shell interativo é `ugrep 7.8.4`; `/usr/bin/grep` é BSD 2.6.0.

### Contradições (§8) que continuam válidas
54. C1: `docs/BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md:376-381` diz "sim" em seis linhas de "Funciona hoje" para jornadas 404.
55. C2: zero ocorrências de `release_capabilit` no mesmo arquivo (`grep -c` = 0).
56. C3: `d93867b68` marcou seis documentos e não este.
57. C5: `OFF_UNTIL_P0_RECEIPT` aparece em `CURRENT_PRODUCT_DECISION.md:60,61,63,114` e não é valor legal (`release_capability_policy.dart:65-69`).
58. C6: `server/bin/cron_sync_rulings.sh:5` diz "MTGJSON AtomicCards"; `server/bin/sync_rulings.dart:25-26` consome `api.scryfall.com/bulk-data`.
59. C9: 26 IDs `P0 CORE` não são ancestrais de `BT-DEC-001` (52 `P0 CORE`; 33 ancestrais; lista: `BT-OFFER-001, BT-AUTH-001..004, BT-AUTH-006, BT-LEGAL-ACCEPT-001, BT-PRIV-001/002, DCK-P0-00/03/04/06/07, BT-UX-FIX-001, BT-CAT-01/02/03, BT-SCN-00, BT-AI-029, SCOPE-P0-SOC-00, SCOPE-P0-TRD-00, BT-DB-002/003/004, BT-WEB-001`).
60. C10: `CURRENT_QUEUE.md:12-13` registra `0ce0be74…`; SHA-256 atual do backlog (e `generated_from.sha256` do registry) é `333b6c0b…`.
61. C11: fluxo `life_counter_post_game` funde `/life-counter` e `/decks/{id}/post-game` com storage local + `post_game_notes` → `project_logic_contracts.json`.
62. C14: idem item 15-16.
63. C16: bloco de egress em `server/test/mutating_e2e_entrypoint_guard_test.dart:365-440`, reescrito em `07014b431`/`d26f23a16`; guard `run_no_egress`/`EGRESS_GUARD` intacto no script.
64. C17: 48 PNG nos três packs `ux-pack-05-social-trade-web-*` (16 cada); `app/integration_test/social_trade_visual_runtime_proof_test.dart:713,747` montam `MarketplaceTabContent`/`CreateTradeScreen` direto; `marketplace` e `trades` `off`.

### Desconhecidos e índice (§9-10)
65. Comandos da §9 existem: `server/bin/audit_easypanel_cron_runtime.py --require-hermes-lab` (`:1069`), `scripts/manaloom_external_engine_delta_audit.sh`; tabela `commander_reference_profiles` em `server/bin/migrate.dart`. Os cinco documentos do índice existem; `0677762d7` existe (2026-09-18).

## 4. Fatos confirmados hoje (tabela de verdade do projeto, recorte deste grupo)

- HEAD `d15beb05b` (2026-09-21), branch `codex/free-beta-release-candidate-2026-07-17`; árvore suja (5 modificados, 4 untracked).
- `docs/MAPA_OPERACIONAL_DO_PROJETO.md` é canônico (`current_contract`) desde `8e6a7e0ed`; 36 canônicos no total; 8 deles sob `docs/hermes-analysis/`.
- Política: 29 capabilities, 0 `allowed`, `live_verified_as_of = null`, `policy_version brewtact_free_beta_2026-08-13`; validação exige `allowed == (release_capability == 'on')`.
- **Três** portões fail-closed consomem a política: servidor (`_middleware.dart:105-144`), app (`release_capabilities.dart:350-534` ligado em `main.dart:426`), scheduler (`manaloom_ops_daemon.py:145-205,711-746`; 16 jobs, 1 roda).
- App: 46 `GoRoute`, 10 alcançáveis, 2 de 5 destinos de navegação; `/life-counter` existe e é negada; `/onboarding/core-flow` é a primeira tela autenticada e fica sem objetivo com tudo off (`docs/flows/platform_release_ops.md` achado 23 — não conferido por mim nesta rodada, registrado como afirmação de outro doc).
- Servidor: 120 arquivos de rota (+16 middlewares), 99 fora dos 8 fluxos declarados; `/market/*` sob `catalog_private`; `/reports*` plano de controle; `PUT /decks/:id` sob `deck_replace_all`.
- Registry: 220 tasks, 402 arestas, 3 PASS, 126 P0 abertas, 49 `P0 CORE` abertas (52 − 3 PASS); NOW `BT-SCP-001`, horizonte 11.
- Engines: pins `2c43ec8…` (XMage, 2026-07-28), `991948742…` (patch, 2026-08-03), `a62915f…` (Forge, 2026-07-14); 7+2(+1) espelhos coerentes; **delta medido em 2026-09-20: XMage +775 commits, Forge +780, 211 cartas candidatas**; auditoria semanal roda por automação Codex (9 relatórios; 6 pulados por árvore suja); LaunchAgent não instalado.
- Gates (2026-09-22): project logic ✓ (`d83e9b1e1`); contrato web público ✓ (`07014b431`/`d26f23a16`); `npm audit` ✗ (`next 15.5.21`, `sharp 0.35.3` pinados; bump autorizado, não feito); `ui_live_evidence` ✗ (22/23 manifests em `8bba809c`; falta `play-vs-ai-web-real` e `latest.json.source_digest`); ChromeDriver pinado em um lugar (153.0.8010.52) com bootstrap; `custom-lint`/`patrol-smoke`/`dependency-audit`/`schema gate` nunca alcançados; 16 commits `--no-verify` (9 em 09-18, 7 em 09-21); nenhum commit/push passa sem `--no-verify`.
- Node: PATH `v20.11.1` insuficiente; usar `MANALOOM_NODE_BIN=/opt/homebrew/opt/node@22/bin/node` (`v22.23.2`).
- Fora do grupo, mas confirmado de passagem: o contador tem **14** folhas nativas (`ls app/lib/features/home/life_counter/life_counter_native_*_sheet.dart | wc -l` = 14; o "16" está em `docs/flows/life_counter_post_game.md:69`, não em `project_logic_contracts.json`); o daemon tem **16** jobs (o "17 crons" de `docs/PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md:163` está errado; `docs/flows/_nao_coberto.md:345` já corrigiu); `docs/flows/_nao_coberto.md:148` diz que o contador "não tem gate de release" — errado: `life_counter_local` gateia a rota e a entrada da Home.
