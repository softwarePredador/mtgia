# Life Counter Lotus Owned Affordances - 2026-03-29

## Objective

Add ManaLoom-owned shell behavior around the embedded Lotus counter without altering the validated gameplay surface.

This step intentionally targets only host-owned affordances:

- loading
- error recovery
- blocked external shortcut messaging

## What was added

### 1. ManaLoom loading overlay

Files:

- `app/lib/features/home/lotus_life_counter_screen.dart`
- `app/lib/features/home/lotus/lotus_host_overlays.dart`

Behavior:

- replaces the generic black spinner with a ManaLoom-branded loading surface
- still covers only the startup window before the Lotus board is ready
- does not alter the board after the WebView is loaded

### 2. ManaLoom error overlay with retry

Files:

- `app/lib/features/home/lotus/lotus_host_controller.dart`
- `app/lib/features/home/lotus/lotus_host_overlays.dart`

Behavior:

- if the main frame fails to load, the host now shows an owned recovery state
- the user gets a clear retry action without exposing WebView internals

### 3. Owned feedback for blocked external shortcuts

Files:

- `app/lib/features/home/lotus/lotus_js_bridges.dart`
- `app/lib/features/home/lotus/lotus_shell_policy.dart`
- `app/lib/features/home/lotus_life_counter_screen.dart`

Behavior:

- when the embedded bundle tries to open Lotus-owned external shortcuts, the host can surface a native ManaLoom snackbar
- this replaces silent failure and keeps control in the host layer

## What still stays unchanged

- the tabletop layout
- gesture model
- counters and overlays
- turn tracker
- game timer
- game mode behavior

## Why this matters

This is the first step where the shell becomes visibly ManaLoom-owned while the actual counter still remains Lotus-faithful.

That gives us:

- lower product mismatch
- better recovery UX
- a host-owned surface we can keep when we later replace more Lotus internals

## Next recommended task

`LC-SHELL-03 - Replace remaining Lotus-owned optional shell assets and helper copy only when they are visible in ManaLoom flows`
