# Hermes Analysis: Project Memory

> Status atual: memoria historica do agente.
> Quando houver conflito, `README.md` e
> `HERMES_E2E_SYSTEM_CONTRACT_2026-06-07.md` prevalecem.

> Memoria operacional do agente residente para o projeto ManaLoom.
> Versionada neste diretorio — atualizar sempre que houver mudanca estrutural.

## Identidade

- Nome: **ManaLoom** (tambem referido como mtgia)
- Repositorio: `softwarePredador/mtgia` (GitHub)
- Produto: Plataforma Commander-first para Magic: The Gathering
- Stack: Flutter (`app/`) + Dart Frog (`server/`) + PostgreSQL
- Backend publicado: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Master HEAD observado no apply Hermes: 55af86c4 (2026-06-11, Deduplicate Hermes battle rules by logical key)
- Relatorio mestre atual: `docs/PROJECT_LOGIC_FULL_REPORT_2026-06-11.md`
- Backend tests: 599 (2026-06-04 14:10Z), `dart analyze lib/` — No issues found, `flutter analyze --no-pub --no-fatal-infos` — No issues found

## Branch de analise

A memoria versionada do agente vive em `codex/hermes-analysis-docs`.
Nunca commitar diretamente na `master`. Fluxo:

1. `git fetch --all --prune`
2. Rodar `/opt/data/scripts/manaloom-docs-branch-sync.sh` ou
   `server/bin/hermes_docs_branch_sync.sh` no workspace Hermes.
3. Prosseguir somente se a sync retornar `up_to_date` ou `merged`.
4. Se a sync bloquear por conflito, worktree sujo ou push falho, retornar
   `BLOCKED` e nao publicar achado novo.
5. Editar `docs/hermes-analysis/*`
6. Stage apenas arquivos intencionais em `docs/hermes-analysis/**` (evitar artefatos de crons como `knowledge.db`, decks gerados e `__pycache__`) e commitar com `Update Hermes project analysis docs`
7. `git push origin codex/hermes-analysis-docs`

Motivo: a branch docs e memoria/staging, mas as auditorias de codigo precisam
ver a `master` viva. A sync mergeia `origin/master` em
`codex/hermes-analysis-docs` antes de qualquer auditoria estrutural.

## Fontes canonicas (ordem de precedencia)

1. `docs/CONTEXTO_PRODUTO_ATUAL.md` - fonte de verdade operacional
2. `docs/PROJECT_LOGIC_FULL_REPORT_2026-06-11.md` - mapa mestre de logica, dados, IA, Hermes e validacao
3. `server/manual-de-instrucao.md` - diario tecnico com ultimas decisoes
4. `docs/README.md` - indice documental
5. `server/doc/API_CONTRACTS_AND_DATA_MAP.md` - contratos app/backend
6. `app/doc/APP_AUDIT_2026-04-29.md` - status consolidado do app
7. `app/doc/UI_TEST_SURFACE_MAP.md` - keys de teste para runtime
8. `docs/hermes-analysis/*` - analise do agente (este diretorio)
9. `git log --oneline --decorate -40` - estado atual dos commits

## Regra de escopo

- `CONTEXTO_PRODUTO_ATUAL.md` prevalece sobre roadmaps antigos e handoffs congelados antes de 2026-03-23.
- Nenhuma melhoria visual ou operacional fora do core de decks deve furar a fila da Sprint 1/2.
- Toda tela do fluxo core precisa preservar: `formato`, `deckId`, feedback de erro e estado de carregamento.
- Toda melhoria de UX precisa de validacao tecnica repetivel.

## ManaLoom PG097 Valakut sync/audit/gate refresh - 2026-06-23 11:48 UTC

- PostgreSQL remained the source of truth; Hermes SQLite/canonical cache was
  refreshed with
  `docs/hermes-analysis/master_optimizer_reports/pg097_valakut_simple_hash_restore_sync_report_20260623_114030.json`.
  The sync reported `include_needs_review=false`, `pg_rows_loaded=1830`,
  `sqlite_inserted_or_updated=1808`, and
  `canonical_snapshot_rows_exported=3201`.
- PG097 restored simple-name `Valakut Awakening` provenance in PostgreSQL:
  precheck found 1 row needing hash/status restore, apply reported
  `updated_rows=1` and `COMMIT`, and postcheck confirmed 1 restored
  hash/status row. Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg097_valakut_simple_hash_restore_rollback_20260623_113918.sql`.
- Fresh deck-card audits after PG097 sync: deck `6` `pass=100`, deck `606`
  `pass=81`, deck `607` `high=15`, `medium=4`, `pass=75`, and global
  `high=29`, `medium=4`, `pass=172`.
- A fresh manual recurring 16-seed gate ran at
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_114452`.
  It completed 16/16 seeds, recorded 13,305 events and 2,219 decisions, and
  passed all 18 wrapper tests.
- The recurring battle baseline remains `review_required`, with
  `mandatory_gate_divergences=["event_contract_static=review_required"]`.
  This is an event-contract/static-fixture residual, not a new deck `6` or
  deck `606` card-rule failure.
- No deck swap, no `deck_cards` mutation, no learned-deck promotion, and no
  commit/push occurred in this checkpoint. PG098 is the next PostgreSQL package
  number.
- Operator card observations remain audit hints only; durable behavior still
  requires Oracle/ruling-backed PostgreSQL rows and runtime/replay evidence
  when battle-relevant.

## Estado do agente neste servidor

Hermes consegue ler, auditar e analisar o repositorio. No recorte atual de
EasyPanel, o `hermes-lab` foi reduzido para **Dart 3.12.0 standalone** em
`/opt/tools/dart-sdk/bin/`; `flutter` deixou de ser dependência do container e
fica restrito ao ambiente local do Codex para validação mobile/UI.

- `dart test`: 599 passed (backend, 2026-05-27)
- `flutter analyze --no-pub --no-fatal-infos`: No issues found (2026-05-27,
  evidência histórica do ambiente anterior)

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
- `docs/PROJECT_LOGIC_FULL_REPORT_2026-06-11.md` (mapa mestre de arquitetura/logica)
- `docs/hermes-analysis/BATTLE_AI_DECK_LOGIC_DEEP_DIVE_2026-06-11.md` (mapa detalhado de battle, IA, Hermes e Lorehold)
- `docs/hermes-analysis/BATTLE_SEMANTIC_SYNC_IMPLEMENTATION_PLAN_2026-06-11.md` (plano de implementação para agregação multi-função e sync Hermes)
- `docs/hermes-analysis/BATTLE_AI_GAP_CYCLE_2026-06-12.md` (ciclo seguro que remove fallback fixo de `/decks/:id/recommendations` e registra triagem Hermes)
- `docs/hermes-analysis/BATTLE_SEMANTIC_SYNC_SLICE1_REPORT_2026-06-11.md` (evidência do Slice 1 de sync semântico local e bridge do optimizer para arrays)
- `docs/hermes-analysis/BATTLE_AI_PROJECT_DECISIONS_TO_VALIDATE_2026-06-11.md` (dúvidas/decisões para validação do owner)
- `docs/hermes-analysis/BATTLE_AI_OWNER_VALIDATION_QUESTIONS_2026-06-11.md` (handoff objetivo de perguntas/furos/logística antes das próximas fases)
- `docs/hermes-analysis/HERMES_FUNCTIONAL_TAG_CONSUMER_CLASSIFICATION_2026-06-11.md` (classificação dos consumidores Hermes de `functional_tag` e status de migração para arrays)
- `docs/hermes-analysis/DECK_GENERATION_FOCUS_READINESS_2026-06-16.md` (triagem atual: battle nao bloqueia foco em geracao/optimize; candidate quality usa sinal EDHREC bounded em dry-run validado)
- Hermes AWS aplicou o snapshot semântico de Lorehold em 2026-06-11 com backup
  do `knowledge.db`; invariantes pós-scan: 100 cartas, 1 comandante, hash
  estrutural restaurado e nenhuma Chrome Mox/Mox Diamond/Mox Opal no deck.
- Hermes AWS aplicou o Slice 2 `ruleset_hash` em 2026-06-11 com backup
  `knowledge.db.pre-ruleset-76d828d2.20260611T194820Z`; invariantes pós-smoke:
  100 cartas, 1 comandante, um `deck_hash`, um `semantics_hash`, um
  `ruleset_hash`, baseline `id=2` com 60 jogos e 7 benchmarks
  `ruleset_hash_smoke` contendo hashes semântico e de regras.
- Hermes AWS aplicou o Slice 3 `logical_rule_key` em 2026-06-11 com backup
  `knowledge.db.pre-logical-rule-55af86c4.20260611T201027Z`; invariantes
  pós-smoke: 100 cartas, 1 comandante, 98 regras com `logical_rule_key`, 0
  regras sem chave lógica, 2 regras equivalentes deduplicadas, baseline `id=3`
  com 36 jogos e 8 benchmarks `logical_rule_smoke` contendo hashes semântico e
  de regras.
- `derive_functional_tags_from_battle_rules.py` existe apenas como report-only:
  smoke PG atualizado em `86ef9062` viu 3156 regras, propôs 89 novos candidatos
  `card_battle_rules_v1`, encontrou 261 tags já presentes e rejeitou 2806 por
  gate. A revisão `BATTLE_RULE_DERIVED_TAG_REVIEW_2026-06-11.md` classifica
  27 candidatos como low-risk review e 62 como manual-review após mover
  Dramatic Reversal, Manamorphose e Victory Chimes para revisão manual por
  escopo card-specific. A allowlist
  `BATTLE_RULE_DERIVED_TAG_LOW_RISK_ALLOWLIST_2026-06-12.json` versiona os 27
  low-risk apenas para dry-run; Hermes AWS confirmou 27 allowlisted, 0 manual
  liberado, 0 unmatched e `apply=false`. O runner agora detecta stale cleanup
  e roda PostgreSQL transaction dry-run com rollback obrigatório; as rodadas
  local e Hermes AWS exercitaram 27 upserts allowlisted, 0 stale deletes,
  rollback true e `apply=false`. O caminho operator-controlled
  `--apply-reviewed-allowlist` existe, mas a allowlist atual bloqueia apply por
  `apply_approved=false`; a tentativa local retornou `pg_apply.blocked=true`.
  Nenhum apply em `card_function_tags` está liberado sem nova allowlist
  revisada com `apply_approved=true`.
- Decision Trace v1 entrou em 2026-06-15 como slice Hermes-only:
  `battle_analyst_v9.py` emite decisoes por side-channel opcional,
  `battle_replay_v10_3.py` grava `*.decision_trace.jsonl`, e
  `replay_decision_auditor.py` audita decisoes sem alterar simulacao, API,
  Flutter ou PostgreSQL. Fonte operacional:
  `docs/hermes-analysis/DECISION_TRACE_V1_SLICE_2026-06-15.md`.
- Identidade canônica de carta entrou em transição em 2026-06-12: backend/sync
  agora têm contrato aditivo para `cards.oracle_id`, `cards.layout` e
  `cards.card_faces_json`, tratando `scryfall_id` como printing id. Ainda falta
  migration/backfill e medição de cobertura antes de ligar singleton/import/
  learned-opponent sync a essa identidade.
- `scripts/quality_gate.sh` (validacao automatizada)
- `CHECKLIST_GO_LIVE_FINAL.md` (gates de release)

## Conta QA para validacao

Credenciais, user IDs, tokens, emails reais e senhas de QA nao devem ficar
versionados neste diretorio. Usar cofre/local env/handoff privado quando uma
rodada de validacao precisar de conta real.

Informacoes operacionais permitidas neste arquivo:

- Plano QA: Free (120 requests IA/mes), se aplicavel
- Decks de smoke podem ser citados por nome sanitizado, sem user ID
- Obs: JWT pode expirar rapido; fazer login fresco antes de usar

## Rotina obrigatoria pos-push Codex -> Hermes

A partir de 2026-05-26, depois de todo push relevante feito no fluxo local/Codex, o Hermes deve ser chamado antes de continuar a proxima frente:

- Mudanca comum: `/opt/data/scripts/manaloom-post-push-audit.sh normal <sha>`
- Mudanca grande de app/backend/layout/runtime: `/opt/data/scripts/manaloom-post-push-audit.sh deep <sha>`
- Smoke rapido de infraestrutura: `/opt/data/scripts/manaloom-post-push-audit.sh smoke`
- Status/ultimo relatorio: `/opt/data/scripts/manaloom-hermes-status.sh`

A rotina esperada e:

1. Codex local implementa, valida e faz push.
2. Se houver backend publico, confirmar `/health.git_sha`.
3. Hermes audita a branch/commit e atualiza somente `docs/hermes-analysis/**` se houver achado real.
4. Codex local le o retorno do Hermes, valida os achados e corrige P0/P1 antes de seguir.
5. Hermes nao substitui prova viva local em iPhone Simulator, scanner/camera, push real ou validacao visual.

### Guardrails do script pos-push

Atualizado em 2026-05-26:

- `smoke` e deterministico, sem chamada LLM, para validar workspace/HEAD/status rapidamente.
- `normal` usa timeout padrao de 360s.
- `deep` usa timeout padrao de 1200s.
- O timeout pode ser sobrescrito com `HERMES_AUDIT_TIMEOUT_SECONDS=<segundos>`.
- Todo relatorio termina com `HERMES_AUDIT_STATUS: PASS|FINDINGS|BLOCKED|TIMEOUT|PASS_UNCLASSIFIED`.
- O ultimo relatorio fica apontado por `/opt/data/.hermes/data/manaloom/reports/post_push_latest.md`.
- Se o LLM travar, o script deve retornar `TIMEOUT` em vez de deixar processo pendurado.
- O script faz `git fetch --all --prune` antes de calcular `origin/master`, para o smoke nao reportar SHA antigo.

## ManaLoom card-rule sync guard - 2026-06-23

- `card_battle_rules` continua sendo a fonte de verdade para semantica de
  batalha; `known_cards_canonical_snapshot.json` e SQLite sao caches derivados.
- O sync `sync_battle_card_rules_pg.py` nao pode apagar `oracle_hash` nem
  metadados PG-only em conflitos de mesma chave logica curated/manual quando o
  reviewed JSON de origem nao contem esses campos.
- Evidencia PG059:
  `docs/hermes-analysis/master_optimizer_reports/pg059_sync_metadata_restore_postcheck_20260623_022328.out`
  fechou `target_missing_hash_rows=0`, `target_hash_mismatch_rows=0` e
  `target_missing_effect_patch_rows=0`.

## ManaLoom deck 6 fetchland gate - 2026-06-23

- PG062 fechou o lote L1 de fetchlands do deck oficial `6` sem promover
  executor dinamico de fetch.
- `Arid Mesa`, `Bloodstained Mire`, `Flooded Strand`, `Marsh Flats`,
  `Prismatic Vista`, `Scalding Tarn`, `Windswept Heath` e `Wooded Foothills`
  continuam como `effect=land`; pagar vida, sacrificar, buscar e embaralhar
  estao marcados como `annotation_only`.
- Evidencia:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l1_fetchlands_pg062_postcheck_20260623_024200.out`
  fechou `active_review_only_or_needs_review_rows=0` e `backup_rows=16`; o
  auditor deck `6` passou para `high=30`, `pass=70`.

## ManaLoom deck 608 tutor/search gate - 2026-06-23

- PG063 fechou o pacote tutor/search do deck `608` para `Enlightened Tutor`,
  `Idyllic Tutor`, `Goblin Engineer` e `Imperial Recruiter`.
- Runtime novo: `library_tutor_candidates` diferencia alvo e destino
  (`artifact_or_enchantment_to_top`, `enchantment`,
  `artifact_to_graveyard`, `creature_power_lte_2`), e criaturas com
  `etb_tutor_target` usam o resolvedor generico de tutor ETB.
- Evidencia:
  `docs/hermes-analysis/master_optimizer_reports/deck608_tutor_search_pg063_postcheck_20260623_024856.out`
  fechou `target_runtime_rows=4`, `old_active_shadow_rows=0` e
  `backup_rows=8`; o auditor deck `608` passou para
  `high=34`, `medium=6`, `pass=28` e os quatro alvos ficaram
  `pass/coherent_for_current_gate`.

## ManaLoom deck 6 Recruiter of the Guard gate - 2026-06-23

- PG064 fechou `Recruiter of the Guard` como criatura com ETB tutor de
  criatura com toughness 2 ou menos para a mao.
- Diferenciar dos recruits por poder: `Imperial Recruiter` usa
  `creature_power_lte_2`; `Recruiter of the Guard` usa
  `creature_toughness_lte_2`.
- Evidencia:
  `docs/hermes-analysis/master_optimizer_reports/deck6_recruiter_guard_pg064_postcheck_20260623_025848.out`
  fechou `target_runtime_rows=1`, `old_active_shadow_rows=0` e
  `backup_rows=2`; o focused event
  `docs/hermes-analysis/master_optimizer_reports/deck6_recruiter_guard_pg064_focused_events_20260623_025848.jsonl`
  prova `rule_logical_key=battle_rule_v1:423a8aa67b5cf450f4c4fb47ca50ae46`;
  o auditor deck `6` passou para `high=27`, `pass=73`.

## ManaLoom deck 6 resource/topdeck engine gate - 2026-06-23

- PG065 fechou `Scroll Rack` e `Smothering Tithe`; PG066 fechou `Birgi, God
  of Storytelling // Harnfel, Horn of Bounty`.
- PostgreSQL venceu a suposicao inicial da fila: `Smothering Tithe` ja tinha
  `oracle_hash`, `battle_model_scope` e shadow gerada desativada via PG065;
  por isso PG066 aplicou somente `Birgi`.
- Evidencia:
  `docs/hermes-analysis/master_optimizer_reports/shared_engine_rules_pg065_postcheck_20260623_031553.out`
  fechou `target_runtime_rows=2`, `old_active_shadow_rows=0` e
  `backup_rows=5`; `docs/hermes-analysis/master_optimizer_reports/deck6_birgi_spellcast_resource_engine_pg066_postcheck_20260623_032200.out`
  fechou `target_runtime_rows=1`, `old_active_shadow_rows=0` e
  `backup_rows=2`.
- Focused event:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg066_birgi_smothering_focused_events_20260623_032200.jsonl`
  prova `Birgi` com
  `battle_rule_v1:05576012d8fca56910da7ea072abe15e` e `Smothering Tithe`
  com `battle_rule_v1:242df1cde958c67ece11aae4af5f4bc6`.
- Auditor deck `6` passou para `high=24`, `pass=76`; `Blasphemous Act`
  permaneceu `pass` e sua reducao de custo segue apenas como caveat
  `annotation_only`.

## ManaLoom PG066/PG067 runtime metadata note - 2026-06-23

- `runtime_hash_backfill_pg066_20260623_032021` aplicou backfill de
  `oracle_hash` em 8 regras runtime ja confiaveis; `hash_mismatch_rows=0` e
  `backup_rows=8`.
- `seething_song_runtime_metadata_pg067_20260623_032307` anotou que
  `Seething Song` preserva `produces=R`, mas o runtime atual abstrai a mana
  para pool generico one-shot; `backup_rows=1`.
- Houve colisao de numeracao PG066 entre o backfill e o pacote `Birgi`; as
  backup tables sao distintas. Proximo deploy deve usar PG068.
- O smoke `20260623_033223` re-sincronizou PG -> SQLite e reexecutou os
  auditores de deck `6`/`606` sem nova escrita PostgreSQL; as contagens
  permaneceram deck `6` `high=24`, `pass=76` e deck `606` `high=37`,
  `medium=7`, `pass=37`.

## ManaLoom deck 6 copy-spell stack gate - 2026-06-23

- PG068 fechou `Reiterate` e `Dualcaster Mage` como familia de copia de
  magica no stack.
- `Reiterate` usa o executor existente de instant `copy_spell`; buyback e
  escolha de novos alvos permanecem `annotation_only`.
- `Dualcaster Mage` agora tem trilha explicita `etb_copy_spell`: a criatura
  com flash entra no stack, resolve para battlefield e so entao copia o
  instant/sorcery alvo ainda no stack.
- Evidencia:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l5a_copy_spell_stack_pg068_postcheck_20260623_004158.out`
  fechou `expected_runtime_rows=2`, `old_active_shadow_rows=0` e
  `backup_rows=4`; o focused event
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg068_copy_spell_stack_focused_events_20260623_004158.jsonl`
  prova `battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405` para `Reiterate`
  e `battle_rule_v1:e176019b87d68d22e2388e08a4efbf55` para `Dualcaster Mage`.
- Auditor deck `6` passou para `high=22`, `pass=78`; deck `606` permaneceu
  `high=37`, `medium=7`, `pass=37`.
- Nota de metodo: observacoes sobre `Blasphemous Act` sao caveats para checar
  quando a lane dele voltar, nao regras normativas nem bloqueadores de outros
  lotes.

## ManaLoom deck 6 copy-token gate - 2026-06-23

- O segundo pacote PG068 fechou `Heat Shimmer`, `Twinflame` e
  `Molten Duplication` como familia de copia temporaria de criatura/artefato,
  e revalidou `Reiterate`/`Dualcaster Mage` no mesmo corte.
- `Heat Shimmer` copia criatura de qualquer controlador e exila o token no fim
  do turno; `Twinflame` copia criatura propria e exila o token; `Molten
  Duplication` copia artefato ou criatura propria como artefato em adicao e
  sacrifica o token no fim do turno.
- Evidencia:
  `docs/hermes-analysis/master_optimizer_reports/deck6_copy_token_stack_rules_pg068_postcheck_20260623_034443.out`
  fechou `exact_runtime_rows=5`, `hash_mismatch_rows=0`,
  `effect_mismatch_rows=0`, `scope_mismatch_rows=0`,
  `old_active_shadow_rows=0` e `backup_rows=12`.
- Auditor deck `6` em
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_035001.json`
  passou para `high=7`, `medium=11`, `pass=82`; deck `606` passou para
  `high=7`, `medium=30`, `pass=44`; deck `607` esta em `high=30`,
  `medium=18`, `pass=46`; deck `608` esta em `high=21`, `medium=9`,
  `pass=38`; global esta em `high=57`, `medium=45`, `pass=103`.
- `test_battle_analyst_v10_3.py`, `test_sync_battle_card_rules_pg_selection.py
  -v`, `test_deck_card_battle_rule_coherence_audit.py -v` e `py_compile`
  passaram no corte atual.
- PG068 agora tem duas backup tables validas:
  `pg068_deck6_l5a_copy_spell_stack_20260623_004158` e
  `pg068_deck6_copy_token_stack_rules_20260623_034443`. Proximo deploy deve
  usar PG069.

## ManaLoom deck 6 L2 specific runtime cleanup - 2026-06-23

- PG069 fechou a limpeza de metadata/runtime especifico para `The One Ring` e
  `Unexpected Windfall`.
- `The One Ring` manteve a semantica PG025 ja testada, mas recebeu
  `oracle_hash=644d5305e6be932586a6d3b7325cadf7` e
  `oracle_runtime_scope=indestructible_cast_etb_protection_upkeep_burden_tap_draw_v1`.
- `Unexpected Windfall` recebeu
  `oracle_hash=9c4fbe06104051a2e8b1d295d307b26a`,
  `oracle_runtime_scope=additional_cost_discard_draw_two_create_two_treasures_v1`
  e `additional_cost_discard_status=runtime_required_card_discard`.
- Runtime tambem passou a emitir `rule_logical_key` e `rule_oracle_hash` no
  evento `treasure_created` dessa carta.
- Evidencia:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_specific_runtime_cleanup_pg069_postcheck_20260623_005736.out`
  fechou `expected_runtime_rows=2`, `old_active_shadow_rows=0`,
  `runtime_missing_hash_rows=0` e `backup_rows=6`.
- Focused event:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg069_specific_runtime_cleanup_focused_events_20260623_011015.jsonl`
  prova `The One Ring` e `Unexpected Windfall` com rule key/hash nos eventos
  de replay.
- Sync final PG -> SQLite:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg069_l2_specific_runtime_cleanup_20260623_040215.json`
  usou `include_needs_review=false`, carregou `pg_rows_loaded=1825` e escreveu
  `sqlite_inserted_or_updated=2493`.
- Auditor deck `6` em
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg069_20260623_040215.json`
  passou para `high=7`, `medium=10`, `pass=83`; deck `606` esta em
  `high=7`, `medium=30`, `pass=44`; global esta em `high=57`,
  `medium=44`, `pass=104`.
- Proximo deploy deve usar PG070.

## ManaLoom deck 6 PG070 hash cleanup and red-discard runtime - 2026-06-23

- PG070 tem duas backup tables validas:
  `pg070_deck6_l2_hash_only_runtime_rules_20260623_011859` e
  `pg070_deck6_red_discard_runtime_20260623_042617`; proximo deploy deve usar
  PG071.
- O primeiro pacote fechou a fila L2/hash-only de `Fellwar Stone`,
  `Mana Vault`, `Mox Amber`, `Scroll Rack`, `Seething Song`, `Silence`,
  `Talisman of Conviction`, `Unexpected Windfall` e
  `Valakut Awakening // Valakut Stoneforge`; o addendum restaurou apenas a
  metadata de mana vermelha generica de `Seething Song`, sem trocar o executor
  `single_shot_red_ritual_v1`.
- O segundo pacote fechou `Faithless Looting` e `Gamble`: `Faithless Looting`
  agora usa `effect=loot` com draw two/discard two; `Gamble` usa tutor para a
  mao seguido de descarte aleatorio runtime. Flashback e shuffle continuam
  annotation-only.
- Evidencia:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_only_runtime_rules_pg070_postcheck_20260623_011859.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_only_runtime_rules_pg070_seething_metadata_postcheck_20260623_011859.out`
  e
  `docs/hermes-analysis/master_optimizer_reports/deck6_red_discard_runtime_pg070_postcheck_20260623_042617.out`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_l2_hash_only_runtime_focused_events_20260623_011859.jsonl`
  e
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_red_discard_runtime_focused_events_20260623_042617.jsonl`.
- Sync aceito PG -> SQLite:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg070_deck6_red_discard_runtime_20260623_042617.json`
  usou `include_needs_review=false`, carregou `pg_rows_loaded=1825`,
  escreveu `sqlite_inserted_or_updated=2493` e exportou
  `canonical_snapshot_rows_exported=3201`.
- Auditor aceito:
  deck `6` em
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg070_20260623_042617.json`
  esta em `high=5`, `medium=10`, `pass=85`; deck `606` esta em
  `high=7`, `medium=30`, `pass=44`; deck `607` esta em `high=30`,
  `medium=17`, `pass=47`; deck `608` esta em `high=21`, `medium=9`,
  `pass=38`; global esta em `high=55`, `medium=44`, `pass=106`.
- O corte gerado com regras ainda em revisao foi descartado como gate aceito;
  ele nao deve orientar fila de ajuste nem fechamento de carta.
- `Blasphemous Act` nao foi alvo do PG070. A reducao de custo continua apenas
  caveat/annotation-only, e nao deve ser tratada como regra normativa ou
  bloqueador fora da lane propria.

## ManaLoom deck 6 red discard runtime - 2026-06-23

- PG070 fechou `Faithless Looting` e `Gamble`.
- `Faithless Looting` saiu de `draw_cards` generico para `loot` com
  `count=2`, `oracle_hash=2e734d8bae3f331866abf1b030c92781` e
  `battle_model_scope=draw_two_discard_two_flashback_annotation_v1`.
- `Gamble` manteve tutor `target=any`, mas agora tem
  `discard_after_tutor_random=true`,
  `oracle_hash=9b3fc8ab7f664f6c084e0bda0ccf9a7c` e
  `battle_model_scope=any_card_to_hand_then_random_discard_v1`.
- Evidencia:
  `docs/hermes-analysis/master_optimizer_reports/deck6_red_discard_runtime_pg070_postcheck_20260623_042617.out`
  fechou `expected_runtime_rows=2`, `old_active_shadow_rows=0`,
  `runtime_missing_hash_rows=0` e `backup_rows=4`.
- Focused event:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_red_discard_runtime_focused_events_20260623_042617.jsonl`
  prova `loot_resolved`, `tutor_resolved` e `random_discard_after_tutor` com
  rule key/hash.
- Sync final PG -> SQLite:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg070_deck6_red_discard_runtime_20260623_042617.json`
  usou `include_needs_review=false`, carregou `pg_rows_loaded=1825` e escreveu
  `sqlite_inserted_or_updated=2493`.
- Auditor deck `6` em
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg070_20260623_042617.json`
  passou para `high=5`, `medium=10`, `pass=85`; deck `606` esta em
  `high=7`, `medium=30`, `pass=44`; global esta em `high=55`,
  `medium=44`, `pass=106`.
- Proximo deploy deve usar PG072.

## ManaLoom deck 6 PG071 L3 fast mana/cost reduction - 2026-06-23

- PG071 fechou `Lotus Petal` e `Ruby Medallion` como lane L3
  fast-mana/cost-reduction: `Lotus Petal` agora tem oracle hash
  `a5b9069217908acfd75c5704b414b035`,
  `battle_model_scope=zero_mana_artifact_sacrifice_one_mana_one_shot_runtime_v1`
  e runtime one-shot para mana; `Ruby Medallion` agora tem oracle hash
  `52bc55846d69bacf3afba1ffa734b81e`,
  `battle_model_scope=red_spell_cost_reduction_annotation_only_v1` e nao e
  tratado como fonte de mana recorrente.
- Evidencia PG:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3_fast_mana_cost_reduction_pg071_precheck_20260623_043623.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3_fast_mana_cost_reduction_pg071_apply_20260623_043623.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3_fast_mana_cost_reduction_pg071_postcheck_20260623_043623.out`
  e rollback
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3_fast_mana_cost_reduction_pg071_rollback_20260623_043623.sql`.
- Focused event:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg071_l3_fast_mana_runtime_focused_events_20260623_043623.jsonl`
  prova `Lotus Petal` resolvendo para graveyard com mana pool `1` e
  `Ruby Medallion` resolvendo para battlefield como `passive` sem virar mana
  source.
- Sync aceito PG -> SQLite:
  `docs/hermes-analysis/master_optimizer_reports/pg071_l3_fast_mana_cost_reduction_trusted_sync_report_20260623_043623.json`
  usou `include_needs_review=false`, carregou `pg_rows_loaded=1825`,
  escreveu `sqlite_inserted_or_updated=2493` e exportou
  `canonical_snapshot_rows_exported=3201`.
- Auditor aceito pos-PG071: deck `6` esta em `high=5`, `medium=8`,
  `pass=87`; deck `606` esta em `high=7`, `medium=30`, `pass=44`;
  deck `607` esta em `high=30`, `medium=16`, `pass=48`; deck `608`
  esta em `high=21`, `medium=7`, `pass=40`; global esta em `high=55`,
  `medium=42`, `pass=108`.
- O sync amplo gerado com regras em revisao foi descartado como gate aceito.
- Proximo deploy deve usar PG072.

## ManaLoom deck 6 PG072 L6 interaction/removal/counter - 2026-06-23

- PG072 fechou `Get Lost` e `Pyroblast` como lote L6
  interaction/removal/counter; `Chaos Warp` ficou fora por exigir shuffle,
  reveal e top permanent como revisao unique.
- `Get Lost` saiu de `remove_creature` para
  `effect=remove_permanent`, `target=creature_enchantment_or_planeswalker`,
  `oracle_hash=6b6517e1b5b60db5cf6bbcd991dbc1ec` e
  `battle_model_scope=destroy_creature_enchantment_planeswalker_create_two_map_tokens_v1`.
  A ativacao/explore dos Map tokens segue `annotation_only`.
- `Pyroblast` passou a exigir alvo azul no runtime de counter:
  `oracle_hash=ecf9ad1f393a664f16867aab8a6edf77` e
  `battle_model_scope=blue_spell_counter_runtime_destroy_blue_permanent_annotation_v1`.
  O modo de destruir permanente azul segue anotado ate existir selecao
  proativa desse modo.
- Evidencia PG:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l6_interaction_removal_counter_pg072_precheck_20260623_045642.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck6_l6_interaction_removal_counter_pg072_apply_20260623_045642.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck6_l6_interaction_removal_counter_pg072_postcheck_20260623_045642.out`
  e rollback
  `docs/hermes-analysis/master_optimizer_reports/deck6_l6_interaction_removal_counter_pg072_rollback_20260623_045642.sql`.
- Focused event:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg072_l6_interaction_removal_counter_focused_events_20260623_045642.jsonl`
  prova `Pyroblast` counterando spell azul e rejeitando spell vermelha, e
  `Get Lost` removendo enchantment e criando dois Map tokens com rule
  key/hash.
- Sync aceito PG -> SQLite:
  `docs/hermes-analysis/master_optimizer_reports/pg072_l6_interaction_removal_counter_sync_report_20260623_045642.json`
  usou `include_needs_review=false`, carregou `pg_rows_loaded=1825` e
  escreveu `sqlite_inserted_or_updated=1802`.
- Resync final apos corrigir a normalizacao oracle de `target creature,
  enchantment, or planeswalker`:
  `docs/hermes-analysis/master_optimizer_reports/pg072_l6_interaction_removal_counter_resync_report_20260623_050816.json`;
  o snapshot canonico passou a manter `Get Lost` como
  `effect=remove_permanent` e `target=creature_enchantment_or_planeswalker`.
- Auditor aceito pos-PG072: deck `6` esta em `high=3`, `medium=8`,
  `pass=89`; deck `606` permanece `high=7`, `medium=30`, `pass=44`;
  global esta em `high=53`, `medium=42`, `pass=110`.
- Proximo deploy deve usar PG073.

## ManaLoom deck 6 PG073-PG075 L4 card-flow/provenance checkpoint - 2026-06-23

- Nota de metodo: observacoes do operador, incluindo a ressalva de
  `Blasphemous Act`, sao pistas para checagem, nao fonte de regra. A carta so
  deve ser reaberta se oracle, PostgreSQL ou executor mostrarem falha real.
- PG073 fechou `Esper Sentinel` e `Wheel of Misfortune` para a fila high do
  deck `6`. `Esper Sentinel` ja estava semanticamente corrigido no PostgreSQL
  com `battle_model_scope=first_opponent_noncreature_spell_power_tax_draw_v1`;
  o ciclo adicionou executor/teste focado e desabilitou a shadow row gerada.
  `Wheel of Misfortune` saiu de draw-seven generico para o modelo compacto de
  escolha secreta, dano ao maior numero e descarte/compra para nao-menores.
- Evidencia PG073:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l4_card_flow_pg073_precheck_20260623_051141.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck6_l4_card_flow_pg073_apply_20260623_051141.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck6_l4_card_flow_pg073_postcheck_20260623_051141.out`
  e rollback
  `docs/hermes-analysis/master_optimizer_reports/deck6_l4_card_flow_pg073_rollback_20260623_051141.sql`.
  O postcheck fechou `target_rule_rows=4`, `expected_runtime_rows=2`,
  `old_active_shadow_rows=0`, `runtime_missing_hash_rows=0` e
  `backup_rows=4`.
- Focused events PG073:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg073_l4_card_flow_focused_events_20260623_051141.jsonl`
  prova `trigger_resolved` de `Esper Sentinel` com tax de poder e
  `wheel_resolved` de `Wheel of Misfortune` com rule key/hash.
- Focused events reconciliados:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg073_l4_l6_card_flow_focused_events_20260623_052954.jsonl`
  preservam `rule_version=2` no replay local depois da correcao do sync
  PG -> SQLite.
- PG074 restaurou somente proveniencia de hash para oito regras confiaveis:
  `Fellwar Stone`, `Mana Vault`, `Mox Amber`, `Scroll Rack`,
  `Seething Song`, `Talisman of Conviction`, `Unexpected Windfall` e
  `Valakut Awakening // Valakut Stoneforge`. Nao houve mudanca semantica de
  `effect_json`, `deck_role_json` ou executor.
- PG075 restaurou metadados de `Seething Song`
  (`produces=R`, `mana_color_status=abstracted_to_generic_pool_runtime` e
  escopo de ritual vermelho) exigidos pelo harness de proveniencia. Tambem
  nao houve mudanca de executor ou deck.
- Syncs aceitos PG -> SQLite:
  `docs/hermes-analysis/master_optimizer_reports/pg073_l4_card_flow_sync_report_20260623_051141.json`,
  `docs/hermes-analysis/master_optimizer_reports/pg074_hash_provenance_restore_sync_report_20260623_052703.json`
  e
  `docs/hermes-analysis/master_optimizer_reports/pg075_seething_song_metadata_sync_report_20260623_053046.json`;
  todos usaram `include_needs_review=false`, carregaram `pg_rows_loaded=1825`,
  escreveram `sqlite_inserted_or_updated=1802` e exportaram
  `canonical_snapshot_rows_exported=3201`.
- Auditor final aceito PG075/reconciliado: deck `6` esta em `high=1`,
  `medium=8`, `pass=91`; deck `606` esta em `high=7`, `medium=30`,
  `pass=44`; deck `607` esta em `high=29`, `medium=16`, `pass=49`;
  deck `608` esta em `high=21`, `medium=7`, `pass=40`; global esta em
  `high=51`, `medium=42`, `pass=112`.
- Os cortes PG073/PG074 gerados em paralelo com sync sem sufixo final/trusted
  sao rejeitados como artefatos racy/intermediarios para gate. Usar somente os
  cortes `trusted`, `accepted` ou `pg075_final` quando decidir fechamento.
- Proximo deploy deve usar PG076. Unico high restante no deck `6`:
  `Chaos Warp`; depois priorizar mediums battle-support `Jeska's Will` e
  `Mizzix's Mastery` antes da fila support/passive.

## ManaLoom deck 6 PG076 support/passive + Chaos Warp closure - 2026-06-23

- PG076 foi reconciliado como pacote combinado. Subpacote support/passive
  aplicou hashes/scope oracle-specific para `Drannith Magistrate`,
  `Giver of Runes`, `Mother of Runes`, `Professional Face-Breaker`,
  `Ranger-Captain of Eos` e `Storm-Kiln Artist`; o addendum de
  `Ranger-Captain of Eos` tornou o ETB tutor de criatura mana value 1 ou
  menos executavel, mantendo shuffle e sacrifice-silence como annotation-only.
- Subpacote `Chaos Warp` aplicou a regra runtime:
  `target_permanent_shuffle_into_owner_library_reveal_top_permanent_to_battlefield_v1`.
  A regra curada `battle_rule_v1:0b547d7209a38ac2d23a1cca07917680` ficou
  `verified/auto`, `rule_version=2`, `oracle_hash=7db2bc44526b855fd22302e9569746b5`;
  a shadow row gerada `draw_cards` ficou `deprecated/disabled`.
- PostgreSQL backups PG076 existentes:
  `manaloom_deploy_audit.pg076_deck6_support_passive_annotation_20260623_054358`,
  `manaloom_deploy_audit.pg076_deck6_support_passive_ranger_tutor_20260623_054358`
  e `manaloom_deploy_audit.pg076_deck6_chaos_warp_runtime_20260623_055230`.
- Sync final aceito PG -> SQLite:
  `docs/hermes-analysis/master_optimizer_reports/pg076_chaos_warp_runtime_sync_report_20260623_055230.json`
  usou `include_needs_review=false`, carregou `pg_rows_loaded=1825`,
  escreveu `sqlite_inserted_or_updated=1802` e exportou
  `canonical_snapshot_rows_exported=3201`.
- Focused event:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg076_chaos_warp_focused_events_20260623_055230.jsonl`
  prova `removal_resolved` com destino `library` e
  `chaos_warp_reveal_resolved` colocando a carta permanente revelada no
  battlefield com rule key/hash.
- Auditor final aceito PG076: deck `6` esta em `high=0`, `medium=2`,
  `pass=98`; deck `606` esta em `high=7`, `medium=30`, `pass=44`;
  deck `607` esta em `high=29`, `medium=14`, `pass=51`; deck `608` esta em
  `high=21`, `medium=6`, `pass=41`; global esta em `high=50`,
  `medium=36`, `pass=119`.
- Testes passaram: `py_compile`, `test_battle_analyst_v10_3.py`
  incluindo `test_pg076_chaos_warp_shuffles_target_into_library_and_reveals_top_permanent`,
  `test_sync_battle_card_rules_pg_selection.py -v` e
  `test_deck_card_battle_rule_coherence_audit.py -v`.
- Proximo deploy deve usar PG077. Deck `6` nao tem high restante; proxima fila
  do deck `6` e `Jeska's Will` e `Mizzix's Mastery`.

## ManaLoom deck 6 PG076 final reconciliation - 2026-06-23 06:01 UTC

- Revalidacao final PG -> SQLite:
  `docs/hermes-analysis/master_optimizer_reports/pg076_final_sync_report_20260623_060105.json`
  confirmou `include_needs_review=false`, `pg_inserted_or_updated=0`,
  `pg_rows_loaded=1825`, `sqlite_inserted_or_updated=1802` e
  `canonical_snapshot_rows_exported=3201`.
- Evento focado support/passive:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg076_support_passive_annotation_focused_events_20260623_054358.jsonl`
  prova seis `spell_resolved` com rule key/hash e um `tutor_resolved` para
  `Ranger-Captain of Eos` buscando `Esper Sentinel` via
  `creature_mana_value_1_or_less`.
- Auditor final deck `6`:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg076_final_20260623_060105.json`
  reportou `high=0`, `medium=2`, `pass=98`; os mediums restantes sao
  `Jeska's Will` e `Mizzix's Mastery`.
- Auditor final deck `606`:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_pg076_final_20260623_060105.json`
  permaneceu `high=7`, `medium=30`, `pass=44`.
- Auditor global final limitado:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_pg076_final_20260623_060105.json`
  reportou `high=50`, `medium=36`, `pass=119`.
- `Blasphemous Act` aparece `pass/coherent_for_current_gate` no corte deck `6`;
  a nota de reducao de custo continua apenas caveat de checagem futura e nao
  reabre a carta sem mismatch real de oracle/runtime/PostgreSQL.

## ManaLoom deck 6 PG077 closure - 2026-06-23 06:25 UTC

- PG077 closed deck `6` for the current card battle-rule coherence gate.
  Final deck `6` audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg077_final_20260623_062156.json`
  reports `pass=100`.
- Runtime rows applied in PostgreSQL:
  `Jeska's Will`
  `battle_rule_v1:c8621a807cc65adc820a8b8189979f70` with
  `oracle_hash=e323893e6c38ee2d618b4f9c737fadee`, and
  `Mizzix's Mastery`
  `battle_rule_v1:e44a8b8d0e4f8fc8e8a5ebd93a73194f` with
  `oracle_hash=8b822f0c58e4ab4e91f9e4946e8c04e9`.
- Hash-only addenda restored missing oracle provenance for `Silence`,
  `Scroll Rack`, `Unexpected Windfall`, and
  `Valakut Awakening // Valakut Stoneforge`; the 8-card addendum updated only
  the 3 rows still missing hash after precheck and left `effect_json` and
  `deck_role_json` unchanged.
- Final sync:
  `docs/hermes-analysis/master_optimizer_reports/pg077_hash_provenance_final_sync_report_20260623_062156.json`
  used PostgreSQL as source, loaded `pg_rows_loaded=1825`, wrote
  `sqlite_inserted_or_updated=1802`, and kept `include_needs_review=false`.
- Runtime events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl`.
- Final deck `606` audit now reports `high=7`, `medium=29`, `pass=45`;
  final global `--limit 200` audit reports `high=50`, `medium=34`,
  `pass=121`.
- Tests passed: `py_compile`, `test_battle_analyst_v10_3.py`,
  `test_sync_battle_card_rules_pg_selection.py -v` with `PYTHONPATH`, and
  `test_deck_card_battle_rule_coherence_audit.py -v`.
- Next PG package is PG078. Next recommended queue is deck `606` high
  battle-critical: `Flare of Duplication`, `Powerbalance`, `Reforge the Soul`,
  `Rise of the Eldrazi`, `Rite of the Dragoncaller`, `Storm Herd`, and
  `Witch Enchanter // Witch-Blessed Meadow`.

## ManaLoom PG077 final addendum - 2026-06-23 06:28 UTC

- The accepted PG077 high-water is the post-addendum `06:24:22` cut, not the
  earlier `06:21:56` sync. The later full harness run caught missing
  `Seething Song` `mana_color_status` metadata.
- Addendum:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_seething_song_metadata_restore_postcheck_20260623_062422.out`
  restored ritual metadata and reported `target_missing_runtime_metadata_rows=0`.
- Final sync:
  `docs/hermes-analysis/master_optimizer_reports/pg077_l4_battle_support_final_sync_report_20260623_062422.json`.
- Final deck `6` audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg077_final_20260623_062422.json`
  reports `high=0`, `medium=0`, `pass=100`.
- Final variant cuts: deck `606` `high=7`, `medium=29`, `pass=45`;
  deck `607` `high=29`, `medium=12`, `pass=53`; deck `608` `high=21`,
  `medium=4`, `pass=43`; global `high=50`, `medium=34`, `pass=121`.
- Final runtime event file:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_l4_battle_support_focused_events_20260623_062422.jsonl`.
- Full tests passed after this addendum. Next PG package is still PG078.

## ManaLoom PG077 high-water addendum - 2026-06-23 06:26 UTC

- Additional PG077 addenda were applied for ramp/ritual hash provenance and
  `Seething Song` metadata drift:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_ramp_ritual_hash_restore_postcheck_20260623_062033.out`
  and
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_seething_song_metadata_restore_postcheck_20260623_062422.out`.
- High-water final sync:
  `docs/hermes-analysis/master_optimizer_reports/pg077_l4_battle_support_final_sync_report_20260623_062422.json`.
- High-water audits: deck `6` `pass=100`, deck `606` `high=7`,
  `medium=29`, `pass=45`, deck `607` `high=29`, `medium=12`, `pass=53`,
  deck `608` `high=21`, `medium=4`, `pass=43`, and global `high=50`,
  `medium=34`, `pass=121`.

## ManaLoom PG078 deck 606 hash/scope restore - 2026-06-23 06:42 UTC

- PG078 was applied and validated as a provenance/cache coherence batch for
  deck `606` L2 rules. It restored `oracle_hash` on 23 trusted scoped
  PostgreSQL `card_battle_rules` rows and disabled 44 superseded generated or
  shadow rows.
- SQL evidence:
  `docs/hermes-analysis/master_optimizer_reports/deck606_l2_hash_scope_restore_pg078_precheck_20260623_063535.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck606_l2_hash_scope_restore_pg078_apply_20260623_063535.out`,
  and
  `docs/hermes-analysis/master_optimizer_reports/deck606_l2_hash_scope_restore_pg078_postcheck_20260623_063535.out`.
- Postcheck facts: `target_rule_rows=23`, `target_hash_match_rows=23`,
  `target_missing_hash_rows=0`, `trusted_auto_rows=23`,
  `active_shadow_rows=0`, `disabled_shadow_rows=44`, and
  `total_backup_rows=67`.
- SQLite/canonical snapshot sync:
  `docs/hermes-analysis/master_optimizer_reports/pg078_l2_hash_scope_restore_sync_report_20260623_063535.json`
  reported `pg_rows_loaded=1824`, `sqlite_inserted_or_updated=1802`,
  `canonical_snapshot_rows_exported=3201`, and `pg_inserted_or_updated=0`
  because this step was sync-from-PG after the SQL apply.
- Focused event evidence:
  `docs/hermes-analysis/master_optimizer_reports/deck606_pg078_l2_hash_scope_restore_focused_events_20260623_063535.jsonl`
  contains 17 records for selected restored rule key/hash runtime provenance.
- Current accepted card-gate cuts: deck `6` `high=0`, `medium=0`,
  `pass=100`; deck `606` `high=7`, `medium=7`, `pass=67`; global
  `high=50`, `medium=12`, `pass=143`.
- Test evidence: `test_battle_analyst_v10_3.py` now includes
  `test_pg078_deck606_l2_hash_scope_rules_resolve_from_sqlite`, and the full
  script passed after the focused event file was registered.
- Work remains: commit this batch, then run a fresh deck `6` 16-seed battle
  rebaseline. Do not treat PG078 as battle-strategy evidence by itself.

## ManaLoom PG078 battle preflight fix - 2026-06-23 06:50 UTC

- First deck `6` PG078 rebaseline attempt stopped during preflight at
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065035/test_battle_runtime_surface_manifest.log`.
- The failure was not a battle/replay result. The runtime surface manifest had
  two unclassified files from the new card-rule coherence audit surface.
- Fixed by classifying `deck_card_battle_rule_coherence_audit.py` and
  `test_deck_card_battle_rule_coherence_audit.py` under `rule registry/sync`
  and updating the expected total/category/coverage/gate counts.
- Validation passed:
  `test_battle_runtime_surface_manifest.py` and
  `battle_runtime_surface_manifest.py --fail-on-unclassified`.
- Next action remains: commit this harness fix, rerun deck `6`
  `deck6_pg078_rebaseline_16_seed` with `start_seed=64270200`.

## ManaLoom PG078 deck 6 rebaseline checkpoint - 2026-06-23 07:32 UTC

- Accepted run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_072754/summary.json`.
- Scope: harness/replay checkpoint only. No PostgreSQL apply, no deck swap, no
  `deck_cards` mutation.
- Runtime/harness fixes validated: flashback targeted removal target
  declaration, Land Tax decision-trace comparison option, spell-copy resolution
  provenance, and action-critic handling for same-name spell copies.
- Gate result: `action_critic=pass`, `forensic_audit=pass`,
  `replay_decision_audit=pass`, `event_contract_static=pass`,
  `decision_trace_taxonomy=pass`, `table_intent=pass`, and
  `target_pressure=pass` across 16 seeds from `64270200`.
- Card-coherence auditor rerun at `20260623_073004`: deck `6` `pass=100`,
  deck `606` `high=7`, `medium=7`, `pass=67`, and global `high=50`,
  `medium=12`, `pass=143`.
- Final aggregate is `trusted_for_strategy_learning`. `strategy_audit` still
  records two medium low-confidence findings (`forced_keep_after_bad_mulligan`
  on seeds `64270204` and `64270207`), but
  `strategy_review_required_findings=0`.
- Next work: keep PG079 for the next real PostgreSQL card-rule package and
  continue deck `606` high battle-critical queue.

## ManaLoom PG079 deck 606 high battle-critical card gate - 2026-06-23 08:01 UTC

- PG079 was applied and validated for the seven deck `606` high
  battle-critical rules: `Flare of Duplication`, `Powerbalance`,
  `Reforge the Soul`, `Rise of the Eldrazi`, `Rite of the Dragoncaller`,
  `Storm Herd`, and `Witch Enchanter // Witch-Blessed Meadow`.
- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/deck606_high_battle_critical_pg079_precheck_20260623_074912.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck606_high_battle_critical_pg079_apply_20260623_074912.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck606_high_battle_critical_pg079_postcheck_20260623_074912.out`,
  and rollback
  `docs/hermes-analysis/master_optimizer_reports/deck606_high_battle_critical_pg079_rollback_20260623_074912.sql`.
- Postcheck facts: seven target rows matched expected `oracle_hash` and
  `battle_model_scope`; zero target rows were missing hashes; seven generated
  shadow rows were disabled; backup table
  `manaloom_deploy_audit.pg079_deck606_high_battle_critical_20260623_074912`
  has 14 rows.
- PG -> SQLite/canonical sync:
  `docs/hermes-analysis/master_optimizer_reports/pg079_deck606_high_battle_critical_sync_report_20260623_075404.json`
  reported `pg_rows_loaded=1824`, `sqlite_inserted_or_updated=1802`, and
  `canonical_snapshot_rows_exported=3201`.
- Focused event evidence:
  `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl`
  contains 19 rows proving all seven PG079 logical rule keys.
- Tests passed:
  `py_compile`, `test_deck_card_battle_rule_coherence_audit.py -v`, and
  `test_battle_analyst_v10_3.py`.
- Post-test audits: deck `6` `pass=100`; deck `606` `high=0`, `medium=7`,
  `pass=74`; global `high=43`, `medium=11`, `pass=151`.
- Method reminder: user observations, including `Blasphemous Act`, are
  validation hints only. Do not promote or reopen a card without
  Oracle/PostgreSQL/runtime evidence.
- Next package number is PG080. Next queue: deck `606`
  `medium/battle_support` cards `Monologue Tax`, `Mox Opal`, and
  `Simian Spirit Guide`.

## ManaLoom PG080 deck 606 L3 mana/ramp card gate - 2026-06-23 08:20 UTC

- PG080 was applied and validated for the three deck `606` L3 mana/ramp
  support rules: `Monologue Tax`, `Mox Opal`, and `Simian Spirit Guide`.
- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/deck606_l3_mana_ramp_pg080_precheck_20260623_081220.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck606_l3_mana_ramp_pg080_apply_20260623_081220.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck606_l3_mana_ramp_pg080_postcheck_20260623_081220.out`,
  and rollback
  `docs/hermes-analysis/master_optimizer_reports/deck606_l3_mana_ramp_pg080_rollback_20260623_081220.sql`.
- Postcheck facts: three target rows matched expected `oracle_hash` and
  `battle_model_scope`; zero target rows were missing hashes; three generated
  shadow rows were disabled; backup table
  `manaloom_deploy_audit.pg080_deck606_l3_mana_ramp_20260623_081220` has six
  rows.
- PG -> SQLite/canonical sync:
  `docs/hermes-analysis/master_optimizer_reports/pg080_l3_mana_ramp_sync_report_20260623_081412.json`
  reported `pg_rows_loaded=1824`, `sqlite_inserted_or_updated=1805`, and
  `canonical_snapshot_rows_exported=3201`.
- Focused event evidence:
  `docs/hermes-analysis/master_optimizer_reports/deck606_pg080_l3_mana_ramp_focused_events_20260623_052022.jsonl`
  contains three rows proving all three PG080 logical rule keys.
- Tests passed: `test_deck_card_battle_rule_coherence_audit.py -v`,
  `test_battle_analyst_v10_3.py`, and `py_compile` for the touched runtime,
  test, and audit scripts.
- Post-test audits: deck `6` `pass=100`; deck `606` `high=0`, `medium=4`,
  `pass=77`; global `high=43`, `medium=8`, `pass=154`.
- Next package number is PG081. Next queue: deck `606`
  `medium/support_or_passive` hash-only cleanup: `Hexing Squelcher`,
  `Ragavan, Nimble Pilferer`, `Skyclave Apparition`, and `Underworld Breach`.

## ManaLoom PG079 deck 606 high battle-critical closeout - 2026-06-23 08:00 UTC

- PG079 closed the seven deck `606` high battle-critical rows:
  `Flare of Duplication`, `Powerbalance`, `Reforge the Soul`,
  `Rise of the Eldrazi`, `Rite of the Dragoncaller`, `Storm Herd`, and
  `Witch Enchanter // Witch-Blessed Meadow`.
- The semantic apply package was already present in PostgreSQL before the
  central-auditor hash restore step ran. Treat
  `docs/hermes-analysis/master_optimizer_reports/deck606_high_battle_critical_pg079_apply_20260623_074912.out`
  and
  `docs/hermes-analysis/master_optimizer_reports/deck606_high_battle_critical_pg079_postcheck_20260623_074912.out`
  as the primary semantic apply evidence for those seven cards.
- Central-auditor follow-up PG079 restored remaining scoped trusted
  `oracle_hash` provenance without overwriting the richer target metadata:
  `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_apply_20260623_044955.out`
  committed `111` backed-up rows and postcheck reported
  `target_hash_match_rows=7`, `target_required_semantic_fields_rows=7`,
  `scoped_trusted_auto_missing_hash_rows=0`, and `backup_rows=111`.
- `Seething Song` required a PG079 addendum after the sync exposed a PG058
  runtime metadata drift. Evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg079_seething_song_metadata_restore_postcheck_20260623_045814.out`.
- PG -> SQLite/canonical snapshot syncs:
  `docs/hermes-analysis/master_optimizer_reports/pg079_runtime_semantics_sync_report_20260623_044955.json`
  and
  `docs/hermes-analysis/master_optimizer_reports/pg079_runtime_semantics_sync_report_after_seething_20260623_045814.json`,
  both with `pg_rows_loaded=1824`, `sqlite_inserted_or_updated=1802`, and
  `canonical_snapshot_rows_exported=3201`.
- Focused runtime evidence:
  `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl`
  and
  `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl`.
- Tests passed: `py_compile`,
  `test_sync_battle_card_rules_pg_selection.py -v`,
  `test_deck_card_battle_rule_coherence_audit.py -v`, and the full
  `test_battle_analyst_v10_3.py`, including
  `test_pg079_deck606_high_rules_resolve_from_sqlite_cache` and all focused
  `test_pg079_*` regressions.
- Accepted post-PG079 card-gate cuts: deck `6` `pass=100`; deck `606`
  `high=0`, `medium=7`, `pass=74`; deck `607` `high=26`, `medium=5`,
  `pass=63`; deck `608` `high=20`, `medium=3`, `pass=45`; global
  `high=43`, `medium=11`, `pass=151`.
- Next PostgreSQL package number: PG080. Next card-rule queue should start
  with shared deck `607`/`608` high cards (`Artist's Talent`,
  `Pinnacle Monk // Mystic Peak`, and `Redirect Lightning`) before single-deck
  lower-impact rows.

## ManaLoom PG082 deck 6/606 hash-only provenance gate - 2026-06-23 08:37 UTC

- PG082 restored missing `oracle_hash` provenance for five already scoped
  trusted executable rows: `Library of Leng`, `Scroll Rack`,
  `Unexpected Windfall`, `Valakut Awakening // Valakut Stoneforge`, and
  `Wayfarer's Bauble`.
- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/deck6_606_hash_only_pg082_precheck_20260623_083100.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck6_606_hash_only_pg082_apply_20260623_083100.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck6_606_hash_only_pg082_postcheck_20260623_083100.out`,
  and rollback
  `docs/hermes-analysis/master_optimizer_reports/deck6_606_hash_only_pg082_rollback_20260623_083100.sql`.
- Postcheck facts: five target rows matched expected `oracle_hash`; zero target
  rows were missing hashes; zero generated shadow rows were active; backup
  table `manaloom_deploy_audit.pg082_deck6_606_hash_only_20260623_083100`
  has 15 rows.
- PG -> SQLite/canonical sync:
  `docs/hermes-analysis/master_optimizer_reports/pg082_hash_only_final_sync_report_20260623_083100.json`
  reported `pg_rows_loaded=1824`, `sqlite_inserted_or_updated=1802`, and
  `canonical_snapshot_rows_exported=3201`.
- Focused event evidence:
  `docs/hermes-analysis/master_optimizer_reports/deck6_606_pg082_hash_only_focused_events_20260623_083100.jsonl`
  contains 10 rows proving all five PG082 logical rule keys/hashes.
- Tests passed: `py_compile`, `test_deck_card_battle_rule_coherence_audit.py
  -v`, and `test_battle_analyst_v10_3.py`.
- Post-test audits: deck `6` `pass=100`; deck `606` `high=0`, `medium=4`,
  `pass=77`; global `high=40`, `medium=8`, `pass=157`.
- Next package number is PG083. Next deck `606` cards are semantic review, not
  hash-only: `Hexing Squelcher`, `Ragavan, Nimble Pilferer`,
  `Skyclave Apparition`, and `Underworld Breach`.

## ManaLoom PG081-PG085 runtime/provenance closeout - 2026-06-23 08:38 UTC

- PG081 was applied and validated for shared deck `607`/`608` high-card rules:
  `Artist's Talent`, `Pinnacle Monk // Mystic Peak`, and `Redirect Lightning`.
  Runtime support was added for Artist's Talent rummage, Pinnacle Monk
  instant/sorcery graveyard recursion, and Redirect Lightning target
  redirection.
- PG082 has two validated packages: the central `Silence` hash restore and the
  adopted deck `6`/`606` hash-only package for `Library of Leng`,
  `Scroll Rack`, `Unexpected Windfall`,
  `Valakut Awakening // Valakut Stoneforge`, and `Wayfarer's Bauble`.
- PG083 restored runtime hashes for `Fellwar Stone`, `Mana Vault`,
  `Mox Amber`, `Talisman of Conviction`, and `Seething Song`.
- PG084 restored `Seething Song` runtime metadata after the sync exposed the
  missing `mana_color_status`, `oracle_runtime_scope`, and
  `pg058_l3b_simple_red_ritual_family` markers.
- PG085 is a checkpoint only. No PG085 apply was performed because the intended
  hash targets had already been handled by the validated PG082 package.
- PostgreSQL remained the source of truth. SQLite and
  `known_cards_canonical_snapshot.json` were refreshed through sync reports
  after the validated PostgreSQL packages.
- No deck swap, no `deck_cards` mutation, and no learned-deck promotion was
  performed in this closeout.

Evidence:

- PG081 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck607_608_shared_high_pg081_postcheck_20260623_082229.out`.
- PG082 postchecks:
  `docs/hermes-analysis/master_optimizer_reports/deck6_silence_hash_restore_pg082_postcheck_20260623_082754.out`
  and
  `docs/hermes-analysis/master_optimizer_reports/deck6_606_hash_only_pg082_postcheck_20260623_083100.out`.
- PG083 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/runtime_hash_restore_pg083_postcheck_20260623_083050.out`.
- PG084 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/seething_song_runtime_metadata_pg084_postcheck_20260623_083303.out`.
- Final sync checkpoint:
  `docs/hermes-analysis/master_optimizer_reports/pg085_after_concurrent_hash_restore_sync_report_20260623_083535.json`.
- Final audits:
  deck `6` `pass=100`; deck `606` `high=0`, `medium=4`, `pass=77`;
  deck `607` `high=23`, `medium=5`, `pass=66`; deck `608` `high=17`,
  `medium=3`, `pass=48`; global `high=40`, `medium=8`, `pass=157`.
- Full runtime wrapper passed after the closeout:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  with 371 tests.

Next package number is PG086. Next queue should prioritize remaining deck
`607`/`608` high battle-critical cards before any new battle-ranking claim.

## ManaLoom PG087/PG088 deck 606 remaining semantic gate - 2026-06-23 09:03 UTC

- PG087 closed the remaining deck `606` card-rule coherence queue:
  `Hexing Squelcher`, `Ragavan, Nimble Pilferer`,
  `Skyclave Apparition`, and `Underworld Breach`.
- These four were validated as semantic-specific rules, not hash-only:
  PostgreSQL now stores card-specific `logical_rule_key`,
  `battle_model_scope`, and runtime/annotation split fields. PG088 corrected
  their `oracle_hash` values to the raw `oracle_text` md5 convention.
- Runtime scope:
  Hexing's uncounterable/static counter shield is executable through the
  counter target filter; Skyclave ETB exile is executable with nonland,
  nontoken, mana-value <= 4 target filtering. Ragavan combat-damage
  Treasure/impulse/dash and Underworld Breach escape/end-step sacrifice are
  explicit annotations.
- PG087 semantic evidence:
  `docs/hermes-analysis/master_optimizer_reports/deck606_remaining_semantic_pg087_postcheck_20260623_085349.out`
  closed `target_rule_rows=4`, `target_hash_match_rows=4` under the original
  normalized-hash convention,
  `target_missing_hash_rows=0`, `non_disabled_shadow_rows=0`, and
  `backup_rows=8`.
- PG088 hash evidence:
  `docs/hermes-analysis/master_optimizer_reports/deck606_pg087_hash_convention_fix_pg088_postcheck_20260623_090018.out`
  reported four raw-hash matches and `backup_rows=4`.
- Sync:
  `docs/hermes-analysis/master_optimizer_reports/pg088_deck606_hash_convention_fix_sync_report_20260623_090018.json`
  reported `pg_rows_loaded=1824`, `sqlite_inserted_or_updated=1802`, and
  `canonical_snapshot_rows_exported=3201`.
- Focused event evidence:
  `docs/hermes-analysis/master_optimizer_reports/deck606_pg088_remaining_semantic_focused_events_20260623_090018.jsonl`.
- Tests passed:
  `py_compile`, `test_deck_card_battle_rule_coherence_audit.py -v`, and
  `test_battle_analyst_v10_3.py`.
- Accepted audits after PG088: deck `6` `pass=100`; deck `606` `pass=81`;
  deck `608` `high=16`, `medium=3`, `pass=49`; global `high=39`,
  `medium=4`, `pass=162`.
- PG086 was already occupied by deck `608` `Angel's Grace` artifacts during
  this cycle, and PG088 subsequently corrected the PG087 hash convention. At
  that checkpoint, PG089 was the next package.
- A read-only PG089 start snapshot was generated after the PG088 sync:
  `docs/hermes-analysis/master_optimizer_reports/pg089_start_sync_report_20260623_061026.json`,
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg089_start_20260623_061026.json`,
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_pg089_start_20260623_061026.json`,
  and
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_pg089_start_20260623_061026.json`.
  It is not a deploy; it confirms deck `6` `pass=100`, deck `606` `pass=81`,
  and global `high=39`, `medium=4`, `pass=162` before the next PG089 write.
- PG089 runtime prework added creature compensation-token execution for targeted
  removal effects and focused test
  `test_pg089_removal_compensation_creature_tokens_are_created_for_target_controller`.
  The initial runtime-only wrapper passed with `379` PASS lines before the
  PostgreSQL closeout; the accepted final state is the PG090-restored wrapper
  result below.
- PG089 then closed `Generous Gift` and `Stroke of Midnight` with PostgreSQL
  postcheck evidence at
  `docs/hermes-analysis/master_optimizer_reports/deck607_l6_removal_compensation_pg089_postcheck_20260623_061026.out`
  and focused events at
  `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_062000.jsonl`.
- PG089 sync exposed older hash/scope drift in PostgreSQL; PG090 restored 12
  already-approved rules. Evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg090_rule_hash_scope_restore_20260623_062000_postcheck.out`
  and
  `docs/hermes-analysis/master_optimizer_reports/pg090_rule_hash_scope_restore_sync_report_20260623_062000.json`.
- Final post-PG090 state: deck `607` `high=21`, `medium=4`, `pass=69`;
  deck `608` `high=16`, `medium=3`, `pass=49`; global `high=37`,
  `medium=4`, `pass=164`; full wrapper passed with `380` PASS lines.
- A read-only PG091 start snapshot was generated after the PG090 sync:
  `docs/hermes-analysis/master_optimizer_reports/pg091_start_sync_report_20260623_manual.json`,
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg091_start_20260623_093259.json`,
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_pg091_start_20260623_093259.json`,
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_pg091_start_20260623_093259.json`,
  and
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck608_pg091_start_20260623_093259.json`.
  It is not a deploy; it confirms deck `6` `pass=100`, deck `606`
  `pass=81`, deck `607` `high=21`, `medium=4`, `pass=69`, and deck `608`
  `high=16`, `medium=3`, `pass=49` as the next cycle baseline.
- PG091 closed the deck `607` token-maker family:
  `Furygale Flocking`, `Prismari Pianist`, and `Tempt with Bunnies`.
  Evidence:
  `docs/hermes-analysis/master_optimizer_reports/deck607_token_maker_family_pg091_postcheck_20260623_093259.out`,
  `docs/hermes-analysis/master_optimizer_reports/pg091_deck607_token_maker_family_sync_report_20260623_093259.json`,
  and
  `docs/hermes-analysis/master_optimizer_reports/deck607_pg091_token_maker_family_focused_events_20260623_093259.jsonl`.
  The runtime now supports token subtype/color metadata, token count by
  opponent count, composed token plus draw resolution, and instant/sorcery
  trigger token counts by spell mana value. User observations about individual
  cards remain audit hints only, not rule sources. Final post-PG091 state:
  deck `607` `high=18`, `medium=4`, `pass=72`; deck `608` `high=16`,
  `medium=3`, `pass=49`; global `high=34`, `medium=4`, `pass=167`.
  PG092 is next.
- PG092 read-only start snapshot was then generated:
  `docs/hermes-analysis/master_optimizer_reports/pg092_start_sync_report_20260623_101000.json`
  plus deck `6`/`606`/`607`/`608`/global PG092 start audits. It did not write
  PostgreSQL and preserves the same counts as the PG091 closeout. The full
  current-state wrapper passed at
  `docs/hermes-analysis/master_optimizer_reports/pg092_start_test_battle_analyst_v10_3_20260623_101200.out`.
- PG092 then closed two deck `608` high L7 modal interaction findings:
  `Return the Favor` and `Untimely Malfunction`. Evidence:
  `docs/hermes-analysis/master_optimizer_reports/deck608_l7_modal_interaction_pg092_postcheck_20260623_095405.out`,
  `docs/hermes-analysis/master_optimizer_reports/pg092_deck608_l7_modal_interaction_sync_report_20260623_095405.json`,
  and
  `docs/hermes-analysis/master_optimizer_reports/deck608_pg092_l7_modal_interaction_focused_events_20260623_095405.jsonl`.
  The executable subset for `Return the Favor` is stack-copy of instant/sorcery
  spells; spree costs, activated/triggered ability copying, and target-change
  mode remain annotations. The executable subset for `Untimely Malfunction` is
  destroy target artifact; redirect and can't-block modes remain annotations.
  Post-PG092 applied state: deck `6` `pass=100`, deck `606` `pass=81`,
  deck `608` `high=14`, `medium=3`, `pass=51`, and global `high=32`,
  `medium=4`, `pass=169`.
- PG093 closed deck `607` `Insurrection` as a scoped compact runtime rule.
  Evidence:
  `docs/hermes-analysis/master_optimizer_reports/deck607_insurrection_pg093_postcheck_20260623_100709.out`,
  `docs/hermes-analysis/master_optimizer_reports/pg093_insurrection_sync_report_20260623_100709.json`,
  and
  `docs/hermes-analysis/master_optimizer_reports/deck607_pg093_insurrection_focused_events_20260623_100709.jsonl`.
  Current rerun evidence:
  `docs/hermes-analysis/master_optimizer_reports/deck607_insurrection_pg093_postcheck_rerun_current_20260623_101800.out`,
  `docs/hermes-analysis/master_optimizer_reports/pg093_insurrection_sync_report_rerun_current_20260623_101800.json`,
  `docs/hermes-analysis/master_optimizer_reports/deck607_pg093_insurrection_focused_events_current_20260623_101800.jsonl`,
  and
  `docs/hermes-analysis/master_optimizer_reports/pg093_test_battle_analyst_v10_3_20260623_101800.out`
  with 387 PASS lines.
  The rule now carries raw Oracle hash
  `a756d0c90be63a18b7eaf97582e75b8e`, scope
  `steal_all_creatures_until_eot_haste_attack_projection_v1`, and runtime
  model `compact_damage_projection`. The limitation is explicit: the engine
  projects stolen-creature combat damage and does not yet transfer objects onto
  Lorehold's battlefield for a full EOT control lifecycle. Post-PG093 current
  state: deck `6` `pass=100`, deck `606` `pass=81`, deck `607` `high=17`,
  `medium=4`, `pass=73`, deck `608` `high=14`, `medium=3`, `pass=51`, and
  global `high=31`, `medium=4`, `pass=170`. PG094 is next.
- PG094 restored 12 already-approved card-rule rows whose canonical
  hash/scope/effect/status metadata drifted after the PG -> SQLite/canonical
  sync path. Evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg094_hash_scope_restore_postcheck_20260623_102141.out`
  reports `target_rule_rows=12`, `hash_restored_rows=12`,
  `effect_json_restored_rows=12`, `status_restored_rows=12`, and
  `backup_rows=12`.
  PG -> SQLite/canonical sync:
  `docs/hermes-analysis/master_optimizer_reports/pg094_hash_scope_restore_sync_report_20260623_102141.json`
  reported `pg_rows_loaded=1829`, `sqlite_inserted_or_updated=1807`, and
  `canonical_snapshot_rows_exported=3201`. Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/pg094_hash_scope_restore_focused_events_20260623_102141.jsonl`.
  Full wrapper output:
  `docs/hermes-analysis/master_optimizer_reports/pg094_test_battle_analyst_v10_3_20260623_102141.out`.
  Current post-PG094 state: deck `6` `pass=100`, deck `606` `pass=81`,
  deck `607` `high=17`, `medium=4`, `pass=73`, deck `608` `high=14`,
  `medium=3`, `pass=51`, and global `high=31`, `medium=4`, `pass=170`.
  PG095 then closed `Winds of Abandon` as an Oracle-specific Sorcery
  single-target exile rule. Evidence:
  `docs/hermes-analysis/master_optimizer_reports/winds_of_abandon_battle_rule_pg095_postcheck_20260623_105512.out`,
  `docs/hermes-analysis/master_optimizer_reports/pg095_winds_of_abandon_runtime_sync_report_20260623_105512.json`,
  and
  `docs/hermes-analysis/master_optimizer_reports/winds_of_abandon_pg095_focused_events_20260623_105512.jsonl`.
  The rule key is `battle_rule_v1:4f844346b4b2b03ff68c2935fd399f9c`,
  raw Oracle hash `05e38c4458b7b803d038978b46f11f72`, and scope
  `winds_of_abandon_opponent_creature_exile_basic_land_overload_annotation_v1`.
  Basic-land search/tapped placement and overload rewrite remain
  `annotation_only`. Final runtime sync used `include_needs_review=false`;
  deck `607` moved to `high=16`, `medium=4`, `pass=74`, and global moved to
  `high=30`, `medium=4`, `pass=171`.
- PG096A corrected `High Noon` in deck `607`: the previous trusted runtime row
  falsely modeled it as `remove_creature`. The new curated rule is
  `battle_rule_v1:fca6c4be65cae378901514ff6c8417d1`, raw Oracle hash
  `dfec584c3cfdf4eb34b8a1e1d4f7da3a`, `effect=passive`, and scope
  `high_noon_one_spell_per_turn_static_activated_five_damage_annotation_v1`.
  Static one-spell-per-turn and activated five-damage modes are
  `annotation_only`; runtime proof
  `docs/hermes-analysis/master_optimizer_reports/high_noon_pg096_focused_events_20260623_112650.jsonl`
  show `High Noon` resolving to battlefield with zero removal events.
  PG096B restored hash/effect/status metadata for 12 already-approved deck
  `6`/`606` rules. Final PG -> SQLite sync used `include_needs_review=false`;
  post-PG096 state: deck `6` `pass=100`, deck `606` `pass=81`, deck `607`
  `high=15`, `medium=4`, `pass=75`, deck `608` `high=14`, `medium=3`,
  `pass=51`, and global `high=29`, `medium=4`, `pass=172`. PG097 followed as
  the next package.
- PG097 restored the simple-name `Valakut Awakening` rule provenance after a
  PG -> SQLite/canonical sync exposed that the simple row lacked the reviewed
  `oracle_hash`. The applied row is
  `battle_rule_v1:245b8d2627720fadfd7a30464d07605a`,
  `oracle_hash=22b42fcc181b7aed71f78b2e1e51e887`, `review_status=active`,
  `execution_status=auto`, and scope `bottom_then_draw_plus_one_v1`. The split
  MDFC rule remained intact with scope `bottom_then_draw_plus_one_mdfc_land_v1`.
  Code guards now preserve SQLite `oracle_hash` on incoming missing-hash rows
  and fill same-key reviewed hash/scope metadata during PG + reviewed runtime
  merge. Evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg097_valakut_simple_hash_restore_postcheck_20260623_113918.out`,
  `docs/hermes-analysis/master_optimizer_reports/pg097_valakut_simple_hash_restore_sync_report_20260623_114030.json`,
  and
  `docs/hermes-analysis/master_optimizer_reports/pg097_valakut_sync_guard_test_battle_analyst_v10_3_20260623_114030.out`.
  Post-PG097 state is unchanged for card-rule queue counts: deck `6`
  `pass=100`, deck `606` `pass=81`, deck `607` `high=15`, `medium=4`,
  `pass=75`, deck `608` `high=14`, `medium=3`, `pass=51`, and global
  `high=29`, `medium=4`, `pass=172`. PG098 is next.

## ManaLoom PG086 Angel's Grace card-rule provenance - 2026-06-23 08:52 UTC

- PG086 was applied and validated for `Angel's Grace` in deck `608`.
- The existing verified `cannot_lose_turn` runtime rule was completed with
  `oracle_hash=627c4ce7adf5be44b93e2b850159e5d9`,
  `battle_model_scope=split_second_cannot_lose_opponents_cannot_win_damage_life_floor_v1`,
  `oracle_runtime_scope=cannot_lose_opponents_cannot_win_damage_life_floor_split_second_annotation`,
  `split_second=true`, and `opponents_cant_win_this_turn=true`.
- Two generated `silence_opponents` shadow rows were disabled.
- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/deck608_angels_grace_pg086_precheck_20260623_084922.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck608_angels_grace_pg086_apply_20260623_084922.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck608_angels_grace_pg086_postcheck_20260623_084922.out`,
  and rollback
  `docs/hermes-analysis/master_optimizer_reports/deck608_angels_grace_pg086_rollback_20260623_084922.sql`.
- PG -> SQLite/canonical sync:
  `docs/hermes-analysis/master_optimizer_reports/pg086_angels_grace_sync_report_20260623_084922.json`
  reported `pg_rows_loaded=1824`, `sqlite_inserted_or_updated=1802`, and
  `canonical_snapshot_rows_exported=3201`.
- Added provenance regression:
  `test_pg086_angels_grace_rule_resolves_from_sqlite_cache`.
- Post-PG086 audits: deck `608` moved to `high=16`, `medium=3`, `pass=49`;
  deck `607` remained `high=23`, `medium=5`, `pass=66`; global moved to
  `high=39`, `medium=8`, `pass=158`.
- Runtime prework also landed for future PG087 candidates, without PostgreSQL
  promotion yet: counter targeting now respects explicit uncounterable/static
  shield metadata, and removal target selection can filter non-token permanents
  by maximum mana value. This is aligned with the current Oracle gaps for
  `Hexing Squelcher` and `Skyclave Apparition`, but those two cards still
  remain pending until a PG087 precheck/apply/postcheck/rollback package exists.
- This was a card-rule/cache gate only. It did not create a new multi-seed
  battle baseline and did not mutate `deck_cards`.
- At that PG086 checkpoint, the next package number was PG087; this was
  superseded by the PG087/PG088 deck `606` checkpoint above. Current next
  package number is PG089.
