# Battle Defender Runtime Guard - 2026-07-05

Status: validated runtime guard, no PostgreSQL apply.

Context:

- The post-PG501 queue showed token/static keyword neighbors where `defender`
  appears as real XMage behavior.
- `xmage_authoritative_exact_scope_split.py` can preserve static self
  `DefenderAbility` metadata in some exact families, but the battle runtime's
  central `can_attack_this_combat` check did not reject `defender`.
- Promoting additional defender-bearing cards before this runtime guard would
  allow illegal attacks in battle.

Change:

- `battle_analyst_v9.py` now blocks creatures with `defender` from attacking.
- Explicit future exceptions are supported through
  `can_attack_with_defender` or `can_attack_as_though_no_defender`, so later
  exact families can model cards that temporarily attack despite defender.
- `battle_combat_tests.py` adds
  `test_defender_creature_cannot_attack_without_explicit_exception`.

Validation:

- Command:
  `set -a; source .credentials.env; set +a; python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
- Output:
  `docs/hermes-analysis/master_optimizer_reports/battle_defender_runtime_guard_20260705.out`
- Result: `629` `PASS` lines.
- Focused test:
  `PASS test_defender_creature_cannot_attack_without_explicit_exception`

Decision:

- Defender is now safe as a runtime attack restriction when effect payloads
  carry `defender=true`.
- This does not by itself promote any card to PostgreSQL. The next card-rule
  package still needs exact XMage split, precheck/apply/postcheck, sync, and
  post-sync queue evidence.
