# ManaLoom Battle e Deckbuilder — varredura definitiva de 2026-07-15

Status: `REOPENED_PROVIDER_AND_MUTATING_E2E_VALIDATION`

> Correção posterior à primeira consolidação: o run
> `manaloom_e2e_suite_20260715T222313Z` continua válido como prova de contratos
> locais e cleanup, mas foi invalidado como prova de otimização real. Os 19
> casos receberam `is_mock=true`, `outcome_code=mock_non_actionable`, zero
> remoções e zero adições; o runner antigo classificou incorretamente HTTP 200
> como `optimized_directly`. A conclusão técnica permanece reaberta até o gate
> fail-closed ser corrigido e repetido com provedor válido.

## Veredito

| Superfície | Veredito | Limite atual |
| --- | --- | --- |
| Battle convencional | Cobertura/triagem fechada no snapshot | 0 residual convencional acionável; isso não prova semântica carta a carta |
| Geração/otimização | Contratos técnicos verdes | produto ainda tem gaps; promoção exige estratégia, exposição natural e replay |
| Decks de produto | Parcial por intenção do dono | 7/16 prontos estruturalmente; 9 skeletons preservados |
| PostgreSQL/Hermes | Contrato runtime alinhado 55/55 | não é alegação de espelho global; PostgreSQL é verdade e SQLite é cache/lab/runtime |
| Release | Pendente | nenhum SHA candidato foi implantado e testado live nesta rodada |

A cobertura/triagem de battle, a base de dados e a execução técnica local estão
verdes no escopo auditado. A qualidade de produto ainda requer reparos de deck
e evidência de promoção. Isso também não é sinônimo de release em produção: os
três perfis live exigem alvo implantado, SHA verificável e device/runtime
aprovado.

## Quanto melhorou desde a verificação anterior

| Indicador | Antes | Agora | Mudança |
| --- | ---: | ---: | ---: |
| Migrations | 32/34 | 35/35 | +3 executadas; 0 pendente |
| Testes server `all-local` | 1.122 | 1.171 | +49 |
| Produto estruturalmente pronto | 6/16 | 7/16 | +1 deck; +6,25 p.p. |
| Produto em reparo | 10/16 | 9/16 | -1 deck |
| Superfícies Commander auditadas | 706 | 310 | -396 fixtures comprovados |
| Spellbook variantes importadas/legal-by-source | 89.897 | 98.658 | +8.761; +9,75% |
| Relações combo/carta | 314.987 | 348.106 | +33.119; +10,51% |
| Resíduo battle sem disposição terminal formal | 1.063 | 0 | 1.063/1.063 formalizados |

A queda de 706 para 310 não é perda de cobertura: 396 decks de teste/legado
foram removidos com backup e rollback. O conjunto corrente contém 277 fixtures
retidos, 16 decks de produto e 17 decks Hermes.

O comparativo de disposição battle usa como antes
`/tmp/manaloom-global-family-goal-post-apply/coverage_20260715_063706/summary.json`
e como depois o snapshot canônico final indicado na seção de battle.

## Reconciliação externa e fontes primárias

- A política atual de brackets foi alinhada às atualizações oficiais da
  Wizards: Game Changers têm teto 0 em B1/B2, 3 em B3 e não têm teto em B4/B5;
  a contagem de tutors não é mais um teto rígido. As referências revisadas foram
  `introducing-commander-brackets-beta`, a atualização de 2025-10-21 e a
  atualização de 2026-02-09.
- `Partner` genérico, `Partner with` e as variantes de partner não são mais
  confundidos. Em `Doctor's companion`, o outro Commander deve ser uma
  criatura lendária `Time Lord Doctor`, conforme CR 702.124.
- Rulings vêm do bulk publicado pela Scryfall. Combos vêm do JSON versionado do
  Commander Spellbook e são ligados por `oracle_id`, não por nome frouxo.
- A coleta automatizada de EDHREC permanece desligada por padrão. A integração
  só abre com autorização própria; dados públicos são evidência, não verdade
  automática de deck.
- XMage continua primário e Forge fallback. Seus pins locais estão coerentes,
  mas só avançam após revisão dos deltas e testes de adaptação.

Referências:

- https://magic.wizards.com/en/news/announcements/introducing-commander-brackets-beta
- https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-october-21-2025
- https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026
- https://magic.wizards.com/en/formats/commander
- https://media.wizards.com/2026/downloads/MagicCompRules%2020260619.pdf
- https://api.scryfall.com/bulk-data
- https://scryfall.com/docs/api/rulings
- https://backend.commanderspellbook.com/schema/
- https://json.commanderspellbook.com/variants.json
- https://edhrec.com/terms

## Battle: estado definitivo do corpus atual

Auditoria canônica final:
`/tmp/manaloom-global-closure-audit-20260715-final/coverage_20260715_202949/summary.json`.

| Métrica | Resultado |
| --- | ---: |
| Linhas PostgreSQL | 34.331 |
| Cobertas | 33.268; 96,9037% |
| Identidades totalmente cobertas | 33.019/34.080; 96,8867% |
| XMage exact | 31.285 |
| Forge exact | 1.796 |
| Native verified | 187 |
| Resíduo | 1.063 linhas; 1.061 identidades |
| Disposições terminais | 1.063/1.063 |
| Residual acionável | 0 |
| Promoção automática | 0 |

O resíduo é técnico, não um backlog convencional escondido:

- 816 objetos de regras não padrão, playtest/funny/acorn;
- 138 objetos auxiliares (planos, atrações, stickers, dungeons e afins);
- 55 interações físicas, de produto ou entrada externa;
- 54 objetos de cenário/challenge/hero deck.

O catálogo-fonte tem 23.951 candidatos: 23.942 estão operacionalmente
cobertos (99,9624%) e 9 têm status auditável
`local_source_candidate_not_executable`. No snapshot auditado há 0 residual
convencional acionável; os deltas upstream dos motores são tratados
separadamente abaixo.

### Deltas dos motores

O contrato dos pins passou com 0 falhas. A comparação upstream está em
`review_required`, não em falha:

| Motor | Pin local | Upstream à frente | Candidatos |
| --- | --- | ---: | ---: |
| XMage | `34d81ea4995ce15d7e1a788dc6d2a3595d35bcec` | 28 commits | 26 |
| Forge | `a62915f500c2411484689294659c6bb84ea215f8` | 8 commits | 11 |

Comparações:

- https://github.com/magefree/mage/compare/34d81ea4995ce15d7e1a788dc6d2a3595d35bcec...master
- https://github.com/Card-Forge/forge/compare/a62915f500c2411484689294659c6bb84ea215f8...master

Os 37 candidatos devem ser revisados por família; não há base para mover os
pins cegamente.

## Deckbuilder, famílias e fontes de dados

Correções duráveis desta rodada:

- identidade de cor passou a ser tri-state: `null` permite fallback, `[]`
  canônico significa realmente colorless, e identidade canônica não vazia
  vence qualquer inferência;
- regras de partner foram separadas por variante e reciprocidade;
- brackets e Game Changers foram reconciliados com a política oficial atual;
- famílias funcionais e suporte de qualidade foram incorporados ao candidato
  de otimização, com cobertura dirigida das 26 cartas de produto;
- Commander Spellbook passou a importar somente variantes Commander-legal
  segundo a fonte; exposição/uso seguro ainda exige requisito conhecido,
  `must-be-commander` satisfeito e composição verificável. Requisito
  desconhecido permanece armazenado, mas falha fechado;
- rulings Scryfall e Spellbook têm transação, aprovação, reconcile e lineage;
- coleta EDHREC automatizada fica default-off;
- migrations aplicam por transação e rollback respeita política por migration;
- snapshot canônico de battle foi atualizado a partir do PostgreSQL.

### Dados carregados

| Dataset | Resultado |
| --- | ---: |
| Scryfall rulings | 76.762 linhas; 19.622 Oracle IDs |
| Commander Spellbook | 98.658 variantes importadas e legais na fonte |
| Spellbook combo cards | 348.106 relações; 0 pares duplicados |
| Tags `combo_piece` da source `commander_spellbook_combo_v1` | 7.323 |
| PG869 famílias funcionais | 46 tags; 35 IDs físicos; 26 nomes |
| PG/Hermes runtime keys | 10.111/10.111; 0 não resolvida |
| Regras comparáveis | 7.156; drift de hash 0 |

O endpoint Spellbook identificou o dataset como `5.5.3`. O release GitHub
`v5.6.0` publicado em 2026-07-15 é dependency-only e não foi indevidamente
registrado como versão do JSON. Das 98.658 variantes importadas, 11.437 têm
composição verificável e 87.221 permanecem fail-closed por requisitos que a
integração não pode afirmar com segurança.

## Decks de produto

O contrato global atual cobre 310 superfícies:

- 277 `test_or_fixture` retidos;
- 16 `user_product`;
- 17 Hermes (baseline, variantes Lorehold e variantes registradas).

Produto: 7 `structure_ready`, 9 `needs_repair`. As falhas restantes de produto
são somente `quantity_not_100` (9), `missing_commander` (2) e
`unresolved_card_id` (1). Não resta carta ilegal nem off-color em produto.

### Goblins

Deck `8c22deb9-80bd-489f-8e87-1344eabac698` (`goblins`):

- 100 cartas, 1 Commander, 0 ilegal, 0 off-color;
- `Auntie Flint` foi removida e a Mountain já existente passou de 4 para 5;
- o perfil de pips justificou Mountain: R=72, B=5, G=4;
- o deck ainda tem 25 lands contra piso diagnóstico 34, 2 wincons contra piso
  3 e 10 quantidades sem papel core mapeado;
- excesso de removal/engine é sinal de revisão, não autorização de auto-cut.

Portanto o deck está legal/estrutural, mas ainda não está estrategicamente
pronto para promoção.

### Skeletons preservados

| ID | Nome | Quantidade | Bloqueio principal |
| --- | --- | ---: | --- |
| `93e0e6e1-e351-4db8-9715-6c6d1fdf5672` | hfgh | 1 | quantidade |
| `8ff632c1-2499-436f-89a4-2802da1e605f` | jin | 1 | quantidade |
| `0b163477-2e8a-488a-8883-774fcd05281f` | Jin | 1 | quantidade |
| `536b9e7d-69c3-4518-ab92-fe83352a0b4e` | Jin | 1 | quantidade |
| `6e9db347-2fb1-413f-bdd1-1e15b690566e` | Jin | 0 | sem Commander/ID |
| `2fb14ec7-7a00-4ad7-a7e9-5a5a85d7f9b2` | jin2 | 1 | quantidade |
| `59bbcd4a-f8a4-46b2-944d-0896d83a6f7c` | jjjj | 1 | quantidade |
| `b17e9d71-8b51-48ad-833b-f17190a347a3` | lorehold | 2 | quantidade |
| `84aacfd4-e518-474a-9066-e88ea35274b9` | rolinha | 1 | sem Commander |

Esses registros parecem rascunhos, mas pertencem à superfície de produto e não
têm prova suficiente de abandono. Foram preservados para decisão explícita do
dono; reconstruí-los automaticamente inventaria intenção estratégica.

### Core roles e promoção

Nos 33 decks elegíveis de produto/lab:

- 9 `core_review_ready`;
- 15 com gaps de core;
- 9 bloqueados estruturalmente;
- slots críticos faltantes: 42 lands, 5 removals e 8 wincons;
- 20 quantidades sem papel core mapeado.

Quatro pacotes candidatos existentes continuam bloqueados por baseline
protegido ou falta de exposição. Eles precisam de replay natural que prove
`drawn/cast/used` das cartas alteradas antes de qualquer promoção.

## Escritas PostgreSQL, backup e rollback

A autorização de escrita foi usada somente com precheck, transação, postcheck
e rollback preparado.

Backups em `/tmp/manaloom_pg_write_20260715T210024Z`:

| Arquivo | SHA-256 |
| --- | --- |
| `pre_migrations_schema.sql` | `75105b7bf0842083ecc399dc867e027218767abb221ba53952db36e18d772c42` |
| `pre_migrations_critical_tables.dump` | `b127f6f31958b69c6ac1b8b930870159c992101d1f210be2fe79812c0c694f44` |
| `pre_spellbook_tables.dump` | `1bdd3516fc6cea3f061ded229e127e352655c8912347f92ba4e04a44210b1b03` |
| `knowledge_pre_sync.db` | `7a652c4997fb1c43fd60d8863640e0296a4336dcf35dd0cbd7fb2fcb472009f5` |

O dump vazio `pre_migrations_rulings_and_migrations.dump` não é contado como
backup. Prestate Spellbook, cleanup e PG870 também foram preservados em
`manaloom_deploy_audit`.

Aplicações concluídas:

1. migrations 033, 034 e 035; status final 35/35;
2. sync Scryfall rulings;
3. reconcile Commander Spellbook;
4. PG869 de famílias funcionais;
5. remoção de 396 fixtures com backup;
6. sync PostgreSQL -> Hermes SQLite;
7. PG870 de legalidade do deck Goblins.

O teste real de `--rollback 1` depois da carga da migration 035 abortou antes
de escrever, como exigido pela política `manualOnly`. O rollback não foi
forçado sobre dados válidos.

## Legado e retenção

- 228 arquivos rastreados sem consumidor foram removidos: 35,68 MiB;
- 396 decks fixture e 4.774 linhas `deck_cards` foram removidos com backup;
- auditoria posterior: 293 decks PostgreSQL restantes, 0 novo subconjunto
  seguro para exclusão automática;
- retenção: PASS, 914 artefatos rastreados; 667 com consumidor e 247 somente
  por manifesto; 0 ungoverned, 0 stale, 0 resíduo local ignorado.

Não há justificativa para outra limpeza indiscriminada. Os 277 fixtures
restantes têm referência, provenance incompleta, owner não explicitamente de
teste, publicidade ou idade que exige revisão manual.

## Validação final

| Área | Resultado |
| --- | --- |
| Server analyze | 0 issues |
| Server completo | 1.171/1.171 PASS, 151 suites |
| App analyze | 0 issues |
| App completo | 637/637 PASS |
| Battle canônico | 42/42 checks; 54 Python; 58 Dart; 1 skip esperado |
| Battle runtime | 348 PASS |
| Deep AI | 12/12 etapas; 164 testes focados |
| PG/Hermes/SQLite | 55/55 |
| E2E agregado, perfil `isolated-mutating` | 12 PASS, 3 SKIP live, 0 FAIL, 0 BLOCKED |
| Subgate mutável de resolução | 1 PASS; 19/19 casos, 0 failed, 0 unresolved |
| Retenção | PASS |

E2E endurecido: `manaloom_e2e_suite_20260715T222313Z`, resumo em
`/tmp/manaloom_e2e_suite_reports/manaloom_e2e_suite_20260715T222313Z/summary.json`.

O subgate mutável `20260715222504_83341_14293e90e188` passou 19/19 casos e
produziu a pós-auditoria obrigatória em
`/tmp/manaloom_resolution_corpus/20260715222504_83341_14293e90e188/mutation_audit.json`.
O cleanup zerou a identidade, os decks e `deck_cards` temporários; uma consulta
PostgreSQL independente confirmou 0/0/0. Os totais das seis superfícies
monitoradas ficaram iguais ao baseline: cache 0, fallback 136, ML feedback 151,
analysis logs 940, AI logs 1.104 e rate-limit 128; nenhuma linha foi criada na
janela e `telemetry_deleted=false`.

Essa medição prova delta de linhas zero nesta janela. Ela não detecta eventual
`UPDATE`/`ON CONFLICT` em linha preexistente quando a tabela não expõe
`updated_at`, nem atribui escritores concorrentes a este run; essa limitação
está registrada no próprio artefato.

As provas de iOS Simulator, Android físico e builds instaláveis no closure E2E
são históricas da rodada de organização. Não foram repetidas depois das cargas
de dados, que não alteram código Flutter/plataforma.

## Pendências reais

1. decidir se os 9 skeletons de produto devem ser excluídos como rascunhos ou
   reconstruídos com Commander/bracket/estratégia fornecidos pelo dono;
2. reparar os floors estratégicos dos decks reais sem auto-cuts;
3. executar exposição natural dos 4 pacotes bloqueados;
4. revisar os 37 deltas upstream de XMage/Forge antes de atualizar pins;
5. implantar um SHA candidato e executar Flutter live, server live e produto
   live contra esse alvo, com `/health`, `/ready`, SHA e cleanup comprovados.

Não houve commit, push ou deploy nesta rodada. O worktree já era amplamente
modificado e mudanças não relacionadas foram preservadas.
