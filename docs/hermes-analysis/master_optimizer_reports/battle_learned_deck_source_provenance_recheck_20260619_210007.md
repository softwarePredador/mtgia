# Battle learned deck source provenance recheck 2026-06-19T21:00:07Z

## Escopo

- Validacao somente leitura do latest recorrente:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest`.
- Sem alteracao de PostgreSQL.
- Sem swaps.
- Sem commit ou staging.
- Objetivo: conferir se o resultado principal permite auditar decks learned usados
  em battle, especialmente os oponentes.

## Resultado do latest

- Latest real: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826`.
- `timestamp_utc=2026-06-19T20:48:26Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `seeds_requested=16`, `seeds_completed=16`.
- `seeds_with_high_or_critical_action_findings=[]`.
- `seeds_with_strategy_blockers=[]`.
- `seeds_with_high_or_critical_forensic_findings=[]`.
- `strategy_learning_confidence_counts={"high_confidence_replay":14,"low_confidence_replay":2}`.
- `strategy_low_confidence_seeds=["63202025","63202031"]`.
- `deck_source_blocker_domains={"none":64}`.

## Deck provenance observado

O `summary.json` principal agrega a politica geral e os campos do deck Lorehold:

- `lorehold_deck_source_kind=sqlite_deck_cards`.
- `lorehold_deck_source_ref=deck_id:6`.
- `lorehold_deck_metrics_basis=runtime_derived_from_resolved_card_list`.
- `lorehold_deck_cached_metadata_used_for_metrics=false`.
- `lorehold_deck_lands=33`.
- `lorehold_deck_avg_cmc_nonlands=2.97`.

Nos `seed_*/deck_provenance.json`, todos os oponentes observed no latest sao:

- `source_kind=learned_decks`.
- `source_system=pg_meta_decks`.
- `source_card_count=100`.
- `battle_card_count=99`.
- `metrics_basis=runtime_derived_from_resolved_built_deck`.
- `cached_metadata_used_for_metrics=false`.
- `blocker_domain=none`.
- sem `construction_report`.

Oponentes learned observados no latest:

- `learned_deck:104` - `Kinnan, Bonder Prodigy #104 (real)` - 6 aparicoes.
- `learned_deck:105` - `Etali, Primal Conqueror #105 (real)` - 5 aparicoes.
- `learned_deck:116` - `Tayam, Luminous Enigma #116 (real)` - 4 aparicoes.
- `learned_deck:25` - `Tayam, Luminous Enigma #25 (real)` - 3 aparicoes.
- `learned_deck:31` - `Sisay, Weatherlight Captain #31 (real)` - 1 aparicao.
- `learned_deck:42` - `The Emperor of Palamecia #42 (real)` - 2 aparicoes.
- `learned_deck:54` - `Thrasios, Triton Hero #54 (real)` - 4 aparicoes.
- `learned_deck:58` - `Thrasios, Triton Hero #58 (real)` - 2 aparicoes.
- `learned_deck:62` - `Rograkh, Son of Rohgahh #62 (real)` - 5 aparicoes.
- `learned_deck:74` - `Dargo, the Shipwrecker #74 (real)` - 3 aparicoes.
- `learned_deck:83` - `Kraum, Ludevic's Opus #83 (real)` - 7 aparicoes.
- `learned_deck:84` - `Kinnan, Bonder Prodigy #84 (real)` - 6 aparicoes.

## Evidencia de ambiguidade de lineage

O audit de coerencia learned-deck mais recente:

- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260619_205609.json`.
- `generated_at=2026-06-19T20:56:07.193427+00:00`.
- `read_only=true`.
- `active_learned_decks=60`.
- `severity_counts.high=173`, `severity_counts.medium=21`.
- `by_source.pg_meta_decks.high=158`, `by_source.pg_meta_decks.medium=18`.

Esse audit mostra `source_system=pg_meta_decks`, `source_ref=learned_deck:116`
como `K-9, Mark I + The Fourteenth Doctor`, com:

- `issues` high para `off_color_cards`, `metadata_total_lands_mismatch`,
  `metadata_zero_lands` e `all_core_metadata_zero`.
- `commander_identity_model.status=combined_identity_manual_review`.
- `commander_deck_shape.passes_shape=false`.

No latest de battle, `source_system=pg_meta_decks`, `source_ref=learned_deck:116`
aparece como `Tayam, Luminous Enigma #116 (real)`.

Leitura conservadora: nao concluir que o battle usou o deck errado a partir disso
sozinho. O ponto validado e que `source_ref` isolado nao e uma chave suficiente
para handoff humano ou consumo downstream. O artefato precisa carregar e resumir a
origem completa do oponente, e os checks precisam ser chaveados por
`source_system + source_ref + name` ou por identificador persistente inequivoco.

## Gap

O battle atual passa os mandatory gates, mas o resultado principal nao permite
auditar, sem abrir todos os `deck_provenance.json`, quais learned decks oponentes
entraram no run, se eles tinham shape/commander/off-color status derivado, ou se
estavam associados a issues do audit de coerencia learned-deck.

No codigo:

- `battle_replay_v10_3.py` inclui `construction_report` no item Lorehold.
- Para oponente `source_kind=learned_decks`, o mesmo arquivo escreve
  `source_system`, `source_card_count`, `battle_card_count`, metricas derivadas e
  `blocker_domain=none`, mas nao escreve `construction_report` ou resumo de
  coerencia do deck oponente.
- `manaloom-battle-strategy-audit.sh` agrega `deck_source_blocker_domains` e
  campos Lorehold no `summary.json`, mas nao agrega lista/resumo de oponentes
  learned, `source_system`, `battle_card_count`, `source_card_count`,
  `construction_valid`, `commander_count` ou issues de coerencia por oponente.

## Risco

Um consumidor pode tratar o latest como "trusted" e aprender com partidas contra
oponentes learned sem saber, pelo `summary.json`, quais decks foram usados e se a
fonte desse deck tem alerta conhecido de metadata stale, commander identity, shape
ou off-color. Isso mistura ausencia de blocker da engine battle com ausencia de
problema de source deck.

## Recomendacao

- Expor no `summary.json` um bloco agregado para oponentes learned, por
  `source_system + source_ref + name`, com aparicoes, `source_card_count`,
  `battle_card_count`, `metrics_basis`, cached flag, blocker domain e status de
  construction/coherence quando disponivel.
- Para `battle_replay_v10_3.py`, adicionar `construction_report` ou
  `deck_coherence_report` tambem nos oponentes learned, mesmo que seja um resumo
  derivado/read-only.
- Se o audit de coerencia learned-deck for usado como apoio, nunca cruzar apenas
  por `learned_deck:<id>`; usar origem completa e nome/row id quando existir.
- Manter separacao explicita: problema de deck source/coerencia nao deve virar
  finding de engine battle sem criterio, mas precisa aparecer como warning/gate
  proprio de aprendizagem.

## Validacoes executadas

- `jq` no latest `summary.json` - PASS.
- `jq` agregado em `seed_*/deck_provenance.json` - PASS.
- `jq` no `learned_deck_coherence_audit_20260619_205609.json` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_learned_deck_completeness.py` - PASS, `Ran 4 tests ... OK`.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_materialize_learned_deck_to_deck_cards.py` - PASS, `Ran 1 test ... OK`.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_export_hermes_learned_deck_metadata.py` - PASS, `Ran 3 tests ... OK`.

