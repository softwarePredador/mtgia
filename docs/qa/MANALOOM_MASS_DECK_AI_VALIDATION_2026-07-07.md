# ManaLoom Mass Deck AI Validation - 2026-07-07

## Escopo

Validacao em massa de criacao de decks, otimizacao, validacao final, coerencia de IA, battle/runtime, dados PG/Hermes/SQLite, app Flutter e fluxos criticos de produto.

Ambiente usado:

- Repo: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- API local: `http://127.0.0.1:8080`
- PostgreSQL local/dev via `server/bin/with_new_server_pg.sh`

## Resultado executivo

Status: PASS para as baterias locais executadas.

Nao foram encontradas falhas funcionais nos fluxos testados de criacao, otimizacao e validacao de decks. Foram encontrados e corrigidos dois problemas de harness/evidencia:

- O runner de resolucao sobrescrevia artefatos quando o corpus tinha comandantes repetidos.
- O Patrol local dependia de texto fragil no cadastro e nao inicializava `path_provider`/SQLite para o cache de imagens em `flutter test`.

## Baterias executadas

| Area | Comando / gate | Resultado |
| --- | --- | --- |
| App deckbuilder/UI | `cd app && flutter test test/features/decks --no-version-check --reporter compact` | PASS, 190 testes |
| Backend deck/optimize/validate | `cd server && JWT_SECRET=local_mass_deck_test_20260707 dart test ...` | PASS, 277 testes |
| Retencao/relatorios/migracoes | `cd server && dart test test/product_retention_report_contract_test.dart test/data_model_migration_test.dart` | PASS, 14 testes |
| Corpus real Commander | `./scripts/quality_gate.sh resolution` | PASS, 19/19, failed=0, unresolved=0 |
| Corpus com artefatos unicos | `VALIDATION_ARTIFACT_DIR=test/artifacts/optimization_resolution_suite_unique_20260707 ... ./scripts/quality_gate.sh resolution` | PASS, 19/19 e 19 artefatos individuais |
| App/IA bridge | `./scripts/quality_gate.sh ai-bridge` | PASS, prompt eval 100/100 |
| Deep AI alignment | `./scripts/quality_gate.sh deep-ai` | PASS |
| Patrol local | `./scripts/quality_gate.sh patrol-smoke` | PASS, 9 testes locais |
| Comercial/retencao/trade | `cd app && flutter test test/features/commercial test/features/retention test/features/growth test/features/trades --no-version-check --reporter compact` | PASS, 29 testes |
| Logs/observabilidade | `cd app && flutter test test/core/utils/logger_test.dart test/core/observability/app_observability_test.dart test/features/auth/providers/auth_provider_log_sanitization_test.dart --no-version-check --reporter compact` | PASS, 8 testes |
| Server deckbuilder/battle routes | `cd server && RUN_INTEGRATION_TESTS=0 JWT_SECRET=local_manaloom_mass_validation_20260707 dart test ...` | PASS, 75 testes |
| Battle runtime scripts | `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_*.py` | PASS, 184 passed, 1 skipped |
| Surface audits | deckbuilding, operational, legacy contamination | PASS |

## Evidencias principais

- Corpus final: `server/test/artifacts/optimization_resolution_suite_unique_20260707/latest_summary.json`
- Artefatos individuais: `server/test/artifacts/optimization_resolution_suite_unique_20260707/`
- Relatorio Commander preservado: `docs/qa/runtime/resolution-corpus-20260707/summary.md`
- Deep AI summary: `/tmp/manaloom_deep_ai_alignment_reports/deep_ai_alignment_20260707_221035_summary.md`
- App/IA bridge: `docs/hermes-analysis/master_optimizer_reports/app_ai_knowledge_bridge_audit_20260707_mass_validation.md`

Resumo do corpus final:

- Total: 19
- Passed: 19
- Failed: 0
- Unresolved: 0
- Direct optimizations: 19
- Rebuild resolutions: 0
- Safe no change: 0

## Correcoes aplicadas durante a validacao

1. Runner de resolucao Commander
   - Arquivos individuais agora incluem indice do caso e token do source deck.
   - Exemplo: `01_lorehold_the_historian_8938b746.json`.
   - Evita sobrescrita quando o corpus contem o mesmo comandante mais de uma vez.

2. Patrol smoke test
   - Cadastro passou a validar `Criar conta` e a key `register-submit-button`, alinhado com a tela atual.
   - Adicionado mock de `path_provider` para ambiente de `flutter test`.
   - Adicionado `sqflite_common_ffi` como dev dependency e inicializacao do `databaseFactoryFfi` para o `flutter_cache_manager`.

## Limites da validacao

- Patrol CLI em device/emulador nao foi executado porque `MANALOOM_RUN_PATROL_DEVICE_TESTS=1` nao foi definido.
- Live product/API E2E externo nao foi executado contra dominio definitivo/producao.
- A prova real de corpus usou API local e PostgreSQL dev/local, nao producao.
