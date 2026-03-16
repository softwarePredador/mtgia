# Relatorio de Otimizacao Real - 3 Decks Commander

- Gerado em: `2026-03-16T15:24:57.622710`
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
- Clone deck: `3612e213-171b-4754-b1dc-363ff879fc59`
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
- Rejeicao protegida pelo gate de qualidade: As trocas foram recusadas porque degradam funcoes criticas ou nao atingem qualidade minima.
- A validação final não fechou como "aprovado" (score 48/100). Optimize só retorna sucesso quando a melhoria é aprovada sem ressalvas.
- Score final abaixo do mínimo para aceitar a otimização com sucesso (48/100; mínimo 70).
- A segunda revisão crítica da IA rejeitou a proposta (approval_score 45/100).
- As trocas não demonstraram ganho mensurável suficiente em consistência, mana ou execução do plano.
- A otimizacao sugerida nao passou no gate final de qualidade.

### Talrand, Sky Summoner

- Source deck: `df780797-bcc4-47cb-82d6-08d01ae3b03b`
- Clone deck: `2d5df44f-652c-454d-9016-94ed58ba4c72`
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
- Rejeicao protegida pelo gate de qualidade: As trocas sugeridas pioravam funcao, curva ou consistencia do deck.
- Nenhuma troca segura restou apos o gate de qualidade da otimizacao.

### Jin-Gitaxias // The Great Synthesis

- Source deck: `f2a2a34a-4561-4a77-886d-7067b672ac85`
- Clone deck: `9abeacae-51b3-4ffc-bd62-50f5235e3460`
- Tipo de resultado: `protected_rejection`
- Archetype usado: `midrange`
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
- A validação final não fechou como "aprovado" (score 50/100). Optimize só retorna sucesso quando a melhoria é aprovada sem ressalvas.
- Score final abaixo do mínimo para aceitar a otimização com sucesso (50/100; mínimo 70).
- A otimizacao sugerida nao passou no gate final de qualidade.

