# Lorehold Accessibility Layer Matrix

- generated_at: `2026-07-05T02:45:12Z`
- deck_id: `607`
- target_bracket: `4`
- postgres_writes: `false`
- source_db_mutated: `false`

## Summary

- cards reviewed: `2`
- owned cards: `1`
- format_staples gaps: `1`
- promotion blocked cards: `2`
- result counts: `{"legal_not_owned_and_promotion_blocked_current_607": 1, "legal_owned_but_promotion_blocked_current_607": 1}`

## Layer Matrix

| Card | Legal | Owned | Format staple | Game Changer | Bracket allowed | In 607 | Promotion decision | Current 607 result |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- |
| Mana Vault | `True` | 0 | `True` | `True` | `True` | `False` | `blocked_prior_gate_rejected` | `legal_not_owned_and_promotion_blocked_current_607` |
| The One Ring | `True` | 1 | `False` | `True` | `True` | `False` | `blocked_existing_package_rejected` | `legal_owned_but_promotion_blocked_current_607` |

## App Contract Note

- Do not label a card as simply accessible unless the UI also says which layer passed: legal, owned, bracket-allowed, discoverable, or promotion-ready.
- decision: Legality, ownership, staple discovery, bracket budget, and 607 promotion are distinct layers. No reviewed card is allowed to enter protected 607 from legality or ownership alone.
