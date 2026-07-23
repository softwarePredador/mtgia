# Archived Large Evidence Artifacts

This manifest records large append-only or point-in-time evidence removed from
the current checkout during Sprint 9. None of these files was a runtime,
PostgreSQL, Hermes sync, deckbuilder, or Battle input. Their reviewed Markdown
summaries remain tracked, and the original bytes remain recoverable from Git
commit `4700fc38317aae0d3c1955176b32c18ac3b34339`.

New exploratory and per-run raw outputs belong in `/tmp`. A raw artifact may be
promoted back only when a current contract names an active consumer and the
retention audit records its owner and reason.

| Removed path | Bytes | SHA-256 | Replacement |
| --- | ---: | --- | --- |
| `xmage_authoritative_adaptation_queue_20260706_post_pg578_look_library_graveyard_new_server_commander_legal.json` | 41,737,094 | `5700e96174f05d690994a230340ac90b63b5b412cc224d552fc075e5704bf3fe` | sibling `.md` summary |
| `xmage_authoritative_adaptation_queue_20260706_post_pg579_creature_enters_draw_new_server_commander_legal.json` | 41,729,216 | `064d0972a6ceb86cb778db27c2ab45675d9dcaefece4e4b085494c11aa4b8546` | sibling `.md` summary |
| `xmage_authoritative_adaptation_queue_20260706_post_pg580_current_commander_legal.json` | 41,729,216 | `277e3804e858f6a1a1b9af4f90f53a2e64a0aad59b3d81c6ed3fcc3f4e7a8d3f` | sibling `.md` summary |
| `xmage_authoritative_adaptation_queue_20260706_post_pg581_each_player_sacrifice_new_server_commander_legal.json` | 41,718,731 | `406abf1ee110c221749678e4b9178089ac7bf566e21ca41786779d41c92a9c92` | sibling `.md` summary |
| `xmage_authoritative_adaptation_queue_20260707_post_pg582_exile_restricted_targets_new_server_commander_legal.json` | 41,706,400 | `01b28cb99af9a83a40816c63f825f62f58f3a02a066e5b8d07a2f52efb99c9be` | sibling `.md` summary |
| `manaloom-knowledge/decks/lorehold-the-historian/BATTLE_LOG.md` | 14,922,231 | `07a929378d1a517da07d8456dbfe52266b810cede34213011d680de1e52dceed` | compact pointer at the same path; future logs under `/tmp/manaloom-battle-logs` |

To inspect an archived original without restoring it into the checkout:

```bash
git show 4700fc38317aae0d3c1955176b32c18ac3b34339:<path>
```
