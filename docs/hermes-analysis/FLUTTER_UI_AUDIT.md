# Flutter UI/UX Audit

## Metadata

- Gerado em UTC: `2026-07-01T15:17:44.600891+00:00`
- Branch: `codex/session-agent-xmage-mapper-20260630`
- SHA: `10051e078`
- Scan repo: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- Memory/report repo: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- Escopo: `app/lib/features/**/*.dart`, `app/lib/core/**/*.dart`
- Arquivos Dart analisados: `166`
- Metodo: varredura estatica deterministica por padroes de UI/UX
- Limite por regra: `80`

## Sumario

`findings=0 P0=0 P1=0 P2=0`

### Contagem por regra

- Nenhum padrao problematico encontrado pela varredura estatica.

## Findings

Nenhum finding objetivo encontrado pela varredura estatica.
## Incertezas / medir depois

- Contraste real depende de renderizacao e tema ativo; validar com screenshot ou teste visual.
- Overflow/truncamento depende de device, escala de fonte e dados reais.
- Estados empty/error/loading contextuais exigem revisar providers/API por fluxo.

## Git status no momento da auditoria

```text
## codex/session-agent-xmage-mapper-20260630...origin/codex/session-agent-xmage-mapper-20260630
 M app/.metadata
 M app/lib/features/community/screens/community_screen.dart
 M app/lib/features/decks/providers/deck_provider.dart
 M app/lib/features/decks/providers/deck_provider_support_ai.dart
 M app/lib/features/decks/screens/deck_details_screen.dart
 M app/lib/features/decks/screens/deck_generate_screen.dart
 M app/lib/features/decks/widgets/deck_optimize_sections.dart
 M app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart
 M app/lib/features/profile/profile_screen.dart
 M app/lib/main.dart
 M docs/qa/MANALOOM_GOAL_STAGE1_2_3_TRACKER_2026-07-01.md
 M docs/qa/MANALOOM_RELEASE_READINESS_FINAL_PASS_2026-07-01.md
?? app/ios/Runner/SceneDelegate.swift
?? app/lib/features/commercial/
?? app/lib/features/growth/
?? app/lib/features/retention/
?? app/test/features/commercial/
?? app/test/features/decks/providers/deck_recommendation_context_payload_test.dart
?? app/test/features/growth/
?? app/test/features/retention/
?? docs/qa/MANALOOM_PRODUCT_ROADMAP_STAGES_4_7_2026-07-01.md
?? docs/qa/MANALOOM_REMAINING_RELEASE_STAGES_GOAL_2026-07-01.md
?? docs/qa/MANALOOM_STAGE4_7_MVP_IMPLEMENTATION_AUDIT_2026-07-01.md
```

## Git status da memoria Hermes

```text
## codex/session-agent-xmage-mapper-20260630...origin/codex/session-agent-xmage-mapper-20260630
 M app/.metadata
 M app/lib/features/community/screens/community_screen.dart
 M app/lib/features/decks/providers/deck_provider.dart
 M app/lib/features/decks/providers/deck_provider_support_ai.dart
 M app/lib/features/decks/screens/deck_details_screen.dart
 M app/lib/features/decks/screens/deck_generate_screen.dart
 M app/lib/features/decks/widgets/deck_optimize_sections.dart
 M app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart
 M app/lib/features/profile/profile_screen.dart
 M app/lib/main.dart
 M docs/qa/MANALOOM_GOAL_STAGE1_2_3_TRACKER_2026-07-01.md
 M docs/qa/MANALOOM_RELEASE_READINESS_FINAL_PASS_2026-07-01.md
?? app/ios/Runner/SceneDelegate.swift
?? app/lib/features/commercial/
?? app/lib/features/growth/
?? app/lib/features/retention/
?? app/test/features/commercial/
?? app/test/features/decks/providers/deck_recommendation_context_payload_test.dart
?? app/test/features/growth/
?? app/test/features/retention/
?? docs/qa/MANALOOM_PRODUCT_ROADMAP_STAGES_4_7_2026-07-01.md
?? docs/qa/MANALOOM_REMAINING_RELEASE_STAGES_GOAL_2026-07-01.md
?? docs/qa/MANALOOM_STAGE4_7_MVP_IMPLEMENTATION_AUDIT_2026-07-01.md
```

UI_AUDIT_RESULT: findings=0 P0=0 P1=0 P2=0
