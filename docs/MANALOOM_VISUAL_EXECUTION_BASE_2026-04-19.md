# ManaLoom Visual Execution Base

Date: 2026-04-19

Status: Active visual source of truth for the non-Life-Counter app experience

## Purpose

This document defines the visual direction, execution rules, QA criteria, and agent expectations for the ManaLoom Flutter app outside the Life Counter.

It exists to stop visual drift, reduce color indecision, and keep agents aligned on the same target.

This is not a vague inspiration note. It is an operating document.

## Design conclusion

After comparing the current ManaLoom app against live reference captures from `MTG Life Counter: Mythic Tools`, the best direction for ManaLoom is:

`Obsidian + Brass + Frost Blue`

Purple is no longer a required anchor color for the general app.

## Visual goal

ManaLoom should feel:

- premium
- dark and intentional
- collectible-aware
- strategically technical
- more mature than flashy
- more coherent than expressive-for-expression's-sake

The app should not feel:

- neon
- over-themed
- overly purple
- visually noisy
- like several unrelated sub-products glued together

## Color system

### Core surfaces

- `obsidian-950`: `#0F1115`
- `obsidian-900`: `#171A21`
- `slate-800`: `#232735`
- `slate-700`: `#2B3142`

Use these for:

- app backgrounds
- scaffold surfaces
- cards
- sheets
- elevated containers
- navigation chrome

### Text

- `ivory-100`: `#F3EFE3`
- `mist-300`: `#B8C0CC`
- `mist-500`: `#8A93A3`

Use:

- `ivory-100` for titles and high-priority text
- `mist-300` for body/supporting text
- `mist-500` for disabled or tertiary text only

Avoid pure white as the default primary text.

### Primary action

- `brass-500`: `#C58B2A`
- `brass-400`: `#E0A93B`
- `brass-700`: `#8E641B`

Use brass for:

- primary CTA
- active states
- high-priority emphasis
- economic/value moments
- deck improvement or important product decisions

Brass should feel deliberate, not everywhere.

### Secondary support

- `frost-400`: `#6FA8DC`
- `frost-600`: `#3E5F8A`

Use frost blue for:

- informational accents
- filters
- navigation support states
- technical indicators
- quiet secondary emphasis

Do not let frost blue replace brass as the main action color.

### Semantic status

- `success`: `#4FAF7A`
- `warning`: `#D28B2C`
- `error`: `#C65A46`

## Color usage rules

1. One screen should have one dominant action color.
2. Brass is the primary product action color.
3. Frost blue supports, but does not lead.
4. Large background regions should stay within the obsidian/slate family.
5. Avoid mixing purple, blue, gold, green, and red at the same visual level.
6. A card should feel like it belongs to the same family as the rest of the app.
7. If a screen needs more color to feel interesting, first improve hierarchy before adding color.

## Component direction

### Cards

Cards should be:

- darker than the page background, but only slightly
- softly rounded
- low-noise
- driven by internal hierarchy, not heavy borders

Cards should not be:

- overly outlined
- glowing by default
- dependent on bright fills to feel clickable

Preferred structure:

- title
- short supporting line
- one primary action
- one optional secondary action

### Buttons

Primary buttons:

- brass background
- dark text only if contrast is clearly strong, otherwise ivory text
- bold and compact

Secondary buttons:

- slate surface
- subtle outline or tonal separation
- frost blue or ivory text depending on context

Avoid using the same visual weight for primary and secondary actions.

### Top bars and headers

Top areas should be simplified.

Reduce:

- icon density
- duplicate controls
- multiple competing tab systems

Every screen should make the main task visible within the first scan.

### Tabs and filters

Tabs should not try to be the loudest thing on the screen.

Use:

- restrained text
- a clean active underline or tonal shift
- one accent color only

### Empty states

Empty states must feel thematic and intentional, not generic.

Each empty state should answer:

- what this area is for
- why it matters
- what the user should do next

## Typography direction

Use serif only where it adds meaning.

Recommended model:

- serif for brand moments, large titles, or featured deck identity
- sans for navigation, buttons, forms, tabs, and system text

Avoid using serif across dense utility UI.

Visual principle:

- fantasy flavor belongs in emphasis
- system usability belongs in sans-serif stability

## What must be improved in ManaLoom

### 1. Reduce visual noise

Why:

- Several screens currently feel busy before they feel useful.
- Too many elements compete for attention at once.

How:

- remove duplicate emphasis
- reduce accent color spread
- tighten top-level controls
- keep one visual hero per screen

### 2. Unify card family

Why:

- The app currently mixes multiple surface behaviors.
- This weakens product identity.

How:

- standardize background, radius, spacing, elevation behavior, and text hierarchy

### 3. Clarify CTA hierarchy

Why:

- Current primary actions do not always look meaningfully primary.

How:

- use brass for the key action
- make secondary actions quieter
- avoid equal-weight action rows

### 4. Improve deck screens first

Why:

- The deck journey is the product core.
- If deck screens feel weak, the product feels weak.

How:

- treat deck details, generation/import, optimize result, and validation as priority surfaces

### 5. Stabilize auth and onboarding polish

Why:

- Auth screens shape first impression
- they should feel elegant, not decorated

How:

- simplify glow usage
- reduce competing color accents
- strengthen spacing and CTA hierarchy

### 6. Make collection and binder feel more premium

Why:

- Collection is where users should feel ownership

How:

- simplify surface clutter
- improve search/filter rhythm
- make item cards and container cards feel deliberate

## AI analysis rubric

When an agent evaluates a ManaLoom screen, it must score or discuss all of these:

1. hierarchy
2. color discipline
3. spacing rhythm
4. card consistency
5. CTA clarity
6. typography clarity
7. contrast and readability
8. density/noise
9. empty/loading/error state quality
10. overall premium feel

Agents must answer:

- What is the first thing the eye sees?
- Is that the right thing?
- Is the screen visually calm or visually anxious?
- Are accent colors used with intention?
- Does the screen belong to the same product as the other screens?
- Would a user perceive this as polished or still prototype-like?

## QA comparison standard

When comparing against external references such as Mythic Tools:

- do not copy layouts literally
- do not copy assets
- do not copy brand marks
- do compare:
  - coherence
  - color discipline
  - modularity
  - premium feel
  - surface consistency
  - hierarchy strength

The correct question is:

- `what product-quality trait are they solving better than us?`

not:

- `how do we make our screen look the same?`

## Agent operating instructions

### ManaLoom App Visual QA

Must:

- read this document before judging visual direction
- use it as the scoring rubric
- capture fresh screenshots
- say plainly when a screen is still noisy, inconsistent, or weak
- write handoffs with references to these visual rules

### ManaLoom App Release Engineer

Must:

- read this document before implementing visual polish
- preserve the color system and hierarchy rules
- avoid solving every screen differently
- update handoffs with what changed and what remains

### ManaLoom Release Coordinator

Must:

- require this document as part of visual readiness
- refuse visual approval when changes contradict this direction
- coordinate App Visual QA and App Release Engineer using this as baseline

## Validation rules

A screen should only be considered visually approved when:

- fresh screenshots exist
- hierarchy is clear
- colors feel disciplined
- primary action is obvious
- there is no obvious overflow, crowding, or weak contrast
- the screen feels coherent with the rest of the app

## What “better than current” means

A better screen is one where:

- the eye lands correctly
- the action is obvious
- the palette feels controlled
- the card family feels unified
- the screen feels calmer and more premium

If a redesign introduces more “style” but less clarity, it is not better.

## Recommended execution order

1. auth screens
2. home shell and top-level navigation
3. deck entry screens
4. deck details
5. optimize/rebuild/apply states
6. collection/binder
7. profile/settings
8. secondary product surfaces

## Prompt contract for agents

When asking agents to work from this base, explicitly say:

- read `docs/MANALOOM_VISUAL_EXECUTION_BASE_2026-04-19.md`
- use the `Obsidian + Brass + Frost Blue` direction
- validate with fresh screenshots
- compare before/after
- do not approve based only on code

