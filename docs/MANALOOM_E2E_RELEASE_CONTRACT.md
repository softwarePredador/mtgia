# Contrato E2E e de conclusão do ManaLoom

Este é o contrato operacional vigente para validar, concluir e preparar uma
entrega do repositório. Relatórios datados registram evidência de uma rodada;
eles não substituem este contrato.

## Regras invariantes

- PostgreSQL é a fonte de verdade de produto. Hermes/SQLite e relatórios são
  cache, laboratório ou evidência; nunca promovem verdade revisada por conta
  própria.
- Nenhum gate local determinístico escreve em PostgreSQL, chama IA externa ou
  cria dados em uma API viva.
- Uma escrita live exige a confirmação textual
  `MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL`.
- Uma escrita via API viva exige o token live; SQL direto, migração ou cleanup
  direto em PostgreSQL exige também
  `MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL`.
- Flags booleanas como `MANALOOM_RUN_*` selecionam uma camada, mas não são
  autorização de escrita.
- DDL de produto pertence somente a migrations. Caminhos de request, serviços e
  testes read-only não podem criar ou alterar schema implicitamente.
- Suites legacy de HTTP só podem usar alvo local/staging explícito. O hostname
  conhecido de produção é bloqueado nelas.
- Um `SKIP` precisa declarar pré-requisito e comando de ativação. Ele não pode
  ser apresentado como `PASS`.
- Gate e release são fail-closed: `PASS` é o único resultado com exit code
  zero. O modo diagnóstico que tolera `PARTIAL` exige `--allow-partial`, é
  marcado como não elegível para gate/release e nunca pode ser descrito como
  sucesso do gate.

## Perfis canônicos

| Perfil | Escopo | Rede/escrita | Entrada | Resultado esperado |
| --- | --- | --- | --- | --- |
| `deterministic-read-only` | app, server, deckbuilder, battle, contratos, PG/Hermes read-only | sem mutação de produto | `./scripts/quality_gate.sh e2e` | gate estrito: `PASS` somente sem `SKIP`; `PARTIAL` retorna 3 |
| `diagnostic-allow-partial` | mesmo inventário, para mapear pré-requisitos ainda ausentes | sem crédito de gate/release | `./scripts/manaloom_e2e_suite.sh --allow-partial` | pode retornar zero em `PARTIAL`, mas grava `execution_policy=diagnostic-allow-partial` e `gate_eligible=false` |
| `isolated-mutating` | corpus Commander completo em ambiente aprovado | cria e remove usuários/decks de validação | `MANALOOM_RUN_MUTATING_RESOLUTION_E2E=1` + token PostgreSQL | `PASS` somente com cleanup e resumo do corpus |
| `live-smoke` | Flutter runtime, API viva e smoke comercial | pode criar/apagar dados e chamar serviços externos | flags `MANALOOM_RUN_*_E2E=1` + tokens live/PG aplicáveis | `PASS` somente no alvo explicitamente aprovado |
| `release-target` | build instalável, device/simulador, saúde e SHA implantado | depende do alvo de release | checklist desta página | conclusão de release, não apenas conclusão local |

O resumo da suíte é gravado por padrão em
`/tmp/manaloom_e2e_suite_reports/<run>/summary.md` e `summary.json`. Os status
válidos são:

- `PASS`: todas as etapas solicitadas executaram e passaram;
- `PARTIAL`: não houve falha, mas camadas opcionais não solicitadas foram
  registradas como `SKIP`; retorna 3 no gate estrito e só retorna zero no modo
  diagnóstico explicitamente selecionado;
- `BLOCKED`: uma camada foi solicitada sem autorização ou pré-requisito;
- `FAIL`: pelo menos uma etapa executada falhou.

O mapeamento canônico é `PASS=0`, `FAIL=1`, `BLOCKED=2` e `PARTIAL=3`.
`quality_gate.sh e2e`, `manaloom_local_ci.sh e2e` e o wrapper PowerShell sempre
selecionam `--strict`; portanto nenhum deles propaga `PARTIAL` como sucesso.

## Matriz mínima de gates

| Área | Comando canônico | Mutação de produto |
| --- | --- | --- |
| Server + app completos | `./scripts/quality_gate.sh full` | não; tags live são excluídas |
| Contratos dos harnesses runtime | `./scripts/quality_gate.sh performance` (também incluído em `full`) | não; valida código/orçamentos sem browser/device e pode abrir fixtures HTTP exclusivamente loopback, efêmeras e sem dados de produto |
| Memória/imagens Web runtime | `./scripts/quality_gate.sh web-image-memory` | não; fixture loopback e Chrome/CDP locais, exige ChromeDriver do mesmo major e falha fechado |
| Dependências | `./scripts/quality_gate.sh deps` | não |
| Regras ManaLoom | `./scripts/quality_gate.sh custom-lint` | não |
| UI automatizada + prova viva revisada | `./scripts/quality_gate.sh ui-audit` | não; exige analyzer/widget/golden e evidência runtime já capturada |
| Vínculo UI corrente | `./scripts/quality_gate.sh ui-proof` | não; valida digest, PNGs/hashes e revisão visual explícita |
| Jornadas Patrol locais | `./scripts/quality_gate.sh patrol-smoke` | não |
| Battle nativo/Forge/XMage | `./scripts/quality_gate.sh battle` | não |
| Transição nominal do pin XMage | `./scripts/quality_gate.sh engine-transition` | não; valida cada carta adicionada/modificada e pode manter deploy bloqueado |
| Ponte app/IA | `./scripts/quality_gate.sh ai-bridge` | não |
| Ramp, optimizer, fundação de dados e regras | etapa `Ramp classifiers and data-foundation safety contracts` de `./scripts/quality_gate.sh e2e` | não; somente testes locais, preflight e injeção simulada de falha |
| Contrato PG/Hermes/SQLite | `./scripts/quality_gate.sh pg-contract` | leitura de PG; relatórios em `/tmp` |
| IA/deckbuilder profundo | `./scripts/quality_gate.sh deep-ai` | leitura de PG; não aplica migração |
| Retenção de relatórios | `./scripts/quality_gate.sh report-retention` | não |
| Produto integrado local | `./scripts/quality_gate.sh e2e` | não por padrão |

O gate de battle deve ser reprodutível sem o `~/.m2` da máquina. O bootstrap
`services/xmage-sidecar/bin/bootstrap_pinned_xmage_maven.sh` instala os módulos
XMage ausentes do Maven Central a partir do SHA de `XMAGE_COMMIT`; o CI executa
esse bootstrap antes do gate.

Um pin XMage atualizado só pode ser implantado quando o contrato versionado de
transição estiver com `qualification.status=pass`. O gate estrutural aceita
`review_required` para manter o desenvolvimento e a auditoria reproduzíveis,
mas `scripts/manaloom_deploy_battle_sidecars.sh` repete o auditor com
`--require-deployable` e falha antes de qualquer operação remota. Resolução no
catálogo não é prova semântica de uma carta. A qualificação inclui bloqueios
pinados do sidecar: uma carta com defeito confirmado deve retornar
`unsupported_cards` com motivo estruturado, e qualquer avanço de
`XMAGE_COMMIT` precisa revisar a política antes de os testes aceitarem o novo
runtime.

Quando `XMAGE_PATCH_COMMIT` estiver presente, o patch governado é uma segunda
identidade obrigatória, não uma edição local implícita. O Battle gate e o
deploy executam `xmage_governed_patch_audit.py --require-deployable`; o build
reproduz a árvore a partir do patch versionado, confirma pai/commit/árvore no
repositório governado e o runtime publica `engine_patch_commit`. Backend,
sidecar batch e sidecar interativo precisam concordar com essa identidade.

A etapa focada da suíte E2E executa explicitamente os classificadores de ramp
em Dart e Python, o piso estrutural do optimizer, os contratos de segurança da
fundação de qualidade de candidatos e da sincronização das Comprehensive Rules.
Testes de segurança do backfill `semantic_layer_v2` entram automaticamente
quando existem no repositório; a etapa nunca chama `--apply`.

## Camadas que exigem autorização

### Corpus Commander mutante

```bash
MANALOOM_RUN_MUTATING_RESOLUTION_E2E=1 \
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
./scripts/quality_gate.sh e2e
```

### Smoke live completo

Defina também `MANALOOM_API_BASE_URL`/`TEST_API_BASE_URL` para o alvo aprovado.

```bash
MANALOOM_RUN_FLUTTER_RUNTIME_E2E=1 \
MANALOOM_RUN_SERVER_LIVE_E2E=1 \
MANALOOM_RUN_LIVE_PRODUCT_E2E=1 \
MANALOOM_FLUTTER_RUNTIME_DEVICE=<flutter-device-id> \
MANALOOM_FLUTTER_RUNTIME_API_BASE_URL=https://alvo-aprovado.example \
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
./scripts/quality_gate.sh e2e
```

O runtime Flutter falha fechado quando o device ou a API não são explícitos;
seleção interativa de dispositivo e `API_BASE_URL` implícita não recebem crédito
de release. `MANALOOM_FLUTTER_BIN` pode fixar o executável pinado da rodada.

Não copie esses tokens para `.env`, CI ou documentação de comando automático.
Eles representam aprovação humana para uma execução específica.

## Critério de conclusão

### Conclusão local do projeto

Uma rodada pode ser declarada concluída localmente quando:

1. `git diff --check` e a sintaxe dos scripts alterados estão verdes;
2. `full`, `deps`, `custom-lint`, `ui-audit`, `patrol-smoke`, `battle`,
   `engine-transition`, `report-retention` e o perfil E2E determinístico estão
   sem falhas estruturais;
3. Android e iOS continuam enumeráveis/compiláveis nos alvos disponíveis;
4. artefatos removidos têm zero consumidor ativo e substituto canônico;
5. relatórios gerados ficam em `/tmp` ou diretório ignorado, salvo evidência
   revisada e manifestada;
6. toda UI alterada possui `PASS_AUTOMATED`, `PASS_RUNTIME` e
   `PASS_VISUAL_REVIEWED` conforme
   `docs/MANALOOM_UI_LIVE_EVIDENCE_CONTRACT.md`;
7. toda camada não executada aparece como `SKIP`/pendência, nunca como sucesso.

### Conclusão de release

Além da conclusão local, exige:

1. build instalável no(s) alvo(s) de distribuição;
2. jornada crítica em device/simulador representativo;
3. smoke live no ambiente explicitamente aprovado, com cleanup validado;
4. pagamentos/webhooks/serviços externos aplicáveis ao release;
5. `/health`, `/ready` e SHA implantado compatíveis com a revisão entregue;
6. nenhuma migração pendente necessária ao código implantado.
7. toda transição ativa de pin XMage está com qualificação
   `pass`/`deployment_allowed=true`, sem carta residual ou reconciliação
   PostgreSQL pendente.
8. todo patch XMage governado ativo está fetchable, reproduzível, com testes
   focados verdes, escopo PostgreSQL read-only reconciliado e identidade
   confirmada em health/readiness/replay.

Sem esses itens, o resultado correto é “localmente concluído, release
pendente”, e não “produção concluída”.

## Política de legado e artefatos

Um arquivo só pode ser removido automaticamente quando não tem consumidor
ativo, não é prova citada, possui substituto canônico quando necessário e os
gates relevantes permanecem verdes. Duplicatas de empacotamento exigidas por
runtimes distintos não são legado apenas por terem o mesmo hash.

Dados brutos em `docs/hermes-analysis/master_optimizer_reports/` são
classificados como `active_consumer`, `manifest_only` ou `ungoverned` pelo gate
de retenção. `ungoverned` falha o gate. `manifest_only` continua dívida de
arquivo explícita e não pode inflar a contagem de consumidores ativos.

## Evidência de execução

Este contrato não incorpora uma “rodada corrente”. Resultados envelhecem e
devem permanecer em receipts task-scoped, ligados ao SHA e ao digest que
provaram. Para conhecer o estado atual, siga:

1. `docs/execution/CURRENT_QUEUE.md` para o único ID `NOW`;
2. `docs/execution/tasks/<TASK-ID>.md` para o ledger da execução;
3. `docs/qa/execution/` para receipts duráveis;
4. o summary machine-readable produzido pelo gate solicitado;
5. `docs/status/CURRENT_PRODUCT_DECISION.md` para o veredito de release.

Relatórios antigos em `docs/qa/` continuam preservados como
`historical_evidence`. Eles nunca são promovidos por data, quantidade de testes
ou link neste contrato. Um receipt local também não prova release sem
identidade same-SHA do alvo implantado e todos os critérios da seção anterior.
