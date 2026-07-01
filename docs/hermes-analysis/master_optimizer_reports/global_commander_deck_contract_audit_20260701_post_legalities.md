# Global Commander Deck Contract Audit

- Generated at: `2026-07-01T00:39:13.546886+00:00`
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
| `test_or_fixture` | 1282 |
| `user_product` | 27 |

## Status By Scope

| Scope | Status | Decks |
| --- | --- | ---: |
| `hermes_lorehold_baseline` | `structure_ready` | 1 |
| `hermes_lorehold_variant` | `structure_ready` | 11 |
| `hermes_registered_variant` | `structure_ready` | 5 |
| `registered_pg_variant` | `structure_ready` | 13 |
| `test_or_fixture` | `needs_repair` | 552 |
| `test_or_fixture` | `ready_with_legality_warnings` | 447 |
| `test_or_fixture` | `structure_ready` | 283 |
| `user_product` | `needs_repair` | 16 |
| `user_product` | `ready_with_legality_warnings` | 6 |
| `user_product` | `structure_ready` | 5 |

## Issue Counts

| Issue | Count |
| --- | ---: |
| `test_or_fixture:missing_commander` | 156 |
| `test_or_fixture:off_color_rows` | 59 |
| `test_or_fixture:partner_or_multi_commander_requires_profile` | 19 |
| `test_or_fixture:quantity_not_100` | 538 |
| `test_or_fixture:unknown_legality_rows` | 447 |
| `test_or_fixture:unresolved_card_id` | 95 |
| `user_product:missing_commander` | 3 |
| `user_product:off_color_rows` | 1 |
| `user_product:quantity_not_100` | 16 |
| `user_product:unknown_legality_rows` | 6 |
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
| `user_product` | `postgres` | `Animar` (`13b58b67-5e72-4584-9841-a859241a906a`) | 100 | 1 | `unknown_legality_rows` |
| `user_product` | `postgres` | `fhghg` (`2f4f1fb5-5874-484f-b234-741cb10dffec`) | 100 | 1 | `unknown_legality_rows` |
| `user_product` | `postgres` | `Flow Talrand 19dcf0c78f8` (`221f35a3-9139-4b27-bb9c-36e920735670`) | 100 | 1 | `unknown_legality_rows` |
| `user_product` | `postgres` | `goblins` (`8c22deb9-80bd-489f-8e87-1344eabac698`) | 100 | 1 | `unknown_legality_rows` |
| `user_product` | `postgres` | `hdshhd` (`e2bda384-a233-4e5b-9566-e985f4b8693d`) | 100 | 1 | `unknown_legality_rows` |
| `user_product` | `postgres` | `hfgh` (`93e0e6e1-e351-4db8-9715-6c6d1fdf5672`) | 1 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `jin` (`8ff632c1-2499-436f-89a4-2802da1e605f`) | 1 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `Jin` (`0b163477-2e8a-488a-8883-774fcd05281f`) | 1 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `Jin` (`536b9e7d-69c3-4518-ab92-fe83352a0b4e`) | 1 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `Jin` (`6e9db347-2fb1-413f-bdd1-1e15b690566e`) | 0 | 0 | `unresolved_card_id, quantity_not_100, missing_commander` |
| `user_product` | `postgres` | `jin2` (`2fb14ec7-7a00-4ad7-a7e9-5a5a85d7f9b2`) | 1 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `jjjj` (`59bbcd4a-f8a4-46b2-944d-0896d83a6f7c`) | 1 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `Kaalinha` (`220a9e4a-3a1f-4f91-b5ca-cf0bbf54028d`) | 100 | 1 | `unknown_legality_rows` |
| `user_product` | `postgres` | `lorehold` (`b17e9d71-8b51-48ad-833b-f17190a347a3`) | 2 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `Meu Deck Commander` (`5883357e-c278-4747-88e1-6b70035255f4`) | 91 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `Meu Deck Commander` (`cd601ddf-ffb0-44c0-8086-7564d3ae8466`) | 91 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `Meu Deck Commander` (`d5e25e80-5c22-42b2-8eb8-59624b1f149a`) | 94 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `Meu Deck Commander` (`db85a888-80f6-4ef4-8c40-2a7c4f578f6b`) | 91 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `Meu Deck Commander` (`de3bc20b-be0d-4d84-8958-0460ff83171b`) | 94 | 0 | `quantity_not_100, missing_commander, off_color_rows` |
| `user_product` | `postgres` | `Meu Deck Commander` (`eb582c54-ede2-4322-8498-5536e3c5686b`) | 91 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `ML Test Deck` (`ccd5f409-7a82-424e-a4b6-3c52ae6d13cf`) | 2 | 1 | `quantity_not_100` |
| `user_product` | `postgres` | `rolinha` (`84aacfd4-e518-474a-9066-e88ea35274b9`) | 1 | 0 | `quantity_not_100, missing_commander` |
| `test_or_fixture` | `postgres` | `Audit Deck 1770812730` (`f4077881-7b94-43ab-bed6-50720507a6f1`) | 0 | 0 | `unresolved_card_id, quantity_not_100, missing_commander` |
| `test_or_fixture` | `postgres` | `Audit Kinnan cEDH Seed` (`2df66407-e8e9-4103-8b43-228dcb32d8b3`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Audit Talrand cEDH Seed` (`27b11da3-ceab-4174-a50b-1e7dc1fc2874`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Audit Talrand cEDH Seed` (`8b7041b6-2525-4193-9195-8e3f98de46ac`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Atraxa, Praetors' Voice - 1776819855308` (`be34e46c-e571-4afd-ab1f-39b739302f17`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Atraxa, Praetors' Voice - 1776956198071` (`2c4ebb40-01a4-425c-a07a-73b7251749c8`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Atraxa, Praetors' Voice - 1776963726518` (`d566f9bc-b235-4007-add3-440c161a7fad`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Atraxa, Praetors' Voice - 1776964770596` (`0d3458ba-8cc7-46e2-96a1-71b9d2b661a8`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Atraxa, Praetors' Voice - 1776966234860` (`3ea4f406-d4fc-4612-82da-620894a51c50`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Atraxa, Praetors' Voice - 1776967027930` (`4ca2afbe-f403-4f89-8d1a-9f00e8d7cdb8`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Atraxa, Praetors' Voice - 1776968402090` (`86350ba1-657c-476d-9a45-41569146ace7`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Atraxa, Praetors' Voice - 1776969192915` (`799857a0-2b24-4375-a75a-13166d843148`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Atraxa, Praetors' Voice - 1776970328442` (`68bcb3ff-2532-4369-94a0-a8c8b8ba154c`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Auntie Ool, Cursewretch - 1776819284852` (`98ebdff1-f871-45ea-a314-f3f42b1ec894`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Auntie Ool, Cursewretch - 1776819397585` (`555bcada-72a2-40c8-b4c6-2f45419e0f21`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Auntie Ool, Cursewretch - 1776819491931` (`28dd1e28-dcd3-4a96-a34e-a0b6ac423724`) | 1 | 1 | `quantity_not_100` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Auntie Ool, Cursewretch - 1776819598989` (`e55d1333-0d07-412c-85a6-c78b42b327f7`) | 100 | 1 | `unknown_legality_rows` |
| `test_or_fixture` | `postgres` | `Commander Only Validation - Auntie Ool, Cursewretch - 1776819746213` (`d4a636df-3f9b-4c35-a25e-d9a166b4752e`) | 100 | 1 | `unknown_legality_rows` |

## Action Items

- `repair_or_exclude_product_user_decks_before_global_promotion`
- `use_issue_counts_to_prioritize_card_id_legal_shape_repairs`
