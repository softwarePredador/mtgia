# Life Counter Lotus Shell Policy - 2026-03-29

## Objective

Take ownership of the non-gameplay shell around the embedded Lotus counter without disturbing the validated gameplay baseline.

This policy is intentionally conservative:

- preserve the tabletop surface
- preserve gestures
- preserve overlays tied to gameplay
- suppress branding and outbound product promotion

## Current implementation

The ManaLoom host now enforces the shell policy in two layers:

1. Dart host navigation policy
2. injected runtime shell cleanup inside the WebView

## Layer 1 - Host navigation policy

File:

- `app/lib/features/home/lotus/lotus_shell_policy.dart`

Behavior:

- allow local bundle navigation
- allow non-network internal frame activity
- prevent top-level navigation away from the embedded counter
- explicitly block known Lotus marketing destinations

Blocked destinations today:

- `apps.apple.com`
- `play.google.com`
- `edh.wiki`
- `edh-combos.com`
- `combo-finder.com`
- `watchedh.com`
- `packsim.app`
- `forms.gle`
- `patreon.com`
- `www.patreon.com`
- `/?force=true`

Rationale:

- gameplay should stay inside ManaLoom
- Lotus store/promo links are not part of the counter baseline we want to preserve

## Layer 2 - Runtime shell cleanup

Files:

- `app/lib/features/home/lotus/lotus_host_controller.dart`
- `app/lib/features/home/lotus/lotus_shell_policy.dart`

Behavior:

- inject CSS/JS after page load
- suppress known branded runtime surfaces
- keep watching DOM mutations so late-created promo surfaces are also suppressed
- intercept clicks on blocked branded links
- intercept `window.open(...)` for blocked branded links

Suppressed selectors today:

- `#Content`
- `.lotus`
- `.patreon`
- `.feedback-btn-wrapper`
- `.feedback-btn`
- `.patreon-btn-wrapper`
- `.patreon-btn`

Rationale:

- these selectors are product shell or promotional surfaces
- they are not core tabletop gameplay
- hiding them is lower risk than rewriting minified Lotus runtime code

## What we are intentionally not changing yet

- player board layout
- commander damage flow
- turn tracker
- game timer
- card search gameplay behavior
- settings and in-game counters
- Planechase / Archenemy / Bounty gameplay surfaces

## Debug escape hatch

To temporarily disable the shell cleanup layer in debug:

```bash
flutter run --dart-define=DEBUG_LOTUS_DISABLE_SHELL_CLEANUP=true
```

This is intended only for debugging parity or investigating regressions.

## Next recommended task

`LC-SHELL-02 - Replace suppressed Lotus shell surfaces with ManaLoom-owned surfaces only where needed`

That next task should still avoid rewriting gameplay. It should focus on:

- owned messaging
- owned empty states
- owned integration affordances
- owned external routing, only when deliberate
