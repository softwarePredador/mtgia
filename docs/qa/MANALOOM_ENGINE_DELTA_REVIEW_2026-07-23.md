# Revisão do delta XMage/Forge

Data: 2026-07-23

Branch: `codex/free-beta-release-candidate-2026-07-17`

Commit de implementação revisado:
`2139ec9f6f902a8b266fbb852db6e834b25bceff`

## Decisão

Disposição: `retain_current_pins`.

Nenhum pin, regra, carta, fixture, deck, dado PostgreSQL ou artefato de runtime
foi promovido. O `review_required` do auditor continua sendo o sinal esperado
de que o upstream está à frente; nesta rodada ele foi explicitamente revisado
e resolvido pela manutenção dos runtimes já qualificados:

| Engine | Pin mantido | Head observado | Commits à frente |
|---|---|---|---:|
| XMage | `34d81ea4995ce15d7e1a788dc6d2a3595d35bcec` | `e0fe4b6f6a8dc2899f518b6a0129855f9d4d3c92` | 113 |
| Forge | `a62915f500c2411484689294659c6bb84ea215f8` | `ca0f80041743cf3f72945835f65f72a0eb3dd4cc` | 113 |

## Auditoria reproduzida

O gate oficial read-only foi executado com saída em `/tmp`:

```text
MANALOOM_ENGINE_DELTA_OUTPUT=/tmp/manaloom_engine_delta_20260723.json \
  ./scripts/quality_gate.sh engine-delta

status                              review_required
pin_contract_failures               0
candidate_cards                     316
candidate_fixtures                  328
XMage                               120 cartas / 131 fixtures
Forge                               196 cartas / 197 fixtures
deployment_actions_performed        false
pin_updates_performed               false
postgres_writes                     false
promotion_actions_performed         false
mutations_performed                 []
```

O compare XMage retornou 203 arquivos e não foi truncado. O compare acumulado
Forge atingiu o limite de 300 arquivos do GitHub e permaneceu truncado. Isso
impede tratar a lista Forge como inventário completo e, por si só, já veta uma
promoção automática.

Os contratos relacionados também foram reexecutados:

```text
xmage_strategy_consistency_audit.py         PASS, 29/29
deckbuilding_contract_surface_audit.py      PASS, 0 falhas
operational_surface_alignment_audit.py      PASS, 53/53
quality_gate.sh engine-capabilities         PASS, 95/95; 20 capacidades
```

## Delta depois dos candidatos já qualificados

### XMage

O candidato `529c6a9f0ebdfc5ced0a62693381bf0422bb1fdc` já havia compilado,
passado 41/41 checks do sidecar e executado uma simulação. Ele não foi
promovido porque duas execuções independentes no orçamento público de 40
segundos terminaram em HTTP 504 e exigiram restart.

Entre esse candidato e o head agora observado existem somente dois commits,
ambos limitados a
`Mage.Client/src/main/java/mage/client/deckeditor/DeckEditorPanel.java`
(91 adições e 63 deleções). São correções do editor desktop — sideboarding
rápido e confirmação/nome de arquivo ao salvar — fora da superfície do
sidecar ManaLoom. Não há benefício de runtime que justifique reabrir a
identidade já qualificada para a candidata.

### Forge

O candidato `3958182708b718d8340c9829c6097787d757d983` já havia compilado os
seis módulos necessários e coberto 100/100 cartas dos dois decks exercitados,
mas terminou em HTTP 504 no orçamento público de 40 segundos. O pin atual
concluiu o mesmo request/seed em 16.986 ms com 774 eventos; portanto, a
candidata foi rejeitada por regressão objetiva.

Depois desse candidato há dez commits e 16 arquivos:

- quatro superfícies gerais de AI, seleção/pagamento de mana, zona de
  battlefield/meld e cache de controller;
- cinco scripts corrigidos: `Contested Cliffs`, `Fear of Falling`,
  `The Celestial Toymaker`, `Triangle of War` e `Ulvenwald Tracker`;
- sete scripts novos: `Belladonna Took`, `Bilbo's Gambit`,
  `Bothersome Noisemaker`, `Fateful Discovery`, `Nighthowl Pursuer`,
  `The Sackville-Bagginses` e `Thranduil's Decree`.

Uma busca case-insensitive nos decks e fixtures rastreados em
`docs/hermes-analysis/manaloom-knowledge/decks`, `server/test` e `app/test`
encontrou zero ocorrência dessas 12 cartas. Isso reduz a urgência específica,
mas não qualifica as mudanças gerais: AI, mana e zona podem alterar resultados
de Battle mesmo sem sobreposição nominal. Elas exigem nova imagem candidata,
inventário de fonte, cobertura exata, orçamento público de 40 segundos,
Battle/E2E e replay antes de qualquer avanço.

## Fechamento e limites

A revisão do delta exigida para S10 está concluída com manutenção explícita dos
pins. Um próximo avanço continua condicionado a:

1. comparação completa e não truncada, ou diff local integral no SHA exato;
2. build reproduzível e inventário de fontes do candidato;
3. cobertura das cartas/decks alvo e negativos estritos;
4. desempenho dentro do contrato público de 40 segundos;
5. Battle, E2E, replay, censura e proveniência na mesma identidade.

Esta disposição não prova equivalência absoluta de regras, não fecha as
dependências de S8/S9 e não autoriza migration, deploy, escrita live ou
promoção de deck/regra. PostgreSQL/backend permanece a verdade; Hermes/SQLite
permanece cache ou laboratório.
