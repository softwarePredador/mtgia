# Lorehold Best Deck Review - 2026-06-20 14:51 -0300

## Scope

- Review current Lorehold deck generation state after PG-009 and runtime
  learned-deck guards.
- Test the current Lorehold deck with the official local battle strategy audit.
- Decide whether current evidence proves the deck is the best available deck.
- No deck swap, PostgreSQL write, code edit, app/backend route mutation, stash,
  revert, commit, or push was performed while producing this report.

## Sources Read

- `docs/CONTEXTO_PRODUTO_ATUAL.md`
- `docs/hermes-analysis/PROJECT_MEMORY.md`
- `docs/hermes-analysis/LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md`
- `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- PostgreSQL read-only queries against `decks`, `deck_cards`,
  `commander_learned_decks`, `card_intelligence_snapshot`,
  `commander_reference_decks`, and `card_battle_rules`.

## Current Deck Identity

- Hermes deck id: `6`
- PostgreSQL saved deck id:
  `528c877f-f829-4207-95e6-73981776c323`
- Saved deck name: `Runtime Lorehold Learned 19e93de3cca`
- Active learned deck id:
  `f46c0421-71b4-4de3-bb79-05a916b4988b`
- Active learned deck source: `hermes` / `learned_deck:82`
- Active learned deck name:
  `Lorehold Best-of Learned No Premium Mox 2026-06-02`

## Decklist Integrity Evidence

PostgreSQL read-only checks:

- deck rows: `100`
- summed quantity: `100`
- commander quantity: `1`
- lands: `33`
- non-land average CMC: `2.97`
- off-color rows for RW identity: `0`
- missing `oracle_id`: `0`
- missing `oracle_text`: `0`
- cards without functional tags: `0`
- cards with any battle rule: `97/100`
- cards with verified battle rule: `96/100`

Top role quantities from `card_intelligence_snapshot`:

- `ramp=53`
- `land=33`
- `mana_fixing=29`
- `enabler=24`
- `draw=20`
- `sacrifice=17`
- `engine=14`
- `payoff=13`
- `token/token_maker=12`
- `big_spell=11`
- `protection=9`
- `removal=8`
- `spellslinger=8`
- `tutor=7`

Interpretation:

- The current deck is structurally coherent and well-covered by the current
  intelligence layer.
- This evidence supports "playable/coherent current Lorehold deck"; it does not
  prove "best possible Lorehold deck".

## Learned-Deck Audit Evidence

Command:

```bash
python3 server/bin/learned_deck_coherence_audit.py --stdout
```

Result:

- active learned decks: `60`
- severity counts: `{"medium":13}`
- no high-severity learned-deck findings
- active Lorehold `learned_deck:82` remains clean in the latest full artifact
  `learned_deck_coherence_audit_20260620_172437.json`.

Focused tests:

```bash
cd server && dart test test/commander_learned_deck_support_test.dart test/ai_generate_learning_boundary_test.dart -r expanded
python3 -m unittest server/test/learned_deck_coherence_audit_test.py -v
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py
```

Results:

- Dart focused learned-deck/generate boundary: `26/26` passed.
- Python learned-deck coherence unit tests: `19/19` passed.
- Runtime surface manifest test: `PASS`.

## Canonical Snapshot / Optimizer Gate Evidence

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_canonical_deck_snapshot.py \
  --deck-id 6 \
  --out-dir docs/hermes-analysis/master_optimizer_reports \
  --prefix lorehold_best_deck_review_snapshot_20260620_174509
```

Generated:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_best_deck_review_snapshot_20260620_174509.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_best_deck_review_snapshot_20260620_174509.md`

Result:

- status: `blocked`
- local hash:
  `dbe24f7d5b17fbc8663afcd187d6381ccfb840f8a3b6486c4bdfad504c9d53fa`
- local semantics hash:
  `faba6b52faec032877fb935d480f8179384b81074fe6f5d465dfd3702a06e7ce`
- local ruleset hash:
  `02bd8e0e5176288d39f8c161193179f42f7611e2910a1842f15578655907a405`
- validation errors:
  - `expected Wheel of Misfortune present`
  - `expected Reforge the Soul absent`

Quality gate command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_quality_gate.py --deck-id 6 --report
```

Result:

- failed before quality scoring because current deck hash does not match the
  latest approved baseline.
- current hash:
  `dbe24f7d5b17fbc8663afcd187d6381ccfb840f8a3b6486c4bdfad504c9d53fa`
- approved baseline hash:
  `f6367a273eef6dc41b09e58c50e79738aab73719e85986a4309020448052c1ac`

Interpretation:

- The current deck is not aligned with the optimizer's approved baseline.
- The known canonical decision still expects `Wheel of Misfortune` over
  `Reforge the Soul`.
- Therefore current evidence blocks any claim that this exact list is the
  best-approved Lorehold list.

## Battle Audit Evidence

Command:

```bash
MANALOOM_REPO_DIR=/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia \
MANALOOM_BATTLE_STRATEGY_INVOCATION_KIND=manual_lorehold_best_deck_review \
/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 16
```

Generated latest run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_174219/summary.json`

Result:

- run profile: `recurring_16_seed`
- run scope: `recurring_full`
- seeds requested/completed: `16/16`
- tests: `16/16` pass
- runtime surface manifest: `runtime_surface_manifest_ready`
- final status: `review_required`
- mandatory gate divergences:
  - `action_critic=review_required`
  - `forensic_audit=review_required`
  - `replay_decision_audit=review_required`
- strategy audit status: `pass`
- strategy review-required findings: `0`
- strategy low-confidence seeds: `63211743`, `63211751`
- raw Lorehold result: `13/16` wins, `81.2%` raw WR.

Blocking evidence:

- Seed: `63211753`
- Opponent: `Tayam, Luminous Enigma #116 (real)`
- Card: `Aven Mindcensor`
- Event: `creature_cast`
- Current rule source/status:
  `known_cards_canonical_snapshot / needs_review / review_only`
- Action critic finding:
  `review_rule_used`
- Forensic finding:
  `Game event depended on a needs_review rule.`
- Replay decision finding:
  `Decision used needs_review rule; keep as audit-only.`

PostgreSQL read-only check for `Aven Mindcensor`:

- `battle_rule_count=1`
- `verified_battle_rule_count=0`
- only rule:
  `generated / needs_review / review_only`
- effect JSON:
  `{"effect":"creature","cmc":3.0,"power":3}`
- oracle text includes a static library-search limiter:
  "If an opponent would search a library, that player searches the top four
  cards of that library instead."

Replay context:

- In seed `63211753`, `Aven Mindcensor` was cast on turn `13`.
- No later tutor/search resolution was found before the relevant end of that
  replay.
- Earlier tutor/search actions happened before Aven entered.

Interpretation:

- The battle run gives positive raw performance signal for Lorehold, but the
  aggregate replay is not trusted for strategy learning.
- The current blocker is not a Lorehold decklist problem; it is battle/runtime
  coverage for an opponent card.
- Promoting Aven as a generic creature would be unsafe unless the static search
  limiter is explicitly modeled, waived with a narrow seed-level rationale, or
  the gate learns to distinguish harmless creature-only use from search-limiter
  use.

## Candidate Comparison Evidence

Current active learned deck:

- `learned_deck:82`
- score: `136.5`
- card count: `100`
- parsed quantity: `100`
- `has_reforge=true`
- `has_wheel_misfortune=false`

Inactive premium learned row:

- `deck-81-premium`
- score: `150.0`
- card count: `100`
- parsed quantity: `100`
- `has_reforge=true`
- `has_wheel_misfortune=false`
- inactive and lacks current canonical metadata fields.

Accepted reference Lorehold rows:

- `edhrec_lorehold_Bn4UCaNCLKSTPqkwxUnStQ`
  - main `99`, commander `1`, accepted `true`, unresolved `0`, off-color `0`
- `edhrec_lorehold_A_z1s_GftOaC6u75p7_TDw`
  - main `99`, commander `1`, accepted `true`, unresolved `0`, off-color `0`
- `edhrec_lorehold_3SFEtbTKhht92q7FXEd3qA`
  - main `99`, commander `1`, accepted `true`, unresolved `0`, off-color `0`

Interpretation:

- There are viable comparison candidates.
- None of the current learned/meta rows inspected proves that the active list is
  strictly best; the inactive premium row has a higher stored score but is not
  active and does not carry current canonical metadata.
- A proper "best deck" decision requires re-freezing the current baseline or
  restoring the canonical Wheel/Reforge decision, then running a controlled
  slot-scan/quality-gate/confirmation loop.

## Verdict

Current deck status:

- Structurally coherent: yes.
- Current learned-deck source healthy: yes.
- Current generation path guarded against incomplete learned decks: yes.
- Raw battle performance from latest manual full run: positive (`13/16`, raw
  `81.2%`).
- Battle trusted for strategy learning: no, because latest aggregate status is
  `review_required`.
- Optimizer/baseline aligned: no.
- Proven best Lorehold deck: no.

Operational conclusion:

- Do not apply a deck swap yet.
- Do not claim this exact deck is the best approved Lorehold deck yet.
- The next correct work is not a blind card swap. It is to restore trusted
  comparison conditions:
  1. resolve the Aven Mindcensor battle gate without hiding the static
     library-search limiter;
  2. decide whether canonical Lorehold should use `Wheel of Misfortune` over
     `Reforge the Soul` or whether the baseline decision is outdated;
  3. freeze a fresh baseline from the approved exact list;
  4. rerun slot scan / quality gate / confirmation / battle replay from that
     frozen baseline.
