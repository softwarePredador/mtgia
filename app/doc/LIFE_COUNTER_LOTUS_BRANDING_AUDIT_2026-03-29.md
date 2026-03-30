# Life Counter Lotus Branding Audit - 2026-03-29

## Objective

Identify everything in the embedded Lotus counter that still belongs to Lotus as a product, brand, promo surface, or external ecosystem.

This audit is intentionally limited to:

- branding
- copy
- links
- promo UI
- brand assets

It does not cover gameplay parity.

## Current conclusion

The embedded counter is already safe as a gameplay baseline, but it still carries Lotus-owned product shell content in three places:

1. static landing/content HTML
2. promo/link behavior
3. brand assets and promo visuals

The core tabletop gameplay surface appears much less coupled to Lotus branding than the supporting shell.

## Findings

### 1. Static product copy in `index.html`

File:

- `app/assets/lotus/index.html`

What is still Lotus-owned:

- product title:
  - `MTG Life Counter: Lotus`
- product description:
  - repeated use of `Lotus` as the app/product name
- store availability copy:
  - web
  - iOS App Store
  - Google Play for `com.vanilla.mtgcounter`
- QR launch copy:
  - `Scan to launch`
- screenshots section:
  - screenshots and alt text explicitly naming Lotus
- `More MTG tools` section:
  - external Lotus ecosystem sites
- feedback section:
  - `Black Lotus` / `LifeCounter.app` references
- `Support Lotus` section:
  - Patreon CTA
- home screen install instructions:
  - repeated `LifeCounter.app` references

Risk:

- high product mismatch
- low gameplay risk
- easiest branding surface to take over first

Recommendation:

- replace or remove this content before touching gameplay UI

### 2. External destinations still tied to Lotus

Files:

- `app/assets/lotus/index.html`
- `app/assets/lotus/js/platform.js`

Confirmed destinations:

- `https://apps.apple.com/app/id1498057193`
- `https://play.google.com/store/apps/details?id=com.vanilla.mtgcounter`
- `https://edh.wiki`
- `https://edh-combos.com`
- `https://combo-finder.com`
- `https://watchedh.com`
- `https://packsim.app`
- `https://forms.gle/ykdFrRDkuBJZzqRr7`
- `https://www.patreon.com/lifecounter`
- `/?force=true`

Special case:

- `app/assets/lotus/js/platform.js` rewrites an app-store link directly to:
  - `https://play.google.com/store/apps/details?id=com.vanilla.mtgcounter`

Risk:

- high brand leakage
- medium UX risk
- medium product risk because these routes can send users outside ManaLoom

Recommendation:

- decide per destination:
  - remove
  - replace with ManaLoom route
  - replace with ManaLoom external destination
  - keep only if intentionally approved

### 3. Promo / brand UI still present in runtime styles

Files:

- `app/assets/lotus/css/styles.min.css`
- `app/assets/lotus/js/app.min.js`

Observed branded runtime surfaces:

- `.lotus`
- `.patreon`
- `.feedback-btn`
- `.patreon-btn`

Associated visual behavior suggests there are promotional cards/banners for:

- Lotus app promotion
- Patreon support
- feedback CTA

Risk:

- medium to high brand mismatch
- uncertain runtime frequency until product shell is cleaned

Recommendation:

- either suppress these surfaces in the host layer
- or replace their content/assets before exposing them in ManaLoom

### 4. Lotus-branded assets in the bundle

Files / groups:

- logo and app brand:
  - `app/assets/lotus/images/lotus.svg`
  - `app/assets/lotus/images/app-icon.svg`
- support/promo:
  - `app/assets/lotus/images/patreon.svg`
  - `app/assets/lotus/images/qr.svg`
- promo screenshots:
  - `app/assets/lotus/images/screenshots/1.svg`
  - `app/assets/lotus/images/screenshots/2.svg`
  - `app/assets/lotus/images/screenshots/3.svg`
- social preview assets:
  - `app/assets/lotus/images/social/og.jpg`
  - `app/assets/lotus/images/social/twitter.jpg`
- app icon sets bundled from Lotus:
  - `app/assets/lotus/icon/**`

Risk:

- medium brand mismatch
- low gameplay impact

Recommendation:

- replace only after deciding whether the landing shell remains
- not urgent for tabletop parity

### 5. Store / install assumptions tied to `LifeCounter.app`

File:

- `app/assets/lotus/index.html`

What is embedded:

- install-to-home-screen guidance for Safari and Chrome
- repeated references to `LifeCounter.app`
- language that assumes a standalone web product, not ManaLoom

Risk:

- high product mismatch
- low technical risk

Recommendation:

- remove this entire section in the ManaLoom shell phase unless there is a deliberate web install strategy

## What does not look urgent to replace

These appear gameplay-facing rather than Lotus-brand-facing:

- counter icons
- commander / poison / energy / storm / tax icons
- planechase / archenemy / bounty icons
- most tabletop visuals on the player board
- background day/night images used as in-game surfaces

These can stay longer without confusing ownership as much as the marketing shell does.

## Priority order

### P1 - Remove or replace before broad release

- Lotus product name in `index.html`
- store links to the original Lotus app
- `More MTG tools`
- feedback Google Form
- Patreon support CTA
- `LifeCounter.app` references

### P2 - Replace in shell polish phase

- Lotus logos and app icon assets
- QR asset
- promo screenshots
- social images
- runtime promo cards/banners

### P3 - Review later

- any remaining copy inside minified JS that only appears in optional help/promotional overlays

## Recommended execution sequence

### Step 1

Create a `host-level link policy` for the embedded Lotus screen:

- allowed internal
- allowed external
- blocked
- replaced

### Step 2

Replace `index.html` shell copy with ManaLoom-owned copy or remove non-essential sections entirely.

### Step 3

Suppress or replace `.lotus`, `.patreon`, and feedback promo surfaces.

### Step 4

Swap Lotus-specific assets once shell decisions are final.

## Suggested next engineering task

### `LC-SHELL-01 - Define external link and branding policy for Lotus host`

Scope:

- inventory external destinations
- choose keep/replace/remove per destination
- define whether `index.html` remains visible at all in ManaLoom
- decide how branded promo surfaces should behave

Why this should be next:

- it removes the highest-risk product mismatch
- it does not disturb gameplay parity
- it gives us a clean contract before visual customization starts
