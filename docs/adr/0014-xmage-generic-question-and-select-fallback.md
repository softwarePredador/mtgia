# ADR 0014 — Pergunta genérica do motor e fallback de GAME_SELECT no Jogar contra IA

- Estado: **ACEITO** em 2026-10-08 pela decisão do dono (D-88, em
  `docs/status/DECISOES_PENDENTES_2026-09-22.md`: "Aprovar o complemento").
- Data: 2026-10-08
- Programa: `BL8` (runtime interativo, Jogar contra IA)
- Complementa: ADR 0012 (GO limitado do spike humano; relato completo no
  registro histórico `0004-xmage-human-spike-go.md`) e ADR 0005 (resposta
  tipada). Não substitui nenhum item deles.

## Contexto

O registro do spike (`0004-xmage-human-spike-go.md`, "Evidência runtime")
fixou: "qualquer callback, payload, opção, estado ou confirmação fora do
contrato falha fechado e termina a sessão". No bridge isso foi implementado
também sobre o **texto** da mensagem: `HumanVsAiSpikeHarness.classify` só
reconhecia o `GAME_ASK` do mulligan e quatro prefixos de `GAME_SELECT`. Para
qualquer outro texto devolvia `null`, `PromptRegistry.open` lançava
`IllegalArgumentException` e o `catch` de `InteractiveBattleRegistry.onCallback`
encerrava a sessão com `engine_error`/`interactive_callback_failed`.

Medido em 2026-09-23 na captura `play-vs-ai-web-real`: a mesa morreu no turno
4, na fase principal pré-combate, na primeira pergunta de sim/não do motor
(por exemplo "Use replacement effect?"). O ramo genérico "Sim"/"Não" de
`questionPrompt` já existia, mas era inalcançável, e o teste do sidecar
afirmava `null` como resultado esperado. Como `fail` guarda só
`getSimpleName()`, a falha também era indiagnosticável. A sessão morria dentro
do sidecar; nenhum prompt chegava ao servidor.

## Decisão

1. `GAME_ASK` que não é o mulligan passa a ser `PromptKind.QUESTION` (kind
   `question` no fio), com as opções opacas "Sim"/"Não" (role `choice`,
   resposta booleana) que o bridge já montava.
2. `GAME_SELECT` com texto fora dos prefixos conhecidos não decide pela frase:
   - se as opções do callback trazem `possibleAttackers` ou `possibleBlockers`
     (as chaves que o XMage põe ao pedir a declaração de atacantes e
     bloqueadores, `Constants.Option`), o kind é `COMBAT`. `selectPrompt`
     oferece então as criaturas dessas chaves, além das jogadas legais;
   - sem dado de combate, o kind é `MAIN_ACTION`: `selectPrompt` monta as
     jogadas legais a partir de `getCanPlayObjects` e inclui "Passar
     prioridade" quando a lista sai vazia.

   Cair sempre em `MAIN_ACTION` não perderia só um realce: `selectPrompt` só
   oferece as criaturas de `possibleAttackers`/`possibleBlockers` quando o kind
   é `COMBAT`, então o jogador ficaria sem poder atacar nem bloquear e só
   conseguiria passar. Por isso o payload de combate vence a frase.
3. Toda vez que o fallback por texto do `GAME_SELECT` é usado,
   `PromptRegistry.open` escreve em stderr uma linha
   `interactive_select_text_fallback` com o kind escolhido, quais chaves de
   combate vieram e o tamanho da frase. A linha não leva o texto do motor (que
   pode trazer nome de jogador), opções, cartas nem IDs.
4. O servidor passa a aceitar `question` em `interactiveBattlePromptKinds`.
   `server/test/interactive_battle_contract_test.dart` lê o enum Java e prova
   que nenhum kind do sidecar fica fora da allowlist, e prova que o parser do
   prompt aceita `question` e recusa um kind desconhecido.
5. O `catch` do callback registra em stderr `interactive_callback_failed` com
   método, id de runtime, turno e stack trace do bridge.

## Limite do relaxamento

O que muda é só a classificação **por texto**, e só para `GAME_ASK` e
`GAME_SELECT`, que já estavam em `DECISION_CALLBACKS` e
`LEGACY_BRIDGED_CALLBACKS`. Continuam fail-closed, sem mudança:

- callback cujo método não é allowlisted, payload de tipo errado
  (`requirePayload`), opções acima do limite (`MAX_OPTION_COUNT`), IDs não
  opacos. `selectPrompt` ainda pode lançar por esses motivos e encerrar a mesa;
- payload de combate malformado (chave que não é lista de UUID), recusado em
  `combatSelectableIds`;
- resposta obsoleta, duplicada, fora das opções ou rejeitada pelo XMage;
- timeout, que concede e termina a sessão (sem decisão implícita pela IA);
- kind fora de `interactiveBattlePromptKinds` no servidor;
- validação final de legalidade, que segue no XMage.

Os logs novos não carregam mensagem, opções nem cartas do prompt. Mensagens de
exceção do bridge só trazem nomes de tipo e de chave; exceções internas do
XMage passam sem filtro e precisam de revisão se surgir dado privado.

## Limitação de produto e follow-up de backlog

A pergunta genérica aparece com o título "Sua decisão", a mensagem genérica
"Escolha uma ação legal para continuar." e os botões "Sim"/"Não":

- `productPromptMessage` não repassa o texto do motor, então o jogador responde
  sem ver a pergunta;
- os rótulos próprios que o motor manda em `UI.left.btn.text` e
  `UI.right.btn.text` são descartados. Numa pergunta "topo ou fundo?", o "Sim"
  significa "topo" e o jogador não tem como saber.

Isso mantém a mesa viva, mas não é uma experiência aceitável de produto. Fica
registrado como follow-up de backlog: texto de produto por pergunta e uso dos
rótulos do motor (saneados e limitados, como os demais textos do prompt). Não
entra neste ADR, e o Battle segue fora do escopo do MVP (D-87).

## Ordem de deploy

O sidecar novo emite `kind: "question"`. Um servidor sem `question` na
allowlist rejeita esse prompt (`interactive_battle_prompt_invalid`) e a mesa
morre do mesmo jeito. Por isso o servidor tem de aceitar `question` **antes ou
junto** do sidecar; nunca o sidecar sozinho. O fallback de `GAME_SELECT` usa
`combat` ou `main_action`, que o servidor já aceita. As capabilities Battle
continuam `OFF` (ADR 0013), e este ADR não autoriza deploy, migration nem
rollout.

## Revisão

O ADR entra em `canonical_documents`. Volta a ser revisto quando o follow-up de
texto por pergunta for feito, ou se o XMage passar a mandar a declaração de
combate sem `possibleAttackers`/`possibleBlockers`.
