# Life Counter - WebView Editing Guardrails - 2026-04-04

## Objective

Registrar, de forma operacional, como o `life counter` se relaciona com o app shell e qual contrato minimo o `WebView` do Lotus precisa preservar para permitir evolucao visual sem quebrar o host ManaLoom.

Este documento complementa:

- `app/doc/LIFE_COUNTER_WEBVIEW_EXECUTION_PLAN_2026-04-02.md`
- `app/doc/LIFE_COUNTER_CORE_OWNERSHIP_CLOSURE_PLAN_2026-04-02.md`

## App relation today

### Entry path

- entrada oficial da home: `app/lib/features/home/home_screen.dart`
- helper de rota: `app/lib/features/home/life_counter_route.dart`
- rota viva: `/life-counter`

O app agora abre o contador por um helper dedicado:

- `openLifeCounterRoute(context)`

Isso tira a navegacao do call site e concentra a relacao do contador com o app shell em um ponto unico.

### Exit path

- tela viva: `app/lib/features/home/lotus_life_counter_screen.dart`
- helper de saida: `closeLifeCounterRoute(context)`

Comportamento atual:

- se existe pilha anterior, o `life counter` faz `pop`
- se a rota foi aberta diretamente, o `life counter` cai para `/home`
- o `back` do sistema segue essa mesma regra
- o `WebView` tambem pode pedir fechamento via shell message `close-life-counter`

Leitura pratica:

- o contador agora nao depende mais de um `Navigator.pop()` implicito
- a relacao `home <-> life counter` ficou explicitamente owned pelo app shell

## WebView contract today

### Central contract file

Arquivo de referencia:

- `app/lib/features/home/lotus/lotus_webview_contract.dart`

Esse arquivo concentra:

- tipos de mensagem da shell
- seletores de DOM observados pelo host
- contrato injetado em `window.__ManaLoomLotusContract`

Isso reduz drift entre:

- `lotus_host_controller.dart`
- `lotus_shell_policy.dart`
- `lotus_life_counter_screen.dart`

### Current shell message contract

Mensagens explicitamente owned:

- `analytics`
- `blocked-link`
- `blocked-window-open`
- `close-life-counter`
- prefixo `open-native-`

Regra:

- se um redesign do Lotus mantiver esse contrato, o app continua entendendo handoffs, bloqueios de links externos e fechamento da tela
- se esse contrato mudar, o host Flutter precisa ser atualizado junto

### Current DOM contract

Seletores centralizados hoje:

- `.player-card`
- `[class*="overlay"]`
- `.game-timer:not(.current-time-clock)`
- `.current-time-clock`
- `.turn-time-tracker`
- `.menu-button`
- `.player-card-inner.option-card`
- `.close-controls-backdrop`
- counters regulares em card
- counters de commander damage em card

Esses seletores hoje sao usados para:

- probes e snapshots do host
- validacao de `live_runtime`
- reset de takeover stale
- observabilidade do runtime Lotus

## Safe editing zone

Mudancas consideradas seguras, desde que nao removam o contrato acima:

- cores
- gradientes
- tipografia
- iconografia
- assets de fundo
- copy visual
- animacoes internas
- espacamentos
- bordas
- sombras
- refinamento de CSS da mesa

Tambem e seguro:

- reorganizar CSS
- introduzir wrappers estilisticos extras
- trocar assets e tokens visuais

Desde que:

- os seletores observados continuem existindo
- a semantica visual principal continue apontando para os mesmos alvos do host

## Sensitive editing zone

Mudancas de risco medio:

- renomear classes de elementos que o host observa
- mover o botao/menu para markup totalmente diferente
- trocar a estrutura do tracker, timer ou option-card
- alterar o jeito como player cards carregam ownership visual

Essas mudancas ainda sao possiveis, mas exigem ajuste sincronizado em:

- `app/lib/features/home/lotus/lotus_webview_contract.dart`
- `app/lib/features/home/lotus/lotus_host_controller.dart`
- `app/lib/features/home/lotus/lotus_shell_policy.dart`
- `app/lib/features/home/lotus_life_counter_screen.dart`

## High-risk editing zone

Mudancas de alto risco:

- remover `.player-card`
- remover `.game-timer` ou `.turn-time-tracker`
- remover `.menu-button`
- eliminar `.player-card-inner.option-card`
- trocar o canal de mensagens da shell sem manter compatibilidade
- trocar o shape do payload `open-native-*`
- eliminar a nocao de menu/overlay sem oferecer substituto claro

Consequencia:

- patches live podem parar de aplicar
- resets de superficie podem falhar
- observabilidade pode passar a reportar sucesso falso ou falha silenciosa
- o app pode perder a capacidade de sair corretamente do contador por shell

## Minimum contract to preserve

Para poder redesenhar o `WebView` sem reabrir uma frente de reimplementacao do host, precisamos preservar pelo menos:

1. Rota e shell

- o app continua abrindo em `/life-counter`
- o `WebView` continua aceitando o ambiente embutido do host

2. Messaging

- `window.__ManaLoomLotusContract.messages`
- `close-life-counter`
- `analytics`
- prefixo `open-native-`
- `blocked-link`
- `blocked-window-open`

3. Surface selectors

- alvo equivalente para player card
- alvo equivalente para timer
- alvo equivalente para clock
- alvo equivalente para tracker
- alvo equivalente para menu button
- alvo equivalente para option-card takeover

4. Storage expectations

- o runtime continua permitindo bootstrap/control via `localStorage`
- o bundle continua reidratavel pelo host ManaLoom

## Editing strategy recommendation

### If the goal is visual polish

Preferir:

- editar `css`
- editar assets
- editar texto
- preservar classes e mensagens atuais

Esse e o caminho mais barato e mais seguro.

### If the goal is structural redesign

Fazer em duas etapas:

1. mapear os novos alvos no contrato central
2. adaptar host, shell policy e runtime tests antes de substituir o markup antigo

Regra pratica:

- nao trocar HTML e depois descobrir no smoke o que quebrou
- primeiro atualizar o contrato, depois migrar a superficie

## Operational recommendation

Se formos mexer no design do Lotus daqui para frente, a ordem recomendada e:

1. editar `app/assets/lotus/`
2. preservar os seletores e mensagens do contrato atual
3. se algum seletor precisar mudar, atualizar primeiro:
   - `lotus_webview_contract.dart`
   - `lotus_host_controller.dart`
   - `lotus_shell_policy.dart`
   - `lotus_life_counter_screen.dart`
4. validar com:
   - `flutter analyze`
   - testes de host/policy
   - smoke Android do `WebView`

## Final reading

Hoje o `life counter` esta bem preparado para:

- mudar skin
- mudar acabamento visual
- evoluir UX dentro do proprio Lotus

Hoje ele ainda e sensivel para:

- trocar markup estrutural sem coordenar o host
- renomear classes observadas
- quebrar o contrato de mensagens do shell

Resumo honesto:

- design editavel: sim
- redesign estrutural sem tocar o host: nao
- redesign estrutural com contrato central e smoke real: sim
