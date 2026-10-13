# Receipt — BT-ART-01: contrato de arte e o portão da Scryfall (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. O PASS também espera a recaptura da prova de UI: a R1 para o que já está no `master`, ou a R2 para o que entra no PR-C (D-92).
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

As imagens nativas de carta passam por um portão que pede licença para cada tentativa na Scryfall e repete 429, 5xx e erro de rede com a política compartilhada (D-37). O User-Agent é `BrewTact/1.0 (+https://brewtact.com)`, e qualquer host que não seja a Scryfall por https é recusado. O herói do deck mostra o selo de referência, e o contrato de arte foi reescrito para a BrewTact.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `f0c24e0a0` | 2026-10-05 | BT-ART-01: Scryfall gate on native, BrewTact User-Agent, host refusal, no crop |

## Testes que cobrem o aceite

- `app/test/core/services/scryfall_image_cache_manager_test.dart`: portão e retry no caminho nativo.
- `app/test/core/widgets/card_image_source_policy_guard_test.dart`: nada de crop nos widgets de carta.
- `app/test/core/widgets/cached_card_image_test.dart`: o cache de imagem.
- `server/test/scryfall_image_url_test.dart`: recusa de host fora da Scryfall.

## Outros arquivos

- `docs/MANALOOM_CARD_ART_SOURCE_CACHE_AND_RIGHTS_CONTRACT.md`: o contrato reescrito.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- A prova de UI na R1.
