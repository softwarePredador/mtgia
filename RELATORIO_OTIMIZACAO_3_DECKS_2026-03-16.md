# Relatorio de Otimizacao Real - 3 Decks Commander

- Gerado em: `2026-03-17T11:34:17.368040`
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
- Clone deck: `657b84bb-87ef-41c6-a280-a7ab8618fcbe`
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
- Rejeicao protegida pelo gate de qualidade: As trocas sugeridas pioravam funcao, curva ou consistencia do deck.
- Nenhuma troca segura restou apos o gate de qualidade da otimizacao.

### Talrand, Sky Summoner

- Source deck: `df780797-bcc4-47cb-82d6-08d01ae3b03b`
- Clone deck: `188bbb82-396a-45fa-9702-44ccfb223e2e`
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
- Rejeicao protegida pelo gate de qualidade: As trocas foram recusadas porque degradam funcoes criticas ou nao atingem qualidade minima.
- Validação automática reprovou as trocas (score 34/100).
- A validação final não fechou como "aprovado" (score 34/100). Optimize só retorna sucesso quando a melhoria é aprovada sem ressalvas.
- Score final abaixo do mínimo para aceitar a otimização com sucesso (34/100; mínimo 70).
- A base de mana continua com problema crítico após a otimização.
- A otimizacao sugerida nao passou no gate final de qualidade.

### Jin-Gitaxias // The Great Synthesis

- Source deck: `f2a2a34a-4561-4a77-886d-7067b672ac85`
- Clone deck: `562c85d1-3ade-490e-80f6-d8d5b1a08fa1`
- Tipo de resultado: `accepted_optimization`
- Archetype usado: `midrange`
- Optimize status: `200`
- Deck salvo valido: `true`
- Validation local: `67/100 - aprovado`
- Validation da rota: `86/100 - aprovado`
- CMC medio: `1.57 -> 1.52`
- Interacao: `25 -> 25`
- Consistencia: `92.0 -> 91.0`
- Artifact: `test/artifacts/optimization_validation_three_decks/jin_gitaxias_the_great_synthesis.json`
- Status final: `PASSOU`

Avisos:
- A melhoria incremental foi pequena (36/100).
- 🔒 Gate de qualidade removeu 2 troca(s) insegura(s) antes da resposta final.
- 🔒 Engulf the Shore -> Command Tower removida pelo gate: papel utility -> land, delta CMC -4.
- 🔒 Mystic Forge -> Counterspell removida pelo gate: papel draw -> removal, delta CMC -2.

