# Relatorio de Otimizacao Real - 3 Decks Commander

- Gerado em: `2026-03-17T13:33:39.819039`
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
- Clone deck: `ab92d082-e199-4ad0-a16e-90254ddbc7f1`
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

### Talrand, Sky Summoner

- Source deck: `df780797-bcc4-47cb-82d6-08d01ae3b03b`
- Clone deck: `072e8492-7e0a-4590-a751-3b396343fb36`
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

### Jin-Gitaxias // The Great Synthesis

- Source deck: `f2a2a34a-4561-4a77-886d-7067b672ac85`
- Clone deck: `f802ec62-c4af-4988-a605-a68d5b53b6b8`
- Tipo de resultado: `accepted_optimization`
- Archetype usado: `midrange`
- Optimize status: `200`
- Deck salvo valido: `true`
- Validation local: `90/100 - aprovado`
- Validation da rota: `74/100 - aprovado`
- CMC medio: `1.57 -> 1.52`
- Interacao: `25 -> 25`
- Consistencia: `90.0 -> 92.0`
- Artifact: `test/artifacts/optimization_validation_three_decks/jin_gitaxias_the_great_synthesis.json`
- Status final: `PASSOU`

Avisos:
- 🔒 Gate de qualidade removeu 2 troca(s) insegura(s) antes da resposta final.
- 🔒 Engulf the Shore -> Command Tower removida pelo gate: papel utility -> land, delta CMC -4.
- 🔒 Mystic Forge -> Counterspell removida pelo gate: papel draw -> removal, delta CMC -2.

