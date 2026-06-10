# Hermes AWS Operational Audit — 2026-06-04

## Verdict

**PASS_WITH_RISKS.** Hermes on AWS is operational and now aligned with the ManaLoom learning loop, but it must remain a supervised automation layer. It can audit, import learning events, promote eligible learned decks, and dry-run sync learned decks into the backend pipeline. It must not be treated as an autonomous production deployer.

## Environment Checked

- Host: AWS EC2 `3.16.217.179`, Ubuntu 24.04, Docker/EasyPanel.
- Container/service: `hermes_agent`.
- Hermes CLI: `/opt/hermes/.venv/bin/hermes`.
- ManaLoom memory workspace: `/opt/data/workspace/mtgia` on `codex/hermes-analysis-docs`.
- ManaLoom sync workspace: `/opt/data/workspace/mtgia-sync` on `master`.
- ManaLoom master audit workspace: `/opt/data/workspace/mtgia-master-audit` on `master`.

## Corrections Applied Remotely

- Fixed `/opt/data/cron/jobs.json` permissions from root-owned to `hermes:hermes`, preserving backup under `/opt/data/cron/jobs.json.bak.codex_*`.
- Disabled the host-level Ubuntu crontab that ran `analyze_lorehold_cards.py` every 5 minutes outside Hermes governance; backup saved under `/opt/data/admin-backups/`.
- Converted the three learning-loop jobs from one-shot schedules to recurring schedules:
  - `manaloom-pull-learning-events`: every 30 minutes.
  - `manaloom-auto-sync-learned-decks`: every 120 minutes.
  - `manaloom-auto-promote-learned`: every 360 minutes.
- Updated `/opt/data/scripts/auto_sync_learned_decks.py` and `/opt/data/scripts/auto_promote_learned_decks.py` to match `origin/master` `70e170f0`.
- Updated `/opt/data/workspace/mtgia-sync` to `70e170f0` so cron sync uses the hardened Commander learned-deck importer.
- Removed accidental product-code drift from the Hermes memory branch by saving the diff to `docs/hermes-analysis/ops-audits/REMOTE_PRODUCT_CODE_DIRTY_PATCH_2026-06-04.diff` and restoring `server/routes/ai/commander-learning/index.dart`.

## Functional Flow Validated

1. App/backend writes deck-learning signals through `deck_learning_events` and `commander_card_usage`.
2. Hermes `pull_learning_events.sh` reads unsynced events from PG into Hermes SQLite.
3. Hermes `auto_promote_learned_decks.py` only promotes learned decks that pass strict Commander 100-card structure by default.
4. Hermes `auto_sync_learned_decks.py` defaults to dry-run, skips Lorehold for manual review, and imports only through `commander_learned_deck.dart --strict`.
5. Backend exposes promoted learned decks through `/ai/commander-learning`.
6. App shows learned-deck CTA only when a promoted Commander deck exists.
7. Generate/reference prompts can consume real-player usage hot cards while filtering commander and duplicate names.

## Evidence

- Public backend health: `git_sha=70e170f0d033521b449c5cf197b5d9331451879a`.
- Hermes safe runs:
  - `pull_learning_events.sh`: completed, no new events.
  - `auto_promote_learned_decks.py`: completed, no eligible incomplete promotion.
  - `auto_sync_learned_decks.py`: completed in dry-run, skipped Lorehold manual, no failures.
- Server focused tests passed:
  - `dart test test/deck_learning_event_support_test.dart test/commander_learned_deck_support_test.dart -r expanded`
- App focused tests passed:
  - `flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart --no-version-check --reporter compact`
- iOS Simulator public runtime passed on `iPhone 15 Pro Max` simulator:
  - `commander_learned_deck_availability_runtime_test.dart`: learned-deck button appeared for Atraxa, Kinnan, Korvold, Lorehold, and Winota.
  - `commander_learned_deck_runtime_test.dart`: Lorehold preview/save produced Commander deck with total `100`, main `99`, commander count `1`, and no Chrome Mox, Mox Diamond, or Mox Opal.

## Remaining Risks

- Hermes dashboard logs still show auth/bind warnings. CLI and cron work, but dashboard hardening should be reviewed separately.
- Hermes memory workspace still contains normal cron artifacts under `docs/hermes-analysis/manaloom-knowledge/**`; these must not be confused with product-code drift.
- Some LLM-based cron jobs may still hit provider/rate-limit constraints. No-agent scripts are reliable; LLM audit jobs remain best-effort.
- Learned-deck auto-sync remains dry-run by default. Production mutation requires explicit `--apply` or `HERMES_AUTO_SYNC_APPLY=1`.

## Operating Rule

After every local `master` push that touches backend/app learning logic, run or wait for Hermes audit, then review Hermes output before continuing feature work. Hermes can validate and document findings, but product code changes must still be implemented and proven locally with Dart/Flutter tests and iOS Simulator runtime when app behavior changes.
