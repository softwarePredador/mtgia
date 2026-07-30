# Atualização controlada do pin XMage — 2026-07-28

Status: `product_scope_qualified_quarantine_active_not_deployed`.

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
| Testes do sidecar XMage | 30/30 |
| Contrato de execução XMage | 42/42 |
| Estratégia XMage | 29/29 |
| Capacidades XMage/Forge | 95/95, 20 capacidades |
| Gate canônico Battle | PASS, 46 checks de produto |
| Spike human vs AI | 9/9; 3/3 partidas do contrato |
| Batalha estrita v2 loopback | HTTP 200; 20 turnos; 700 eventos |
| Auditor de pins/mirrors | PASS, zero divergências |
| Diff Git exato, sem limite da API | 356/356 caminhos |
| Catálogo das 87 cartas adicionadas | 86 reconhecidas; 1 não reconhecida |
| Catálogo XMage das 169 adicionadas/modificadas | 168 reconhecidas; 1 não reconhecida |
| Qualificação bruta do catálogo | 166 suportadas; 3 quarentenas/residuais |
| Escopo PostgreSQL read-only | 34 no produto; 2 gaps; 45 futuras; 88 ausentes |
| Runtime após política de ativação | 34 disponíveis; 135 bloqueadas de forma explícita |
| Verificador oficial de dados/classes XMage | 1/1 PASS nos 10 sets envolvidos |
| Inventário nominal das 169 cartas | 5 cartas; 11 cenários candidatos |
| Suítes nominais selecionadas | 15/15 PASS |
| Testes focados no escopo do produto | 68/68 PASS; 31 identidades diretas; 3 fontes/patches e 4 execuções |
| Teste da política de bloqueio do sidecar | 16/16 PASS |
| Classificação nominal versionada | 169/169 cartas |
| Qualificação para deploy | `pass`; liberada pelo auditor local |

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
| `product_scope_focused_semantic_tests_passed` | 29 | carta do escopo atual coberta por identidade exata, patches pinados e execução semântica focada |
| `exact_non_executable_tokens_passed` | 5 | equivalências estritas de tokens não executáveis no escopo atual; outras 6 equivalências continuam preservadas sob o bloqueio de ativação |
| `activation_blocked_pending_product_semantic_review` | 133 | carta futura ou ausente do PostgreSQL atual; a disposição anterior e o estado de catálogo foram preservados para a próxima revisão |
| `external_runtime_quarantine_semantic_defect` | 1 | `Planetarium of Wan Shi Tong` resolve no catálogo, porém está bloqueada por defeito mecânico confirmado |
| `external_runtime_quarantine_known_upstream_gap` | 1 | `Mandate of Peace` permanece indisponível pelo gap upstream aberto de cópia/LKI; a quarentena não promove a carta nem bloqueia o deploy das demais |

As 133 linhas de ativação são uma camada operacional, não uma reclassificação
semântica. Cada uma conserva `underlying_transition_disposition` e
`catalog_status_before_activation`. Isso inclui `Prudent Fateseer`, cujo
residual `external_residual_upstream_unfinished` continua anexado à linha, mas
não bloqueia o deploy das 34 cartas que pertencem ao escopo atual.

Entre as 169 cartas da transição, 45 aparecem exclusivamente em sets futuros
na data de corte. Isso exige nova
conferência de identidade/Oracle/legality conforme os dados oficiais
amadurecem.

`Prudent Fateseer` existe como classe e `SetCardInfo`, mas
`RealityFracture.java` a inclui na lista `unfinished` e remove esses nomes do
catálogo. O Forge `a62915f500c2411484689294659c6bb84ea215f8` não contém
correspondência exata. Ela permanece residual externo; isso não cria
automaticamente uma regra nativa ManaLoom.

`Planetarium of Wan Shi Tong` sofreu uma regressão no commit upstream
`84e46530`: `setDoOnlyOnceEachTurn(true)` torna o trigger opcional e o refactor
removeu o `setOptional(false)` que mantinha obrigatória a ação de olhar o topo.
Como o `master` oficial continua exatamente no pin atual, não há correção
oficial posterior para absorver. O ManaLoom passou a bloqueá-la em
`XmageCardQualificationPolicy`, com `reason_code=xmage_pin_semantic_defect`,
até existir correção oficial e cenário focado aprovado.

A política também declara explicitamente `Prudent Fateseer` como
`xmage_upstream_mechanic_unfinished`. Ela é amarrada ao SHA do engine e o
sidecar falha fechado se um próximo avanço de pin não revisar essa lista.

Nas 82 classes modificadas, a revisão dos hunks classificou 28 mudanças
executáveis ou mistas, 52 de apresentação/metadados e 2 somente de comentário.
Os dois comentários (`Krark` e `Mandate of Peace`) apontam para o issue upstream
de cópias/LKI e permanecem dívida de qualificação; não foram tratados como
correção de comportamento.

Em `Mandate of Peace`, o comentário referencia o issue oficial
`magefree/mage#12911`, ainda aberto, e a implementação usa a remoção direta da
pilha no ramo afetado por cópias/LKI. O comentário não causou uma regressão:
ele documenta uma lacuna executável preexistente. A carta foi colocada em uma
quarentena pinada e não promocional. Como a restrição impede somente essa
carta, ela não integra a contagem de revisões que bloqueia o deploy global.

O classificador exato e sem rede em
`docs/qa/evidence/XMAGE_TRANSITION_NOMINAL_REVIEW_34d81EA_2c43ec8.json`
reduziu as revisões pendentes de 168 para 157. As 11 baixas são `Avengers
Tower`, `Black Panther, Vanguard`, `Bullseye, Death Dealer`, `Currency
Converter`, `Doorman`, `Metallic Mimic`, `Repulsor Bots`, `Restorative
Technique`, `The Ruinous Wrecking Crew`, `Villainous Hideout` e `Wondrous
Revival`. Cada regra é presa aos pins, caminho/classe, OIDs completos dos
blobs, SHA-256 das fontes, diff canônico com `--full-index` e hash dos tokens
normalizados. Apenas imports reordenados/delta exato e literais explicitamente
listados podem ser normalizados; filtros, predicados, números, booleanos e
tokens executáveis falham fechado. Resolução no catálogo não entra como prova
semântica e essa autorização não ativa a carta no runtime.

`Swordsman, Sharp Scoundrel` foi movida para a faixa executável: o hunk remove
o vínculo do predicado ao controlador do atacante. Ela permanece bloqueada
fora do escopo atual até passarem cenários positivo e negativo que diferenciem
criatura equipada controlada e atacante equipado do oponente.

`Mjolnir, Hammer of Thor` foi corrigida na taxonomia para mudança executável:
o hunk altera o `ChannelAbility` para `TimingRule.INSTANT`, enquanto o teste
nominal existente cobre equipar e dobrar dano. Ela permanece bloqueada fora do
escopo atual até haver um cenário específico de timing de Channel. `Krark`
também permanece na faixa bloqueada porque seu teste nominal não cobre a dívida
de cópia/LKI marcada no fonte. Essas dívidas não entram nos zero bloqueios
globais das 34 cartas atualmente disponíveis.

O comparador detalhado encontrou ainda findings de texto/regras em
`Ajani Resolute`, `Consider the Prime Directive`, `Sky Cycle`, `Sting`,
`My Precious`, `Crimson Cowl`, `Hire a Crew` e `Falcon's Wing Harness`.
Os sete primeiros estão sob o bloqueio de ativação. Em `Falcon's Wing Harness`,
a diferença é restrita à informação de carta gerada pelo engine: a prova
comparativa cobre anexar, reequipar, +1/+1, voar e ward `{1}` nos dois pins.
O replay normalizado não publica texto de regras, a entrada de Battle usa
identidade do PostgreSQL e o produto mantém o Oracle do PostgreSQL como fonte
de verdade. A evidência, portanto, não afirma que o upstream corrigiu o texto;
ela classifica o aviso como apresentação fora da fronteira do runtime. Isso
não afirma uma correção upstream; a carta entra na disposição focada somente
porque seu comportamento de produto foi comprovado nos dois pins e o texto de
regras publicado continua vindo do PostgreSQL.

O reconciliador PostgreSQL confirmou o fingerprint aprovado e executou duas
consultas dentro de uma transação comprovadamente read-only. As 169 identidades
foram reconciliadas sem ambiguidade e sem escrita: 34 estão no escopo do
produto, 2 são gaps de runtime, 45 são futuras e 88 ainda não existem no catálogo
do produto. O artefato completo das linhas fica fora do JSON principal e é
referenciado por caminho, SHA-256 e digest canônico das linhas.

O contrato
`docs/hermes-analysis/EXTERNAL_ENGINE_PIN_TRANSITION_CONTRACT.json` fixa o hash
da evidência. `./scripts/quality_gate.sh engine-transition` valida a
classificação completa sem rede. O deploy executa o mesmo auditor com
`--require-deployable`; com as 29 provas focadas e as 5 equivalências exatas do
escopo atual, a qualificação local passa sem revisão pendente.

O auditor rejeita uma reconciliação PostgreSQL falsa contendo apenas
`{"status":"pass"}`. Um passe exige 169 resultados individuais, transação
read-only comprovada, consulta não vazia, zero ambiguidades, contagens
reconciliadas e digest das linhas. Também recalcula a classificação
`future_only` pelas datas dos sets. A política de ativação versionada bloqueia
as 45 cartas futuras e as 88 ausentes do PostgreSQL. Somadas às quarentenas
exatas de `Planetarium` e `Mandate of Peace`, a disponibilidade efetiva fica
em 34 suportadas e 135
indisponíveis; essa indisponibilidade deliberada é uma propriedade de
segurança, não uma falha que deva ser reduzida artificialmente a zero.

O pacote
`docs/qa/evidence/XMAGE_PRODUCT_SCOPE_FOCUSED_TEST_EVIDENCE_34d81ea_2c43ec8_2026-07-30.json`
registra três patches somente de testes e 68/68 cenários para 31 identidades
diretas. São quatro execuções: 15 testes das cartas adicionadas no pin novo, 29
testes executáveis no pin novo e 12 testes idênticos de apresentação em cada
pin. As execuções comparativas usam repositórios Maven locais separados
(`m2-from` e `m2-to`); compartilhar o cache entre pins é rejeitado porque pode
misturar JARs e produzir um falso resultado. Ambos os lados são reconstruídos e
executados com Java 17. Testes marcados como parciais continuam pendentes.
`Planetarium` aparece apenas para confirmar executavelmente a quarentena; esse
teste não é evidência de promoção. O mesmo vale para o cenário de reprodução
de `Mandate of Peace`, que confirma o residual de cópia/LKI e não libera a
carta. As outras 29 identidades diretas cobrem exatamente as cartas executáveis
do escopo atual; somadas às 5 equivalências estritas, cobrem as 34 cartas
disponíveis no produto. Nenhum fonte de carta do upstream foi alterado.

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

Fonte, build, runtime loopback, inventário nominal, escopo PostgreSQL e política
de ativação foram auditados. Não resta revisão semântica global nas 34 cartas
do escopo atual: 29 têm prova focada e 5 têm equivalência estrita
não executável. As 133 cartas fora do escopo atual permanecem indisponíveis por
política e serão revisadas quando puderem ser ativadas; elas não contam como
bloqueio global. `Planetarium` e `Mandate of Peace` ficam em quarentenas exatas
e não promocionais. `Prudent Fateseer` conserva o residual upstream sob o
bloqueio de ativação, e `Swordsman` conserva a dívida de controlador na mesma
faixa até entrar no escopo do produto. O pin está qualificado localmente para
deploy, mas nenhum deploy, reinício ou mutação de produção foi realizado; o
serviço publicado continua no pin anterior.
