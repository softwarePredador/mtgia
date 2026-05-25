# Hermes Analysis: Technical Map

> Mapa tecnico inicial para orientar analises futuras do agente residente.

## Estrutura principal

```text
mtgia/
  app/       Flutter mobile app
  server/    Dart Frog API
  docs/      documentacao ativa e auditorias atuais
  scripts/   gates e automacoes locais
  archive_docs/ documentacao historica
```

## App Flutter

Arquivo de dependencias: `app/pubspec.yaml`

Principais tecnologias observadas:

- Flutter SDK `^3.7.2`
- Provider
- GoRouter
- HTTP
- Firebase Core/Messaging/Performance
- Sentry Flutter
- Google MLKit Text Recognition
- Camera
- Shared Preferences
- WebView Flutter

Areas de maior interesse:

- `app/lib/features/decks/**`
- `app/lib/features/home/**`
- `app/lib/features/scanner/**` apenas quando scanner voltar ao escopo
- `app/test/**`
- `app/doc/**`

## Backend Dart Frog

Arquivo de dependencias: `server/pubspec.yaml`

Principais tecnologias observadas:

- Dart Frog
- PostgreSQL
- dotenv
- http
- bcrypt
- crypto
- dart_jsonwebtoken
- json_serializable
- html
- Sentry

Areas de maior interesse:

- `server/routes/ai/generate/**`
- `server/routes/ai/optimize/**`
- `server/routes/ai/rebuild/**`
- `server/routes/decks/**`
- `server/lib/ai/**`
- `server/test/**`
- `server/doc/**`

## Scripts operacionais

- `scripts/quality_gate.sh quick`: `dart test` + `flutter analyze`
- `scripts/quality_gate.sh full`: backend completo + `flutter analyze` + `flutter test`
- `scripts/quality_gate.sh resolution`: corpus Commander estavel
- `scripts/dev_full_with_integration.sh`: sobe API local e roda gate full com integracao
- `scripts/validate_request_id_ready.sh`: validacao de tracing
- `scripts/validate_sentry_backend_ingestion.sh`: validacao Sentry backend
- `scripts/validate_sentry_mobile_local.sh`: validacao Sentry mobile local

## Regras para analise tecnica

- Alteracoes em contratos exigem leitura de `server/doc/API_CONTRACTS_AND_DATA_MAP.md`.
- Alteracoes em UI runtime exigem leitura de `app/doc/UI_TEST_SURFACE_MAP.md`.
- Alteracoes no core devem buscar testes existentes antes de propor novos testes.
- Quando o agente nao executar testes, deve declarar explicitamente que a validacao e apenas estatica.
