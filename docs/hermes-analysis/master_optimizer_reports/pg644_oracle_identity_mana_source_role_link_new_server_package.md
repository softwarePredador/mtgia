# PG644 Oracle Identity Mana Source Rule Link

- Scope: copy verified same-oracle battle rules to `Birds of Paradise // Birds of Paradise` and `Sol Ring // Sol Ring`.
- Donors: `Birds of Paradise` and `Sol Ring`.
- Safety gate: same `oracle_id`, same Oracle text hash, donor rule `verified/auto`.
- Data repair: align donor and copied `effect_json`/`deck_role_json` to battle and deckbuilder purpose:
  - Birds of Paradise: `ramp / mana_dork`.
  - Sol Ring: `ramp / fast_mana_rock`.
  - Both rules explicitly require tapped mana activation.

## Files

- Precheck: `pg644_oracle_identity_mana_source_role_link_new_server_precheck.sql`
- Apply: `pg644_oracle_identity_mana_source_role_link_new_server_apply.sql`
- Postcheck: `pg644_oracle_identity_mana_source_role_link_new_server_postcheck.sql`
- Rollback: `pg644_oracle_identity_mana_source_role_link_new_server_rollback.sql`
- Manifest: `pg644_oracle_identity_mana_source_role_link_new_server_manifest.json`

## Expected Outcome

- `oracle_identity_rule_link_or_copy` should drop from `2` to `0`.
- `Sol Ring // Sol Ring` should become `battle_and_oracle_ready`.
- The SLD row of `Birds of Paradise // Birds of Paradise` with missing Oracle data remains blocked by `oracle_data_sync`; the 10E row with valid `oracle_id` becomes rule-ready.
