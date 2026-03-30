# Life Counter Lotus Static Shell Replacement - 2026-03-29

## Objective

Replace the last remaining static Lotus-owned landing shell with a ManaLoom-owned fallback shell, without altering the embedded gameplay runtime.

This targets only:

- `index.html`
- `platform.js`
- document title ownership

It does not touch:

- `app.min.js`
- gameplay state
- player board layout
- in-game gestures

## What changed

### 1. `index.html` now belongs to ManaLoom

Files:

- `app/assets/lotus/index.html`

Behavior:

- the fallback shell is now a minimal ManaLoom-owned page
- Lotus product name, store links, promo sections, Patreon, feedback, screenshots, and web-install copy were removed
- the page still loads the same CSS and gameplay runtime scripts

### 2. `platform.js` no longer rewrites to the Lotus Play Store listing

Files:

- `app/assets/lotus/js/platform.js`

Behavior:

- the old forced redirect target is gone
- if a legacy `app-store-link` node exists, it is neutralized rather than rewritten

### 3. document title ownership

File:

- `app/lib/features/home/lotus/lotus_shell_policy.dart`

Behavior:

- the host now forces the embedded document title to `ManaLoom Life Counter`

## Why this matters

Before this step, the gameplay surface was already mostly isolated, but the static shell still contained a full Lotus-owned landing page. That shell is now replaced by a ManaLoom-owned fallback, which reduces residual brand leakage without increasing gameplay risk.

Runtime note:

- `app/assets/lotus/` is the live runtime source of truth
- the local Android mirror is no longer treated as a sync target for this shell step

## Next recommended task

`LC-SHELL-04 - Audit optional helper overlays and guidance copy that still appears inside gameplay flows, then replace only the ones that remain product-facing`
