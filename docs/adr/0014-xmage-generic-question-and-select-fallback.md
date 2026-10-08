# ADR 0014 — Pergunta genérica do motor e fallback de GAME_SELECT no Jogar contra IA

- Estado: **PROPOSTO — pendente de aprovação do dono**. Não é decisão vigente;
  fica fora de `canonical_documents` até o aceite.
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
`getSimpleName()`, a falha também era indiagnosticável.

## Mudança proposta

1. `GAME_ASK` que não é o mulligan passa a ser `PromptKind.QUESTION` (kind
   `question` no fio), com as opções opacas "Sim"/"Não" (role `choice`,
   resposta booleana) que o bridge já montava.
2. `GAME_SELECT` com texto fora dos prefixos conhecidos passa a ser
   `MAIN_ACTION`. `selectPrompt` monta as jogadas legais a partir de
   `getCanPlayObjects` e sempre inclui "Passar prioridade"; perde-se só o
   realce de combate, que depende de reconhecer a frase.
3. O servidor passa a aceitar `question` em `interactiveBattlePromptKinds`, e
   `server/test/interactive_battle_contract_test.dart` lê o enum Java para
   provar que nenhum kind do sidecar fica fora da allowlist.
4. O `catch` do callback registra em stderr `interactive_callback_failed` com
   método, id de runtime, turno e stack trace do bridge.

## Limite do relaxamento

O que muda é só a classificação **por texto**, e só para `GAME_ASK` e
`GAME_SELECT`, que já estavam em `DECISION_CALLBACKS` e
`LEGACY_BRIDGED_CALLBACKS`. Continuam fail-closed, sem mudança:

- callback cujo método não é allowlisted, payload de tipo errado, opções acima
  do limite, IDs não opacos;
- resposta obsoleta, duplicada, fora das opções ou rejeitada pelo XMage;
- timeout, que concede e termina a sessão (sem decisão implícita pela IA);
- kind fora de `interactiveBattlePromptKinds` no servidor;
- validação final de legalidade, que segue no XMage.

Limitação conhecida: `productPromptMessage` não repassa o texto do motor, então
a pergunta genérica aparece com o título "Sua decisão" e uma mensagem genérica.
O jogador responde Sim/Não sem ver a pergunta. Texto de produto por pergunta é
um trabalho separado e não entra nesta proposta.

O log novo não carrega mensagem, opções nem cartas do prompt. Mensagens de
exceção do bridge só trazem nomes de tipo e de chave; exceções internas do
XMage passam sem filtro e precisam de revisão se surgir dado privado.

## Ordem de deploy

O sidecar novo emite `kind: "question"`. Um servidor sem `question` na
allowlist rejeita esse prompt (`interactive_battle_prompt_invalid`) e a mesa
morre do mesmo jeito. Por isso o servidor tem de aceitar `question` **antes ou
junto** do sidecar; nunca o sidecar sozinho. O fallback de `GAME_SELECT` usa
`main_action`, que o servidor já aceita. As capabilities Battle continuam
`OFF` (ADR 0013), e esta proposta não autoriza deploy, migration nem rollout.

## Critério de aceite

O dono aprova ou recusa esta proposta. Se aprovar, o ADR entra em
`canonical_documents` e o estado passa a aceito. Se recusar, a correção do
código volta ao comportamento anterior (falha fechada por texto) ou é
substituída por outra decisão registrada em novo ADR.
