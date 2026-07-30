# ManaLoom — prova viva core de coleção, deck e otimização

**Data:** 2026-07-29
**Branch:** `codex/free-beta-release-candidate-2026-07-17`
**Digest visual:** `91f4d5af5d61a1e7b9c244f6656ab2d3cf95e9ff23072f202ad040e343c60b34`
**Dispositivo:** Samsung SM-A135M físico, Android 14, 1080×2408, portrait-up
**Decisão deste escopo:** `PASS_AUTOMATED` + `PASS_RUNTIME` + `PASS_VISUAL_REVIEWED`

## Escopo comprovado

O fluxo físico corrente cobre três jornadas do produto:

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
no aparelho físico; ela não é apresentada como E2E de API/PostgreSQL.

## Resultado automatizado

O gate `scripts/manaloom_ui_live_evidence_gate.sh --capture-core-product`
executou, no digest acima:

- análise estática dos nove arquivos envolvidos: sem finding;
- três testes de integração da jornada core: 3/3;
- testes focados de Binder, DeckProvider, modal responsivo e otimização:
  90/90;
- captura física: 12/12 checkpoints;
- atestado fail-closed: aparelho físico, Android 14, 1080×2408 e todas as
  imagens em portrait.

## Evidência runtime

Manifesto:
`docs/qa/ui-live/current/core-product-android/capture-manifest.json`

SHA-256 do manifesto:
`345204c10a435adb03161982d6eb6bb8bf109bb38273b59ec091dc91f209294e`

Todas as capturas possuem 1080×2408:

| Checkpoint | Resultado visível | SHA-256 |
| --- | --- | --- |
| `core_01_collection_editor` | impressão, verso autoral, mercado e cadastro | `e0b64f2e1ef51d4cfd0f37d9d5032e2c1b361fb000033759561dfa5542842f3d` |
| `core_02_collection_inline_validation` | preço inválido dentro do editor | `18bc0cfdd9d34cc1ffeeda41aa8cb890d848ffac7e974b5c8be90faafabe8c03` |
| `core_03_collection_persistence_failure` | falha sanitizada e dados preservados | `7996c6b114366b90d990eed0743e824f0dc8b12479042f64f77332107d8d1fd5` |
| `core_04_collection_retry_success` | Sol Ring salvo por R$ 12,50 | `29e3e4686deea011fb3b8f65df96d45ea9bbed006c993ea7ca30842a79470b1b` |
| `core_05_deck_inline_validation` | nome obrigatório dentro do modal | `099a2f9673abcf716011b0f8e55463a9746ba30256256ef1714385b059ce169e` |
| `core_06_deck_commander_filtered` | somente Lorehold elegível; Sol Ring ausente | `0805672fb4ef990c79dafc6344f527117ccbd3c383bbd31bc39d07350f37fd94` |
| `core_07_deck_persistence_failure` | erro fixado no modal e formulário preservado | `26eaba9068b88ad5e7113f0a7c9b6a14dd2df8efafd713ef76592c01c195017e` |
| `core_08_deck_retry_success` | Lorehold Lessons aparece imediatamente e como “agora” | `fec1fa3302dfa217ada5531960bd2d5138ef3665bae68f17d9e8a18e36a98c8e` |
| `core_09_optimization_safe_mana_preview` | `Terrenos 9 → 36` e `Piso mínimo ≥ 33` | `1256790720707e8e925c20ce769315abaf56ecbb4d5760fe6b19ddc93d3c4e6c` |
| `core_10_optimization_partial_selection` | remoção/adição parcial e recálculo explícito | `430bb0f10950794b6655afd3ccd3989daf56e99735acf75222f8b9e8543dff61` |
| `core_11_optimization_applied` | duas mudanças e ação Desfazer | `f4f87d6270fd035bbaa750cd02127b47988d803d4d5b6bf6b0a0427ab88cdd8d` |
| `core_12_optimization_undo` | confirmação de reversão | `ec4c9262854c67cc3e014f7d840c47ba44205644a112164ae3e69b3ec0e4fe49` |

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
- O aggregate P0 Web mobile/desktop/wide + Android anterior pertence a outro
  digest. Mudanças correntes em Home, Legal e Deck vazio exigem recaptura
  integral, sem carry-forward, antes de `ui-proof` voltar a `PASS`.
- Escritas na fixture PostgreSQL/API, mesmo exclusivamente loopback e
  descartável, permanecem bloqueadas pelo contrato até a confirmação literal
  de uma execução específica.
