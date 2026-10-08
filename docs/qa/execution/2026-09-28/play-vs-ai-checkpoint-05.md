# `play-vs-ai-web-real` — o checkpoint 05 e o limite da fixture (2026-09-28)

> **Nota editorial (2026-10-08).** Registro histórico da árvore antiga do gate
> (backup `refs/backup/2026-10-08/gate-arvore-1419`), trazido como estava; o
> "não commitado" abaixo era o estado daquela árvore. **Kari Zev não foi
> adotado:** o master fechou o checkpoint 05 sem trocar o deck — o adversário
> do `scripts/manaloom_play_vs_ai_e2e.sh` continua sendo Krenko, e o pacote
> `play-vs-ai-web-real` foi recapturado com `PASS_RUNTIME` e
> `PASS_VISUAL_REVIEWED` (`docs/qa/execution/2026-10-06/btuiev001-recaptura-unica.md`).
> A seção "RESOLVIDO" descreve a solução daquela árvore, não a do master. O que
> ficou do registro são as lições de método e a regra da chave de
> idempotência na concessão, que o roteiro de captura do master segue.

Arquivo **não commitado** enquanto o gate de UI está vermelho.

## Oito dos nove capturam de forma confiável

`01`, `02`, `03`, `04`, `06`, `07`, `08` e `09`, numa passagem única contra o
motor XMage local, 1440x900, com asserção real em cada um. O `04` foi conferido
abrindo a imagem: mostra o Plains **e** o Isamaru na mesa, pilha vazia, sem
oferta de lançar.

## O `05` esbarra no confronto que a fixture semeia

O contrato pede dano de combate **com a partida em curso**. Medido pela API do
backend, em quatro corridas e dois ambientes recém-construídos:

```
vida no início:  40 e 40
vida no fim:     -23 e 40     status=completed, terminal=true
```

O primeiro dano de combate desta matchup **já é o letal**: o deck do sujeito é
Plains mais Isamaru e não se defende, o adversário acumula goblins e ataca uma
vez só, para 63. Não existe estado "ferido e vivo" para capturar — o mesmo golpe
que causa o dano encerra a mesa, e essa tela é justamente a do `07`.

## O que eu tentei, e o que cada tentativa ensinou

1. **Exigir queda da vida adversária.** Errado: quem apanha é o sujeito.
2. **Aceitar queda de qualquer lado, lendo a tela.** Capturou "Partida
   concluída" no turno 21 — o fim, não o combate.
3. **Exigir o rótulo "Dano de combate".** 420 s sem cair no instante.
4. **Amostrar lendo a árvore inteira duas vezes por volta.** O driver passava o
   tempo lendo em vez de jogando, e a partida nem avançava.
5. **Gatilho pelo estado da API**, como a coordenação sugeriu. Trouxe ganho real
   de diagnóstico — foi assim que descobri que o estado do jogo mora em
   `private_state` e que o contrato expõe um campo `terminal` autoritativo. Mas
   como **gatilho** ela é pior que a tela aqui: o backend entrega o valor
   assentado (40, depois -23), enquanto a tela atualiza progressivamente.
6. **Tela como gatilho, API como guarda de fim.** É a combinação certa, e está
   no código. Mesmo assim não há instante para pegar nesta matchup.
7. **Vigiar o dano desde o mulligan**, não só depois do comandante, para pegar
   um ataque pequeno do início. Não há ataque pequeno: o primeiro é o letal.

## O que resolveria, e é decisão de contrato

O deck do sujeito precisa sobreviver ao primeiro ataque. Três caminhos, nenhum
meu para decidir:

- semear no deck do sujeito com que se defender, para haver um turno em que ele
  apanha e continua vivo;
- o driver responder o prompt de bloqueio em vez de delegar, jogando para
  sobreviver — isso muda o que o pacote prova, de "partida real" para "partida
  jogada de um jeito específico";
- aceitar que, nesta matchup, o instante de dano coincide com o fim, e redefinir
  o que o `05` deve mostrar.

## Ganhos que ficam, independentemente da decisão

- **Limpeza de mesas pela API antes de começar.** Cada corrida que falhava no
  meio deixava a sessão viva, e a seguinte gastava minutos — às vezes o limite
  inteiro — só para voltar ao estado de boas-vindas. Isso é preparo, não prova.
- **Guarda de fim de partida pelo campo `terminal`** do próprio contrato, em vez
  de eu enumerar nomes de status e errar um (`waiting_for_action` já me pegou).
- **A lição do `private_state`:** o estado do jogo não está no topo da resposta;
  o app o lê de lá (`interactive_battle_session.dart:334`), e eu precisei medir
  as chaves para descobrir em vez de supor.

---

## A troca de deck (opção 1): duas tentativas, e o que a medição mostrou

### Tentativa 1 — Raging Goblin no deck do adversário

Semeei `Raging Goblin` (1/1, ímpeto) no catálogo isolado e troquei o deck do
adversário para `Krenko + 1 Raging Goblin + 98 Mountain`.

Não funcionou, e o erro de raciocínio foi meu: **uma** cópia em 100 cartas quase
nunca é comprada cedo, e o singleton de Commander impede repetir a carta. O dano
do começo precisa vir de algo sempre disponível.

### Tentativa 2 — Zurgo Bellstriker como comandante adversário

O comandante é a única carta sempre disponível, então troquei: sai Krenko
(`{2}{R}{R}`, que prefere gerar goblins), entra `Zurgo Bellstriker` (`{R}`, 2/1,
que ataca cedo). Confirmei antes que nada no fluxo do navegador depende do
Krenko — o `_aiCommander` do teste de contrato usa decks próprios.

Também não funcionou, e desta vez a API disse exatamente por quê:

```
turno 22 | status waiting_for_action | terminal false
  QA Web Isamaru: vida=40  campo=[Plains, Isamaru, Hound of Konda]
  QA Web Zurgo:   vida=40  campo=[Zurgo Bellstriker, Mountain x5]
```

Zurgo está no campo desde cedo e **nunca atacou**. O motivo é o meu próprio
Isamaru: um 2/1 não ataca contra um bloqueador 2/2, porque perde a troca. E
mesmo que atacasse, o automático do jogador bloquearia — então o dano não
chegaria ao jogador de qualquer forma.

### O que isso revela sobre o problema

O obstáculo não é o deck adversário ser fraco: é que o sujeito tem um bloqueador
e o automático bloqueia. Para o dano chegar ao jogador, com ele delegando, o
atacante precisa **passar pelo bloqueio** — evasão, tipo voar ou ameaça — ou o
sujeito precisa não ter bloqueador no momento do combate.

Isso é escolha de desenho do confronto, não detalhe de implementação, e por isso
parei aqui em vez de seguir tentando cartas.

### Um erro de método que vale registrar

Ao investigar a primeira falha, capturei o log do estágio com um vigia que
copiava de **qualquer** diretório de corrida. Peguei o log de uma execução
antiga, vi `All tests passed` e afirmei à coordenação que a minha mudança não
tinha quebrado nada. Tinha. Captura de log por padrão de diretório precisa
filtrar pela corrida corrente.

E a quebra em si foi um comentário meu com **aspas duplas** dentro do bloco SQL:
todo aquele SQL viaja numa string de aspas duplas do shell, e a aspa fechou a
string. O PostgreSQL reportou `syntax error at end of input` apontando para a
linha do comentário. Ao documentar isso, escrevi um segundo comentário que também
tinha aspas duplas. O aviso ficou no código, agora sem nenhuma.

---

## RESOLVIDO: comandante adversário com ameaça (2026-09-29)

### A troca, e por que ameaça

O comandante do deck adversário do navegador passou de `Krenko, Mob Boss` para
**`Kari Zev, Skyship Raider`** (`{1}{R}`, 1/3, golpe primeiro e **ameaça**). O
deck volta ao mínimo: comandante mais 99 Mountain. `Raging Goblin` e
`Zurgo Bellstriker` saíram do catálogo.

Ameaça é o que resolve: uma criatura com ameaça **não pode ser bloqueada por uma
criatura só**, e o sujeito tem apenas o Isamaru no campo — que o checkpoint 04
exige lá. O jogador continua delegando ao automático, e o dano passa mesmo
assim, baixo e não letal.

**A carta foi escolhida por conferência, não por indicação.** O exemplo sugerido
era `Kari Zev, Perfect Rebel`, e ela **não existe** no motor pinado: abri o
`mage-sets-1.4.60.jar` e a classe não está lá. `KariZevSkyshipRaider` está.

### A medição, cinco corridas, pela API

| corrida | vida (adversário, você) | turno | status |
| --- | --- | --- | --- |
| 1 | 40, 39 | 5 | `waiting_for_action` |
| 2 | 40, 39 | 5 | `waiting_for_action` |
| 3 | 40, 39 | 6 | `waiting_for_action` |
| 4 | 40, 39 | 5 | `waiting_for_action` |
| 5 | 40, 39 | 5 | `waiting_for_action` |

Cinco de cinco: dano de 1, **os dois vivos**, entre os turnos 5 e 6. Não há
aleatoriedade a reportar.

A captura confirma de olho: cabeçalho `Turno 5 · Combate · First combat damage`,
log com `Kari Zev, Skyship Raider → QA Web Isamaru` e `Ragavan → QA Web Isamaru`,
adversário em 40 e o sujeito em 39, com o painel ainda oferecendo ações.

### O checkpoint 07 e a concessão

Sem o golpe letal, a partida deixou de acabar sozinha em tempo razoável — o dano
agora é de 1 por combate. O `07` passou a **conceder explicitamente**, pelo mesmo
endpoint que o app chama (`/ai/battle/sessions/<id>/concede`), seguido de recarga
para capturar o painel que o produto renderiza. O registro da corrida diz
`sessao CONCEDIDA explicitamente`, e não fica implícito.

A rota exige **chave de idempotência** no corpo, no formato que o app usa; sem
ela devolve 422. Descobri isso lendo a rota depois do erro.

### Resultado

Nove capturas, todas 1440x900, **nove sha256 distintos**.

### Higiene que o caminho ensinou

- Cada corrida interrompida deixa mesa viva ou abandonada, e a rota sem sessão
  reexibe a mesa encerrada até o servidor expirá-la — o que bloqueia a corrida
  seguinte por minutos. Limpar `interactive_battle_sessions` no banco descartável
  antes de cada corrida resolve. A API não serve para isso: conceder mesa já
  abandonada devolve 422.
- A janela de uma hora do harness expira no meio de corridas longas. Foi o que
  produziu um `Connection refused` na concessão, que por um instante pareceu
  defeito e era só o ambiente tendo terminado.
