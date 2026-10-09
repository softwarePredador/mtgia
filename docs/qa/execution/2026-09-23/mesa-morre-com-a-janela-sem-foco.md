# A mesa morre quando a janela perde o foco

> **Nota editorial (2026-10-08).** Registro histórico da árvore antiga do gate
> (backup `refs/backup/2026-10-08/gate-arvore-1419`), trazido como estava. O
> achado continua aberto no master: `battle_coach_screen.dart` ainda faz
> `_appActive = state == AppLifecycleState.resumed` e para o polling fora de
> `resumed`, e o app ainda pede `prompt_timeout_seconds: 90`. Nenhuma decisão
> de produto sobre isso foi registrada até esta data. O que mudou foi só o
> instrumento: o harness WebDriver passou a rodar headless (`--headless=new`),
> onde `document.hasFocus()` é sempre verdadeiro, então a captura deixou de
> sofrer com isso. O jogador, não.

Data: 2026-09-23
Arquivo: `app/lib/features/battle/screens/battle_coach_screen.dart`
Estado: **achado, não corrigido** — a correção é decisão de produto, não linha de código

## O que acontece

`battle_coach_screen.dart:100`:

```dart
_appActive = state == AppLifecycleState.resumed;
```

e `_refresh()` (`:224`) retorna cedo quando `!_appActive`. Ou seja: o app para
de buscar o estado da mesa assim que deixa de estar `resumed`.

Em Flutter Web, `resumed` depende do foco da janela, não da visibilidade. Uma
janela **visível mas sem foco** (`document.hasFocus() == false`,
`visibilityState == 'visible'`) já é reportada como não-`resumed`.

O problema é que o prazo do prompt **continua correndo no servidor**. O app envia
`prompt_timeout_seconds: 90`. Então:

1. o jogador clica em outra janela;
2. o app para de atualizar a mesa;
3. 90 segundos depois o servidor abandona a sessão;
4. o jogador volta e encontra "Sessão abandonada", turno 1, mão vazia.

Medido nesta máquina: mesa criada, servidor em `waiting_for_action` com prompt
de mulligan pronto, e a tela parada em "Preparando a mesa — Aguardando estado do
jogo" até o abandono. `document.hasFocus()` era `false` o tempo todo.

## Por que isso não é "só QA"

Parar de poupar rede com o app em segundo plano é razoável. O defeito é o
**descasamento**: o cliente para de acompanhar, o servidor não para de contar.
Quem tira o foco por um minuto e meio perde a partida, exatamente como quem
trocava de aba perdia antes da correção de
`docs/qa/execution/2026-09-23/app-expulsa-da-mesa-ao-focar-a-aba.md`.

## Por que não corrigi

As saídas possíveis são escolhas de produto, não uma linha óbvia:

- continuar o polling com a janela sem foco (gasta rede e bateria);
- distinguir "sem foco" de "oculto" e só pausar no segundo caso;
- renovar o prazo do prompt ao voltar o foco;
- avisar na volta em vez de abandonar em silêncio.

Escolher por conta própria seria inventar política de produto. Fica registrado
para decisão.

## Efeito na captura

É a causa de corridas minhas que eu vinha atribuindo ao motor. A janela dirigida
por WebDriver fica visível e sem foco por padrão, então o tabuleiro nunca
carregava e a mesa era abandonada no turno 1. O driver de captura passou a
reafirmar o foco a cada iteração, via `switchToWindow` do W3C, que é o que de
fato devolve `document.hasFocus() == true`.

Três capturas geradas antes disso foram **apagadas**, não reaproveitadas:
`07-terminal-replay-rematch`, `08-replay` e `09-rematch-picker`. Abri a primeira:
mostrava "Sessão abandonada", turno 1, mão vazia e campo vazio. Uma partida que
nunca começou não é o terminal de fim de partida.
