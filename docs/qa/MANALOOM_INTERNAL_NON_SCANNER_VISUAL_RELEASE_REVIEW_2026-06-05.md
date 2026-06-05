# ManaLoom Internal Non-Scanner Visual Release Review — 2026-06-05

Status: **PASS_WITH_RISKS**

This review validates the current internal-test candidate for the non-scanner scope using live iPhone Simulator evidence. It does not approve camera/scanner/OCR, real push delivery, or physical-device-only permission behavior.

## Runtime Target

- Device: iPhone Simulator `DABB9D79-2FDB-4585-94DB-E31F1288EE74`
- Public backend: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Backend `/health.git_sha`: `f9c3cdde44722f70139654b89a4d9febdf893213`
- Git head during review: `f9c3cdde Fix life counter hub color tokens`
- Local visual proof folder for this run: `/tmp/manaloom_visual_proofs_20260605`
- Extracted screenshots: 33 PNGs

## Screens Validated

- Splash, login, register.
- Home with new hero treatment and quick actions.
- Deck generator with and without learned-commander availability.
- Hermes learned deck preview and saved deck details.
- My Decks empty state and create deck dialog.
- Deck details, import list, generic generate flow.
- Card add modal with commander/common-card decision.
- Community, collection, profile.
- Deck analysis functional tags / semantic tags explainability.
- Life Counter main table, plus/minus controls for 4 players.
- Life Counter Set Life sheet.
- Life Counter commander damage hint.
- Life Counter turn tracker hint.
- Life Counter settings, radial menu, and history overlay.

## Passed Evidence

- `card_add_commander_choice_runtime_test.dart`: modal displays commander choice and quantity controls; common-card selection persists `is_commander=false`.
- `commander_learned_deck_runtime_test.dart`: Lorehold learned deck button, preview, save, 100 total cards, 99 main deck, commander marked, premium Mox cards absent.
- `commander_learned_deck_availability_runtime_test.dart`: learned deck button appears for Atraxa, Kinnan, Korvold, Lorehold, and Winota; hidden when commander is empty.
- `deck_functional_tags_runtime_test.dart`: analysis UI renders functional tags, semantic v2 source priority, samples, and explainability.
- `app_full_non_life_counter_visual_capture_smoke_test.dart`: main non-scanner screens render without crash and produce live screenshots.
- `life_counter_lotus_visual_runtime_proof_test.dart`: 4 player controls render, `+/-` are present for all players, life text fits, no horizontal overflow.
- `life_counter_lotus_visual_capture_smoke_test.dart`: commander damage and turn tracker overlays render.
- `life_counter_set_life_live_smoke_test.dart`: Set Life sheet renders with visible number value.
- `life_counter_lotus_settings_visual_smoke_test.dart`: settings overlay renders.
- `life_counter_lotus_visual_overlays_smoke_test.dart`: radial menu and history overlay render.

## Visual Findings

No P0/P1 visual blocker was found for the internal non-scanner round.

Accepted P2 follow-ups:

- Generic deck generation smoke captured `generate_preview_not_proven`; dedicated Hermes learned-preview flow is proven separately and passed.
- Import and generate screens remain denser than Home/My Decks and should be refined later for premium hierarchy.
- Life Counter settings disabled actions are legible but visually heavy because disabled edit rows appear strongly muted/struck-through.
- Very long generated deck names truncate with ellipsis in deck details; acceptable for generated QA names, but should be monitored with real user names.

## Release Decision

Internal non-scanner user testing can proceed.

Tester scope must explicitly exclude:

- Scanner/camera/OCR/MLKit.
- Real push notification delivery on physical devices.
- Camera/gallery permission flows.
- Physical-device-only behavior.

Hermes crons can continue running in parallel. Treat Hermes findings as prioritized backlog unless they identify a P0/P1 regression in the non-scanner flows above.
