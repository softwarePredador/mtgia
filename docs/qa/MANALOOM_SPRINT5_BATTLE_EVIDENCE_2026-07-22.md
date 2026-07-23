# ManaLoom — evidência da Sprint 5 (Battle)

Data: 2026-07-22
Branch: `codex/free-beta-release-candidate-2026-07-17`
HEAD base observado: `2813152121c4`
Owner: `/root`

Este documento é incremental. Cada task só recebe `PASS` quando o seu próprio
critério e cleanup estiverem registrados; o início da Sprint 5 não promove
regra, carta, família, deck ou candidato.

## S5-01 — revalidar alinhamento canônico

**Decisão:** `PASS`.

Foram executadas, no checkout atual e em modo somente leitura, as três
auditorias exigidas:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/deckbuilding_contract_surface_audit.py \
  --out-prefix /tmp/manaloom_s501_alignment_20260722/deckbuilding_contract_surface
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_strategy_consistency_audit.py \
  --output-prefix /tmp/manaloom_s501_alignment_20260722/xmage_strategy_consistency
python3 docs/hermes-analysis/manaloom-knowledge/scripts/operational_surface_alignment_audit.py \
  --out-prefix /tmp/manaloom_s501_alignment_20260722/operational_surface_alignment
```

| Auditoria | Resultado |
|---|---|
| contrato/superfície do Deckbuilder | PASS; 344 superfícies ativas, 0 falhas |
| consistência estratégica XMage | PASS; 29/29 checks |
| alinhamento da superfície operacional | PASS; 53/53 checks |

O auditor do Deckbuilder manteve sete avisos sobre relatórios históricos
voláteis ausentes. Eles dependiam de cópias locais ignoradas do Hermes/replays,
estão explicitamente bloqueados para promoção e não são superfícies executáveis
atuais. Os dois builders históricos permanecem protegidos pelos marcadores
`historical_disabled` e `legacy_deprecated_not_authorized_for_handoff`.

Hashes dos outputs descartáveis:

- Deckbuilder JSON: `f36c1965bc05163956d1e3621fae30ffd2cca8c4a9bd5066b1b4a692a2fb816f`;
- XMage JSON: `243999ba37fbba1e430cd382d2375bbbb626cc17a41ade198892589d50cd8908`;
- superfície operacional JSON: `72a3f525170a2f6aaf9162368039bdbcf99d98efb94d56fcaefd4c8aeaa12645`.

Todas as três execuções retornaram exit code zero. Nenhum PostgreSQL, Hermes,
deck, regra ou relatório versionado foi alterado. Os outputs ficaram somente em
`/tmp/manaloom_s501_alignment_20260722` para revisão e podem ser descartados.

## S5-02 — inventário de cobertura

**Decisão:** `PASS` para o inventário; runtime/package dos três candidatos
Forge segue para S5-03 e não foi promovido.

O snapshot local canônico do deck 607 contém 100 instâncias e 94 nomes únicos.
Ele foi enviado ao endpoint `/cards/coverage` de um sidecar XMage compilado
localmente no pin `34d81ea4995ce15d7e1a788dc6d2a3595d35bcec`:

- catálogo XMage: 32.475 nomes;
- cobertura exata XMage: 91/94;
- residual XMage: 3/94;
- listener temporário encerrado e verificado;
- zero escrita em PostgreSQL/Hermes.

O residual foi reconciliado contra arquivos `Name:` exatos do Forge no pin
`a62915f500c2411484689294659c6bb84ea215f8`, sem inferência por classe, nome
parecido ou Oracle:

| Carta | Família de triagem | Lane atual |
|---|---|---|
| Improvisation Capstone | `copy_or_alternate_cast` | `forge_exact_source_candidate` |
| Lorehold, the Historian | `draw_selection_topdeck` | `forge_exact_source_candidate` |
| Molecule Man | `draw_selection_topdeck` | `forge_exact_source_candidate` |

As três cartas existem exatamente no catálogo-fonte fixado do Forge, mas
`runtime_package_proven=false`. Portanto não são marcadas como cobertura
executável nem criam adapter nativo/linha PostgreSQL. O próximo gate é S5-03,
que precisa compilar e exercitar o pacote Forge fixado. Nenhuma carta exige
adapter nativo neste inventário antes dessa prova.

Provas adicionais:

- manifesto Battle: 186 arquivos, 186 classificados, zero não classificado;
- contratos de fechamento/reconciliação: 12/12 testes PASS;
- sidecar Forge: 13/13 testes unitários PASS;
- build local do XMage fixado: PASS;
- inventário JSON SHA-256:
  `271c505812fcf07274664e825140f88e1aaf15170f11e990e145f9ab51a157fa`;
- resposta XMage SHA-256:
  `1d100e05d4bdb000496fad53e9d311448555cd81ba4803340d86ba0a0cf3e186`;
- manifesto de superfície SHA-256:
  `f0044892a0990e16affae9b74d22c0d1a946ebe8cde1c77c088c7b08c2567d77`.

Os outputs permanecem em
`/tmp/manaloom_s502_lorehold_xmage_20260722.2oiiZi`. Não houve execução de
battle, promoção, aprendizado, mutation live, commit, push ou deploy.

## S5-03 — gaps executáveis dos decks alvo

**Decisão:** `PASS` para package/runtime Forge local. A evidência não promove
regra nativa, deck, carta ou aprendizado.

O pacote foi compilado do `Dockerfile` canônico no pin
`a62915f500c2411484689294659c6bb84ea215f8`. Antes do build, os 13 testes
unitários do sidecar passaram. O reactor Maven compilou os seis módulos
necessários (`Forge Parent`, `Core`, `Game`, `AI`, `Gui` e
`forge-gui-desktop`) em 1 minuto e 15 segundos, todos com `SUCCESS`.

Prova do artefato:

- imagem local: `manaloom-forge-sidecar:local-proof`;
- image ID/manifest list:
  `sha256:847207953835bcbbcaba827ba39cb85cbae7dc49efc25b8ee4a0b07e6c8d7a2f`;
- tamanho final: 392.415.816 bytes;
- `/health`: `status=ok`, Forge `2.0.14-SNAPSHOT`, pin exato e 33.288 cartas
  indexadas;
- os três gaps XMage (`Improvisation Capstone`, `Lorehold, the Historian` e
  `Molecule Man`) retornaram 3/3 suportados em `/cards/coverage`;
- o deck 607 lido do PostgreSQL em transação `READ ONLY` manteve 100 instâncias,
  94 nomes únicos e um comandante;
- o oponente Korvold do corpus manteve 100 instâncias, 90 nomes únicos e um
  comandante;
- `/coverage` retornou `ready=true` para os dois decks e zero carta não
  suportada.

A chamada local de `/simulate` usou seed `20260722`, limite controlado de 180
segundos e concluiu em 10.574 ms:

| Campo | Resultado |
|---|---|
| status | `completed` |
| turnos | 13 |
| vencedor nessa seed | `Corpus Seed - Korvold, Fae-Cursed King` |
| eventos Forge | 774 |
| erros do engine | 0 |
| contrato de aprendizado | `external_battle_learning_v1` |
| stream | `best_effort_engine_log_lower_bound` |
| prova estratégica/swap | `false` |

`Lorehold, the Historian` apareceu em cinco eventos visíveis. `Improvisation
Capstone` e `Molecule Man` tiveram resolução/package proof, mas zero atividade
visível nesta seed. Portanto, esta execução não é apresentada como prova de uso
dessas duas cartas nem como prova de superioridade do deck. Ausência no stream
continua sem provar não uso, conforme `absence_proves_nonuse=false`.

O gate negativo substituiu um nome por
`ManaLoom Deliberately Unsupported Probe`; `/simulate` retornou HTTP `422`,
`forge_coverage_incomplete` e `card_script_not_found`, sem iniciar uma partida.
Isso confirma que saída zero, nome aproximado ou card omitido não vira sucesso.

Depois da prova em container, `./scripts/quality_gate.sh battle` passou por
completo: auditoria dos dois pins sem review, 32/32 + 13/13 + 14/14 testes
Python, 45/45 checks do produto Battle, análise Dart sem issues e 66/66 testes
Dart. O dispatcher encerrou com `Todos os checks do modo 'battle' passaram`.

Os requests e resultados ficaram apenas em:

- `/tmp/manaloom-forge-deck607-vs-korvold-request.json`;
- `/tmp/manaloom-forge-deck607-vs-korvold-result.json`;
- `/tmp/manaloom-forge-negative-request.json`;
- `/tmp/manaloom-forge-negative-result.json`.

Os dois containers temporários foram encerrados. Não houve escrita em
PostgreSQL/Hermes, promoção, commit, push ou deploy. A imagem local foi mantida
para os próximos gates reproduzíveis da Sprint 5.

## S5-04 - determinismo, identidade e falhas de engine

**Decisão:** `PASS` para o contrato honesto de execução. Nem XMage nem Forge
receberam uma alegação falsa de replay determinístico.

O request e o resultado externos passaram para os schemas
`external_battle_request_v2` e `external_battle_execution_v2`. Toda execução
aceita precisa correlacionar engine, versão, commit, protocolo, build, processo,
instante de início, request ID, request hash, seed solicitada, timeout, controles
e hashes canônicos dos dois decks. O hash de deck é compartilhado entre
Python, Dart, Java/Forge e Java/XMage; o vetor dourado é
`926d4864af12aa6d6bd9b57758df6249a3fbc49fdb2818ed5941a58f0c35e25b`.

As semânticas de seed ficaram explícitas:

- XMage: `request_correlation_only_server_rng_uncontrolled` e
  `deterministic=false`, pois o sidecar não controla o RNG da JVM separada do
  servidor XMage;
- Forge: `engine_rng_seeded_not_replay_guarantee` e `deterministic=false`;
- seed igual é somente balanceamento de agenda, com
  `seed_pairing_claim=false`, e não pareamento estatístico de RNG.

Timeout, resposta censurada e gap de cobertura agora são estados distintos.
Timeout jamais chama Forge silenciosamente. Fallback só é permitido após um
HTTP 422 XMage estruturado, correlacionado e elegível. Saída censurada não pode
conter vencedor. Resposta com identidade, hash ou correlação divergente falha
fechado e não produz evidência.

O runner rejeita registry/checkpoint v1, produz apenas
`external_battle_async_registry_v2` e
`external_battle_async_checkpoint_v2`, constrói o request estrito por tentativa
e registra separadamente seleção primária e cadeia de fallback. As provas
focadas passaram: auditoria de contrato 41/41, testes Forge 15/15, runner 30/30,
clientes/contrato Dart incluídos na suíte Battle e Maven XMage com exit zero.

## S5-05 - persistência, autorização e segurança dos replays

**Decisão:** `PASS`.

Foi centralizada a sanitização em
`server/lib/battle/battle_replay_payload_sanitizer.dart`. A simulação só retorna
sucesso quando o replay foi persistido; POST, lista e detalhe usam o mesmo UUID.
Leitura é escopada ao dono do deck iniciador, inclusive quando o usuário possui
o deck B: possuir o oponente não concede acesso ao replay de outro usuário.
Zonas ocultas, segredos, SQL e detalhes de exceção são removidos tanto de
payloads novos quanto legados.

Os testes unitários cobrem falha fechada, IDOR, payload corrompido e erro 500
sanitizado. O E2E final de S5-09 confirmou dois UUIDs duráveis e distintos,
presença dos mesmos IDs na lista e no detalhe e HTTP 404 sanitizado para a
identidade intrusa.

## S5-06 - evidência real da carta

**Decisão:** `PASS` para o gate de evidência; nenhuma carta ou regra foi
promovida por este fechamento.

Somente eventos de source card com `event_type` ou `action` tipado contam como
compra/conjuração/uso natural. Campos genéricos `type`, texto de log, target
isolado ou a mera presença da carta no deck não contam. Sem essa prova, o
estado continua `unknown`.

Teste focado positivo e negativo pode fechar a entrada de execução de uma
regra, mas nunca aprova sozinho um swap de deck. Forced access continua
diagnóstico. Promoção de swap exige hipótese revisada na mesma lane, hashes dos
decks, política de timeout, atestado de legalidade e exposição natural tipada.

## S5-07 - prioridade e ownership da fila de regras

**Decisão:** `PASS`.

A fila operacional agora combina decks de produto, uso natural tipado, impacto,
residual comprovado, owner e próximo gate. Fonte Java local é candidata, não
prova de cobertura no pacote em execução. As lanes operacionais são:

- `pinned_xmage_catalog_confirmation_required`;
- `forge_then_native_residual_review`.

XMage/Forge executam externamente o catálogo confirmado. Trabalho nativo só é
aberto para residual externo provado. `translation_lane` e `adapter_work_unit`
permanecem apenas como compatibilidade analítica de arquivos históricos e não
dirigem implementação. User skeleton nunca é preenchido, removido ou alterado
automaticamente; PostgreSQL permanece a fonte canônica. A suíte da fila passou
11/11.

## S5-08 - gate Battle duas vezes na mesma versão

**Decisão:** `PASS`.

Foram aceitas duas execuções completas consecutivas de
`./scripts/quality_gate.sh battle`, ambas com exit code zero, no HEAD base
`2813152121c4` e no mesmo digest de fontes:

`cf7db6175a68171271723c00469ffa18f9b6311830764bc40c07cb5b466c0928`.

Cada execução aprovou:

- auditoria do contrato externo 41/41;
- auditoria de estratégia XMage 29/29;
- alinhamentos operacional e Deckbuilder;
- suíte Python principal 42/42;
- Forge 15/15, runner 30/30 e fila 11/11;
- manifesto Battle e Maven XMage;
- auditoria de produto 45/45;
- análise Dart sem issues e testes Dart 100/100.

Uma tentativa anterior, feita antes de corrigir um guard obsoleto que ainda
procurava `externalRequest`, foi descartada e não integra a contagem. O guard
foi alinhado ao campo atual `battleRequest`, os artefatos foram regenerados pelo
script canônico e somente então as duas passagens acima foram executadas.

## S5-09 - Battle E2E com PostgreSQL descartável

**Decisão:** `PASS`.

Com as confirmações guardadas explícitas, foi executado:

```bash
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_BATTLE_E2E_AUDIT_OUT=/tmp/manaloom_s5_09_disposable_final.json \
./scripts/manaloom_battle_product_gate.sh --isolated-e2e
```

O harness criou um PostgreSQL novo exclusivamente em loopback, aplicou
schema/migrations, iniciou API e sidecar nativo locais e executou
`battle_product_e2e_test.dart` 1/1. O run token foi
`20260722T195907Z_77997_fcf357ba6587`.

Contagens auditadas:

| Momento | users | decks | deck_cards | battle_simulations |
|---|---:|---:|---:|---:|
| Antes | 0 | 0 | 0 | 0 |
| Durante | 2 | 2 | 200 | 2 |
| Depois | 0 | 0 | 0 | 0 |

O E2E comprovou replay durável, IDs consistentes entre POST/lista/detalhe,
contrato de execução revisada, consumo apenas de evidência natural e negação
sanitizada para a identidade intrusa. Escritas de aprendizado de produto foram
suprimidas.

No cleanup, os três PIDs capturados foram encerrados, todos os listeners foram
fechados, o cluster foi destruído e os diretórios de dados/socket foram
removidos. O JSON final registra `status=pass`, `cleanup_pass=true`,
`cluster_destroyed=true` e `runtime_cleanup.pass=true`. Nenhum banco do servidor,
PostgreSQL live ou Hermes foi acessado ou alterado.

## S5-10 — auditoria e prova dos deltas upstream

**Decisão:** `PASS` para a auditoria read-only; os dois candidatos mais novos
foram compilados e exercitados, mas nenhum pin foi promovido.

`./scripts/quality_gate.sh engine-delta` consultou os repositórios oficiais e
encerrou sem falha de contrato dos pins. O estado `review_required` é o produto
esperado desse gate quando há mudanças upstream: foram encontradas 304 cartas
candidatas e 316 fixtures para revisão, com 111 commits após o pin XMage e 103
após o pin Forge.

| Engine | Pin canônico mantido | Candidato auditado | Delta de catálogo |
|---|---|---|---:|
| XMage | `34d81ea4995ce15d7e1a788dc6d2a3595d35bcec` | `529c6a9f0ebdfc5ced0a62693381bf0422bb1fdc` | 32.475 → 32.552 (+77) |
| Forge | `a62915f500c2411484689294659c6bb84ea215f8` | `3958182708b718d8340c9829c6097787d757d983` | 33.288 → 33.376 (+88) |

O XMage candidato foi compilado em imagem local, preservou o contrato do
sidecar (41/41 checks), manteve os mesmos três gaps do deck 607 e concluiu uma
simulação mirror Korvold em 23.592 ms, 12 turnos e 498 eventos. Porém, duas
execuções independentes no orçamento público de 40 segundos terminaram em
HTTP 504 `simulation_timeout`, ambas exigindo restart do processo. Uma tentativa
de reconstruir o runtime histórico exato para comparação adicional chegou ao
empacotamento de 32.346 fontes, mas o Maven antigo falhou com `Java heap space`
ao montar `mage-sets.jar`; aumentar o limite Docker e encerrar os outros
containers não alterou o resultado. Isso é limitação de build da comparação,
não evidência para aprovar o candidato. Como a promoção exige prova estável, o
pin XMage permaneceu inalterado.

O primeiro Forge candidato observado (`07d00407103fb02094054a6c0f1d85da426ccf3d`)
compilou os seis módulos necessários com `SUCCESS`, indexou os três gaps XMage
e retornou cobertura completa para deck 607 e Korvold. A simulação de seed
`20260722` concluiu com limite diagnóstico de 180 segundos em 54.083 ms, 12
turnos, 868 eventos e zero erro do engine; no orçamento público de 40 segundos
retornou HTTP 504 `simulation_timeout`. Enquanto a auditoria era fechada, o
upstream avançou três commits. O HEAD final
`3958182708b718d8340c9829c6097787d757d983` também foi baixado e compilado: seis
módulos `SUCCESS`, 33.376 scripts, cobertura 100/100 para os dois decks e,
novamente, HTTP 504 no mesmo orçamento de 40 segundos. O runtime Forge canônico,
com o mesmo request e seed, concluiu em 16.986 ms e 774 eventos. O candidato é,
portanto, regressão objetiva para o contrato público e foi rejeitado. O teste
negativo do primeiro candidato continuou estrito: carta inexistente retornou
HTTP 422, `forge_coverage_incomplete` e `card_script_not_found`.

Artefatos locais das provas:

- XMage candidato:
  `sha256:4b92b2c0468047aa73762d9f185e09c0e502922643318b77e247dce24312e6bf`;
- XMage reconstruído com identidade oficial do candidato:
  `sha256:d592ff8f202d3b58c37b5cc36d5f474e3278e01dd4ec21c73a3cfcf1aeb39a56`;
- Forge candidato:
  `sha256:b421b5da5248d8df7916a4e59bc435ca8e6aae6929af18fa19278b89dbb3d657`;
- Forge HEAD final:
  `sha256:2f25978e272b1c2dcadb0f88423874fe2c13a5b7c17c8effbf59fd5322417f11`;
- JSON da auditoria: `/tmp/manaloom_external_engine_upstream_delta_audit.json`;
- requests, health, coverage e resultados candidatos:
  `/tmp/manaloom-xmage-candidate-*` e `/tmp/manaloom-forge-candidate-*`.

Todos os containers e listeners temporários foram encerrados. As quatro tags de
imagens candidatas rejeitadas foram removidas para devolver espaço ao Mac; os
hashes e JSONs preservam a trilha da prova. A imagem Forge canônica de S5-03 foi
mantida para os gates locais. Não houve escrita em PostgreSQL/Hermes, alteração
de pin efetiva, promoção, commit, push ou deploy.
