# ManaLoom — prova viva core de coleção, deck e otimização

**Data:** 2026-07-29
**Branch:** `codex/free-beta-release-candidate-2026-07-17`
**Digest visual:** `718d54ee3493e503e601568213c20b3a39b7df19d6c6c612f7b7091b5c86ca15`
**Runtime:** emulador Android 14, 1080×2400, portrait-up
**Decisão deste escopo:** `PASS_AUTOMATED` + `PASS_RUNTIME` + `PASS_VISUAL_REVIEWED`

## Escopo comprovado

O fluxo corrente no emulador cobre três jornadas do produto:

1. **Coleção:** abrir o editor de Sol Ring, escolher uma impressão, alternar
   lista/quantidade/condição/idioma/venda, impedir preço inválido dentro do
   editor, preservar os dados após falha de persistência e concluir o retry.
2. **Deck Commander:** impedir nome vazio dentro do modal, oferecer o seletor
   de comandante no formato, filtrar apenas candidato elegível, selecionar
   Lorehold, preservar todos os campos após falha, repetir a criação
   atomicamente e mostrar o deck criado imediatamente.
3. **Otimização:** mostrar a correção de terrenos `9 → 36`, o piso mínimo
   `≥ 33 terrenos`, a validação prévia, seleção parcial com recálculo,
   aplicação e desfazer.

Os providers de persistência usados nesta prova são controlados e
determinísticos. Portanto, esta rodada comprova a UI Flutter e suas transições
no emulador Android; ela não é apresentada como E2E de API/PostgreSQL nem como
prova de aparelho físico.

## Resultado automatizado

O gate `scripts/manaloom_ui_live_evidence_gate.sh --capture-core-product`
executou, no digest acima:

- análise estática dos nove arquivos envolvidos: sem finding;
- três testes de integração da jornada core: 3/3;
- testes focados de Binder, DeckProvider, modal responsivo e otimização:
  90/90;
- captura no emulador: 12/12 checkpoints;
- atestado fail-closed: emulador, Android 14, 1080×2400 e todas as
  imagens em portrait.

## Evidência runtime

Manifesto:
`docs/qa/ui-live/current/core-product-android/capture-manifest.json`

SHA-256 do manifesto:
`606269ddceea37d2c106f99c766c50aed53d76a2928bcb6d5934b49848791ba3`

Todas as capturas possuem 1080×2337:

| Checkpoint | Resultado visível | SHA-256 |
| --- | --- | --- |
| `core_01_collection_editor` | impressão, verso autoral, mercado e cadastro | `3350a4b215b6a4559d67ebbc904d28b9d05e7e875f2b6ed24840804416b71fd8` |
| `core_02_collection_inline_validation` | preço inválido dentro do editor | `306fb7af74eb80cb5604d3bcd337fb144c6696293bc70ccd59c817ac77631a9b` |
| `core_03_collection_persistence_failure` | falha sanitizada e dados preservados | `8448833cbc39e28e633989513474fe5398d9ea4f3ccfddabd52d8ff92d3fdfff` |
| `core_04_collection_retry_success` | Sol Ring salvo por R$ 12,50 | `3f2f3c061bf4366de8700c05baada06c314d5dc2c678290a88a1fc1c3991f9fd` |
| `core_05_deck_inline_validation` | nome obrigatório dentro do modal | `f22a1e1fe621c129126bffa004d521be36a9ddfa80310ea3e2f7a77c7a9fa235` |
| `core_06_deck_commander_filtered` | somente Lorehold elegível; Sol Ring ausente | `5afa43441380a0b7a41b7b1a24c9cc13a8ea849ef56b754635828cc73de3782b` |
| `core_07_deck_persistence_failure` | erro fixado no modal e formulário preservado | `2723e764d397b26f6b8c24fb4e05e42417e6d690004e1985de8617ef330e19cd` |
| `core_08_deck_retry_success` | Lorehold Lessons aparece imediatamente e como “agora” | `0eb35547bf7fb67900308b73bf84873a358c31a37524ccd4596185ce163bc8bb` |
| `core_09_optimization_safe_mana_preview` | `Terrenos 9 → 36` e `Piso mínimo ≥ 33` | `7adf3bc27b3fbaa96b7e23cad02ccae69fd0251f6b37824086f4b38e57a4d116` |
| `core_10_optimization_partial_selection` | remoção/adição parcial e recálculo explícito | `695f95c106d7584c939511a47b12d4d5b38bcaeaf8f4cf15a14325314e59d0c7` |
| `core_11_optimization_applied` | duas mudanças e ação Desfazer | `d81b227ba67bf4ce18b2d400bc37df0ed5bed5a0e9747cb3371415022119e907` |
| `core_12_optimization_undo` | confirmação de reversão | `b5aa1079f7bbaff9502fbd9f9aa10b1c587ad396731734bffaf26d341fff7bac` |

## Revisão visual

As 12 imagens foram abertas individualmente. A decisão
`PASS_VISUAL_REVIEWED` considera:

- **hierarquia e interação:** contexto, estado, erro e próxima ação são
  inequívocos; erros de coleção e deck permanecem na superfície que os gerou;
- **identidade e atratividade:** Obsidian, Frost e Brass, verso autoral,
  símbolos de mana, Commander e objetos de carta mantêm a linguagem de MTG
  sem reproduzir marcas ou verso oficial;
- **cor, contraste e tipografia:** estados usam texto, ícone e cor; títulos,
  labels e CTAs permanecem legíveis no Samsung;
- **espaçamento e adaptação:** modal, sheet, scroll, footer e snackbar não
  apresentam overflow bloqueante em portrait;
- **cobertura de estados:** vazio inválido, falha, retry, sucesso, filtro,
  preview seguro, seleção parcial, aplicação e undo estão representados;
- **acessibilidade visual:** foco/labels e redundância de estado estão
  presentes; TalkBack humano não recebe crédito nesta revisão.

## Tentativas recusadas durante a revisão

Os seguintes runs não contam como aprovação:

- captura em landscape causada pela orientação residual do aparelho;
- interferência da IME/PixelCopy no harness;
- sucesso de criação acompanhado pelo estado vazio de decks;
- card recém-criado com horário “17h” em vez de “agora”;
- carregamento remoto de arte deixando tarefa assíncrona de cache no harness;
- preview que validava `9 → 36` por assert, mas não exibia a transição na PNG;
- rótulo “Piso automático” truncado no cartão compacto.

Cada causa foi eliminada e o conjunto completo foi repetido. A captura final
mostra o deck criado, timestamp coerente, `Terrenos 9 → 36`, `Piso mínimo` e
`≥ 33 terrenos`.

## Limites e pendências separadas

- O conjunto usa clientes/providers controlados e não substitui o E2E mutante
  autenticado de cadastro, deck e otimização contra API/PostgreSQL.
- O teclado físico Web e o TalkBack humano são gates separados.
- O aggregate P0 Web mobile/desktop/wide + Android foi recapturado
  integralmente no mesmo digest; nenhum screenshot anterior recebeu crédito.
- Escritas na fixture PostgreSQL/API, mesmo exclusivamente loopback e
  descartável, permanecem bloqueadas pelo contrato até a confirmação literal
  de uma execução específica.
