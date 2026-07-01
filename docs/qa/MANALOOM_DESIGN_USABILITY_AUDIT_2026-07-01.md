# ManaLoom design and usability audit - 2026-07-01

## Verdict

Status: `PASS_WITH_RISKS`.

The app does not show a current P0/P1 visual blocker from the evidence reviewed
and commands rerun today. It is usable for the proven non-scanner product scope,
and the main native app surfaces are aligned around the Obsidian / Brass /
Frost visual system.

This is not a global `PASS` for final design polish. The premium static gate now
reports zero objective drift signals, but intentionally keeps
`visual_pass=false` until current rich screenshots are reviewed screen by
screen.

## Scope

Audited:

- Flutter app shell, routes and native non-scanner surfaces.
- Theme system and token discipline.
- Visual pollution, color use, density, hierarchy and usability risks.
- Life Counter / Lotus as its own tabletop visual system.
- Existing runtime visual proofs from the latest validated iPhone Simulator
  rounds.

Not fully approved by this pass:

- Scanner, camera, OCR and physical permission flows.
- Pixel-level approval against any external mockup.
- Every below-the-fold state of every long list.

## Current evidence

Current checkout:

- Branch: `codex/session-agent-xmage-mapper-20260630`
- SHA after launch-readiness and visual-token commits: `470dd95a5`

Commands rerun today:

```bash
cd app && flutter analyze lib test --no-version-check
```

Result: `No issues found!`

```bash
cd app && flutter test test/core/theme test/features/home/lotus_ui_snapshot_test.dart --no-version-check
```

Result: `00:00 +6: All tests passed!`

```bash
python3 server/bin/premium_visual_audit.py --include-life-counter --output /tmp/manaloom_premium_visual_audit_current.md
```

Result:

```text
VISUAL_PREMIUM_QA_RESULT: signals=0 P1=0 P2=0 visual_pass=false
```

Existing live visual evidence reviewed:

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
| Splash/Login/Cadastro | 0 | Static token/radius drift cleared; still requires screenshot review. |
| Home | 0 | Static token/radius drift cleared; still requires screenshot review. |
| Meus Decks | 0 | Baseline remains good; screenshot review still required. |
| Detalhes do Deck | 0 | Static drift cleared; dense analytical areas still need live visual review. |
| Criar/Gerar/Importar Deck | 0 | Static drift cleared; preview states still need screenshot review. |
| Busca/Detalhe/Adicionar Carta | 0 | Small touch target candidates were raised to tokenized minimums where touched. |
| Colecao/Fichario/Marketplace | 0 | Border/radius token drift cleared in configured surfaces. |
| Trades/Mensagens/Notificacoes | 0 | Static drift cleared; chat/send affordances still need runtime review. |
| Comunidade/Perfil | 0 | Static drift cleared in configured surfaces. |
| Life Counter/Lotus | 0 | Tabletop skin now passes the static token gate, but remains screenshot-gated. |

The prior saved premium report had 301 P2 signals, and an intermediate run had
227 P2 signals. The current run is zero objective signals, but the correct
release interpretation remains the same: `PASS_WITH_RISKS`, not global `PASS`.

## Design assessment

### Visual identity

Strong. The app has a recognizable premium MTG-adjacent product language:
dark obsidian surfaces, brass as primary action, frost blue as secondary
information, and restrained ivory text. The brand no longer reads like default
Material UI in the proven non-scanner flow.

Main risk: future drift if new screens copy old direct values instead of the
token scale.

### Visual pollution

Controlled in the main app, still present in dense feature areas.

The largest pollution risk is not a single bad screen; it is accumulated
micro-chrome: borders with custom alpha, pill radii, chips, score/status badges,
domain colors, and analytical metadata in the same viewport. Deck details,
community/profile cards, binder/marketplace and Life Counter sheets are the
areas to keep under the strictest screenshot review.

Life Counter is visually heavier than the native app, but that is partly
intentional because it is a tabletop/game surface. Its direct color, radius and
text-style decisions were tokenized where touched in this pass, but the separate
style still needs screenshot review because static checks cannot judge tabletop
composition.

### Color use

Good product palette, acceptable current discipline.

The strongest current proof is `app/test/core/theme/app_theme_token_usage_test.dart`:
shared app surfaces are checked for local hardcoded colors, while scanner and
life-counter skins are explicitly excluded because they have independent visual
systems.

Remaining risk:

- Current configured premium gate: `0` material color/radius/border signals.
- Direct colors in Life Counter and special skins were tokenized where touched,
  but screenshots remain the correct approval source for visual exceptions.

### Usability

Good for the proven internal non-scanner scope.

The app has clear primary flows, protected routes, visible loading/error/empty
states in many surfaces, and prior live evidence for splash, auth, home, deck
flows, collection, community, profile, messages, notifications, trades and Life
Counter overlays.

Remaining usability risks:

- Some icon/touch targets still need live review, even after the current
  tokenized touch-target cleanup.
- Generate/import/deck analysis can still feel dense when populated.
- Scanner/camera/OCR remains outside this approval.
- Long scrollable surfaces can still hide below-the-fold visual issues.

### Typography and hierarchy

Mostly strong. Inter is the utility font and Fraunces is reserved for
brand/display hierarchy. This gives the app a clearer product voice than the
older mixed system.

Remaining risk: isolated `TextStyle(...)` literals still exist, especially in
Life Counter and a few deck/card flows. They are not blockers, but they should be
reduced when touching those screens.

## Priority backlog

P1: none found in today's design/usability pass.

P2:

1. Keep Life Counter / Lotus on a separate design gate and continue screenshot
   review, even though its static signals are now zero.
2. Review small target candidates in live screenshots and interaction tests
   after the current tokenized touch-target changes.
3. Keep replacing any newly introduced border/radius/text literals with
   `AppTheme` tokens during future feature work.
4. For each app-facing layout change, rerun the premium static gate plus the
   relevant iPhone Simulator capture suite and inspect contact sheets manually.

## Release interpretation

Internal non-scanner testing can continue.

Do not claim final visual/design closure yet. The honest state is:

- app visual system: good and coherent;
- visual pollution: controlled, with dense-area live-review risk;
- color system: strong, with Life Counter now static-token clean but still
  visually exception-heavy by design;
- usability: acceptable for proven non-scanner flows;
- global design approval: still gated by current screenshot review.
