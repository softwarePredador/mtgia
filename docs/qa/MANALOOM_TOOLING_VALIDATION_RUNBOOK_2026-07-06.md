# ManaLoom Tooling Validation Runbook - 2026-07-06

> Snapshot de instalação das ferramentas. Para o contrato vigente de perfis,
> autorização e conclusão, use `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`.

## Objetivo

Deixar o projeto com comandos repetiveis para manutencao, auditoria de UI,
E2E critico, lint customizado e higiene de dependencias sem mudar a arquitetura
app/server.

## Ferramentas instaladas

- `melos 6.3.3` na raiz: orquestra comandos entre `app`, `server` e `tools/manaloom_lints`.
- `dependency_validator 5.0.5` no `app`: valida dependencias diretas do Flutter.
- `dependency_validator 3.2.3` no `server`: valida dependencias diretas do Dart Frog respeitando o SDK atual do backend.
- `dependency_validator 5.0.5` em `tools/manaloom_lints`: valida o pacote local de regras.
- `custom_lint 0.8.1` no `app` e `server`: executa regras customizadas ManaLoom.
- `manaloom_lints` em `tools/manaloom_lints`: pacote local com as regras `avoid_legacy_manaloom_endpoint_literal` e `avoid_manaloom_secret_literal`.
- `patrol 4.6.1` e `patrol_cli 4.4.0` no `app`: E2E critico e base para testes em device/emulador/web.
- `alchemist 0.14.0` no `app`: golden tests para telas criticas.
- `accessibility_tools 2.8.0` no `app`: checagem de tap target, labels semanticos e overflow em testes/debug.

## Comandos principais

Listar pacotes do workspace:

```bash
dart run melos list
```

Validar dependencias declaradas:

```bash
dart run melos run deps
./scripts/quality_gate.sh deps
```

Validar lint customizado:

```bash
dart run melos run custom-lint
./scripts/quality_gate.sh custom-lint
```

Validar suite E2E critica local do Patrol:

```bash
dart run melos run patrol-smoke
./scripts/quality_gate.sh patrol-smoke
```

Rodar Patrol real em device/emulador/web quando houver alvo conectado:

```bash
MANALOOM_RUN_PATROL_DEVICE_TESTS=1 ./scripts/quality_gate.sh patrol-smoke
```

Validar regressao visual e acessibilidade:

```bash
dart run melos run ui-audit
./scripts/quality_gate.sh ui-audit
```

Rodar a suite E2E local de produto/deckbuilder/battle/IA/logs:

```bash
dart run melos run e2e
./scripts/quality_gate.sh e2e
```

O resumo e os logs por etapa ficam em `/tmp/manaloom_e2e_suite_reports` por
padrao. Para persistir em outro local:

```bash
MANALOOM_E2E_REPORT_ROOT=docs/qa/runtime ./scripts/quality_gate.sh e2e
```

Camadas vivas opcionais exigem alvo explícito e confirmação textual. Flags
`MANALOOM_RUN_*` selecionam a camada, mas não autorizam escrita:

```bash
MANALOOM_RUN_FLUTTER_RUNTIME_E2E=1 \
MANALOOM_RUN_SERVER_LIVE_E2E=1 \
MANALOOM_RUN_LIVE_PRODUCT_E2E=1 \
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_API_BASE_URL=https://alvo-aprovado.example \
TEST_API_BASE_URL=https://alvo-aprovado.example \
./scripts/quality_gate.sh e2e
```

Sem camadas opcionais, o resumo integrado pode terminar `PARTIAL`: os checks
solicitados passaram, mas live/device permaneceram como `SKIP`. Isso não é
falha e não é aprovação de produção.

Rodar app/backend pelo gate principal:

```bash
./scripts/quality_gate.sh full
```

Rodar o pacote principal de qualidade local:

```bash
dart run melos run quality
```

O workflow `.github/workflows/manaloom-guardrails.yml` tambem roda o pacote
principal via `dart run melos run quality` em PR/push que altere `app`,
`server`, `tools`, `scripts`, `melos.yaml` ou pubspecs.

## Quando usar

- Depois de adicionar ou remover pacote: `./scripts/quality_gate.sh deps`.
- Depois de mexer em login, cadastro, paywall, planos, shell ou visual: `./scripts/quality_gate.sh ui-audit`.
- Depois de mexer em configuracao Dart/Flutter ou URLs de ambiente: `./scripts/quality_gate.sh custom-lint`.
- Depois de mexer em segredos, EasyPanel, URLs, Sentry, OpenAI ou pagamento: `./scripts/quality_gate.sh custom-lint`.
- Depois de mexer em login, cadastro, paywall, planos, legal, upgrade, checkout, harness E2E ou interacao nativa: `./scripts/quality_gate.sh patrol-smoke`.
- Depois de mexer em deckbuilder, battle, simulacao, IA, logs, PG/Hermes/SQLite ou contratos cruzados: `./scripts/quality_gate.sh e2e`.
- Antes de fechar uma entrega app/backend: `./scripts/quality_gate.sh full`.
- Antes de mexer em IA/deckbuilder/battle: `./scripts/quality_gate.sh ai-bridge` e `./scripts/quality_gate.sh deep-ai`.

## Wrapper debug de acessibilidade

O app pode abrir com o painel/checkers do `accessibility_tools` em debug:

```bash
cd app
flutter run --dart-define=MANALOOM_ENABLE_ACCESSIBILITY_TOOLS=true
```

O modo normal nao injeta o painel. A flag existe para revisao manual durante QA
de telas, sem afetar build normal.

## Politica de dependencias

- Dependencia usada por `lib/` deve ser dependencia direta do pacote.
- Dependencia usada so por testes ou scripts de validacao deve ficar em `dev_dependencies`.
- Dependencia sem import real deve ser removida ou explicitamente justificada.
- Nao ignorar alerta do `dependency_validator` sem motivo escrito no `dart_dependency_validator.yaml`.
- `manaloom_lints` fica ignorado no app/server porque e carregado pelo analyzer via `custom_lint`, nao por import direto.
- `avoid_legacy_manaloom_endpoint_literal` bloqueia endpoint antigo/local hardcoded em `app/lib`, `server/lib` e `server/routes`.
- `avoid_manaloom_secret_literal` bloqueia tokens reais, DSNs com credenciais e chaves de provedor hardcoded em codigo de producao.
- O gate PowerShell `scripts/quality_gate.ps1` deve ficar em paridade com o shell para os modos `full`, `ui-audit`, `deps`, `custom-lint` e `patrol-smoke`.

## Ferramentas avaliadas e nao instaladas agora

- `very_good_analysis`: deve entrar como migracao de lint dedicada, nao como troca silenciosa, porque o projeto atual ainda usa `flutter_lints`.

## Evidência da instalação em 2026-07-06

Os números abaixo pertencem àquela rodada e não devem ser usados como status
corrente. A evidência atual fica no relatório de fechamento datado mais novo.

- `dart run melos list`: encontrou `manaloom`, `server` e `manaloom_lints`.
- `./scripts/quality_gate.sh deps`: passou no app, server e pacote local de lint.
- `./scripts/quality_gate.sh custom-lint`: passou no pacote local, app e backend, incluindo 5 testes das regras customizadas.
- `./scripts/quality_gate.sh patrol-smoke`: passou com 4 testes Patrol locais cobrindo login, cadastro, paywall, planos, legal, upgrade e checkout.
- `MANALOOM_RUN_PATROL_DEVICE_TESTS=1 MANALOOM_PATROL_DEVICE=chrome MANALOOM_PATROL_WEB_HEADLESS=true ./scripts/quality_gate.sh patrol-smoke`: passou com 4 testes Patrol reais em Chrome headless.
- Observacao Patrol Web: o cadastro valida erro de senha, correcao e submit no Chrome headless; a navegacao pos-auth para `/home` e assertada no runner local, porque a leitura de rota pos-auth do cadastro ficou instavel no bridge web do Patrol.
- `./scripts/quality_gate.sh ui-audit`: passou com 7 testes de golden/accessibility.
- `dart run melos run quality`: passou com backend, 612 testes Flutter, UI audit, custom lint, Patrol smoke e dependency audit.
- `.github/workflows/manaloom-guardrails.yml`: agora executa `dart run melos run quality` para app/server/tools/scripts/pubspecs.
- `./scripts/quality_gate.sh e2e`: alvo criado para orquestrar Patrol, deckbuilder Flutter, contratos comerciais/retencao/trade, logs/observabilidade, contratos server de IA/deckbuilder/battle, pytest de battle runtime, corpus Commander, app/IA bridge, PG-Hermes-SQLite e deep-ai.
- Dependencias diretas removidas do app por nao terem uso real: `cupertino_icons`, `flutter_animate`, `webview_flutter_android`.
- Dependencias diretas adicionadas ao server por uso real: `meta`, `path`.
- String local hardcoded removida do log de debug do `ApiClient` para respeitar a regra customizada.
- Regra `avoid_manaloom_secret_literal` adicionada para bloquear tokens reais, DSNs com credenciais e chaves de provedor hardcoded.
