# App Flutter — ManaLoom

Aplicativo Flutter do ManaLoom.

## Papel do app hoje

O app deve preservar a jornada principal do produto:

1. onboarding com contexto correto
2. gerar ou importar deck
3. abrir details
4. otimizar ou reconstruir
5. aplicar e validar

## Fonte de verdade

Antes de mudar fluxo, prioridade ou UX do app, consultar:

1. [../docs/CONTEXTO_PRODUTO_ATUAL.md](../docs/CONTEXTO_PRODUTO_ATUAL.md)
2. [../docs/README.md](../docs/README.md)
3. [test/README.md](test/README.md)

Os documentos em `app/doc/` continuam úteis como apoio, mas hoje são complementares ao contexto operacional do repositório.

Documento complementar importante para a frente do contador:

- `app/doc/LIFE_COUNTER_LOTUS_MIGRATION_PLAN_2026-03-29.md`
- `app/doc/LIFE_COUNTER_LOTUS_HOST_SMOKE_CHECKLIST_2026-03-29.md`
- `app/doc/LIFE_COUNTER_LOTUS_BRANDING_AUDIT_2026-03-29.md`
- `app/doc/LIFE_COUNTER_LOTUS_SHELL_POLICY_2026-03-29.md`
- `app/doc/LIFE_COUNTER_LOTUS_SHELL_OWNED_AFFORDANCES_2026-03-29.md`
- `app/doc/LIFE_COUNTER_LOTUS_STATIC_SHELL_REPLACEMENT_2026-03-29.md`
- `app/doc/LIFE_COUNTER_LOTUS_GAMEPLAY_COPY_AUDIT_2026-03-29.md`

Estado vivo do contador hoje:

- runtime source-of-truth: `app/assets/lotus/`
- implementacao oficial: `app/lib/features/home/lotus_life_counter_screen.dart`
- rota viva: `app/lib/features/home/life_counter_route.dart`
- o espelho local em `app/android/app/src/main/assets/lotus/` nao e contrato ativo de runtime

## Comandos

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Pastas principais

- `lib/features/decks/`
- `lib/features/home/`
- `lib/features/auth/`
- `lib/features/collection/`
- `lib/features/trades/`

## Observação

Neste momento, o app não deve puxar prioridade para longe do core de decks.  
Melhorias visuais e superfícies secundárias só entram quando protegem ou reforçam o fluxo principal.
