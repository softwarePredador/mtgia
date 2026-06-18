# Hermes Cron Value And Migration Audit — 2026-06-11

> Objetivo: auditar todas as crons Hermes uma a uma, validar se ainda agregam
> valor depois das melhorias de branch/protocolo e preparar a migração gradual
> para o servidor ManaLoom.

## Resumo executivo

Estado após ajustes em AWS/Hermes:

| Métrica | Antes | Depois |
|---|---:|---:|
| Jobs cadastrados | 25 | 25 |
| Jobs habilitados | 17 | 13 |
| Jobs pausados | 8 | 12 |

Decisão principal:

- Manter alta frequência apenas para crons determinísticas/script-only que
  alimentam aprendizado, sync e preflight.
- Reduzir frequência de crons com LLM/provider porque elas já bateram 429 e
  geram muito ruído quando não há dado novo.
- Pausar auditorias genéricas que duplicam o fluxo pós-push do Codex ou já
  causaram conflito de documentação.
- Manter jobs pesados de optimizer como execução manual até virarem rotinas do
  servidor ManaLoom com isolamento, locks e métricas.

## Atualização 2026-06-18 — EasyPanel runtime e uso real de OpenAI

Evidência canônica desta rodada:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
python3 server/bin/audit_easypanel_runtime_alignment.py --stdout-only
```

Achados confirmados:

- `manaloom-ops` está rodando no SHA
  `e0a908f02e767711b206562811eca7605de36c87`.
- `deck_learning_events.pending=0` e
  `deck_learning_events.latest_synced=2026-06-18T00:32:10.843015+00:00`,
  o que prova execução real do boot catch-up / `pull_learning_events`.
- `manaloom-ops` aparece com `openai_api_key_present=False`, e isso é o estado
  correto: os jobs canônicos ativos desse serviço são determinísticos e não
  dependem de provider.
- `hermes-lab` continua sendo o serviço report-only/provider-backed; ele é o
  único que precisa de `OPENAI_API_KEY` neste desenho atual.

Jobs server-owned confirmados como script-only/determinísticos:

- `pull_learning_events`
- `auto_sync_learned_decks`
- `auto_promote_learned_decks`
- `master_optimizer_preflight`
- `manaloom_knowledge_import`
- `hermes_mana_base_validator`
- `hermes_cron_governor_report`

Gap remanescente:

- `hermes-lab` ainda está em SHA antigo
  `80eb35700e6df11422594b4a919fe8b91110d544`.
- Esse drift não bloqueia o pipeline canônico enquanto o lab continuar
  estritamente `report-only` e sem ownership sobre decisões do backend.

## Atualização 2026-06-13 — sync obrigatório da branch docs

Achado novo: as auditorias de documentação/estrutura rodam na branch
`codex/hermes-analysis-docs`, mas essa branch pode ficar atrás de
`origin/master`. Quando isso acontece, a auditoria vê um snapshot antigo do
código e pode publicar achados stale.

Correção versionada:

- `server/bin/hermes_docs_branch_sync.sh` cria a rotina segura de sincronização.
- `docs/hermes-analysis/HERMES_DOCS_BRANCH_SYNC_CRON_2026-06-13.md` documenta
  instalação, ordem, status permitidos e guardrails.

Nova cron recomendada:

| Cron | Cadência | Função real | Valor para ManaLoom | Decisão |
|---|---:|---|---|---|
| `manaloom-docs-branch-sync` | 20m | Mergeia `origin/master` em `codex/hermes-analysis-docs` com lock e abort seguro em conflito | Garante que auditorias de docs analisam código vivo | Adicionar antes de reativar/rodar auditorias documentais |

Regra nova: qualquer auditoria que leia código vivo a partir da branch docs
deve exigir evidência fresca de `manaloom-docs-branch-sync` com status
`up_to_date` ou `merged`. Se a sync bloquear por conflito, worktree sujo ou push
falho, a auditoria deve retornar `BLOCKED`, não `FINDINGS`.

## Evidência operacional

Coleta feita no container Hermes:

```bash
cd /opt/data/workspace/mtgia
git fetch --all --prune
git status --short --branch
python3 -m json.tool /opt/data/cron/jobs.json
bash -n /opt/data/scripts/manaloom-hermes-report-only.sh \
  /opt/data/scripts/manaloom-post-push-audit.sh \
  /opt/data/scripts/manaloom-master-watchdog.sh
```

Observações iniciais:

- O workspace Hermes foi alinhado em `master`.
- Remotes reais restantes: `origin/master` e `origin/codex/hermes-analysis-docs`.
- `jobs.json` chegou a ficar `root:root 600`, impedindo leitura pelo scheduler.
  Foi corrigido com `/opt/data/scripts/fix-cron-perms.sh`.
- Após a correção, o scheduler recalculou `next_run_at`.

Evidência nova após a primeira rodada (`2026-06-11T13:05Z`):

| Cron | Resultado observado | Impacto |
|---|---|---|
| `manaloom-master-watchdog` | OK; detectou `origin/master` avançando até `5e8de767`. | Confirma que o watchdog voltou a ler Git e emitir alerta útil. |
| `manaloom-pull-learning-events` | Falhou com `sqlite3.OperationalError: attempt to write a readonly database`. | Expôs ownership incorreto em `/opt/data/workspace/mtgia`, `/opt/data/cron`, `/opt/data/artifacts` e `/opt/data/scripts`. |
| `lorehold-knowncards-validator` | Falhou com `sqlite3.OperationalError: no such table: learned_decks`. | Expôs dependência real do preflight/sync antes dos validadores de conhecimento. |

Correções operacionais aplicadas no runtime AWS:

```bash
chown -R hermes:hermes /opt/data/workspace/mtgia \
  /opt/data/cron /opt/data/artifacts /opt/data/scripts
/opt/data/scripts/fix-cron-perms.sh
```

Preflight manual como usuário `hermes` passou a popular `learned_decks` a partir
de `pg_meta_decks` (`seen=120`, `inserted=120` no primeiro apply), mas revelou
um segundo problema: o sync do target deck para `deck_cards` falhava em decks
reais com linhas duplicadas por `card_name`.

Correção versionada:

- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py`
  agora agrega duplicatas por nome antes de gravar no SQLite, somando
  quantidade e preservando comandante/tag funcional.
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_pg_target_deck_to_hermes.py`
  cobre o caso de duplicata que quebrava a cron.
- scripts operacionais de optimizer/knowncards foram ajustados para fazer
  checkout de `master`, evitando executar código antigo da branch de memória.
- `server/bin/pull_learning_events.py` agora inicializa a tabela SQLite
  `commanders`, desbloqueando importação de eventos de aprendizado em bancos
  Hermes recém-recriados.
- `server/bin/hermes_cron_governor_report.py` substitui o governor com provider
  por relatório determinístico de saúde das crons, evitando novo `429` em uma
  rotina que deveria ser observabilidade básica.
- `server/bin/hermes_master_watchdog.sh` versiona o watchdog e troca a instrução
  antiga "rodar normal audit" por `manaloom-hermes-report-only.sh`, alinhado ao
  fluxo Codex pós-push.
- `server/bin/hermes_mana_base_validator.py` substitui o validador de mana com
  provider por relatório determinístico sobre `knowledge.db`. O output padrão
  vai para `/opt/data/artifacts/hermes_mana_base_validator/`, não para `docs/`,
  para evitar workspace sujo a cada cron.

Validação remota após correções (`2026-06-11T13:25Z`):

| Job manual | Resultado | Observação |
|---|---|---|
| `manaloom-master-optimizer-preflight.sh` | PASS; `status: approved`. | `deck_cards=100`, `learned_decks=120`, `duplicate_rows_collapsed=4`, cache oracle e battle rules sincronizados. |
| `pull_learning_events.sh` | PASS; `TOTALS imported=42`. | Erro de SQLite readonly e tabela `commanders` ausente resolvidos. |
| `known_cards_validator_cron.sh` | SKIPPED por lock ativo. | Lock recente é comportamento esperado; próxima rodada deve validar com `learned_decks` já populado. |

Novo achado de qualidade:

- O pull de eventos importou vários registros com `card_count=0` ou `card_count=1`.
  Isso confirma o loop operacional, mas esses eventos devem ser tratados como
  parciais/telemetria, não como aprendizado de deck completo.
- Correção aplicada: `server/bin/pull_learning_events.py` classifica eventos em
  `trainable_commander_deck`, `partial_telemetry` ou
  `non_commander_telemetry`, com `training_eligible=1` somente para Commander
  com comandante e `card_count >= 90`.
- Validação remota pós-backfill (`2026-06-11T13:41Z`): `user_learning_events`
  ficou com `16` eventos `trainable_commander_deck`, `22`
  `partial_telemetry` e `4` `non_commander_telemetry`.

Novo achado no auto-sync de decks aprendidos (`2026-06-11T13:55Z`):

- `manaloom-auto-sync-learned-decks` estava tentando reprocessar learned decks
  promovidos antigos que não eram Commander completos. O caso observado foi
  Korvold `learned_id=7`, declarado com `card_count=90`, que o importador
  rejeitou como inválido.
- Correção aplicada: `server/bin/auto_sync_learned_decks.py` agora só seleciona
  promoted rows com comandante preenchido e `card_count=100`; promoted rows
  inválidos são contados como `INVALID_PROMOTED_SKIPPED_BY_QUERY`, sem chamar o
  importador Dart.
- Validação local adicionada em `server/test/auto_sync_learned_decks_test.py`
  cobre seleção apenas de decks Commander 100/99+1 e ausência segura das tabelas
  SQLite esperadas.

## Crons habilitadas

| Cron | Cadência | Função real | Valor para ManaLoom | Decisão |
|---|---:|---|---|---|
| `manaloom-master-watchdog` | 30m | Detecta mudança em `origin/master` | Útil enquanto Hermes precisa reagir a push sem webhook | Manter temporário; migrar para webhook/CI |
| `manaloom-pull-learning-events` | 30m | Puxa eventos de aprendizado do backend | Essencial para loop IA/humano | Manter; migrar para job server |
| `lorehold-knowncards-validator` | 30m | Valida cards conhecidos contra knowledge DB/battle | Útil para qualidade do corpus Lorehold | Manter; migrar para suite server |
| `manaloom-master-optimizer-preflight` | 60m | Sincroniza metadados, regras e roda preflight | Essencial antes de qualquer optimizer | Manter; migrar para job server isolado |
| `manaloom-knowledge-import` | 120m | Importa conhecimento Hermes de forma segura/dry-run | Útil para consolidar aprendizado | Manter; migrar para ingest server |
| `manaloom-auto-sync-learned-decks` | 120m | Sincroniza learned decks aprovados | Essencial para botão/deck aprendido no app | Manter; migrar para backend job |
| `manaloom-auto-promote-learned` | 360m | Promove learned decks elegíveis | Útil para reduzir intervenção manual | Manter; migrar para backend job com auditoria |
| `manaloom-commander-knowledge-deep` | 360m | Extrai padrões por comandante | Útil, mas dependente de provider | Manter com menor cadência; migrar para mineração determinística |
| `manaloom-knowledge-synthesis` | 360m | Transforma achados MTG em tasks | Útil como ponte Hermes → Codex | Manter com menor cadência; sempre triado por Codex |
| `manaloom-gamechanger-research` | 720m | Pesquisa gamechangers e gaps de ranking | Útil, mas corpus já está majoritariamente coberto | Manter baixa cadência |
| `manaloom-mana-base-validator` | 720m | Valida base de mana dos decks via script determinístico | Útil para qualidade de deckbuilding e detecção de decks aprendidos inválidos | Manter; migrar para backend metrics |
| `mtg-rules-auditor` | 720m | Audita regras MTG contra pipeline | Útil como guardrail técnico | Manter baixa cadência; migrar para testes/golden scenarios |
| `manaloom-cron-governor-report` | 720m | Audita saúde da frota de crons sem LLM | Útil enquanto Hermes existir; agora script-only para evitar 429 | Manter até migração; depois trocar por health interno |

## Crons pausadas

| Cron | Motivo |
|---|---|
| `manaloom-hermes-normal-audit` | Duplicava o report-only pós-push do Codex e gastava provider; agora Codex chama Hermes quando há push real. |
| `manaloom-hermes-weekly-parallel-audit` | Auditoria ampla gerava conflito/ruído e falhou em runs anteriores por git/provider. |
| `manaloom-manager-watchdog` | Watchdog legado; substituído por governador report-only. |
| `manaloom-tag-accuracy-reporter` | Achado é valioso, mas a versão agent bateu limite mensal; deve virar script/server job antes de reativar. |
| `manaloom-code-structure-auditor` | Auditoria ampla já causou conflito de docs; deve rodar manualmente com triagem Codex. |
| `manaloom-logic-coherence-auditor` | Já estava pausada; manter manual até existir harness determinístico. |
| `lorehold-knowncards-generator` | Gerador foi substituído pelo fluxo atual de validator/import; manter pausado. |
| `lorehold-universal-optimizer` | Antigo, com risco de apply/erro; substituído por preflight/slot-scan/manual. |
| `manaloom-master-optimizer-slot-scan` | Pesado; manter manual até isolamento no servidor. |
| `manaloom-master-optimizer-end-to-end` | Prova completa pesada; manual até ter janela controlada. |
| `manaloom-master-optimizer-loop` | One-shot vencido; manter desligado. |
| `manaloom-flutter-ui-auditor` | One-shot vencido; validação visual deve ser feita por Codex/simulator, não por Linux Hermes. |

## Mudanças aplicadas no runtime

Arquivo ajustado:

- `/opt/data/cron/jobs.json`

Backup criado:

- `/opt/data/cron/jobs.json.bak_codex_cron_value_audit_20260611_124613`

Mudanças:

- Habilitadas passaram de 17 para 13.
- Pausadas passaram de 8 para 12.
- Crons agent/provider de baixo valor ou duplicadas foram pausadas.
- `manaloom-cron-governor-report` deve rodar via script determinístico
  `hermes_cron_governor_report.sh`, não mais via provider.
- `manaloom-master-watchdog` deve apontar para report-only pós-push, não para
  `manaloom-hermes-normal-audit`, que permanece pausada.
- Cadência das crons agent úteis foi reduzida:
  - commander knowledge: 180m → 360m
  - gamechanger research: 180m → 720m
  - mana base validator: 360m → 720m e convertido para script-only
  - knowledge synthesis: 240m → 360m
  - MTG rules auditor: 180m → 720m

## Impacto prático no projeto

### Impacto imediato

- Menos risco de Hermes gerar documentação conflitante.
- Menos consumo de provider e menor chance de `429`.
- Mais foco nas rotinas que realmente alimentam app/IA:
  - eventos de aprendizado;
  - learned decks;
  - known cards;
  - preflight do optimizer;
  - validações de mana/regras em baixa cadência.

### Impacto já observado após as melhorias

- `manaloom-master-watchdog` voltou a detectar avanço real em `origin/master`.
- `manaloom-master-optimizer-preflight` passou com `status: approved`,
  `deck_cards=100`, `learned_decks=120` e duplicatas colapsadas.
- `manaloom-pull-learning-events` importou eventos reais e passou a classificar
  quais registros podem treinar deck completo.
- `manaloom-auto-sync-learned-decks` agora tem guardrail para não insistir em
  promoted rows incompletos; isso reduz ruído e evita tentativas repetidas
  contra o importador Commander.
- `manaloom-cron-governor-report` deixa de consumir provider para detectar
  saúde da frota. A próxima execução deve produzir tabela local com riscos
  `P0/P1/P2/P3` a partir de `jobs.json`, scripts e outputs recentes.

Validação remota pós-conversão do governor (`2026-06-11T14:08Z`):

- `server/bin/hermes_cron_governor_report.py` rodou no container Hermes como
  `/opt/data/scripts/hermes_cron_governor_report.sh`, sem provider.
- Resultado: `jobs_total=25`, `enabled=13`, `paused=12`,
  `enabled_provider_dependent=5`, `flagged=12`.
- Todas as crons essenciais script-only ficaram `OK`: `master-watchdog`,
  `knowledge-import`, `auto-sync-learned-decks`, `pull-learning-events`,
  `auto-promote-learned`, `knowncards-validator` e
  `master-optimizer-preflight`.
- Após a conversão do governor, as crons ainda dependentes de provider ficaram
  corretamente classificadas como `P2 replace_with_deterministic_report`:
  `commander-knowledge-deep`, `gamechanger-research`, `mana-base-validator`,
  `knowledge-synthesis` e `mtg-rules-auditor`. Depois da conversão do
  `mana-base-validator`, a lista caiu para 4 dependências de provider.
- Isso confirma o próximo bloco de migração: converter esses P2 em scripts,
  scorecards ou jobs internos antes de aposentar Hermes.

Validação remota pós-conversão do mana-base validator (`2026-06-11T14:20Z`):

- `manaloom-mana-base-validator` passou a rodar via
  `/opt/data/scripts/hermes_mana_base_validator.sh`, sem provider.
- O governor passou a reportar `enabled_provider_dependent=4`.
- Dependentes de provider restantes: `manaloom-commander-knowledge-deep`,
  `manaloom-gamechanger-research`, `manaloom-knowledge-synthesis` e
  `mtg-rules-auditor`.
- Achado real: o deck aprendido `Runtime Lorehold Learned 19e93de3cca` está
  `OVERFULL`, com `104` cartas agregadas contra o limite Commander `100`.
  O SQLite Hermes contém quatro nomes com quantidade `2`: `Birgi, God of
  Storytelling // Harnfel, Horn of Bounty`, `Mountain // Mountain`,
  `Plains // Plains` e `Valakut Awakening // Valakut Stoneforge`.
- Impacto: o loop de aprendizado está funcionando, mas precisa bloquear ou
  normalizar learned decks Commander acima de 100 antes de usar o resultado
  como deck completo no app/servidor.

Correção de causa raiz inicial (`2026-06-11T14:35Z`):

- O deck PG alvo declarava `100` cartas, mas
  `sync_pg_target_deck_to_hermes.py` usava `LEFT JOIN card_battle_rules` direto.
  Cartas com múltiplas regras em `card_battle_rules` multiplicavam linhas antes
  da gravação no SQLite, inflando o target Hermes para `104`.
- O primeiro containment usou `LEFT JOIN LATERAL (... LIMIT 1)` para manter uma
  linha de regra por carta e recusar payload em que `sum(quantity)` das linhas
  buscadas não batesse com `deck.total_qty` antes de escrever em `deck_cards`.
- O Slice 1 posterior substituiu esse containment por agregação por `card_id`,
  preservando múltiplas regras em `battle_rules_json` sem multiplicar linhas de
  deck.
- Teste adicionado/expandido:
  `docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_pg_target_deck_to_hermes.py`
  cobre rejeição de quantidade multiplicada por join, rejeição de `card_id`
  duplicado/missing e ausência de `LEFT JOIN LATERAL`/`LIMIT 1` na query
  semântica.
- Validação remota pós-fix em Hermes: `cards_seen=100`, `cards_written=100`,
  `quantity_seen=100`, `quantity_written=100`, `deck_cards.sum(quantity)=100`.
  O mana validator deixou de reportar `OVERFULL`; o status restante é
  `NO_PROFILE` para `Lorehold, the Historian`, com `3` cartas sem tag funcional
  conhecida.

### Impacto ainda não provado

Ainda falta observar uma rodada completa agendada, não apenas manual, depois da
correção de ownership, do fix de duplicatas no sync do target deck, da
classificação de eventos de aprendizado e do guardrail de auto-sync.

Próxima evidência necessária no Hermes remoto:

```bash
find /opt/data/cron/output -type f -name '*.md' \
  -printf '%TY-%Tm-%TdT%TH:%TM:%TS %p\n' | sort -r | head
```

Validar se a próxima rodada agendada produz sem erro:

- `manaloom-master-watchdog`
- `manaloom-pull-learning-events`
- `lorehold-knowncards-validator`
- `manaloom-master-optimizer-preflight`

Backlog técnico aberto:

- garantir que consumidores futuros consultem `training_eligible=1` para
  scores de aprendizado por comandante, mantendo `partial_telemetry` apenas como
  sinal operacional/diagnóstico.

## Caminho para remover Hermes

### Fase 1 — Manter Hermes como observador e laboratório

Status atual.

- Hermes coleta e testa aprendizado.
- Codex implementa produto em `master`.
- Branch docs é staging, não fonte canônica.

### Fase 2 — Migrar jobs determinísticos para o servidor ManaLoom

Prioridade:

1. `pull-learning-events`
2. `auto-sync-learned-decks`
3. `auto-promote-learned`
4. `knowledge-import`
5. `knowncards-validator`
6. `master-optimizer-preflight`

Formato recomendado:

- Dart/Python CLI versionado no repo principal ou job backend;
- tabela de auditoria para cada execução;
- lock por job;
- endpoint/health para último sucesso;
- logs sanitizados.

### Fase 3 — Converter crons agent em testes/dados determinísticos

Converter:

- `mana-base-validator` → métrica backend + teste por deck.
- `mtg-rules-auditor` → golden scenarios de regras.
- `tag-accuracy-reporter` → script de score por tag.
- `gamechanger-research` → atualização controlada de dados/ranking.
- `commander-knowledge-deep` → minerador de padrões por comandante.

### Fase 4 — Aposentar Hermes

Hermes pode ser desligado quando:

- todos os sync/import/promote rodam no servidor;
- scorecards e validators estão versionados;
- Codex não depende de docs branch para descobrir estado;
- app/backend têm endpoints/artefatos para learned decks e métricas;
- auditorias genéricas foram substituídas por CI/testes/provas vivas.

## Próxima ação recomendada

Não reativar crons pausadas agora.

Próximo passo técnico:

1. Esperar ou forçar uma rodada leve pós-ajuste.
2. Validar outputs de `watchdog`, `pull-learning-events` e
   `knowncards-validator`.
3. Tratar o deck aprendido `OVERFULL` antes de promover novos learned decks como
   fonte confiável de Commander completo.
4. Começar migração pelo trio:
   - `pull-learning-events`;
   - `auto-sync-learned-decks`;
   - `auto-promote-learned`.
