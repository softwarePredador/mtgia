# Verge Rangers Runtime Waiver

- status: `ready`
- card: `Verge Rangers`
- postgres_writes: `false`
- source_db_mutated: `false`
- XMage source: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/v/VergeRangers.java`

## Runtime Rule

- effect: `topdeck_play`
- battle_model_scope: `look_top_library_play_lands_from_top_if_opponent_more_lands_v1`
- logical_rule_key: `battle_rule_v1:c795721c1dc42d0f9ee3fa23349500e1`
- oracle_hash: `44aa2eeb2eeb517fb30478aec7cec42f`
- review_status: `verified`
- execution_status: `auto`
- opened_at_utc: `2026-06-28T18:40:00Z`
- expires_at_utc: `2026-07-05T23:59:59Z`

## Validation

- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_verge_rangers_runtime.py -q`
- result: `3 passed`

The focused test proves that the battle engine plays the top-library land only
when an opponent controls more lands than the Verge Rangers controller.
