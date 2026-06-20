# ManaLoom Post-Loop Smoke And Next Cycle - 2026-06-20

## Scope

This register closes the post-publication organization cycle after the
documentation heartbeat loop fix. It records stable evidence only:

- no deck swap was applied;
- no PostgreSQL write was performed;
- production smoke used only `GET` calls and local artifact reads;
- exact "current HEAD" must not be recursively re-stamped in tracked heartbeat
  docs after documentation-only commits.

## Worktree And Deploy Evidence

- Heartbeat-loop closure commit tested before this register:
  `3800c940501ba687369c5d8208d9eccfad0c1dcc`
  (`docs: close ManaLoom heartbeat loop`).
- Production `/health` matched that closure commit before this register was
  created: `status=healthy`, `environment=production`.
- After a 75-second post-commit wait, the worktree stayed clean:
  `git status --short --branch` showed only `## master...origin/master`;
  untracked non-ignored count was `0`;
  `git rev-list --left-right --count HEAD...origin/master` returned `0 0`.
- This register intentionally does not claim to be the final deployed SHA after
  its own commit. The final handoff for this cycle must use live `/health` and
  Git status, not another tracked heartbeat restamp.

## Production Read-Only Smoke

Smoke artifact:
`/tmp/manaloom_production_readonly_smoke_20260620_1358.json`

Result: `verdict=pass`.

Read-only public checks:

- `GET /health`: HTTP `200`, `status=healthy`,
  `git_sha=3800c940501ba687369c5d8208d9eccfad0c1dcc`.
- `GET /ready`: HTTP `200`, `status=ready`, database `healthy`,
  `cards_data.card_count=34329`.
- `GET /health/ready`: HTTP `200`, `status=ready`, database `healthy`,
  `cards_data.card_count=34329`.
- `GET /cards?name=Velomachus+Lorehold&limit=5`: HTTP `200`,
  `total_returned=1`, first result `Velomachus Lorehold`.
- `GET /community/decks?format=Commander&limit=1`: HTTP `200`, `rows=1`,
  public Commander total `45`.
- `GET /community/decks/1c3a57ee-98de-42a4-bf35-982558e3b930`: HTTP `200`,
  detail shape included `main_board`, `all_cards_flat`, `stats`, and owner
  fields. This public QA fixture had only one main-board row, so it proves
  route shape and DB reachability, not full 100-card Commander quality.
- `GET /rules?q=Commander&limit=3&meta=true`: HTTP `200`, `rows=3`,
  metadata included.

Expected auth-boundary checks:

- `GET /ai/ml-status` without token: HTTP `401`, JSON auth error.
- `GET /ai/commander-learning` without token: HTTP `401`, JSON auth error.

Battle smoke boundary:

- Live `POST /ai/simulate`, `POST /ai/simulate-matchup`, and deck write routes
  were not called because they are write-capable.
- Latest local battle artifact remains the read-only battle evidence:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_160459/summary.json`.
- That artifact reports `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, and `test_results_status_counts.pass=16`.

## Active Next Cycle

### 1. Deck Learned-Deck QA

Source:
`docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.json`.

Aggregate state:

- active learned decks: `60`;
- high severity: `2`;
- medium severity: `13`;
- `commander_deck_quantity_mismatch=1`;
- `commander_quantity_mismatch=1`;
- `land_count_low_review=7`;
- `land_count_high_review=1`;
- `some_core_metadata_zero=5`.

Highest priority:

- `learned_deck:7` / `Korvold, Fae-Cursed King`:
  `parsed_quantity=90`, `resolved_quantity=90`, expected `100`;
  commander quantity actual `0`, expected `1`. This is a real deck-quality
  issue and should be investigated before any strategic use of this learned
  deck.

Medium land-count reviews:

- `learned_deck:105` / `Aang, at the Crossroads`: `23` lands.
- `learned_deck:150` / `Brigid, Clachan's Heart`: `23` lands.
- `learned_deck:173` / `Krark, the Thumbless`: `23` lands.
- `learned_deck:131` / `Lumra, Bellow of the Woods`: `48` lands.
- `learned_deck:104` / `Ral, Monsoon Mage`: `14` lands.
- `learned_deck:114` / `Rowan, Scion of War`: `23` lands.
- `learned_deck:137` / `Selvala, Explorer Returned`: `20` lands.
- `learned_deck:95` / `Yuriko, the Tiger's Shadow`: `22` lands.

Medium metadata-counter reviews:

- `learned_deck:5` / `Atraxa, Praetors' Voice`: `tutor_count=0`.
- `learned_deck:1` / `Krenko, Mob Boss`: `tutor_count=0`.
- `learned_deck:127` / `Sauron, Lord of the Rings`: `tutor_count=0`.
- `learned_deck:124` / `The Emperor of Palamecia`: `tutor_count=0`.
- `learned_deck:120` / `Yorion, Sky Nomad`: `tutor_count=0`.

Lorehold status:

- Lorehold `learned_deck:82` remains clean in the same artifact with
  `issues=[]`; it is not the first next-cycle target unless new evidence appears.

### 2. Battle Follow-Up

Latest battle is trusted and has no mandatory gate divergences. Remaining
strategy observations are not blockers:

- `strategy_findings=5`;
- all five are `forced_keep_after_bad_mulligan`;
- severity is `medium`;
- `strategy_review_required_findings=0`;
- `action_findings=0`;
- `decision_audit_decision_findings=0`;
- `forensic_rule_findings=0`;
- `forensic_turn_findings=0`.

Next battle work should improve confidence labeling around forced mulligan-cap
keeps or add specific decision-trace contracts for currently uncovered accepted
types. It should not trigger a PostgreSQL deploy by itself.

### 3. Production Smoke Gap

Authenticated production deck/AI reads were not fully smoked because no reusable
read-only QA token was available in this cycle, and creating a production test
user would be a DB write.

Next safe options:

1. use an existing QA token if Rafael provides one;
2. create a documented non-production or explicitly authorized production QA
   read fixture;
3. add a backend-owned read-only smoke route only if product/security policy
   accepts it.

### 4. PostgreSQL Gate

No current PostgreSQL apply is ready.

PG-003 remains blocked by policy:

- oracle/card text/type backlog still exists;
- previous planner state had `missing_any=363`;
- `backfill_ready=0`;
- `db_mutations=false`.

The next PostgreSQL write may happen only when all items below exist together:

1. exact row-level diff;
2. source-of-truth policy for the rows;
3. read-only precheck;
4. apply SQL;
5. rollback SQL;
6. postcheck SQL;
7. runtime or artifact evidence after apply.

Until then, deck and battle investigation should stay in code/tests/artifacts,
not database mutation.
