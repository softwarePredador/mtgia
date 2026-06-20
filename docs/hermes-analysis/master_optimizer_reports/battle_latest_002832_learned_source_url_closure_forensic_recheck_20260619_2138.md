# Battle Latest 002832 Learned Source URL Closure and Forensic Recheck

Status: closes BV-075; BV-067 remains open.

Scope: read-only audit of the recurring battle-strategy artifact
`20260620_002832`. No PostgreSQL query, database mutation, code change, deck
swap, commit, or push was performed.

## Primary Evidence

- Latest artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_002832`.
- `summary.json` timestamp: `2026-06-20T00:28:32Z`.
- `battle_replay_final_status=blocked`.
- `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- `mandatory_gate_statuses.forensic_audit.status=blocked`.
- `mandatory_gate_statuses.forensic_audit.blocking_seeds=["63210031"]`.
- `forensic_rule_findings=2`.
- `forensic_severity_counts={"high":1,"medium":1}`.
- `seeds_with_high_or_critical_forensic_findings=["63210031"]`.
- `action_findings=0`,
  `seeds_with_high_or_critical_action_findings=[]`, and
  `seeds_with_strategy_blockers=[]`.

## BV-075 Closure Evidence

The learned-opponent aggregate now satisfies the stable source identity
criterion:

- `learned_deck_opponents` is present.
- `opponent_deck_provenance.status=learned_opponent_provenance_present_with_shape_waiver`.
- `opponent_deck_provenance.learned_opponent_appearance_count=48`.
- `opponent_deck_provenance.learned_opponent_unique_count=12`.
- `opponent_deck_provenance.source_url_missing_count=0`.
- `learned_opponent_source_counts={"pg_meta_decks":48}`.
- All `12` learned-opponent rows have a `source_url` beginning with
  `pg:meta_decks:`.

Sample row:

- `source_ref=learned_deck:104`
- `source_system=pg_meta_decks`
- `source_row_id=104`
- `source_url=pg:meta_decks:33899d41-c1e5-4827-8145-d370360cdf7e`
- `name="Kinnan, Bonder Prodigy #104 (real)"`
- `provenance_status=source_identity_and_shape_present_with_coherence_waiver`
- `construction_status=waived_not_emitted_by_replay_deck_provenance`
- `deck_coherence_status=waived_not_emitted_by_replay_deck_provenance`

Result: `BV-075` can leave the open table. The result principal now lists the
learned opponents with both local replay identity (`source_ref`/`source_row_id`)
and stable PG meta-deck identity (`source_url`), while preserving the explicit
construction/coherence waiver.

## BV-067 Recheck

The latest remains blocked by the same forensic issue:

- Seed `63210031`, turn `10`, player `Tayam, Luminous Enigma #25 (real)`.
- `Aura of Silence` executes through `rule_source=functional_tags_json`,
  `rule_review_status=heuristic`, `rule_confidence=0.35`,
  `effect=remove_permanent`.
- `spell_cast` is medium severity and `spell_resolved` is high severity.
- `forensic_card_id_missing_unaccepted=2`.
- `forensic_semantic_hash_missing_unaccepted=2`.
- `forensic_lineage_unaccepted_missing_samples` lists `Aura of Silence` missing
  `card_id` and `semantic_hash` on `spell_cast` and `spell_resolved`.

Result: `BV-067` remains the only current open issue in this audit register.
The battle replay is not trusted for strategy learning until the forensic gate
passes or an explicit waiver is documented and tested.
