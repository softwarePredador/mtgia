# Global Commander Deck Contract Audit

- Generated at: `2026-07-01T00:52:22.966823+00:00`
- Status: `action_required`
- Contract: `docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md`
- Total decks audited: `1339`

## Scope Counts

| Scope | Decks |
| --- | ---: |
| `hermes_lorehold_baseline` | 1 |
| `hermes_lorehold_variant` | 11 |
| `hermes_registered_variant` | 5 |
| `registered_pg_variant` | 13 |
| `test_or_fixture` | 1293 |
| `user_product` | 16 |

## Status By Scope

| Scope | Status | Decks |
| --- | --- | ---: |
| `hermes_lorehold_baseline` | `structure_ready` | 1 |
| `hermes_lorehold_variant` | `structure_ready` | 11 |
| `hermes_registered_variant` | `structure_ready` | 5 |
| `registered_pg_variant` | `structure_ready` | 13 |
| `test_or_fixture` | `needs_repair` | 625 |
| `test_or_fixture` | `ready_with_legality_warnings` | 74 |
| `test_or_fixture` | `structure_ready` | 594 |
| `user_product` | `needs_repair` | 10 |
| `user_product` | `structure_ready` | 6 |

## Issue Counts

| Issue | Count |
| --- | ---: |
| `test_or_fixture:illegal_card_rows` | 103 |
| `test_or_fixture:missing_commander` | 157 |
| `test_or_fixture:off_color_rows` | 60 |
| `test_or_fixture:partner_or_multi_commander_requires_profile` | 19 |
| `test_or_fixture:quantity_not_100` | 545 |
| `test_or_fixture:unknown_legality_rows` | 74 |
| `test_or_fixture:unresolved_card_id` | 95 |
| `user_product:illegal_card_rows` | 1 |
| `user_product:missing_commander` | 2 |
| `user_product:quantity_not_100` | 9 |
| `user_product:unresolved_card_id` | 1 |

## Top Commanders

| Commander | Decks |
| --- | ---: |
| `Talrand, Sky Summoner` | 464 |
| `Auntie Ool, Cursewretch` | 109 |
| `Jin-Gitaxias // The Great Synthesis` | 89 |
| `Atraxa, Praetors' Voice` | 64 |
| `Lorehold, the Historian` | 50 |
| `Krenko, Mob Boss` | 30 |
| `Edgar Markov` | 27 |
| `Muldrotha, the Gravetide` | 25 |
| `Prosper, Tome-Bound` | 24 |
| `Kaalia of the Vast` | 22 |
| `Kozilek, the Great Distortion` | 22 |
| `Miirym, Sentinel Wyrm` | 21 |
| `Urza, Lord High Artificer` | 21 |
| `Isshin, Two Heavens as One` | 19 |
| `Meren of Clan Nel Toth` | 19 |

## Sample Issues

| Scope | Source | Deck | Quantity | Commanders | Issues |
| --- | --- | --- | ---: | ---: | --- |
| `user_product` | `postgres` | `goblins` (`8c22deb9-80bd-489f-8e87-1344eabac698`) | 100 | 1 | `illegal_card_rows` |
| `user_product` | `postgres` | `hfgh` (`93e0e6e1-e351-4db8-9715-6c6d1fdf5672`) | 1 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `jin` (`8ff632c1-2499-436f-89a4-2802da1e605f`) | 1 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `Jin` (`0b163477-2e8a-488a-8883-774fcd05281f`) | 1 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `Jin` (`536b9e7d-69c3-4518-ab92-fe83352a0b4e`) | 1 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `Jin` (`6e9db347-2fb1-413f-bdd1-1e15b690566e`) | 0 | 0 | `unresolved_card_id, quantity_not_100, missing_commander` |
| `user_product` | `postgres` | `jin2` (`2fb14ec7-7a00-4ad7-a7e9-5a5a85d7f9b2`) | 1 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `jjjj` (`59bbcd4a-f8a4-46b2-944d-0896d83a6f7c`) | 1 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `lorehold` (`b17e9d71-8b51-48ad-833b-f17190a347a3`) | 2 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `rolinha` (`84aacfd4-e518-474a-9066-e88ea35274b9`) | 1 | 0 | `quantity_not_100, missing_commander` |
| `test_or_fixture` | `postgres` | `Audit Deck 1770812730` (`f4077881-7b94-43ab-bed6-50720507a6f1`) | 0 | 0 | `unresolved_card_id, quantity_not_100, missing_commander` |
| `test_or_fixture` | `postgres` | `Audit Kinnan cEDH Seed` (`2df66407-e8e9-4103-8b43-228dcb32d8b3`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Audit Talrand cEDH Seed` (`27b11da3-ceab-4174-a50b-1e7dc1fc2874`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Audit Talrand cEDH Seed` (`8b7041b6-2525-4193-9195-8e3f98de46ac`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Atraxa, Praetors' Voice - 1776966234860` (`3ea4f406-d4fc-4612-82da-620894a51c50`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Auntie Ool, Cursewretch - 1776819284852` (`98ebdff1-f871-45ea-a314-f3f42b1ec894`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Auntie Ool, Cursewretch - 1776819397585` (`555bcada-72a2-40c8-b4c6-2f45419e0f21`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Auntie Ool, Cursewretch - 1776819491931` (`28dd1e28-dcd3-4a96-a34e-a0b6ac423724`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Auntie Ool, Cursewretch - 1776963625616` (`c858c147-d4ac-4b68-b133-a4d6cf2d5dc5`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Auntie Ool, Cursewretch - 1776964671794` (`a74a651e-77b0-4720-87c3-c3da59af25d9`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Auntie Ool, Cursewretch - 1776966135467` (`44285de1-7755-4b7e-8de5-1a4d1a8d62cf`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Edgar Markov - 1776966431165` (`6063d727-74bd-49b9-b73f-106766f6bc8d`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Isshin, Two Heavens as One - 1776966333972` (`6d9414c3-1672-4901-9315-e9fda6352519`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Jin-Gitaxias // The Great Synthesis - 1776819309583` (`4a5e219d-a548-4ca3-b8f4-54165ea57dde`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Jin-Gitaxias // The Great Synthesis - 1776819419276` (`4f705b6f-4b7e-4098-bb52-d95fe0ddab86`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Jin-Gitaxias // The Great Synthesis - 1776819513438` (`24de5e3d-27e9-4e99-af21-7f6b241a3abc`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Jin-Gitaxias // The Great Synthesis - 1776819644735` (`6d520bff-1c11-4554-a02f-f952fc5c9b82`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Jin-Gitaxias // The Great Synthesis - 1776819784078` (`3ce6dc72-8d13-4349-bb0b-b6e4a664e403`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Jin-Gitaxias // The Great Synthesis - 1776966165358` (`b0e84617-08b6-411e-8de3-17121d5cf76f`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Kaalia of the Vast - 1776820190493` (`ca27bd71-9428-4bb9-9983-84b6020faf35`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Kaalia of the Vast - 1776966559243` (`e2ba6168-f18e-40e2-90e9-9268987d065f`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Kaalia of the Vast - 1777292873511` (`b7c5dc54-b38e-4bd5-ba53-4b27ccc2a426`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Korvold, Fae-Cursed King - 1776820156269` (`554277cd-aa99-4b8b-aacc-72378616a801`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Korvold, Fae-Cursed King - 1776956489022` (`aaf21ebc-299c-417e-b267-a616456eadbe`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Korvold, Fae-Cursed King - 1776964072239` (`bf1cf42b-c0e3-4bfc-b719-7c9973b81374`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Korvold, Fae-Cursed King - 1776965086328` (`44827a21-1623-4e2f-91dc-84729f9c8b7d`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Korvold, Fae-Cursed King - 1776966526731` (`092586ef-64f2-42b1-8607-3e5558541ff7`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Korvold, Fae-Cursed King - 1776967383209` (`7f23dec6-3d88-40b5-8094-8cf1e66f27f8`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Korvold, Fae-Cursed King - 1776968696914` (`f9a8d660-c072-4dc1-a6ac-a4833d346cb3`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Korvold, Fae-Cursed King - 1776969491125` (`04df008d-ebea-41ab-b0fe-5b09145bb1a1`) | 100 | 1 | `unknown_legality_rows` |

## Action Items

- `repair_or_exclude_product_user_decks_before_global_promotion`
- `use_issue_counts_to_prioritize_card_id_legal_shape_repairs`
