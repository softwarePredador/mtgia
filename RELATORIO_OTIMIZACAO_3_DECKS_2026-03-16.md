# Relatorio de Otimizacao Real - 3 Decks Commander

- Gerado em: `2026-04-19T10:15:04.725867`
- API: `http://127.0.0.1:8080`
- Artefatos: `test/artifacts/optimization_validation_three_decks`
- Total: `3`
- Otimizacoes aceitas: `1`
- Rejeicoes protegidas: `2`
- Passaram: `3`
- Falharam: `0`

## Resultado por deck

### Auntie Ool, Cursewretch

- Source deck: `8c22deb9-80bd-489f-8e87-1344eabac698`
- Clone deck: `3d7e29b2-4b70-4b68-946a-d1a76f645fe5`
- Tipo de resultado: `protected_rejection`
- Archetype usado: `aggro`
- Optimize status: `422`
- Deck salvo valido: `true`
- Validation local: `n/d - quality_rejected`
- Validation da rota: `n/d`
- CMC medio: `n/d`
- Interacao: `n/d`
- Consistencia: `n/d`
- Artifact: `test/artifacts/optimization_validation_three_decks/auntie_ool_cursewretch.json`
- Status final: `PASSOU`

Avisos:
- Rejeicao protegida pelo gate de qualidade: O deck atual esta fora da faixa em que optimize por swaps pontuais funciona bem.
- O deck está com apenas 24 terrenos, abaixo do mínimo seguro para Commander.
- O deck precisa de reparo estrutural antes de uma micro-otimizacao segura.

### Jin-Gitaxias // The Great Synthesis

- Source deck: `f2a2a34a-4561-4a77-886d-7067b672ac85`
- Clone deck: `407a3154-85fe-4d72-8c58-b4f925695cf0`
- Tipo de resultado: `accepted_optimization`
- Archetype usado: `control`
- Optimize status: `200`
- Deck salvo valido: `true`
- Validation local: `65/100 - aprovado`
- Validation da rota: `65/100 - aprovado`
- CMC medio: `3.07 -> 2.97`
- Interacao: `25 -> 25`
- Consistencia: `91.0 -> 90.0`
- Artifact: `test/artifacts/optimization_validation_three_decks/jin_gitaxias_the_great_synthesis.json`
- Status final: `PASSOU`

Avisos:
- A melhoria incremental foi pequena (31/100).
- 🔒 Gate de qualidade removeu 1 troca(s) insegura(s) antes da resposta final.
- 🔒 Engulf the Shore -> Command Tower removida pelo gate: papel utility -> land, delta CMC -4.
- A melhoria incremental foi pequena (31/100).

### Talrand, Sky Summoner

- Source deck: `723991bb-bbdb-4fdd-9bfe-579ca76d1676`
- Clone deck: `1c52dc8e-5d0a-4701-90a4-4d254229707e`
- Tipo de resultado: `protected_rejection`
- Archetype usado: `midrange`
- Optimize status: `422`
- Deck salvo valido: `true`
- Validation local: `n/d - quality_rejected`
- Validation da rota: `n/d`
- CMC medio: `n/d`
- Interacao: `n/d`
- Consistencia: `n/d`
- Artifact: `test/artifacts/optimization_validation_three_decks/talrand_sky_summoner.json`
- Status final: `PASSOU`

Avisos:
- Rejeicao protegida pelo gate de qualidade: O deck atual esta fora da faixa em que optimize por swaps pontuais funciona bem.
- O deck está com 99 terrenos, muito acima do intervalo saudável para commander.
- O deck tem apenas 1 não-terrenos, insuficiente para sustainar o plano do comandante.
- A base de mana ainda não cobre as cores exigidas pelo comandante.
- A identidade U do comandante não possui nenhuma fonte funcional de mana no deck.
- O comandante pede instants/sorceries, mas o deck só tem 0 cartas desse tipo.
- O deck ainda não tem massa crítica suficiente para o arquétipo detectado.
- O deck precisa de reparo estrutural antes de uma micro-otimizacao segura.

