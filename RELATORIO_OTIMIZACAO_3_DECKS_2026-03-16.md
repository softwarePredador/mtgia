# Relatorio de Otimizacao Real - 3 Decks Commander

- Gerado em: `2026-03-17T16:31:55.322899`
- API: `http://127.0.0.1:8080`
- Artefatos: `test/artifacts/optimization_validation_three_decks`
- Total: `3`
- Otimizacoes aceitas: `0`
- Rejeicoes protegidas: `3`
- Passaram: `3`
- Falharam: `0`

## Resultado por deck

### Auntie Ool, Cursewretch

- Source deck: `8c22deb9-80bd-489f-8e87-1344eabac698`
- Clone deck: `226f5322-b161-45b5-b7eb-8f7d04a809bd`
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
- Clone deck: `60e0438e-5589-4215-96a7-8a7ce377ca1e`
- Tipo de resultado: `protected_rejection`
- Archetype usado: `control`
- Optimize status: `422`
- Deck salvo valido: `true`
- Validation local: `n/d - quality_rejected`
- Validation da rota: `n/d`
- CMC medio: `n/d`
- Interacao: `n/d`
- Consistencia: `n/d`
- Artifact: `test/artifacts/optimization_validation_three_decks/jin_gitaxias_the_great_synthesis.json`
- Status final: `PASSOU`

Avisos:
- Rejeicao protegida pelo gate de qualidade: As trocas foram recusadas porque degradam funcoes criticas ou nao atingem qualidade minima.
- As trocas não demonstraram ganho mensurável suficiente em consistência, mana ou execução do plano.
- A otimizacao sugerida nao passou no gate final de qualidade.

### Talrand, Sky Summoner

- Source deck: `df780797-bcc4-47cb-82d6-08d01ae3b03b`
- Clone deck: `710d1556-70d1-4393-9dae-76ea4e56d6d3`
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

