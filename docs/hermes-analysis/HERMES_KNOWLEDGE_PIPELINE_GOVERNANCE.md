# Hermes Knowledge Pipeline Governance

> Status atual: historico/snapshot antigo.
> Este arquivo ainda descreve parte da estrategia original das crons Lorehold.
> Para o contrato operacional atual, leia `docs/hermes-analysis/README.md` e
> `docs/hermes-analysis/HERMES_E2E_SYSTEM_CONTRACT_2026-06-07.md`.

Updated: 2026-06-01

## Purpose

The Lorehold crons are an intentional learning laboratory for ManaLoom. Their goal is to learn how strong Commander decks are built, validated, iterated, and explained, then convert that learning into deterministic backend logic so the product depends less on raw AI judgment over time.

This is not product proof by itself. It is research input.

## Separation Of Concerns

- `codex/hermes-analysis-docs`: memory, research, generated knowledge, methodology, and implementation tasks.
- `origin/master`: production code and product docs.
- `/opt/data/workspace/mtgia`: Hermes memory/docs worktree.
- `/opt/data/workspace/mtgia-master-audit`: read-only audit worktree tracking `origin/master`.

Lorehold learning may update docs and knowledge artifacts. It must not directly edit app/backend product code.

## Promotion Path To Product Logic

A learned pattern can become product logic only after this sequence:

1. Evidence appears in generated knowledge logs, deck simulations, or learned deck profiles.
2. `manaloom-knowledge-synthesis` converts it into an implementation task with code evidence.
3. A human/Codex reviews the task against the current backend/app code.
4. Product code is changed on `master` with focused tests.
5. Runtime/product validation is executed locally when visual/iOS behavior is involved.

## Current Useful Learnings

The current Lorehold laboratory produced useful tasks:

- Use `card_rulings` to validate interactions in optimize/generate quality checks.
- Add synergy-axis awareness beyond simple role equality in optimize quality gates.
- Detect MDFC/split-name duplicates in deck validation.
- Preserve wincon diversity concepts: fast, resilient, stealth.
- Treat mulligan/early-play metrics as measurable deck quality signals.

## Cron Frequency Policy

Learning crons should not run every 20-30 minutes indefinitely. The safe cadence is:

- Scout: every 180m.
- Validator: every 180m.
- Mulligan analyst: every 180m.
- Evolution oracle: every 240m.
- Knowledge synthesis: every 240m.
- Wincon/deckbuilding research: every 360m or manual/on-demand while scripts mature.
- Product master audit: every 360m, separate from Lorehold learning.

## Output Rules

Cron outputs must be evidence-backed.

Allowed outputs:

- Markdown logs under `docs/hermes-analysis/**`.
- SQLite research DB under `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`.
- Implementation tasks under `docs/hermes-analysis/IMPLEMENTATION_TASKS.md`.

Not allowed:

- Raw secrets, DB URLs, PATs, API keys, DSNs, private HTML.
- Claims of iPhone Simulator, Android runtime, or visual proof from Linux.
- Direct product code edits without explicit request.
- Repeated noisy logs with no new conclusion.

## When A Cron Should Be Silent

Return exactly `[SILENT]` when:

- The deck hash did not change and the previous result still applies.
- A query returns no new candidates.
- The job would only repeat prior methodology without new evidence.

## Handling Dirty Workspace

Before committing:

1. `git status --short --branch`.
2. Review generated files.
3. Run a staged/changed-file secret scan.
4. Commit only memory/knowledge artifacts.
5. Push only `codex/hermes-analysis-docs`.

If a product-code issue is discovered, document it as an implementation task. Do not fix product code from Hermes.

## Known Limitations

- Hermes runs on Linux and cannot validate iPhone Simulator UI.
- Hermes can run backend tests and Flutter analyze, but not real iOS runtime proof.
- Some wincon jobs still need script hardening; until then, their outputs are research drafts, not product requirements.
