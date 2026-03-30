# Life Counter Lotus Gameplay Copy Audit - 2026-03-29

## Objective

Audit helper copy that still appears inside gameplay flows and replace only the text that still feels product-facing or excessively Lotus-specific.

This phase intentionally avoids editing the minified Lotus gameplay runtime directly.

## Strategy

The host now applies a small set of runtime text replacements from the shell policy layer.

Why:

- lower risk than patching `app.min.js`
- keeps gameplay logic intact
- makes the replacements easy to review and remove later

## Replacements added

File:

- `app/lib/features/home/lotus/lotus_shell_policy.dart`

Current replacements:

- turn tracker hint copy
- counters-on-card hint copy
- generic clipboard confirmation copy
- bounty load failure wording
- generic fatal error wording replacing the Cyclonic Rift joke

## Additional shell suppression

Also suppressed for safety:

- `.feedback-btn`
- `.patreon-btn`

These are in addition to the wrapper-level shell suppression already in place.

## What we intentionally did not replace

- game mode names like `Planechase`, `Archenemy`, and `Bounty`
- gameplay instructions that are rules-facing rather than product-facing
- table labels like `Back`, `Flip`, `Claim`, or `Got it!`

## Why this matters

At this point the embedded counter is much closer to feeling like a ManaLoom-owned experience even when a user hits hints, prompts, or failure states during play.

## Next recommended task

`LC-SHELL-05 - Validate live overlays in the emulator and replace only the copy that still feels off in real interaction`
