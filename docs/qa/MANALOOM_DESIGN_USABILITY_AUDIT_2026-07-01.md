# ManaLoom design and usability audit - 2026-07-01

## Verdict

Status: `PASS_WITH_SCOPE_LIMITS`.

The app does not show a current P0/P1 visual blocker from the evidence reviewed
and commands rerun today. It is usable for the proven non-scanner product scope,
and the main native app surfaces are aligned around the Obsidian / Brass /
Frost visual system.

This is closed for the requested static-token and usability cleanup scope:
objective static drift is zero, local tests pass, and prior iPhone Simulator
smoke coverage captures the main non-scanner, Life Counter and learned
Commander flows. Scanner/camera/OCR and pixel-level approval against an
external mockup remain outside this pass.

## Scope

Audited:

- Flutter app shell, routes and native non-scanner surfaces.
- Theme system and token discipline.
- Visual pollution, color use, density, hierarchy and usability risks.
- Life Counter / Lotus as its own tabletop visual system.
- Runtime visual proofs from prior validated iPhone Simulator rounds.

Not fully approved by this pass:

- Scanner, camera, OCR and physical permission flows.
- Pixel-level approval against any external mockup.
- Exhaustive approval of every below-the-fold state of every long list.

## Current evidence

Current checkout at final documentation update:

- Branch: `codex/session-agent-xmage-mapper-20260630`
- Base SHA at latest static audit generation: `afc244e19`

Commands rerun today:

```bash
cd app && flutter analyze lib test --no-version-check
```

Result: `No issues found!`

```bash
cd app && flutter test test --no-version-check --reporter compact
```

Result: `01:12 +626: All tests passed!`

```bash
python3 server/bin/premium_visual_audit.py --include-life-counter --output docs/qa/manaloom_premium_visual_audit_latest.md
```

Result:

```text
VISUAL_PREMIUM_QA_RESULT: signals=0 P1=0 P2=0 visual_pass=false
```

Carried-forward iPhone Simulator evidence from prior validated rounds:

- Non-Life Counter visual capture:
  `integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart`
  on iPhone 15 Pro Max simulator
  `DABB9D79-2FDB-4585-94DB-E31F1288EE74` passed with
  `00:51 +1: All tests passed!`.
- Life Counter visual bundle:
  `life_counter_lotus_visual_capture_smoke_test.dart`,
  `life_counter_native_card_search_smoke_test.dart`,
  `life_counter_set_life_live_smoke_test.dart`, and
  `life_counter_native_player_appearance_color_card_live_smoke_test.dart`
  passed with `03:46 +5: All tests passed!`.
- Commander learned deck runtime:
  `integration_test/commander_learned_deck_runtime_test.dart` passed with
  `00:45 +1: All tests passed!`, including screenshots
  `01_no_commander_no_learned_button`, `02_commander_learned_button_visible`,
  `03_hermes_preview`, and `04_saved_deck_details`.

Supporting historical visual evidence reviewed:

- `docs/qa/MANALOOM_INTERNAL_NON_SCANNER_VISUAL_RELEASE_REVIEW_2026-06-05.md`
  reported `PASS_WITH_RISKS`, 33 extracted screenshots, and no P0/P1 visual
  blocker for internal non-scanner testing.
- `docs/qa/MANALOOM_STRICT_VISUAL_REVALIDATION_2026-06-05.md` reported
  `PASS_WITH_RISKS` for live iPhone Simulator proof and verified the previously
  reported Life Counter overlay / set-life sheet regressions.
- `docs/qa/manaloom_layout_uniformity_audit_iphone15_2026-05-22.md` reported
  uniformity for the non-scanner shell against the `Meus Decks` visual baseline.

## Static gate snapshot

The current premium gate found no objective drift signals in the configured
surfaces:

| Surface | P2 signals | Interpretation |
| --- | ---: | --- |
| Splash/Login/Cadastro | 0 | Static token/radius drift cleared. |
| Home | 0 | Static token/radius drift cleared. |
| Meus Decks | 0 | Baseline remains good in validated flows. |
| Detalhes do Deck | 0 | Static drift cleared; dense analytical areas remain watchlist items. |
| Criar/Gerar/Importar Deck | 0 | Static drift cleared; learned Commander preview validated on iOS. |
| Busca/Detalhe/Adicionar Carta | 0 | Small touch target candidates were raised to tokenized minimums where touched. |
| Colecao/Fichario/Marketplace | 0 | Border/radius token drift cleared in configured surfaces. |
| Trades/Mensagens/Notificacoes | 0 | Static drift cleared in configured surfaces. |
| Comunidade/Perfil | 0 | Static drift cleared in configured surfaces. |
| Life Counter/Lotus | 0 | Tabletop skin passes static token gate and current iOS visual smoke bundle. |

The prior saved premium report had 301 P2 signals, and an intermediate run had
227 P2 signals. The current run is zero objective signals. The script still
prints `visual_pass=false`; in this workflow that means the static gate does not
replace screenshot review, not that a P1/P2 signal remains.

## Design assessment

### Visual identity

Strong. The app has a recognizable premium MTG-adjacent product language:
dark obsidian surfaces, brass as primary action, frost blue as secondary
information, and restrained ivory text. The brand no longer reads like default
Material UI in the proven non-scanner flow.

Main risk: future drift if new screens copy old direct values instead of the
token scale.

### Visual pollution

Controlled in the main app, with dense feature areas kept on watchlist.

The largest pollution risk is not a single bad screen; it is accumulated
micro-chrome: borders with custom alpha, pill radii, chips, score/status badges,
domain colors, and analytical metadata in the same viewport. Deck details,
community/profile cards, binder/marketplace and Life Counter sheets are the
areas to keep under screenshot review when they change.

Life Counter is visually heavier than the native app, but that is intentional
because it is a tabletop/game surface. Its direct color, radius and text-style
decisions were tokenized where touched in this pass, and the current iOS visual
bundle validates its main overlays and sheets.

### Color use

Good product palette, acceptable current discipline.

The strongest current proof is `app/test/core/theme/app_theme_token_usage_test.dart`:
shared app surfaces are checked for local hardcoded colors, while scanner and
life-counter skins are explicitly excluded because they have independent visual
systems.

Current proof:

- Current configured premium gate: `0` material color/radius/border signals.
- Life Counter and special skins are now static-token clean in configured
  surfaces; screenshots remain the approval source for intentional visual
  exceptions.

### Usability

Good for the proven internal non-scanner scope.

The app has clear primary flows, protected routes, visible loading/error/empty
states in many surfaces, and prior live evidence for splash, auth, home, deck
flows, collection, community, profile, messages, notifications, trades and Life
Counter overlays.

Remaining usability limits:

- Generate/import/deck analysis can still feel dense when heavily populated.
- Scanner/camera/OCR remains outside this approval.
- Long scrollable surfaces can still hide below-the-fold visual issues.

### Typography and hierarchy

Mostly strong. Inter is the utility font and Fraunces is reserved for
brand/display hierarchy. This gives the app a clearer product voice than the
older mixed system.

Remaining risk: isolated `TextStyle(...)` literals still exist in some
specialized flows. They are not blockers, but they should be reduced when
touching those screens.

## Priority backlog

P1: none found in today's design/usability pass.

P2 for the requested scope: none remaining.

Watchlist:

1. Keep Scanner/camera/OCR as a separate design QA track.
2. Keep Life Counter / Lotus on its own screenshot review when changing its
   tabletop layout.
3. Keep replacing newly introduced border/radius/text literals with `AppTheme`
   tokens during future feature work.
4. For each app-facing layout change, rerun the premium static gate plus the
   relevant iPhone Simulator capture suite.

## Release interpretation

Internal non-scanner testing can continue.

For the requested scope, design/usability cleanup is closed:

- app visual system: good and coherent;
- visual pollution: controlled in the validated surfaces;
- color system: strong and static-token clean in configured gates;
- usability: acceptable for proven non-scanner flows;
- exclusions: Scanner/camera/OCR, external mockup parity, and exhaustive
  below-the-fold review.
