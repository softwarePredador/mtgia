# Battle Latest 002230 Forensic Blocker and Learned Provenance Delta

Status: current latest is blocked; BV-067 is active again; BV-075 remains
partially open.

Scope: read-only audit of the recurring battle-strategy artifact
`20260620_002230`. No PostgreSQL query, database mutation, code change, deck
swap, commit, or push was performed.

## Primary Evidence

- Latest artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_002230`.
- `summary.json` timestamp: `2026-06-20T00:22:30Z`.
- `battle_replay_final_status=blocked`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`.
- `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- `mandatory_gate_statuses.forensic_audit.status=blocked`.
- `mandatory_gate_statuses.forensic_audit.blocking_seeds=["63210031"]`.
- `forensic_rule_findings=2`, `forensic_turn_findings=0`.
- `forensic_severity_counts={"high":1,"medium":1}`.
- `seeds_with_high_or_critical_forensic_findings=["63210031"]`.
- `action_findings=0`,
  `seeds_with_high_or_critical_action_findings=[]`, and
  `seeds_with_strategy_blockers=[]`.
- `global_learning_eligible_seeds=[]`; all `16` seeds are listed in
  `global_not_learning_eligible_seeds` because the final status is blocked.

## BV-067 Reopened Evidence

The blocking seed is `63210031`.

Artifacts checked:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_002230/seed_63210031/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_002230/seed_63210031/forensic_audit.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_002230/seed_63210031/replay.events.jsonl`

Findings:

- `Aura of Silence`, turn `10`, `precombat_main`, player
  `Tayam, Luminous Enigma #25 (real)`.
- `spell_cast` emitted `severity=medium` and `spell_resolved` emitted
  `severity=high`.
- Both findings say: game event depended on heuristic source
  `functional_tags_json`.
- The replay events have `rule_source=functional_tags_json`,
  `rule_review_status=heuristic`, `rule_confidence=0.35`,
  `effect=remove_permanent`, and target `Esper Sentinel`.
- Forensic lineage for that source is incomplete:
  `forensic_card_id_missing_unaccepted=2`,
  `forensic_semantic_hash_missing_unaccepted=2`, and
  `forensic_lineage_unaccepted_missing_samples` lists `Aura of Silence` for
  missing `card_id` and `semantic_hash` on `spell_cast` and `spell_resolved`.

Result: this is the same root class tracked by `BV-067`: an executed gameplay
event came from the broad `functional_tags_json` heuristic path instead of a
verified/active battle rule or an explicit accepted runtime waiver. Because the
current latest has a high forensic finding, the replay cannot be treated as
trusted for strategy learning.

Task for "Ajustar battle":

- Move the `Aura of Silence` `remove_permanent` runtime path into
  verified/active battle-rule coverage with stable lineage (`card_id`,
  `semantic_hash`, logical rule key), or add an explicit documented runtime
  waiver if this heuristic path is intentionally accepted.
- Add a regression fixture that fails when `Aura of Silence` or another
  non-waived `functional_tags_json` card produces high/critical forensic
  findings.
- Keep action/strategy clean status separate from final readiness; this run has
  clean action and no strategy blockers but is still blocked by forensic.

## BV-075 Delta Evidence

The latest `20260620_002230` improves the learned-opponent aggregate:

- `learned_deck_opponents` is present.
- `opponent_deck_provenance.status=learned_opponent_provenance_present_with_shape_waiver`.
- `opponent_deck_provenance.learned_opponent_appearance_count=48`.
- `opponent_deck_provenance.learned_opponent_unique_count=12`.
- `learned_opponent_source_counts={"pg_meta_decks":48}`.
- Each learned opponent row includes `source_ref`, `source_system`,
  `source_row_id`, `name`, appearances/seeds, card counts, metrics basis,
  blocker domain, cached metadata flag, and explicit construction/coherence
  waiver fields.

Remaining gap:

- None of the `learned_deck_opponents` rows publishes `source_url`.
- Sample row: `source_ref=learned_deck:104`,
  `source_system=pg_meta_decks`, `source_row_id=104`,
  `source_url=null`, `name="Kinnan, Bonder Prodigy #104 (real)"`.
- The prior source-key audit showed the stable local cache identity exists in
  Hermes SQLite as `source_url=pg:meta_decks:<uuid>`, but it is still absent
  from the main result.

Result: `BV-075` should remain open, but its current scope is narrower than in
the `000720` run. The main summary now publishes learned-opponent provenance
and waivers, but still lacks the stable PG/meta-deck source identity required
for downstream persistence and cross-run comparison.

Task for "Ajustar battle":

- Include `source_url` or a stronger backend-owned PG meta-deck identity in
  each learned opponent aggregate row when available.
- Preserve the current aggregate fields and explicit construction/coherence
  waivers.
- Add a test that fails when a `source_ref=learned_deck:<sqlite_id>` row is
  published without `source_system`, `source_row_id`, `name`, provenance status,
  and stable `source_url` or documented backend-owned replacement.
