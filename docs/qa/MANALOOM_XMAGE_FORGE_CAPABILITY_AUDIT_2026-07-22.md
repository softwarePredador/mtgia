# ManaLoom — auditoria de capacidades XMage e Forge

Data: 2026-07-22
Branch: `codex/free-beta-release-candidate-2026-07-17`
HEAD observado: `2813152121c4d41069f9ebbb3334eb4c6b8b1110`
Owner: `/root`

## Decisão

ManaLoom **não usava de forma explícita e verificável tudo o que era útil** nos
dois projetos. O runtime externo já existia, mas duas superfícies de análise
ainda descreviam Forge como conferência manual e aceitavam uma árvore XMage
local sem provar o commit. Isso permitia confundir fonte de diagnóstico com o
runtime realmente pinado.

A correção não foi copiar os engines para o backend. Foi congelar um contrato
de capacidades, atribuir uma decisão a cada superfície relevante e bloquear
drift de papel, licença, pin, evidência e imports. O contrato classificou 20
capacidades: 13 adotadas, 3 avaliadas e não adotadas, 3 fora do escopo atual e
1 explicitamente rejeitada.

Contrato executável:
`docs/hermes-analysis/EXTERNAL_ENGINE_CAPABILITY_CONTRACT.json`.

## Fontes oficiais e pins

| Engine | Fonte oficial | Pin executado | Licença | Papel ManaLoom |
|---|---|---|---|---|
| XMage | https://github.com/magefree/mage | `34d81ea4995ce15d7e1a788dc6d2a3595d35bcec` | MIT | executor externo primário |
| Forge | https://github.com/Card-Forge/forge | `a62915f500c2411484689294659c6bb84ea215f8` | GPL-3.0-only | fallback externo apenas para gap estruturado do XMage |

Referências oficiais revisadas:

- XMage: README/repositório, licença e ferramentas de teste/AI em
  https://github.com/magefree/mage,
  https://github.com/magefree/mage/blob/master/LICENSE.txt e
  https://github.com/magefree/mage/wiki/Development-Testing-Tools;
- Forge: README/repositório, engine, AI, scripts de cartas, documentação da DSL,
  contribuição e licença em https://github.com/Card-Forge/forge,
  https://github.com/Card-Forge/forge/tree/master/forge-game/src/main/java/forge/game,
  https://github.com/Card-Forge/forge/tree/master/forge-ai/src/main/java/forge/ai,
  https://github.com/Card-Forge/forge/tree/master/forge-gui/res/cardsfolder,
  https://github.com/Card-Forge/forge/wiki/Creating-a-Custom-Card,
  https://github.com/Card-Forge/forge/blob/master/CONTRIBUTING.md e
  https://github.com/Card-Forge/forge/blob/master/LICENSE.

O Forge permanece obrigatoriamente atrás de processo/API isolado. Nenhum
pacote `forge.*` pode entrar no backend. A mesma separação impede que código de
um engine vire silenciosamente verdade PostgreSQL.

## Inventário reproduzido no pin

Clones temporários e exatos foram usados somente em `/tmp`, removidos depois da
auditoria; nenhum checkout externo foi versionado:

| Métrica | XMage | Forge |
|---|---:|---:|
| arquivos Java | 38.809 | 2.506 |
| implementações/scripts de cartas | 31.768 | 33.290 |
| testes Java | 2.014 | 98 |

O auditor exigiu o SHA Git exato antes de contar o corpus. Scripts operacionais
agora usam um resolvedor comum que exige Git top-level, checkout limpo, módulos
completos e o pin canônico. A antiga pasta `Downloads/mage-master` não é mais
default em nenhum script. Apenas o inventário de pesquisa aceita override
diagnóstico explícito, nunca para pacote, promoção ou Battle.

## Capacidades adotadas

As 13 capacidades usadas pelo produto são:

1. execução de regras pelos engines pinados;
2. preflight de cobertura do catálogo;
3. Commander/multiplayer, incluindo command zone;
4. prioridade, stack, state-based actions e replacement effects no engine;
5. seleção de ações pela AI do engine, com uso limitado à simulação;
6. timeout e isolamento por processo;
7. normalização censurada de eventos observáveis do replay;
8. proveniência, pin e auditoria de delta upstream;
9. fallback Forge somente após gap XMage estruturado;
10. referência exata ao código/script da carta para diagnóstico;
11. taxonomia semântica por famílias para triagem em lote;
12. corpus de cenários upstream como referência focada;
13. legalidade Commander como cross-check, não como verdade de produto.

AI interna dos engines pode escolher jogadas, mas uma decisão opaca não vira
aprendizado de carta. Aprendizado exige evento natural tipado, identidade da
carta-fonte e censura explícita; resultado agregado da partida não basta.

## O que não foi adotado

| Capacidade | Decisão | Motivo |
|---|---|---|
| geradores de deck e relation matrix | não adotada | não respeitam coleção, orçamento, anchors, proveniência e outcome ManaLoom |
| busca/racional interno da AI | não adotada | logs/debug não formam contrato estável, censurado e atribuído à carta-fonte |
| calculador de bracket Forge | referência secundária apenas | política oficial atual e dados versionados ManaLoom continuam autoritativos |
| draft, sealed e torneios | fora do escopo | a entrega atual é Commander/deckbuilding/Battle |
| cliente, editor, rede e adventure | fora do escopo | substituiriam superfícies Flutter/backend já próprias |
| rating e matchmaking | fora do escopo | Battle atual é avaliação, não serviço competitivo |
| copiar código dos engines para backend | rejeitada | duplica ownership de regras e viola a fronteira GPL do Forge |

## Correções implementadas

- criado auditor fail-closed de 95 checks para decisões, paths, pins, licenças,
  evidências e fronteiras de import;
- criado `quality_gate.sh engine-capabilities` e incluído no gate Battle;
- Forge passou de “cross-check manual” para executor secundário real e limitado;
- inventário XMage passou a exigir o mesmo commit do runtime;
- recomendações de adaptação nativa agora excluem cartas já cobertas por engine;
- consumidores operacionais de fonte XMage perderam o caminho absoluto legado
  e agora exigem o resolvedor pinado; quatro auditorias de Battle perderam defaults para
  `.manaloom-agents` e exigem artefato corrente explícito;
- o pipeline de replay valida fonte e parâmetros antes de materializar qualquer
  dado de laboratório;
- o delta oficial é consultado sem atualizar pin, deployar ou promover regras.

## Evidência de execução

```text
quality_gate.sh engine-capabilities: PASS, 95/95 checks
fontes exatas: PASS, XMage e Forge nos pins canônicos
inventário pinado final SHA-256: a6c36494541aaaa0bbb0ad6b029dd6ca2402defdb1fca3d9740caf69f8601bdb
test_external_engine_capability_alignment_audit.py: PASS, 6 testes
test_external_engine_source_contract.py: PASS, 5 testes
test_battle_external_engine_crosscheck.py: PASS, 2 testes
test_xmage_engine_absorption_inventory.py: PASS, 4 testes
quality_gate.sh engine-delta: PASS com status review_required
```

O delta de 2026-07-22 encontrou os dois pins consistentes, sem falha de
contrato, mas os heads oficiais estão adiante:

| Engine | Head observado | Commits à frente | Candidatos de carta | Fixtures candidatas |
|---|---|---:|---:|---:|
| XMage | `529c6a9f0ebdfc5ced0a62693381bf0422bb1fdc` | 111 | 120 | 131 |
| Forge | `d5e3f57577d1e56f4f776381575fa3f8d539fa07` | 105 | 185 | 186 |

Forge atingiu o limite de 300 arquivos da comparação do GitHub. Logo, os 185
candidatos são piso de revisão, não inventário completo. Nenhum head foi
promovido automaticamente.

## Risco residual e próxima ação

Esta auditoria prova alinhamento arquitetural e cobertura de capacidades; não
prova equivalência absoluta entre todas as regras do Magic nos dois engines.
O risco restante é controlado por pin, fixtures focadas, execução E2E e revisão
do delta antes de qualquer atualização. A fila de 305 cartas/317 fixtures deve
ser triada quando houver proposta de avanço dos pins, mantendo os engines
atuais até que o mesmo conjunto de gates passe no candidato.
