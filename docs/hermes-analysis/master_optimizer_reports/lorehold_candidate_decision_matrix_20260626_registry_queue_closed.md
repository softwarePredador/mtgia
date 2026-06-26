# Lorehold Candidate Decision Matrix

- status: `ready`
- baseline: `deck_607`
- decision: `deck_607 remains best`
- queue_status: `closed`
- postgres_writes: `false`
- source_db_mutated: `false`

## Results

| Candidate | Swap | Result | WR | Winota | Miracle | Topdeck | Molecule Man | Decision |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `deck_607` | baseline | 5W/4L/0S | 55.56% | 2W/1L/0S | 8/9 | 3/9 | preserved | `keep_baseline` |
| `candidate_607_reprieve_v1` | +Reprieve; -Tibalt's Trickery | 0W/9L/0S | 0.00% | 0W/3L/0S | 4/9 | 2/9 | preserved | `reject` |
| `candidate_607_galvanoth_v1` | +Galvanoth; -Creative Technique | 4W/5L/0S | 44.44% | 1W/2L/0S | 6/9 | 1/9 | preserved | `reject` |
| `candidate_607_ghostly_prison_v1` | +Ghostly Prison; -High Noon | 3W/6L/0S | 33.33% | 0W/3L/0S | 6/9 | 2/9 | preserved | `reject` |
| `candidate_607_guttersnipe_v1` | +Guttersnipe; -Prismari Pianist | 1W/8L/0S | 11.11% | 0W/3L/0S | 8/9 | 5/9 | preserved | `reject` |

## Learning

- `Molecule Man` is present in `deck_607` and was preserved in every isolated candidate tested here.
- `Reprieve`, `Galvanoth`, `Ghostly Prison`, and `Guttersnipe` all preserved construction validity and commander intent but failed the battle acceptance rule.
- Newly protected until a same-function replacement wins: `Tibalt's Trickery`, `Creative Technique`, `High Noon`, `Prismari Pianist`.
