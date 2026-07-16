# ManaLoom

Plataforma para Magic: The Gathering focada em um fluxo confiável de decks:

1. criar ou importar
2. validar e analisar
3. otimizar ou reconstruir
4. aplicar e validar o resultado final

## Fonte de verdade

Se você precisar entender o estado atual do projeto, a ordem correta é:

1. [docs/MANALOOM_E2E_RELEASE_CONTRACT.md](docs/MANALOOM_E2E_RELEASE_CONTRACT.md)
2. [docs/CONTEXTO_PRODUTO_ATUAL.md](docs/CONTEXTO_PRODUTO_ATUAL.md)
3. [docs/qa/MANALOOM_E2E_PROJECT_CLOSURE_2026-07-15.md](docs/qa/MANALOOM_E2E_PROJECT_CLOSURE_2026-07-15.md)
4. [docs/qa/MANALOOM_BATTLE_DECKBUILDER_DEFINITIVE_2026-07-15.md](docs/qa/MANALOOM_BATTLE_DECKBUILDER_DEFINITIVE_2026-07-15.md)
5. [docs/README.md](docs/README.md)

O contrato E2E define gates, autorizações e o significado de `PASS`, `PARTIAL`,
`BLOCKED` e `FAIL`. O contexto atual define prioridade de produto. Roadmaps,
matrizes e handoffs datados são apoio histórico e não substituem essas duas
fontes.

## Prioridade atual

O foco ativo do produto está no core de decks:

- onboarding
- geração
- importação
- análise
- otimização
- rebuild
- validação final

Frentes adjacentes como social, binder, trade, scanner e refinamentos cosméticos só devem avançar se não competirem com a confiabilidade desse fluxo.

## Estrutura do repositório

- `app/`: aplicativo Flutter
- `server/`: API Dart Frog, regras, IA, testes e scripts
- `docs/`: documentação ativa e auditorias atuais
- `archive_docs/`: documentação arquivada para referência histórica

## Documentação principal

- contexto operacional: [docs/CONTEXTO_PRODUTO_ATUAL.md](docs/CONTEXTO_PRODUTO_ATUAL.md)
- contrato E2E e conclusão: [docs/MANALOOM_E2E_RELEASE_CONTRACT.md](docs/MANALOOM_E2E_RELEASE_CONTRACT.md)
- encerramento E2E corrente: [docs/qa/MANALOOM_E2E_PROJECT_CLOSURE_2026-07-15.md](docs/qa/MANALOOM_E2E_PROJECT_CLOSURE_2026-07-15.md)
- battle/deckbuilder definitivo: [docs/qa/MANALOOM_BATTLE_DECKBUILDER_DEFINITIVE_2026-07-15.md](docs/qa/MANALOOM_BATTLE_DECKBUILDER_DEFINITIVE_2026-07-15.md)
- índice documental: [docs/README.md](docs/README.md)
- matriz histórica da otimização: [docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md](docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md)
- auditoria de UX, lógica e performance: [docs/AUDITORIA_UX_LOGICA_PERFORMANCE_2026-03-23.md](docs/AUDITORIA_UX_LOGICA_PERFORMANCE_2026-03-23.md)
- manual técnico contínuo: [server/manual-de-instrucao.md](server/manual-de-instrucao.md)

## Setup rápido

### Backend

```bash
cd server
dart pub get
dart_frog dev -p 8080
```

### Frontend

```bash
cd app
flutter pub get
flutter run
```

## Testes

### Workspace e gates

```bash
dart run melos list
dart run melos run deps
dart run melos run custom-lint
dart run melos run patrol-smoke
dart run melos run ui-audit
dart run melos run e2e
```

Atalhos diretos equivalentes:

```bash
./scripts/quality_gate.sh deps
./scripts/quality_gate.sh custom-lint
./scripts/quality_gate.sh patrol-smoke
./scripts/quality_gate.sh ui-audit
./scripts/quality_gate.sh full
./scripts/quality_gate.sh e2e
```

`e2e` roda a varredura local de produto/lógica: Patrol, deckbuilder Flutter,
contratos comerciais/retencao/trade, logs/observabilidade, testes server de
IA/deckbuilder/battle, classificadores de ramp, piso estrutural do optimizer,
segurança da fundação de dados/regras, pytest de battle runtime, corpus
Commander, app/IA, PG-Hermes-SQLite e deep-ai. Os logs ficam em
`/tmp/manaloom_e2e_suite_reports` por padrão. A execução determinística retorna
`PARTIAL` quando as camadas live opcionais são puladas; isso é diferente de
falha e também não equivale a uma validação de produção.

O CI roda `dart run melos run quality` no workflow `ManaLoom Guardrails` para
PR/push que altera app, backend, scripts, lints ou pubspecs.

Runbook de uso: [docs/qa/MANALOOM_TOOLING_VALIDATION_RUNBOOK_2026-07-06.md](docs/qa/MANALOOM_TOOLING_VALIDATION_RUNBOOK_2026-07-06.md)

### App

```bash
cd app
flutter analyze
flutter test
```

### Server

```bash
cd server
dart test
```

Para a malha mais importante do core, ver:

- [app/test/README.md](app/test/README.md)
- [server/test/README.md](server/test/README.md)

## Status

Em `2026-07-15`, código, base de dados e o corpus mutável isolado ficaram
tecnicamente verdes na rodada registrada no
[relatório de encerramento](docs/qa/MANALOOM_E2E_PROJECT_CLOSURE_2026-07-15.md).
As 35 migrations estão executadas. Depois dessa rodada, a API, o app Flutter em
`/app` e o APK Android assinado foram publicados no servidor novo; o Android
também passou em aparelho físico. A distribuição iOS nativa ainda depende da
equipe Apple Developer/App Store Connect da ManaLoom. Nenhum `SKIP` é contado
como aprovação de produção.
