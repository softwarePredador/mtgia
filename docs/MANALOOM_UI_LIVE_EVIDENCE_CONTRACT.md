# Contrato de prova viva de UI do ManaLoom

Este contrato define quando uma mudança visual pode ser chamada de validada.
Teste de widget, golden e análise estática continuam obrigatórios, mas não
provam sozinhos que a interface real está coerente, funcional e atraente.

## Resultado obrigatório

Uma superfície app-facing só recebe `PASS` quando os três níveis abaixo estão
presentes e vinculados ao mesmo digest de código:

1. `PASS_AUTOMATED`: analyzer, widget/golden, overflow, viewport,
   acessibilidade automatizada e contratos de estado aplicáveis passaram.
2. `PASS_RUNTIME`: a implementação corrente rodou em runtime Android atestado
   (`emulator` ou `physical`) ou build Web real, executou a interação relevante
   e produziu PNGs íntegros, com dimensões e SHA-256 registrados. O manifesto
   nunca pode apresentar emulador como aparelho físico.
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

Para o Battle Live, a tese corrente é uma mesa observável contínua em
Obsidian/slate, sem porcentagens simuladas: brass identifica execução e ação,
frost organiza estado público e timeline. O conteúdo segue fase e tempo
decorrido → mesa pública → eventos incrementais → conclusão/replay. A interação
revela o primeiro checkpoint assim que ele existe, preserva a mesa ao
reconectar, drena páginas terminais e oferece nova tentativa explícita em
timeout ou falha operacional.

Para o Battle Learning, a tese é um registro de mesa pós-partida: arte de
printing exata ancora deck e cartas observadas, verde identifica o que deve ser
preservado e brass identifica revisão e próxima ação. O conteúdo segue entrada
de jogo → sessão/Battle → replay imutável → sinais estruturados → recibo →
Optimize autenticado. A interação nunca inventa arte por nome nem transforma a
evidência em autorização automática para alterar o deck.

Para Social/Trade, a tese é uma mesa social confiável: carta e pessoa ancoram a
decisão, Frost organiza identidade/estado e Brass indica somente a próxima
ação. O conteúdo segue falta → cópia pública verificável → proposta recuperável
→ revisão → resposta/histórico. A interação revalida privacidade e
disponibilidade no backend, nunca infere impressão e não apresenta o ManaLoom
como intermediador de pagamento ou entrega.

Para Onboarding Intent, a tese é uma mesa de escolha Obsidian/Frost: a
ilustração ManaLoom ancora identidade, enquanto Brass fica reservado à próxima
ação. O conteúdo segue objetivo → experiência/formato → método → tarefa real →
Home contextual. A interação persiste intenção antes do handoff, permite pular
e retomar e só conclui após sucesso verificável, sem inferir resultado a partir
de um deck preexistente.

Para Visual System Workspace, a tese é uma bancada do jogador: identidade e
contexto ficam à esquerda, tarefa e decisão à direita no wide; Frost organiza
leitura e Brass identifica somente prioridade/ação. O conteúdo segue identidade
→ tarefa/estado → evidência → decisão → feedback. A interação distingue clean,
dirty, saving, success e error, e usa linguagens próprias para primeiro uso,
zero resultados, offline e indisponível.

Para Critical Overlays and States, a tese é manter a decisão crítica em
primeiro plano sem perder o contexto que a originou: Obsidian reduz o fundo,
Frost sustenta leitura, Brass marca recuperação e coral identifica risco
destrutivo. O conteúdo segue contexto anterior → ação aberta → consequência →
cancelamento, retry ou estado final. A interação usa anchors estáveis, não
executa mutation destrutiva na fixture, preserva entrada no erro e mantém
identidade exata de carta/impressão quando ela participa da decisão.

## Fluxo canônico

Revalidar somente a prova já revisada:

```bash
./scripts/manaloom_ui_live_evidence_gate.sh --check
```

Capturar o Battle Coach em runtime Android conectado:

```bash
MANALOOM_UI_PROOF_DEVICE=<ANDROID_RUNTIME_ID> \
MANALOOM_UI_ANDROID_RUNTIME_KIND=auto \
./scripts/manaloom_ui_live_evidence_gate.sh --capture-battle-coach
```

Capturar o Battle Live em build Web release real:

```bash
./scripts/manaloom_ui_live_evidence_gate.sh --capture-battle-live-web
```

Capturar o Battle Learning em três builds Web release reais:

```bash
./scripts/manaloom_battle_learning_visual_qa.sh
```

Capturar Social/Trade em três builds Web release reais:

```bash
./scripts/manaloom_social_trade_visual_qa.sh
```

Capturar Onboarding Intent em três builds Web release reais:

```bash
./scripts/manaloom_onboarding_intent_visual_qa.sh
```

Capturar Visual System Workspace em três builds Web release reais:

```bash
./scripts/manaloom_visual_system_workspace_qa.sh
```

Capturar Critical Overlays and States em três builds Web release reais:

```bash
./scripts/manaloom_critical_overlays_states_visual_qa.sh
```

Essa prova registra cinco checkpoints nos perfis exclusivos
`web_onboarding_intent_mobile_390x844`,
`web_onboarding_intent_desktop_1440x900` e
`web_onboarding_intent_wide_1920x1080`: primeiro uso, caminho configurado,
retomada, skip/Home e conclusão/Home. Capturar não promove o aggregate; todas
as 15 imagens precisam ser abertas e revisadas primeiro.

A prova Visual System Workspace registra dez checkpoints nos perfis exclusivos
`web_visual_system_mobile_390x844`,
`web_visual_system_desktop_1440x900` e
`web_visual_system_wide_1920x1080`: Profile clean/dirty/saving/error/saved,
perfil público com card art, primeiro deck, zero resultados, offline e
indisponível. Capturar não promove o aggregate; todas as 30 imagens precisam
ser abertas e revisadas primeiro.

A prova Critical Overlays and States registra 22 checkpoints nos perfis
exclusivos `web_critical_overlays_mobile_390x844`,
`web_critical_overlays_desktop_1440x900` e
`web_critical_overlays_wide_1920x1080`: segurança abaixo da dobra, avatar,
bloqueados loading/error/retry/recovered, validações de senha/sessão/conta,
ação e cancelamento de exclusão de deck, recuperação de comandante, editor do
Fichário, picker/revisão/erro de Trade e contratos explícitos de sessão expirada
e permissão negada. Capturar não promove o aggregate; todas as 66 imagens
precisam ser abertas e revisadas primeiro.

Essa prova registra 16 checkpoints nos perfis exclusivos
`web_social_trade_mobile_390x844`,
`web_social_trade_desktop_1440x900` e
`web_social_trade_wide_1920x1080`: match, Marketplace, proposta reidratada,
revisão, indisponibilidade, contraproposta, recusa, erro, conclusão, vazios e
comentário contextual. Capturar não promove o aggregate; todas as 48 imagens
precisam ser abertas e revisadas primeiro.

Essa prova registra dez checkpoints nos perfis exclusivos
`web_battle_learning_mobile_390x844`,
`web_battle_learning_desktop_1440x900` e
`web_battle_learning_wide_1920x1080`. Os nomes exclusivos impedem colisão com
os perfis da matriz P0. Capturar não promove o aggregate: todas as 30 imagens
precisam ser abertas e revisadas primeiro.

Essa prova usa gateway fake, não autentica nem chama API, e registra cinco
checkpoints: espera com progresso indeterminado, feed público com snapshot e
evento, falha recuperável preservando a mesa, timeout com próxima ação clara e
conclusão com replay. A captura grava
`docs/qa/ui-live/current/battle-live-web/capture-manifest.json`; ela permanece
fora do aggregate até todas as cinco imagens serem abertas e revisadas.

O capture do Battle Coach executa analyzer e testes focados, roda o integration
test no device e atesta por ADB se o alvo é emulador ou aparelho físico,
extrai os PNGs emitidos pelo runtime e grava
`docs/qa/ui-live/current/battle-coach-android/capture-manifest.json`. Capturar
não aprova visualmente: depois disso o revisor abre cada PNG, corrige a UI se
necessário, recaptura e somente então atualiza `docs/qa/ui-live/latest.json`.

A política corrente exige a matriz P0 ampla em quatro perfis: Web real mobile,
desktop e wide, mais o Samsung físico `android_physical_sm_a135m`. Battle Live,
Binder Import, Deck Workshop, Battle Learning, Social/Trade, Onboarding Intent,
Visual System Workspace e Critical Overlays and States completam 26 manifests
e 456 capturas. Battle Coach Android e teclado Web continuam superfícies
opcionais/separadas enquanto não forem declarados como perfis obrigatórios pela
política executável.

Os manifests ficam sob `docs/qa/ui-live/current`. O aggregate `latest.json`
registra o hash de cada manifesto, todos os perfis revisados e a quantidade
total de screenshots. O verificador exige igualdade exata desses conjuntos;
revisar apenas uma seleção de imagens não concede `PASS_VISUAL_REVIEWED`.

Vídeo é evidência complementar. Uma gravação contínua pode ajudar a revisar
sequência e interação, mas não substitui manifests, PNGs, hashes nem a abertura
de todas as capturas. Um reel montado a partir de screenshots aprovadas deve ser
rotulado explicitamente como `derived_runtime_frames`; ele não prova uma
interação contínua nem recebe crédito E2E adicional. MP4s derivados permanecem
locais sob `docs/qa/ui-live/videos/`, ignorados pelo Git. Se uma task exigir
vídeo durável, o receipt deve manter o arquivo fora do checkout e versionar
somente classificação, origem, digest, duração e política de retenção.

O Life Counter é uma platform view Android. Screenshot produzida pela surface
Flutter não comprova sua composição nativa e pode resultar em frame preto.
Nesse checkpoint o harness anuncia prontidão e
`scripts/manaloom_capture_android_platform_view.sh` usa `adb screencap` no
runtime Android, valida assinatura PNG, dimensão landscape e tamanho mínimo antes de
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
  nem smoke de hardware/release. Prova em emulador valida o runtime Android,
  mas não recebe crédito por sensores, desempenho, fabricante ou comportamento
  específico de hardware. Teclado Web real só recebe crédito quando o
  manifesto de runtime correspondente está presente.
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
- integração Battle Live:
  `app/integration_test/battle_live_visual_runtime_proof_test.dart`;
- integração Battle Learning:
  `app/integration_test/battle_learning_visual_runtime_proof_test.dart`;
- integração Social/Trade:
  `app/integration_test/social_trade_visual_runtime_proof_test.dart`;
- captura Social/Trade: `scripts/manaloom_social_trade_visual_qa.sh`;
- integração Onboarding Intent:
  `app/integration_test/onboarding_intent_visual_runtime_proof_test.dart`;
- captura Onboarding Intent:
  `scripts/manaloom_onboarding_intent_visual_qa.sh`;
- integração Visual System Workspace:
  `app/integration_test/visual_system_workspace_runtime_proof_test.dart`;
- captura Visual System Workspace:
  `scripts/manaloom_visual_system_workspace_qa.sh`;
- integração Critical Overlays and States:
  `app/integration_test/critical_overlays_states_runtime_proof_test.dart`;
- captura Critical Overlays and States:
  `scripts/manaloom_critical_overlays_states_visual_qa.sh`;
- extração/verificação: `app/tool/ui_runtime_evidence.dart`;
- gate: `scripts/manaloom_ui_live_evidence_gate.sh`;
- digest: `scripts/manaloom_ui_source_digest.sh`;
- captura nativa de platform view:
  `scripts/manaloom_capture_android_platform_view.sh`;
- evidência corrente: `docs/qa/ui-live/latest.json`.
