# ManaLoom — fechamento de código dos findings visuais P2

**Data:** 2026-07-29
**Estado:** `IMPLEMENTED_AWAITING_NEW_LIVE_PROOF`

Este acompanhamento fecha em código os três findings visuais P2 registrados na
prova P0 anterior. Ele não reaproveita screenshots históricos como aprovação
da interface modificada.

## Alterações

- Home estreita: o trilho de ações rápidas calcula duas ou três ações completas
  por viewport, mantém padding de borda e usa snap pelo passo exato do item. O
  final do scroll não deixa fragmentos laterais.
- Decks vazios: `Criar novo deck` e `Gerar com IA` continuam ocupando a largura
  útil no telefone, mas ficam centralizados e limitados a 380 px em
  desktop/wide.
- Termos e Privacidade: versões foram separadas para leitura responsiva, a
  navegação empilha com texto a 200%, e a seção ativa expõe estado `selected`
  ao leitor de tela.
- O conteúdo jurídico não foi ampliado nem reinterpretado. A tela identifica
  que o texto é informativo da beta e que a revisão jurídica externa continua
  pendente antes do lançamento comercial.
- Harness Web: o driver remove somente margens externas simétricas,
  quase-brancas e inequivocamente fora da superfície Flutter. Imagem escura,
  margem assimétrica ou caso incerto permanece intacto. O recorte aceito é
  registrado no log como `SCREENSHOT_VIEWPORT_CROP`.

## Evidência automatizada

- 40 testes focados de Home, lista de decks, ciclo legal e recorte do runtime:
  `PASS`.
- 3 testes adicionais do contrato de prova viva: `PASS`; os 3 casos do recorte
  fail-safe também foram repetidos junto desse contrato.
- análise estática dos sources e testes alterados: `PASS`, sem findings.
- `git diff --check` e sintaxe dos dois scripts de UI alterados: `PASS`.

## Prova viva ainda obrigatória

O digest visual mudou. Portanto, `PASS_RUNTIME` e
`PASS_VISUAL_REVIEWED` anteriores estão obsoletos para estas superfícies.
Antes de chamar o fechamento de `PASS`, é obrigatório:

1. recapturar a matriz Web mobile, desktop e wide com o driver corrente;
2. recapturar os checkpoints Android afetados no Samsung SM-A135M;
3. abrir todas as novas imagens, inclusive o trilho após scroll, deck vazio em
   wide, Termos e Privacidade a 200%;
4. registrar os hashes/dimensões e atualizar `docs/qa/ui-live/latest.json`;
5. executar `./scripts/quality_gate.sh ui-proof`.

TalkBack humano e revisão jurídica profissional continuam verificações externas
separadas; nenhuma delas recebe crédito desta rodada automatizada.
