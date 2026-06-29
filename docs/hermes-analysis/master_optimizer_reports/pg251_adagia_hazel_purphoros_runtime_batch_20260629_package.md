# PG251 XMage Runtime Batch PostgreSQL Package

Status: `applied_synced_validated`

Cards:

- `Hazel's Brewmaster`: ETB/attack graveyard exile + Food token + Food activated ability sharing from exiled creature cards.
- `Adagia, Windswept Bastion`: Station 12 gated copy of controlled artifact/enchantment as legendary token; existing land rule is preserved as a separate function.
- `Purphoros, God of the Forge`: passive controlled-creature ETB damage to each opponent; existing shadows preserved.

Source proposal artifact:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_151845_post_adagia_hazel_runtime_proposals.json`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg251_adagia_hazel_purphoros_runtime_batch_20260629_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg251_adagia_hazel_purphoros_runtime_batch_20260629_apply.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg251_adagia_hazel_purphoros_runtime_batch_20260629_postcheck.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg251_adagia_hazel_purphoros_runtime_batch_20260629_rollback.sql`

Focused runtime evidence before apply:

- `test_adagia_runtime.py`
- `test_hazels_brewmaster_runtime.py`
- `test_purphoros_runtime.py`
- `test_xmage_to_manaloom_effect_hints.py`
- `test_xmage_semantic_family_batch_pipeline.py`

Executed sequence: precheck, apply, postcheck, PG -> SQLite sync, direct runtime lookup proof, current queue rebuild, strategy consistency audit.
