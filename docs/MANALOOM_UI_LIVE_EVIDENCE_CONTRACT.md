# Contrato de prova viva de UI do ManaLoom

Este contrato define quando uma mudança visual pode ser chamada de validada.
Teste de widget, golden e análise estática continuam obrigatórios, mas não
provam sozinhos que a interface real está coerente, funcional e atraente.

## Resultado obrigatório

Uma superfície app-facing só recebe `PASS` quando os três níveis abaixo estão
presentes e vinculados ao mesmo digest de código:

1. `PASS_AUTOMATED`: analyzer, widget/golden, overflow, viewport,
   acessibilidade automatizada e contratos de estado aplicáveis passaram.
2. `PASS_RUNTIME`: a implementação corrente rodou em Android físico ou build
   Web real, executou a interação relevante e produziu PNGs íntegros, com
   dimensões e SHA-256 registrados.
3. `PASS_VISUAL_REVIEWED`: um agente ou pessoa abriu **todas** as capturas e
   registrou decisão explícita sobre hierarquia, identidade MTG, cor/contraste,
   tipografia, espaçamento/densidade, adaptação, clareza de interação, estados,
   acessibilidade visual e atratividade.

`PASS_STATIC_ONLY`, screenshot histórico, captura de bundle anterior, arquivo
PNG não aberto e `SKIP` não satisfazem este contrato. Qualquer mudança nos
sources app-facing invalida o digest e faz o gate falhar fechado até existir
nova prova.

## Tese visual, conteúdo e interação

Antes de aprovar uma superfície, a revisão declara:

- **tese visual**: qual linguagem domina e onde os acentos são permitidos;
- **plano de conteúdo**: a ordem em que a pessoa entende contexto, estado,
  decisão e resultado;
- **tese de interação**: como prioridade, transição, feedback e recuperação
  tornam a próxima ação inequívoca.

Para o Battle Coach, a tese corrente é uma mesa tática Obsidian/slate; brass
fica reservado para prioridade e ação, frost para informação. O conteúdo segue
status → mesa e zonas → decisão → conclusão/replay. A interação para quando há
uma decisão humana, bloqueia duplicidade durante o envio, preserva a mesa no
erro recuperável e mantém concessão atrás de confirmação.

## Fluxo canônico

Revalidar somente a prova já revisada:

```bash
./scripts/manaloom_ui_live_evidence_gate.sh --check
```

Capturar o Battle Coach no Android físico:

```bash
MANALOOM_UI_PROOF_DEVICE=<ANDROID_DEVICE_ID> \
./scripts/manaloom_ui_live_evidence_gate.sh --capture-battle-coach
```

O capture executa analyzer e testes focados, roda o integration test no device,
extrai os PNGs emitidos pelo runtime e grava
`docs/qa/ui-live/current/battle-coach-android/capture-manifest.json`. Capturar
não aprova visualmente: depois disso o revisor abre cada PNG, corrige a UI se
necessário, recaptura e somente então atualiza `docs/qa/ui-live/latest.json`.

A prova corrente também agrega a matriz P0 ampla em quatro perfis:

- Web real mobile, desktop e wide;
- Android profile em Samsung SM-A135M, Android 14;
- Battle Coach Android em sete estados;
- Battle Coach Web em nove checkpoints de teclado físico.

Os manifestos ficam em `docs/qa/ui-live/current/p0-matrix`,
`battle-coach-android` e `battle-coach-web-keyboard`. O aggregate
`latest.json` registra o hash de cada manifesto, todos os perfis revisados e a
quantidade total de screenshots. O verificador exige igualdade exata desses
conjuntos; revisar apenas uma seleção de imagens não concede
`PASS_VISUAL_REVIEWED`.

O Life Counter é uma platform view Android. Screenshot produzida pela surface
Flutter não comprova sua composição nativa e pode resultar em frame preto.
Nesse checkpoint o harness anuncia prontidão e
`scripts/manaloom_capture_android_platform_view.sh` usa `adb screencap` no
aparelho, valida assinatura PNG, dimensão landscape e tamanho mínimo antes de
promover o arquivo. Captura preta, frame de transição e conversão da surface
Flutter são recusados.

A prova Web de teclado usa eventos físicos no build release servido em
loopback e registra, em imagens e log sanitizado, Tab, Shift+Tab, Enter, Space,
Escape, digitação, foco visível e restauração após o modal. Automação widget
não substitui esse roteiro.

`./scripts/quality_gate.sh ui-proof`, `ui-audit`, `battle-lab` e o gate local
rápido verificam a prova corrente. O digest é calculado por
`scripts/manaloom_ui_source_digest.sh` sobre código Flutter, assets, shell Web,
resources Android, contrato de superfícies e o próprio harness de prova.

## O que a prova não autoriza

- A fixture do Battle Coach não chama API, não autentica, não escreve em
  PostgreSQL e não promove regra de carta; ela prova somente UI e interação.
- Revisão visual por agente não substitui TalkBack humano em Android físico
  nem smoke live de release. Teclado Web real só recebe crédito quando o
  manifesto físico correspondente está presente.
- Uma captura Android não prova a composição Web. Mudança específica de Web
  exige sua própria captura em build real quando o Browser/harness permitido
  estiver disponível.
- A prova é por superfície declarada. Ao mudar outra tela, o manifest de
  revisão precisa nomear e capturar a superfície alterada; reutilizar apenas a
  captura do Battle Coach ou uma matriz P0 anterior é evidência insuficiente.

## Arquivos executáveis

- política: `app/test/ui/fixtures/ui_live_evidence_policy.json`;
- guard: `app/test/ui/ui_live_evidence_policy_test.dart`;
- integração: `app/integration_test/battle_coach_visual_runtime_proof_test.dart`;
- extração/verificação: `app/tool/ui_runtime_evidence.dart`;
- gate: `scripts/manaloom_ui_live_evidence_gate.sh`;
- digest: `scripts/manaloom_ui_source_digest.sh`;
- captura nativa de platform view:
  `scripts/manaloom_capture_android_platform_view.sh`;
- evidência corrente: `docs/qa/ui-live/latest.json`.
