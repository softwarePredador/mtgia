# pg420 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T18:22:08+00:00`
- Selected cards: `["Anaconda", "Anurid Murkdiver", "Benthic Behemoth", "Bog Raiders", "Bog Smugglers", "Bog Tatters", "Bog Wraith", "Bull Hippo", "Canyon Wildcat", "Cat Warriors", "Cliff Threader", "Devouring Deep", "Dwarven Grunt", "Elite Cat Warrior", "Emerald Oryx", "Farbog Explorer", "Glissa's Courier", "Goblin Mountaineer", "Goblin Spelunkers", "Grayscaled Gharial", "Heartwood Treefolk", "Hillcomber Giant", "Jukai Messenger", "Koth's Courier", "Leaf Dancer", "Lost Soul", "Lynx", "Marsh Boa", "Marsh Goblins", "Marsh Threader", "Moor Fiend", "Mountain Goat", "Pale Bears", "Plague Beetle", "Pygmy Allosaurus", "Raiding Nightstalker", "Righteous Avengers", "River Bear", "Rock Badger", "Rootwater Commando", "Rushwood Dryad", "Segovian Leviathan", "Shanodin Dryads", "Slinking Serpent", "Sokenzan Bruiser", "Somberwald Dryad", "Warthog", "Wild Ox", "Willow Dryad", "Zendikar Farguide", "Zodiac Dog", "Zodiac Goat", "Zodiac Horse", "Zodiac Monkey", "Zodiac Ox", "Zodiac Pig", "Zodiac Rabbit", "Zodiac Rat", "Zodiac Rooster", "Zodiac Snake", "Zodiac Tiger"]`
- Families: `{"xmage_static_self_basic_landwalk_creature": 61}`

Files:

- precheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg420_xmage_static_basic_landwalk_new_server_precheck.sql`
- apply: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg420_xmage_static_basic_landwalk_new_server_apply.sql`
- rollback: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg420_xmage_static_basic_landwalk_new_server_rollback.sql`
- postcheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg420_xmage_static_basic_landwalk_new_server_postcheck.sql`
- manifest: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg420_xmage_static_basic_landwalk_new_server_manifest.json`
- package: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg420_xmage_static_basic_landwalk_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
