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
