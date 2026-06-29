# Master Optimizer Reports

This directory is an evidence archive. Files here are not executable source of
truth for the battle simulator, deck builder, PostgreSQL, or Hermes sync.

Operational rules:

- Runtime and card-rule behavior must come from code, PostgreSQL-reviewed rules,
  and focused tests.
- Hermes SQLite and these reports are cache/lab/evidence surfaces only.
- Exploratory pipeline runs should write to `/tmp` with `--output-prefix`.
- Commit only reviewed summaries, package evidence, or final manifests that are
  explicitly needed for audit traceability.
- Do not store local SQLite backups here; they are ignored by `.gitignore` and
  should be regenerated from PostgreSQL/Hermes when needed.

For the current XMage to ManaLoom flow, use
`../XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md` as the operating contract.
