# PG-017 Arcane Epiphany Battle Rule Package

- Scope: add a curated executable `draw_cards` rule for Arcane Epiphany.
- Reason: PG-016 Windborn/Norn/Silent/Magus variants were blocked by forensic audit when The Emperor of Palamecia cast Arcane Epiphany from `functional_tags_json` in seed `63212310`.
- Deck mutation: none.
- Runtime caveat: Wizard cost reduction is documented in notes but not modeled in this pass; the important execution behavior is `draw_count=3`.

## Expected Postcheck

- `card_rows=1`
- `curated_executable_rows=1`
- `draw_function_tag_rows=1`
