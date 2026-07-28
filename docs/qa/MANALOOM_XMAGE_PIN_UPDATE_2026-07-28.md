# Atualização controlada do pin XMage — 2026-07-28

Status: `card_audit_review_required_not_deployed`.

## Decisão

O executor externo primário foi atualizado do pin histórico
`34d81ea4995ce15d7e1a788dc6d2a3595d35bcec` para o commit oficial
`2c43ec8cdb5cd475d47e6b555a4077151f476a3b` do branch `master` de
`magefree/mage`. A versão publicada pelo projeto continua `1.4.60`.

O avanço absorve 152 commits oficiais. A primeira comparação pela API foi útil
para descoberta, mas não era prova completa porque o GitHub limitou a lista a
300 arquivos. A reconstrução pelos objetos Git dos dois pins encontrou:

- 356 caminhos alterados: 106 adicionados, 217 modificados, 30 renomeados e
  3 removidos;
- 169 implementações de carta em `Mage.Sets`: 87 adicionadas e 82 modificadas;
- 7 classes de cenários de jogo alteradas em `Mage.Tests`;
- 41 arquivos Java do núcleo `Mage` alterados.

O pin não acompanha `master` automaticamente. O SHA foi congelado, propagado
para os seis mirrors ativos e permanece sujeito aos mesmos gates de identidade,
replay, persistência e promoção de regra.

## Compatibilidade e dependências

O upstream passou a usar `sqlite-jdbc 3.53.2.0`. O bootstrap e a imagem Docker
agora exigem essa versão exata em vez de reescrever a dependência para
`3.50.2.0`; isso evita downgrade e falha fechado se o grafo do pin revisado
divergir.

Os 47 tipos `mage.*` importados pelo sidecar e seus testes continuam presentes,
e os respectivos arquivos-fonte não mudaram entre os dois pins. O assembly
mantém os plugins `Computer - mad`, Freeform Commander, constructed e human
usados pelo contrato ManaLoom.

## Evidência executada

| Camada | Resultado |
| --- | --- |
| Build Maven `Mage.Server -am` | 33/33 módulos |
| Assembly `mage-server.zip` | PASS |
| Testes upstream focados nas regras alteradas | 72/72 |
| Testes do sidecar XMage | 28/28 |
| Contrato de execução XMage | 41/41 |
| Estratégia XMage | 29/29 |
| Capacidades XMage/Forge | 95/95, 20 capacidades |
| Gate canônico Battle | PASS, 46 checks de produto |
| Spike human vs AI | 9/9; 3/3 partidas do contrato |
| Batalha estrita v2 loopback | HTTP 200; 20 turnos; 700 eventos |
| Auditor de pins/mirrors | PASS, zero divergências |
| Diff Git exato, sem limite da API | 356/356 caminhos |
| Catálogo das 87 cartas adicionadas | 86 reconhecidas; 1 não reconhecida |
| Catálogo das 169 adicionadas/modificadas | 168 reconhecidas; 1 não reconhecida |
| Teste nominal entre as 87 novas | 2 cartas; 3/3 casos focados |
| Classificação nominal versionada | 169/169 cartas |
| Qualificação para deploy | `review_required`; bloqueada |

O runtime loopback foi iniciado duas vezes a partir do artefato atualizado. Nos
dois boots, `/health` publicou o novo commit, `catalog_ready=true` e exatamente
32.561 nomes indexados, com identificadores de processo distintos. Os logs não
registraram erro de leitura de classe/JAR, plugin ausente ou fatal.

A batalha estrita v2 encerrou com vencedor, schema de learning correto e zero
erro de engine, timeout ou censura.

O endpoint `/cards/coverage` processou o snapshot canônico de 8.073 nomes:
7.820 foram reconhecidos e 253 permaneceram como lacunas estruturadas. Essa
medição é evidência de catálogo, não autorização para promover regra ou afirmar
execução semântica.

## Auditoria das cartas adicionadas e modificadas

O snapshot canônico de 8.073 nomes não contém nenhuma das 87 implementações
adicionadas e só cruza 5 das 82 modificadas. Portanto, o resultado agregado
anterior é uma regressão do corpus antigo, não uma auditoria das cartas novas.

A evidência nominal corrente está em
`docs/qa/evidence/XMAGE_PIN_TRANSITION_34d81ea_2c43ec8.json`. Ela registra cada
classe, nome, caminho-fonte, sets, data de lançamento, resolução no catálogo,
teste nominal e disposição:

| Disposição | Cartas | Interpretação |
| --- | ---: | --- |
| `focused_upstream_test_passed` | 2 | `SP//dr, Piloted by Peni` e `Sting, Bilbo's Sword`; 3/3 casos nominais passaram |
| `catalog_supported_semantic_review_required` | 84 | carta nova resolve no runtime, mas não tem prova nominal individual |
| `catalog_supported_regression_only_review_required` | 82 | implementação modificada resolve, mas só possui evidência de regressão compartilhada |
| `external_residual_upstream_unfinished` | 1 | `Prudent Fateseer` é removida do catálogo XMage como `unfinished` e não existe no Forge pinado |

Entre as 87 adições, 45 têm alguma inscrição em set posterior a 2026-07-28 e
44 aparecem exclusivamente em sets futuros nessa data. Isso exige nova
conferência de identidade/Oracle/legality conforme os dados oficiais
amadurecem.

`Prudent Fateseer` existe como classe e `SetCardInfo`, mas
`RealityFracture.java` a inclui na lista `unfinished` e remove esses nomes do
catálogo. O Forge `a62915f500c2411484689294659c6bb84ea215f8` não contém
correspondência exata. Ela permanece residual externo; isso não cria
automaticamente uma regra nativa ManaLoom.

Também permanecem `TODO`s explícitos de copy tests em `Krark, the Thumbless` e
`Mandate of Peace`.

O reconciliador read-only de PostgreSQL parou corretamente antes da consulta
porque este ambiente não forneceu
`MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256`. Nenhum fingerprint foi inferido,
nenhuma consulta foi executada e nenhuma escrita ocorreu. PostgreSQL continua
sendo a verdade para decidir se cada identidade futura está no escopo do
produto.

O contrato
`docs/hermes-analysis/EXTERNAL_ENGINE_PIN_TRANSITION_CONTRACT.json` fixa o hash
da evidência. `./scripts/quality_gate.sh engine-transition` valida a
classificação completa sem rede. O deploy executa o mesmo auditor com
`--require-deployable` e falha enquanto a qualificação for
`review_required`.

Uma comparação oficial repetida após a mudança retornou XMage com
`ahead_by=0` e o mesmo SHA no upstream. Forge permaneceu no pin separado
`a62915f500c2411484689294659c6bb84ea215f8`, com delta próprio que continua em
`review_required`; ele não foi promovido por esta atualização.

## Monitoramento semanal

Foi adicionada uma auditoria semanal somente leitura, descrita em
`docs/MANALOOM_EXTERNAL_ENGINE_DELTA_SCHEDULE.md`. Ela:

- nunca altera pins, runtime, PostgreSQL, Hermes/SQLite, regras ou decks;
- ignora o acesso de rede e registra `skipped` quando o checkout está sujo;
- grava apenas fora do checkout;
- retém somente seus relatórios timestampados por 180 dias;
- considera ausente, inválido, `fail`, `skipped` ou mais antigo que oito dias
  como estado não saudável;
- trata `review_required` como uma execução válida que exige revisão humana.

A automação local `ManaLoom • Deltas XMage/Forge` foi ativada no Codex para
domingo às 09:17. Essa é a opção usada neste Mac porque o checkout está sob
`Documents` e um LaunchAgent sem permissão TCC falhou fechado com
`Operation not permitted`.

O LaunchAgent abaixo permanece disponível apenas para um checkout fora das
pastas protegidas ou depois de uma concessão explícita e comprovada de acesso:

```bash
./scripts/manaloom_install_external_engine_delta_schedule.sh --install
./scripts/manaloom_install_external_engine_delta_schedule.sh --check
```

## Limite operacional

Fonte, build, runtime loopback e inventário nominal foram auditados, mas 167
cartas ainda têm revisão semântica/residual pendente e a reconciliação de
escopo PostgreSQL não foi executada. Por isso o pin não está qualificado para
deploy. Nenhum deploy, reinício ou mutação de produção foi realizado; o serviço
publicado continua no pin anterior.
