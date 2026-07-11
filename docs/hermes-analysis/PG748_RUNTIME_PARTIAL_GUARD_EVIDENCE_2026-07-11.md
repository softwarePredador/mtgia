# PG748 Runtime Partial Guard Evidence - 2026-07-11

Status: `validated_no_pg_apply`

Database target for queue/split verification:
`127.0.0.1:15432/halder` through `server/bin/with_new_server_pg.sh`.

## Reason

After PG747, the exact splitter still surfaced mana-source proposals whose
runtime model covered only the mana ability while leaving relevant auxiliary
abilities/effects unmodeled.

That is useful as family-planning evidence, but it must not be counted as a
safe executable PostgreSQL package candidate.

## Change

`xmage_authoritative_exact_scope_split.py` now treats any proposal with
`effect_json._runtime_partial=true` as review-only:

- `promotion_lane`: `runtime_partial_review_only`
- `proposal_status`: `runtime_partial_requires_family_runtime`
- `safe_for_batch_pg_package`: `false`

The exact split summary now counts `safe_for_batch_pg_package_count` from the
actual proposal field instead of hardcoding `len(proposals)`.

The restricted mana-source path now also marks proposals partial when XMage
contains auxiliary non-mana abilities/effects. This prevents cards such as
`Shaman of Forgotten Ways` from being promoted as complete just because their
restricted mana ability is modeled while their Formidable life-total ability is
not.

## Validation

Tests:

- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`
  - `998` tests passed
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`
  - `184` tests passed
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py`
  - pass

Final split report:

- `docs/hermes-analysis/master_optimizer_reports/pg748_candidate_post_pg747_after_partial_guard_v3_exact_scope_split.json`

Final split summary:

- proposal count: `12`
- safe for batch PostgreSQL package: `0`
- proposal statuses: `{"runtime_partial_requires_family_runtime": 12}`
- families:
  - `xmage_simple_mana_source_with_unmodeled_auxiliary`: `11`
  - `xmage_restricted_spell_category_mana_source`: `1`

The 12 rows remain useful next-work candidates, but require family/runtime
support for their auxiliary abilities before promotion.
