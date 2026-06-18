# Lorehold Canonical Deck Decision - 2026-06-14

## Decision

The canonical Hermes-local Lorehold deck state is:

- `deck_id=6`
- 100 cards
- 33 lands
- `Wheel of Misfortune` present
- `Reforge the Soul` absent
- `Rise of the Eldrazi` present
- `Plaza of Heroes` absent

This follows the documented live Hermes result where the only surviving apply
was:

```text
+ Wheel of Misfortune
-- Reforge the Soul
```

The later `Plaza of Heroes` over `Rise of the Eldrazi` candidate failed the
post-apply gate and was rolled back. Do not reapply it without a fresh full
confirmation and post-apply gate.

## Product status

This is not a product/app mutation.

The deck remains a Hermes-local canonical candidate until product owner
approval is given. Before changing production/Postgres/app deck data:

1. Confirm the target product deck id and environment.
2. Create a product deck backup.
3. Run a product dry-run diff.
4. Verify Commander legality, 100 cards and color identity.
5. Run API/app smoke tests.
6. Attach the Hermes evidence listed below.

## Evidence generated locally

- Canonical snapshot:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_canonical_snapshot_20260614.md`
- Canonical JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_canonical_snapshot_20260614.json`
- Preflight:
  `docs/hermes-analysis/master_optimizer_reports/master_optimizer_preflight_20260614_185941.md`
- Baseline smoke:
  `docs/hermes-analysis/master_optimizer_reports/master_optimizer_baseline_20260614_185538.md`
- Forensic replay audit:
  `docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_20260614_185929.md`
- Fresh replay directory:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_canonical_replays_20260614_after_rule_fix/`

## Local validation summary

- `lorehold_canonical_deck_snapshot.py`: approved.
- Battle regression suite: passed.
- Preflight: approved.
- Local 60-game smoke baseline: 58W/2L/0S, 96.7% WR.
- Forensic replay audit: 3 fresh replays, 3590 structured events, 0 findings.

The official live Hermes baseline remains the documented 300-game post-rollback
state: 87.3% WR, 100 cards, 33 lands, hash
`12c55613ae4f7bcd4c934fae4253cfa75fcc4946352a18a61365835427e90c08`.

The local SQLite hash differs because the local ignored SQLite copy is not the
server database and may not preserve all server-only identity fields.

## Rule hardening included

The local forensic replay initially found high-severity findings because
`Gilded Goose` was a generated `needs_review` token rule. The fix was:

- curate `Gilded Goose` in `battle_analyst_v8.py` and `battle_analyst_v9.py`;
- make `battle_rule_registry.py` classify mana-source creatures as
  `ramp/mana_dork`;
- resync local `battle_card_rules`;
- rerun the replay audit until findings reached zero.

## Re-run commands

From repo root:

```powershell
python docs\hermes-analysis\manaloom-knowledge\scripts\lorehold_canonical_deck_snapshot.py
python docs\hermes-analysis\manaloom-knowledge\scripts\master_optimizer_loop.py --preflight --report
python docs\hermes-analysis\manaloom-knowledge\scripts\test_battle_analyst_v10_3.py
```

For a local baseline smoke:

```powershell
$env:MANALOOM_KNOWLEDGE_DB=(Resolve-Path docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db).Path
$env:MANALOOM_BATTLE_SCRIPT=(Resolve-Path docs\hermes-analysis\manaloom-knowledge\scripts\battle_analyst_v9.py).Path
python docs\hermes-analysis\manaloom-knowledge\scripts\master_optimizer_baseline.py --deck-id 6 --games 5 --report
```

For fresh replay audit:

```powershell
$env:MANALOOM_KNOWLEDGE_DB=(Resolve-Path docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db).Path
$env:MANALOOM_BATTLE_SCRIPT=(Resolve-Path docs\hermes-analysis\manaloom-knowledge\scripts\battle_analyst_v9.py).Path
python docs\hermes-analysis\manaloom-knowledge\scripts\battle_forensic_audit.py --seed 614 --generate 3 --sqlite-db docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db --output-dir docs\hermes-analysis\master_optimizer_reports\lorehold_canonical_replays_20260614_after_rule_fix --report --fail-on-high
```

## AWS note

SSH to `3.16.217.179:22` still timed out during this validation, so the live
server could not be queried directly in this run. The decision above is based
on the latest documented Hermes reports plus local materialization and replay
validation.
