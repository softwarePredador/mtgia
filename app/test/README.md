# Testes do app ManaLoom

Este diretório contém unit, widget, golden e auditorias de acessibilidade do
Flutter. O contrato vigente de perfis, autorizações e conclusão fica em
`docs/MANALOOM_E2E_RELEASE_CONTRACT.md`; testes runtime/Patrol são inventariados
em `app/integration_test/README.md`.

## Jornada protegida

Em 2026-07-15, a prioridade continua sendo a jornada Commander:

`onboarding -> generate/import -> details -> analyze -> optimize/rebuild -> apply -> validate`

O app deve preservar IDs, commander, formato, legalidade e pareamento atômico
de swaps ao interpretar o backend. UI verde sem contrato de aplicação verde não
é aprovação do fluxo.

## Entradas canônicas

| Objetivo | Comando na raiz | Rede/escrita |
| --- | --- | --- |
| app + server completos | `./scripts/quality_gate.sh full` | não |
| deckbuilder integrado | `./scripts/quality_gate.sh e2e` | não por padrão |
| UI/goldens/acessibilidade | `./scripts/quality_gate.sh ui-audit` | não |
| jornadas críticas Patrol | `./scripts/quality_gate.sh patrol-smoke` | fake/local por padrão |
| dependências | `./scripts/quality_gate.sh deps` | não |
| regras customizadas | `./scripts/quality_gate.sh custom-lint` | não |

Comandos focados dentro de `app/`:

```bash
flutter analyze --no-fatal-infos
flutter test --no-version-check
flutter test test/features/decks --no-version-check
flutter test test/ui test/core/widgets/debug_accessibility_tools_test.dart \
  --no-version-check
```

## Organização da cobertura

- `test/features/decks/models/`: parsing, defaults e serialização;
- `test/features/decks/providers/`: requests, resolução de cartas, mutações e
  interpretação dos contratos de IA;
- `test/features/decks/screens/`: entrada e jornada de telas;
- `test/features/decks/widgets/`: análise, diagnóstico, optimize, sample hand e
  robustez de layout;
- `test/ui/`: goldens e contratos de campo/acessibilidade;
- `test/core/`: API client, observabilidade, logging e widgets compartilhados;
- `integration_test/`: runtime em device/simulador, sempre opt-in;
- `patrol_test/`: jornadas Patrol determinísticas e runner real opt-in.

## Goldens e artefatos

Baselines revisadas ficam em `test/**/goldens/`. Atualize uma baseline somente
depois de inspecionar visualmente a mudança:

```bash
flutter test <arquivo> --update-goldens --no-version-check
```

`test/**/failures/`, `test_bundle.dart`, `playwright-report/`, `test-results/` e
`*.xcresult` são saídas geradas e ficam ignorados. Não mova um diff de falha
para `goldens/` para fazer o gate passar.

## Patrol

O smoke local cobre login, cadastro/validação, paywall de IA, planos, legal,
upgrade e checkout com serviços controlados:

```bash
./scripts/quality_gate.sh patrol-smoke
```

Chrome headless, quando solicitado, continua sem escrever em produto:

```bash
MANALOOM_RUN_PATROL_DEVICE_TESTS=1 \
MANALOOM_PATROL_DEVICE=chrome \
MANALOOM_PATROL_WEB_HEADLESS=true \
./scripts/quality_gate.sh patrol-smoke
```

O bridge iOS ativo fica em `ios/RunnerUITests/`. A ausência desse target em
`xcodebuild -list` é falha de harness, não motivo para pular silenciosamente.

## Runtime live

Arquivos em `integration_test/` variam: alguns são visuais/offline; outros
registram usuário, criam deck ou chamam API/IA. Não rode o diretório inteiro
contra uma URL pública.

O perfil integrado guardado exige seleção e tokens textuais:

```bash
MANALOOM_RUN_FLUTTER_RUNTIME_E2E=1 \
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_API_BASE_URL=https://alvo-aprovado.example \
./scripts/quality_gate.sh e2e
```

Uma flag `MANALOOM_RUN_*` não é autorização. Não persista tokens em `.env` ou
CI.

## Life counter

O caminho vivo é o host Lotus. A única fonte empacotada do bundle é
`app/assets/lotus/`; o antigo espelho em
`app/android/app/src/main/assets/lotus/` foi removido. A cobertura principal
fica no host, nas rotas e nos cenários runtime descritos em
`app/integration_test/README.md`.

## Critério de aceite

- teste focado para a regra alterada;
- suíte completa do app verde;
- gate UI quando houver mudança visual/interativa;
- Patrol quando houver login, cadastro, paywall, planos, legal, checkout ou
  bridge nativo;
- E2E integrado para deckbuilder/IA/battle;
- qualquer runtime/device/live não executado registrado como `SKIP` ou
  pendência, nunca contado como `PASS` de produção.
