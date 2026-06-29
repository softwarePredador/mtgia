# Battle Simulator Rules Alignment Audit

Date: 2026-06-29

## Objective

Limpar artefatos que confundiam a nova rotina XMage -> ManaLoom e alinhar o
simulador de battle rules com fontes externas primarias, deixando explicito o
que ja e coberto, o que e parcial e qual gate deve bloquear promocoes futuras.

## Cleanup Performed

Removed from repository:

- 60 root-level generated files matching `xmage_current_replay_batch_pipeline_20260624_*`
- Approximate tracked root artifact size removed: 23 MB

Removed from local workspace only:

- Ignored SQLite backups under `docs/hermes-analysis/master_optimizer_reports/*.sqlite`
- Approximate local backup size removed: 77 MB

Added safeguards:

- `.gitignore` now blocks root-level `xmage_current_replay_batch_pipeline_*`
- `docs/hermes-analysis/master_optimizer_reports/README.md` now states that this
  directory is evidence/archive only, not executable source of truth
- New rule: exploratory pipeline runs should use `/tmp` via `--output-prefix`;
  only reviewed summaries/package evidence/final manifests should be committed

## Script Surface Audit

AST dependency scan over `docs/hermes-analysis/manaloom-knowledge/scripts`:

- Python files scanned: 348
- Core reachable files from current XMage/battle runtime roots: 23
- Test files: 174
- Battle-related files: 88
- XMage-related files: 28
- One-off/historical-name candidates: 50

Core reachable roots:

- `battle_analyst_v9.py`
- `battle_replay_v10_3.py`
- `battle_rule_registry.py`
- `reviewed_battle_card_rules.py`
- `xmage_current_replay_batch_pipeline.py`
- `xmage_local_rule_indexer.py`
- `xmage_to_manaloom_effect_hints.py`
- `xmage_semantic_family_classifier.py`
- supporting battle modules for mana, card characteristics, land, replacement,
  SBA, and zone transitions

Manifest result after classification:

- Related battle/runtime files classified: 147
- Unclassified related files: 0
- `battle_package_end_to_end_validation.py` was newly classified as
  `focused evidence/promotion`

## External Source Contract

The battle simulator should be aligned against these sources:

| Source | URL | Use |
| --- | --- | --- |
| Wizards Comprehensive Rules | https://magic.wizards.com/en/rules | Authoritative game rules: priority, casting, stack, zones, SBAs, replacement/prevention, continuous effects, keywords |
| XMage | https://github.com/magefree/mage | Primary open implementation reference for exact card abilities/effects |
| Forge | https://github.com/Card-Forge/forge | Secondary open implementation reference when XMage mapping is ambiguous |
| Scryfall API | https://scryfall.com/docs/api | Oracle text, rulings, legalities, ids, bulk card data; not a rules executor |
| MTGJSON | https://mtgjson.com/ | Bulk metadata and identity cross-checks; not a rules executor |
| Commander rules | https://mtgcommander.net/index.php/rules/ | Commander deck construction, command zone, tax, color identity, commander damage |

## Rule Area Alignment

| Area | Rules | Status | Local Gate |
| --- | --- | --- | --- |
| Turn, priority, stack, casting, resolution | CR 117, 405, 500, 601, 608 | covered_by_core_tests | Run stack/turn tests before changing priority/casting/resolution |
| Mana costs/payment/mana abilities | CR 106, 107.4, 601.2f-h, 605 | covered_with_known_mode_gaps | Alternate/sacrifice mana modes need explicit executor tests before PG promotion |
| Zones, LKI, movement | CR 400, 608.2, 701 | covered_by_core_tests | Run zone/SBA tests before movement helper changes |
| State-based actions | CR 704 | covered_by_core_tests | Run SBA tests after damage/counter/token/attachment changes |
| Replacement/prevention/damage/life | CR 119, 120, 614, 615 | covered_with_known_scope_limits | Cross-check competing replacements against XMage/Forge |
| Continuous effect layers | CR 613 | partial_family_specific_support | Do not claim generic layer engine; require family-specific tests |
| Combat | CR 506, 508, 509, 510 | covered_by_core_tests | Run combat tests before target pressure/blocker/damage changes |
| Triggered abilities | CR 603 | partial_family_specific_support | Require event-contract and focused replay tests before promotion |
| Modal targets/choices/copying | CR 115, 601.2b-d, 707 | covered_with_known_scope_limits | Require mode, target legality, stack provenance tests |
| Commander format | CR 903 plus Commander rules | covered_with_known_scope_limits | Verify command zone, commander tax, color identity, commander damage |
| Card-specific runtime rules | Oracle, XMage, Forge | family_mapper_required | XMage/Oracle creates candidate; PG promotion requires focused test and safe lane |

## Validation Evidence

Commands:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py \
  --json-output /tmp/battle_runtime_surface_manifest_20260629.json \
  --output /tmp/battle_runtime_surface_manifest_20260629.md \
  --fail-on-unclassified

python3 -m pytest -q \
  test_battle_runtime_surface_manifest.py \
  test_reviewed_battle_card_rules.py \
  battle_mana_tests.py \
  battle_stack_casting_tests.py \
  battle_sba_zone_tests.py \
  battle_replacement_tests.py \
  battle_combat_tests.py

/usr/bin/time -p python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_current_replay_batch_pipeline.py \
  --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master \
  --skip-materialize \
  --output-prefix /tmp/manaloom_cleanup_battle_alignment_pipeline_20260629
```

Results:

- Surface manifest: passed with 0 unclassified files
- Battle representative suite: 32 passed in 2.69s
- XMage current replay pipeline: real 0.70s
- Pipeline counts unchanged after cleanup:
  - Cards scanned: 541
  - Actionable cards: 139
  - Structured XMage/review candidates: 76
  - Mapper-required cards: 63
  - Proposal lanes: 63 mapper-required, 1 runtime-family-required, 75 split-family-review

## Decision

The battle simulator is not a full generic MTG engine and should not be treated
as one. The correct operating model is:

1. Use the Comprehensive Rules as the rule ontology.
2. Use XMage as the primary executable card-reference source.
3. Use Forge as the secondary implementation cross-check.
4. Use Scryfall/MTGJSON for Oracle/data identity, not execution.
5. Promote only family-scoped runtime behavior backed by focused tests.
6. Keep PostgreSQL as reviewed product truth and Hermes/report files as cache or
   evidence only.

This keeps the simulator coherent without letting historical reports or broad
generated candidates influence the new routine.
