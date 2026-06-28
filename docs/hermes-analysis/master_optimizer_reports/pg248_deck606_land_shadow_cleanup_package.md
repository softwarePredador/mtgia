# PG248 Deck 606 Land Shadow Cleanup

Purpose: close the deck `606` L1 land/mana-base audit queue by rejecting
generated review-only land shadows when a trusted curated land-only runtime row
already exists.

Cards:

- `Boros Garrison`
- `Boseiju, Who Shelters All`
- `Command Beacon`
- `Eiganjo, Seat of the Empire`
- `Furycalm Snarl`
- `Reliquary Tower`
- `Valakut, the Molten Pinnacle`

Rules:

- Reject/disable generated `needs_review/review_only` shadows:
  `battle_rule_v1:55c2bc99b653af8c05e99108f1c45b5d`,
  `battle_rule_v1:2be7a9b6c891893428bd34f4866a48a8`,
  `battle_rule_v1:33d0f77ed0b6806a7128dbd3d865b167`.
- Preserve trusted curated land-only runtime:
  `battle_rule_v1:603c776839827f2f21cef8b62e22a1be`.

Important boundary:

- This package does not implement utility-land behavior.
- It does not promote Valakut damage, Boseiju uncounterable mana, Eiganjo
  channel damage, Command Beacon commander-zone movement, Reliquary Tower max
  hand size, Boros Garrison bounce/tapped timing, or Furycalm Snarl reveal/tap
  timing.
- Those clauses require separate oracle-specific executors if they become
  battle-decisive.

Expected counts:

- `target_cards=7`.
- Precheck `generated_review_only_rows=7`.
- Precheck `trusted_land_rows=7`.
- Apply `rejected_shadow_rows=7`.
- Apply `annotated_trusted_land_rows=7`.
- Postcheck `remaining_review_shadow_rows=0`.
