# Encerramento E2E do projeto ManaLoom — 2026-07-15

> **Reaberto após revisão adversarial:** o run `222313Z` comprovou cleanup e
> contratos locais, mas não comprovou otimização real. Todos os 19 resultados
> do subgate eram fallback mock não acionável, aceito incorretamente como
> `optimized_directly`. As linhas de fechamento técnico abaixo ficam
> supersedidas até a repetição com o runner fail-closed e provedor válido.

## Follow-up operacional do mesmo dia

O texto abaixo preserva exatamente o estado da execução E2E original. Depois
dela, três pendências operacionais foram tratadas separadamente:

- o JWT de produção foi rotacionado no EasyPanel; o token anterior passou a
  retornar 401 e um token emitido após a rotação retornou 200 em `/auth/me`;
- o app Flutter autenticado foi publicado em `/app` no servidor novo, sem
  substituir a raiz pública existente;
- um APK Android dedicado da ManaLoom foi assinado, validado em aparelho físico
  e publicado com manifesto/checksum; o AAB ficou preservado no servidor para
  envio à loja.

A distribuição iOS nativa não foi improvisada com identidades de outras
empresas. O build sem assinatura está preservado, mas a publicação depende da
equipe Apple Developer/App Store Connect proprietária de
`com.mtgia.mtgApp`.

Relatório detalhado de battle/deckbuilder:
`docs/qa/MANALOOM_BATTLE_DECKBUILDER_DEFINITIVE_2026-07-15.md`.

## Veredito

| Camada | Resultado | Observação |
| --- | --- | --- |
| Código/local | **CONCLUÍDA** | analyze, testes, gates, contratos e retenção sem falhas |
| Base de dados técnica | **VERDE** | 35/35 migrations, cargas aplicadas e contrato runtime PG/SQLite 55/55 |
| Qualidade de produto | **PENDENTE** | 9/16 decks em reparo; 15 core gaps e 9 bloqueios estruturais no recorte elegível |
| E2E agregado, perfil `isolated-mutating` | **PARTIAL esperado** | 12 PASS, 3 SKIP live, 0 FAIL, 0 BLOCKED |
| Release/produção | **PENDENTE** | nenhum SHA candidato implantado e smoke live nesta rodada |

`PARTIAL` não representa regressão. O corpus mutável autorizado foi executado;
os três skips restantes dependem de um backend implantado e de runtime/device
aprovado. Sem alvo e SHA, rodá-los contra produção seria uma expansão insegura
de escopo.

## Evidência agregada final

- execução: `manaloom_e2e_suite_20260715T222313Z`;
- perfil: `isolated-mutating`;
- resultado: 12 PASS, 3 SKIP, 0 FAIL, 0 BLOCKED em 15 etapas;
- resumo:
  `/tmp/manaloom_e2e_suite_reports/manaloom_e2e_suite_20260715T222313Z/summary.json`;
- corpus de resolução: 19/19 PASS, 0 failed, 0 unresolved;
- auditoria profunda: `deep_ai_alignment_20260715_224235`, 12/12 etapas;
- contrato PostgreSQL/Hermes/SQLite: 55/55.

Os três `SKIP` são:

1. integração Flutter contra runtime/API live;
2. E2E do server contra API implantada;
3. smoke de produto, paywall e geração de IA contra alvo live.

## Correções e organização concluídas

### Segurança, schema e fontes

- Escritas PostgreSQL foram guardadas por token textual, precheck, transação,
  postcheck, backup e rollback.
- Migrations 033, 034 e 035 foram aplicadas; status final 35/35, 0 pendente.
- O migrator passou a aplicar cada migration transacionalmente e a respeitar
  políticas `emptyOnly`/`manualOnly` no rollback.
- DDL de produto ficou restrito a migrations; sync PG -> SQLite não cria schema
  implicitamente.
- PostgreSQL permanece fonte de verdade. Hermes SQLite continua cache/lab; o
  contrato runtime auditado passou 55/55, sem alegar espelho global.
- Scryfall rulings e Commander Spellbook ganharam reconcile transacional,
  approval gate e lineage.
- EDHREC automatizado está default-off e falha fechado sem autorização própria.

### Deckbuilder, geração e otimização

- Identidade de cor passou a distinguir `null` (fallback), `[]` (colorless
  canônico) e identidade canônica não vazia.
- Partner genérico, `Partner with`, Friends Forever, Choose a Background e
  Doctor's companion deixaram de compartilhar heurística frouxa.
- Brackets/Game Changers foram atualizados para a política oficial corrente;
  tutor count não é teto rígido.
- Tags/famílias funcionais e suporte de qualidade do candidato cobrem 26 cartas
  de produto; PG869 carregou 46 tags para 35 IDs físicos/26 nomes.
- Spellbook foi carregado com 98.658 variantes legais segundo a fonte, 348.106
  relações e 7.323 tags `combo_piece` da source versionada; 11.437 variantes
  têm composição verificável e requisitos desconhecidos falham fechado.
- Produto atual: 7/16 decks estruturalmente prontos e 9 skeletons preservados
  para decisão do dono.
- Goblins passou a 100 cartas, 1 Commander e 0 ilegal/off-color; ainda precisa
  corrigir lands/wincon no gate estratégico.

### Battle

- 33.268/34.331 linhas estão cobertas (96,9037%).
- As 1.063 linhas residuais têm disposição terminal: objetos não padrão,
  auxiliares, físicos/externos ou de cenário. Residual convencional acionável:
  0.
- O catálogo-fonte está 23.942/23.951 operacionalmente coberto (99,9624%).
- Pins XMage/Forge passaram o contrato. Há 37 deltas upstream para revisão
  manual, sem autorização técnica para atualizar pins cegamente.

### Limpeza e retenção

- 228 arquivos rastreados sem consumidor foram removidos: 35,68 MiB.
- 396 decks fixture e 4.774 `deck_cards` foram removidos com backup/rollback.
- Auditoria posterior encontrou 0 novo subconjunto seguro para auto-delete.
- Retenção: 914 artefatos rastreados; 667 com consumidor e 247 por manifesto;
  0 ungoverned, 0 stale e 0 resíduo ignorado.

## PostgreSQL aplicado

| Carga | Resultado |
| --- | --- |
| Migrations | 35/35 executadas |
| Scryfall rulings | 76.762 linhas; 19.622 Oracle IDs |
| Commander Spellbook | 98.658 variantes importadas; 348.106 relações |
| PG869 | 46 tags; 35 IDs; 26 nomes |
| Cleanup fixtures | 396 decks; 4.774 itens |
| PG870 Goblins | 100 cartas; 1 Commander; 0 ilegal/off-color |
| PG -> SQLite | 10.111/10.111 runtime keys; drift 0 |

Backups válidos ficam em `/tmp/manaloom_pg_write_20260715T210024Z`; o arquivo
de dump que ficou com 0 bytes foi explicitamente excluído da lista de backups.
Prestates também existem em `manaloom_deploy_audit`.

## Matriz de validação atual

| Área | Resultado |
| --- | --- |
| Backend completo | 1.171 PASS; 151 suites; 0 fail/skip |
| App completo | analyze 0; 637 PASS |
| Deckbuilder/UI focado | PASS no E2E agregado |
| Deep AI | 12/12 etapas; 164 testes focados |
| Battle canônico | 42/42 checks; 54 Python; 58 Dart; 1 skip esperado |
| Battle runtime | 348 PASS |
| PostgreSQL/Hermes/SQLite | 55/55 |
| Corpus Commander mutável | 19/19 PASS; cleanup de usuário/decks zerado |
| Patrol product E2E local | PASS do harness local; CLI/device não executado nesta rodada final |
| Retenção | PASS |
| `git diff --check` | PASS após docs/hardening |

## Provas de plataforma históricas

As provas abaixo pertencem à rodada de organização e não foram repetidas após
as cargas de dados, porque essas cargas não alteram Flutter/plataformas:

- Patrol Chrome headless: 9/9;
- iOS Simulator `RunnerUITests`: 9/9;
- Android físico life counter: 1/1;
- APK debug: 215.911.384 bytes;
- archive iOS e `dart_frog build`: PASS.

Evidência iOS:
`app/build/ios_results_fixed_scheme_patched_1784142689.xcresult`.

## Cleanup do E2E mutável

A execução endurecida `222313Z`, subgate
`20260715222504_83341_14293e90e188`, criou uma identidade única, 19 clones e
os itens dependentes. Ao terminar:

- usuário por email: 0;
- usuário por username: 0;
- decks da identidade: 0;
- nomes `Resolution Validation`/`Rebuild Draft`: 0;
- delta observado de cache, fallback, feedback ML, analysis logs, AI logs e
  rate-limit: 0.

O gate foi endurecido e repetido com pós-auditoria obrigatória em
`/tmp/manaloom_resolution_corpus/20260715222504_83341_14293e90e188/mutation_audit.json`.
O artefato marcou `cleanup.pass=true`, `runner_exit_code=0` e
`telemetry_deleted=false`; uma consulta PostgreSQL independente confirmou 0
usuários, 0 decks e 0 `deck_cards` remanescentes para o token do run.

Os seis totais persistentes ficaram inalterados e nenhuma linha foi criada na
janela. A medição não detecta `UPDATE`/`ON CONFLICT` sobre linhas preexistentes
sem sinal `updated_at`, nem consegue atribuir escritores concorrentes; essa
limitação está explícita no artefato.

## Pendências reais de release/produto

1. decidir excluir ou reconstruir os 9 skeletons de produto;
2. reparar floors estratégicos e classificar cards sem core role;
3. obter replay de exposição natural para 4 pacotes candidatos bloqueados;
4. revisar 26 candidatos XMage e 11 Forge antes de alterar pins;
5. implantar um SHA candidato;
6. confirmar `/health`, `/ready` e SHA do alvo;
7. executar Flutter live, server live e produto live com cleanup comprovado.

## Conclusão operacional

Não há um novo backlog convencional de battle no snapshot auditado nem outra
limpeza automática segura. Código, dados e E2E local/mutável estão verdes. O
que falta é decisão de produto sobre decks ambíguos, evidência de promoção de
candidatos e release live sobre um alvo identificado.

Não houve commit, push ou deploy. O worktree já continha muitas alterações e
elas foram preservadas.
