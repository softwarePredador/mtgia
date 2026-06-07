# Hermes E2E System Contract — Battle, Knowledge, Optimizer e Produto

Updated: 2026-06-07

## Objetivo deste documento

Este e o mapa operacional ponta a ponta do Hermes dentro do projeto ManaLoom.
Ele existe para responder, sem depender de memoria de conversa:

- o que cada etapa usa;
- de onde os dados vem;
- quais scripts rodam;
- quais bancos e tabelas sao lidos/escritos;
- quais parametros controlam o fluxo;
- quais retornos sao esperados;
- quais guardrails bloqueiam mutacao;
- quais furos aparecem quando o fluxo e documentado por inteiro.

Este documento nao substitui os relatorios historicos. Ele e o contrato de
execucao. Relatorios de rodada ficam em `docs/hermes-analysis/master_optimizer_reports/`.

## Principio de seguranca

Hermes e sandbox de aprendizado e simulacao. O SQLite do Hermes pode receber
swaps locais para validar hipotese, mas isso nao significa apply no produto.

Regras duras:

- Nao aplicar swap no produto a partir de `slot_benchmarks`.
- Nao aplicar swap no Hermes sem `full_confirmation` aprovada.
- Nao aplicar swap se o hash atual do deck divergir do hash do baseline.
- Nao aplicar swap se a carta de corte nao existe no deck atual.
- Nao aplicar swap se a carta de entrada ja existe no deck atual.
- Nao copiar swap Hermes para deck real/produto sem handoff de produto e aprovacao humana.
- Nao tratar `last_error` de cron como verdade isolada; confirmar com log/artefato fresco.

## Ambientes

### Repositorio local

- Workspace local: `C:\Users\rafae\OneDrive\Documents\mtgia`
- Branch de trabalho do fluxo Hermes: `codex/hermes-analysis-docs`
- Docs principais: `docs/hermes-analysis/`
- Scripts versionados: `docs/hermes-analysis/manaloom-knowledge/scripts/`

### Hermes remoto observado

- Host atual: `ubuntu@3.16.217.179`
- Container observado: `d5fe57bf9de2`
- Workspace no container: `/opt/data/workspace/mtgia`
- SQLite Hermes: `/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Artefatos runtime: `/opt/data/artifacts/hermes_master_optimizer/`
- Cron config no container: `/opt/data/cron/jobs.json`
- Scripts instalados no container: `/opt/data/scripts/`
- Segredos Postgres no container: `/opt/data/secrets/manaloom-postgres.env`

Nao versionar segredos. O arquivo de ambiente do Postgres deve ser carregado
pelos scripts shell no servidor, nunca copiado para docs.

## Fonte de verdade dos dados

### Postgres real

O Postgres real e a fonte de metadata de cartas que deve alimentar o Hermes.
O script `sync_pg_card_metadata_to_hermes.py` consulta a tabela publica `cards`.

Colunas usadas quando existem no Postgres:

- `name`
- `mana_cost`
- `type_line`
- `oracle_text`
- `colors`
- `color_identity`
- `cmc`
- `power`
- `toughness`
- `keywords`
- `scryfall_id`

O script consulta `information_schema.columns` antes de montar o SELECT.
Se uma coluna nao existir, usa fallback `NULL`, exceto `name`, que e obrigatoria.

Contrato esperado do SELECT:

```sql
SELECT
  c.name,
  c.mana_cost,
  c.type_line,
  c.oracle_text,
  c.colors,
  c.color_identity,
  c.cmc,
  c.power,
  c.toughness,
  c.keywords,
  c.scryfall_id::text
FROM cards c
WHERE lower(c.name) = ANY(...)
   OR lower(split_part(c.name, ' // ', 1)) = ANY(...)
ORDER BY c.name;
```

Observacao: se o Postgres nao tiver `power`, `toughness` ou `keywords`, o Hermes
continua funcionando, mas perde precisao em combate, habilidades e avaliacao de
criaturas. O cache local ja aceita esses campos.

### SQLite Hermes

O SQLite `knowledge.db` e a fonte operacional do battle/optimizer. Ele recebe:

- decks aprendidos;
- deck alvo atual;
- cache de metadata importada do Postgres;
- legalidades;
- Game Changers;
- resultados de baseline, scan, confirmation, handoff e apply local.

Snapshot vivo observado em 2026-06-07:

| Tabela | Linhas | Uso |
| --- | ---: | --- |
| `deck_cards` | 543 | Decks locais do Hermes, incluindo deck alvo `deck_id=6`. |
| `learned_decks` | 82 | Oponentes reais aprendidos para battle. |
| `card_oracle_cache` | 1260 | Cache de metadata importada do Postgres. |
| `card_legalities` | 31369 | Legalidade por formato. |
| `game_changers` | 53 | Politica de bracket/Game Changer. |
| `slot_benchmarks` | 30 | Resultados de scan isolado por slot. |
| `swap_benchmarks` | 5 | Confirmacoes e full confirmations. |
| `optimizer_baseline_runs` | 2 | Baselines congelados por deck/hash. |
| `optimizer_quality_reviews` | 50 | Reviews de quality gate. |
| `optimizer_handoffs` | 1 | Handoffs de candidatos aprovados. |
| `optimizer_applied_swaps` | 0 | Applies locais Hermes. |
| `optimizer_product_handoffs` | 0 | Handoffs para produto. |

Tabela local `cards`: ausente no SQLite vivo observado. Portanto battle e
optimizer nao devem depender dela no Hermes atual. Se algum script passar a
depender de `cards`, precisa criar fallback para `card_oracle_cache` ou falhar no
preflight.

## Contrato das tabelas principais

### `deck_cards`

Leituras principais:

- `battle_analyst_v8.py`
- `master_optimizer_common.py`
- `slot_optimizer.py`
- `sync_pg_card_metadata_to_hermes.py`

Escritas principais:

- importadores de decks;
- `temporary_swap()` durante teste isolado, com restauracao obrigatoria;
- `master_optimizer_apply.py` quando apply local Hermes e aprovado.

Colunas observadas:

- `id`
- `deck_id`
- `card_name`
- `quantity`
- `functional_tag`
- `tag_confidence`
- `is_commander`
- `is_partner`
- `cmc`
- `type_line`
- `oracle_text`

Contrato:

- `deck_id=6` e o Lorehold alvo atual.
- Commander deve ter `is_commander=1`.
- Total Commander precisa continuar 100 cartas considerando quantity.
- `card_name` e chave funcional para lookup, hash e swap.

### `learned_decks`

Leituras principais:

- `battle_analyst_v8.py` como pool de oponentes;
- `sync_pg_card_metadata_to_hermes.py` para coletar nomes a cachear;
- `kc_validator.py` para expandir/validar conhecimento.

Colunas observadas:

- `id`
- `source`
- `source_url`
- `commander`
- `deck_name`
- `archetype`
- `card_list`
- `card_count`
- `wincon_primary`
- `wincon_backup`
- `budget_level`
- `notes`
- `created_at`

Contrato:

- `card_list` deve ser JSON.
- Decks incompletos devem ser excluidos do battle/optimizer.
- Promocao ideal deve rejeitar decks com menos de 90 cartas por codigo.

### `card_oracle_cache`

Criada/atualizada por `sync_pg_card_metadata_to_hermes.py`.

Colunas:

- `normalized_name`
- `name`
- `mana_cost`
- `colors_json`
- `color_identity_json`
- `type_line`
- `oracle_text`
- `cmc`
- `power`
- `toughness`
- `keywords_json`
- `scryfall_id`
- `source`
- `updated_at`

Contrato:

- `normalized_name` e chave primaria.
- Deve incluir alias da face frontal para cartas dupla-face.
- `battle_analyst_v8.py` usa este cache para mana colorida, poder/resistencia e keywords.
- `slot_optimizer.py` usa este cache para identidade de cor e legalidade indireta.

### `card_legalities`

Colunas observadas:

- `card_name`
- `format`
- `status`
- `scryfall_id`
- `synced_at`

Contrato:

- Quality gate deve exigir `format='commander'` e `status='legal'`.
- Qualquer fallback por ausencia de legalidade deve ser bloqueador, nao aprovacao silenciosa.

### `game_changers`

Colunas observadas:

- `card_name`
- `impact_level`
- `impact_category`
- `manaloom_bracket_category`
- `restricted_bracket`
- demais metadata de carta.

Contrato:

- Usada como politica externa de bracket/Game Changer.
- Warnings de Game Changer nao sao necessariamente bloqueio, mas precisam aparecer em handoff.

### `optimizer_baseline_runs`

Criada por `ensure_optimizer_tables()`.

Escrita por:

- `master_optimizer_baseline.py`

Lida por:

- `slot_optimizer.py`
- `master_optimizer_quality_gate.py`
- `master_optimizer_confirmation.py`
- `replay_decision_auditor.py`
- `master_optimizer_handoff.py`
- `master_optimizer_apply.py`

Colunas:

- `id`
- `deck_id`
- `deck_hash`
- `battle_version`
- `games_per_opponent`
- `opponents`
- `total_games`
- `wr`
- `wins`
- `losses`
- `stalls`
- `status`
- `result_json`
- `created_at`

Contrato:

- Somente baseline `status='approved'` pode ser usado.
- Baseline e imutavel para uma rodada.
- O hash atual do deck precisa bater com `deck_hash`.
- `result_json` deve preservar matchup payload e stdout tail.

Baseline vivo observado para `deck_id=6`:

- `id=2`
- `deck_hash=110ce10b8152085ec589ed09b15ab1e0c21a5656b60b366f59a34e369b2ff811`
- `wr=86.7`
- `260W/11L/29S`
- `total_games=300`
- `created_at=2026-06-07T15:45:25.698034+00:00`

### `slot_benchmarks`

Criada por `ensure_optimizer_tables()`.

Escrita por:

- `slot_optimizer.py`

Lida por:

- `master_optimizer_quality_gate.py`
- `master_optimizer_confirmation.py`
- `master_optimizer_handoff.py`
- `sync_pg_card_metadata_to_hermes.py`

Colunas:

- `id`
- `deck_id`
- `baseline_id`
- `baseline_hash`
- `category`
- `card_added`
- `card_removed`
- `add_cmc`
- `add_effect`
- `add_tag`
- `wr`
- `wins`
- `losses`
- `draws`
- `games`
- `delta_pp`
- `phase`
- `tested_at`

Contrato:

- Cada linha deve estar vinculada ao `deck_id`, `baseline_id` e `baseline_hash`.
- Resultados so valem para o deck/hash exato do baseline.
- Scan deve ser temporario; apos cada teste, o deck deve ser restaurado.
- Fases atuais aceitas: `phase1`, `best-in-slot` e fases equivalentes consumidas por `candidate_rows()`.

### `swap_benchmarks`

Criada por `ensure_optimizer_tables()`.

Escrita por:

- `master_optimizer_confirmation.py`

Atualizada por:

- `master_optimizer_apply.py`, que marca `applied=1` apos apply local Hermes.

Colunas:

- `id`
- `deck_id`
- `baseline_id`
- `baseline_hash`
- `card_added`
- `card_removed`
- `add_cmc`
- `add_effect`
- `add_tag`
- `wr`
- `wins`
- `losses`
- `draws`
- `games`
- `phase`
- `delta_pp`
- `applied`
- `tested_at`

Contrato:

- `confirmation` e triagem reforcada.
- `full_confirmation` e a unica fase elegivel para apply.
- `delta_pp` minimo atual para apply: `+0.5pp`.
- Uma linha negativa ou flat deve bloquear apply, mesmo que uma rodada anterior tenha sido positiva.

### `optimizer_quality_reviews`

Escrita por `quality_gate_candidate()`.

Colunas:

- `deck_id`
- `card_added`
- `card_removed`
- `source_phase`
- `status`
- `reasons_json`
- `warnings_json`
- `created_at`

Contrato:

- `status='passed'` e necessario para confirmation.
- `reasons_json` deve explicar bloqueios.
- `warnings_json` deve chegar ao handoff.

### `optimizer_handoffs`

Escrita por `master_optimizer_handoff.py`.

Contrato:

- Status `approved_swaps_ready_for_manual_apply` significa pronto para decisao humana.
- Nao significa apply automatico.
- Se dois candidatos cortam a mesma carta, aplicar no maximo um e recomeçar baseline.

### `optimizer_applied_swaps`

Escrita por `master_optimizer_apply.py`.

Contrato:

- Registra apply local Hermes.
- Precisa ter `before_hash`, `after_hash` e `rollback_path`.
- `rollback_path` pode conter decklist completa e nao deve ser versionado sem revisao.

### `optimizer_product_handoffs`

Escrita por `master_optimizer_product_handoff.py`.

Contrato:

- Status esperado inicial: `needs_product_owner_approval`.
- Nunca muta produto.
- Serve para transportar uma decisao Hermes validada para o fluxo app/producao com checklist.

## Scripts e responsabilidades

### `sync_pg_card_metadata_to_hermes.py`

Funcao:

- coleta nomes relevantes do SQLite;
- consulta metadata no Postgres real;
- escreve/atualiza `card_oracle_cache`.

Entradas:

- SQLite Hermes via `--sqlite-db`;
- Postgres via `DATABASE_URL` ou variaveis `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`;
- nomes vindos de `deck_cards`, `learned_decks`, `slot_benchmarks`, `swap_benchmarks`, `known_cards_generated.json`.

Parametros:

- `--sqlite-db`: caminho do `knowledge.db`;
- `--dry-run`: mede sem escrever;
- `--limit`: smoke pequeno;
- `--report`: JSON sanitizado.

Saida esperada:

- tabela `card_oracle_cache` criada/atualizada;
- report JSON com cobertura;
- nenhuma credencial impressa.

### `master_optimizer_loop.py --preflight --report`

Funcao:

- validar se o ambiente Hermes esta pronto para battle/optimizer.

Contrato esperado:

- `knowledge.db` existe;
- tabelas essenciais existem;
- `battle_analyst_v8.py` compila;
- testes de battle passam;
- `card_oracle_cache` existe e tem cobertura minima;
- scripts do optimizer existem.

Saida esperada:

- Markdown `master_optimizer_preflight_*.md`;
- status de shell `0` em ambiente aprovado.

### `master_optimizer_baseline.py`

Funcao:

- congelar baseline do deck atual.

Parametros:

- `--deck-id`, default `6`;
- `--games`, default `50` por oponente;
- `--report`.

Escreve:

- `optimizer_baseline_runs`.

Saida esperada:

- baseline id;
- winrate;
- record;
- deck hash;
- Markdown `master_optimizer_baseline_*.md`.

### `slot_optimizer.py`

Funcao:

- testar candidatos por categoria, um swap por vez, sem mutacao permanente.

Parametros:

- `--deck-id`, default `MANALOOM_OPTIMIZER_DECK_ID` ou `6`;
- `--games`, default `MANALOOM_SLOT_GAMES` ou `10`;
- `--max-per-category`, default `MANALOOM_SLOT_MAX_PER_CATEGORY` ou `15`;
- `--category`;
- `--phase`, default `phase1`;
- `--reset-current-baseline`.

Le:

- `known_cards_generated.json`;
- `deck_cards`;
- `card_oracle_cache`;
- `card_legalities`;
- `game_changers`;
- ultimo baseline aprovado.

Escreve:

- `slot_benchmarks`.

Guardrails:

- exige baseline aprovado;
- exige hash atual igual ao baseline;
- filtra identidade de cor Commander;
- exige legalidade Commander;
- usa `temporary_swap()` e restaura deck.

Saida esperada:

- linhas em `slot_benchmarks`;
- resumo `slot_scan=ok`;
- nenhum card permanente alterado em `deck_cards`.

### `master_optimizer_quality_gate.py`

Funcao:

- revisar candidatos antes de confirmacao.

Parametros:

- `--deck-id`, default `6`;
- `--limit`, default `25`;
- `--report`.

Le:

- ultimo baseline aprovado;
- `slot_benchmarks`;
- `card_oracle_cache`;
- `card_legalities`;
- `game_changers`;
- deck atual.

Escreve:

- `optimizer_quality_reviews`.

Saida esperada:

- Markdown com `passed`/`blocked`;
- razoes e warnings por candidato.

### `master_optimizer_confirmation.py`

Funcao:

- retestar candidatos promissores com amostra maior.

Parametros:

- `--deck-id`, default `6`;
- `--candidate-limit`, default `25`;
- `--run-limit`, default `3`;
- `--games`, default `10`;
- `--min-scan-delta`, default `-2.0`;
- `--phase confirmation|full_confirmation`;
- `--include-existing`;
- `--only-added`;
- `--report`.

Le:

- ultimo baseline aprovado;
- `slot_benchmarks`;
- `optimizer_quality_reviews`;
- deck atual.

Escreve:

- `swap_benchmarks`.

Saida esperada:

- candidatos testados;
- candidatos bloqueados;
- candidatos skipped;
- `delta_pp` contra baseline atual.

### `replay_decision_auditor.py`

Funcao:

- validar qualidade turno-a-turno da logica do battle.

Parametros:

- `--deck-id`, default `6`;
- `--events`, opcional;
- `--generate`, default `3`;
- `--seed-start`, default `42`;
- `--report`.

Le:

- ultimo baseline aprovado;
- eventos gerados por `battle_replay_v10_3.py` quando `--events` nao e informado.

Saida esperada:

- status `turn_by_turn_clean` quando sem findings;
- Markdown `master_optimizer_replay_audit_*.md`;
- findings estruturados quando detectar erro de combate, removal, tutor, cleanup, Approach ou encerramento.

### `master_optimizer_handoff.py`

Funcao:

- produzir pacote de decisao humana/agente apos confirmation.

Parametros:

- `--deck-id`, default `6`;
- `--report`.

Le:

- ultimo baseline aprovado;
- `swap_benchmarks`;
- `optimizer_quality_reviews`.

Escreve:

- `optimizer_handoffs`.

Saida esperada:

- status `approved_swaps_ready_for_manual_apply` quando houver `full_confirmation` com `delta_pp >= +0.5`;
- recomendacao de ampliar scan/retestar quando nao houver candidato forte.

### `master_optimizer_apply.py`

Funcao:

- aplicar um swap aprovado apenas no SQLite Hermes.

Parametros:

- `--deck-id`, default `6`;
- `--card-added`, opcional;
- `--min-delta`, default `0.5`;
- `--report`.

Le:

- ultimo baseline aprovado;
- `swap_benchmarks` com `phase='full_confirmation'`, `applied=0`, `delta_pp >= min_delta`.

Escreve:

- `deck_cards`;
- `swap_benchmarks.applied=1`;
- `optimizer_applied_swaps`;
- rollback JSON em `master_optimizer_reports`.

Guardrails:

- bloqueia sem baseline;
- bloqueia hash divergente;
- bloqueia sem candidato aprovado;
- gera rollback antes da mutacao;
- revalida resumo do deck depois.

### `master_optimizer_product_handoff.py`

Funcao:

- criar handoff separado para copiar uma decisao Hermes ao produto depois de aprovacao.

Parametros:

- `--deck-id`, default `6`;
- `--applied-swap-id`, opcional;
- `--report`.

Saida esperada:

- status `needs_product_owner_approval`;
- checklist de backup, dry-run, legalidade e smoke app/API;
- zero mutacao em produto.

## Ordem ponta a ponta recomendada

### Fase 0 — sync e preflight

```bash
cd /opt/data/workspace/mtgia
set -a
. /opt/data/secrets/manaloom-postgres.env
set +a
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_card_metadata_to_hermes.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --report /opt/data/artifacts/hermes_master_optimizer/card_oracle_cache_sync_manual.json
python3 docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_loop.py --preflight --report
```

Bloquear se:

- sync falhar;
- `card_oracle_cache` ficar vazio/baixo;
- battle tests falharem;
- SQLite nao tiver tabelas essenciais.

### Fase 1 — baseline

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_baseline.py \
  --deck-id 6 \
  --games 25 \
  --report
```

Para decisao forte, preferir `--games 50` ou maior. O baseline deve virar a
referencia unica para todas as fases seguintes.

### Fase 2 — slot scan

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py \
  --deck-id 6 \
  --games 10 \
  --max-per-category 15 \
  --phase phase1
```

Para focar uma categoria:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py \
  --deck-id 6 \
  --games 10 \
  --max-per-category 15 \
  --category engine \
  --phase phase1
```

### Fase 3 — quality gate

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_quality_gate.py \
  --deck-id 6 \
  --limit 25 \
  --report
```

### Fase 4 — confirmation curta

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_confirmation.py \
  --deck-id 6 \
  --candidate-limit 25 \
  --run-limit 3 \
  --games 25 \
  --min-scan-delta 0.5 \
  --phase confirmation \
  --report
```

### Fase 5 — full confirmation

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_confirmation.py \
  --deck-id 6 \
  --candidate-limit 25 \
  --run-limit 3 \
  --games 50 \
  --min-scan-delta 0.5 \
  --phase full_confirmation \
  --report
```

Para revalidar apenas uma carta:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_confirmation.py \
  --deck-id 6 \
  --candidate-limit 25 \
  --run-limit 1 \
  --games 50 \
  --min-scan-delta 0.5 \
  --phase full_confirmation \
  --only-added "Nome da Carta" \
  --include-existing \
  --report
```

### Fase 6 — replay audit

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py \
  --deck-id 6 \
  --generate 3 \
  --report
```

### Fase 7 — handoff

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_handoff.py \
  --deck-id 6 \
  --report
```

### Fase 8 — apply local Hermes, se aprovado

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_apply.py \
  --deck-id 6 \
  --card-added "Nome da Carta" \
  --min-delta 0.5 \
  --report
```

### Fase 9 — baseline pos-apply

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_baseline.py \
  --deck-id 6 \
  --games 50 \
  --report
```

### Fase 10 — handoff produto

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_product_handoff.py \
  --deck-id 6 \
  --report
```

## Crons atuais e papel correto

Snapshot vivo observado em 2026-06-07:

| Job | Schedule | Enabled | Papel |
| --- | --- | --- | --- |
| `manaloom-master-watchdog` | every 30m | true | Supervisao geral. |
| `manaloom-knowledge-import` | every 120m | true | Import de conhecimento. |
| `manaloom-pull-learning-events` | every 30m | true | Puxa eventos/decks aprendidos. |
| `lorehold-knowncards-validator` | every 30m | true | Valida/expande known cards. |
| `manaloom-master-optimizer-preflight` | every 20m | true | Mantem Hermes pronto, sem apply. |
| `manaloom-master-optimizer-slot-scan` | every 720m | false | Scan pesado, deve ficar pausado ate baseline aprovado. |
| `manaloom-master-optimizer-end-to-end` | every 1440m | false | Pipeline manual/supervisionado. |
| `lorehold-universal-optimizer` | every 10m | false | Deve ficar pausado; risco de auto-apply legado. |

Nota operacional: o snapshot mostrou `last_error` stale em alguns jobs. A forma
correta de validar job e olhar:

- `enabled`;
- log fresco em `/opt/data/artifacts/hermes_master_optimizer/`;
- report fresco em `docs/hermes-analysis/master_optimizer_reports/`;
- timestamp de execucao;
- saida final `*_ok`.

## Fluxo shell pronto

`master_optimizer_preflight_cron.sh`:

- faz `git fetch/checkout/pull --ff-only`;
- carrega `/opt/data/secrets/manaloom-postgres.env`;
- roda sync PG -> SQLite;
- roda preflight;
- copia ultimo report para artefato latest.

`master_optimizer_slot_scan_cron.sh`:

- tem lock de 12h;
- carrega Postgres env;
- roda sync;
- roda preflight;
- roda `slot_optimizer.py`;
- copia log para `latest_master_optimizer_slot_scan.log`;
- deve ficar desabilitado ate baseline controlado.

`master_optimizer_end_to_end.sh`:

- tem lock de 12h;
- carrega Postgres env;
- roda sync;
- roda preflight;
- roda baseline;
- roda slot scan fresco para o baseline atual;
- roda quality gate;
- roda confirmation;
- roda replay audit;
- roda handoff.

Furo identificado durante esta documentacao e corrigido no script versionado:
`master_optimizer_end_to_end.sh` nao rodava `slot_optimizer.py` entre baseline e
quality gate. Agora ele executa slot scan com `--reset-current-baseline`, usando
`MANALOOM_SLOT_GAMES`, `MANALOOM_SLOT_MAX_PER_CATEGORY`, `MANALOOM_SLOT_PHASE` e
`MANALOOM_SLOT_CATEGORY` quando definidos.

## Estado atual do Lorehold

Deck alvo:

- `deck_id=6`
- hash atual observado: `110ce10b8152085ec589ed09b15ab1e0c21a5656b60b366f59a34e369b2ff811`

Ultima revalidacao documentada:

- `Fork`: nao aplicado; delta fresco `+0.0pp`.
- `Reversal of Fortune`: nao aplicado; delta fresco `-1.4pp`.
- `Invoke Calamity`: marginal `+0.6pp`.
- `Restoration Seminar`: marginal `+0.6pp`.

Interpretacao:

- Nao ha swap forte o bastante para apply automatico agora.
- O proximo passo correto e ampliar amostra para os marginais ou ampliar scan.
- Forcar apply seria ir contra a evidencia atual.

## Furos e riscos encontrados ao documentar

### P0 — E2E shell nao incluia slot scan

Problema:

- `master_optimizer_end_to_end.sh` roda baseline -> quality gate -> confirmation,
  mas nao rodava `slot_optimizer.py`.
- Isso faz o E2E depender de linhas antigas em `slot_benchmarks`.

Impacto:

- Risco de confirmation usar candidatos incompletos ou nao encontrar candidatos.
- Guardrail de hash reduz risco de stale target, mas nao garante que houve scan
  suficiente para o baseline atual.

Correcao recomendada:

- Corrigido no script versionado: `slot_optimizer.py` roda depois do baseline
  com `--reset-current-baseline`.
- Evolucao futura: tambem bloquear explicitamente se o scan terminar sem linhas
  em `slot_benchmarks` para o baseline atual.

### P0 — Baselines podem sumir se o SQLite for recriado

Problema observado:

- Em rodada anterior, tabelas `optimizer_*`, `slot_benchmarks` e `swap_benchmarks`
  estavam ausentes/recriadas.

Impacto:

- Apply bloqueia corretamente sem baseline, mas a equipe pode achar que havia
  evidencia valida por docs antigos.

Correcao recomendada:

- Sempre anexar `baseline_id`, `baseline_hash`, timestamp e caminho do SQLite
  aos reports.
- Antes de apply, consultar o SQLite vivo, nao apenas doc historico.

### P1 — `cards` ausente no SQLite Hermes

Problema:

- Snapshot vivo nao tem tabela local `cards`.
- Alguns validadores antigos fazem fallback ou tentam ler `cards`.

Impacto:

- Scripts novos devem usar `card_oracle_cache`; scripts antigos podem falhar ou
  usar menos dados.

Correcao recomendada:

- Preflight deve declarar explicitamente que `cards` local e opcional.
- Qualquer script que precise metadata deve usar `card_oracle_cache`.

### P1 — Cron `last_error` pode estar stale

Problema:

- Jobs ativos podem manter `last_error` antigo mesmo apos correcao ou mudanca de provider.

Impacto:

- Diagnostico visual de cron pode parecer pior do que o estado real.

Correcao recomendada:

- Padronizar `last_status`, `last_run_at` e artefato `latest_*.status`.
- Docs e agentes devem citar logs frescos, nao apenas `last_error`.

### P1 — Produto ainda nao tem ponte automatizada segura

Problema:

- Hermes valida no SQLite local.
- Produto real precisa de backup/dry-run/legalidade/smoke antes de receber swap.

Impacto:

- Sem handoff produto, um swap bom no Hermes pode ser copiado errado.

Correcao recomendada:

- So permitir copia para produto via `master_optimizer_product_handoff.py`.
- Criar script futuro de dry-run no produto que nao escreva antes de aprovacao.

### P2 — Amostra estatistica ainda pode oscilar

Problema:

- Reversal passou forte em uma rodada e falhou na revalidacao seguinte.

Impacto:

- Alguns ganhos podem ser ruido de simulacao/seed/matchup.

Correcao recomendada:

- Para apply real, exigir duas full confirmations independentes ou amostra maior.
- Registrar seed/run config no `result_json`.

## Checklist de uma rodada valida

Antes de aceitar qualquer recomendacao:

- [ ] Sync PG -> SQLite rodou com report fresco.
- [ ] Preflight passou com report fresco.
- [ ] Baseline novo existe no SQLite vivo.
- [ ] Hash atual do deck bate com baseline.
- [ ] Slot scan rodou para o mesmo `baseline_id`/`baseline_hash`.
- [ ] Quality gate revisou candidatos do baseline atual.
- [ ] Confirmation curta passou.
- [ ] Full confirmation passou com delta minimo.
- [ ] Replay audit nao encontrou erro turno-a-turno.
- [ ] Handoff foi gerado.
- [ ] Apply local Hermes, se feito, gerou rollback.
- [ ] Baseline pos-apply foi rodado.
- [ ] Handoff produto foi gerado antes de qualquer copia para app/prod.

## Comando seguro para pedir ao Hermes

Use este pedido quando quiser o fluxo completo, sem auto-apply:

```text
Rode o fluxo Hermes E2E para o deck Lorehold deck_id=6 seguindo docs/hermes-analysis/HERMES_E2E_SYSTEM_CONTRACT_2026-06-07.md. Nao aplique swap automaticamente. Execute sync PG->SQLite, preflight, baseline fresco, slot scan para o baseline atual, quality gate, confirmation, full_confirmation, replay audit e handoff. Em cada fase, valide baseline_id e baseline_hash contra o SQLite vivo. Se qualquer etapa falhar, pare e documente o bloqueio. Ao final, entregue caminhos dos reports, status, candidatos aprovados, deltas, record e recomendacao de apply ou no-apply.
```

Use este pedido quando quiser validar um candidato especifico:

```text
Revalide o candidato <CARD_IN> sobre <CARD_OUT> no Hermes para Lorehold deck_id=6 seguindo docs/hermes-analysis/HERMES_E2E_SYSTEM_CONTRACT_2026-06-07.md. Recrie baseline fresco se o hash divergir. Rode full_confirmation com amostra suficiente, replay audit e handoff. Nao aplique se delta_pp < +0.5pp ou se a evidencia nao reproduzir. Documente deck_hash, baseline_id, record, delta e estado final do deck.
```

## Conclusao

Nao havia um documento unico com esse nivel de contrato. A documentacao anterior
registrava evolucao e evidencias, mas nao amarrava completamente scripts,
tabelas, parametros, retornos e bloqueios.

Ao documentar o fluxo inteiro, o principal furo encontrado foi o script E2E nao
executar slot scan antes de quality gate/confirmation; isso foi corrigido no
script versionado. O segundo ponto critico e que a evidencia antiga nao pode ser
usada se o SQLite vivo perdeu/recriou tabelas de baseline. Esse risco continua
mitigado pelos hash guardrails, mas toda rodada deve consultar o SQLite vivo
antes de qualquer apply.
