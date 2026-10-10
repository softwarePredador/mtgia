# Play vs IA: a primeira pergunta de sim/não mata a mesa

Data: 2026-09-23
Escopo: `docs/qa/ui-live/current/play-vs-ai-web-real` (23º manifesto)
Digest de UI: `108f74a9` — inalterado por esta correção

## Sintoma

Na corrida dedicada de captura joguei a partida de verdade pelo navegador e
cheguei ao turno 5 com duas ações validadas em tela. A mesa então morreu com:

> Motor indisponível — O motor não concluiu a partida. Nenhum resultado foi
> fabricado. Código técnico: IllegalArgumentException

```
status          = "engine_error"
terminal_reason = "interactive_callback_failed"
error_code      = "IllegalArgumentException"
```

## Correção do diagnóstico

Meu primeiro recibo dizia que a mesa morria **ao entrar em combate**. Estava
errado, e a inferência era razoável mas não medida: a partida pela UI morreu por
volta do combate, e eu tratei coincidência como causa.

Reproduzindo pela API, a morte é no **turno 4, fase principal pré-combate**,
antes de qualquer combate. O combate não tem nada a ver.

## Causa raiz

`HumanVsAiSpikeHarness.classify` reconhecia **um único** `GAME_ASK`: o mulligan
(mensagem começando com `mulligan ` e os dois textos de botão). Qualquer outro
`GAME_ASK` caía no `return null` final, e `PromptRegistry.open` traduz `null`
em `IllegalArgumentException("callback is not allowlisted")`.

`GAME_ASK` é como o motor faz toda pergunta de sim/não — "Use replacement
effect?", confirmações, gatilhos opcionais. Ou seja: **a primeira pergunta
banal que o motor fizesse derrubava a partida.** Nenhuma partida real podia
terminar.

O mais revelador: o tratamento genérico **já existia e era inalcançável**. O
`else` de `questionPrompt` monta "Sim"/"Não" com role `choice` e nunca podia
rodar, porque `open` estourava duas linhas antes. Alguém escreveu o caminho
certo e o classificador nunca deixou chegar nele.

## Por que ninguém tinha visto

Três coisas se somaram:

1. **A exceção era descartada.** O `catch (Throwable)` do `onCallback` chamava
   `fail()`, que guarda só `error.getClass().getSimpleName()`. A sessão morria
   carregando a string `IllegalArgumentException` e nada mais — nem mensagem,
   nem qual callback, nem stack. O erro era, por construção, indiagnosticável a
   partir da evidência que ele mesmo produzia.
2. **Um teste pinava o defeito como esperado.**
   `HumanVsAiSpikeTest` afirmava
   `classify(GAME_ASK, "Use replacement effect?") == null`. O teste estava
   verde descrevendo exatamente o comportamento que quebrava o produto.
3. **Duas allowlists em linguagens diferentes**, ambas internamente coerentes:
   `PromptKind` no Java e a lista fail-closed em
   `server/lib/battle/interactive_battle_contract.dart`. Nada as comparava.

## O que foi feito

- `InteractiveBattleRegistry.onCallback`: o `catch` agora imprime callback,
  sessão, turno e stack completo antes de falhar. Foi essa mudança que produziu
  o stack trace acima — sem ela eu continuaria adivinhando.
- `HumanVsAiSpikeHarness`: novo `PromptKind.QUESTION`; `GAME_ASK` não-mulligan
  passa a classificar como `QUESTION` em vez de `null`.
- `HumanVsAiSpikeTest`: o caso que pinava `null` agora exige `QUESTION`, e um
  caso novo garante que o mulligan **continua** com kind próprio (é ele que
  decide entre "Fazer mulligan"/"Manter esta mão" e "Sim"/"Não").
- `interactive_battle_contract.dart`: allowlist extraída para
  `interactiveBattlePromptKinds`, com `question` incluído.
- `interactive_battle_contract_test.dart`: teste novo lê o enum Java da fonte e
  exige que todo `PromptKind` esteja na allowlist do servidor. Provado por
  mutação nos dois sentidos — removendo `question` do Dart e acrescentando um
  kind só no Java, o teste falha nomeando o culpado.

Nada disso toca `app/lib`, `app/assets`, `app/web` ou `app/pubspec.*`:
`services/` e `server/lib` estão fora de `manaloom_ui_source_digest.sh`
(conferido, não presumido). O digest continua `108f74a9` e **nenhuma evidência
corrente foi invalidada**.

Correção de um número que eu vinha repetindo: **não** são "22 de 23" manifestos
correntes. Medido agora, comparando `source_digest` de cada
`capture-manifest.json` com o digest atual: **18 de 34 estão em `108f74a9` e 16
estão defasados** — `play-vs-ai-web-real` é apenas um deles. Eu havia herdado o
número errado e o repeti sem medir; na primeira vez que fui medir, ainda errei o
nome do campo (`ui_source_digest` em vez de `source_digest`) e obtive "0 de 34".
Os 16 defasados:

```
battle-coach-android            battle-coach-web-keyboard
battle-live-web                 card-back-fallback-web
card-details-navigation-web     core-product-android
optimization-card-reader-web    play-vs-ai-web-real
ux-pack-01-card-printing-web    ux-pack-01-catalog-web
ux-pack-01-community-web        ux-pack-01-completion-web
ux-pack-01-deck-detail-web      ux-pack-04-battle-learning-web-{desktop,mobile,wide}
```

## O commit continua bloqueado

O índice já trazia, de antes desta sessão, um lote de 112 arquivos que inclui
`app/lib/**` e `app/web/nginx.conf` — mudança app-facing. Pelo
`MANALOOM_UI_LIVE_EVIDENCE_CONTRACT`, ela exige a prova UI integral, e a prova
integral exige os 34 manifestos no digest corrente. Com 16 defasados, o gate
recusa, e está certo em recusar.

Não commitei. Commitar só o meu trabalho não resolveria: o classificador exige
worktree idêntica ao índice, então eu teria de mexer no lote em andamento, o que
é intervenção maior do que o pedido comporta. As mudanças desta sessão ficam na
árvore, com os gates que dependem delas verdes:
`project_logic --write` e `--check` EXIT=0, 47/47 no sidecar, 30/30 nos testes
de servidor tocados.

## Prova de que a correção funciona

Mesma reprodução pela API, mesmo deck, antes e depois:

```
antes:  TERMINAL status=engine_error reason=interactive_callback_failed
        code=IllegalArgumentException turno=4 fase=Precombat Main

depois: TERMINAL status=completed reason=engine_game_over
        turno=20 fase=Combat
```

O momento exato em que a correção pesa aparece no log da partida:

```
t19 Precombat Main -> Sim              <- o `else` de questionPrompt, antes morto
t19 Combat -> Isamaru, Hound of Konda  <- atacante declarado; o combate roda
```

A partida correu 20 turnos até `engine_game_over` natural.

Também rodei o `natural_full_match_spike` depois da correção. A primeira
execução falhou (`idle_timeout`, `deadlocks: 1`, turno 16) e eu **não** conclui
nada a partir disso: repeti, e a segunda deu `PASS` com `normal_completion:
true`, `deadlocks: 0`, turno 19 — idêntico às execuções anteriores à correção.
Era flakiness do spike, não regressão. Ambas as execuções tiveram `GAME_ASK: 1`
(só o mulligan), então o caminho que mudei nem foi exercitado ali.

## Buraco que ficou aberto (FECHADO pelo PR-A2, #32)

> **Atualização:** o `GAME_SELECT` com mensagem não prevista foi fechado pelo
> PR-A2 (#32, ADR 0014: pergunta genérica do motor e fallback do `select`).
> O texto abaixo é o registro de 2026-09-23, mantido como foi escrito.

`classify` devolve `null` também para `GAME_SELECT` com mensagem não prevista, e
`selectPrompt` chama o mesmo `open` — mesma morte. Não corrigi porque não tenho
medição de um caso real: as mensagens de combate que importam para a captura
(`select attackers`, `select blockers`) já são reconhecidas. Fica registrado,
não silenciado.

## Por que o 23º manifesto continua defasado

Com o motor corrigido a partida completa 20 turnos, mas a **captura pelo
navegador** ainda não fecha os nove checkpoints. Dois obstáculos medidos, os
dois independentes do defeito já corrigido:

1. **O app sai da tela de batalha sozinho.** Estando em
   `#/decks/<id>/play-vs-ai` com a partida em curso, o app navega para `#/home`
   sem nenhum clique meu, e a sessão continua `waiting_for_action` no servidor
   — conferido pela API no mesmo instante. "Retomar mesa ativa" traz de volta,
   mas o desvio se repete. Não investiguei a causa; fica como achado.
2. **O prazo de 90s do prompt não perdoa ferramenta.** Cada ida e volta minha
   entre passos custa segundos, e três sessões morreram com
   `interactive_prompt_deadline_expired` enquanto eu ajustava o laço. Escrevi a
   captura como processo único por causa disso, e ainda assim o desvio do item
   1 gasta ~14s por recuperação.

Descartei três capturas que o laço gerou e que eu havia rotulado como
checkpoints: duas `05-combat-damage` e uma `07-terminal-replay-rematch`. As três
saíram de telas erradas porque o leitor de semântica casava um contêiner cujo
`textContent` é a tela inteira, e o critério da `05` (`'40 pontos' not in v`)
era verdadeiro para qualquer string que não fosse um rótulo de vida. Corrigi os
dois — leitura só de folhas com área pequena, e dano medido comparando o número
de pontos — mas a correção veio depois das capturas, então elas foram apagadas,
não reaproveitadas.

O pacote commitado foi **restaurado byte a byte** em
`docs/qa/ui-live/current/play-vs-ai-web-real/`. O 23º manifesto segue defasado
em relação ao digest `108f74a9`, exatamente como estava antes desta sessão — não
o transformei em algo que parecesse pronto.

## Estado da captura

Capturas genuínas da corrida anterior, cada uma aberta e conferida, arquivadas
em `docs/qa/ui-live/reference/2026-09-23-pva-v3-parcial-combate/` (diretório
que nunca foi versionado neste repositório; as capturas vigentes do 23º
manifesto estão em `docs/qa/ui-live/current/play-vs-ai-web-real/`, e a
recaptura única do D-89 as refaz):
`01-opponent-picker`, `02-private-hand-mulligan`, `03-land-played`,
`04-commander-cast`.

Uma quinta foi feita e **descartada**: eu a havia nomeado
`07-terminal-replay-rematch`, mas mostra a tela de erro do motor, não o terminal
normal de fim de partida. Um checkpoint que retrata falha de infraestrutura como
fim de partida esperado é evidência falsa.
