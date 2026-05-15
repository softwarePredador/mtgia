# Docs and artifact retention audit - 2026-05-15

## Verdict

**PASS_WITH_RISKS** for documentation/artifact cleanup on `master`.

Risks accepted:

- Historical proof folders remain versioned because they are cited by canonical
  docs, runtime handoffs, API map, release reports, production audits, or
  Commander Reference readiness evidence.
- Scanner/camera/OCR documents remain as historical/deferred evidence only; they
  are not a functional gate for the current non-scanner round.
- Large Commander Reference and MTG data integrity JSON/CSV artifacts remain
  versioned when they act as scorecards, summaries, readiness inputs, corpus
  evidence, or data-integrity proof.
- The final workspace scan is clean for strict secret-value patterns, but the
  patch necessarily contains removed-line hits for pre-existing values that were
  redacted in this change.

## Scope read

- `docs/README.md`
- `server/doc/FULL_FLOW_STATE_AND_DOC_AUDIT_2026-05-15.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `server/manual-de-instrucao.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `app/doc/runtime_flow_handoffs/`
- `app/doc/runtime_flow_proofs_*`
- `server/test/artifacts/`

Tracked inventory in scope at audit time: **1077 files**.

## Retention matrix

| Category | Paths / groups | Reason | Last relevant commit | Active reference | Risk if removed |
|---|---|---|---|---|---|
| KEEP/ACTIVE | `docs/README.md`, `server/manual-de-instrucao.md`, `server/doc/API_CONTRACTS_AND_DATA_MAP.md`, `app/doc/APP_AUDIT_2026-04-29.md`, `app/doc/UI_TEST_SURFACE_MAP.md`, `docs/qa/MANALOOM_INTERNAL_TEST_CHECKLIST_2026-05-15.md`, `server/doc/INTERNAL_TEST_ROUND_READY_2026-05-15.md`, `app/doc/runtime_flow_handoffs/README.md` | Current operational index, API contract map, app status, UI surface map, internal non-scanner release state and runtime handoff rules. | `24d9556` / `8c34db1` | `docs/README.md` canonical list and manual header rules. | High: agents would use stale contracts or lose current release readiness context. |
| KEEP/ACTIVE | Recent Commander Reference reports and handoffs, including `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`, `server/doc/COMMANDER_REFERENCE_SPRINT4_EXECUTION_PLAN_2026-05-14.md`, `app/doc/runtime_flow_handoffs/commander_reference_feather_app_2026-05-15.md`, `app/doc/runtime_flow_handoffs/commander_reference_sprint4_lot1_app_2026-05-14.md` | Current Commander Reference readiness, app-runtime proof and promotion context. | `5c316ab` / `fca1142` | `docs/README.md`, `APP_AUDIT_2026-04-29.md`, manual entries. | High: could break promotion traceability and readiness decisions. |
| KEEP/HISTORICAL | Older root `docs/*.md` with references, for example `docs/CONTEXTO_PRODUTO_ATUAL.md`, `docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md`, `docs/SENTRY_SETUP_MTGIA_2026-03-24.md`, Life Counter sprint docs and UX audit docs | Historical planning/proof referenced by README, roadmap, active context, or related historical docs. | `f0ad766` / `c7b1b82` | `docs/CONTEXTO_PRODUTO_ATUAL.md`, `README.md`, `ROADMAP.md`. | Medium: removal would break historical links and hide product/ops decisions. |
| KEEP/HISTORICAL | `app/doc/runtime_flow_handoffs/scanner_*.md`, `app/doc/runtime_flow_proofs_*scanner*` | Scanner/camera/OCR are out of functional scope now, but prior deferred/blocker evidence must remain auditable. | `8cf8f17` / `f1465b2` | Runtime handoff README scanner scope and app audit deferred notes. | Medium: removal would erase why scanner is deferred and could reopen stale gates. |
| KEEP/HISTORICAL | `app/doc/runtime_flow_proofs_*`, visual proof folders, release screenshots and logs cited by handoffs | Evidence for runtime decisions, regressions, design/readiness and release handoffs. | `24d9556` group latest | `app/doc/runtime_flow_handoffs/*.md`, `APP_AUDIT_2026-04-29.md`, release docs. | Medium/high: proof chain and release evidence would become unverifiable. |
| KEEP/HISTORICAL | `server/test/artifacts/commander_reference_*`, `readiness_scorecard_summary.json`, `summary.json`, corpus/profile outputs | Required evidence for Commander Reference readiness and promotion; explicitly protected from deletion. | `fca1142` / `5c316ab` | Commander Reference reports, Sprint 3/4 tracker, app audit. | High: readiness and promotion claims would lose source artifacts. |
| KEEP/HISTORICAL | `server/test/artifacts/mtg_data_integrity_*` JSON/CSV | Data-integrity proof and backfill evidence; large but referenced by integrity reports. | `fca1142` group latest | `server/doc/RELATORIO_MTG_DATA_INTEGRITY_*.md`. | Medium: difficult to audit backfill candidates/results. |
| ARCHIVE | `docs/archive/2026-03/CONTRATO_OPTIMIZE_REBUILD_2026-03-23.md` | Legacy March contract note with no active reference; historical value retained. | `c64ab38` | No active reference found. | Low: archived path preserves history while removing it from active root docs. |
| ARCHIVE | `docs/archive/2026-03/PLANO_ABSORCAO_OPERACIONAL_REDIS_SENTRY_EASYPANEL_2026-03-23.md` | Legacy ops absorption plan with no active reference; historical value retained. | `c64ab38` | No active reference found. | Low: archived path preserves history while removing it from active root docs. |
| DELETE_CANDIDATE | Ignored/local-only `.DS_Store`, `*.pid`, `*.tmp`, backup files if they appear in doc/artifact trees | Clearly temporary OS/process artifacts; no historical or release value. | Not applicable | None. | Low if untracked; delete immediately when found. |
| DELETE_CANDIDATE | Raw auth payloads, Authorization headers, JWTs, real e-mails, complete decklists, `SENTRY_DSN`, `DATABASE_URL`, `OPENAI_API_KEY` values | Sensitive payloads must not be versioned. | Not applicable | None; if a cited artifact contains one, redact instead of deleting the cited proof. | High security risk if kept unredacted. |

## Files moved

| From | To | Why |
|---|---|---|
| `docs/CONTRATO_OPTIMIZE_REBUILD_2026-03-23.md` | `docs/archive/2026-03/CONTRATO_OPTIMIZE_REBUILD_2026-03-23.md` | No active reference; historical contract note retained in archive. |
| `docs/PLANO_ABSORCAO_OPERACIONAL_REDIS_SENTRY_EASYPANEL_2026-03-23.md` | `docs/archive/2026-03/PLANO_ABSORCAO_OPERACIONAL_REDIS_SENTRY_EASYPANEL_2026-03-23.md` | No active reference; historical ops plan retained in archive. |

## Files sanitized in place

The following files were kept because they are evidence or historical docs, but
sensitive values/payload fields were replaced with placeholders:

- `app/doc/runtime_flow_handoffs/binder_marketplace_trade_iphone15_2026-04-29.md`
- `app/doc/runtime_flow_handoffs/deck_runtime_2026-04-23.md`
- `app/doc/runtime_flow_handoffs/profile_community_iphone15_2026-04-30.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/doc/INTERNAL_RELEASE_STAGING_HANDOFF_2026-05-04.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_PROFILE_STRIXHAVEN_LOT2_2026-05-11.md`
- `server/doc/RELATORIO_META_DECK_INTELLIGENCE_2026-04-23.md`
- `server/doc/RELATORIO_META_DECK_INTELLIGENCE_2026-04-24.md`
- `server/test/artifacts/commander_optimize_flow_audit_2026-04-28/live_payload_summary.json`

## Files deliberately kept

- `server/test/artifacts/commander_reference_*` corpus, public proof, scorecard
  and summary JSON files.
- `server/test/artifacts/mtg_data_integrity_*` audit/backfill artifacts.
- `app/doc/runtime_flow_proofs_*` folders cited by runtime handoffs and app audit.
- Scanner/camera/OCR handoffs and proof folders as historical/deferred evidence.
- Visual proof screenshots and Life Counter proof folders cited by app docs.

## Commands executed

```bash
git status --short --branch
git fetch origin master --prune
git pull --ff-only origin master
git ls-files docs app/doc server/doc server/test/artifacts
find docs app/doc server/doc server/test/artifacts -type f
grep -RFn "live_payload_summary.json" docs app/doc server/doc server/test/artifacts
git mv docs/CONTRATO_OPTIMIZE_REBUILD_2026-03-23.md docs/archive/2026-03/CONTRATO_OPTIMIZE_REBUILD_2026-03-23.md
git mv docs/PLANO_ABSORCAO_OPERACIONAL_REDIS_SENTRY_EASYPANEL_2026-03-23.md docs/archive/2026-03/PLANO_ABSORCAO_OPERACIONAL_REDIS_SENTRY_EASYPANEL_2026-03-23.md
git diff --check
git diff --cached --check
python3 <doc-link-validation>
python3 <strict-secret-scan-workspace>
python3 <strict-secret-scan-added-and-removed-diff-lines>
cd app && flutter analyze lib test --no-version-check
```

Secret scans were run against file contents and the final diff with output
restricted to file paths or pattern names only. Added lines had no strict
secret-value hits; removed lines contained only pre-existing values redacted by
this audit.
